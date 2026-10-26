//+------------------------------------------------------------------+
//|                      Hans123_Trader(barabashkakvn's edition).mq5 |
//|                              Copyright © 2018, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
#property version   "1.002"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\OrderInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
COrderInfo     m_order;                      // pending orders object
//---
#define MODE_LOW 1
#define MODE_HIGH 2
//--- input parameters
input double   InpLots           = 0.1;      // Lots
input ushort   InpStopLoss       = 50;       // Stop Loss (in pips)
input ushort   InpTakeProfit     = 50;       // Take Profit (in pips)
input ushort   InpTrailingStop   = 10;       // Trailing Stop (in pips)
input ushort   InpTrailingStep   = 5;        // Trailing Step (in pips)
input int      InpStartHour      = 6;        // Start hour
input int      InpEndHour        = 10;       // End hour
//---
ulong          m_magic;                      // magic number
ulong          m_slippage=10;                // slippage

double         ExtStopLoss=0.0;
double         ExtTakeProfit=0.0;
double         ExtTrailingStop=0.0;
double         ExtTrailingStep=0.0;
//---
double         m_adjusted_point;             // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpStartHour<0)
     {
      Print(__FUNCSIG__,", ERRROR: \"Start hour\" can not be less than zero!");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpEndHour<0)
     {
      Print(__FUNCSIG__,", ERRROR: \"End hour\" can not be less than zero!");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpStartHour>=InpEndHour)
     {
      Print(__FUNCSIG__,", ERRROR: \"Start hour\" can not be greater than or equal to \"End hour\"!");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpTrailingStop!=0 && InpTrailingStep==0)
     {
      Print(__FUNCSIG__,", ERRROR: \"Trailing Step\" == 0 !");
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();

   string err_text="";
   if(!CheckVolumeValue(InpLots,err_text))
     {
      Print(err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   m_magic=50000+func_Symbol2Val(m_symbol.Name())*100;
   m_trade.SetExpertMagicNumber(m_magic);
//---
   if(IsFillingTypeAllowed(SYMBOL_FILLING_FOK))
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if(IsFillingTypeAllowed(SYMBOL_FILLING_IOC))
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
//---
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtStopLoss=InpStopLoss*m_adjusted_point;
   ExtTakeProfit=InpTakeProfit*m_adjusted_point;
   ExtTrailingStop=InpTrailingStop*m_adjusted_point;
   ExtTrailingStep=InpTrailingStep*m_adjusted_point;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   Trailing();
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
//---
   MqlDateTime str1;
   TimeToStruct(TimeCurrent(),str1);
//--- pending orders

   MqlDateTime SValidity=str1;
   SValidity.hour=23;
   SValidity.min=59;
   datetime validity=StructToTime(SValidity);
//--- 
   long current_time = str1.hour*3600+str1.min*60+str1.sec;
   long start_time   = InpStartHour*3600;
   long end_time     = InpEndHour*3600;
   if(current_time>=start_time && current_time<end_time)
     {
      if(!RefreshRates())
         return;

      double HighestPrice=iHighest(m_symbol.Name(),Period(),MODE_HIGH,80,0);
      if(HighestPrice==0.0)
         return;
      double LowestPrice=iLowest(m_symbol.Name(),Period(),MODE_LOW,80,0);
      if(LowestPrice==0.0)
         return;

      Comment(TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),": ","\n",
              "Highest price ",DoubleToString(HighestPrice,m_symbol.Digits()),"\n",
              "Lowest price ",DoubleToString(LowestPrice,m_symbol.Digits()));

      double ask=m_symbol.Ask();
      double bid=m_symbol.Bid();
      double stops_level=m_symbol.StopsLevel()*m_symbol.Point();

      if(HighestPrice>ask+stops_level && !CompareDoubles(HighestPrice,ask+stops_level,m_symbol.Digits()))
        {
         //--- pending buy stop
         double sl=(InpStopLoss==0)?0.0:HighestPrice-ExtStopLoss;
         double tp=(InpTakeProfit==0)?0.0:HighestPrice+ExtTakeProfit;
         if(m_trade.BuyStop(InpLots,HighestPrice,m_symbol.Name(),
            m_symbol.NormalizePrice(sl),
            m_symbol.NormalizePrice(tp),
            ORDER_TIME_SPECIFIED,validity))
            Print("BUY_STOP - > true. ticket of order = ",m_trade.ResultOrder());
         else
            Print("BUY_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
                  ", ticket of order: ",m_trade.ResultOrder());
        }

      if(LowestPrice<bid-stops_level && !CompareDoubles(LowestPrice,bid-stops_level,m_symbol.Digits()))
        {
         //--- pending buy stop
         double sl=(InpStopLoss==0)?0.0:LowestPrice+ExtStopLoss;
         double tp=(InpTakeProfit==0)?0.0:LowestPrice-ExtTakeProfit;
         if(m_trade.SellStop(InpLots,LowestPrice,m_symbol.Name(),
            m_symbol.NormalizePrice(sl),
            m_symbol.NormalizePrice(tp),
            ORDER_TIME_SPECIFIED,validity))
            Print("SELL_STOP - > true. ticket of order = ",m_trade.ResultOrder());
         else
            Print("SELL_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
                  ", ticket of order: ",m_trade.ResultOrder());
        }
     }
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   double res=0.0;
   int losses=0.0;
//--- get transaction type as enumeration value 
   ENUM_TRADE_TRANSACTION_TYPE type=trans.type;
//--- if transaction is result of addition of the transaction in history
   if(type==TRADE_TRANSACTION_DEAL_ADD)
     {
      long     deal_ticket       =0;
      long     deal_order        =0;
      long     deal_time         =0;
      long     deal_time_msc     =0;
      long     deal_type         =-1;
      long     deal_entry        =-1;
      long     deal_magic        =0;
      long     deal_reason       =-1;
      long     deal_position_id  =0;
      double   deal_volume       =0.0;
      double   deal_price        =0.0;
      double   deal_commission   =0.0;
      double   deal_swap         =0.0;
      double   deal_profit       =0.0;
      string   deal_symbol       ="";
      string   deal_comment      ="";
      string   deal_external_id  ="";
      if(HistoryDealSelect(trans.deal))
        {
         deal_ticket       =HistoryDealGetInteger(trans.deal,DEAL_TICKET);
         deal_order        =HistoryDealGetInteger(trans.deal,DEAL_ORDER);
         deal_time         =HistoryDealGetInteger(trans.deal,DEAL_TIME);
         deal_time_msc     =HistoryDealGetInteger(trans.deal,DEAL_TIME_MSC);
         deal_type         =HistoryDealGetInteger(trans.deal,DEAL_TYPE);
         deal_entry        =HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
         deal_magic        =HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
         deal_reason       =HistoryDealGetInteger(trans.deal,DEAL_REASON);
         deal_position_id  =HistoryDealGetInteger(trans.deal,DEAL_POSITION_ID);

         deal_volume       =HistoryDealGetDouble(trans.deal,DEAL_VOLUME);
         deal_price        =HistoryDealGetDouble(trans.deal,DEAL_PRICE);
         deal_commission   =HistoryDealGetDouble(trans.deal,DEAL_COMMISSION);
         deal_swap         =HistoryDealGetDouble(trans.deal,DEAL_SWAP);
         deal_profit       =HistoryDealGetDouble(trans.deal,DEAL_PROFIT);

         deal_symbol       =HistoryDealGetString(trans.deal,DEAL_SYMBOL);
         deal_comment      =HistoryDealGetString(trans.deal,DEAL_COMMENT);
         deal_external_id  =HistoryDealGetString(trans.deal,DEAL_EXTERNAL_ID);
        }
      else
         return;
      //if(deal_reason!=-1)
      //   DebugBreak();
      if(deal_symbol==Symbol() && deal_magic==m_magic)
         if(deal_entry==DEAL_ENTRY_IN)
            if((ENUM_DEAL_TYPE)deal_type==DEAL_TYPE_BUY || (ENUM_DEAL_TYPE)deal_type==DEAL_TYPE_SELL)
               DeleteAllOrders();
     }
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates(void)
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print("RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=m_symbol.LotsMin();
   if(volume<min_volume)
     {
      error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }
//--- maximal allowed volume of trade operations
   double max_volume=m_symbol.LotsMax();
   if(volume>max_volume)
     {
      error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }
//--- get minimal step of volume changing
   double volume_step=m_symbol.LotsStep();
   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                     volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Checks if the specified filling mode is allowed                  | 
//+------------------------------------------------------------------+ 
bool IsFillingTypeAllowed(int fill_type)
  {
//--- Obtain the value of the property that describes allowed filling modes 
   int filling=m_symbol.TradeFillFlags();
//--- Return true, if mode fill_type is allowed 
   return((filling & fill_type)==fill_type);
  }
//+------------------------------------------------------------------+ 
//| Get Time for specified bar index                                 | 
//+------------------------------------------------------------------+ 
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[1];
   datetime time=0; // D'1970.01.01 00:00:00'
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0)
      time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int func_Symbol2Val(string symbol)
  {
   if(StringFind(symbol,"AUDUSD",0)!=-1)
      return(01);
   if(StringFind(symbol,"CHFJPY",0)!=-1)
      return(10);
   if(StringFind(symbol,"EURAUD",0)!=-1)
      return(10);
   if(StringFind(symbol,"EURCAD",0)!=-1)
      return(11);
   if(StringFind(symbol,"EURCHF",0)!=-1)
      return(12);
   if(StringFind(symbol,"EURGBP",0)!=-1)
      return(13);
   if(StringFind(symbol,"EURJPY",0)!=-1)
      return(14);
   if(StringFind(symbol,"EURUSD",0)!=-1)
      return(15);
   if(StringFind(symbol,"GBPCHF",0)!=-1)
      return(20);
   if(StringFind(symbol,"GBPJPY",0)!=-1)
      return(21);
   if(StringFind(symbol,"GBPUSD",0)!=-1)
      return(22);
   if(StringFind(symbol,"USDCAD",0)!=-1)
      return(40);
   if(StringFind(symbol,"USDCHF",0)!=-1)
      return(41);
   if(StringFind(symbol,"USDJPY",0)!=-1)
      return(42);
   if(StringFind(symbol,"GOLD",0)!=-1)
      return(90);
//---
   Comment("unexpected Symbol");
   return(0);
  }
//+------------------------------------------------------------------+
//| Return lowest price                                              |
//+------------------------------------------------------------------+
double iLowest(string symbol,
               ENUM_TIMEFRAMES timeframe,
               int type,
               int count=WHOLE_ARRAY,
               int start=0)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   if(start<0)
      return(0.0);
   if(count<=0)
      count=Bars(symbol,timeframe);
   if(type==MODE_LOW)
     {
      double Low[];
      if(CopyLow(symbol,timeframe,start,count,Low)!=count)
         return(0.0);
      int index_min=ArrayMinimum(Low);
      return(Low[index_min]);
     }
//---
   return(0.0);
  }
//+------------------------------------------------------------------+
//| Return highest price                                             |
//+------------------------------------------------------------------+
double iHighest(string symbol,
                ENUM_TIMEFRAMES timeframe,
                int type,
                int count=WHOLE_ARRAY,
                int start=0)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   if(start<0)
      return(0.0);
   if(count<=0)
      count=Bars(symbol,timeframe);
   if(type==MODE_HIGH)
     {
      double High[];
      if(CopyHigh(symbol,timeframe,start,count,High)!=count)
         return(0.0);
      int index_max=ArrayMaximum(High);
      return(High[index_max]);
     }
//---
   return(0.0);
  }
//+------------------------------------------------------------------+
//| Compare doubles                                                  |
//+------------------------------------------------------------------+
bool CompareDoubles(double number1,double number2,int digits)
  {
   if(NormalizeDouble(number1-number2,digits)==0)
      return(true);
   else
      return(false);
  }
//+------------------------------------------------------------------+
//| Trailing                                                         |
//+------------------------------------------------------------------+
void Trailing()
  {
   if(InpTrailingStop==0)
      return;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtTrailingStop+ExtTrailingStep)
                  if(m_position.StopLoss()<m_position.PriceCurrent()-(ExtTrailingStop+ExtTrailingStep))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()-ExtTrailingStop),
                        m_position.TakeProfit()))
                        Print("Modify BUY ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                     continue;
                    }
              }
            else
              {
               if(m_position.PriceOpen()-m_position.PriceCurrent()>ExtTrailingStop+ExtTrailingStep)
                  if((m_position.StopLoss()>(m_position.PriceCurrent()+(ExtTrailingStop+ExtTrailingStep))) || 
                     (m_position.StopLoss()==0))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()+ExtTrailingStop),
                        m_position.TakeProfit()))
                        Print("Modify SELL ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
              }

           }
  }
//+------------------------------------------------------------------+
//| Delete all pending orders                                        |
//+------------------------------------------------------------------+
void DeleteAllOrders()
  {
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            m_trade.OrderDelete(m_order.Ticket());
  }
//+------------------------------------------------------------------+

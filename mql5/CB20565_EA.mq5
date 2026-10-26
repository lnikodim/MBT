//+------------------------------------------------------------------+
//|                          Absorption(barabashkakvn's edition).mq5 |
//|                              Copyright © 2018, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
#property version   "1.002"
//---
#define MODE_LOW 1
#define MODE_HIGH 2
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\OrderInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
COrderInfo     m_order;                      // pending orders object
//--- input parameters
input double   InpLots              = 0.1;   // Lots
input ushort   InpTakeProfitBuy     = 10;    // Take Profit Buy
input ushort   InpTakeProfitSell    = 10;    // Take Profit Sell 
input ushort   InpTrailingStop      = 5;     // Trailing Stop (in pips)
input ushort   InpTrailingStep      = 5;     // Trailing Step (in pips)
input ushort   InpIndent            = 1;     // Indent from high or low
input int      Max_Search           = 10;    // Number of bars to search for price extremes
input int      OrderExp             = 8;     // Expiration a pending order in hours
input ulong    MagicType1           = 11111; // Magic number for signal 1
input ulong    MagicType2           = 22222; // Magic number for signal 2
input ushort   InpBreakeven         = 1;     // Breakeven (in pips) ("0" -> parameter "Breakeven" is off)
input ushort   InpBreakevenProfit   = 10;    // Breakeven profit (in pips)
//---
ulong          m_magic=0;                    // magic number
ulong          m_slippage=10;                // slippage
//---

double         ExtTakeProfitBuy=0.0;
double         ExtTakeProfitSell=0.0;
double         ExtTrailingStop=0.0;
double         ExtTrailingStep=0.0;
double         ExtIndent=0.0;
double         ExtBreakeven=0.0;
double         ExtBreakevenProfit=0.0;

double         m_adjusted_point;             // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(InpTrailingStop!=0 && InpTrailingStep==0)
     {
      Alert(__FUNCTION__," ERROR: Trailing is not possible: the parameter \"Trailing Step\" is zero!");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpBreakeven!=0 && InpBreakevenProfit==0)
     {
      Alert(__FUNCTION__," ERROR: Breakeven is not possible: the parameter \"Breakeven profit\" is zero!");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpBreakeven>=InpBreakevenProfit)
     {
      Alert(__FUNCTION__," ERROR: \"Breakeven\" can not be greater than or equal to \"Breakeven profit\"!");
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();

   string err_text="";
   if(!CheckVolumeValue(InpLots,err_text))
     {
      Print(__FUNCTION__,", ERROR: ",err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
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

   ExtTakeProfitBuy     = InpTakeProfitBuy   * m_adjusted_point;
   ExtTakeProfitSell    = InpTakeProfitSell  * m_adjusted_point;
   ExtTrailingStop      = InpTrailingStop    * m_adjusted_point;
   ExtTrailingStep      = InpTrailingStep    * m_adjusted_point;
   ExtIndent            = InpIndent          * m_adjusted_point;
   ExtBreakeven         = InpBreakeven       * m_adjusted_point;
   ExtBreakevenProfit   = InpBreakevenProfit * m_adjusted_point;
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
//---
   StopLossInBreakeven();
//--- Checking for orders and positions
   bool exist_pos1=false,  exist_ord1=false;
   bool exist_pos2=false,  exist_ord2=false;
   bool exist_pos3=false,  exist_ord3=false;
   ExistPositionsAndPendingOrders(exist_pos1,exist_ord1,MagicType1,
                                  exist_pos2,exist_ord2,MagicType2);
//--- Order placing
   int signal_1=0;   double high_1=0.0;   double low_1=0.0;
   int signal_2=0;   double high_2=0.0;   double low_2=0.0;
   if(!Signals(signal_1,high_1,low_1,signal_2,high_2,low_2))
      return;
   if(!exist_pos1 && !exist_ord1 && signal_1!=0)
     {
      double price= high_2 + ExtIndent;
      double sl   = low_2  - ExtIndent;
      double tp   = price  + ExtTakeProfitBuy;
      m_trade.SetExpertMagicNumber(MagicType1);
      if(m_trade.BuyStop(InpLots,price,m_symbol.Name(),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp),ORDER_TIME_SPECIFIED,TimeCurrent()+3600*OrderExp,"signal 1"))
         Print("BUY_STOP - > true. ticket of order = ",m_trade.ResultOrder());
      else
         Print("BUY_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
               ", ticket of order: ",m_trade.ResultOrder());

      price= low_2  - ExtIndent;
      sl   = high_2 + ExtIndent;
      tp   = price  - ExtTakeProfitSell;
      m_trade.SetExpertMagicNumber(MagicType2);
      if(m_trade.SellStop(InpLots,price,m_symbol.Name(),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp),ORDER_TIME_SPECIFIED,TimeCurrent()+3600*OrderExp,"signal 1"))
         Print("SELL_STOP - > true. ticket of order = ",m_trade.ResultOrder());
      else
         Print("SELL_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
               ", ticket of order: ",m_trade.ResultOrder());

      return;
     }

   if(!exist_pos2 && !exist_ord2 && signal_2!=0)
     {
      double price= high_1 + ExtIndent;
      double sl   = low_1  - ExtIndent;
      double tp   = price  + ExtTakeProfitBuy;
      m_trade.SetExpertMagicNumber(MagicType1);
      if(m_trade.BuyStop(InpLots,price,m_symbol.Name(),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp),ORDER_TIME_SPECIFIED,TimeCurrent()+3600*OrderExp,"signal 2"))
         Print("BUY_STOP - > true. ticket of order = ",m_trade.ResultOrder());
      else
         Print("BUY_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
               ", ticket of order: ",m_trade.ResultOrder());

      price= low_1  - ExtIndent;
      sl   = high_1 + ExtIndent;
      tp   = price  - ExtTakeProfitSell;
      m_trade.SetExpertMagicNumber(MagicType2);
      if(m_trade.SellStop(InpLots,price,m_symbol.Name(),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp),ORDER_TIME_SPECIFIED,TimeCurrent()+3600*OrderExp,"signal 2"))
         Print("SELL_STOP - > true. ticket of order = ",m_trade.ResultOrder());
      else
         Print("SELL_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
               ", ticket of order: ",m_trade.ResultOrder());

      return;
     }

   Trailing();
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
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
      if(deal_reason!=-1)
         DebugBreak();
      if(deal_symbol==m_symbol.Name() && (deal_magic==MagicType1 || deal_magic==MagicType2))
         if(deal_entry==DEAL_ENTRY_IN)
           {
            if(deal_type==DEAL_TYPE_BUY)
               DeleteOrders(ORDER_TYPE_SELL_STOP);
            else if(deal_type==DEAL_TYPE_SELL)
               DeleteOrders(ORDER_TYPE_BUY_STOP);
           }
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
// double max_volume=m_symbol.LotsMax();
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
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
//| Stop Loss in a breakeven                                         |
//+------------------------------------------------------------------+
void StopLossInBreakeven()
  {
   if(InpBreakeven==0)
      return;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && (m_position.Magic()==MagicType1 || m_position.Magic()==MagicType2))
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.StopLoss()<m_position.PriceOpen() || m_position.StopLoss()==0.0)
                  if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtBreakevenProfit)
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceOpen()+ExtBreakeven),
                        m_position.TakeProfit()))
                        Print("Breakeven BUY ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
              }
            else
              {
               double pos_sl=m_position.StopLoss();
               double pos_po=m_position.PriceOpen();
               double pos_pc=m_position.PriceCurrent();
               if(m_position.StopLoss()>m_position.PriceOpen() || m_position.StopLoss()==0.0)
                  if(m_position.PriceOpen()-m_position.PriceCurrent()>ExtBreakevenProfit)
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceOpen()-ExtBreakeven),
                        m_position.TakeProfit()))
                        Print("Breakeven SELL ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
              }

           }
  }
//+------------------------------------------------------------------+
//| Compare doubles                                                  |
//+------------------------------------------------------------------+
bool CompareDoubles(double number1,double number2,int digits)
  {
   digits--;
   if(digits<0)
      digits=0;
   if(NormalizeDouble(number1-number2,digits)==0)
      return(true);
   else
      return(false);
  }
//+------------------------------------------------------------------+
//| Exist positions and pending orders                               |
//+------------------------------------------------------------------+
void ExistPositionsAndPendingOrders(bool &pos_1,bool &ord_1,const ulong magic_1,
                                    bool &pos_2,bool &ord_2,const ulong magic_2)
  {
//--- initialization
   pos_1=false;   ord_1=false;
   pos_2=false;   ord_2=false;
//---
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name())
           {
            if(m_position.Magic()==magic_1)
               pos_1=true;
            if(m_position.Magic()==magic_2)
               pos_2=true;
            //---
            if(pos_1 && pos_2)
               break;
           }
//---
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i)) // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name())
           {
            if(m_order.Magic()==magic_1)
               ord_1=true;
            if(m_order.Magic()==magic_2)
               ord_2=true;
            //---
            if(ord_1 && ord_2)
               break;
           }
  }
//+------------------------------------------------------------------+
//| Signals                                                          |
//+------------------------------------------------------------------+
bool Signals(int &signal_1,double &high_1,double &low_1,int &signal_2,double &high_2,double &low_2)
  {
   signal_1=0; high_1=0.0; low_1=0.0;
   signal_2=0; high_2=0.0; low_2=0.0;

   int lowest=iLowest(m_symbol.Name(),Period(),MODE_LOW,Max_Search,0);
   if(lowest==-1)
      return(false);

   int highest=iHighest(m_symbol.Name(),Period(),MODE_HIGH,Max_Search,0);
   if(highest==-1)
      return(false);

   high_2=iHigh(2);
   if(high_2==0.0)
      return(false);

   high_1=iHigh(1);
   if(high_1==0.0)
      return(false);

   low_2=iLow(2);
   if(low_2==0.0)
      return(false);

   low_1=iLow(1);
   if(low_1==0.0)
      return(false);

//--- pattern Absorption in bar #2
   if(lowest==2 && high_2>high_1 && low_2<low_1)
     {
      signal_1=1;
     }
   else if(highest==2 && high_2>high_1 && low_2<low_1)
     {
      signal_1=-1;
     }
   else
      signal_1=0;
//--- pattern Absorption in bar #1
   if(lowest==1 && high_1>high_2 && low_1<low_2)
     {
      signal_2=1;
     }
   else if(highest==1 && high_1>high_2 && low_1<low_2)
     {
      signal_2=-1;
     }
   else
      signal_2=0;
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Lowest                                                           |
//+------------------------------------------------------------------+
int iLowest(string symbol,
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
      return(-1);
   if(count<=0)
      count=Bars(symbol,timeframe);
   if(type==MODE_LOW)
     {
      double Low[];
      ArraySetAsSeries(Low,true);
      int copied=CopyLow(symbol,timeframe,start,count,Low);
      if(copied==-1 || copied!=count)
         return(-1);
      return(ArrayMinimum(Low));
     }
//---
   return(-1);
  }
//+------------------------------------------------------------------+
//| Highest                                                          |
//+------------------------------------------------------------------+
int iHighest(string symbol,
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
      return(-1);
   if(count<=0)
      count=Bars(symbol,timeframe);
   if(type==MODE_HIGH)
     {
      double High[];
      ArraySetAsSeries(High,true);
      int copied=CopyHigh(symbol,timeframe,start,count,High);
      if(copied==-1 || copied!=count)
         return(-1);
      return(ArrayMinimum(High));
     }
//---
   return(-1);
  }
//+------------------------------------------------------------------+ 
//| Get the High for specified bar index                             | 
//+------------------------------------------------------------------+ 
double iHigh(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   double High[1];
   double high=0.0;
   int copied=CopyHigh(symbol,timeframe,index,1,High);
   if(copied>0)
      high=High[0];
   return(high);
  }
//+------------------------------------------------------------------+ 
//| Get Low for specified bar index                                  | 
//+------------------------------------------------------------------+ 
double iLow(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   double Low[1];
   double low=0.0;
   int copied=CopyLow(symbol,timeframe,index,1,Low);
   if(copied>0)
      low=Low[0];
   return(low);
  }
//+------------------------------------------------------------------+
//| Delete Orders                                                    |
//+------------------------------------------------------------------+
void DeleteOrders(const ENUM_ORDER_TYPE order_type)
  {
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && (m_order.Magic()==MagicType1 || m_order.Magic()==MagicType2))
            if(m_order.OrderType()==order_type)
               m_trade.OrderDelete(m_order.Ticket());
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
         if(m_position.Symbol()==m_symbol.Name() && (m_position.Magic()==MagicType1 || m_position.Magic()==MagicType2))
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtTrailingStop+ExtTrailingStep)
                  if(m_position.StopLoss()<m_position.PriceCurrent()-(ExtTrailingStop+ExtTrailingStep))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()-ExtTrailingStop),
                        m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
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
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
              }

           }
  }
//+------------------------------------------------------------------+

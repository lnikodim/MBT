//+------------------------------------------------------------------+
//|                                         Aeron JJN Scalper EA.mq5 |
//|                              Copyright © 2018, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
#property version   "1.000"
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
input double   InpLots           = 0.1;      // Lots
input ushort   InpTrailingStop   = 5;        // Trailing Stop (in pips)
input ushort   InpTrailingStep   = 5;        // Trailing Step (in pips)
input uchar    InpResetTime      = 10;       // Reset time (minutes)
input ushort   DojiDiff1         = 10;       // Doji diff 1
input ushort   DojiDiff2         = 4;        // Doji diff 2
input ulong    m_magic           = 1237322;  // magic number
//---
ulong          m_slippage=10;                // slippage

double         ExtTrailingStop=0.0;
double         ExtTrailingStep=0.0;
double         ExtDojiDiff1=0.0;
double         ExtDojiDiff2=0.0;

int            handle_iATR;                  // variable for storing the handle of the iATR indicator 

double         m_adjusted_point;             // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
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

   ExtTrailingStop   = InpTrailingStop * m_adjusted_point;
   ExtTrailingStep   = InpTrailingStep * m_adjusted_point;
   ExtDojiDiff1      = DojiDiff1       * m_adjusted_point;
   ExtDojiDiff2      = DojiDiff2       * m_adjusted_point;
//--- create handle of the indicator iATR
   handle_iATR=iATR(m_symbol.Name(),Period(),8);
//--- if the handle is not created 
   if(handle_iATR==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iATR indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
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
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
//---
   int lastbullishindex=0;
   int lastbearishindex=0;
   double lastbearishopen=0;
   double lastbullishopen=0;
   double Atr=0.0;
//---
   int count_buys=0;
   int count_sells=0;
   int count_buy_stop=0;
   int count_sell_stop=0;
   CalculatePositions(count_buys,count_sells);
   CalculateOrders(count_buy_stop,count_sell_stop);

   if(count_buys+count_buy_stop==0 || count_sells+count_sell_stop==0)
     {
      if(!RefreshRates())
         return;
      Atr=iATRGet(1);
      if(Atr==0.0)
         return;
      datetime time_current=TimeCurrent();
      string            symbol_name=m_symbol.Name();  // symbol name 
      ENUM_TIMEFRAMES   timeframe=Period();           // period 
      int               start_pos=1;                  // start position 
      int               count=100;                     // data count to copy 
      MqlRates          rates[];                      // target array to copy 

      ArraySetAsSeries(rates,true);
      int copied=CopyRates(symbol_name,timeframe,start_pos,count,rates);
      if(copied!=count)
         return;
      //---
      if(rates[0].close>rates[0].open && rates[1].open-rates[1].close>ExtDojiDiff1) // BUY
        {
         for(int i=0;i<copied;i++) // search for the last bearish candle
           {
            if(rates[i].close<rates[i].open && rates[i].open-rates[i].close>ExtDojiDiff2)
              {
               lastbearishopen=rates[i].open;
               lastbearishindex=i;
               break;
              }
           }
        }
      else if(rates[0].close<rates[0].open && rates[1].close-rates[1].open>ExtDojiDiff1) // SELL
        {
         for(int i=0;i<copied;i++) // search for the last bullish candle
           {
            if(rates[i].close>rates[i].open && rates[i].close-rates[i].open>ExtDojiDiff2)
              {
               lastbullishopen=rates[i].open;
               lastbullishindex=i;
               break;
              }
           }
        }
      else // NO TRADE
        {
         lastbullishindex=0;
         lastbearishindex=0;
         lastbearishopen=0.0;
         lastbullishopen=0.0;
        }
      //--- pending buy stop
      if(count_buys+count_buy_stop==0)
        {
         double ask,stops_level;
         //---
         ask=m_symbol.Ask();
         stops_level=m_symbol.StopsLevel()*m_symbol.Point();
         if(lastbearishopen!=0.0)
           {
            if(lastbearishopen>ask+stops_level)
              {
               //--- 
               if(m_trade.BuyStop(InpLots,lastbearishopen,m_symbol.Name(),
                  lastbearishopen-Atr,lastbearishopen+Atr,
                  ORDER_TIME_SPECIFIED,time_current+InpResetTime*60))
                  Print("BUY_STOP - > true. ticket of order = ",m_trade.ResultOrder());
               else
                  Print("BUY_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
                        ", description of Retcode: ",m_trade.ResultRetcodeDescription());
              }
           }
        }
      //--- pending sell stop
      if(count_sells+count_sell_stop==0)
        {
         double bid,stops_level;
         //---
         bid=m_symbol.Bid();
         stops_level=m_symbol.StopsLevel()*m_symbol.Point();
         if(lastbullishopen!=0.0)
           {
            if(lastbullishopen<bid-stops_level)
              {
               //--- 
               if(m_trade.SellStop(InpLots,lastbullishopen,m_symbol.Name(),
                  lastbullishopen+Atr,lastbullishopen-Atr,
                  ORDER_TIME_SPECIFIED,time_current+InpResetTime*60))
                  Print("SELL_STOP - > true. ticket of order = ",m_trade.ResultOrder());
               else
                  Print("SELL_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
                        ", description of Retcode: ",m_trade.ResultRetcodeDescription());
              }
           }
        }
     }
//---
   if(count_buys+count_sell_stop!=0)
      Trailing();
//---
   return;
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//---

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
      symbol=Symbol();
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
//| Get value of buffers for the iATR                                |
//+------------------------------------------------------------------+
double iATRGet(const int index)
  {
   double ATR[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iATR array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iATR,0,index,1,ATR)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iATR indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(ATR[0]);
  }
//+------------------------------------------------------------------+
//| Calculate positions Buy and Sell                                 |
//+------------------------------------------------------------------+
void CalculatePositions(int &count_buys,int &count_sells)
  {
   count_buys=0;
   count_sells=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
               count_buys++;

            else if(m_position.PositionType()==POSITION_TYPE_SELL)
               count_sells++;
           }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Calculate pending orders                                         |
//+------------------------------------------------------------------+
void CalculateOrders(int &count_buy_stop,int &count_sell_stop)
  {
   count_buy_stop=0;
   count_sell_stop=0;

   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
           {
            if(m_order.OrderType()==ORDER_TYPE_BUY_STOP)
               count_buy_stop++;
            else if(m_order.OrderType()==ORDER_TYPE_SELL_STOP)
               count_sell_stop++;
           }
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
                        Print("Modify ",m_position.Ticket(),
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
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
              }

           }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                     Kijun Sen Robot(barabashkakvn's edition).mq5 |
//|                   Copyright ® 2005 Noam Koren (noamko@shani.net) |
//|                                         http://www.metaquotes.ru |
//+------------------------------------------------------------------+
//+-------------------------------------------------------------------------------------------------------------+
//| Based on Akash discussion at Moneytech ("Great technique for beginners")                                    |
//|                                                                                                             |
//| Disclaimer :   Distributed for forward testing purposes.                                                    |
//|                This expert was never tested on a live account - use at your own risk!                       |
//|                In other words - DO NOT USE ON A LIVE ACCOUNT !                                              |
//|                                                                                                             |
//| Attach to 30 Minute chart                                                                                   |
//|                                                                                                             |
//|  $Log: KSRobot.mq4,v $                                                                                      |
//|  Revision 1.5  2005/10/18 11:10:09  noam                                                                    |
//|  1) Added alerts                                                                                            |
//|                                                                                                             |
//|  2) Modified S/L rules to reduce average S/L size - if a bar closes with MA in the wrong direction          |
//|     exit if B/E was not hit yet.                                                                            |
//|                                                                                                             |
//|  3) Modified Entry rule - Wait for BID to cross KS for Long and ASK to cross down for Short.                |
//|     This helps to filter out faulty signals.                                                                |
//|                                                                                                             |
//|  4) Modified Entry rule - only enter if KS is Horizontal OR in the same direction of entry.                 |
//|                                                                                                             |
//| Revision 1.4  2005/10/08 18:19:58  noam                                                                     |
//|  1) Added slope: allows filtering out trades if the slope of KS line is too vertical (too = defined by user)|
//|  2) Added optimized values per currency. This can be overrider by setting UseOptimizedValues to false.      |
//|  3) Added a comment to provide some information to the user while the expert is attached.                   |
//|                                                                                                             |
//| Experimental                                                                                                |
//|   E1) Added two experimental stop loss tactics (not used unless by default):                                |
//|   a) PSAR                                                                                                |
//|   b) Exit if not at BE after X bars                                                                      |
//|                                                                                                             |
//|   Revision 1.3  2005/09/21 01:00:47  noam                                                                   |
//|   Use limit order / market order depending on current price                                                 |
//|   Do not clear cross value until order is sent                                                              |
//|   Added some printouts                                                                                      |
//|                                                                                                             |
//|   Revision 1.2  2005/09/20 17:11:12  noam                                                                   |
//|   Added disclaimer                                                                                          |
//|   Added price normalization                                                                                 |
//|   Adjusted time limits to fit MT4 time                                                                      |
//|                                                                                                             |
//|   Revision 1.1  2005/09/19 20:34:57  noam                                                                   |
//|   Initial Kijun Sen Robot version                                                                           |
//|   Backtested on 30M GBP/USD                                                                                 |
//|                                                                                                             | 
//| 1) Find a way to improve profit taking - TS is good but misses much of trendy moves. Maybe                  |
//|    switch to EMA signal once X pips are secure?                                                             |
//|                                                                                                             |
//| 2) Find out why entering only once per bar hits performance.                                                |
//|                                                                                                             |
//| 3) Add 2% money management rule.                                                                            |
//+-------------------------------------------------------------------------------------------------------------+
#property copyright "Noam Koren"
#property version   "1.001"
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\OrderInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
COrderInfo     m_order;                      // pending orders object
/* expert specific parameters */
#define EXPERT_STRING   "Kijun Sen Robot"
#define UP       1
#define DOWN    -1
#define NEUTRAL  0
/*  
    Optimized results 
    GBP/USD:
    4.38	1000.00	8.38%	ExtStopLoss=50 ExtBreakEven=9 ExtTrailingStop=10 ExtMAfilter=6 ExtTakeProfit=120
    EUR/USD:
    2.68	1520.00	12.24%	ExtStopLoss=60 ExtBreakEven=9 ExtTrailingStop=6    ExtMAfilter=6 ExtTakeProfit=120      
*/
int      MaxOpenPositions=1;
/* Default parameters. */
ushort         InpTakeProfit     =120;  /* default 120 */
input ushort   InpStopLoss       =50;   /* 50  very imporant to allow for a substaintial movement in the other direction */
input ushort   InpBreakEven      =9;    /* default = 9 */
input ushort   InpTrailingStop   =10;   /* default 10 */
input int      InpMAfilter=6;    /* MA must be at least 6 pips away from KS in order to be valid */
input bool     UseOptimizedValues=true;
/* MM */
input double   Lots=1;
//----
int TenkanSen          =6;
int KijunSen           =12;
int Senkou             =24;
/* globals */
double lastbid         =0.0;
double lastask         =0.0;
double longcross       =0.0;
double shortcross      =0.0;
double longentry       =0.0;
double shortentry      =0.0;
int daystart           =7; /* 5AM GMT */
int dayend             =19;/* 5PM GMT */
int MAdir              =NEUTRAL;
int precision          =4;
datetime lastbar       =0;
bool newbar            =false;
//---
ulong          m_magic=13;
double         ExtTakeProfit=0.0;
double         ExtStopLoss=0.0;
double         ExtBreakEven=0.0;
double         ExtTrailingStop=0.0;
int            ExtMAfilter=0;
ENUM_ACCOUNT_MARGIN_MODE m_margin_mode;
double         m_adjusted_point;             // point value adjusted for 3 or 5 points
int            handle_iIchimoku;             // variable for storing the handle of the iIchimoku indicator 
int            handle_iMA;                   // variable for storing the handle of the iMA indicator 
int            handle_iSAR;                  // variable for storing the handle of the iSAR indicator 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetMarginMode();
   if(!IsHedging())
     {
      Print("Hedging only!");
      return(INIT_FAILED);
     }
/* make sure that the char is valid */
   if(Bars(Symbol(),Period())<100)
     {
      Print("Invalid chart: less than 100 bars!");
      return(INIT_FAILED);
     }
//---
   m_symbol.Name(Symbol());                  // sets symbol name
   if(!RefreshRates())
     {
      Print("Error RefreshRates. Bid=",DoubleToString(m_symbol.Bid(),Digits()),
            ", Ask=",DoubleToString(m_symbol.Ask(),Digits()));
      return(INIT_FAILED);
     }
//---
   m_trade.SetExpertMagicNumber(m_magic);    // sets magic number
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;
   ExtTakeProfit     = ExtTakeProfit* m_adjusted_point;
   ExtStopLoss       = ExtStopLoss  * m_adjusted_point;
   ExtBreakEven      = ExtBreakEven * m_adjusted_point;
   ExtTrailingStop   = ExtBreakEven * m_adjusted_point;
   ExtMAfilter       = InpMAfilter;
//--- create handle of the indicator iIchimoku
   handle_iIchimoku=iIchimoku(m_symbol.Name(),Period(),TenkanSen,KijunSen,Senkou);
//--- if the handle is not created 
   if(handle_iIchimoku==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iIchimoku indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA=iMA(m_symbol.Name(),Period(),20,0,MODE_LWMA,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iMA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iSAR
   handle_iSAR=iSAR(m_symbol.Name(),Period(),0.02,0.2);
//--- if the handle is not created 
   if(handle_iSAR==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iSAR indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//---
   if(UseOptimizedValues==true)
     {
/* set parameters based on pair */
      if(Symbol()=="GBPUSD")
        {
         ExtStopLoss=50; ExtBreakEven=9; ExtTrailingStop=10; ExtMAfilter=6;
        }
      if(Symbol()=="EURUSD")
        {
         ExtStopLoss=60; ExtBreakEven=9; ExtTrailingStop=6;  ExtMAfilter=6;
        }
     }
   precision=m_symbol.Digits();
   lastbar=iTime(m_symbol.Name(),Period(),0);
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
//|                                                                  |
//+------------------------------------------------------------------+
int OpenPosition()
  {
   double KS      =iIchimokuGet(KIJUNSEN_LINE, 0);
   double KS1     =iIchimokuGet(KIJUNSEN_LINE, 1);
   double KS2     =iIchimokuGet(KIJUNSEN_LINE, 2);
   double Ema20   =iMAGet(0);
   double PEma20  =iMAGet(1);
   double PSAR    =iSARGet(0); /* fast parabolic for tight exits */
//---
   if(!RefreshRates())
      return(0);
//---
   if(lastbid==0.0)
      lastbid=m_symbol.Bid();
   if(lastask==0.0)
      lastask=m_symbol.Ask();
/* Make sure the time is right */
   MqlDateTime str1;
   TimeToStruct(TimeCurrent(),str1);
   if(str1.hour<daystart || str1.hour>dayend-1)
      return(0);
/* KS cross */
   if(iOpen(m_symbol.Name(),Period(),0)<KS && lastbid<KS && m_symbol.Bid()>KS && longcross==0 && KS>=KS2)
     {
/* the cross is only interesting if the KS line is above the MA  */
      if(Ema20<KS-ExtMAfilter*m_adjusted_point)
        {
         longcross=KS;
         shortcross=0;
        }
     }
   if(iOpen(m_symbol.Name(),Period(),0)>KS && lastask>KS && m_symbol.Ask()<KS && shortcross==0 && KS<=KS2)
     {
/* the cross is only interesting if the KS line is under the MA  */
      if(Ema20>KS+ExtMAfilter*m_adjusted_point)
        {
         shortcross=KS;
         longcross=0;
        }
     }
/* check MA direction */
   if(PEma20<Ema20)
     {
      MAdir=UP;
     }
   if(PEma20>Ema20)
     {
      MAdir=DOWN;
     }
/* once the MA is pointing in the right direction set the the entry price to be the current KS */
   if(MAdir==UP && longcross!=0)// && longentry==0)
     {
      longentry=NormalizeDouble(KS,precision);
      return(1);
     }
/* once the MA is pointing in the right direction set the the entry price to be the current KS */
   if(MAdir==DOWN && shortcross!=0)// && shortentry==0)
     {
      shortentry=NormalizeDouble(KS,precision);
      return(-1);
     }
   lastbid=m_symbol.Bid();
   lastask=m_symbol.Ask();
//---
   return(0);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ClosePosition()
  {
   double PEma20  =iMAGet(1);
   double PPEma20 =iMAGet(2);
//----
   if(m_position.PositionType()==POSITION_TYPE_BUY)
     {
      if(newbar && PEma20<PPEma20 && m_position.StopLoss()<m_position.PriceOpen())
        {
         return(1);
        }
     }
   if(m_position.PositionType()==POSITION_TYPE_SELL)
     {
      if(newbar && PEma20>PPEma20 && m_position.StopLoss()>m_position.PriceOpen())
        {
         return(-1);
        }
     }
//----
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   int action=0;
   ENUM_ORDER_TYPE method=-1;
   double hardstop;
   datetime ticketexpiration=0;

   MqlDateTime str1;
   TimeToStruct(TimeCurrent(),str1);

   if(str1.hour<daystart || str1.hour>dayend-1)
     {
      Comment("\nTrading halted. (will start again at ",daystart," AM )\n");
     }
   else
     {
      Comment("\nExpert is active. (will halt at ",dayend," PM )\n");
      Comment("\nTS = ",ExtTrailingStop," BE = ",ExtBreakEven," SL = ",ExtStopLoss," ExtMAfilter  = ",ExtMAfilter,"\n");
     }
   if(iTime(m_symbol.Name(),Period(),0)==lastbar)
     {
      newbar=false;
     }
   else
     {
      lastbar=iTime(m_symbol.Name(),Period(),0);
      newbar=true;
     }
/* Only allow one open position at a time (per expert)- so if there is an open position - do not open another one. */
   int total=0;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            total++;

   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            total++;

   if(total<MaxOpenPositions)
     {
      if(!RefreshRates())
         return;

      ticketexpiration=TimeCurrent()+30*60; /* orders are valid for half an hour */
/* OpenPosition() has state so calling it again will mess up the results - this is why I call it
         * once and remember the return value before acting 
         */
      action=OpenPosition();
/* check for long position (BUY) possibility */
      if(action==1)
        {
         if(m_symbol.Ask()>longentry+4*m_adjusted_point)
            method=ORDER_TYPE_BUY_LIMIT;
         if(m_symbol.Ask()==longentry)
            method=ORDER_TYPE_BUY;
         if(m_symbol.Ask()<longentry)
           {
            longentry=m_symbol.Ask();
            method=ORDER_TYPE_BUY;
           }
         hardstop=NormalizeDouble(longentry-ExtStopLoss*m_adjusted_point,precision);
         Alert("KSRobot ",m_symbol.Name()," Go Long @ ",longentry,"!");
         if(method==ORDER_TYPE_BUY_LIMIT)
           {
            if(m_trade.BuyLimit(Lots,longentry,NULL,hardstop,m_symbol.Ask()+ExtTakeProfit*m_adjusted_point,ORDER_TIME_SPECIFIED,ticketexpiration))
              {
               if(m_trade.ResultOrder()>0)
                 {
                  longcross=0;
                  Print("BUY_LIMIT - > true. ticket of order = ",m_trade.ResultOrder());
                 }
               else
                 {
                  longentry=0;
                  Print("BUY_LIMIT - > false. Result Retcode: ",m_trade.ResultRetcode(),
                        ", description of Retcode: ",m_trade.ResultRetcodeDescription());
                 }
              }
            else
              {
               longentry=0;
               Print("BUY_LIMIT - > false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of Retcode: ",m_trade.ResultRetcodeDescription());
              }
           }
         if(method==ORDER_TYPE_BUY)
           {
            if(m_trade.Buy(Lots,NULL,longentry,hardstop,m_symbol.Ask()+ExtTakeProfit*m_adjusted_point))
              {
               if(m_trade.ResultDeal()>0)
                 {
                  longcross=0;
                  Print("BUY - > true. ticket of deal = ",m_trade.ResultDeal());
                 }
               else
                 {
                  longentry=0;
                  Print("BUY - > false. Result Retcode: ",m_trade.ResultRetcode(),
                        ", description of Retcode: ",m_trade.ResultRetcodeDescription());
                 }
              }
            else
              {
               longentry=0;
               Print("BUY - > false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of Retcode: ",m_trade.ResultRetcodeDescription());
              }
           }
         //---
         return;
        }
/* check for short position (SELL) possibility */
      if(action==-1)
        {
         hardstop=NormalizeDouble(shortentry+ExtStopLoss*m_adjusted_point,precision);
         Alert("KSRobot ",Symbol()," KS Go Short @ ",shortentry,"!");
         //----
         if(m_symbol.Bid()<shortentry-4*m_adjusted_point)
            method=ORDER_TYPE_SELL_LIMIT;
         if(m_symbol.Bid()==shortentry)
            method=ORDER_TYPE_SELL;
         if(m_symbol.Bid()>shortentry)
           {
            shortentry=m_symbol.Bid();
            method=ORDER_TYPE_SELL;
           }
         if(method==ORDER_TYPE_SELL_LIMIT)
           {
            if(m_trade.SellLimit(Lots,shortentry,NULL,hardstop,m_symbol.Bid()-ExtTakeProfit*m_adjusted_point,ORDER_TIME_SPECIFIED,ticketexpiration))
              {
               if(m_trade.ResultOrder()>0)
                 {
                  longcross=0;
                  Print("SELL_LIMIT - > true. ticket of order = ",m_trade.ResultOrder());
                 }
               else
                 {
                  longentry=0;
                  Print("SELL_LIMIT - > false. Result Retcode: ",m_trade.ResultRetcode(),
                        ", description of Retcode: ",m_trade.ResultRetcodeDescription());
                 }
              }
            else
              {
               longentry=0;
               Print("SELL_LIMIT - > false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of Retcode: ",m_trade.ResultRetcodeDescription());
              }
           }
         if(method==ORDER_TYPE_SELL)
           {
            if(m_trade.Sell(Lots,NULL,shortentry,hardstop,m_symbol.Bid()-ExtTakeProfit*m_adjusted_point))
              {
               if(m_trade.ResultDeal()>0)
                 {
                  shortcross=0;
                  Print("SELL - > true. ticket of deal = ",m_trade.ResultDeal());
                 }
               else
                 {
                  shortentry=0;
                  Print("SELL - > false. Result Retcode: ",m_trade.ResultRetcode(),
                        ", description of Retcode: ",m_trade.ResultRetcodeDescription());
                 }
              }
            else
              {
               shortentry=0;
               Print("SELL - > false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of Retcode: ",m_trade.ResultRetcodeDescription());
              }
           }
         //---
         return;
        }
/* do nothing */
      return;
     }
/* if there are open positions - check if they need to be closed */
   if(!RefreshRates())
      return;

   lastbid=m_symbol.Bid();
   lastask=m_symbol.Ask();

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==Symbol() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
/* close if condition met */
               if(ClosePosition()==1)
                 {
                  m_trade.PositionClose(m_position.Ticket());
                  return;
                 }
/* set ExtBreakEven if set */
               if(ExtBreakEven>0)
                 {
                  if(m_symbol.Bid()-m_position.PriceOpen()>ExtBreakEven*m_adjusted_point)
                    {
                     if(m_position.StopLoss()<m_position.PriceOpen())
                       {
                        m_trade.PositionModify(m_position.Ticket(),m_position.PriceOpen()+1*m_adjusted_point,m_position.TakeProfit());
                       }
                    }
                 }
/* update trailing stop */
               if(ExtTrailingStop>0)
                 {
                  if(m_symbol.Bid()-m_position.PriceOpen()>ExtTrailingStop*m_adjusted_point)
                    {
                     if(m_position.StopLoss()<m_symbol.Bid()-ExtTrailingStop*m_adjusted_point)
                       {
                        m_trade.PositionModify(m_position.Ticket(),m_symbol.Bid()-ExtTrailingStop*m_adjusted_point,m_position.TakeProfit());
                        return;
                       }
                    }
                 }
              }

            if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
/* close if condition met */
               if(ClosePosition()==-1)
                 {
                  m_trade.PositionClose(m_position.Ticket());
                  return;
                 }
/* set ExtBreakEven if set */
               if(ExtBreakEven>0)
                 {
                  if(m_position.PriceOpen()-m_symbol.Ask()>ExtBreakEven*m_adjusted_point)
                    {
                     if(m_position.StopLoss()>m_position.PriceOpen())
                       {
                        m_trade.PositionModify(m_position.Ticket(),m_position.PriceOpen()-1*m_adjusted_point,m_position.TakeProfit());
                       }
                    }
                 }
/* update trailing stop */
               if(ExtTrailingStop>0)
                 {
                  if(m_position.PriceOpen()-m_symbol.Ask()>ExtTrailingStop*m_adjusted_point)
                    {
                     if(m_position.StopLoss()>m_symbol.Ask()+ExtTrailingStop*m_adjusted_point)
                       {
                        m_trade.PositionModify(m_position.Ticket(),m_symbol.Ask()+ExtTrailingStop*m_adjusted_point,m_position.TakeProfit());
                        return;
                       }
                    }
                 }
              }
           }
//---
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetMarginMode(void)
  {
   m_margin_mode=(ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsHedging(void)
  {
   return(m_margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iIchimoku                           |
//|  the buffer numbers are the following:                           |
//|   0 - TENKANSEN_LINE, 1 - KIJUNSEN_LINE, 2 - SENKOUSPANA_LINE,   |
//|   3 - SENKOUSPANB_LINE, 4 - CHIKOUSPAN_LINE                      |
//+------------------------------------------------------------------+
double iIchimokuGet(const int buffer,const int index)
  {
   double Ichimoku[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iIchimoku array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iIchimoku,buffer,index,1,Ichimoku)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iIchimoku indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Ichimoku[0]);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(const int index)
  {
   double MA[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iMA,0,index,1,MA)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(MA[0]);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iSAR                                |
//+------------------------------------------------------------------+
double iSARGet(const int index)
  {
   double SAR[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iSARBuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iSAR,0,index,1,SAR)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iSAR indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(SAR[0]);
  }
//+------------------------------------------------------------------+

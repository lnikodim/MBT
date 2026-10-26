//+------------------------------------------------------------------+
//|                                             Reverse Strategy.mq5 |
//|                          Copyright 2021, Valentinos Konstantinou |
//|                    https://www.mql5.com/en/users/valentinoskonst |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Valentinos Konstantinou"
#property link      "https://www.mql5.com/en/users/valentinoskonst"
#property version   "1.00"
#property description "Expert Advisor using Bollinger Bands and RSI"
#property strict

#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh> 
#include <Trade\AccountInfo.mqh> 

CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper

//---- input parameters
input double      my_lot         =1;       // lot size
input int         MA_period      =20;        // period of the MA and STDV
input int         RSI_period     =14;         // period of the RSI
input int         RSI_overbought =70;        // RSI overbought signal
input int         RSI_oversold   =30;        // RSI oversold signal
//---
ulong          m_magic=12345;                // magic number
ENUM_ACCOUNT_MARGIN_MODE m_margin_mode;

double m_adjusted_point;             // point value adjusted for 3 or 5 points 
int    handle_iMA_M5;                // variable for storing the handle of the iMA indicator
int    handle_iSTDV_M5;              // variable for storing the handle of the iSTDV indicator
int    handle_iRSI_M5;               // // variable for storing the handle of the iRSI indicator
          
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
//---
   m_symbol.Name(Symbol());                  // sets symbol name
   if(!RefreshRates())
     {
      Print("Error RefreshRates. Bid=",DoubleToString(m_symbol.Bid(),Digits()),
            ", Ask=",DoubleToString(m_symbol.Ask(),Digits()));
      return(INIT_FAILED);
     }
   m_symbol.Refresh();
//---
   m_trade.SetExpertMagicNumber(m_magic);    // sets magic number
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
   digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;




//--- create handle of the indicator iMA
   handle_iMA_M5=iMA(m_symbol.Name(),PERIOD_CURRENT,MA_period,0,MODE_SMA,PRICE_CLOSE);
//--- if the handle is not created
   if(handle_iMA_M5==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_CURRENT),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
     
//--- create handle of the indicator iSTDV
   handle_iSTDV_M5=iStdDev(m_symbol.Name(),PERIOD_CURRENT,MA_period,0,MODE_SMA,PRICE_CLOSE);
//--- if the handle is not created
   if(handle_iSTDV_M5==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_CURRENT),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }

//--- create handle of the indicator iRSI
   handle_iRSI_M5=iRSI(m_symbol.Name(),PERIOD_CURRENT,RSI_period,PRICE_CLOSE);
//--- if the handle is not created
   if(handle_iRSI_M5==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_CURRENT),
                  GetLastError());
      //--- the indicator is stopped early
      return(INIT_FAILED);
     }
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
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
   static datetime prev_time=0;
   datetime time_0=iTime(0);

   if(prev_time==time_0)
      return;

   prev_time=time_0;
   
   double MA_0 = iMAGet(handle_iMA_M5,0);
   double STDV_0 = iSTDVGet(handle_iSTDV_M5,0);
   double RSI_0 = iRSIGet(handle_iRSI_M5,0);
   double MA_1 = iMAGet(handle_iMA_M5,1);
   double STDV_1 = iSTDVGet(handle_iSTDV_M5,1);
   double RSI_1 = iRSIGet(handle_iRSI_M5,1);
   double Previous_Open=iOpen(Symbol(),PERIOD_CURRENT,1);
   double Previous_Close=iClose(Symbol(),PERIOD_CURRENT,1);
   double Current_Open=iOpen(Symbol(),PERIOD_CURRENT,0);
   double Current_Close=iClose(Symbol(),PERIOD_CURRENT,0);
   


   if(Previous_Close<MA_1-2*STDV_1 && Current_Close>=MA_0-2*STDV_0 && RSI_1<RSI_oversold && RSI_0>=RSI_oversold)
     {
      if(!RefreshRates())
        {
         prev_time=iTime(1);
         return;
        }

      double price=m_symbol.Ask();
      double my_SL=m_symbol.Ask()-STDV_0;
      double my_TP=m_symbol.Ask()+2*STDV_0;

      double chek_volime_lot=m_trade.CheckVolume(m_symbol.Name(),my_lot,price,ORDER_TYPE_BUY);
      if(chek_volime_lot!=0.0)
         if(chek_volime_lot>=my_lot)
           {
            m_trade.Buy(my_lot,NULL,price,my_SL,my_TP,"VK");
            return;
           }
     }

   if(Previous_Close>MA_1+2*STDV_1 && Current_Close<=MA_0+2*STDV_0 && RSI_1>RSI_overbought && RSI_0<=RSI_overbought)
     {
      if(!RefreshRates())
        {
         prev_time=iTime(1);
         return;
        }

      double price=m_symbol.Bid();
      double my_SL=m_symbol.Bid()+STDV_0;
      double my_TP=m_symbol.Bid()-2*STDV_0;


      double chek_volime_lot=m_trade.CheckVolume(m_symbol.Name(),my_lot,price,ORDER_TYPE_SELL);
      if(chek_volime_lot!=0.0)
         if(chek_volime_lot>=my_lot)
           {
            m_trade.Sell(my_lot,NULL,price,my_SL,my_TP,"VK");
            return;
           }
     }

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(Current_Close>=MA_0+2*STDV_0)
                 {
                  m_trade.PositionClose(m_position.Ticket()); // close position
                 }
               }
            if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               if(Current_Close<=MA_0-2*STDV_0)
                 {
                  m_trade.PositionClose(m_position.Ticket()); // close position
                 }            
               }
           }
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
//| Get Time for specified bar index                                 |
//+------------------------------------------------------------------+
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[1];
   datetime time=0;
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0) time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(int handle_iMA,const int index)
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
//| Get value of buffers for the iSTDV                               |
//+------------------------------------------------------------------+
double iSTDVGet(const int handle_iSTDV,const int index)
  {
   double STDV[1];
//--- reset error code
   ResetLastError();
//--- fill a part of the iRSI array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle_iSTDV,0,index,1,STDV)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iRSI indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(STDV[0]);
}

//+------------------------------------------------------------------+
//| Get value of buffers for the iRSI                              |
//+------------------------------------------------------------------+
double iRSIGet(const int handle_iRSI,const int index)
  {
   double RSI[1];
//--- reset error code
   ResetLastError();
//--- fill a part of the iRSI array with values from the indicator buffer that has 0 index
   if(CopyBuffer(handle_iRSI,0,index,1,RSI)<0)
     {
      //--- if the copying fails, tell the error code
      PrintFormat("Failed to copy data from the iRSI indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated
      return(0.0);
     }
   return(RSI[0]);
}

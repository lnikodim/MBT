//+------------------------------------------------------------------+
//|                          EMA_WMA v2(barabashkakvn's edition).mq5 |
//|                               Copyright © 2009, Vladimir Hlystov |
//|                                                cmillion@narod.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009, Vladimir Hlystov"
#property link      "cmillion@narod.ru"
#property version   "2.000"
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
input int      period_EMA     = 28;          // EMA: averaging period 
input int      period_WMA     = 8;           // WMA: averaging period 
input ushort   InpStopLoss    = 50;          // StopLoss 
input ushort   InpTakeProfit  = 50;          // TakeProfit 
input ushort   InpTrailingStop= 50;          // Trailing Stop 
input ushort   InpTrailingStep= 10;          // Trailing Step 
input int      risk           = 10;          // Risk
double         my_lot;
ulong          m_magic=72406264;             // magic number
//---
double my_SL,my_TP;
datetime TimeBar;

double         ExtStopLoss=0.0;
double         ExtTakeProfit=0.0;
double         ExtTrailingStop=0.0;
double         ExtTrailingStep=0.0;

int            handle_iMA_EMA;               // variable for storing the handle of the iMA indicator 
int            handle_iMA_WMA;               // variable for storing the handle of the iMA indicator 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpTrailingStop!=0 && InpTrailingStep==0)
     {
      Alert(__FUNCTION__," ERROR: Trailing is not possible: the parameter \"Trailing Step\" is zero!");
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   m_symbol.Name(Symbol());                  // sets symbol name
//---
   m_trade.SetExpertMagicNumber(m_magic);    // sets magic number
   if(!RefreshRates())
     {
      Print("Error RefreshRates. Bid=",DoubleToString(m_symbol.Bid(),Digits()),
            ", Ask=",DoubleToString(m_symbol.Ask(),Digits()));
      return(INIT_FAILED);
     }
   m_symbol.Refresh();
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;

   ExtStopLoss    = InpStopLoss     * digits_adjust;
   ExtTakeProfit  = InpTakeProfit   * digits_adjust;
   ExtTrailingStop= InpTrailingStop * digits_adjust;
   ExtTrailingStep= InpTrailingStep * digits_adjust;

//--- create handle of the indicator iMA
   handle_iMA_EMA=iMA(Symbol(),Period(),period_EMA,0,MODE_EMA,PRICE_OPEN);
//--- if the handle is not created 
   if(handle_iMA_EMA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }

//--- create handle of the indicator iMA
   handle_iMA_WMA=iMA(Symbol(),Period(),period_WMA,0,MODE_LWMA,PRICE_OPEN);
//--- if the handle is not created 
   if(handle_iMA_WMA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   datetime time_0=iTime(0);
   if(TimeBar==time_0)
      return;

   if(TimeBar==0)
     {
      TimeBar=time_0;
      return;
     }//first program run

   double EMA0 = iMAGet(handle_iMA_EMA,0);
   double WMA0 = iMAGet(handle_iMA_WMA,0);
   double EMA1 = iMAGet(handle_iMA_EMA,1);
   double WMA1 = iMAGet(handle_iMA_WMA,1);

   if(EMA0<WMA0 && EMA1>WMA1) //Buy
     {
      if(!RefreshRates())
         return;
      TimeBar=time_0;
      my_TP  = m_symbol.Ask() + ExtTakeProfit*Point();
      my_SL  = m_symbol.Ask() - ExtStopLoss*Point();
      my_lot = LOT(risk);
      CLOSEORDER("Sell");
      OPENORDER("Buy");
     }

   if(EMA0>WMA0 && EMA1<WMA1) //Sell
     {
      if(!RefreshRates())
         return;
      TimeBar=time_0;
      my_TP=m_symbol.Bid()-ExtTakeProfit*Point();
      my_SL = m_symbol.Bid() + ExtStopLoss*Point();
      my_lot= LOT(risk);
      CLOSEORDER("Buy");
      OPENORDER("Sell");
     }
//---
   Trailing();
//---
   return;
  }
//--------------------------------------------------------------------
void CLOSEORDER(string ord)
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==Symbol() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY && ord=="Buy")
               m_trade.PositionClose(m_position.Ticket());  // Close Buy
            if(m_position.PositionType()==POSITION_TYPE_SELL && ord=="Sell")
               m_trade.PositionClose(m_position.Ticket()); // Close Sell
           }
  }
//--------------------------------------------------------------------
void OPENORDER(string ord)
  {
   if(ord=="Buy")
      if(!m_trade.Buy(my_lot,Symbol(),m_symbol.Ask(),my_SL,my_TP,""))
         Print("Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of result: ",m_trade.ResultRetcodeDescription(),
               ", ticket of deal: ",m_trade.ResultDeal());

   if(ord=="Sell")
      if(!m_trade.Sell(my_lot,Symbol(),m_symbol.Bid(),my_SL,my_TP,""))
         Print("BUY_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
               ", ticket of order: ",m_trade.ResultOrder());
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LOT(int input_risk)
  {
   if(!RefreshRates())
      return(m_symbol.LotsMin());

   double MINLOT=m_symbol.LotsMin();

   double margin_required=0.0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY,Symbol(),1.0,m_symbol.Ask(),margin_required))
      return(m_symbol.LotsMin());

   my_lot=m_account.FreeMargin()*input_risk/100.0/margin_required;

   if(my_lot>m_symbol.LotsMax())
      my_lot=m_symbol.LotsMax();

   if(my_lot<MINLOT)
      my_lot=MINLOT;

   if(MINLOT<0.1)
      my_lot=NormalizeDouble(my_lot,2);
   else
      my_lot=NormalizeDouble(my_lot,1);

   return(my_lot);
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
   datetime Time[];
   datetime time=0;
   ArraySetAsSeries(Time,true);
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0) time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(int handle_iMA,const int index)
  {
   double MA[];
   ArraySetAsSeries(MA,true);
//--- reset error code 
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iMA,0,0,index+1,MA)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(MA[index]);
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

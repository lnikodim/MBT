//+------------------------------------------------------------------+
//|                            ssb5_123(barabashkakvn's edition).mq5 |
//|         Copyright © 2009, Yury V. Reshetov  http://ssb.bigfx.ru/ |
//|                                             http://ssb.bigfx.ru/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009, Yury V. Reshetov http://ssb.bigfx.ru"
#property link      "http://ssb.bigfx.ru"
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
//--- input parameters
input double   InpLots                    = 1.0;      // Lots
input int      Inp_MA_ma_period           = 45;       // MA: averaging period
input int      Inp_MACD_fast_ema_period   = 47;       // MACD: period for Fast average calculation 
input int      Inp_MACD_slow_ema_period   = 95;       // MACD: period for Slow average calculation 
input int      Inp_MACD_signal_period     = 74;       // MACD: period for their difference averaging 
input int      Inp_STO_Kperiod            = 25;       // Stochastic: K-period (number of bars for calculations) 
input int      Inp_STO_Dperiod            = 12;       // Stochastic: D-period (period of first smoothing) 
input int      Inp_STO_slowing            = 56;       // Stochastic: final smoothing 
input ulong    m_magic                    = 4797863;  // magic number
//---
ulong          m_slippage=10;                // slippage

int            handle_iMA;                   // variable for storing the handle of the iMA indicator 
int            handle_iMACD;                 // variable for storing the handle of the iMACD indicator 
int            handle_iStochastic;           // variable for storing the handle of the iStochastic indicator 
int            handle_iOsMA;                 // variable for storing the handle of the iOsMA indicator 
int            handle_iAO;                   // variable for storing the handle of the iAO indicator 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
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
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
   m_trade.SetDeviationInPoints(m_slippage);
//--- create handle of the indicator iMA
   handle_iMA=iMA(m_symbol.Name(),Period(),Inp_MA_ma_period,0,MODE_SMMA,PRICE_CLOSE);
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
//--- create handle of the indicator iMACD
   handle_iMACD=iMACD(m_symbol.Name(),Period(),
                      Inp_MACD_fast_ema_period,Inp_MACD_slow_ema_period,Inp_MACD_signal_period,PRICE_OPEN);
//--- if the handle is not created 
   if(handle_iMACD==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMACD indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iStochastic
   handle_iStochastic=iStochastic(m_symbol.Name(),Period(),
                                  Inp_STO_Kperiod,Inp_STO_Dperiod,Inp_STO_slowing,MODE_SMMA,STO_LOWHIGH);
//--- if the handle is not created 
   if(handle_iStochastic==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iStochastic indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iOsMA
   handle_iOsMA=iOsMA(m_symbol.Name(),Period(),
                      Inp_MACD_fast_ema_period,Inp_MACD_slow_ema_period,Inp_MACD_signal_period,PRICE_OPEN);
//--- if the handle is not created 
   if(handle_iOsMA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create a handle of iOsMA for the pair %s/%s, error code is %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iAO
   handle_iAO=iAO(m_symbol.Name(),Period());
//--- if the handle is not created 
   if(handle_iAO==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iAO indicator for the symbol %s/%s, error code %d",
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
   datetime time_0=iTime(m_symbol.Name(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
//---
   bool longsignal=LongSignal();
   bool shortsignal=ShortSignal();
//---
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY && shortsignal)
              {
               m_trade.PositionClose(m_position.Ticket());
               PrevBars=0;
               return;
              }
            if(m_position.PositionType()==POSITION_TYPE_SELL && longsignal)
              {
               m_trade.PositionClose(m_position.Ticket());
               PrevBars=0;
               return;
              }
            //---
            return;
           }
//---
   if(longsignal)
      m_trade.Buy(InpLots,m_symbol.Name());
   else if(shortsignal)
      m_trade.Sell(InpLots,m_symbol.Name());
//---
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
//| Check the correctness of the position volume                     |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=m_symbol.LotsMin();
   if(volume<min_volume)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем меньше минимально допустимого SYMBOL_VOLUME_MIN=%.2f",min_volume);
      else
         error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }
//--- maximal allowed volume of trade operations
   double max_volume=m_symbol.LotsMax();
   if(volume>max_volume)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем больше максимально допустимого SYMBOL_VOLUME_MAX=%.2f",max_volume);
      else
         error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }
//--- get minimal step of volume changing
   double volume_step=m_symbol.LotsStep();
   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем не кратен минимальному шагу SYMBOL_VOLUME_STEP=%.2f, ближайший правильный объем %.2f",
                                        volume_step,ratio*volume_step);
      else
         error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                        volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
   return(true);
  }
//+------------------------------------------------------------------+
//| Long signal                                                      |
//+------------------------------------------------------------------+
bool LongSignal()
  {
   if(fcandle()<0)
      return(false);
   if(fao()<0)
      return(false);
   if(fao1()<0)
      return(false);
   if(fmacd()<0)
      return(false);
   if(fmacd1()<0)
      return(false);
   if(fosma1()<0)
      return(false);
   if(fsmma()<0)
      return(false);
   if(fstoch1()<0)
      return(false);
   if(fstoch2()<0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Short signal                                                     |
//+------------------------------------------------------------------+
bool ShortSignal()
  {
   if(fcandle()>0)
      return(false);
   if(fao()>0)
      return(false);
   if(fao1()>0)
      return(false);
   if(fmacd()>0)
      return(false);
   if(fmacd1()>0)
      return(false);
   if(fosma1()>0)
      return(false);
   if(fsmma()>0)
      return(false);
   if(fstoch1()>0)
      return(false);
   if(fstoch2()>0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int fcandle()
  {
   int result=0;
   if(iOpen(m_symbol.Name(),Period(),0)<iOpen(m_symbol.Name(),Period(),1))
      result=1;
   if(iOpen(m_symbol.Name(),Period(),0)>iOpen(m_symbol.Name(),Period(),1))
      result=-1;
//---
   return(result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int fao()
  {
   int result = 0;
   double ind = iAOGet(0);
   if(ind>0)
      result=1;
   if(ind<0)
      result=-1;
//---
   return(result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int fao1()
  {
   int result = 0;
   double ind = iAOGet(0);
   double ind1= iAOGet(1);
   if((ind-ind1)<0)
      result=1;
   if((ind-ind1)>0)
      result=-1;
//---
   return(result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int fmacd()
  {
   int result = 0;
   double ind = iMACDGet(MAIN_LINE, 0);
   if(ind>0)
      result=1;
   if(ind<0)
      result=-1;
//---
   return(result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int fmacd1()
  {
   int result=0;
   double ind = iMACDGet(MAIN_LINE, 0);
   double ind1= iMACDGet(MAIN_LINE, 1);
   if((ind-ind1)>0)
      result=1;
   if((ind-ind1)<0)
      result=-1;
//---
   return(result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int fosma1()
  {
   int result = 0;
   double ind = iOsMAGet(0);
   double ind1= iOsMAGet(1);
   if((ind-ind1)<0)
      result=1;
   if((ind-ind1)>0)
      result=-1;
//---
   return(result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int fsmma()
  {
   int result = 0;
   double ind = iOpen(m_symbol.Name(),Period(),0) - iMAGet(0);
   if(ind>0)
      result=1;
   if(ind<0)
      result=-1;
//---
   return(result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int fstoch1()
  {
   int result = 0;
   double ind = iStochasticGet(MAIN_LINE, 0) - 50.0;
   if(ind>0)
      result=1;
   if(ind<0)
      result=-1;
//---
   return(result);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int fstoch2()
  {
   int result = 0;
   double ind = iStochasticGet(SIGNAL_LINE, 0) - 50.0;
   if(ind>0)
      result=1;
   if(ind<0)
      result=-1;
//---
   return(result);
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
//| Get value of buffers for the iMACD                               |
//|  the buffer numbers are the following:                           |
//|   0 - MAIN_LINE, 1 - SIGNAL_LINE                                 |
//+------------------------------------------------------------------+
double iMACDGet(const int buffer,const int index)
  {
   double MACD[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iMACDBuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iMACD,buffer,index,1,MACD)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iMACD indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(MACD[0]);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iStochastic                         |
//|  the buffer numbers are the following:                           |
//|   0 - MAIN_LINE, 1 - SIGNAL_LINE                                 |
//+------------------------------------------------------------------+
double iStochasticGet(const int buffer,const int index)
  {
   double Stochastic[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iStochasticBuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iStochastic,buffer,index,1,Stochastic)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iStochastic indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Stochastic[0]);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iOsMA                               |
//+------------------------------------------------------------------+
double iOsMAGet(const int index)
  {
   double OsMA[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iOsMA array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iOsMA,0,index,1,OsMA)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iOsMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(OsMA[0]);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iAO                                 |
//+------------------------------------------------------------------+
double iAOGet(const int index)
  {
   double AO[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iAO array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iAO,0,index,1,AO)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iAO indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(AO[0]);
  }
//+------------------------------------------------------------------+

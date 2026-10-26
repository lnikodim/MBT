//+------------------------------------------------------------------+
//|              RSI Bollinger Bands EA(barabashkakvn's edition).mq5 |
//|                                                     Copyright RAP|
//+------------------------------------------------------------------+
#property copyright "RAP"
#property version   "1.000"
/*
   SingleCurrency EA                                              
   Use M15 Chart                                                   
   Triggers: T1 RSI Over Bot/Over Sold with fixed limits           
             T2 RSI Over Bot/Over Sold  N*Sigma Limits             
   Uses M15,H1 and H4 time frames                    
   Use either T1 or T1, not both     
*/
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
//--- input parameters
// ---------- Trigger Control  -----------------------
input bool     TriggerOne = true; // Trig 1 RSI OB/OS Fixed Lims
input bool     TriggerTwo =  false; // Trig 2 RSI OB/OS BB Sigma Lims
//------------ Trigger 1 RSI OB/OS ----------------
input string   NoteTrigger1=" Trigger 1 - RSI OB/OS ";
input double   BBSpreadH4Min_1=84.;
input double   BBSpreadM15Max_1=64.;
input int      RSIPer_1=10;
//---
input double   RSILoM15_1 = 24.;
input double   RSIHiM15_1 = 66.;
input double   RSILoH1_1 =  34.;
input double   RSIHiH1_1 =  54.;
input double   RSILoH4_1 =  48.;
input double   RSIHiH4_1 =  56.;
//--- Lowest and Highest liimits
input double   RSIHiLimH4_1 =   85.;
input double   RSILoLimH4_1 =   35.;
input double   RSIHiLimH1_1 =   80.;
input double   RSILoLimH1_1 =   24.;
input double   RSIHiLimM15_1 =  92.;
input double   RSILoLimM15_1 =  20.;
input double   RDeltaM15_Lim_1=-3.5;
input double   StocLoM15_1   =  26.;
input double   StocHiM15_1   =  64.;
//-------- Trigger 2 RSI BB OB/OS ---------------------
input string   NoteTrigger2=" Trigger 2 - RSI BB OB/OS ";
input int      RSIPer_2=20;
input double   BBSpreadH4Min_2=65.;
input double   BBSpreadM15Max_2=75.;
input int      NumRSI=60;
//---
input double   RSIM15_Sigma_2= 1.20;
input double   RSIH1_Sigma_2 =  0.95;
input double   RSIH4_Sigma_2 =  0.9;
//--- Lowest and Highest liimits
input double   RSIM15_SigmaLim_2=1.85;
input double   RSIH1_SigmaLim_2=  2.55;
input double   RSIH4_SigmaLim_2=   2.7;
//---
input double   RDeltaM15_Lim_2=-5.5;
//---
input double   StocLoM15_2 = 24.;
input double   StocHiM15_2 = 68.;
//--- 
input double   InpLots=0.1;      // Lots
//---
input string   noteT1MonMgt=" Trigger One Money Mgmt";
input ushort   InpTakeProfit_Buy_1  = 150;   // Take Profit Buy "One Money Mgmt" (in pips)
input ushort   InpStopLoss_Buy_1    = 70;    // Stop Loss Buy "One Money Mgmt" (in pips)
input ushort   InpTakeProfit_Sell_1 = 70;    // Take Profit Sell "One Money Mgmt" (in pips)
input ushort   InpStopLoss_Sell_1   = 35;    // Stop Loss Sell "One Money Mgmt" (in pips)
//---
input string   noteT2MonMgt=" Trigger Two Money Mgmt";
input ushort   InpTakeProfit_Buy_2  = 140;   // Take Profit Buy "Two Money Mgmt" (in pips)
input ushort   InpStopLoss_Buy_2    = 35;    // Stop Loss Buy "Two Money Mgmt" (in pips
input ushort   InpTakeProfit_Sell_2 = 60;    // Take Profit Sell "Two Money Mgmt" (in pips)
input ushort   InpStopLoss_Sell_2   = 30;    // Stop Loss Sell "Two Money Mgmt" (in pips)
//---
input string   noteCommon=" Common Data ";
//--- General Periods and limits
input int      ATRPer=60;
input int      BBPeriod=20;
input double   ATRLim=90.;
//---
input int      entryhour =     0;
input int      openhours =    14;
input int      NumPositions=1;
input int      TotOpenOrders=8;
//---
input int      FridayEndHour=4;
input int      L1 = 12;
input int      L2 =  5;
input int      L3 =  5;
//---
input ulong    m_magic=15489;                // magic number
//---
ulong          m_slippage=10;                // slippage

double         ExtTakeProfit_Buy_1=0.0;
double         ExtStopLoss_Buy_1=0.0;
double         ExtTakeProfit_Sell_1=0.0;
double         ExtStopLoss_Sell_1=0.0;

double         ExtTakeProfit_Buy_2=0.0;
double         ExtStopLoss_Buy_2=0.0;
double         ExtTakeProfit_Sell_2=0.0;
double         ExtStopLoss_Sell_2=0.0;
//---
double       _spread;
int          CtrBuy=0;
int          CtrSell=0;

int            handle_iStochastic;           // variable for storing the handle of the iStochastic indicator 
int            handle_iATR;                  // variable for storing the handle of the iATR indicator 
int            handle_iBands_M15;            // variable for storing the handle of the iBands indicator 
int            handle_iBands_H4;             // variable for storing the handle of the iBands indicator 
int            handle_iRSI_M15_Per_1;        // variable for storing the handle of the iRSI indicator
int            handle_iRSI_H1_Per_1;         // variable for storing the handle of the iRSI indicator
int            handle_iRSI_H4_Per_1;         // variable for storing the handle of the iRSI indicator
int            handle_iRSI_M15_Per_2;        // variable for storing the handle of the iRSI indicator
int            handle_iRSI_H1_Per_2;         // variable for storing the handle of the iRSI indicator
int            handle_iRSI_H4_Per_2;         // variable for storing the handle of the iRSI indicator

double         m_adjusted_point;             // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- 
   if(TriggerOne && TriggerTwo)
     {
      Alert(" Aborting - Should not have both triggers on at the same time ");
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
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
//---
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtTakeProfit_Buy_1  = InpTakeProfit_Buy_1   * m_adjusted_point;
   ExtStopLoss_Buy_1    = InpStopLoss_Buy_1     * m_adjusted_point;
   ExtTakeProfit_Sell_1 = InpTakeProfit_Sell_1  * m_adjusted_point;
   ExtStopLoss_Sell_1   = InpStopLoss_Sell_1    * m_adjusted_point;

   ExtTakeProfit_Buy_2  = InpTakeProfit_Buy_2   * m_adjusted_point;
   ExtStopLoss_Buy_2    = InpStopLoss_Buy_2     * m_adjusted_point;
   ExtTakeProfit_Sell_2 = InpTakeProfit_Sell_2  * m_adjusted_point;
   ExtStopLoss_Sell_2   = InpStopLoss_Sell_2    * m_adjusted_point;
//--- create handle of the indicator iStochastic
   handle_iStochastic=iStochastic(m_symbol.Name(),Period(),L1,L2,L3,MODE_SMA,STO_LOWHIGH);
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
//--- create handle of the indicator iATR
   handle_iATR=iATR(m_symbol.Name(),PERIOD_H4,ATRPer);
//--- if the handle is not created 
   if(handle_iATR==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iATR indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_H4),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iBands
   handle_iBands_M15=iBands(m_symbol.Name(),PERIOD_M15,BBPeriod,0,2,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iBands_M15==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iBands indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_M15),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iBands
   handle_iBands_H4=iBands(m_symbol.Name(),PERIOD_H4,BBPeriod,0,2,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iBands_H4==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iBands indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_M15),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iRSI
   handle_iRSI_M15_Per_1=iRSI(m_symbol.Name(),PERIOD_M15,RSIPer_1,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iRSI_M15_Per_1==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_M15),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iRSI
   handle_iRSI_H1_Per_1=iRSI(m_symbol.Name(),PERIOD_H1,RSIPer_1,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iRSI_H1_Per_1==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_H1),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iRSI
   handle_iRSI_H4_Per_1=iRSI(m_symbol.Name(),PERIOD_H4,RSIPer_1,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iRSI_H4_Per_1==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_H4),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }

//--- create handle of the indicator iRSI
   handle_iRSI_M15_Per_2=iRSI(m_symbol.Name(),PERIOD_M15,RSIPer_2,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iRSI_M15_Per_2==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_M15),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iRSI
   handle_iRSI_H1_Per_2=iRSI(m_symbol.Name(),PERIOD_H1,RSIPer_2,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iRSI_H1_Per_2==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_H1),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iRSI
   handle_iRSI_H4_Per_2=iRSI(m_symbol.Name(),PERIOD_H4,RSIPer_2,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iRSI_H4_Per_2==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_H4),
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
   if(!RefreshRates())
     {
      PrevBars=iTime(1);
      return;
     }
//--- Loop over currency pairs (multi currency EA)
//--- set up new bar test
   MqlDateTime SBarTimeCurrent;
   TimeToStruct(PrevBars,SBarTimeCurrent);
   int hour_current      = SBarTimeCurrent.hour;
   int minute_current    = SBarTimeCurrent.min;
   int second_current    = SBarTimeCurrent.sec;

   _spread=m_symbol.Spread();
//--- initializaton          
   int tradentry     = 0;
   double Take_Profit= 0.0;
   double Stop_Loss  = 0.0;
   bool Buy_1        = false;
   bool Sell_1       = false;
   bool Buy_2        = false;
   bool Sell_2       = false;
   int MaxPositions  = NumPositions;
   int Positions     = 0;
//--- technical indicators 
   double BB_SpreadM15=(iBandsGet(handle_iBands_M15,UPPER_BAND,1) -iBandsGet(handle_iBands_M15,LOWER_BAND,1))/
                       m_adjusted_point;
   double BB_Lower   = iBandsGet(handle_iBands_H4,LOWER_BAND,1);
   double BB_Upper   = iBandsGet(handle_iBands_H4,UPPER_BAND,1);
   double BB_Spread  = (BB_Upper-BB_Lower)/m_adjusted_point;
//---     
   Positions=CalculateAllPositions();   // number of positions for this symbol and this magic 
   double ATRCur=iATRGet(1)/m_adjusted_point;
//---  RSI OPb/OS Trigger T3
   if(TriggerOne && BB_Spread>BBSpreadH4Min_1 && ATRCur<ATRLim && BB_SpreadM15<BBSpreadM15Max_1)
      RSITriggerOBS(Buy_1,Sell_1);
//--- RSI BB OB/OS Trigger 4       
   if(TriggerTwo && BB_Spread>BBSpreadH4Min_2 && ATRCur<ATRLim && BB_SpreadM15<BBSpreadM15Max_2)
      RSIBBTrigger(Buy_2,Sell_2);
//--- set tradentry                   
   if(Buy_1)
     {
      tradentry=1;
      Take_Profit =  ExtTakeProfit_Buy_1;
      Stop_Loss   =  ExtStopLoss_Buy_1;
     }
   if(Buy_2)
     {
      tradentry=1;
      Take_Profit =  ExtTakeProfit_Buy_2;
      Stop_Loss   =  ExtStopLoss_Buy_2;
     }
   if(Sell_1)
     {
      tradentry=2;
      Take_Profit =  ExtTakeProfit_Sell_1;
      Stop_Loss   =  ExtStopLoss_Sell_1;
     }
   if(Sell_2)
     {
      tradentry=2;
      Take_Profit =  ExtTakeProfit_Sell_2;
      Stop_Loss   =  ExtStopLoss_Sell_2;
     }
//---  Filters        
   if(hour_current>=FridayEndHour && SBarTimeCurrent.day_of_week==5)
      tradentry=0;
//--- Hour of Day Filer    
   if(!HourRange(hour_current,entryhour,openhours))
      tradentry=0;
//---
   if(tradentry==1)
      CtrBuy+=1; // instrumentation
   if(tradentry==2)
      CtrSell+=1;
//---
   if(Positions>=NumPositions)
      tradentry=0;
   if(tradentry>0)
     {
      //--- Open new market order            
      OpenPosition(tradentry,Stop_Loss,Take_Profit,NumPositions);
     }
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
//| Check the correctness of the position volume                     |
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
//| Get Time for specified bar index                                 | 
//+------------------------------------------------------------------+ 
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[1];
   datetime time=0; // datetime "0" -> D'1970.01.01 00:00:00'
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0)
      time=Time[0];
   return(time);
  }
//+-----------------------------------------------------------------------------------+
//| Open New Positions                                                                |
//| Uses externals: magic_number, NumPositions, Currency                              |
//+-----------------------------------------------------------------------------------+   
void OpenPosition(int trade_entry,double Stop_Loss,double Take_Profit,int Num_Positions)
  {
   string NetString;
//--- Open New Orders   
//--- Get new open order total     
   int total_EA=PositionsTotal();
   if(total_EA>=TotOpenOrders)
      return; // max number of positions allowed( all symbols)

   total_EA=CalculateAllPositions();

   if(total_EA<Num_Positions) // open new position if below OpenPosition limit
     {
      if(!RefreshRates())
         return;
      if(trade_entry==1) // Open a Buy
        {
         double sl=(Stop_Loss==0.0)?0.0:m_symbol.Ask()-Stop_Loss;
         double tp=(Take_Profit==0.0)?0.0:m_symbol.Ask()+Take_Profit;
         OpenBuy(sl,tp);
        }
      if(trade_entry==2) // Open a Sell
        {
         double sl=(Stop_Loss==0)?0.0:m_symbol.Bid()+Stop_Loss;
         double tp=(Take_Profit==0)?0.0:m_symbol.Bid()-Take_Profit;
         OpenSell(sl,tp);
        }
     }
   return;
  }
//+------------------------------------------------------------------+
//| Calculate all positions                                          |
//+------------------------------------------------------------------+
int CalculateAllPositions()
  {
   int total=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            total++;
//---
   return(total);
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
//| Get value of buffers for the iBands                              |
//|  the buffer numbers are the following:                           |
//|   0 - BASE_LINE, 1 - UPPER_BAND, 2 - LOWER_BAND                  |
//+------------------------------------------------------------------+
double iBandsGet(const int handle_iBands,const int buffer,const int index)
  {
   double Bands[1];
//ArraySetAsSeries(Bands,true);
//--- reset error code 
   ResetLastError();
//--- fill a part of the iBands array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iBands,buffer,index,1,Bands)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iBands indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Bands[0]);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iRSI                                |
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
//+----------------------------------------------------------+
//| OverBought / OverSold  Trigger 1                         |
//| OverSold: RSI < RSI Low (Buy Trigger)                    |
//| OverBought: RSI > RSI Hi (Sell Trigger)                  |
//+----------------------------------------------------------+
void RSITriggerOBS(bool &TBuy,bool &TSell)
  {
   double RSI_M15_1  = iRSIGet(handle_iRSI_M15_Per_1,1);
   double RSI_M15_2  = iRSIGet(handle_iRSI_M15_Per_1,2);
   double RSI_H1_1   = iRSIGet(handle_iRSI_H1_Per_1,1);
   double RSI_H4_1   = iRSIGet(handle_iRSI_H4_Per_1,0);
   double Delta_M15  = RSI_M15_1-RSI_M15_2;
   double Stoc_M15   = iStochasticGet(MAIN_LINE,1);

   if(RSI_H1_1<RSILoH1_1 && RSI_M15_1<RSILoM15_1 && RSI_H4_1<RSILoH4_1
      && RSI_H4_1>RSILoLimH4_1 && RSI_M15_1>RSILoLimM15_1 && RSI_H1_1>RSILoLimH1_1 && 
      Delta_M15>RDeltaM15_Lim_1 && Stoc_M15<StocLoM15_1)
      TBuy=true;
   if(RSI_H1_1>RSIHiH1_1 && RSI_M15_1>RSIHiM15_1 && RSI_H4_1>RSIHiH4_1
      && RSI_H4_1<RSIHiLimH4_1 && RSI_M15_1<RSIHiLimM15_1 && RSI_H1_1<RSIHiLimH1_1 && 
      Delta_M15<-RDeltaM15_Lim_1 && Stoc_M15>StocHiM15_1)
      TSell=true;

   return;
  }
//+----------------------------------------------------------+
//| OverBought / OverSold Bollinger Band Trigger - Trigger 2 |
//| OverSold: RSI < RSI Upper (Buy Trigger)                  |
//| OverBought: RSI > RSI Lower (Sell Trigger)               |
//+----------------------------------------------------------+
void RSIBBTrigger(bool &TBuy,bool &TSell)
  {
   double RSI_H1_1,RSI_H4_1,RSI_M15_1,RSI_M15_2,DeltaM15;
   double Stoc_M15;
   double RSI_M15Ary[250],RSI_H1Ary[250],RSI_H4Ary[250];  // greater than NumRSI_
   double RSI_M15Avg,RSI_H1Avg,RSI_H4Avg;
   double XMeanM15,XMeanH1,XMeanH4;
   double XSigmaM15P,XSigmaH1P,XSigmaH4P,XSigmaM15M,XSigmaH1M,XSigmaH4M;
   double RSI_M15_Lo,RSI_H1_Lo,RSI_H4_Lo,RSI_M15_Hi,RSI_H1_Hi,RSI_H4_Hi;
   double RSI_LoLimM15_2,RSI_LoLimH1_2,RSI_LoLimH4_2,RSI_HiLimM15_2,RSI_HiLimH1_2,RSI_HiLimH4_2;

   int jj;
//       
   for(jj=0; jj<NumRSI; jj++)
     {
      RSI_M15Ary[jj]=iRSIGet(handle_iRSI_M15_Per_2,jj+1);
     }
//          
   for(jj=0; jj<NumRSI; jj++)
     {
      RSI_H1Ary[jj]=iRSIGet(handle_iRSI_H1_Per_2, jj+1);
      RSI_H4Ary[jj]=iRSIGet(handle_iRSI_H4_Per_2,jj); // start with current bar 
     }
//
   RSI_M15_1   = iRSIGet(handle_iRSI_M15_Per_2, 1);
   RSI_M15_2   = iRSIGet(handle_iRSI_M15_Per_2, 2);
   RSI_H1_1    = iRSIGet(handle_iRSI_H1_Per_2, 1);
   RSI_H4_1=iRSIGet(handle_iRSI_H4_Per_2,0); // use current bar
   DeltaM15= RSI_M15_1 - RSI_M15_2;
//     
   Stoc_M15=iStochasticGet(MAIN_LINE,1);

   DataSigmaAsym(NumRSI,RSI_M15Ary,XMeanM15,XSigmaM15P,XSigmaM15M);    // M15
   RSI_M15Avg = XMeanM15;
   RSI_M15_Lo = RSI_M15Avg - RSIM15_Sigma_2*XSigmaM15M;
   RSI_M15_Hi = RSI_M15Avg + RSIM15_Sigma_2*XSigmaM15P;
   RSI_LoLimM15_2 = RSI_M15Avg - RSIM15_SigmaLim_2*XSigmaM15M;
   RSI_HiLimM15_2 = RSI_M15Avg + RSIM15_SigmaLim_2*XSigmaM15P;
//             
   DataSigmaAsym(NumRSI,RSI_H1Ary,XMeanH1,XSigmaH1P,XSigmaH1M);        // H1
   RSI_H1Avg =  XMeanH1;
   RSI_H1_Lo = RSI_H1Avg  -  RSIH1_Sigma_2*XSigmaH1M;
   RSI_H1_Hi = RSI_H1Avg  +  RSIH1_Sigma_2*XSigmaH1P;
   RSI_LoLimH1_2 = RSI_H1Avg - RSIH1_SigmaLim_2*XSigmaH1M;
   RSI_HiLimH1_2 = RSI_H1Avg + RSIH1_SigmaLim_2*XSigmaH1P;

//               
   DataSigmaAsym(NumRSI,RSI_H4Ary,XMeanH4,XSigmaH4P,XSigmaH4M);        // H4 (using current bar)
   RSI_H4Avg =  XMeanH4;
   RSI_H4_Lo = RSI_H4Avg  -  RSIH4_Sigma_2*XSigmaH4M;
   RSI_H4_Hi = RSI_H4Avg  +  RSIH4_Sigma_2*XSigmaH4P;
   RSI_LoLimH4_2 = RSI_H4Avg - RSIH4_SigmaLim_2*XSigmaH4M;
   RSI_HiLimH4_2 = RSI_H4Avg + RSIH4_SigmaLim_2*XSigmaH4P;
// 
   RSI_M15_Lo=  MathMax(RSI_M15_Lo,5.);
   RSI_H1_Lo =   MathMax(RSI_H1_Lo,  5.);
   RSI_H4_Lo =   MathMax(RSI_H4_Lo, 5.);
   RSI_LoLimM15_2= MathMax(RSI_LoLimM15_2,5.);
   RSI_LoLimH1_2 =  MathMax(RSI_LoLimH1_2,5.);
   RSI_LoLimH4_2 =  MathMax(RSI_LoLimH4_2,5.);
//         
   RSI_M15_Hi=  MathMin(RSI_M15_Hi,95.);
   RSI_H1_Hi =   MathMin(RSI_H1_Hi,95.);
   RSI_H4_Hi =   MathMin(RSI_H4_Hi,95.);
   RSI_HiLimM15_2= MathMin(RSI_HiLimM15_2,95.);
   RSI_HiLimH1_2 =  MathMin(RSI_HiLimH1_2,95.);
   RSI_HiLimH4_2 =  MathMin(RSI_HiLimH4_2,95.);
//     
   if(RSI_H1_1<RSI_H1_Lo && RSI_M15_1<RSI_M15_Lo && RSI_H4_1<RSI_H4_Lo
      && RSI_H4_1>RSI_LoLimH4_2 && RSI_M15_1>RSI_LoLimM15_2 && RSI_H1_1>RSI_LoLimH1_2 && 
      DeltaM15>RDeltaM15_Lim_2 && Stoc_M15<StocLoM15_2) TBuy=true;
//   
   if(RSI_H1_1>RSI_H1_Hi && RSI_M15_1>RSI_M15_Hi && RSI_H4_1>RSI_H4_Hi
      && RSI_H4_1<RSI_HiLimH4_2 && RSI_M15_1<RSI_HiLimM15_2 && RSI_H1_1<RSI_HiLimH1_2 && 
      DeltaM15<-RDeltaM15_Lim_2 && Stoc_M15>StocHiM15_2) TSell=true;
   return;
  }
//+-----------------------------------------------------------------+ 
//| Open trades within a range of hours starting at entry_hour      |
//| Duration of trading window is open_hours                        |
//| open_hours = 0 means open for 1 hour                            |
//+-----------------------------------------------------------------+
bool HourRange(int hour_current,int lentryhour,int lopenhours)
  {
   bool Hour_Test= false;
   int closehour = (int)MathMod((lentryhour+lopenhours),24);
// 
   if(closehour==lentryhour && hour_current==lentryhour)
      Hour_Test=true;

   if(closehour>lentryhour)
     {
      if(hour_current>=lentryhour && hour_current<=closehour)
         Hour_Test=true;
     }

   if(closehour<lentryhour)
     {
      if(hour_current>=lentryhour && hour_current<=23)
         Hour_Test=true;
      if(hour_current>=0 && hour_current<=closehour)
         Hour_Test=true;
     }
   return(Hour_Test);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.Buy(InpLots,m_symbol.Name(),m_symbol.Ask(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print(__FUNCTION__,", #1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print(__FUNCTION__,", #2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< Lots (",DoubleToString(InpLots,2),")");
         return;
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.Sell(InpLots,m_symbol.Name(),m_symbol.Bid(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print(__FUNCTION__,", #1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print(__FUNCTION__,", #2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< Lots (",DoubleToString(InpLots,2),")");
         return;
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return;
     }
//---
  }
//+--------------------------------------------------------------------+
//|   Compute Stnd Dev of array                                        |
//| Return two Sigmas for Plus,Minus sides of distribution             |
//+--------------------------------------------------------------------+  
void  DataSigmaAsym(int NSize,double &A[],double &AMean,double &ASigmaP,double &ASigmaM)
  {
   double  AVarP,AVarM,AVar,ASigma;
   int jj,NPlus,NMinus;
   AMean= 0.;
   AVar = 0.;
   AVarP =  0.;
   AVarM =  0.;
   ASigmaP = 0.;
   ASigmaM = 0.;
   NPlus=0;
   NMinus=0;
//
   if(NSize<3)
     {
      AMean=A[0];
      ASigmaP = 0.3*A[0];
      ASigmaM = 0.3*A[0];
      return;
     }
// Compute mean of  array   
   for(jj=0; jj<NSize; jj++)
     {
      AMean+=A[jj];
     }
   AMean=AMean/NSize;
// Compute Sigma of array     
   for(jj=0; jj<NSize; jj++)
     {
      AVar+=MathPow((A[jj]-AMean),2); // Compute variance of each array
      if(A[jj]>=AMean)
        {
         AVarP+=MathPow((A[jj]-AMean),2); // Compute variance of each array
         NPlus+=1;
        }
      if(A[jj]<AMean)
        {
         AVarM+=MathPow((A[jj]-AMean),2); // Compute variance of each array
         NMinus+=1;
        }
     }
   ASigma=MathSqrt(AVar/NSize);
   ASigmaP=ASigma; // no data case
   ASigmaM= ASigma;
   if(NPlus>0)  ASigmaP = MathSqrt(AVarP/NPlus);
   if(NMinus>0) ASigmaM = MathSqrt(AVarM/NMinus);
   return;
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResult(CTrade &trade,CSymbolInfo &symbol)
  {
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result: "+trade.ResultRetcodeDescription());
   Print("deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("current bid price: "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("current ask price: "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("broker comment: "+trade.ResultComment());
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                           AIS2 Trading Robot.mq5 |
//|                              Copyright © 2018, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
#property version   "1.004"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
//--- < 1. Property 7 >
#property     copyright                 "Copyright (C) 2009, MetaQuotes Software Corp."                      
#property     link                      "https://www.metaquotes.net"                                          
#define       A_System_Series           "AIS"                                                                
#define       A_System_Modification     "20005"                                                              
#define       A_System_ReleaseDate      "2009.03.25"                                                         
#define       A_System_Program          "Trading Robot"                                                       
#define       A_System_Programmer       "Airat Safin                           http://www.mql4.com/users/Ais" 
//--- </1. Property 7 >
//--- < 2. Constants 6 >
#define       A_System_Name             "A System"                                                           
#define       aci_OrderID               20005                                                                
#define       acd_TrailStepping         1.0                                                                   
#define       aci_TradingPause          5                                                                    
string        acs_Operation[]={"Buy","Sell"};
#define       aci_SetupSeparator        1000000000                                                            
//--- </2. Constants 6 >
//--- < 3. Presets 8 >
//--- < 3.1. Risk Management Preset 2 >
input double Inp_aed_AccountReserve       = 0.20; // % допустимого остатка Средст
input double Inp_aed_OrderReserve         = 0.04; // % убытка от Средст
//--- </3.1. Risk Management Preset 2 >
//--- < 3.2. Trading Strategy Preset 6 >
input string aes_Symbol="EURUSD"; // рабочий символ
input ENUM_TIMEFRAMES Inp_aei_Timeframe_1 = PERIOD_M15; // Таймфрейм №1
input ENUM_TIMEFRAMES Inp_aei_Timeframe_2 = PERIOD_M1;  // Таймфрейм №2
input double Inp_aed_TakeFactor           = 1.7;  // Take Factor
input double Inp_aed_StopFactor           = 1.7;  // StopFactor
input double Inp_aed_TrailFactor          = 0.5;  // TrailFactor 
//--- </3.2. Trading Strategy Preset 6 >
//--- </3. Presets 8 >
//--- < 4. Global Variables 84 >
//--- < 4.1. Trading Strategy Interface 4 >
ENUM_ORDER_TYPE   avi_Command=WRONG_VALUE;
double        avd_Price               = -1;
double        avd_Stop                = -1;
double        avd_Take                = -1;
//--- </4.1. Trading Strategy Interface 4 >
//--- < 4.2. System Controls 28 >
int           avi_SystemFlag;
int           avi_TradingFlag;
int           avi_MonitorFlag;
datetime      avi_TimeStamp;
uint          avi_Exception;
int           avi_ExcepionsTrade;
int           avi_ExcepionsTrail;
datetime      avi_TimeStart;
datetime      avi_TimeLastRun;
int           avi_Runs;
int           avi_BuyTrades;
int           avi_SellTrades;
int           avi_TotalTrades;
int           avi_Trailes;
int           avi_AttemptsTrade;
int           avi_AttemptsTrail;
double        avd_Capital;
datetime      avd_PeakTime;
double        avd_InitialEquity;
double        avd_InitialCapital;
double        avd_EquityReserve;
string        avs_Currency[]={ "","","",""};
#define       ari_Account               0
#define       ari_Base                  1
#define       ari_Quote                 2
#define       ari_Margin                3
//--- </4.2. System Controls 28 >
//--- < 4.3. Preset Control 10 >
//--- < 4.3.1. Setup Separators 2 >
string        avs_SetupBegin;
string        avs_SetupEnd;
//--- </4.3.1. Setup Separators 2 >                                                                            
//--- < 4.3.2. Risk Management Preset Setup 2 >                                                                  
string        avs_SetupAccountReserve;
string        avs_SetupOrderReserve;
//--- </4.3.2. Risk Management Preset Setup 2 >                                                                
//--- < 4.3.3. Trading Preset Setup 6 >                                                                           
string        avs_SetupTrading;
string        avs_SetupTimeframe_1;
string        avs_SetupTimeframe_2;
string        avs_SetupTakeFactor;
string        avs_SetupStopFactor;
string        avs_SetupTrailFactor;
//--- </4.3.3. Trading Preset Setup 6 >                                                                         
//--- </4.3. Preset Control 10 >
//--- < 4.5. System Messages 4 >
string        avs_SystemMessage;
string        avs_LocalMessage;
string        avs_SystemStamp;
string        avs_LocalStamp;
//--- </4.4. System Messages 4 >
//--- < 4.5. Common Data 14 >
double        avd_QuoteSpread;
double        avd_QuoteFreeze;
double        avd_QuoteStops;
double        avd_NominalMargin;
//--- </4.5. Common Data 14 >
//--- < 4.6. Trading Strategy Data 15 >
double        avd_Low_1;
double        avd_High_1;
double        avd_Close_1;
double        avd_Low_2;
double        avd_High_2;
double        avd_Close_2;
double        avd_Average_1;
double        avd_Range_1;
double        avd_Range_2;
double        avd_QuoteTake;
double        avd_QuoteStop;
double        avd_QuoteTrail;
double        avd_TrailStep;
//--- </4.6. Trading Strategy Data 15 >
//--- < 4.7. Risk Management Data 9 >
double        avd_QuoteTarget;
double        avd_QuoteRisk;
double        avd_NominalPoint;
int           avi_MarginPoints;
int           avi_RiskPoints;
double        avd_VARLimit;
double        avd_RiskPoint;
double        avd_MarginLimit;
double        avd_SizeLimit;
//--- </4.7. Risk Management Data 9 >
//--- </4. Global Variables 84 >
//--- < 5. Program Initialization 21 >
double Ext_aed_AccountReserve;
double Ext_aed_OrderReserve;
ENUM_TIMEFRAMES Ext_aei_Timeframe_1;
ENUM_TIMEFRAMES Ext_aei_Timeframe_2;
double Ext_aed_TakeFactor;
double Ext_aed_StopFactor;
double Ext_aed_TrailFactor;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!m_symbol.Name(aes_Symbol)) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();

   m_trade.SetExpertMagicNumber(aci_OrderID);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
//---
   Ext_aed_AccountReserve  = Inp_aed_AccountReserve;
   Ext_aed_OrderReserve    = Inp_aed_OrderReserve;
   Ext_aei_Timeframe_1     = Inp_aei_Timeframe_1;
   Ext_aei_Timeframe_2     = Inp_aei_Timeframe_2;
   Ext_aed_TakeFactor      = Inp_aed_TakeFactor;
   Ext_aed_StopFactor      = Inp_aed_StopFactor;
   Ext_aed_TrailFactor     = Inp_aed_TrailFactor;
//--- < 5.1. System Controls Reset 8 >
   avi_TimeStart           = TimeLocal();
   avi_TimeStamp           = TimeLocal();
   avd_PeakTime            = TimeLocal();
   avd_InitialEquity       = m_account.Equity();
   avd_InitialCapital      = m_account.Equity()*(1-Ext_aed_AccountReserve);
   avi_TradingFlag         = 1;
   avi_MonitorFlag         = 1;
//--- </5.1. System Controls Reset 8 >
//--- < 5.2. System Stamp Reset 3 > 
   avs_SystemStamp=A_System_Series+A_System_Modification+A_System_Program;
//--- </5.2. System Stamp Reset 3 >
//--- < 5.3. First Alert 8 >
   Alert(avs_SystemStamp,
         ": Symbol=",aes_Symbol,
         ", Preset=",Ext_aei_Timeframe_1,
         "/",Ext_aei_Timeframe_2,
         "/",DoubleToString(Ext_aed_TakeFactor,1),
         "/",DoubleToString(Ext_aed_StopFactor,1),
         "/",DoubleToString(Ext_aed_TrailFactor,1),
         " ",", Reload code=",UninitializeReason());
//--- </5.3. First Alert 8 > 
//--- < 5.4. Setup Reset 1 > 
   afr_CreateSetup();
//--- </5.4. Setup Reset 1 > 
//--- < 5.5. Monitoring Panel Reset 1 > 
   afr_CreatePanel_1();
//--- </5.5. Monitoring Panel Reset 1 >
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
//--- < 6.1. Setup Deletion 1 >
   afr_DeleteSetup();
//--- </6.1. Setup Deletion 1 >`
//--- < 6.2. Monitoring Panel Deletion 1 >
   afr_DeletePanel_1();
//--- </6.2. Monitoring Panel Deletion 1 >
//--- < 6.3. Final Alert 3 >
   Alert(avs_SystemStamp,": Stop code=",UninitializeReason()
         ,"/",avi_ExcepionsTrade
         ,"/",avi_ExcepionsTrail);
//--- </6.3. Final Alert 3 >
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!RefreshRates())
      return;
//---
//--- < 7.1. System Controls Reset On Enter 75 >                                                                            
//--- < 7.1.2. Live Mode Subroutine 23 >                                                                          
   if(!GlobalVariableCheck(avs_SetupBegin))
      GlobalVariableSet(avs_SetupBegin,aci_SetupSeparator);
   if(!GlobalVariableCheck(avs_SetupAccountReserve))
      GlobalVariableSet(avs_SetupAccountReserve,Ext_aed_AccountReserve);
   if(!GlobalVariableCheck(avs_SetupOrderReserve))
      GlobalVariableSet(avs_SetupOrderReserve,Ext_aed_OrderReserve);
   if(!GlobalVariableCheck(avs_SetupTrading))
      GlobalVariableSet(avs_SetupTrading,avi_TradingFlag);
   if(!GlobalVariableCheck(avs_SetupTimeframe_1))
      GlobalVariableSet(avs_SetupTimeframe_1,Ext_aei_Timeframe_1);
   if(!GlobalVariableCheck(avs_SetupTimeframe_2))
      GlobalVariableSet(avs_SetupTimeframe_2,Ext_aei_Timeframe_2);
   if(!GlobalVariableCheck(avs_SetupTakeFactor))
      GlobalVariableSet(avs_SetupTakeFactor,Ext_aed_TakeFactor);
   if(!GlobalVariableCheck(avs_SetupStopFactor))
      GlobalVariableSet(avs_SetupStopFactor,Ext_aed_StopFactor);
   if(!GlobalVariableCheck(avs_SetupTrailFactor))
      GlobalVariableSet(avs_SetupTrailFactor,Ext_aed_TrailFactor);
   if(!GlobalVariableCheck(avs_SetupEnd))
      GlobalVariableSet(avs_SetupEnd,aci_SetupSeparator);
//--- </7.1.2. Live Mode Subroutine 23 >                                                                          
//--- < 7.1.3. All Modes Subroutine 8 >                                                                           
   if(GlobalVariableGet(avs_SetupTrading)==1)
     {
      avi_SystemFlag         = 1;
      avi_TradingFlag        = 1;
      avs_SystemMessage="Trading is enabled";
     }
   else
     {
      avi_SystemFlag         = 0;
      avi_TradingFlag        = 0;
      avs_SystemMessage="Trading is disabled";
     }
//--- </7.1.3. All Modes Subroutine 8 >                                                                           
//--- < 7.1.4. Live Mode Subroutine 43 >                                                                          
   Ext_aed_AccountReserve=GlobalVariableGet(avs_SetupAccountReserve);
   Ext_aed_OrderReserve       = GlobalVariableGet    ( avs_SetupOrderReserve                              );
   Ext_aei_Timeframe_1        = (ENUM_TIMEFRAMES)GlobalVariableGet    ( avs_SetupTimeframe_1                               );
   Ext_aei_Timeframe_2        = (ENUM_TIMEFRAMES)GlobalVariableGet    ( avs_SetupTimeframe_2                               );
   Ext_aed_TakeFactor         = GlobalVariableGet    ( avs_SetupTakeFactor                                );
   Ext_aed_StopFactor         = GlobalVariableGet    ( avs_SetupStopFactor                                );
   Ext_aed_TrailFactor        = GlobalVariableGet    ( avs_SetupTrailFactor                               );

   if(Ext_aei_Timeframe_1!=PERIOD_M1
      && Ext_aei_Timeframe_1  != PERIOD_M5
      && Ext_aei_Timeframe_1  != PERIOD_M15
      && Ext_aei_Timeframe_1  != PERIOD_M30
      && Ext_aei_Timeframe_1  != PERIOD_H1
      && Ext_aei_Timeframe_1  != PERIOD_H4
      && Ext_aei_Timeframe_1  != PERIOD_D1
      && Ext_aei_Timeframe_1  != PERIOD_W1
      && Ext_aei_Timeframe_1  != PERIOD_MN1 )
     {
      Ext_aei_Timeframe_1=0;
      avi_SystemFlag    = 0;
      avi_TradingFlag   = 0;
      GlobalVariableSet(avs_SetupTimeframe_1,Ext_aei_Timeframe_1);
      GlobalVariableSet(avs_SetupTrading,avi_TradingFlag);
      avs_SystemMessage="Check Timeframe_1";
      Alert(avs_SystemStamp,": Symbol=",
            aes_Symbol," ",avs_SystemMessage);
     }

   if(Ext_aei_Timeframe_2!=PERIOD_M1
      && Ext_aei_Timeframe_2  != PERIOD_M5
      && Ext_aei_Timeframe_2  != PERIOD_M15
      && Ext_aei_Timeframe_2  != PERIOD_M30
      && Ext_aei_Timeframe_2  != PERIOD_H1
      && Ext_aei_Timeframe_2  != PERIOD_H4
      && Ext_aei_Timeframe_2  != PERIOD_D1
      && Ext_aei_Timeframe_2  != PERIOD_W1
      && Ext_aei_Timeframe_2  != PERIOD_MN1 )
     {
      Ext_aei_Timeframe_2=0;
      avi_SystemFlag    = 0;
      avi_TradingFlag   = 0;
      GlobalVariableSet(avs_SetupTimeframe_2,Ext_aei_Timeframe_2);
      GlobalVariableSet(avs_SetupTrading,avi_TradingFlag);
      avs_SystemMessage="Check Timeframe_2";
      Alert(avs_SystemStamp,": Symbol=",
            aes_Symbol," ",avs_SystemMessage);
     }
//--- </7.1.4. Live Mode Subroutine 43 >                                                                          
//--- </7.1. System Controls Reset On Enter 75 >
//--- </7.2. Trading Pause Control 2 >
   if(TimeLocal()-avi_TimeStamp<aci_TradingPause)
     {
      avs_SystemMessage="Trading pause "+IntegerToString(aci_TradingPause)+" seconds";
      avi_SystemFlag=0;
     }
//--- </7.2. Trading Pause Control 2 >`
//--- < 7.3. Equity Control 6 >``````

   if(m_account.Equity() -m_account.Equity()>0)
     {
      avd_PeakTime=TimeLocal();
     }

   avd_Capital=m_account.Equity() *(1-Ext_aed_AccountReserve);
   avd_EquityReserve=m_account.Equity() -avd_Capital;
   avd_VARLimit=m_account.Equity() *Ext_aed_OrderReserve;

   if(avd_EquityReserve-avd_VARLimit<0)
     {
      avs_SystemMessage="System stop";
      avi_SystemFlag=0;
      ExpertRemove();
     }

//--- </7.3. Equity Control 6 >
//--- < 7.4. Data Feed 29 >
//--- < 7.4.1. Common Data 14 >                                                                                   
   avd_QuoteSpread   = m_symbol.Spread()        * m_symbol.Point();
   avd_QuoteFreeze   = m_symbol.FreezeLevel()   * m_symbol.Point();
   avd_QuoteStops    = m_symbol.StopsLevel()    * m_symbol.Point();
   if(!OrderCalcMargin(ORDER_TYPE_BUY,m_symbol.Name(),1.0,m_symbol.Ask(),avd_NominalMargin))
      return;
//--- </7.4.1. Common Data 14 >                                                                                   
//--- < 7.4.2. Trading Strategy Data 15 >                                                                         
   MqlRates rates_tf_1[];
   CopyRates(m_symbol.Name(),Ext_aei_Timeframe_1,1,1,rates_tf_1);
   MqlRates rates_tf_2[];
   CopyRates(m_symbol.Name(),Ext_aei_Timeframe_2,1,1,rates_tf_2);

   avd_Low_1         = rates_tf_1[0].low;
   avd_High_1        = rates_tf_1[0].high;
   avd_Close_1       = rates_tf_1[0].close;

   avd_Low_2         = rates_tf_2[0].low;
   avd_High_2        = rates_tf_2[0].high;
   avd_Close_2       = rates_tf_2[0].close;

   avd_Average_1=(avd_High_1+avd_Low_1)/2;

   avd_Range_1       =              avd_High_1 - avd_Low_1;
   avd_Range_2       =              avd_High_2 - avd_Low_2;

   avd_QuoteTake=avd_Range_1            *Ext_aed_TakeFactor;
   avd_QuoteStop=avd_Range_1             * Ext_aed_StopFactor;
   avd_QuoteTrail=avd_Range_2            *Ext_aed_TrailFactor;

   avd_TrailStep=avd_QuoteSpread        *acd_TrailStepping;
//--- </7.4.2. Trading Strategy Data 15 >                                                                         
//--- </7.4. Data Feed 29 >
//--- < 7.5. Trading Strategy Interface Reset 4 >
   avi_Command       = WRONG_VALUE;
   avd_Price         = -1;
   avd_Stop          = -1;
   avd_Take          = -1;
//--- </7.5. Trading Strategy Interface Reset 4 >
//--- < 7.6. Position Management Module 55 >
//--- < 7.6.1. Position Management Module Entry Point 7 >                                                         
   if(avi_SystemFlag==1)
     {
      for(int i=PositionsTotal()-1;i>=0;i--)
         if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
            if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==aci_OrderID)
              {
               avi_SystemFlag=0;
               //--- </7.6.1. Position Management Module Entry Point 7 >                                                         
               //--- < 7.6.2. Trailing Logic 18 >  
               //--- <  Buy Orders Trailing Rules > 
               if(m_position.PositionType()==POSITION_TYPE_BUY)
                 {
                  if(m_position.Profit()>0)
                     if(NormalizeDouble(avd_QuoteTrail-avd_QuoteStops,m_symbol.Digits())>0)
                        if(NormalizeDouble(avd_QuoteTrail-avd_QuoteFreeze,m_symbol.Digits())>0)
                           if(NormalizeDouble(m_position.TakeProfit()-m_symbol.Bid()-avd_QuoteStops,m_symbol.Digits())>0)
                              if(NormalizeDouble(m_symbol.Bid()-m_position.StopLoss()-avd_TrailStep-avd_QuoteTrail,m_symbol.Digits())>0)
                                 avd_Stop=NormalizeDouble(m_symbol.Bid()-avd_QuoteTrail,m_symbol.Digits());
                  continue;
                  //--- </ Buy Orders Trailing Rules >   
                 }
               //--- <  Sell Orders Trailing Rules > 
               else if(m_position.PositionType()==POSITION_TYPE_SELL)
                 {
                  if(m_position.Profit()>0)
                     if(NormalizeDouble(avd_QuoteTrail-avd_QuoteStops,m_symbol.Digits())>0)
                        if(NormalizeDouble(avd_QuoteTrail-avd_QuoteFreeze,m_symbol.Digits())>0)
                           if(NormalizeDouble(m_symbol.Ask()-m_position.TakeProfit()-avd_QuoteStops,m_symbol.Digits())>0)
                              if(NormalizeDouble(m_position.StopLoss()-m_symbol.Ask()-avd_TrailStep-avd_QuoteTrail,m_symbol.Digits())>0)
                                 avd_Stop=NormalizeDouble(m_symbol.Ask()+avd_QuoteTrail,m_symbol.Digits());
                  continue;
                 }
               //--- </ Sell Orders Trailing Rules >                                                                    
               //--- </7.6.2. Trailing Logic 18 >                                                                                
               //--- < 7.6.3. Order Modify Trading Function 28 >  
               if(avd_Stop>0)
                 {
                  int  ali_TrailPoints=(int)MathRound(MathAbs(m_position.StopLoss()-avd_Stop)/m_symbol.Point());
                  if(ali_TrailPoints>=m_symbol.FreezeLevel())
                    {
                     //--- < Trading Function Execution Sequence >                                                      
                     //--- < Step 1 >                                                                                   
                     avs_LocalStamp=avs_SystemStamp+": Attempt to trail "+
                                    aes_Symbol+" "+
                                    acs_Operation[m_position.PositionType()]+" #"+
                                    IntegerToString(m_position.Magic())+"/"+
                                    IntegerToString(m_position.Ticket());
                     //--- < Step 2 >                                                                                   
                     Alert(avs_LocalStamp," +",
                           ali_TrailPoints," from ",
                           DoubleToString(m_position.StopLoss(),m_symbol.Digits())," to ",
                           DoubleToString(avd_Stop,m_symbol.Digits()));
                     //--- < Step 3 >   
                     m_trade.PositionModify(m_position.Ticket(),
                                            m_symbol.NormalizePrice(avd_Stop),
                                            m_position.TakeProfit());
                     //--- < Step 4 >                                                                                   
                     avi_TimeStamp=TimeLocal();
                     //--- < Step 5 >                                                                                   
                     avi_Exception=GetLastError();
                     //--- < Step 6 >                                                                                   
                     if(avi_Exception!=0)
                        avs_LocalMessage=" Success ";
                     else
                        avs_LocalMessage=" Failure "+IntegerToString(avi_Exception);
                     //--- < Step 7 >                                                                                   
                     avi_AttemptsTrail++;
                     if(avi_Exception==0)
                        avi_Trailes++;
                     else
                        avi_ExcepionsTrail++;
                     //--- < Step 8 >                                                                                   
                     Alert(avs_LocalStamp+avs_LocalMessage);
                     //--- < Step 9 >                                                                                   
                     avs_SystemMessage="Trailing Stop"+avs_LocalMessage;
                     //--- </Trading Function Execution Sequence >                                                           
                    } // if 7.6.3                                                                                
                 } // if 7.6.3                                                                                     
               //--- </7.6.3. Order Modify Trading Function 28 >                                                                 
               //--- < 7.6.4. Position Management Module Exit Point 2 >   
              }
     }
//--- </7.6.4. Position Management Module Exit Point 2 >                                                          
//--- </7.6. Position Management Module 55 >
//--- < 7.7. Trading Strategy Logic 33 >
//--- < 7.7.1. Trading Strategy Entry Point 2 >                                                                   
   if(avi_SystemFlag==1)
     {
      //--- </7.7.1. Trading Strategy Entry Point 2 >                                                                   
      //--- < 7.7.2. Buy Rules 2 >                                                                                      
      if(NormalizeDouble(avd_Close_1-avd_Average_1,m_symbol.Digits())>0)
         if(NormalizeDouble(m_symbol.Ask() -(avd_High_1+avd_QuoteSpread),m_symbol.Digits())>0)
            //--- </7.7.2. Buy Rules 2 >                                                                                      
            //--- < 7.7.3. Trading Strategy Interface Set for Buy 8 >                                                         
           {
            avd_Price   = NormalizeDouble(m_symbol.Ask()                              ,m_symbol.Digits());
            avd_Stop    = NormalizeDouble(avd_High_1 + avd_QuoteSpread - avd_QuoteStop,m_symbol.Digits());
            avd_Take    = NormalizeDouble(m_symbol.Ask()               + avd_QuoteTake,m_symbol.Digits());
            if(NormalizeDouble((avd_Take-avd_Price)-avd_QuoteStops,m_symbol.Digits())>0)
               if(NormalizeDouble((avd_Price-avd_QuoteSpread-avd_Stop)-avd_QuoteStops,m_symbol.Digits())>0)
                  avi_Command=ORDER_TYPE_BUY;
           }
      //--- </7.7.3. Trading Strategy Interface Set for Buy 8 >                                                         
      //--- < 7.7.4. Sell Rules 2 >                                                                                     
      if(NormalizeDouble(avd_Close_1-avd_Average_1,m_symbol.Digits())<0)
         if(NormalizeDouble(m_symbol.Bid()-avd_Low_1,m_symbol.Digits())<0)
            //--- </7.7.4. Sell Rules 2 >                                                                                     
            //--- < 7.7.5. Trading Strategy Interface Set for Sell 8 >                                                        
           {
            avd_Price   = NormalizeDouble(m_symbol.Bid()                              ,m_symbol.Digits());
            avd_Stop    = NormalizeDouble(avd_Low_1                    + avd_QuoteStop,m_symbol.Digits());
            avd_Take    = NormalizeDouble(m_symbol.Bid()               - avd_QuoteTake,m_symbol.Digits());
            if(NormalizeDouble((avd_Price-avd_Take)-avd_QuoteStops,m_symbol.Digits())>0)
               if(NormalizeDouble((avd_Stop-avd_Price-avd_QuoteSpread)-avd_QuoteStops,m_symbol.Digits())>0)
                  avi_Command=ORDER_TYPE_SELL;
           }
      //--- </7.7.5. Trading Strategy Interface Set for Sell 8 >                                                        
      //--- < 7.7.6. Trading Strategy Exit Point 1 >                                                                    
     } // if 7.7.1                                                                                              
//--- </7.7.6. Trading Strategy Exit Point 1 >                                                                    
//--- </7.7. Trading Strategy Logic 33 >
//--- < 7.8. Trading Module 59 >
//--- < 7.8.1. Trading Module Entry Point 3 >                                                                     
   if(avi_Command>WRONG_VALUE)
      if(IsTradeAllowed())
        {
         //--- </7.8.1. Trading Module Entry Point 3 >                                                                     
         //--- < 7.8.2. Risk Management 9 >                                                                                
         avd_QuoteTarget      = MathAbs               (avd_Price           - avd_Take        );
         avd_QuoteRisk        = MathAbs               (avd_Price           - avd_Stop        );
         avd_NominalPoint     = m_symbol.TickValue()  * m_symbol.Point()/m_symbol.TickSize();
         avi_MarginPoints     = (int)MathRound        (avd_NominalMargin   / avd_NominalPoint);
         avi_RiskPoints       = (int)MathRound        (avd_QuoteRisk       / m_symbol.Point());
         avd_VARLimit         = m_account.Equity()    * Ext_aed_OrderReserve;
         avd_RiskPoint        = avd_VARLimit/avi_RiskPoints;
         avd_MarginLimit      = avd_RiskPoint         * avi_MarginPoints;
         avd_SizeLimit        = avd_MarginLimit/avd_NominalMargin;
         //--- </7.8.2. Risk Management 9 >                                                                                
         //--- < 7.8.3. Operation Size Control 17 >     
         double ald_Size=0.0;
         if(avd_SizeLimit>=m_symbol.LotsMin())
           {
            int ali_Steps=(int)MathFloor(( avd_SizeLimit-m_symbol.LotsMin())/m_symbol.LotsStep());
            ald_Size=m_symbol.LotsMin()+m_symbol.LotsStep() *ali_Steps;
           }
         else
            ald_Size=0;

         if(ald_Size>m_symbol.LotsMax())
            ald_Size=m_symbol.LotsMax();

         double ald_MarginCheck=0.0;
         if(ald_Size>=m_symbol.LotsMin())
            ald_MarginCheck=m_account.FreeMarginCheck(aes_Symbol,avi_Command,ald_Size,
                                                      (avi_Command==ORDER_TYPE_BUY)?m_symbol.Ask():m_symbol.Bid());
         else
            ald_MarginCheck=-1;

         double ald_Margin=0.0;
         double ald_Contract=0.0;
         double ald_VAR=0.0;
         double ald_Target=0.0;

         if(ald_MarginCheck<=0.0)
            avi_SystemFlag=0;
         else
           {
            ald_Margin=m_account.FreeMargin()-ald_MarginCheck;
            ald_Contract=ald_Size       *avd_NominalPoint/m_symbol.Point();
            ald_VAR=avd_QuoteRisk       *ald_Contract;
            ald_Target=avd_QuoteTarget  *ald_Contract;
           }
         //--- </7.8.3. Operation Size Control 17 >                                                                        
         //--- < 7.8.4. Order Send Trading Function 29 >                                                                   
         if(avi_SystemFlag==1)
           {
            //--- < Trading Function Execution Sequence >                                                           
            //--- < Step 1 >                                                                                        
            avs_LocalStamp=avs_SystemStamp+": Attempt to "+
                           acs_Operation[avi_Command]+" "+
                           DoubleToString(ald_Size,2)+" "+
                           aes_Symbol+" at "+
                           DoubleToString(avd_Price,m_symbol.Digits())+" sl: "+
                           DoubleToString(avd_Stop,m_symbol.Digits())+" tp: "+
                           DoubleToString(avd_Take,m_symbol.Digits())+" //";
            //--- < Step 2 >                                                                                        
            Alert(avs_LocalStamp," Margin: ",
                  DoubleToString(ald_Margin,2)," / VAR: -",
                  DoubleToString(ald_VAR,2)," / Target: ",
                  DoubleToString(ald_Target,2));
            //--- < Step 3 >                                                                                        
            m_trade.PositionOpen(aes_Symbol,avi_Command,ald_Size,
                                 avd_Price,avd_Stop,avd_Take);
            ulong ali_Ticket=m_trade.ResultDeal();
            //--- < Step 4 >                                                                                        
            avi_TimeStamp=TimeLocal();
            //--- < Step 5 >                                                                                        
            avi_Exception=m_trade.ResultRetcode();
            //--- < Step 6 >                                                                                        
            if(avi_Exception!=0)
               avs_LocalMessage=" Success "+IntegerToString(ali_Ticket);
            else
               avs_LocalMessage=" Failure "+IntegerToString(avi_Exception);
            //--- < Step 7 >                                                                                        
            avi_AttemptsTrade++;
            if(avi_Exception==0)
              {
               if(avi_Command==ORDER_TYPE_BUY)
                  avi_BuyTrades++;
               else
                  avi_SellTrades++;
               avi_TotalTrades++;
              }
            else
               avi_ExcepionsTrade++;
            //--- < Step 8 >                                                                                        
            Alert(avs_LocalStamp+avs_LocalMessage);
            //--- < Step 9 >                                                                                        
            avs_SystemMessage=acs_Operation[avi_Command]+avs_LocalMessage;
            //--- </Trading Function Execution Sequence >                                                               
           } // if 7.8.4                                                                                     
         //--- </7.8.4. Order Send Trading Function 29 >                                                                   

         //--- < 7.8.5. Trading Module Exit Point 1 >                                                                      
        } // if 7.8.1                                                                                            
//--- </7.8.5. Trading Module Exit Point 1 >                                                                      
//--- </7.8. Trading Module 59 >
//--- < 7.9. Monitoring Module 1 >
   afr_Monitoring();
//--- </7.9. Monitoring Module 1 >
//--- < 7.10. System Controls Reset On Exit 2 >
   avi_TimeLastRun=TimeLocal();
   avi_Runs++;
//--- </7.10. System Controls Reset On Exit 2 >
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
//--- </7. Main Program 266 >=====================================================================================
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//--- < 8. Extra Code >===========================================================================================

//--- < A_System_Extra: Data 23 >````

#define acs_FontName                    "Courier New"                                                         
#define aci_TextLines                   32                                                                    
#define aci_TextColumns                 64                                                                    

#define acs_Blank                       "                                                                "    
#define aci_Right                       1                                                                     
#define aci_Left                        0                                                                     

string  abs_TextBuffer_1[aci_TextLines];
string  avs_BufferName_1[aci_TextLines];

#define ari_Panel_1                     0                                                                     
#define ari_FontSize                    1                                                                     
#define ari_FontColor                   2                                                                     
#define ari_LineSpace                   3                                                                     
#define ari_PositionX                   4                                                                     
#define ari_PositionY                   5                                                                     

int  arv_Panel_1[]=
  {
   ari_Panel_1,
   8,
   White,
   2.0,
   0,
   10
  };

string  arn_Panel_1[]=
  {
   "Panel_1",
   "FontSize",
   "FontColor",
   "LineSpace",
   "PositionX",
   "PositionY"
  };
string  avs_SetupPrefix;
string  avs_SetupMonitor;
string  avs_SetupFontSize;
string  avs_SetupFontColor;
string  avs_SetupLineSpace;
string  avs_SetupPositionX;
string  avs_SetupPositionY;
//--- < A_System_Extra: Function 01 >
void    afr_Monitoring()
  {
//--- < 1.1. Monitoring Control 11 >                                                                              
   if(!GlobalVariableCheck(avs_SetupMonitor))
      GlobalVariableSet(avs_SetupMonitor,avi_MonitorFlag);

   if(GlobalVariableGet(avs_SetupMonitor)==1)
     {
      if(avi_MonitorFlag==0)
        {
         avi_MonitorFlag=1;
         afr_CreatePanel_1();
        }
      afr_ResetPanel_1();
     }

   else
     {
      if(avi_MonitorFlag==1)
        {
         avi_MonitorFlag=0;
         afr_DeleteSetup();
         afr_DeletePanel_1();
        }
      return;
     }
//--- </1.1. Monitoring Control 11 >                                                                              

//--- < 1.2. Setup Reset 1 >                                                                                      
   afr_ResetSetup();
//--- </1.2. Setup Reset 1 >                                                                                      
  }
//--- </A_System_Extra: Function 01 >
//--- < A_System_Extra: Function 02 >
void    afr_CreateSetup()
  {
   avs_SetupPrefix=A_System_Series+A_System_Modification+".Setup.";
   avs_SetupBegin=avs_SetupPrefix+"0.Begin.=============================";
   avs_SetupAccountReserve        = avs_SetupPrefix+"1.1."+"AccountReserve";
   avs_SetupOrderReserve          = avs_SetupPrefix+ "1.2."+ "OrderReserve";
   avs_SetupTrading=avs_SetupPrefix+"2.1."+"Trading";
   avs_SetupTimeframe_1           = avs_SetupPrefix           + "2.2." + "Timeframe_1";
   avs_SetupTimeframe_2           = avs_SetupPrefix           + "2.3." + "Timeframe_2";
   avs_SetupTakeFactor            = avs_SetupPrefix           + "2.4." + "TakeFactor";
   avs_SetupStopFactor            = avs_SetupPrefix           + "2.5." + "StopFactor";
   avs_SetupTrailFactor=avs_SetupPrefix+"2.6."+"TrailFactor";
   avs_SetupMonitor=avs_SetupPrefix+"3.1."+"Monitor";
   avs_SetupFontSize              = avs_SetupPrefix           + "3.2." + arn_Panel_1  [ ari_FontSize  ];
   avs_SetupFontColor             = avs_SetupPrefix           + "3.3." + arn_Panel_1  [ ari_FontColor ];
   avs_SetupLineSpace             = avs_SetupPrefix           + "3.4." + arn_Panel_1  [ ari_LineSpace ];
   avs_SetupPositionX             = avs_SetupPrefix           + "3.5." + arn_Panel_1  [ ari_PositionX ];
   avs_SetupPositionY             = avs_SetupPrefix           + "3.6." + arn_Panel_1  [ ari_PositionY ];
   avs_SetupEnd                   = avs_SetupPrefix           + "9.End.===============================";

   GlobalVariableSet(avs_SetupBegin,aci_SetupSeparator);
   GlobalVariableSet(avs_SetupAccountReserve,Ext_aed_AccountReserve);
   GlobalVariableSet(avs_SetupOrderReserve,Ext_aed_OrderReserve);
   GlobalVariableSet(avs_SetupTrading,avi_TradingFlag);
   GlobalVariableSet(avs_SetupTimeframe_1,Ext_aei_Timeframe_1);
   GlobalVariableSet(avs_SetupTimeframe_2,Ext_aei_Timeframe_2);
   GlobalVariableSet(avs_SetupTakeFactor,Ext_aed_TakeFactor);
   GlobalVariableSet(avs_SetupStopFactor,Ext_aed_StopFactor);
   GlobalVariableSet(avs_SetupTrailFactor,Ext_aed_TrailFactor);
   GlobalVariableSet(avs_SetupMonitor,avi_MonitorFlag);
   GlobalVariableSet(avs_SetupFontSize,arv_Panel_1[ari_FontSize]);
   GlobalVariableSet(avs_SetupFontColor,arv_Panel_1[ari_FontColor]);
   GlobalVariableSet(avs_SetupLineSpace,arv_Panel_1[ari_LineSpace]);
   GlobalVariableSet(avs_SetupPositionX,arv_Panel_1[ari_PositionX]);
   GlobalVariableSet(avs_SetupPositionY,arv_Panel_1[ari_PositionY]);
   GlobalVariableSet(avs_SetupEnd,aci_SetupSeparator);
  }
//--- </A_System_Extra: Function 02 >
//--- < A_System_Extra: Function 03 >
void    afr_DeleteSetup() //    1 
  {
   GlobalVariablesDeleteAll(avs_SetupPrefix);
  }
//--- </A_System_Extra: Function 03 >

//--- < A_System_Extra: Function 04 >

void    afr_ResetSetup() //   19 
  {
   if(!GlobalVariableCheck(avs_SetupBegin))
      GlobalVariableSet(avs_SetupBegin,aci_SetupSeparator);

   if(!GlobalVariableCheck(avs_SetupFontSize))
      GlobalVariableSet(avs_SetupFontSize,arv_Panel_1[ari_FontSize]);
   else
      arv_Panel_1[ari_FontSize]=(int)GlobalVariableGet(avs_SetupFontSize);

   if(!GlobalVariableCheck(avs_SetupFontColor))
      GlobalVariableSet(avs_SetupFontColor,arv_Panel_1[ari_FontColor]);
   else
      arv_Panel_1[ari_FontColor]=(int)GlobalVariableGet(avs_SetupFontColor);

   if(!GlobalVariableCheck(avs_SetupLineSpace))
      GlobalVariableSet(avs_SetupLineSpace,arv_Panel_1[ari_LineSpace]);
   else
      arv_Panel_1[ari_LineSpace]=(int)GlobalVariableGet(avs_SetupLineSpace);

   if(!GlobalVariableCheck(avs_SetupPositionX))
      GlobalVariableSet(avs_SetupPositionX,arv_Panel_1[ari_PositionX]);
   else
      arv_Panel_1[ari_PositionX]=(int)GlobalVariableGet(avs_SetupPositionX);

   if(!GlobalVariableCheck(avs_SetupPositionY))
      GlobalVariableSet(avs_SetupPositionY,arv_Panel_1[ari_PositionY]);
   else
      arv_Panel_1[ari_PositionY]=(int)GlobalVariableGet(avs_SetupPositionY);

   if(!GlobalVariableCheck(avs_SetupEnd))
      GlobalVariableSet(avs_SetupEnd,aci_SetupSeparator);
  }
//--- </A_System_Extra: Function 04 >

//--- < A_System_Extra: Function 05 >
void    afr_CreatePanel_1() //    5 
  {
   static int     i,N=aci_TextLines;
   for(i=0; i<N;       i++)
     {
      abs_TextBuffer_1[i]="";
      avs_BufferName_1[i]=A_System_Series+A_System_Modification+".TextBuffer_"+IntegerToString(i);
      afr_ResetTextLine_1(i);
     }
  }
//--- </A_System_Extra: Function 05 >

//--- < A_System_Extra: Function 06 >
void    afr_DeletePanel_1() //    3 
  {
   static int     i,N=aci_TextLines;
   for(i=0; i<N; i++)
      ObjectDelete(0,avs_BufferName_1[i]);
  }
//--- </A_System_Extra: Function 06 >

//--- < A_System_Extra: Function 07 >
void    afr_ResetPanel_1() //    7 
  {
   static int     i,N=aci_TextLines;

   for(i=0; i<N;       i++)
     {
      abs_TextBuffer_1[i]=" ";
      afr_SetTextLine_1(i);
     }

   afr_Report_1();

   for(i=0; i<N;       i++)
      afr_SetTextLine_1(i);
  }
//--- </A_System_Extra: Function 07 >

//--- < A_System_Extra: Function 08 >
void afr_ResetTextLine_1(int aai_Line)
  {
   static string   als_Name; als_Name=avs_BufferName_1[aai_Line];

   ObjectCreate(0,als_Name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,als_Name,OBJPROP_XDISTANCE,arv_Panel_1[ari_FontSize]*arv_Panel_1[ari_PositionX]);
   ObjectSetInteger(0,als_Name,OBJPROP_YDISTANCE,
                    arv_Panel_1[ari_FontSize]*(arv_Panel_1[ari_PositionY]+aai_Line*arv_Panel_1[ari_LineSpace]));
   ObjectSetString(0,als_Name,OBJPROP_TEXT,abs_TextBuffer_1[aai_Line]);
   ObjectSetString(0,als_Name,OBJPROP_FONT,acs_FontName);
   ObjectSetInteger(0,als_Name,OBJPROP_FONTSIZE,arv_Panel_1[ari_FontSize]);
   ObjectSetInteger(0,als_Name,OBJPROP_COLOR,arv_Panel_1[ari_FontColor]);
  }
//--- </A_System_Extra: Function 08 >
//--- < A_System_Extra: Function 09 >
void    afr_SetTextLine_1(int     aai_Line)
  {
   static string als_Name;
   als_Name=avs_BufferName_1[aai_Line];

   ObjectSetString(0,als_Name,OBJPROP_TEXT,abs_TextBuffer_1[aai_Line]);
   ObjectSetString(0,als_Name,OBJPROP_FONT,acs_FontName);
   ObjectSetInteger(0,als_Name,OBJPROP_FONTSIZE,arv_Panel_1[ari_FontSize]);
   ObjectSetInteger(0,als_Name,OBJPROP_COLOR,arv_Panel_1[ari_FontColor]);
  }
//--- </A_System_Extra: Function 09 >

//--- < A_System_Extra: Function 10 >
void    afr_SetText_1(int     aai_Line,
                      int     aai_Position,
                      int     aai_Indent,
                      string  aas_Text)
  {
   static int     ali_Begin; ali_Begin=aai_Position-StringLen(aas_Text)*aai_Indent;

   if(aai_Indent==0) ali_Begin        --;

   if(ali_Begin<=0) abs_TextBuffer_1[aai_Line]=aas_Text;

   else
     {
      int     ali_BufferLength=StringLen(abs_TextBuffer_1[aai_Line]);
      if(ali_Begin>ali_BufferLength)
         abs_TextBuffer_1[aai_Line]=abs_TextBuffer_1[aai_Line]+
                                    StringSubstr(acs_Blank,0,ali_Begin-ali_BufferLength)+aas_Text;
      else    abs_TextBuffer_1[aai_Line]=
                                         StringSubstr(abs_TextBuffer_1[aai_Line],0,ali_Begin)+aas_Text;
     }
  }
//--- </A_System_Extra: Function 10 >

//--- < A_System_Extra: Function 11 >
void    afr_Report_1() //  234 
  {
//--- < 11.1. Header 3 >                                                                                          
   static int ali_Trigger;
   static string als_Header;
   if(!ali_Trigger)
     {
      ali_Trigger=1;
      als_Header=A_System_Series+A_System_Modification+" "+A_System_Program;
     }
   afr_SetText_1(0,1,0,als_Header+": "+avs_SystemMessage);
//--- </11.1. Header 3 >                                                                                          
//--- < 11.2. Currency Set Initialization 1 >
   afr_CurrencyDetector(aes_Symbol,avs_Currency);
//--- </11.2. Currency Set Initialization 1 >
//--- < 11.3. First Cluster: System Report 11 >                                                                   
   afr_SetText_1(2,1,0,"Client Time: "+afs_Time(TimeLocal(),1)+" / ");
   afr_SetText_1(3,1,0,"Client Name: "+m_account.Name());
   afr_SetText_1(4,1,0,"Server Name: "+m_account.Server());
   afr_SetText_1(5,1,0,"Server Time: "+afs_Time(TimeCurrent(),1)+" / ");

   afr_SetText_1(2,48,1,afs_Interval((long)TimeLocal()-(long)avi_TimeStart,1)+" / ");
   afr_SetText_1(5,48,1,afs_Interval((long)TimeLocal()-(long)avi_TimeLastRun,1)+" / ");

   afr_SetText_1(2,49,0,IntegerToString(avi_BuyTrades)+"+"+
                 IntegerToString(avi_SellTrades)+"="+
                 IntegerToString(avi_TotalTrades)+"/"+IntegerToString(avi_Trailes));

   afr_SetText_1(5,49,0,IntegerToString(avi_Runs)+"/"+
                 IntegerToString(avi_AttemptsTrade)+"/"+IntegerToString(avi_AttemptsTrail));
//--- </11.3. First Cluster: System Report 11 >                                                                   
//--- < 11.4. Second Cluster: Capital Management Report 57 >                                                      
   double ald_DrawdownAbs       = m_account.Equity     ()   - m_account.Equity();
   double ald_DrawdownRel       = ald_DrawdownAbs        / m_account.Equity();
   double ald_CapitalAbs=m_account.Equity()         *(1-Ext_aed_AccountReserve);
   double ald_CapitalRel=1-Ext_aed_AccountReserve;
   double ald_CapitalGainAbs=avd_Capital-avd_InitialCapital;
   double ald_CapitalGainRel=ald_CapitalGainAbs/avd_InitialCapital*100;
   double ald_EquityGainAbs=m_account.Equity() -avd_InitialEquity;
   double ald_EquityGainRel=ald_EquityGainAbs/avd_InitialEquity *100;
   double ald_EquityReserveAbs  = m_account.Equity     ()   - ald_CapitalAbs;
   double ald_EquityReserveRel  = ald_EquityReserveAbs   / m_account.Equity();
   double ald_AccountEquityAbs=m_account.Equity();
   double ald_AccountEquityRel=m_account.Equity() /m_account.Equity();
   double ald_AccountFreeMargin=m_account.FreeMargin();
   double ald_MarginLevel;
   string als_StopoutLevelAbs;
   string als_StopoutLevelRel;

   if(m_account.Margin()>0) ald_MarginLevel=m_account.Equity()/m_account.Margin();
   else                           ald_MarginLevel=0;

   if(m_account.StopoutMode()==ACCOUNT_STOPOUT_MODE_PERCENT)
     {
      als_StopoutLevelAbs=DoubleToString(m_account.MarginStopOut()*m_account.Equity()/100,2);
      als_StopoutLevelRel+=DoubleToString(m_account.MarginStopOut(),2)+".00%";
     }
   else
     {
      als_StopoutLevelAbs=DoubleToString(m_account.MarginStopOut(),2)+".00";
      als_StopoutLevelRel=DoubleToString(m_account.MarginStopOut()/m_account.Equity() *100,2)+"%";
     }

   string als_GainSign="";
   if(ald_EquityGainAbs>0)
      als_GainSign="+";
   else
      als_GainSign="";

   afr_SetText_1(7,1,0,"Capital "+avs_Currency[ari_Account]+":");
   afr_SetText_1(8,1,0,"Reserve:");
   afr_SetText_1(9,1,0,"Peak Equity:");
   afr_SetText_1(10,1,0,"Drawdown:");
   afr_SetText_1(11,1,0,"Acc. Equity:");
   afr_SetText_1(12,1,0,"Free Margin:");

   afr_SetText_1(7,23,1,DoubleToString(ald_CapitalAbs,2));
   afr_SetText_1(8,23,1,DoubleToString(ald_EquityReserveAbs,2));
   afr_SetText_1(9,23,1,DoubleToString(m_account.Equity(),2));
   afr_SetText_1(10,23,1,DoubleToString(ald_DrawdownAbs,2));
   afr_SetText_1(11,23,1,DoubleToString(ald_AccountEquityAbs,2));
   afr_SetText_1(12,23,1,DoubleToString(ald_AccountFreeMargin,2));

   afr_SetText_1(7,32,1,DoubleToString(ald_CapitalRel      *100,2)+"%");
   afr_SetText_1(7,45,1,"+"+DoubleToString(ald_CapitalGainAbs,2));
   afr_SetText_1(7,54,1,"+"+DoubleToString(ald_CapitalGainRel,2)+"%");
   afr_SetText_1(8,32,1,DoubleToString(ald_EquityReserveRel*100,2)+"%");
   afr_SetText_1(9,32,1,DoubleToString(100,2)+"%");
   afr_SetText_1(9,45,1,afs_Interval(TimeLocal()-avd_PeakTime,1));
   afr_SetText_1(10,32,1,DoubleToString(ald_DrawdownRel     *100,2)+"%");
   afr_SetText_1(11,32,1,DoubleToString(ald_AccountEquityRel*100,2)+"%");
   afr_SetText_1(11,45,1,als_GainSign+DoubleToString(ald_EquityGainAbs,2));
   afr_SetText_1(11,54,1,als_GainSign+DoubleToString(ald_EquityGainRel,2)+"%");
   afr_SetText_1(12,32,1,DoubleToString(ald_MarginLevel     *100,2)+"%");
   afr_SetText_1(12,45,1,als_StopoutLevelAbs);
   afr_SetText_1(12,54,1,als_StopoutLevelRel);
//--- </11.4. Second Cluster: Capital Management Report 57 >                                                      
//--- < 11.5. Third Cluster: Position Management Report 97 >                                                      
   double ald_VARLimit=m_account.Equity() *Ext_aed_OrderReserve;
   double ali_LotSize=m_symbol.ContractSize();
   double ald_NominalPoint=m_symbol.TickValue() *m_symbol.Point()/m_symbol.TickSize();
   int    ali_MarginPoints;
   if(ald_NominalPoint>0)
      ali_MarginPoints=(int)MathRound(avd_NominalMargin/ald_NominalPoint);
   else
      ali_MarginPoints=0;

   string als_OrderCurrency[]={"","","",""};

   string als_OrderType="";
   double ald_ContractSize  = 0;
   double ald_ContractValue = 0;
   double ald_OrderPoint    = 0;
   int    ali_OrderLifetime = 0;

   double ald_QuotePrice    = 0;
   double ald_QuoteTake     = 0;
   double ald_QuoteStop     = 0;
   double ald_QuoteTarget   = 0;
   double ald_QuoteVAR      = 0;

   int    ali_OrderProfit   = 0;
   int    ali_OrderTarget   = 0;
   int    ali_OrderVAR      = 0;

   double ald_OrderProfit   = 0;
   double ald_OrderTarget   = 0;
   double ald_OrderVAR      = 0;


   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==aci_OrderID)
           {
            afr_CurrencyDetector(m_position.Symbol(),als_OrderCurrency);
            ald_ContractSize  = m_position.Volume();
            ald_ContractValue = ald_ContractSize/m_symbol.Point() * ald_NominalPoint;
            ald_OrderPoint    = ald_NominalPoint                  * ald_ContractSize;
            ali_OrderLifetime = (int)(TimeCurrent()-m_position.Time());
            ald_QuotePrice    = m_position.PriceOpen  ();
            ald_QuoteTake     = m_position.TakeProfit ();
            ald_QuoteStop     = m_position.StopLoss   ();
            ald_QuoteTarget=MathAbs(ald_QuotePrice-ald_QuoteTake);

            if(m_position.PositionType()==POSITION_TYPE_BUY)
               ald_QuoteVAR=ald_QuoteStop-ald_QuotePrice;
            else
               ald_QuoteVAR=ald_QuotePrice-ald_QuoteStop;

            ald_OrderProfit   = m_position.Profit();
            ald_OrderTarget   = ald_QuoteTarget       * ald_ContractValue;
            ald_OrderVAR      = ald_QuoteVAR          * ald_ContractValue;

            ali_OrderProfit   = (int)MathRound        ( ald_OrderProfit / ald_OrderPoint );
            ali_OrderTarget   = (int)MathRound        ( ald_QuoteTarget / m_symbol.Point() );
            ali_OrderVAR      = (int)MathRound        ( ald_QuoteVAR    / m_symbol.Point() );

            als_OrderType="#"+IntegerToString(m_position.Ticket())+" "+
                          acs_Operation[m_position.PositionType()]+" "+
                          DoubleToString(ald_ContractSize,2)+" x "+
                          DoubleToString(ali_LotSize,0)+" "+
                          als_OrderCurrency[ari_Margin]+" / "+
                          IntegerToString(ali_MarginPoints)+" x "+
                          DoubleToString(ald_OrderPoint,2);
           }
   string als_OPSign="";
   if(ald_OrderProfit>0)
      als_OPSign="+";
   else
      als_OPSign="";

   string als_OTSign="";
   if(ald_OrderTarget>0)
      als_OTSign="+";
   else
      als_OTSign="";

   string als_OVSign="";
   if(ald_OrderVAR>0)
      als_OVSign="+";
   else
      als_OVSign="";

   afr_SetText_1(14,1,0,"Order:");
   afr_SetText_1(15,1,0,"Profit:");
   afr_SetText_1(16,1,0,"Target:");
   afr_SetText_1(17,1,0,"VAR:");
   afr_SetText_1(18,1,0,"Limit:");

   afr_SetText_1(14,14,0,als_OrderType);
   afr_SetText_1(15,23,1,als_OPSign+DoubleToString(ald_OrderProfit,2));
   afr_SetText_1(15,32,1,als_OPSign+IntegerToString(ali_OrderProfit));
   afr_SetText_1(15,45,1,afs_Interval(ali_OrderLifetime,1));
   afr_SetText_1(16,23,1,als_OTSign+DoubleToString(ald_OrderTarget,2));
   afr_SetText_1(16,32,1,als_OTSign+IntegerToString(ali_OrderTarget));
   afr_SetText_1(17,23,1,als_OVSign+DoubleToString(ald_OrderVAR,2));
   afr_SetText_1(17,32,1,als_OVSign+IntegerToString(ali_OrderVAR));
   afr_SetText_1(18,23,1,DoubleToString(-ald_VARLimit,2));
   afr_SetText_1(18,32,1,DoubleToString(Ext_aed_OrderReserve*100,2)+"%");
//--- </11.5. Third Cluster: Position Management Report 97 >                                                      
//--- < 11.6. Leverage/Contract Specification Indicator 14 >                                                      
   string als_Leverage="1:"+
                       IntegerToString(m_account.Leverage())+" / "+
                       DoubleToString(avd_NominalMargin,2)+" "+
                       avs_Currency[ari_Account]+" = "+
                       IntegerToString(ali_MarginPoints)+" points x "+
                       DoubleToString(ald_NominalPoint,2)+" "+
                       avs_Currency[ari_Account];

   string als_Contract=DoubleToString(m_symbol.ContractSize(),2)+" "+
                       avs_Currency[ari_Margin]+" / "+
                       DoubleToString(m_symbol.LotsMin(),2)+" / "+
                       DoubleToString(m_symbol.LotsStep(),2)+" / "+
                       DoubleToString(m_symbol.LotsMax(),2);

   afr_SetText_1(20,1,0,"Leverage:    "+als_Leverage);
   afr_SetText_1(21,1,0,"Contract:    "+als_Contract);
//--- </11.6. Leverage/Contract Specification Indicator 14 >                                                      
//--- < 11.7. Fourth Cluster: Trading Strategy Rules 12 >                                                         
   afr_SetText_1(23,1,0,"Rules            Ask:     High_1      Close_1  Average_1");
   afr_SetText_1(24,1,0,"Buy: ");
   afr_SetText_1(24,24,1,DoubleToString(m_symbol.Ask(),m_symbol.Digits())+" > ");
   afr_SetText_1(24,36,1,DoubleToString(avd_High_1+avd_QuoteSpread,m_symbol.Digits())+"  &&");
   afr_SetText_1(24,48,1,DoubleToString(avd_Close_1+avd_QuoteSpread,m_symbol.Digits())+" > ");
   afr_SetText_1(24,56,1,DoubleToString(avd_Average_1+avd_QuoteSpread,m_symbol.Digits()));

   afr_SetText_1(25,1,0,"Sell: ");
   afr_SetText_1(25,24,1,DoubleToString(m_symbol.Bid(),m_symbol.Digits())+" < ");
   afr_SetText_1(25,36,1,DoubleToString(avd_Low_1,m_symbol.Digits())+"  &&");
   afr_SetText_1(25,48,1,DoubleToString(avd_Close_1,m_symbol.Digits())+" < ");
   afr_SetText_1(25,56,1,DoubleToString(avd_Average_1,m_symbol.Digits()));
   afr_SetText_1(26,1,0,"                 Bid:      Low_1      Close_1  Average_1");
//--- </11.7. Fourth Cluster: Trading Strategy Rules 12 >                                                         
//--- < 11.8. Fifth Cluster: Trading Strategy Preset 14 >                                                         
   afr_SetText_1(28,1,0,"Preset        Factors      Range         Take       Stop");
   afr_SetText_1(29,1,0,"Trade "+EnumToString(Ext_aei_Timeframe_1)+":");
   afr_SetText_1(29,21,1,DoubleToString(Ext_aed_TakeFactor,1)+"/"+
                 DoubleToString(Ext_aed_StopFactor,1));
   afr_SetText_1(29,32,1,DoubleToString(avd_Range_1,m_symbol.Digits()));
   afr_SetText_1(29,45,1,DoubleToString(avd_QuoteTake,m_symbol.Digits()));
   afr_SetText_1(29,56,1,DoubleToString(avd_QuoteStop,m_symbol.Digits()));

   afr_SetText_1(30,1,0,"Trail "+EnumToString(Ext_aei_Timeframe_2)+":");
   afr_SetText_1(30,21,1,DoubleToString(Ext_aed_TrailFactor,1)+"/"+
                 DoubleToString(acd_TrailStepping,1));
   afr_SetText_1(30,32,1,DoubleToString(avd_Range_2,m_symbol.Digits()));
   afr_SetText_1(30,45,1,DoubleToString(avd_QuoteTrail,m_symbol.Digits()));
   afr_SetText_1(30,56,1,DoubleToString(avd_TrailStep,m_symbol.Digits()));
   afr_SetText_1(31,1,0,"              Factors      Range        Trail       Step");
//--- </11.8. Fifth Cluster: Trading Strategy Preset 14 >                                                         
  }
//--- </A_System_Extra: Function 11 >
//--- < A_System_Extra: Function 12 >
string afs_Interval(long aai_Interval,int aai_Seconds=-1)
  {
   static string  als_Result;

   static long     ali_Interval;  ali_Interval=(long)MathAbs(aai_Interval);
   if(aai_Seconds==-1)
      als_Result=TimeToString(ali_Interval,TIME_MINUTES);
   else
      als_Result=TimeToString(ali_Interval,TIME_SECONDS);

   if(ali_Interval>=86400)
      als_Result=IntegerToString(ali_Interval/86400)+" "+als_Result;
   else if(aai_Interval<0)
      als_Result="-"+als_Result;

   return(als_Result);
  }
//--- </A_System_Extra: Function 12 >
//--- < A_System_Extra: Function 13 >
//--- </A_System_Extra: Function 13 >
//--- < A_System_Extra: Function 14 >
string afs_Time(long aai_Time,int aai_Seconds=-1)
  {
   static string  als_Result;

   int ali_Mode;
   if(aai_Seconds==-1)
      ali_Mode=TIME_DATE|TIME_MINUTES;
   else
      ali_Mode=TIME_DATE|TIME_SECONDS;

   als_Result=TimeToString(aai_Time,ali_Mode);

   return(als_Result);
  }
//--- </A_System_Extra: Function 14 >
//--- < A_System_Extra: Function 15 >
void    afr_CurrencyDetector(string  aas_Symbol,
                             string &aas_Currency[])
  {
   aas_Currency[ari_Account]=m_account.Currency();

   if((     m_symbol.TradeCalcMode()==SYMBOL_CALC_MODE_FOREX)
      && (StringLen(aas_Symbol)==6)
      && ( StringFind(aas_Symbol,"#")==-1)
      && ( StringFind(aas_Symbol,"@")==-1)
      && ( StringFind(aas_Symbol,"_")==-1))
     {
      aas_Currency[ari_Base]=StringSubstr(aas_Symbol,0,3);
      aas_Currency[ari_Quote]=StringSubstr(aas_Symbol,3,3);
     }
   else
     {
      aas_Currency[ari_Base]=aas_Symbol;
      aas_Currency[ari_Quote]=aas_Currency[ari_Account];
     }

   if(avd_NominalMargin>0)
     {
      if(m_account.Leverage()==MathRound(m_symbol.ContractSize()/avd_NominalMargin))
         aas_Currency[ari_Margin]=aas_Currency[ari_Account];
      else
         aas_Currency[ari_Margin]=aas_Currency[ari_Base];
     }
   else
     {
      aas_Currency[ari_Margin]="";
     }
  }
//--- </A_System_Extra: Function 15 >
//--- </8. Extra Code >
//+------------------------------------------------------------------+
//| Gets the information about permission to trade                   |
//+------------------------------------------------------------------+
bool IsTradeAllowed()
  {
   return(true);
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      Alert("Check if automated trading is allowed in the terminal settings!");
      return(false);
     }
   else
     {
      if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         Alert("Automated trading is forbidden in the program settings for ",__FILE__);
         return(false);
        }
     }
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
     {
      Alert("Automated trading is forbidden for the account ",AccountInfoInteger(ACCOUNT_LOGIN),
            " at the trade server side");
      return(false);
     }
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
     {
      Comment("Trading is forbidden for the account ",AccountInfoInteger(ACCOUNT_LOGIN),
              ".\n Perhaps an investor password has been used to connect to the trading account.",
              "\n Check the terminal journal for the following entry:",
              "\n\'",AccountInfoInteger(ACCOUNT_LOGIN),"\': trading has been disabled - investor mode.");
      return(false);
     }
//---
   return(true);
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

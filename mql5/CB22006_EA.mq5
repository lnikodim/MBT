//+------------------------------------------------------------------+
//|                   NeuroNirvamanEA 2(barabashkakvn's edition).mq5 |
//|                              Copyright © 2018, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
#property version   "2.000"
/*
   you can change the code. you can add your code, you can publish your changes
   but please dont erase my name from the Copyright Gabriel Jaime Mejнa Arbelaez
   thanks.

   if you ever make money with this EA please give some of your fortune to the more 
   needed of my country. Thats  fair in exchange to what I am giving to you.

   https://pagos.conexioncolombia.com/home.aspx

   I believe in good things happen to you when you do good things to other people.

   just try it. ;-)
*/
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
//--- input parameters
input int      InpRISK_1            = 3;     // SilverTrend #1: RISK
input int      Laguerre_1_Period    = 14;    // Laguerre #1: Period
input double   Laguerre_1_Distance  = 0;     // Distance #1 
input double   x11                  = 100.0; // x11
input double   x12                  = 100.0; // x12
input int      tp1                  = 100;   // Take Profit #1
input int      sl1                  = 50;    // Stop Loss #1

input int      InpRISK_2            = 9;     // SilverTrend #2 RISK
input int      Laguerre_2_Period    = 14;    // Laguerre #2: Period
input double   Laguerre_2_Distance  = 0;     // Distance #2
input double   x21                  = 100.0; // x21
input double   x22                  = 100.0; // x22
input int      tp2                  = 100;   // Take Profit #2
input int      sl2                  = 50;    // Stop Loss #2

input int      Laguerre_3_Period    = 14;    // Laguerre #3: Period
input double   Laguerre_3_Distance  = 0;     // Distance #3
input int      Laguerre_4_Period    = 14;    // Laguerre #4: Period
input double   Laguerre_4_Distance  = 0;     // Distance #4
input int      x31                  = 100;   // x31
input int      x32                  = 100;   // x32

input int      pass                 = 4;     // Pass   
input double   InpLots              = 0.1;   // Lots  
input uchar    InpStartHour         = 9;     // Start hour
input uchar    InpStartMin          = 0;     // Start minute
input uchar    InpEndHour           = 17;    // End hour
input uchar    InpEndMin            = 03;    // End minute
input ulong    m_magic=75962120;             // magic number
//---
ulong          m_slippage=10;                // slippage

int            handle_iCustom_Laguerre_1;    // variable for storing the handle of the iCustom indicator 
int            handle_iCustom_Laguerre_2;    // variable for storing the handle of the iCustom indicator 
int            handle_iCustom_Laguerre_3;    // variable for storing the handle of the iCustom indicator 
int            handle_iCustom_Laguerre_4;    // variable for storing the handle of the iCustom indicator 
int            handle_iCustom_SilverTrend_1; // variable for storing the handle of the iCustom indicator 
int            handle_iCustom_SilverTrend_2; // variable for storing the handle of the iCustom indicator 

double         m_adjusted_point;             // point value adjusted for 3 or 5 points
long           m_start=-1;
long           m_end=-1;
bool           m_close_all=false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   m_start     =  InpStartHour*60*60   + InpStartMin*60;
   m_end       =  InpEndHour*60*60     + InpEndMin*60;
   m_close_all = false;
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
//--- create handle of the indicator iCustom
   handle_iCustom_Laguerre_1=iCustom(m_symbol.Name(),Period(),"laguerre_plusdi",Laguerre_1_Period);
//--- if the handle is not created 
   if(handle_iCustom_Laguerre_1==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iCustom indicator (\"Laguerre #1\") for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iCustom
   handle_iCustom_Laguerre_2=iCustom(m_symbol.Name(),Period(),"laguerre_plusdi",Laguerre_2_Period);
//--- if the handle is not created 
   if(handle_iCustom_Laguerre_2==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iCustom indicator (\"Laguerre #2\") for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iCustom
   handle_iCustom_Laguerre_3=iCustom(m_symbol.Name(),Period(),"laguerre_plusdi",Laguerre_3_Period);
//--- if the handle is not created 
   if(handle_iCustom_Laguerre_3==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iCustom indicator (\"Laguerre #3\") for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iCustom
   handle_iCustom_Laguerre_4=iCustom(m_symbol.Name(),Period(),"laguerre_plusdi",Laguerre_4_Period);
//--- if the handle is not created 
   if(handle_iCustom_Laguerre_4==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iCustom indicator (\"Laguerre #4\") for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iCustom
   handle_iCustom_SilverTrend_1=iCustom(m_symbol.Name(),Period(),"silvertrend_signal",InpRISK_1);
//--- if the handle is not created 
   if(handle_iCustom_SilverTrend_1==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iCustom indicator (\"SilverTrane #1\") for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iCustom
   handle_iCustom_SilverTrend_2=iCustom(m_symbol.Name(),Period(),"silvertrend_signal",InpRISK_2);
//--- if the handle is not created 
   if(handle_iCustom_SilverTrend_2==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iCustom indicator (\"SilverTrane #2\") for the symbol %s/%s, error code %d",
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
void OnTick(void)
  {
   if(m_close_all)
     {
      if(IsPositionExists())
        {
         CloseAllPositions();
         return;
        }
      else
         m_close_all=false;
     }
   MqlDateTime STimeCurrent;
   TimeToStruct(TimeCurrent(),STimeCurrent);
   long current=STimeCurrent.hour*60*60+STimeCurrent.min*60;
   if(current<m_start || current>m_end)
     {
      if(IsPositionExists())
         m_close_all=true;
      return;
     }
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(m_symbol.Name(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;

   if(!IsTradeAllowed())
     {
      PrevBars=0;
      Sleep(30000);
     }

   if(!RefreshRates())
     {
      PrevBars=0;
      return;
     }

   if(IsPositionExists())
      return;

   double tp = 100.0;
   double sl = 50;
   int perceptron=Supervisor(tp,sl);

   if(perceptron>0)
     {
      m_trade.Buy(InpLots,m_symbol.Name(),
                  m_symbol.Ask(),
                  m_symbol.NormalizePrice(m_symbol.Ask()-sl*m_adjusted_point),
                  m_symbol.NormalizePrice(m_symbol.Ask()+tp*m_adjusted_point));
     }

   if(perceptron<0)
     {
      m_trade.Sell(InpLots,m_symbol.Name(),
                   m_symbol.Bid(),
                   m_symbol.NormalizePrice(m_symbol.Bid()+sl*m_adjusted_point),
                   m_symbol.NormalizePrice(m_symbol.Bid()-tp*m_adjusted_point));
     }
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
//| Gets the information about permission to trade                   |
//+------------------------------------------------------------------+
bool IsTradeAllowed(void)
  {
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
//| Is position exists                                               |
//+------------------------------------------------------------------+
bool IsPositionExists(void)
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iCustom                             |
//|  the buffer numbers are the following:                           |
//+------------------------------------------------------------------+
double iCustomGet(int handle,const int buffer,const int index)
  {
   double Custom[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iCustom array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle,buffer,index,1,Custom)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iCustom indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Custom[0]);
  }
//+------------------------------------------------------------------+
//| Calculate perciptrons value                                      |
//+------------------------------------------------------------------+
int Supervisor(double &take_profit,double &stop_loss)
  {
   if(pass==3)
     {
      if(Perceptron3()>0)
        {
         if(Perceptron2()>0)
           {
            take_profit=tp2;
            stop_loss=sl2;
            return(1);
           }
        }
      else
        {
         if(Perceptron1()<0)
           {
            take_profit=tp1;
            stop_loss=sl1;
            return(-1);
           }
        }
      return(0);
     }
//---
   if(pass==2)
     {
      if(Perceptron2()>0)
        {
         take_profit=tp2;
         stop_loss=sl2;
         return(1);
        }
      else
        {
         return(-1);
        }
     }
//---
   if(pass==1)
     {
      if(Perceptron1()<0)
        {
         take_profit=tp1;
         stop_loss=sl1;
         return(-1);
        }
      else
        {
         return(1);
        }
     }
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Perceptron #3                                                    |
//+------------------------------------------------------------------+
double Perceptron3()
  {
   double w1 = x31 - 100.0;
   double w2 = x32 - 100.0;

   double a1=0;
   double a2=0;

   double Laguerre=iCustomGet(handle_iCustom_Laguerre_3,0,0);
   double Laguerre2=iCustomGet(handle_iCustom_Laguerre_4,0,0);

   if(Laguerre>(0.5+(Laguerre_3_Distance/100.0)))
      a1=-1;
   if(Laguerre<(0.5-(Laguerre_3_Distance/100.0)))
      a1=1;
   if(Laguerre2>(0.5+(Laguerre_4_Distance/100.0)))
      a2=-1;
   if(Laguerre2<(0.5-(Laguerre_4_Distance/100.0)))
      a2=1;

   return(w1 * a1 + w2 * a2  );
  }
//+------------------------------------------------------------------+
//| Perceptron #2                                                    |
//+------------------------------------------------------------------+
double Perceptron2()
  {
   double w2 = x21 - 100.0;
   double w4 = x22 - 100.0;

   double a2 = Tension2();
   double a4 = Silvertrend2();
   return(w2 * a2 + w4 * a4);
  }
//+------------------------------------------------------------------+
//| Perceptron #1                                                    |
//+------------------------------------------------------------------+
double Perceptron1()
  {
   double w2 = x11 - 100.0;
   double w4 = x12 - 100.0;

   double a2 = Tension1();
   double a4 = Silvertrend1();
   return(w2 * a2 + w4 * a4);
  }
//+------------------------------------------------------------------+
//| Tension value #1                                                 |
//+------------------------------------------------------------------+
int Tension1()
  {
   double Laguerre=iCustomGet(handle_iCustom_Laguerre_1,0,0);
   if(Laguerre>(0.5+(Laguerre_1_Distance/100.0)))
      return(-1);
   if(Laguerre<(0.5-(Laguerre_1_Distance/100.0)))
      return(1);
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Tension value #2                                                 |
//+------------------------------------------------------------------+
int Tension2()
  {
   double Laguerre=iCustomGet(handle_iCustom_Laguerre_2,0,0);
   if(Laguerre>(0.5+(Laguerre_2_Distance/100.0)))
      return(-1);
   if(Laguerre<(0.5-(Laguerre_2_Distance/100.0)))
      return(1);
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Calculate Silvertrend value #1                                   |
//+------------------------------------------------------------------+
int Silvertrend1()
  {
   double buff0=iCustomGet(handle_iCustom_SilverTrend_1,0,0);
   double buff1=iCustomGet(handle_iCustom_SilverTrend_1,1,0);

   if(buff0!=0)
      return(1);
   if(buff1!=0)
      return(-1);
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Calculate Silvertrend2 value #2                                  |
//+------------------------------------------------------------------+
int Silvertrend2()
  {
   double buff0=iCustomGet(handle_iCustom_SilverTrend_2,0,0);
   double buff1=iCustomGet(handle_iCustom_SilverTrend_2,1,0);

   if(buff0!=0)
      return(1);
   if(buff1!=0)
      return(-1);
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+

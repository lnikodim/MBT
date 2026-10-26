//+------------------------------------------------------------------+
//|                   MostasHaR15 Pivot(barabashkakvn's edition).mq5 |
//|                              Copyright © 2018, MoStAsHaR15 FoReX |
//|                                            mostashar15@yahoo.com |
//+------------------------------------------------------------------+
#property copyright "MoStAsHaR15 FoReX © CopyRights 2005"
#property link      "mostashar15@yahoo.com"
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
//--- input parameters
input double   InpLots           = 0.1;      // Lots
input ushort   InpStopLoss       = 20;       // Stop Loss (in pips)
input ushort   InpTrailingStop   = 5;        // Trailing Stop (in pips)
input ushort   InpTrailingStep   = 5;        // Trailing Step (in pips)
input int      InpTimeZone       = 2;        // Time zone
input ulong    m_magic           = 541114416;// magic number
//---
ulong          m_slippage=10;                // slippage

double         ExtStopLoss=0.0;
double         ExtTrailingStop=0.0;
double         ExtTrailingStep=0.0;
double         ExtStep=0.0;

int            handle_iADX;                  // variable for storing the handle of the iADX indicator 
int            handle_iMA_CLOSE;             // variable for storing the handle of the iMA indicator 
int            handle_iMA_OPEN;              // variable for storing the handle of the iMA indicator 
int            handle_iOsMA;                 // variable for storing the handle of the iOsMA indicator 

double         m_adjusted_point;             // point value adjusted for 3 or 5 points

MqlRates       rates_h1[],rates_d1[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ArraySetAsSeries(rates_h1,true);
   ArraySetAsSeries(rates_d1,true);
//---
   if(InpTrailingStop!=0 && InpTrailingStep==0)
     {
      string text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                  "Трейлинг невозможен: параметр \"Trailing Step\" равен нулю!":
                  "Trailing is not possible: parameter \"Trailing Step\" is zero!";
      Alert(__FUNCTION__," ERROR! ",text);
      return(INIT_PARAMETERS_INCORRECT);
     }
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
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtStopLoss    = InpStopLoss     * m_adjusted_point;
   ExtTrailingStop= InpTrailingStop * m_adjusted_point;
   ExtTrailingStep= InpTrailingStep * m_adjusted_point;
   ExtStep        = 5               * m_adjusted_point;
//--- create handle of the indicator iADX
   handle_iADX=iADX(m_symbol.Name(),PERIOD_H1,14);
//--- if the handle is not created 
   if(handle_iADX==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iADX indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_H1),
                  GetLastError());
      //--- the indicator is stopped early 
     }
//--- create handle of the indicator iMA
   handle_iMA_CLOSE=iMA(m_symbol.Name(),PERIOD_H1,5,0,MODE_EMA,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iMA_CLOSE==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_H1),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_OPEN=iMA(m_symbol.Name(),PERIOD_H1,8,0,MODE_EMA,PRICE_OPEN);
//--- if the handle is not created 
   if(handle_iMA_OPEN==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_H1),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iOsMA
   handle_iOsMA=iOsMA(m_symbol.Name(),PERIOD_H1,12,26,9,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iOsMA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create a handle of iOsMA for the pair %s/%s, error code is %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_H1),
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
//---
   if(CopyRates(Symbol(),PERIOD_D1,0,2,rates_d1)!=2)
      return;
   double yesterday_high   = rates_d1[1].high;
   double yesterday_low    = rates_d1[1].low;
   double day_high         = rates_d1[0].high;
   double day_low          = rates_d1[0].low;
   double yesterday_close  = 0.0;
   double yesterday_open   = 0.0;
   double today_open       = 0.0;
//---
   if(CopyRates(Symbol(),PERIOD_H1,0,50,rates_h1)!=50)
      return;
   for(int i=0;i<=25;i++)
     {
      MqlDateTime STime;
      TimeToStruct(rates_h1[i].time,STime);
      if(STime.min==0 && (STime.hour-InpTimeZone)==0)
        {
         yesterday_close   = rates_h1[i+1].close;
         yesterday_open    = rates_h1[i+24].open;
         today_open        = rates_h1[i].open;
         break;
        }
     }
//--- calculate Pivots
   double D = (day_high - day_low);
   double Q = (yesterday_high - yesterday_low);
   double P = (yesterday_high + yesterday_low + yesterday_close)/3.0;
   double R1= (2.0*P)-yesterday_low;
   double S1= (2.0*P)-yesterday_high;
//---
   double R2= P+(yesterday_high - yesterday_low);
   double S2= P-(yesterday_high - yesterday_low);
   double R3= (2.0*P)+(yesterday_high-(2.0*yesterday_low));
   double S3= (2.0*P)-((2.0* yesterday_high)-yesterday_low);
//---
   double M5= (R2+R3)/2.0;
   double M4= (R1+R2)/2.0;
   double M3= (P+R1)/2.0;
   double M2= (P+S1)/2.0;
   double M1= (S1+S2)/2.0;
   double M0= (S2+S3)/2.0;
   double nQ= 0.0;
   double nD= 0.0;
//---
   if(Q>5)
      nQ=Q;
   else
      nQ=Q*10000;

   if(D>5)
      nD=D;
   else
      nD=D*10000;
//--- pivot Lines Labeling
   if(ObjectFind(0,"R1 label")<0)
      TextCreate(0,"R1 label",0,iTime(m_symbol.Name(),Period(),20),R1,clrYellow,"R1");
   else
      TextMove(0,"R1 label",iTime(m_symbol.Name(),Period(),20),R1);
//---
   if(ObjectFind(0,"R2 label")<0)
      TextCreate(0,"R2 label",0,iTime(m_symbol.Name(),Period(),20),R2,clrOrange,"R2");
   else
      TextMove(0,"R2 label",iTime(m_symbol.Name(),Period(),20),R2);
//---
   if(ObjectFind(0,"R3 label")<0)
      TextCreate(0,"R3 label",0,iTime(m_symbol.Name(),Period(),20),R3,clrRed,"R3");
   else
      TextMove(0,"R3 label",iTime(m_symbol.Name(),Period(),20),R3);
//---
   if(ObjectFind(0,"P label")<0)
      TextCreate(0,"P label",0,iTime(m_symbol.Name(),Period(),20),P,clrDeepPink,"Pivot");
   else
      TextMove(0,"P label",iTime(m_symbol.Name(),Period(),20),P);
//---
   if(ObjectFind(0,"S1 label")<0)
      TextCreate(0,"S1 label",0,iTime(m_symbol.Name(),Period(),20),S1,clrYellow,"S1");
   else
      TextMove(0,"S1 label",iTime(m_symbol.Name(),Period(),20),S1);
//---
   if(ObjectFind(0,"S2 label")<0)
      TextCreate(0,"S2 label",0,iTime(m_symbol.Name(),Period(),20),S2,clrOrange,"S2");
   else
      TextMove(0,"S2 label",iTime(m_symbol.Name(),Period(),20),S2);
//---
   if(ObjectFind(0,"S3 label")<0)
      TextCreate(0,"S3 label",0,iTime(m_symbol.Name(),Period(),20),S3,clrRed,"S3");
   else
      TextMove(0,"S3 label",iTime(m_symbol.Name(),Period(),20),S3);
//--- drawing Pivot lines
   if(ObjectFind(0,"S1 line")<0)
      HLineCreate(0,"S1 line",0,S1,clrYellow);
   else
      HLineMove(0,"S1 line",S1);
//---
   if(ObjectFind(0,"S2 line")<0)
      HLineCreate(0,"S2 line",0,S2,clrOrange);
   else
      HLineMove(0,"S2 line",S2);
//---
   if(ObjectFind(0,"S3 line")<0)
      HLineCreate(0,"S3 line",0,S3,clrRed);
   else
      HLineMove(0,"S3 line",S3);
//---
   if(ObjectFind(0,"P line")<0)
      HLineCreate(0,"P line",0,P,clrDeepPink);
   else
      HLineMove(0,"P line",P);
//---
   if(ObjectFind(0,"R1 line")<0)
      HLineCreate(0,"R1 line",0,R1,clrYellow);
   else
      HLineMove(0,"R1 line",R1);
//---
   if(ObjectFind(0,"R2 line")<0)
      HLineCreate(0,"R2 line",0,R2,clrOrange);
   else
      HLineMove(0,"R2 line",R2);
//---
   if(ObjectFind(0,"R3 line")<0)
      HLineCreate(0,"R3 line",0,R3,clrRed);
   else
      HLineMove(0,"R3 line",R3);
//--- midpoints Labeling
   if(ObjectFind(0,"M5 line")<0)
      HLineCreate(0,"M5 line",0,M5,clrBlue);
   else
      HLineMove(0,"M5 line",M5);
//---
   if(ObjectFind(0,"M4 line")<0)
      HLineCreate(0,"M4 line",0,M4,clrBlue);
   else
      HLineMove(0,"M4 line",M4);
//---
   if(ObjectFind(0,"M3 line")<0)
      HLineCreate(0,"M3 line",0,M3,clrBlue);
   else
      HLineMove(0,"M3 line",M3);
//---
   if(ObjectFind(0,"M2 line")<0)
      HLineCreate(0,"M2 line",0,M2,clrBlue);
   else
      HLineMove(0,"M2 line",M2);
//---
   if(ObjectFind(0,"M1 line")<0)
      HLineCreate(0,"M1 line",0,M1,clrBlue);
   else
      HLineMove(0,"M1 line",M1);
//---
   if(ObjectFind(0,"M0 line")<0)
      HLineCreate(0,"M0 line",0,M0,clrBlue);
   else
      HLineMove(0,"M0 line",M0);
//--- indicator Calculations
   double adx_MAIN_LINE_array[];
   if(!iADXGetArray(MAIN_LINE,0,1,adx_MAIN_LINE_array))
      return;
//---
   double adx_PLUSDI_LINE_array[];
   ArraySetAsSeries(adx_PLUSDI_LINE_array,true);
   if(!iADXGetArray(PLUSDI_LINE,0,2,adx_PLUSDI_LINE_array))
      return;

   double adx_MINUSDI_LINE_array[];
   ArraySetAsSeries(adx_MINUSDI_LINE_array,true);
   if(!iADXGetArray(MINUSDI_LINE,0,2,adx_MINUSDI_LINE_array))
      return;
//---
   double ma_CLOSE_array[];
   ArraySetAsSeries(ma_CLOSE_array,true);
   if(!iMAGetArray(handle_iMA_CLOSE,0,2,ma_CLOSE_array))
      return;

   double ma_OPEN_array[];
   ArraySetAsSeries(ma_OPEN_array,true);
   if(!iMAGetArray(handle_iMA_OPEN,0,2,ma_OPEN_array))
      return;
//---
   double OsMA_array[];
   ArraySetAsSeries(OsMA_array,true);
   if(!iOsMAGetArray(0,2,OsMA_array))
      return;
//--- determining Bounding Pivot Lines & Take Profit Point
   if(!RefreshRates())
      return;
   double Sup=0.0;
   double Res=0.0;
   double Sell_TP=0.0;
   double Buy_TP=0.0;
   if((m_symbol.Bid()-S3) *(m_symbol.Bid()-M0)<0)
     {
      Sup=S3;
      Res=M0;
      Sell_TP=Sup;
      Buy_TP=Res;
     }
   if((m_symbol.Bid()-M0) *(m_symbol.Bid()-S2)<0)
     {
      Sup=M0;
      Res=S2;
      Sell_TP=Sup;
      Buy_TP=Res;
     }
   if((m_symbol.Bid()-S2) *(m_symbol.Bid()-M1)<0)
     {
      Sup=S2;
      Res=M1;
      Sell_TP=Sup;
      Buy_TP=Res;
     }
   if((m_symbol.Bid()-M1) *(m_symbol.Bid()-S1)<0)
     {
      Sup=M1;
      Res=S1;
      Sell_TP=Sup;
      Buy_TP=Res;
     }
   if((m_symbol.Bid()-S1) *(m_symbol.Bid()-M2)<0)
     {
      Sup=S1;
      Res=M2;
      Sell_TP=Sup;
      Buy_TP=Res;
     }
   if((m_symbol.Bid()-M2) *(m_symbol.Bid()-P)<0)
     {
      Sup=M2;
      Res=P;
      Sell_TP=Sup;
      Buy_TP=Res;
     }
   if((m_symbol.Bid()-P) *(m_symbol.Bid()-M3)<0)
     {
      Sup=P;
      Res=M3;
      Sell_TP=Sup;
      Buy_TP=Res;
     }
   if((m_symbol.Bid()-M3) *(m_symbol.Bid()-R1)<0)
     {
      Sup=M3;
      Res=R1;
      Sell_TP=Sup;
      Buy_TP=Res;
     }
   if((m_symbol.Bid()-R1) *(m_symbol.Bid()-M4)<0)
     {
      Sup=R1;
      Res=M4;
      Sell_TP=Sup;
      Buy_TP=Res;
     }
   if((m_symbol.Bid()-M4) *(m_symbol.Bid()-R2)<0)
     {
      Sup=M4;
      Res=R2;
      Sell_TP=Sup;
      Buy_TP=Res;
     }
   if((m_symbol.Bid()-R2) *(m_symbol.Bid()-M5)<0)
     {
      Sup=R2;
      Res=M5;
      Sell_TP=Sup;
      Buy_TP=Res;
     }
   if((m_symbol.Bid()-M5) *(m_symbol.Bid()-R3)<0)
     {
      Sup=S3;
      Res=M0;
      Sell_TP=Sup;
      Buy_TP=Res;
     }
   double dif1=(m_symbol.Bid()-Sell_TP)/m_symbol.Point();
   double dif2=(Buy_TP-m_symbol.Ask())/m_symbol.Point();
//---
   Comment("MoStAsHaR15 FoReX - Pivot Strategy","\nSupport = ",Sup," - Difference = ",
           DoubleToString(dif1,0)," Pips","\nResistance = ",Res," - Difference = ",DoubleToString(dif2,0)," Pips");
//--- checking Account Free Margin       
   if(!IsPositionExists())
     {
      //--- check for long positions  
      if(dif2>14 && adx_MAIN_LINE_array[0]>20 && adx_PLUSDI_LINE_array[0]>adx_PLUSDI_LINE_array[1] && 
         adx_PLUSDI_LINE_array[0]>adx_MINUSDI_LINE_array[0] && (ma_CLOSE_array[0]-ma_OPEN_array[0])>=ExtStep && 
         ma_CLOSE_array[1]>ma_OPEN_array[1] && OsMA_array[0]>OsMA_array[1])
        {
         double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
         if(sl>=m_symbol.Bid()) // incident: the position isn't opened yet, and has to be already closed
           {
            return;
           }
         OpenBuy(sl,Buy_TP);
         return;
        }
      //--- check for short positions 
      if(dif1>14 && adx_MAIN_LINE_array[0]>20 && adx_MINUSDI_LINE_array[0]>adx_MINUSDI_LINE_array[1] && 
         adx_PLUSDI_LINE_array[0]<adx_MINUSDI_LINE_array[0] && (ma_OPEN_array[0]-ma_CLOSE_array[0])>=ExtStep && 
         ma_OPEN_array[1]>ma_CLOSE_array[1] && OsMA_array[0]<OsMA_array[1])
        {
         double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
         if(sl<=m_symbol.Ask()) // incident: the position isn't opened yet, and has to be already closed
           {
            return;
           }
         OpenSell(sl,Sell_TP);
         return;
        }
     }
//---
   Trailing();
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
//| Creating Text object                                             | 
//+------------------------------------------------------------------+ 
bool TextCreate(const long              chart_ID=0,// chart's ID
                const string            name="Text",              // object name 
                const int               sub_window=0,             // subwindow index 
                datetime                time=0,                   // anchor point time 
                double                  price=0,                  // anchor point price 
                const color             clr=clrBlueViolet,        // color
                const string            text="Text",              // the text itself 
                const string            font="Arial",             // font 
                const int               font_size=10,             // font size 
                const double            angle=0.0,// text slope 
                const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type 
                const bool              back=false,               // in the background 
                const bool              selection=false,          // highlight to move 
                const bool              hidden=true,              // hidden in the object list 
                const long              z_order=0)                // priority for mouse click 
  {
//--- set anchor point coordinates if they are not set 
   ChangeTextEmptyPoint(time,price);
//--- reset the error value 
   ResetLastError();
//--- create Text object 
   if(!ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price))
     {
      Print(__FUNCTION__,
            ": failed to create \"Text\" object! Error code = ",GetLastError());
      return(false);
     }
//--- set the text 
   ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
//--- set text font 
   ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
//--- set font size 
   ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
//--- set the slope angle of the text 
   ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
//--- set anchor type 
   ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
//--- set color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the object by mouse 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Move the anchor point                                            | 
//+------------------------------------------------------------------+ 
bool TextMove(const long   chart_ID=0,  // chart's ID 
              const string name="Text", // object name 
              datetime     time=0,      // anchor point time coordinate 
              double       price=0)     // anchor point price coordinate 
  {
//--- if point position is not set, move it to the current bar having Bid price 
   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value 
   ResetLastError();
//--- move the anchor point 
   if(!ObjectMove(chart_ID,name,0,time,price))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Change the object text                                           | 
//+------------------------------------------------------------------+ 
bool TextChange(const long   chart_ID=0,  // chart's ID 
                const string name="Text", // object name 
                const string text="Text") // text 
  {
//--- reset the error value 
   ResetLastError();
//--- change object text 
   if(!ObjectSetString(chart_ID,name,OBJPROP_TEXT,text))
     {
      Print(__FUNCTION__,
            ": failed to change the text! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Delete Text object                                               | 
//+------------------------------------------------------------------+ 
bool TextDelete(const long   chart_ID=0,  // chart's ID 
                const string name="Text") // object name 
  {
//--- reset the error value 
   ResetLastError();
//--- delete the object 
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete \"Text\" object! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Check anchor point values and set default values                 | 
//| for empty ones                                                   | 
//+------------------------------------------------------------------+ 
void ChangeTextEmptyPoint(datetime &time,double &price)
  {
//--- if the point's time is not set, it will be on the current bar 
   if(!time)
      time=TimeCurrent();
//--- if the point's price is not set, it will have Bid value 
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
  }
//+------------------------------------------------------------------+ 
//| Create the horizontal line                                       | 
//+------------------------------------------------------------------+ 
bool HLineCreate(const long            chart_ID=0,        // chart's ID 
                 const string          name="HLine",      // line name 
                 const int             sub_window=0,      // subwindow index 
                 double                price=0,           // line price 
                 const color           clr=clrRed,        // line color 
                 const ENUM_LINE_STYLE style=STYLE_DASH,  // line style 
                 const int             width=1,           // line width 
                 const bool            back=false,        // in the background 
                 const bool            selection=false,   // highlight to move 
                 const bool            hidden=true,       // hidden in the object list 
                 const long            z_order=0)         // priority for mouse click 
  {
//--- if the price is not set, set it at the current Bid price level 
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value 
   ResetLastError();
//--- create a horizontal line 
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
     {
      Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- set line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Move horizontal line                                             | 
//+------------------------------------------------------------------+ 
bool HLineMove(const long   chart_ID=0,   // chart's ID 
               const string name="HLine", // line name 
               double       price=0)      // line price 
  {
//--- if the line price is not set, move it to the current Bid price level 
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value 
   ResetLastError();
//--- move a horizontal line 
   if(!ObjectMove(chart_ID,name,0,0,price))
     {
      Print(__FUNCTION__,
            ": failed to move the horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Delete a horizontal line                                         | 
//+------------------------------------------------------------------+ 
bool HLineDelete(const long   chart_ID=0,   // chart's ID 
                 const string name="HLine") // line name 
  {
//--- reset the error value 
   ResetLastError();
//--- delete a horizontal line 
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iADX                                |
//|  the buffer numbers are the following:                           |
//|    0 - MAIN_LINE, 1 - PLUSDI_LINE, 2 - MINUSDI_LINE              |
//+------------------------------------------------------------------+
double iADXGetArray(const int buffer,const int start_pos,const int count,double &arr_buffer[])
  {
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
      Print("This a no dynamic array!");
      return(false);
     }
   ArrayFree(arr_buffer);
   int       buffer_num=0;          // indicator buffer number 
//--- reset error code 
   ResetLastError();
//--- fill a part of the iBands array with values from the indicator buffer
   int copied=CopyBuffer(handle_iADX,buffer,start_pos,count,arr_buffer);
   if(copied!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iADX indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
   return(result);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA in the array                    |
//+------------------------------------------------------------------+
bool iMAGetArray(const int handle_iMA,const int start_pos,const int count,double &arr_buffer[])
  {
//---
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
      Print("This a no dynamic array!");
      return(false);
     }
   ArrayFree(arr_buffer);
   int       buffer_num=0;          // indicator buffer number 
//--- reset error code 
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index 
   int copied=CopyBuffer(handle_iMA,buffer_num,start_pos,count,arr_buffer);
   if(copied!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iOsMA in the array                  |
//+------------------------------------------------------------------+
bool iOsMAGetArray(const int start_pos,const int count,double &arr_buffer[])
  {
//---
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
      Print("This a no dynamic array!");
      return(false);
     }
   ArrayFree(arr_buffer);
   int       buffer_num=0;          // indicator buffer number 
//--- reset error code 
   ResetLastError();
//--- fill a part of the iOsMA array with values from the indicator buffer that has 0 index 
   int copied=CopyBuffer(handle_iOsMA,buffer_num,start_pos,count,arr_buffer);
   if(copied!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iOsMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
//---
   return(result);
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
               PrintResultTrade(m_trade,m_symbol);
              }
            else
              {
               Print(__FUNCTION__,", #2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
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
               PrintResultTrade(m_trade,m_symbol);
              }
            else
              {
               Print(__FUNCTION__,", #2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
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
                     RefreshRates();
                     m_position.SelectByIndex(i);
                     PrintResultModify(m_trade,m_symbol,m_position);
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
                     RefreshRates();
                     m_position.SelectByIndex(i);
                     PrintResultModify(m_trade,m_symbol,m_position);
                    }
              }

           }
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultTrade(CTrade &trade,CSymbolInfo &symbol)
  {
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result as a string: "+trade.ResultRetcodeDescription());
   Print("Deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("Order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("Volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("Price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("Current bid price: "+DoubleToString(symbol.Bid(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("Current ask price: "+DoubleToString(symbol.Ask(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("Broker comment: "+trade.ResultComment());
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultModify(CTrade &trade,CSymbolInfo &symbol,CPositionInfo &position)
  {
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result as a string: "+trade.ResultRetcodeDescription());
   Print("Deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("Order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("Volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("Price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("Current bid price: "+DoubleToString(symbol.Bid(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("Current ask price: "+DoubleToString(symbol.Ask(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("Broker comment: "+trade.ResultComment());
   Print("Price of position opening: "+DoubleToString(position.PriceOpen(),symbol.Digits()));
   Print("Price of position's Stop Loss: "+DoubleToString(position.StopLoss(),symbol.Digits()));
   Print("Price of position's Take Profit: "+DoubleToString(position.TakeProfit(),symbol.Digits()));
   Print("Current price by position: "+DoubleToString(position.PriceCurrent(),symbol.Digits()));
  }
//+------------------------------------------------------------------+

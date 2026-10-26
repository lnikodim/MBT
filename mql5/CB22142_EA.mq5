//+------------------------------------------------------------------+
//|                                              Rollback system.mq5 |
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
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
//--- input parameters
input double   InpLots              = 0.1;      // Lots
input ushort   InpStopLoss          = 50;       // Stop Loss (in pips)
input ushort   InpTakeProfit        = 50;       // Take Profit (in pips)
input double   InpRollback          = 20;       // Rollback 
input double   InpChannelOpenClose  = 18;       // Channel Open Close
input double   InpChannelRollback   = 3;        // Channel Rollback
//---
input color                Inp_Rectangle_Open_Close   = clrMediumPurple;   // Rectangle Open: Color 
input color                Inp_Rectangle_Close_Open   = clrLawnGreen;      // Rectangle Close: Color 
input ENUM_LINE_STYLE      Inp_Rectangle_Style        = STYLE_DASH;        // Rectangle: Style
input int                  Inp_Rectangle_Width        = 2;                 // Rectangle: Width 
input bool                 Inp_Rectangle_Fill         = false;             // Rectangle: Filling  color 
input bool                 Inp_Rectangle_Back         = false;             // Rectangle: Background  
input bool                 Inp_Rectangle_Selection    = false;             // Rectangle: Highlight to move 
input bool                 Inp_Rectangle_Hidden       = true;              // Rectangle: Hidden in the object list 
input long                 Inp_Rectangle_ZOrder       = 0;                 // Rectangle: Priority for mouse click 
//---
input ulong    m_magic=55998580;// magic number
//---
ulong  m_slippage=10;                // slippage

double ExtStopLoss=0.0;
double ExtTakeProfit=0.0;
double ExtRollback=0.0;
double ExtChannelOpenClose=0.0;
double ExtChannelRollback=0.0;

double m_adjusted_point;             // point value adjusted for 3 or 5 points
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
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtStopLoss          = InpStopLoss           * m_adjusted_point;
   ExtTakeProfit        = InpTakeProfit         * m_adjusted_point;
   ExtRollback          = InpRollback           * m_adjusted_point;
   ExtChannelOpenClose  = InpChannelOpenClose   * m_adjusted_point;
   ExtChannelRollback   = InpChannelRollback    * m_adjusted_point;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   ObjectsDeleteAll(0,"Rectangle_",0,OBJ_RECTANGLE);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(m_symbol.Name(),PERIOD_H1,0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;

   if(IsPositionExists())
      return;

   MqlDateTime STimeCurrent;
   TimeToStruct(TimeCurrent(),STimeCurrent);
   if(STimeCurrent.hour==0 && STimeCurrent.min<=3 && STimeCurrent.day_of_week!=1 && STimeCurrent.day_of_week!=5)
     {
      if(!RefreshRates())
        {
         PrevBars=0;
         return;
        }

      string            symbol_name    = m_symbol.Name();   // symbol name 
      ENUM_TIMEFRAMES   timeframe      = PERIOD_H1;         // period 
      int               start_pos      = 0;                 // start position 
      int               count          = 25;                // data count to copy 
      MqlRates          rates[];                            // target array to copy 
      ArraySetAsSeries(rates,true);
      if(CopyRates(symbol_name,timeframe,start_pos,count,rates)!=count)
        {
         PrevBars=0;
         return;
        }
      double Open_24_minus_Close_1     = rates[24].open-rates[1].close; //Open[24]-Close[1];
      double Close_1_minus_Open_24     = rates[1].close-rates[24].open; //Close[1]-Open[24];
      double Highest = DBL_MIN;
      double Lowest  = DBL_MAX;
      for(int i=1;i<25;i++)
        {
         if(rates[i].high>Highest)
            Highest=rates[i].high;
         if(rates[i].low<Lowest)
            Lowest=rates[i].low;
        }
      double Close_1_minus_Lowest      = rates[1].close-Lowest;         //Close[1]-Low[Lowest(NULL,60,MODE_LOW,24,0)];
      double Highest_minus_Close_1     = Highest-rates[1].close;        //High[Highest(NULL,60,MODE_HIGH,24,0)]-Close[1];
      //--- check for long position (BUY) possibility
      if(Open_24_minus_Close_1>ExtChannelOpenClose && Close_1_minus_Lowest<(ExtRollback-ExtChannelRollback))
        {
         int d=0;
         RectangleCreate(0,"Rectangle_"+TimeToString(PrevBars,TIME_DATE|TIME_MINUTES),0,
                         rates[24].time,rates[24].open,rates[1].time,rates[1].close,Inp_Rectangle_Open_Close,
                         Inp_Rectangle_Style,Inp_Rectangle_Width,Inp_Rectangle_Fill,Inp_Rectangle_Back,
                         Inp_Rectangle_Selection,Inp_Rectangle_Hidden,Inp_Rectangle_ZOrder);
         double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
         if(sl>=m_symbol.Bid()) // incident: the position isn't opened yet, and has to be already closed
           {
            PrevBars=0;
            return;
           }
         double tp=(InpTakeProfit==0)?0.0:m_symbol.Ask()+ExtTakeProfit;
         OpenBuy(sl,tp);
         return;
        }
      if(Close_1_minus_Open_24>ExtChannelOpenClose && Highest_minus_Close_1>ExtRollback+ExtChannelRollback)
        {
         int d=0;
         RectangleCreate(0,"Rectangle_"+TimeToString(PrevBars,TIME_DATE|TIME_MINUTES),0,
                         rates[24].time,rates[24].open,rates[1].time,rates[1].close,Inp_Rectangle_Close_Open,
                         Inp_Rectangle_Style,Inp_Rectangle_Width,Inp_Rectangle_Fill,Inp_Rectangle_Back,
                         Inp_Rectangle_Selection,Inp_Rectangle_Hidden,Inp_Rectangle_ZOrder);
         double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
         if(sl>=m_symbol.Bid()) // incident: the position isn't opened yet, and has to be already closed
           {
            PrevBars=0;
            return;
           }
         double tp=(InpTakeProfit==0)?0.0:m_symbol.Ask()+ExtTakeProfit;
         OpenBuy(sl,tp);
         return;
        }
      //--- check for short position (SELL) possibility
      if(Close_1_minus_Open_24>ExtChannelOpenClose && Highest_minus_Close_1<ExtRollback-ExtChannelRollback)
        {
         int d=0;
         RectangleCreate(0,"Rectangle_"+TimeToString(PrevBars,TIME_DATE|TIME_MINUTES),0,
                         rates[24].time,rates[24].open,rates[1].time,rates[1].close,Inp_Rectangle_Close_Open,
                         Inp_Rectangle_Style,Inp_Rectangle_Width,Inp_Rectangle_Fill,Inp_Rectangle_Back,
                         Inp_Rectangle_Selection,Inp_Rectangle_Hidden,Inp_Rectangle_ZOrder);
         double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
         if(sl<=m_symbol.Ask()) // incident: the position isn't opened yet, and has to be already closed
           {
            PrevBars=0;
            return;
           }
         double tp=(InpTakeProfit==0)?0.0:m_symbol.Bid()-ExtTakeProfit;
         OpenSell(sl,tp);
         return;
        }
      if(Open_24_minus_Close_1>ExtChannelOpenClose && Close_1_minus_Lowest>ExtRollback+ExtChannelRollback)
        {
         int d=0;
         RectangleCreate(0,"Rectangle_"+TimeToString(PrevBars,TIME_DATE|TIME_MINUTES),0,
                         rates[24].time,rates[24].open,rates[1].time,rates[1].close,Inp_Rectangle_Open_Close,
                         Inp_Rectangle_Style,Inp_Rectangle_Width,Inp_Rectangle_Fill,Inp_Rectangle_Back,
                         Inp_Rectangle_Selection,Inp_Rectangle_Hidden,Inp_Rectangle_ZOrder);
         double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
         if(sl<=m_symbol.Ask()) // incident: the position isn't opened yet, and has to be already closed
           {
            PrevBars=0;
            return;
           }
         double tp=(InpTakeProfit==0)?0.0:m_symbol.Bid()-ExtTakeProfit;
         OpenSell(sl,tp);
         return;
        }
     }
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
bool OpenBuy(double sl,double tp)
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
               return(false);
              }
            else
              {
               Print(__FUNCTION__,", #2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
               return(true);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
            return(false);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< Lots (",DoubleToString(InpLots,2),")");
         return(false);
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return(false);
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
bool OpenSell(double sl,double tp)
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
               return(false);
              }
            else
              {
               Print(__FUNCTION__,", #2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
               return(true);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
            return(false);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< Lots (",DoubleToString(InpLots,2),")");
         return(false);
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return(false);
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultTrade(CTrade &trade,CSymbolInfo &symbol)
  {
   Print("File: ",__FILE__,", symbol: ",m_symbol.Name());
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
//| Create rectangle by the given coordinates                        | 
//+------------------------------------------------------------------+ 
bool RectangleCreate(const long            chart_ID=0,        // chart's ID 
                     const string          name="Rectangle",  // rectangle name 
                     const int             sub_window=0,      // subwindow index  
                     datetime              time1=0,           // first point time 
                     double                price1=0,          // first point price 
                     datetime              time2=0,           // second point time 
                     double                price2=0,          // second point price 
                     const color           clr=clrRed,        // rectangle color 
                     const ENUM_LINE_STYLE style=STYLE_SOLID, // style of rectangle lines 
                     const int             width=1,           // width of rectangle lines 
                     const bool            fill=false,        // filling rectangle with color 
                     const bool            back=false,        // in the background 
                     const bool            selection=true,    // highlight to move 
                     const bool            hidden=true,       // hidden in the object list 
                     const long            z_order=0)         // priority for mouse click 
  {
////--- set anchor points' coordinates if they are not set 
//ChangeRectangleEmptyPoints(time1,price1,time2,price2);
//--- reset the error value 
   ResetLastError();
//--- create a rectangle by the given coordinates 
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE,sub_window,time1,price1,time2,price2))
     {
      Print(__FUNCTION__,
            ": failed to create a rectangle! Error code = ",GetLastError());
      return(false);
     }
//--- set rectangle color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set the style of rectangle lines 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set width of the rectangle lines 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- enable (true) or disable (false) the mode of filling the rectangle 
   ObjectSetInteger(chart_ID,name,OBJPROP_FILL,fill);
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of highlighting the rectangle for moving 
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

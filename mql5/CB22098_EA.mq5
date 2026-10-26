//+------------------------------------------------------------------+
//|                               Ketty(barabashkakvn's edition).mq5 |
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
CPositionInfo  m_position;                      // trade position object
CTrade         m_trade;                         // trading object
CSymbolInfo    m_symbol;                        // symbol info object
COrderInfo     m_order;                         // pending orders object
//--- input parameters
input double   InpLots                 = 0.1;   // Lots
input ushort   InpStopLoss             = 35;    // Stop Loss (in pips)
input ushort   InpTakeProfit           = 75;    // Take Profit (in pips)
input uchar    InpChannelStartHour     = 07;    // Channel start hour 
input uchar    InpChannelStartMin      = 00;    // Channel start minute 
input uchar    InpChannelEndHour       = 08;    // Channel end hour 
input uchar    InpChannelEndtMin       = 00;    // Channel end minute 
input uchar    InpPlacingStartHour     = 08;    // Placing order start time (hour)
input uchar    InpPlacingEndHour       = 18;    // Placing order end time (hour)
input ushort   InpChannelBreakthrough  = 30;    // Channel breakthrough (in pips)
input ushort   InpOrderPriceShift      = 10;    // Order price shift (in pips)
input bool     InpVisual               = true;  // Channel visual 
//---
input color                Inp_Rectangle_Color        = clrMediumPurple;   // Rectangle Open: Color 
input ENUM_LINE_STYLE      Inp_Rectangle_Style        = STYLE_DASH;        // Rectangle: Style
input int                  Inp_Rectangle_Width        = 2;                 // Rectangle: Width 
input bool                 Inp_Rectangle_Fill         = false;             // Rectangle: Filling  color 
input bool                 Inp_Rectangle_Back         = false;             // Rectangle: Background  
input bool                 Inp_Rectangle_Selection    = false;             // Rectangle: Highlight to move 
input bool                 Inp_Rectangle_Hidden       = true;              // Rectangle: Hidden in the object list 
input long                 Inp_Rectangle_ZOrder       = 0;                 // Rectangle: Priority for mouse click 
//---

input ulong    m_magic=572077809;               // magic number
//---
ulong  m_slippage=10;               // slippage

double ExtStopLoss=0.0;
double ExtTakeProfit=0.0;
double ExtChannelBreakthrough=0.0;
double ExtOrderPriceShift=0.0;

double m_adjusted_point;            // point value adjusted for 3 or 5 points

bool   m_delete_pending=false;

double  BuyPrice,SellPrice;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpChannelStartHour>23)
     {
      string text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                  "Параметр \"Channel start hour\" не может быть больше 23!":
                  "Parameter \"Channel start hour\" can not be more than 23!";
      Alert(__FUNCTION__," ERROR! ",text);
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpChannelStartMin>59)
     {
      string text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                  "Параметр \"Channel start minute\" не может быть больше 59!":
                  "Parameter \"Channel start minute\" can not be more than 59!";
      Alert(__FUNCTION__," ERROR! ",text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(InpChannelEndHour>23)
     {
      string text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                  "Параметр \"Channel end hour\" не может быть больше 23!":
                  "Parameter \"Channel end hour\" can not be more than 23!";
      Alert(__FUNCTION__," ERROR! ",text);
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpChannelEndtMin>59)
     {
      string text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                  "Параметр \"Channel end minute\" не может быть больше 59!":
                  "Parameter \"Channel end minute\" can not be more than 59!";
      Alert(__FUNCTION__," ERROR! ",text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(InpPlacingStartHour>23)
     {
      string text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                  "Параметр \"Placing order start time\" не может быть больше 23!":
                  "Parameter \"Placing order start time\" can not be more than 23!";
      Alert(__FUNCTION__," ERROR! ",text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(InpPlacingEndHour>23)
     {
      string text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                  "Параметр \"Placing order end time\" не может быть больше 23!":
                  "Parameter \"Placing order end time\" can not be more than 23!";
      Alert(__FUNCTION__," ERROR! ",text);
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
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtStopLoss             = InpStopLoss              * m_adjusted_point;
   ExtTakeProfit           = InpTakeProfit            * m_adjusted_point;
   ExtChannelBreakthrough  = InpChannelBreakthrough   * m_adjusted_point;
   ExtOrderPriceShift      = InpOrderPriceShift       * m_adjusted_point;
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
   if(m_delete_pending)
     {
      if(IsPendingOrdersExists())
        {
         DeleteAllPendingOrders();
         return;
        }
      else
         m_delete_pending=false;
     }
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(m_symbol.Name(),PERIOD_M1,0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
//---
   MqlDateTime STimeCurrent;
   TimeToStruct(TimeCurrent(),STimeCurrent);
   if(STimeCurrent.hour*60*60+STimeCurrent.min*60>InpPlacingEndHour*60*60 && IsPendingOrdersExists())
     {
      m_delete_pending=true;
      return;
     }
   int rules=RulesOfKetty(STimeCurrent);
   if(rules!=0 && IsPendingOrdersExists())
      return;

   if(rules==1)
     {
      double sl=(InpStopLoss==0)?0.0:BuyPrice-ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:BuyPrice+ExtTakeProfit;
      PendingBuyStop(BuyPrice,sl,tp);
     }
   if(rules==2)
     {
      double sl=(InpStopLoss==0)?0.0:SellPrice+ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:SellPrice-ExtTakeProfit;
      PendingSellStop(SellPrice,sl,tp);
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
//| Is pendinf orders exists                                         |
//+------------------------------------------------------------------+
bool IsPendingOrdersExists(void)
  {
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Delete all pending orders                                        |
//+------------------------------------------------------------------+
void DeleteAllPendingOrders(void)
  {
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            m_trade.OrderDelete(m_order.Ticket());
  }
//+------------------------------------------------------------------+
//| RulesOfKetty                                                     |
//|   1 --> Buy                                                      |
//|   2 --> Sell                                                     |
//|   0 --> No signal                                                |
//+------------------------------------------------------------------+
int RulesOfKetty(const MqlDateTime &struct_time)
  {
   if(struct_time.hour*60*60+struct_time.min*60>=InpPlacingStartHour*60*60 &&
      struct_time.hour*60*60+struct_time.min*60<=InpPlacingEndHour*60*60)
     {
      double max=0.0,min=0.0;

      MqlDateTime STimeStart;
      STimeStart=struct_time;
      STimeStart.hour=InpChannelStartHour;
      STimeStart.min=InpChannelStartMin;
      datetime start=StructToTime(STimeStart);
      MqlDateTime STimeEnd;
      STimeEnd=struct_time;
      STimeEnd.hour=InpChannelEndHour;
      STimeEnd.min=InpChannelEndtMin;
      datetime end=StructToTime(STimeEnd);

      double high[];
      ArraySetAsSeries(high,true);
      int copy_high=CopyHigh(m_symbol.Name(),Period(),start,end,high);
      double low[];
      ArraySetAsSeries(low,true);
      int copy_low=CopyLow(m_symbol.Name(),Period(),start,end,low);
      if(copy_high==-1 || copy_low==-1 || copy_high!=copy_low)
         return(0);
      max=high[ArrayMaximum(high)];
      min=low[ArrayMinimum(low)];

      SellPrice   = min-ExtOrderPriceShift;
      BuyPrice    = max+ExtOrderPriceShift;

      if(InpVisual)
         RectangleCreate(0,"Channel "+TimeToString(start,TIME_DATE|TIME_MINUTES),0,start,max,end,min,
                         Inp_Rectangle_Color,Inp_Rectangle_Style,Inp_Rectangle_Width,Inp_Rectangle_Fill,Inp_Rectangle_Back,
                         Inp_Rectangle_Selection,Inp_Rectangle_Hidden,Inp_Rectangle_ZOrder);
      if(iLow(m_symbol.Name(),Period(),1)<min-ExtChannelBreakthrough)
         return(1); // Buy
      if(iHigh(m_symbol.Name(),Period(),1)>max+ExtChannelBreakthrough)
         return(2); // Sell
     }
//---
   return(0);
  }
//+------------------------------------------------------------------+ 
//| Create rectangle by the given coordinates                        | 
//+------------------------------------------------------------------+ 
void RectangleCreate(const long            chart_ID=0,        // chart's ID 
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
   if(ObjectFind(chart_ID,name)>=0)
      return;
//--- reset the error value 
   ResetLastError();
//--- create a rectangle by the given coordinates 
   if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE,sub_window,time1,price1,time2,price2))
     {
      Print(__FUNCTION__,
            ": failed to create a rectangle! Error code = ",GetLastError());
      return;
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
   return;
  }
//+------------------------------------------------------------------+
//| Pending order of Buy Stop                                        |
//+------------------------------------------------------------------+
void PendingBuyStop(double price,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.BuyStop(InpLots,m_symbol.NormalizePrice(price),
            m_symbol.Name(),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp)))
           {
            if(m_trade.ResultOrder()==0)
              {
               Print("#1 Buy Stop -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Buy Stop -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Buy Stop -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< Lots ("+DoubleToString(InpLots,2)+")");
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
//| Pending order of Sell Stop                                       |
//+------------------------------------------------------------------+
void PendingSellStop(double price,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.SellStop(InpLots,m_symbol.NormalizePrice(price),
            m_symbol.Name(),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp)))
           {
            if(m_trade.ResultOrder()==0)
              {
               Print("#1 Sell Stop -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Sell Stop -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Sell Stop -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(InpLots,2),") ",
               "< Lots ("+DoubleToString(InpLots,2)+")");
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

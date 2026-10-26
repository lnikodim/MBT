#property copyright "2026, Cheng Kah Seng"
#property link      "https://forge.mql5.io"
#property version   "1.00"
#property description "Educational completed-candle EMA and RSI Expert Advisor with a compact dashboard."
#property strict

input group "Entry Settings"
input int      FastEMA=9;
input int      SlowEMA=21;
input int      RSIPeriod=14;
input double   BuyRSILevel=48.0;
input double   SellRSILevel=52.0;
input bool     OneEntryPerCandle=true;

input group "Trade Settings"
input ulong    MagicNumber=26071501;
input double   FixedLot=0.01;
input int      MaximumSpreadPoints=50;
input int      StopLossPoints=500;
input int      TakeProfitPoints=500;
input int      SlippagePoints=30;

input group "Dashboard"
input ENUM_BASE_CORNER DashboardCorner=CORNER_LEFT_UPPER;
input int      DashboardX=12;
input int      DashboardY=25;
input int      DashboardFontSize=10;

const color AQL_GOLD=C'212,175,55';
const color AQL_DARK=C'20,20,22';
const color AQL_PANEL=C'38,38,42';
const color AQL_GREEN=C'38,190,110';
const color AQL_RED=C'230,70,70';
const color AQL_WHITE=C'230,230,230';

int      g_fast_handle=INVALID_HANDLE;
int      g_slow_handle=INVALID_HANDLE;
int      g_rsi_handle=INVALID_HANDLE;
double   g_fast=0.0;
double   g_slow=0.0;
double   g_rsi=0.0;
datetime g_last_bar=0;
datetime g_last_entry_bar=0;
string   g_status="Initializing";
string   g_signal="Waiting";
string   g_prefix="AQL_";

string Obj(const string key)
  {
   return g_prefix+key;
  }

void DeleteDashboard()
  {
   for(int i=ObjectsTotal(0)-1;i>=0;i--)
     {
      string name=ObjectName(0,i);
      if(StringFind(name,g_prefix)==0) ObjectDelete(0,name);
     }
  }

void MakeLabel(const string key,const string text,const int x,const int y,const color clr,const int size)
  {
   string name=Obj(key);
   if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,name,OBJPROP_CORNER,DashboardCorner);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
   ObjectSetString(0,name,OBJPROP_FONT,"Arial");
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
  }

void CreateDashboard()
  {
   string panel=Obj("PANEL");
   if(ObjectFind(0,panel)<0) ObjectCreate(0,panel,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,panel,OBJPROP_CORNER,DashboardCorner);
   ObjectSetInteger(0,panel,OBJPROP_XDISTANCE,DashboardX);
   ObjectSetInteger(0,panel,OBJPROP_YDISTANCE,DashboardY);
   ObjectSetInteger(0,panel,OBJPROP_XSIZE,285);
   ObjectSetInteger(0,panel,OBJPROP_YSIZE,185);
   ObjectSetInteger(0,panel,OBJPROP_BGCOLOR,AQL_DARK);
   ObjectSetInteger(0,panel,OBJPROP_BORDER_COLOR,AQL_GOLD);
   ObjectSetInteger(0,panel,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,panel,OBJPROP_HIDDEN,true);
   MakeLabel("TITLE","AEGIS QUANTUM LITE",DashboardX+14,DashboardY+10,AQL_GOLD,DashboardFontSize+2);
  }

string TimeframeText()
  {
   return EnumToString((ENUM_TIMEFRAMES)_Period);
  }

bool ReadIndicators()
  {
   double fast[1],slow[1],rsi[1];
   if(CopyBuffer(g_fast_handle,0,1,1,fast)!=1) return false;
   if(CopyBuffer(g_slow_handle,0,1,1,slow)!=1) return false;
   if(CopyBuffer(g_rsi_handle,0,1,1,rsi)!=1) return false;
   g_fast=fast[0];
   g_slow=slow[0];
   g_rsi=rsi[0];
   return true;
  }

bool HasSymbolPosition()
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      if(PositionGetTicket(i)==0) continue;
      if(PositionGetString(POSITION_SYMBOL)==_Symbol) return true;
     }
   return false;
  }

double NormalizeVolume(double volume)
  {
   double minv=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxv=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step<=0.0) step=0.01;
   volume=MathMax(minv,MathMin(maxv,volume));
   volume=MathFloor(volume/step+1e-9)*step;
   return NormalizeDouble(volume,8);
  }

ENUM_ORDER_TYPE_FILLING FillingMode()
  {
   long mode=SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
   if((mode&SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC) return ORDER_FILLING_IOC;
   if((mode&SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK) return ORDER_FILLING_FOK;
   return ORDER_FILLING_RETURN;
  }

bool OpenMarket(const ENUM_ORDER_TYPE type)
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ||
      !MQLInfoInteger(MQL_TRADE_ALLOWED) ||
      !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
     {
      g_status="Trading is not allowed";
      return false;
     }

   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick)) return false;
   double volume=NormalizeVolume(FixedLot);
   double price=(type==ORDER_TYPE_BUY?tick.ask:tick.bid);
   int digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);

   MqlTradeRequest request={};
   MqlTradeResult result={};
   request.action=TRADE_ACTION_DEAL;
   request.magic=MagicNumber;
   request.symbol=_Symbol;
   request.volume=volume;
   request.type=type;
   request.price=price;
   request.deviation=SlippagePoints;
   request.type_filling=FillingMode();
   request.type_time=ORDER_TIME_GTC;
   request.comment="Aegis Quantum Lite";
   if(StopLossPoints>0)
      request.sl=NormalizeDouble(type==ORDER_TYPE_BUY?price-StopLossPoints*_Point:price+StopLossPoints*_Point,digits);
   if(TakeProfitPoints>0)
      request.tp=NormalizeDouble(type==ORDER_TYPE_BUY?price+TakeProfitPoints*_Point:price-TakeProfitPoints*_Point,digits);

   double margin=0.0;
   if(OrderCalcMargin(type,_Symbol,volume,price,margin) &&
      margin>AccountInfoDouble(ACCOUNT_MARGIN_FREE)+1e-8)
     {
      g_status="Insufficient free margin";
      return false;
     }

   MqlTradeCheckResult check={};
   if(!OrderCheck(request,check))
     {
      g_status="Order check failed";
      return false;
     }
   if(check.retcode!=TRADE_RETCODE_DONE && check.retcode!=TRADE_RETCODE_PLACED)
     {
      g_status=StringFormat("Order blocked: %u",check.retcode);
      return false;
     }

   if(!OrderSend(request,result))
     {
      g_status="Order send failed";
      return false;
     }
   if(result.retcode!=TRADE_RETCODE_DONE && result.retcode!=TRADE_RETCODE_DONE_PARTIAL &&
      result.retcode!=TRADE_RETCODE_PLACED)
     {
      g_status=StringFormat("Trade rejected: %u",result.retcode);
      return false;
     }
   g_status=(type==ORDER_TYPE_BUY?"Buy opened":"Sell opened");
   g_last_entry_bar=iTime(_Symbol,_Period,0);
   return true;
  }

void UpdateDashboard()
  {
   MqlTick tick={};
   SymbolInfoTick(_Symbol,tick);
   double spread=(tick.ask-tick.bid)/_Point;
   int x=DashboardX+14;
   int y=DashboardY+38;
   int line=20;
   MakeLabel("SYMBOL","Symbol / TF: "+_Symbol+" / "+TimeframeText(),x,y,AQL_WHITE,DashboardFontSize);
   MakeLabel("EMA",StringFormat("EMA %d / %d: %.5f / %.5f",FastEMA,SlowEMA,g_fast,g_slow),x,y+line,AQL_WHITE,DashboardFontSize);
   MakeLabel("RSI",StringFormat("RSI %d: %.2f",RSIPeriod,g_rsi),x,y+line*2,AQL_WHITE,DashboardFontSize);
   MakeLabel("SPREAD",StringFormat("Spread: %.1f points",spread),x,y+line*3,(spread<=MaximumSpreadPoints?AQL_GREEN:AQL_RED),DashboardFontSize);
   MakeLabel("SIGNAL","Signal: "+g_signal,x,y+line*4,(g_signal=="Buy"?AQL_GREEN:(g_signal=="Sell"?AQL_RED:AQL_GOLD)),DashboardFontSize);
   MakeLabel("STATUS","Status: "+g_status,x,y+line*5,AQL_GOLD,DashboardFontSize);
   MakeLabel("MODE","Educational fixed-lot edition",x,y+line*6,AQL_WHITE,DashboardFontSize-1);
   ChartRedraw();
  }

int OnInit()
  {
   if(FastEMA<1 || SlowEMA<=FastEMA || RSIPeriod<2 || FixedLot<=0.0 ||
      BuyRSILevel<=0.0 || BuyRSILevel>=100.0 || SellRSILevel<=0.0 || SellRSILevel>=100.0)
      return INIT_PARAMETERS_INCORRECT;

   g_fast_handle=iMA(_Symbol,_Period,FastEMA,0,MODE_EMA,PRICE_CLOSE);
   g_slow_handle=iMA(_Symbol,_Period,SlowEMA,0,MODE_EMA,PRICE_CLOSE);
   g_rsi_handle=iRSI(_Symbol,_Period,RSIPeriod,PRICE_CLOSE);
   if(g_fast_handle==INVALID_HANDLE || g_slow_handle==INVALID_HANDLE || g_rsi_handle==INVALID_HANDLE)
      return INIT_FAILED;
   g_last_bar=iTime(_Symbol,_Period,0);
   CreateDashboard();
   g_status="Waiting for a new candle";
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   if(g_fast_handle!=INVALID_HANDLE) IndicatorRelease(g_fast_handle);
   if(g_slow_handle!=INVALID_HANDLE) IndicatorRelease(g_slow_handle);
   if(g_rsi_handle!=INVALID_HANDLE) IndicatorRelease(g_rsi_handle);
   DeleteDashboard();
  }

void OnTick()
  {
   if(!ReadIndicators())
     {
      g_status="Indicator data unavailable";
      UpdateDashboard();
      return;
     }

   bool buy_signal=(g_fast>g_slow && g_rsi>BuyRSILevel);
   bool sell_signal=(g_fast<g_slow && g_rsi<SellRSILevel);
   g_signal=(buy_signal?"Buy":(sell_signal?"Sell":"Waiting"));

   datetime current_bar=iTime(_Symbol,_Period,0);
   bool new_bar=(current_bar!=g_last_bar);
   if(new_bar) g_last_bar=current_bar;

   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick)) return;
   double spread=(tick.ask-tick.bid)/_Point;

   if(!new_bar)
      g_status="Waiting for completed candle";
   else if(HasSymbolPosition())
      g_status="Existing symbol position";
   else if(spread>MaximumSpreadPoints)
      g_status="Spread too high";
   else if(OneEntryPerCandle && g_last_entry_bar==current_bar)
      g_status="Same candle entry blocked";
   else if(buy_signal)
      OpenMarket(ORDER_TYPE_BUY);
   else if(sell_signal)
      OpenMarket(ORDER_TYPE_SELL);
   else
      g_status="EMA or RSI condition not met";

   UpdateDashboard();
  }

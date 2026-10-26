//+------------------------------------------------------------------+
//|                                        EMA_Cross_Scalper_M15.mq5 |
//|                   XAUUSD M15 EMA(10) x EMA(30) - 19:00-22:00 WIB |
//|                                              v1.10 - educational |
//+------------------------------------------------------------------+
#property copyright "Cintia Andrea Boos"
#property version   "1.11"
#property description "EMA(10) x EMA(30) scalper for XAUUSD M15 with WIB session filter."
#property description "Educational sample: fixed lot, SL/TP in points, max 1 position."

#include <Trade\Trade.mqh>
CTrade trade;

//--- signal inputs
input group "=== EMA Signal (M15) ==="
input int    InpFastEMA   = 10;                // Fast EMA
input int    InpSlowEMA   = 30;                // Slow EMA
input ENUM_TIMEFRAMES InpSignalTF = PERIOD_M15; // Signal timeframe

input group "=== WIB Jakarta Hours ==="
input int    InpStartHourWIB = 19;   // Session start hour (WIB)
input int    InpEndHourWIB   = 22;   // Session end hour, inclusive (open until 22:59 WIB)
input int    InpWIBOffsetGMT = 7;    // WIB = GMT+7

input group "=== Risk ==="
input double InpLot      = 0.01;       // Lot size
input int    InpSLpoints = 70;         // Stop Loss (points)
input int    InpTPpoints = 200;        // Take Profit (points, usable range 150-300)
input int    InpMaxPos   = 1;          // Max open positions
input long   InpMagic    = 20260909;   // Magic number
input int    InpDeviation = 10;        // Max deviation (points)
input int    InpMaxSpreadPoints = 100; // Max spread (points, 0=disabled)

//--- indicator handles
int g_fastHandle = INVALID_HANDLE;
int g_slowHandle = INVALID_HANDLE;
datetime g_lastBarTime = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpFastEMA >= InpSlowEMA)
     {
      Print("ERROR: fast EMA must be smaller than slow EMA");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpTPpoints < 150 || InpTPpoints > 300)
      Print("WARNING: TP outside the 150-300 range. Still applied: ", InpTPpoints);
   if(InpLot <= 0)
     {
      Print("ERROR: lot size must be > 0");
      return(INIT_PARAMETERS_INCORRECT);
     }

//--- create EMA indicators
   g_fastHandle = iMA(_Symbol, InpSignalTF, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_slowHandle = iMA(_Symbol, InpSignalTF, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(g_fastHandle == INVALID_HANDLE || g_slowHandle == INVALID_HANDLE)
     {
      Print("ERROR creating iMA handles: ", GetLastError());
      return(INIT_FAILED);
     }

   trade.SetExpertMagicNumber((long)InpMagic);
   trade.SetDeviationInPoints(InpDeviation);
   trade.SetTypeFillingBySymbol(_Symbol);

   Print("EMA_Cross_Scalper_M15 started: EMA", InpFastEMA, "xEMA", InpSlowEMA,
         " | ", InpStartHourWIB, ":00-", InpEndHourWIB, ":59 WIB | Lot=", InpLot,
         " SL=", InpSLpoints, " TP=", InpTPpoints, " MaxPos=", InpMaxPos);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(g_fastHandle != INVALID_HANDLE)
      IndicatorRelease(g_fastHandle);
   if(g_slowHandle != INVALID_HANDLE)
      IndicatorRelease(g_slowHandle);
  }
//+------------------------------------------------------------------+
//| Current hour in WIB (Jakarta) via TimeGMT + offset               |
//+------------------------------------------------------------------+
int HourWIB()
  {
   datetime gmt = TimeGMT();
//--- fallback to server time on very old tester builds
   if(gmt == 0)
      gmt = TimeTradeServer();
   else
      gmt = gmt + InpWIBOffsetGMT * 3600;
   MqlDateTime st;
   TimeToStruct(gmt, st);
   return(st.hour);
  }
//+------------------------------------------------------------------+
//| Session filter                                                   |
//+------------------------------------------------------------------+
bool InTradingHours()
  {
   int h = HourWIB();
   if(InpStartHourWIB <= InpEndHourWIB)
      return(h >= InpStartHourWIB && h <= InpEndHourWIB);
//--- overnight session (not the 19-22 case, kept for robustness)
   return(h >= InpStartHourWIB || h <= InpEndHourWIB);
  }
//+------------------------------------------------------------------+
//| Count our positions (magic + symbol)                             |
//+------------------------------------------------------------------+
int CountMyPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket((uint)i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      count++;
     }
   return(count);
  }
//+------------------------------------------------------------------+
//| New bar on the signal timeframe                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   datetime cur = iTime(_Symbol, InpSignalTF, 0);
   if(cur == 0)
      return(false);
   if(cur != g_lastBarTime)
     {
      g_lastBarTime = cur;
      return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+
//| Returns +1 on UP cross, -1 on DOWN cross, 0 otherwise             |
//+------------------------------------------------------------------+
int GetCross()
  {
   double fast[3], slow[3];
   if(CopyBuffer(g_fastHandle, 0, 1, 2, fast) < 2)
      return(0);
   if(CopyBuffer(g_slowHandle, 0, 1, 2, slow) < 2)
      return(0);
//--- fast[0]=last closed bar, fast[1]=bar before it
   bool wasBelow = (fast[1] <= slow[1]);
   bool nowAbove = (fast[0] >  slow[0]);
   bool wasAbove = (fast[1] >= slow[1]);
   bool nowBelow = (fast[0] <  slow[0]);
   if(wasBelow && nowAbove)
      return(+1);
   if(wasAbove && nowBelow)
      return(-1);
   return(0);
  }
//+------------------------------------------------------------------+
//| Validate stops against live bid/ask (BUY exits on bid,           |
//| SELL exits on ask) plus a spread filter to avoid invalid stops   |
//+------------------------------------------------------------------+
double NormPrice(double p) { return(NormalizeDouble(p, _Digits)); }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckStops(bool isBuy, double ask, double bid, double sl, double tp)
  {
   long stopsLevel = 0;
   SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL, stopsLevel);
   double minDist = (double)stopsLevel * _Point;
   if(isBuy)
     {
      //--- BUY stop-loss / take-profit trigger on bid
      if((bid - sl) < minDist || (tp - bid) < minDist)
        {
         Print("BUY SL/TP too close (bid). Min dist=", stopsLevel,
               " points, spread=", DoubleToString((ask - bid) / _Point, 1));
         return(false);
        }
     }
   else
     {
      //--- SELL stop-loss / take-profit trigger on ask
      if((sl - ask) < minDist || (ask - tp) < minDist)
        {
         Print("SELL SL/TP too close (ask). Min dist=", stopsLevel,
               " points, spread=", DoubleToString((ask - bid) / _Point, 1));
         return(false);
        }
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| Free-margin check: skip the signal cleanly when the account      |
//| cannot afford the position (no server "No money" errors)         |
//+------------------------------------------------------------------+
bool EnoughMoney(double vol, ENUM_ORDER_TYPE type, double price)
  {
   double margin = 0.0;
   if(!OrderCalcMargin(type, _Symbol, vol, price, margin))
     {
      Print("OrderCalcMargin failed: ", GetLastError());
      return(false);
     }
   double free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(margin > free)
     {
      Print("Not enough money: need ", DoubleToString(margin, 2),
            ", free ", DoubleToString(free, 2), ", signal skipped");
      return(false);
     }
   return(true);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- evaluate on new bars only (no repainting, one signal per bar)
   if(!IsNewBar())
      return;

//--- session filter: no new trades outside WIB hours (open ones are kept)
   if(!InTradingHours())
      return;

//--- max positions (magic + symbol)
   if(CountMyPositions() >= InpMaxPos)
      return;

   int cross = GetCross();
   if(cross == 0)
      return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask <= 0 || bid <= 0)
      return;

//--- spread filter: skip expensive scalps and rejected stops
   if(InpMaxSpreadPoints > 0)
     {
      double spreadPts = (ask - bid) / _Point;
      if(spreadPts > InpMaxSpreadPoints)
        {
         Print("Spread too high (", DoubleToString(spreadPts, 1), " pts), signal skipped");
         return;
        }
     }

//--- normalize lot to the broker minimum/maximum/step
   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double vol = MathMax(minVol, MathMin(maxVol, InpLot));
   vol = MathFloor(vol / volStep) * volStep;
   vol = NormalizeDouble(vol, 2);
   if(vol < minVol)
     {
      Print("Lot below the broker minimum");
      return;
     }

   if(cross > 0)
     {
      double sl = NormPrice(ask - InpSLpoints * _Point);
      double tp = NormPrice(ask + InpTPpoints * _Point);
      if(!CheckStops(true, ask, bid, sl, tp))
         return;
      if(!EnoughMoney(vol, ORDER_TYPE_BUY, ask))
         return;
      if(!trade.Buy(vol, _Symbol, ask, sl, tp, "EMA cross UP"))
         Print("Buy failed: ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
      else
         Print("BUY opened: EMA", InpFastEMA, " crossed UP EMA", InpSlowEMA, " | WIB hour=", HourWIB());
     }
   else
     {
      double sl = NormPrice(bid + InpSLpoints * _Point);
      double tp = NormPrice(bid - InpTPpoints * _Point);
      if(!CheckStops(false, ask, bid, sl, tp))
         return;
      if(!EnoughMoney(vol, ORDER_TYPE_SELL, bid))
         return;
      if(!trade.Sell(vol, _Symbol, bid, sl, tp, "EMA cross DOWN"))
         Print("Sell failed: ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
      else
         Print("SELL opened: EMA", InpFastEMA, " crossed DOWN EMA", InpSlowEMA, " | WIB hour=", HourWIB());
     }
  }
//+------------------------------------------------------------------+

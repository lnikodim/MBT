//+------------------------------------------------------------------+
//|                                                   TEB_MTF_EA.mq5 |
//|  TEB63 (Forex Factory, 2010): trend from a higher chart (5 EMA vs |
//|  12 EMA and RSI(20) vs 50), entries on the lower chart when the   |
//|  5 EMA crosses the 12 EMA with RSI on the trend side (or, variant,|
//|  a pullback to the 12 EMA that closes back above the 5 EMA).      |
//|  Two lots: lot 1 stop 10 pips / target 10 pips + spread; lot 2    |
//|  same stop, break-even once lot 1 is gone, then trailed under     |
//|  each confirmed swing. Session windows in server time.            |
//|  Execution, guards and trade log from EACore.mqh.                 |
//|  v1.00: spec 2026-10-16-teb-mtf-prereg.md                         |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.00"
#property strict
#property description "TEB 5/12 EMA + RSI(20) multi-timeframe: trend chart filter, lower-chart cross or pullback entry, two lots (10-pip scalp + swing-trailed runner); MACD_Cross_EA v1.42 safety core"

#define EA_NAME    "TEB_MTF_EA"
#define EA_VERSION "1.00"
#define EA_MAGIC   261017
#define EA_COMMENT "TEB_MTF"
#define EA_TIMEFRAME PERIOD_M5
#define EA_MAX_SPREAD_POINTS 20   // 2 pips on a 5-digit pair: a 10-pip scalp cannot pay more
#define EA_SPREAD_WAIT_MIN 0      // the target is pips from the signal price: a retried entry would break that
#include "EACore.mqh"

enum ENUM_TEB_ENTRY { TEB_CROSS = 0,     // 5 EMA crosses the 12 EMA on the entry chart
                      TEB_PULLBACK = 1 };// Pullback to the 12 EMA that closes back beyond the 5 EMA

input group "=== Strategy ==="
input int             InpFastEMA         = 5;          // Fast EMA period (both charts)
input int             InpSlowEMA         = 12;         // Slow EMA period (both charts)
input int             InpRsiPeriod       = 20;         // RSI period (both charts)
input ENUM_TIMEFRAMES InpTrendTF         = PERIOD_M30; // Trend chart timeframe
input double          InpTrendRsiBuy     = 50.0;       // Trend chart RSI above this = buys allowed
input double          InpTrendRsiSell    = 50.0;       // Trend chart RSI below this = sells allowed
input double          InpEntryRsiLevel   = 50.0;       // Entry chart RSI level (buys above, sells below)
input ENUM_TEB_ENTRY  InpEntryMode       = TEB_CROSS;  // Entry
input double          InpStopPips        = 10.0;       // Stop loss (pips)
input double          InpTargetPips      = 10.0;       // Lot 1 target (pips, current spread is added)
input bool            InpSecondLot       = true;       // Lot 2: break-even after lot 1, then swing trail
input int             InpSwingBars       = 2;          // Swing = extreme with N bars on each side
input double          InpSwingBufferPips = 1.0;        // Trail buffer beyond the swing (pips)
input group "=== Sessions (server hours, end exclusive) ==="
input bool            InpUseSessions     = true;       // Trade only inside the sessions
input int             InpS1Start         = 10;         // Session 1 start (3am EST = London)
input int             InpS1End           = 12;         // Session 1 end
input int             InpS2Start         = 14;         // Session 2 start (7am EST = New York)
input int             InpS2End           = 19;         // Session 2 end
input int             InpS3Start         = 3;          // Session 3 start (8pm EST = Asia)
input int             InpS3End           = 5;          // Session 3 end

int g_fast = INVALID_HANDLE, g_slow = INVALID_HANDLE, g_rsi = INVALID_HANDLE,
    g_fastT = INVALID_HANDLE, g_slowT = INVALID_HANDLE, g_rsiT = INVALID_HANDLE;

double Pip() { return((_Digits == 5 || _Digits == 3) ? 10.0 * _Point : _Point); }
ENUM_TIMEFRAMES TrendTF() { return(InpTrendTF == PERIOD_CURRENT ? InpTimeframe : InpTrendTF); }

bool InSession(const datetime t)
  {
   if(!InpUseSessions)
      return(true);
   MqlDateTime d;
   TimeToStruct(t, d);
   const int h = d.hour;
   return((h >= InpS1Start && h < InpS1End) || (h >= InpS2Start && h < InpS2End) || (h >= InpS3Start && h < InpS3End));
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpFastEMA < 1 || InpSlowEMA <= InpFastEMA || InpRsiPeriod < 2 || InpStopPips <= 0.0 || InpTargetPips <= 0.0 ||
      InpSwingBars < 1 || InpSwingBufferPips < 0.0 || InpTrendRsiBuy < 0.0 || InpTrendRsiBuy > 100.0 ||
      InpTrendRsiSell < 0.0 || InpTrendRsiSell > 100.0 || InpEntryRsiLevel <= 0.0 || InpEntryRsiLevel >= 100.0 ||
      PeriodSeconds(TrendTF()) <= PeriodSeconds(InpTimeframe))
     {
      Print("Invalid inputs: slow EMA > fast EMA >= 1, RSI >= 2, stop/target pips > 0, swing bars >= 1, RSI levels 0..100, trend timeframe above the entry timeframe");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   g_fast  = iMA(_Symbol, InpTimeframe, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_slow  = iMA(_Symbol, InpTimeframe, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_rsi   = iRSI(_Symbol, InpTimeframe, InpRsiPeriod, PRICE_CLOSE);
   g_fastT = iMA(_Symbol, TrendTF(), InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_slowT = iMA(_Symbol, TrendTF(), InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_rsiT  = iRSI(_Symbol, TrendTF(), InpRsiPeriod, PRICE_CLOSE);
   if(g_fast == INVALID_HANDLE || g_slow == INVALID_HANDLE || g_rsi == INVALID_HANDLE ||
      g_fastT == INVALID_HANDLE || g_slowT == INVALID_HANDLE || g_rsiT == INVALID_HANDLE)
     {
      Print("Failed to create indicators, error ", GetLastError());
      return(INIT_FAILED);
     }
   PrintFormat("%s v%s started on %s %s, magic %I64u, own positions: %d",
               EA_NAME, EA_VERSION, _Symbol, EnumToString(InpTimeframe), InpMagic, CountOwnPositions());
   PrintFormat("Inputs: EMA %d/%d RSI(%d) | trend %s RSI > %.0f buys / < %.0f sells | entry %s, RSI level %.0f | stop %.1f pips, lot-1 target %.1f pips + spread | lot 2 %s (swing %d bars, buffer %.1f pips) | sessions %s %02d-%02d %02d-%02d %02d-%02d | risk %s %.2f",
               InpFastEMA, InpSlowEMA, InpRsiPeriod, EnumToString(TrendTF()), InpTrendRsiBuy, InpTrendRsiSell,
               EnumToString(InpEntryMode), InpEntryRsiLevel, InpStopPips, InpTargetPips, InpSecondLot ? "on" : "off",
               InpSwingBars, InpSwingBufferPips, InpUseSessions ? "on" : "off", InpS1Start, InpS1End, InpS2Start, InpS2End,
               InpS3Start, InpS3End, InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   const int h[] = {g_fast, g_slow, g_rsi, g_fastT, g_slowT, g_rsiT};
   for(int i = 0; i < ArraySize(h); i++)
      if(h[i] != INVALID_HANDLE)
         IndicatorRelease(h[i]);
   Core_Deinit(reason);
  }

//--- most recent confirmed swing low (buy) / high (sell) on the entry chart, 0 if none in the last 100 bars
double LastSwing(const bool isBuy)
  {
   const int n = 100 + InpSwingBars;
   double v[];
   ArraySetAsSeries(v, true);
   if((isBuy ? CopyLow(_Symbol, InpTimeframe, 1, n, v) : CopyHigh(_Symbol, InpTimeframe, 1, n, v)) < n)
      return(0.0);
   for(int i = InpSwingBars; i < n - InpSwingBars; i++)        // i = bars back from the last closed bar (index 0)
     {
      bool ok = true;
      for(int k = 1; k <= InpSwingBars && ok; k++)
         ok = isBuy ? (v[i] < v[i - k] && v[i] < v[i + k]) : (v[i] > v[i - k] && v[i] > v[i + k]);
      if(ok)
         return(v[i]);
     }
   return(0.0);
  }

//--- lot 2: break-even once lot 1 is gone, then trail behind each confirmed swing (new bars only), tightening only
void ManageLot2(const bool newBar)
  {
   bool lot1Open = false;
   ulong t2 = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      const ulong t = PositionGetTicket(i);
      if(t == 0 || !IsOwnPosition())
         continue;
      if(PositionGetDouble(POSITION_TP) > 0.0) lot1Open = true; else t2 = t;
     }
   if(t2 == 0 || lot1Open || !PositionSelectByTicket(t2) || !g_symbol.RefreshRates())
      return;
   const bool   isBuy  = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
   const double open   = PositionGetDouble(POSITION_PRICE_OPEN);
   const double curSL  = PositionGetDouble(POSITION_SL);
   const double market = isBuy ? g_symbol.Bid() : g_symbol.Ask();
   const double minDist = (double)MathMax(g_symbol.StopsLevel(), g_symbol.FreezeLevel()) * g_symbol.Point();
   double newSL = 0.0;
   string why = "";
   if(curSL == 0.0 || (isBuy ? curSL < open : curSL > open))
     {
      newSL = open; why = "BE";                                   // lot 1 is gone: break-even first
     }
   else
     {
      if(!newBar)
         return;
      const double swing = LastSwing(isBuy);
      if(swing <= 0.0)
         return;
      newSL = isBuy ? swing - InpSwingBufferPips * Pip() : swing + InpSwingBufferPips * Pip(); why = "TRAIL";
     }
   if(isBuy  && market - newSL < minDist) newSL = market - minDist;
   if(!isBuy && newSL - market < minDist) newSL = market + minDist;
   newSL = NormalizeDouble(newSL, g_symbol.Digits());
   if((isBuy ? newSL - curSL : curSL - newSL) <= g_symbol.Point())
      return;                                                    // only ever tighten
   if(g_trade.PositionModify(t2, newSL, 0.0))
      PrintFormat("TEB %s %s #%I64u sl=%s -> %s", why, isBuy ? "BUY" : "SELL", t2, DoubleToString(curSL, _Digits), DoubleToString(newSL, _Digits));
   else
      PrintFormat("Lot-2 %s #%I64u failed: %d %s", why, t2, g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
  }

void OnTick()
  {
   Core_OnTickStart();
   const datetime bar = Core_CurrentBar();
   Core_RetryPending(bar);
   const bool newBar = Core_IsNewBar(bar);
   if(InpSecondLot && CountOwnPositions() > 0)
      ManageLot2(newBar);
   if(!newBar)
      return;
   double f[3], s[3], r[2], fT[1], sT[1], rT[1];
   if(CopyBuffer(g_fast, 0, 1, 3, f) < 3 || CopyBuffer(g_slow, 0, 1, 3, s) < 3 || CopyBuffer(g_rsi, 0, 1, 2, r) < 2 ||
      CopyBuffer(g_fastT, 0, 1, 1, fT) < 1 || CopyBuffer(g_slowT, 0, 1, 1, sT) < 1 || CopyBuffer(g_rsiT, 0, 1, 1, rT) < 1)
      return;                                      // data not ready: bar stays unprocessed, retried next tick
   Core_MarkBar(bar);
   // oldest-first: f[2] = shift 1 (last closed bar), f[1] = shift 2, f[0] = shift 3; r[1] = shift 1
   const double f1 = f[2], f2 = f[1], s1 = s[2], s2 = s[1], r1 = r[1];
   const double c1 = iClose(_Symbol, InpTimeframe, 1), c2 = iClose(_Symbol, InpTimeframe, 2);
   const double lo2 = iLow(_Symbol, InpTimeframe, 2), hi2 = iHigh(_Symbol, InpTimeframe, 2);
   const int trend = (fT[0] > sT[0] && rT[0] > InpTrendRsiBuy) ? 1 : (fT[0] < sT[0] && rT[0] < InpTrendRsiSell) ? -1 : 0;
   const string ctx = StringFormat("ema %.5f/%.5f rsi %.1f | trend %s ema %.5f/%.5f rsi %.1f -> %d", f1, s1, r1,
                                   EnumToString(TrendTF()), fT[0], sT[0], rT[0], trend);
   if(CountOwnPositions() > 0)
     {
      Core_LogBar(bar, ctx + " | holding");
      return;
     }
   if(!InSession(bar))
     {
      Core_LogBar(bar, ctx + " | outside sessions");
      return;
     }
   int sig = 0;
   if(InpEntryMode == TEB_CROSS)
     {
      if(trend > 0 && f1 > s1 && f2 <= s2 && r1 > InpEntryRsiLevel) sig = 1;
      if(trend < 0 && f1 < s1 && f2 >= s2 && r1 < InpEntryRsiLevel) sig = -1;
     }
   else
     {
      if(trend > 0 && f1 > s1 && f2 > s2 && lo2 <= s2 && c2 <= f2 && c1 > f1 && r1 > InpEntryRsiLevel) sig = 1;
      if(trend < 0 && f1 < s1 && f2 < s2 && hi2 >= s2 && c2 >= f2 && c1 < f1 && r1 < InpEntryRsiLevel) sig = -1;
     }
   if(sig == 0)
     {
      Core_LogBar(bar, ctx + " | no signal");
      return;
     }
   if(!g_symbol.RefreshRates())
      return;
   const bool   buy    = (sig > 0);
   const double spread = g_symbol.Ask() - g_symbol.Bid();
   const double price  = buy ? g_symbol.Ask() : g_symbol.Bid();
   const double slDist = InpStopPips * Pip();
   const double tpDist = InpTargetPips * Pip() + spread;
   const double tp1    = NormalizeDouble(buy ? price + tpDist : price - tpDist, g_symbol.Digits());
   MqlDateTime d;
   TimeToStruct(bar, d);
   PrintFormat("TEB SIGNAL %s f1=%.8f f2=%.8f s1=%.8f s2=%.8f r1=%.4f fT=%.8f sT=%.8f rT=%.4f c1=%.5f c2=%.5f lo2=%.5f hi2=%.5f hour=%d sl_dist=%.5f tp_dist=%.5f spread=%.5f mode=%d trend=%d",
               buy ? "BUY" : "SELL", f1, f2, s1, s2, r1, fT[0], sT[0], rT[0], c1, c2, lo2, hi2, d.hour, slDist, tpDist, spread, (int)InpEntryMode, trend);
   Core_LogBar(bar, ctx + StringFormat(" | %s stop %.1f pips, lot-1 target %.5f", buy ? "BUY" : "SELL", InpStopPips, tp1));
   const ENUM_POSITION_TYPE type = buy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   if(Core_Open(type, slDist, tp1) && InpSecondLot)
      Core_Open(type, slDist, 0.0);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

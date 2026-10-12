//+------------------------------------------------------------------+
//|                                                  Camvcvoo_EA.mq5 |
//|  Port of camvcvooV5.mq4 ("H1 GBPUSD EA", O3 Power Ltd, 2010).    |
//|  Once a day, in one server hour: BUY when the H1 SMA(197) and    |
//|  SMA(10) both rose on the last closed bar, an M5 lower fractal   |
//|  sits N M5 bars back and the latest M15 fractal is an upper one; |
//|  SELL is the mirror. Three positions open at once, stop S pips   |
//|  on all, targets T1 < T2 < T3 pips. Position 2 trails its stop   |
//|  once in profit by the trail distance; position 3 moves its stop |
//|  once to lock a few pips at the same trigger. One set at a time, |
//|  no hedging, at most one set per H1 bar. Lots per position from  |
//|  EACore's risk %, so a full stop-out of a set is 3R (MACD        |
//|  stacking convention). Daily level lines and the panel dropped.  |
//|  Deviations: server-side SL/TP (same levels as the original's    |
//|  tick checks); the trade hour is a plain server hour (the        |
//|  original adds a fixed broker offset to 23:00 GMT, no DST).      |
//|                                                                  |
//|  v1.00                                                           |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.00"
#property strict
#property description "camvcvooV5 port: daily-hour SMA slope + fractal entry, 3 positions 22/50/80 pips, 140 pip stop; MACD_Cross_EA v1.42 safety core"

#define EA_NAME      "Camvcvoo_EA"
#define EA_VERSION   "1.00"
#define EA_MAGIC     261014
#define EA_COMMENT   "CAMV"
#define EA_TIMEFRAME PERIOD_H1
#define EA_MAX_SPREAD_POINTS 20   // 2 pips on a 5-digit GBPUSD quote
#define EA_SPREAD_WAIT_MIN 0      // a set of three cannot share EACore's single pending retry; the next M5 bar re-evaluates anyway
#include "EACore.mqh"

input group "=== Strategy (pips = 10 points on 5-digit quotes) ==="
input int                 InpTradeHour       = 1;      // Server hour of the daily entry window (original: 23:00 GMT + 2)
input int                 InpFastSMA         = 10;     // Fast SMA period (H1 close)
input int                 InpSlowSMA         = 197;    // Slow SMA period (H1 close)
input int                 InpFractalShift    = 3;      // M5 fractal must sit this many M5 bars back
input int                 InpStopPips        = 140;    // Stop loss, pips (all three positions)
input int                 InpTP1Pips         = 22;     // Take profit, position 1
input int                 InpTP2Pips         = 50;     // Take profit, position 2 (trailed)
input int                 InpTP3Pips         = 80;     // Take profit, position 3 (one-shot lock)
input int                 InpTrailPips       = 22;     // Position 2 trails this far behind price once this far in profit
input int                 InpLockPips        = 12;     // Position 3: at the same trigger, stop moved once to lock this much (original: trail - 10)

int      g_fast = INVALID_HANDLE, g_slow = INVALID_HANDLE, g_fr5 = INVALID_HANDLE, g_fr15 = INVALID_HANDLE;
double   g_pip = 0.0;
datetime g_lastM5 = 0, g_lastEntryBar = 0;

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpTradeHour < 0 || InpTradeHour > 23 || InpFastSMA <= 1 || InpSlowSMA <= 1 || InpFractalShift < 3 ||
      InpStopPips <= 0 || InpTP1Pips <= 0 || InpTP2Pips <= InpTP1Pips + 1 || InpTP3Pips <= InpTP2Pips + 1 ||
      InpTrailPips <= 0 || InpLockPips < 0 || InpLockPips >= InpTrailPips)
     {
      Print("Invalid inputs: hour 0-23, periods > 1, fractal shift >= 3, stop > 0, TP1 < TP2 < TP3 (2+ pips apart), 0 <= lock < trail");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   g_pip  = (g_symbol.Digits() == 3 || g_symbol.Digits() == 5) ? 10.0 * g_symbol.Point() : g_symbol.Point();
   g_fast = iMA(_Symbol, InpTimeframe, InpFastSMA, 0, MODE_SMA, PRICE_CLOSE);
   g_slow = iMA(_Symbol, InpTimeframe, InpSlowSMA, 0, MODE_SMA, PRICE_CLOSE);
   g_fr5  = iFractals(_Symbol, PERIOD_M5);
   g_fr15 = iFractals(_Symbol, PERIOD_M15);
   if(g_fast == INVALID_HANDLE || g_slow == INVALID_HANDLE || g_fr5 == INVALID_HANDLE || g_fr15 == INVALID_HANDLE)
     {
      Print("Failed to create indicators, error ", GetLastError());
      return(INIT_FAILED);
     }
   PrintFormat("%s v%s started on %s %s, magic %I64u, own positions: %d",
               EA_NAME, EA_VERSION, _Symbol, EnumToString(InpTimeframe), InpMagic, CountOwnPositions());
   PrintFormat("Inputs: hour %02d server | SMA %d/%d rising/falling | M5 fractal at shift %d, M15 last-fractal trend | stop %d pips, TP %d/%d/%d | trail %d, lock %d | pip %s | risk %s %.2f per position",
               InpTradeHour, InpFastSMA, InpSlowSMA, InpFractalShift, InpStopPips, InpTP1Pips, InpTP2Pips, InpTP3Pips,
               InpTrailPips, InpLockPips, DoubleToString(g_pip, g_symbol.Digits()),
               InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(g_fast != INVALID_HANDLE) IndicatorRelease(g_fast);
   if(g_slow != INVALID_HANDLE) IndicatorRelease(g_slow);
   if(g_fr5  != INVALID_HANDLE) IndicatorRelease(g_fr5);
   if(g_fr15 != INVALID_HANDLE) IndicatorRelease(g_fr15);
   Core_Deinit(reason);
  }

bool HasFractal(const double v) { return(v != EMPTY_VALUE && v > 0.0); }

//--- 1 = latest M15 fractal is an upper one, 2 = a lower one (the original's "trend"), 0 = data not ready
int M15Trend()
  {
   double up[], dn[];
   ArraySetAsSeries(up, true);
   ArraySetAsSeries(dn, true);
   const int n = 500;                           // ponytail: a fractal older than 500 M15 bars (5 days) is treated as absent, as the original effectively did on a short chart
   if(CopyBuffer(g_fr15, 0, 0, n, up) < n || CopyBuffer(g_fr15, 1, 0, n, dn) < n)
      return(0);
   int iu = n, id = n;
   for(int i = 1; i < n; i++) { if(HasFractal(up[i])) { iu = i; break; } }
   for(int i = 1; i < n; i++) { if(HasFractal(dn[i])) { id = i; break; } }
   return(iu < id ? 1 : 2);                     // more recent = smaller shift; original: TimeOfLastUp > TimeOfLastDown -> 1 else 2
  }

//--- +1 buy, -1 sell, 0 none; only called inside the trade hour on a new M5 bar
int Signal(string &ctx)
  {
   double f[2], s[2], fr5[1];
   if(CopyBuffer(g_fast, 0, 1, 2, f) < 2 || CopyBuffer(g_slow, 0, 1, 2, s) < 2 ||
      f[0] == EMPTY_VALUE || f[1] == EMPTY_VALUE || s[0] == EMPTY_VALUE || s[1] == EMPTY_VALUE)
      return(0);                                // CopyBuffer static arrays oldest-first: [1] = shift 1, [0] = shift 2
   const int trend = M15Trend();
   const bool slowUp = s[1] > s[0], fastUp = f[1] > f[0];
   const bool slowDn = s[1] < s[0], fastDn = f[1] < f[0];
   ctx = StringFormat("slow %s fast %s m15trend %d", slowUp ? "up" : slowDn ? "down" : "flat", fastUp ? "up" : fastDn ? "down" : "flat", trend);
   if(slowUp && fastUp && trend == 1)
     {
      if(CopyBuffer(g_fr5, 1, InpFractalShift, 1, fr5) == 1 && HasFractal(fr5[0]))
         return(1);
      ctx += " | no M5 lower fractal";
     }
   else if(slowDn && fastDn && trend == 2)
     {
      if(CopyBuffer(g_fr5, 0, InpFractalShift, 1, fr5) == 1 && HasFractal(fr5[0]))
         return(-1);
      ctx += " | no M5 upper fractal";
     }
   return(0);
  }

//--- role of an own position by its target distance: 1, 2 (trailed) or 3 (one-shot lock)
int Role(const double open, const double tp)
  {
   const int tpPips = (int)MathRound(MathAbs(tp - open) / g_pip);
   if(MathAbs(tpPips - InpTP2Pips) <= 1) return(2);
   if(MathAbs(tpPips - InpTP3Pips) <= 1) return(3);
   return(1);
  }

void ManagePositions()
  {
   if(!g_symbol.RefreshRates())
      return;
   const int    digits  = g_symbol.Digits();
   const double point   = g_symbol.Point();
   const double minDist = (double)MathMax(g_symbol.StopsLevel(), g_symbol.FreezeLevel()) * point;
   const double trail   = InpTrailPips * g_pip, lock = InpLockPips * g_pip;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !IsOwnPosition())
         continue;
      const bool   isBuy  = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      const double open   = PositionGetDouble(POSITION_PRICE_OPEN);
      const double curSL  = PositionGetDouble(POSITION_SL);
      const double curTP  = PositionGetDouble(POSITION_TP);
      const double market = isBuy ? g_symbol.Bid() : g_symbol.Ask();
      const double profit = isBuy ? market - open : open - market;
      if(profit <= trail)
         continue;                              // both rules trigger only beyond the trail distance
      const int role = Role(open, curTP);
      double newSL = 0.0;
      if(role == 2)
         newSL = isBuy ? market - trail : market + trail;                 // classic trailing stop
      else if(role == 3 && (curSL == 0.0 || (isBuy ? curSL < open : curSL > open)))
         newSL = isBuy ? market - lock : market + lock;                   // one shot: only while the stop is still the initial one
      else
         continue;
      if(isBuy  && market - newSL < minDist) newSL = market - minDist;
      if(!isBuy && newSL - market < minDist) newSL = market + minDist;
      newSL = NormalizeDouble(newSL, digits);
      const bool better = (curSL == 0.0) || (isBuy ? newSL > curSL + point : newSL < curSL - point);
      if(!better)
         continue;
      if(!g_trade.PositionModify(ticket, newSL, curTP))
         PrintFormat("Modify #%I64u (role %d) failed: %d %s", ticket, role, g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
     }
  }

void OnTick()
  {
   Core_OnTickStart();
   const datetime bar = Core_CurrentBar();      // H1
   Core_RetryPending(bar);
   if(CountOwnPositions() > 0)
      ManagePositions();                        // the original trails on every tick
   const datetime m5 = iTime(_Symbol, PERIOD_M5, 0);
   if(m5 == g_lastM5)
      return;
   g_lastM5 = m5;                               // the M5 fractal condition changes once per M5 bar
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   const bool inWindow = (dt.hour == InpTradeHour);
   if(Core_IsNewBar(bar))
     {
      Core_MarkBar(bar);
      Core_LogBar(bar, inWindow ? "trade hour" : "outside the trade hour");
     }
   if(!inWindow || bar == g_lastEntryBar || CountOwnPositions() > 0)
      return;                                   // one set per H1 bar, one set at a time, no hedging
   string ctx;
   const int sig = Signal(ctx);
   if(sig == 0)
      return;
   if(!g_symbol.RefreshRates())
      return;
   const bool   buy   = (sig > 0);
   const double price = buy ? g_symbol.Ask() : g_symbol.Bid();
   const double slDist = InpStopPips * g_pip;
   const int    tps[3] = {InpTP1Pips, InpTP2Pips, InpTP3Pips};
   int opened = 0;
   for(int k = 0; k < 3; k++)
     {
      const double tp = buy ? price + tps[k] * g_pip : price - tps[k] * g_pip;
      if(Core_Open(buy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL, slDist, tp))
         opened++;
     }
   PrintFormat("%s %s set: %d of 3 positions opened (%s)", TimeToString(TimeCurrent()), buy ? "BUY" : "SELL", opened, ctx);
   if(opened > 0)
      g_lastEntryBar = bar;
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

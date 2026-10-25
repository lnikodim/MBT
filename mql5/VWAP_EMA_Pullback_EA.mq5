//+------------------------------------------------------------------+
//|                                          VWAP_EMA_Pullback_EA.mq5 |
//|  VWAP + EMA 9/21 pullback system (user rule, 2026-10-26).        |
//|  Long: close above the daily VWAP, EMA 9 above EMA 21, a pullback |
//|  (the bars before the signal closed at or below EMA 9, none below |
//|  EMA 21), then a bullish bar closing back above EMA 9. Short is   |
//|  the mirror image. The stop sits beyond the pullback extreme plus |
//|  a buffer of ATR; the target is a multiple of the stop distance.  |
//|  One position at a time. Execution, guards and trade log from     |
//|  EACore.mqh (MACD_Cross_EA v1.42 core).                           |
//|                                                                  |
//|  v1.00                                                           |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.00"
#property strict
#property description "VWAP + EMA 9/21 pullback: trend above/below VWAP and the EMAs, pullback, bullish/bearish confirmation; ATR stop, RR target; MACD_Cross_EA v1.42 safety core"

#define EA_NAME      "VWAP_EMA_Pullback_EA"
#define EA_VERSION   "1.00"
#define EA_MAGIC     261026
#define EA_COMMENT   "VWAP_PB"
#define EA_TIMEFRAME PERIOD_M5
#include "EACore.mqh"

enum ENUM_ANCHOR
  {
   ANCHOR_DAY   = 0,  // Day (server midnight)
   ANCHOR_WEEK  = 1,  // Week (Monday 00:00 server)
   ANCHOR_MONTH = 2   // Month
  };

//--- 5. Strategy continues here (EACore opened the group with the signal timeframe)
input ENUM_ANCHOR         InpAnchor          = ANCHOR_DAY;   // VWAP anchor
input int                 InpEMAFast         = 9;            // Fast EMA period (close)
input int                 InpEMASlow         = 21;           // Slow EMA period (close)
input int                 InpMaxPullbackBars = 8;            // Pullback: max bars below the fast EMA
input bool                InpAllowBuys       = true;         // Allow buys
input bool                InpAllowSells      = true;         // Allow sells

input group "6. Filters"
input int                 InpVwapWarmupBars  = 12;           // VWAP warm-up after the anchor, bars (0 = off)
input double              InpMaxStopATR      = 3.0;          // Skip if the stop is wider than, x ATR (0 = off)

input group "7. Exits"
input int                 InpATRPeriod       = 14;           // Stop: ATR period
input double              InpSLBufferATR     = 0.2;          // Stop: buffer beyond the pullback, x ATR
input double              InpMinStopATR      = 1.0;          // Stop: minimum distance, x ATR (0 = off)
input double              InpRR              = 1.5;          // Take profit, x stop distance (0 = off)

int  g_fast = INVALID_HANDLE;
int  g_slow = INVALID_HANDLE;
int  g_atr  = INVALID_HANDLE;
bool g_warnedShortHistory = false;

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpEMAFast <= 1 || InpEMASlow <= InpEMAFast || InpMaxPullbackBars < 1 || InpATRPeriod < 1 ||
      InpSLBufferATR < 0.0 || InpMinStopATR < 0.0 || InpMaxStopATR < 0.0 || InpRR < 0.0 || InpVwapWarmupBars < 0)
     {
      Print("Invalid inputs: need 1 < fast EMA < slow EMA, pullback bars >= 1, ATR period >= 1, no negative ATR / RR values");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   g_fast = iMA(_Symbol, InpTimeframe, InpEMAFast, 0, MODE_EMA, PRICE_CLOSE);
   g_slow = iMA(_Symbol, InpTimeframe, InpEMASlow, 0, MODE_EMA, PRICE_CLOSE);
   g_atr  = iATR(_Symbol, InpTimeframe, InpATRPeriod);
   if(g_fast == INVALID_HANDLE || g_slow == INVALID_HANDLE || g_atr == INVALID_HANDLE)
     {
      Print("Failed to create an indicator, error ", GetLastError());
      return(INIT_FAILED);
     }
   PrintFormat("%s v%s started on %s %s, magic %I64u, own positions: %d",
               EA_NAME, EA_VERSION, _Symbol, EnumToString(InpTimeframe), InpMagic, CountOwnPositions());
   PrintFormat("Inputs: anchor %s | EMA %d/%d | pullback <= %d bars | warm-up %d bars | stop buffer %.2f ATR(%d), min %.2f, max %.2f | RR %.2f | buys %s sells %s | risk %s %.2f",
               EnumToString(InpAnchor), InpEMAFast, InpEMASlow, InpMaxPullbackBars, InpVwapWarmupBars,
               InpSLBufferATR, InpATRPeriod, InpMinStopATR, InpMaxStopATR, InpRR,
               InpAllowBuys ? "on" : "off", InpAllowSells ? "on" : "off",
               InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(g_fast != INVALID_HANDLE) IndicatorRelease(g_fast);
   if(g_slow != INVALID_HANDLE) IndicatorRelease(g_slow);
   if(g_atr  != INVALID_HANDLE) IndicatorRelease(g_atr);
   Core_Deinit(reason);
  }

//--- start of the VWAP period containing t, in server time (the day boundary EACore's daily stop uses)
datetime PeriodStart(const datetime t)
  {
   const datetime day = t - t % 86400;
   if(InpAnchor == ANCHOR_DAY)
      return(day);
   MqlDateTime dt;
   TimeToStruct(t, dt);
   if(InpAnchor == ANCHOR_WEEK)
      return(day - ((dt.day_of_week + 6) % 7) * 86400);   // Monday 00:00
   dt.day = 1; dt.hour = 0; dt.min = 0; dt.sec = 0;
   return(StructToTime(dt));
  }

//--- VWAP of bar i (series index, 0 = last closed bar), anchored at that bar's own period, tick-volume weighted
//--- over (high + low + close) / 3. 0.0 = not computable.
//--- ponytail: recomputed from scratch on every new bar (<= 300 bars for Day on M5); running sums if Month on M1/M5 matters.
double VwapAt(const MqlRates &r[], const int i)
  {
   const datetime start = PeriodStart(r[i].time);
   const int n = ArraySize(r);
   double pv = 0.0, v = 0.0;
   int k = i;
   for(; k < n && r[k].time >= start; k++)
     {
      const double tv = (double)r[k].tick_volume;
      pv += (r[k].high + r[k].low + r[k].close) / 3.0 * tv;
      v  += tv;
     }
   if(k == n || v <= 0.0)
      return(0.0);                              // copied window ended before the anchor, or no volume
   return(pv / v);
  }

//--- Pullback test for a long (dir = +1) or a short (dir = -1) on the last closed bar r[0].
//--- The bars r[1..streak] closed on the wrong side of the fast EMA (below it for a long) and never beyond the slow EMA;
//--- the streak is 1..InpMaxPullbackBars bars long and ended exactly before r[0]. Returns the streak (0 = no pullback).
int PullbackStreak(const MqlRates &r[], const double &fast[], const double &slow[], const int dir, const int cnt)
  {
   int streak = 0;
   for(int j = 1; j <= InpMaxPullbackBars && j < cnt; j++)
     {
      const bool beyondFast = (dir > 0) ? (r[j].close <= fast[j]) : (r[j].close >= fast[j]);
      if(!beyondFast)
         break;
      const bool beyondSlow = (dir > 0) ? (r[j].close <= slow[j]) : (r[j].close >= slow[j]);
      if(beyondSlow)
         return(0);                              // the pullback broke the slow EMA: trend not intact
      streak++;
     }
   if(streak == InpMaxPullbackBars && streak + 1 < cnt)
     {
      const int j = streak + 1;                  // still on the wrong side one bar earlier: a longer pullback than allowed
      if((dir > 0) ? (r[j].close <= fast[j]) : (r[j].close >= fast[j]))
         return(0);
     }
   return(streak);
  }

void OnTick()
  {
   Core_OnTickStart();
   const datetime bar = Core_CurrentBar();
   Core_RetryPending(bar);
   if(!Core_IsNewBar(bar))
      return;
   const int anchorSec = (InpAnchor == ANCHOR_DAY) ? 86400 : (InpAnchor == ANCHOR_WEEK) ? 7 * 86400 : 31 * 86400;
   const int need = anchorSec / PeriodSeconds(InpTimeframe) + 2;   // time-based upper bound on bars per period
   const int cnt  = InpMaxPullbackBars + 2;                        // EMA values needed: the signal bar, the streak, one earlier bar
   MqlRates r[];
   double fast[], slow[], atr[1];
   ArraySetAsSeries(r, true);
   ArraySetAsSeries(fast, true);                                   // index 0 = shift 1 (last closed bar), like r[]
   ArraySetAsSeries(slow, true);
   const int copied = CopyRates(_Symbol, InpTimeframe, 1, need, r);
   if(copied < cnt || CopyBuffer(g_fast, 0, 1, cnt, fast) < cnt || CopyBuffer(g_slow, 0, 1, cnt, slow) < cnt ||
      CopyBuffer(g_atr, 0, 1, 1, atr) < 1 || atr[0] <= 0.0 || atr[0] == EMPTY_VALUE)
      return;                                   // data not ready: bar stays unprocessed, retried next tick
   const double vwap = VwapAt(r, 0);
   if(vwap <= 0.0)
     {
      if(copied < need && !g_warnedShortHistory)
        {
         g_warnedShortHistory = true;
         PrintFormat("VWAP not computable: only %d of %d bars available (history still loading, or Max bars in chart too low)", copied, need);
        }
      return;                                   // unknown VWAP: no signal, retried next tick
     }
   Core_MarkBar(bar);

   ulong ticket;
   if(Core_SelectOwnPosition(ticket))
     {
      Core_LogBar(bar, StringFormat("vwap %.5f | holding", vwap));
      return;                                   // one position at a time: the stop or the target ends the trade
     }

   const datetime start = PeriodStart(r[0].time);
   int sinceAnchor = 0;
   while(sinceAnchor < copied && r[sinceAnchor].time >= start)
      sinceAnchor++;
   if(InpVwapWarmupBars > 0 && sinceAnchor < InpVwapWarmupBars)
     {
      Core_LogBar(bar, StringFormat("vwap %.5f | warm-up (%d of %d bars)", vwap, sinceAnchor, InpVwapWarmupBars));
      return;
     }

   const bool bullTrend = r[0].close > vwap && fast[0] > slow[0];
   const bool bearTrend = r[0].close < vwap && fast[0] < slow[0];
   const bool bullConf  = r[0].close > r[0].open && r[0].close > fast[0];
   const bool bearConf  = r[0].close < r[0].open && r[0].close < fast[0];
   const string ctx = StringFormat("vwap %.5f ema %.5f/%.5f close %.5f", vwap, fast[0], slow[0], r[0].close);

   int dir = 0, streak = 0;
   if(InpAllowBuys && bullTrend && bullConf)
     {
      streak = PullbackStreak(r, fast, slow, +1, cnt);
      if(streak > 0) dir = +1;
     }
   else if(InpAllowSells && bearTrend && bearConf)
     {
      streak = PullbackStreak(r, fast, slow, -1, cnt);
      if(streak > 0) dir = -1;
     }
   if(dir == 0)
     {
      Core_LogBar(bar, ctx + " | no setup");
      return;
     }

   double extreme = r[0].low;                   // pullback extreme over the signal bar and the streak
   if(dir < 0) extreme = r[0].high;
   for(int j = 1; j <= streak; j++)
      extreme = (dir > 0) ? MathMin(extreme, r[j].low) : MathMax(extreme, r[j].high);

   if(!g_symbol.RefreshRates())
      return;
   const bool   buy  = (dir > 0);
   const double px   = buy ? g_symbol.Ask() : g_symbol.Bid();
   const double stopPrice = buy ? extreme - InpSLBufferATR * atr[0] : extreme + InpSLBufferATR * atr[0];
   double dist = buy ? px - stopPrice : stopPrice - px;
   dist = MathMax(dist, InpMinStopATR * atr[0]);
   if(InpMaxStopATR > 0.0 && dist > InpMaxStopATR * atr[0])
     {
      Core_LogBar(bar, ctx + StringFormat(" | %s setup skipped: stop %.2f ATR > max", buy ? "BUY" : "SELL", dist / atr[0]));
      return;
     }
   const double tp = (InpRR > 0.0) ? (buy ? px + dist * InpRR : px - dist * InpRR) : 0.0;
   Core_LogBar(bar, ctx + StringFormat(" | %s pullback %d bars, stop dist %.5f (%.2f ATR)", buy ? "BUY" : "SELL", streak, dist, dist / atr[0]));
   Core_Open(buy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL, dist, tp);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

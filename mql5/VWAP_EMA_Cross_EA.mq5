//+------------------------------------------------------------------+
//|                                            VWAP_EMA_Cross_EA.mq5 |
//|  VWAP / EMA cross reversal system (user rule, 2026-10-12): on    |
//|  every cross of the anchored VWAP and the EMA the open position  |
//|  is closed and the new side opened. VWAP above EMA -> BUY, VWAP  |
//|  below EMA -> SELL (InpInvert flips both). Always in the market  |
//|  after the first cross, one position at a time. The protective  |
//|  stop (% of price) only sizes the lots and defines R; the next   |
//|  cross is the exit. Execution, guards and trade log from         |
//|  EACore.mqh (MACD_Cross_EA v1.42 core).                          |
//|                                                                  |
//|  v1.00                                                           |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.00"
#property strict
#property description "VWAP / EMA cross reversal: close and flip on every cross, protective % stop; MACD_Cross_EA v1.42 safety core"

#define EA_NAME      "VWAP_EMA_Cross_EA"
#define EA_VERSION   "1.00"
#define EA_MAGIC     261012
#define EA_COMMENT   "VWAP_EMA"
#define EA_TIMEFRAME PERIOD_M5
#include "EACore.mqh"

enum ENUM_ANCHOR
  {
   ANCHOR_DAY   = 0,  // Day (server midnight)
   ANCHOR_WEEK  = 1,  // Week (Monday 00:00 server)
   ANCHOR_MONTH = 2   // Month
  };

input group "=== Strategy ==="
input ENUM_ANCHOR         InpAnchor          = ANCHOR_DAY;   // VWAP anchor
input int                 InpEMAPeriod       = 9;            // EMA period (close)
input double              InpSLPercent       = 0.5;          // Protective stop, % of price (sizes the lots)
input bool                InpInvert          = false;        // false: VWAP above EMA = BUY (as specified); true: the opposite

int  g_ema = INVALID_HANDLE;
bool g_warnedShortHistory = false;

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpEMAPeriod <= 1 || InpSLPercent <= 0.0)
     {
      Print("Invalid EMA period / stop percent");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   g_ema = iMA(_Symbol, InpTimeframe, InpEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(g_ema == INVALID_HANDLE)
     {
      Print("Failed to create the EMA, error ", GetLastError());
      return(INIT_FAILED);
     }
   PrintFormat("%s v%s started on %s %s, magic %I64u, own positions: %d",
               EA_NAME, EA_VERSION, _Symbol, EnumToString(InpTimeframe), InpMagic, CountOwnPositions());
   PrintFormat("Inputs: anchor %s | EMA %d | stop %.2f%% of price | direction %s | risk %s %.2f",
               EnumToString(InpAnchor), InpEMAPeriod, InpSLPercent,
               InpInvert ? "inverted (VWAP above EMA = SELL)" : "as specified (VWAP above EMA = BUY)",
               InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(g_ema != INVALID_HANDLE)
      IndicatorRelease(g_ema);
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

//--- VWAP of bar i (series index, 0 = last closed bar), anchored at that bar's own period. 0.0 = not computable.
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

//--- +1 when VWAP is above the EMA, -1 below, 0 equal
int Sign(const double d) { return(d > 0.0 ? 1 : (d < 0.0 ? -1 : 0)); }

void OnTick()
  {
   Core_OnTickStart();
   const datetime bar = Core_CurrentBar();
   Core_RetryPending(bar);
   if(!Core_IsNewBar(bar))
      return;
   const int anchorSec = (InpAnchor == ANCHOR_DAY) ? 86400 : (InpAnchor == ANCHOR_WEEK) ? 7 * 86400 : 31 * 86400;
   const int need = anchorSec / PeriodSeconds(InpTimeframe) + 2;   // time-based upper bound on bars per period
   MqlRates r[];
   ArraySetAsSeries(r, true);
   double ema[2];                                // CopyBuffer fills static arrays oldest-first: ema[1] = shift 1, ema[0] = shift 2
   const int copied = CopyRates(_Symbol, InpTimeframe, 1, need, r);
   if(copied < 2 || CopyBuffer(g_ema, 0, 1, 2, ema) < 2 || ema[0] == EMPTY_VALUE || ema[1] == EMPTY_VALUE)
      return;                                   // data not ready: bar stays unprocessed, retried next tick
   const double vwap1 = VwapAt(r, 0), vwap2 = VwapAt(r, 1);
   if(vwap1 <= 0.0 || vwap2 <= 0.0)
     {
      if(copied < need && !g_warnedShortHistory)
        {
         g_warnedShortHistory = true;
         PrintFormat("VWAP not computable: only %d of %d bars available (history still loading, or Max bars in chart too low)", copied, need);
        }
      return;                                   // unknown VWAP: no side, no signal, retried next tick
     }
   Core_MarkBar(bar);
   const int s1 = Sign(vwap1 - ema[1]);         // last closed bar
   const int s2 = Sign(vwap2 - ema[0]);         // the bar before it
   const int wanted = InpInvert ? -s1 : s1;     // +1 = long, -1 = short, 0 = lines equal
   const string ctx = StringFormat("vwap %.2f ema %.2f side %d prev %d", vwap1, ema[1], s1, s2);

   ulong ticket;
   if(Core_SelectOwnPosition(ticket))
     {
      const int held = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      if(wanted == 0 || held == wanted)
        {
         Core_LogBar(bar, ctx + " | holding");
         return;
        }
      if(!Core_ClosePosition(ticket, "cross"))  // lines crossed against the position: close, then flip below
        {
         Core_LogBar(bar, ctx + " | close failed, retry next bar");
         return;
        }
     }
   if(s1 == 0 || s2 == 0 || s1 == s2)
     {
      Core_LogBar(bar, ctx + " | no cross");
      return;                                   // entries only on a cross: after a stop-out wait for the next one
     }
   if(!g_symbol.RefreshRates())
      return;
   const bool   buy  = (wanted > 0);
   const double px   = buy ? g_symbol.Ask() : g_symbol.Bid();
   const double dist = px * InpSLPercent / 100.0;
   Core_LogBar(bar, ctx + StringFormat(" | %s stop dist %.2f", buy ? "BUY" : "SELL", dist));
   Core_Open(buy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL, dist, 0.0);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                            EMA_VWAP_Trail_EA.mq5 |
//|  Port of the Pine strategy "EMA 9 + VWAP Strategy with ATR       |
//|  Trailing Stop": long when EMA(9) crosses above the session      |
//|  VWAP, short when it crosses below, each entry reversing the     |
//|  open position; exit by an ATR trailing stop (k x ATR) or the    |
//|  opposite cross. The initial stop is k x ATR from the entry and  |
//|  sizes the lots (R = k x ATR). Pine's trail_points/trail_offset  |
//|  are tick units (a few cents on gold as written); this port      |
//|  follows the plotted stop lines: close -/+ k x ATR, ratcheted.   |
//|  InpTrailAfterProfit reproduces the strategy.exit activation     |
//|  (trailing only after +k x ATR). Execution, guards and trade log |
//|  from EACore.mqh (MACD_Cross_EA v1.42 core).                      |
//|                                                                  |
//|  v1.01 optional entry filters: EMA trend on the signal TF, H1/H4 |
//|        EMA bias, server-hour session. Exits unchanged: a cross    |
//|        still closes the opposite position, filters gate entries. |
//|  v1.00                                                           |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.01"
#property strict
#property description "EMA(9)/VWAP cross reversal with k x ATR trailing stop (Pine port); MACD_Cross_EA v1.42 safety core"

#define EA_NAME      "EMA_VWAP_Trail_EA"
#define EA_VERSION   "1.01"
#define EA_MAGIC     261013
#define EA_COMMENT   "EMA_VWAP"
#define EA_TIMEFRAME PERIOD_M15
#include "EACore.mqh"

enum ENUM_ANCHOR
  {
   ANCHOR_DAY   = 0,  // Day (server midnight)
   ANCHOR_WEEK  = 1,  // Week (Monday 00:00 server)
   ANCHOR_MONTH = 2   // Month
  };

input group "=== Strategy ==="
input ENUM_ANCHOR         InpAnchor           = ANCHOR_DAY;   // VWAP anchor
input int                 InpEMAPeriod        = 9;            // EMA period (close)
input int                 InpATRPeriod        = 14;           // ATR period
input double              InpATRMult          = 2.0;          // Initial stop and trailing distance, x ATR
input bool                InpTrailAfterProfit = false;        // false: trail from entry (plotted lines); true: only after +k x ATR (Pine trail_points)

enum ENUM_HTF_BIAS
  {
   HTF_NONE = 0,  // Off
   HTF_H1   = 1,  // H1 close vs its EMA
   HTF_H4   = 2   // H4 close vs its EMA
  };

input group "=== Optional entry filters (0 / Off / 0-24 = off) ==="
input int                 InpTrendEMA         = 0;            // EMA period on the signal timeframe: longs above, shorts below (0 = off)
input ENUM_HTF_BIAS       InpHTFBias          = HTF_NONE;     // Higher-timeframe bias: last closed H1/H4 bar vs its EMA
input int                 InpHTFEMA           = 200;          // EMA period for the higher-timeframe bias
input int                 InpSessionStart     = 0;            // Entries from this server hour (inclusive)
input int                 InpSessionEnd       = 24;           // ... until this server hour (exclusive); 0-24 = off

int  g_ema = INVALID_HANDLE;
int  g_atr = INVALID_HANDLE;
int  g_trend = INVALID_HANDLE;
int  g_htf = INVALID_HANDLE;
bool g_warnedShortHistory = false;

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpEMAPeriod <= 1 || InpATRPeriod <= 1 || InpATRMult <= 0.0)
     {
      Print("Invalid EMA period / ATR period / ATR multiplier");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpTrendEMA < 0 || InpHTFEMA <= 1 || InpSessionStart < 0 || InpSessionEnd > 24 || InpSessionStart >= InpSessionEnd)
     {
      Print("Invalid filter inputs: trend EMA >= 0, HTF EMA > 1, 0 <= session start < end <= 24");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   g_ema = iMA(_Symbol, InpTimeframe, InpEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_atr = iATR(_Symbol, InpTimeframe, InpATRPeriod);
   if(InpTrendEMA > 0)
      g_trend = iMA(_Symbol, InpTimeframe, InpTrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(InpHTFBias != HTF_NONE)
      g_htf = iMA(_Symbol, HTFPeriod(), InpHTFEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(g_ema == INVALID_HANDLE || g_atr == INVALID_HANDLE ||
      (InpTrendEMA > 0 && g_trend == INVALID_HANDLE) || (InpHTFBias != HTF_NONE && g_htf == INVALID_HANDLE))
     {
      Print("Failed to create indicators, error ", GetLastError());
      return(INIT_FAILED);
     }
   PrintFormat("%s v%s started on %s %s, magic %I64u, own positions: %d",
               EA_NAME, EA_VERSION, _Symbol, EnumToString(InpTimeframe), InpMagic, CountOwnPositions());
   PrintFormat("Inputs: anchor %s | EMA %d | stop and trail %.2f x ATR(%d) | trail %s | risk %s %.2f",
               EnumToString(InpAnchor), InpEMAPeriod, InpATRMult, InpATRPeriod,
               InpTrailAfterProfit ? "after +k x ATR profit" : "from entry",
               InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   PrintFormat("Filters: trend EMA %s | HTF bias %s | session %s",
               InpTrendEMA > 0 ? IntegerToString(InpTrendEMA) : "off",
               InpHTFBias == HTF_NONE ? "off" : StringFormat("%s EMA%d", EnumToString(HTFPeriod()), InpHTFEMA),
               (InpSessionStart > 0 || InpSessionEnd < 24) ? StringFormat("%02d-%02d server", InpSessionStart, InpSessionEnd) : "off");
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(g_ema != INVALID_HANDLE)
      IndicatorRelease(g_ema);
   if(g_atr != INVALID_HANDLE)
      IndicatorRelease(g_atr);
   if(g_trend != INVALID_HANDLE)
      IndicatorRelease(g_trend);
   if(g_htf != INVALID_HANDLE)
      IndicatorRelease(g_htf);
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
//--- ponytail: recomputed from scratch on every new bar (<= 100 bars for Day on M15); running sums if Month on M1/M5 matters.
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

ENUM_TIMEFRAMES HTFPeriod() { return(InpHTFBias == HTF_H1 ? PERIOD_H1 : PERIOD_H4); }

//--- optional entry filters; exits are never filtered
bool EntryAllowed(const bool buy, const double close, const datetime barTime, string &why)
  {
   double e[1];
   if(InpTrendEMA > 0)
     {
      if(CopyBuffer(g_trend, 0, 1, 1, e) < 1 || e[0] == EMPTY_VALUE)
        {
         why = "trend EMA not ready";
         return(false);
        }
      if(buy ? close <= e[0] : close >= e[0])
        {
         why = StringFormat("close %.2f %s EMA%d %.2f", close, buy ? "below" : "above", InpTrendEMA, e[0]);
         return(false);
        }
     }
   if(InpHTFBias != HTF_NONE)
     {
      const double c = iClose(_Symbol, HTFPeriod(), 1);          // last closed higher-timeframe bar
      if(CopyBuffer(g_htf, 0, 1, 1, e) < 1 || e[0] == EMPTY_VALUE || c <= 0.0)
        {
         why = "HTF EMA not ready";
         return(false);
        }
      if(buy ? c <= e[0] : c >= e[0])
        {
         why = StringFormat("%s close %.2f %s EMA%d %.2f", EnumToString(HTFPeriod()), c, buy ? "below" : "above", InpHTFEMA, e[0]);
         return(false);
        }
     }
   if(InpSessionStart > 0 || InpSessionEnd < 24)
     {
      MqlDateTime dt;
      TimeToStruct(barTime, dt);
      if(dt.hour < InpSessionStart || dt.hour >= InpSessionEnd)
        {
         why = StringFormat("hour %02d outside %02d-%02d", dt.hour, InpSessionStart, InpSessionEnd);
         return(false);
        }
     }
   return(true);
  }

//--- +1 when the EMA is above the VWAP (long side), -1 below, 0 equal
int Sign(const double d) { return(d > 0.0 ? 1 : (d < 0.0 ? -1 : 0)); }

//--- Pine plotted stop line: close -/+ k x ATR on the closed bar, only ever tightened (MACD_Cross_EA modify pattern)
void TrailStop(const ulong ticket, const double close, const double dist)
  {
   if(!PositionSelectByTicket(ticket) || !g_symbol.RefreshRates())
      return;
   const bool   isBuy  = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
   const double open   = PositionGetDouble(POSITION_PRICE_OPEN);
   const double curSL  = PositionGetDouble(POSITION_SL);
   const double curTP  = PositionGetDouble(POSITION_TP);
   if(InpTrailAfterProfit && (isBuy ? close - open : open - close) < dist)
      return;                                   // strategy.exit trail_points: nothing trails before +k x ATR
   const int    digits  = g_symbol.Digits();
   const double point   = g_symbol.Point();
   const double minDist = (double)MathMax(g_symbol.StopsLevel(), g_symbol.FreezeLevel()) * point;
   const double market  = isBuy ? g_symbol.Bid() : g_symbol.Ask();
   double newSL = isBuy ? close - dist : close + dist;
   if(isBuy  && market - newSL < minDist) newSL = market - minDist;
   if(!isBuy && newSL - market < minDist) newSL = market + minDist;
   newSL = NormalizeDouble(newSL, digits);
   const bool better = (curSL == 0.0) || (isBuy ? newSL > curSL + point : newSL < curSL - point);
   if(!better)
      return;
   if(!g_trade.PositionModify(ticket, newSL, curTP))
      PrintFormat("Modify #%I64u failed: %d %s", ticket, g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
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
   MqlRates r[];
   ArraySetAsSeries(r, true);
   double ema[2], atr[1];                       // CopyBuffer fills static arrays oldest-first: ema[1] = shift 1, ema[0] = shift 2
   const int copied = CopyRates(_Symbol, InpTimeframe, 1, need, r);
   if(copied < 2 || CopyBuffer(g_ema, 0, 1, 2, ema) < 2 || CopyBuffer(g_atr, 0, 1, 1, atr) < 1 ||
      ema[0] == EMPTY_VALUE || ema[1] == EMPTY_VALUE || atr[0] <= 0.0)
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
   const double dist = atr[0] * InpATRMult;
   const int s1 = Sign(ema[1] - vwap1);         // last closed bar: +1 = EMA above VWAP
   const int s2 = Sign(ema[0] - vwap2);         // the bar before it
   const string ctx = StringFormat("ema %.2f vwap %.2f atr %.2f side %d prev %d", ema[1], vwap1, atr[0], s1, s2);

   ulong ticket = 0;
   const bool held = Core_SelectOwnPosition(ticket);
   if(held)
      TrailStop(ticket, r[0].close, dist);      // exit order first, as process_orders_on_close does
   if(s1 == 0 || s2 == 0 || s1 == s2)
     {
      Core_LogBar(bar, ctx + (held ? " | holding" : " | no cross"));
      return;                                   // entries only on a cross: after a stop-out wait for the next one
     }
   if(held && PositionSelectByTicket(ticket))
     {
      const int side = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      if(side == s1)
        {
         Core_LogBar(bar, ctx + " | already on the new side");
         return;
        }
      if(!Core_ClosePosition(ticket, "cross"))  // reverse: close, then open the other side below
        {
         Core_LogBar(bar, ctx + " | close failed, retry on the next cross");
         return;
        }
     }
   if(!g_symbol.RefreshRates())
      return;
   const bool   buy = (s1 > 0);
   string why;
   if(!EntryAllowed(buy, r[0].close, bar, why))
     {
      Core_LogBar(bar, ctx + StringFormat(" | %s filtered: %s", buy ? "BUY" : "SELL", why));
      return;
     }
   Core_LogBar(bar, ctx + StringFormat(" | %s stop dist %.2f", buy ? "BUY" : "SELL", dist));
   Core_Open(buy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL, dist, 0.0);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

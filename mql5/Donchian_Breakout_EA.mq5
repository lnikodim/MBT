//+------------------------------------------------------------------+
//|                                         Donchian_Breakout_EA.mq5 |
//|  Donchian channel breakout on the signal timeframe with a        |
//|  higher-timeframe EMA trend filter: BUY when the last closed bar |
//|  closes above the highest high of the previous N bars (SELL      |
//|  mirrored). Stop k x ATR, target R x stop, one break-even step,  |
//|  no trailing, one position at a time, opposite signals ignored.  |
//|  Execution, guards and trade log from EACore.mqh.                |
//|  v1.03: account drawdown throttle via EACore;                    |
//|        live defaults = FTMO 2-Step: 0.5% risk, daily stop 3%,    |
//|        throttle 3%; logic same.                                  |
//|  v1.02: EACore 2026-10-18 fixes (session-aware bars, late-signal |
//|        guard, close retry, daily-stop latch, log); logic same.   |
//|  v1.01 defaults: H4, N 20, 2 x ATR(20), 2R, long-only, BE off    |
//|        (amendment 1 of the 2026-10-13 spec, passes Gate A).      |
//|  v1.00 H1, N 48, 3R, both sides, BE +1R (failed Gate A).          |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.03"
#property strict
#property description "Donchian channel breakout + HTF EMA trend filter; k x ATR stop, R x stop target, one break-even; MACD_Cross_EA v1.42 safety core"

#define EA_NAME    "Donchian_Breakout_EA"
#define EA_VERSION "1.03"
#define EA_MAGIC   261015
#define EA_COMMENT "DONCH"
#define EA_TIMEFRAME PERIOD_H4   // v1.01 defaults = the published, Gate-A-passing cell (spec 2026-10-13 amendment 1)
#define EA_SPREAD_WAIT_MIN 0   // the target is R x stop from the signal price: a retried entry would break that ratio
#define EA_RISK_VALUE 0.5             // compiled default from spec 2026-10-22-dd-reduction, phase 3b; each account's live value is in mql5/sets/<account>/
#define EA_DAILY_LOSS_PCT 3.0
#define ACCOUNT_THROTTLE_DD_PCT 3.0
#include "EACore.mqh"

//--- "5. Strategy" continues from EACore (signal timeframe). The channel is the highest high /
//--- lowest low of bars 2..N+1.
input int             InpChannelBars = 20;         // Channel length, bars
input bool            InpAllowShort  = false;      // Allow sells

input group "6. Filters"
input ENUM_TIMEFRAMES InpTrendTF     = PERIOD_H4;  // Trend filter: timeframe
input int             InpTrendEMA    = 200;        // Trend filter: EMA period (0 = off)

input group "7. Exits"
input int             InpATRPeriod   = 20;         // Stop loss: ATR period
input double          InpStopATR     = 2.0;        // Stop loss: distance, x ATR
input double          InpTargetR     = 2.0;        // Take profit, x stop distance (0 = off)
input double          InpBreakEvenR  = 0.0;        // Break-even: start at, x stop distance (0 = off)
input double          InpBELockR     = 0.2;        // Break-even: lock in, x stop distance

int g_atr = INVALID_HANDLE, g_trend = INVALID_HANDLE;

ENUM_TIMEFRAMES TrendTF() { return(InpTrendTF == PERIOD_CURRENT ? InpTimeframe : InpTrendTF); }

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpChannelBars < 2 || InpATRPeriod <= 1 || InpStopATR <= 0.0 || InpTargetR < 0.0 || InpTrendEMA < 0 ||
      InpBreakEvenR < 0.0 || InpBELockR < 0.0 || (InpBreakEvenR > 0.0 && InpBELockR >= InpBreakEvenR))
     {
      Print("Invalid inputs: channel >= 2, ATR period > 1, stop ATR > 0, target R >= 0, trend EMA >= 0, 0 <= lock R < break-even R");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   g_atr = iATR(_Symbol, InpTimeframe, InpATRPeriod);
   if(InpTrendEMA > 0)
      g_trend = iMA(_Symbol, TrendTF(), InpTrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(g_atr == INVALID_HANDLE || (InpTrendEMA > 0 && g_trend == INVALID_HANDLE))
     {
      Print("Failed to create indicators, error ", GetLastError());
      return(INIT_FAILED);
     }
   PrintFormat("%s v%s started on %s %s, magic %I64u, own positions: %d",
               EA_NAME, EA_VERSION, _Symbol, EnumToString(InpTimeframe), InpMagic, CountOwnPositions());
   PrintFormat("Inputs: channel %d | trend %s | shorts %s | stop %.2f x ATR(%d) | target %.2f R | break-even %.2f R lock %.2f R | risk %s %.2f",
               InpChannelBars, InpTrendEMA > 0 ? StringFormat("%s EMA%d", EnumToString(TrendTF()), InpTrendEMA) : "off",
               InpAllowShort ? "on" : "off", InpStopATR, InpATRPeriod, InpTargetR, InpBreakEvenR, InpBELockR,
               InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(g_atr != INVALID_HANDLE)
      IndicatorRelease(g_atr);
   if(g_trend != INVALID_HANDLE)
      IndicatorRelease(g_trend);
   Core_Deinit(reason);
  }

//--- one-shot break-even: acts only while the stop is still on the loss side of the entry (stateless, restart-safe)
void BreakEven()
  {
   if(!g_symbol.RefreshRates())
      return;
   const double minDist = (double)MathMax(g_symbol.StopsLevel(), g_symbol.FreezeLevel()) * g_symbol.Point();
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !IsOwnPosition())
         continue;
      const bool   isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      const double open  = PositionGetDouble(POSITION_PRICE_OPEN);
      const double curSL = PositionGetDouble(POSITION_SL);
      if(curSL == 0.0 || (isBuy ? curSL >= open : curSL <= open))
         continue;                                  // no stop, or already moved
      const double dist   = MathAbs(open - curSL);  // the real risk distance (after any stops-level widening)
      const double market = isBuy ? g_symbol.Bid() : g_symbol.Ask();
      if((isBuy ? market - open : open - market) < InpBreakEvenR * dist)
         continue;
      double newSL = isBuy ? open + InpBELockR * dist : open - InpBELockR * dist;
      if(isBuy  && market - newSL < minDist) newSL = market - minDist;
      if(!isBuy && newSL - market < minDist) newSL = market + minDist;
      newSL = NormalizeDouble(newSL, g_symbol.Digits());
      if(!g_trade.PositionModify(ticket, newSL, PositionGetDouble(POSITION_TP)))
         PrintFormat("Break-even #%I64u failed: %d %s", ticket, g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
     }
  }

void OnTick()
  {
   Core_OnTickStart();
   const datetime bar = Core_CurrentBar();
   Core_RetryPending(bar);
   if(InpBreakEvenR > 0.0 && CountOwnPositions() > 0)
      BreakEven();
   if(!Core_IsNewBar(bar))
      return;
   double hi[], lo[], atr[1], ema[1];
   double htfClose = 0.0;
   ema[0] = 0.0;
   if(CopyHigh(_Symbol, InpTimeframe, 2, InpChannelBars, hi) != InpChannelBars ||
      CopyLow(_Symbol, InpTimeframe, 2, InpChannelBars, lo) != InpChannelBars ||
      CopyBuffer(g_atr, 0, 1, 1, atr) < 1 || atr[0] <= 0.0)
      return;                                      // data not ready: bar stays unprocessed, retried next tick
   if(InpTrendEMA > 0)
     {
      htfClose = iClose(_Symbol, TrendTF(), 1);    // last closed trend-timeframe bar
      if(CopyBuffer(g_trend, 0, 1, 1, ema) < 1 || ema[0] == EMPTY_VALUE || htfClose <= 0.0)
         return;
     }
   Core_MarkBar(bar);
   const double close1 = iClose(_Symbol, InpTimeframe, 1);
   const double chHigh = hi[ArrayMaximum(hi)], chLow = lo[ArrayMinimum(lo)];
   const string ctx = StringFormat("close %.2f channel %.2f/%.2f atr %.2f", close1, chHigh, chLow, atr[0]);
   if(CountOwnPositions() > 0)
     {
      Core_LogBar(bar, ctx + " | holding");
      return;
     }
   const int sig = close1 > chHigh ? 1 : (close1 < chLow && InpAllowShort) ? -1 : 0;
   if(sig == 0)
     {
      Core_LogBar(bar, ctx + " | no breakout");
      return;
     }
   const bool buy = (sig > 0);
   if(InpTrendEMA > 0 && (buy ? htfClose <= ema[0] : htfClose >= ema[0]))
     {
      Core_LogBar(bar, ctx + StringFormat(" | %s filtered: %s close %.2f vs EMA%d %.2f",
                  buy ? "BUY" : "SELL", EnumToString(TrendTF()), htfClose, InpTrendEMA, ema[0]));
      return;
     }
   if(!g_symbol.RefreshRates())
      return;
   const double slDist = InpStopATR * atr[0];
   const double price  = buy ? g_symbol.Ask() : g_symbol.Bid();
   const double tp     = InpTargetR > 0.0 ? NormalizeDouble(buy ? price + InpTargetR * slDist : price - InpTargetR * slDist, g_symbol.Digits()) : 0.0;
   PrintFormat("DONCH SIGNAL %s close=%.2f hi=%.2f lo=%.2f atr=%.2f sl_dist=%.2f tp=%.2f htf_close=%.2f ema=%.2f",
               buy ? "BUY" : "SELL", close1, chHigh, chLow, atr[0], slDist, tp, htfClose, ema[0]);
   Core_LogBar(bar, ctx + StringFormat(" | %s stop dist %.2f", buy ? "BUY" : "SELL", slDist));
   Core_Open(buy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL, slDist, tp);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

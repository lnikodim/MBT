//+------------------------------------------------------------------+
//|                                                      FZMR_EA.mq5 |
//|  Port of the user's FZMR_Quant_Scalper v6 (Gemini): fade a       |
//|  2-sigma close (z-score vs SMA 20) when Kaufman ER says chop,    |
//|  RSI(7) is stretched and the EMA 50/200 trend agrees. Stop and   |
//|  target in ATR, time exit after N bars once z is back at 0.      |
//|  Added for the test: buys-only switch, target in R.              |
//|  Execution, guards and trade log from EACore.mqh.                |
//|  v1.00: spec 2026-10-17-fzmr-prereg.md                           |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.00"
#property strict
#property description "FZMR v6 z-score fade (ER, RSI, EMA 50/200 filters, ATR stop/target, time exit); MACD_Cross_EA v1.42 safety core"

#define EA_NAME    "FZMR_EA"
#define EA_VERSION "1.00"
#define EA_MAGIC   261019
#define EA_COMMENT "FZMR"
#define EA_TIMEFRAME PERIOD_M15
#define EA_SPREAD_WAIT_MIN 0      // v6 skips a spread-blocked bar
#include "EACore.mqh"

input group "=== Strategy ==="
input int    InpZPeriod        = 20;    // Z-score period (mean and std dev)
input double InpZThreshold     = 2.0;   // Z-score entry threshold (sigma)
input int    InpERPeriod       = 10;    // Efficiency ratio period
input double InpMaxER          = 0.40;  // Max efficiency ratio
input bool   InpUseTrendFilter = true;  // Trade only with the EMA trend
input int    InpFastEMAPeriod  = 50;    // Fast EMA period
input int    InpSlowEMAPeriod  = 200;   // Slow EMA period
input int    InpRSIPeriod      = 7;     // RSI period
input double InpRSIOverbought  = 70.0;  // RSI overbought (sells)
input double InpRSIOversold    = 30.0;  // RSI oversold (buys)
input int    InpATRPeriod      = 14;    // ATR period
input double InpSLMultiplier   = 2.0;   // Stop loss (x ATR)
input double InpTPMultiplier   = 2.5;   // Take profit (x ATR, used when target R = 0)
input double InpTargetR        = 0.0;   // Take profit (x stop distance, 0 = use the ATR target)
input int    InpMaxHoldBars    = 24;    // Time exit after N bars (0 = off)
input int    InpStartHour      = 2;     // Trading start hour (server)
input int    InpEndHour        = 20;    // Trading end hour (server)
input bool   InpSkipNYOpen     = true;  // Skip server hours 15-16
input bool   InpAllowShort     = true;  // Allow sells

int g_ma = INVALID_HANDLE, g_sd = INVALID_HANDLE, g_rsi = INVALID_HANDLE, g_atr = INVALID_HANDLE,
    g_fast = INVALID_HANDLE, g_slow = INVALID_HANDLE;

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpZPeriod < 2 || InpZThreshold <= 0.0 || InpERPeriod < 1 || InpMaxER <= 0.0 || InpFastEMAPeriod < 1 ||
      InpSlowEMAPeriod <= InpFastEMAPeriod || InpRSIPeriod < 2 || InpATRPeriod < 1 || InpSLMultiplier <= 0.0 ||
      InpTPMultiplier <= 0.0 || InpTargetR < 0.0 || InpMaxHoldBars < 0 || InpStartHour < 0 || InpEndHour > 24 ||
      InpStartHour >= InpEndHour)
     {
      Print("Invalid inputs: periods >= 2 (ER/EMA/ATR >= 1, slow EMA > fast), thresholds/multipliers > 0, target R >= 0, hold >= 0, 0 <= start < end <= 24");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   g_ma   = iMA(_Symbol, InpTimeframe, InpZPeriod, 0, MODE_SMA, PRICE_CLOSE);
   g_sd   = iStdDev(_Symbol, InpTimeframe, InpZPeriod, 0, MODE_SMA, PRICE_CLOSE);
   g_rsi  = iRSI(_Symbol, InpTimeframe, InpRSIPeriod, PRICE_CLOSE);
   g_atr  = iATR(_Symbol, InpTimeframe, InpATRPeriod);
   g_fast = iMA(_Symbol, InpTimeframe, InpFastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_slow = iMA(_Symbol, InpTimeframe, InpSlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(g_ma == INVALID_HANDLE || g_sd == INVALID_HANDLE || g_rsi == INVALID_HANDLE || g_atr == INVALID_HANDLE ||
      g_fast == INVALID_HANDLE || g_slow == INVALID_HANDLE)
     {
      Print("Failed to create indicators, error ", GetLastError());
      return(INIT_FAILED);
     }
   PrintFormat("%s v%s started on %s %s, magic %I64u, own positions: %d",
               EA_NAME, EA_VERSION, _Symbol, EnumToString(InpTimeframe), InpMagic, CountOwnPositions());
   PrintFormat("Inputs: z(%d) %.2f | ER(%d) <= %.2f | trend %s EMA %d/%d | RSI(%d) %.0f/%.0f | stop %.2f ATR(%d) | target %s | hold %d bars | hours %d-%d%s | shorts %s | risk %s %.2f",
               InpZPeriod, InpZThreshold, InpERPeriod, InpMaxER, InpUseTrendFilter ? "on" : "off", InpFastEMAPeriod, InpSlowEMAPeriod,
               InpRSIPeriod, InpRSIOversold, InpRSIOverbought, InpSLMultiplier, InpATRPeriod,
               InpTargetR > 0.0 ? StringFormat("%.2f R", InpTargetR) : StringFormat("%.2f ATR", InpTPMultiplier),
               InpMaxHoldBars, InpStartHour, InpEndHour, InpSkipNYOpen ? " skip 15-16" : "", InpAllowShort ? "on" : "off",
               InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   const int h[] = {g_ma, g_sd, g_rsi, g_atr, g_fast, g_slow};
   for(int i = 0; i < ArraySize(h); i++)
      if(h[i] != INVALID_HANDLE)
         IndicatorRelease(h[i]);
   Core_Deinit(reason);
  }

// Kaufman efficiency ratio over `period` closed bars ending at shift 1 (v6 CalculateEfficiencyRatio)
double EfficiencyRatio(const int period)
  {
   MqlRates r[];
   ArraySetAsSeries(r, true);
   if(CopyRates(_Symbol, InpTimeframe, 1, period + 1, r) < period + 1)
      return(1.0);
   double sum = 0.0;
   for(int i = 0; i < period; i++)
      sum += MathAbs(r[i].close - r[i + 1].close);
   return(sum == 0.0 ? 0.0 : MathAbs(r[0].close - r[period].close) / sum);
  }

// v6 time exit, every tick: after InpMaxHoldBars close once the live z is back at 0, after +10 bars close anyway
void ManagePosition(const double mean, const double sd)
  {
   ulong ticket = 0;
   if(InpMaxHoldBars <= 0 || !Core_SelectOwnPosition(ticket))
      return;
   const int held = (int)((TimeCurrent() - (datetime)PositionGetInteger(POSITION_TIME)) / PeriodSeconds(InpTimeframe));
   if(held < InpMaxHoldBars)
      return;
   const bool   isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
   const double z     = (iClose(_Symbol, InpTimeframe, 0) - mean) / sd;
   if((isBuy && z >= 0.0) || (!isBuy && z <= 0.0) || held >= InpMaxHoldBars + 10)
     {
      PrintFormat("FZMR EXIT %s held=%d z=%.8f", isBuy ? "BUY" : "SELL", held, z);
      Core_ClosePosition(ticket, "expert");
     }
  }

void OnTick()
  {
   Core_OnTickStart();
   const datetime bar = Core_CurrentBar();
   Core_RetryPending(bar);
   double ma[1], sd[1];
   if(CopyBuffer(g_ma, 0, 1, 1, ma) < 1 || CopyBuffer(g_sd, 0, 1, 1, sd) < 1 || sd[0] <= 0.0)
      return;
   ManagePosition(ma[0], sd[0]);
   if(!Core_IsNewBar(bar))
      return;
   double rsi[1], atr[1], fast[1], slow[4];
   MqlRates r[];
   ArraySetAsSeries(r, true);
   if(CopyBuffer(g_rsi, 0, 1, 1, rsi) < 1 || CopyBuffer(g_atr, 0, 1, 1, atr) < 1 || CopyBuffer(g_fast, 0, 1, 1, fast) < 1 ||
      CopyBuffer(g_slow, 0, 1, 4, slow) < 4 || CopyRates(_Symbol, InpTimeframe, 1, 1, r) < 1 || atr[0] <= 0.0)
      return;                                      // data not ready: bar stays unprocessed, retried next tick
   Core_MarkBar(bar);
   // oldest-first: slow[3] = shift 1 (last closed bar), slow[0] = shift 4
   const double close = r[0].close, z = (close - ma[0]) / sd[0], range = r[0].high - r[0].low;
   const string ctx = StringFormat("z %.2f rsi %.1f atr %.2f", z, rsi[0], atr[0]);
   if(CountOwnPositions() > 0)
     {
      Core_LogBar(bar, ctx + " | in position");
      return;
     }
   MqlDateTime dt;
   TimeCurrent(dt);
   if(dt.hour < InpStartHour || dt.hour >= InpEndHour || (InpSkipNYOpen && (dt.hour == 15 || dt.hour == 16)))
     {
      Core_LogBar(bar, ctx + " | outside hours");
      return;
     }
   const double er = EfficiencyRatio(InpERPeriod);
   if(er > InpMaxER || range > 2.0 * atr[0])
     {
      Core_LogBar(bar, ctx + StringFormat(" | er %.2f range %.2f: filtered", er, range));
      return;
     }
   const bool bullOK = !InpUseTrendFilter || (fast[0] > slow[3] && slow[3] >= slow[0] && close > slow[3]);
   const bool bearOK = !InpUseTrendFilter || (fast[0] < slow[3] && slow[3] <= slow[0] && close < slow[3]);
   int sig = 0;
   if(z <= -InpZThreshold && rsi[0] < InpRSIOversold && bullOK)
      sig = 1;
   else if(z >= InpZThreshold && rsi[0] > InpRSIOverbought && bearOK && InpAllowShort)
      sig = -1;
   if(sig == 0)
     {
      Core_LogBar(bar, ctx + " | no signal");
      return;
     }
   if(!g_symbol.RefreshRates())
      return;
   const bool   buy    = (sig > 0);
   const double price  = buy ? g_symbol.Ask() : g_symbol.Bid();
   const double slDist = InpSLMultiplier * atr[0];
   const double tpDist = InpTargetR > 0.0 ? InpTargetR * slDist : InpTPMultiplier * atr[0];
   const double tp     = NormalizeDouble(buy ? price + tpDist : price - tpDist, g_symbol.Digits());
   PrintFormat("FZMR SIGNAL %s z=%.8f rsi=%.8f er=%.8f fast=%.8f slow=%.8f slow4=%.8f close=%.8f range=%.8f atr=%.8f sl_dist=%.8f tp_dist=%.8f",
               buy ? "BUY" : "SELL", z, rsi[0], er, fast[0], slow[3], slow[0], close, range, atr[0], slDist, tpDist);
   Core_LogBar(bar, ctx + StringFormat(" | %s", buy ? "BUY" : "SELL"));
   Core_Open(buy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL, slDist, tp);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

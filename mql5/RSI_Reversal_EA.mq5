//+------------------------------------------------------------------+
//|                                              RSI_Reversal_EA.mq5 |
//| Buys when RSI closes below the buy level, sells when it closes   |
//| above the sell level. The same direction trades again only after |
//| RSI has closed back across 50. Optional MA trend filter, SL / TP,|
//| break-even and trailing stop as % of the open price.             |
//|                                                                  |
//| Signals use closed bars of the RSI timeframe (InpTimeframe),     |
//| evaluated once per bar. Re-arm state is rebuilt from the account |
//| deal history at start-up, so a restart, crash or VPS migration   |
//| cannot duplicate a trade. Only positions with InpMagic on        |
//| _Symbol are touched.                                             |
//|                                                                  |
//| v1.22: account drawdown throttle via EACore;                     |
//|        live defaults = FTMO 2-Step: 0.5% risk, daily stop 3%,    |
//|        throttle 3%; logic same.                                  |
//| v1.21: EACore 2026-10-18 fixes (session-aware bars, spread retry |
//|        window from the delay, late-signal guard, daily-stop      |
//|        latch, trade log per login); signal logic unchanged.      |
//| v1.20: execution, guards and trade log from EACore.mqh (the      |
//|        MACD_Cross_EA v1.42 core: spread cap + in-bar retry,      |
//|        daily / monthly loss stops, closed-trade CSV, Ready check |
//|        and Bar status lines), MACD-style break-even              |
//|        (InpBreakEvenPct / InpBreakEvenLockPct, off by default),  |
//|        trailing kept as an input (InpTrailTriggerPct 0 = off).   |
//|        Dropped: InpLotsWithoutSL (a stop is required), the 10-s  |
//|        retry loop; InpRsiTimeframe is now InpTimeframe and       |
//|        InpSlippage is InpSlippagePoints. NOTE: EACore's          |
//|        InpRiskMode is MONEY 0 / PERCENT 1 (v1.10 had PERCENT 0). |
//|        Prereg: docs/superpowers/specs/2026-10-14-rsi-donchian-   |
//|        guardrails-prereg.md.                                     |
//| v1.10 defaults tuned on XAUUSD 2019-2024 (each 3-year regime     |
//| profitable on its own), held out 2025-26: PF 1.77 real ticks.    |
//+------------------------------------------------------------------+
#property copyright   "MBT"
#define EA_VERSION    "1.22"
#property version     EA_VERSION
#property strict
#property description "RSI threshold entries with a re-arm at 50, optional MA filter, % SL / TP,"
#property description "break-even and trailing stop; MACD_Cross_EA v1.42 safety core"

#define EA_NAME      "RSI_Reversal_EA"
#define EA_MAGIC     261004
#define EA_COMMENT   "RSI_REV"
#define EA_TIMEFRAME PERIOD_H6     // InpTimeframe = RSI timeframe (v1.10 InpRsiTimeframe)
#define EA_RISK_VALUE 0.5             // compiled default from spec 2026-10-22-dd-reduction, phase 3b; each account's live value is in mql5/sets/<account>/
#define EA_DAILY_LOSS_PCT 3.0
#define ACCOUNT_THROTTLE_DD_PCT 3.0
#include "EACore.mqh"

//--- "5. Strategy" continues from EACore (signal timeframe = RSI timeframe)
input int              InpRsiPeriod        = 4;            // RSI period
input double           InpRsiBuyLevel      = 40.0;         // Buy when RSI closes below
input double           InpRsiSellLevel     = 55.0;         // Sell when RSI closes above

input group "6. Filters"
input bool             InpUseMaFilter      = true;         // Use MA filter (buy above MA, sell below)
input ENUM_TIMEFRAMES  InpMaTimeframe      = PERIOD_H12;   // MA filter: timeframe
input int              InpMaPeriod         = 250;          // MA filter: period
input ENUM_MA_METHOD   InpMaMethod         = MODE_SMA;     // MA filter: type

input group "7. Exits"
input double           InpStopLossPct      = 1.0;          // Stop loss, % of open price
input double           InpTakeProfitPct    = 5.0;          // Take profit, % of open price (0 = off)
input double           InpBreakEvenPct     = 0.0;          // Break-even: start at profit, % (0 = off)
input double           InpBreakEvenLockPct = 0.1;          // Break-even: lock in profit, %
input double           InpTrailTriggerPct  = 1.0;          // Trailing stop: start at profit, % (0 = off)
input double           InpTrailDistancePct = 1.0;          // Trailing stop: distance, %
input double           InpTrailStepPct     = 0.05;         // Trailing stop: step, %

#define REARM_LEVEL 50.0  // RSI must close beyond this before the same direction trades again

int    g_rsi = INVALID_HANDLE, g_ma = INVALID_HANDLE;
ENUM_TIMEFRAMES g_maTf;
bool   g_hedging;
bool   g_synced;        // re-arm flags rebuilt from the account
bool   g_buyArmed, g_sellArmed;

//+------------------------------------------------------------------+
//| Lifecycle                                                        |
//+------------------------------------------------------------------+
int OnInit()
  {
   string err = "";
   if(InpRsiPeriod < 2)
      err = "RSI period must be at least 2";
   else if(InpRsiBuyLevel <= 0.0 || InpRsiBuyLevel > REARM_LEVEL)
      err = "RSI buy level must be above 0 and not above 50";
   else if(InpRsiSellLevel < REARM_LEVEL || InpRsiSellLevel >= 100.0)
      err = "RSI sell level must be at least 50 and below 100";
   else if(InpUseMaFilter && InpMaPeriod < 1)
      err = "MA period must be at least 1";
   else if(InpStopLossPct <= 0.0 || InpStopLossPct >= 100.0)
      err = "Stop loss % must be above 0 and below 100 (risk sizing needs a stop)";
   else if(InpTakeProfitPct < 0.0)
      err = "Take profit % must not be negative";
   else if(InpBreakEvenPct < 0.0 || InpBreakEvenLockPct < 0.0 || (InpBreakEvenPct > 0.0 && InpBreakEvenLockPct >= InpBreakEvenPct))
      err = "Break-even: 0 <= lock % < trigger %";
   else if(InpTrailTriggerPct < 0.0 || InpTrailDistancePct < 0.0 || InpTrailStepPct < 0.0)
      err = "Trailing stop inputs must not be negative";
   else if(InpTrailTriggerPct > 0.0 && InpTrailDistancePct <= 0.0)
      err = "Trailing distance % must be above 0 when the trailing stop is on";
   if(err != "")
     {
      Print("Invalid inputs: ", err);
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);

   g_maTf = (InpMaTimeframe == PERIOD_CURRENT) ? Period() : InpMaTimeframe;
   g_rsi  = iRSI(_Symbol, InpTimeframe, InpRsiPeriod, PRICE_CLOSE);
   if(InpUseMaFilter)
      g_ma = iMA(_Symbol, g_maTf, InpMaPeriod, 0, InpMaMethod, PRICE_CLOSE);
   if(g_rsi == INVALID_HANDLE || (InpUseMaFilter && g_ma == INVALID_HANDLE))
     {
      PrintFormat("Failed to create indicators, error %d", GetLastError());
      return(INIT_FAILED);
     }
   g_hedging = (AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
//--- reset explicitly: a parameter or chart change re-runs OnInit without reloading the program
   g_synced    = false;
   g_buyArmed  = true;
   g_sellArmed = true;

   PrintFormat("%s v%s %s | magic %I64u | RSI(%d) %s buy < %.1f, sell > %.1f | MA filter %s | SL %.2f%% | TP %s | "
               "break-even %s | trailing %s | risk %s | %s account",
               EA_NAME, EA_VERSION, _Symbol, InpMagic, InpRsiPeriod, StringSubstr(EnumToString(InpTimeframe), 7),
               InpRsiBuyLevel, InpRsiSellLevel,
               InpUseMaFilter ? StringFormat("%s(%d) %s", StringSubstr(EnumToString(InpMaMethod), 5), InpMaPeriod,
                                             StringSubstr(EnumToString(g_maTf), 7)) : "off",
               InpStopLossPct,
               InpTakeProfitPct > 0.0 ? StringFormat("%.2f%%", InpTakeProfitPct) : "none",
               InpBreakEvenPct > 0.0 ? StringFormat("at +%.2f%%, lock +%.2f%%", InpBreakEvenPct, InpBreakEvenLockPct) : "off",
               InpTrailTriggerPct > 0.0 ? StringFormat("at +%.2f%%, distance %.2f%%, step %.2f%%",
                                                       InpTrailTriggerPct, InpTrailDistancePct, InpTrailStepPct) : "off",
               InpRiskMode == RISK_PERCENT ? StringFormat("%.2f%% of balance", InpRiskValue)
                                           : StringFormat("%.2f %s", InpRiskValue, AccountInfoString(ACCOUNT_CURRENCY)),
               g_hedging ? "hedging" : "netting (opens only while the symbol has no position)");
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(g_rsi != INVALID_HANDLE)
      IndicatorRelease(g_rsi);
   if(g_ma != INVALID_HANDLE)
      IndicatorRelease(g_ma);
   Core_Deinit(reason);
  }

void OnTick()
  {
   Core_OnTickStart();                                   // daily stop closes own positions first
   const datetime bar = Core_CurrentBar();
   Core_RetryPending(bar);
   if((InpBreakEvenPct > 0.0 || InpTrailTriggerPct > 0.0) && CountOwnPositions() > 0)
      ManageStops();
   if(!g_synced)
     {
      if(!SyncArmState())
         return;
      g_synced = true;
     }
   if(!Core_IsNewBar(bar))
      return;
   int signal = -1;
   if(!EvaluateBar(bar, signal))
      return;                                            // indicator data not ready: retried next tick
   Core_MarkBar(bar);
   if(signal >= 0)
      TryEntry(signal == POSITION_TYPE_BUY);
  }

//+------------------------------------------------------------------+
//| Re-arm state                                                     |
//+------------------------------------------------------------------+
//--- Rebuilds the re-arm flags from the account itself: the newest own entry per direction and the
//--- RSI bars that closed after it. Needs no stored state, so restarts and VPS moves are safe.
bool SyncArmState()
  {
   double probe[];
   if(CopyBuffer(g_rsi, 0, 0, 1, probe) != 1 || BarsCalculated(g_rsi) < Bars(_Symbol, InpTimeframe))
      return(false);

   datetime lastBuy = 0, lastSell = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionGetTicket(i) != 0 && IsOwnPosition())
        {
         const datetime t = (datetime)PositionGetInteger(POSITION_TIME);
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           { if(t > lastBuy) lastBuy = t; }
         else if(t > lastSell)
            lastSell = t;
        }
   if(!HistorySelect(0, TimeCurrent() + 86400))
      return(false);
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      const ulong deal = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(deal, DEAL_MAGIC) != (long)InpMagic ||
         HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_IN ||
         HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol)
         continue;
      const datetime t    = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
      const long     type = HistoryDealGetInteger(deal, DEAL_TYPE);
      if(type == DEAL_TYPE_BUY)
        { if(t > lastBuy) lastBuy = t; }
      else if(type == DEAL_TYPE_SELL && t > lastSell)
         lastSell = t;
     }

   const int buy  = RearmedSince(lastBuy, true);
   const int sell = RearmedSince(lastSell, false);
   if(buy < 0 || sell < 0)
      return(false);
   g_buyArmed  = (buy == 1);
   g_sellArmed = (sell == 1);
   PrintFormat("State: buys %s (last buy %s), sells %s (last sell %s)",
               g_buyArmed ? "armed" : "wait for RSI > 50", lastBuy > 0 ? TimeToString(lastBuy) : "none",
               g_sellArmed ? "armed" : "wait for RSI < 50", lastSell > 0 ? TimeToString(lastSell) : "none");
   return(true);
  }

//--- 1 = RSI closed beyond 50 on a bar after the entry, 0 = not yet, -1 = data not ready.
int RearmedSince(const datetime entry, const bool isBuy)
  {
   if(entry == 0)
      return(1);
   const int bars = Bars(_Symbol, InpTimeframe);
   if(bars < 2)
      return(-1);
   if(entry < iTime(_Symbol, InpTimeframe, bars - 1))
      return(1);                       // older than the loaded history: long since re-armed
   const int shift = iBarShift(_Symbol, InpTimeframe, entry);
   if(shift < 0)
      return(-1);
   if(shift == 0)
      return(0);                       // entered on the forming bar: no bar has closed since
   double rsi[];
   if(CopyBuffer(g_rsi, 0, 1, shift, rsi) != shift)
      return(-1);
   for(int i = 0; i < shift; i++)
      if(isBuy ? rsi[i] > REARM_LEVEL : rsi[i] < REARM_LEVEL)
         return(1);
   return(0);
  }

void Disarm(const bool isBuy)
  {
   if(isBuy)
      g_buyArmed = false;
   else
      g_sellArmed = false;
  }

//+------------------------------------------------------------------+
//| Signal                                                           |
//+------------------------------------------------------------------+
//--- Runs once per new RSI bar on the bar that just closed. Returns false when data are not ready.
//--- signal: POSITION_TYPE_BUY / POSITION_TYPE_SELL, or -1 for none. A filtered signal stays armed.
bool EvaluateBar(const datetime bar, int &signal)
  {
   double rsi[];
   if(CopyBuffer(g_rsi, 0, 1, 1, rsi) != 1 || BarsCalculated(g_rsi) < Bars(_Symbol, InpTimeframe))
      return(false);
   const double r = rsi[0];
   if(r > REARM_LEVEL)
      g_buyArmed = true;
   if(r < REARM_LEVEL)
      g_sellArmed = true;

   signal = -1;
   if(r < InpRsiBuyLevel && g_buyArmed)
      signal = POSITION_TYPE_BUY;
   else if(r > InpRsiSellLevel && g_sellArmed)
      signal = POSITION_TYPE_SELL;
   const string ctx = StringFormat("RSI %.2f | buys %s, sells %s", r, g_buyArmed ? "armed" : "wait", g_sellArmed ? "armed" : "wait");
   if(signal < 0)
     {
      Core_LogBar(bar, ctx + " | no signal");
      return(true);
     }
   const bool isBuy = (signal == POSITION_TYPE_BUY);
   if(InpUseMaFilter)
     {
      double ma[];
      if(CopyBuffer(g_ma, 0, 0, 1, ma) != 1 || BarsCalculated(g_ma) < Bars(_Symbol, g_maTf) || !g_symbol.RefreshRates())
         return(false);
      const double price = isBuy ? g_symbol.Ask() : g_symbol.Bid();   // current price vs the MA at shift 0, as v1.10
      if(isBuy ? price <= ma[0] : price >= ma[0])
        {
         PrintFormat("%s signal (RSI %.2f) filtered: price %s is %s MA %s", isBuy ? "BUY" : "SELL", r,
                     DoubleToString(price, _Digits), isBuy ? "not above" : "not below", DoubleToString(ma[0], _Digits));
         Core_LogBar(bar, ctx + StringFormat(" | %s filtered by MA %.2f", isBuy ? "BUY" : "SELL", ma[0]));
         signal = -1;
         return(true);
        }
     }
   Core_LogBar(bar, ctx + (isBuy ? " | BUY signal" : " | SELL signal"));
   return(true);
  }

//+------------------------------------------------------------------+
//| Entry                                                            |
//+------------------------------------------------------------------+
void TryEntry(const bool isBuy)
  {
   if(!g_hedging && PositionSelect(_Symbol))
     {
      PrintFormat("%s entry skipped: netting account already holds a position on %s", isBuy ? "BUY" : "SELL", _Symbol);
      return;                                            // stays armed, as every skipped signal
     }
   if(!g_symbol.RefreshRates())
      return;
   const double price = isBuy ? g_symbol.Ask() : g_symbol.Bid();
   const double tp    = InpTakeProfitPct > 0.0
                        ? NormalizeDouble(isBuy ? price * (1.0 + InpTakeProfitPct / 100.0) : price * (1.0 - InpTakeProfitPct / 100.0), g_symbol.Digits())
                        : 0.0;
//--- a spread-delayed signal is retried by EACore with this stop distance and this absolute target
   if(Core_Open(isBuy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL, price * InpStopLossPct / 100.0, tp))
      Disarm(isBuy);                                     // retried fills disarm through OnTradeTransaction
  }

//+------------------------------------------------------------------+
//| Break-even and trailing stop for own positions (only tighten)    |
//+------------------------------------------------------------------+
void ManageStops()
  {
   if(!g_symbol.RefreshRates())
      return;
   const int    digits  = g_symbol.Digits();
   const double point   = g_symbol.Point();
   const double minDist = (double)MathMax(g_symbol.StopsLevel(), g_symbol.FreezeLevel()) * point;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !IsOwnPosition())
         continue;
      const bool   isBuy  = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      const double open   = PositionGetDouble(POSITION_PRICE_OPEN);
      const double curSL  = PositionGetDouble(POSITION_SL);
      const double curTP  = PositionGetDouble(POSITION_TP);
      const double market = isBuy ? g_symbol.Bid() : g_symbol.Ask();      // exit price
      const double profit = isBuy ? market - open : open - market;        // in price units
      if(profit <= 0.0)
         continue;
      double newSL = 0.0;
      //--- break-even (MACD_Cross_EA rule: % of the open price)
      if(InpBreakEvenPct > 0.0 && profit >= open * InpBreakEvenPct / 100.0)
        {
         const double lock = open * InpBreakEvenLockPct / 100.0;
         newSL = isBuy ? open + lock : open - lock;
        }
      //--- trailing (v1.10 rule: distance and step as % of the open price)
      if(InpTrailTriggerPct > 0.0 && profit >= open * InpTrailTriggerPct / 100.0)
        {
         const double dist  = open * InpTrailDistancePct / 100.0;
         const double trail = isBuy ? market - dist : market + dist;
         const bool   step  = (curSL == 0.0) || (isBuy ? trail - curSL : curSL - trail) >= open * InpTrailStepPct / 100.0;
         if(step && (newSL == 0.0 || (isBuy ? trail > newSL : trail < newSL)))
            newSL = trail;
        }
      if(newSL == 0.0)
         continue;
      if(isBuy  && market - newSL < minDist) newSL = market - minDist;
      if(!isBuy && newSL - market < minDist) newSL = market + minDist;
      newSL = NormalizeDouble(newSL, digits);
      const bool better = (curSL == 0.0) || (isBuy ? newSL > curSL + point : newSL < curSL - point);
      if(!better)
         continue;
      if(!g_trade.PositionModify(ticket, newSL, curTP))
         PrintFormat("Modify #%I64u failed: %d %s", ticket, g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
     }
  }

//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
//--- any own entry fill disarms its direction (covers EACore's spread-delayed retry, which opens without telling us)
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD && trans.deal != 0 && HistoryDealSelect(trans.deal) &&
      HistoryDealGetInteger(trans.deal, DEAL_ENTRY) == DEAL_ENTRY_IN &&
      HistoryDealGetInteger(trans.deal, DEAL_MAGIC) == (long)InpMagic &&
      HistoryDealGetString(trans.deal, DEAL_SYMBOL) == _Symbol)
      Disarm(HistoryDealGetInteger(trans.deal, DEAL_TYPE) == DEAL_TYPE_BUY);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| EACore.mqh -- shared execution core for MBT EAs                  |
//| Copied from MACD_Cross_EA v1.42 without behaviour changes:       |
//| risk sizing, spread guard + in-bar retry, daily/monthly loss     |
//| stops, closed-trade CSV log, Ready check / Bar status lines,     |
//| restart-safe bar tracking. Strategy-free.                        |
//| 2026-10-18 (spec 2026-10-18-eacore-correctness-prereg.md): bars  |
//| are processed only inside the trade session; spread-retry window |
//| counts from the delay; failed closes retried every tick; live:   |
//| no entry on a bar that opened before load, single-instance lock, |
//| foreign-entry alert, trade log per login with catch-up; daily    |
//| stop latches for the server day.                                 |
//|                                                                  |
//| Before including, the EA defines:                                |
//|   #define EA_NAME    "MeanRev_EA"                                |
//|   #define EA_VERSION "1.00"                                      |
//|   #define EA_MAGIC   240819                                      |
//|   #define EA_COMMENT "MREV"                                      |
//+------------------------------------------------------------------+
#property strict

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include "AccountThrottle.mqh"

#ifndef EA_TIMEFRAME
#define EA_TIMEFRAME PERIOD_H1        // an EA may #define a different compiled default before including
#endif
#ifndef EA_MAX_SPREAD_POINTS
#define EA_MAX_SPREAD_POINTS 150       // an EA may #define a different compiled default before including
#endif
#ifndef EA_SPREAD_WAIT_MIN
#define EA_SPREAD_WAIT_MIN 30          // an EA may #define a different compiled default before including
#endif
#ifndef EA_DAILY_LOSS_PCT
#define EA_DAILY_LOSS_PCT 4.0          // an EA may #define a different compiled default before including
#endif
#ifndef EA_MONTHLY_LOSS_PCT
#define EA_MONTHLY_LOSS_PCT 12.0       // an EA may #define a different compiled default before including
#endif

enum ENUM_RISK_MODE
  {
   RISK_MONEY   = 0,  // Fixed money per trade (account currency)
   RISK_PERCENT = 1   // Percent of account balance per trade
  };

input group "=== General ==="
input ulong               InpMagic           = EA_MAGIC;    // Magic number
input ENUM_TIMEFRAMES     InpTimeframe       = EA_TIMEFRAME; // Signal timeframe
input string              InpComment         = EA_COMMENT;  // Order comment
input int                 InpSlippagePoints  = 30;          // Max deviation (points)
input int                 InpMaxSpreadPoints = EA_MAX_SPREAD_POINTS; // Max spread to trade (points, 0 = off)

input group "=== Risk ==="
input ENUM_RISK_MODE      InpRiskMode        = RISK_PERCENT;// Risk mode
input double              InpRiskValue       = 1.0;         // Risk value (money or %)

input group "=== Safety guards ==="
input int                 InpSpreadWaitMin   = EA_SPREAD_WAIT_MIN; // Retry a spread-blocked signal for N minutes (0 = drop it)
input double              InpDailyLossPct    = EA_DAILY_LOSS_PCT;   // Daily loss stop, % of day-start balance (0 = off)
input double              InpMonthlyLossPct  = EA_MONTHLY_LOSS_PCT; // Monthly loss stop, % of month-start balance (0 = off)
input bool                InpTradeLog        = true;        // Write closed trades to a CSV in MQL5\Files

input group "=== Diagnostics ==="
input bool                InpLogEveryBar     = true;        // Log a status line on every new signal bar

#define TRADE_LOG_HEADER "close_time,open_time,symbol,side,volume,open_price,close_price,sl,tp,gross,commission,swap,profit,balance,r_multiple,exit_reason,spread_pts,slippage_pts,deal,position,magic\n"

CTrade        g_trade;
CSymbolInfo   g_symbol;
datetime      g_lastBarTime  = 0;
string        g_gvLastBar    = "";
int           g_pendingType  = -1;     // spread-blocked signal: POSITION_TYPE_BUY/SELL, -1 = none
datetime      g_pendingBar   = 0;
datetime      g_pendingSince = 0;     // when the signal was delayed: its retry window starts here
double        g_pendingSL    = 0.0;
double        g_pendingTP    = 0.0;
datetime      g_dayStart     = 0;
double        g_dayBalance   = 0.0;
datetime      g_monthStart   = 0;
double        g_monthBalance = 0.0;
bool          g_dayStopHit   = false;  // daily stop hit: flat and no entries until the next server day
long          g_guardLogin   = 0;      // account the cached start balances belong to
datetime      g_loadGMT      = 0;      // live: GMT at load; no entry on a bar that had quotes before it (Core_LateBar)
string        g_lockName     = "";     // live: single-instance lock (temporary terminal global variable)
bool          g_logCaughtUp  = true;   // live: closes made while the EA was not running are appended once
ulong         g_closeRetry[];          // positions whose close failed: retried every tick
string        g_logFile      = "";
int           g_logFlags     = 0;
uint          g_lastCloseFailMsg = 0;
ulong         g_lastLoggedDeal   = 0;     // newest closing deal written to the trade log
struct EntryInfo   { ulong position; int spread; double slippage; double risk; };
struct ForcedClose { ulong position; string reason; };
EntryInfo     g_entries[];
ForcedClose   g_forced[];

//+------------------------------------------------------------------+
//| Lifecycle                                                        |
//+------------------------------------------------------------------+
bool Core_Init()
  {
   if(InpRiskValue <= 0.0 || (InpRiskMode == RISK_PERCENT && InpRiskValue > 100.0))
     {
      Print("Invalid risk value");
      return(false);
     }
   if(InpSpreadWaitMin < 0 || InpDailyLossPct < 0.0 || InpDailyLossPct >= 100.0 ||
      InpMonthlyLossPct < 0.0 || InpMonthlyLossPct >= 100.0)
     {
      Print("Invalid safety guard inputs");
      return(false);
     }
   if(!g_symbol.Name(_Symbol))
     {
      Print("Failed to initialise symbol ", _Symbol);
      return(false);
     }
   g_symbol.Refresh();
   if(!MQLInfoInteger(MQL_TESTER))
     {
      g_lockName = StringFormat("%s_%s_%I64u_lock", EA_NAME, _Symbol, InpMagic);
      GlobalVariableTemp(g_lockName);
      if(!GlobalVariableSetOnCondition(g_lockName, LockValue(), 0.0) && GlobalVariableGet(g_lockName) != LockValue())
        {
         PrintFormat("%s already runs on %s with magic %I64u on another chart: this instance does not start",
                     EA_NAME, _Symbol, InpMagic);
         g_lockName = "";
         return(false);
        }
      g_loadGMT = TimeGMT();
     }

   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetDeviationInPoints(InpSlippagePoints);
   g_trade.SetTypeFillingBySymbol(_Symbol);
   g_trade.SetAsyncMode(false);
   g_trade.LogLevel(LOG_LEVEL_ERRORS);

   g_gvLastBar = StringFormat("%s_%s_%s_%I64u", EA_NAME, _Symbol, EnumToString(InpTimeframe), InpMagic);
   if(GlobalVariableCheck(g_gvLastBar))
      g_lastBarTime = (datetime)GlobalVariableGet(g_gvLastBar);
   UpdatePeriodBalances();
   LogInit();
   return(true);
  }

void Core_PrintReady()
  {
   PrintFormat("Guards: max spread %s, retry %d min | daily stop %s | monthly stop %s | trade log %s",
               InpMaxSpreadPoints > 0 ? StringFormat("%d pts", InpMaxSpreadPoints) : "off", InpSpreadWaitMin,
               InpDailyLossPct > 0.0 ? StringFormat("-%.1f%%", InpDailyLossPct) : "off",
               InpMonthlyLossPct > 0.0 ? StringFormat("-%.1f%%", InpMonthlyLossPct) : "off",
               InpTradeLog ? "on" : "off");
   Print("Ready check: ", TradePermissionText(), " | ", GuardStatus());
   Print("Trade sessions (server): ", SessionText());
  }

void Core_Deinit(const int reason)
  {
//--- tester: catch up closing deals that raised no trade event (the end-of-test close).
//--- Live, the catch-up runs at the first tick or trade event of the next start, from the file's last deal.
   if(MQLInfoInteger(MQL_TESTER))
      LogCatchUp();
   if(g_lockName != "" && GlobalVariableGet(g_lockName) == LockValue())
      GlobalVariableDel(g_lockName);
   g_lockName = "";
   if(reason == REASON_REMOVE || reason == REASON_PARAMETERS || reason == REASON_CHARTCHANGE)
      GlobalVariableDel(g_gvLastBar);
  }

//+------------------------------------------------------------------+
//| Bar tracking                                                     |
//+------------------------------------------------------------------+
datetime Core_CurrentBar()                 { return(iTime(_Symbol, InpTimeframe, 0)); }
//--- a bar counts as new only at a tick inside the trade session: a quote before the session opens (IC Markets gold,
//--- 01:00 server, trading from 01:02) would consume the bar with entries and exits rejected as "market closed"
bool     Core_IsNewBar(const datetime bar) { return(bar != 0 && bar != g_lastBarTime && Core_SessionOpen()); }

//--- true when the last tick falls inside one of today's trade sessions of the symbol (no session listed = open)
bool Core_SessionOpen()
  {
   const datetime now = TimeCurrent();
   const datetime sec = now % 86400;
   MqlDateTime t;
   TimeToStruct(now, t);
   datetime from, to;
   uint i = 0;
   for(; SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)t.day_of_week, i, from, to); i++)
      if(from < to ? (sec >= from && sec < to) : (sec >= from || sec < to))
         return(true);
   return(i == 0);
  }

string SessionText()
  {
   const string days[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
   string txt = "";
   for(int d = 1; d <= 5; d++)
     {
      txt += (d > 1 ? " | " : "") + days[d];
      datetime from, to;
      uint i = 0;
      for(; SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)d, i, from, to); i++)
         txt += StringFormat(" %s-%s", TimeToString(from, TIME_MINUTES), TimeToString(to, TIME_MINUTES));
      if(i == 0)
         txt += " none listed (open)";
     }
   return(txt);
  }

double LockValue() { return((double)(ChartID() % 1000000000000 + 1)); }   // exact in a double

//--- live: the current bar had quotes before this instance loaded (fresh attach, re-attach, restart mid-bar). The load
//--- moment is kept in GMT (OS clock, valid before login) and moved to server time here, once quotes flow. A bar that
//--- began quoting only after the load (the 00:00 H4/H6 bar during the daily break) is not late.
bool Core_LateBar()
  {
   if(g_loadGMT == 0)
      return(false);
   const long     offset = (long)MathRound(((long)TimeTradeServer() - (long)TimeGMT()) / 900.0) * 900;
   const datetime load   = (datetime)((long)g_loadGMT + offset);
   const datetime bar    = Core_CurrentBar();
   return(bar < load && Bars(_Symbol, PERIOD_M1, bar, load - 1) > 0);
  }

void Core_MarkBar(const datetime bar)
  {
   g_lastBarTime = bar;
   GlobalVariableSet(g_gvLastBar, (double)bar);
  }

//+------------------------------------------------------------------+
//| Diagnostics                                                      |
//+------------------------------------------------------------------+
string TradePermissionText()
  {
   return(StringFormat("terminal=%s program=%s account=%s expert=%s connected=%s",
          TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ? "on" : "OFF",
          MQLInfoInteger(MQL_TRADE_ALLOWED)          ? "on" : "OFF",
          AccountInfoInteger(ACCOUNT_TRADE_ALLOWED)  ? "on" : "OFF",
          AccountInfoInteger(ACCOUNT_TRADE_EXPERT)   ? "on" : "OFF",
          TerminalInfoInteger(TERMINAL_CONNECTED)    ? "yes" : "NO"));
  }

void Core_LogBar(const datetime bar, const string detail)
  {
   if(!InpLogEveryBar)
      return;
   PrintFormat("Bar %s | %s | own positions %d | trading %s | %s",
               TimeToString(bar, TIME_DATE | TIME_MINUTES), detail, CountOwnPositions(),
               TradePermissionText(), GuardStatus());
  }

//+------------------------------------------------------------------+
//| Positions                                                        |
//+------------------------------------------------------------------+
bool IsOwnPosition()
  {
   return(PositionGetInteger(POSITION_MAGIC) == (long)InpMagic &&
          PositionGetString(POSITION_SYMBOL) == _Symbol);
  }

int CountOwnPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
      if(PositionGetTicket(i) != 0 && IsOwnPosition())
         count++;
   return(count);
  }

bool Core_SelectOwnPosition(ulong &ticket)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      const ulong t = PositionGetTicket(i);
      if(t != 0 && IsOwnPosition())
        {
         ticket = t;
         return(true);
        }
     }
   return(false);
  }

bool Core_ClosePosition(const ulong ticket, const string reason)
  {
   if(!PositionSelectByTicket(ticket))
      return(false);
   const int n = ArraySize(g_forced);
   ArrayResize(g_forced, n + 1, 16);
   g_forced[n].position = (ulong)PositionGetInteger(POSITION_IDENTIFIER);
   g_forced[n].reason   = reason;
   if(g_trade.PositionClose(ticket))
      return(true);
   if(!CloseQueued(ticket))
     {
      const int k = ArraySize(g_closeRetry);
      ArrayResize(g_closeRetry, k + 1, 8);
      g_closeRetry[k] = ticket;
     }
   if(GetTickCount() - g_lastCloseFailMsg > 60000)
     {
      g_lastCloseFailMsg = GetTickCount();
      PrintFormat("Close #%I64u (%s) failed: %d %s -- retrying every tick", ticket, reason,
                  g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
     }
   return(false);
  }

bool CloseQueued(const ulong ticket)
  {
   for(int i = ArraySize(g_closeRetry) - 1; i >= 0; i--)
      if(g_closeRetry[i] == ticket)
         return(true);
   return(false);
  }

//--- re-send closes that failed (requote, no connection, session closed) until the position is gone
void RetryCloses()
  {
   for(int i = ArraySize(g_closeRetry) - 1; i >= 0; i--)
     {
      const ulong ticket = g_closeRetry[i];
      if(!PositionSelectByTicket(ticket))
         ArrayRemove(g_closeRetry, i, 1);
      else if(!g_trade.PositionClose(ticket) && GetTickCount() - g_lastCloseFailMsg > 60000)
        {
         g_lastCloseFailMsg = GetTickCount();
         PrintFormat("Close #%I64u retry failed: %d %s -- retrying every tick", ticket,
                     g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
        }
     }
  }

bool TradingAllowed()
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED) ||
      !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) || !AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
     {
      Print("Trading is not allowed (terminal/account/EA settings)");
      return(false);
     }
   if(g_symbol.TradeMode() == SYMBOL_TRADE_MODE_DISABLED || g_symbol.TradeMode() == SYMBOL_TRADE_MODE_CLOSEONLY)
     {
      Print("Trading disabled for symbol ", _Symbol);
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Entry                                                            |
//+------------------------------------------------------------------+
double CalculateLots(const double slDistance, const ENUM_ORDER_TYPE orderType, const double price)
  {
   if(slDistance <= 0.0)
      return(0.0);
   double riskMoney = (InpRiskMode == RISK_MONEY) ? InpRiskValue
                      : AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskValue / 100.0;
   const double throttle = ThrottleFactor();                         // AccountThrottle.mqh (spec 2026-10-22-dd-reduction)
   if(throttle < 1.0)
      PrintFormat("AccountThrottle: account drawdown >= %.1f%% of the initial deposit - risk x %.2f", InpThrottleDDPct, throttle);
   riskMoney *= throttle;
   if(riskMoney <= 0.0)
      return(0.0);
   double tickSize  = g_symbol.TickSize();
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);   // live: CSymbolInfo caches it at Core_Init, and it moves with the quote currency (JPY, CHF)
   if(tickSize <= 0.0 || tickValue <= 0.0)
      return(0.0);
   double lossPerLot = slDistance / tickSize * tickValue;
   if(lossPerLot <= 0.0)
      return(0.0);
   double lots = riskMoney / lossPerLot;
   const double step   = g_symbol.LotsStep();
   const double minLot = g_symbol.LotsMin();
   const double maxLot = g_symbol.LotsMax();
   if(step <= 0.0)
      return(0.0);
   lots = MathFloor(lots / step) * step;
   if(lots > maxLot) lots = maxLot;
   if(lots < minLot) return(0.0);        // never exceed configured risk
   double margin = 0.0;
   if(!OrderCalcMargin(orderType, _Symbol, lots, price, margin))
      return(0.0);
   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 0.95;
   if(margin > freeMargin && margin > 0.0)
     {
      lots = MathFloor(lots * freeMargin / margin / step) * step;
      if(lots < minLot)
         return(0.0);
     }
   const int volDigits = (int)MathRound(-MathLog10(step));
   return(NormalizeDouble(lots, volDigits));
  }

bool Core_Open(const ENUM_POSITION_TYPE type, const double slDistance, const double tpPrice)
  {
   if(!TradingAllowed() || !g_symbol.RefreshRates())
      return(false);
   string why;
   if(!GuardsAllowEntry(why))
     {
      PrintFormat("Signal skipped, %s", why);
      return(false);
     }
   if(Core_LateBar())
     {
      PrintFormat("Signal skipped, late signal: bar %s had quotes before the EA was loaded (%s GMT)",
                  TimeToString(Core_CurrentBar(), TIME_DATE | TIME_MINUTES), TimeToString(g_loadGMT, TIME_DATE | TIME_SECONDS));
      return(false);
     }
   if(InpMaxSpreadPoints > 0 && g_symbol.Spread() > InpMaxSpreadPoints)
     {
      if(InpSpreadWaitMin > 0 && g_pendingType < 0)
        {
         g_pendingType  = (int)type;
         g_pendingBar   = Core_CurrentBar();
         g_pendingSince = TimeCurrent();
         g_pendingSL   = slDistance;
         g_pendingTP   = tpPrice;
         PrintFormat("Signal delayed, spread %d > %d points -- retrying for up to %d min",
                     g_symbol.Spread(), InpMaxSpreadPoints, InpSpreadWaitMin);
        }
      else if(InpSpreadWaitMin <= 0)
         PrintFormat("Signal skipped, spread %d > %d points", g_symbol.Spread(), InpMaxSpreadPoints);
      return(false);
     }

   const int    digits  = g_symbol.Digits();
   const double minDist = (double)g_symbol.StopsLevel() * g_symbol.Point();
   const bool   isBuy   = (type == POSITION_TYPE_BUY);
   const double price   = isBuy ? g_symbol.Ask() : g_symbol.Bid();
   const double slDist  = MathMax(slDistance, minDist);
   const double sl      = NormalizeDouble(isBuy ? price - slDist : price + slDist, digits);
   double tp = 0.0;
   if(tpPrice > 0.0)
     {
      const bool valid = isBuy ? (tpPrice > price && tpPrice - price >= minDist)
                               : (tpPrice < price && price - tpPrice >= minDist);
      if(!valid)
        {
         PrintFormat("Signal skipped, take-profit %s is not beyond entry price %s",
                     DoubleToString(tpPrice, digits), DoubleToString(price, digits));
         return(false);
        }
      tp = NormalizeDouble(tpPrice, digits);
     }

   const double lots = CalculateLots(MathAbs(price - sl), isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, price);
   if(lots <= 0.0)
     {
      Print("Signal skipped, lot calculation returned 0 (risk too small or insufficient margin)");
      return(false);
     }
   const bool ok = isBuy ? g_trade.Buy (lots, _Symbol, price, sl, tp, InpComment)
                         : g_trade.Sell(lots, _Symbol, price, sl, tp, InpComment);
   const uint rc = g_trade.ResultRetcode();
   if(!ok || (rc != TRADE_RETCODE_DONE && rc != TRADE_RETCODE_PLACED))
     {
      PrintFormat("%s failed: %d %s", isBuy ? "Buy" : "Sell", rc, g_trade.ResultRetcodeDescription());
      return(false);
     }
   const double fill = g_trade.ResultPrice();
   const int    n    = ArraySize(g_entries);
   ArrayResize(g_entries, n + 1, 64);
   g_entries[n].position = g_trade.ResultOrder();
   g_entries[n].spread   = g_symbol.Spread();
   g_entries[n].slippage = (fill > 0.0) ? (isBuy ? fill - price : price - fill) / g_symbol.Point() : 0.0;
   double perLot = 0.0;
   g_entries[n].risk = (OrderCalcProfit(isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, lots, price, sl, perLot)
                        && perLot < 0.0) ? -perLot : 0.0;
   return(true);
  }

void Core_RetryPending(const datetime barTime)
  {
   if(g_pendingType < 0)
      return;
   if(barTime != g_pendingBar || TimeCurrent() - g_pendingSince > InpSpreadWaitMin * 60)
     {
      PrintFormat("Delayed %s signal dropped, spread stayed above %d points",
                  g_pendingType == POSITION_TYPE_BUY ? "BUY" : "SELL", InpMaxSpreadPoints);
      g_pendingType = -1;
      return;
     }
   if(!g_symbol.RefreshRates() || g_symbol.Spread() > InpMaxSpreadPoints)
      return;
   const ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)g_pendingType;
   g_pendingType = -1;
   if(CountOwnPositions() > 0)
      return;
   PrintFormat("Spread back to %d points, executing delayed %s signal", g_symbol.Spread(),
               type == POSITION_TYPE_BUY ? "BUY" : "SELL");
   Core_Open(type, g_pendingSL, g_pendingTP);
  }

//+------------------------------------------------------------------+
//| Loss stops                                                       |
//+------------------------------------------------------------------+
double BalanceAt(const datetime t)
  {
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   if(!HistorySelect(t, TimeCurrent() + 86400))
      return(bal);
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      const ulong d = HistoryDealGetTicket(i);
      const long  k = HistoryDealGetInteger(d, DEAL_TYPE);
      if(d != 0 && k != DEAL_TYPE_BALANCE && k != DEAL_TYPE_CREDIT)
         bal -= HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) +
                HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
     }
   return(bal);
  }

void UpdatePeriodBalances()
  {
   const long login = AccountInfoInteger(ACCOUNT_LOGIN);
   if(login != g_guardLogin)
     {
      g_guardLogin   = login;          // account switched: the cached balances belong to the old account
      g_dayStart     = 0;
      g_dayBalance   = 0.0;
      g_monthStart   = 0;
      g_monthBalance = 0.0;
     }
   if(!MQLInfoInteger(MQL_TESTER) && !TerminalInfoInteger(TERMINAL_CONNECTED))
      return;                          // balance and history may still be the previous account's
   const datetime now = TimeCurrent();
   const datetime day = now - now % 86400;
   if(day != g_dayStart)
     {
      g_dayStart   = day;
      g_dayBalance = BalanceAt(day);
      g_dayStopHit = false;
     }
   MqlDateTime t;
   TimeToStruct(now, t);
   t.day = 1; t.hour = 0; t.min = 0; t.sec = 0;
   const datetime month = StructToTime(t);
   if(month != g_monthStart)
     {
      g_monthStart   = month;
      g_monthBalance = BalanceAt(month);
     }
  }

double DailyFloor()     { return(g_dayBalance   * (1.0 - InpDailyLossPct   / 100.0)); }
double MonthlyFloor()   { return(g_monthBalance * (1.0 - InpMonthlyLossPct / 100.0)); }
bool   DailyStopped()   { return(InpDailyLossPct   > 0.0 && AccountInfoDouble(ACCOUNT_EQUITY) <= DailyFloor()); }
bool   MonthlyStopped() { return(InpMonthlyLossPct > 0.0 && AccountInfoDouble(ACCOUNT_EQUITY) <= MonthlyFloor()); }

string GuardStatus()
  {
   const double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   return(StringFormat("guards %s | day %+.2f%% (stop -%.1f%%) | month %+.2f%% (stop -%.1f%%)",
                       g_dayStopHit || DailyStopped() ? "DAILY STOP" : MonthlyStopped() ? "MONTHLY STOP" : "ok",
                       g_dayBalance   > 0.0 ? 100.0 * (eq / g_dayBalance   - 1.0) : 0.0, InpDailyLossPct,
                       g_monthBalance > 0.0 ? 100.0 * (eq / g_monthBalance - 1.0) : 0.0, InpMonthlyLossPct));
  }

void Core_OnTickStart()
  {
   if(!g_logCaughtUp)
      LogCatchUp();
   const bool open = Core_SessionOpen();   // a close sent before the session opens only fails (IC gold 01:00-01:02)
   if(open)
      RetryCloses();
   UpdatePeriodBalances();
   if(!DailyStopped() && !g_dayStopHit)
      return;
   if(!g_dayStopHit)
     {
      g_dayStopHit = true;
      PrintFormat("DAILY STOP: equity %.2f <= floor %.2f (-%.1f%% of day start %.2f) -- closing own positions, no entries until next server day",
                  AccountInfoDouble(ACCOUNT_EQUITY), DailyFloor(), InpDailyLossPct, g_dayBalance);
     }
   if(!open)
      return;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = PositionGetTicket(i);
      if(ticket != 0 && IsOwnPosition() && !CloseQueued(ticket))   // a queued close was re-sent by RetryCloses
         Core_ClosePosition(ticket, "daily_stop");
     }
  }

bool GuardsAllowEntry(string &why)
  {
   why = "";
   if(g_dayStopHit || DailyStopped())
      why = StringFormat("daily loss stop hit today (equity %.2f, floor %.2f)", AccountInfoDouble(ACCOUNT_EQUITY), DailyFloor());
   else if(MonthlyStopped())
      why = StringFormat("monthly loss stop (equity %.2f <= %.2f)", AccountInfoDouble(ACCOUNT_EQUITY), MonthlyFloor());
   return(why == "");
  }

//+------------------------------------------------------------------+
//| Closed-trade CSV log                                             |
//+------------------------------------------------------------------+
void LogInit()
  {
   g_logFile        = "";
   g_lastLoggedDeal = 0;
   g_logCaughtUp    = true;
   if(!InpTradeLog || MQLInfoInteger(MQL_OPTIMIZATION))
      return;
   const bool tester = (bool)MQLInfoInteger(MQL_TESTER);
   g_logFlags = tester ? FILE_COMMON : 0;
   const string name = StringFormat("%s_%s_%I64u_%s_trades.csv", EA_NAME, _Symbol, InpMagic,
                                    tester ? "tester" : IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)));
   if(tester)
      FileDelete(name, g_logFlags);
   const int h = FileOpen(name, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI | g_logFlags);
   if(h == INVALID_HANDLE)
     {
      PrintFormat("Trade log: cannot open %s, error %d -- logging off", name, GetLastError());
      return;
     }
   if(FileSize(h) == 0)
      FileWriteString(h, TRADE_LOG_HEADER);
   else if(!tester)
      g_lastLoggedDeal = LastLoggedDeal(h);
   FileClose(h);
   g_logFile     = name;
   g_logCaughtUp = tester;
  }

//--- deal ticket of the file's last row (0 for a header-only file)
ulong LastLoggedDeal(const int h)
  {
   string last = "";
   FileSeek(h, 0, SEEK_SET);
   while(!FileIsEnding(h))
     {
      const string line = FileReadString(h);
      if(line != "")
         last = line;
     }
   string f[];
   return(StringSplit(last, ',', f) == 21 ? (ulong)StringToInteger(f[18]) : 0);
  }

//--- log every closing deal newer than the last one written (own symbol and magic only, see LogClosingDeal)
void LogCatchUp()
  {
   g_logCaughtUp = true;
   if(g_logFile == "" || !HistorySelect(0, TimeCurrent() + 86400))
      return;
   ulong pending[];
   for(int i = 0; i < HistoryDealsTotal(); i++)
     {
      const ulong d = HistoryDealGetTicket(i);
      if(d > g_lastLoggedDeal)
        {
         const int n = ArraySize(pending);
         ArrayResize(pending, n + 1, 16);
         pending[n] = d;
        }
     }
   ArraySort(pending);
   const bool live = !MQLInfoInteger(MQL_TESTER);   // tester: the end-of-test close, logged as it happens
   for(int i = 0; i < ArraySize(pending); i++)
      LogClosingDeal(pending[i], live);
  }

//--- account balance right after a deal: today's balance minus everything booked after it (credit is not balance)
double BalanceAfter(const ulong deal)
  {
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   if(!HistorySelect(0, TimeCurrent() + 86400))
      return(bal);
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      const ulong d = HistoryDealGetTicket(i);
      if(d > deal && HistoryDealGetInteger(d, DEAL_TYPE) != DEAL_TYPE_CREDIT)
         bal -= HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) +
                HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
     }
   return(bal);
  }

string ReasonName(const long reason, const ulong pos)
  {
   for(int i = ArraySize(g_forced) - 1; i >= 0; i--)
      if(g_forced[i].position == pos)
         return(g_forced[i].reason);
   switch((int)reason)
     {
      case DEAL_REASON_SL:     return("sl");
      case DEAL_REASON_TP:     return("tp");
      case DEAL_REASON_SO:     return("stop_out");
      case DEAL_REASON_EXPERT: return("expert");
      case DEAL_REASON_CLIENT: return(MQLInfoInteger(MQL_TESTER) ? "end_of_test" : "manual");
      case DEAL_REASON_MOBILE:
      case DEAL_REASON_WEB:    return("manual");
     }
   return("other");
  }

void LogClosingDeal(const ulong deal, const bool caughtUp = false)
  {
   if(g_logFile == "" || deal <= g_lastLoggedDeal || !HistoryDealSelect(deal))
      return;                                       // written already: the catch-up and the trade event can both see a deal
   if(HistoryDealGetInteger(deal, DEAL_ENTRY) != DEAL_ENTRY_IN)
      g_lastLoggedDeal = deal;
   const long entry = HistoryDealGetInteger(deal, DEAL_ENTRY);
   if(entry != DEAL_ENTRY_OUT && entry != DEAL_ENTRY_INOUT && entry != DEAL_ENTRY_OUT_BY)
      return;
   if(HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol)
      return;
   const datetime closeTime = (datetime)HistoryDealGetInteger(deal, DEAL_TIME);
   const ulong    pos    = (ulong)HistoryDealGetInteger(deal, DEAL_POSITION_ID);
   const bool     wasBuy = (HistoryDealGetInteger(deal, DEAL_TYPE) == DEAL_TYPE_SELL);
   const double   vol    = HistoryDealGetDouble(deal, DEAL_VOLUME);
   const double   px     = HistoryDealGetDouble(deal, DEAL_PRICE);
   const double   gross  = HistoryDealGetDouble(deal, DEAL_PROFIT);
   const double   swap   = HistoryDealGetDouble(deal, DEAL_SWAP);
   const double   outFee = HistoryDealGetDouble(deal, DEAL_COMMISSION) + HistoryDealGetDouble(deal, DEAL_FEE);
   const double   sl     = HistoryDealGetDouble(deal, DEAL_SL);
   const double   tp     = HistoryDealGetDouble(deal, DEAL_TP);
   const string   reason = ReasonName(HistoryDealGetInteger(deal, DEAL_REASON), pos);

   if(!HistorySelectByPosition(pos))
      return;
   datetime openTime = 0;
   long     inMagic  = -1;
   ulong    inDeal   = 0;
   double   inVol = 0.0, inPxVol = 0.0, inFee = 0.0;
   for(int i = 0; i < HistoryDealsTotal(); i++)
     {
      const ulong d = HistoryDealGetTicket(i);
      if(d == 0 || HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_IN)
         continue;
      const double v = HistoryDealGetDouble(d, DEAL_VOLUME);
      if(openTime == 0)
        {
         openTime = (datetime)HistoryDealGetInteger(d, DEAL_TIME);
         inMagic  = HistoryDealGetInteger(d, DEAL_MAGIC);
         inDeal   = d;
        }
      inVol   += v;
      inPxVol += HistoryDealGetDouble(d, DEAL_PRICE) * v;
      inFee   += HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
     }
   if(inMagic != (long)InpMagic || inVol <= 0.0)
      return;
   const double share = MathMin(vol / inVol, 1.0);
   const double comm  = outFee + inFee * share;
   const double net   = gross + swap + comm;
   const int    dg    = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   string spread = "", slip = "", rMult = "";
   for(int i = ArraySize(g_entries) - 1; i >= 0; i--)
      if(g_entries[i].position == pos)
        {
         spread = IntegerToString(g_entries[i].spread);
         slip   = DoubleToString(g_entries[i].slippage, 1);
         if(g_entries[i].risk > 0.0)
            rMult = DoubleToString(net / (g_entries[i].risk * share), 3);
         break;
        }
   double perLot = 0.0, inSL = HistoryDealGetDouble(inDeal, DEAL_SL);
   if(rMult == "" && inSL > 0.0 &&                 // entry not seen by this instance (restart, catch-up): risk from its stop
      OrderCalcProfit(wasBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, inVol, inPxVol / inVol, inSL, perLot) && perLot < 0.0)
      rMult = DoubleToString(net / (-perLot * share), 3);
   const double balance = caughtUp ? BalanceAfter(deal) : AccountInfoDouble(ACCOUNT_BALANCE);
   const int h = FileOpen(g_logFile, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI | g_logFlags);
   if(h == INVALID_HANDLE)
     {
      PrintFormat("Trade log write failed, error %d", GetLastError());
      return;
     }
   FileSeek(h, 0, SEEK_END);
   FileWriteString(h, StringFormat("%s,%s,%s,%s,%.2f,%s,%s,%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%s,%s,%s,%s,%I64u,%I64u,%I64u\n",
                   TimeToString(closeTime, TIME_DATE | TIME_SECONDS), TimeToString(openTime, TIME_DATE | TIME_SECONDS),
                   _Symbol, wasBuy ? "buy" : "sell", vol, DoubleToString(inPxVol / inVol, dg), DoubleToString(px, dg),
                   DoubleToString(sl, dg), DoubleToString(tp, dg), gross, comm, swap, net,
                   balance, rMult, reason, spread, slip, deal, pos, InpMagic));
   FileClose(h);
  }

void Core_OnTradeTransaction(const MqlTradeTransaction &trans)
  {
   if(trans.type != TRADE_TRANSACTION_DEAL_ADD || trans.deal == 0)
      return;
   if(!g_logCaughtUp)
      LogCatchUp();
   LogClosingDeal(trans.deal);
//--- live: an entry on this magic and symbol that this instance did not send (second terminal on the account)
   if(MQLInfoInteger(MQL_TESTER) || !HistoryDealSelect(trans.deal) ||
      HistoryDealGetInteger(trans.deal, DEAL_ENTRY) != DEAL_ENTRY_IN ||
      HistoryDealGetInteger(trans.deal, DEAL_MAGIC) != (long)InpMagic || HistoryDealGetString(trans.deal, DEAL_SYMBOL) != _Symbol)
      return;
   const ulong order = (ulong)HistoryDealGetInteger(trans.deal, DEAL_ORDER);
   for(int i = ArraySize(g_entries) - 1; i >= 0; i--)
      if(g_entries[i].position == order)
         return;
   const string msg = StringFormat("%s %s magic %I64u: order #%I64u was not sent by this instance -- another chart or terminal trades this magic on the account",
                                   EA_NAME, _Symbol, InpMagic, order);
   Print(msg);
   Alert(msg);
  }

//--- custom optimization criterion ("Custom max"), same as MACD_Cross_EA
double Core_OnTester()
  {
   const double trades = TesterStatistics(STAT_TRADES);
   if(trades < 30)
      return(0.0);
   const double profit = TesterStatistics(STAT_PROFIT);
   if(profit <= 0.0)
      return(0.0);
   return(profit * TesterStatistics(STAT_PROFIT_FACTOR) / (1.0 + TesterStatistics(STAT_EQUITY_DDREL_PERCENT)));
  }
//+------------------------------------------------------------------+

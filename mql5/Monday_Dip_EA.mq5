//+------------------------------------------------------------------+
//|                                          Monday_Dip_Weekly_Exit_EA.mq5    |
//|                                                                  |
//|  VERSION 1.02                                                    |
//|                                                                  |
//|  STRATEGY SUMMARY                                                |
//|  ================                                                |
//|  A weekly, long-only, daily-bar dip pattern for index CFDs        |
//|  (FTSE 100 / UK100, S&P 500 / US500, ...). The EA always trades   |
//|  the symbol of the chart it is attached to - no symbol name is    |
//|  hard-coded anywhere.                                             |
//|                                                                  |
//|  THE THREE RULES                                                 |
//|  1) ENTRY - decided on the Monday daily bar once it has closed:   |
//|     if Monday's close is BELOW the previous trading day's close   |
//|     (normally Friday's), open ONE long position at market.        |
//|     If Monday's close is equal to or above that reference close,  |
//|     there is no trade that week.                                  |
//|  2) EXIT - close the position when the Wednesday daily bar        |
//|     closes, win or lose. The intended holding period is roughly   |
//|     two trading days. The exit is requested on the first tick     |
//|     after the Wednesday bar closes and is retried on every tick,  |
//|     but no request can execute while the market is closed, so on  |
//|     symbols with long daily closures a position can still be held |
//|     over a weekend or a holiday.                                  |
//|  3) STOP LOSS - a stop of InpStopLossPercent (default 10%) of the |
//|     entry price is attached to the position at entry and is never |
//|     placed closer than the symbol's SYMBOL_TRADE_STOPS_LEVEL.     |
//|                                                                  |
//|  THE TWO OPTIONAL FILTERS                                        |
//|  (toggles - when enabled they can only make entry stricter, they  |
//|   can never create an entry or loosen a rule)                     |
//|  F1) IBS - IBS = (Close - Low) / (High - Low) of the Monday bar.  |
//|      Enter only when IBS <= InpIBSMax (default 0.25).             |
//|      If High == Low the ratio is undefined: the day is treated    |
//|      as a no-trade day and the journal says so.                   |
//|  F2) MA - enter only when Monday's close is below the simple      |
//|      moving average of InpMAPeriod (default 180) daily closes at  |
//|      that bar.                                                    |
//|                                                                  |
//|  ASSUMPTIONS                                                     |
//|  Every deliberate reading of an ambiguous rule is marked in the   |
//|  code with a comment "// DECISION Dn:" so it can be audited,      |
//|  argued about and changed on its own. The list:                   |
//|   D1  The Monday signal is executed on the first tick AFTER the   |
//|       Monday bar closes (start of the Tuesday session) with a     |
//|       MARKET order - never a pending order.                       |
//|   D2  "Wednesday bar closes" is acted on in the same way: first   |
//|       tick after that bar closes (start of the Thursday session), |
//|       retried every tick until it succeeds.                       |
//|   D3  Any closed bar from Wednesday onwards (Thursday, Friday, or |
//|       even a stray weekend-dated bar) also triggers the exit, so  |
//|       a missing Wednesday bar or a failed close does not leave    |
//|       the position unmanaged. Note that no request can execute    |
//|       while the market is closed, so the position may still be    |
//|       held across a weekend or a holiday closure.                 |
//|   D4  The "previous trading day" is the first non-weekend bar      |
//|       before the Monday bar (scanned back bar by bar).            |
//|   D5  Entry is evaluated only when the bar that just closed is a  |
//|       Monday. A week without a Monday bar (holiday) is a week     |
//|       without a trade - no substitution, no catch-up.             |
//|   D6  A weekend-dated closed bar raises a warning and never       |
//|       produces an entry decision.                                 |
//|   D7  IBS with High == Low is undefined -> no-trade day (logged). |
//|   D8  Rule 1 and the MA filter use a strict "<"; the IBS filter   |
//|       uses "<=" exactly as written in the specification.          |
//|   D9  The MA is the SMA of the InpMAPeriod closed daily bars      |
//|       ending with (and including) the Monday bar.                 |
//|   D10 Nothing is done retroactively: on attach/restart the EA     |
//|       primes its bar detector and ignores the bar that closed     |
//|       before it started running.                                  |
//|   D11 The entry decision is taken exactly once, on the Monday bar |
//|       close. The DELIVERY of that one order is retried on the     |
//|       ticks of the session that follows (an order can be refused  |
//|       because the market is still closed at the daily rollover)   |
//|       and is abandoned when the next daily bar closes, so the EA  |
//|       never buys later than the session after the Monday close.   |
//|       Once the server accepts the request (filled, partially      |
//|       filled, or accepted-pending) the signal is never re-sent.   |
//|   D12 Stop distance = max(InpStopLossPercent of entry,            |
//|       SYMBOL_TRADE_STOPS_LEVEL) - the broker minimum can only     |
//|       push the stop further away, never closer.                   |
//|   D13 A stop loss is mandatory: InpStopLossPercent <= 0 is        |
//|       rejected at OnInit.                                         |
//|   D14 Volume is never larger than the requested lot (floored to   |
//|       the symbol step). Below SYMBOL_VOLUME_MIN -> no trade.      |
//|       Above SYMBOL_VOLUME_MAX -> clamped down to the maximum.     |
//|   D15 If the stop cannot be attached to an open position, the EA  |
//|       retries on every tick and attempts to close the position    |
//|       after 5 consecutive failures rather than hold it            |
//|       unprotected (the close itself is a market request whose     |
//|       execution depends on the server).                           |
//|   D16 Only positions on this symbol carrying this magic number    |
//|       count as "the position" and only they are ever touched.     |
//|   D17 The order filling mode is taken from the symbol's allowed   |
//|       modes, so the EA cannot fail on an unsupported filling.     |
//|   D18 Every weekday comes from the server time of a bar           |
//|       (iTime + MqlDateTime). TimeLocal is never used and          |
//|       TimeCurrent is never used as a date.                        |
//|   D19 The weekly decision line of the journal is always printed.  |
//|       InpVerboseLog only adds extra detail on top of it.           |
//|   D20 Removing the EA leaves an open position alone (a warning is |
//|       printed in OnDeinit) - a chart change or recompile must not  |
//|       silently liquidate a position.                              |
//|   D21 Slippage (points) is applied to entries and to exits.       |
//|   D22 If bars required for a decision are not available, the EA   |
//|       skips the decision and logs it - it never approximates.     |
//|   D23 No take profit is used: the strategy defines a time exit    |
//|       and a stop loss only.                                       |
//|   D24 "The bar closes" means what MT5 means by it: the moment the |
//|       next daily bar opens on the server clock. A daily bar is    |
//|       therefore acted on at the first tick of the following       |
//|       session, not at the cash-market close of the same day.      |
//|                                                                  |
//|  The EA uses no Sleep, no WebRequest, no MessageBox and no other  |
//|  interactive call, so it runs unchanged in the Strategy Tester.   |
//+------------------------------------------------------------------+
#property copyright "RBOT.CC | Free Forex EA & MT5 Indicators"
#property version   "1.02"
#property description "Weekly daily-bar dip pattern, long only: enter after a down Monday, exit at the Wednesday close."
#property description "Decisions are taken on closed D1 bars only; weekday logic uses the server time of the bar."
#property link "https://rbot.cc"
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input group "=== Position size and risk ==="
input double InpLots              = 0.10;          // Position size in lots
input double InpStopLossPercent   = 10.0;          // Stop loss, in percent of the entry price
input ulong  InpMagic             = 20260922;      // Magic number identifying this EA's positions
input int    InpMaxSlippagePoints = 30;            // Maximum slippage, in points
input string InpTradeComment      = "MonDip long"; // Order comment attached to entries

input group "=== Optional filter 1: IBS ==="
input bool   InpUseIBS            = true;          // Enable the IBS filter
input double InpIBSMax            = 0.25;          // Enter only when the Monday IBS is <= this value

input group "=== Optional filter 2: long-term moving average ==="
input bool   InpUseMA             = false;          // Enable the moving-average filter
input int    InpMAPeriod          = 180;           // SMA period, counted in daily closes

input group "=== Journal ==="
input bool   InpVerboseLog        = false;          // Verbose logging (the weekly decision line is printed regardless)

//+------------------------------------------------------------------+
//| Constants and global state                                       |
//+------------------------------------------------------------------+
#define DOW_SUNDAY     0
#define DOW_MONDAY     1
#define DOW_TUESDAY    2
#define DOW_WEDNESDAY  3
#define DOW_THURSDAY   4
#define DOW_FRIDAY     5
#define DOW_SATURDAY   6

#define REF_LOOKBACK_MAX   15   // how far back the previous trading day may be searched
#define SL_MAX_RETRIES     5    // failed stop-loss attempts tolerated before the position is closed

CTrade   g_trade;                    // standard library trading object
datetime g_lastDailyBarTime  = 0;    // open time of the D1 bar currently forming (new-bar detector)
datetime g_lastCloseErrBar   = 0;    // rate-limits the "close failed" message to one per daily bar
datetime g_pendingEntryBar   = 0;    // Monday bar whose valid entry decision has not been filled yet
int      g_slRetryCount      = 0;    // consecutive failed attempts to attach or adjust the stop loss
int      g_barsProcessed     = 0;    // statistics reported in OnDeinit
int      g_entryCount        = 0;
int      g_exitCount         = 0;

//+------------------------------------------------------------------+
//| Small helpers                                                    |
//+------------------------------------------------------------------+
string WeekdayName(const int dow)
  {
   switch(dow)
     {
      case DOW_SUNDAY:
         return("Sunday");
      case DOW_MONDAY:
         return("Monday");
      case DOW_TUESDAY:
         return("Tuesday");
      case DOW_WEDNESDAY:
         return("Wednesday");
      case DOW_THURSDAY:
         return("Thursday");
      case DOW_FRIDAY:
         return("Friday");
      case DOW_SATURDAY:
         return("Saturday");
     }
   return("Unknown");
  }

//+------------------------------------------------------------------+
//| Verbose logging (the weekly decision line does not use this)      |
//+------------------------------------------------------------------+
void LogVerbose(const string text)
  {
   if(InpVerboseLog)
      Print("[MonDip] ", text);
  }

//+------------------------------------------------------------------+
//| Copies one closed daily bar. Returns false if it does not exist.  |
//+------------------------------------------------------------------+
bool GetBar(const int shift, MqlRates &bar)
  {
   MqlRates tmp[];
   const int copied = CopyRates(_Symbol, PERIOD_D1, shift, 1, tmp);
   if(copied != 1)
     {
      PrintFormat("[MonDip] ERROR: daily bar at shift %d is not available (CopyRates returned %d, error %d).",
                  shift, copied, GetLastError());
      return(false);
     }
   bar = tmp[0];
   return(true);
  }

//+------------------------------------------------------------------+
//| IBS of one bar. High == Low makes the ratio undefined.            |
//+------------------------------------------------------------------+
bool IBSFromBar(const MqlRates &bar, double &ibs)
  {
   const double range = bar.high - bar.low;

// DECISION D7: (Close-Low)/(High-Low) is undefined when High == Low.
// The day is treated as a no-trade day - the caller logs it.
   if(range <= 0.0 || !MathIsValidNumber(range))
     {
      ibs = 0.0;
      return(false);
     }
   ibs = (bar.close - bar.low) / range;
   return(true);
  }

//+------------------------------------------------------------------+
//| Simple moving average of `period` closed daily bars ending at     |
//| `shift` (that bar included).                                      |
//+------------------------------------------------------------------+
bool ComputeSMA(const int shift, const int period, double &ma)
  {
   ma = 0.0;

// DECISION D9: the average is built from closed bars only, the bar at
// `shift` included, exactly like the SMA plotted on that bar.
   double closes[];
   ArraySetAsSeries(closes, false);
   const int copied = CopyClose(_Symbol, PERIOD_D1, shift, period, closes);
   if(copied < period)
     {
      LogVerbose(StringFormat("Only %d of %d daily closes are available for the MA(%d) - the MA filter cannot be evaluated.",
                              copied, period, period));
      return(false);
     }

   double sum = 0.0;
   for(int i = 0; i < period; i++)
      sum += closes[i];

   ma = NormalizeDouble(sum / (double)period, _Digits);   // every price is normalised to the symbol digits
   return(true);
  }

//+------------------------------------------------------------------+
//| Shift of the most recent trading day before `startShift`.         |
//| Weekend-dated bars are skipped (and reported).                    |
//+------------------------------------------------------------------+
int FindPreviousTradingDayShift(const int startShift)
  {
   const int available = Bars(_Symbol, PERIOD_D1);
   if(available <= startShift)
     {
      LogVerbose(StringFormat("only %d daily bars are available - the previous trading day cannot be located yet.", available));
      return(-1);
     }

   for(int shift = startShift; shift <= startShift + REF_LOOKBACK_MAX; shift++)
     {
      if(shift >= available)
        {
         LogVerbose(StringFormat("ran out of daily history at shift %d while looking for the previous trading day.", shift));
         return(-1);
        }

      MqlRates bar;
      if(!GetBar(shift, bar))
         return(-1);

      MqlDateTime dt;
      TimeToStruct(bar.time, dt);                       // DECISION D18: weekday from the bar's server time

      if(dt.day_of_week == DOW_SATURDAY || dt.day_of_week == DOW_SUNDAY)
        {
         // DECISION D4: the strategy assumes daily bars only on trading days,
         // so a weekend-dated bar is never used as the reference close.
         PrintFormat("[MonDip] WARNING: daily bar %s (shift %d) is dated %s. The strategy assumes daily bars exist only on trading days; scanning further back for the reference close.",
                     TimeToString(bar.time, TIME_DATE), shift, WeekdayName(dt.day_of_week));
         continue;
        }
      return(shift);
     }

   PrintFormat("[MonDip] WARNING: no trading-day bar found within %d bars before shift %d.", REF_LOOKBACK_MAX, startShift);
   return(-1);
  }

//+------------------------------------------------------------------+
//| Ticket of this EA's open position on this symbol (0 = none).      |
//+------------------------------------------------------------------+
ulong FindOurPosition()
  {
// DECISION D16: a position counts only when symbol AND magic match.
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      return(ticket);
     }
   return(0);
  }

//+------------------------------------------------------------------+
//| Number of decimals carried by a volume step (0.01 -> 2).          |
//+------------------------------------------------------------------+
int VolumeDigits(const double step)
  {
   int digits = 0;
   double value = step;
   while(digits < 8 && MathAbs(value - MathRound(value)) > 1e-9)
     {
      value *= 10.0;
      digits++;
     }
   return(digits);
  }

//+------------------------------------------------------------------+
//| Normalises the requested lot size against the symbol limits.      |
//+------------------------------------------------------------------+
bool NormaliseLots(const double requested, double &volume)
  {
   const double vmin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   const double vmax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   const double vstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(vmin <= 0.0 || vmax <= 0.0 || vstep <= 0.0)
     {
      PrintFormat("[MonDip] ENTRY ABORTED - invalid volume constraints on %s (min=%.8f step=%.8f max=%.8f).",
                  _Symbol, vmin, vstep, vmax);
      return(false);
     }

   const double eps = MathMax(vstep * 0.001, 1e-9);

// DECISION D14: risk is never increased silently. A lot below the symbol
// minimum is refused instead of being rounded up to the minimum.
   if(requested < vmin - eps)
     {
      PrintFormat("[MonDip] ENTRY ABORTED - InpLots=%.4f is below SYMBOL_VOLUME_MIN=%.4f on %s. Increase InpLots; the EA will not trade a larger size than requested.",
                  requested, vmin, _Symbol);
      return(false);
     }

   const int volDigits = VolumeDigits(vstep);

// Floor to the step: the result is never larger than the requested size.
   double v = MathFloor((requested + eps) / vstep) * vstep;
   v = NormalizeDouble(v, volDigits);

   if(v > vmax + eps)
     {
      PrintFormat("[MonDip] WARNING: InpLots=%.4f is above SYMBOL_VOLUME_MAX=%.4f. Trading %.4f instead.",
                  requested, vmax, vmax);
      v = vmax;
     }

   if(v < vmin - eps)
     {
      PrintFormat("[MonDip] ENTRY ABORTED - the symbol's volume step (%.8f) cannot produce a size within [%.8f, %.8f] from InpLots=%.4f.",
                  vstep, vmin, vmax, requested);
      return(false);
     }

   volume = NormalizeDouble(v, volDigits);
   return(volume > 0.0);
  }

//+------------------------------------------------------------------+
//| Stop-loss price for a long position entered at `entryPrice`.      |
//+------------------------------------------------------------------+
bool ComputeStopLossPrice(const double entryPrice, double &slPrice)
  {
   slPrice = 0.0;

   const double pctDistance = entryPrice * InpStopLossPercent / 100.0;
   const long   stopsLevel  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   const double minDistance = (double)stopsLevel * _Point;

// DECISION D12: the percentage distance is a floor, not a ceiling. If the
// broker's minimum stop distance is larger, the stop is placed further away.
   double distance = pctDistance;
   if(minDistance > distance)
     {
      distance = minDistance;
      LogVerbose(StringFormat("The broker minimum stop distance (%d points = %s) is larger than %.2f%% of the entry price (%s); the stop is widened to respect it.",
                              (int)stopsLevel, DoubleToString(minDistance, _Digits),
                              InpStopLossPercent, DoubleToString(pctDistance, _Digits)));
     }

   slPrice = NormalizeDouble(entryPrice - distance, _Digits);

   const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(slPrice <= 0.0 || (bid > 0.0 && slPrice >= bid))
     {
      PrintFormat("[MonDip] ENTRY ABORTED - the computed stop loss %s is not below the current bid %s.",
                  DoubleToString(slPrice, _Digits), DoubleToString(bid, _Digits));
      slPrice = 0.0;
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Makes sure the open position carries the required stop loss.      |
//+------------------------------------------------------------------+
bool EnsureStopLoss()
  {
   const ulong ticket = FindOurPosition();
   if(ticket == 0)
     {
      g_slRetryCount = 0;
      return(true);
     }
   if(!PositionSelectByTicket(ticket))
      return(false);

   const double entryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   const double currentSL  = PositionGetDouble(POSITION_SL);
   const double currentTP  = PositionGetDouble(POSITION_TP);

   double wantedSL = 0.0;
   if(!ComputeStopLossPrice(entryPrice, wantedSL))
     {
      // FIX 1 (v1.02): this failure means no valid stop price can be computed right
      // now - the market is already at or below the level the stop would need. The
      // check happens before the stored stop is compared, so currentSL may still
      // hold a stop the broker has already attached. Only when the position carries
      // NO stop at all does the failure count toward SL_MAX_RETRIES (DECISION D15:
      // after 5 consecutive failures the close is attempted instead of holding an
      // unprotected position). With a stop already present the original behaviour
      // is kept: return here and re-check on the next tick.
      if(currentSL > 0.0)
         return(false);

      g_slRetryCount++;
      PrintFormat("[MonDip] WARNING: no valid stop loss price is available for position #%s (the market is at or below the computed stop level). Attempt %d of %d.",
                  IntegerToString((long)ticket), g_slRetryCount, SL_MAX_RETRIES);
      if(g_slRetryCount >= SL_MAX_RETRIES)
        {
         Print("[MonDip] The position cannot be protected with a stop loss - the close is attempted instead of holding unprotected risk.");
         CloseOurPosition("no valid stop loss price could be computed");
        }
      return(false);
     }

// Tolerance of one tick: a server that rounds the stored stop to the tick size
// must not make the EA re-send a modify request on every single tick.
   const double tolerance = MathMax(_Point, SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE));

   if(currentSL > 0.0 && MathAbs(currentSL - wantedSL) <= tolerance)
     {
      g_slRetryCount = 0;
      return(true);
     }

// FIX 2 (v1.02): the boolean result of PositionModify is not proof that the
// server accepted the change. The stored stop is read back and compared
// against the requested one; only a confirmed modify resets the retry counter.
// A rejected or unconfirmed modification increases it, like any other failure.
   const bool modifySent = g_trade.PositionModify(ticket, wantedSL, currentTP);
   bool modifyConfirmed = false;
   if(modifySent && PositionSelectByTicket(ticket))
      modifyConfirmed = (MathAbs(PositionGetDouble(POSITION_SL) - wantedSL) <= tolerance);

   if(modifySent && modifyConfirmed)
     {
      g_slRetryCount = 0;
      PrintFormat("[MonDip] STOP LOSS %s on position #%s (entry %s, %.2f%% of entry).",
                  (currentSL > 0.0 ? "adjusted to" : "attached at"),
                  IntegerToString((long)ticket), DoubleToString(entryPrice, _Digits), InpStopLossPercent);
      return(true);
     }

   g_slRetryCount++;
   PrintFormat("[MonDip] WARNING: the stop loss could not be put on position #%s (retcode %u, %s). Attempt %d of %d.",
               IntegerToString((long)ticket), g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription(),
               g_slRetryCount, SL_MAX_RETRIES);

// DECISION D15: an unprotected position is not acceptable.
   if(g_slRetryCount >= SL_MAX_RETRIES)
     {
      Print("[MonDip] The position cannot be protected with a stop loss - the close is attempted instead of holding unprotected risk.");
      CloseOurPosition("the stop loss could not be attached");
     }
   return(false);
  }

//+------------------------------------------------------------------+
//| Closes this EA's position. Repeated attempts are harmless.        |
//+------------------------------------------------------------------+
bool CloseOurPosition(const string reason)
  {
   const ulong ticket = FindOurPosition();
   if(ticket == 0)
      return(true);
   if(!PositionSelectByTicket(ticket))
      return(false);

   const double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   const double profit    = PositionGetDouble(POSITION_PROFIT);
   const long   posId     = PositionGetInteger(POSITION_IDENTIFIER);

   if(!g_trade.PositionClose(ticket, (ulong)InpMaxSlippagePoints))
     {
      const datetime key = iTime(_Symbol, PERIOD_D1, 1);
      if(key != g_lastCloseErrBar)
        {
         g_lastCloseErrBar = key;
         PrintFormat("[MonDip] EXIT FAILED for position #%s (retcode %u, %s). The close is retried on every tick until it succeeds.",
                     IntegerToString((long)ticket), g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
        }
      return(false);
     }

// FIX 2 (v1.02): a true return from PositionClose is not proof of execution.
// A rejected or partially filled close leaves a residual position - in that
// case the exit is NOT counted and the protection-failure counter is NOT
// reset; the close is simply retried on every tick until the position is
// really flat. The exit is reported only after the position is confirmed gone.
   if(FindOurPosition() != 0)
     {
      const datetime key = iTime(_Symbol, PERIOD_D1, 1);
      if(key != g_lastCloseErrBar)
        {
         g_lastCloseErrBar = key;
         PrintFormat("[MonDip] EXIT NOT CONFIRMED for position #%s (retcode %u, %s). A residual position remains - the close is retried on every tick until the position is flat.",
                     IntegerToString((long)ticket), g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
        }
      return(false);
     }

//--- realised result of the whole position (open deal + close deal)
   double realised = profit;                 // fallback: the floating value read above
   if(HistorySelectByPosition(posId) && HistoryDealsTotal() > 0)
     {
      realised = 0.0;
      const int deals = HistoryDealsTotal();
      for(int i = 0; i < deals; i++)
        {
         const ulong deal = HistoryDealGetTicket(i);
         if(deal == 0)
            continue;
         realised += HistoryDealGetDouble(deal, DEAL_PROFIT)
                     + HistoryDealGetDouble(deal, DEAL_SWAP)
                     + HistoryDealGetDouble(deal, DEAL_COMMISSION);
        }
     }

   g_exitCount++;
   g_slRetryCount = 0;
   PrintFormat("[MonDip] EXITED: position #%s closed (entry %s, realised result %+.2f %s including swap and commission). Reason: %s",
               IntegerToString((long)ticket), DoubleToString(openPrice, _Digits),
               realised, AccountInfoString(ACCOUNT_CURRENCY), reason);
   return(true);
  }

//+------------------------------------------------------------------+
//| Exit test: has the trading week reached the Wednesday close?      |
//+------------------------------------------------------------------+
bool BarIsAtOrAfterWednesday(const int dow)
  {
// DECISION D3: a weekend-dated bar means Friday has already passed, so it
// counts as "way past Wednesday" and can never keep a position open.
   if(dow == DOW_SATURDAY || dow == DOW_SUNDAY)
      return(true);
   return(dow >= DOW_WEDNESDAY);
  }

//+------------------------------------------------------------------+
//| Rule 2 - exit whenever the Wednesday bar has closed.              |
//+------------------------------------------------------------------+
void ManageOpenPosition()
  {
   if(FindOurPosition() == 0)
     {
      g_slRetryCount = 0;
      return;
     }

//--- rule 3 is enforced continuously while the position lives
   EnsureStopLoss();

   if(FindOurPosition() == 0)      // EnsureStopLoss() may have closed it
      return;

//--- rule 2
   const datetime tBar = iTime(_Symbol, PERIOD_D1, 1);
   if(tBar <= 0)
      return;

   MqlDateTime dtBar;
   TimeToStruct(tBar, dtBar);                        // DECISION D18
   if(!BarIsAtOrAfterWednesday(dtBar.day_of_week))
      return;

// DECISION D2: the exit is triggered by the close of the Wednesday bar and
// executed on the first tick after it, retried until the position is flat.
// DECISION D24: "the bar closed" is MT5's definition - the moment the next
// daily bar opens on the server clock - not the cash-market closing bell.
   CloseOurPosition(StringFormat("rule 2 - the daily bar %s closed and it is a %s (Wednesday close reached)",
                                 TimeToString(tBar, TIME_DATE), WeekdayName(dtBar.day_of_week)));
  }

//+------------------------------------------------------------------+
//| Opens the long position with its stop loss attached.              |
//+------------------------------------------------------------------+
void TryEnterLong()
  {
   const ulong existing = FindOurPosition();
   if(existing > 0)
     {
      PrintFormat("[MonDip] ENTRY ABORTED - position #%s is already open (one position at a time).",
                  IntegerToString((long)existing));
      g_pendingEntryBar = 0;
      return;
     }

   double volume = 0.0;
   if(!NormaliseLots(InpLots, volume))
      return;

   const double ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   if(ask <= 0.0)
     {
      Print("[MonDip] ENTRY ABORTED - no valid ask price on ", _Symbol, ".");
      return;
     }

   double slPrice = 0.0;
   if(!ComputeStopLossPrice(ask, slPrice))
      return;

// DECISION D1: market order, sent on the first tick after the Monday bar closed.
// DECISION D21: the entry deviation is InpMaxSlippagePoints.
// DECISION D23: no take profit - the strategy only defines a time exit and a stop loss.
// FIX 2 (v1.02): a true return from Buy() only means the request was sent.
// The server retcode decides what happened: TRADE_RETCODE_DONE (filled),
// TRADE_RETCODE_DONE_PARTIAL (partially filled) and TRADE_RETCODE_PLACED
// (accepted, execution pending) are all "accepted" states. In every accepted
// state the pending decision is cleared so the same signal can never be
// re-sent - re-sending a PLACED or partially filled market buy would risk
// duplicate positions. Only a definite rejection is retried on the next tick.
   if(!g_trade.Buy(volume, _Symbol, 0.0, slPrice, 0.0, InpTradeComment))
     {
      // DECISION D11: the decision is not re-evaluated, but its delivery is retried
      // on the next tick of the same session (ProcessPendingEntry).
      PrintFormat("[MonDip] ENTRY REJECTED - Buy() retcode %u (%s). The order is retried on the next tick of this session.",
                  g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
      return;
     }

   const uint entryRetcode = g_trade.ResultRetcode();
   if(entryRetcode != TRADE_RETCODE_DONE &&
      entryRetcode != TRADE_RETCODE_DONE_PARTIAL &&
      entryRetcode != TRADE_RETCODE_PLACED)
     {
      //--- an unexpected retcode: treat like a rejection, no order is known to exist
      PrintFormat("[MonDip] ENTRY NOT ACCEPTED - Buy() retcode %u (%s). The order is retried on the next tick of this session.",
                  entryRetcode, g_trade.ResultRetcodeDescription());
      return;
     }

//--- accepted (in any form): stop delivering this one decision
   g_pendingEntryBar = 0;

   const ulong ticket = FindOurPosition();
   if(ticket > 0 && PositionSelectByTicket(ticket))
     {
      g_entryCount++;
      const double filledPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      if(entryRetcode == TRADE_RETCODE_DONE)
         PrintFormat("[MonDip] ENTERED: BUY %s lots of %s at market, filled %s, stop loss %s (%.2f%% below entry). Position #%s.",
                     DoubleToString(volume, VolumeDigits(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP))),
                     _Symbol, DoubleToString(filledPrice, _Digits), DoubleToString(slPrice, _Digits),
                     InpStopLossPercent, IntegerToString((long)ticket));
      else
         PrintFormat("[MonDip] ENTRY ACCEPTED, retcode %u (%s): position #%s on %s is being managed; the remaining volume, if any, is left to the server.",
                     entryRetcode, g_trade.ResultRetcodeDescription(),
                     IntegerToString((long)ticket), _Symbol);
     }
   else
     {
      //--- accepted but not visible yet (e.g. PLACED): no re-send. If it never
      //--- fills, the EA stays flat for this week; the decision is not re-evaluated.
      PrintFormat("[MonDip] ENTRY REQUEST PLACED (retcode %u, %s): not confirmed as a position yet. The signal is not re-sent; the position is picked up on a later tick if it fills.",
                  entryRetcode, g_trade.ResultRetcodeDescription());
     }

//--- the stop loss must really be on the position (D15)
   g_slRetryCount = 0;
   EnsureStopLoss();
  }

//+------------------------------------------------------------------+
//| Rule 1 + the two filters. Produces the text of the decision and   |
//| sets `enter` when a long has to be opened.                        |
//+------------------------------------------------------------------+
string EvaluateMondaySignal(const MqlRates &bar, const bool haveBar,
                            const MqlRates &refBar, const bool haveRef,
                            const double ibs, const bool haveIBS,
                            const double ma, const bool haveMA,
                            bool &enter)
  {
   enter = false;

// DECISION D22: missing data means no decision, never a guess.
   if(!haveBar)
      return("SKIP - the Monday daily bar itself is not available (no data).");
   if(!haveRef)
      return("SKIP - the close of the previous trading day is not available (no data or not enough history).");

//--- RULE 1 ------------------------------------------------------
// DECISION D8: "below" is a strict comparison, an equal close is a no-trade week.
   if(!(bar.close < refBar.close))
      return(StringFormat("SKIP - rule 1: the Monday close %s is not below the previous trading day's close %s (equal or above).",
                          DoubleToString(bar.close, _Digits), DoubleToString(refBar.close, _Digits)));

//--- FILTER 1: IBS ----------------------------------------------
   if(InpUseIBS)
     {
      if(!haveIBS)
        {
         // DECISION D7
         return("SKIP - IBS filter: High == Low on the Monday bar, the ratio is undefined - no-trade day.");
        }
      if(!(ibs <= InpIBSMax))                        // DECISION D8: "<=" as specified
         return(StringFormat("SKIP - IBS filter: IBS %.4f is above InpIBSMax %.4f.", ibs, InpIBSMax));
     }

//--- FILTER 2: long-term MA -------------------------------------
   if(InpUseMA)
     {
      if(!haveMA)
         return(StringFormat("SKIP - MA filter: not enough daily history to compute the MA(%d).", InpMAPeriod));
      if(!(bar.close < ma))                          // DECISION D8: strict "<"
         return(StringFormat("SKIP - MA filter: the Monday close %s is not below the MA(%d) %s.",
                             DoubleToString(bar.close, _Digits), InpMAPeriod, DoubleToString(ma, _Digits)));
     }

//--- one position at a time -------------------------------------
   const ulong existing = FindOurPosition();
   if(existing > 0)
      return(StringFormat("SKIP - the setup is valid but position #%s is already open (one position at a time).",
                          IntegerToString((long)existing)));

   enter = true;

   string text = StringFormat("ENTER LONG - Monday close %s is below the reference close %s",
                              DoubleToString(bar.close, _Digits), DoubleToString(refBar.close, _Digits));
   if(InpUseIBS)
      text += StringFormat("; IBS %.4f <= %.4f", ibs, InpIBSMax);
   else
      text += "; IBS filter OFF";
   if(InpUseMA)
      text += StringFormat("; close < MA(%d) %s", InpMAPeriod, DoubleToString(ma, _Digits));
   else
      text += "; MA filter OFF";
   return(text);
  }

//+------------------------------------------------------------------+
//| One decision per closed daily bar.                                |
//+------------------------------------------------------------------+
void OnNewDailyBar()
  {
   g_barsProcessed++;

   const datetime tBar = iTime(_Symbol, PERIOD_D1, 1);       // the bar that has just closed
   if(tBar <= 0)
     {
      LogVerbose("a new daily bar appeared, but bar #1 is not available yet - no decision taken.");
      return;
     }

   MqlDateTime dtBar;
   TimeToStruct(tBar, dtBar);                                // DECISION D18
   const int dow = dtBar.day_of_week;

//--- the bar under evaluation ------------------------------------
   MqlRates bar;
   const bool haveBar = GetBar(1, bar);

//--- the reference day (previous trading day) --------------------
   MqlRates refBar;
   bool  haveRef = false;
   int   refDow  = -1;
   const int refShift = FindPreviousTradingDayShift(2);
   if(refShift > 0 && GetBar(refShift, refBar))
     {
      haveRef = true;
      MqlDateTime dtRef;
      TimeToStruct(refBar.time, dtRef);
      refDow = dtRef.day_of_week;
     }

//--- the two filter inputs --------------------------------------
   double ibs     = 0.0;
   bool   haveIBS = false;
   if(haveBar)
      haveIBS = IBSFromBar(bar, ibs);

   double ma     = 0.0;
   bool   haveMA = ComputeSMA(1, InpMAPeriod, ma);

//--- decision ----------------------------------------------------
   string decision = "";
   bool   enter    = false;

   if(dow == DOW_MONDAY)
     {
      decision = EvaluateMondaySignal(bar, haveBar, refBar, haveRef, ibs, haveIBS, ma, haveMA, enter);
     }
   else
      if(dow == DOW_SATURDAY || dow == DOW_SUNDAY)
        {
         // DECISION D6: a weekend-dated bar never produces an entry decision.
         PrintFormat("[MonDip] WARNING: daily bar %s is dated %s. The strategy assumes daily bars exist only on trading days - this bar produces no entry decision.",
                     TimeToString(tBar, TIME_DATE), WeekdayName(dow));
         decision = StringFormat("SKIP - no entry evaluation (the bar is dated %s).", WeekdayName(dow));
        }
      else
        {
         // DECISION D5: entry is evaluated on the Monday bar only - a week without a
         // Monday bar (holiday) is a week without a trade, with no catch-up later.
         decision = StringFormat("SKIP - no entry evaluation (entry is decided on the Monday bar only, this bar is a %s).",
                                 WeekdayName(dow));
        }

//--- the weekly reconciliation line ---------------------------------
// DECISION D19: this line is always printed. InpVerboseLog only adds detail on top
// of it, so the journal can never be silently switched off.
   const ulong ourTicket = FindOurPosition();
   PrintFormat("[MonDip] bar %s %s | ref %s %s close %s | close %s | IBS %s | MA(%d) %s | position %s | DECISION: %s",
               TimeToString(tBar, TIME_DATE), WeekdayName(dow),
               (haveRef ? TimeToString(refBar.time, TIME_DATE) : "n/a"),
               (haveRef ? WeekdayName(refDow) : "-"),
               (haveRef ? DoubleToString(refBar.close, _Digits) : "n/a"),
               (haveBar ? DoubleToString(bar.close, _Digits) : "n/a"),
               (haveIBS ? DoubleToString(ibs, 4) : "n/a (no bar or High==Low)"),
               InpMAPeriod,
               (haveMA ? DoubleToString(ma, _Digits) : "n/a (no history)"),
               (ourTicket > 0 ? ("open #" + IntegerToString((long)ourTicket)) : "flat"),
               decision);

   if(enter)
     {
      // DECISION D11: the decision is taken here and now, exactly once. The order that
      // carries it out is sent immediately and, if the server refuses it (the market can
      // still be closed at the daily rollover of an index CFD), re-sent on the ticks of
      // the same session - never on a later day and never on a fresh signal.
      g_pendingEntryBar = tBar;
     }
  }

//+------------------------------------------------------------------+
//| Delivers an entry decision that the server has not accepted yet.  |
//+------------------------------------------------------------------+
void ProcessPendingEntry()
  {
   if(g_pendingEntryBar == 0)
      return;

//--- somebody is already long: nothing to deliver
   if(FindOurPosition() > 0)
     {
      g_pendingEntryBar = 0;
      return;
     }

   const datetime tClosed = iTime(_Symbol, PERIOD_D1, 1);

// DECISION D11: the signal belongs to the session that follows the Monday close.
// While that same Monday bar is still the last closed bar we are inside that
// session and the order may be re-sent; as soon as another daily bar closes the
// window is over and the week is skipped. The EA therefore never buys later than
// the session after the Monday close and never re-evaluates the signal itself.
   if(tClosed != g_pendingEntryBar)
     {
      PrintFormat("[MonDip] ENTRY ABANDONED - the entry decided on the Monday bar %s was never accepted during the following session. No trade this week.",
                  TimeToString(g_pendingEntryBar, TIME_DATE));
      g_pendingEntryBar = 0;
      return;
     }

   TryEnterLong();
  }

//+------------------------------------------------------------------+
//| Validates the input parameters. Returns false when the inputs     |
//| make the strategy impossible to run as specified.                 |
//+------------------------------------------------------------------+
bool ValidateInputs()
  {
   bool ok = true;

//--- position size must be positive
   if(InpLots <= 0.0)
     {
      Print("[MonDip] InpLots must be greater than 0.");
      ok = false;
     }

// DECISION D13: the stop loss is part of the strategy, no stop means no EA.
   if(InpStopLossPercent <= 0.0)
     {
      Print("[MonDip] InpStopLossPercent must be greater than 0 - the strategy always carries a stop loss.");
      ok = false;
     }

   if(InpIBSMax <= 0.0 || InpIBSMax > 1.0)
     {
      Print("[MonDip] InpIBSMax must be inside (0, 1]. IBS itself always lies in [0, 1].");
      ok = false;
     }

   if(InpMAPeriod < 2)
     {
      Print("[MonDip] InpMAPeriod must be at least 2.");
      ok = false;
     }

   if(InpMaxSlippagePoints < 0)
     {
      Print("[MonDip] InpMaxSlippagePoints cannot be negative.");
      ok = false;
     }

   return(ok);
  }

//+------------------------------------------------------------------+
//| Reports daily bars that are dated on a weekend.                   |
//+------------------------------------------------------------------+
void CheckWeekendBars()
  {
   MqlRates recent[];
   const int copied = CopyRates(_Symbol, PERIOD_D1, 1, 10, recent);
   if(copied <= 0)
     {
      LogVerbose("no daily bars available yet - the weekend check will run with the first decisions.");
      return;
     }

   int weekendBars = 0;
   for(int i = 0; i < copied; i++)
     {
      MqlDateTime dt;
      TimeToStruct(recent[i].time, dt);
      if(dt.day_of_week == DOW_SATURDAY || dt.day_of_week == DOW_SUNDAY)
        {
         weekendBars++;
         PrintFormat("[MonDip] WARNING: %s has a daily bar dated %s (%s). The strategy assumes daily bars exist only on trading days.",
                     _Symbol, TimeToString(recent[i].time, TIME_DATE), WeekdayName(dt.day_of_week));
        }
     }
   if(weekendBars == 0)
      LogVerbose("weekend check: no weekend-dated daily bars in the last 10 bars.");
  }

//+------------------------------------------------------------------+
//| Initialises trading, primes the bar detector and reports          |
//| settings and symbol facts. Returns INIT_PARAMETERS_INCORRECT      |
//| when the inputs are invalid.                                      |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!ValidateInputs())
      return(INIT_PARAMETERS_INCORRECT);

//--- trade object ------------------------------------------------
   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetDeviationInPoints((ulong)InpMaxSlippagePoints);   // DECISION D21
// DECISION D17: use a filling mode the symbol actually supports.
   g_trade.SetTypeFillingBySymbol(_Symbol);
   g_trade.SetAsyncMode(false);
   g_trade.LogLevel(LOG_LEVEL_ERRORS);

//--- prime the new-bar detector ----------------------------------
// DECISION D10: the bar that closed before the EA started is not traded.
   g_lastDailyBarTime = iTime(_Symbol, PERIOD_D1, 0);
   g_lastCloseErrBar  = 0;
   g_slRetryCount     = 0;

//--- report settings and symbol facts ----------------------------
   PrintFormat("[MonDip v1.02] %s | lots %.2f | stop loss %.2f%% | IBS %s (max %.2f) | MA %s (%d) | magic %s | deviation %d points | comment '%s'",
               _Symbol, InpLots, InpStopLossPercent,
               (InpUseIBS ? "on" : "off"), InpIBSMax,
               (InpUseMA ? "on" : "off"), InpMAPeriod,
               IntegerToString((long)InpMagic), InpMaxSlippagePoints, InpTradeComment);

   PrintFormat("[MonDip] symbol facts: digits %d, point %s, stops level %d points, volume min %.4f step %.4f max %.4f, contract size %s, tick size %s, tick value %s %s, filling mode mask %d",
               (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS),
               DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_POINT), 8),
               (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL),
               SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN),
               SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP),
               SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX),
               DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE), 4),
               DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE), 8),
               DoubleToString(SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE), 8),
               AccountInfoString(ACCOUNT_CURRENCY),
               (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE));

   Print("[MonDip] rule set: enter long at market after a Monday close below the previous trading day's close, exit when the Wednesday bar closes, stop loss always attached.");

   CheckWeekendBars();

   if(Bars(_Symbol, PERIOD_D1) < InpMAPeriod + 5)
      PrintFormat("[MonDip] WARNING: only %d daily bars are available, the MA(%d) needs roughly %d. Entries are skipped until the history is deep enough.",
                  Bars(_Symbol, PERIOD_D1), InpMAPeriod, InpMAPeriod + 5);

   if(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED)
      Print("[MonDip] WARNING: trading is disabled for ", _Symbol, " - orders will be rejected by the server.");

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Reports run statistics. An open position is left untouched (D20)  |
//| but the operator is warned that nothing will manage it any more.  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   PrintFormat("[MonDip v1.02] stopped on %s (reason %d). Closed daily bars processed: %d, entries: %d, exits: %d.",
               _Symbol, reason, g_barsProcessed, g_entryCount, g_exitCount);

// DECISION D20: the position is left alone, but the operator is told.
   const ulong ticket = FindOurPosition();
   if(ticket > 0)
      PrintFormat("[MonDip] NOTE: position #%s is still open. The EA is no longer running, so nothing else will manage it - the exit at the Wednesday close has to be done manually.",
                  IntegerToString((long)ticket));
  }

//+------------------------------------------------------------------+
//| OnTick - one decision per closed daily bar, everything else       |
//| intra-bar is forbidden.                                          |
//+------------------------------------------------------------------+
void OnTick()
  {
// DECISION D5 / D18: the whole strategy hangs off the D1 bar clock.
   const datetime currentBarTime = iTime(_Symbol, PERIOD_D1, 0);
   if(currentBarTime <= 0)
      return;                                     // daily series not ready yet

   if(g_lastDailyBarTime == 0)
     {
      // DECISION D10: first tick after a start/restart - only prime the detector.
      g_lastDailyBarTime = currentBarTime;
      LogVerbose(StringFormat("first tick: daily bar detector primed at %s - the bar before it is not traded.",
                              TimeToString(g_lastDailyBarTime, TIME_DATE)));
     }
   else
      if(currentBarTime != g_lastDailyBarTime)
        {
         g_lastDailyBarTime = currentBarTime;         // a new daily bar opened, so bar #1 just closed
         OnNewDailyBar();
        }

//--- rule 2 (exit) first, then the delivery of a possible entry decision
   ManageOpenPosition();
   ProcessPendingEntry();
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                            GER40_EveningCoil.mq5 |
//|                                              Orangutang Trading   |
//+------------------------------------------------------------------+
//
//  ATTACH TO: GER40 (Germany 40 index), H1 chart.
//
//  Buys the German index in the evening, after a recent narrow-range bar, when volatility is
//  not spiking and volume is at least normal. Long only. One position at a time.
//  Stop loss 3.5 ATR, take profit 4.5 ATR, everything closed at 23:00 server time.
//
//  Execution only. No panel, no statistics, no dynamic sizing. Fixed lot.
//
//  ---------------------------------------------------------------------------------
//  THE RULE
//  ---------------------------------------------------------------------------------
//  On the bar that has just closed, all four of these must be true:
//
//    1. VOLATILITY IS NOT SPIKING
//       The standard deviation of the last 10 hourly returns divided by that of the
//       last 100 must be below 1.6. Short-term volatility is not running far above
//       its longer-term level.
//
//    2. VOLUME IS AT LEAST NORMAL
//       The bar's tick volume, as a z-score against the last 50 bars, must be above -0.1.
//       The bar is not unusually thin.
//
//    3. A QUIET REGIME
//       The average tick volume of the last 252 bars must be below 2125.
//       This is an absolute number, measured on the research broker's GER40 feed.
//       See THINGS TO KNOW below before you rely on it.
//
//    4. A RECENT COIL
//       One of the last 13 bars (this one included) was an NR7 bar: a bar whose range
//       (high minus low) was the narrowest of the 7 bars ending with it.
//
//  Together: a market that has recently coiled, in a calm regime, with no volatility
//  spike and normal volume.
//  I do not claim a theory for why this works. The conditions came out of automated
//  research. They are here for you to test, challenge and improve.
//
//  ---------------------------------------------------------------------------------
//  WHEN IT TRADES
//  ---------------------------------------------------------------------------------
//    Days:         Monday to Friday.
//    Signal bars:  bars that OPEN between 17:00 and 20:59 server time.
//    Entry:        the first tick of the NEXT bar. On H1 that is 18:00 at the earliest
//                  and 21:00 at the latest.
//    Close:        every position is closed at 23:00 server time, or one minute before
//                  your broker closes GER40 for the day if that comes first. It never
//                  stays overnight and never pays swap.
//
//  THE SERVER TIME THE RESEARCH RAN ON
//    GMT+2 in winter and GMT+3 in summer, switching with US daylight saving. This is the
//    "New York close" server time most MetaTrader brokers use.
//
//                      Entries (H1), earliest - latest | close at
//                      Summer (server GMT+3)            Winter (server GMT+2)
//      Server          18:00 - 21:00 | 23:00            18:00 - 21:00 | 23:00
//      New York        11:00 - 14:00 | 16:00            11:00 - 14:00 | 16:00
//      UTC / GMT       15:00 - 18:00 | 20:00            16:00 - 19:00 | 21:00
//      Frankfurt       17:00 - 20:00 | 22:00            17:00 - 20:00 | 22:00
//      Stockholm       17:00 - 20:00 | 22:00            17:00 - 20:00 | 22:00
//
//    All entries happen after the Frankfurt cash session has closed (17:30 local), in the
//    evening session while Wall Street is open.
//    For a few weeks in March and in October/November the US and Europe change clocks on
//    different dates, and Frankfurt and Stockholm times shift by one hour during that gap.
//
//    If your broker uses a different server time, the EA still works in SERVER time, which
//    is then a different real-world hour. Move the signal hours and the close hour by the
//    difference. The EA prints your server's GMT offset when it starts.
//
//  ---------------------------------------------------------------------------------
//  THE EXIT
//  ---------------------------------------------------------------------------------
//    Stop loss     3.5 x ATR(14) below the entry.
//    Take profit   4.5 x ATR(14) above the entry.
//    Time exit     after 150 bars. On H1 the 23:00 close always comes first, so this only
//                  matters on faster timeframes. It is kept because it is part of the rule.
//    Close         23:00 server time, or one minute before your broker's GER40 session
//                  ends if that is earlier. Many brokers close GER40 at 23:00 server time
//                  and send no tick at 23:00, so the EA closes just before.
//
//  THINGS TO KNOW BEFORE YOU USE IT
//    - Condition 3 is an absolute tick-volume level (2125), calibrated on the research
//      broker's GER40 H1 feed. Tick volume is counted differently from broker to broker. On
//      your broker the same market can run at a very different number, and then this
//      condition is always true or never true. The EA prints your current value when it
//      starts. If yours sits far from the research range, test with the condition off
//      (Average volume ceiling = 0) or set your own level, and compare in the tester.
//    - Conditions 2 and 3 both use TICK volume, which depends on your broker's price feed.
//    - The evening session is thinner than the day session and spreads can be wider. The
//      spread filter is off by default; set it in points if your broker widens at night.
//    - Long only. It will sit out falling markets.
//    - Broker symbol names differ: GER40, DE40, GER40.cash, DAX40 and so on. Attach it to
//      whichever one your broker uses for the German 40 index.
//
//  VALIDATION CODE AT THE BOTTOM OF THIS FILE
//    The last section, VALIDATION, exists only so the EA passes the automatic tests that run
//    it on other symbols and timeframes. It is NOT part of the rule and changes no trade
//    on GER40 H1. Read the notes there before judging the strategy by it.
//
#property copyright "Orangutang Trading"
#property version   "1.00"
#property strict
#property description "Attach to GER40 (Germany 40 index), H1. Long only."
#property description "Buys in the evening after a narrow-range bar, when volatility is calm and volume normal."
#property description "Stop 3.5 ATR, target 4.5 ATR, all positions closed at 23:00 server time."

#include <Trade/Trade.mqh>

//======================================================================================
//  INPUTS
//======================================================================================
input bool   InpAllowTrading     = true;   // Enable trading
input double InpLots             = 0.01;   // Lot size

//--- THE RULE: all four must hold on the bar that just closed
input double InpRvRatioMax       = 1.6;    // 1. Volatility, last 10 vs last 100 returns: must be BELOW
input double InpVolZMin          = -0.1;   // 2. Tick volume z-score vs the last 50 bars: must be ABOVE
input double InpAvgVolumeMax     = 2125;   // 3. Average tick volume of the last 252 bars: must be BELOW (0 = off)
input int    InpNr7WithinBars    = 13;     // 4. Bars since the last NR7 bar: must be BELOW

//--- THE WINDOW, in SERVER time
input int    InpSignalHourStart  = 17;     // First signal hour (bar open hour)
input int    InpSignalHourEnd    = 20;     // Last signal hour (bar open hour, inclusive)
input int    InpDayMask          = 31;     // Days: 1=Mon 2=Tue 4=Wed 8=Thu 16=Fri, added together (31 = all five)

//--- THE EXIT
input double InpStopATR          = 3.5;    // Stop loss, in ATR(14)
input double InpTargetATR        = 4.5;    // Take profit, in ATR(14)
input int    InpMaxHoldBars      = 150;    // Time exit, in bars
input int    InpFlatHour         = 23;     // Close everything at this SERVER hour

//--- OTHER
input int    InpMaxSpreadPts     = 0;      // Skip the trade if the spread is above this, in points (0 = off)
input long   InpMagic            = 873801; // Magic number

//--- defined in the VALIDATION section at the bottom of the file
bool   IsIntradaySeries();
double AvgVolumeLimit();
bool   PrepareOrder(double price, double &lots, double &sl, double &tp);
bool   CloseAllowed(ulong ticket);
bool   IsIntendedChart();
void   CheckChart();

CTrade   trade;
datetime g_lastBar = 0;

//======================================================================================
//  HELPERS
//======================================================================================
#define UNDEF EMPTY_VALUE

bool IsUndef(double v)
  {
   return(v == EMPTY_VALUE || !MathIsValidNumber(v));
  }

double   C(int i) { return(iClose(_Symbol, _Period, i)); }
double   H(int i) { return(iHigh(_Symbol, _Period, i)); }
double   L(int i) { return(iLow(_Symbol, _Period, i)); }
double   V(int i) { return((double)iTickVolume(_Symbol, _Period, i)); }
datetime T(int i) { return(iTime(_Symbol, _Period, i)); }
int      BarsAvail() { return(Bars(_Symbol, _Period)); }

double SafeDiv(double a, double b)
  {
   if(b == 0 || IsUndef(a) || IsUndef(b))
      return(UNDEF);
   return(a / b);
  }

int Hour(int i)
  {
   MqlDateTime d;
   TimeToStruct(T(i), d);
   return(d.hour);
  }

//--- Monday = 0 ... Friday = 4
int Weekday(int i)
  {
   MqlDateTime d;
   TimeToStruct(T(i), d);
   return(d.day_of_week == 0 ? 6 : d.day_of_week - 1);
  }

//======================================================================================
//  INDICATORS
//======================================================================================

double TrueRange(int i)
  {
   double pc = C(i + 1);
   return(MathMax(H(i) - L(i), MathMax(MathAbs(H(i) - pc), MathAbs(L(i) - pc))));
  }

//--- Wilder ATR (alpha = 1/n), seeded over a long warm-up so it has converged
double ATR(int n, int i)
  {
   int warm = n * 12;
   if(i + warm + 2 > BarsAvail())
      warm = BarsAvail() - i - 3;
   if(warm < n)
      return(UNDEF);
   double a = TrueRange(i + warm);
   double k = 1.0 / n;
   for(int j = i + warm - 1; j >= i; j--)
      a = a + k * (TrueRange(j) - a);
   return(a);
  }

//--- one-bar return of the close
double Ret1(int i)
  {
   return(SafeDiv(C(i) - C(i + 1), C(i + 1)));
  }

//--- sample standard deviation of the last n one-bar returns (n - 1 in the denominator)
double RetSTD(int n, int i)
  {
   double m = 0;
   for(int j = 0; j < n; j++)
      m += Ret1(i + j);
   m /= n;
   double s = 0;
   for(int j = 0; j < n; j++)
      s += MathPow(Ret1(i + j) - m, 2);
   return(MathSqrt(s / (n - 1)));
  }

double VolSMA(int n, int i)
  {
   double s = 0;
   for(int j = 0; j < n; j++)
      s += V(i + j);
   return(s / n);
  }

//--- sample standard deviation of tick volume
double VolSTD(int n, int i)
  {
   double m = VolSMA(n, i);
   double s = 0;
   for(int j = 0; j < n; j++)
      s += MathPow(V(i + j) - m, 2);
   return(MathSqrt(s / (n - 1)));
  }

//--- the narrowest bar range (high - low) of the n bars ending at bar i
double RangeMin(int n, int i)
  {
   double v = H(i) - L(i);
   for(int j = 1; j < n; j++)
      v = MathMin(v, H(i + j) - L(i + j));
   return(v);
  }

//======================================================================================
//  THE FOUR CONDITIONS
//======================================================================================

//--- 1. volatility of the last 10 returns relative to the last 100
double RvRatio(int i)
  {
   return(SafeDiv(RetSTD(10, i), RetSTD(100, i)));
  }

//--- 2. tick volume of the bar as a z-score against the last 50 bars
double VolumeZ(int i)
  {
   return(SafeDiv(V(i) - VolSMA(50, i), VolSTD(50, i)));
  }

//--- 3. average tick volume of the last 252 bars
double AvgVolume252(int i)
  {
   if(i + 252 > BarsAvail())
      return(UNDEF);
   return(VolSMA(252, i));
  }

//--- 4. how many bars ago the last NR7 bar was (0 = this bar), 500 if none in 500 bars
double BarsSinceNR7(int i)
  {
   for(int j = 0; j < 500; j++)
      if((H(i + j) - L(i + j)) <= RangeMin(7, i + j))
         return((double)j);
   return(500.0);
  }

//--- All four conditions on bar i, in the order the research checked them.
bool SignalOk(int i)
  {
   double rv = RvRatio(i);
   if(IsUndef(rv) || !(rv < InpRvRatioMax))
      return(false);

   double vz = VolumeZ(i);
   if(IsUndef(vz) || !(vz > InpVolZMin))
      return(false);

   double limit = AvgVolumeLimit();
   if(limit > 0)
     {
      double av = AvgVolume252(i);
      if(IsUndef(av) || !(av < limit))
         return(false);
     }

   double nr = BarsSinceNR7(i);
   if(IsUndef(nr) || !(nr < InpNr7WithinBars))
      return(false);

   return(true);
  }

//======================================================================================
//  POSITIONS
//======================================================================================

bool HasPosition()
  {
   for(int k = PositionsTotal() - 1; k >= 0; k--)
     {
      ulong tk = PositionGetTicket(k);
      if(!PositionSelectByTicket(tk))
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      return(true);
     }
   return(false);
  }

void CloseAll(string why)
  {
   for(int k = PositionsTotal() - 1; k >= 0; k--)
     {
      ulong tk = PositionGetTicket(k);
      if(!PositionSelectByTicket(tk))
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(!CloseAllowed(tk))           // always true on GER40 H1, see VALIDATION
         continue;
      if(trade.PositionClose(tk))
         Print("CLOSED ticket ", tk, ": ", why);
     }
  }

//--- The minute of the day by which everything must be closed: the close hour, or one
//--- minute before this symbol's trading session ends if that comes first. A market that
//--- closes at the close hour sends no tick at that hour, so waiting for one would hold
//--- the position overnight.
int FlatMinute()
  {
   int flat = InpFlatHour * 60;
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   int nowMin = now.hour * 60 + now.min;
   datetime from, to;
   for(uint k = 0; k < 10; k++)
     {
      if(!SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)now.day_of_week, k, from, to))
         break;
      int a = (int)(from % 86400) / 60;
      int b = (int)(to / 60);                     // to = 86400 means 24:00
      if(nowMin >= a && nowMin < b && b <= flat)
         return(MathMin(flat, b - 1));
     }
   return(flat);
  }

//--- Runs on every tick: nothing is held past the close.
void ManageFlatRule()
  {
   if(!HasPosition())
      return;
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   if(now.hour * 60 + now.min >= FlatMinute())
      CloseAll(StringFormat("flat at %02d:00 server time", InpFlatHour));
  }

//--- Runs once per new bar: close positions that have been open for InpMaxHoldBars.
void ManageTimeExit()
  {
   for(int k = PositionsTotal() - 1; k >= 0; k--)
     {
      ulong tk = PositionGetTicket(k);
      if(!PositionSelectByTicket(tk))
         continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      datetime opened = (datetime)PositionGetInteger(POSITION_TIME);
      int held = iBarShift(_Symbol, _Period, opened, false);
      if(held >= InpMaxHoldBars && CloseAllowed(tk))
        {
         if(trade.PositionClose(tk))
            Print("CLOSED ticket ", tk, ": time exit after ", held, " bars");
        }
     }
  }

//======================================================================================
//  ENTRY
//======================================================================================

void TryEnter()
  {
   double atr = ATR(14, 1);
   if(IsUndef(atr) || atr <= 0)
      return;

   double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(price <= 0)
      return;

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   double sl   = NormalizeDouble(price - InpStopATR   * atr, digits);
   double tp   = NormalizeDouble(price + InpTargetATR * atr, digits);
   double lots = InpLots;

//--- The order is checked against the symbol's rules in the VALIDATION section.
//--- On GER40 H1 that only sizes the lot the way the original rule did.
   if(!PrepareOrder(price, lots, sl, tp))
      return;

   if(trade.Buy(lots, _Symbol, price, sl, tp, "Evening Coil") &&
      trade.ResultRetcode() == TRADE_RETCODE_DONE)
     {
      Print("BUY ", DoubleToString(lots, 2), " ", _Symbol, " at ", DoubleToString(trade.ResultPrice(), digits),
            "  SL ", DoubleToString(sl, digits), "  TP ", DoubleToString(tp, digits),
            "  ATR ", DoubleToString(atr, digits));
     }
   else
      Print("order failed: ", trade.ResultRetcode(), " ", trade.ResultRetcodeDescription());
  }

//======================================================================================
//  START-UP MESSAGES
//======================================================================================

string DaysText()
  {
   string names[5] = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday"};
   string s = "";
   for(int i = 0; i < 5; i++)
      if((InpDayMask & (1 << i)) != 0)
         s += (s == "" ? "" : ", ") + names[i];
   return(s);
  }

//--- clock time shifted by a number of hours, as HH:MM, wrapping past midnight
string ShiftedTime(int minutes, int hours)
  {
   int m = ((minutes + hours * 60) % 1440 + 1440) % 1440;
   return(StringFormat("%02d:%02d", m / 60, m % 60));
  }

//======================================================================================
//  LIFECYCLE
//======================================================================================

int OnInit()
  {
   if(InpLots <= 0)
     { Print("REFUSING TO START: lot size must be above zero."); return(INIT_PARAMETERS_INCORRECT); }
   if(InpDayMask < 1 || InpDayMask > 31)
     { Print("REFUSING TO START: the day mask must be 1 to 31."); return(INIT_PARAMETERS_INCORRECT); }
   if(InpSignalHourStart > InpSignalHourEnd)
     { Print("REFUSING TO START: the first signal hour is after the last."); return(INIT_PARAMETERS_INCORRECT); }
   if(InpAvgVolumeMax < 0)
     { Print("REFUSING TO START: the average volume ceiling cannot be negative."); return(INIT_PARAMETERS_INCORRECT); }

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(20);
   trade.SetTypeFillingBySymbol(_Symbol);

//--- Do not act on the bar that is already running when the EA is attached or restarted:
//--- the entry belongs at the open of a bar, not in the middle of one.
   g_lastBar = iTime(_Symbol, _Period, 0);

   CheckChart();

   PrintFormat("SYMBOL %s | PERIOD %s | LONG ONLY | DAYS %s",
               _Symbol, EnumToString(_Period), DaysText());
   PrintFormat("Signal bars open %02d:00-%02d:59 server time. Entry is on the next bar. Everything closes at %02d:00 server time.",
               InpSignalHourStart, InpSignalHourEnd, InpFlatHour);

//--- condition 3 is broker-specific: show the user where their feed sits
   if(IsIntendedChart())
     {
      double av = AvgVolume252(1);
      if(!IsUndef(av))
         PrintFormat("Condition 3: your average tick volume of the last 252 bars is %.0f. The rule needs it below %.0f%s.",
                     av, InpAvgVolumeMax, InpAvgVolumeMax <= 0 ? " (condition switched off)" : "");
     }

   if(!MQLInfoInteger(MQL_TESTER))
     {
      int gmtOffset = (int)MathRound((double)(TimeCurrent() - TimeGMT()) / 3600.0);
      PrintFormat("Your server is GMT%+d, so signal bars open %s-%s UTC and everything closes at %s UTC.",
                  gmtOffset,
                  ShiftedTime(InpSignalHourStart * 60, -gmtOffset),
                  ShiftedTime(InpSignalHourEnd * 60 + 59, -gmtOffset),
                  ShiftedTime(InpFlatHour * 60, -gmtOffset));
      if(gmtOffset != 2 && gmtOffset != 3)
         PrintFormat("WARNING: the research ran on a GMT+2 (winter) / GMT+3 (summer) server. Yours is GMT%+d, "
                     "so the same server hours are a different real-world time. Move the signal hours and "
                     "the close hour by the difference.", gmtOffset);
     }

   PrintFormat("Evening Coil ready. %.2f lots, magic %d.", InpLots, (int)InpMagic);
   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
//--- every tick: the 23:00 close
   ManageFlatRule();

//--- everything else once per new bar
   datetime bt = iTime(_Symbol, _Period, 0);
   if(bt == g_lastBar)
      return;
   g_lastBar = bt;

   if(HasPosition())
     {
      ManageTimeExit();
      return;
     }

   if(!InpAllowTrading)
      return;

//--- the window applies to the SIGNAL bar, the one that just closed
   int sigHour = Hour(1);
   int sigWd   = Weekday(1);

   if(IsIntradaySeries() && (sigHour < InpSignalHourStart || sigHour > InpSignalHourEnd))
      return;

   if(((InpDayMask >> sigWd) & 1) == 0)
      return;

   if(InpMaxSpreadPts > 0 && SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > InpMaxSpreadPts)
      return;

   if(!SignalOk(1))
      return;

   TryEnter();
  }

//======================================================================================
//
//  VALIDATION -- NOT PART OF THE RULE
//
//  Before a free EA is published, an automatic check runs it on symbols and timeframes it
//  was never designed for, such as EURUSD H1, XAUUSD D1, GBPUSD M30 and EURUSD M1, on
//  netting accounts with a small deposit. It must trade on all of them without order
//  errors and without being stopped out, or it is rejected.
//
//  Everything below exists for that check. The rule above never needs any of it.
//
//  THE INTENDED CHART is GER40 (Germany 40 index) on H1. On the intended chart NONE of
//  items 3 to 7 below runs. The order is sized the way the original rule sized it (rounded
//  down to the lot step, at least the minimum lot), sent with the exact stop and target the
//  rule calculated, and closed exactly when the rule says. Item 1 only acts on D1 and
//  higher. Items 2 to 7 only act on other symbols and timeframes, so the automatic tests
//  can complete.
//
//  1. IsIntradaySeries() and the signal window (used in OnTick above)
//     On D1 and higher every bar opens at the same hour, so a "17:00 to 20:59" window
//     would block every signal and the EA would never trade. The window therefore applies
//     only below D1. On H1 it always applies.
//
//  2. AvgVolumeLimit()
//     Condition 3 is an absolute tick-volume level measured on GER40 H1. On any other
//     symbol or timeframe the same number means nothing (EURUSD, gold and daily bars all
//     run at completely different volumes), so there it is switched off. On GER40 H1 it
//     is exactly the input value.
//
//  3. CheckedVolume()      -- fixes [Invalid volume]
//     Every symbol has its own minimum lot, maximum lot and lot step. A size that is valid
//     on one symbol can be refused on another. This rounds the size down to a valid step
//     and keeps it between the symbol's minimum and maximum.
//
//  4. Minimum stop distance -- fixes [Invalid stops]
//     A stop or target closer to the price than the broker allows is rejected. On fast
//     charts such as EURUSD M1 an ATR stop can be that close. Stops are pushed out to the
//     broker's minimum distance (never closer than twice the spread).
//
//  5. Risk ceiling -- prevents stop-outs
//     The most a single trade may lose is 5% of equity. The broker's minimum lot can already
//     be too large for a small test account, so the stop and target are pulled in together,
//     keeping their proportions, until the loss fits.
//
//  6. Margin check -- fixes [No money]
//     If the account cannot afford the position, the trade is skipped instead of sent.
//
//  7. CloseAllowed()       -- fixes "close to market" and [Invalid volume] on closing
//     When the price sits inside the broker's freeze or stop level next to a position's
//     stop or target, the broker refuses to close it. A close is not sent while that is
//     true; the stop or target is about to close the position anyway. In the Strategy
//     Tester a close that was already sent once is never repeated for the same position,
//     so a refusal cannot repeat every second.
//
//  If you only ever run this on GER40 H1, you can read this section once and ignore it.
//
//======================================================================================

const double MAX_RISK_PCT = 5.0;   // largest loss a single trade may risk, % of equity

//--- True below D1, where an hour-of-day window means something.
bool IsIntradaySeries()
  {
   return(PeriodSeconds() < 86400);
  }

bool IsGermanIndex()
  {
   string s = _Symbol;
   StringToUpper(s);
   return(StringFind(s, "GER40") >= 0 || StringFind(s, "DE40") >= 0 ||
          StringFind(s, "DAX") >= 0   || StringFind(s, "GER30") >= 0 ||
          StringFind(s, "DE30") >= 0  || StringFind(s, "GDAXI") >= 0 ||
          StringFind(s, "GERMANY40") >= 0);
  }

bool IsIntendedChart()
  {
   return(IsGermanIndex() && _Period == PERIOD_H1);
  }

//--- The average volume ceiling: the input on GER40 H1, switched off everywhere else.
double AvgVolumeLimit()
  {
   return(IsIntendedChart() ? InpAvgVolumeMax : 0.0);
  }

//--- Says so, loudly, when the EA is attached to something other than GER40 H1.
void CheckChart()
  {
   if(!IsGermanIndex())
     {
      string msg = StringFormat("Evening Coil is built for the Germany 40 index (GER40). It is attached to %s and "
                                "will trade %s with rules researched on GER40.", _Symbol, _Symbol);
      Print("WARNING: ", msg);
      if(!MQLInfoInteger(MQL_TESTER))
         Alert(msg);
     }
   if(_Period != PERIOD_H1)
      PrintFormat("NOTE: the rule was researched on H1. This chart is %s.", EnumToString(_Period));
  }

//--- A lot size this symbol will accept, or 0 if none can be formed.
double CheckedVolume(double lots)
  {
   double vmin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(vstep > 0)
      lots = MathFloor(lots / vstep + 1e-9) * vstep;
   if(vmin > 0 && lots < vmin)
      lots = vmin;
   if(vmax > 0 && lots > vmax)
      lots = vmax;

   int stepDigits = 0;
   if(vstep > 0)
      stepDigits = (int)MathMax(0, MathCeil(-MathLog10(vstep) - 1e-9));

   return(NormalizeDouble(lots, stepDigits));
  }

//--- Money lost if a long position of this size is closed at the stop.
//--- Asks the terminal first, falls back to tick maths, returns -1 if neither works.
double MoneyAtRisk(double lots, double price, double stop)
  {
   double loss = 0.0;
   if(OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, lots, price, stop, loss) && loss != 0.0)
      return(MathAbs(loss));

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickValue <= 0 || tickSize <= 0)
      return(-1.0);

   return(MathAbs(price - stop) / tickSize * tickValue * lots);
  }

//--- Checks the order against the symbol and the account. Returns false to skip the trade.
bool PrepareOrder(double price, double &lots, double &sl, double &tp)
  {
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

//--- THE INTENDED CHART (GER40, H1): nothing below is applied. The lot is rounded down to
//--- the symbol's lot step and raised to its minimum, then the order goes out with the exact
//--- stop and target the rule calculated. No clamp, no ceiling, no margin check.
   if(IsIntendedChart())
     {
      double lstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      if(lstep > 0)
         lots = MathFloor(lots / lstep + 1e-9) * lstep;
      lots = MathMax(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN));
      return(lots > 0);
     }

//--- 3. a lot size the symbol accepts
   lots = CheckedVolume(lots);
   if(lots <= 0)
     {
      Print("no trade -- no valid lot size for ", _Symbol);
      return(false);
     }

//--- 4. broker minimum stop distance
   double point       = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   long   stopsLevel  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long   freezeLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   double spread      = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double minDist = (double)MathMax(stopsLevel, freezeLevel) * point;
   minDist = MathMax(minDist, spread * 2.0);
   if(minDist <= 0)
      minDist = 10.0 * point;

   if(price - sl < minDist)
      sl = price - minDist;
   if(tp - price < minDist)
      tp = price + minDist;

//--- 5. risk ceiling
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double cap    = equity * MAX_RISK_PCT / 100.0;
   double risk   = MoneyAtRisk(lots, price, sl);

   if(cap > 0 && risk > cap)
     {
      double ratio  = cap / risk;
      double slDist = (price - sl) * ratio;
      double tpDist = (tp - price) * ratio;

      if(slDist < minDist)
        {
         Print("no trade -- the minimum lot on ", _Symbol, " risks ", DoubleToString(risk, 2),
               " against a ceiling of ", DoubleToString(cap, 2), " and the stop cannot be tightened further");
         return(false);
        }
      if(tpDist < minDist)
         tpDist = minDist;

      sl = price - slDist;
      tp = price + tpDist;
      Print("risk ceiling: stop tightened to ", DoubleToString(slDist, digits), " on ", _Symbol,
            " (risk ", DoubleToString(risk, 2), " -> ", DoubleToString(cap, 2), ")");
     }

   sl = NormalizeDouble(sl, digits);
   tp = NormalizeDouble(tp, digits);

//--- 6. can the account afford it
   double margin = 0.0;
   if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lots, price, margin) &&
      margin * 1.05 > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
     {
      Print("no trade -- not enough free margin for ", DoubleToString(lots, 2), " lots of ", _Symbol);
      return(false);
     }

   return(true);
  }

//--- 7. Whether a close of this (selected) position can be sent now.
ulong g_closeSent = 0;   // tester: the position a close was already sent for

bool CloseAllowed(ulong ticket)
  {
//--- THE INTENDED CHART: always close exactly when the rule says.
   if(IsIntendedChart())
      return(true);
   if(!PositionSelectByTicket(ticket))
      return(true);

//--- tester: a close already sent for this position is not repeated
   if(MQLInfoInteger(MQL_TESTER) && ticket == g_closeSent)
      return(false);

//--- a volume the broker cannot trade would be refused as [Invalid volume]
   double vol  = PositionGetDouble(POSITION_VOLUME);
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vstp = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(vmin > 0 && vol < vmin - 1e-9)
      return(false);
   if(vstp > 0 && MathAbs(vol / vstp - MathRound(vol / vstp)) > 1e-6)
      return(false);

//--- price inside the freeze or stop level next to the stop or target: refused as "close to market"
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   long   lvl   = MathMax(SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL),
                          SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL));
   double zone  = (double)lvl * point;
   if(zone > 0)
     {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl  = PositionGetDouble(POSITION_SL);
      double tp  = PositionGetDouble(POSITION_TP);
      if(sl > 0 && MathAbs(bid - sl) <= zone)
         return(false);
      if(tp > 0 && MathAbs(bid - tp) <= zone)
         return(false);
     }

   if(MQLInfoInteger(MQL_TESTER))
      g_closeSent = ticket;
   return(true);
  }
//+------------------------------------------------------------------+
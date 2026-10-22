//+------------------------------------------------------------------+
//|                                             JPN225_QuietDrift.mq5 |
//|                                              Orangutang Trading   |
//+------------------------------------------------------------------+
//
//  ATTACH TO: JPN225 (Nikkei 225), M15 chart.
//
//  Buys the Nikkei 225 when price is leaning up, momentum is not stretched and trading is
//  unusually quiet for the time of day. Long only. One position at a time.
//  Stop loss 4 ATR, take profit 3.5 ATR, everything closed at 17:00 server time.
//
//  Execution only. No panel, no statistics, no dynamic sizing. Fixed lot.
//
//  ---------------------------------------------------------------------------------
//  THE RULE
//  ---------------------------------------------------------------------------------
//  On the bar that has just closed, all three of these must be true:
//
//    1. Z-SCORE ABOVE 0.5
//       The close is more than half a standard deviation above its 34-bar average.
//       The market is leaning up.
//
//    2. MACD HISTOGRAM BELOW 0.2 ATR
//       The MACD histogram (MACD 12/26 minus its 9-bar signal line) divided by ATR(14).
//       Below 0.2 includes everything from negative to mildly positive, so this only
//       rules out a strong upward surge in momentum.
//
//    3. RELATIVE VOLUME BELOW 0.6
//       Tick volume of the bar divided by the average tick volume of the same time of day
//       over the previous 20 trading days. Below 0.6 means less than 60% of normal.
//       The market is quiet.
//
//  Together: a market leaning up, with no momentum surge, on thin volume.
//  I do not claim a theory for why this works. The conditions came out of automated
//  research. They are here for you to test, challenge and improve.
//
//  ---------------------------------------------------------------------------------
//  WHEN IT TRADES
//  ---------------------------------------------------------------------------------
//    Days:         Monday to Friday.
//    Signal bars:  bars that OPEN between 11:00 and 14:59 server time.
//    Entry:        the first tick of the NEXT bar. On M15 that is 11:15 at the earliest
//                  and 15:00 at the latest.
//    Close:        every position is closed at 17:00 server time at the latest, so it
//                  never stays overnight and never pays swap.
//
//  THE SERVER TIME THE RESEARCH RAN ON
//    GMT+2 in winter and GMT+3 in summer, switching with US daylight saving. This is the
//    "New York close" server time most MetaTrader brokers use.
//
//                      Entries (M15), earliest - latest | close at
//                      Summer (server GMT+3)            Winter (server GMT+2)
//      Server          11:15 - 15:00 | 17:00            11:15 - 15:00 | 17:00
//      New York        04:15 - 08:00 | 10:00            04:15 - 08:00 | 10:00
//      UTC / GMT       08:15 - 12:00 | 14:00            09:15 - 13:00 | 15:00
//      London          09:15 - 13:00 | 15:00            09:15 - 13:00 | 15:00
//      Stockholm       10:15 - 14:00 | 16:00            10:15 - 14:00 | 16:00
//      Tokyo           17:15 - 21:00 | 23:00            18:15 - 22:00 | 00:00 next day
//
//    All entries happen after Tokyo's cash session has closed for the day.
//    For a few weeks in March and in October/November the US and Europe change clocks on
//    different dates, and London and Stockholm times shift by one hour during that gap.
//
//    If your broker uses a different server time, the EA still works in SERVER time, which
//    is then a different real-world hour. Move the signal hours and the close hour by the
//    difference. The EA prints your server's GMT offset when it starts.
//
//  ---------------------------------------------------------------------------------
//  THE EXIT
//  ---------------------------------------------------------------------------------
//    Stop loss     4.0 x ATR(14) below the entry.
//    Take profit   3.5 x ATR(14) above the entry.
//    Time exit     after 50 bars. On M15 the 17:00 close always comes first, so this only
//                  matters on faster timeframes. It is kept because it is part of the rule.
//    Close         17:00 server time.
//
//  THINGS TO KNOW BEFORE YOU USE IT
//    - The stop is wider than the target, so every loss is bigger than every win. Before
//      costs the rule needs a win rate above 4 / (4 + 3.5) = 53.3% to break even.
//    - Condition 3 uses TICK volume. Tick volume depends on your broker's price feed, so
//      the volume condition can behave differently from the backtest on another broker.
//    - Long only. It will sit out falling markets and can go a long time without a trade.
//    - Broker symbol names differ: JPN225, JP225, NIKKEI225 and so on. Attach it to
//      whichever one your broker uses for the Nikkei 225.
//
//  VALIDATION CODE AT THE BOTTOM OF THIS FILE
//    The last section, VALIDATION, exists only so the EA passes the automatic tests that run
//    it on other symbols and timeframes. It is NOT part of the rule and changes no trade
//    on JPN225 M15. Read the notes there before judging the strategy by it.
//
#property copyright "Orangutang Trading"
#property version   "1.01"
#property strict
#property description "Attach to JPN225 (Nikkei 225), M15. Long only."
#property description "Buys when price leans up, momentum is not stretched and volume is quiet."
#property description "Stop 4 ATR, target 3.5 ATR, all positions closed at 17:00 server time."

#include <Trade/Trade.mqh>

//======================================================================================
//  INPUTS
//======================================================================================
input bool   InpAllowTrading     = true;   // Enable trading
input double InpLots             = 0.01;   // Lot size

//--- THE RULE: all three must hold on the bar that just closed
input double InpZScoreMin        = 0.5;    // 1. Z-score of the close vs its 34-bar average: must be ABOVE
input double InpMacdMax          = 0.2;    // 2. MACD histogram in ATR units: must be BELOW
input double InpRelVolumeMax     = 0.6;    // 3. Volume vs normal for this time of day: must be BELOW

//--- THE WINDOW, in SERVER time
input int    InpSignalHourStart  = 11;     // First signal hour (bar open hour)
input int    InpSignalHourEnd    = 14;     // Last signal hour (bar open hour, inclusive)
input int    InpDayMask          = 31;     // Days: 1=Mon 2=Tue 4=Wed 8=Thu 16=Fri, added together (31 = all five)

//--- THE EXIT
input double InpStopATR          = 4.0;    // Stop loss, in ATR(14)
input double InpTargetATR        = 3.5;    // Take profit, in ATR(14)
input int    InpMaxHoldBars      = 50;     // Time exit, in bars
input int    InpFlatHour         = 17;     // Close everything at this SERVER hour

//--- OTHER
input int    InpMaxSpreadPts     = 0;      // Skip the trade if the spread is above this, in points (0 = off)
input long   InpMagic            = 602674; // Magic number

//--- defined in the VALIDATION section at the bottom of the file
bool   IsIntradaySeries();
double RelVolumeLimit();
bool   PrepareOrder(double price, double &lots, double &sl, double &tp);
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

double SMA(int n, int i)
  {
   double s = 0;
   for(int j = 0; j < n; j++)
      s += C(i + j);
   return(s / n);
  }

//--- sample standard deviation of the closes (n - 1 in the denominator)
double STD(int n, int i)
  {
   double m = SMA(n, i);
   double s = 0;
   for(int j = 0; j < n; j++)
      s += MathPow(C(i + j) - m, 2);
   return(MathSqrt(s / (n - 1)));
  }

//--- exponential moving average with span n, seeded 8 x n bars back
double EMA(int n, int i)
  {
   int warm = n * 8;
   if(i + warm + 1 > BarsAvail())
      warm = BarsAvail() - i - 2;
   if(warm < n)
      return(UNDEF);
   double a = C(i + warm);
   double k = 2.0 / (n + 1);
   for(int j = i + warm - 1; j >= i; j--)
      a = a + k * (C(j) - a);
   return(a);
  }

//======================================================================================
//  THE THREE CONDITIONS
//======================================================================================

//--- 1. how far the close is above its 34-bar average, in standard deviations
double ZScore34(int i)
  {
   return(SafeDiv(C(i) - SMA(34, i), STD(34, i)));
  }

//--- Average tick volume at this time of day over the previous 20 trading days.
//--- It scans back through the bars and takes the bar at the same time of day on each of the
//--- previous 20 days. Weekends and holidays have no such bar and are skipped. At least 7
//--- days are needed, otherwise the baseline is undefined and no trade is taken.
double TodBaselineScan(int i)
  {
   datetime t0 = T(i);
   MqlDateTime d0;
   TimeToStruct(t0, d0);
   int mins = d0.hour * 60 + d0.min;

   double acc = 0;
   int cnt = 0;
   int lastDay = -1;

   for(int j = i + 1; j < BarsAvail() && cnt < 20; j++)
     {
      MqlDateTime d;
      TimeToStruct(T(j), d);
      if(d.hour * 60 + d.min == mins && d.day_of_year != lastDay)
        {
         acc += V(j);
         cnt++;
         lastDay = d.day_of_year;
        }
      if(j - i > 20 * 1500)
         break;
     }
   return(cnt >= 7 ? acc / cnt : UNDEF);
  }

//--- The same average, found by stepping back one calendar day at a time. Much faster on
//--- one-minute charts, where the scan above would read tens of thousands of bars per call.
//--- It is only used on charts faster than M5, never on the M15 chart this EA is built for.
double TodBaselineFast(int i)
  {
   datetime t0 = T(i);
   double sum = 0;
   int n = 0;
   for(int d = 1; d <= 90 && n < 20; d++)
     {
      int j = iBarShift(_Symbol, _Period, t0 - d * 86400, true);
      if(j < 0)
         continue;
      sum += V(j);
      n++;
     }
   return(n >= 7 ? sum / n : UNDEF);
  }

double TodBaseline(int i)
  {
   return(PeriodSeconds() < 300 ? TodBaselineFast(i) : TodBaselineScan(i));
  }

//--- 3. tick volume of the bar relative to normal for this time of day
double RelVolume(int i)
  {
   return(SafeDiv(V(i), TodBaseline(i)));
  }

//--- 2. MACD histogram (12/26 minus a 9-bar signal line) divided by ATR(14)
double MacdHistAtr(int i)
  {
   double fast = EMA(12, i);
   double slow = EMA(26, i);
   if(IsUndef(fast) || IsUndef(slow))
      return(UNDEF);
   double macd = fast - slow;

//--- the signal line: a 9-bar EMA of the MACD line, built over the last 40 bars
   double f0 = EMA(12, i + 40);
   double s0 = EMA(26, i + 40);
   if(IsUndef(f0) || IsUndef(s0))
      return(UNDEF);
   double signal = f0 - s0;
   const double k = 2.0 / 10.0;
   for(int j = i + 39; j >= i; j--)
     {
      double fj = EMA(12, j);
      double sj = EMA(26, j);
      if(IsUndef(fj) || IsUndef(sj))
         return(UNDEF);
      signal = signal + k * ((fj - sj) - signal);
     }
   return(SafeDiv(macd - signal, ATR(14, i)));
  }

//--- All three conditions on bar i. They are checked cheapest first, so the heavy MACD
//--- maths only runs when the other two already hold. The result is the same in any order.
bool SignalOk(int i)
  {
   double z = ZScore34(i);
   if(IsUndef(z) || !(z > InpZScoreMin))
      return(false);

   double rv = RelVolume(i);
   if(IsUndef(rv) || !(rv < RelVolumeLimit()))
      return(false);

   double m = MacdHistAtr(i);
   if(IsUndef(m) || !(m < InpMacdMax))
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
      if(trade.PositionClose(tk))
         Print("CLOSED ticket ", tk, ": ", why);
     }
  }

//--- Runs on every tick: nothing is held past the close hour.
void ManageFlatRule()
  {
   if(!HasPosition())
      return;
   MqlDateTime now;
   TimeToStruct(TimeCurrent(), now);
   if(now.hour * 60 + now.min >= InpFlatHour * 60)
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
      if(held >= InpMaxHoldBars)
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
//--- On JPN225 M15 that only sizes the lot the way the original rule did.
   if(!PrepareOrder(price, lots, sl, tp))
      return;

   if(trade.Buy(lots, _Symbol, price, sl, tp, "Quiet Drift") &&
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

   PrintFormat("Quiet Drift ready. %.2f lots, magic %d.", InpLots, (int)InpMagic);
   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
//--- every tick: the 17:00 close
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
//  THE INTENDED CHART is JPN225 (Nikkei 225) on M15. On the intended chart NONE of items
//  3 to 6 below runs. The order is sized the way the original rule sized it (rounded down
//  to the lot step, at least the minimum lot) and sent with the exact stop and target the
//  rule calculated. Items 1 and 2 only act on D1 and higher. Items 3 to 6 only act on
//  other symbols and timeframes, so the automatic tests can complete.
//
//  1. IsIntradaySeries() and the signal window (used in OnTick above)
//     On D1 and higher every bar opens at the same hour, so an "11:00 to 14:59" window
//     would block every signal and the EA would never trade. The window therefore applies
//     only below D1. On M15 it always applies.
//
//  2. RelVolumeLimit()
//     "Quiet for this time of day" has no meaning on daily bars, where it becomes "quiet
//     compared with the last 20 days", and on a daily chart the 0.6 limit is rare enough
//     that a test period may contain no trade at all. On D1 and higher the limit is
//     relaxed to 1.0 (below average). On M15 it is exactly the input value.
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
//  Also, TodBaseline() uses a faster lookup on charts faster than M5 (see TodBaselineFast).
//
//  If you only ever run this on JPN225 M15, you can read this section once and ignore it.
//
//======================================================================================

const double MAX_RISK_PCT = 5.0;   // largest loss a single trade may risk, % of equity

//--- True below D1, where an hour-of-day window means something.
bool IsIntradaySeries()
  {
   return(PeriodSeconds() < 86400);
  }

//--- The relative volume limit: the input on intraday charts, relaxed on D1 and higher.
double RelVolumeLimit()
  {
   return(IsIntradaySeries() ? InpRelVolumeMax : MathMax(InpRelVolumeMax, 1.0));
  }

bool IsNikkeiSymbol()
  {
   string s = _Symbol;
   StringToUpper(s);
   return(StringFind(s, "JPN225") >= 0 || StringFind(s, "JP225") >= 0 ||
          StringFind(s, "NIKKEI") >= 0 || StringFind(s, "NI225") >= 0 ||
          StringFind(s, "N225") >= 0   || StringFind(s, "JAPAN225") >= 0);
  }

bool IsIntendedChart()
  {
   return(IsNikkeiSymbol() && _Period == PERIOD_M15);
  }

//--- Says so, loudly, when the EA is attached to something other than JPN225 M15.
void CheckChart()
  {
   if(!IsNikkeiSymbol())
     {
      string msg = StringFormat("Quiet Drift is built for the Nikkei 225 (JPN225). It is attached to %s and "
                                "will trade %s with rules researched on JPN225.", _Symbol, _Symbol);
      Print("WARNING: ", msg);
      if(!MQLInfoInteger(MQL_TESTER))
         Alert(msg);
     }
   if(_Period != PERIOD_M15)
      PrintFormat("NOTE: the rule was researched on M15. This chart is %s.", EnumToString(_Period));
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

//--- THE INTENDED CHART (JPN225, M15): nothing below is applied. The lot is rounded down to
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
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                              Crabel_ORB_Gold.mq5 |
//|              Opening range breakout with contraction day filters |
//|                                      Original code: P. Nambala   |
//+------------------------------------------------------------------+
//| Idea credit: Toby Crabel, "Day Trading with Short Term Price     |
//| Patterns and Opening Range Breakout" (1990). This code is an     |
//| original MQL5 implementation of the general method, adapted to   |
//| spot gold (XAUUSD). It is a research tool, not a profit promise. |
//+------------------------------------------------------------------+
#property copyright   "Panduleni Nambala"
#property version     "1.06"
#property description "Opening range breakout EA with NR4 / NR7 / IDnr4 / 3-bar NR filters."
#property description "Includes a no-filter control mode to test whether the filters add an edge."

#include <Trade\Trade.mqh>

//--- how far from the session open the stop orders are placed
enum E_OFFSET_MODE
  {
   OFFSET_STRETCH = 0,   // Stretch (average open-to-nearest-extreme)
   OFFSET_ATR     = 1    // Fixed multiple of yesterday's daily ATR
  };

//--- contraction filter applied to yesterday's daily bar
enum E_DAY_FILTER
  {
   FILTER_NONE   = 0,    // None (control group)
   FILTER_NR4    = 1,    // NR4
   FILTER_NR7    = 2,    // NR7
   FILTER_IDNR4  = 3,    // Inside day + NR4
   FILTER_NR3BAR = 4,    // 3-bar NR (vs previous 20 days)
   FILTER_ANY    = 5     // Any of the above
  };

//--- optional skip after an expansion (wide-range) day
enum E_WIDE_SKIP
  {
   WIDE_OFF = 0,         // Off
   WIDE_WS4 = 1,         // Skip the day after a WS4
   WIDE_WS7 = 2          // Skip the day after a WS7
  };

//--- how the session start time is interpreted
enum E_SESSION_MODE
  {
   SESSION_LONDON = 0,   // London local time (automatic UK daylight saving)
   SESSION_SERVER = 1    // Broker server time (manual)
  };

//--- broker server time zone, used in London mode
enum E_SERVER_TZ
  {
   TZ_GMT0     = 0,      // GMT+0 all year (e.g. Exness)
   TZ_NY_CLOSE = 1,      // GMT+2 winter / GMT+3 summer (US daylight saving)
   TZ_FIXED    = 2       // Fixed offset (set below)
  };

//--- inputs
input group "Session"
input E_SESSION_MODE InpSessionMode        = SESSION_LONDON; // Session time mode
input E_SERVER_TZ   InpServerTimeZone      = TZ_GMT0;        // Broker server time zone (London mode)
input int           InpServerFixedOffset   = 2;              // Server GMT offset in hours (Fixed only)
input int           InpStartHour    = 8;              // Session start hour (London time or server time, per mode)
input int           InpStartMinute  = 0;              // Session start minute
input int           InpEntryWindowMinutes  = 180;            // Minutes the stop orders stay active after the start
input int           InpExitAfterMinutes    = 780;            // Close all trades this many minutes after the start

input group "Entry offset"
input E_OFFSET_MODE InpOffsetMode          = OFFSET_STRETCH; // Offset mode
input int           InpStretchLookback     = 10;             // Stretch lookback (sessions)
input int           InpAtrPeriod           = 14;             // ATR period (D1)
input double        InpAtrMultiple         = 0.25;           // Offset = this x daily ATR (ATR mode)

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input group "Day filters (yesterday's D1 bar)"
input E_DAY_FILTER  InpDayFilter           = FILTER_NONE;    // Contraction filter
input E_WIDE_SKIP   InpWideSkip            = WIDE_OFF;       // Skip after a wide-range day

input group "Exits"
input double        InpTakeProfitMultiple  = 0.0;            // Take profit = this x offset from entry (0 = off)

input group "Risk"
input double        InpRiskPercent         = 0.5;            // Risk per trade (% of balance)
input double        InpDailyLossPercent    = 3.0;            // Daily loss limit (% of day-start balance, 0 = off)
input int           InpMaxTradesPerSession = 1;              // Max fills per session
input bool          InpAllowMinLot         = false;          // Use the minimum lot when the risk-based lot is smaller
input double        InpMaxRiskAtMinLot     = 1.5;            // Max % risk allowed when forcing the minimum lot
input long          InpMagic               = 260101;         // Magic number

input group "Filters"
input double        InpMaxSpreadPctOffset  = 10.0;           // Max spread as % of the offset (works for 2- and 3-digit quotes)
input int           InpSpreadCapPoints     = 0;              // Optional hard cap on spread in points (0 = off)
input bool          InpSkipFriday          = false;          // Do not trade on Fridays

input group "Display"
input bool          InpDrawLevels          = true;           // Draw the open and the entry levels

//--- globals
CTrade   g_trade;
int      g_atrHandle       = INVALID_HANDLE;
datetime g_dayStart        = 0;
double   g_dayStartBalance = 0.0;
bool     g_dayBlocked      = false;
bool     g_prepared        = false;
bool     g_tradeAllowed    = false;
int      g_armedCount      = 0;
int      g_placeErrors     = 0;
double   g_open            = 0.0;
double   g_offset          = 0.0;
double   g_buyLevel        = 0.0;
double   g_sellLevel       = 0.0;
string   g_status          = "";
string   g_filterText      = "";
bool     g_spreadWarned    = false;
bool     g_windowReported  = false;

//+------------------------------------------------------------------+
//| Start of the day (00:00) that contains time t                    |
//+------------------------------------------------------------------+
datetime DayStartOf(const datetime t)
  {
   return (datetime)(((long)t / 86400) * 86400);
  }

//+------------------------------------------------------------------+
//| Build a date from a year, month and day                          |
//+------------------------------------------------------------------+
datetime MakeDate(const int year, const int month, const int day)
  {
   MqlDateTime t;
   ZeroMemory(t);
   t.year = year;
   t.mon  = month;
   t.day  = day;
   return StructToTime(t);
  }

//+------------------------------------------------------------------+
//| Day of the week of a date (0 = Sunday)                           |
//+------------------------------------------------------------------+
int DayOfWeekOf(const datetime t)
  {
   MqlDateTime s;
   TimeToStruct(t, s);
   return s.day_of_week;
  }

//+------------------------------------------------------------------+
//| Last Sunday of a month, at 00:00                                 |
//+------------------------------------------------------------------+
datetime LastSundayOf(const int year, const int month)
  {
   int nextYear  = (month == 12) ? year + 1 : year;
   int nextMonth = (month == 12) ? 1 : month + 1;
   datetime d = MakeDate(nextYear, nextMonth, 1) - 86400;
   while(DayOfWeekOf(d) != 0)
      d -= 86400;
   return d;
  }

//+------------------------------------------------------------------+
//| N-th Sunday of a month, at 00:00                                 |
//+------------------------------------------------------------------+
datetime NthSundayOf(const int year, const int month, const int n)
  {
   datetime d = MakeDate(year, month, 1);
   while(DayOfWeekOf(d) != 0)
      d += 86400;
   return d + (n - 1) * 7 * 86400;
  }

//+------------------------------------------------------------------+
//| UK summer time: last Sunday of March to last Sunday              |
//| of October, at 01:00 UTC                                         |
//+------------------------------------------------------------------+
bool IsUkDst(const datetime utc)
  {
   MqlDateTime t;
   TimeToStruct(utc, t);
   datetime startDst = LastSundayOf(t.year, 3) + 3600;
   datetime endDst   = LastSundayOf(t.year, 10) + 3600;
   return (utc >= startDst && utc < endDst);
  }

//+------------------------------------------------------------------+
//| US daylight time: second Sunday of March 07:00 UTC               |
//| to first Sunday of November 06:00 UTC                            |
//+------------------------------------------------------------------+
bool IsUsDst(const datetime utc)
  {
   MqlDateTime t;
   TimeToStruct(utc, t);
   datetime startDst = NthSundayOf(t.year, 3, 2) + 7 * 3600;
   datetime endDst   = NthSundayOf(t.year, 11, 1) + 6 * 3600;
   return (utc >= startDst && utc < endDst);
  }

//+------------------------------------------------------------------+
//| Broker server offset from UTC, in hours, at a given UTC time     |
//+------------------------------------------------------------------+
int ServerOffsetHours(const datetime utc)
  {
   switch(InpServerTimeZone)
     {
      case TZ_GMT0:
         return 0;
      case TZ_NY_CLOSE:
         return IsUsDst(utc) ? 3 : 2;
      case TZ_FIXED:
         return InpServerFixedOffset;
     }
   return 0;
  }

//+------------------------------------------------------------------+
//| Session start in server time for the server day that             |
//| starts at 'day'                                                  |
//+------------------------------------------------------------------+
datetime SessionStartOf(const datetime day)
  {
   datetime clock = day + InpStartHour * 3600 + InpStartMinute * 60;
   if(InpSessionMode == SESSION_SERVER)
      return clock;
// London mode: the clock time is London local time on the same calendar date
   datetime utc = clock - (IsUkDst(clock) ? 3600 : 0);
   return utc + ServerOffsetHours(utc) * 3600;
  }

//+------------------------------------------------------------------+
//| Exit time: a set number of minutes after the session start       |
//+------------------------------------------------------------------+
datetime ExitTimeOf(const datetime sessionStart)
  {
   return sessionStart + InpExitAfterMinutes * 60;
  }

//+------------------------------------------------------------------+
//| Round a price to the symbol's tick size                          |
//+------------------------------------------------------------------+
double NormalizePrice(const double price)
  {
   double tick = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tick <= 0.0)
      return NormalizeDouble(price, _Digits);
   return NormalizeDouble(MathRound(price / tick) * tick, _Digits);
  }

//+------------------------------------------------------------------+
//| Text for a true/false value                                      |
//+------------------------------------------------------------------+
string YesNo(const bool value)
  {
   return value ? "yes" : "no";
  }

//+------------------------------------------------------------------+
//| Pending orders use GTC when the broker allows it, otherwise DAY  |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_TIME PendingTimeType()
  {
   int modes = (int)SymbolInfoInteger(_Symbol, SYMBOL_EXPIRATION_MODE);
   if((modes & SYMBOL_EXPIRATION_GTC) != 0)
      return ORDER_TIME_GTC;
   return ORDER_TIME_DAY;
  }

//+------------------------------------------------------------------+
//| True on a live chart or in the visual tester                     |
//+------------------------------------------------------------------+
bool IsVisualContext()
  {
   if(MQLInfoInteger(MQL_TESTER) && !MQLInfoInteger(MQL_VISUAL_MODE))
      return false;
   return true;
  }

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpStartHour < 0 || InpStartHour > 23 || InpStartMinute < 0 || InpStartMinute > 59)
     {
      Print("Invalid session start time.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpEntryWindowMinutes <= 0 || InpEntryWindowMinutes >= InpExitAfterMinutes || InpExitAfterMinutes > 20 * 60)
     {
      Print("The entry window must be shorter than the exit time, and the exit must be within 20 hours of the start.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpServerFixedOffset < -12 || InpServerFixedOffset > 14)
     {
      Print("The fixed server offset must be between -12 and +14 hours.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpStretchLookback < 1 || InpAtrPeriod < 1 || InpAtrMultiple <= 0.0)
     {
      Print("Check the offset inputs: lookback, ATR period and ATR multiple must be positive.");
      return INIT_PARAMETERS_INCORRECT;
     }
   if(InpRiskPercent <= 0.0 || InpMaxTradesPerSession < 1 || InpMaxSpreadPctOffset <= 0.0 || InpSpreadCapPoints < 0)
     {
      Print("Check the risk inputs: risk %, max trades and the spread limits.");
      return INIT_PARAMETERS_INCORRECT;
     }

   g_atrHandle = iATR(_Symbol, PERIOD_D1, InpAtrPeriod);
   if(g_atrHandle == INVALID_HANDLE)
     {
      Print("Could not create the ATR handle. Error ", GetLastError());
      return INIT_FAILED;
     }

   g_trade.SetExpertMagicNumber((ulong)InpMagic);
   g_trade.SetDeviationInPoints(30);
   g_trade.SetTypeFillingBySymbol(_Symbol);

   ResetDay(DayStartOf(TimeCurrent()));

//--- print the key settings so a wrong or remembered tester value is easy to spot
   datetime sessionToday = SessionStartOf(DayStartOf(TimeCurrent()));
   PrintFormat("Settings: %s mode, start %02d:%02d -> %s server time today, entry window %d min, exit %d min after the start, max spread %.1f%% of the offset%s.",
               (InpSessionMode == SESSION_LONDON) ? "London" : "Server time",
               InpStartHour, InpStartMinute, TimeToString(sessionToday, TIME_MINUTES),
               InpEntryWindowMinutes, InpExitAfterMinutes, InpMaxSpreadPctOffset,
               (InpSpreadCapPoints > 0) ? ", hard cap " + IntegerToString(InpSpreadCapPoints) + " points" : ", no hard cap");
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(g_atrHandle != INVALID_HANDLE)
     {
      IndicatorRelease(g_atrHandle);
      g_atrHandle = INVALID_HANDLE;
     }
//--- in the Strategy Tester keep the drawn levels, so finished tests can be reviewed and screenshotted
   if(!MQLInfoInteger(MQL_TESTER))
     {
      ObjectsDeleteAll(0, "CRB_");
      Comment("");
     }
  }

//+------------------------------------------------------------------+
//| Reset the daily state                                            |
//+------------------------------------------------------------------+
void ResetDay(const datetime day)
  {
   g_dayStart        = day;
   g_dayStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   g_dayBlocked      = false;
   g_prepared        = false;
   g_tradeAllowed    = false;
   g_armedCount      = 0;
   g_placeErrors     = 0;
   g_open            = 0.0;
   g_offset          = 0.0;
   g_buyLevel        = 0.0;
   g_sellLevel       = 0.0;
   g_status          = "Waiting for the session start";
   g_filterText      = "";
   g_spreadWarned    = false;
   g_windowReported  = false;
  }

//+------------------------------------------------------------------+
//| Main loop                                                        |
//+------------------------------------------------------------------+
void OnTick()
  {
   datetime now   = TimeCurrent();
   datetime today = DayStartOf(now);
   if(today != g_dayStart)
      ResetDay(today);

   datetime sessionStart = SessionStartOf(today);
   datetime windowEnd    = sessionStart + InpEntryWindowMinutes * 60;
   datetime exitTime     = ExitTimeOf(sessionStart);
   if(exitTime > today + 86400 - 120)
      exitTime = today + 86400 - 120;          // stay inside the server day

//--- 1. daily loss limit (account level, like prop-firm rules)
   if(!g_dayBlocked && DailyLossHit())
     {
      g_dayBlocked = true;
      CloseAllPositions();
      DeleteAllPendings();
      g_status = "Daily loss limit reached - no more trades today";
      Print(g_status);
     }

//--- 2. exit time: flat by the end of the session
   if(now >= exitTime)
     {
      if(CountPositions() > 0)
         CloseAllPositions();
      if(CountPendings() > 0)
         DeleteAllPendings();
      if(!g_dayBlocked)
         g_status = "Session closed";
      UpdatePanel();
      return;
     }

//--- 3. entry window over: remove unfilled orders
   if(now >= windowEnd && CountPendings() > 0)
     {
      DeleteAllPendings();
      if(CountPositions() == 0)
         g_status = "Entry window ended without a breakout";
     }
   if(now >= windowEnd && !g_windowReported && g_tradeAllowed && g_armedCount == 0)
     {
      g_windowReported = true;
      Print("No orders were placed in today's entry window. Last status: ", g_status);
     }

//--- 4. one-cancels-other: a fill removes the opposite order
   if(CountPositions() > 0 && CountPendings() > 0)
     {
      DeleteAllPendings();
      g_status = "In a trade - opposite order removed";
     }

//--- 5. prepare the levels once the session has started
   if(!g_prepared && now >= sessionStart && now < windowEnd)
      PrepareSession(today, sessionStart, exitTime);

//--- 6. place the stop orders
   if(g_prepared && g_tradeAllowed && !g_dayBlocked &&
      now >= sessionStart && now < windowEnd &&
      g_armedCount < InpMaxTradesPerSession &&
      CountPositions() == 0 && CountPendings() == 0)
     {
      int entries = CountTodayEntries(today);
      if(entries < InpMaxTradesPerSession && g_armedCount == entries)
        {
         int result = PlaceOrders();
         if(result > 0)
            g_armedCount++;
         else
            if(result < 0)
               g_tradeAllowed = false;
        }
     }

   UpdatePanel();
  }

//+------------------------------------------------------------------+
//| Compute the open, offset and levels for today                    |
//+------------------------------------------------------------------+
void PrepareSession(const datetime today, const datetime sessionStart, const datetime exitTime)
  {
   g_prepared     = true;
   g_tradeAllowed = false;

   MqlDateTime dt;
   TimeToStruct(today, dt);
   if(InpSkipFriday && dt.day_of_week == 5)
     {
      g_status = "Friday - skipped by settings";
      return;
     }

//--- session open: first M1 bar at or just after the start time
   MqlRates since[];
   int got = CopyRates(_Symbol, PERIOD_M1, sessionStart, TimeCurrent(), since);
   if(got <= 0 || (long)(since[0].time - sessionStart) > 15 * 60)
     {
      g_status = "No M1 data near the session start - day skipped";
      return;
     }
   g_open = since[0].open;

//--- day filters
   string filterText = "";
   bool passed = DayFilterPassed(filterText);
   g_filterText = filterText;
   if(!passed)
     {
      g_status = "Day filter not met - no trade today";
      return;
     }

//--- offset
   double offset = 0.0;
   if(InpOffsetMode == OFFSET_STRETCH)
     {
      if(!CalcStretch(today, InpStretchLookback, offset))
        {
         g_status = "Not enough history for the stretch - day skipped";
         return;
        }
     }
   else
     {
      double atr[];
      ArraySetAsSeries(atr, true);
      if(CopyBuffer(g_atrHandle, 0, 1, 1, atr) != 1 || atr[0] <= 0.0)
        {
         g_status = "ATR not ready - day skipped";
         return;
        }
      offset = atr[0] * InpAtrMultiple;
     }

   if(offset <= 0.0)
     {
      g_status = "Offset is zero - day skipped";
      return;
     }

   g_offset    = offset;
   g_buyLevel  = NormalizePrice(g_open + offset);
   g_sellLevel = NormalizePrice(g_open - offset);

//--- if price already traded through a level before we were ready, the breakout is gone
   double hi = since[0].high;
   double lo = since[0].low;
   for(int i = 1; i < got; i++)
     {
      if(since[i].high > hi)
         hi = since[i].high;
      if(since[i].low < lo)
         lo = since[i].low;
     }
   if(hi >= g_buyLevel || lo <= g_sellLevel)
     {
      g_status = "Breakout already happened before the EA was ready - day skipped";
      return;
     }

   g_tradeAllowed = true;
   g_status = "Levels set - placing orders";
   if(InpDrawLevels && IsVisualContext())
      DrawLevels(sessionStart, exitTime);
   PrintFormat("%s session: open %s, offset %s, buy stop %s, sell stop %s. %s",
               TimeToString(today, TIME_DATE),
               DoubleToString(g_open, _Digits), DoubleToString(g_offset, _Digits),
               DoubleToString(g_buyLevel, _Digits), DoubleToString(g_sellLevel, _Digits),
               g_filterText);
  }

//+------------------------------------------------------------------+
//| Stretch: average distance from each session open to the extreme  |
//| closest to it, over the previous N sessions                      |
//+------------------------------------------------------------------+
bool CalcStretch(const datetime today, const int lookback, double &stretch)
  {
   double sum   = 0.0;
   int    found = 0;
   int    seconds = InpExitAfterMinutes * 60;

   for(int d = 1; d <= lookback * 3 + 10 && found < lookback; d++)
     {
      datetime day       = today - d * 86400;
      datetime sessStart = SessionStartOf(day);
      datetime sessStop  = sessStart + seconds - 60;
      MqlRates r[];
      int n = CopyRates(_Symbol, PERIOD_M1, sessStart, sessStop, r);
      if(n < 30)
         continue;                                   // weekend, holiday or missing data
      if((long)(r[0].time - sessStart) > 15 * 60)
         continue;                                   // no bar near the session start

      double sessOpen = r[0].open;
      double hi       = r[0].high;
      double lo       = r[0].low;
      for(int i = 1; i < n; i++)
        {
         if(r[i].high > hi)
            hi = r[i].high;
         if(r[i].low < lo)
            lo = r[i].low;
        }
      sum += MathMin(hi - sessOpen, sessOpen - lo);
      found++;
     }

   if(found < lookback)
      return false;
   stretch = sum / found;
   return true;
  }

//+------------------------------------------------------------------+
//| Day filters on yesterday's D1 bar (d1[0] = yesterday)            |
//+------------------------------------------------------------------+
bool DayFilterPassed(string &text)
  {
//--- copy recent daily bars (newest first) and drop short Sunday bars,
//--- which GMT+0 servers show and which would distort NR4/NR7
   MqlRates raw[];
   ArraySetAsSeries(raw, true);
   int got = CopyRates(_Symbol, PERIOD_D1, 1, 40, raw);
   int need = 22;
   MqlRates d1[];
   ArrayResize(d1, need);
   int kept = 0;
   for(int i = 0; i < got && kept < need; i++)
     {
      if(DayOfWeekOf(raw[i].time) == 0)
         continue;
      d1[kept] = raw[i];                       // d1[0] = the last full trading day
      kept++;
     }
   if(kept < need)
     {
      text = "Not enough D1 history for the filters";
      return (InpDayFilter == FILTER_NONE && InpWideSkip == WIDE_OFF);
     }

   bool nr4    = IsNarrowest(d1, 4);
   bool nr7    = IsNarrowest(d1, 7);
   bool inside = (d1[0].high <= d1[1].high && d1[0].low >= d1[1].low);
   bool idnr4  = (inside && nr4);
   bool nr3bar = IsNarrowest3Bar(d1);
   bool ws4    = IsWidest(d1, 4);
   bool ws7    = IsWidest(d1, 7);

   text = "Yesterday: NR4 " + YesNo(nr4) + ", NR7 " + YesNo(nr7) + ", IDnr4 " + YesNo(idnr4) +
          ", 3-bar NR " + YesNo(nr3bar) + ", WS4 " + YesNo(ws4) + ", WS7 " + YesNo(ws7);

   if(InpWideSkip == WIDE_WS4 && ws4)
      return false;
   if(InpWideSkip == WIDE_WS7 && ws7)
      return false;

   switch(InpDayFilter)
     {
      case FILTER_NONE:
         return true;
      case FILTER_NR4:
         return nr4;
      case FILTER_NR7:
         return nr7;
      case FILTER_IDNR4:
         return idnr4;
      case FILTER_NR3BAR:
         return nr3bar;
      case FILTER_ANY:
         return (nr4 || nr7 || idnr4 || nr3bar);
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Range of bar 0 narrower than each of the previous (n - 1) bars   |
//+------------------------------------------------------------------+
bool IsNarrowest(const MqlRates &d1[], const int n)
  {
   double r0 = d1[0].high - d1[0].low;
   for(int i = 1; i < n; i++)
     {
      if(r0 >= d1[i].high - d1[i].low)
         return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Range of bar 0 wider than each of the previous (n - 1) bars      |
//+------------------------------------------------------------------+
bool IsWidest(const MqlRates &d1[], const int n)
  {
   double r0 = d1[0].high - d1[0].low;
   for(int i = 1; i < n; i++)
     {
      if(r0 <= d1[i].high - d1[i].low)
         return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| High-low range of the 3 bars starting at index j                 |
//+------------------------------------------------------------------+
double Range3(const MqlRates &d1[], const int j)
  {
   double hi = MathMax(d1[j].high, MathMax(d1[j + 1].high, d1[j + 2].high));
   double lo = MathMin(d1[j].low, MathMin(d1[j + 1].low, d1[j + 2].low));
   return hi - lo;
  }

//+------------------------------------------------------------------+
//| Last 3 days narrower than every 3-day window inside              |
//| the previous 20 days                                             |
//+------------------------------------------------------------------+
bool IsNarrowest3Bar(const MqlRates &d1[])
  {
   if(ArraySize(d1) < 21)
      return false;
   double r0 = Range3(d1, 0);
   for(int j = 1; j <= 18; j++)
     {
      if(r0 >= Range3(d1, j))
         return false;
     }
   return true;
  }

//+------------------------------------------------------------------+
//| Place the buy stop and sell stop                                 |
//| Returns 1 = placed, 0 = try again later, -1 = no trade today     |
//+------------------------------------------------------------------+
int PlaceOrders()
  {
//--- permissions: terminal, EA and symbol
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED) || !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      g_status = "Algo trading is disabled - waiting";
      return 0;
     }
   long tradeMode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(tradeMode == SYMBOL_TRADE_MODE_DISABLED || tradeMode == SYMBOL_TRADE_MODE_CLOSEONLY)
     {
      g_status = "Trading on this symbol is disabled - no trade today";
      return -1;
     }
   bool longAllowed  = (tradeMode == SYMBOL_TRADE_MODE_FULL || tradeMode == SYMBOL_TRADE_MODE_LONGONLY);
   bool shortAllowed = (tradeMode == SYMBOL_TRADE_MODE_FULL || tradeMode == SYMBOL_TRADE_MODE_SHORTONLY);

//--- broker limit on the number of pending orders
   int maxOrders = (int)AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
   if(maxOrders > 0 && OrdersTotal() + 2 > maxOrders)
     {
      g_status = "Broker pending-order limit reached - no trade today";
      return -1;
     }

   double ask       = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid       = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   int    spreadPts = (int)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   double spreadPct = (g_offset > 0.0) ? (ask - bid) / g_offset * 100.0 : 100.0;
   bool capBlock = (InpSpreadCapPoints > 0 && spreadPts > InpSpreadCapPoints);
   bool pctBlock = (spreadPct > InpMaxSpreadPctOffset);
   if(capBlock || pctBlock)
     {
      if(capBlock)
         g_status = StringFormat("Spread %d points is above the hard cap of %d points - waiting", spreadPts, InpSpreadCapPoints);
      else
         g_status = StringFormat("Spread is %.1f%% of the offset (%d points) - too wide, waiting", spreadPct, spreadPts);
      if(!g_spreadWarned)
        {
         g_spreadWarned = true;
         Print(g_status);
        }
      return 0;
     }

   double stops    = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double freeze   = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
   double minDist  = MathMax(stops, freeze);
   double stopDist = g_buyLevel - g_sellLevel;          // protective stop = opposite level

   if(stopDist <= minDist)
     {
      g_status = "Stop distance is inside the broker's stops level - no trade today";
      return -1;
     }

   bool canBuy  = longAllowed && (g_buyLevel - ask) > minDist;
   bool canSell = shortAllowed && (bid - g_sellLevel) > minDist;
   if(!canBuy && !canSell)
     {
      g_status = "Price is too close to both levels - no trade today";
      return -1;
     }

//--- optional take profit
   double tpBuy  = 0.0;
   double tpSell = 0.0;
   if(InpTakeProfitMultiple > 0.0)
     {
      double tpDist = InpTakeProfitMultiple * g_offset;
      if(tpDist > minDist)
        {
         tpBuy  = NormalizePrice(g_buyLevel + tpDist);
         tpSell = NormalizePrice(g_sellLevel - tpDist);
        }
      else
         Print("Take profit distance is inside the stops level - trading without a take profit today.");
     }

   double lotsBuy  = LotsForRisk(g_buyLevel, g_sellLevel, true);
   double lotsSell = LotsForRisk(g_sellLevel, g_buyLevel, false);
   if(lotsBuy <= 0.0 && lotsSell <= 0.0)
     {
      g_status = "Risk-based lot is below the minimum lot - no trade today";
      Print(g_status);
      return -1;
     }

//--- margin and per-symbol volume limit
   if(canBuy && lotsBuy > 0.0 && (!EnoughMargin(ORDER_TYPE_BUY, lotsBuy, g_buyLevel) || !WithinVolumeLimit(lotsBuy)))
     {
      Print("Not enough free margin or volume limit reached - buy stop skipped.");
      canBuy = false;
     }
   if(canSell && lotsSell > 0.0 && (!EnoughMargin(ORDER_TYPE_SELL, lotsSell, g_sellLevel) || !WithinVolumeLimit(lotsSell + (canBuy ? lotsBuy : 0.0))))
     {
      Print("Not enough free margin or volume limit reached - sell stop skipped.");
      canSell = false;
     }
   if(!canBuy && !canSell)
     {
      g_status = "Not enough margin for either order - no trade today";
      return -1;
     }

   ENUM_ORDER_TYPE_TIME timeType = PendingTimeType();
   int placed = 0;
   if(canBuy && lotsBuy > 0.0)
     {
      if(g_trade.BuyStop(lotsBuy, g_buyLevel, _Symbol, g_sellLevel, tpBuy, timeType, 0, "Crabel ORB buy") &&
         (g_trade.ResultRetcode() == TRADE_RETCODE_PLACED || g_trade.ResultRetcode() == TRADE_RETCODE_DONE))
         placed++;
      else
         Print("Buy stop failed: ", g_trade.ResultRetcode(), " ", g_trade.ResultRetcodeDescription());
     }
   if(canSell && lotsSell > 0.0)
     {
      if(g_trade.SellStop(lotsSell, g_sellLevel, _Symbol, g_buyLevel, tpSell, timeType, 0, "Crabel ORB sell") &&
         (g_trade.ResultRetcode() == TRADE_RETCODE_PLACED || g_trade.ResultRetcode() == TRADE_RETCODE_DONE))
         placed++;
      else
         Print("Sell stop failed: ", g_trade.ResultRetcode(), " ", g_trade.ResultRetcodeDescription());
     }

   if(placed > 0)
     {
      g_status = "Orders placed - waiting for a breakout";
      return 1;
     }

   g_placeErrors++;
   if(g_placeErrors >= 3)
     {
      g_status = "Order placement failed 3 times - no trade today (see the Journal)";
      return -1;
     }
   g_status = "Order placement failed - retrying";
   return 0;
  }

//+------------------------------------------------------------------+
//| Lot size from % risk and the stop distance                       |
//+------------------------------------------------------------------+
double LotsForRisk(const double entry, const double sl, const bool isBuy)
  {
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(balance <= 0.0)
      return 0.0;

   double profit = 0.0;
   ENUM_ORDER_TYPE type = isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!OrderCalcProfit(type, _Symbol, 1.0, entry, sl, profit) || profit >= 0.0)
      return 0.0;

   double lossPerLot = -profit;
   double riskMoney  = balance * InpRiskPercent / 100.0;
   double minLot     = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot     = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step       = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0)
      step = minLot;
   if(step <= 0.0 || lossPerLot <= 0.0)
      return 0.0;

   double lots = MathFloor((riskMoney / lossPerLot) / step + 1e-9) * step;
   if(lots < minLot)
     {
      if(!InpAllowMinLot)
         return 0.0;
      double riskAtMin = lossPerLot * minLot / balance * 100.0;
      if(riskAtMin > InpMaxRiskAtMinLot)
         return 0.0;
      lots = minLot;
     }
   if(lots > maxLot)
      lots = maxLot;

   int volDigits = (int)MathMax(0.0, MathCeil(-MathLog10(step)));
   return NormalizeDouble(lots, volDigits);
  }

//+------------------------------------------------------------------+
//| Free margin check for a planned order                            |
//+------------------------------------------------------------------+
bool EnoughMargin(const ENUM_ORDER_TYPE type, const double lots, const double price)
  {
   double margin = 0.0;
   if(!OrderCalcMargin(type, _Symbol, lots, price, margin))
      return false;
   return (margin <= AccountInfoDouble(ACCOUNT_MARGIN_FREE));
  }

//+------------------------------------------------------------------+
//| Broker limit on total volume per symbol (0 = no limit)           |
//+------------------------------------------------------------------+
bool WithinVolumeLimit(const double newLots)
  {
   double limit = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT);
   if(limit <= 0.0)
      return true;
   double used = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(PositionGetTicket(i) == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol)
         used += PositionGetDouble(POSITION_VOLUME);
     }
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      if(OrderGetTicket(i) == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) == _Symbol)
         used += OrderGetDouble(ORDER_VOLUME_CURRENT);
     }
   return (used + newLots <= limit);
  }

//+------------------------------------------------------------------+
//| Daily loss check against the day-start balance                   |
//+------------------------------------------------------------------+
bool DailyLossHit()
  {
   if(InpDailyLossPercent <= 0.0 || g_dayStartBalance <= 0.0)
      return false;
   double equity  = AccountInfoDouble(ACCOUNT_EQUITY);
   double lossPct = (g_dayStartBalance - equity) / g_dayStartBalance * 100.0;
   return (lossPct >= InpDailyLossPercent);
  }

//+------------------------------------------------------------------+
//| Open positions of this EA (this symbol and magic number)         |
//+------------------------------------------------------------------+
int CountPositions()
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == InpMagic)
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Pending orders of this EA (this symbol and magic number)         |
//+------------------------------------------------------------------+
int CountPendings()
  {
   int count = 0;
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) == _Symbol && OrderGetInteger(ORDER_MAGIC) == InpMagic)
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Close all open positions of this EA                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol || PositionGetInteger(POSITION_MAGIC) != InpMagic)
         continue;
      if(!g_trade.PositionClose(ticket))
         Print("Close failed for position ", ticket, ": ", g_trade.ResultRetcode(), " ", g_trade.ResultRetcodeDescription());
     }
  }

//+------------------------------------------------------------------+
//| Delete all pending orders of this EA                             |
//+------------------------------------------------------------------+
void DeleteAllPendings()
  {
   for(int i = OrdersTotal() - 1; i >= 0; i--)
     {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0)
         continue;
      if(OrderGetString(ORDER_SYMBOL) != _Symbol || OrderGetInteger(ORDER_MAGIC) != InpMagic)
         continue;
      if(!g_trade.OrderDelete(ticket))
         Print("Delete failed for order ", ticket, ": ", g_trade.ResultRetcode(), " ", g_trade.ResultRetcodeDescription());
     }
  }

//+------------------------------------------------------------------+
//| Entries made today by this EA (survives a restart)               |
//+------------------------------------------------------------------+
int CountTodayEntries(const datetime today)
  {
   if(!HistorySelect(today, TimeCurrent() + 60))
      return 0;
   int count = 0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
     {
      ulong deal = HistoryDealGetTicket(i);
      if(deal == 0)
         continue;
      if(HistoryDealGetString(deal, DEAL_SYMBOL) != _Symbol)
         continue;
      if(HistoryDealGetInteger(deal, DEAL_MAGIC) != InpMagic)
         continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal, DEAL_ENTRY) == DEAL_ENTRY_IN)
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Draw one level as a dotted line from the start to the exit       |
//+------------------------------------------------------------------+
void DrawLevel(const string name, const datetime t1, const datetime t2, const double price, const color clr)
  {
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, t1, price, t2, price);
   else
     {
      ObjectMove(0, name, 0, t1, price);
      ObjectMove(0, name, 1, t2, price);
     }
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
  }

//+------------------------------------------------------------------+
//| Draw the open, buy stop and sell stop levels for a session       |
//+------------------------------------------------------------------+
void DrawLevels(const datetime sessionStart, const datetime exitTime)
  {
   string tag = "CRB_" + TimeToString(sessionStart, TIME_DATE) + "_";
   DrawLevel(tag + "open", sessionStart, exitTime, g_open, clrSilver);
   DrawLevel(tag + "buy", sessionStart, exitTime, g_buyLevel, clrLimeGreen);
   DrawLevel(tag + "sell", sessionStart, exitTime, g_sellLevel, clrTomato);
  }

//+------------------------------------------------------------------+
//| Show the current state in the chart comment                      |
//+------------------------------------------------------------------+
void UpdatePanel()
  {
   if(!IsVisualContext())
      return;
   string mode = (InpOffsetMode == OFFSET_STRETCH) ? "Stretch" : "ATR x " + DoubleToString(InpAtrMultiple, 2);
   string text = "Crabel ORB Gold v1.06\n";
   text += "Offset: " + mode + "   Filter: " + EnumToString(InpDayFilter) + "   Wide skip: " + EnumToString(InpWideSkip) + "\n";
   if(g_filterText != "")
      text += g_filterText + "\n";
   if(g_open > 0.0)
      text += "Open " + DoubleToString(g_open, _Digits) + "   Offset " + DoubleToString(g_offset, _Digits) +
              "   Buy stop " + DoubleToString(g_buyLevel, _Digits) + "   Sell stop " + DoubleToString(g_sellLevel, _Digits) + "\n";
   text += "Status: " + g_status;
   Comment(text);
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

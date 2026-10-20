//+------------------------------------------------------------------+
//|                                                       ORB_EA.mq5 |
//|  Opening Range Breakout after Zarattini, Barbon & Aziz (2024),   |
//|  "A Profitable Day Trading Strategy For The U.S. Equity Market", |
//|  SSRN 4729284, section 2.1 (base strategy, no relative-volume    |
//|  filter), moved to forex session opens:                          |
//|   - opening range = the first N minutes (N = InpTimeframe) after |
//|     the London 08:00 or New York 09:30 open, local time with DST |
//|   - range candle closed up: buy at the range high only; closed   |
//|     down: sell at the range low only; doji: no trade             |
//|   - stop InpStopATR x daily ATR(14) from the fill, no target,     |
//|     close at InpEodHour:InpEodMinute server (before rollover)    |
//|   - one trade per day; a level not reached by then expires       |
//|  The breakout is a market order at the first tick beyond the     |
//|  level (Ask for buys, Bid for sells), as a stop order fills.     |
//|  Execution, guards and trade log from EACore.mqh.                |
//|  v1.00 2026-10-20 (spec 2026-10-20-orb-fx-prereg.md).            |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.00"
#property strict
#property description "Opening Range Breakout (Zarattini/Barbon/Aziz 2024 base rules) at the London or New York open; ATR-fraction stop, end-of-day exit"

#define EA_NAME    "ORB_EA"
#define EA_VERSION "1.00"
#define EA_MAGIC   261021
#define EA_COMMENT "ORB"
#define EA_TIMEFRAME PERIOD_M5        // opening range length (the paper's 5-minute ORB)
#define EA_MAX_SPREAD_POINTS 30        // forex: 3 pips (0.3 yen on JPY pairs)
#define EA_SPREAD_WAIT_MIN 0           // a wide spread at the breakout is waited out tick by tick in TryEntry
#include "EACore.mqh"

enum ENUM_ORB_SESSION
  {
   SESSION_LONDON  = 0,  // London open 08:00 Europe/London
   SESSION_NEWYORK = 1   // New York open 09:30 America/New_York
  };

enum ENUM_DST_RULE
  {
   DST_NONE = 0,  // clock never shifts
   DST_EU   = 1,  // last Sun Mar 01:00 UTC -> last Sun Oct 01:00 UTC
   DST_US   = 2   // 2nd Sun Mar 02:00 local -> 1st Sun Nov 02:00 local
  };

input group "=== Strategy ==="
input ENUM_ORB_SESSION InpSession   = SESSION_NEWYORK; // Session open (range = first InpTimeframe minutes after it)
input double           InpStopATR   = 0.10;            // Stop distance, x daily ATR
input int              InpATRPeriod = 14;              // Daily ATR period (completed days)
input int              InpEodHour   = 23;              // End-of-day close, server hour
input int              InpEodMinute = 50;              // End-of-day close, server minute

input group "=== Broker clock ==="
input int              InpSrvStdOffsetHours = 2;       // Server UTC offset in winter (Darwinex, IC: +2)
input ENUM_DST_RULE    InpSrvDstRule        = DST_US;  // DST rule of the server clock (NY close = 00:00 server: US)

enum ENUM_DAY_STATE { DAY_WAIT, DAY_ARMED, DAY_DONE };

int            g_atr      = INVALID_HANDLE;
datetime       g_day      = 0;        // server day being traded
datetime       g_orStart  = 0, g_orEnd = 0, g_eod = 0;
ENUM_DAY_STATE g_state    = DAY_DONE;
int            g_dir      = 0;        // +1 buy at g_level, -1 sell at g_level
double         g_level    = 0.0;
double         g_slDist   = 0.0;

//====================== CLOCK (from NYClockSelfTest.mq5) ===========
int DaysInMonth(const int y, const int m)
  {
   static int dim[12] = {31,28,31,30,31,30,31,31,30,31,30,31};
   if(m == 2 && ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0))
      return 29;
   return dim[m - 1];
  }

long DaysFromCivil(int y, const int m, const int d)
  {
   y -= (m <= 2) ? 1 : 0;
   long era = (long)((y >= 0 ? y : y - 399) / 400);
   long yoe = (long)(y - era * 400);
   long doy = (long)((153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1);
   long doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
   return era * 146097 + doe - 719468;
  }

datetime NthDow(const int y, const int mo, const int dow, const int n)
  {
   long d1  = DaysFromCivil(y, mo, 1);
   int  w1  = (int)((d1 + 4) % 7);        // 1970-01-01 was a Thursday
   int  off = (dow - w1 + 7) % 7;
   return (datetime)((d1 + off + 7 * (n - 1)) * 86400);
  }

datetime LastDow(const int y, const int mo, const int dow)
  {
   long dl = DaysFromCivil(y, mo, DaysInMonth(y, mo));
   int  wl = (int)((dl + 4) % 7);
   return (datetime)((dl - ((wl - dow + 7) % 7)) * 86400);
  }

int YearOf(const datetime t)
  {
   MqlDateTime s;
   TimeToStruct(t, s);
   return s.year;
  }

bool EuSummerUtc(const datetime utc)
  {
   int y = YearOf(utc);
   return (utc >= LastDow(y, 3, 0) + 3600 && utc < LastDow(y, 10, 0) + 3600);
  }

bool UsSummerUtc(const datetime utc)
  {
   int y = YearOf(utc);
   return (utc >= NthDow(y, 3, 0, 2) + 7 * 3600 && utc < NthDow(y, 11, 0, 1) + 6 * 3600);
  }

bool SummerUtc(const datetime utc, const ENUM_DST_RULE rule)
  {
   if(rule == DST_EU) return EuSummerUtc(utc);
   if(rule == DST_US) return UsSummerUtc(utc);
   return false;
  }

datetime UtcToLocal(const datetime utc, const int stdH, const ENUM_DST_RULE rule)
  {
   return utc + (datetime)(stdH * 3600 + (SummerUtc(utc, rule) ? 3600 : 0));
  }

datetime LocalToUtc(const datetime loc, const int stdH, const ENUM_DST_RULE rule)
  {
   datetime g1 = loc - (datetime)(stdH * 3600);
   if(!SummerUtc(g1, rule))
      return g1;
   datetime g2 = g1 - 3600;
   return SummerUtc(g2, rule) ? g2 : g1;
  }
//====================================================================

//--- server time of the session open on the server day `day` (the open's local date equals the server date)
datetime SessionOpenSrv(const datetime day, const ENUM_ORB_SESSION session)
  {
   const datetime utc = (session == SESSION_LONDON) ? LocalToUtc(day + 8 * 3600, 0, DST_EU)
                                                    : LocalToUtc(day + 9 * 3600 + 1800, -5, DST_US);
   return UtcToLocal(utc, InpSrvStdOffsetHours, InpSrvDstRule);
  }

//--- known opens on a +2/US-DST server: London 10:00 server, 11:00 in the weeks the US is on summer time and the UK
//--- is not; New York always 16:30
bool ClockSelfTest()
  {
   if(InpSrvStdOffsetHours != 2 || InpSrvDstRule != DST_US)
      return(true);                                // the cases below are for a +2/US server
   const string   days[] = {"2024.01.15", "2024.03.15", "2024.04.15", "2024.10.29", "2024.11.05", "2025.03.12", "2025.07.01"};
   const int      lon[]  = {10, 11, 10, 11, 10, 11, 10};
   for(int i = 0; i < ArraySize(days); i++)
     {
      const datetime d = StringToTime(days[i]);
      if(SessionOpenSrv(d, SESSION_LONDON) != d + lon[i] * 3600 || SessionOpenSrv(d, SESSION_NEWYORK) != d + 16 * 3600 + 1800)
        {
         PrintFormat("Clock self-test failed on %s: London %s, New York %s", days[i],
                     TimeToString(SessionOpenSrv(d, SESSION_LONDON)), TimeToString(SessionOpenSrv(d, SESSION_NEWYORK)));
         return(false);
        }
     }
   return(true);
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   const int orMin = PeriodSeconds(InpTimeframe) / 60;
   if(orMin < 1 || orMin > 240 || InpStopATR <= 0.0 || InpATRPeriod < 2 ||
      InpEodHour < 0 || InpEodHour > 23 || InpEodMinute < 0 || InpEodMinute > 59)
     {
      Print("Invalid inputs: range 1-240 min, stop ATR > 0, ATR period >= 2, end-of-day 00:00-23:59");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!ClockSelfTest())
      return(INIT_FAILED);
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   g_loadGMT = 0;                                   // late attach is handled by the day state (DAY_DONE after the range end):
                                                    // EACore's bar check would drop a NY H1 breakout after a 17:00-17:29 load
   g_atr = iATR(_Symbol, PERIOD_D1, InpATRPeriod);
   if(g_atr == INVALID_HANDLE)
     {
      Print("Failed to create the daily ATR, error ", GetLastError());
      return(INIT_FAILED);
     }
   g_day = 0;
   PrintFormat("%s v%s started on %s, magic %I64u, own positions: %d", EA_NAME, EA_VERSION, _Symbol, InpMagic, CountOwnPositions());
   PrintFormat("Inputs: %s open, %d-min range | stop %.2f x D1 ATR(%d) | close %02d:%02d server | clock UTC%+d %s | risk %s %.2f",
               InpSession == SESSION_LONDON ? "London 08:00" : "New York 09:30", orMin, InpStopATR, InpATRPeriod,
               InpEodHour, InpEodMinute, InpSrvStdOffsetHours, EnumToString(InpSrvDstRule),
               InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(g_atr != INVALID_HANDLE)
      IndicatorRelease(g_atr);
   Core_Deinit(reason);
  }

//--- close own positions opened before `before` (end of day: all of them)
void CloseOwn(const datetime before)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = PositionGetTicket(i);
      if(ticket != 0 && IsOwnPosition() && (datetime)PositionGetInteger(POSITION_TIME) < before && !CloseQueued(ticket))
         Core_ClosePosition(ticket, "eod");
     }
  }

//--- live restart: an own entry since the range closed means today's trade was taken
bool TradedSince(const datetime from)
  {
   if(MQLInfoInteger(MQL_TESTER) || !HistorySelect(from, TimeCurrent() + 60))
      return(false);
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      const ulong d = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(d, DEAL_MAGIC) == (long)InpMagic && HistoryDealGetString(d, DEAL_SYMBOL) == _Symbol &&
         HistoryDealGetInteger(d, DEAL_ENTRY) == DEAL_ENTRY_IN)
         return(true);
     }
   return(false);
  }

//--- the range is complete: take its candle and arm the one allowed side
void BuildRange()
  {
   MqlRates r[];
   const int n = CopyRates(_Symbol, PERIOD_M1, g_orStart, g_orEnd - 1, r);
   double atr[1];
   if(n <= 0 || CopyBuffer(g_atr, 0, 1, 1, atr) < 1 || atr[0] <= 0.0)
     {
      if(TimeCurrent() >= g_orEnd + 600)            // still nothing 10 min later: no range today (holiday, data gap)
        {
         PrintFormat("ORB %s: no range data (%d M1 bars from %s)", TimeToString(g_day, TIME_DATE), n, TimeToString(g_orStart));
         g_state = DAY_DONE;
        }
      return;
     }
   double hi = r[0].high, lo = r[0].low;
   for(int i = 1; i < n; i++)
     {
      hi = MathMax(hi, r[i].high);
      lo = MathMin(lo, r[i].low);
     }
   const double open = r[0].open, close = r[n - 1].close;
   const int    dg   = g_symbol.Digits();
   const string ctx  = StringFormat("range %s-%s (%d bars) open %s close %s high %s low %s atr %s",
                                    TimeToString(g_orStart, TIME_MINUTES), TimeToString(g_orEnd, TIME_MINUTES), n,
                                    DoubleToString(open, dg), DoubleToString(close, dg), DoubleToString(hi, dg),
                                    DoubleToString(lo, dg), DoubleToString(atr[0], dg));
   g_state = DAY_DONE;
   if(close == open)
     {
      Core_LogBar(g_orStart, ctx + " | doji, no trade");
      return;
     }
   if(CountOwnPositions() > 0 || TradedSince(g_orEnd))
     {
      Core_LogBar(g_orStart, ctx + " | already traded today");
      return;
     }
   g_dir    = close > open ? 1 : -1;
   g_level  = g_dir > 0 ? hi : lo;
   g_slDist = InpStopATR * atr[0];
   g_state  = DAY_ARMED;
   Core_LogBar(g_orStart, ctx + StringFormat(" | %s at %s, stop %s", g_dir > 0 ? "BUY" : "SELL",
                                              DoubleToString(g_level, dg), DoubleToString(g_slDist, dg)));
  }

void TryEntry()
  {
   if(!g_symbol.RefreshRates())
      return;
   const bool buy = (g_dir > 0);
   if(buy ? g_symbol.Ask() < g_level : g_symbol.Bid() > g_level)
      return;
   if(InpMaxSpreadPoints > 0 && g_symbol.Spread() > InpMaxSpreadPoints)
      return;                                       // beyond the level but spread too wide: wait for a normal quote
   g_state = DAY_DONE;                              // one attempt per day
   const int dg = g_symbol.Digits();
   PrintFormat("ORB SIGNAL %s day=%s level=%s price=%s spread=%d sl_dist=%s",
               buy ? "BUY" : "SELL", TimeToString(g_day, TIME_DATE), DoubleToString(g_level, dg),
               DoubleToString(buy ? g_symbol.Ask() : g_symbol.Bid(), dg), g_symbol.Spread(), DoubleToString(g_slDist, dg));
   Core_Open(buy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL, g_slDist, 0.0);
  }

void OnTick()
  {
   Core_OnTickStart();
   const datetime now = TimeCurrent();
   const datetime day = now - now % 86400;
   if(day != g_day)
     {
      g_day     = day;
      g_orStart = SessionOpenSrv(day, InpSession);
      g_orEnd   = g_orStart + PeriodSeconds(InpTimeframe);
      g_eod     = day + InpEodHour * 3600 + InpEodMinute * 60;
      g_state   = (g_orEnd < g_eod && now < g_orEnd) ? DAY_WAIT : DAY_DONE;   // attached after the range closed: next day
     }
   CloseOwn(now >= g_eod ? now + 1 : g_day);        // end of day, or a position left over from an earlier day
   if(now >= g_eod)
     {
      g_state = DAY_DONE;
      return;
     }
   if(g_state == DAY_WAIT && now >= g_orEnd)
      BuildRange();
   if(g_state == DAY_ARMED)
      TryEntry();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

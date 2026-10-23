//+------------------------------------------------------------------+
//|                                               NY_4H_Range_EA.mq5 |
//|  The "4 Hour Range" strategy (mql5.com code 68082, Peter Mueller, |
//|  DataTraderH4Breakout.mq5 v1.01) on the MBT EACore.              |
//|  Range = high / low of the M5 bars opening 00:00-03:55 New York.  |
//|  From 04:00 NY to NY midnight: an M5 bar closes outside the range |
//|  and the next one closes back inside -> fade it (below the low =  |
//|  buy, above the high = sell). Stop = extreme of the bars that     |
//|  closed outside, target = 2 x stop distance, no trade if more than|
//|  13 bars closed outside in a row. One own position at a time.     |
//|  Changes from the source (spec 2026-10-23-ny-4h-range-prereg.md): |
//|  NY = server - 7 h (Darwinex follows US DST), range bars 00:00-   |
//|  03:55 NY (the source is off by one bar), own positions only, %   |
//|  risk sizing and EACore guards.                                   |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.00"
#property strict
#property description "4-hour New York range: fade an M5 close outside that closes back in; stop at the excursion extreme, 2R target"

#define EA_NAME    "NY_4H_Range_EA"
#define EA_VERSION "1.00"
#define EA_MAGIC   261025
#define EA_COMMENT "NY4H"
#define EA_TIMEFRAME PERIOD_M5
#define EA_MAX_SPREAD_POINTS 0   // the source has no spread cap
#define EA_SPREAD_WAIT_MIN 0     // a signal belongs to one bar: no delayed entries
#include "EACore.mqh"

//--- "5. Strategy" continues from EACore (signal timeframe). Darwinex-Demo is New York + 7 h all year
//--- (it changes clocks with the US): check this for any other broker before trading it.
input int    InpServerMinusNY  = 7;    // Server time minus New York time, hours
input int    InpMaxBarsOutside = 13;   // Max bars closed outside the range (0 = off)

input group "7. Exits"
input double InpTargetR        = 2.0;  // Take profit, x stop distance

#define RANGE_SECONDS (4 * 3600)       // the first 4 hours of the New York day

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpServerMinusNY < -12 || InpServerMinusNY > 14 || InpMaxBarsOutside < 0 || InpTargetR <= 0.0)
     {
      Print("Invalid inputs: server minus New York -12..14 h, max bars outside >= 0, target R > 0");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   PrintFormat("%s v%s started on %s %s, magic %I64u, own positions: %d",
               EA_NAME, EA_VERSION, _Symbol, EnumToString(InpTimeframe), InpMagic, CountOwnPositions());
   PrintFormat("Inputs: New York = server - %d h | range 00:00-04:00 NY | max bars outside %s | target %.2f R | risk %s %.2f",
               InpServerMinusNY, InpMaxBarsOutside > 0 ? IntegerToString(InpMaxBarsOutside) : "off", InpTargetR,
               InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) { Core_Deinit(reason); }

//--- the range of the New York day that bar time t belongs to; false while the range is still forming or has no bars
bool DayRange(const datetime t, double &hi, double &lo)
  {
   const long     shift = (long)InpServerMinusNY * 3600;
   const datetime ny    = (datetime)(t - shift);
   const datetime nyDay = ny - ny % 86400;                 // New York midnight, on the New York clock
   if(ny - nyDay < RANGE_SECONDS)
      return(false);
   const datetime from = (datetime)(nyDay + shift);        // the same instant on the server clock
   double h[], l[];
   const int n = CopyHigh(_Symbol, InpTimeframe, from, from + RANGE_SECONDS - 1, h);
   if(n <= 0 || CopyLow(_Symbol, InpTimeframe, from, from + RANGE_SECONDS - 1, l) != n)
      return(false);
   hi = h[ArrayMaximum(h)];
   lo = l[ArrayMinimum(l)];
   return(hi > lo);
  }

void OnTick()
  {
   Core_OnTickStart();
   const datetime bar = Core_CurrentBar();
   if(!Core_IsNewBar(bar))
      return;
   const datetime t1 = iTime(_Symbol, InpTimeframe, 1);
   const double   c1 = iClose(_Symbol, InpTimeframe, 1), c2 = iClose(_Symbol, InpTimeframe, 2);
   if(t1 == 0 || c1 <= 0.0 || c2 <= 0.0)
      return;                                      // data not ready: bar stays unprocessed, retried next tick
   double hi = 0.0, lo = 0.0;
   const bool ranged = DayRange(t1, hi, lo);
   Core_MarkBar(bar);
   if(!ranged)
     {
      Core_LogBar(bar, "range forming or empty");
      return;
     }
   const string ctx = StringFormat("close %s range %s/%s", DoubleToString(c1, _Digits), DoubleToString(hi, _Digits), DoubleToString(lo, _Digits));
   if(CountOwnPositions() > 0)
     {
      Core_LogBar(bar, ctx + " | holding");
      return;
     }
   const int sig = (c2 < lo && c1 > lo) ? 1 : (c2 > hi && c1 < hi) ? -1 : 0;
   if(sig == 0)
     {
      Core_LogBar(bar, ctx + " | no re-entry");
      return;
     }
   const bool buy = (sig > 0);
   //--- walk back over the bars that closed outside: their extreme is the stop
   double ext = buy ? DBL_MAX : 0.0;
   int    outside = 0;
   for(int i = 2; i < 300; i++)
     {
      const double c = iClose(_Symbol, InpTimeframe, i);
      if(c <= 0.0 || (buy ? c >= lo : c <= hi))
         break;
      ext = buy ? MathMin(ext, iLow(_Symbol, InpTimeframe, i)) : MathMax(ext, iHigh(_Symbol, InpTimeframe, i));
      if(InpMaxBarsOutside > 0 && ++outside > InpMaxBarsOutside)
        {
         Core_LogBar(bar, ctx + StringFormat(" | %s skipped: over %d bars outside", buy ? "BUY" : "SELL", InpMaxBarsOutside));
         return;
        }
     }
   if(!g_symbol.RefreshRates())
      return;
   const double price  = buy ? g_symbol.Ask() : g_symbol.Bid();
   const double slDist = buy ? price - ext : ext - price;
   const double floor4 = 4.0 * g_symbol.StopsLevel() * _Point;   // the source's minimum stop and target distance
   if(slDist <= floor4 || InpTargetR * slDist <= floor4)
     {
      Core_LogBar(bar, ctx + StringFormat(" | %s skipped: stop distance %s", buy ? "BUY" : "SELL", DoubleToString(slDist, _Digits)));
      return;
     }
   const double tp = NormalizeDouble(buy ? price + InpTargetR * slDist : price - InpTargetR * slDist, _Digits);
   PrintFormat("NY4H SIGNAL %s close1=%s close2=%s range=%s/%s stop=%s sl_dist=%s tp=%s",
               buy ? "BUY" : "SELL", DoubleToString(c1, _Digits), DoubleToString(c2, _Digits), DoubleToString(hi, _Digits),
               DoubleToString(lo, _Digits), DoubleToString(ext, _Digits), DoubleToString(slDist, _Digits), DoubleToString(tp, _Digits));
   Core_LogBar(bar, ctx + StringFormat(" | %s stop dist %s", buy ? "BUY" : "SELL", DoubleToString(slDist, _Digits)));
   Core_Open(buy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL, slDist, tp);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

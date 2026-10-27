//+------------------------------------------------------------------+
//|                                          NDX_Band_Breakout_EA.mq5 |
//|  Intraday band breakout on the Nasdaq-100 cash session, long    |
//|  only. Bands = the session-open price x (1 +/- mult x sigma),  |
//|  sigma = the average absolute move from the open to the same    |
//|  minute over the last N days (the "noise area" of the Concretum |
//|  Group's intraday momentum papers). Entry = a bar opens inside  |
//|  the bands and closes above the upper band, in the direction of |
//|  the SMA trend filter, not in the first hour of the session.    |
//|  Exit = stop 1% of price, price closing back under the session  |
//|  VWAP, or flat at the exit time. One position at a time.        |
//|                                                                  |
//|  Origin: ORB3.mq5 of MQL5 article 17745 (Zhuo Kai Chen, 2025,   |
//|  "Decoding Opening Range Breakout Intraday Trading Strategies"). |
//|  The article's materials are all-rights-reserved by MetaQuotes;  |
//|  the article invites readers to build on its code. Changes      |
//|  (spec 2026-10-26-article17745-orb-prereg.md, 2026-10-27-       |
//|  orb3f-ndx-improve-prereg.md):                                  |
//|   - time gates compare the time of day (the article tested      |
//|     hour AND minute separately, so it acted in minutes 35-59);  |
//|   - the band reference is the session open, not 09:30 server;   |
//|   - long only, bands x1.25, no entries in the first 60 minutes  |
//|     (variant x8: PF 1.2 in 2019-21, 2022-23 and 2024-26);       |
//|   - execution, guards and trade log from EACore.mqh.            |
//|  Server clock: the defaults are for New York + 7 hours (open    |
//|  16:30, flat 22:55), the clock of Darwinex and FTMO.            |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.00"
#property strict
#property description "NDX opening-range band breakout (long only): bands from the session open and the average move, SMA trend filter, no entries in the first hour, VWAP / stop / end-of-day exit; EACore safety"

#define EA_NAME    "NDX_Band_Breakout_EA"
#define EA_VERSION "1.00"
#define EA_MAGIC   271027
#define EA_COMMENT "NDXBB"
#define EA_TIMEFRAME PERIOD_M1
#define EA_SPREAD_WAIT_MIN 0          // a late entry is a different trade: no waiting for the spread
#define EA_MAX_SPREAD_POINTS 100      // NDX quotes in 0.1 points: 100 points = 10 index points
#define EA_RISK_VALUE 0.25            // add-on sizing: about 2% own drawdown on the account (spec 2026-10-27-orb3f-ndx-improve-prereg.md)
#define EA_DAILY_LOSS_PCT 3.0
#define ACCOUNT_THROTTLE_DD_PCT 3.0
#include "EACore.mqh"

//--- "5. Strategy" continues from EACore (signal timeframe: M1, the bands are built from M1 bars)
input int    InpOpenHour       = 16;    // Session open, hour (server time)
input int    InpOpenMinute     = 30;    // Session open, minute (server time)
input int    InpEntryDelayMin  = 60;    // No entries after the open for, minutes (0 = off)
input double InpBandMult       = 1.25;  // Bands: width, x average move
input int    InpSigmaDays      = 14;    // Bands: average move over, days
input bool   InpAllowShort     = false; // Allow sells

input group "6. Filters"
input int    InpTrendSMA       = 400;   // Trend filter: SMA period, bars (0 = off)

input group "7. Exits"
input double InpStopPct        = 1.0;   // Stop loss, % of open price
input bool   InpUseVwapExit    = true;  // Use VWAP exit (close when price crosses it)
input int    InpCloseHour      = 22;    // Exit time, hour (server time)
input int    InpCloseMinute    = 55;    // Exit time, minute (server time)

int g_ma = INVALID_HANDLE;

int MinuteOfDay(const datetime t)
  {
   MqlDateTime s;
   TimeToStruct(t, s);
   return(s.hour * 60 + s.min);
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   const int openMin  = InpOpenHour * 60 + InpOpenMinute;
   const int closeMin = InpCloseHour * 60 + InpCloseMinute;
   if(InpTimeframe != PERIOD_M1)
     {
      Print("Invalid inputs: the signal timeframe must be M1 (the bands are built from M1 bars)");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpOpenHour < 0 || InpOpenHour > 23 || InpOpenMinute < 0 || InpOpenMinute > 59 ||
      InpCloseHour < 0 || InpCloseHour > 23 || InpCloseMinute < 0 || InpCloseMinute > 59 ||
      InpEntryDelayMin < 0 || closeMin <= openMin + MathMax(5, InpEntryDelayMin) ||
      InpBandMult <= 0.0 || InpSigmaDays < 1 || InpStopPct <= 0.0 || InpStopPct >= 100.0 || InpTrendSMA < 0)
     {
      Print("Invalid inputs: open and exit times valid with the exit later than the first entry, delay >= 0, band width > 0, sigma days >= 1, stop 0-100%, trend SMA >= 0");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   if(InpTrendSMA > 0)
     {
      g_ma = iMA(_Symbol, InpTimeframe, InpTrendSMA, 0, MODE_SMA, PRICE_CLOSE);
      if(g_ma == INVALID_HANDLE)
        {
         Print("Failed to create the trend SMA, error ", GetLastError());
         return(INIT_FAILED);
        }
     }
   PrintFormat("%s v%s started on %s %s, magic %I64u, own positions: %d",
               EA_NAME, EA_VERSION, _Symbol, EnumToString(InpTimeframe), InpMagic, CountOwnPositions());
   PrintFormat("Inputs: open %02d:%02d | no entries for %d min | bands x%.2f of the %d-day average move | trend %s | shorts %s | stop %.2f%% | VWAP exit %s | flat %02d:%02d | risk %s %.2f",
               InpOpenHour, InpOpenMinute, InpEntryDelayMin, InpBandMult, InpSigmaDays,
               InpTrendSMA > 0 ? StringFormat("SMA%d", InpTrendSMA) : "off", InpAllowShort ? "on" : "off",
               InpStopPct, InpUseVwapExit ? "on" : "off", InpCloseHour, InpCloseMinute,
               InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(g_ma != INVALID_HANDLE)
      IndicatorRelease(g_ma);
   Core_Deinit(reason);
  }

//--- VWAP of the M1 bars from the session open to the last closed bar (typical price x tick volume), 0 = not available
double SessionVwap()
  {
   const datetime from = (datetime)(TimeTradeServer() / 86400 * 86400) + InpOpenHour * 3600 + InpOpenMinute * 60;
   const datetime last = iTime(_Symbol, InpTimeframe, 1);
   MqlRates r[];
   const int n = CopyRates(_Symbol, InpTimeframe, from, last, r);
   if(n <= 0)
      return(0.0);
   double pv = 0.0, v = 0.0;
   for(int i = 0; i < n; i++)
     {
      pv += (r[i].high + r[i].low + r[i].close) / 3.0 * (double)r[i].tick_volume;
      v  += (double)r[i].tick_volume;
     }
   return(v > 0.0 ? pv / v : 0.0);
  }

//--- the noise-area bands: session open of today x (1 +/- mult x sigma); sigma = the mean over the last InpSigmaDays days of
//--- |close of the bar at this minute / open of the session-open bar - 1|. false = no data for today's open or for any day.
bool Bands(double &upper, double &lower)
  {
   MqlDateTime cur;
   TimeToStruct(iTime(_Symbol, InpTimeframe, 0), cur);
   const int openSec = InpOpenHour * 3600 + InpOpenMinute * 60;
   const int nowSec  = cur.hour * 3600 + cur.min * 60;
   const int todayOpen = iBarShift(_Symbol, PERIOD_M1, iTime(_Symbol, PERIOD_D1, 0) + openSec, true);
   if(todayOpen < 0)
      return(false);
   const double open0 = iOpen(_Symbol, PERIOD_M1, todayOpen);
   if(open0 <= 0.0)
      return(false);
   double sum = 0.0;
   int    days = 0;
   for(int i = 1; i <= InpSigmaDays; i++)
     {
      const datetime d = iTime(_Symbol, PERIOD_D1, i);
      if(d == 0)
         break;
      const int a = iBarShift(_Symbol, PERIOD_M1, d + openSec, true);
      const int b = iBarShift(_Symbol, PERIOD_M1, d + nowSec, true);
      if(a < 0 || b < 0)
         continue;
      const double o = iOpen(_Symbol, PERIOD_M1, a);
      if(o <= 0.0)
         continue;
      sum += MathAbs(iClose(_Symbol, PERIOD_M1, b) / o - 1.0);
      days++;
     }
   if(days == 0)
      return(false);
   const double sigma = sum / days;
   upper = open0 * (1.0 + InpBandMult * sigma);
   lower = open0 * (1.0 - InpBandMult * sigma);
   return(true);
  }

//+------------------------------------------------------------------+
void OnTick()
  {
   Core_OnTickStart();
   const datetime bar = Core_CurrentBar();
   Core_RetryPending(bar);
   if(!Core_IsNewBar(bar))
      return;
   Core_MarkBar(bar);

   const int mod      = MinuteOfDay(TimeTradeServer());
   const int openMin  = InpOpenHour * 60 + InpOpenMinute;
   const int closeMin = InpCloseHour * 60 + InpCloseMinute;
   ulong ticket = 0;
   const bool hold = Core_SelectOwnPosition(ticket);
   if(hold && (mod >= closeMin || mod < openMin))    // exit time reached, or a position left over from before the open
     {
      Core_ClosePosition(ticket, mod >= closeMin ? "end of day" : "left over");
      return;
     }
   if(mod >= closeMin || mod < openMin + 5)          // the first five minutes only build the first closed bars
      return;

   const double c1 = iClose(_Symbol, InpTimeframe, 1);
   const double o1 = iOpen(_Symbol, InpTimeframe, 1);
   if(c1 <= 0.0 || o1 <= 0.0)
      return;

   if(hold && InpUseVwapExit)
     {
      const double vwap = SessionVwap();
      const bool   buy  = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
      if(vwap > 0.0 && (buy ? c1 < vwap : c1 > vwap))
        {
         PrintFormat("VWAP exit: close %.2f %s VWAP %.2f", c1, buy ? "under" : "over", vwap);
         Core_ClosePosition(ticket, "vwap");
        }
     }
   if(CountOwnPositions() > 0)                       // still holding, or the close is queued for retry
      return;
   if(mod < openMin + MathMax(5, InpEntryDelayMin))
      return;

   double ma[1];
   if(InpTrendSMA > 0 && (g_ma == INVALID_HANDLE || CopyBuffer(g_ma, 0, 1, 1, ma) != 1))
      return;
   double up = 0.0, lo = 0.0;
   if(!Bands(up, lo))
      return;
   const bool trendUp = (InpTrendSMA == 0 || c1 > ma[0]);
   const bool trendDn = (InpTrendSMA == 0 || c1 < ma[0]);
   if(o1 < up && c1 > up && trendUp)
     {
      PrintFormat("BUY signal: bar %.2f -> %.2f closed above the upper band %.2f", o1, c1, up);
      Core_Open(POSITION_TYPE_BUY, SymbolInfoDouble(_Symbol, SYMBOL_ASK) * InpStopPct / 100.0, 0.0);
     }
   else if(InpAllowShort && o1 > lo && c1 < lo && trendDn)
     {
      PrintFormat("SELL signal: bar %.2f -> %.2f closed below the lower band %.2f", o1, c1, lo);
      Core_Open(POSITION_TYPE_SELL, SymbolInfoDouble(_Symbol, SYMBOL_BID) * InpStopPct / 100.0, 0.0);
     }
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

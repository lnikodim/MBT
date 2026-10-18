//+------------------------------------------------------------------+
//|                                                  RSI8020_EA.mq5 |
//|  TradingStrategyGuides "RSI 80-20" strategy, RSI(8) 80/20:       |
//|  BUY: A = a closed bar that is the lowest low (or close) of the  |
//|  last 50 bars with RSI <= 20; B = a later bar with a lower low   |
//|  (close) than A and a higher RSI (divergence); entry at the next |
//|  bar's open after a bar closes above A's high. A close above     |
//|  A's high before B cancels; a setup expires 50 bars after A.     |
//|  Stop below the lowest low since A (- buffer x ATR), optionally  |
//|  at least k x ATR away; target 3R. SELL mirrors. One position;   |
//|  setups reset at entry and are not tracked while in a position. |
//|  Execution, guards and trade log from EACore.mqh.                |
//|  v1.00: spec 2026-10-18-rsi8020-prereg.md                        |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.00"
#property strict
#property description "RSI 80-20: 50-bar extreme with RSI(8) <= 20 / >= 80, RSI divergence, close beyond the first candle; swing stop, 3R target"

#define EA_NAME    "RSI8020_EA"
#define EA_VERSION "1.00"
#define EA_MAGIC   261020
#define EA_COMMENT "RSI8020"
#define EA_TIMEFRAME PERIOD_H1
#define EA_MAX_SPREAD_POINTS 50   // 5 pips on a 5-digit pair (GBPJPY: 5 pips on 3 digits)
#define EA_SPREAD_WAIT_MIN 0      // the EA retries spread-blocked entries itself, from the stop price
#include "EACore.mqh"
#define ATR_PERIOD 14

enum ENUM_EXTREME { EXTREME_HIGH_LOW = 0,  // A and B judged on lows (buys) / highs (sells)
                    EXTREME_CLOSE    = 1   // A and B judged on closes
                  };

input group "=== Strategy ==="
input int    InpRsiPeriod   = 8;     // RSI period
input double InpRsiLevel    = 20.0;  // RSI level: buys need RSI <= this at A, sells >= 100 - this
input ENUM_EXTREME InpExtremeMode = EXTREME_HIGH_LOW; // Price that defines A and B
input int    InpLookback    = 50;    // A must be the lowest low / highest high (or close) of this many bars, itself included
input int    InpExpiryBars  = 50;    // Setup expires this many bars after A without a trigger
input double InpTargetR     = 3.0;   // Take profit, x stop distance
input double InpSLBufferATR = 0.1;   // Stop beyond the setup's extreme by this x ATR(14)
input double InpWideStopATR = 0.0;   // Stop at least this x ATR(14) from the entry price (0 = off)
input bool   InpAllowShort  = true;  // Allow sells
input int    InpRetryMin    = 60;    // Retry a spread-blocked entry for this many minutes (stop kept, R recomputed)

enum SETUP_STATE { ST_IDLE = 0, ST_ARMED = 1, ST_DIV = 2 };
struct Setup { int st; datetime aTime; double aClose, aHigh, aLow, aRsi; };
Setup g_buy, g_sell;
int    g_rsi = INVALID_HANDLE, g_atr = INVALID_HANDLE;
int    g_pendSide = 0;            // spread-blocked entry: +1 buy, -1 sell
double g_pendStop = 0.0, g_pendAtr = 0.0;
datetime g_pendFrom = 0;

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpRsiPeriod < 2 || InpRsiLevel <= 0.0 || InpRsiLevel >= 50.0 || InpLookback < 2 || InpExpiryBars < 1 ||
      InpTargetR <= 0.0 || InpSLBufferATR < 0.0 || InpWideStopATR < 0.0 || InpRetryMin < 0)
     {
      Print("Invalid inputs: RSI period >= 2, 0 < RSI level < 50, lookback >= 2, expiry >= 1, target R > 0, buffer >= 0, retry >= 0");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   g_rsi = iRSI(_Symbol, InpTimeframe, InpRsiPeriod, PRICE_CLOSE);
   g_atr = iATR(_Symbol, InpTimeframe, ATR_PERIOD);
   if(g_rsi == INVALID_HANDLE || g_atr == INVALID_HANDLE)
     {
      Print("Failed to create indicators, error ", GetLastError());
      return(INIT_FAILED);
     }
   g_buy.st = g_sell.st = ST_IDLE;
   PrintFormat("%s v%s started on %s %s, magic %I64u, own positions: %d",
               EA_NAME, EA_VERSION, _Symbol, EnumToString(InpTimeframe), InpMagic, CountOwnPositions());
   PrintFormat("Inputs: RSI(%d) %.0f/%.0f | extremes on %s | lookback %d | expiry %d bars | target %.2f R | stop buffer %.2f x ATR(%d), min %.2f x ATR | shorts %s | retry %d min | risk %s %.2f",
               InpRsiPeriod, InpRsiLevel, 100.0 - InpRsiLevel, InpExtremeMode == EXTREME_CLOSE ? "closes" : "lows/highs", InpLookback,
               InpExpiryBars, InpTargetR, InpSLBufferATR, ATR_PERIOD, InpWideStopATR,
               InpAllowShort ? "on" : "off", InpRetryMin, InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(g_rsi != INVALID_HANDLE)
      IndicatorRelease(g_rsi);
   if(g_atr != INVALID_HANDLE)
      IndicatorRelease(g_atr);
   Core_Deinit(reason);
  }

//--- one side's state machine on the bar that just closed (shift 1); returns true when it triggers.
//--- Order: expiry; DIV -> trigger; ARMED -> B, else cancel on a close beyond A; IDLE -> new A.
bool Step(Setup &u, const bool buy, const MqlRates &t, const double rsi, const bool isExtreme, string &log)
  {
   const string side = buy ? "BUY" : "SELL";
   const bool   byClose = (InpExtremeMode == EXTREME_CLOSE);
   if(u.st != ST_IDLE && iBarShift(_Symbol, InpTimeframe, u.aTime) - 1 > InpExpiryBars)
     {
      log += StringFormat(" | %s setup expired", side);
      u.st = ST_IDLE;
     }
   const bool beyondA = buy ? t.close > u.aHigh : t.close < u.aLow;
   bool fired = false;
   if(u.st == ST_DIV && beyondA)
     {
      fired = true;
      log += StringFormat(" | %s TRIGGER", side);
      u.st = ST_IDLE;
     }
   else if(u.st == ST_ARMED)
     {
      const double p  = byClose ? t.close : (buy ? t.low : t.high);
      const double pa = byClose ? u.aClose : (buy ? u.aLow : u.aHigh);
      if(buy ? (p < pa && rsi > u.aRsi) : (p > pa && rsi < u.aRsi))
        {
         u.st = ST_DIV;
         log += StringFormat(" | %s divergence: %.5f vs A %.5f, RSI %.2f vs %.2f", side, p, pa, rsi, u.aRsi);
        }
      else if(beyondA)
        {
         u.st = ST_IDLE;
         log += StringFormat(" | %s setup cancelled: closed beyond A before divergence", side);
        }
     }
   if(u.st == ST_IDLE && !fired && isExtreme && (buy ? rsi <= InpRsiLevel : rsi >= 100.0 - InpRsiLevel))
     {
      u.st = ST_ARMED; u.aTime = t.time; u.aClose = t.close; u.aHigh = t.high; u.aLow = t.low; u.aRsi = rsi;
      log += StringFormat(" | %s A armed: close %.5f high %.5f low %.5f RSI %.2f", side, t.close, t.high, t.low, rsi);
     }
   return(fired);
  }

//--- stop price beyond the setup's extreme (bars A..shift 1); 0 when the history is not available
double StopPrice(const bool buy, const datetime aTime, const double atr)
  {
   const int n = iBarShift(_Symbol, InpTimeframe, aTime);       // A's shift; bars 1..n
   if(n < 1)
      return(0.0);
   if(buy)
     {
      const int k = iLowest(_Symbol, InpTimeframe, MODE_LOW, n, 1);
      return(k < 0 ? 0.0 : iLow(_Symbol, InpTimeframe, k) - InpSLBufferATR * atr);
     }
   const int k = iHighest(_Symbol, InpTimeframe, MODE_HIGH, n, 1);
   return(k < 0 ? 0.0 : iHigh(_Symbol, InpTimeframe, k) + InpSLBufferATR * atr);
  }

//--- market entry with the stop at a price: R from the live price; the sell stop sits a spread above (bars are Bid)
void Enter(const int side, const double stop, const double atr)
  {
   if(!g_symbol.RefreshRates())
      return;
   const bool   buy   = (side > 0);
   const double price = buy ? g_symbol.Ask() : g_symbol.Bid();
   double sl = buy ? stop : stop + g_symbol.Spread() * _Point;
   if(InpWideStopATR > 0.0)                          // at least k x ATR from the entry price
      sl = buy ? MathMin(sl, price - InpWideStopATR * atr) : MathMax(sl, price + InpWideStopATR * atr);
   const double dist  = buy ? price - sl : sl - price;
   if(dist <= 0.0)
     {
      PrintFormat("RSI8020 %s skipped: price %.5f already beyond the stop %.5f", buy ? "BUY" : "SELL", price, sl);
      g_pendSide = 0;
      return;
     }
   if(InpMaxSpreadPoints > 0 && g_symbol.Spread() > InpMaxSpreadPoints)
     {
      if(g_pendSide == 0 && InpRetryMin > 0)
        {
         g_pendSide = side; g_pendStop = stop; g_pendAtr = atr; g_pendFrom = TimeCurrent();
         PrintFormat("RSI8020 %s delayed: spread %d > %d points, retrying for %d min", buy ? "BUY" : "SELL",
                     g_symbol.Spread(), InpMaxSpreadPoints, InpRetryMin);
        }
      else if(InpRetryMin == 0)
         PrintFormat("RSI8020 %s skipped: spread %d > %d points", buy ? "BUY" : "SELL", g_symbol.Spread(), InpMaxSpreadPoints);
      return;
     }
   g_pendSide = 0;
   const double tp = NormalizeDouble(buy ? price + InpTargetR * dist : price - InpTargetR * dist, g_symbol.Digits());
   PrintFormat("RSI8020 ENTRY %s price=%.5f sl=%.5f dist=%.5f tp=%.5f spread=%d", buy ? "BUY" : "SELL", price, sl, dist, tp, g_symbol.Spread());
   Core_Open(buy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL, dist, tp);
  }

void OnTick()
  {
   Core_OnTickStart();
   if(g_pendSide != 0)
     {
      if(CountOwnPositions() > 0 || TimeCurrent() - g_pendFrom > InpRetryMin * 60)
        {
         PrintFormat("RSI8020 delayed %s dropped", g_pendSide > 0 ? "BUY" : "SELL");
         g_pendSide = 0;
        }
      else if(g_symbol.RefreshRates() && g_symbol.Spread() <= InpMaxSpreadPoints)
         Enter(g_pendSide, g_pendStop, g_pendAtr);
     }
   const datetime bar = Core_CurrentBar();
   if(!Core_IsNewBar(bar))
      return;
   MqlRates r[];
   ArraySetAsSeries(r, true);
   double rsi[1], atr[1];
   if(CopyRates(_Symbol, InpTimeframe, 1, InpLookback, r) != InpLookback ||
      CopyBuffer(g_rsi, 0, 1, 1, rsi) < 1 || CopyBuffer(g_atr, 0, 1, 1, atr) < 1 || atr[0] <= 0.0)
      return;                                      // data not ready: bar stays unprocessed, retried next tick
   Core_MarkBar(bar);
   const bool byClose = (InpExtremeMode == EXTREME_CLOSE);
   bool lowest = true, highest = true;              // r[0] = the bar that just closed; ties allowed
   for(int i = 1; i < InpLookback; i++)
     {
      if((byClose ? r[i].close : r[i].low)  < (byClose ? r[0].close : r[0].low))  lowest = false;
      if((byClose ? r[i].close : r[i].high) > (byClose ? r[0].close : r[0].high)) highest = false;
     }
   string log = StringFormat("closed %s o=%.5f h=%.5f l=%.5f c=%.5f rsi=%.4f atr=%.6f%s%s", TimeToString(r[0].time), r[0].open, r[0].high, r[0].low, r[0].close, rsi[0], atr[0],
                             lowest ? " | 50-bar low" : "", highest ? " | 50-bar high" : "");
   if(CountOwnPositions() > 0 || g_pendSide != 0)
     {
      g_buy.st = g_sell.st = ST_IDLE;               // setups reset at entry and are not tracked while in a position
      Core_LogBar(bar, log + " | in position");
      return;
     }
   const datetime aBuy = g_buy.aTime, aSell = g_sell.aTime;   // A of a setup that triggers on this bar
   const bool buyFire  = Step(g_buy, true, r[0], rsi[0], lowest, log);
   const bool sellFire = InpAllowShort && Step(g_sell, false, r[0], rsi[0], highest, log);
   if(buyFire && sellFire)
      log += " | both sides triggered: skipped";
   else if(buyFire || sellFire)
     {
      const bool buy = buyFire;
      const double stop = StopPrice(buy, buy ? aBuy : aSell, atr[0]);
      if(stop > 0.0)
        {
         g_buy.st = g_sell.st = ST_IDLE;
         PrintFormat("RSI8020 SIGNAL %s A=%s close=%.5f stop=%.5f atr=%.6f", buy ? "BUY" : "SELL",
                     TimeToString(buy ? aBuy : aSell), r[0].close, stop, atr[0]);
         Core_LogBar(bar, log);
         Enter(buy ? 1 : -1, stop, atr[0]);
         return;
        }
      log += " | stop history unavailable";
     }
   Core_LogBar(bar, log);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

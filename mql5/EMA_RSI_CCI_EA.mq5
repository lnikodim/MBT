//+------------------------------------------------------------------+
//|                                               EMA_RSI_CCI_EA.mq5 |
//|  ahmedabbas (Forex Factory, 2016): BUY when EMA 5 crosses above  |
//|  EMA 12 on the closed bar with RSI(21) above 50 and CCI(80)      |
//|  above 0; SELL mirrored. Exit when the EMAs cross back or when   |
//|  RSI and CCI are both back across their levels. Fixed pip stop,  |
//|  optional pip target, one position at a time, same-bar reversal. |
//|  Execution, guards and trade log from EACore.mqh.                |
//|  v1.00: spec 2026-10-16-ema-rsi-cci-prereg.md                    |
//|  v1.01: Bagovino (FF): CCI period 0 = off; entry mode "both      |
//|  crossed" (EMA side and RSI side agree, one just turned); exit   |
//|  mode "reverse" (exit only on the opposite signal, then reverse).|
//|  Defaults = v1.00. Spec 2026-10-17-bagovino-prereg.md           |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.01"
#property strict
#property description "EMA 5/12 cross + RSI(21) and CCI(80) filter, indicator exit, fixed pip stop; MACD_Cross_EA v1.42 safety core"

#define EA_NAME    "EMA_RSI_CCI_EA"
#define EA_VERSION "1.01"
#define EA_MAGIC   261018
#define EA_COMMENT "EMARC"
#define EA_TIMEFRAME PERIOD_H1
#define EA_MAX_SPREAD_POINTS 30   // 3 pips on a 5-digit pair
#include "EACore.mqh"

enum ENUM_EMARC_ENTRY
  {
   ENTRY_EMA_CROSS    = 0,  // EMA cross on the closed bar, RSI/CCI on its side (v1.00)
   ENTRY_BOTH_CROSSED = 1   // EMA and RSI/CCI agree on the closed bar and did not on the bar before
  };
enum ENUM_EMARC_EXIT
  {
   EXIT_INDICATOR = 0,      // EMA cross back or RSI/CCI back across their levels (v1.00)
   EXIT_REVERSE   = 1       // only on the opposite entry signal (stop and reverse)
  };

input group "=== Strategy ==="
input int    InpFastEMA    = 5;     // Fast EMA period
input int    InpSlowEMA    = 12;    // Slow EMA period
input int    InpRsiPeriod  = 21;    // RSI period
input double InpRsiLevel   = 50.0;  // RSI level (buys above, sells below 100 - level)
input int    InpCciPeriod  = 80;    // CCI period (0 = off)
input double InpCciLevel   = 0.0;   // CCI level (buys above, sells below -level)
input double InpStopPips   = 35.0;  // Stop loss (pips)
input double InpTargetPips = 0.0;   // Take profit (pips, 0 = indicator exit only)
input bool   InpAllowShort = true;  // Allow sells
input ENUM_EMARC_ENTRY InpEntryMode = ENTRY_EMA_CROSS; // Entry
input ENUM_EMARC_EXIT  InpExitMode  = EXIT_INDICATOR;  // Exit

int g_fast = INVALID_HANDLE, g_slow = INVALID_HANDLE, g_rsi = INVALID_HANDLE, g_cci = INVALID_HANDLE;

double Pip() { return((_Digits == 5 || _Digits == 3) ? 10.0 * _Point : _Point); }

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpFastEMA < 1 || InpSlowEMA <= InpFastEMA || InpRsiPeriod < 2 || (InpCciPeriod != 0 && InpCciPeriod < 2) || InpStopPips <= 0.0 ||
      InpTargetPips < 0.0 || InpRsiLevel < 50.0 || InpRsiLevel >= 100.0 || InpCciLevel < 0.0)
     {
      Print("Invalid inputs: slow EMA > fast EMA >= 1, RSI period >= 2, CCI period 0 or >= 2, stop pips > 0, target pips >= 0, 50 <= RSI level < 100, CCI level >= 0");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   g_fast = iMA(_Symbol, InpTimeframe, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_slow = iMA(_Symbol, InpTimeframe, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   g_rsi  = iRSI(_Symbol, InpTimeframe, InpRsiPeriod, PRICE_CLOSE);
   if(InpCciPeriod > 0)
      g_cci = iCCI(_Symbol, InpTimeframe, InpCciPeriod, PRICE_TYPICAL);
   if(g_fast == INVALID_HANDLE || g_slow == INVALID_HANDLE || g_rsi == INVALID_HANDLE || (InpCciPeriod > 0 && g_cci == INVALID_HANDLE))
     {
      Print("Failed to create indicators, error ", GetLastError());
      return(INIT_FAILED);
     }
   PrintFormat("%s v%s started on %s %s, magic %I64u, own positions: %d",
               EA_NAME, EA_VERSION, _Symbol, EnumToString(InpTimeframe), InpMagic, CountOwnPositions());
   PrintFormat("Inputs: EMA %d/%d | RSI(%d) level %.0f | CCI(%d) level %.0f | entry %s | exit %s | stop %.1f pips | target %s | shorts %s | risk %s %.2f",
               InpFastEMA, InpSlowEMA, InpRsiPeriod, InpRsiLevel, InpCciPeriod, InpCciLevel,
               InpEntryMode == ENTRY_EMA_CROSS ? "EMA cross" : "both crossed", InpExitMode == EXIT_INDICATOR ? "indicator" : "reverse", InpStopPips,
               InpTargetPips > 0.0 ? StringFormat("%.1f pips", InpTargetPips) : "off", InpAllowShort ? "on" : "off",
               InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   const int h[] = {g_fast, g_slow, g_rsi, g_cci};
   for(int i = 0; i < ArraySize(h); i++)
      if(h[i] != INVALID_HANDLE)
         IndicatorRelease(h[i]);
   Core_Deinit(reason);
  }

void OnTick()
  {
   Core_OnTickStart();
   const datetime bar = Core_CurrentBar();
   Core_RetryPending(bar);
   if(!Core_IsNewBar(bar))
      return;
   double f[2], s[2], r[2], c[2] = {0.0, 0.0};
   if(CopyBuffer(g_fast, 0, 1, 2, f) < 2 || CopyBuffer(g_slow, 0, 1, 2, s) < 2 ||
      CopyBuffer(g_rsi, 0, 1, 2, r) < 2 || (InpCciPeriod > 0 && CopyBuffer(g_cci, 0, 1, 2, c) < 2))
      return;                                      // data not ready: bar stays unprocessed, retried next tick
   Core_MarkBar(bar);
   // oldest-first: f[1] = shift 1 (last closed bar), f[0] = shift 2
   const double f1 = f[1], f2 = f[0], s1 = s[1], s2 = s[0], rsi = r[1], rsi2 = r[0], cci = c[1], cci2 = c[0];
   const bool crossUp = (f1 > s1 && f2 <= s2), crossDn = (f1 < s1 && f2 >= s2);
   const bool cciOff = (InpCciPeriod == 0);
   const bool bull  = (rsi  > InpRsiLevel && (cciOff || cci  > InpCciLevel)), bear  = (rsi  < 100.0 - InpRsiLevel && (cciOff || cci  < -InpCciLevel));
   const bool bull2 = (rsi2 > InpRsiLevel && (cciOff || cci2 > InpCciLevel)), bear2 = (rsi2 < 100.0 - InpRsiLevel && (cciOff || cci2 < -InpCciLevel));
   const bool buySig  = (InpEntryMode == ENTRY_EMA_CROSS) ? (crossUp && bull) : (f1 > s1 && bull && !(f2 > s2 && bull2));
   const bool sellSig = (InpEntryMode == ENTRY_EMA_CROSS) ? (crossDn && bear) : (f1 < s1 && bear && !(f2 < s2 && bear2));
   const string ctx = StringFormat("ema %.6f/%.6f rsi %.2f cci %.2f", f1, s1, rsi, cci);
   ulong ticket = 0;
   if(Core_SelectOwnPosition(ticket))
     {
      const bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      const bool exitSig = (InpExitMode == EXIT_REVERSE) ? (isBuy ? sellSig : buySig)
                                                         : (isBuy ? (crossDn || bear) : (crossUp || bull));
      if(!exitSig)
        {
         Core_LogBar(bar, ctx + " | holding");
         return;
        }
      PrintFormat("EMARC EXIT %s f1=%.8f f2=%.8f s1=%.8f s2=%.8f rsi=%.4f cci=%.4f rsi2=%.4f cci2=%.4f", isBuy ? "BUY" : "SELL", f1, f2, s1, s2, rsi, cci, rsi2, cci2);
      if(!Core_ClosePosition(ticket, "expert") || CountOwnPositions() > 0)
        {
         Core_LogBar(bar, ctx + " | exit sent");
         return;                                  // reversal only once the close is confirmed (same tick in the tester)
        }
     }
   int sig = buySig ? 1 : (sellSig && InpAllowShort) ? -1 : 0;
   if(sig == 0)
     {
      Core_LogBar(bar, ctx + " | no signal");
      return;
     }
   if(!g_symbol.RefreshRates())
      return;
   const bool   buy    = (sig > 0);
   const double price  = buy ? g_symbol.Ask() : g_symbol.Bid();
   const double slDist = InpStopPips * Pip();
   const double tp     = InpTargetPips > 0.0 ? NormalizeDouble(buy ? price + InpTargetPips * Pip() : price - InpTargetPips * Pip(), g_symbol.Digits()) : 0.0;
   PrintFormat("EMARC SIGNAL %s f1=%.8f f2=%.8f s1=%.8f s2=%.8f rsi=%.4f cci=%.4f rsi2=%.4f cci2=%.4f sl_dist=%.5f tp=%.5f",
               buy ? "BUY" : "SELL", f1, f2, s1, s2, rsi, cci, rsi2, cci2, slDist, tp);
   Core_LogBar(bar, ctx + StringFormat(" | %s stop %.1f pips", buy ? "BUY" : "SELL", InpStopPips));
   Core_Open(buy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL, slDist, tp);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                MA_Channel_EA.mq5 |
//|  Jeffrey Kennedy's moving-average price channel (EWI, 2010):     |
//|  upper = SMA(high, N), lower = SMA(low, N), signal = SMA(close,  |
//|  fast). BREAKOUT entry = signal line crosses the channel;        |
//|  PULLBACK entry = after a channel break, the signal line dips    |
//|  inside the channel and turns back. Exit = opposite channel      |
//|  cross, or fast/slow SMA cross against the position, or R x stop |
//|  target. Protective stop k x ATR in every mode. One position at a|
//|  time. Execution, guards and trade log from EACore.mqh.          |
//|  v1.01 defaults: H1, PULLBACK entry, CHANNEL exit, long-only     |
//|        (Stage A winner, spec 2026-10-16 outcome: PF 1.61, +99 R).|
//|  v1.00: the PDF's breakout system (BREAKOUT, CHANNEL, both sides)|
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.01"
#property strict
#property description "MA price channel (SMA of highs/lows + fast SMA of closes): breakout or pullback entry, channel / MA-cross / target exit; MACD_Cross_EA v1.42 safety core"

#define EA_NAME    "MA_Channel_EA"
#define EA_VERSION "1.01"
#define EA_MAGIC   261016
#define EA_COMMENT "MA_CH"
#define EA_TIMEFRAME PERIOD_H1
#define EA_SPREAD_WAIT_MIN 0   // a target is R x stop from the signal price: a retried entry would break that ratio
#include "EACore.mqh"

enum ENUM_ENTRY_MODE { ENTRY_BREAKOUT = 0,  // Signal line crosses the channel
                       ENTRY_PULLBACK = 1 };// Dip into the channel that turns back (after a channel break)
enum ENUM_EXIT_MODE  { EXIT_CHANNEL = 0,    // Opposite channel cross (stop-and-reverse)
                       EXIT_CROSS   = 1,    // Fast/slow SMA cross against the position
                       EXIT_TARGET  = 2 };  // Target R x stop, no bar exit

input group "=== Strategy ==="
input int             InpFastMA     = 5;              // Fast SMA of closes (signal line)
input int             InpSlowMA     = 10;             // Slow SMA of closes (EXIT_CROSS)
input int             InpChannelMA  = 20;             // Channel: SMA of highs / SMA of lows
input ENUM_ENTRY_MODE InpEntryMode  = ENTRY_PULLBACK; // Entry
input ENUM_EXIT_MODE  InpExitMode   = EXIT_CHANNEL;   // Exit
input double          InpTargetR    = 2.0;            // Target, x stop distance (EXIT_TARGET)
input bool            InpAllowShort = false;          // Allow sells
input int             InpATRPeriod  = 20;             // ATR period (signal timeframe)
input double          InpStopATR    = 2.0;            // Protective stop, x ATR
input ENUM_TIMEFRAMES InpTrendTF    = PERIOD_H4;      // Trend filter timeframe
input int             InpTrendEMA   = 0;              // Trend EMA period on that timeframe (0 = off)

int g_fast = INVALID_HANDLE, g_slow = INVALID_HANDLE, g_up = INVALID_HANDLE, g_lo = INVALID_HANDLE,
    g_atr = INVALID_HANDLE, g_trend = INVALID_HANDLE;
int g_state = 0;   // last channel break: +1 up, -1 down, 0 none seen yet (rebuilt from bars after a restart)

ENUM_TIMEFRAMES TrendTF() { return(InpTrendTF == PERIOD_CURRENT ? InpTimeframe : InpTrendTF); }

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpFastMA < 1 || InpSlowMA <= InpFastMA || InpChannelMA < 2 || InpATRPeriod <= 1 || InpStopATR <= 0.0 ||
      InpTargetR < 0.0 || InpTrendEMA < 0 || (InpExitMode == EXIT_TARGET && InpTargetR <= 0.0))
     {
      Print("Invalid inputs: fast >= 1, slow > fast, channel >= 2, ATR period > 1, stop ATR > 0, target R > 0 in EXIT_TARGET, trend EMA >= 0");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   g_fast = iMA(_Symbol, InpTimeframe, InpFastMA, 0, MODE_SMA, PRICE_CLOSE);
   g_slow = iMA(_Symbol, InpTimeframe, InpSlowMA, 0, MODE_SMA, PRICE_CLOSE);
   g_up   = iMA(_Symbol, InpTimeframe, InpChannelMA, 0, MODE_SMA, PRICE_HIGH);
   g_lo   = iMA(_Symbol, InpTimeframe, InpChannelMA, 0, MODE_SMA, PRICE_LOW);
   g_atr  = iATR(_Symbol, InpTimeframe, InpATRPeriod);
   if(InpTrendEMA > 0)
      g_trend = iMA(_Symbol, TrendTF(), InpTrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(g_fast == INVALID_HANDLE || g_slow == INVALID_HANDLE || g_up == INVALID_HANDLE || g_lo == INVALID_HANDLE ||
      g_atr == INVALID_HANDLE || (InpTrendEMA > 0 && g_trend == INVALID_HANDLE))
     {
      Print("Failed to create indicators, error ", GetLastError());
      return(INIT_FAILED);
     }
   PrintFormat("%s v%s started on %s %s, magic %I64u, own positions: %d",
               EA_NAME, EA_VERSION, _Symbol, EnumToString(InpTimeframe), InpMagic, CountOwnPositions());
   PrintFormat("Inputs: SMA %d/%d, channel SMA%d of highs/lows | entry %s | exit %s | target %.2f R | stop %.2f x ATR(%d) | shorts %s | trend %s | risk %s %.2f",
               InpFastMA, InpSlowMA, InpChannelMA, EnumToString(InpEntryMode), EnumToString(InpExitMode), InpTargetR,
               InpStopATR, InpATRPeriod, InpAllowShort ? "on" : "off",
               InpTrendEMA > 0 ? StringFormat("%s EMA%d", EnumToString(TrendTF()), InpTrendEMA) : "off",
               InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   const int h[] = {g_fast, g_slow, g_up, g_lo, g_atr, g_trend};
   for(int i = 0; i < ArraySize(h); i++)
      if(h[i] != INVALID_HANDLE)
         IndicatorRelease(h[i]);
   Core_Deinit(reason);
  }

//--- rebuild g_state from the last 300 closed bars (restart safety for PULLBACK mode)
void RebuildState()
  {
   double f[], u[], l[];
   const int n = 300;
   if(CopyBuffer(g_fast, 0, 1, n, f) < n || CopyBuffer(g_up, 0, 1, n, u) < n || CopyBuffer(g_lo, 0, 1, n, l) < n)
      return;
   for(int i = 1; i < n; i++)                        // oldest-first: i-1 is the bar before i
     {
      if(f[i] > u[i] && f[i - 1] <= u[i - 1]) g_state = 1;
      else if(f[i] < l[i] && f[i - 1] >= l[i - 1]) g_state = -1;
     }
  }

void OnTick()
  {
   Core_OnTickStart();
   const datetime bar = Core_CurrentBar();
   Core_RetryPending(bar);
   if(!Core_IsNewBar(bar))
      return;
   static bool stateBuilt = false;
   double f[3], s[2], u[3], l[3], atr[1], ema[1];
   double htfClose = 0.0;
   ema[0] = 0.0;
   if(CopyBuffer(g_fast, 0, 1, 3, f) < 3 || CopyBuffer(g_slow, 0, 1, 2, s) < 2 || CopyBuffer(g_up, 0, 1, 3, u) < 3 ||
      CopyBuffer(g_lo, 0, 1, 3, l) < 3 || CopyBuffer(g_atr, 0, 1, 1, atr) < 1 || atr[0] <= 0.0)
      return;                                      // data not ready: bar stays unprocessed, retried next tick
   if(InpTrendEMA > 0)
     {
      htfClose = iClose(_Symbol, TrendTF(), 1);
      if(CopyBuffer(g_trend, 0, 1, 1, ema) < 1 || ema[0] == EMPTY_VALUE || htfClose <= 0.0)
         return;
     }
   if(!stateBuilt) { RebuildState(); stateBuilt = true; }
   Core_MarkBar(bar);
   // CopyBuffer arrays are oldest-first: [2] = shift 1 (last closed bar), [1] = shift 2, [0] = shift 3
   const double f1 = f[2], f2 = f[1], f3 = f[0], u1 = u[2], u2 = u[1], l1 = l[2], l2 = l[1], s1 = s[1], s2 = s[0];
   const bool crossUp = (f1 > u1 && f2 <= u2), crossDn = (f1 < l1 && f2 >= l2);
   if(crossUp) g_state = 1; else if(crossDn) g_state = -1;
   const string ctx = StringFormat("fast %.2f/%.2f slow %.2f up %.2f lo %.2f atr %.2f state %d", f1, f2, s1, u1, l1, atr[0], g_state);
   ulong ticket = 0;
   if(Core_SelectOwnPosition(ticket))
     {
      const bool isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
      bool exitSig = false;
      if(InpExitMode == EXIT_CHANNEL) exitSig = isBuy ? crossDn : crossUp;
      if(InpExitMode == EXIT_CROSS)   exitSig = isBuy ? (f1 < s1 && f2 >= s2) : (f1 > s1 && f2 <= s2);
      if(!exitSig)
        {
         Core_LogBar(bar, ctx + " | holding");
         return;
        }
      PrintFormat("MACH EXIT %s f1=%.2f f2=%.2f s1=%.2f s2=%.2f up1=%.2f up2=%.2f lo1=%.2f lo2=%.2f", isBuy ? "BUY" : "SELL", f1, f2, s1, s2, u1, u2, l1, l2);
      if(!Core_ClosePosition(ticket, "expert") || CountOwnPositions() > 0)
        {
         Core_LogBar(bar, ctx + " | exit sent");
         return;                                  // reversal only once the close is confirmed (same tick in the tester)
        }
      Core_LogBar(bar, ctx + " | exited");
      if(InpExitMode != EXIT_CHANNEL)
         return;                                  // only the channel system reverses on the same bar
     }
   int sig = 0;
   if(InpEntryMode == ENTRY_BREAKOUT)
      sig = crossUp ? 1 : (crossDn ? -1 : 0);
   else
     {
      if(g_state > 0 && f2 < u2 && f2 >= l2 && f2 < f3 && f1 > f2) sig = 1;   // dip inside the channel, turned up
      if(g_state < 0 && f2 > l2 && f2 <= u2 && f2 > f3 && f1 < f2) sig = -1;  // bounce inside the channel, turned down
     }
   if(sig < 0 && !InpAllowShort)
      sig = 0;
   if(sig == 0)
     {
      Core_LogBar(bar, ctx + " | no signal");
      return;
     }
   const bool buy = (sig > 0);
   if(InpTrendEMA > 0 && (buy ? htfClose <= ema[0] : htfClose >= ema[0]))
     {
      Core_LogBar(bar, ctx + StringFormat(" | %s filtered: %s close %.2f vs EMA%d %.2f",
                  buy ? "BUY" : "SELL", EnumToString(TrendTF()), htfClose, InpTrendEMA, ema[0]));
      return;
     }
   if(!g_symbol.RefreshRates())
      return;
   const double slDist = InpStopATR * atr[0];
   const double price  = buy ? g_symbol.Ask() : g_symbol.Bid();
   const double tp     = (InpExitMode == EXIT_TARGET) ? NormalizeDouble(buy ? price + InpTargetR * slDist : price - InpTargetR * slDist, g_symbol.Digits()) : 0.0;
   PrintFormat("MACH SIGNAL %s f1=%.2f f2=%.2f f3=%.2f up1=%.2f up2=%.2f lo1=%.2f lo2=%.2f slow1=%.2f atr=%.2f sl_dist=%.2f tp=%.2f state=%d mode=%d",
               buy ? "BUY" : "SELL", f1, f2, f3, u1, u2, l1, l2, s1, atr[0], slDist, tp, g_state, (int)InpEntryMode);
   Core_LogBar(bar, ctx + StringFormat(" | %s stop dist %.2f", buy ? "BUY" : "SELL", slDist));
   Core_Open(buy ? POSITION_TYPE_BUY : POSITION_TYPE_SELL, slDist, tp);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                             USDX_Trader_v1.33.mq5 |
//|  Synthetic index chart + basket trading with virtual TP/SL.      |
//|                                                                  |
//|  VERSION HISTORY                                                 |
//|   v1.00  Initial: USDX (DXY formula) custom symbol, live ticks,  |
//|          basket trading, virtual TP/SL in index points.          |
//|   v1.10  New GUI, custom combinations, last N bars rebuilt from  |
//|          real ticks.                                             |
//|   v1.20  - Preset dropdown: USDX, Broad USD 9-leg, Broad USD    |
//|            12-leg (BBDXY weights), Equal-weight USD G6, Custom.  |
//|          - Legs below the minimum lot are rounded UP to the      |
//|            smallest allowed size; a confirmation dialog shows    |
//|            ideal vs actual volumes before the trade is placed.   |
//|          - TP/SL levels drawn on chart BEFORE entry (projected   |
//|            for BUY and SELL) and AFTER entry (live basket).      |
//|          - TP = 0 or SL = 0 means no TP / no SL.                 |
//|          - Fix: removed "%.*f" formats (not supported in MQL5).  |
//|          - Symbol matching prefers names that START with the     |
//|            base name (e.g. EURUSD.m) over names containing it.   |
//|                                                                  |
//|   v1.30  - Strategy Tester / MQL5 Market validation support:     |
//|            custom-symbol functions are skipped in the tester,    |
//|            index is computed virtually from the legs, legs are   |
//|            auto-selected, missing legs are dropped (weights      |
//|            renormalised), no dialogs, margin pre-check.          |
//|          - Optional auto-trade mode (EMA cross on index bars),   |
//|            ON in the tester by default, OFF live by default.     |
//|                                                                  |
//|   v1.31  - Every INIT_FAILED path now prints its reason.          |
//|          - Tester: legs are selected directly by name first,     |
//|            and legs that never receive quotes are dropped        |
//|            automatically so the test always trades.              |
//|                                                                  |
//|   v1.32  - Restart-safe history: existing custom history is kept  |
//|            (no more wipe/rebuild on every start). Bars missing   |
//|            while the terminal was off are filled from the legs'  |
//|            M1 data after the terminal has synchronised, and the  |
//|            gap is re-checked periodically while running.         |
//|          - Full rebuild only on first run or if the definition   |
//|            (preset/spec/digits/K) changed.                       |
//|                                                                  |
//|   v1.33  - Compiler warning fix: MqlTick.time_msc is long, the   |
//|            ulong cast was removed; redundant (long) casts gone.  |
//|                                                                  |
//|  USDX = 50.14348112 * EURUSD^-0.576 * USDJPY^0.136 *             |
//|         GBPUSD^-0.119 * USDCAD^0.091 * USDSEK^0.042 *           |
//|         USDCHF^0.036                                             |
//+------------------------------------------------------------------+
#property copyright "USDX Trader"
#property version   "1.33"
#property description "Synthetic index (USDX / broad USD presets / custom) chart + basket trading, virtual TP/SL"

#include <Trade\Trade.mqh>

#define EA_NAME     "USDX Trader"
#define EA_VERSION  "1.33"
#define MAXLEG      12

enum ENUM_PRESET
  {
   PRESET_USDX    = 0,  // USDX - ICE Dollar Index (6 legs)
   PRESET_BROAD9  = 1,  // Broad USD - 9 liquid legs (BBDXY-like)
   PRESET_BROAD12 = 2,  // Broad USD - 12 legs (full BBDXY weights)
   PRESET_EQ6     = 3,  // Equal-weight USD vs 6 majors
   PRESET_CUSTOM  = 4   // Custom (use the spec below)
  };

enum ENUM_FORMULA { FORMULA_GEOMETRIC = 0, FORMULA_LINEAR = 1 };

enum ENUM_AUTOMODE
  {
   AUTO_OFF    = 0,  // Manual only (panel buttons)
   AUTO_TESTER = 1,  // Auto-trade in Strategy Tester only
   AUTO_ALWAYS = 2   // Auto-trade always (live too)
  };

//--- inputs ---------------------------------------------------------
input group "=== Instrument definition ==="
input ENUM_PRESET  InpPreset       = PRESET_USDX;          // Combination preset
input string       InpUsdxName     = "USDX_SYNTH";         // Symbol name for the USDX preset
input string       InpSuffix       = "";                   // Broker suffix (blank = auto-detect)

input group "=== Custom preset only ==="
input string       InpCustomSpec   = "EURUSD:1;GBPUSD:-1"; // Legs  SYMBOL:weight;SYMBOL:weight
input ENUM_FORMULA InpCustomFormula= FORMULA_GEOMETRIC;    // Formula
input double       InpCustomK      = 1.0;                  // Geometric constant K (scale only)
input string       InpCustomName   = "CUSTOM_SYNTH";       // Symbol name
input int          InpCustomDigits = 5;                    // Symbol digits

input group "=== Chart / history ==="
input int    InpHistoryBars  = 20000;         // M1 bars of history to build (OHLC based)
input int    InpTickBars     = 20;            // Rebuild last N chart bars from real ticks (0 = off)
input ENUM_TIMEFRAMES InpTickTF = PERIOD_CURRENT; // Timeframe used for the N bars
input int    InpTickLimit    = 1500000;       // Max total ticks to download for rebuild
input bool   InpStoreTicks   = true;          // Also store rebuilt ticks in the custom symbol
input int    InpUpdateMs     = 250;           // Live update interval (ms)

input group "=== Trading ==="
input double InpLots         = 0.50;          // Basket size (start value)
input double InpLotStep      = 0.10;          // Size +/- button step
input double InpBasketUnit   = 100000.0;      // Geometric: account-ccy notional per 1.0 size
input double InpTPIndex      = 0.50;          // Virtual TP in index points (0 = no TP)
input double InpSLIndex      = 0.50;          // Virtual SL in index points (0 = no SL)
input double InpWarnLegError = 25.0;          // Warn if a leg's lot rounding error exceeds this %
input bool   InpConfirm      = true;          // Always confirm before opening a basket
input ulong  InpMagic        = 20250101;      // Magic number (use a different one per instrument)
input int    InpDeviation    = 20;            // Max slippage (points)

input group "=== Automation (tester / optional live) ==="
input ENUM_AUTOMODE   InpAutoMode      = AUTO_TESTER;  // Auto-trade mode
input ENUM_TIMEFRAMES InpAutoTF        = PERIOD_H1;    // Auto: index bar timeframe
input int             InpFastEMA       = 12;           // Auto: fast EMA period
input int             InpSlowEMA       = 26;           // Auto: slow EMA period
input int             InpTesterStepSec = 1;            // Tester: evaluation step (seconds)

input group "=== Panel / chart ==="
input bool   InpShowPanel    = true;          // Show panel
input bool   InpShowPreview  = true;          // Show projected TP/SL lines before entry
input int    InpPanelX       = 10;            // Panel X
input int    InpPanelY       = 20;            // Panel Y

//--- preset constants -------------------------------------------------
// K scales each index to ~100 at these reference rates (scale only, no other meaning):
// EURUSD 1.15 USDJPY 150 GBPUSD 1.33 USDCAD 1.38 USDMXN 18.5 USDCNH 7.2 USDCHF 0.88
// AUDUSD 0.66 USDSGD 1.30 USDKRW 1400 USDINR 85 USDTWD 31
const double K_USDX    = 50.14348112;   // official ICE constant
const double K_BROAD9  = 31.459041;
const double K_BROAD12 = 22.031673;
const double K_EQ6     = 42.066857;

//--- active definition ----------------------------------------------
int    g_n = 0;
string g_base[MAXLEG];
double g_w[MAXLEG];
string g_sym[MAXLEG];
double g_K = 1.0;
ENUM_FORMULA g_mode = FORMULA_GEOMETRIC;
string g_name = "";
int    g_digits = 3;
string g_title = "USDX";

//--- runtime ---------------------------------------------------------
CTrade g_trade;
double g_lastBid = 0, g_lastAsk = 0, g_shownBid = 0;
long   g_lastMsc = 0, g_rebuildEndMsc = 0;
double g_lots = 0.5, g_tp = 0, g_sl = 0;
bool   g_collapsed = false;

//--- tester / automation state
bool     g_tester = false, g_visual = false;
datetime g_lastStep = 0;
int      g_autoSec = 3600;
long     g_barId = 0;
double   g_barClose = 0, g_emaF = 0, g_emaS = 0;
int      g_barCount = 0, g_prevSign = 0, g_signal = 0;
int      g_noQuoteSteps = 0;
datetime g_gapFrom = 0, g_nextHeal = 0;   // history gap healing
bool     g_adapted = false;

//--- basket state ------------------------------------------------------
bool   g_basketOpen = false, g_complete = false;
int    g_dir = 0, g_legs = 0;
double g_entry = 0, g_profit = 0;
double g_legVol[MAXLEG], g_legProfit[MAXLEG];
int    g_legSide[MAXLEG];

struct RatesBuf { MqlRates a[]; };
struct TickBuf  { MqlTick  a[]; };

const string PFX = "USDXEA_";
const string PP  = "USDXEA_P_";

//+------------------------------------------------------------------+
//| Definition setup                                                  |
//+------------------------------------------------------------------+
void AddLeg(const string b, const double w)
  {
   if(g_n >= MAXLEG) return;
   g_base[g_n] = b;
   g_w[g_n] = w;
   g_n++;
  }

bool SetupDefinition()
  {
   g_n = 0;
   g_mode = FORMULA_GEOMETRIC;
   g_digits = 3;

   switch(InpPreset)
     {
      case PRESET_USDX:
         AddLeg("EURUSD", -0.576); AddLeg("USDJPY", 0.136); AddLeg("GBPUSD", -0.119);
         AddLeg("USDCAD", 0.091);  AddLeg("USDSEK", 0.042); AddLeg("USDCHF", 0.036);
         g_K = K_USDX; g_name = InpUsdxName; g_title = "USDX";
         return true;

      case PRESET_BROAD9:   // BBDXY 2026-27 weights, KRW/INR/TWD dropped, renormalised to 100%
         AddLeg("EURUSD", -0.3183); AddLeg("USDJPY", 0.1404); AddLeg("USDCAD", 0.1208);
         AddLeg("USDMXN", 0.1079);  AddLeg("GBPUSD", -0.0985); AddLeg("USDCNH", 0.0768);
         AddLeg("USDCHF", 0.0594);  AddLeg("AUDUSD", -0.0480); AddLeg("USDSGD", 0.0300);
         g_K = K_BROAD9; g_name = "BROAD9_SYNTH"; g_title = "BROAD9";
         return true;

      case PRESET_BROAD12:  // BBDXY 2026-27 target weights
         AddLeg("EURUSD", -0.2901); AddLeg("USDJPY", 0.1280); AddLeg("USDCAD", 0.1101);
         AddLeg("USDMXN", 0.0983);  AddLeg("GBPUSD", -0.0898); AddLeg("USDCNH", 0.0700);
         AddLeg("USDCHF", 0.0541);  AddLeg("AUDUSD", -0.0437); AddLeg("USDKRW", 0.0322);
         AddLeg("USDINR", 0.0314);  AddLeg("USDSGD", 0.0273);  AddLeg("USDTWD", 0.0250);
         g_K = K_BROAD12; g_name = "BROAD12_SYNTH"; g_title = "BROAD12";
         return true;

      case PRESET_EQ6:      // equal-weight USD vs EUR GBP AUD JPY CHF CAD
         AddLeg("EURUSD", -1.0 / 6.0); AddLeg("GBPUSD", -1.0 / 6.0); AddLeg("AUDUSD", -1.0 / 6.0);
         AddLeg("USDJPY",  1.0 / 6.0); AddLeg("USDCHF",  1.0 / 6.0); AddLeg("USDCAD",  1.0 / 6.0);
         g_K = K_EQ6; g_name = "USDEQ6_SYNTH"; g_title = "USDEQ6";
         return true;

      default: break;
     }

   //--- custom
   string tmp = InpCustomSpec;
   StringReplace(tmp, ",", ";");
   StringReplace(tmp, " ", "");
   string parts[];
   int np = StringSplit(tmp, ';', parts);
   if(np < 1 || np > MAXLEG)
     { Alert(EA_NAME, ": custom spec must have 1-", MAXLEG, " legs."); return false; }

   for(int k = 0; k < np; k++)
     {
      if(parts[k] == "") continue;
      string kv[];
      if(StringSplit(parts[k], ':', kv) != 2)
        { Alert(EA_NAME, ": bad custom leg '", parts[k], "' (use SYMBOL:weight)."); return false; }
      double w = StringToDouble(kv[1]);
      if(kv[0] == "" || w == 0.0)
        { Alert(EA_NAME, ": bad custom leg '", parts[k], "'."); return false; }
      for(int j = 0; j < g_n; j++)
         if(g_base[j] == kv[0]) { Alert(EA_NAME, ": duplicate symbol ", kv[0]); return false; }
      AddLeg(kv[0], w);
     }
   if(g_n < 1) { Alert(EA_NAME, ": custom spec is empty."); return false; }
   g_K = InpCustomK; g_mode = InpCustomFormula;
   g_name = InpCustomName; g_digits = InpCustomDigits; g_title = InpCustomName;
   return true;
  }

string Fmt(const double v) { return DoubleToString(v, g_digits); }
string FmtS(const double v) { return (v >= 0 ? "+" : "") + DoubleToString(v, g_digits); }

//+------------------------------------------------------------------+
//| Index maths                                                       |
//+------------------------------------------------------------------+
double CalcIdx(const double &v[])
  {
   double r;
   if(g_mode == FORMULA_GEOMETRIC)
     {
      r = g_K;
      for(int i = 0; i < g_n; i++) r *= MathPow(v[i], g_w[i]);
     }
   else
     {
      r = 0;
      for(int i = 0; i < g_n; i++) r += g_w[i] * v[i];
     }
   return r;
  }

// Index bid = value when closing a LONG index; ask = cost of opening a LONG index.
void CalcBidAsk(const double &pb[], const double &pa[], double &bid, double &ask)
  {
   double vb[MAXLEG], va[MAXLEG];
   for(int i = 0; i < g_n; i++)
     {
      if(g_w[i] > 0) { vb[i] = pb[i]; va[i] = pa[i]; }
      else           { vb[i] = pa[i]; va[i] = pb[i]; }
     }
   bid = CalcIdx(vb);
   ask = CalcIdx(va);
  }

bool GetQuote(double &bid, double &ask)
  {
   double pb[MAXLEG], pa[MAXLEG];
   for(int i = 0; i < g_n; i++)
     {
      pb[i] = SymbolInfoDouble(g_sym[i], SYMBOL_BID);
      pa[i] = SymbolInfoDouble(g_sym[i], SYMBOL_ASK);
      if(pb[i] <= 0 || pa[i] <= 0) return false;
     }
   CalcBidAsk(pb, pa, bid, ask);
   return true;
  }

//+------------------------------------------------------------------+
//| Symbol discovery (Market Watch only)                              |
//+------------------------------------------------------------------+
string FindSymbolRaw(const string baseName)
  {
   int total = SymbolsTotal(!g_tester);   // tester: search all server symbols
   if(InpSuffix != "")
     {
      string want = baseName + InpSuffix;
      for(int i = 0; i < total; i++)
         if(SymbolName(i, true) == want) return want;
      return "";
     }
   string bestPrefix = "", bestContains = "";
   for(int i = 0; i < total; i++)
     {
      string n = SymbolName(i, true);
      if(n == g_name) continue;
      if(SymbolInfoInteger(n, SYMBOL_CUSTOM)) continue;
      if(n == baseName) return n;
      int pos = StringFind(n, baseName);
      if(pos == 0)
        { if(bestPrefix == "" || StringLen(n) < StringLen(bestPrefix)) bestPrefix = n; }
      else if(pos > 0)
        { if(bestContains == "" || StringLen(n) < StringLen(bestContains)) bestContains = n; }
     }
   return (bestPrefix != "") ? bestPrefix : bestContains;
  }

string FindSymbol(const string baseName)
  {
   if(g_tester)   // direct selection by name works even if the symbol list is restricted
     {
      string want = baseName + InpSuffix;
      if(SymbolSelect(want, true)) return want;
     }
   string s = FindSymbolRaw(baseName);
   if(s != "" && g_tester) SymbolSelect(s, true);
   return s;
  }

// Tester only: drop legs that are not available, renormalise, never leave zero legs.
void AdaptLegsForTester()
  {
   double oldSum = 0, newSum = 0;
   for(int i = 0; i < g_n; i++) oldSum += MathAbs(g_w[i]);
   int m = 0;
   for(int i = 0; i < g_n; i++)
     {
      if(g_sym[i] == "") continue;
      g_base[m] = g_base[i]; g_sym[m] = g_sym[i]; g_w[m] = g_w[i];
      newSum += MathAbs(g_w[m]);
      m++;
     }
   g_n = m;
   if(g_n < 1)
     {
      g_n = 1; g_base[0] = _Symbol; g_sym[0] = _Symbol; g_w[0] = 1.0;
      g_K = 1.0; g_mode = FORMULA_GEOMETRIC;
      Print("Tester: no leg symbols available - using chart symbol ", _Symbol, " as single leg.");
     }
   else if(g_mode == FORMULA_GEOMETRIC && newSum > 0)
     {
      for(int i = 0; i < g_n; i++) g_w[i] *= oldSum / newSum;
      Print("Tester: some legs unavailable - using ", g_n, " legs, weights renormalised.");
     }
  }

bool ResolveSymbols()
  {
   string missing = "";
   for(int i = 0; i < g_n; i++)
     {
      g_sym[i] = FindSymbol(g_base[i]);
      if(g_sym[i] == "") missing += g_base[i] + " ";
     }
   if(missing != "" && g_tester)
      AdaptLegsForTester();
   else if(missing != "")
     {
      string m = EA_NAME + ": not in Market Watch: " + missing +
                 "- add them (right-click Market Watch > Symbols) or pick another preset.";
      Print(m); Alert(m);
      return false;
     }
   string list = "";
   for(int i = 0; i < g_n; i++) list += g_sym[i] + (i < g_n - 1 ? ", " : "");
   Print(EA_NAME, " v", EA_VERSION, " [", g_title, "] legs: ", list);
   return true;
  }

//+------------------------------------------------------------------+
//| Custom symbol + M1 OHLC history                                   |
//+------------------------------------------------------------------+
bool PrepareCustomSymbol()
  {
   bool custom = false;
   if(!SymbolExist(g_name, custom))
     {
      if(!CustomSymbolCreate(g_name, "Custom\\Index"))
        { Print("CustomSymbolCreate failed: ", GetLastError()); return false; }
     }
   else if(!custom)
     {
      Alert(EA_NAME, ": '", g_name, "' exists and is not a custom symbol. Change the name.");
      return false;
     }
   CustomSymbolSetInteger(g_name, SYMBOL_DIGITS, g_digits);
   CustomSymbolSetString(g_name, SYMBOL_DESCRIPTION, "Synthetic index " + g_title + " (" + EA_NAME + " v" + EA_VERSION + ")");
   CustomSymbolSetInteger(g_name, SYMBOL_TRADE_MODE, SYMBOL_TRADE_MODE_DISABLED);
   SymbolSelect(g_name, true);
   return true;
  }

// Align the legs' M1 bars on the first leg's timeline and compute index bars (time >= minTime).
int BuildBarsFromRates(RatesBuf &R[], const datetime minTime, MqlRates &out[])
  {
   int n0 = ArraySize(R[0].a);
   ArrayResize(out, n0);
   int cnt = 0;
   int idx[MAXLEG];
   ArrayInitialize(idx, 0);

   for(int k = 0; k < n0; k++)
     {
      datetime t = R[0].a[k].time;
      double o[MAXLEG], h[MAXLEG], l[MAXLEG], c[MAXLEG];
      bool ok = true;
      for(int i = 0; i < g_n; i++)
        {
         int sz = ArraySize(R[i].a);
         while(idx[i] + 1 < sz && R[i].a[idx[i] + 1].time <= t) idx[i]++;
         if(sz <= 0 || R[i].a[idx[i]].time > t) { ok = false; continue; }
         MqlRates b = R[i].a[idx[i]];
         if(b.time == t) { o[i] = b.open; h[i] = b.high; l[i] = b.low; c[i] = b.close; }
         else            { o[i] = h[i] = l[i] = c[i] = b.close; }
        }
      if(!ok || t < minTime) continue;
      double vo = CalcIdx(o), vc = CalcIdx(c), vh = CalcIdx(h), vl = CalcIdx(l);
      out[cnt].time        = t;
      out[cnt].open        = vo;
      out[cnt].close       = vc;
      out[cnt].high        = MathMax(MathMax(vo, vc), MathMax(vh, vl));
      out[cnt].low         = MathMin(MathMin(vo, vc), MathMin(vh, vl));
      out[cnt].tick_volume = MathMax(1, R[0].a[k].tick_volume);
      out[cnt].spread      = 0;
      out[cnt].real_volume = 0;
      cnt++;
     }
   ArrayResize(out, cnt);
   return cnt;
  }

bool LegsSynced()
  {
   if(!TerminalInfoInteger(TERMINAL_CONNECTED)) return false;
   for(int i = 0; i < g_n; i++)
      if(!SeriesInfoInteger(g_sym[i], PERIOD_M1, SERIES_SYNCHRONIZED)) return false;
   return true;
  }

// After a terminal restart the leg histories may not be downloaded yet - wait (bounded).
void WaitForSync(const int maxSec)
  {
   uint t0 = GetTickCount();
   MqlRates tmp[];
   while(!IsStopped())
     {
      for(int i = 0; i < g_n; i++) CopyRates(g_sym[i], PERIOD_M1, 0, 1, tmp);   // triggers loading
      if(LegsSynced()) return;
      if(GetTickCount() - t0 > (uint)maxSec * 1000)
        { Print("Leg history not fully synchronised yet - gap will be healed later."); return; }
      Sleep(500);
     }
  }

// Full rebuild (first run, or definition changed): replaces ALL history of the custom symbol.
bool BuildHistory()
  {
   RatesBuf R[MAXLEG];
   for(int i = 0; i < g_n; i++)
     {
      SymbolSelect(g_sym[i], true);
      int n = -1;
      for(int attempt = 0; attempt < 10; attempt++)
        {
         n = CopyRates(g_sym[i], PERIOD_M1, 0, InpHistoryBars, R[i].a);
         if(n > 0 && n >= (int)(InpHistoryBars * 0.9)) break;
         Sleep(300);
        }
      if(n <= 0) { Print("No M1 history for ", g_sym[i], " err=", GetLastError()); return false; }
     }

   MqlRates out[];
   int cnt = BuildBarsFromRates(R, 0, out);
   if(cnt == 0) { Print("No overlapping history across the legs."); return false; }

   CustomRatesDelete(g_name, 0, TimeCurrent() + 86400);
   int added = CustomRatesReplace(g_name, out[0].time, out[cnt - 1].time, out);
   if(added <= 0) { Print("CustomRatesReplace failed: ", GetLastError()); return false; }
   PrintFormat("%s M1 history built: %d bars (%s -> %s)", g_title, added,
               TimeToString(out[0].time), TimeToString(out[cnt - 1].time));
   return true;
  }

// Fill M1 bars that exist in the legs but are missing in the custom symbol (e.g. terminal was off).
// Never overwrites existing bars and never touches the current (live) minute.
int HealGap()
  {
   datetime now = TimeCurrent();
   datetime nowMin = now - now % 60;
   datetime from = (g_gapFrom != 0) ? g_gapFrom : nowMin - 240 * 60;
   datetime cap = nowMin - (datetime)InpHistoryBars * 60;
   if(from < cap) from = cap;

   MqlRates C[];
   int nc = CopyRates(g_name, PERIOD_M1, from, nowMin + 60, C);
   if(nc < 0) nc = 0;

   RatesBuf R[MAXLEG];
   for(int i = 0; i < g_n; i++)
     {
      int n = CopyRates(g_sym[i], PERIOD_M1, from - 900, nowMin + 60, R[i].a);
      if(n <= 0) return 0;                       // legs not ready yet - try again later
     }
   MqlRates out[];
   int cnt = BuildBarsFromRates(R, from, out);
   if(cnt <= 0) return 0;

   MqlRates fill[];
   ArrayResize(fill, cnt);
   int nf = 0, j = 0;
   for(int k = 0; k < cnt; k++)
     {
      if(out[k].time >= nowMin) break;
      while(j < nc && C[j].time < out[k].time) j++;
      if(j < nc && C[j].time == out[k].time) continue;     // bar already exists
      fill[nf++] = out[k];
     }
   if(nf > 0)
     {
      ArrayResize(fill, nf);
      int r = CustomRatesUpdate(g_name, fill);
      if(r > 0)
         PrintFormat("%s: filled %d missing M1 bars (%s -> %s)", g_title, nf,
                     TimeToString(fill[0].time), TimeToString(fill[nf - 1].time));
      else
         Print("HealGap: CustomRatesUpdate failed: ", GetLastError());
      ChartRedraw();
     }
   if(g_gapFrom != 0 && LegsSynced()) g_gapFrom = 0;       // gap fully processed
   return nf;
  }

// Signature of the active definition - full rebuild only if it changes.
double DefSig()
  {
   string t = g_name + "|" + IntegerToString(g_digits) + "|" + IntegerToString((int)g_mode) + "|" + DoubleToString(g_K, 8);
   for(int i = 0; i < g_n; i++) t += "|" + g_base[i] + ":" + DoubleToString(g_w[i], 6);
   ulong h = 5381;
   for(int i = 0; i < StringLen(t); i++) h = ((h << 5) + h) + (ulong)StringGetCharacter(t, i);
   return (double)(h & 0xFFFFFFFFFFFFF);                  // 52 bits: exact in a double
  }

bool HistoryExists()
  {
   return (SeriesInfoInteger(g_name, PERIOD_M1, SERIES_BARS_COUNT) > 100);
  }

//+------------------------------------------------------------------+
//| Rebuild the last N chart bars from REAL ticks of all legs         |
//+------------------------------------------------------------------+
bool RebuildFromTicks()
  {
   if(InpTickBars <= 0) return true;

   ENUM_TIMEFRAMES tf = (InpTickTF == PERIOD_CURRENT) ? (ENUM_TIMEFRAMES)Period() : InpTickTF;
   datetime start = iTime(g_sym[0], tf, InpTickBars - 1);
   if(start <= 0) start = TimeCurrent() - (datetime)(InpTickBars * PeriodSeconds(tf));
   long from_msc = (long)start * 1000;
   long to_msc   = ((long)TimeCurrent() + 3600) * 1000;

   TickBuf T[MAXLEG];
   long total = 0;
   for(int i = 0; i < g_n; i++)
     {
      int n = -1;
      for(int attempt = 0; attempt < 6; attempt++)
        {
         n = CopyTicksRange(g_sym[i], T[i].a, COPY_TICKS_INFO, (ulong)from_msc, (ulong)to_msc);
         if(n > 0) break;
         Sleep(400);
        }
      if(n <= 0) { Print("Tick rebuild: no ticks for ", g_sym[i], " err=", GetLastError()); return false; }
      total += n;
     }

   if(total > InpTickLimit)
     {
      int per = MathMax(1000, InpTickLimit / g_n);
      for(int i = 0; i < g_n; i++)
        {
         int n = ArraySize(T[i].a);
         if(n > per) from_msc = MathMax(from_msc, T[i].a[n - per].time_msc);
        }
      PrintFormat("Tick rebuild: %d ticks exceeds limit, window shortened to %s",
                  (int)total, TimeToString((datetime)(from_msc / 1000), TIME_DATE | TIME_SECONDS));
     }

   int p[MAXLEG];
   long remain = 0;
   for(int i = 0; i < g_n; i++)
     {
      p[i] = 0;
      int n = ArraySize(T[i].a);
      while(p[i] < n && T[i].a[p[i]].time_msc < from_msc) p[i]++;
      remain += (n - p[i]);
     }
   if(remain <= 0) return false;

   MqlTick oticks[];
   ArrayResize(oticks, (int)remain);
   int nT = 0;
   int maxBars = (int)((to_msc - from_msc) / 60000) + 4;
   MqlRates bars[];
   ArrayResize(bars, maxBars);
   int nB = 0;

   double pb[MAXLEG], pa[MAXLEG];
   bool have[MAXLEG];
   ArrayInitialize(have, false);
   int haveCnt = 0;
   long alignedStart = -1;
   long curMin = -1;
   double bo = 0, bh = 0, bl = 0, bc = 0;
   long bvol = 0;
   double lastBid = 0, lastAsk = 0;

   while(true)
     {
      int best = -1;
      long bt = LONG_MAX;
      for(int i = 0; i < g_n; i++)
        {
         if(p[i] >= ArraySize(T[i].a)) continue;
         long t = T[i].a[p[i]].time_msc;
         if(t < bt) { bt = t; best = i; }
        }
      if(best < 0) break;

      MqlTick tk = T[best].a[p[best]];
      p[best]++;
      if(tk.bid <= 0 || tk.ask <= 0) continue;
      pb[best] = tk.bid; pa[best] = tk.ask;
      if(!have[best]) { have[best] = true; haveCnt++; }
      if(haveCnt < g_n) continue;

      long tm = tk.time_msc;
      if(alignedStart < 0) alignedStart = ((tm / 60000) + 1) * 60000;
      if(tm < alignedStart) continue;

      double bid, ask;
      CalcBidAsk(pb, pa, bid, ask);
      bid = NormalizeDouble(bid, g_digits);
      ask = NormalizeDouble(ask, g_digits);
      if(bid == lastBid && ask == lastAsk) continue;
      lastBid = bid; lastAsk = ask;

      oticks[nT].time        = (datetime)(tm / 1000);
      oticks[nT].time_msc    = tm;
      oticks[nT].bid         = bid;
      oticks[nT].ask         = ask;
      oticks[nT].last        = 0;
      oticks[nT].volume      = 0;
      oticks[nT].volume_real = 0;
      oticks[nT].flags       = TICK_FLAG_BID | TICK_FLAG_ASK;
      nT++;

      long m = tm / 60000;
      if(m != curMin)
        {
         if(curMin >= 0 && nB < maxBars)
           {
            bars[nB].time = (datetime)(curMin * 60);
            bars[nB].open = bo; bars[nB].high = bh; bars[nB].low = bl; bars[nB].close = bc;
            bars[nB].tick_volume = bvol; bars[nB].spread = 0; bars[nB].real_volume = 0;
            nB++;
           }
         curMin = m; bo = bh = bl = bc = bid; bvol = 1;
        }
      else
        {
         bh = MathMax(bh, bid); bl = MathMin(bl, bid); bc = bid; bvol++;
        }
     }
   if(curMin >= 0 && nB < maxBars)
     {
      bars[nB].time = (datetime)(curMin * 60);
      bars[nB].open = bo; bars[nB].high = bh; bars[nB].low = bl; bars[nB].close = bc;
      bars[nB].tick_volume = bvol; bars[nB].spread = 0; bars[nB].real_volume = 0;
      nB++;
     }
   if(nT == 0 || nB == 0) { Print("Tick rebuild: nothing produced (legs may not overlap yet)."); return false; }
   ArrayResize(oticks, nT);
   ArrayResize(bars, nB);

   if(InpStoreTicks)
     {
      int rt = CustomTicksReplace(g_name, oticks[0].time_msc, oticks[nT - 1].time_msc, oticks);
      if(rt < 0) Print("CustomTicksReplace failed: ", GetLastError());
     }
   CustomRatesDelete(g_name, bars[0].time, TimeCurrent() + 86400);
   int ru = CustomRatesUpdate(g_name, bars);
   if(ru <= 0) { Print("CustomRatesUpdate failed: ", GetLastError()); return false; }

   g_rebuildEndMsc = oticks[nT - 1].time_msc;
   PrintFormat("Tick rebuild OK: %d ticks -> %d M1 bars from %s (last %d %s bars requested)",
               nT, nB, TimeToString(bars[0].time), InpTickBars, EnumToString(tf));
   return true;
  }

//+------------------------------------------------------------------+
//| Live tick injection                                               |
//+------------------------------------------------------------------+
void PushTick(const double bid, const double ask)
  {
   if(bid == g_lastBid && ask == g_lastAsk) return;
   long maxMsc = 0;
   for(int i = 0; i < g_n; i++)
      maxMsc = MathMax(maxMsc, SymbolInfoInteger(g_sym[i], SYMBOL_TIME_MSC));
   if(maxMsc <= g_lastMsc) maxMsc = g_lastMsc + 1;

   MqlTick tk[1];
   tk[0].time        = (datetime)(maxMsc / 1000);
   tk[0].time_msc    = maxMsc;
   tk[0].bid         = NormalizeDouble(bid, g_digits);
   tk[0].ask         = NormalizeDouble(ask, g_digits);
   tk[0].last        = 0;
   tk[0].volume      = 0;
   tk[0].volume_real = 0;
   tk[0].flags       = TICK_FLAG_BID | TICK_FLAG_ASK;
   if(CustomTicksAdd(g_name, tk) > 0)
     { g_lastBid = bid; g_lastAsk = ask; g_lastMsc = maxMsc; }
  }

//+------------------------------------------------------------------+
//| Runtime settings persistence                                      |
//+------------------------------------------------------------------+
string RtKey(const string f) { return "USDXEA|rt|" + IntegerToString((long)InpMagic) + "|" + f; }

void SaveRuntime()
  {
   GlobalVariableSet(RtKey("lots"), g_lots);
   GlobalVariableSet(RtKey("tp"),   g_tp);
   GlobalVariableSet(RtKey("sl"),   g_sl);
  }

void InitRuntime(const bool chartChange)
  {
   g_lots = InpLots; g_tp = InpTPIndex; g_sl = InpSLIndex;
   ScanBasket();
   if((chartChange || g_basketOpen) && GlobalVariableCheck(RtKey("lots")))
     {
      g_lots = GlobalVariableGet(RtKey("lots"));
      g_tp   = GlobalVariableGet(RtKey("tp"));
      g_sl   = GlobalVariableGet(RtKey("sl"));
     }
   SaveRuntime();
  }

//+------------------------------------------------------------------+
//| Basket                                                            |
//+------------------------------------------------------------------+
int LegIndex(const string s)
  {
   for(int i = 0; i < g_n; i++) if(g_sym[i] == s) return i;
   return -1;
  }

void ScanBasket()
  {
   g_basketOpen = false; g_complete = false; g_dir = 0; g_legs = 0;
   g_entry = 0; g_profit = 0;
   double opv[MAXLEG], opw[MAXLEG];
   ArrayInitialize(opv, 0); ArrayInitialize(opw, 0);
   ArrayInitialize(g_legVol, 0); ArrayInitialize(g_legProfit, 0); ArrayInitialize(g_legSide, 0);

   for(int p = PositionsTotal() - 1; p >= 0; p--)
     {
      ulong tk = PositionGetTicket(p);
      if(tk == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)InpMagic) continue;
      int i = LegIndex(PositionGetString(POSITION_SYMBOL));
      if(i < 0) continue;
      double v = PositionGetDouble(POSITION_VOLUME);
      int side = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) ? 1 : -1;
      opv[i] += v * PositionGetDouble(POSITION_PRICE_OPEN);
      opw[i] += v;
      g_legVol[i]    += v;
      g_legSide[i]    = side;
      g_legProfit[i] += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      g_dir = side * (g_w[i] > 0 ? 1 : -1);
     }
   double op[MAXLEG];
   for(int i = 0; i < g_n; i++)
     {
      if(opw[i] > 0) { op[i] = opv[i] / opw[i]; g_legs++; g_profit += g_legProfit[i]; }
      else op[i] = 0;
     }
   if(g_legs > 0)
     {
      g_basketOpen = true;
      g_complete = (g_legs == g_n);
      if(g_complete) g_entry = CalcIdx(op);
     }
  }

void CloseBasket(const string reason)
  {
   for(int p = PositionsTotal() - 1; p >= 0; p--)
     {
      ulong tk = PositionGetTicket(p);
      if(tk == 0) continue;
      if(PositionGetInteger(POSITION_MAGIC) != (long)InpMagic) continue;
      string s = PositionGetString(POSITION_SYMBOL);
      if(LegIndex(s) < 0) continue;
      g_trade.SetDeviationInPoints(InpDeviation);
      if(!g_trade.PositionClose(tk))
         PrintFormat("Close %s failed: %d", s, g_trade.ResultRetcode());
     }
   Print(g_title, " basket close requested: ", reason);
  }

// Volume for leg i at basket size 'lots'.
//  rawOut : ideal (unrounded) volume
//  bumped : true if the ideal size is below the minimum lot and was rounded UP to the minimum
// Geometric: leg exposure = |w| * lots * InpBasketUnit (account ccy), sized via tick value.
// Linear:    volume = |w| * lots (weights are lot ratios).
double LegVolume(const int i, const double lots, double &errPct, double &rawOut, bool &bumped)
  {
   string s = g_sym[i];
   bumped = false; errPct = 999; rawOut = 0;
   double step = SymbolInfoDouble(s, SYMBOL_VOLUME_STEP);
   double vmin = SymbolInfoDouble(s, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(s, SYMBOL_VOLUME_MAX);
   if(step <= 0) return 0;

   double raw;
   if(g_mode == FORMULA_LINEAR)
      raw = MathAbs(g_w[i]) * lots;
   else
     {
      double px = SymbolInfoDouble(s, SYMBOL_BID);
      double tv = SymbolInfoDouble(s, SYMBOL_TRADE_TICK_VALUE);
      double ts = SymbolInfoDouble(s, SYMBOL_TRADE_TICK_SIZE);
      if(px <= 0 || tv <= 0 || ts <= 0) return 0;
      double notionalPerLot = px * tv / ts;               // account ccy per 1.0 lot
      raw = MathAbs(g_w[i]) * lots * InpBasketUnit / notionalPerLot;
     }
   rawOut = raw;
   double v = MathFloor(raw / step + 0.5) * step;
   if(v < vmin) { bumped = true; v = vmin; }               // too small -> smallest allowed amount
   v = MathMin(vmax, v);
   v = NormalizeDouble(v, 8);
   errPct = (raw > 0) ? MathAbs(v - raw) / raw * 100.0 : 999;
   return v;
  }

bool MarginOK(const int dir, const double &vol[])
  {
   double need = 0;
   for(int i = 0; i < g_n; i++)
     {
      ENUM_ORDER_TYPE ot = (dir * g_w[i] > 0) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double px = SymbolInfoDouble(g_sym[i], ot == ORDER_TYPE_BUY ? SYMBOL_ASK : SYMBOL_BID);
      double m = 0;
      if(px <= 0 || !OrderCalcMargin(ot, g_sym[i], vol[i], px, m)) return false;
      need += m;
     }
   return (need <= AccountInfoDouble(ACCOUNT_MARGIN_FREE) * 0.95);
  }

bool OpenBasket(const int dir, const bool silentAuto = false)
  {
   bool silent = silentAuto || g_tester;
   ScanBasket();
   if(g_basketOpen) { Print("A basket is already open for magic ", InpMagic); return false; }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
     { Alert(EA_NAME, ": algo trading is not allowed."); return false; }

   double vol[MAXLEG];
   string summary = "";
   bool warn = false;
   for(int i = 0; i < g_n; i++)
     {
      if(SymbolInfoInteger(g_sym[i], SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL)
        { Alert(EA_NAME, ": trading not allowed on ", g_sym[i]); return false; }
      double err, raw; bool bumped;
      vol[i] = LegVolume(i, g_lots, err, raw, bumped);
      if(vol[i] <= 0) { Alert(EA_NAME, ": cannot size leg ", g_sym[i], " (no quote / tick value)."); return false; }
      bool flag = (bumped || err > InpWarnLegError);
      if(flag) warn = true;
      bool buy = (dir * g_w[i] > 0);
      double dev = (raw > 0) ? (vol[i] - raw) / raw * 100.0 : 0;
      summary += StringFormat("%s %s  %.2f lots   (ideal %.4f, %+.0f%%)%s\n",
                              buy ? "BUY " : "SELL", g_sym[i], vol[i], raw, dev,
                              bumped ? "  <- minimum lot" : "");
     }

   if(!MarginOK(dir, vol))
     {
      if(silent) Print(g_title, ": not enough free margin for the basket - skipped.");
      else Alert(EA_NAME, ": not enough free margin for this basket size.");
      return false;
     }
   if(warn && silent && !g_tester)
     { Print(g_title, ": auto-trade skipped - a leg is below the minimum lot at this size."); return false; }

   if(!silent && (warn || InpConfirm))
     {
      string head = "";
      if(warn)
         head = "Some legs are below the minimum lot (or rounded heavily).\n"
                "They will be rounded to the smallest allowed size, so the basket\n"
                "will NOT match the target weights exactly.\n\n";
      string title = (dir > 0 ? "BUY " : "SELL ") + g_title + "?";
      int r = MessageBox(head + summary + "\nPlace this basket?", title,
                         MB_YESNO | (warn ? MB_ICONWARNING : MB_ICONQUESTION));
      if(r != IDYES) return false;
     }

   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetDeviationInPoints(InpDeviation);
   for(int i = 0; i < g_n; i++)
     {
      g_trade.SetTypeFillingBySymbol(g_sym[i]);
      bool buy = (dir * g_w[i] > 0);
      bool ok = buy ? g_trade.Buy(vol[i], g_sym[i], 0, 0, 0, g_title)
                    : g_trade.Sell(vol[i], g_sym[i], 0, 0, 0, g_title);
      uint rc = g_trade.ResultRetcode();
      if(!ok || (rc != TRADE_RETCODE_DONE && rc != TRADE_RETCODE_DONE_PARTIAL))
        {
         PrintFormat("%s leg %s failed rc=%u. Rolling back.", g_title, g_sym[i], rc);
         Alert(EA_NAME, ": leg ", g_sym[i], " failed - rolling back basket.");
         CloseBasket("rollback");
         return false;
        }
     }
   ScanBasket();
   Print(g_title, " ", dir > 0 ? "LONG" : "SHORT", " basket opened. Entry = ", Fmt(g_entry));
   return true;
  }

// Virtual TP/SL evaluated on the synthetic index. 0 = disabled.
void ManageBasket(const double bid, const double ask)
  {
   ScanBasket();
   if(!g_basketOpen || !g_complete) return;
   double pl = (g_dir > 0) ? (bid - g_entry) : (g_entry - ask);
   if(g_tp > 0 && pl >= g_tp)       CloseBasket("virtual TP");
   else if(g_sl > 0 && pl <= -g_sl) CloseBasket("virtual SL");
  }

//+------------------------------------------------------------------+
//| GUI                                                               |
//+------------------------------------------------------------------+
const color C_BG     = C'24,27,36';
const color C_BORDER = C'70,78,96';
const color C_TEXT   = C'220,224,232';
const color C_DIM    = C'140,148,165';
const color C_UP     = C'80,200,120';
const color C_DOWN   = C'235,95,95';
const color C_WARN   = C'240,185,70';
const color C_FIELD  = C'40,45,58';
const color C_BTN    = C'55,62,80';

void P_Rect(const string n, const int x, const int y, const int w, const int h)
  {
   ObjectCreate(0, n, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, C_BG);
   ObjectSetInteger(0, n, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, n, OBJPROP_COLOR, C_BORDER);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
  }

void P_Label(const string n, const int x, const int y, const string txt, const color c, const int fs = 9)
  {
   ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_COLOR, c);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, fs);
   ObjectSetString(0, n, OBJPROP_FONT, "Consolas");
   ObjectSetString(0, n, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
  }

void P_Button(const string n, const int x, const int y, const int w, const int h,
              const string txt, const color bg)
  {
   ObjectCreate(0, n, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, n, OBJPROP_BORDER_COLOR, C_BORDER);
   ObjectSetInteger(0, n, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, n, OBJPROP_FONT, "Segoe UI");
   ObjectSetString(0, n, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
  }

void P_Edit(const string n, const int x, const int y, const int w, const int h, const string txt)
  {
   ObjectCreate(0, n, OBJ_EDIT, 0, 0, 0);
   ObjectSetInteger(0, n, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, n, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, n, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, n, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, n, OBJPROP_BGCOLOR, C_FIELD);
   ObjectSetInteger(0, n, OBJPROP_BORDER_COLOR, C_BORDER);
   ObjectSetInteger(0, n, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, n, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(0, n, OBJPROP_READONLY, false);
   ObjectSetInteger(0, n, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, n, OBJPROP_FONT, "Consolas");
   ObjectSetString(0, n, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
  }

void SetT(const string n, const string txt, const color c)
  {
   if(ObjectFind(0, n) < 0) return;
   if(ObjectGetString(0, n, OBJPROP_TEXT) != txt) ObjectSetString(0, n, OBJPROP_TEXT, txt);
   if((color)ObjectGetInteger(0, n, OBJPROP_COLOR) != c) ObjectSetInteger(0, n, OBJPROP_COLOR, c);
  }

void RefreshEdits()
  {
   int d = MathMax(2, g_digits);
   if(ObjectFind(0, PP + "lots") >= 0) ObjectSetString(0, PP + "lots", OBJPROP_TEXT, DoubleToString(g_lots, 2));
   if(ObjectFind(0, PP + "tp") >= 0)   ObjectSetString(0, PP + "tp",   OBJPROP_TEXT, DoubleToString(g_tp, d));
   if(ObjectFind(0, PP + "sl") >= 0)   ObjectSetString(0, PP + "sl",   OBJPROP_TEXT, DoubleToString(g_sl, d));
  }

void CreatePanel()
  {
   ObjectsDeleteAll(0, PP);
   if(!InpShowPanel) return;
   const int PW = 300;
   int x = InpPanelX, y = InpPanelY;

   int H = g_collapsed ? 54 : (306 + g_n * 15);
   P_Rect(PP + "bg", x, y, PW, H);
   P_Label(PP + "title", x + 10, y + 7, EA_NAME + " v" + EA_VERSION + "  [" + g_title + "]", C_TEXT, 9);
   P_Button(PP + "min", x + PW - 28, y + 5, 20, 18, g_collapsed ? "+" : "-", C_BTN);
   P_Label(PP + "idx", x + 10, y + 28, "", C_TEXT, 12);
   if(g_collapsed) { ChartRedraw(); return; }

   P_Label(PP + "sub", x + 10, y + 50, "", C_DIM, 8);

   int ry = y + 76;
   P_Label(PP + "l_size", x + 10, ry + 4, "Size", C_DIM);
   P_Button(PP + "lm", x + 52, ry, 24, 22, "-", C_BTN);
   P_Edit(PP + "lots", x + 80, ry, 64, 22, "");
   P_Button(PP + "lp", x + 148, ry, 24, 22, "+", C_BTN);
   P_Label(PP + "unit", x + 180, ry + 4, "", C_DIM, 8);

   ry += 30;
   P_Label(PP + "l_tp", x + 10, ry + 4, "TP", C_DIM);
   P_Edit(PP + "tp", x + 34, ry, 66, 22, "");
   P_Label(PP + "l_sl", x + 112, ry + 4, "SL", C_DIM);
   P_Edit(PP + "sl", x + 136, ry, 66, 22, "");
   P_Label(PP + "l_pt", x + 208, ry + 4, "pts, 0 = off", C_DIM, 8);

   ry += 32;
   P_Button(PP + "buy",  x + 10,  ry, 136, 30, "BUY " + g_title,  C'30,130,76');
   P_Button(PP + "sell", x + 154, ry, 136, 30, "SELL " + g_title, C'176,58,58');
   ry += 36;
   P_Button(PP + "close", x + 10, ry, 280, 24, "CLOSE BASKET", C_BTN);

   ry += 32;
   P_Label(PP + "st1", x + 10, ry, "", C_TEXT, 9);
   P_Label(PP + "st2", x + 10, ry + 17, "", C_TEXT, 9);
   P_Label(PP + "lv1", x + 10, ry + 34, "", C_TEXT, 9);
   P_Label(PP + "lv2", x + 10, ry + 51, "", C_TEXT, 9);

   ry += 76;
   P_Label(PP + "hdr", x + 10, ry, "", C_DIM, 8);
   ry += 16;
   for(int i = 0; i < g_n; i++)
      P_Label(PP + "leg" + IntegerToString(i), x + 10, ry + i * 15, "", C_TEXT, 9);

   RefreshEdits();
   ChartRedraw();
  }

void SetLine(const string n, const double price, const color clr, const ENUM_LINE_STYLE st,
             const int width, const string txt)
  {
   if(ObjectFind(0, n) < 0) ObjectCreate(0, n, OBJ_HLINE, 0, 0, price);
   ObjectSetDouble(0, n, OBJPROP_PRICE, price);
   ObjectSetInteger(0, n, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, n, OBJPROP_STYLE, st);
   ObjectSetInteger(0, n, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, n, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, n, OBJPROP_BACK, true);
   ObjectSetString(0, n, OBJPROP_TEXT, txt);        // shown next to the line (CHART_SHOW_OBJECT_DESCR)
   ObjectSetString(0, n, OBJPROP_TOOLTIP, txt);
  }

void DelLines(const string &names[])
  {
   for(int i = 0; i < ArraySize(names); i++) ObjectDelete(0, names[i]);
  }

// TP/SL lines: projected (before entry) and live (after entry)
void UpdateLevels(const double bid, const double ask)
  {
   string liveN[3]    = {PFX + "L_entry", PFX + "L_tp", PFX + "L_sl"};
   string previewN[4] = {PFX + "L_btp", PFX + "L_bsl", PFX + "L_stp", PFX + "L_ssl"};
   bool onChart = (_Symbol == g_name);

   if(g_basketOpen && g_complete && onChart)
     {
      DelLines(previewN);
      SetLine(liveN[0], g_entry, clrSilver, STYLE_DOT, 1,
              (g_dir > 0 ? "LONG entry " : "SHORT entry ") + Fmt(g_entry));
      if(g_tp > 0)
        {
         double lv = (g_dir > 0) ? g_entry + g_tp : g_entry - g_tp;
         SetLine(liveN[1], lv, clrLimeGreen, STYLE_SOLID, 2, "TP " + Fmt(lv) + "  (" + FmtS(lv - g_entry) + ")");
        }
      else ObjectDelete(0, liveN[1]);
      if(g_sl > 0)
        {
         double lv = (g_dir > 0) ? g_entry - g_sl : g_entry + g_sl;
         SetLine(liveN[2], lv, clrTomato, STYLE_SOLID, 2, "SL " + Fmt(lv) + "  (" + FmtS(lv - g_entry) + ")");
        }
      else ObjectDelete(0, liveN[2]);
     }
   else if(!g_basketOpen && onChart && InpShowPreview)
     {
      DelLines(liveN);
      // BUY enters at ask, SELL at bid
      if(g_tp > 0)
        {
         SetLine(previewN[0], ask + g_tp, clrLimeGreen, STYLE_DOT, 1, "BUY TP " + Fmt(ask + g_tp));
         SetLine(previewN[2], bid - g_tp, clrSeaGreen,  STYLE_DOT, 1, "SELL TP " + Fmt(bid - g_tp));
        }
      else { ObjectDelete(0, previewN[0]); ObjectDelete(0, previewN[2]); }
      if(g_sl > 0)
        {
         SetLine(previewN[1], ask - g_sl, clrTomato,    STYLE_DOT, 1, "BUY SL " + Fmt(ask - g_sl));
         SetLine(previewN[3], bid + g_sl, clrFireBrick, STYLE_DOT, 1, "SELL SL " + Fmt(bid + g_sl));
        }
      else { ObjectDelete(0, previewN[1]); ObjectDelete(0, previewN[3]); }
     }
   else
     {
      DelLines(liveN);
      DelLines(previewN);
     }
  }

void UpdatePanel(const double bid, const double ask)
  {
   if(InpShowPanel)
     {
      color qc = (bid >= g_shownBid) ? C_UP : C_DOWN;
      g_shownBid = bid;
      SetT(PP + "idx", Fmt(bid) + " / " + Fmt(ask), qc);

      if(!g_collapsed)
        {
         SetT(PP + "sub", StringFormat("%s | %d legs | spread %s",
              (g_mode == FORMULA_GEOMETRIC ? "geometric" : "linear"), g_n, Fmt(ask - bid)), C_DIM);
         SetT(PP + "unit", (g_mode == FORMULA_GEOMETRIC) ? StringFormat("= %.0f notional", g_lots * InpBasketUnit)
                                                          : "lot ratio multiplier", C_DIM);

         if(!g_basketOpen)
           {
            SetT(PP + "st1", "FLAT - no basket open", C_DIM);
            SetT(PP + "st2", "", C_DIM);
            string b = "BUY  @" + Fmt(ask) + "  TP " + (g_tp > 0 ? Fmt(ask + g_tp) : "off") + "  SL " + (g_sl > 0 ? Fmt(ask - g_sl) : "off");
            string s = "SELL @" + Fmt(bid) + "  TP " + (g_tp > 0 ? Fmt(bid - g_tp) : "off") + "  SL " + (g_sl > 0 ? Fmt(bid + g_sl) : "off");
            SetT(PP + "lv1", b, C_DIM);
            SetT(PP + "lv2", s, C_DIM);
            SetT(PP + "hdr", "PLAN (BUY side)    Lots    Err", C_DIM);
            for(int i = 0; i < g_n; i++)
              {
               double err, raw; bool bumped;
               double v = LegVolume(i, g_lots, err, raw, bumped);
               bool buy = (g_w[i] > 0);
               SetT(PP + "leg" + IntegerToString(i),
                    StringFormat("%-4s %-10s %6.2f %6.1f%%%s", buy ? "BUY" : "SELL", g_sym[i], v, err, bumped ? " MIN" : ""),
                    (bumped || err > InpWarnLegError) ? C_WARN : C_TEXT);
              }
           }
         else
           {
            if(!g_complete)
              {
               SetT(PP + "st1", StringFormat("WARNING %d/%d legs open - TP/SL paused", g_legs, g_n), C_DOWN);
               SetT(PP + "st2", StringFormat("Float P/L: %.2f", g_profit), (g_profit >= 0) ? C_UP : C_DOWN);
               SetT(PP + "lv1", "", C_DIM);
               SetT(PP + "lv2", "Use CLOSE BASKET", C_DIM);
              }
            else
              {
               double pl = (g_dir > 0) ? (bid - g_entry) : (g_entry - ask);
               SetT(PP + "st1", (g_dir > 0 ? "LONG" : "SHORT") + "  entry " + Fmt(g_entry), g_dir > 0 ? C_UP : C_DOWN);
               SetT(PP + "st2", "P/L " + FmtS(pl) + " idx | " + StringFormat("%+.2f", g_profit), (g_profit >= 0) ? C_UP : C_DOWN);
               double tpL = (g_dir > 0) ? g_entry + g_tp : g_entry - g_tp;
               double slL = (g_dir > 0) ? g_entry - g_sl : g_entry + g_sl;
               SetT(PP + "lv1", (g_tp > 0) ? "TP " + Fmt(tpL) + "  (" + FmtS(tpL - g_entry) + ")" : "No TP", (g_tp > 0) ? C_UP : C_DIM);
               SetT(PP + "lv2", (g_sl > 0) ? "SL " + Fmt(slL) + "  (" + FmtS(slL - g_entry) + ")" : "No SL", (g_sl > 0) ? C_DOWN : C_DIM);
              }
            SetT(PP + "hdr", "OPEN LEGS          Lots     P/L", C_DIM);
            for(int i = 0; i < g_n; i++)
              {
               string side = (g_legSide[i] > 0) ? "BUY" : (g_legSide[i] < 0 ? "SELL" : "--");
               SetT(PP + "leg" + IntegerToString(i),
                    StringFormat("%-4s %-10s %6.2f %8.2f", side, g_sym[i], g_legVol[i], g_legProfit[i]),
                    (g_legProfit[i] >= 0) ? C_UP : C_DOWN);
              }
           }
        }
     }
   UpdateLevels(bid, ask);
   ChartRedraw();
  }

//+------------------------------------------------------------------+
//| Remember / restore the chart's original symbol                    |
//+------------------------------------------------------------------+
string OrigKey() { return "USDXEA|orig|" + IntegerToString(ChartID()) + "|"; }

void RestoreOriginalSymbol()
  {
   string key = OrigKey();
   for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
     {
      string n = GlobalVariableName(i);
      if(StringFind(n, key) == 0)
        {
         string orig = StringSubstr(n, StringLen(key));
         GlobalVariableDel(n);
         if(_Symbol == g_name && SymbolSelect(orig, true))
            ChartSetSymbolPeriod(0, orig, PERIOD_CURRENT);
         return;
        }
     }
  }

//+------------------------------------------------------------------+
//| Optional auto-trade: EMA cross on the synthetic index bars        |
//+------------------------------------------------------------------+
void AutoBarClose(const double c)
  {
   int fp = MathMax(2, InpFastEMA), sp = MathMax(fp + 1, InpSlowEMA);
   g_barCount++;
   if(g_barCount == 1) { g_emaF = c; g_emaS = c; }
   else
     {
      g_emaF += 2.0 / (fp + 1) * (c - g_emaF);
      g_emaS += 2.0 / (sp + 1) * (c - g_emaS);
     }
   int sgn = (g_emaF > g_emaS) ? 1 : ((g_emaF < g_emaS) ? -1 : 0);
   if(g_barCount == sp + 1 && sgn != 0)
      g_signal = sgn;                                              // first position after warm-up
   else if(g_barCount > sp && g_prevSign != 0 && sgn != 0 && sgn != g_prevSign)
      g_signal = sgn;                                              // crossover
   if(sgn != 0) g_prevSign = sgn;
  }

void AutoStep(const double bid)
  {
   bool on = (InpAutoMode == AUTO_ALWAYS) || (InpAutoMode == AUTO_TESTER && g_tester);
   if(!on) return;
   long b = (long)TimeCurrent() / g_autoSec;
   if(g_barId == 0) { g_barId = b; g_barClose = bid; return; }
   if(b != g_barId) { AutoBarClose(g_barClose); g_barId = b; }
   g_barClose = bid;
   if(g_signal == 0) return;

   ScanBasket();
   if(g_basketOpen)
     {
      if(g_complete && g_dir == g_signal) g_signal = 0;
      else CloseBasket("auto reverse");
      return;
     }
   OpenBasket(g_signal, true);
   g_signal = 0;
  }

// Strategy Tester: no custom symbols / panel clicks - index is computed virtually
void StepTester()
  {
   datetime now = TimeCurrent();
   if(g_lastStep != 0 && now - g_lastStep < MathMax(1, InpTesterStepSec)) return;
   g_lastStep = now;
   double bid, ask;
   if(!GetQuote(bid, ask))
     {
      // legs that never receive quotes in the tester are dropped so the test can still run
      if(!g_adapted && ++g_noQuoteSteps >= 300)
        {
         for(int i = 0; i < g_n; i++)
            if(SymbolInfoDouble(g_sym[i], SYMBOL_BID) <= 0 || SymbolInfoDouble(g_sym[i], SYMBOL_ASK) <= 0)
              { Print("Tester: no quotes for ", g_sym[i], " - leg dropped."); g_sym[i] = ""; }
         AdaptLegsForTester();
         g_adapted = true;
         g_barId = 0; g_barCount = 0; g_prevSign = 0; g_signal = 0;
        }
      return;
     }
   g_noQuoteSteps = 0;
   ManageBasket(bid, ask);
   AutoStep(bid);
   if(g_visual) UpdatePanel(bid, ask);
  }

//+------------------------------------------------------------------+
//| Expert events                                                     |
//+------------------------------------------------------------------+
int OnInit()
  {
   g_tester = (bool)MQLInfoInteger(MQL_TESTER);
   g_visual = (bool)MQLInfoInteger(MQL_VISUAL_MODE);
   PrintFormat("%s v%s OnInit: tester=%s visual=%s preset=%s", EA_NAME, EA_VERSION,
               g_tester ? "yes" : "no", g_visual ? "yes" : "no", EnumToString(InpPreset));
   if(!SetupDefinition()) { Print("INIT_FAILED: invalid instrument definition (check the custom spec)."); return INIT_FAILED; }
   if(!ResolveSymbols())  { Print("INIT_FAILED: leg symbols not found in Market Watch."); return INIT_FAILED; }
   g_autoSec = MathMax(60, PeriodSeconds(InpAutoTF));

   if(g_tester)   // no custom symbols, no symbol switching, no timer in the tester
     {
      g_trade.SetExpertMagicNumber(InpMagic);
      g_trade.SetDeviationInPoints(InpDeviation);
      InitRuntime(false);
      if(g_visual) CreatePanel();
      Print("Tester mode: virtual index from ", g_n, " leg(s); auto-trade ",
            (InpAutoMode == AUTO_OFF ? "OFF" : "ON"));
      return INIT_SUCCEEDED;
     }

   bool chartChange = (UninitializeReason() == REASON_CHARTCHANGE);
   if(!chartChange)
     {
      if(!PrepareCustomSymbol()) { Print("INIT_FAILED: custom symbol could not be prepared."); return INIT_FAILED; }
      WaitForSync(20);                                    // let the legs' history load first
      string sigKey = "USDXEA|sig|" + g_name;
      bool sameDef = GlobalVariableCheck(sigKey) && (GlobalVariableGet(sigKey) == DefSig());
      if(!sameDef || !HistoryExists())
        {
         if(!BuildHistory()) { Print("INIT_FAILED: no M1 history for one or more legs."); return INIT_FAILED; }
         GlobalVariableSet(sigKey, DefSig());
        }
      else
        {
         // restart: keep the stored history and only fill what is missing
         MqlRates lr[];
         datetime lastBar = (CopyRates(g_name, PERIOD_M1, 0, 1, lr) > 0) ? lr[0].time : 0;
         g_gapFrom = (lastBar > 0) ? lastBar - 600 : 0;
         int nf = HealGap();
         PrintFormat("Restart: kept existing history, filled %d missing bars.", nf);
        }
      if(!RebuildFromTicks())
         Print("Tick rebuild skipped/failed - keeping M1-OHLC approximated bars.");
     }
   g_nextHeal = TimeCurrent() + 20;
   g_lastMsc = MathMax(SymbolInfoInteger(g_name, SYMBOL_TIME_MSC), g_rebuildEndMsc);

   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetDeviationInPoints(InpDeviation);

   ChartSetInteger(0, CHART_SHOW_OBJECT_DESCR, true);   // show TP/SL text next to the lines
   InitRuntime(chartChange);
   CreatePanel();
   EventSetMillisecondTimer(MathMax(50, InpUpdateMs));

   if(!chartChange && _Symbol != g_name)
     {
      GlobalVariableSet(OrigKey() + _Symbol, 1);
      ChartSetSymbolPeriod(0, g_name, PERIOD_CURRENT);   // EA reloads on the new symbol
     }
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   ObjectsDeleteAll(0, PFX);
   if(reason == REASON_REMOVE && !g_tester) RestoreOriginalSymbol();
  }

void OnTimer()
  {
   double bid, ask;
   if(!GetQuote(bid, ask)) return;
   PushTick(bid, ask);
   if(TimeCurrent() >= g_nextHeal)
     {
      HealGap();
      g_nextHeal = TimeCurrent() + ((g_gapFrom != 0) ? 30 : 900);   // retry fast until the gap is closed
     }
   ManageBasket(bid, ask);
   AutoStep(bid);
   UpdatePanel(bid, ask);
  }

void OnTick() { if(g_tester) StepTester(); }

void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_OBJECT_ENDEDIT)
     {
      double v = StringToDouble(ObjectGetString(0, sparam, OBJPROP_TEXT));
      if(sparam == PP + "lots")      { if(v > 0 && v <= 10000) g_lots = v; }
      else if(sparam == PP + "tp")   { if(v >= 0) g_tp = v; }     // 0 = no TP
      else if(sparam == PP + "sl")   { if(v >= 0) g_sl = v; }     // 0 = no SL
      else return;
      SaveRuntime();
      RefreshEdits();
      return;
     }

   if(id != CHARTEVENT_OBJECT_CLICK) return;

   if(sparam == PP + "buy")         OpenBasket(+1);
   else if(sparam == PP + "sell")   OpenBasket(-1);
   else if(sparam == PP + "close")  CloseBasket("manual");
   else if(sparam == PP + "lp")   { g_lots = NormalizeDouble(g_lots + InpLotStep, 2); SaveRuntime(); RefreshEdits(); }
   else if(sparam == PP + "lm")   { g_lots = NormalizeDouble(MathMax(0.01, g_lots - InpLotStep), 2); SaveRuntime(); RefreshEdits(); }
   else if(sparam == PP + "min")  { g_collapsed = !g_collapsed; CreatePanel(); return; }
   else return;

   ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
   ChartRedraw();
  }
//+------------------------------------------------------------------+

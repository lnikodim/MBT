//+------------------------------------------------------------------+
//|                                                 SFX_Algo_EA.mq5 |
//|  Supertrend flip strategy with four partial take-profits,       |
//|  ported from the TradingView strategy "Flux Charts - SFX Algo   |
//|  [2.2.1]" (Pine v6). Only the trading logic is ported:          |
//|   - entry: close crosses the Supertrend line (ATR period 15,    |
//|     band x5, source hl2, Wilder ATR as in TradingView), judged  |
//|     on the closed bar, executed at the next bar's open;         |
//|   - optional sideways filter (ATR vs its average, RSI band);    |
//|   - take-profits and stop anchored to the signal bar: its close |
//|     +/- ATR(14) x (1.5, 3, 5, 9) for the targets and x6 for the |
//|     stop, or percentages of the price (2/4/6/12 and 3);         |
//|   - four partial exits of 30/30/30/10 % of the opening volume;  |
//|   - an opposite signal closes the position and reverses.        |
//|  Not ported: the 14-day display window ("backtest" in the       |
//|  script), alert JSON for Zignaly/Telegram, dashboards, drawings |
//|  and the moving-average/trendline overlays (display only).      |
//|  Differences from the script: the stop is a broker stop (the    |
//|  script checks the low at bar close and exits at the next open);|
//|  lots come from the risk per trade and the stop distance (the   |
//|  script trades a fixed 10,000 notional); partial exits are      |
//|  market orders sent when the quote reaches the level (limit     |
//|  orders in the script); a tranche below the minimum lot is      |
//|  merged into the next level. Execution, guards and the trade    |
//|  log come from EACore.mqh.                                       |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.00"
#property strict
#property description "Supertrend flip with ATR targets: four partial take-profits, ATR stop, reverse on the opposite signal (port of a TradingView strategy)"

#define EA_NAME    "SFX_Algo_EA"
#define EA_VERSION "1.00"
#define EA_MAGIC   281028
#define EA_COMMENT "SFX"
#include "EACore.mqh"

enum ENUM_SFX_FILTER
  {
   SFX_FILTER_ATR          = 0,  // Volatility: ATR above its average
   SFX_FILTER_RSI          = 1,  // Momentum: RSI outside the band
   SFX_FILTER_ATR_OR_RSI   = 2,  // ATR above average or RSI outside the band
   SFX_FILTER_ATR_AND_RSI  = 3,  // ATR above average and RSI outside the band
   SFX_FILTER_NONE         = 4,  // No filtering
   SFX_FILTER_SIDE_OR      = 5,  // Sideways only: ATR below avg or RSI in band
   SFX_FILTER_SIDE_AND     = 6   // Sideways only: ATR below avg and RSI in band
  };

enum ENUM_SFX_MA
  {
   SFX_MA_SMA = 0,  // Simple average
   SFX_MA_EMA = 1   // Exponential average
  };

enum ENUM_SFX_EXIT
  {
   SFX_EXIT_ATR = 0,  // ATR multiples of the signal bar
   SFX_EXIT_PCT = 1   // % of the signal bar close
  };

//--- "5. Strategy" continues from EACore (signal timeframe)
input int            InpStPeriod     = 15;             // Supertrend: ATR period, bars
input double         InpStMult       = 5.0;            // Supertrend: band width, x ATR
input bool           InpAllowBuy     = true;           // Allow buys
input bool           InpAllowSell    = true;           // Allow sells

input group "6. Filters"
input ENUM_SFX_FILTER InpFilter      = SFX_FILTER_NONE; // Sideways filter
input int            InpRsiPeriod    = 7;              // Filter: RSI period, bars
input int            InpRsiTop       = 45;             // Filter: RSI upper limit
input int            InpRsiBot       = 10;             // Filter: RSI lower limit
input int            InpFlAtrPeriod  = 5;              // Filter: ATR period, bars
input ENUM_SFX_MA    InpFlMaType     = SFX_MA_EMA;     // Filter: ATR average type
input int            InpFlMaPeriod   = 5;              // Filter: ATR average period, bars

input group "7. Exits"
input ENUM_SFX_EXIT  InpExitMode     = SFX_EXIT_ATR;   // Targets and stop measured in
input int            InpExitAtrPeriod = 14;            // Exit ATR period, bars
input double         InpTp1Atr       = 1.5;            // Take profit 1, x ATR
input double         InpTp2Atr       = 3.0;            // Take profit 2, x ATR
input double         InpTp3Atr       = 5.0;            // Take profit 3, x ATR
input double         InpTp4Atr       = 9.0;            // Take profit 4, x ATR
input double         InpSlAtr        = 6.0;            // Stop loss, x ATR
input double         InpTp1Pct       = 2.0;            // Take profit 1, % of price
input double         InpTp2Pct       = 4.0;            // Take profit 2, % of price
input double         InpTp3Pct       = 6.0;            // Take profit 3, % of price
input double         InpTp4Pct       = 12.0;           // Take profit 4, % of price
input double         InpSlPct        = 3.0;            // Stop loss, % of price
input int            InpTp1Share     = 30;             // Take profit 1: close, % of volume (0 = off)
input int            InpTp2Share     = 30;             // Take profit 2: close, % of volume (0 = off)
input int            InpTp3Share     = 30;             // Take profit 3: close, % of volume (0 = off)
input int            InpTp4Share     = 10;             // Take profit 4: close, % of volume (0 = off)

#define SFX_WARMUP 1000       // closed bars replayed at start so the Supertrend, ATR and RSI have settled

//--- running Wilder average (TradingView rma): the first value is the mean of the first len inputs
struct Rma
  {
   int    len;
   int    n;
   double sum;
   double v;
   bool   ready;
  };

void RmaInit(Rma &r, const int len)
  {
   r.len = len;
   r.n = 0;
   r.sum = 0.0;
   r.v = 0.0;
   r.ready = false;
  }

void RmaAdd(Rma &r, const double x)
  {
   if(r.ready)
     {
      r.v = (r.v * (r.len - 1) + x) / r.len;
      return;
     }
   r.sum += x;
   if(++r.n >= r.len)
     {
      r.v = r.sum / r.len;
      r.ready = true;
     }
  }

//--- what the last processed closed bar says
struct SfxSignal
  {
   datetime time;
   bool     ready;
   bool     buy;
   bool     sell;
   bool     filterOk;
   double   close;
   double   atrExit;
  };

Rma       g_atrSt, g_atrEx, g_atrFl, g_gain, g_loss;
double    g_flRing[];             // last InpFlMaPeriod values of the filter ATR (simple average)
int       g_flPos = 0;
int       g_flCount = 0;
double    g_flSum = 0.0;
double    g_flEma = 0.0;
bool      g_flEmaReady = false;
int       g_bars = 0;             // closed bars processed
double    g_prevClose = 0.0;
bool      g_haveSt = false;
double    g_up = 0.0, g_dn = 0.0, g_st = 0.0;
int       g_trend = 1;
datetime  g_procTime = 0;         // open time of the newest processed bar
SfxSignal g_sig;

//--- the open position's targets (signal-bar levels), kept in terminal globals to survive a restart
ulong     g_posId = 0;
bool      g_managed = false;
double    g_initVol = 0.0;
double    g_tp[4];
bool      g_hit[4];
int       g_sigType = -1;         // signal waiting for its position to appear (the spread guard may delay the entry)
datetime  g_sigBar = 0;
double    g_sigTP[4];
datetime  g_nextTry = 0;          // after a failed partial close, no new attempt before this time
string    g_gvPrefix = "";

void SfxReset()
  {
   RmaInit(g_atrSt, InpStPeriod);
   RmaInit(g_atrEx, InpExitAtrPeriod);
   RmaInit(g_atrFl, InpFlAtrPeriod);
   RmaInit(g_gain, InpRsiPeriod);
   RmaInit(g_loss, InpRsiPeriod);
   ArrayResize(g_flRing, InpFlMaPeriod);
   ArrayInitialize(g_flRing, 0.0);
   g_flPos = 0;
   g_flCount = 0;
   g_flSum = 0.0;
   g_flEma = 0.0;
   g_flEmaReady = false;
   g_bars = 0;
   g_prevClose = 0.0;
   g_haveSt = false;
   g_trend = 1;
   g_procTime = 0;
   ZeroMemory(g_sig);
  }

//--- one closed bar, oldest first; the Supertrend lines and the cross tests follow the Pine script line by line
void SfxStep(const MqlRates &b)
  {
   const bool   hasPrev = g_bars > 0;
   const double pc = g_prevClose;
   const double tr = hasPrev ? MathMax(b.high - b.low, MathMax(MathAbs(b.high - pc), MathAbs(b.low - pc))) : b.high - b.low;
   RmaAdd(g_atrSt, tr);
   RmaAdd(g_atrEx, tr);
   RmaAdd(g_atrFl, tr);
   if(hasPrev)
     {
      const double ch = b.close - pc;
      RmaAdd(g_gain, MathMax(ch, 0.0));
      RmaAdd(g_loss, MathMax(-ch, 0.0));
     }
//--- average of the filter ATR
   if(g_atrFl.ready)
     {
      g_flSum += g_atrFl.v - g_flRing[g_flPos];
      g_flRing[g_flPos] = g_atrFl.v;
      g_flPos = (g_flPos + 1) % InpFlMaPeriod;
      if(g_flCount < InpFlMaPeriod)
         g_flCount++;
      const double alpha = 2.0 / (InpFlMaPeriod + 1.0);
      g_flEma = g_flEmaReady ? alpha * g_atrFl.v + (1.0 - alpha) * g_flEma : g_atrFl.v;
      g_flEmaReady = true;
     }
//--- Supertrend
   bool buy = false, sell = false;
   if(g_atrSt.ready)
     {
      const double src   = (b.high + b.low) / 2.0;
      const double upRaw = src - InpStMult * g_atrSt.v;
      const double dnRaw = src + InpStMult * g_atrSt.v;
      const double up1   = g_haveSt ? g_up : upRaw;
      const double dn1   = g_haveSt ? g_dn : dnRaw;
      const double up    = (hasPrev && pc > up1) ? MathMax(upRaw, up1) : upRaw;
      const double dn    = (hasPrev && pc < dn1) ? MathMin(dnRaw, dn1) : dnRaw;
      int trend = g_haveSt ? g_trend : 1;
      if(trend == -1 && b.close > dn1)
         trend = 1;
      else if(trend == 1 && b.close < up1)
         trend = -1;
      const double st = trend == 1 ? up : dn;
      if(g_haveSt)
        {
         buy  = pc <= g_st && b.close > st;      // ta.crossover(close, st)
         sell = pc >= g_st && b.close < st;      // ta.crossunder(close, st)
        }
      g_up = up;
      g_dn = dn;
      g_st = st;
      g_trend = trend;
      g_haveSt = true;
     }
//--- sideways filter
   bool filterOk = (InpFilter == SFX_FILTER_NONE);
   const bool flReady = g_atrFl.ready && g_flCount >= InpFlMaPeriod && g_gain.ready && g_loss.ready;
   if(flReady)
     {
      double rsi = g_loss.v == 0.0 ? 100.0 : (g_gain.v == 0.0 ? 0.0 : 100.0 - 100.0 / (1.0 + g_gain.v / g_loss.v));
      rsi = (double)((long)(rsi * 100.0)) / 100.0;                 // the script truncates the RSI to two decimals
      const double atrMa = InpFlMaType == SFX_MA_EMA ? g_flEma : g_flSum / InpFlMaPeriod;
      const bool atrUp   = g_atrFl.v >= atrMa;
      const bool rsiOut  = rsi > InpRsiTop || rsi < InpRsiBot;
      const bool atrDn   = g_atrFl.v <= atrMa;
      const bool rsiIn   = rsi < InpRsiTop && rsi > InpRsiBot;
      switch(InpFilter)
        {
         case SFX_FILTER_ATR:         filterOk = atrUp;            break;
         case SFX_FILTER_RSI:         filterOk = rsiOut;           break;
         case SFX_FILTER_ATR_OR_RSI:  filterOk = atrUp || rsiOut;  break;
         case SFX_FILTER_ATR_AND_RSI: filterOk = atrUp && rsiOut;  break;
         case SFX_FILTER_NONE:        filterOk = true;             break;
         case SFX_FILTER_SIDE_OR:     filterOk = atrDn || rsiIn;   break;
         case SFX_FILTER_SIDE_AND:    filterOk = atrDn && rsiIn;   break;
        }
     }
   g_sig.time     = b.time;
   g_sig.ready    = g_haveSt && g_atrEx.ready && (InpFilter == SFX_FILTER_NONE || flReady);
   g_sig.buy      = buy;
   g_sig.sell     = sell;
   g_sig.filterOk = filterOk;
   g_sig.close    = b.close;
   g_sig.atrExit  = g_atrEx.v;
   g_prevClose    = b.close;
   g_procTime     = b.time;
   g_bars++;
  }

//--- bring the indicator state up to the last closed bar (warm-up at start, one bar per call afterwards, more after a gap)
void SfxCatchUp()
  {
   MqlRates r[];
   const datetime last = iTime(_Symbol, InpTimeframe, 1);
   if(last == 0 || last == g_procTime)
      return;
   int n;
   if(g_procTime == 0)
      n = CopyRates(_Symbol, InpTimeframe, 1, SFX_WARMUP, r);                    // oldest first: the array is not a series
   else
      n = CopyRates(_Symbol, InpTimeframe, g_procTime + 1, last, r);
   for(int i = 0; i < n; i++)
      SfxStep(r[i]);
  }

//+------------------------------------------------------------------+
//| Take-profit management                                           |
//+------------------------------------------------------------------+
double TpShare(const int i)
  {
   switch(i)
     {
      case 0:  return(InpTp1Share);
      case 1:  return(InpTp2Share);
      case 2:  return(InpTp3Share);
     }
   return(InpTp4Share);
  }

double FloorToStep(const double lots)
  {
   const double step = g_symbol.LotsStep();
   return(NormalizeDouble(MathFloor(lots / step + 1e-9) * step, (int)MathRound(-MathLog10(step))));
  }

string GvName(const string key) { return(g_gvPrefix + key); }

void SaveTargets()
  {
   GlobalVariableSet(GvName("id"), (double)g_posId);
   GlobalVariableSet(GvName("vol"), g_initVol);
   for(int i = 0; i < 4; i++)
     {
      GlobalVariableSet(GvName("tp" + IntegerToString(i)), g_tp[i]);
      GlobalVariableSet(GvName("hit" + IntegerToString(i)), g_hit[i] ? 1.0 : 0.0);
     }
  }

void ClearTargets()
  {
   GlobalVariableDel(GvName("id"));
   GlobalVariableDel(GvName("vol"));
   for(int i = 0; i < 4; i++)
     {
      GlobalVariableDel(GvName("tp" + IntegerToString(i)));
      GlobalVariableDel(GvName("hit" + IntegerToString(i)));
     }
   g_posId = 0;
   g_managed = false;
  }

//--- a position of ours that this run does not know yet: new entry (levels from the signal) or restart (levels from the globals)
void AdoptPosition(const ulong id)
  {
   g_posId = id;
   g_managed = false;
   if(GlobalVariableCheck(GvName("id")) && (ulong)GlobalVariableGet(GvName("id")) == id)
     {
      g_initVol = GlobalVariableGet(GvName("vol"));
      for(int i = 0; i < 4; i++)
        {
         g_tp[i]  = GlobalVariableGet(GvName("tp" + IntegerToString(i)));
         g_hit[i] = GlobalVariableGet(GvName("hit" + IntegerToString(i))) > 0.5;
        }
      g_managed = true;
      PrintFormat("Position #%I64u: take-profit levels restored after a restart", id);
      return;
     }
   const int type = (int)PositionGetInteger(POSITION_TYPE);
   if(g_sigType == type && (datetime)PositionGetInteger(POSITION_TIME) >= g_sigBar)
     {
      g_initVol = PositionGetDouble(POSITION_VOLUME);
      for(int i = 0; i < 4; i++)
        {
         g_tp[i]  = g_sigTP[i];
         g_hit[i] = TpShare(i) <= 0.0;
        }
      g_sigType = -1;
      g_managed = true;
      SaveTargets();
      PrintFormat("Position #%I64u opened: volume %.2f, targets %s / %s / %s / %s", id, g_initVol,
                  DoubleToString(g_tp[0], _Digits), DoubleToString(g_tp[1], _Digits),
                  DoubleToString(g_tp[2], _Digits), DoubleToString(g_tp[3], _Digits));
      return;
     }
   PrintFormat("Position #%I64u has no saved take-profit levels: only its stop and the opposite signal manage it", id);
  }

//--- volume to close when level i is reached: its share of the opening volume (cumulative, so merged tranches add up),
//--- all of it when the shares reach 100%; 0 = too small for the broker, it joins the next level
double TrancheVolume(const int i, const double posVol)
  {
   double cum = 0.0;
   for(int j = 0; j <= i; j++)
      cum += TpShare(j);
   const double target = cum >= 100.0 ? g_initVol : FloorToStep(g_initVol * cum / 100.0);
   double vol = MathMin(target - (g_initVol - posVol), posVol);
   if(vol <= 0.0)
      return(0.0);
   const double minLot = g_symbol.LotsMin();
   if(posVol - vol > 1e-9 && posVol - vol < minLot - 1e-9)   // the remainder would be below the minimum lot: close all
      vol = posVol;
   return(vol < minLot - 1e-9 ? 0.0 : NormalizeDouble(vol, (int)MathRound(-MathLog10(g_symbol.LotsStep()))));
  }

void ManageTargets()
  {
   ulong ticket = 0;
   if(!Core_SelectOwnPosition(ticket))
     {
      if(g_posId != 0)
         ClearTargets();
      return;
     }
   const ulong id = (ulong)PositionGetInteger(POSITION_IDENTIFIER);
   if(id != g_posId)
      AdoptPosition(id);
   if(!g_managed)
      return;
   const bool buy = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
   for(int i = 0; i < 4; i++)
     {
      if(g_hit[i])
         continue;
      const double px = SymbolInfoDouble(_Symbol, buy ? SYMBOL_BID : SYMBOL_ASK);
      if(px <= 0.0 || (buy ? px < g_tp[i] : px > g_tp[i]))
         continue;
      if(!PositionSelectByTicket(ticket))
         return;
      const double posVol = PositionGetDouble(POSITION_VOLUME);
      const double vol = TrancheVolume(i, posVol);
      if(vol > 0.0)
        {
         if(TimeCurrent() < g_nextTry)
            return;
         if(!g_trade.PositionClosePartial(ticket, vol))
           {
            g_nextTry = TimeCurrent() + 60;
            PrintFormat("Take profit %d: closing %.2f lots failed: %d %s -- retrying in 60 s", i + 1, vol,
                        g_trade.ResultRetcode(), g_trade.ResultRetcodeDescription());
            return;
           }
         PrintFormat("Take profit %d reached at %s: closed %.2f of %.2f lots", i + 1, DoubleToString(px, _Digits), vol, posVol);
        }
      else
         PrintFormat("Take profit %d reached at %s: its share is below the minimum lot, merged into the next level", i + 1,
                     DoubleToString(px, _Digits));
      g_hit[i] = true;
      SaveTargets();
      if(!PositionSelectByTicket(ticket))
         return;
     }
  }

//+------------------------------------------------------------------+
//| Entries                                                          |
//+------------------------------------------------------------------+
void OpenSignal(const ENUM_POSITION_TYPE type, const datetime bar)
  {
   const bool   buy = (type == POSITION_TYPE_BUY);
   const double dir = buy ? 1.0 : -1.0;
   const double cb  = g_sig.close;
   const double atr = g_sig.atrExit;
   double sl;
   if(InpExitMode == SFX_EXIT_ATR)
     {
      g_sigTP[0] = cb + dir * atr * InpTp1Atr;
      g_sigTP[1] = cb + dir * atr * InpTp2Atr;
      g_sigTP[2] = cb + dir * atr * InpTp3Atr;
      g_sigTP[3] = cb + dir * atr * InpTp4Atr;
      sl         = cb - dir * atr * InpSlAtr;
     }
   else
     {
      g_sigTP[0] = cb * (1.0 + dir * InpTp1Pct / 100.0);
      g_sigTP[1] = cb * (1.0 + dir * InpTp2Pct / 100.0);
      g_sigTP[2] = cb * (1.0 + dir * InpTp3Pct / 100.0);
      g_sigTP[3] = cb * (1.0 + dir * InpTp4Pct / 100.0);
      sl         = cb * (1.0 - dir * InpSlPct / 100.0);
     }
   if(!g_symbol.RefreshRates())
      return;
   const double slDist = buy ? g_symbol.Ask() - sl : sl - g_symbol.Bid();
   if(slDist <= 0.0)
     {
      PrintFormat("%s signal skipped: the price is already beyond the stop level %s", buy ? "BUY" : "SELL", DoubleToString(sl, _Digits));
      return;
     }
   PrintFormat("%s signal: bar close %s, ATR %s, stop %s, targets %s / %s / %s / %s", buy ? "BUY" : "SELL",
               DoubleToString(cb, _Digits), DoubleToString(atr, _Digits), DoubleToString(sl, _Digits),
               DoubleToString(g_sigTP[0], _Digits), DoubleToString(g_sigTP[1], _Digits),
               DoubleToString(g_sigTP[2], _Digits), DoubleToString(g_sigTP[3], _Digits));
   g_sigType = (int)type;
   g_sigBar  = bar;
   Core_Open(type, slDist, 0.0);
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpStPeriod < 1 || InpStMult <= 0.0 || InpExitAtrPeriod < 1 || InpFlAtrPeriod < 1 || InpFlMaPeriod < 1 || InpRsiPeriod < 1 ||
      InpRsiBot >= InpRsiTop || InpRsiBot < 0 || InpRsiTop > 100)
     {
      Print("Invalid inputs: periods >= 1, band width > 0, RSI lower limit below the upper limit (0-100)");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpTp1Atr <= 0.0 || InpTp2Atr <= 0.0 || InpTp3Atr <= 0.0 || InpTp4Atr <= 0.0 || InpSlAtr <= 0.0 ||
      InpTp1Pct <= 0.0 || InpTp2Pct <= 0.0 || InpTp3Pct <= 0.0 || InpTp4Pct <= 0.0 || InpSlPct <= 0.0 || InpSlPct >= 100.0)
     {
      Print("Invalid inputs: take-profit and stop distances must be above 0 (stop % below 100)");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpTp1Share < 0 || InpTp2Share < 0 || InpTp3Share < 0 || InpTp4Share < 0 ||
      InpTp1Share + InpTp2Share + InpTp3Share + InpTp4Share > 100)
     {
      Print("Invalid inputs: take-profit shares must be 0 or more and add up to at most 100%");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!InpAllowBuy && !InpAllowSell)
     {
      Print("Invalid inputs: both buys and sells are switched off");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(!Core_Init())
      return(INIT_PARAMETERS_INCORRECT);
   g_gvPrefix = StringFormat("%s_%s_%I64u_", EA_NAME, _Symbol, InpMagic);
   if(MQLInfoInteger(MQL_TESTER))
      ClearTargets();                                 // position ids restart at 1 in every test: no levels from an earlier run
   SfxReset();
   SfxCatchUp();
   PrintFormat("%s v%s started on %s %s, magic %I64u, own positions: %d, %d bars replayed", EA_NAME, EA_VERSION, _Symbol,
               EnumToString(InpTimeframe), InpMagic, CountOwnPositions(), g_bars);
   PrintFormat("Inputs: Supertrend %d x %.2f | buys %s sells %s | filter %s | exits %s, ATR %d | shares %d/%d/%d/%d%% | risk %s %.2f",
               InpStPeriod, InpStMult, InpAllowBuy ? "on" : "off", InpAllowSell ? "on" : "off", EnumToString(InpFilter),
               InpExitMode == SFX_EXIT_ATR ? "ATR multiples" : "percent of price", InpExitAtrPeriod,
               InpTp1Share, InpTp2Share, InpTp3Share, InpTp4Share,
               InpRiskMode == RISK_PERCENT ? "percent" : "money", InpRiskValue);
   Core_PrintReady();
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason)
  {
   if(MQLInfoInteger(MQL_TESTER))
      ClearTargets();
   Core_Deinit(reason);
  }

void OnTick()
  {
   Core_OnTickStart();
   const datetime bar = Core_CurrentBar();
   Core_RetryPending(bar);
   ManageTargets();
   if(!Core_IsNewBar(bar))
      return;
   Core_MarkBar(bar);

   SfxCatchUp();
   if(!g_sig.ready || g_sig.time != iTime(_Symbol, InpTimeframe, 1))
     {
      Core_LogBar(bar, "indicators not ready");
      return;
     }
   Core_LogBar(bar, StringFormat("Supertrend %s | close %s | signal %s | filter %s", g_trend == 1 ? "up" : "down",
                                 DoubleToString(g_sig.close, _Digits), g_sig.buy ? "BUY" : (g_sig.sell ? "SELL" : "none"),
                                 g_sig.filterOk ? "pass" : "block"));
   if(!g_sig.buy && !g_sig.sell)
      return;

   ulong ticket = 0;
   if(Core_SelectOwnPosition(ticket))
     {
      const bool isBuy = PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY;
      if(isBuy ? g_sig.sell : g_sig.buy)              // the opposite signal closes whatever the filter and side switches say
         Core_ClosePosition(ticket, "opposite signal");
     }
   if(CountOwnPositions() > 0)                       // same direction still open, or the close is queued for retry
      return;
   if(!g_sig.filterOk)
      return;
   if(g_sig.buy && InpAllowBuy)
      OpenSignal(POSITION_TYPE_BUY, bar);
   else if(g_sig.sell && InpAllowSell)
      OpenSignal(POSITION_TYPE_SELL, bar);
  }

void OnTradeTransaction(const MqlTradeTransaction &trans, const MqlTradeRequest &request, const MqlTradeResult &result)
  {
   Core_OnTradeTransaction(trans);
  }

double OnTester() { return(Core_OnTester()); }
//+------------------------------------------------------------------+

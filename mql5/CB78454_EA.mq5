//+-------------------------------------------------------------------+
//|                                            SMC_StructureFVG_EA.mq5|
//|                                Copyright 2026, Sandro Begashvili  |
//|                   https://www.mql5.com/en/users/sandrobegashvil   |
//|                                          https://t.me/rhinoquant  |
//|                                                                   |
//| Trades fair value gaps in the direction of the market structure   |
//| produced by SmcMarketStructure.mqh - the same engine the SMC      |
//| Market Structure indicator draws.                                 |
//|                                                                   |
//| The setup, long side (short is the mirror):                       |
//|                                                                   |
//|   1. Trend is UP and the last structural break was a BoS. After a |
//|      CHoCH the EA stands down until the first BoS of the new      |
//|      trend arrives.                                               |
//|   2. The BoS marks the gaps: scan from the structure LOW rightward|
//|      and record every bullish FVG that is wide enough and sits    |
//|      below the broken level.                                      |
//|   3. The structure high is confirmed - price has taken the IDM.   |
//|   4. Price trades back into one of those gaps. That is the entry. |
//|                                                                   |
//| Stop loss is the structure low less a buffer; take profit is a    |
//| multiple of that risk. A gap trades at most once, and a new BoS   |
//| discards every gap left over from the previous leg.               |
//+-------------------------------------------------------------------+
#property copyright "Copyright 2026, Sandro Begashvili"
#property link      "https://www.mql5.com/en/users/sandrobegashvil"
#property version   "1.00"
#property description "Trades fair value gaps in the direction of SMC market structure."
#property description "BoS marks the gaps, the IDM confirms the leg, the gap is the entry."
#property description "Telegram: https://t.me/rhinoquant"

#include <Trade/Trade.mqh>
#include "SmcMarketStructure.mqh"
#include "PositionManager.mqh"

//--- how distance inputs are read
enum ENUM_DIST_UNIT
  {
   DIST_POINTS,     // Points
   DIST_PIPS        // Pips (10 points on a 3 / 5 digit symbol)
  };

//--- how the position size is decided
enum ENUM_LOT_MODE
  {
   LOT_RISK,        // Percent of balance risked on the stop
   LOT_FIXED        // Fixed lot
  };

input group             "Structure engine"
input ENUM_LOOKING_FOR  InpStartSide    = LOOK_HIGH;      // Start by looking for
input ENUM_BREAK_MODE   InpBreakMode    = BREAK_BY_WICK;  // Pullback break confirmed by
input ENUM_TOUCH_MODE   InpTouchMode    = TOUCH_BY_WICK;  // IDM taken when reference is
input bool              InpUseSweeps    = true;           // Detect liquidity sweeps
input int               InpHistoryBars  = 3000;           // Bars of history to build on

input group             "Fair value gaps"
input ENUM_DIST_UNIT    InpDistUnit     = DIST_POINTS;    // Distance inputs are in
input double            InpFvgMinSize   = 50;             // Minimum gap size (0 = any)
input bool              InpRequireIdm   = true;           // Only trade once the IDM is taken
input bool              InpFvgBelowBos  = true;           // Keep only gaps on the near side of the broken level
input bool              InpFvgLogSkips  = false;          // Log every gap candidate and why it was skipped
input bool              InpShowFvg      = true;           // Draw the gaps
input color             InpFvgBuyColor  = clrSeaGreen;    // Bullish gap colour
input color             InpFvgSellColor = clrIndianRed;   // Bearish gap colour
input color             InpFvgTextColor = clrWhite;       // Gap caption colour
input int               InpFvgTextSize  = 8;              // Gap caption size

input group             "Structure display"
input bool              InpShowStruct   = true;           // Draw the structure the EA sees
input color             InpPbLegColor   = clrGainsboro;   // Pullback zigzag
input color             InpMsLegColor   = clrGoldenrod;   // Structure zigzag
input color             InpHighColor    = clrOrangeRed;   // Structure high marker
input color             InpLowColor     = clrDodgerBlue;  // Structure low marker
input color             InpBosColor     = clrMediumSeaGreen; // BoS
input color             InpChochColor   = clrTomato;      // CHoCH
input color             InpSweepColor   = clrMediumOrchid;// Liquidity sweep
input color             InpIdmColor     = clrSteelBlue;   // IDM
input color             InpDepthColor   = clrDarkGray;    // Minimum-retracement level

input group             "Trading"
input bool              InpAllowBuy     = true;           // Allow long trades
input bool              InpAllowSell    = true;           // Allow short trades
input double            InpRiskReward   = 2.0;            // Take profit, in R
input double            InpSlBuffer     = 20;             // Stop buffer beyond the structure
input double            InpMinDepth     = 50.0;           // Minimum retracement into the leg (%, 0 = off)
input int               InpMaxPositions = 1;              // Max open positions (1 = one at a time)
input ENUM_LOT_MODE     InpLotMode      = LOT_RISK;       // Position size from
input double            InpRiskPercent  = 1.0;            // Risk per trade (% of balance)
input double            InpFixedLot     = 0.01;           // Fixed lot (only when sizing is fixed)
input ulong             InpMagic        = 20261010;       // Magic number
input ulong             InpSlippage     = 20;             // Slippage (points)

input group             "Break even"
input bool              InpBeEnable     = true;           // Move the stop to break even
input double            InpBeTrigger    = 100;            // Profit that arms it
input double            InpBeOffset     = 10;             // Offset beyond entry (lock-in)

input group             "Trailing stop"
input bool              InpTrailEnable  = true;           // Trail the stop
input double            InpTrailTrigger = 150;            // Profit before trailing starts
input double            InpTrailStep    = 20;             // Smallest move worth making
input double            InpTrailDist    = 100;            // Distance held behind price

//+-------------------------------------------------------------------+
//| One fair value gap                                                |
//|                                                                   |
//| Keyed by the TIME of its first candle, not a bar index: the       |
//| structure is rebuilt from scratch on every bar, so indices move   |
//| but times do not.                                                 |
//+-------------------------------------------------------------------+
struct FvgBox
  {
   datetime          t_open;    // first candle of the three
   datetime          t_right;   // right edge, walks forward until touched
   double            top;
   double            bottom;
   bool              bullish;
   bool              frozen;    // price has touched it: stop extending
   bool              spent;     // already traded, or mitigated without a trade
   string            name;
  };

CTrade           Trade;
CPositionManager Manager;
FvgBox           Fvgs[];

string        ObjPrefix    = "";
datetime      LastBarTime  = 0;
datetime      ActiveBosTime = 0;   // the BoS the current gaps belong to
int           ActiveDir     = 0;   // +1 long setup, -1 short, 0 stood down
double        StructLow     = 0.0; // the levels a stop hides behind, as of
double        StructHigh    = 0.0; // the last closed bar
bool          LegConfirmed  = false; // the extreme has taken its IDM
double        PointSize     = 0.0;
double        UnitSize      = 0.0; // one input unit, in price
double        WarnedFree    = -1.0; // free margin the funds notice last reported
datetime      EntryBlockedBar = 0; // a send failed on this bar: stand down

//--- the slice of free margin the EA refuses to spend, so that spread,
//--- commission and the next tick cannot turn an accepted order into a
//--- margin call
const double  MarginReserve = 0.05;   // 5%

//--- the price history the engines run on, oldest first
double        H[], L[], C[];
datetime      T[];

//--- the pullback swings of the last rebuild, kept only for drawing
SwingPoint    PbSwings[];

//+-------------------------------------------------------------------+
int OnInit(void)
  {
   ObjPrefix = StringFormat("SFVG_%I64d_", ChartID());

   PointSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   const int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   const double pip = (digits == 3 || digits == 5) ? PointSize * 10.0 : PointSize;
   UnitSize = (InpDistUnit == DIST_PIPS) ? pip : PointSize;

   Trade.SetExpertMagicNumber(InpMagic);
   Trade.SetDeviationInPoints((ulong)InpSlippage);
   Trade.SetTypeFillingBySymbol(_Symbol);

//--- the stop manager speaks the same distance unit as everything else
   Manager.Configure(_Symbol, InpMagic, UnitSize, InpSlippage);
   Manager.SetBreakEven(InpBeEnable, InpBeTrigger, InpBeOffset);
   Manager.SetTrailing(InpTrailEnable, InpTrailTrigger, InpTrailStep, InpTrailDist);

   if(InpRiskReward <= 0.0)
     {
      Print("Risk / reward must be greater than zero.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpMaxPositions < 1)
     {
      Print("Max open positions must be at least 1.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpMinDepth < 0.0 || InpMinDepth > 100.0)
     {
      Print("Minimum retracement must be between 0 and 100 percent.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   ArrayResize(Fvgs, 0);
   LastBarTime   = 0;
   ActiveBosTime = 0;
   ActiveDir     = 0;
   WarnedFree    = -1.0;
   EntryBlockedBar = 0;

   return(INIT_SUCCEEDED);
  }

//+-------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, ObjPrefix);
   ChartRedraw();
  }

//+-------------------------------------------------------------------+
//| Loads the history and runs both engines over it from scratch.     |
//|                                                                   |
//| Rebuilding every bar rather than stepping incrementally keeps the |
//| EA honest: bar indices cannot drift as history loads or shifts,   |
//| and what the EA sees is exactly what the indicator would draw on  |
//| the same chart. The engines are linear, so the cost is noise.     |
//+-------------------------------------------------------------------+
bool BuildStructure(CMarketStructure &ms)
  {
   const int want = MathMin(InpHistoryBars, Bars(_Symbol, _Period));
   if(want < 50)
      return(false);

   ArraySetAsSeries(H, false);
   ArraySetAsSeries(L, false);
   ArraySetAsSeries(C, false);
   ArraySetAsSeries(T, false);

   if(CopyHigh(_Symbol, _Period, 0, want, H)  != want)
      return(false);
   if(CopyLow(_Symbol, _Period, 0, want, L)   != want)
      return(false);
   if(CopyClose(_Symbol, _Period, 0, want, C) != want)
      return(false);
   if(CopyTime(_Symbol, _Period, 0, want, T)  != want)
      return(false);

   CPullbackDetector pb;
   pb.Configure(InpStartSide, InpBreakMode);
   ms.Configure(InpTouchMode, InpUseSweeps);
   ArrayResize(PbSwings, 0);

   const int last_closed = want - 2;          // the forming bar is never used
   for(int i = 0; i <= last_closed; i++)
     {
      SwingPoint swing;
      const bool have = pb.Step(i, H, L, C, swing);
      if(have)
        {
         const int n = ArraySize(PbSwings);
         ArrayResize(PbSwings, n + 1);
         PbSwings[n] = swing;
        }
      ms.Step(i, H, L, C, have, swing);
     }
   return(true);
  }

//+-------------------------------------------------------------------+
//| The newest BoS or CHoCH, ignoring IDM and sweep events.           |
//+-------------------------------------------------------------------+
bool LastBreak(CMarketStructure &ms, MsEvent &out)
  {
   for(int k = ms.Events() - 1; k >= 0; k--)
     {
      MsEvent e;
      ms.Event(k, e);
      if(e.type == MS_EVENT_BOS || e.type == MS_EVENT_CHOCH)
        {
         out = e;
         return(true);
        }
     }
   return(false);
  }

//+-------------------------------------------------------------------+
void ClearFvgs(void)
  {
   for(int i = 0; i < ArraySize(Fvgs); i++)
     {
      ObjectDelete(0, Fvgs[i].name);
      ObjectDelete(0, Fvgs[i].name + "t");
     }
   ArrayResize(Fvgs, 0);
  }

//+-------------------------------------------------------------------+
//| Collects the gaps a fresh BoS makes available.                    |
//|                                                                   |
//| The scan walks from the structure low (high, when short) rightward|
//| to the breaking bar. A gap only qualifies if it is wide enough    |
//| and sits entirely on the near side of the level that was broken - |
//| a gap above a bullish BoS is not a discount, it is chasing.       |
//+-------------------------------------------------------------------+
void ScanFvgs(CMarketStructure &ms, const bool bullish, const int bos_bar,
              const double bos_price, const int to_bar, const bool reset)
  {
   if(reset)
      ClearFvgs();

   const int from = bullish ? ms.LowIndex() : ms.HighIndex();
   if(from < 0 || to_bar <= from)
      return;

   const double min_size = InpFvgMinSize * UnitSize;
   int seen = 0, too_small = 0, wrong_side = 0;

//--- i is the third candle of the pattern, so it starts two on
   for(int i = from + 2; i <= to_bar; i++)
     {
      double top, bottom;
      if(bullish)
        {
         if(!(L[i] > H[i - 2]))              // no gap between candle 1 and 3
            continue;
         bottom = H[i - 2];
         top    = L[i];
        }
      else
        {
         if(!(H[i] < L[i - 2]))
            continue;
         bottom = H[i];
         top    = L[i - 2];
        }
      seen++;

      if(FvgKnown(T[i - 2]))
         continue;                            // already on the books

      if(top - bottom < min_size)
        {
         too_small++;
         if(InpFvgLogSkips)
            PrintFormat("gap at %s skipped: %.*f wide, minimum is %.*f",
                        TimeToString(T[i - 2]), _Digits, top - bottom,
                        _Digits, min_size);
         continue;
        }

      if(InpFvgBelowBos && (bullish ? (top > bos_price) : (bottom < bos_price)))
        {
         wrong_side++;
         if(InpFvgLogSkips)
            PrintFormat("gap at %s skipped: %.*f-%.*f is on the far side of the broken %.*f",
                        TimeToString(T[i - 2]), _Digits, bottom, _Digits, top,
                        _Digits, bos_price);
         continue;
        }

      const int n = ArraySize(Fvgs);
      ArrayResize(Fvgs, n + 1);
      Fvgs[n].t_open  = T[i - 2];
      Fvgs[n].t_right = T[i];
      Fvgs[n].top     = top;
      Fvgs[n].bottom  = bottom;
      Fvgs[n].bullish = bullish;
      Fvgs[n].frozen  = false;
      Fvgs[n].spent   = false;
      Fvgs[n].name    = StringFormat("%sFVG_%I64d", ObjPrefix, (long)T[i - 2]);
      DrawFvg(Fvgs[n]);
     }

   if(InpFvgLogSkips && reset)
      PrintFormat("scan %d..%d: %d gap(s) found, %d too small, %d wrong side, %d kept",
                  from, to_bar, seen, too_small, wrong_side, ArraySize(Fvgs));
  }

//+-------------------------------------------------------------------+
//| Gaps are keyed by the time of their first candle, so a rescan can |
//| add what is new without disturbing what is already being tracked. |
//+-------------------------------------------------------------------+
bool FvgKnown(const datetime t)
  {
   for(int i = 0; i < ArraySize(Fvgs); i++)
      if(Fvgs[i].t_open == t)
         return(true);
   return(false);
  }

//+-------------------------------------------------------------------+
//| Draws or updates one gap, caption centred in the box.             |
//+-------------------------------------------------------------------+
void DrawFvg(FvgBox &f)
  {
   if(!InpShowFvg)
      return;

   const color clr = f.bullish ? InpFvgBuyColor : InpFvgSellColor;

   if(ObjectFind(0, f.name) < 0)
     {
      ObjectCreate(0, f.name, OBJ_RECTANGLE, 0, f.t_open, f.bottom, f.t_right, f.top);
      ObjectSetInteger(0, f.name, OBJPROP_COLOR,      clr);
      ObjectSetInteger(0, f.name, OBJPROP_FILL,       true);
      ObjectSetInteger(0, f.name, OBJPROP_BACK,       true);
      ObjectSetInteger(0, f.name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, f.name, OBJPROP_HIDDEN,     true);
     }
   ObjectSetInteger(0, f.name, OBJPROP_TIME,  0, f.t_open);
   ObjectSetDouble(0,  f.name, OBJPROP_PRICE, 0, f.bottom);
   ObjectSetInteger(0, f.name, OBJPROP_TIME,  1, f.t_right);
   ObjectSetDouble(0,  f.name, OBJPROP_PRICE, 1, f.top);

//--- the caption follows the middle of the box as the box grows
   const string lbl = f.name + "t";
   const datetime mid_t = (datetime)((long)f.t_open / 2 + (long)f.t_right / 2);
   const double   mid_p = (f.top + f.bottom) / 2.0;

   if(ObjectFind(0, lbl) < 0)
     {
      ObjectCreate(0, lbl, OBJ_TEXT, 0, mid_t, mid_p);
      ObjectSetString(0, lbl, OBJPROP_TEXT, "FVG");
      ObjectSetString(0, lbl, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, lbl, OBJPROP_FONTSIZE,   InpFvgTextSize);
      ObjectSetInteger(0, lbl, OBJPROP_COLOR,      InpFvgTextColor);
      ObjectSetInteger(0, lbl, OBJPROP_ANCHOR,     ANCHOR_CENTER);
      ObjectSetInteger(0, lbl, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, lbl, OBJPROP_HIDDEN,     true);
     }
   ObjectSetInteger(0, lbl, OBJPROP_TIME,  0, mid_t);
   ObjectSetDouble(0,  lbl, OBJPROP_PRICE, 0, mid_p);
  }

//+-------------------------------------------------------------------+
//| How far price has to come back before a gap may be traded.        |
//|                                                                   |
//| The leg is A -> B: the structure low to the confirmed high when   |
//| long, mirrored when short. Depth is measured from B back towards  |
//| A, so 50% is the midpoint of the leg and 100% is A itself. A      |
//| shallow touch near B is the weakest kind of entry, which is what  |
//| this filter is there to refuse.                                   |
//+-------------------------------------------------------------------+
double DepthLevel(const bool bullish)
  {
   const double a = bullish ? StructLow  : StructHigh;   // where the leg began
   const double b = bullish ? StructHigh : StructLow;    // the confirmed extreme
   return(b - (b - a) * InpMinDepth / 100.0);
  }

//+-------------------------------------------------------------------+
bool DepthOk(const bool bullish, const double price)
  {
   if(InpMinDepth <= 0.0)
      return(true);

   const double a = bullish ? StructLow  : StructHigh;
   const double b = bullish ? StructHigh : StructLow;
   if(MathAbs(b - a) <= 0.0)
      return(true);                          // degenerate leg, do not block

   return(bullish ? (price <= DepthLevel(true))
          : (price >= DepthLevel(false)));
  }

//+-------------------------------------------------------------------+
int CountPositions(void)
  {
   int n = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == (long)InpMagic)
         n++;
     }
   return(n);
  }

//+-------------------------------------------------------------------+
//| Volume for the requested risk, clamped to the symbol's limits.    |
//+-------------------------------------------------------------------+
double PositionVolume(const ENUM_ORDER_TYPE type, const double entry, const double sl)
  {
   const double v_min  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   const double v_max  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   const double v_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(InpLotMode == LOT_FIXED)
      return(AffordableVolume(type, NormalizeVolume(InpFixedLot, v_min, v_max, v_step), entry));

//--- risk sizing: a tighter stop buys a bigger position for the same
//--- money, which is the whole point of placing the stop structurally
   const double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   const double tick_size  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   const double distance   = MathAbs(entry - sl);

   if(tick_value <= 0.0 || tick_size <= 0.0 || distance <= 0.0)
     {
      Print("Cannot size the trade: symbol tick data or stop distance is unusable.");
      return(0.0);
     }

   const double loss_per_lot = distance / tick_size * tick_value;
   if(loss_per_lot <= 0.0)
      return(0.0);

   const double risk = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
   const double raw  = risk / loss_per_lot;
   const double lot  = NormalizeVolume(raw, v_min, v_max, v_step);

//--- rounding up to the smallest tradable size would quietly risk more
//--- than asked for, so say so rather than hide it
   if(lot * loss_per_lot > risk * 1.01)
      PrintFormat("Minimum volume %.*f risks %.2f, above the %.2f requested (%.1f%% of balance).",
                  VolumeDigits(v_step), lot, lot * loss_per_lot, risk, InpRiskPercent);

//--- the size the risk asks for is worthless if the account cannot
//--- finance it; trimming only ever lowers the risk taken
   return(AffordableVolume(type, lot, entry));
  }

//+-------------------------------------------------------------------+
int VolumeDigits(const double step)
  {
   for(int d = 0; d <= 8; d++)
      if(MathAbs(step * MathPow(10, d) - MathRound(step * MathPow(10, d))) < 1e-9)
         return(d);
   return(2);
  }

//+-------------------------------------------------------------------+
//| Snaps a volume onto the symbol's step and limits.                 |
//+-------------------------------------------------------------------+
double NormalizeVolume(const double lot, const double v_min, const double v_max,
                       const double v_step)
  {
   double v = lot;
   if(v_step > 0.0)
      v = MathFloor(v / v_step + 1e-9) * v_step;
   v = MathMax(v, v_min);
   v = MathMin(v, v_max);
   return(NormalizeDouble(v, VolumeDigits(v_step)));
  }

//+-------------------------------------------------------------------+
//| Margin the broker would hold for this order, 0 on failure.        |
//+-------------------------------------------------------------------+
bool MarginNeeded(const ENUM_ORDER_TYPE type, const double lot, const double price,
                  double &margin)
  {
   margin = 0.0;
   if(lot <= 0.0 || price <= 0.0)
      return(false);
   ResetLastError();
   return(OrderCalcMargin(type, _Symbol, lot, price, margin));
  }

//+-------------------------------------------------------------------+
bool Affordable(const double margin)
  {
   return(margin * (1.0 + MarginReserve) <= AccountInfoDouble(ACCOUNT_MARGIN_FREE));
  }

//+-------------------------------------------------------------------+
//| The volume free margin can actually carry, or zero.               |
//|                                                                   |
//| An account can always be too small for the trade the rules just   |
//| found - the Market validator deliberately runs on a deposit of a  |
//| single currency unit, where even the symbol's minimum volume      |
//| cannot be financed. Sending the order anyway earns nothing but a  |
//| "not enough money" rejection, so the size is settled against free |
//| margin here and the setup is passed over when nothing fits.       |
//+-------------------------------------------------------------------+
double AffordableVolume(const ENUM_ORDER_TYPE type, const double lot, const double price)
  {
   double margin = 0.0;
   if(!MarginNeeded(type, lot, price, margin))
     {
      PrintFormat("Cannot calculate margin for %.2f lots: error %d - trade skipped.",
                  lot, GetLastError());
      return(0.0);
     }
   if(Affordable(margin))
      return(lot);

   const double v_min  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   const double v_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   const double free   = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

//--- margin is linear in volume, so one calculation sizes the rest;
//--- the result is then verified rather than trusted
   if(margin > 0.0 && free > 0.0)
     {
      const double fits = free / (1.0 + MarginReserve) / (margin / lot);
      double       trim = (v_step > 0.0) ? MathFloor(fits / v_step + 1e-9) * v_step : fits;
      trim = NormalizeDouble(trim, VolumeDigits(v_step));
      if(trim >= v_min && trim < lot &&
         MarginNeeded(type, trim, price, margin) && Affordable(margin))
        {
         PrintFormat("Volume trimmed from %.*f to %.*f lots: free margin %.2f.",
                     VolumeDigits(v_step), lot, VolumeDigits(v_step), trim, free);
         return(trim);
        }
     }

   return(0.0);
  }

//+-------------------------------------------------------------------+
//| Can the account finance the smallest trade the symbol allows?     |
//|                                                                   |
//| Checked before the gaps are scanned: when the answer is no, every |
//| touched gap would otherwise try, fail and try again on the next   |
//| tick, filling the journal with rejections.                        |
//+-------------------------------------------------------------------+
bool CanFinanceMinVolume(const ENUM_ORDER_TYPE type)
  {
   const double v_min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   const double price = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                        : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double margin = 0.0;
   if(!MarginNeeded(type, v_min, price, margin))
      return(false);
   if(Affordable(margin))
      return(true);

//--- said once per state of the account, not once per bar: an account
//--- that stays too small would otherwise fill the journal on its own
   const double free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(WarnedFree < 0.0 || MathAbs(free - WarnedFree) > MathMax(0.01, WarnedFree * 0.01))
     {
      WarnedFree = free;
      PrintFormat("Minimum volume %.2f needs %.2f margin, free margin is %.2f - setups passed over.",
                  v_min, margin, free);
     }
   return(false);
  }

//+-------------------------------------------------------------------+
//| Opens the trade a touched gap calls for. Returns true on success. |
//+-------------------------------------------------------------------+
bool OpenTrade(const bool bullish, const double structure_level)
  {
   const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   const int    dig = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   const double entry  = bullish ? ask : bid;
   const double buffer = InpSlBuffer * UnitSize;
   const double sl     = NormalizeDouble(bullish ? structure_level - buffer
                                         : structure_level + buffer, dig);

   const double risk = bullish ? (entry - sl) : (sl - entry);
   if(risk <= 0.0)
     {
      Print("Stop is on the wrong side of price - trade skipped.");
      return(false);
     }

//--- the broker will not accept a stop closer than this
   const double stops = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * PointSize;
   if(risk <= stops)
     {
      Print("Stop is inside the broker's stop level - trade skipped.");
      return(false);
     }

   const double tp  = NormalizeDouble(bullish ? entry + risk * InpRiskReward
                                      : entry - risk * InpRiskReward, dig);

   const ENUM_ORDER_TYPE type = bullish ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   const double lot = PositionVolume(type, entry, sl);
   if(lot <= 0.0)
     {
      Print("Volume resolved to zero - trade skipped.");
      return(false);
     }

   const bool ok = bullish ? Trade.Buy(lot, _Symbol, 0.0, sl, tp, "SMC FVG")
                   : Trade.Sell(lot, _Symbol, 0.0, sl, tp, "SMC FVG");
   if(!ok)
      PrintFormat("Order failed: retcode %d, %s", Trade.ResultRetcode(),
                  Trade.ResultRetcodeDescription());
   return(ok);
  }

//+-------------------------------------------------------------------+
//| Draws the structure exactly as the EA computed it.                |
//|                                                                   |
//| The engines are rebuilt from scratch every bar, so the drawing is |
//| too: delete and redraw rather than track what moved. That costs a |
//| few hundred objects a bar, which is nothing next to the certainty |
//| that the picture is the EA's own state and not a second opinion   |
//| from an indicator configured slightly differently.                |
//+-------------------------------------------------------------------+
void DrawStructure(CMarketStructure &ms)
  {
   const string pre = ObjPrefix + "S_";
   ObjectsDeleteAll(0, pre);
   if(!InpShowStruct)
      return;

   int serial = 0;

//--- the pullback zigzag underneath
   for(int k = 1; k < ArraySize(PbSwings); k++)
     {
      const string nm = pre + "P" + (string)(serial++);
      if(ObjectCreate(0, nm, OBJ_TREND, 0,
                      T[PbSwings[k - 1].index], PbSwings[k - 1].price,
                      T[PbSwings[k].index],     PbSwings[k].price))
         StyleSeg(nm, InpPbLegColor, STYLE_SOLID, 1, true);
     }

//--- the structure chain, plus a marker on every point
   MsPoint p, prev;
   for(int k = 0; k < ms.Points(); k++)
     {
      ms.Point(k, p);

      if(k > 0)
        {
         ms.Point(k - 1, prev);
         const string nm = pre + "M" + (string)(serial++);
         if(ObjectCreate(0, nm, OBJ_TREND, 0, T[prev.index], prev.price,
                         T[p.index], p.price))
            StyleSeg(nm, InpMsLegColor, STYLE_SOLID, 2, false);
        }

      const string am = pre + "A" + (string)(serial++);
      if(ObjectCreate(0, am, OBJ_ARROW, 0, T[p.index], p.price))
        {
         ObjectSetInteger(0, am, OBJPROP_ARROWCODE, p.is_high ? 217 : 218);
         ObjectSetInteger(0, am, OBJPROP_COLOR, p.is_high ? InpHighColor : InpLowColor);
         ObjectSetInteger(0, am, OBJPROP_ANCHOR,
                          p.is_high ? ANCHOR_BOTTOM : ANCHOR_TOP);
         ObjectSetInteger(0, am, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, am, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, am, OBJPROP_HIDDEN, true);
        }
     }

//--- the minimum-retracement level of the live leg, so the filter can
//--- be checked by eye against where price actually turned
   if(InpMinDepth > 0.0 && ActiveDir != 0 && ms.Points() > 1)
     {
      const bool   bull = (ActiveDir > 0);
      const int    a_i  = bull ? ms.LowIndex() : ms.HighIndex();
      const double lvl  = DepthLevel(bull);
      if(a_i >= 0 && lvl > 0.0)
        {
         const string nm = pre + "D";
         if(ObjectCreate(0, nm, OBJ_TREND, 0, T[a_i], lvl,
                         T[ArraySize(T) - 1], lvl))
            StyleSeg(nm, InpDepthColor, STYLE_DASHDOT, 1, false);

         const string lb = pre + "DL";
         if(ObjectCreate(0, lb, OBJ_TEXT, 0, T[ArraySize(T) - 1], lvl))
           {
            ObjectSetString(0, lb, OBJPROP_TEXT,
                            StringFormat("%.0f%%", InpMinDepth));
            ObjectSetString(0, lb, OBJPROP_FONT, "Arial");
            ObjectSetInteger(0, lb, OBJPROP_FONTSIZE, 8);
            ObjectSetInteger(0, lb, OBJPROP_COLOR, InpDepthColor);
            ObjectSetInteger(0, lb, OBJPROP_ANCHOR, ANCHOR_LEFT);
            ObjectSetInteger(0, lb, OBJPROP_SELECTABLE, false);
            ObjectSetInteger(0, lb, OBJPROP_HIDDEN, true);
           }
        }
     }

//--- the events, drawn the way the indicator draws them
   MsEvent e;
   for(int k = 0; k < ms.Events(); k++)
     {
      ms.Event(k, e);
      if(e.from < 0 || e.to < 0)
         continue;

      color           clr   = InpSweepColor;
      string          txt   = "x";
      ENUM_LINE_STYLE style = STYLE_SOLID;

      if(e.type == MS_EVENT_BOS)
        { clr = InpBosColor;   txt = "BoS";   style = STYLE_DASH; }
      else
         if(e.type == MS_EVENT_CHOCH)
           { clr = InpChochColor; txt = "CHoCH"; style = STYLE_DASH; }
         else
            if(e.type == MS_EVENT_IDM)
              { clr = InpIdmColor;   txt = "IDM";   style = STYLE_DOT;  }

      const string nm = pre + "E" + (string)(serial++);
      if(ObjectCreate(0, nm, OBJ_TREND, 0, T[e.from], e.price, T[e.to], e.price))
         StyleSeg(nm, clr, style, 1, false);

      const int    mid = (e.from + e.to) / 2;
      const string lb  = pre + "L" + (string)(serial++);
      if(ObjectCreate(0, lb, OBJ_TEXT, 0, T[mid], e.price))
        {
         ObjectSetString(0, lb, OBJPROP_TEXT, txt);
         ObjectSetString(0, lb, OBJPROP_FONT, "Arial");
         ObjectSetInteger(0, lb, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(0, lb, OBJPROP_COLOR, clr);
         ObjectSetInteger(0, lb, OBJPROP_ANCHOR, e.above ? ANCHOR_LOWER : ANCHOR_UPPER);
         ObjectSetInteger(0, lb, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, lb, OBJPROP_HIDDEN, true);
        }
     }
  }

//+-------------------------------------------------------------------+
void StyleSeg(const string name, const color clr, const ENUM_LINE_STYLE style,
              const int width, const bool back)
  {
   ObjectSetInteger(0, name, OBJPROP_COLOR,      clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE,      style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH,      width);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT,  false);
   ObjectSetInteger(0, name, OBJPROP_RAY_LEFT,   false);
   ObjectSetInteger(0, name, OBJPROP_BACK,       back);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN,     true);
  }

//+-------------------------------------------------------------------+
//| Per-bar work: rebuild the structure, react to a new break.        |
//+-------------------------------------------------------------------+
void OnBar(void)
  {
   CMarketStructure ms;
   if(!BuildStructure(ms))
      return;

   DrawStructure(ms);

   MsEvent brk;
   if(!LastBreak(ms, brk))
      return;

   const datetime brk_time = T[brk.to];

//--- a CHoCH stands the EA down: nothing trades until the first BoS
//--- of the new trend confirms that the reversal has legs
   if(brk.type == MS_EVENT_CHOCH)
     {
      if(ActiveDir != 0)
        {
         ClearFvgs();
         ActiveDir     = 0;
         ActiveBosTime = 0;
        }
      return;
     }

   const int last_closed = ArraySize(T) - 2;

//--- a BoS we have not seen before replaces the whole gap set
   if(brk_time != ActiveBosTime)
     {
      ActiveBosTime = brk_time;
      ActiveDir     = brk.bullish ? 1 : -1;
      ScanFvgs(ms, brk.bullish, brk.to, brk.price, last_closed, true);
      PrintFormat("BoS %s at %s - %d gap(s) marked",
                  brk.bullish ? "up" : "down",
                  DoubleToString(brk.price, _Digits), ArraySize(Fvgs));
     }
   else
     {
      //--- the window runs from the structure point to NOW, not merely to
      //--- the breaking bar, so a gap that forms while price is pulling
      //--- back is picked up as well
      const int before = ArraySize(Fvgs);
      ScanFvgs(ms, brk.bullish, brk.to, brk.price, last_closed, false);
      if(ArraySize(Fvgs) > before)
         PrintFormat("%d new gap(s) formed since the BoS", ArraySize(Fvgs) - before);
     }

//--- levels and confirmation state for this bar
   StructLow    = ms.LowPrice();
   StructHigh   = ms.HighPrice();
   LegConfirmed = (ms.Pending() == 0);

//--- the gaps still waiting walk forward with the chart
   const datetime now = T[ArraySize(T) - 1];
   for(int i = 0; i < ArraySize(Fvgs); i++)
     {
      if(Fvgs[i].frozen)
         continue;
      Fvgs[i].t_right = now;
      DrawFvg(Fvgs[i]);
     }
  }

//+-------------------------------------------------------------------+
//| Per-tick work: has price reached one of the gaps?                 |
//+-------------------------------------------------------------------+
void CheckEntries(void)
  {
   if(ActiveDir == 0 || ArraySize(Fvgs) == 0)
      return;

   const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(bid <= 0.0)
      return;

//--- nothing below is worth doing on an account that cannot pay for
//--- the smallest trade on offer; the gaps stay live for later
   if(!CanFinanceMinVolume(ActiveDir > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL))
      return;

//--- and an order the server has already refused this bar will be
//--- refused again on the next tick: wait for the next bar instead
   if(EntryBlockedBar == LastBarTime)
      return;

//--- the leg is only tradable once its extreme has been confirmed,
//--- which is exactly what taking the inducement does
   const bool may_trade = (!InpRequireIdm || LegConfirmed) &&
                          ((ActiveDir > 0 && InpAllowBuy) ||
                           (ActiveDir < 0 && InpAllowSell));

   int open_now = CountPositions();

   for(int i = 0; i < ArraySize(Fvgs); i++)
     {
      if(Fvgs[i].spent)
         continue;

      const bool bull = Fvgs[i].bullish;
      const bool touched = bull ? (bid <= Fvgs[i].top) : (bid >= Fvgs[i].bottom);
      if(!touched)
         continue;

      bool changed = false;

      //--- a touched gap stops extending, whatever happens next
      if(!Fvgs[i].frozen)
        {
         Fvgs[i].frozen = true;
         changed = true;
        }

      //--- Touching is NOT the same as being used up. A gap entered at
      //--- its edge may still be too shallow for the retracement filter,
      //--- and price can go deeper into the very same gap on a later
      //--- tick. The gap stays live until it either trades or is fully
      //--- traded through.
      if(may_trade && open_now < InpMaxPositions && DepthOk(bull, bid))
        {
         if(OpenTrade(bull, bull ? StructLow : StructHigh))
           {
            Fvgs[i].spent = true;
            changed = true;
            open_now++;
           }
         else
           {
            EntryBlockedBar = LastBarTime;   // leave the gap live, stop retrying
            if(changed)
               DrawFvg(Fvgs[i]);
            return;
           }
        }
      else
        {
         const bool mitigated = bull ? (bid <= Fvgs[i].bottom)
                                : (bid >= Fvgs[i].top);
         if(mitigated)                       // price went straight through it
           {
            Fvgs[i].spent = true;
            changed = true;
           }
        }

      if(changed)
         DrawFvg(Fvgs[i]);
     }
  }

//+-------------------------------------------------------------------+
void OnTick(void)
  {
   const datetime bar = iTime(_Symbol, _Period, 0);
   if(bar != LastBarTime)
     {
      LastBarTime = bar;
      OnBar();
      ChartRedraw();
     }

   CheckEntries();
   Manager.Manage();
  }
//+-------------------------------------------------------------------+

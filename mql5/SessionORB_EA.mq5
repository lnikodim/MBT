//+------------------------------------------------------------------+
//|                                                SessionORB_EA.mq5 |
//|                                Session Opening Range Breakout EA |
//|                                            https://forge.mql5.io |
//+------------------------------------------------------------------+
#property copyright "2026"
#property link      "https://forge.mql5.io"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- opening-range trade direction, used only for internal bookkeeping
enum ENUM_ORB_DIRECTION
  {
   ORB_NONE = 0,   // no breakout yet
   ORB_LONG = 1,   // long breakout traded
   ORB_SHORT = 2   // short breakout traded
  };

//+------------------------------------------------------------------+
//| Inputs                                                            |
//+------------------------------------------------------------------+
input group "===== Session Settings (broker/server time) ====="
input int      InpSessionStartHour   = 8;    // Session start hour   (0-23)
input int      InpSessionStartMinute = 0;    // Session start minute (0-59)
input int      InpOpeningRangeMinutes= 30;   // Opening range duration, minutes
input int      InpTradingWindowMinutes = 120;// Minutes after range close during which breakouts may be traded

input group "===== Trade Settings ====="
input ulong    InpMagicNumber        = 20260815; // Magic number
input int      InpMaxTradesPerSession= 1;        // Max trades allowed per session
input bool     InpAllowLongTrades    = true;      // Allow long (buy) breakouts
input bool     InpAllowShortTrades   = true;      // Allow short (sell) breakouts
input int      InpBreakoutBufferPoints = 20;       // Points beyond range level required to confirm breakout

input group "===== Risk Management ====="
input double   InpRiskPercent          = 1.0;   // Risk percent of balance per trade
input int      InpStopLossBufferPoints = 30;    // Extra points added past the opposite range boundary for SL
input double   InpRewardToRiskRatio    = 2.0;   // Take-profit distance as a multiple of the risk distance
input bool     InpUseFixedLot          = false; // Use a fixed lot size instead of risk-based sizing
input double   InpFixedLotSize         = 0.10;  // Fixed lot size (used only if InpUseFixedLot = true)

input group "===== Visuals ====="
input bool     InpDrawObjects   = true;          // Draw range box and breakout trigger lines on chart
input color    InpRangeBoxColor = clrSilver;      // Range box border color
input color    InpTriggerColor  = clrWhite;       // Breakout trigger line color
input string   InpObjectPrefix  = "SORB_";        // Prefix for all chart objects created by this EA

//+------------------------------------------------------------------+
//| Globals                                                           |
//+------------------------------------------------------------------+
CTrade         trade;

datetime       g_sessionDate;          // midnight of the trading day currently tracked
datetime       g_rangeStartTime;       // session open time for the tracked day
datetime       g_rangeEndTime;         // session open + InpOpeningRangeMinutes
datetime       g_tradingWindowEndTime; // g_rangeEndTime + InpTradingWindowMinutes

double         g_rangeHigh;
double         g_rangeLow;
bool           g_rangeComputed;

int            g_tradesThisSession;
ENUM_ORB_DIRECTION g_lastDirection;

datetime       g_lastBarTime;          // for cheap new-bar detection on the chart timeframe

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetMarginMode();
   trade.SetTypeFillingBySymbol(_Symbol);

   if(InpOpeningRangeMinutes <= 0 || InpTradingWindowMinutes <= 0)
     {
      Print("SessionORB_EA: OpeningRangeMinutes and TradingWindowMinutes must be > 0");
      return(INIT_PARAMETERS_INCORRECT);
     }

//--- force a fresh session build on the first tick
   g_sessionDate   = 0;
   g_rangeComputed = false;
   g_lastBarTime   = 0;

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- remove every chart object this EA created, identified by its unique prefix
   ObjectsDeleteAll(0, InpObjectPrefix);
   ChartRedraw(0);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
  {
   datetime now = TimeCurrent();

//--- 1) session bookkeeping: rebuild session anchor times once per calendar day
   CheckNewSession(now);

//--- 2) while inside the opening-range window there is nothing else to do but wait
   if(now < g_rangeEndTime)
      return;

//--- 3) the instant the range window closes, compute it exactly once
   if(!g_rangeComputed)
     {
      ComputeOpeningRange();
      if(InpDrawObjects)
         DrawRangeObjects();
      g_rangeComputed = true;
     }

//--- 4) outside the trading window, or after the trade quota is used, do nothing further
   if(now > g_tradingWindowEndTime)
      return;

   if(g_tradesThisSession >= InpMaxTradesPerSession)
      return;

//--- 5) breakout decisions are only evaluated once per closed bar, not on every tick
   if(!IsNewBar())
      return;

   CheckBreakoutAndTrade();
  }

//+------------------------------------------------------------------+
//| Rebuild session start/end/trading-window anchors on a new day     |
//+------------------------------------------------------------------+
void CheckNewSession(const datetime now)
  {
   MqlDateTime dt;
   TimeToStruct(now, dt);

   dt.hour = 0; dt.min = 0; dt.sec = 0;
   datetime todayMidnight = StructToTime(dt);

   if(todayMidnight == g_sessionDate)
      return; // already built for today

   g_sessionDate = todayMidnight;

   MqlDateTime st;
   TimeToStruct(todayMidnight, st);
   st.hour = InpSessionStartHour;
   st.min  = InpSessionStartMinute;
   st.sec  = 0;

   g_rangeStartTime       = StructToTime(st);
   g_rangeEndTime          = g_rangeStartTime + InpOpeningRangeMinutes * 60;
   g_tradingWindowEndTime  = g_rangeEndTime   + InpTradingWindowMinutes * 60;

   g_rangeHigh          = 0.0;
   g_rangeLow            = 0.0;
   g_rangeComputed       = false;
   g_tradesThisSession    = 0;
   g_lastDirection        = ORB_NONE;

//--- clear yesterday's drawings so the chart never accumulates stale objects
   if(InpDrawObjects)
      ObjectsDeleteAll(0, InpObjectPrefix);
  }

//+------------------------------------------------------------------+
//| Compute the opening range high/low from M1 history                |
//+------------------------------------------------------------------+
void ComputeOpeningRange()
  {
   int startBar = iBarShift(_Symbol, PERIOD_M1, g_rangeStartTime, false);
   int endBar   = iBarShift(_Symbol, PERIOD_M1, g_rangeEndTime,   false);

   if(startBar < 0 || endBar < 0 || startBar < endBar)
     {
      Print("SessionORB_EA: insufficient M1 history to build the opening range");
      return;
     }

   int count = startBar - endBar + 1;

   int highestIdx = iHighest(_Symbol, PERIOD_M1, MODE_HIGH, count, endBar);
   int lowestIdx  = iLowest(_Symbol,  PERIOD_M1, MODE_LOW,  count, endBar);

   g_rangeHigh = iHigh(_Symbol, PERIOD_M1, highestIdx);
   g_rangeLow  = iLow(_Symbol,  PERIOD_M1, lowestIdx);
  }

//+------------------------------------------------------------------+
//| Cheap new-bar detector on the chart's own timeframe                |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   datetime barTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(barTime == g_lastBarTime)
      return(false);

   g_lastBarTime = barTime;
   return(true);
  }

//+------------------------------------------------------------------+
//| Evaluate the last closed bar for a breakout and, if valid, trade  |
//+------------------------------------------------------------------+
void CheckBreakoutAndTrade()
  {
   if(g_rangeHigh <= 0.0 || g_rangeLow <= 0.0 || g_rangeHigh <= g_rangeLow)
      return;

   double point  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double buffer = InpBreakoutBufferPoints * point;
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1); // last fully closed bar

   if(InpAllowLongTrades && close1 > g_rangeHigh + buffer)
     {
      OpenBreakoutTrade(ORDER_TYPE_BUY);
      return;
     }

   if(InpAllowShortTrades && close1 < g_rangeLow - buffer)
     {
      OpenBreakoutTrade(ORDER_TYPE_SELL);
      return;
     }
  }

//+------------------------------------------------------------------+
//| Build and send a risk-sized market order for the breakout          |
//+------------------------------------------------------------------+
void OpenBreakoutTrade(const ENUM_ORDER_TYPE orderType)
  {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double slBufferPrice = InpStopLossBufferPoints * point;

   double entry, sl, tp;
   double slDistancePoints;

   if(orderType == ORDER_TYPE_BUY)
     {
      entry = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      sl    = g_rangeLow - slBufferPrice;
      tp    = entry + InpRewardToRiskRatio * (entry - sl);
     }
   else
     {
      entry = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      sl    = g_rangeHigh + slBufferPrice;
      tp    = entry - InpRewardToRiskRatio * (sl - entry);
     }

//--- enforce the broker's minimum stop distance so the order is never rejected
//--- with "Invalid stops"; this must happen before risk sizing so the lot is
//--- calculated against the SL distance actually sent to the server
   EnforceMinStopDistance(orderType, entry, sl, tp);

   if(orderType == ORDER_TYPE_BUY)
      slDistancePoints = (entry - sl) / point;
   else
      slDistancePoints = (sl - entry) / point;

   if(slDistancePoints <= 0)
      return;

   double lot = CalculateLotSize(slDistancePoints, orderType, entry);
   if(lot <= 0)
     {
      Print("SessionORB_EA: computed lot size is zero (risk or margin constraint), trade skipped");
      return;
     }

   bool sent;
   if(orderType == ORDER_TYPE_BUY)
      sent = trade.Buy(lot, _Symbol, entry, sl, tp, "SessionORB breakout long");
   else
      sent = trade.Sell(lot, _Symbol, entry, sl, tp, "SessionORB breakout short");

   if(sent)
     {
      g_tradesThisSession++;
      g_lastDirection = (orderType == ORDER_TYPE_BUY) ? ORB_LONG : ORB_SHORT;
     }
   else
      Print("SessionORB_EA: order send failed, retcode=", trade.ResultRetcode());
  }

//+------------------------------------------------------------------+
//| Push sl/tp outward (in place) so both clear a safe minimum        |
//| distance from price -- combining the broker's reported stops/     |
//| freeze level with current spread and a fixed pad, since some      |
//| symbols report 0 for stops/freeze level yet still reject stops    |
//| placed too close. Without this, tight opening ranges on volatile  |
//| symbols can produce stops the server rejects with "Invalid stops".|
//+------------------------------------------------------------------+
void EnforceMinStopDistance(const ENUM_ORDER_TYPE orderType, const double entry, double &sl, double &tp)
  {
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   long stopsLevel  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long freezeLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   long spreadPoints = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);

//--- some symbols (including synthetic/test feeds) report 0 for stops/freeze
//--- level even though the server still enforces a real minimum distance, so
//--- this never trusts those alone: it always adds the current spread plus a
//--- fixed safety pad on top, and only ever uses this to push stops FURTHER
//--- from price, never closer.
   long minPoints = MathMax(stopsLevel, freezeLevel) + spreadPoints + 10;

   double minDist = minPoints * point;
   if(minDist <= 0)
      return;

   if(orderType == ORDER_TYPE_BUY)
     {
      if(entry - sl < minDist)
         sl = entry - minDist;
      if(tp - entry < minDist)
         tp = entry + minDist;
     }
   else
     {
      if(sl - entry < minDist)
         sl = entry + minDist;
      if(entry - tp < minDist)
         tp = entry - minDist;
     }
  }

//+------------------------------------------------------------------+
//| Risk-based position sizing, clamped to what free margin allows    |
//+------------------------------------------------------------------+
double CalculateLotSize(const double slDistancePoints, const ENUM_ORDER_TYPE orderType, const double entryPrice)
  {
   double lot;

   if(InpUseFixedLot)
      lot = InpFixedLotSize;
   else
     {
      double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
      double riskMoney = balance * InpRiskPercent / 100.0;

      double point     = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

      if(tickSize <= 0 || tickValue <= 0)
         return(0.0);

      double slPriceDistance = slDistancePoints * point;
      double lossPerLot      = (slPriceDistance / tickSize) * tickValue;

      if(lossPerLot <= 0)
         return(0.0);

      lot = riskMoney / lossPerLot;
     }

//--- never propose a lot the account cannot actually margin, regardless of risk math
   double maxAffordable = GetMaxLotByFreeMargin(orderType, entryPrice);
   if(maxAffordable <= 0)
      return(0.0);

   lot = MathMin(lot, maxAffordable);
   return(NormalizeLot(lot));
  }

//+------------------------------------------------------------------+
//| Largest lot the current free margin can support (with a safety   |
//| buffer, since margin requirements can shift between calc and     |
//| execution)                                                        |
//+------------------------------------------------------------------+
double GetMaxLotByFreeMargin(const ENUM_ORDER_TYPE orderType, const double entryPrice)
  {
   double marginPerLot = 0.0;
   if(!OrderCalcMargin(orderType, _Symbol, 1.0, entryPrice, marginPerLot) || marginPerLot <= 0)
      return(0.0);

   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double usableMargin = freeMargin * 0.90; // keep a 10% safety buffer

   return(usableMargin / marginPerLot);
  }

//+------------------------------------------------------------------+
//| Clamp/round a lot size to the symbol's step and maximum. If the   |
//| requested size is below the broker's minimum lot, this returns    |
//| 0.0 rather than rounding up -- forcing a trade up to the minimum  |
//| would silently override the risk/margin sizing that decided the   |
//| account cannot safely (or legally, per margin) take that trade.   |
//+------------------------------------------------------------------+
double NormalizeLot(double lot)
  {
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lot = MathFloor(lot / lotStep) * lotStep;

   if(lot < minLot)
      return(0.0); // too small to trade -- do not round up past what was actually sized

   lot = MathMin(lot, maxLot);

   int digits = 2;
   if(lotStep >= 1.0) digits = 0;
   else if(lotStep >= 0.1) digits = 1;
   else digits = 2;

   return(NormalizeDouble(lot, digits));
  }

//+------------------------------------------------------------------+
//| Draw the opening-range box and forward breakout trigger lines     |
//+------------------------------------------------------------------+
void DrawRangeObjects()
  {
   if(g_rangeHigh <= 0.0 || g_rangeLow <= 0.0)
      return;

   string dayTag = TimeToString(g_sessionDate, TIME_DATE);
   string boxName    = InpObjectPrefix + "Box_"    + dayTag;
   string highName   = InpObjectPrefix + "High_"   + dayTag;
   string lowName     = InpObjectPrefix + "Low_"    + dayTag;
   string startName   = InpObjectPrefix + "Start_"  + dayTag;

//--- shaded rectangle spanning the opening-range window
   ObjectCreate(0, boxName, OBJ_RECTANGLE, 0, g_rangeStartTime, g_rangeHigh, g_rangeEndTime, g_rangeLow);
   ObjectSetInteger(0, boxName, OBJPROP_COLOR, InpRangeBoxColor);
   ObjectSetInteger(0, boxName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, boxName, OBJPROP_FILL,  false);
   ObjectSetInteger(0, boxName, OBJPROP_BACK,  true);
   ObjectSetInteger(0, boxName, OBJPROP_SELECTABLE, false);

//--- forward-projected dashed trigger lines, extending through the trading window
   ObjectCreate(0, highName, OBJ_TREND, 0, g_rangeEndTime, g_rangeHigh, g_tradingWindowEndTime, g_rangeHigh);
   ObjectSetInteger(0, highName, OBJPROP_COLOR, InpTriggerColor);
   ObjectSetInteger(0, highName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, highName, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, highName, OBJPROP_SELECTABLE, false);

   ObjectCreate(0, lowName, OBJ_TREND, 0, g_rangeEndTime, g_rangeLow, g_tradingWindowEndTime, g_rangeLow);
   ObjectSetInteger(0, lowName, OBJPROP_COLOR, InpTriggerColor);
   ObjectSetInteger(0, lowName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, lowName, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, lowName, OBJPROP_SELECTABLE, false);

//--- vertical dotted marker at the session open
   ObjectCreate(0, startName, OBJ_VLINE, 0, g_rangeStartTime, 0);
   ObjectSetInteger(0, startName, OBJPROP_COLOR, InpTriggerColor);
   ObjectSetInteger(0, startName, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, startName, OBJPROP_SELECTABLE, false);

   ChartRedraw(0);
  }
//+------------------------------------------------------------------+

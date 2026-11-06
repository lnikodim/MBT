//+------------------------------------------------------------------+
//| H4_Trend_H1_Donchian_Breakout_v1.mq5                             |
//| New strategy experiment: H4 EMA trend + H1 Donchian breakout     |
//| No Bollinger compression filter.                                 |
//| Weekend controls use broker-server time.                         |
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"
#property description "H4 EMA trend-aligned H1 Donchian breakout EA with ATR stops and weekend protection"

#include <Trade/Trade.mqh>

CTrade trade;

input group "TIMEFRAMES & BREAKOUT"
input ENUM_TIMEFRAMES SignalTimeframe       = PERIOD_H1; // Entry signal timeframe (recommended: H1)
input int             BreakoutPeriod        = 24;        // Prior closed bars used for breakout high/low
input double          BreakoutBufferATR     = 0.05;      // Extra H1 close distance beyond range (ATR multiples)

input group "HIGHER-TIMEFRAME TREND FILTER"
input ENUM_TIMEFRAMES TrendTimeframe        = PERIOD_H4; // Trend timeframe (recommended: H4)
input int             TrendEMAPeriod        = 200;       // EMA period on trend timeframe
input bool            RequireEMASlope       = true;      // Require EMA to slope in trade direction?

input group "ATR STOPS, TARGET & RISK"
input int             ATRPeriod             = 14;        // ATR period on signal timeframe
input double          StopATRMultiplier     = 2.0;       // Stop-loss distance (ATR multiples)
input double          TargetATRMultiplier   = 3.0;       // Take-profit distance (ATR multiples)
input double          RiskPercent           = 0.25;      // Planned risk per trade (% of current equity)

input group "EXECUTION LIMITS & EA ID"
input int             MaxSpreadPoints       = 25;        // Skip new entries above this spread (points)
input int             MaxDeviationPoints    = 20;        // Maximum allowed execution deviation (points)
input ulong           MagicNumber            = 26101806;  // Unique identifier for this EA version

input group "WEEKEND PROTECTION (BROKER SERVER TIME)"
input bool            UseFridayEntryCutoff       = true; // Block new entries at/after Friday cutoff?
input int             FridayEntryCutoffHour      = 16;   // Friday entry cutoff hour (server time, 0-23)
input int             FridayEntryCutoffMinute    = 0;    // Friday entry cutoff minute (server time, 0-59)
input bool            ClosePositionsBeforeWeekend = true;// Close this EA's open position on Friday?
input int             FridayCloseHour            = 20;   // Friday close hour (server time, 0-23)
input int             FridayCloseMinute          = 0;    // Friday close minute (server time, 0-59)

int      g_atrHandle       = INVALID_HANDLE;
int      g_trendEmaHandle  = INVALID_HANDLE;
datetime g_lastBarTime     = 0;
int      g_lastFridayBlockLogDateKey = 0;
datetime g_lastWeekendCloseFailureLogTime = 0;
ulong    g_lastWeekendCloseFailureTicket = 0;

// Read a single indicator-buffer value at a closed-bar shift.
bool ReadBufferValue(const int handle, const int bufferIndex, const int shift, double &value)
{
   if(handle == INVALID_HANDLE)
      return false;

   double oneValue[1];
   if(CopyBuffer(handle, bufferIndex, shift, 1, oneValue) != 1)
      return false;

   value = oneValue[0];
   return (value != EMPTY_VALUE && MathIsValidNumber(value));
}

// Normalize prices to the symbol's tick size. Round outward so stop/target
// distances are not inadvertently reduced by price normalization.
double NormalizePriceToTick(const double price, const bool roundUp)
{
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0.0)
      tickSize = _Point;

   double units = price / tickSize;
   units = roundUp ? MathCeil(units - 1e-10) : MathFloor(units + 1e-10);
   return NormalizeDouble(units * tickSize, _Digits);
}

// Calculate lots from the monetary loss at the proposed stop price.
// If the broker minimum lot would exceed the risk budget, skip the trade.
double CalculateVolume(const ENUM_ORDER_TYPE orderType, const double entryPrice, const double stopPrice)
{
   const double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   const double riskMoney = equity * RiskPercent / 100.0;
   if(equity <= 0.0 || riskMoney <= 0.0)
      return 0.0;

   double oneLotResult = 0.0;
   if(!OrderCalcProfit(orderType, _Symbol, 1.0, entryPrice, stopPrice, oneLotResult))
   {
      Print("OrderCalcProfit failed. Error=", GetLastError());
      return 0.0;
   }

   const double lossPerLot = MathAbs(oneLotResult);
   if(lossPerLot <= 0.0)
      return 0.0;

   const double volumeMin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   const double volumeMax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   const double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(volumeMin <= 0.0 || volumeMax <= 0.0 || volumeStep <= 0.0)
      return 0.0;

   double rawVolume = MathMin(riskMoney / lossPerLot, volumeMax);
   double volume = MathFloor(rawVolume / volumeStep + 1e-10) * volumeStep;

   int volumeDigits = 0;
   double stepScaled = volumeStep;
   while(volumeDigits < 8 && MathAbs(stepScaled - MathRound(stepScaled)) > 1e-8)
   {
      stepScaled *= 10.0;
      volumeDigits++;
   }
   volume = NormalizeDouble(volume, volumeDigits);

   if(volume < volumeMin)
      return 0.0;

   return volume;
}

bool IsFridayAtOrAfter(const datetime timestamp, const int hour, const int minute)
{
   if(timestamp <= 0 || hour < 0 || hour > 23 || minute < 0 || minute > 59)
      return false;

   MqlDateTime serverTime;
   if(!TimeToStruct(timestamp, serverTime))
      return false;

   if(serverTime.day_of_week != 5) // 0=Sunday ... 5=Friday ... 6=Saturday
      return false;

   return (serverTime.hour * 60 + serverTime.min >= hour * 60 + minute);
}

bool IsNewEntryBlockedByWeekendTime(const datetime now)
{
   if(UseFridayEntryCutoff &&
      IsFridayAtOrAfter(now, FridayEntryCutoffHour, FridayEntryCutoffMinute))
      return true;

   // Once the position-close time has passed, do not open a new trade that Friday.
   if(ClosePositionsBeforeWeekend &&
      IsFridayAtOrAfter(now, FridayCloseHour, FridayCloseMinute))
      return true;

   return false;
}

// Runs on every tick, rather than only at the start of a new H1 candle.
void ManagePreWeekendClose()
{
   if(!ClosePositionsBeforeWeekend ||
      !IsFridayAtOrAfter(TimeCurrent(), FridayCloseHour, FridayCloseMinute))
      return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol ||
         (ulong)PositionGetInteger(POSITION_MAGIC) != MagicNumber)
         continue;

      const bool requestOk = trade.PositionClose(ticket, (ulong)MaxDeviationPoints);
      const uint retcode = trade.ResultRetcode();
      const bool closed = requestOk &&
         (retcode == TRADE_RETCODE_DONE || retcode == TRADE_RETCODE_DONE_PARTIAL);

      if(closed)
      {
         Print("Pre-weekend close executed for position #", ticket,
               ". Retcode=", retcode, " ", trade.ResultRetcodeDescription());
         g_lastWeekendCloseFailureTicket = 0;
         g_lastWeekendCloseFailureLogTime = 0;
      }
      else
      {
         const datetime now = TimeCurrent();
         if(ticket != g_lastWeekendCloseFailureTicket ||
            g_lastWeekendCloseFailureLogTime == 0 ||
            now - g_lastWeekendCloseFailureLogTime >= 60)
         {
            Print("WARNING: Pre-weekend close FAILED for position #", ticket,
                  ". Retcode=", retcode, " ", trade.ResultRetcodeDescription(),
                  ". Position may remain exposed over the weekend.");
            g_lastWeekendCloseFailureTicket = ticket;
            g_lastWeekendCloseFailureLogTime = now;
         }
      }
   }
}

bool HasOwnOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0)
         continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         return true;
   }
   return false;
}

bool EnoughHistoryAvailable()
{
   if(Bars(_Symbol, SignalTimeframe) < BreakoutPeriod + ATRPeriod + 10)
      return false;
   if(BarsCalculated(g_atrHandle) < ATRPeriod + 3)
      return false;
   if(Bars(_Symbol, TrendTimeframe) < TrendEMAPeriod + 3)
      return false;
   if(BarsCalculated(g_trendEmaHandle) < TrendEMAPeriod + 3)
      return false;
   return true;
}

// Trend confirmation uses only completed H4 bars to avoid reading an incomplete
// current H4 candle. BUY: H4 close above EMA and optionally EMA rising. SELL: inverse.
bool TrendAllowsDirection(const bool isBuy, bool &dataReady)
{
   dataReady = false;
   const double trendClose = iClose(_Symbol, TrendTimeframe, 1);
   double ema1 = 0.0;
   double ema2 = 0.0;

   if(trendClose <= 0.0 ||
      !ReadBufferValue(g_trendEmaHandle, 0, 1, ema1) ||
      !ReadBufferValue(g_trendEmaHandle, 0, 2, ema2))
      return false;

   dataReady = true;

   if(isBuy)
   {
      if(trendClose <= ema1)
         return false;
      if(RequireEMASlope && ema1 <= ema2)
         return false;
      return true;
   }

   if(trendClose >= ema1)
      return false;
   if(RequireEMASlope && ema1 >= ema2)
      return false;
   return true;
}

bool CheckStopDistances(const bool isBuy, const double entry, const double sl, const double tp)
{
   const long stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   if(isBuy)
      return ((entry - sl) / _Point >= stopsLevel && (tp - entry) / _Point >= stopsLevel);
   return ((sl - entry) / _Point >= stopsLevel && (entry - tp) / _Point >= stopsLevel);
}

int OnInit()
{
   if(ATRPeriod < 1 || BreakoutPeriod < 2 || BreakoutBufferATR < 0.0 ||
      TrendEMAPeriod < 2 || StopATRMultiplier <= 0.0 || TargetATRMultiplier <= 0.0 ||
      RiskPercent <= 0.0 || RiskPercent > 100.0 || MaxSpreadPoints < 0 ||
      MaxDeviationPoints < 0 ||
      FridayEntryCutoffHour < 0 || FridayEntryCutoffHour > 23 ||
      FridayEntryCutoffMinute < 0 || FridayEntryCutoffMinute > 59 ||
      FridayCloseHour < 0 || FridayCloseHour > 23 ||
      FridayCloseMinute < 0 || FridayCloseMinute > 59 ||
      PeriodSeconds(SignalTimeframe) <= 0 || PeriodSeconds(TrendTimeframe) <= PeriodSeconds(SignalTimeframe) ||
      (UseFridayEntryCutoff && ClosePositionsBeforeWeekend &&
       (FridayEntryCutoffHour * 60 + FridayEntryCutoffMinute >
        FridayCloseHour * 60 + FridayCloseMinute)))
   {
      Print("Invalid inputs. Check ranges, require trend timeframe > signal timeframe, and ensure Friday entry cutoff is not later than Friday close time when both are enabled.");
      return INIT_PARAMETERS_INCORRECT;
   }

   g_atrHandle = iATR(_Symbol, SignalTimeframe, ATRPeriod);
   g_trendEmaHandle = iMA(_Symbol, TrendTimeframe, TrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);

   if(g_atrHandle == INVALID_HANDLE || g_trendEmaHandle == INVALID_HANDLE)
   {
      Print("Failed to create indicator handles. Error=", GetLastError());
      return INIT_FAILED;
   }

   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints((ulong)MaxDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetAsyncMode(false);

   g_lastBarTime = iTime(_Symbol, SignalTimeframe, 0);

   Print("H4 Trend + H1 Donchian Breakout v1 initialized. Signal TF=", EnumToString(SignalTimeframe),
         ", trend TF=", EnumToString(TrendTimeframe), ", EMA period=", TrendEMAPeriod,
         ", require EMA slope=", (RequireEMASlope ? "true" : "false"),
         ", breakout lookback=", BreakoutPeriod, ", ATR buffer=", DoubleToString(BreakoutBufferATR, 2),
         ", SL=", DoubleToString(StopATRMultiplier, 2), " ATR, TP=", DoubleToString(TargetATRMultiplier, 2),
         " ATR, risk=", DoubleToString(RiskPercent, 2), "%. Weekend times are broker-server time; verify them against the broker session.");

   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
   if(g_trendEmaHandle != INVALID_HANDLE)
      IndicatorRelease(g_trendEmaHandle);
}

void OnTick()
{
   // First, try to flatten this EA's position if the configured Friday time is reached.
   ManagePreWeekendClose();

   // Evaluate signals once when a new signal-timeframe bar starts, using the candle
   // that has just closed (shift 1). Entry is placed at the next available tick.
   const datetime currentBarTime = iTime(_Symbol, SignalTimeframe, 0);
   if(currentBarTime == 0 || currentBarTime == g_lastBarTime)
      return;

   const datetime now = TimeCurrent();
   if(IsNewEntryBlockedByWeekendTime(now))
   {
      g_lastBarTime = currentBarTime;
      MqlDateTime serverTime;
      TimeToStruct(now, serverTime);
      const int dateKey = serverTime.year * 10000 + serverTime.mon * 100 + serverTime.day;
      if(dateKey != g_lastFridayBlockLogDateKey)
      {
         Print("New entry blocked by Friday weekend controls. Broker-server time=",
               StringFormat("%02d:%02d", serverTime.hour, serverTime.min), ".");
         g_lastFridayBlockLogDateKey = dateKey;
      }
      return;
   }

   // Do not consume this bar when history/indicator buffers are still loading;
   // retry on the next tick so the first bar after startup is not lost.
   if(!EnoughHistoryAvailable())
      return;
   if(HasOwnOpenPosition())
   {
      g_lastBarTime = currentBarTime;
      return;
   }

   const double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   const double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask <= 0.0 || bid <= 0.0 || ask < bid)
      return;

   const double spreadPoints = (ask - bid) / _Point;
   if(spreadPoints > MaxSpreadPoints)
   {
      g_lastBarTime = currentBarTime;
      Print("Signal skipped: spread ", DoubleToString(spreadPoints, 1),
            " points exceeds MaxSpreadPoints=", MaxSpreadPoints);
      return;
   }

   double atr = 0.0;
   if(!ReadBufferValue(g_atrHandle, 0, 1, atr) || atr <= 0.0)
      return;

   const double signalClose = iClose(_Symbol, SignalTimeframe, 1);
   if(signalClose <= 0.0)
      return;

   // Exclude the signal candle from the Donchian range: closed bars at shifts 2..N+1.
   const int highShift = iHighest(_Symbol, SignalTimeframe, MODE_HIGH, BreakoutPeriod, 2);
   const int lowShift  = iLowest(_Symbol, SignalTimeframe, MODE_LOW, BreakoutPeriod, 2);
   if(highShift < 0 || lowShift < 0)
      return;

   const double priorHigh = iHigh(_Symbol, SignalTimeframe, highShift);
   const double priorLow  = iLow(_Symbol, SignalTimeframe, lowShift);
   const double buffer = atr * BreakoutBufferATR;

   const bool buySignal  = (signalClose > priorHigh + buffer);
   const bool sellSignal = (signalClose < priorLow - buffer);

   // No signal: mark this bar complete. For a breakout, wait until the H4
   // buffers are available before consuming the bar, so transient history
   // loading does not discard a valid signal.
   if(!buySignal && !sellSignal)
   {
      g_lastBarTime = currentBarTime;
      return;
   }

   if(buySignal)
   {
      bool trendDataReady = false;
      const bool trendAllowed = TrendAllowsDirection(true, trendDataReady);
      if(!trendDataReady)
         return;
      g_lastBarTime = currentBarTime;
      if(!trendAllowed)
      {
         Print("BUY breakout rejected: H4 trend is not bullish under the EMA rule.");
         return;
      }

      const double entry = ask;
      const double sl = NormalizePriceToTick(entry - atr * StopATRMultiplier, false);
      const double tp = NormalizePriceToTick(entry + atr * TargetATRMultiplier, true);
      if(!CheckStopDistances(true, entry, sl, tp))
      {
         Print("BUY skipped: calculated stop or target is inside the broker's minimum stop distance.");
         return;
      }

      const double volume = CalculateVolume(ORDER_TYPE_BUY, entry, sl);
      if(volume <= 0.0)
      {
         Print("BUY skipped: calculated volume is below the minimum lot or invalid.");
         return;
      }

      const bool requestOk = trade.Buy(volume, _Symbol, 0.0, sl, tp, "H4 trend H1 Donchian BUY");
      const uint retcode = trade.ResultRetcode();
      if(!requestOk || (retcode != TRADE_RETCODE_DONE && retcode != TRADE_RETCODE_PLACED))
         Print("BUY request failed. Retcode=", retcode, " ", trade.ResultRetcodeDescription());
      else
         Print("BUY sent. Volume=", DoubleToString(volume, 4), " SL=", DoubleToString(sl, _Digits),
               " TP=", DoubleToString(tp, _Digits), " risk target=", DoubleToString(RiskPercent, 2), "% equity.");
      return;
   }

   if(sellSignal)
   {
      bool trendDataReady = false;
      const bool trendAllowed = TrendAllowsDirection(false, trendDataReady);
      if(!trendDataReady)
         return;
      g_lastBarTime = currentBarTime;
      if(!trendAllowed)
      {
         Print("SELL breakout rejected: H4 trend is not bearish under the EMA rule.");
         return;
      }

      const double entry = bid;
      const double sl = NormalizePriceToTick(entry + atr * StopATRMultiplier, true);
      const double tp = NormalizePriceToTick(entry - atr * TargetATRMultiplier, false);
      if(!CheckStopDistances(false, entry, sl, tp))
      {
         Print("SELL skipped: calculated stop or target is inside the broker's minimum stop distance.");
         return;
      }

      const double volume = CalculateVolume(ORDER_TYPE_SELL, entry, sl);
      if(volume <= 0.0)
      {
         Print("SELL skipped: calculated volume is below the minimum lot or invalid.");
         return;
      }

      const bool requestOk = trade.Sell(volume, _Symbol, 0.0, sl, tp, "H4 trend H1 Donchian SELL");
      const uint retcode = trade.ResultRetcode();
      if(!requestOk || (retcode != TRADE_RETCODE_DONE && retcode != TRADE_RETCODE_PLACED))
         Print("SELL request failed. Retcode=", retcode, " ", trade.ResultRetcodeDescription());
      else
         Print("SELL sent. Volume=", DoubleToString(volume, 4), " SL=", DoubleToString(sl, _Digits),
               " TP=", DoubleToString(tp, _Digits), " risk target=", DoubleToString(RiskPercent, 2), "% equity.");
      return;
   }
}
//+------------------------------------------------------------------+

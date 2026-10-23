//+------------------------------------------------------------------+
//| MajorFX_DonchianTrend_EA.mq5                                     |
//| Research baseline: Donchian breakout + EMA trend + ADX + ATR risk  |
//| Intended for local MT5 Strategy Tester experiments.               |
//| MBT v1.03: daily loss stop (DailyStop.mqh, -3% live default):    |
//| account equity -3% from the day start closes it, no entries till |
//| the next server day; logic same.                                 |
//| MBT v1.02: account drawdown throttle (AccountThrottle.mqh); live |
//| defaults = FTMO 2-Step: 0.5% risk, throttle 3%; logic same.      |
//+------------------------------------------------------------------+
#property copyright "OpenAI"
#property version   "1.03"
#property description "Donchian breakout EA with EMA trend filter, ADX confirmation and ATR-based SL/TP."
#property description "Designed as a backtest baseline, not a claim of profitability."

#include <Trade/Trade.mqh>

CTrade trade;

//--- inputs: groups per docs/ea-inputs.md
input group "1. Trade size"
input double          InpRiskPercent      = 0.5;      // Risk per trade, % of equity
input bool            InpSkipIfMinLotTooRisky = true; // Skip if the minimum lot risks more

input group "2. Account protection"
#define ACCOUNT_THROTTLE_DD_PCT 3.0   // live defaults = FTMO 2-Step settings (spec 2026-10-22-dd-reduction, phase 3b)
#include "AccountThrottle.mqh"
#define EA_DAILY_LOSS_PCT 3.0         // live default = FTMO 2-Step: -3%, as the gold EAs (DailyStop.mqh)
#include "DailyStop.mqh"

input group "3. Orders"
input int             InpMaxSpreadPoints  = 30;       // Max spread, points (0 = off)
input int             InpDeviationPoints  = 10;       // Max slippage, points

input group "4. Identity and logs"
input ulong           InpMagicNumber      = 20261020; // Magic number (unique per EA)
input string          InpTradeComment     = "MajorFX DonchianTrend"; // Order comment

input group "5. Strategy"
input ENUM_TIMEFRAMES InpSignalTimeframe = PERIOD_H4; // Signal timeframe
input int             InpDonchianPeriod  = 10;        // Channel length, bars
input double          InpBreakoutBufferATR = 0.00;    // Breakout buffer, x ATR (0 = off)
input bool            InpRequireSignalCandleDirection = true; // Buy only on an up candle, sell on a down one
input bool            InpAllowLong  = true;           // Allow buys
input bool            InpAllowShort = false;          // Allow sells
input bool            InpOnePositionPerSymbol = true; // One trade at a time on this symbol

input group "6. Filters"
input int             InpFastEMAPeriod = 50;          // Trend filter: fast EMA period
input int             InpSlowEMAPeriod = 200;         // Trend filter: slow EMA period
input bool            InpUseADXFilter  = true;        // Use ADX filter
input int             InpADXPeriod     = 14;          // ADX filter: period
input double          InpMinADX        = 20.0;        // ADX filter: minimum value

input group "7. Exits"
input int             InpATRPeriod        = 14;       // Stop loss: ATR period (also breakout buffer)
input double          InpATRStopMultiplier = 1.5;     // Stop loss: distance, x ATR
input double          InpRewardRiskRatio  = 1.5;      // Take profit, x stop distance

int      g_fastMAHandle = INVALID_HANDLE;
int      g_slowMAHandle = INVALID_HANDLE;
int      g_atrHandle    = INVALID_HANDLE;
int      g_adxHandle    = INVALID_HANDLE;
datetime g_lastBarTime  = 0;

//+------------------------------------------------------------------+
//| Expert initialization                                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpDonchianPeriod < 2 || InpFastEMAPeriod < 1 || InpSlowEMAPeriod < 2 ||
      InpATRPeriod < 1 || InpATRStopMultiplier <= 0.0 || InpRewardRiskRatio <= 0.0 ||
      InpRiskPercent <= 0.0 || InpRiskPercent > 10.0 || InpBreakoutBufferATR < 0.0 ||
      InpADXPeriod < 1 || InpMinADX < 0.0)
     {
      Print("Initialization failed: one or more inputs are outside the accepted range.");
      return INIT_PARAMETERS_INCORRECT;
     }

   g_fastMAHandle = iMA(_Symbol, InpSignalTimeframe, InpFastEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_slowMAHandle = iMA(_Symbol, InpSignalTimeframe, InpSlowEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   g_atrHandle    = iATR(_Symbol, InpSignalTimeframe, InpATRPeriod);
   if(InpUseADXFilter)
      g_adxHandle = iADX(_Symbol, InpSignalTimeframe, InpADXPeriod);

   if(g_fastMAHandle == INVALID_HANDLE || g_slowMAHandle == INVALID_HANDLE ||
      g_atrHandle == INVALID_HANDLE || (InpUseADXFilter && g_adxHandle == INVALID_HANDLE))
     {
      PrintFormat("Initialization failed while creating indicators. Error=%d", GetLastError());
      return INIT_FAILED;
     }

   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetAsyncMode(false);

   // Prevent an entry on the already-open candle immediately after attaching the EA.
   g_lastBarTime = iTime(_Symbol, InpSignalTimeframe, 0);

   PrintFormat("MajorFX DonchianTrend initialized: symbol=%s, signal timeframe=%s, risk=%.2f%%, RR=%.2f",
               _Symbol, EnumToString(InpSignalTimeframe), InpRiskPercent, InpRewardRiskRatio);
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(g_fastMAHandle != INVALID_HANDLE) IndicatorRelease(g_fastMAHandle);
   if(g_slowMAHandle != INVALID_HANDLE) IndicatorRelease(g_slowMAHandle);
   if(g_atrHandle    != INVALID_HANDLE) IndicatorRelease(g_atrHandle);
   if(g_adxHandle    != INVALID_HANDLE) IndicatorRelease(g_adxHandle);
  }

//+------------------------------------------------------------------+
//| Tick handler: evaluate only once per new signal-timeframe bar     |
//+------------------------------------------------------------------+
void OnTick()
  {
   const bool stopped = DailyStop(InpMagicNumber);   // every tick: closes own positions while the stop is on
   if(!IsNewSignalBar() || stopped)
      return;

   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) || !MQLInfoInteger(MQL_TRADE_ALLOWED))
     {
      Print("Trading is disabled in the terminal or EA settings.");
      return;
     }

   if(Bars(_Symbol, InpSignalTimeframe) < InpSlowEMAPeriod + InpDonchianPeriod + 10)
     {
      Print("Not enough historical bars yet for the selected indicators.");
      return;
     }

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || tick.ask <= 0.0 || tick.bid <= 0.0)
     {
      Print("Could not retrieve a valid current quote.");
      return;
     }

   double spreadPoints = (tick.ask - tick.bid) / _Point;
   if(InpMaxSpreadPoints > 0 && spreadPoints > InpMaxSpreadPoints)
     {
      PrintFormat("Signal skipped: spread %.1f points exceeds limit %d.", spreadPoints, InpMaxSpreadPoints);
      return;
     }

   if(InpOnePositionPerSymbol && HasOpenPositionOnSymbol())
      return;

   int signal = GetEntrySignal(); // +1 buy, -1 sell, 0 no signal
   if(signal == 0)
      return;

   if(signal > 0 && !InpAllowLong)  return;
   if(signal < 0 && !InpAllowShort) return;

   ExecuteEntry(signal, tick);
  }

//+------------------------------------------------------------------+
//| New bar detector                                                  |
//+------------------------------------------------------------------+
bool IsNewSignalBar()
  {
   datetime barTime = iTime(_Symbol, InpSignalTimeframe, 0);
   if(barTime <= 0)
      return false;
   if(barTime == g_lastBarTime)
      return false;
   g_lastBarTime = barTime;
   return true;
  }

//+------------------------------------------------------------------+
//| Read a single indicator-buffer value                              |
//+------------------------------------------------------------------+
bool ReadIndicatorValue(const int handle, const int bufferNumber, const int shift, double &value)
  {
   if(handle == INVALID_HANDLE)
      return false;

   double data[1];
   ResetLastError();
   int copied = CopyBuffer(handle, bufferNumber, shift, 1, data);
   if(copied != 1)
     {
      PrintFormat("CopyBuffer failed: handle=%d, buffer=%d, shift=%d, copied=%d, error=%d",
                  handle, bufferNumber, shift, copied, GetLastError());
      return false;
     }
   value = data[0];
   return (value != EMPTY_VALUE && MathIsValidNumber(value));
  }

//+------------------------------------------------------------------+
//| Entry logic: closed-bar Donchian breakout + EMA trend + optional ADX|
//+------------------------------------------------------------------+
int GetEntrySignal()
  {
   // Shift 1 is the most recently closed candle. The channel excludes it.
   double signalOpen  = iOpen(_Symbol, InpSignalTimeframe, 1);
   double signalClose = iClose(_Symbol, InpSignalTimeframe, 1);
   if(signalOpen <= 0.0 || signalClose <= 0.0)
      return 0;

   double priorHighest = -DBL_MAX;
   double priorLowest  = DBL_MAX;
   for(int shift = 2; shift <= InpDonchianPeriod + 1; shift++)
     {
      double barHigh = iHigh(_Symbol, InpSignalTimeframe, shift);
      double barLow  = iLow(_Symbol, InpSignalTimeframe, shift);
      if(barHigh <= 0.0 || barLow <= 0.0)
         return 0;
      if(barHigh > priorHighest) priorHighest = barHigh;
      if(barLow  < priorLowest)  priorLowest  = barLow;
     }

   double fastMA, slowMA, atrValue;
   if(!ReadIndicatorValue(g_fastMAHandle, 0, 1, fastMA) ||
      !ReadIndicatorValue(g_slowMAHandle, 0, 1, slowMA) ||
      !ReadIndicatorValue(g_atrHandle, 0, 1, atrValue))
      return 0;
   if(atrValue <= 0.0)
      return 0;

   double breakoutBuffer = atrValue * InpBreakoutBufferATR;
   bool bullishCandle = (signalClose > signalOpen);
   bool bearishCandle = (signalClose < signalOpen);

   bool adxPass = true;
   if(InpUseADXFilter)
     {
      double adxValue;
      // iADX buffer 0 is the main ADX line.
      if(!ReadIndicatorValue(g_adxHandle, 0, 1, adxValue))
         return 0;
      adxPass = (adxValue >= InpMinADX);
     }

   bool buyBreakout  = (signalClose > priorHighest + breakoutBuffer);
   bool sellBreakout = (signalClose < priorLowest  - breakoutBuffer);
   bool buyTrend     = (fastMA > slowMA);
   bool sellTrend    = (fastMA < slowMA);

   if(InpAllowLong && buyBreakout && buyTrend && adxPass &&
      (!InpRequireSignalCandleDirection || bullishCandle))
     {
      PrintFormat("BUY signal: close=%.*f, prior high=%.*f, EMA%d=%.*f > EMA%d=%.*f",
                  _Digits, signalClose, _Digits, priorHighest,
                  InpFastEMAPeriod, _Digits, fastMA, InpSlowEMAPeriod, _Digits, slowMA);
      return 1;
     }

   if(InpAllowShort && sellBreakout && sellTrend && adxPass &&
      (!InpRequireSignalCandleDirection || bearishCandle))
     {
      PrintFormat("SELL signal: close=%.*f, prior low=%.*f, EMA%d=%.*f < EMA%d=%.*f",
                  _Digits, signalClose, _Digits, priorLowest,
                  InpFastEMAPeriod, _Digits, fastMA, InpSlowEMAPeriod, _Digits, slowMA);
      return -1;
     }

   return 0;
  }

//+------------------------------------------------------------------+
//| Calculate volume from account-equity risk and actual SL distance   |
//+------------------------------------------------------------------+
double CalculatePositionVolume(const ENUM_ORDER_TYPE orderType,
                               const double entryPrice,
                               const double stopLossPrice)
  {
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity <= 0.0)
      return 0.0;

   double riskMoney = equity * InpRiskPercent / 100.0 * ThrottleFactor();   // AccountThrottle.mqh (spec 2026-10-22-dd-reduction)
   double lossForOneLot = 0.0;
   ResetLastError();
   if(!OrderCalcProfit(orderType, _Symbol, 1.0, entryPrice, stopLossPrice, lossForOneLot))
     {
      PrintFormat("OrderCalcProfit failed while sizing the trade. Error=%d", GetLastError());
      return 0.0;
     }

   double riskPerLot = MathAbs(lossForOneLot);
   if(riskPerLot <= 0.0 || !MathIsValidNumber(riskPerLot))
      return 0.0;

   double rawVolume = riskMoney / riskPerLot;
   double volumeMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double volumeMax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double volumeStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(volumeMin <= 0.0 || volumeMax <= 0.0 || volumeStep <= 0.0)
     {
      Print("Invalid symbol volume constraints.");
      return 0.0;
     }

   if(rawVolume < volumeMin)
     {
      if(InpSkipIfMinLotTooRisky)
        {
         PrintFormat("Trade skipped: risk-based volume %.6f is below minimum lot %.6f; minimum lot could exceed target risk.",
                     rawVolume, volumeMin);
         return 0.0;
        }
      rawVolume = volumeMin;
     }

   double cappedVolume = MathMin(rawVolume, volumeMax);
   double steppedVolume = MathFloor(cappedVolume / volumeStep + 1e-9) * volumeStep;
   int volumeDigits = GetVolumeDigits(volumeStep);
   steppedVolume = NormalizeDouble(steppedVolume, volumeDigits);

   if(steppedVolume < volumeMin)
      return 0.0;

   return steppedVolume;
  }

//+------------------------------------------------------------------+
//| Determine precision for volume step                               |
//+------------------------------------------------------------------+
int GetVolumeDigits(const double step)
  {
   for(int digits = 0; digits <= 8; digits++)
     {
      if(MathAbs(step - NormalizeDouble(step, digits)) < 1e-10)
         return digits;
     }
   return 8;
  }

//+------------------------------------------------------------------+
//| Round a price to the instrument's trade tick size                  |
//+------------------------------------------------------------------+
double NormalizePriceToTick(const double price)
  {
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0.0)
      tickSize = _Point;
   double rounded = MathRound(price / tickSize) * tickSize;
   return NormalizeDouble(rounded, _Digits);
  }

//+------------------------------------------------------------------+
//| Entry execution                                                    |
//+------------------------------------------------------------------+
void ExecuteEntry(const int signal, const MqlTick &tick)
  {
   double atrValue;
   if(!ReadIndicatorValue(g_atrHandle, 0, 1, atrValue) || atrValue <= 0.0)
      return;

   double entryPrice = (signal > 0 ? tick.ask : tick.bid);
   double stopDistance = atrValue * InpATRStopMultiplier;

   // Respect broker minimum stop distance, allowing one additional tick.
   long stopsLevelPoints = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0.0) tickSize = _Point;
   double minStopDistance = (double)stopsLevelPoints * _Point;
   if(stopDistance < minStopDistance + tickSize)
      stopDistance = minStopDistance + tickSize;

   double sl, tp;
   if(signal > 0)
     {
      sl = NormalizePriceToTick(entryPrice - stopDistance);
      tp = NormalizePriceToTick(entryPrice + stopDistance * InpRewardRiskRatio);
     }
   else
     {
      sl = NormalizePriceToTick(entryPrice + stopDistance);
      tp = NormalizePriceToTick(entryPrice - stopDistance * InpRewardRiskRatio);
     }

   // Verify levels remain on the correct side after tick-size rounding.
   if(signal > 0 && !(sl < entryPrice && tp > entryPrice))
     {
      Print("BUY skipped: calculated SL/TP are invalid after price normalization.");
      return;
     }
   if(signal < 0 && !(sl > entryPrice && tp < entryPrice))
     {
      Print("SELL skipped: calculated SL/TP are invalid after price normalization.");
      return;
     }

   ENUM_ORDER_TYPE orderType = (signal > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   double volume = CalculatePositionVolume(orderType, entryPrice, sl);
   if(volume <= 0.0)
     {
      Print("Trade skipped because a valid position volume could not be calculated.");
      return;
     }

   bool requestAccepted = false;
   if(signal > 0)
      requestAccepted = trade.Buy(volume, _Symbol, 0.0, sl, tp, InpTradeComment);
   else
      requestAccepted = trade.Sell(volume, _Symbol, 0.0, sl, tp, InpTradeComment);

   uint retcode = trade.ResultRetcode();
   bool serverAccepted = (retcode == TRADE_RETCODE_DONE ||
                          retcode == TRADE_RETCODE_DONE_PARTIAL ||
                          retcode == TRADE_RETCODE_PLACED);

   if(!requestAccepted || !serverAccepted)
     {
      PrintFormat("Order failed. requestAccepted=%s, retcode=%u (%s), volume=%.4f, SL=%.*f, TP=%.*f",
                  (requestAccepted ? "true" : "false"), retcode, trade.ResultRetcodeDescription(),
                  volume, _Digits, sl, _Digits, tp);
      return;
     }

   PrintFormat("Order placed: %s %s, volume=%.4f, entry~%.*f, SL=%.*f, TP=%.*f, target risk=%.2f%%, RR=%.2f",
               (signal > 0 ? "BUY" : "SELL"), _Symbol, volume,
               _Digits, entryPrice, _Digits, sl, _Digits, tp,
               InpRiskPercent, InpRewardRiskRatio);
  }

//+------------------------------------------------------------------+
//| Optional one-position-per-symbol guard                            |
//+------------------------------------------------------------------+
bool HasOpenPositionOnSymbol()
  {
   for(int index = PositionsTotal() - 1; index >= 0; index--)
     {
      ulong ticket = PositionGetTicket(index);
      if(ticket == 0)
         continue;
      string positionSymbol = PositionGetString(POSITION_SYMBOL);
      if(positionSymbol == _Symbol)
         return true;
     }
   return false;
  }
//+------------------------------------------------------------------+

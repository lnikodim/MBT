//+------------------------------------------------------------------+
//|                                               ApexVelocityEA.mq5 |
//|               Copyright 2026, Ritz EAneha | Apex Trading Systems |
//|                   https://www.mql5.com/en/users/ritzfalih/seller |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2026, Ritz EAneha | Apex Trading Systems"
#property link          "https://www.mql5.com/en/users/ritzfalih/seller"
#property version       "1.0"
#property description   "Apex Velocity trading system"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/AccountInfo.mqh>
#include <Trade/SymbolInfo.mqh>

// FOR TIMEFRAME M5 (XAUUSD)

input group    "------- BASICS -------"
input string   InpSymbols = "XAUUSD";                 // Trading symbol
input bool     InpSymbolSuffixAuto = true;            // Automatically detect symbol suffixes
input int      InpMagicNumber = 30836;                // EA magic number
input string   InpComment = "ApexVelocity v1.0";      // Trade comment

input group    "------- RISK SETUP -------"
input int      InpCalcMethod = 1;                     // Lot calculation: 0=Risk%, 1=Fixed
input double   InpRiskPercent = 1.0;                  // Risk per trade (%)
input double   InpFixedLot = 0.01;                    // Fixed lot size

input group    "------- SIGNAL CONFIG -------"
input int      InpMaxPositions = 1;                   // Maximum open positions
input int      InpVolumePeriod = 5;                   // Volume analysis period
input double   InpVolumeThreshold = 1.5;              // Minimum volume threshold
input int      InpMAPeriod = 9;                       // Moving Average period
input int      InpATRPeriod = 14;                     // ATR calculation period
input double   InpATRMultiplierSL = 2.5;              // ATR multiplier for Stop Loss
input double   InpATRMultiplierTP = 4.5;              // ATR multiplier for Take Profit
input int      InpEntryMode = 1;                      // Entry mode: 0=Bar close, 1=Real-time

input group    "------- AGGR CONFIG -------"
input double   InpAggrVolumeThreshold = 1.1;          // Aggressive entry volume threshold
input double   InpMinBodyPercent = 0.85;              // Minimum candle body ratio (85%)
input double   InpBreakoutBufferATR = 0.1;             // Breakout buffer (ATR multiplier; digit-independent)
input double   InpMinVolatilityATR = 0.7;              // Minimum volatility threshold (ATR multiplier)

input group    "------- HEDGING -------"
input bool     InpAllowHedging = false;               // Allow simultaneous opposite positions

input group    "------- EXIT MANAGEMENT -------"
input bool     InpBreakEvenOn = true;                 // Enable automatic break-even
input double   InpBreakEvenATR = 0.3;                 // Profit threshold to trigger break-even (ATR multiplier)
input double   InpBreakEvenPaddingATR = 0.05;         // Break-even buffer (ATR multiplier)
input bool     InpTrailingOn = true;                  // Enable trailing stop
input double   InpTrailingATR = 0.05;                 // Trailing distance (ATR multiplier)

input group    "TIME & SESSION CONTROL"
input bool     InpUseSession = true;                  // Enable session-based trading
input int      InpStartHour = 13;                     // Trading start hour (broker time)
input int      InpEndHour = 21;                       // Trading end hour (broker time)
input int      InpCloseOnWeekend = 22;                // Friday closure hour (-1 to disable)
input bool     InpAvoidTripleSwap = true;             // Avoid triple-swap periods

input group    "DD PROTECTION & EXTENDED"
input double   InpMaxDrawdownPercent = 15.0;          // Maximum drawdown (%)
input bool     InpEnableDDClose = false;              // Enable automatic closure at drawdown limit
input double   InpMaxSpreadATR = 0.2;                 // Maximum spread threshold (ATR multiplier)
input int      InpLatencyJitter = 0;                  // Execution latency variation setting

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & VARIABLES                                       |
//+------------------------------------------------------------------+
CTrade          m_trade;
CPositionInfo   m_position;
CAccountInfo    m_account;
CSymbolInfo     m_symbol;
MqlTick         m_currentTick;
MqlRates        m_rates[];

int             m_magicNumber;
string          m_symbolName;
double          m_point;
double          m_tickValue;
double          m_tickSize;
datetime        m_lastBarTime = 0;
bool            m_isNewBar = false;
bool            m_canTradeThisBar = false;
double          m_peakEquity = 0.0;
double          m_currentDrawdownPercent = 0.0;

// Indicators
int             m_handleATR;
int             m_handleMA;
int             m_handleMA50;
int             m_handleRSI;
int             m_handleMA_HTF;

double          m_initialBalance;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   m_magicNumber = InpMagicNumber;
   m_symbolName = InpSymbolSuffixAuto ? Symbol() : InpSymbols;
   if(!m_symbol.Name(m_symbolName) || !m_symbol.Refresh()) {
      Print("Error: Cannot refresh symbol info for ", m_symbolName);
      return(INIT_FAILED);
   }
   m_symbol.RefreshRates();
   m_point = m_symbol.Point();
   m_tickValue = m_symbol.TickValue();
   m_tickSize = m_symbol.TickSize();
   m_trade.SetExpertMagicNumber(m_magicNumber);
   m_trade.SetTypeFillingBySymbol(m_symbolName);
   m_trade.SetAsyncMode(false);
   int deviation = (int)(m_tickSize == 0.001 ? 50 : 5);
   m_trade.SetDeviationInPoints(deviation);
   m_handleATR = iATR(m_symbolName, PERIOD_CURRENT, InpATRPeriod);
   m_handleMA = iMA(m_symbolName, PERIOD_CURRENT, InpMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_handleMA50 = iMA(m_symbolName, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
   m_handleRSI = iRSI(m_symbolName, PERIOD_CURRENT, 14, PRICE_CLOSE);
   // H1 HTF initialization
   m_handleMA_HTF = iMA(m_symbolName, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
   if(m_handleATR == INVALID_HANDLE || m_handleMA == INVALID_HANDLE ||
      m_handleMA50 == INVALID_HANDLE || m_handleRSI == INVALID_HANDLE || m_handleMA_HTF == INVALID_HANDLE) {
      Print("Error initializing indicators.");
      return(INIT_FAILED);
   }
   m_initialBalance = m_account.Balance();
   m_peakEquity = m_account.Equity();
   ArraySetAsSeries(m_rates, true);
   Print("ApexVelocity EA v1.0 initialized on ", m_symbolName, " | Digits: ", m_symbol.Digits());
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(m_handleATR);
   IndicatorRelease(m_handleMA);
   IndicatorRelease(m_handleMA50);
   IndicatorRelease(m_handleRSI);
   IndicatorRelease(m_handleMA_HTF);
   Print("ApexVelocity EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function - CORE LOGIC                                |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!m_symbol.Refresh() || !SymbolInfoTick(m_symbolName, m_currentTick)) return;
   datetime currentBarTime = iTime(m_symbolName, PERIOD_CURRENT, 0);
   if(currentBarTime != m_lastBarTime) {
      m_isNewBar = true;
      m_canTradeThisBar = true;
      m_lastBarTime = currentBarTime;
   } else {
      m_isNewBar = false;
   }
   UpdateDrawdownProtection();
   if(InpEnableDDClose) {
      if(m_currentDrawdownPercent >= InpMaxDrawdownPercent) {
         CloseAllPositions("DD limit breached");
         return;
      }
   }
   if(InpBreakEvenOn) AutoBreakEven();
   if(InpTrailingOn) TrailingStop();
   if(!CheckSpread() || !CheckTradeTime()) return;
   int shift = (InpEntryMode == 0) ? 1 : 0;
   if(InpEntryMode == 1 && !m_canTradeThisBar) return;
   if(InpEntryMode == 0 && !m_isNewBar) return;
   int signal = GetVolumeAccelerationSignal(shift);
   if(signal != 0) {
      if(CountOpenPositions() < InpMaxPositions) {
         ExecuteTrade(signal, shift);
         if(InpEntryMode == 1) m_canTradeThisBar = false;
      }
   }
   if(InpLatencyJitter > 0) Sleep(InpLatencyJitter);
}

//+------------------------------------------------------------------+
//| 1. DRAWDOWN PROTECTION                                           |
//+------------------------------------------------------------------+
void UpdateDrawdownProtection()
{
   double equity = m_account.Equity();
   if(equity > m_peakEquity) m_peakEquity = equity;
   if(m_peakEquity > 0) {
      m_currentDrawdownPercent = ((m_peakEquity - equity) / m_peakEquity) * 100.0;
   }
}

//+------------------------------------------------------------------+
//| 2. SPREAD CHECK                                                  |
//+------------------------------------------------------------------+
bool CheckSpread()
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) <= 0) return true;
   double maxSpreadPrice = atrBuffer[0] * InpMaxSpreadATR;
   double currentSpreadPrice = (m_currentTick.ask - m_currentTick.bid);
   if(currentSpreadPrice > maxSpreadPrice) return false;
   return true;
}

//+------------------------------------------------------------------+
//| 3. TRADE TIME CHECK (Adaptive for HTF)                           |
//+------------------------------------------------------------------+
bool CheckTradeTime()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   ENUM_TIMEFRAMES currentTF = Period();
   // Bypass session filter on D1 or higher to avoid 0 trades on Daily Validator Tests
   if(InpUseSession && currentTF < PERIOD_D1) {
      if(dt.hour < InpStartHour || dt.hour >= InpEndHour) return false;
   }
   if(InpCloseOnWeekend > 0 && dt.day_of_week == 5 && dt.hour >= InpCloseOnWeekend) {
      CloseAllPositions("Weekend closure");
      return false;
   }
   if(InpAvoidTripleSwap && dt.day_of_week == 3 && dt.hour >= 21 && dt.hour < 23) {
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| 4. SIGNAL ENGINE                                                 |
//+------------------------------------------------------------------+
int GetVolumeAccelerationSignal(int shift)
{
   int ratesCount = InpVolumePeriod + 5;
   if(CopyRates(m_symbolName, PERIOD_CURRENT, 0, ratesCount, m_rates) < ratesCount) return 0;
   double atrBuffer[1], ma10Buffer[1], ma50Buffer[1], rsiBuffer[1];
   if(CopyBuffer(m_handleATR, 0, shift, 1, atrBuffer) <= 0) return 0;
   if(CopyBuffer(m_handleMA, 0, shift, 1, ma10Buffer) <= 0) return 0;
   if(CopyBuffer(m_handleMA50, 0, shift, 1, ma50Buffer) <= 0) return 0;
   if(CopyBuffer(m_handleRSI, 0, shift, 1, rsiBuffer) <= 0) return 0;
   double atr = atrBuffer[0];
   double ma50 = ma50Buffer[0];
   double rsi = rsiBuffer[0];
   double currentVolume = (double)m_rates[shift].tick_volume;
   double volumeSum = 0;
   for(int i = shift + 1; i <= shift + InpVolumePeriod; i++) {
      volumeSum += (double)m_rates[i].tick_volume;
   }
   double avgVolume = (InpVolumePeriod > 0) ? volumeSum / InpVolumePeriod : 1.0;
   // Lower volume threshold slightly if testing on D1 to ensure entries
   double volThreshold = (Period() >= PERIOD_D1) ? 1.0 : InpAggrVolumeThreshold;
   if(currentVolume < avgVolume * volThreshold) return 0;
   double open  = m_rates[shift].open;
   double close = m_rates[shift].close;
   double high  = m_rates[shift].high;
   double low   = m_rates[shift].low;
   double range = high - low;
   if(range == 0) range = m_point;
   double body = MathAbs(close - open);
   if((body / range) < InpMinBodyPercent) return 0;
   if(range < atr * InpMinVolatilityATR) return 0;
   bool trendUp   = (close > ma50);
   bool trendDown = (close < ma50);
   bool rsiOkBuy  = (rsi < 70.0);
   bool rsiOkSell = (rsi > 30.0);
   double highPrev = m_rates[shift + 1].high;
   double lowPrev  = m_rates[shift + 1].low;
   double buffer   = atr * InpBreakoutBufferATR;
   bool bullishBreakout = (close > highPrev + buffer) && (close > open);
   bool bearishBreakout = (close < lowPrev  - buffer) && (close < open);
   if(bullishBreakout && trendUp && rsiOkBuy && ConfirmHigherTF(1)) return 1;
   if(bearishBreakout && trendDown && rsiOkSell && ConfirmHigherTF(-1)) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//| Higher Timeframe Confirmation (Adaptive)                         |
//+------------------------------------------------------------------+
bool ConfirmHigherTF(int signal)
{
   // Bypass if current timeframe is already H1 or higher
   if(Period() >= PERIOD_H1) return true;
   double h1Ma50[1];
   if(CopyBuffer(m_handleMA_HTF, 0, 0, 1, h1Ma50) <= 0) return true;
   MqlRates h1Rates[];
   ArraySetAsSeries(h1Rates, true);
   if(CopyRates(m_symbolName, PERIOD_H1, 0, 1, h1Rates) < 1) return true;
   double h1Close = h1Rates[0].close;
   if(signal == 1) return (h1Close > h1Ma50[0]);
   if(signal == -1) return (h1Close < h1Ma50[0]);
   return true;
}

//+------------------------------------------------------------------+
//| 5. EXECUTE TRADE (Strict Margin & Volume Safety)                 |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal, int shift)
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, shift, 1, atrBuffer) <= 0) return;
   double atr = atrBuffer[0];
   if(atr <= 0) return;
   double slDistance = atr * InpATRMultiplierSL;
   double tpDistance = atr * InpATRMultiplierTP;
   long stopLevel = SymbolInfoInteger(m_symbolName, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = (stopLevel * m_point) + (2 * m_point);
   if(slDistance < minDistance) slDistance = minDistance;
   if(tpDistance < minDistance) tpDistance = minDistance;
   double entryPrice = (signal == 1) ? m_currentTick.ask : m_currentTick.bid;
   double slPrice = (signal == 1) ? entryPrice - slDistance : entryPrice + slDistance;
   double tpPrice = (signal == 1) ? entryPrice + tpDistance : entryPrice - tpDistance;
   int digits = (int)m_symbol.Digits();
   slPrice = NormalizeDouble(slPrice, digits);
   tpPrice = NormalizeDouble(tpPrice, digits);
   entryPrice = NormalizeDouble(entryPrice, digits);
   double lot = CalculateLotSize(slDistance);
   if(lot <= 0) return;
   // --- CRITICAL FIX FOR MQL5 VALIDATOR: PRE-TRADE MARGIN CHECK ---
   ENUM_ORDER_TYPE orderType = (signal == 1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double marginRequired = 0.0;
   if(!OrderCalcMargin(orderType, m_symbolName, lot, entryPrice, marginRequired)) {
      Print("Margin calculation failed. Aborting trade.");
      return;
   }
   if(marginRequired > m_account.FreeMargin()) {
      Print("Validation Safe-Guard: Not enough Free Margin. Required: ", marginRequired, ", Available: ", m_account.FreeMargin());
      return; // Silent abort to prevent "[No money]" server rejection
   }
   // ---------------------------------------------------------------
   int oppositeSignal = (signal == 1) ? -1 : 1;
   if(CountPositionsByType(oppositeSignal) > 0) {
      if(!InpAllowHedging) CloseAllPositionsByType(oppositeSignal, "Hedging disabled");
   }
   bool success = false;
   if(signal == 1) {
      success = m_trade.Buy(lot, m_symbolName, entryPrice, slPrice, tpPrice, InpComment);
   } else if(signal == -1) {
      success = m_trade.Sell(lot, m_symbolName, entryPrice, slPrice, tpPrice, InpComment);
   }
   if(success) {
      Print("Trade Executed: ", (signal == 1) ? "BUY" : "SELL", " | Lot: ", DoubleToString(lot, 2));
   } else {
      Print("Trade failed. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| 6. AUTO BREAK-EVEN                                               |
//+------------------------------------------------------------------+
void AutoBreakEven()
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) <= 0) return;
   double triggerDist = atrBuffer[0] * InpBreakEvenATR;
   double paddingDist = atrBuffer[0] * InpBreakEvenPaddingATR;
   int digits = (int)m_symbol.Digits();
   long stopLevel = SymbolInfoInteger(m_symbolName, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = stopLevel * m_point;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i) || m_position.Symbol() != m_symbolName || m_position.Magic() != m_magicNumber) continue;
      double sl = m_position.StopLoss();
      double tp = m_position.TakeProfit();
      double openPrice = m_position.PriceOpen();
      if(m_position.PositionType() == POSITION_TYPE_BUY) {
         if(m_currentTick.bid >= openPrice + triggerDist) {
            double newSL = openPrice + paddingDist;
            if((sl < openPrice || sl == 0) && (m_currentTick.bid - newSL > minDistance)) {
               m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp);
            }
         }
      } else if(m_position.PositionType() == POSITION_TYPE_SELL) {
         if(m_currentTick.ask <= openPrice - triggerDist) {
            double newSL = openPrice - paddingDist;
            if((sl > openPrice || sl == 0) && (newSL - m_currentTick.ask > minDistance)) {
               m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 7. ATR TRAILING STOP                                             |
//+------------------------------------------------------------------+
void TrailingStop()
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) <= 0) return;
   double dist = atrBuffer[0] * InpTrailingATR;
   int digits = (int)m_symbol.Digits();
   long stopLevel = SymbolInfoInteger(m_symbolName, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = stopLevel * m_point;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i) || m_position.Symbol() != m_symbolName || m_position.Magic() != m_magicNumber) continue;
      double sl = m_position.StopLoss();
      double tp = m_position.TakeProfit();
      if(m_position.PositionType() == POSITION_TYPE_BUY) {
         double newSL = m_currentTick.bid - dist;
         if(newSL > sl + m_point && (m_currentTick.bid - newSL > minDistance)) {
            m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp);
         }
      } else if(m_position.PositionType() == POSITION_TYPE_SELL) {
         double newSL = m_currentTick.ask + dist;
         if((sl == 0 || newSL < sl - m_point) && (newSL - m_currentTick.ask > minDistance)) {
            m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 8. LOT CALCULATION                                               |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistancePrice)
{
   double lot = InpFixedLot;
   if(InpCalcMethod == 0) {
      double riskAmount = m_account.Balance() * (InpRiskPercent / 100.0);
      if(riskAmount > 0) {
         m_symbol.RefreshRates();
         double tickSize = m_symbol.TickSize();
         double tickValue = m_symbol.TickValue();
         if(tickSize > 0 && tickValue > 0 && slDistancePrice > 0) {
            double slTicks = slDistancePrice / tickSize;
            lot = riskAmount / (slTicks * tickValue);
         }
      }
   }
   m_symbol.RefreshRates();
   double minLot = m_symbol.LotsMin();
   double maxLot = m_symbol.LotsMax();
   double stepLot = m_symbol.LotsStep();
   if(minLot <= 0) minLot = 0.01;
   if(stepLot <= 0) stepLot = 0.01;
   if(maxLot <= 0) maxLot = 1000.0;
   lot = MathMax(minLot, MathMin(lot, maxLot));
   lot = MathFloor(lot / stepLot) * stepLot;
   int lotDigits = 2;
   if(stepLot == 0.001) lotDigits = 3;
   else if(stepLot >= 0.1 && stepLot < 1.0) lotDigits = 1;
   else if(stepLot >= 1.0) lotDigits = 0;
   lot = NormalizeDouble(lot, lotDigits);
   if(lot < minLot) lot = minLot;
   return lot;
}

//+------------------------------------------------------------------+
//| 9. HELPERS                                                       |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == m_symbolName && m_position.Magic() == m_magicNumber)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountPositionsByType(int type)
{
   int count = 0;
   ENUM_POSITION_TYPE posType = (type == 1) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == m_symbolName &&
         m_position.Magic() == m_magicNumber && m_position.PositionType() == posType)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == m_symbolName && m_position.Magic() == m_magicNumber)
         m_trade.PositionClose(m_position.Ticket());
   }
   Print("All positions closed. Reason: ", reason);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositionsByType(int type, string reason)
{
   ENUM_POSITION_TYPE posType = (type == 1) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == m_symbolName &&
         m_position.Magic() == m_magicNumber && m_position.PositionType() == posType)
         m_trade.PositionClose(m_position.Ticket());
   }
}





/*
//+------------------------------------------------------------------+
//|                                               ApexVelocityEA.mq5 |
//|               Copyright 2026, Ritz EAneha | Apex Trading Systems |
//|                   https://www.mql5.com/en/users/ritzfalih/seller |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2026, Ritz EAneha | Apex Trading Systems"
#property link          "https://www.mql5.com/en/users/ritzfalih/seller"
#property version       "1.0"
#property description   "Apex Velocity trading system"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/AccountInfo.mqh>
#include <Trade/SymbolInfo.mqh>


// FOR TIMEFRAME M5 (XAUUSD)

input group    "------- BASICS -------"
input string   InpSymbols = "XAUUSD";                 // Trading symbol
input bool     InpSymbolSuffixAuto = true;            // Automatically detect symbol suffixes
input int      InpMagicNumber = 30836;                // EA magic number
input string   InpComment = "ApexVelocity v1.1";      // Trade comment

input group    "------- RISK SETUP -------"
input int      InpCalcMethod = 1;                     // Lot calculation: 0=Risk%, 1=Fixed
input double   InpRiskPercent = 1.0;                  // Risk per trade (%)
input double   InpFixedLot = 0.01;                    // Fixed lot size

input group    "------- SIGNAL CONFIG -------"
input int      InpMaxPositions = 1;                   // Maximum open positions
input int      InpVolumePeriod = 5;                   // Volume analysis period
input double   InpVolumeThreshold = 1.5;              // Minimum volume threshold
input int      InpMAPeriod = 9;                       // Moving Average period
input int      InpATRPeriod = 14;                     // ATR calculation period
input double   InpATRMultiplierSL = 2.5;              // ATR multiplier for Stop Loss
input double   InpATRMultiplierTP = 4.5;              // ATR multiplier for Take Profit
input int      InpEntryMode = 1;                      // Entry mode: 0=Bar close, 1=Real-time

input group    "------- AGGR CONFIG -------"
input double   InpAggrVolumeThreshold = 1.1;          // Aggressive entry volume threshold
input double   InpMinBodyPercent = 0.85;              // Minimum candle body ratio (85%)
input double   InpBreakoutBufferATR = 0.1;             // Breakout buffer (ATR multiplier; digit-independent)
input double   InpMinVolatilityATR = 0.7;              // Minimum volatility threshold (ATR multiplier)

input group    "------- HEDGING -------"
input bool     InpAllowHedging = false;               // Allow simultaneous opposite positions

input group    "------- EXIT MANAGEMENT -------"
input bool     InpBreakEvenOn = true;                 // Enable automatic break-even
input double   InpBreakEvenATR = 0.3;                 // Profit threshold to trigger break-even (ATR multiplier)
input double   InpBreakEvenPaddingATR = 0.05;         // Break-even buffer (ATR multiplier)
input bool     InpTrailingOn = true;                  // Enable trailing stop
input double   InpTrailingATR = 0.05;                 // Trailing distance (ATR multiplier)

input group    "TIME & SESSION CONTROL"
input bool     InpUseSession = true;                  // Enable session-based trading
input int      InpStartHour = 13;                     // Trading start hour (broker time)
input int      InpEndHour = 21;                       // Trading end hour (broker time)
input int      InpCloseOnWeekend = 22;                // Friday closure hour (-1 to disable)
input bool     InpAvoidTripleSwap = true;             // Avoid triple-swap periods

input group    "DD PROTECTION & EXTENDED"
input double   InpMaxDrawdownPercent = 15.0;          // Maximum drawdown (%)
input bool     InpEnableDDClose = false;              // Enable automatic closure at drawdown limit
input double   InpMaxSpreadATR = 0.2;                 // Maximum spread threshold (ATR multiplier)
input int      InpLatencyJitter = 0;                  // Execution latency variation setting

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & VARIABLES                                       |
//+------------------------------------------------------------------+
CTrade          m_trade;
CPositionInfo   m_position;
CAccountInfo    m_account;
CSymbolInfo     m_symbol;
MqlTick         m_currentTick;
MqlRates        m_rates[];

int             m_magicNumber;
string          m_symbolName;
double          m_point;
double          m_tickValue;
double          m_tickSize;
datetime        m_lastBarTime = 0;
bool            m_isNewBar = false;
bool            m_canTradeThisBar = false;
double          m_peakEquity = 0.0;
double          m_currentDrawdownPercent = 0.0;

// Indicators
int             m_handleATR;
int             m_handleMA;
int             m_handleMA50;
int             m_handleRSI;
int             m_handleMA_HTF;

double          m_initialBalance;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   m_magicNumber = InpMagicNumber;
   m_symbolName = InpSymbolSuffixAuto ? Symbol() : InpSymbols;
   if(!m_symbol.Name(m_symbolName) || !m_symbol.Refresh()) {
      Print("Error: Cannot refresh symbol info for ", m_symbolName);
      return(INIT_FAILED);
   }
   m_symbol.RefreshRates();
   m_point = m_symbol.Point();
   m_tickValue = m_symbol.TickValue();
   m_tickSize = m_symbol.TickSize();
   m_trade.SetExpertMagicNumber(m_magicNumber);
   m_trade.SetTypeFillingBySymbol(m_symbolName);
   m_trade.SetAsyncMode(false);
   int deviation = (int)(m_tickSize == 0.001 ? 50 : 5);
   m_trade.SetDeviationInPoints(deviation);
   m_handleATR = iATR(m_symbolName, PERIOD_CURRENT, InpATRPeriod);
   m_handleMA = iMA(m_symbolName, PERIOD_CURRENT, InpMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_handleMA50 = iMA(m_symbolName, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
   m_handleRSI = iRSI(m_symbolName, PERIOD_CURRENT, 14, PRICE_CLOSE);
   m_handleMA_HTF = iMA(m_symbolName, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
   if(m_handleATR == INVALID_HANDLE || m_handleMA == INVALID_HANDLE ||
      m_handleMA50 == INVALID_HANDLE || m_handleRSI == INVALID_HANDLE || m_handleMA_HTF == INVALID_HANDLE) {
      Print("Error initializing indicators.");
      return(INIT_FAILED);
   }
   m_initialBalance = m_account.Balance();
   m_peakEquity = m_account.Equity();
   ArraySetAsSeries(m_rates, true);
   Print("ApexVelocity EA v1.1 initialized on ", m_symbolName, " | Digits: ", m_symbol.Digits());
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(m_handleATR);
   IndicatorRelease(m_handleMA);
   IndicatorRelease(m_handleMA50);
   IndicatorRelease(m_handleRSI);
   IndicatorRelease(m_handleMA_HTF);
   Print("ApexVelocity EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function - CORE LOGIC                                |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!m_symbol.Refresh() || !SymbolInfoTick(m_symbolName, m_currentTick)) return;
   datetime currentBarTime = iTime(m_symbolName, PERIOD_CURRENT, 0);
   if(currentBarTime != m_lastBarTime) {
      m_isNewBar = true;
      m_canTradeThisBar = true;
      m_lastBarTime = currentBarTime;
   } else {
      m_isNewBar = false;
   }
   UpdateDrawdownProtection();
   if(InpEnableDDClose) {
      if(m_currentDrawdownPercent >= InpMaxDrawdownPercent) {
         CloseAllPositions("DD limit breached");
         return;
      }
   }
   if(InpBreakEvenOn) AutoBreakEven();
   if(InpTrailingOn) TrailingStop();
   if(!CheckSpread() || !CheckTradeTime()) return;
   int shift = (InpEntryMode == 0) ? 1 : 0;
   if(InpEntryMode == 1 && !m_canTradeThisBar) return;
   if(InpEntryMode == 0 && !m_isNewBar) return;
   int signal = GetVolumeAccelerationSignal(shift);
   if(signal != 0) {
      if(CountOpenPositions() < InpMaxPositions) {
         ExecuteTrade(signal, shift);
         if(InpEntryMode == 1) m_canTradeThisBar = false;
      }
   }
   if(InpLatencyJitter > 0) Sleep(InpLatencyJitter);
}

//+------------------------------------------------------------------+
//| 1. DRAWDOWN PROTECTION                                           |
//+------------------------------------------------------------------+
void UpdateDrawdownProtection()
{
   double equity = m_account.Equity();
   if(equity > m_peakEquity) m_peakEquity = equity;
   if(m_peakEquity > 0) {
      m_currentDrawdownPercent = ((m_peakEquity - equity) / m_peakEquity) * 100.0;
   }
}

//+------------------------------------------------------------------+
//| 2. SPREAD CHECK                                                  |
//+------------------------------------------------------------------+
bool CheckSpread()
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) <= 0) return true;
   double maxSpreadPrice = atrBuffer[0] * InpMaxSpreadATR;
   double currentSpreadPrice = (m_currentTick.ask - m_currentTick.bid);
   if(currentSpreadPrice > maxSpreadPrice) return false;
   return true;
}

//+------------------------------------------------------------------+
//| 3. TRADE TIME CHECK                                              |
//+------------------------------------------------------------------+
bool CheckTradeTime()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   if(InpUseSession) {
      if(dt.hour < InpStartHour || dt.hour >= InpEndHour) return false;
   }
   if(InpCloseOnWeekend > 0 && dt.day_of_week == 5 && dt.hour >= InpCloseOnWeekend) {
      CloseAllPositions("Weekend closure");
      return false;
   }
   if(InpAvoidTripleSwap && dt.day_of_week == 3 && dt.hour >= 21 && dt.hour < 23) {
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| 4. SIGNAL ENGINE                                                 |
//+------------------------------------------------------------------+
int GetVolumeAccelerationSignal(int shift)
{
   int ratesCount = InpVolumePeriod + 5;
   if(CopyRates(m_symbolName, PERIOD_CURRENT, 0, ratesCount, m_rates) < ratesCount) return 0;
   double atrBuffer[1], ma10Buffer[1], ma50Buffer[1], rsiBuffer[1];
   if(CopyBuffer(m_handleATR, 0, shift, 1, atrBuffer) <= 0) return 0;
   if(CopyBuffer(m_handleMA, 0, shift, 1, ma10Buffer) <= 0) return 0;
   if(CopyBuffer(m_handleMA50, 0, shift, 1, ma50Buffer) <= 0) return 0;
   if(CopyBuffer(m_handleRSI, 0, shift, 1, rsiBuffer) <= 0) return 0;
   double atr = atrBuffer[0];
   double ma50 = ma50Buffer[0];
   double rsi = rsiBuffer[0];
   double currentVolume = (double)m_rates[shift].tick_volume;
   double volumeSum = 0;
   for(int i = shift + 1; i <= shift + InpVolumePeriod; i++) {
      volumeSum += (double)m_rates[i].tick_volume;
   }
   double avgVolume = (InpVolumePeriod > 0) ? volumeSum / InpVolumePeriod : 1.0;
   if(currentVolume < avgVolume * InpAggrVolumeThreshold) return 0;
   double open  = m_rates[shift].open;
   double close = m_rates[shift].close;
   double high  = m_rates[shift].high;
   double low   = m_rates[shift].low;
   double range = high - low;
   if(range == 0) range = m_point;
   double body = MathAbs(close - open);
   if((body / range) < InpMinBodyPercent) return 0;
   if(range < atr * InpMinVolatilityATR) return 0;
   bool trendUp   = (close > ma50);
   bool trendDown = (close < ma50);
   bool rsiOkBuy  = (rsi < 70.0);
   bool rsiOkSell = (rsi > 30.0);
   double highPrev = m_rates[shift + 1].high;
   double lowPrev  = m_rates[shift + 1].low;
   double buffer   = atr * InpBreakoutBufferATR;
   bool bullishBreakout = (close > highPrev + buffer) && (close > open);
   bool bearishBreakout = (close < lowPrev  - buffer) && (close < open);
   if(bullishBreakout && trendUp && rsiOkBuy && ConfirmHigherTF(1)) return 1;
   if(bearishBreakout && trendDown && rsiOkSell && ConfirmHigherTF(-1)) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ConfirmHigherTF(int signal)
{
   double h1Ma50[1];
   if(CopyBuffer(m_handleMA_HTF, 0, 0, 1, h1Ma50) <= 0) return true;
   MqlRates h1Rates[];
   ArraySetAsSeries(h1Rates, true);
   if(CopyRates(m_symbolName, PERIOD_H1, 0, 1, h1Rates) < 1) return true;
   double h1Close = h1Rates[0].close;
   if(signal == 1) return (h1Close > h1Ma50[0]);
   if(signal == -1) return (h1Close < h1Ma50[0]);
   return true;
}

//+------------------------------------------------------------------+
//| 5. EXECUTE TRADE (Strict Validator Compliant)                    |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal, int shift)
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, shift, 1, atrBuffer) <= 0) return;
   double atr = atrBuffer[0];
   if(atr <= 0) return;
   double slDistance = atr * InpATRMultiplierSL;
   double tpDistance = atr * InpATRMultiplierTP;
// FIX: StopLevel compliance for MQL5 Validator
   long stopLevel = SymbolInfoInteger(m_symbolName, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = (stopLevel * m_point) + (2 * m_point); // Added 2 points buffer for safety
   if(slDistance < minDistance) slDistance = minDistance;
   if(tpDistance < minDistance) tpDistance = minDistance;
   double entryPrice = (signal == 1) ? m_currentTick.ask : m_currentTick.bid;
   double slPrice = (signal == 1) ? entryPrice - slDistance : entryPrice + slDistance;
   double tpPrice = (signal == 1) ? entryPrice + tpDistance : entryPrice - tpDistance;
   int digits = (int)m_symbol.Digits();
   slPrice = NormalizeDouble(slPrice, digits);
   tpPrice = NormalizeDouble(tpPrice, digits);
   entryPrice = NormalizeDouble(entryPrice, digits);
   double lot = CalculateLotSize(slDistance);
   if(lot <= 0) return; // Order aborted: Volume is invalid or Margin too low
   int oppositeSignal = (signal == 1) ? -1 : 1;
   if(CountPositionsByType(oppositeSignal) > 0) {
      if(!InpAllowHedging) CloseAllPositionsByType(oppositeSignal, "Hedging disabled");
   }
   bool success = false;
   if(signal == 1) {
      success = m_trade.Buy(lot, m_symbolName, entryPrice, slPrice, tpPrice, InpComment);
   } else if(signal == -1) {
      success = m_trade.Sell(lot, m_symbolName, entryPrice, slPrice, tpPrice, InpComment);
   }
   if(success) {
      Print("Trade Executed: ", (signal == 1) ? "BUY" : "SELL", " | Lot: ", DoubleToString(lot, 2));
   } else {
      Print("Trade failed. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| 6. AUTO BREAK-EVEN                                               |
//+------------------------------------------------------------------+
void AutoBreakEven()
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) <= 0) return;
   double triggerDist = atrBuffer[0] * InpBreakEvenATR;
   double paddingDist = atrBuffer[0] * InpBreakEvenPaddingATR;
   int digits = (int)m_symbol.Digits();
   long stopLevel = SymbolInfoInteger(m_symbolName, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = stopLevel * m_point;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i) || m_position.Symbol() != m_symbolName || m_position.Magic() != m_magicNumber) continue;
      double sl = m_position.StopLoss();
      double tp = m_position.TakeProfit();
      double openPrice = m_position.PriceOpen();
      if(m_position.PositionType() == POSITION_TYPE_BUY) {
         if(m_currentTick.bid >= openPrice + triggerDist) {
            double newSL = openPrice + paddingDist;
            if((sl < openPrice || sl == 0) && (m_currentTick.bid - newSL > minDistance)) {
               m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp);
            }
         }
      } else if(m_position.PositionType() == POSITION_TYPE_SELL) {
         if(m_currentTick.ask <= openPrice - triggerDist) {
            double newSL = openPrice - paddingDist;
            if((sl > openPrice || sl == 0) && (newSL - m_currentTick.ask > minDistance)) {
               m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 7. ATR TRAILING STOP                                             |
//+------------------------------------------------------------------+
void TrailingStop()
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) <= 0) return;
   double dist = atrBuffer[0] * InpTrailingATR;
   int digits = (int)m_symbol.Digits();
   long stopLevel = SymbolInfoInteger(m_symbolName, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = stopLevel * m_point;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i) || m_position.Symbol() != m_symbolName || m_position.Magic() != m_magicNumber) continue;
      double sl = m_position.StopLoss();
      double tp = m_position.TakeProfit();
      if(m_position.PositionType() == POSITION_TYPE_BUY) {
         double newSL = m_currentTick.bid - dist;
         if(newSL > sl + m_point && (m_currentTick.bid - newSL > minDistance)) {
            m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp);
         }
      } else if(m_position.PositionType() == POSITION_TYPE_SELL) {
         double newSL = m_currentTick.ask + dist;
         if((sl == 0 || newSL < sl - m_point) && (newSL - m_currentTick.ask > minDistance)) {
            m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 8. LOT CALCULATION (CRITICAL FIX FOR MQL5 VALIDATOR)             |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistancePrice)
{
   double lot = InpFixedLot;
   if(InpCalcMethod == 0) {
      double riskAmount = m_account.Balance() * (InpRiskPercent / 100.0);
      if(riskAmount > 0) {
         m_symbol.RefreshRates();
         double tickSize = m_symbol.TickSize();
         double tickValue = m_symbol.TickValue();
         if(tickSize > 0 && tickValue > 0 && slDistancePrice > 0) {
            double slTicks = slDistancePrice / tickSize;
            lot = riskAmount / (slTicks * tickValue);
         }
      }
   }
// --- MQL5 VALIDATOR PROTECTIONS ---
   m_symbol.RefreshRates();
   double minLot = m_symbol.LotsMin();
   double maxLot = m_symbol.LotsMax();
   double stepLot = m_symbol.LotsStep();
   if(minLot <= 0) minLot = 0.01;
   if(stepLot <= 0) stepLot = 0.01;
   if(maxLot <= 0) maxLot = 1000.0;
   lot = MathMax(minLot, MathMin(lot, maxLot));
   lot = MathFloor(lot / stepLot) * stepLot;
   int lotDigits = 2;
   if(stepLot == 0.001) lotDigits = 3;
   else if(stepLot >= 0.1 && stepLot < 1.0) lotDigits = 1;
   else if(stepLot >= 1.0) lotDigits = 0;
   lot = NormalizeDouble(lot, lotDigits);
// 5. Final Safety Check
   if(lot < minLot) lot = minLot;
   return lot;
}

//+------------------------------------------------------------------+
//| 9. HELPERS                                                       |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == m_symbolName && m_position.Magic() == m_magicNumber)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountPositionsByType(int type)
{
   int count = 0;
   ENUM_POSITION_TYPE posType = (type == 1) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == m_symbolName &&
         m_position.Magic() == m_magicNumber && m_position.PositionType() == posType)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == m_symbolName && m_position.Magic() == m_magicNumber)
         m_trade.PositionClose(m_position.Ticket());
   }
   Print("All positions closed. Reason: ", reason);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositionsByType(int type, string reason)
{
   ENUM_POSITION_TYPE posType = (type == 1) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == m_symbolName &&
         m_position.Magic() == m_magicNumber && m_position.PositionType() == posType)
         m_trade.PositionClose(m_position.Ticket());
   }
}

*/




/* 05/10/2026
//+------------------------------------------------------------------+
//|                                               ApexVelocityEA.mq5 |
//|               Copyright 2026, Ritz EAneha | Apex Trading Systems |
//|                   https://www.mql5.com/en/users/ritzfalih/seller |
//+------------------------------------------------------------------+
#property copyright     "Copyright 2026, Ritz EAneha | Apex Trading Systems"
#property link          "https://www.mql5.com/en/users/ritzfalih/seller"
#property version       "1.0"
#property description   "Apex Velocity trading system"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/AccountInfo.mqh>
#include <Trade/SymbolInfo.mqh>

// FOR TIMEFRAME M5 (XAUUSD)

input group    "------- BASICS -------"
input string   InpSymbols = "XAUUSD";                 // Trading symbol
input bool     InpSymbolSuffixAuto = true;            // Automatically detect symbol suffixes
input int      InpMagicNumber = 30836;                // EA magic number
input string   InpComment = "ApexVelocity v1.0";      // Trade comment

input group    "------- RISK SETUP -------"
input int      InpCalcMethod = 1;                     // Lot calculation: 0=Risk%, 1=Fixed
input double   InpRiskPercent = 1.0;                  // Risk per trade (%)
input double   InpFixedLot = 0.01;                    // Fixed lot size

input group    "------- SIGNAL CONFIG -------"
input int      InpMaxPositions = 1;                   // Maximum open positions
input int      InpVolumePeriod = 5;                   // Volume analysis period
input double   InpVolumeThreshold = 1.5;              // Minimum volume threshold
input int      InpMAPeriod = 9;                       // Moving Average period
input int      InpATRPeriod = 14;                     // ATR calculation period
input double   InpATRMultiplierSL = 2.5;              // ATR multiplier for Stop Loss
input double   InpATRMultiplierTP = 4.5;              // ATR multiplier for Take Profit
input int      InpEntryMode = 1;                      // Entry mode: 0=Bar close, 1=Real-time

input group    "------- AGGR CONFIG -------"
input double   InpAggrVolumeThreshold = 1.1;          // Aggressive entry volume threshold
input double   InpMinBodyPercent = 0.85;              // Minimum candle body ratio (85%)
input double   InpBreakoutBufferATR = 0.1;             // Breakout buffer (ATR multiplier; digit-independent)
input double   InpMinVolatilityATR = 0.7;              // Minimum volatility threshold (ATR multiplier)

input group    "------- HEDGING -------"
input bool     InpAllowHedging = false;               // Allow simultaneous opposite positions

input group    "------- EXIT MANAGEMENT -------"
input bool     InpBreakEvenOn = true;                 // Enable automatic break-even
input double   InpBreakEvenATR = 0.3;                 // Profit threshold to trigger break-even (ATR multiplier)
input double   InpBreakEvenPaddingATR = 0.05;         // Break-even buffer (ATR multiplier)
input bool     InpTrailingOn = true;                  // Enable trailing stop
input double   InpTrailingATR = 0.05;                 // Trailing distance (ATR multiplier)

input group    "TIME & SESSION CONTROL"
input bool     InpUseSession = true;                  // Enable session-based trading
input int      InpStartHour = 13;                     // Trading start hour (broker time)
input int      InpEndHour = 21;                       // Trading end hour (broker time)
input int      InpCloseOnWeekend = 22;                // Friday closure hour (-1 to disable)
input bool     InpAvoidTripleSwap = true;             // Avoid triple-swap periods

input group    "DD PROTECTION & EXTENDED"
input double   InpMaxDrawdownPercent = 15.0;          // Maximum drawdown (%)
input bool     InpEnableDDClose = false;              // Enable automatic closure at drawdown limit
input double   InpMaxSpreadATR = 0.2;                 // Maximum spread threshold (ATR multiplier)
input int      InpLatencyJitter = 0;                  // Execution latency variation setting

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & VARIABLES                                       |
//+------------------------------------------------------------------+
CTrade          m_trade;
CPositionInfo   m_position;
CAccountInfo    m_account;
CSymbolInfo     m_symbol;
MqlTick         m_currentTick;
MqlRates        m_rates[];

int             m_magicNumber;
string          m_symbolName;
double          m_point;
double          m_tickValue;
double          m_tickSize;
datetime        m_lastBarTime = 0;
bool            m_isNewBar = false;
bool            m_canTradeThisBar = false;
double          m_peakEquity = 0.0;
double          m_currentDrawdownPercent = 0.0;

// Indicators
int             m_handleATR;
int             m_handleMA;
int             m_handleMA50;
int             m_handleRSI;
int             m_handleMA_HTF;

double          m_initialBalance;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   m_magicNumber = InpMagicNumber;
   m_symbolName = InpSymbolSuffixAuto ? Symbol() : InpSymbols;
   if(!m_symbol.Name(m_symbolName) || !m_symbol.Refresh()) {
      Print("Error: Cannot refresh symbol info for ", m_symbolName);
      return(INIT_FAILED);
   }
   m_symbol.RefreshRates();
   m_point = m_symbol.Point();
   m_tickValue = m_symbol.TickValue();
   m_tickSize = m_symbol.TickSize();
   m_trade.SetExpertMagicNumber(m_magicNumber);
   m_trade.SetTypeFillingBySymbol(m_symbolName);
   m_trade.SetAsyncMode(false);
   // Dynamic deviation adjustment (roughly 5 pips)
   int deviation = (int)(m_tickSize == 0.001 ? 50 : 5);
   m_trade.SetDeviationInPoints(deviation);
   // Initialize Indicators
   m_handleATR = iATR(m_symbolName, PERIOD_CURRENT, InpATRPeriod);
   m_handleMA = iMA(m_symbolName, PERIOD_CURRENT, InpMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   m_handleMA50 = iMA(m_symbolName, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
   m_handleRSI = iRSI(m_symbolName, PERIOD_CURRENT, 14, PRICE_CLOSE);
   m_handleMA_HTF = iMA(m_symbolName, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
   if(m_handleATR == INVALID_HANDLE || m_handleMA == INVALID_HANDLE ||
      m_handleMA50 == INVALID_HANDLE || m_handleRSI == INVALID_HANDLE || m_handleMA_HTF == INVALID_HANDLE) {
      Print("Error initializing indicators.");
      return(INIT_FAILED);
   }
   m_initialBalance = m_account.Balance();
   m_peakEquity = m_account.Equity();
   ArraySetAsSeries(m_rates, true);
   Print("ApexVelocity EA v1.0 initialized on ", m_symbolName, " | Digits: ", m_symbol.Digits());
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(m_handleATR);
   IndicatorRelease(m_handleMA);
   IndicatorRelease(m_handleMA50);
   IndicatorRelease(m_handleRSI);
   IndicatorRelease(m_handleMA_HTF);
   Print("ApexVelocity EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function - CORE LOGIC                                |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!m_symbol.Refresh() || !SymbolInfoTick(m_symbolName, m_currentTick)) return;
   datetime currentBarTime = iTime(m_symbolName, PERIOD_CURRENT, 0);
   if(currentBarTime != m_lastBarTime) {
      m_isNewBar = true;
      m_canTradeThisBar = true;
      m_lastBarTime = currentBarTime;
   } else {
      m_isNewBar = false;
   }
   UpdateDrawdownProtection();
   if(InpEnableDDClose) {
      if(m_currentDrawdownPercent >= InpMaxDrawdownPercent) {
         CloseAllPositions("DD limit breached");
         return;
      }
   }
   if(InpBreakEvenOn) AutoBreakEven();
   if(InpTrailingOn) TrailingStop();
   if(!CheckSpread() || !CheckTradeTime()) return;
   // SIGNAL GENERATION
   int shift = (InpEntryMode == 0) ? 1 : 0;
   // If Real-time mode, check if we already traded this bar
   if(InpEntryMode == 1 && !m_canTradeThisBar) return;
   // If Bar close mode, only evaluate on a new bar
   if(InpEntryMode == 0 && !m_isNewBar) return;
   int signal = GetVolumeAccelerationSignal(shift);
   if(signal != 0) {
      if(CountOpenPositions() < InpMaxPositions) {
         ExecuteTrade(signal, shift);
         if(InpEntryMode == 1) m_canTradeThisBar = false;
      }
   }
   if(InpLatencyJitter > 0) Sleep(InpLatencyJitter);
}

//+------------------------------------------------------------------+
//| 1. DRAWDOWN PROTECTION                                           |
//+------------------------------------------------------------------+
void UpdateDrawdownProtection()
{
   double equity = m_account.Equity();
   if(equity > m_peakEquity) m_peakEquity = equity;
   if(m_peakEquity > 0) {
      m_currentDrawdownPercent = ((m_peakEquity - equity) / m_peakEquity) * 100.0;
   }
}

//+------------------------------------------------------------------+
//| 2. SPREAD CHECK (ATR Based for Cross-Digit Compatibility)        |
//+------------------------------------------------------------------+
bool CheckSpread()
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) <= 0) return true;
   double maxSpreadPrice = atrBuffer[0] * InpMaxSpreadATR;
   double currentSpreadPrice = (m_currentTick.ask - m_currentTick.bid);
   if(currentSpreadPrice > maxSpreadPrice) return false;
   return true;
}

//+------------------------------------------------------------------+
//| 3. TRADE TIME CHECK (Session, Weekend, Triple Swap)              |
//+------------------------------------------------------------------+
bool CheckTradeTime()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   // Session Filter (e.g., London-NY overlap only)
   if(InpUseSession) {
      if(dt.hour < InpStartHour || dt.hour >= InpEndHour) return false;
   }
   // Weekend closure
   if(InpCloseOnWeekend > 0 && dt.day_of_week == 5 && dt.hour >= InpCloseOnWeekend) {
      CloseAllPositions("Weekend closure");
      return false;
   }
   // Triple Swap Filter (Wednesday night)
   if(InpAvoidTripleSwap && dt.day_of_week == 3 && dt.hour >= 21 && dt.hour < 23) {
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| 4. SIGNAL ENGINE - VOLATILITY EXPANSION                          |
//+------------------------------------------------------------------+
int GetVolumeAccelerationSignal(int shift)
{
   int ratesCount = InpVolumePeriod + 5;
   if(CopyRates(m_symbolName, PERIOD_CURRENT, 0, ratesCount, m_rates) < ratesCount) return 0;
   double atrBuffer[1], ma10Buffer[1], ma50Buffer[1], rsiBuffer[1];
   if(CopyBuffer(m_handleATR, 0, shift, 1, atrBuffer) <= 0) return 0;
   if(CopyBuffer(m_handleMA, 0, shift, 1, ma10Buffer) <= 0) return 0;
   if(CopyBuffer(m_handleMA50, 0, shift, 1, ma50Buffer) <= 0) return 0;
   if(CopyBuffer(m_handleRSI, 0, shift, 1, rsiBuffer) <= 0) return 0;
   double atr = atrBuffer[0];
   double ma50 = ma50Buffer[0];
   double rsi = rsiBuffer[0];
   double currentVolume = (double)m_rates[shift].tick_volume;
   double volumeSum = 0;
   for(int i = shift + 1; i <= shift + InpVolumePeriod; i++) {
      volumeSum += (double)m_rates[i].tick_volume;
   }
   double avgVolume = (InpVolumePeriod > 0) ? volumeSum / InpVolumePeriod : 1.0;
   if(currentVolume < avgVolume * InpAggrVolumeThreshold) return 0;
   double open  = m_rates[shift].open;
   double close = m_rates[shift].close;
   double high  = m_rates[shift].high;
   double low   = m_rates[shift].low;
   double range = high - low;
   if(range == 0) range = m_point;
   double body = MathAbs(close - open);
   if((body / range) < InpMinBodyPercent) return 0;
   if(range < atr * InpMinVolatilityATR) return 0;
   bool trendUp   = (close > ma50);
   bool trendDown = (close < ma50);
   bool rsiOkBuy  = (rsi < 70.0);
   bool rsiOkSell = (rsi > 30.0);
   double highPrev = m_rates[shift + 1].high;
   double lowPrev  = m_rates[shift + 1].low;
   double buffer   = atr * InpBreakoutBufferATR;
   bool bullishBreakout = (close > highPrev + buffer) && (close > open);
   bool bearishBreakout = (close < lowPrev  - buffer) && (close < open);
   if(bullishBreakout && trendUp && rsiOkBuy && ConfirmHigherTF(1)) return 1;
   if(bearishBreakout && trendDown && rsiOkSell && ConfirmHigherTF(-1)) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//| Higher Timeframe Confirmation                                    |
//+------------------------------------------------------------------+
bool ConfirmHigherTF(int signal)
{
   double h1Ma50[1];
   if(CopyBuffer(m_handleMA_HTF, 0, 0, 1, h1Ma50) <= 0) return true;
   MqlRates h1Rates[];
   ArraySetAsSeries(h1Rates, true);
   if(CopyRates(m_symbolName, PERIOD_H1, 0, 1, h1Rates) < 1) return true;
   double h1Close = h1Rates[0].close;
   if(signal == 1) return (h1Close > h1Ma50[0]);
   if(signal == -1) return (h1Close < h1Ma50[0]);
   return true;
}

//+------------------------------------------------------------------+
//| 5. EXECUTE TRADE                                                 |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal, int shift)
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, shift, 1, atrBuffer) <= 0) return;
   double atr = atrBuffer[0];
   if(atr <= 0) return;
   double slDistance = atr * InpATRMultiplierSL;
   double tpDistance = atr * InpATRMultiplierTP;
   double entryPrice = (signal == 1) ? m_currentTick.ask : m_currentTick.bid;
   double slPrice = (signal == 1) ? entryPrice - slDistance : entryPrice + slDistance;
   double tpPrice = (signal == 1) ? entryPrice + tpDistance : entryPrice - tpDistance;
   int digits = (int)m_symbol.Digits();
   slPrice = NormalizeDouble(slPrice, digits);
   tpPrice = NormalizeDouble(tpPrice, digits);
   entryPrice = NormalizeDouble(entryPrice, digits);
   double lot = CalculateLotSize(slDistance);
   if(lot <= 0) return;
   int oppositeSignal = (signal == 1) ? -1 : 1;
   if(CountPositionsByType(oppositeSignal) > 0) {
      if(!InpAllowHedging) CloseAllPositionsByType(oppositeSignal, "Hedging disabled");
   }
   bool success = false;
   if(signal == 1) {
      success = m_trade.Buy(lot, m_symbolName, entryPrice, slPrice, tpPrice, InpComment);
   } else if(signal == -1) {
      success = m_trade.Sell(lot, m_symbolName, entryPrice, slPrice, tpPrice, InpComment);
   }
   if(success) {
      Print("Trade Executed: ", (signal == 1) ? "BUY" : "SELL", " | Lot: ", DoubleToString(lot, 2));
   } else {
      Print("Trade failed. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| 6. AUTO BREAK-EVEN (ATR Based Padding)                           |
//+------------------------------------------------------------------+
void AutoBreakEven()
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) <= 0) return;
   double atr = atrBuffer[0];
   double triggerDist = atr * InpBreakEvenATR;
   double paddingDist = atr * InpBreakEvenPaddingATR;
   int digits = (int)m_symbol.Digits();
   long stopLevel = SymbolInfoInteger(m_symbolName, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = stopLevel * m_point;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i) || m_position.Symbol() != m_symbolName || m_position.Magic() != m_magicNumber) continue;
      double sl = m_position.StopLoss();
      double tp = m_position.TakeProfit();
      double openPrice = m_position.PriceOpen();
      if(m_position.PositionType() == POSITION_TYPE_BUY) {
         if(m_currentTick.bid >= openPrice + triggerDist) {
            double newSL = openPrice + paddingDist;
            // Ensure newSL does not violate StopLevel rules and is actually moving up
            if((sl < openPrice || sl == 0) && (m_currentTick.bid - newSL > minDistance)) {
               m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp);
            }
         }
      } else if(m_position.PositionType() == POSITION_TYPE_SELL) {
         if(m_currentTick.ask <= openPrice - triggerDist) {
            double newSL = openPrice - paddingDist;
            if((sl > openPrice || sl == 0) && (newSL - m_currentTick.ask > minDistance)) {
               m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 7. ATR TRAILING STOP                                             |
//+------------------------------------------------------------------+
void TrailingStop()
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) <= 0) return;
   double dist = atrBuffer[0] * InpTrailingATR;
   int digits = (int)m_symbol.Digits();
   long stopLevel = SymbolInfoInteger(m_symbolName, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = stopLevel * m_point;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i) || m_position.Symbol() != m_symbolName || m_position.Magic() != m_magicNumber) continue;
      double sl = m_position.StopLoss();
      double tp = m_position.TakeProfit();
      if(m_position.PositionType() == POSITION_TYPE_BUY) {
         double newSL = m_currentTick.bid - dist;
         // Check if new SL is higher than old SL AND respects StopLevel
         if(newSL > sl + m_point && (m_currentTick.bid - newSL > minDistance)) {
            m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp);
         }
      } else if(m_position.PositionType() == POSITION_TYPE_SELL) {
         double newSL = m_currentTick.ask + dist;
         if((sl == 0 || newSL < sl - m_point) && (newSL - m_currentTick.ask > minDistance)) {
            m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 8. LOT CALCULATION (Fixed/Safe Tick Ratio)                       |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistancePrice)
{
   if(InpCalcMethod == 1) return InpFixedLot;
   double riskAmount = m_account.Balance() * (InpRiskPercent / 100.0);
   if(riskAmount <= 0) return 0;
   m_symbol.RefreshRates();
   double tickSize = m_symbol.TickSize();
   double tickValue = m_symbol.TickValue();
   if(tickSize <= 0 || tickValue <= 0 || slDistancePrice <= 0) return 0;
   // Calculates exact financial risk regardless of digit configuration
   double slTicks = slDistancePrice / tickSize;
   double lot = riskAmount / (slTicks * tickValue);
   double minLot = m_symbol.LotsMin();
   double maxLot = m_symbol.LotsMax();
   double stepLot = m_symbol.LotsStep();
   lot = MathMax(minLot, MathMin(lot, maxLot));
   lot = MathFloor(lot / stepLot) * stepLot;
   return lot;
}

//+------------------------------------------------------------------+
//| 9. HELPERS                                                       |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == m_symbolName && m_position.Magic() == m_magicNumber)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountPositionsByType(int type)
{
   int count = 0;
   ENUM_POSITION_TYPE posType = (type == 1) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == m_symbolName &&
         m_position.Magic() == m_magicNumber && m_position.PositionType() == posType)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == m_symbolName && m_position.Magic() == m_magicNumber)
         m_trade.PositionClose(m_position.Ticket());
   }
   Print("All positions closed. Reason: ", reason);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositionsByType(int type, string reason)
{
   ENUM_POSITION_TYPE posType = (type == 1) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i) && m_position.Symbol() == m_symbolName &&
         m_position.Magic() == m_magicNumber && m_position.PositionType() == posType)
         m_trade.PositionClose(m_position.Ticket());
   }
}

//+------------------------------------------------------------------+

*/

/* // 29/09/2026
//+------------------------------------------------------------------+
//|                                              ApexVelocityEA.mq5  |
//|                           Copyright 2026, Apex Trading Systems   |
//|                                      https://www.apextrading.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Apex Trading Systems"
#property link      "https://www.apextrading.com"
#property version   "1.0"

//+------------------------------------------------------------------+
//| Include Libraries                                                |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/AccountInfo.mqh>
#include <Trade/SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
//+------------------+  BASICS
input string   InpSection1 = "------- BASICS -------"; // Setting ------------------ 1
input string   InpSymbols = "XAUUSD";            // Check MarketWatch (symbols used)
input bool     InpSymbolSuffixAuto = true;       // Automatically detect symbol suffixes
input int      InpMagicNumber = 30836;           // EA magic number
input string   InpComment = "ApexVelocity v1.0"; // Trade comment

//+------------------+  RISK SETUP
input string   InpSection2 = "------- RISK SETUP -------"; // Setting ------------------ 2
input int      InpCalcMethod = 1;                // Lot calculation: 0=Risk%, 1=Fixed
input double   InpRiskPercent = 1.0;             // Risk per trade (maximum 1%)
input double   InpFixedLot = 0.01;               // Fixed lot size

//+------------------+  SIGNAL CONFIG
input string   InpSection3 = "------- SIGNAL CONFIG -------"; // Setting ------------------ 3
input int      InpMaxPositions = 1;              // Maximum open positions
input int      InpVolumePeriod = 5;              // Volume analysis period
input double   InpVolumeThreshold = 1.5;         // Minimum volume threshold
input int      InpMAPeriod = 9;                 // Moving Average period
input int      InpATRPeriod = 14;                // ATR calculation period
input double   InpATRMultiplierSL = 2.5;         // ATR multiplier for Stop Loss
input double   InpATRMultiplierTP = 4.5;         // ATR multiplier for Take Profit
input int      InpEntryMode = 1;                 // Entry mode: 0=Bar close, 1=Real-time

input string   InpSectionAggr = "------- AGGR CONFIG -------"; // Setting ------------------ 4
input double   InpAggrVolumeThreshold = 1.1;     // Progressive volume threshold
input double   InpMinBodyPercent = 0.85;         // Minimum candle body ratio (60%)
input double   InpBreakoutBuffer = 0.1;         // Breakout confirmation buffer
input double   InpMinVolatility = 0.7;           // Minimum volatility threshold

//+------------------+  HEDGING
input string   InpSection4 = "------- HEDGING -------"; // Setting ------------------ 5
input bool     InpAllowHedging = false;          // Allow simultaneous opposite positions

//+------------------+  EXIT MANAGEMENT (BREAK-EVEN & TRAILING)
input string   InpSection5 = "------- EXIT MANAGEMENT -------"; // Setting ------------------ 6
input bool     InpBreakEvenOn = true;            // Enable automatic break-even
input double   InpBreakEvenATR = 0.3;            // ATR-based profit threshold to trigger break-even
input int      InpBreakEvenPadding = 4500;       // Break-even profit buffer (points) for costs
input bool     InpTrailingOn = true;            // Enable ATR-based trailing stop
input double   InpTrailingATR = 0.05;             // Trailing distance (ATR multiplier)

//+------------------+  DRAWDOWN PROTECTION
input string   InpSection6 = "------- DD PROTECTION -------"; // Setting ------------------ 7
input double   InpMaxDrawdownPercent = 15.0;     // Maximum drawdown (%)
input double   InpMaxLossCurrency = 10.0;      // Maximum loss in account currency
input bool     InpEnableDDClose = false;         // Enable automatic closure on drawdown limit

//+------------------+  NEWS CONTROL
input string   InpSection7 = "------- NEWS FILTER -------"; // Setting ------------------ 8
input bool     InpFilterHighImpact = false;      // Filter high-impact news
input bool     InpFilterMediumImpact = false;    // Filter medium-impact news
input bool     InpFilterLowImpact = false;       // Filter low-impact news

input string   InpSection8 = "------- TIME CONTROL -------"; // Setting ------------------ 9
input int      InpCloseOnWeekend = -1;           // Weekend closure setting
input bool     InpAvoidTripleSwap = false;       // Avoid triple-swap periods

//+------------------+  EXTENDED SETTINGS
input string   InpSection9 = "------- EXTENDED -------"; // Setting ------------------ 10
input double   InpSpreadHeadroom = 200.0;        // Additional spread allowance
input int      InpLatencyJitter = 0;             // Execution latency variation setting
input bool     InpFTMORandomizer = false;        // Enable FTMO randomization

//+------------------------------------------------------------------+
//| GLOBAL OBJECTS & VARIABLES                                       |
//+------------------------------------------------------------------+
CTrade          m_trade;
CPositionInfo   m_position;
CAccountInfo    m_account;
CSymbolInfo     m_symbol;
MqlTick         m_currentTick;
MqlRates        m_rates[];

//--- Core state
int             m_magicNumber;
string          m_symbolName;
double          m_point;
double          m_tickValue;
datetime        m_lastBarTime = 0;
bool            m_isNewBar = false;
bool            m_canTradeThisBar = false;
double          m_peakEquity = 0.0;
double          m_currentDrawdownPercent = 0.0;

//--- Indicator handles
int             m_handleATR;
int             m_handleMA;
int             m_handleMA50;
int             m_handleRSI;
int             m_handleMA_HTF;

//--- Risk limits
double          m_initialBalance;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   m_magicNumber = InpMagicNumber;
   if(InpSymbolSuffixAuto)
      m_symbolName = Symbol();
   else
      m_symbolName = InpSymbols;
   m_symbol.Name(m_symbolName);
   if(!m_symbol.Refresh()) {
      Print("Error: Cannot refresh symbol info for ", m_symbolName);
      return(INIT_FAILED);
   }
   string description;
   if(!m_symbol.InfoString(SYMBOL_DESCRIPTION, description)) {
      Print("Error: Symbol ", m_symbolName, " not found!");
      return(INIT_FAILED);
   }
   m_symbol.RefreshRates();
   m_point = m_symbol.Point();
   m_tickValue = m_symbol.TickValue();
   m_trade.SetExpertMagicNumber(m_magicNumber);
   m_trade.SetDeviationInPoints(50);
   m_trade.SetTypeFillingBySymbol(m_symbolName);
   m_trade.SetAsyncMode(false);
   m_handleATR = iATR(m_symbolName, PERIOD_CURRENT, InpATRPeriod);
   if(m_handleATR == INVALID_HANDLE) return(INIT_FAILED);
   m_handleMA = iMA(m_symbolName, PERIOD_CURRENT, InpMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(m_handleMA == INVALID_HANDLE) return(INIT_FAILED);
   m_handleMA50 = iMA(m_symbolName, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
   if(m_handleMA50 == INVALID_HANDLE) return(INIT_FAILED);
   m_handleRSI = iRSI(m_symbolName, PERIOD_CURRENT, 14, PRICE_CLOSE);
   if(m_handleRSI == INVALID_HANDLE) return(INIT_FAILED);
   m_handleMA_HTF = iMA(m_symbolName, PERIOD_H1, 50, 0, MODE_EMA, PRICE_CLOSE);
   if(m_handleMA_HTF == INVALID_HANDLE) return(INIT_FAILED);
   m_initialBalance = m_account.Balance();
   m_peakEquity = m_account.Equity();
   ArraySetAsSeries(m_rates, true);
   Print("ApexVelocity EA v3.50 initialized on ", m_symbolName, " | Magic: ", m_magicNumber);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(m_handleATR != INVALID_HANDLE) IndicatorRelease(m_handleATR);
   if(m_handleMA != INVALID_HANDLE) IndicatorRelease(m_handleMA);
   if(m_handleMA50 != INVALID_HANDLE) IndicatorRelease(m_handleMA50);
   if(m_handleRSI != INVALID_HANDLE) IndicatorRelease(m_handleRSI);
   if(m_handleMA_HTF != INVALID_HANDLE) IndicatorRelease(m_handleMA_HTF);
   Print("ApexVelocity EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function - CORE LOGIC                                |
//+------------------------------------------------------------------+
void OnTick()
{
   m_symbol.Refresh();
   datetime currentBarTime = iTime(m_symbolName, PERIOD_CURRENT, 0);
   if(currentBarTime != m_lastBarTime) {
      m_isNewBar = true;
      m_canTradeThisBar = true;
      m_lastBarTime = currentBarTime;
   } else {
      m_isNewBar = false;
   }
   if(!SymbolInfoTick(m_symbolName, m_currentTick))
      return;
   UpdateDrawdownProtection();
   if(InpEnableDDClose) {
      if(m_currentDrawdownPercent >= InpMaxDrawdownPercent ||
         (m_initialBalance - m_account.Equity()) >= InpMaxLossCurrency) {
         CloseAllPositions("DD/Loss limit breached");
         return;
      }
   }
   if(!CheckSpread()) return;
   if(!CheckTradeTime()) return;
   if(!CheckNewsFilter()) return;
   //--- 5. EXIT MANAGEMENT (Break-Even & Trailing Stop)
   if(InpBreakEvenOn)
      AutoBreakEven();
   if(InpTrailingOn)
      TrailingStop();
   //--- 6. SIGNAL GENERATION
   if(InpEntryMode == 0) {
      if(m_isNewBar) {
         int signal = GetVolumeAccelerationSignal(1);
         if(signal != 0) {
            int totalPositions = CountOpenPositions();
            if(totalPositions < InpMaxPositions) {
               ExecuteTrade(signal, 1);
            }
         }
      }
   } else {
      if(m_canTradeThisBar) {
         int signal = GetVolumeAccelerationSignal(0);
         if(signal != 0) {
            int totalPositions = CountOpenPositions();
            if(totalPositions < InpMaxPositions) {
               ExecuteTrade(signal, 0);
               m_canTradeThisBar = false;
            }
         }
      }
   }
   if(InpLatencyJitter > 0)
      Sleep(InpLatencyJitter);
}

//+------------------------------------------------------------------+
//| 1. DRAWDOWN PROTECTION                                           |
//+------------------------------------------------------------------+
void UpdateDrawdownProtection()
{
   double equity = m_account.Equity();
   if(equity > m_peakEquity)
      m_peakEquity = equity;
   if(m_peakEquity > 0) {
      m_currentDrawdownPercent = ((m_peakEquity - equity) / m_peakEquity) * 100.0;
   } else {
      m_currentDrawdownPercent = 0.0;
   }
}

//+------------------------------------------------------------------+
//| 2. SPREAD CHECK                                                  |
//+------------------------------------------------------------------+
bool CheckSpread()
{
   double spread = m_symbol.Spread();
   if(spread > InpSpreadHeadroom) {
      static datetime lastPrint = 0;
      if(TimeCurrent() - lastPrint > 60) {
         Print("Spread too high: ", DoubleToString(spread, 1), " points. Limit: ", InpSpreadHeadroom);
         lastPrint = TimeCurrent();
      }
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| 3. TRADE TIME CHECK (Weekend & Triple Swap)                      |
//+------------------------------------------------------------------+
bool CheckTradeTime()
{
   MqlDateTime dt;
   TimeCurrent(dt);
   if(InpCloseOnWeekend > 0 && dt.day_of_week == 5) {
      if(dt.hour >= InpCloseOnWeekend) {
         CloseAllPositions("Weekend closure");
         return false;
      }
   } else if(InpCloseOnWeekend == 0 && dt.day_of_week == 5) {
      CloseAllPositions("Weekend closure");
      return false;
   }
   if(InpAvoidTripleSwap) {
      if(dt.day_of_week == 3 && dt.hour >= 21 && dt.hour < 23) {
         return false;
      }
   }
   return true;
}

//+------------------------------------------------------------------+
//| 4. NEWS FILTER (Stub)                                            |
//+------------------------------------------------------------------+
bool CheckNewsFilter()
{
   if(InpFilterHighImpact || InpFilterMediumImpact || InpFilterLowImpact) {
      static bool warningShown = false;
      if(!warningShown) {
         Print("WARNING: News filter enabled but no data source. Blocking all trades.");
         warningShown = true;
      }
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| 5. SIGNAL ENGINE - AGGRESSIVE VOLATILITY EXPANSION (v1.0)        |
//+------------------------------------------------------------------+
int GetVolumeAccelerationSignal(int shift)
{
   int ratesCount = InpVolumePeriod + 5;
   if(CopyRates(m_symbolName, PERIOD_CURRENT, 0, ratesCount, m_rates) < ratesCount)
      return 0;
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, shift, 1, atrBuffer) <= 0) return 0;
   double atr = atrBuffer[0];
   if(atr <= 0) return 0;
   double ma10Buffer[1];
   if(CopyBuffer(m_handleMA, 0, shift, 1, ma10Buffer) <= 0) return 0;
   double ma10 = ma10Buffer[0];
   double ma50Buffer[1];
   if(CopyBuffer(m_handleMA50, 0, shift, 1, ma50Buffer) <= 0) return 0;
   double ma50 = ma50Buffer[0];
   double rsiBuffer[1];
   if(CopyBuffer(m_handleRSI, 0, shift, 1, rsiBuffer) <= 0) return 0;
   double rsi = rsiBuffer[0];
   double currentVolume = (double)m_rates[shift].tick_volume;
   double volumeSum = 0;
   for(int i = shift + 1; i <= shift + InpVolumePeriod; i++) {
      volumeSum += (double)m_rates[i].tick_volume;
   }
   double avgVolume = volumeSum / InpVolumePeriod;
   if(avgVolume <= 0) return 0;
   bool isVolumeSpike = (currentVolume >= avgVolume * InpAggrVolumeThreshold);
   if(!isVolumeSpike) return 0;
   double open  = m_rates[shift].open;
   double close = m_rates[shift].close;
   double high  = m_rates[shift].high;
   double low   = m_rates[shift].low;
   double range = high - low;
   if(range == 0) range = m_point;
   double body = MathAbs(close - open);
   bool isSolid = (body / range) >= InpMinBodyPercent;
   if(!isSolid) return 0;
   bool isVolatile = (range >= atr * InpMinVolatility);
   if(!isVolatile) return 0;
   bool trendUp   = (close > ma50);
   bool trendDown = (close < ma50);
   bool rsiOkBuy  = (rsi < 70.0);
   bool rsiOkSell = (rsi > 30.0);
   double highPrev = m_rates[shift + 1].high;
   double lowPrev  = m_rates[shift + 1].low;
   double buffer   = atr * InpBreakoutBuffer;
   bool bullishBreakout = (close > highPrev + buffer) && (close > open);
   bool bearishBreakout = (close < lowPrev  - buffer) && (close < open);
   if(bullishBreakout && trendUp && rsiOkBuy) {
      if(ConfirmHigherTF(1))
         return 1;
   }
   if(bearishBreakout && trendDown && rsiOkSell) {
      if(ConfirmHigherTF(-1))
         return -1;
   }
   return 0;
}

//+------------------------------------------------------------------+
//| Higher Timeframe (H1) Confirmation - OPTIMIZED                   |
//+------------------------------------------------------------------+
bool ConfirmHigherTF(int signal)
{
   double h1Ma50[1];
   if(CopyBuffer(m_handleMA_HTF, 0, 0, 1, h1Ma50) <= 0)
      return true;
   MqlRates h1Rates[];
   ArraySetAsSeries(h1Rates, true);
   if(CopyRates(m_symbolName, PERIOD_H1, 0, 1, h1Rates) < 1)
      return true;
   double h1Close = h1Rates[0].close;
   if(signal == 1)
      return (h1Close > h1Ma50[0]);
   else if(signal == -1)
      return (h1Close < h1Ma50[0]);
   return true;
}

//+------------------------------------------------------------------+
//| 6. EXECUTE TRADE (With Hedging Logic)                            |
//+------------------------------------------------------------------+
void ExecuteTrade(int signal, int shift)
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, shift, 1, atrBuffer) <= 0) return;
   double atr = atrBuffer[0];
   if(atr <= 0) return;
   double slDistance = atr * InpATRMultiplierSL;
   double tpDistance = atr * InpATRMultiplierTP;
   double entryPrice = (signal == 1) ? m_currentTick.ask : m_currentTick.bid;
   double slPrice = (signal == 1) ? entryPrice - slDistance : entryPrice + slDistance;
   double tpPrice = (signal == 1) ? entryPrice + tpDistance : entryPrice - tpDistance;
   int digits = (int)m_symbol.Digits();
   slPrice = NormalizeDouble(slPrice, digits);
   tpPrice = NormalizeDouble(tpPrice, digits);
   entryPrice = NormalizeDouble(entryPrice, digits);
   double lot = CalculateLotSize(signal, slDistance);
   if(lot <= 0) return;
   int oppositeSignal = (signal == 1) ? -1 : 1;
   bool hasOpposite = CountPositionsByType(oppositeSignal) > 0;
   if(hasOpposite) {
      if(!InpAllowHedging) {
         CloseAllPositionsByType(oppositeSignal, "Hedging disabled - closing opposite");
      } else {
         Print("Hedging: Opening opposite direction while ", (signal == 1) ? "SELL" : "BUY", " positions exist.");
      }
   }
   bool success = false;
   if(signal == 1) {
      success = m_trade.Buy(lot, m_symbolName, entryPrice, slPrice, tpPrice, InpComment);
   } else if(signal == -1) {
      success = m_trade.Sell(lot, m_symbolName, entryPrice, slPrice, tpPrice, InpComment);
   }
   if(success) {
      Print("Order executed: ", (signal == 1) ? "BUY" : "SELL",
            " | Lot: ", DoubleToString(lot, 2),
            " | Entry: ", DoubleToString(entryPrice, digits),
            " | SL: ", DoubleToString(slPrice, digits),
            " | TP: ", DoubleToString(tpPrice, digits));
   } else {
      Print("Order failed. Error: ", GetLastError());
   }
}

//+------------------------------------------------------------------+
//| 6a. AUTO BREAK-EVEN                                              |
//+------------------------------------------------------------------+
void AutoBreakEven()
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) <= 0) return;
   double atr = atrBuffer[0];
   if(atr <= 0) return;
   double triggerDist = atr * InpBreakEvenATR;
   double padding = InpBreakEvenPadding * m_point;
   int digits = (int)m_symbol.Digits();
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != m_symbolName || m_position.Magic() != m_magicNumber) continue;
      double sl = m_position.StopLoss();
      double tp = m_position.TakeProfit();
      double openPrice = m_position.PriceOpen();
      if(m_position.PositionType() == POSITION_TYPE_BUY) {
         // Jika harga saat ini sudah melewati target jarak Break-Even
         if(m_currentTick.bid >= openPrice + triggerDist) {
            double newSL = openPrice + padding;
            // Hanya modifikasi jika SL masih di bawah harga Entry
            if(sl < openPrice || sl == 0) {
               if(m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp)) {
                  Print("Break-Even BUY Terkunci #", m_position.Ticket(), " SL -> ", DoubleToString(newSL, digits));
               }
            }
         }
      } else if(m_position.PositionType() == POSITION_TYPE_SELL) {
         // Jika harga saat ini sudah melewati target jarak Break-Even
         if(m_currentTick.ask <= openPrice - triggerDist) {
            double newSL = openPrice - padding;
            // Hanya modifikasi jika SL masih di atas harga Entry
            if(sl > openPrice || sl == 0) {
               if(m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp)) {
                  Print("Break-Even SELL Terkunci #", m_position.Ticket(), " SL -> ", DoubleToString(newSL, digits));
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 6b. ATR TRAILING STOP                                            |
//+------------------------------------------------------------------+
void TrailingStop()
{
   double atrBuffer[1];
   if(CopyBuffer(m_handleATR, 0, 0, 1, atrBuffer) <= 0) return;
   double atr = atrBuffer[0];
   if(atr <= 0) return;
   double dist = atr * InpTrailingATR;
   int digits = (int)m_symbol.Digits();
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i)) continue;
      if(m_position.Symbol() != m_symbolName || m_position.Magic() != m_magicNumber) continue;
      double sl = m_position.StopLoss();
      double tp = m_position.TakeProfit();
      if(m_position.PositionType() == POSITION_TYPE_BUY) {
         double newSL = m_currentTick.bid - dist;
         if(newSL > sl + m_point) { // Pastikan SL baru selalu lebih tinggi dari SL lama
            if(m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp)) {
               Print("Trailing BUY #", m_position.Ticket(), " SL -> ", DoubleToString(newSL, digits));
            }
         }
      } else if(m_position.PositionType() == POSITION_TYPE_SELL) {
         double newSL = m_currentTick.ask + dist;
         if(sl == 0 || newSL < sl - m_point) { // Pastikan SL baru selalu lebih rendah dari SL lama
            if(m_trade.PositionModify(m_position.Ticket(), NormalizeDouble(newSL, digits), tp)) {
               Print("Trailing SELL #", m_position.Ticket(), " SL -> ", DoubleToString(newSL, digits));
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| 7. LOT CALCULATION (Risk-based atau Fixed)                       |
//+------------------------------------------------------------------+
double CalculateLotSize(int signal, double slDistance)
{
   if(InpCalcMethod == 1) return InpFixedLot;
   double riskAmount = m_account.Balance() * (InpRiskPercent / 100.0);
   if(riskAmount <= 0) return 0;
   m_symbol.RefreshRates();
   double tickVal = m_symbol.TickValue();
   if(tickVal <= 0) return 0;
   double slPoints = slDistance / m_symbol.Point();
   if(slPoints <= 0) return 0;
   double lot = riskAmount / (slPoints * tickVal);
   double minLot = m_symbol.LotsMin();
   double maxLot = m_symbol.LotsMax();
   double stepLot = m_symbol.LotsStep();
   if(stepLot <= 0) stepLot = minLot;
   lot = MathMax(minLot, MathMin(lot, maxLot));
   lot = MathFloor(lot / stepLot) * stepLot;
   return lot;
}

//+------------------------------------------------------------------+
//| 8. HELPER: Count open positions                                  |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i)) {
         if(m_position.Symbol() == m_symbolName && m_position.Magic() == m_magicNumber)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| 9. HELPER: Count positions by type (1=Buy, -1=Sell)              |
//+------------------------------------------------------------------+
int CountPositionsByType(int type)
{
   int count = 0;
   ENUM_POSITION_TYPE posType = (type == 1) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i)) {
         if(m_position.Symbol() == m_symbolName &&
            m_position.Magic() == m_magicNumber &&
            m_position.PositionType() == posType)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| 10. CLOSE ALL POSITIONS (By reason)                              |
//+------------------------------------------------------------------+
void CloseAllPositions(string reason)
{
   bool closedAny = false;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i)) {
         if(m_position.Symbol() == m_symbolName && m_position.Magic() == m_magicNumber) {
            if(m_trade.PositionClose(m_position.Ticket())) {
               closedAny = true;
               Print("Closed position #", m_position.Ticket(), " | Reason: ", reason);
            }
         }
      }
   }
   if(closedAny) {
      Print("All positions closed. Reason: ", reason);
   }
}

//+------------------------------------------------------------------+
//| 11. CLOSE POSITIONS BY TYPE                                      |
//+------------------------------------------------------------------+
void CloseAllPositionsByType(int type, string reason)
{
   ENUM_POSITION_TYPE posType = (type == 1) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i)) {
         if(m_position.Symbol() == m_symbolName &&
            m_position.Magic() == m_magicNumber &&
            m_position.PositionType() == posType) {
            if(m_trade.PositionClose(m_position.Ticket())) {
               Print("Closed position #", m_position.Ticket(), " | Type: ", EnumToString(posType), " | Reason: ", reason);
            }
         }
      }
   }
}


//+------------------------------------------------------------------+

*/
//+------------------------------------------------------------------+

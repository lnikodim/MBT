//+------------------------------------------------------------------+
//|                                        FZMR_Quant_Scalper_v4.mq5 |
//|                     Filtered Z-Score Mean Reversion Strategy v4  |
//|                     Based on v2 Core + Optimized R:R & Sessions  |
//+------------------------------------------------------------------+
#property copyright "Quant Research Model v4.0"
#property version   "4.00"
#property strict

#include <Trade\Trade.mqh>

//--- Input Parameters
input group "=== Mathematical Model (Z-Score & ER) ==="
input int      InpZPeriod         = 20;       // Z-Score Period (Mean & StdDev)
input double   InpZThreshold      = 2.0;      // Z-Score Entry Threshold (Sigma)
input bool     InpExitAtMean      = true;     // Dynamic Exit on Mean Reversion
input double   InpExitZTarget     = 0.25;     // Target Z-Score for Exit (0.0 = Exact Mean, 0.25 = Slight Overshoot)
input int      InpMinProfitPts    = 45;       // Min Profit (Points) to allow Dynamic Z-Exit
input int      InpERPeriod        = 10;       // Kaufman Efficiency Ratio (ER) Period
input double   InpMaxER           = 0.38;     // Max ER Threshold (Strict Range Filter)

input group "=== Trend & Momentum Filters ==="
input bool     InpUseTrendFilter  = true;     // Trade only in direction of Macro EMA
input int      InpTrendEMAPeriod  = 200;      // Macro Trend EMA Period
input int      InpEMASlopeBars    = 3;        // Bars to confirm EMA Slope direction
input int      InpRSIPeriod       = 7;        // Fast RSI Period
input double   InpRSIOverbought   = 70.0;     // RSI Overbought Level (Sell)
input double   InpRSIOversold     = 30.0;     // RSI Oversold Level (Buy)

input group "=== Risk & Volatility Management (ATR) ==="
input double   InpRiskPercent     = 1.0;      // Risk per Trade (% of Balance, 0 = Fixed Lot)
input double   InpFixedLot        = 0.10;     // Fixed Lot Size (if Risk % = 0)
input int      InpATRPeriod       = 14;       // ATR Period for SL/TP
input double   InpSLMultiplier    = 1.60;     // Stop Loss ATR Multiplier (Cut losses faster than v2)
input double   InpTPMultiplier    = 2.20;     // Hard Take Profit ATR Multiplier
input int      InpMinATRPts       = 40;       // Min ATR in Points (Avoids dead market commission bleed)
input int      InpMaxHoldBars     = 20;       // Time Exit: Max Bars to hold a trade (0 = Off)

input group "=== Session & Spread Filter ==="
input int      InpStartHour       = 8;        // Trading Start Hour (08:00 = London Open)
input int      InpEndHour         = 19;       // Trading End Hour (19:00 = NY Afternoon)
input int      InpMaxSpreadPts    = 15;       // Max Allowed Spread (in Points)
input ulong    InpMagicNumber     = 884422;   // EA Magic Number

//--- Global Variables
CTrade         trade;
int            handleMA;
int            handleStdDev;
int            handleRSI;
int            handleATR;
int            handleTrendEMA;
datetime       lastBarTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFillingBySymbol(_Symbol);

   handleMA       = iMA(_Symbol, _Period, InpZPeriod, 0, MODE_SMA, PRICE_CLOSE);
   handleStdDev   = iStdDev(_Symbol, _Period, InpZPeriod, 0, MODE_SMA, PRICE_CLOSE);
   handleRSI      = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   handleATR      = iATR(_Symbol, _Period, InpATRPeriod);
   handleTrendEMA = iMA(_Symbol, _Period, InpTrendEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);

   if(handleMA == INVALID_HANDLE || handleStdDev == INVALID_HANDLE ||
      handleRSI == INVALID_HANDLE || handleATR == INVALID_HANDLE || handleTrendEMA == INVALID_HANDLE)
   {
      Print("Error creating indicator handles!");
      return(INIT_FAILED);
   }

   lastBarTime = 0;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(handleMA);
   IndicatorRelease(handleStdDev);
   IndicatorRelease(handleRSI);
   IndicatorRelease(handleATR);
   IndicatorRelease(handleTrendEMA);
}

//+------------------------------------------------------------------+
//| Calculate Kaufman Efficiency Ratio (Fractal Regime Filter)       |
//+------------------------------------------------------------------+
double CalculateEfficiencyRatio(int period, int shift)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, _Period, shift, period + 1, rates);
   if(copied < period + 1) return 1.0;

   double netChange = MathAbs(rates[0].close - rates[period].close);
   double sumChanges = 0.0;

   for(int i = 0; i < period; i++)
      sumChanges += MathAbs(rates[i].close - rates[i+1].close);

   if(sumChanges == 0.0) return 0.0;
   return netChange / sumChanges;
}

//+------------------------------------------------------------------+
//| Manage Open Positions: Profitable Z-Target Exit & Time Exit      |
//+------------------------------------------------------------------+
void ManageOpenPositions(double currentZScore)
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double minProfitPrice = InpMinProfitPts * _Point;
   int periodSeconds = PeriodSeconds(_Period);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
         {
            long posType     = PositionGetInteger(POSITION_TYPE);
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            datetime openTime= (datetime)PositionGetInteger(POSITION_TIME);

            // 1. Dynamic Z-Score Reversion Exit (Only if net profitable above MinProfitPts)
            if(InpExitAtMean)
            {
               if(posType == POSITION_TYPE_BUY && currentZScore >= InpExitZTarget)
               {
                  if(bid >= openPrice + minProfitPrice)
                  {
                     trade.PositionClose(ticket);
                     continue;
                  }
               }
               else if(posType == POSITION_TYPE_SELL && currentZScore <= -InpExitZTarget)
               {
                  if(ask <= openPrice - minProfitPrice)
                  {
                     trade.PositionClose(ticket);
                     continue;
                  }
               }
            }

            // 2. Time-Based Exit (Only close stagnant trades if they are in profit or small loss)
            if(InpMaxHoldBars > 0 && periodSeconds > 0)
            {
               int barsHeld = (int)((TimeCurrent() - openTime) / periodSeconds);
               if(barsHeld >= InpMaxHoldBars)
               {
                  trade.PositionClose(ticket);
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Check if an open position already exists for this symbol/magic   |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == InpMagicNumber)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Dynamic Lot Size calculation (Fixed to Initial or Current Bal)   |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistancePrice)
{
   if(InpRiskPercent <= 0.0 || slDistancePrice <= 0.0)
      return InpFixedLot;

   double balance   = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney = balance * (InpRiskPercent / 100.0) * 0.90; // 10% buffer for ECN commission
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tickValue <= 0.0 || tickSize <= 0.0)
      return InpFixedLot;

   double slTicks = slDistancePrice / tickSize;
   double lots    = riskMoney / (slTicks * tickValue);

   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lots = MathFloor(lots / lotStep) * lotStep;
   if(lots < minLot) lots = minLot;
   if(lots > maxLot) lots = maxLot;

   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   double maBuf[], stdBuf[], rsiBuf[], atrBuf[], emaBuf[];
   ArraySetAsSeries(maBuf, true);
   ArraySetAsSeries(stdBuf, true);
   ArraySetAsSeries(rsiBuf, true);
   ArraySetAsSeries(atrBuf, true);
   ArraySetAsSeries(emaBuf, true);

   int slopeBars = MathMax(1, InpEMASlopeBars);

   if(CopyBuffer(handleMA, 0, 1, 1, maBuf) < 1) return;
   if(CopyBuffer(handleStdDev, 0, 1, 1, stdBuf) < 1) return;
   if(CopyBuffer(handleRSI, 0, 1, 1, rsiBuf) < 1) return;
   if(CopyBuffer(handleATR, 0, 1, 1, atrBuf) < 1) return;
   if(CopyBuffer(handleTrendEMA, 0, 1, slopeBars + 1, emaBuf) < slopeBars + 1) return;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, 3, rates) < 3) return;

   double closePrice = rates[1].close;
   double mean       = maBuf[0];
   double stdDev     = stdBuf[0];
   double rsi        = rsiBuf[0];
   double atr        = atrBuf[0];
   double trendEMA   = emaBuf[0];
   double prevEMA    = emaBuf[slopeBars];

   if(stdDev <= 0.0 || atr <= 0.0) return;

   // 1. Live Z-Score management for open positions
   if(HasOpenPosition())
   {
      double liveZScore = (rates[0].close - mean) / stdDev;
      ManageOpenPositions(liveZScore);
   }

   // 2. Execute new entries only on a new bar open
   if(rates[0].time == lastBarTime) return;
   lastBarTime = rates[0].time;

   if(HasOpenPosition()) return;

   // 3. Minimum Volatility Filter (Do not trade dead Asian markets where commission > profit)
   if(atr < InpMinATRPts * _Point) return;

   // 4. Spread & Session Filters
   if(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) > InpMaxSpreadPts) return;

   MqlDateTime dt;
   TimeCurrent(dt);
   if(dt.hour < InpStartHour || dt.hour >= InpEndHour) return;

   // 5. Fractal Regime Filter (Kaufman ER)
   double er = CalculateEfficiencyRatio(InpERPeriod, 1);
   if(er > InpMaxER) return;

   // 6. Z-Score on last closed bar (Exact v2 Entry Logic)
   double zScore = (closePrice - mean) / stdDev;

   // 7. Macro Trend Filter (Price above EMA 200 AND EMA 200 rising over N bars)
   // Also ensure Price is not more than 4 ATRs away from EMA (prevents buying blow-off tops before crash)
   double distFromEMA = MathAbs(closePrice - trendEMA);
   bool notOverextended = (distFromEMA < atr * 6.0);

   bool bullTrendOK = !InpUseTrendFilter || (closePrice > trendEMA && trendEMA > prevEMA && notOverextended);
   bool bearTrendOK = !InpUseTrendFilter || (closePrice < trendEMA && trendEMA < prevEMA && notOverextended);

   // Skip abnormal news spike bars
   double lastBarRange = rates[1].high - rates[1].low;
   if(lastBarRange > atr * 2.0) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double slDistance = atr * InpSLMultiplier;
   double tpDistance = atr * InpTPMultiplier;
   double lotSize    = CalculateLotSize(slDistance);

   // --- BUY SIGNAL (v2 Core) ---
   if(zScore <= -InpZThreshold && rsi < InpRSIOversold && bullTrendOK)
   {
      double sl = NormalizeDouble(ask - slDistance, _Digits);
      double tp = NormalizeDouble(ask + tpDistance, _Digits);
      trade.Buy(lotSize, _Symbol, ask, sl, tp, "FZMR v4 Buy | Z=" + DoubleToString(zScore, 2));
   }
   // --- SELL SIGNAL (v2 Core) ---
   else if(zScore >= InpZThreshold && rsi > InpRSIOverbought && bearTrendOK)
   {
      double sl = NormalizeDouble(bid + slDistance, _Digits);
      double tp = NormalizeDouble(bid - tpDistance, _Digits);
      trade.Sell(lotSize, _Symbol, bid, sl, tp, "FZMR v4 Sell | Z=" + DoubleToString(zScore, 2));
   }
}
//+------------------------------------------------------------------+

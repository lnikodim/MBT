//+------------------------------------------------------------------+
//|                                                 EMA_Cross_EA.mq5 |
//|              Simple EMA crossover EA with SL/TP and Magic Number |
//|                                          For MetaTrader 5 (MQL5) |
//+------------------------------------------------------------------+
#property copyright "Edgar Alexis Benitez"
#property version   "1.00"
#property description "Opens trades on a fast/slow EMA crossover. Evaluates signals on candle close."

#include <Trade/Trade.mqh>
CTrade trade;

//--- Input parameters
input int    InpFastEMA      = 9;         // Fast EMA period
input int    InpSlowEMA      = 21;        // Slow EMA period
input int    InpStopLoss     = 300;       // Stop Loss in points (0 = disabled)
input int    InpTakeProfit   = 600;       // Take Profit in points (0 = disabled)
input double InpLotSize      = 0.10;      // Fixed lot size
input ulong  InpMagicNumber  = 20260101;  // Magic number for this EA's trades

//--- Global variables
int      handleFastEMA;
int      handleSlowEMA;
datetime lastBarTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   handleFastEMA = iMA(_Symbol, _Period, InpFastEMA, 0, MODE_EMA, PRICE_CLOSE);
   handleSlowEMA = iMA(_Symbol, _Period, InpSlowEMA, 0, MODE_EMA, PRICE_CLOSE);

   if(handleFastEMA == INVALID_HANDLE || handleSlowEMA == INVALID_HANDLE)
     {
      Print("Error creating EMA indicators.");
      return(INIT_FAILED);
     }

   trade.SetExpertMagicNumber(InpMagicNumber);
   lastBarTime = 0;

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(handleFastEMA);
   IndicatorRelease(handleSlowEMA);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Only evaluate once per new candle (avoids duplicate signals within the same bar)
   datetime currentBarTime = iTime(_Symbol, _Period, 0);
   if(currentBarTime == lastBarTime)
      return;
   lastBarTime = currentBarTime;

   double fastEMA[3], slowEMA[3];
   if(CopyBuffer(handleFastEMA, 0, 1, 2, fastEMA) < 2) return;
   if(CopyBuffer(handleSlowEMA, 0, 1, 2, slowEMA) < 2) return;

   bool crossUp   = (fastEMA[0] <= slowEMA[0]) && (fastEMA[1] > slowEMA[1]);
   bool crossDown = (fastEMA[0] >= slowEMA[0]) && (fastEMA[1] < slowEMA[1]);

   // If there is already a position open by this EA, do nothing
   if(PositionSelect(_Symbol) && PositionGetInteger(POSITION_MAGIC) == (long)InpMagicNumber)
      return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double lot = NormalizeLot(InpLotSize);

   if(lot <= 0)
     {
      Print("Lot size invalid for this symbol's volume constraints. Trade skipped.");
      return;
     }

   if(crossUp)
     {
      double sl = (InpStopLoss > 0)   ? ask - InpStopLoss * point   : 0;
      double tp = (InpTakeProfit > 0) ? ask + InpTakeProfit * point : 0;
      trade.Buy(lot, _Symbol, ask, sl, tp, "EMA Cross Buy");
     }
   else if(crossDown)
     {
      double sl = (InpStopLoss > 0)   ? bid + InpStopLoss * point   : 0;
      double tp = (InpTakeProfit > 0) ? bid - InpTakeProfit * point : 0;
      trade.Sell(lot, _Symbol, bid, sl, tp, "EMA Cross Sell");
     }
  }

//+------------------------------------------------------------------+
//| Normalize lot size to the symbol's min/max/step constraints      |
//+------------------------------------------------------------------+
double NormalizeLot(double requestedLot)
  {
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(stepLot <= 0) stepLot = minLot;

   double normalized = MathRound(requestedLot / stepLot) * stepLot;

   if(normalized < minLot) normalized = minLot;
   if(normalized > maxLot) normalized = maxLot;

   return(normalized);
  }
//+------------------------------------------------------------------+

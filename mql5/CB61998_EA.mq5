//+------------------------------------------------------------------+
//|      TradingLab_Best_MACD_Strategy.mq5                           |
//|      Author: Mueller Peter                                       |
//|      https://www.mql5.com/en/users/mullerp04/seller              |
//+------------------------------------------------------------------+

#property copyright "Mueller Peter"
#property link      "https://www.mql5.com/en/users/mullerp04/seller"
#property version   "1.00"

#include <ExpertFunctions.mqh> // Contains utility functions like CheckVolumeValue()

//--- Input parameters
input int SignalValidity = 7;               // Number of candles for which a signal remains valid
input double Lotsize = 1;                   // Trade lot size
input int SLPointDistanceFromMA = 50;       // Distance in points from the MA for stop loss placement

//--- Indicator handles
int MAHandle, MACDHandle, SuppResHandle;

//--- Buffers to store indicator values
double MACDFastBuffer[2], MACDSlowBuffer[2];
double MABuffer[1], SuppBuffer[1], ResBuffer[1];

//+------------------------------------------------------------------+
//| Initialization function                                          |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Load custom Support/Resistance indicator with parameters: high=20, low=10
   SuppResHandle = iCustom(_Symbol, PERIOD_CURRENT, "SupportResistance", 20, 10);

   // 200-period Exponential Moving Average
   MAHandle = iMA(_Symbol, PERIOD_CURRENT, 200, 0, MODE_EMA, PRICE_CLOSE);

   // Standard MACD: Fast=12, Slow=26, Signal=9
   MACDHandle = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Deinitialization function                                        |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // No resources need manual release
  }

//+------------------------------------------------------------------+
//| Main tick handler                                                |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Only process on new candles
   if(!IsNewCandle())
      return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_BID); // Get current ask price
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID); // Get current bid price

   // Signal timers (how long a signal remains valid)
   static int ResistanceTouch = 0;
   static int SupportTouch = 0;
   static int MACDDownSig = 0;
   static int MACDUpSig = 0;

   static CTrade trade; // Trade object for executing orders

   // Load indicator values into buffers
   if(CopyBuffer(MACDHandle, 0, 1, 2, MACDFastBuffer) <= 0 ||
      CopyBuffer(MACDHandle, 1, 1, 2, MACDSlowBuffer) <= 0 ||
      CopyBuffer(MAHandle, 0, 1, 1, MABuffer) <= 0 ||
      CopyBuffer(SuppResHandle, 0, 1, 1, ResBuffer) <= 0 ||
      CopyBuffer(SuppResHandle, 1, 1, 1, SuppBuffer) <= 0)
   {
      Print("Error loading indicator buffers");
      return;
   }

   // Decrease signal timers each candle
   if(ResistanceTouch)
      ResistanceTouch--;
   if(SupportTouch)
      SupportTouch--;   
   if(MACDDownSig)
      MACDDownSig--;
   if(MACDUpSig)
      MACDUpSig--;

   // Check if price touched resistance in previous candle
   if(ResBuffer[0] != EMPTY_VALUE && iHigh(_Symbol, PERIOD_CURRENT, 1) > ResBuffer[0])
      ResistanceTouch = SignalValidity;

   // Check if price touched support in previous candle
   if(SuppBuffer[0] != EMPTY_VALUE && iLow(_Symbol, PERIOD_CURRENT, 1) < SuppBuffer[0])
      SupportTouch = SignalValidity;

   // Detect bullish MACD crossover below 0
   if(MACDFastBuffer[0] > MACDSlowBuffer[0] && MACDFastBuffer[1] < MACDSlowBuffer[1] && MACDFastBuffer[0] < 0)
      MACDUpSig = SignalValidity;

   // Detect bearish MACD crossover above 0
   if(MACDFastBuffer[0] < MACDSlowBuffer[0] && MACDFastBuffer[1] > MACDSlowBuffer[1] && MACDFastBuffer[0] > 0)
      MACDDownSig = SignalValidity;

   // --- Buy condition ---
   if(MACDUpSig && SupportTouch && MABuffer[0] < ask &&
      (MACDUpSig == SignalValidity || SupportTouch == SignalValidity))
   {
      if(!CheckVolumeValue(Lotsize))
         return;

      // Calculate SL and TP
      double Sl = MABuffer[0] - SLPointDistanceFromMA * _Point;
      double Tp = ask + (ask - MABuffer[0] + SLPointDistanceFromMA * _Point) * 1.5;

      trade.Buy(Lotsize, _Symbol, 0, Sl, Tp);
   }

   // --- Sell condition ---
   if(MACDDownSig && ResistanceTouch && MABuffer[0] > ask &&
      (MACDDownSig == SignalValidity || ResistanceTouch == SignalValidity))
   {
      if(!CheckVolumeValue(Lotsize))
         return;

      // Calculate SL and TP
      double Sl = MABuffer[0] + SLPointDistanceFromMA * _Point;
      double Tp = bid - (MABuffer[0] - bid + SLPointDistanceFromMA * _Point) * 1.5;

      trade.Sell(Lotsize, _Symbol, 0, Sl, Tp);
   }
}

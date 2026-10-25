//+------------------------------------------------------------------+
//| Butterfly Strategy Expert Advisor                                |
//+------------------------------------------------------------------+
#property copyright "User"
#property version   "2.00"
#property description "This EA trades based on Butterfly Strategy with multiple TP levels"
#property strict

#include <Trade\Trade.mqh>
CTrade trade;

input group "----- Basic Pattern Parameters -----"
input int    PivotLeft    = 1;      // Number of bars to the left for pivot check
input int    PivotRight   = 1;      // Number of bars to the right for pivot check
input double Tolerance    = 0.10;   // Allowed deviation (10% of XA move)
input bool   AllowTrading = true;   // Enable or disable trading

input group "----- Risk Management Parameters -----"
input bool   UseFixedLots = true;   // Use fixed lot size or calculate based on risk
input double LotSize      = 0.01;   // Fixed lot size for trades (if UseFixedLots = true)
input double RiskPercent = 1.0;     // Risk percentage per trade (of account balance)
input bool   AdjustLotsForTP = true; // Adjust lot distribution for take profits
input double TP1Percent = 50.0;     // Percentage of position to close at TP1
input double TP2Percent = 30.0;     // Percentage of position to close at TP2
input double TP3Percent = 20.0;     // Percentage of position to close at TP3

input group "----- Pattern Quality Parameters -----"
input double MinPatternQuality = 0.1;  // Minimum pattern quality score (0.0-1.0)

input group "----- Trading Session Filter -----"
input bool   UseSessionFilter = false;  // Use trading session filter
input int    SessionStartHour = 8;      // Session start hour (GMT)
input int    SessionEndHour = 16;       // Session end hour (GMT)

input group "----- Pattern Revalidation -----"
input bool   RevalidatePattern = false;  // Revalidate pattern before trading

input group "----- Timeframe Selection -----"
input bool   Use_M2        = true;    // Use 2-minute timeframe
input bool   Use_M5        = false;    // Use 5-minute timeframe
input bool   Use_M10       = false;    // Use 10-minute timeframe
input bool   Use_M15       = false;    // Use 15-minute timeframe
input bool   Use_M30       = false;    // Use 30-minute timeframe
input bool   Use_H1        = false;    // Use 1-hour timeframe
input bool   Use_H2        = false;    // Use 2-hour timeframe
input bool   Use_H4        = false;    // Use 4-hour timeframe
input bool   Use_D1        = false;    // Use Daily timeframe

input group "----- Magic Number for identifying EA trades -----"
input int    MagicNumber = 123456;      // Magic number for order identification

// Define timeframe-specific parameters for each timeframe
input group "----- M2 Parameters -----"
input bool   M2_UseBreakEven = false;     // Activate break-even stop
input int    M2_BreakEvenAfterTP = 1;     // Activate break-even after which TP (1 or 2)
input double M2_BreakEvenTrigger = 30;    // Points required to move stop to break-even
input double M2_BreakEvenProfit = 5;      // Points profit after break-even is triggered
input bool   M2_UseTrailingStop = false;  // Use trailing stop
input int    M2_TrailAfterTP = 2;         // Start trailing after which TP (1 or 2)
input double M2_TrailStart = 20.0;        // Points required to start trailing
input double M2_TrailStep = 5.0;          // Trail step size in points

input group "----- M5 Parameters -----"
input bool   M5_UseBreakEven = false;     // Activate break-even stop
input int    M5_BreakEvenAfterTP = 1;     // Activate break-even after which TP (1 or 2)
input double M5_BreakEvenTrigger = 30;    // Points required to move stop to break-even
input double M5_BreakEvenProfit = 5;      // Points profit after break-even is triggered
input bool   M5_UseTrailingStop = false;  // Use trailing stop
input int    M5_TrailAfterTP = 2;         // Start trailing after which TP (1 or 2)
input double M5_TrailStart = 20.0;        // Points required to start trailing
input double M5_TrailStep = 5.0;          // Trail step size in points

input group "----- M10 Parameters -----"
input bool   M10_UseBreakEven = false;     // Activate break-even stop
input int    M10_BreakEvenAfterTP = 1;     // Activate break-even after which TP (1 or 2)
input double M10_BreakEvenTrigger = 30;    // Points required to move stop to break-even
input double M10_BreakEvenProfit = 5;      // Points profit after break-even is triggered
input bool   M10_UseTrailingStop = false;  // Use trailing stop
input int    M10_TrailAfterTP = 2;         // Start trailing after which TP (1 or 2)
input double M10_TrailStart = 20.0;        // Points required to start trailing
input double M10_TrailStep = 5.0;          // Trail step size in points

input group "----- M15 Parameters -----"
input bool   M15_UseBreakEven = false;     // Activate break-even stop
input int    M15_BreakEvenAfterTP = 1;     // Activate break-even after which TP (1 or 2)
input double M15_BreakEvenTrigger = 30;    // Points required to move stop to break-even
input double M15_BreakEvenProfit = 5;      // Points profit after break-even is triggered
input bool   M15_UseTrailingStop = false;  // Use trailing stop
input int    M15_TrailAfterTP = 2;         // Start trailing after which TP (1 or 2)
input double M15_TrailStart = 20.0;        // Points required to start trailing
input double M15_TrailStep = 5.0;          // Trail step size in points

input group "----- M30 Parameters -----"
input bool   M30_UseBreakEven = false;     // Activate break-even stop
input int    M30_BreakEvenAfterTP = 1;     // Activate break-even after which TP (1 or 2)
input double M30_BreakEvenTrigger = 30;    // Points required to move stop to break-even
input double M30_BreakEvenProfit = 5;      // Points profit after break-even is triggered
input bool   M30_UseTrailingStop = false;  // Use trailing stop
input int    M30_TrailAfterTP = 2;         // Start trailing after which TP (1 or 2)
input double M30_TrailStart = 20.0;        // Points required to start trailing
input double M30_TrailStep = 5.0;          // Trail step size in points

input group "----- H1 Parameters -----"
input bool   H1_UseBreakEven = false;     // Activate break-even stop
input int    H1_BreakEvenAfterTP = 1;     // Activate break-even after which TP (1 or 2)
input double H1_BreakEvenTrigger = 30;    // Points required to move stop to break-even
input double H1_BreakEvenProfit = 5;      // Points profit after break-even is triggered
input bool   H1_UseTrailingStop = false;  // Use trailing stop
input int    H1_TrailAfterTP = 2;         // Start trailing after which TP (1 or 2)
input double H1_TrailStart = 20.0;        // Points required to start trailing
input double H1_TrailStep = 5.0;          // Trail step size in points

input group "----- H2 Parameters -----"
input bool   H2_UseBreakEven = false;     // Activate break-even stop
input int    H2_BreakEvenAfterTP = 1;     // Activate break-even after which TP (1 or 2)
input double H2_BreakEvenTrigger = 30;    // Points required to move stop to break-even
input double H2_BreakEvenProfit = 5;      // Points profit after break-even is triggered
input bool   H2_UseTrailingStop = false;  // Use trailing stop
input int    H2_TrailAfterTP = 2;         // Start trailing after which TP (1 or 2)
input double H2_TrailStart = 20.0;        // Points required to start trailing
input double H2_TrailStep = 5.0;          // Trail step size in points

input group "----- H4 Parameters -----"
input bool   H4_UseBreakEven = false;     // Activate break-even stop
input int    H4_BreakEvenAfterTP = 1;     // Activate break-even after which TP (1 or 2)
input double H4_BreakEvenTrigger = 30;    // Points required to move stop to break-even
input double H4_BreakEvenProfit = 5;      // Points profit after break-even is triggered
input bool   H4_UseTrailingStop = false;  // Use trailing stop
input int    H4_TrailAfterTP = 2;         // Start trailing after which TP (1 or 2)
input double H4_TrailStart = 20.0;        // Points required to start trailing
input double H4_TrailStep = 5.0;          // Trail step size in points

input group "----- D1 Parameters -----"
input bool   D1_UseBreakEven = false;     // Activate break-even stop
input int    D1_BreakEvenAfterTP = 1;     // Activate break-even after which TP (1 or 2)
input double D1_BreakEvenTrigger = 30;    // Points required to move stop to break-even
input double D1_BreakEvenProfit = 5;      // Points profit after break-even is triggered
input bool   D1_UseTrailingStop = false;  // Use trailing stop
input int    D1_TrailAfterTP = 2;         // Start trailing after which TP (1 or 2)
input double D1_TrailStart = 20.0;        // Points required to start trailing
input double D1_TrailStep = 5.0;          // Trail step size in points

// Structure to hold timeframe-specific parameters
struct TimeframeParams
  {
   bool              UseBreakEven;
   int               BreakEvenAfterTP;
   double            BreakEvenTrigger;
   double            BreakEvenProfit;
   bool              UseTrailingStop;
   int               TrailAfterTP;
   double            TrailStart;
   double            TrailStep;
  };

struct Pivot
  {
   datetime          time;
   double            price;
   bool              isHigh;
  };

Pivot pivots[];

TimeframeParams tfParams[9]; // Array to hold parameters for each timeframe
ENUM_TIMEFRAMES timeframes[9] = {PERIOD_M2, PERIOD_M5, PERIOD_M10, PERIOD_M15, PERIOD_M30, PERIOD_H1, PERIOD_H2, PERIOD_H4, PERIOD_D1};
bool timeframeEnabled[9] = {false, false, false, false, false, false, false, false, false};
string timeframeNames[9] = {"M2", "M5", "M10", "M15", "M30", "H1", "H2", "H4", "D1"};

// For each timeframe, we need pattern detection status variables
struct PatternStatus
  {
   int               formationBar;
   datetime          lockedPatternX;
  };
PatternStatus patternStatus[9];

// Statistics
int totalTrades = 0;
int winTrades = 0;
int lossTrades = 0;
double totalProfit = 0.0;
double totalLoss = 0.0;
double maxDrawdown = 0.0;
double peakBalance = 0.0;

//+------------------------------------------------------------------+
//| Draw a filled triangle                                           |
//+------------------------------------------------------------------+
void DrawTriangle(string name, datetime t1, double p1, datetime t2, double p2, datetime t3, double p3, color cl, int width, bool fill, bool back)
  {
   if(ObjectCreate(0, name, OBJ_TRIANGLE, 0, t1, p1, t2, p2, t3, p3))
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, cl);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
      ObjectSetInteger(0, name, OBJPROP_FILL, fill);
      ObjectSetInteger(0, name, OBJPROP_BACK, back);
      ChartRedraw();
     }
  }

//+------------------------------------------------------------------+
//| Draw a trend line                                                |
//+------------------------------------------------------------------+
void DrawTrendLine(string name, datetime t1, double p1, datetime t2, double p2, color cl, int width, int style)
  {
   if(ObjectCreate(0, name, OBJ_TREND, 0, t1, p1, t2, p2))
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, cl);
      ObjectSetInteger(0, name, OBJPROP_STYLE, style);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
      ChartRedraw();
     }
  }

//+------------------------------------------------------------------+
//| Draw a dotted trend line                                         |
//+------------------------------------------------------------------+
void DrawDottedLine(string name, datetime t1, double p, datetime t2, color lineColor)
  {
   if(ObjectCreate(0, name, OBJ_TREND, 0, t1, p, t2, p))
     {
      ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ChartRedraw();
     }
  }

//+------------------------------------------------------------------+
//| Draw anchored text label (for pivots)                            |
//+------------------------------------------------------------------+
void DrawTextEx(string name, string text, datetime t, double p, color cl, int fontsize, bool isHigh)
  {
   if(ObjectCreate(0, name, OBJ_TEXT, 0, t, p))
     {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, cl);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontsize);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
      if(isHigh)
         ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_BOTTOM);
      else
         ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_TOP);
      ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
      ChartRedraw();
     }
  }

//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                      |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLossPrice, double entryPrice)
{
   double lotSize;
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(UseFixedLots)
   {
      lotSize = LotSize;
   }
   else
   {
      double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * (RiskPercent / 100.0);
      double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double pointValue = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double stopLossPips = MathAbs(stopLossPrice - entryPrice) / pointValue;
      
      double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      double pricePerPip = tickValue * (pointValue / tickSize);
      lotSize = NormalizeDouble(riskAmount / (stopLossPips * pricePerPip), 2);
   }

   // Ensure lot size is within symbol limits
   lotSize = MathMax(minLot, MathMin(maxLot, NormalizeDouble(lotSize / lotStep, 0) * lotStep));

   return lotSize;
}

//+------------------------------------------------------------------+
//| Assess pattern quality (0.0 to 1.0)                             |
//+------------------------------------------------------------------+
double AssessPatternQuality(const Pivot &X, const Pivot &A, const Pivot &B, const Pivot &C, const Pivot &D, string patternType)
  {
   double score = 1.0;
   double diff = patternType == "Bullish" ? A.price - X.price : X.price - A.price;

// Check B retracement quality (should be close to 0.786)
   double idealB = patternType == "Bullish" ? A.price - 0.786 * diff : A.price + 0.786 * diff;
   double bDeviation = MathAbs(B.price - idealB) / diff;
   score -= bDeviation * 0.2; // Penalize up to 20% for B deviation

// Check C retracement quality (should be between 0.382 and 0.886)
   double idealC = patternType == "Bullish" ?
                   B.price + 0.618 * (A.price - B.price) :
                   B.price - 0.618 * (B.price - A.price);
   double cDeviation = MathAbs(C.price - idealC) / diff;
   score -= cDeviation * 0.2; // Penalize up to 20% for C deviation

// Check D extension quality (should be close to 1.27-1.618)
   double idealD = patternType == "Bullish" ?
                   C.price - 1.414 * (C.price - B.price) :
                   C.price + 1.414 * (B.price - C.price);
   double dDeviation = MathAbs(D.price - idealD) / diff;
   score -= dDeviation * 0.2; // Penalize up to 20% for D deviation

// Check time symmetry
   double timeRatioAB_CD = (double)(B.time - A.time) / (double)(D.time - C.time);
   double timeDeviationAB_CD = MathAbs(1.0 - timeRatioAB_CD);
   score -= timeDeviationAB_CD * 0.1; // Penalize up to 10% for time asymmetry

   double timeRatioXA_BC = (double)(A.time - X.time) / (double)(C.time - B.time);
   double timeDeviationXA_BC = MathAbs(1.0 - timeRatioXA_BC);
   score -= timeDeviationXA_BC * 0.1; // Penalize up to 10% for time asymmetry

// Ensure score stays between 0 and 1
   score = MathMax(0.0, MathMin(1.0, score));

   Print("Pattern quality score: ", score);
   return score;
  }

//+------------------------------------------------------------------+
//| Check if current time is within trading session                  |
//+------------------------------------------------------------------+
bool IsWithinSession()
  {
   if(!UseSessionFilter)
      return true;

   datetime serverTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(serverTime, dt);
   int currentHour = dt.hour;

   if(SessionStartHour < SessionEndHour)
     {
      // Simple case - session within same day
      return (currentHour >= SessionStartHour && currentHour < SessionEndHour);
     }
   else
     {
      // Session spans midnight
      return (currentHour >= SessionStartHour || currentHour < SessionEndHour);
     }
  }

//+------------------------------------------------------------------+
//| Revalidate pattern before trading                                |
//+------------------------------------------------------------------+
bool RevalidatePatternBeforeTrading(const Pivot &X, const Pivot &A, const Pivot &B, const Pivot &C, const Pivot &D, string patternType)
  {
   if(!RevalidatePattern)
      return true;

   double currentPrice = iClose(_Symbol, PERIOD_CURRENT, 0);
   double expectedDirection = (patternType == "Bullish") ? 1 : -1;
   double priceMovement = (currentPrice - D.price) * expectedDirection;

// Check if price has moved against expected direction
   if(priceMovement < 0)
     {
      Print("Pattern invalidated: Price moved against expected direction");
      return false;
     }

// Check if price has moved too far in expected direction
   double diff = patternType == "Bullish" ? A.price - X.price : X.price - A.price;
   if(MathAbs(priceMovement) > 0.3 * diff)
     {
      Print("Pattern invalidated: Price moved too far from pattern completion point");
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Manage break-even stops for open positions                       |
//+------------------------------------------------------------------+
void ManageBreakEvenStops()
  {
// Check if any timeframe has break-even enabled
   bool anyBreakEvenEnabled = false;
   for(int i = 0; i < 9; i++)
     {
      if(timeframeEnabled[i] && tfParams[i].UseBreakEven)
        {
         anyBreakEvenEnabled = true;
         break;
        }
     }

   if(!anyBreakEvenEnabled)
      return;

// Count how many EA positions are open
   int totalEAPositions = 0;
   for(int j = PositionsTotal() - 1; j >= 0; j--)
     {
      ulong checkTicket = PositionGetTicket(j);
      if(PositionSelectByTicket(checkTicket))
        {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol)
            totalEAPositions++;
        }
     }

// Determine if TP1 or TP2 has been hit based on remaining positions
   bool tp1Hit = (totalEAPositions < 3); // Started with 3, so if fewer than 3 remain, TP1 hit
   bool tp2Hit = (totalEAPositions < 2); // If fewer than 2 remain, TP2 hit

// Process each position for break-even
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket))
         continue;

      // Check if position belongs to this EA
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber || PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      // Get timeframe index from position comment
      string comment = PositionGetString(POSITION_COMMENT);
      int tfIndex = GetTimeframeIndexFromComment(comment);

      // Skip if no valid timeframe or break-even is disabled for this timeframe
      if(tfIndex == -1 || !tfParams[tfIndex].UseBreakEven)
         continue;

      // Apply break-even based on timeframe-specific preference
      bool applyBreakEven = false;
      if(tfParams[tfIndex].BreakEvenAfterTP == 1 && tp1Hit)
        {
         applyBreakEven = true;
        }
      else
         if(tfParams[tfIndex].BreakEvenAfterTP == 2 && tp2Hit)
           {
            applyBreakEven = true;
           }

      if(!applyBreakEven)
         continue;

      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double currentPrice = (posType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentStopLoss = PositionGetDouble(POSITION_SL);
      double newStopLoss = 0;

      // For BUY positions
      if(posType == POSITION_TYPE_BUY)
        {
         double priceDifference = currentPrice - openPrice;
         if(priceDifference >= tfParams[tfIndex].BreakEvenTrigger * _Point)
           {
            newStopLoss = openPrice + tfParams[tfIndex].BreakEvenProfit * _Point;
            if(newStopLoss > currentStopLoss || currentStopLoss == 0)
              {
               trade.PositionModify(ticket, newStopLoss, PositionGetDouble(POSITION_TP));
               if(trade.ResultRetcode() != TRADE_RETCODE_DONE)
                  Print("Error modifying break-even stop for ", timeframeNames[tfIndex], ": ", trade.ResultRetcodeDescription());
               else
                  Print("Break-even stop applied at: ", newStopLoss, " for ", timeframeNames[tfIndex]);
              }
           }
        }
      // For SELL positions
      else
         if(posType == POSITION_TYPE_SELL)
           {
            double priceDifference = openPrice - currentPrice;
            if(priceDifference >= tfParams[tfIndex].BreakEvenTrigger * _Point)
              {
               newStopLoss = openPrice - tfParams[tfIndex].BreakEvenProfit * _Point;
               if(newStopLoss < currentStopLoss || currentStopLoss == 0)
                 {
                  trade.PositionModify(ticket, newStopLoss, PositionGetDouble(POSITION_TP));
                  if(trade.ResultRetcode() != TRADE_RETCODE_DONE)
                     Print("Error modifying break-even stop for ", timeframeNames[tfIndex], ": ", trade.ResultRetcodeDescription());
                  else
                     Print("Break-even stop applied at: ", newStopLoss, " for ", timeframeNames[tfIndex]);
                 }
              }
           }
     }
  }

//+------------------------------------------------------------------+
//| Manage trailing stops for open positions                         |
//+------------------------------------------------------------------+
void ManageTrailingStops()
  {
// Check if any timeframe has trailing stop enabled
   bool anyTrailingEnabled = false;
   for(int i = 0; i < 9; i++)
     {
      if(timeframeEnabled[i] && tfParams[i].UseTrailingStop)
        {
         anyTrailingEnabled = true;
         break;
        }
     }

   if(!anyTrailingEnabled)
      return;

// Count how many EA positions are open
   int totalEAPositions = 0;
   for(int j = PositionsTotal() - 1; j >= 0; j--)
     {
      ulong checkTicket = PositionGetTicket(j);
      if(PositionSelectByTicket(checkTicket))
        {
         if(PositionGetInteger(POSITION_MAGIC) == MagicNumber && PositionGetString(POSITION_SYMBOL) == _Symbol)
            totalEAPositions++;
        }
     }

// Determine if TP1 or TP2 has been hit based on remaining positions
   bool tp1Hit = (totalEAPositions < 3); // Started with 3, so if fewer than 3 remain, TP1 hit
   bool tp2Hit = (totalEAPositions < 2); // If fewer than 2 remain, TP2 hit

// Process each position for trailing stop
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket))
         continue;

      // Check if position belongs to this EA
      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber || PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      // Get timeframe index from position comment
      string comment = PositionGetString(POSITION_COMMENT);
      int tfIndex = GetTimeframeIndexFromComment(comment);

      // Skip if no valid timeframe or trailing stop is disabled for this timeframe
      if(tfIndex == -1 || !tfParams[tfIndex].UseTrailingStop)
         continue;

      // Apply trailing stop based on timeframe-specific preference
      bool applyTrailing = false;
      if(tfParams[tfIndex].TrailAfterTP == 1 && tp1Hit)
        {
         applyTrailing = true;
        }
      else
         if(tfParams[tfIndex].TrailAfterTP == 2 && tp2Hit)
           {
            applyTrailing = true;
           }

      if(!applyTrailing)
         continue;

      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double currentPrice = (posType == POSITION_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_BID) : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentStopLoss = PositionGetDouble(POSITION_SL);
      double newStopLoss = 0;

      // For BUY positions
      if(posType == POSITION_TYPE_BUY)
        {
         double priceDifference = currentPrice - openPrice;
         if(priceDifference >= tfParams[tfIndex].TrailStart * _Point)
           {
            newStopLoss = currentPrice - tfParams[tfIndex].TrailStep * _Point;
            if(newStopLoss > currentStopLoss + _Point || currentStopLoss == 0)
              {
               trade.PositionModify(ticket, newStopLoss, PositionGetDouble(POSITION_TP));
               if(trade.ResultRetcode() != TRADE_RETCODE_DONE)
                  Print("Error modifying trailing stop for ", timeframeNames[tfIndex], ": ", trade.ResultRetcodeDescription());
               else
                  Print("Trailing stop updated to: ", newStopLoss, " for ", timeframeNames[tfIndex]);
              }
           }
        }
      // For SELL positions
      else
         if(posType == POSITION_TYPE_SELL)
           {
            double priceDifference = openPrice - currentPrice;
            if(priceDifference >= tfParams[tfIndex].TrailStart * _Point)
              {
               newStopLoss = currentPrice + tfParams[tfIndex].TrailStep * _Point;
               if(newStopLoss < currentStopLoss - _Point || currentStopLoss == 0)
                 {
                  trade.PositionModify(ticket, newStopLoss, PositionGetDouble(POSITION_TP));
                  if(trade.ResultRetcode() != TRADE_RETCODE_DONE)
                     Print("Error modifying trailing stop for ", timeframeNames[tfIndex], ": ", trade.ResultRetcodeDescription());
                  else
                     Print("Trailing stop updated to: ", newStopLoss, " for ", timeframeNames[tfIndex]);
                 }
              }
           }
     }
  }

//+------------------------------------------------------------------+
//| Update trading statistics                                        |
//+------------------------------------------------------------------+
void UpdateStatistics()
  {
// Update peak balance and drawdown
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   if(currentBalance > peakBalance)
      peakBalance = currentBalance;

   double currentDrawdown = peakBalance - currentBalance;
   if(currentDrawdown > maxDrawdown)
      maxDrawdown = currentDrawdown;

// Reset statistics to avoid double-counting
   totalTrades = 0;
   winTrades = 0;
   lossTrades = 0;
   totalProfit = 0.0;
   totalLoss = 0.0;

// Select trade history for the current symbol and magic number
   datetime fromDate = 0; // Start from the beginning of history
   datetime toDate = TimeCurrent();
   if(!HistorySelect(fromDate, toDate))
     {
      Print("Failed to select trade history: ", GetLastError());
      return;
     }

// Iterate through closed deals
   int dealsTotal = HistoryDealsTotal();
   for(int i = 0; i < dealsTotal; i++)
     {
      ulong dealTicket = HistoryDealGetTicket(i);
      if(dealTicket == 0)
         continue;

      // Check if deal belongs to this EA (same symbol and magic number)
      if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol)
         continue;
      if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != MagicNumber)
         continue;

      // Get deal properties
      double dealProfit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
      long dealType = HistoryDealGetInteger(dealTicket, DEAL_TYPE);
      long dealEntry = HistoryDealGetInteger(dealTicket, DEAL_ENTRY);

      // Only process closed deals (DEAL_ENTRY_OUT)
      if(dealEntry != DEAL_ENTRY_OUT)
         continue;

      // Increment total trades
      totalTrades++;

      // Update win/loss and profit/loss
      if(dealProfit > 0)
        {
         winTrades++;
         totalProfit += dealProfit;
        }
      else
         if(dealProfit < 0)
           {
            lossTrades++;
            totalLoss += MathAbs(dealProfit);
           }
     }
  }

//+------------------------------------------------------------------+
//| Display dashboard with trading statistics                        |
//+------------------------------------------------------------------+
void ShowDashboard()
  {
   UpdateStatistics();

   string stats = "";
   stats += "---- BUTTERFLY EA STATS ----\n";
   stats += "Total Trades: " + IntegerToString(totalTrades) + "\n";

   double winRate = (totalTrades > 0) ? (double)winTrades / totalTrades * 100.0 : 0;
   stats += "Win Rate: " + DoubleToString(winRate, 2) + "%\n";

   stats += "Wins/Losses: " + IntegerToString(winTrades) + "/" + IntegerToString(lossTrades) + "\n";
   stats += "Total Profit: " + DoubleToString(totalProfit, 2) + "\n";
   stats += "Total Loss: " + DoubleToString(totalLoss, 2) + "\n";

   double avgProfit = (winTrades > 0) ? totalProfit / winTrades : 0;
   double avgLoss = (lossTrades > 0) ? totalLoss / lossTrades : 0;

   stats += "Avg Profit: " + DoubleToString(avgProfit, 2) + "\n";
   stats += "Avg Loss: " + DoubleToString(avgLoss, 2) + "\n";
   stats += "Max Drawdown: " + DoubleToString(maxDrawdown, 2) + "\n";
   stats += "--------------------------\n";

   Comment(stats);
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);

// Initialize statistics values
   peakBalance = AccountInfoDouble(ACCOUNT_BALANCE);

// Set timeframe enabled flags
   timeframeEnabled[0] = Use_M2;
   timeframeEnabled[1] = Use_M5;
   timeframeEnabled[2] = Use_M10;
   timeframeEnabled[3] = Use_M15;
   timeframeEnabled[4] = Use_M30;
   timeframeEnabled[5] = Use_H1;
   timeframeEnabled[6] = Use_H2;
   timeframeEnabled[7] = Use_H4;
   timeframeEnabled[8] = Use_D1;

// Initialize pattern status for each timeframe
   for(int i = 0; i < 9; i++)
     {
      patternStatus[i].formationBar = -1;
      patternStatus[i].lockedPatternX = 0;
     }

// Setup timeframe-specific parameters
// M2 Parameters
   tfParams[0].UseBreakEven = M2_UseBreakEven;
   tfParams[0].BreakEvenAfterTP = M2_BreakEvenAfterTP;
   tfParams[0].BreakEvenTrigger = M2_BreakEvenTrigger;
   tfParams[0].BreakEvenProfit = M2_BreakEvenProfit;
   tfParams[0].UseTrailingStop = M2_UseTrailingStop;
   tfParams[0].TrailAfterTP = M2_TrailAfterTP;
   tfParams[0].TrailStart = M2_TrailStart;
   tfParams[0].TrailStep = M2_TrailStep;

// M5 Parameters
   tfParams[1].UseBreakEven = M5_UseBreakEven;
   tfParams[1].BreakEvenAfterTP = M5_BreakEvenAfterTP;
   tfParams[1].BreakEvenTrigger = M5_BreakEvenTrigger;
   tfParams[1].BreakEvenProfit = M5_BreakEvenProfit;
   tfParams[1].UseTrailingStop = M5_UseTrailingStop;
   tfParams[1].TrailAfterTP = M5_TrailAfterTP;
   tfParams[1].TrailStart = M5_TrailStart;
   tfParams[1].TrailStep = M5_TrailStep;

// M10 Parameters
   tfParams[2].UseBreakEven = M10_UseBreakEven;
   tfParams[2].BreakEvenAfterTP = M10_BreakEvenAfterTP;
   tfParams[2].BreakEvenTrigger = M10_BreakEvenTrigger;
   tfParams[2].BreakEvenProfit = M10_BreakEvenProfit;
   tfParams[2].UseTrailingStop = M10_UseTrailingStop;
   tfParams[2].TrailAfterTP = M10_TrailAfterTP;
   tfParams[2].TrailStart = M10_TrailStart;
   tfParams[2].TrailStep = M10_TrailStep;

// M15 Parameters
   tfParams[3].UseBreakEven = M15_UseBreakEven;
   tfParams[3].BreakEvenAfterTP = M15_BreakEvenAfterTP;
   tfParams[3].BreakEvenTrigger = M15_BreakEvenTrigger;
   tfParams[3].BreakEvenProfit = M15_BreakEvenProfit;
   tfParams[3].UseTrailingStop = M15_UseTrailingStop;
   tfParams[3].TrailAfterTP = M15_TrailAfterTP;
   tfParams[3].TrailStart = M15_TrailStart;
   tfParams[3].TrailStep = M15_TrailStep;

// M30 Parameters
   tfParams[4].UseBreakEven = M30_UseBreakEven;
   tfParams[4].BreakEvenAfterTP = M30_BreakEvenAfterTP;
   tfParams[4].BreakEvenTrigger = M30_BreakEvenTrigger;
   tfParams[4].BreakEvenProfit = M30_BreakEvenProfit;
   tfParams[4].UseTrailingStop = M30_UseTrailingStop;
   tfParams[4].TrailAfterTP = M30_TrailAfterTP;
   tfParams[4].TrailStart = M30_TrailStart;
   tfParams[4].TrailStep = M30_TrailStep;

// H1 Parameters
   tfParams[5].UseBreakEven = H1_UseBreakEven;
   tfParams[5].BreakEvenAfterTP = H1_BreakEvenAfterTP;
   tfParams[5].BreakEvenTrigger = H1_BreakEvenTrigger;
   tfParams[5].BreakEvenProfit = H1_BreakEvenProfit;
   tfParams[5].UseTrailingStop = H1_UseTrailingStop;
   tfParams[5].TrailAfterTP = H1_TrailAfterTP;
   tfParams[5].TrailStart = H1_TrailStart;
   tfParams[5].TrailStep = H1_TrailStep;

// H2 Parameters
   tfParams[6].UseBreakEven = H2_UseBreakEven;
   tfParams[6].BreakEvenAfterTP = H2_BreakEvenAfterTP;
   tfParams[6].BreakEvenTrigger = H2_BreakEvenTrigger;
   tfParams[6].BreakEvenProfit = H2_BreakEvenProfit;
   tfParams[6].UseTrailingStop = H2_UseTrailingStop;
   tfParams[6].TrailAfterTP = H2_TrailAfterTP;
   tfParams[6].TrailStart = H2_TrailStart;
   tfParams[6].TrailStep = H2_TrailStep;

// H4 Parameters
   tfParams[7].UseBreakEven = H4_UseBreakEven;
   tfParams[7].BreakEvenAfterTP = H4_BreakEvenAfterTP;
   tfParams[7].BreakEvenTrigger = H4_BreakEvenTrigger;
   tfParams[7].BreakEvenProfit = H4_BreakEvenProfit;
   tfParams[7].UseTrailingStop = H4_UseTrailingStop;
   tfParams[7].TrailAfterTP = H4_TrailAfterTP;
   tfParams[7].TrailStart = H4_TrailStart;
   tfParams[7].TrailStep = H4_TrailStep;

// D1 Parameters
   tfParams[8].UseBreakEven = D1_UseBreakEven;
   tfParams[8].BreakEvenAfterTP = D1_BreakEvenAfterTP;
   tfParams[8].BreakEvenTrigger = D1_BreakEvenTrigger;
   tfParams[8].BreakEvenProfit = D1_BreakEvenProfit;
   tfParams[8].UseTrailingStop = D1_UseTrailingStop;
   tfParams[8].TrailAfterTP = D1_TrailAfterTP;
   tfParams[8].TrailStart = D1_TrailStart;
   tfParams[8].TrailStep = D1_TrailStep;

// Validate timeframe-specific parameters
   for(int i = 0; i < 9; i++)
     {
      if(timeframeEnabled[i])
        {
         if(tfParams[i].BreakEvenAfterTP != 1 && tfParams[i].BreakEvenAfterTP != 2)
           {
            Print("ERROR: BreakEvenAfterTP for ", timeframeNames[i], " must be either 1 or 2");
            return(INIT_PARAMETERS_INCORRECT);
           }
         if(tfParams[i].TrailAfterTP != 1 && tfParams[i].TrailAfterTP != 2)
           {
            Print("ERROR: TrailAfterTP for ", timeframeNames[i], " must be either 1 or 2");
            return(INIT_PARAMETERS_INCORRECT);
           }
        }
     }

// Validate TP percentages sum to 100%
   double totalTPPercent = TP1Percent + TP2Percent + TP3Percent;
   if(MathAbs(totalTPPercent - 100.0) > 0.01)
     {
      Print("WARNING: TP percentages do not sum to 100%. Got ", totalTPPercent, "%");
     }

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
// Clean up any objects created by the EA
   ObjectsDeleteAll(0, "BF_");
   Comment("");
  }

//+------------------------------------------------------------------+
//| Dash board update                                                |
//+------------------------------------------------------------------+
void OnTrade()
  {
// Update statistics when a trade event occurs
   UpdateStatistics();
   ShowDashboard();
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   static datetime lastBarTime[9];

// Manage existing positions based on global parameters
   ManageTrailingStops();
   ManageBreakEvenStops();

// Check if we're within trading session
   if(!IsWithinSession())
     {
      return;
     }

// Loop through each timeframe
   for(int tfIndex = 0; tfIndex < 9; tfIndex++)
     {
      // Skip disabled timeframes
      if(!timeframeEnabled[tfIndex])
         continue;

      ENUM_TIMEFRAMES tf = timeframes[tfIndex];
      datetime currentBarTime = iTime(_Symbol, tf, 1);

      // Check if we need to process this timeframe (new bar)
      if(currentBarTime == lastBarTime[tfIndex])
         continue;

      lastBarTime[tfIndex] = currentBarTime;

      // Process pattern detection for this timeframe
      ProcessPatternDetection(tf, tfIndex);
     }
  }

//+------------------------------------------------------------------+
//| Find Pivots                                                      |
//+------------------------------------------------------------------+
void ProcessPatternDetection(ENUM_TIMEFRAMES tf, int tfIndex)
  {
   ArrayResize(pivots, 0);
   int barsCount = Bars(_Symbol, tf);
   int start = PivotLeft;
   int end = barsCount - PivotRight;

   for(int i = end - 1; i >= start; i--)
     {
      bool isPivotHigh = true;
      bool isPivotLow = true;
      double currentHigh = iHigh(_Symbol, tf, i);
      double currentLow = iLow(_Symbol, tf, i);
      for(int j = i - PivotLeft; j <= i + PivotRight; j++)
        {
         if(j < 0 || j >= barsCount)
            continue;
         if(j == i)
            continue;
         if(iHigh(_Symbol, tf, j) > currentHigh)
            isPivotHigh = false;
         if(iLow(_Symbol, tf, j) < currentLow)
            isPivotLow = false;
        }
      if(isPivotHigh || isPivotLow)
        {
         Pivot p;
         p.time = iTime(_Symbol, tf, i);
         p.price = isPivotHigh ? currentHigh : currentLow;
         p.isHigh = isPivotHigh;
         int size = ArraySize(pivots);
         ArrayResize(pivots, size + 1);
         pivots[size] = p;
        }
     }

   int pivotCount = ArraySize(pivots);
   if(pivotCount < 5)
     {
      patternStatus[tfIndex].formationBar = -1;
      patternStatus[tfIndex].lockedPatternX = 0;
      return;
     }

   Pivot X = pivots[pivotCount - 5];
   Pivot A = pivots[pivotCount - 4];
   Pivot B = pivots[pivotCount - 3];
   Pivot C = pivots[pivotCount - 2];
   Pivot D = pivots[pivotCount - 1];

   bool patternFound = false;

//BEARISH BUTTERFLY PATTERN
   if(X.isHigh && (!A.isHigh) && B.isHigh && (!C.isHigh) && D.isHigh)
     {
      double diff = X.price - A.price;
      if(diff > 0)
        {
         double idealB = A.price + 0.786 * diff;
         if(MathAbs(B.price - idealB) <= Tolerance * diff)
           {
            double BC = B.price - C.price;
            if((BC >= 0.382 * diff) && (BC <= 0.886 * diff))
              {
               double CD = D.price - C.price;
               if((CD >= 1.27 * diff) && (CD <= 1.618 * diff) && (D.price > X.price))
                  patternFound = true;
              }
           }
        }
     }
//BULLISH BUTTERFLY PATTERN
   if((!X.isHigh) && A.isHigh && (!B.isHigh) && C.isHigh && (!D.isHigh))
     {
      double diff = A.price - X.price;
      if(diff > 0)
        {
         double idealB = A.price - 0.786 * diff;
         if(MathAbs(B.price - idealB) <= Tolerance * diff)
           {
            double BC = C.price - B.price;
            if((BC >= 0.382 * diff) && (BC <= 0.886 * diff))
              {
               double CD = C.price - D.price;
               if((CD >= 1.27 * diff) && (CD <= 1.618 * diff) && (D.price < X.price))
                  patternFound = true;
              }
           }
        }
     }

   string patternType = "";
   if(patternFound)
     {
      if(D.price > X.price)
         patternType = "Bearish";  //--- Bearish Butterfly indicates a SELL signal
      else
         if(D.price < X.price)
            patternType = "Bullish";  //--- Bullish Butterfly indicates a BUY signal
     }

   if(patternFound)
     {
      // Check pattern quality
      double patternQuality = AssessPatternQuality(X, A, B, C, D, patternType);
      if(patternQuality < MinPatternQuality)
        {
         Print("Pattern quality too low: ", patternQuality, " < ", MinPatternQuality);
         return;
        }

      Print(patternType, " Butterfly pattern detected at ", TimeToString(D.time, TIME_DATE|TIME_MINUTES|TIME_SECONDS));
      string tfName = timeframeNames[tfIndex];
      string signalPrefix = "BF_" + tfName + "_" + IntegerToString(X.time);
      color triangleColor = (patternType=="Bullish") ? clrBlue : clrRed;

      // Draw the first triangle connecting pivots X, A, and B
      DrawTriangle(signalPrefix+"_Triangle1", X.time, X.price, A.time, A.price, B.time, B.price,
                   triangleColor, 2, true, true);
      // Draw the second triangle connecting pivots B, C, and D
      DrawTriangle(signalPrefix+"_Triangle2", B.time, B.price, C.time, C.price, D.time, D.price,
                   triangleColor, 2, true, true);

      // Draw boundary trend lines connecting the pivots for clarity
      DrawTrendLine(signalPrefix+"_TL_XA", X.time, X.price, A.time, A.price, clrWhite, 2, STYLE_SOLID);
      DrawTrendLine(signalPrefix+"_TL_AB", A.time, A.price, B.time, B.price, clrWhite, 2, STYLE_SOLID);
      DrawTrendLine(signalPrefix+"_TL_BC", B.time, B.price, C.time, C.price, clrWhite, 2, STYLE_SOLID);
      DrawTrendLine(signalPrefix+"_TL_CD", C.time, C.price, D.time, D.price, clrWhite, 2, STYLE_SOLID);
      DrawTrendLine(signalPrefix+"_TL_XB", X.time, X.price, B.time, B.price, clrWhite, 2, STYLE_SOLID);
      DrawTrendLine(signalPrefix+"_TL_BD", B.time, B.price, D.time, D.price, clrWhite, 2, STYLE_SOLID);

      // Retrieve the symbol's point size to calculate offsets for text positioning
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      // Calculate an offset (15 points) for positioning text above or below pivots
      double offset = 15 * point;

      // Determine the Y coordinate for each pivot label based on its type
      double textY_X = (X.isHigh ? X.price + offset : X.price - offset);
      double textY_A = (A.isHigh ? A.price + offset : A.price - offset);
      double textY_B = (B.isHigh ? B.price + offset : B.price - offset);
      double textY_C = (C.isHigh ? C.price + offset : C.price - offset);
      double textY_D = (D.isHigh ? D.price + offset : D.price - offset);

      // Draw text labels for each pivot with appropriate anchoring
      DrawTextEx(signalPrefix+"_Text_X", "X", X.time, textY_X, clrWhite, 11, X.isHigh);
      DrawTextEx(signalPrefix+"_Text_A", "A", A.time, textY_A, clrWhite, 11, A.isHigh);
      DrawTextEx(signalPrefix+"_Text_B", "B", B.time, textY_B, clrWhite, 11, B.isHigh);
      DrawTextEx(signalPrefix+"_Text_C", "C", C.time, textY_C, clrWhite, 11, C.isHigh);
      DrawTextEx(signalPrefix+"_Text_D", "D", D.time, textY_D, clrWhite, 11, D.isHigh);

      // Calculate the central label's time as the midpoint between pivots X and B
      datetime centralTime = (X.time + B.time) / 2;
      double centralPrice = D.price;
      if(ObjectCreate(0, signalPrefix+"_Text_Center", OBJ_TEXT, 0, centralTime, centralPrice))
        {
         ObjectSetString(0, signalPrefix+"_Text_Center", OBJPROP_TEXT,
                         (patternType=="Bullish" ? "Bullish" : "Bearish") + " Butterfly " + tfName);
         ObjectSetInteger(0, signalPrefix+"_Text_Center", OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(0, signalPrefix+"_Text_Center", OBJPROP_FONTSIZE, 11);
         ObjectSetString(0, signalPrefix+"_Text_Center", OBJPROP_FONT, "Arial Bold");
         ObjectSetInteger(0, signalPrefix+"_Text_Center", OBJPROP_ALIGN, ALIGN_CENTER);
        }

      // Define start and end times for drawing horizontal dotted lines for trade levels
      datetime lineStart = D.time;
      datetime lineEnd = D.time + PeriodSeconds(tf)*2;

      // Declare variables for entry price and take profit levels
      double entryPriceLevel, TP1Level, TP2Level, TP3Level, tradeDiff;
      if(patternType=="Bullish")   // Bullish → BUY signal
        {
         entryPriceLevel = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         TP3Level = C.price;
         tradeDiff = TP3Level - entryPriceLevel;
         TP1Level = entryPriceLevel + tradeDiff/3;
         TP2Level = entryPriceLevel + 2*tradeDiff/3;
        }
      else     // Bearish → SELL signal
        {
         entryPriceLevel = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         TP3Level = C.price;
         tradeDiff = entryPriceLevel - TP3Level;
         TP1Level = entryPriceLevel - tradeDiff/3;
         TP2Level = entryPriceLevel - 2*tradeDiff/3;
        }

      // Draw dotted horizontal lines to represent the entry and TP levels
      DrawDottedLine(signalPrefix+"_EntryLine", lineStart, entryPriceLevel, lineEnd, clrMagenta);
      DrawDottedLine(signalPrefix+"_TP1Line", lineStart, TP1Level, lineEnd, clrForestGreen);
      DrawDottedLine(signalPrefix+"_TP2Line", lineStart, TP2Level, lineEnd, clrGreen);
      DrawDottedLine(signalPrefix+"_TP3Line", lineStart, TP3Level, lineEnd, clrDarkGreen);

      // Define a label time coordinate positioned just to the right of the dotted lines
      datetime labelTime = lineEnd + PeriodSeconds(tf)/2;

      // Construct the entry label text with the price
      string entryLabel = (patternType=="Bullish") ? "BUY (" : "SELL (";
      entryLabel += DoubleToString(entryPriceLevel, _Digits) + ")";
      // Draw the entry label on the chart
      DrawTextEx(signalPrefix+"_EntryLabel", entryLabel, labelTime, entryPriceLevel, clrMagenta, 11, true);

      // Construct and draw the TP1 label
      string tp1Label = "TP1 (" + DoubleToString(TP1Level, _Digits) + ")";
      DrawTextEx(signalPrefix+"_TP1Label", tp1Label, labelTime, TP1Level, clrForestGreen, 11, true);

      // Construct and draw the TP2 label
      string tp2Label = "TP2 (" + DoubleToString(TP2Level, _Digits) + ")";
      DrawTextEx(signalPrefix+"_TP2Label", tp2Label, labelTime, TP2Level, clrGreen, 11, true);

      // Construct and draw the TP3 label
      string tp3Label = "TP3 (" + DoubleToString(TP3Level, _Digits) + ")";
      DrawTextEx(signalPrefix+"_TP3Label", tp3Label, labelTime, TP3Level, clrDarkGreen, 11, true);

      // Retrieve the index of the current bar
      int currentBarIndex = Bars(_Symbol, tf) - 1;
      if(patternStatus[tfIndex].formationBar == -1)
        {
         patternStatus[tfIndex].formationBar = currentBarIndex;
         patternStatus[tfIndex].lockedPatternX = X.time;
         Print("Pattern detected on ", tfName, " bar ", currentBarIndex, ". Waiting for confirmation on next bar.");
         return;
        }
      if(currentBarIndex == patternStatus[tfIndex].formationBar)
        {
         Print("Pattern is repainting on ", tfName, "; still on locked formation bar ", currentBarIndex, ". No trade yet.");
         return;
        }
      // If we are on a new bar compared to the locked formation
      if(currentBarIndex > patternStatus[tfIndex].formationBar)
        {
         if(patternStatus[tfIndex].lockedPatternX == X.time)
           {
            Print("Confirmed pattern on ", tfName, " (locked on bar ", patternStatus[tfIndex].formationBar, "). Opening trade on bar ", currentBarIndex, ".");
            patternStatus[tfIndex].formationBar = currentBarIndex;

               if(AllowTrading && PositionsTotal() <= 0)
               {
                  double entryPriceTrade = 0, stopLoss = 0;
                  double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
               
                  // Get symbol constraints
                  double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
                  double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
                  double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
                  int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL); // Minimum stop distance in points
                  double minStopDistance = stopsLevel * point;
               
                  // Get margin requirements
                  double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
                  double marginRequiredPerLot = contractSize * entryPriceTrade / (double)AccountInfoInteger(ACCOUNT_LEVERAGE);
                  double freeMargin = AccountInfoDouble(ACCOUNT_FREEMARGIN);
                  double marginSafetyBuffer = 50.0; // Safety buffer in account currency (USD)
               
                  if(patternType == "Bullish") // BUY signal
                  {
                     entryPriceTrade = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
                     double diffTrade = TP2Level - entryPriceTrade;
                     stopLoss = entryPriceTrade - diffTrade * 3;
               
                     // Validate stop loss distance
                     if(MathAbs(entryPriceTrade - stopLoss) < minStopDistance)
                     {
                        stopLoss = entryPriceTrade - minStopDistance;
                        Print("Adjusted stop loss to meet minimum stop distance: ", stopLoss);
                     }
               
                     // Validate take profit distances
                     if(MathAbs(TP1Level - entryPriceTrade) < minStopDistance)
                     {
                        Print("TP1 too close to entry price: ", TP1Level, ". Minimum distance required: ", minStopDistance);
                        return;
                     }
                     if(MathAbs(TP2Level - entryPriceTrade) < minStopDistance)
                     {
                        Print("TP2 too close to entry price: ", TP2Level, ". Minimum distance required: ", minStopDistance);
                        return;
                     }
                     if(MathAbs(TP3Level - entryPriceTrade) < minStopDistance)
                     {
                        Print("TP3 too close to entry price: ", TP3Level, ". Minimum distance required: ", minStopDistance);
                        return;
                     }
               
                     // Calculate lot size based on risk
                     double totalLotSize = CalculateLotSize(stopLoss, entryPriceTrade);
               
                     // Calculate individual lot sizes based on percentages
                     double lot1 = NormalizeDouble(totalLotSize * TP1Percent / 100.0, 2);
                     double lot2 = NormalizeDouble(totalLotSize * TP2Percent / 100.0, 2);
                     double lot3 = NormalizeDouble(totalLotSize * TP3Percent / 100.0, 2);
               
                     // Validate and adjust lot sizes to meet broker requirements
                     lot1 = MathMax(minLot, MathMin(maxLot, NormalizeDouble(lot1 / lotStep, 0) * lotStep));
                     lot2 = MathMax(minLot, MathMin(maxLot, NormalizeDouble(lot2 / lotStep, 0) * lotStep));
                     lot3 = MathMax(minLot, MathMin(maxLot, NormalizeDouble(lot3 / lotStep, 0) * lotStep));
               
                     // Check if lot sizes are valid
                     if(lot1 < minLot || lot2 < minLot || lot3 < minLot)
                     {
                        Print("Invalid lot sizes after adjustment: lot1=", lot1, ", lot2=", lot2, ", lot3=", lot3, ". Minimum lot size is ", minLot);
                        return;
                     }
               
                     // Calculate total margin required for all three positions
                     double totalLots = lot1 + lot2 + lot3;
                     double marginRequiredPerLot = contractSize * entryPriceTrade / (double)AccountInfoInteger(ACCOUNT_LEVERAGE);
                     double totalMarginRequired = totalLots * marginRequiredPerLot;
               
                     // Check if sufficient margin is available
                     if(totalMarginRequired + marginSafetyBuffer > freeMargin)
                     {
                        Print("Insufficient margin to open positions. Required: ", totalMarginRequired, 
                              ", Available: ", freeMargin, ", Lots: ", totalLots);
                        return;
                     }
               
                     // Place three separate BUY orders with different take profits
                     if(lot1 >= minLot && trade.Buy(lot1, _Symbol, entryPriceTrade, stopLoss, TP1Level, "Butterfly " + timeframeNames[tfIndex] + " TP1"))
                        Print("Buy order 1 (", timeframeNames[tfIndex], " TP1) opened successfully with lot size: ", lot1);
                     else
                        Print("Buy order 1 (", timeframeNames[tfIndex], " TP1) failed: ", trade.ResultRetcodeDescription());
               
                     if(lot2 >= minLot && trade.Buy(lot2, _Symbol, entryPriceTrade, stopLoss, TP2Level, "Butterfly " + timeframeNames[tfIndex] + " TP2"))
                        Print("Buy order 2 (", timeframeNames[tfIndex], " TP2) opened successfully with lot size: ", lot2);
                     else
                        Print("Buy order 2 (", timeframeNames[tfIndex], " TP2) failed: ", trade.ResultRetcodeDescription());
               
                     if(lot3 >= minLot && trade.Buy(lot3, _Symbol, entryPriceTrade, stopLoss, TP3Level, "Butterfly " + timeframeNames[tfIndex] + " TP3"))
                        Print("Buy order 3 (", timeframeNames[tfIndex], " TP3) opened successfully with lot size: ", lot3);
                     else
                        Print("Buy order 3 (", timeframeNames[tfIndex], " TP3) failed: ", trade.ResultRetcodeDescription());
                  }
                  else if(patternType == "Bearish") // SELL signal
                  {
                     entryPriceTrade = SymbolInfoDouble(_Symbol, SYMBOL_BID);
                     double diffTrade = entryPriceTrade - TP2Level;
                     stopLoss = entryPriceTrade + diffTrade * 3;
               
                     // Validate stop loss distance
                     if(MathAbs(stopLoss - entryPriceTrade) < minStopDistance)
                     {
                        stopLoss = entryPriceTrade + minStopDistance;
                        Print("Adjusted stop loss to meet minimum stop distance: ", stopLoss);
                     }
               
                     // Validate take profit distances
                     if(MathAbs(entryPriceTrade - TP1Level) < minStopDistance)
                     {
                        Print("TP1 too close to entry price: ", TP1Level, ". Minimum distance required: ", minStopDistance);
                        return;
                     }
                     if(MathAbs(entryPriceTrade - TP2Level) < minStopDistance)
                     {
                        Print("TP2 too close to entry price: ", TP2Level, ". Minimum distance required: ", minStopDistance);
                        return;
                     }
                     if(MathAbs(entryPriceTrade - TP3Level) < minStopDistance)
                     {
                        Print("TP3 too close to entry price: ", TP3Level, ". Minimum distance required: ", minStopDistance);
                        return;
                     }
               
                     // Calculate lot size based on risk
                     double totalLotSize = CalculateLotSize(stopLoss, entryPriceTrade);
               
                     // Calculate individual lot sizes based on percentages
                     double lot1 = NormalizeDouble(totalLotSize * TP1Percent / 100.0, 2);
                     double lot2 = NormalizeDouble(totalLotSize * TP2Percent / 100.0, 2);
                     double lot3 = NormalizeDouble(totalLotSize * TP3Percent / 100.0, 2);
               
                     // Validate and adjust lot sizes to meet broker requirements
                     lot1 = MathMax(minLot, MathMin(maxLot, NormalizeDouble(lot1 / lotStep, 0) * lotStep));
                     lot2 = MathMax(minLot, MathMin(maxLot, NormalizeDouble(lot2 / lotStep, 0) * lotStep));
                     lot3 = MathMax(minLot, MathMin(maxLot, NormalizeDouble(lot3 / lotStep, 0) * lotStep));
               
                     // Check if lot sizes are valid
                     if(lot1 < minLot || lot2 < minLot || lot3 < minLot)
                     {
                        Print("Invalid lot sizes after adjustment: lot1=", lot1, ", lot2=", lot2, ", lot3=", lot3, ". Minimum lot size is ", minLot);
                        return;
                     }
               
                     // Calculate total margin required for all three positions
                     double totalLots = lot1 + lot2 + lot3;
                     double marginRequiredPerLot = contractSize * entryPriceTrade / (double)AccountInfoInteger(ACCOUNT_LEVERAGE);
                     double totalMarginRequired = totalLots * marginRequiredPerLot;
               
                     // Check if sufficient margin is available
                     if(totalMarginRequired + marginSafetyBuffer > freeMargin)
                     {
                        Print("Insufficient margin to open positions. Required: ", totalMarginRequired, 
                              ", Available: ", freeMargin, ", Lots: ", totalLots);
                        return;
                     }
               
                     // Place three separate SELL orders with different take profits
                     if(lot1 >= minLot && trade.Sell(lot1, _Symbol, entryPriceTrade, stopLoss, TP1Level, "Butterfly " + timeframeNames[tfIndex] + " TP1"))
                        Print("Sell order 1 (", timeframeNames[tfIndex], " TP1) opened successfully with lot size: ", lot1);
                     else
                        Print("Sell order 1 (", timeframeNames[tfIndex], " TP1) failed: ", trade.ResultRetcodeDescription());
               
                     if(lot2 >= minLot && trade.Sell(lot2, _Symbol, entryPriceTrade, stopLoss, TP2Level, "Butterfly " + timeframeNames[tfIndex] + " TP2"))
                        Print("Sell order 2 (", timeframeNames[tfIndex], " TP2) opened successfully with lot size: ", lot2);
                     else
                        Print("Sell order 2 (", timeframeNames[tfIndex], " TP2) failed: ", trade.ResultRetcodeDescription());
               
                     if(lot3 >= minLot && trade.Sell(lot3, _Symbol, entryPriceTrade, stopLoss, TP3Level, "Butterfly " + timeframeNames[tfIndex] + " TP3"))
                        Print("Sell order 3 (", timeframeNames[tfIndex], " TP3) opened successfully with lot size: ", lot3);
                     else
                        Print("Sell order 3 (", timeframeNames[tfIndex], " TP3) failed: ", trade.ResultRetcodeDescription());
                  }
               }
               else
               {
                  Print("A position is already open for ", _Symbol, ". No new trade executed.");
               }
           }
         else
           {
            patternStatus[tfIndex].formationBar = currentBarIndex;
            patternStatus[tfIndex].lockedPatternX = X.time;
            Print("Pattern has changed on ", tfName, "; updating lock on bar ", currentBarIndex, ". Waiting for confirmation.");
            return;
           }
        }
     }
   else
     {
      patternStatus[tfIndex].formationBar = -1;
      patternStatus[tfIndex].lockedPatternX = 0;
     }
  }

//+------------------------------------------------------------------+
//| Time frame Index                                                 |
//+------------------------------------------------------------------+
int GetTimeframeIndexFromComment(string comment)
  {
   for(int i = 0; i < 9; i++)
     {
      if(StringFind(comment, timeframeNames[i]) >= 0)
         return i;
     }
   return -1; // Not found
  }
//+------------------------------------------------------------------+
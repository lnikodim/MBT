//+------------------------------------------------------------------+
//|                                           VR Breakdown level.mq5 |
//|                                      Copyright 2025, Trading-Go. |
//+------------------------------------------------------------------+
#property copyright "@ Voldemar"                                      // Copyright information
#property link      "https://www.mql5.com/en/channels/tradingo-go-en" // Website link
#property version   "26.020"                                          // Expert Advisor version

// Include Trade class for executing trading operations
#include <Trade\Trade.mqh>        CTrade        trade; // Creates trade object for order management
// Include PositionInfo class for getting information about positions
#include <Trade\PositionInfo.mqh> CPositionInfo posit; // Creates position info object

//+------------------------------------------------------------------+
//| Input parameters                                                |
//+------------------------------------------------------------------+
input double          iLots        = 0.01;          // Trading volume in lots
input ENUM_TIMEFRAMES iTimeFrame   = PERIOD_CURRENT; // Timeframe for analysis
input int             iTakeProfit  = 400;           // Take Profit in points
input int             iStopLoss    = 200;           // Stop Loss in points
input int             iMagicNumber = 227;           // Unique identifier for EA orders
input int             iSlippage    = 30;            // Maximum slippage in points

double lt       = 0;    // Corrected lot size after checking step and min limits
double level_up = 0;    // Upper breakout level (previous bar high)
double level_dw = 0;    // Lower breakout level (previous bar low)

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Configure trade object with EA's magic number
   trade.SetExpertMagicNumber(iMagicNumber);
   // Set maximum allowed slippage in points
   trade.SetDeviationInPoints(iSlippage);
   // Set order filling type based on symbol specifications
   trade.SetTypeFillingBySymbol(_Symbol);
   // Set margin mode for the trade object
   trade.SetMarginMode();
   
   // Get the minimum lot step for the symbol
   double stepvol = ::SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(stepvol > 0)
      // Calculate lot size rounded to the nearest valid step
      lt = stepvol * (int)(iLots / stepvol);
      
   // Check if calculated lot is less than minimum allowed lot
   if(lt < ::SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
      lt = 0.0;  // Set to 0 if below minimum (invalid)
      
   // Return successful initialization
   return(INIT_SUCCEEDED);
  }
  
//+------------------------------------------------------------------+
//| Expert tick function - executes on every new tick               |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Get total number of open positions
   int total = ::PositionsTotal();

   // Check if a new bar has formed
   if(NewBar())
     {
      // Update breakout levels with previous bar's high and low
      level_up = ::iHigh(_Symbol, iTimeFrame, 1);  // High of previous bar
      level_dw = ::iLow(_Symbol,  iTimeFrame, 1);  // Low of previous bar
     }

   // Get current Ask and Bid prices
   double ask = ::SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = ::SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Check BUY condition: price breaks above previous bar's high
   if(ask > 0 && level_up > 0 && ask >= level_up)
      // Execute BUY order using trade object
      if(trade.Buy(lt))
         // Reset upper level and exit after successful order placement
         if((level_up = 0) == 0)
            return;

   // Check SELL condition: price breaks below previous bar's low
   if(bid > 0 && level_dw > 0 && bid <= level_dw)
      // Execute SELL order using trade object
      if(trade.Sell(lt))
         // Reset lower level and exit after successful order placement
         if((level_dw = 0) == 0)
            return;

   // Loop through all positions to modify SL/TP
   for(int i = 0; i < total; i++)
      // Select position by its index in the positions list
      if(posit.SelectByIndex(i))
         // Check if position belongs to current symbol
         if(posit.Symbol() == _Symbol)
            // Check if position was opened by this EA (matching magic number)
            if(posit.Magic() == iMagicNumber)
              {
               // Get position opening price
               double op = posit.PriceOpen();
               // Get current Take Profit value (normalized to digits)
               double tp = ::NormalizeDouble(posit.TakeProfit(), _Digits);
               // Get current Stop Loss value (normalized to digits)
               double sl = ::NormalizeDouble(posit.StopLoss(), _Digits);
               // Initialize new SL/TP with current values
               double new_sl = sl;
               double new_tp = tp;

               // Handle BUY position
               if(posit.PositionType() == POSITION_TYPE_BUY)
                 {
                  // Calculate new Stop Loss if enabled (below entry price)
                  if(iStopLoss > 0)
                     new_sl = ::NormalizeDouble(op - iStopLoss * _Point, _Digits);
                  // Calculate new Take Profit if enabled (above entry price)
                  if(iTakeProfit > 0)
                     new_tp = ::NormalizeDouble(op + iTakeProfit * _Point, _Digits);
                 }

               // Handle SELL position
               if(posit.PositionType() == POSITION_TYPE_SELL)
                 {
                  // Calculate new Stop Loss if enabled (above entry price)
                  if(iStopLoss > 0)
                     new_sl = ::NormalizeDouble(op + iStopLoss * _Point, _Digits);
                  // Calculate new Take Profit if enabled (below entry price)
                  if(iTakeProfit > 0)
                     new_tp = ::NormalizeDouble(op - iTakeProfit * _Point, _Digits);
                 }

               // If SL or TP values have changed
               if(new_sl != sl || new_tp != tp)
                  // Check if new levels are valid according to broker rules
                  if(CheckSL_TP(posit.PositionType(), new_sl, new_tp))
                     // Modify the position with new SL and TP using trade object
                     trade.PositionModify(posit.Ticket(), new_sl, new_tp);
              }
  }
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)  // Function called when EA is removed from chart
  {
   // No cleanup needed
  }
  
//+------------------------------------------------------------------+
//| Function to detect new bar formation                            |
//+------------------------------------------------------------------+
bool NewBar(void)
  {
   // Get open time of current bar (index 0)
   datetime new_time = ::iTime(_Symbol, iTimeFrame, 0);
   
   // Static variable to store previous bar time (retains value between calls)
   static datetime old_time = new_time;
   
   // Compare current bar time with previous bar time
   if(new_time != old_time)
      // Update old_time and return true (new bar detected)
      if((old_time = new_time) != NULL)
         return(true);
   
   // No new bar formed
   return(false);
  }
  
//+------------------------------------------------------------------+
//| Check if Stop Loss and Take Profit levels are valid            |
//+------------------------------------------------------------------+
bool CheckSL_TP(ENUM_POSITION_TYPE type, double aSL, double aTP)
  {
   // Get minimum stop level required by broker (in points)
   int stops_level = (int)::SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   // Get current Ask price
   double ask = ::SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   // Get current Bid price
   double bid = ::SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   // Check validity based on position type
   switch(type)
     {
      case POSITION_TYPE_BUY:  // For BUY positions
        {
         // SL must be below Bid by at least stops_level points
         // TP must be above Bid by at least stops_level points
         return((bid - aSL > stops_level * _Point) && (aTP - bid > stops_level * _Point));
        }
      case POSITION_TYPE_SELL:  // For SELL positions
        {
         // TP must be below Ask by at least stops_level points
         // SL must be above Ask by at least stops_level points
         return((ask - aTP > stops_level * _Point) && (aSL - ask > stops_level * _Point));
        }
        break;
     }
   // Return false if position type is unknown
   return (false);
  }
//+------------------------------------------------------------------+
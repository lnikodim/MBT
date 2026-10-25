//+------------------------------------------------------------------+
//|                                                 VR Rsi Robot.mq5 |
//|                                      Copyright 2026, Trading-Go. |
//+------------------------------------------------------------------+
#property copyright "@ Voldemar"
#property link      "https://www.mql5.com/en/users/voldemar"
#property version   "26.030"

// Include trade and position handling classes
#include <Trade\Trade.mqh>        CTrade        trade;      // Trading object
#include <Trade\PositionInfo.mqh> CPositionInfo posit;      // Position information object

// Input parameters (configurable via Expert Advisor properties)
input double          iLots             = 0.01;             // Trading volume in lots

input int             iRSI_Period_H1    = 12;               // RSI period for H1 chart
input ENUM_TIMEFRAMES iRSI_TimeFrame_H1 = PERIOD_H1;        // Timeframe for the first RSI (H1)

input int             iRSI_Period_D1    = 18;               // RSI period for D1 chart
input ENUM_TIMEFRAMES iRSI_TimeFrame_D1 = PERIOD_D1;        // Timeframe for the second RSI (D1)

input double          iRSI_Level_UP     = 80.0;             // Overbought level (sell signal zone)
input double          iRSI_Level_DW     = 20.0;             // Oversold level (buy signal zone)

input int             iMagicNumber      = 227;              // Unique identifier for this EA's trades
input int             iSlippage         = 30;               // Allowed slippage in points

// Global variables
double lt       = 0;                     // Corrected lot size after step adjustment
double level_up = 0;                      // Not used (reserved)
double level_dw = 0;                      // Not used (reserved)

int    handle_0 = -1;                     // Handle for the H1 RSI indicator
int    handle_1 = -1;                     // Handle for the D1 RSI indicator
double rsi_mass_h1[];                      // Dynamic array for H1 RSI values
double rsi_mass_d1[];                      // Dynamic array for D1 RSI values

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   // Configure trade object with magic number and slippage
   trade.SetExpertMagicNumber(iMagicNumber);               // Set magic number for all orders
   trade.SetDeviationInPoints(iSlippage);                  // Set allowed slippage
   trade.SetTypeFillingBySymbol(_Symbol);                  // Automatically choose order filling mode
   trade.SetMarginMode();                                   // Set margin mode (auto)

   // Adjust lot size to comply with symbol's volume step
   double stepvol = ::SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP); // Get minimum volume step
   if(stepvol > 0)
      lt = stepvol * (int)(iLots / stepvol);               // Round down to nearest step

   // Ensure lot size is not less than minimum allowed
   if(lt < ::SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
      lt = ::SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN); // Set to minimum if needed

   // Create RSI indicator handles for both timeframes
   handle_0 = ::iRSI(_Symbol, iRSI_TimeFrame_H1, iRSI_Period_H1, PRICE_CLOSE); // H1 RSI
   handle_1 = ::iRSI(_Symbol, iRSI_TimeFrame_D1, iRSI_Period_D1, PRICE_CLOSE); // D1 RSI

   return(INIT_SUCCEEDED);                                  // Initialization successful
  }

//+------------------------------------------------------------------+
//| Expert tick function (executed on every new tick)               |
//+------------------------------------------------------------------+
void OnTick()
  {
   // Get current market prices
   double Bid = ::SymbolInfoDouble(_Symbol, SYMBOL_BID);   // Current Bid price (for sells)
   double Ask = ::SymbolInfoDouble(_Symbol, SYMBOL_ASK);   // Current Ask price (for buys)

   int total = ::PositionsTotal();                          // Total number of open positions

   ulong b_ticket = 0;                                      // Ticket of existing buy position (if any)
   ulong s_ticket = 0;                                      // Ticket of existing sell position (if any)

   // Loop through all positions to find those belonging to this EA and symbol
   for(int i = 0; i < total; i++)
      if(posit.SelectByIndex(i))                            // Select position by index
         if(posit.Symbol() == _Symbol)                      // Check if symbol matches
            if(posit.Magic() == iMagicNumber)               // Check if magic number matches
              {
               if(posit.PositionType() == POSITION_TYPE_BUY)
                  b_ticket = posit.Ticket();                // Store buy ticket
               if(posit.PositionType() == POSITION_TYPE_SELL)
                  s_ticket = posit.Ticket();                // Store sell ticket
              }

   // (Optional debug comments, currently disabled)
   /*
   Comment
   (
   "\n rsi_mass_h1 0 "+rsi_mass_h1[0]+
   "\n rsi_mass_h1 1 "+rsi_mass_h1[1]+
   "\n rsi_mass_d1 0 "+rsi_mass_d1[0]+
   "\n rsi_mass_d1 1 "+rsi_mass_d1[1]
   );
   */

   bool signal_up = false;                                  // Flag for buy signal
   bool signal_dw = false;                                  // Flag for sell signal

   // Check for BUY signal only if no buy position already open
   if(b_ticket == 0)
     {
      // Copy latest two RSI values from H1 (skip current forming bar: start=1)
      if((::CopyBuffer(handle_0, 0, 1, 2, rsi_mass_h1)) != -1)
         ArraySetAsSeries(rsi_mass_h1, true);               // Index 0 = oldest? Actually we set as series so [0] is newest

      // Copy latest two RSI values from D1
      if((::CopyBuffer(handle_1, 0, 1, 2, rsi_mass_d1)) != -1)
         ArraySetAsSeries(rsi_mass_d1, true);               // Index 0 = newest

      // Ensure both buffers have at least 2 elements
      if(::ArraySize(rsi_mass_h1) >= 2)
         if(::ArraySize(rsi_mass_d1) >= 2)
            // Conditions for buy:
            // 1. Current H1 RSI >= oversold level AND rising (current > previous)
            // 2. Current D1 RSI >= oversold level AND rising
            if(rsi_mass_h1[0] >= iRSI_Level_DW && rsi_mass_h1[0] > rsi_mass_h1[1])
               if(rsi_mass_d1[0] >= iRSI_Level_DW && rsi_mass_d1[0] > rsi_mass_d1[1])
                  signal_up = true;                         // All conditions met: buy signal
     }

   // Check for SELL signal only if no sell position already open
   if(s_ticket == 0)
     {
      // (Same buffer copy as above)
      if((::CopyBuffer(handle_0, 0, 1, 2, rsi_mass_h1)) != -1)
         ArraySetAsSeries(rsi_mass_h1, true);
      if((::CopyBuffer(handle_1, 0, 1, 2, rsi_mass_d1)) != -1)
         ArraySetAsSeries(rsi_mass_d1, true);

      if(::ArraySize(rsi_mass_h1) >= 2)
         if(::ArraySize(rsi_mass_d1) >= 2)
            // Conditions for sell:
            // 1. Current H1 RSI <= overbought level AND falling (current < previous)
            // 2. Current D1 RSI <= overbought level AND falling
            if(rsi_mass_h1[0] <= iRSI_Level_UP && rsi_mass_h1[0] < rsi_mass_h1[1])
               if(rsi_mass_d1[0] <= iRSI_Level_UP && rsi_mass_d1[0] < rsi_mass_d1[1])
                  signal_dw = true;                         // All conditions met: sell signal
     }

   // Execute buy signal
   if(signal_up)
     {
      if(s_ticket > 0)
         trade.PositionClose(s_ticket);                     // Close opposite position first

      // Safety checks before opening buy
      if(CheckMargin(ORDER_TYPE_BUY, lt))                   // Check if enough free margin
         if(trade.CheckVolume(_Symbol, lt, Ask, ORDER_TYPE_BUY)) // Verify volume is tradable
            if(trade.Buy(lt))                                // Open buy position
               return;                                        // Exit tick handler after successful trade
     }

   // Execute sell signal
   if(signal_dw)
     {
      if(b_ticket > 0)
         trade.PositionClose(b_ticket);                     // Close opposite position first

      // Safety checks before opening sell
      if(CheckMargin(ORDER_TYPE_SELL, lt))                  // Check if enough free margin
         if(trade.CheckVolume(_Symbol, lt, Bid, ORDER_TYPE_SELL)) // Verify volume is tradable
            if(trade.Sell(lt))                               // Open sell position
               return;                                        // Exit tick handler after successful trade
     }
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // Nothing to clean up here; indicator handles are released automatically
  }

//+------------------------------------------------------------------+
//| Helper function to validate stop loss and take profit distances |
//| (Currently not used in main logic, but kept for reference)      |
//+------------------------------------------------------------------+
bool CheckSL_TP(ENUM_POSITION_TYPE type, double aSL, double aTP)
  {
   int stops_level = (int)::SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL); // Minimum stop distance
   double ask = ::SymbolInfoDouble(_Symbol, SYMBOL_ASK);   // Current Ask
   double bid = ::SymbolInfoDouble(_Symbol, SYMBOL_BID);   // Current Bid
   switch(type)
     {
      case POSITION_TYPE_BUY:
        {
         // For buy: stop loss must be below bid by at least stops_level, take profit above bid similarly
         return((bid - aSL > stops_level * _Point) && (aTP - bid > stops_level * _Point));
        }
      case POSITION_TYPE_SELL:
        {
         // For sell: take profit must be below ask, stop loss above ask, both with sufficient distance
         return((ask - aTP > stops_level * _Point) && (aSL - ask > stops_level * _Point));
        }
      break;
     }
   return (false);
  }

//+------------------------------------------------------------------+
//| Check if there is enough free margin for the trade              |
//+------------------------------------------------------------------+
bool CheckMargin(ENUM_ORDER_TYPE aType, double aLot)
  {
   double Bid = ::SymbolInfoDouble(_Symbol, SYMBOL_BID);   // Current Bid
   double Ask = ::SymbolInfoDouble(_Symbol, SYMBOL_ASK);   // Current Ask
   double fMargin = 0;                                      // To store required margin
   if(Ask > 0 && Bid > 0)                                   // Ensure prices are valid
      if(::OrderCalcMargin(aType, _Symbol, aLot, aType == 0 ? Ask : Bid, fMargin)) // Calculate required margin
         return(fMargin < ::AccountInfoDouble(ACCOUNT_MARGIN_FREE)); // True if enough free margin
   return (false);                                           // Margin check failed
  }
//+------------------------------------------------------------------+
 
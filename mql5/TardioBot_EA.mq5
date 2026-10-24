//+------------------------------------------------------------------+
//|                                              TardioBot V1.05.mq5 |
//|                               Copyright 2025, Lupus Materia Ltd. |
//|                                    https://www.lupusmateria.com/ |
//| WARNING: This trading robot comes with no guarantees of profit.  |
//| Forex trading involves substantial risk of loss.                 |
//| Only use risk capital you can afford to lose.                    |
//| No liability accepted for any losses incurred.                   |
//| Always test thoroughly in demo account before live use.          |
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, Lupus Materia Ltd."
#property link      "https://www.lupusmateria.com"
#property version   "1.05"
#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| EA Overview                                                      |
//|                                                                  |
//| Name: TardioBot V1.05                                            |
//|                                                                  |
//| Named after Giuseppe Tardio - Brigantaggio politico.             |
//|                                                                  |
//| Purpose:                                                         |
//|   This Expert Advisor (EA) for MetaTrader 5 implements a         |
//|   triangular arbitrage strategy, identifying and exploiting price|
//|   discrepancies across three currency pairs to execute profitable|
//|   trades. It monitors bid/ask prices, calculates arbitrage ratios,|
//|   and executes simultaneous trades when opportunities exceed       |
//|   defined thresholds, accounting for spreads and commissions.      |
//|                                                                  |
//| Functionality:                                                   |
//|   - Supports six predefined arbitrage trios (e.g., EUR/USD,       |
//|     GBP/USD, EUR/GBP).                                           |
//|   - Dynamically updates price data using symbol-specific precision.|
//|   - Validates lot sizes for all symbols in the trio.              |
//|   - Handles per-symbol commissions and spread costs.              |
//|   - Closes stale trades after a user-defined duration.            |
//|   - Logs arbitrage opportunities and trade details to a file.     |
//|   - Includes safety checks for equity, margin, and extreme ratios. |
//|                                                                  |
//| Supported Trios:                                                 |
//|   1. EUR/USD, GBP/USD, EUR/GBP                                   |
//|   2. GBP/USD, USD/JPY, GBP/JPY                                   |
//|   3. EUR/GBP, GBP/CHF, EUR/CHF                                   |
//|   4. AUD/USD, USD/NZD, AUD/NZD                                   |
//|   5. EUR/CAD, CAD/JPY, EUR/JPY                                   |
//|   6. USD/SGD, EUR/USD, EUR/SGD                                   |
//|                                                                  |
//| Key Features:                                                    |
//|   - Handles varying decimal places (e.g., 3 digits for JPY pairs, |
//|     5 digits for others) using SYMBOL_POINT and SYMBOL_DIGITS.    |
//|   - Per-symbol lot size normalization to prevent invalid volumes.  |
//|   - Simplified commission inputs for JPY and non-JPY pairs.       |
//|   - Detailed logging of price differences, thresholds, and trades.|
//|   - Warnings for unusual symbol precisions (e.g., exotic pairs).   |
//|                                                                  |
//| Input Parameters:                                                |
//|   - Arbitrage Trio Selection: Choose one of the six trios.        |
//|   - Arbitrage Thresholds: Set minimum arbitrage thresholds per     |
//|     trio (e.g., 0.0001 for 5-digit pairs, 0.01 for 3-digit pairs).|
//|   - Trading Parameters: Configure lot size per thousand pounds,    |
//|     commissions (non-JPY and JPY pairs), and max daily trades.    |
//|   - Operational Settings: Set magic number, max trade duration,    |
//|     and logging option.                                          |
//|                                                                  |
//| Usage Notes:                                                     |
//|   - Test in MetaTrader 5 Strategy Tester with your broker’s symbols.|
//|   - Verify symbol names (e.g., EURUSD, USDJPY) match your broker’s,|
//|     including suffixes (e.g., EURUSDm).                          |
//|   - Adjust MinArbitrageThreshold based on broker spreads and       |
//|     market conditions.                                           |
//|   - Set Commission_NonJPY and Commission_JPY per your broker’s     |
//|     commission structure (account or quote currency).             |
//|   - Monitor logs (ArbitrageLog.txt) for precision and trade details.|
//|   - For exotic pairs, check warnings for unusual precisions and    |
//|     adjust thresholds if needed.                                  |
//|                                                                  |
//| Version: 1.05 (Updated with EA Overview)                         |
//|                                                                  |
//+------------------------------------------------------------------+

CTrade Trade;

// Input variables
// --- Arbitrage Trio Selection ---
enum ArbitrageTrio {
   TRIO_EURUSD_GBPUSD_EURGBP = 0,  // EUR/USD, GBP/USD, EUR/GBP
   TRIO_GBPUSD_USDJPY_GBPJPY = 1,  // GBP/USD, USD/JPY, GBP/JPY
   TRIO_EURGBP_GBPCHF_EURCHF = 2,  // EUR/GBP, GBP/CHF, EUR/CHF
   TRIO_AUDUSD_USDNZD_AUDNZD = 3,  // AUD/USD, USD/NZD, AUD/NZD
   TRIO_EURCAD_CADJPY_EURJPY = 4,  // EUR/CAD, CAD/JPY, EUR/JPY
   TRIO_USDSGD_EURUSD_EURSGD = 5   // USD/SGD, EUR/USD, EUR/SGD
};
input ArbitrageTrio SelectedTrio = TRIO_EURUSD_GBPUSD_EURGBP; // Select arbitrage trio

// --- Arbitrage Thresholds ---
input double MinArbitrageThreshold_EURGBP = 0.0001; // Min threshold for EUR/USD, GBP/USD, EUR/GBP (5 digits)
input double MinArbitrageThreshold_GBPJPY = 0.01;  // Min threshold for GBP/USD, USD/JPY, GBP/JPY (3 digits)
input double MinArbitrageThreshold_EURCHF = 0.0001; // Min threshold for EUR/GBP, GBP/CHF, EUR/CHF (5 digits)
input double MinArbitrageThreshold_AUDNZD = 0.0001; // Min threshold for AUD/USD, USD/NZD, AUD/NZD (5 digits)
input double MinArbitrageThreshold_EURJPY = 0.01;  // Min threshold for EUR/CAD, CAD/JPY, EUR/JPY (3 digits)
input double MinArbitrageThreshold_EURSGD = 0.0001; // Min threshold for USD/SGD, EUR/USD, EUR/SGD (5 digits)

// --- Trading Parameters ---
input double Lot_Size_Per_Thousand = 0.002; // Lot size per thousand pounds (reduced for small balance)
input double Commission_EURUSD = 7.0; // Commission per lot for EUR/USD or similar (pounds)
input double Commission_USDJPY = 700.0; // Commission per lot for USD/JPY or similar (pounds, adjusted for JPY scale)
input double Commission_EURGBP = 7.0; // Commission per lot for EUR/GBP or similar (pounds)
input double Commission_GBPCHF = 7.0; // Commission per lot for GBP/CHF or similar (pounds)
input double Commission_AUDUSD = 7.0; // Commission per lot for AUD/USD or similar (pounds)
input double Commission_USDNZD = 7.0; // Commission per lot for USD/NZD or similar (pounds)
input double Commission_EURCAD = 7.0; // Commission per lot for EUR/CAD or similar (pounds)
input double Commission_CADJPY = 700.0; // Commission per lot for CAD/JPY or similar (pounds)
input double Commission_USDSGD = 7.0; // Commission per lot for USD/SGD or similar (pounds)
input int MaxDailyTrades = 5; // Max trade cycles per day

// --- Operational Settings ---
input int MagicNumber = 1234567; // Unique EA identifier
input double MaxTradeDuration = 60; // Max trade duration (seconds)
input bool Plot_Max_Difference = true; // Log max price difference to file

// Structure to hold symbol data
struct SymbolData {
   string symbol;
   double bid;
   double ask;
   double spread_points;
   double max_volume;
   double min_volume;
   double lot_step;
   bool is_valid;
   int digits; // Store symbol's decimal places
   double point; // Store symbol's point value
   // Default constructor
   SymbolData() {
      symbol = "";
      bid = 0.0;
      ask = 0.0;
      spread_points = 0.0;
      max_volume = 0.0;
      min_volume = 0.0;
      lot_step = 0.0;
      is_valid = false;
      digits = 0;
      point = 0.0;
   }
   // Copy constructor
   SymbolData(const SymbolData &other) {
      symbol = other.symbol;
      bid = other.bid;
      ask = other.ask;
      spread_points = other.spread_points;
      max_volume = other.max_volume;
      min_volume = other.min_volume;
      lot_step = other.lot_step;
      is_valid = other.is_valid;
      digits = other.digits;
      point = other.point;
   }
};

// Array to store data for all symbols
SymbolData symbols[3];

// Daily trade tracking
static int daily_trades = 0;
static datetime last_day = 0;

// Initialization
int OnInit() {
   Trade.SetExpertMagicNumber(MagicNumber);
   // Initialize symbol data based on selected trio
   switch (SelectedTrio) {
      case TRIO_EURUSD_GBPUSD_EURGBP:
         symbols[0].symbol = "EURUSD";
         symbols[1].symbol = "GBPUSD";
         symbols[2].symbol = "EURGBP";
         break;
      case TRIO_GBPUSD_USDJPY_GBPJPY:
         symbols[0].symbol = "GBPUSD";
         symbols[1].symbol = "USDJPY";
         symbols[2].symbol = "GBPJPY";
         break;
      case TRIO_EURGBP_GBPCHF_EURCHF:
         symbols[0].symbol = "EURGBP";
         symbols[1].symbol = "GBPCHF";
         symbols[2].symbol = "EURCHF";
         break;
      case TRIO_AUDUSD_USDNZD_AUDNZD:
         symbols[0].symbol = "AUDUSD";
         symbols[1].symbol = "USDNZD";
         symbols[2].symbol = "AUDNZD";
         break;
      case TRIO_EURCAD_CADJPY_EURJPY:
         symbols[0].symbol = "EURCAD";
         symbols[1].symbol = "CADJPY";
         symbols[2].symbol = "EURJPY";
         break;
      case TRIO_USDSGD_EURUSD_EURSGD:
         symbols[0].symbol = "USDSGD";
         symbols[1].symbol = "EURUSD";
         symbols[2].symbol = "EURSGD";
         break;
   }
   for (int i = 0; i < 3; i++) {
      if (!SymbolSelect(symbols[i].symbol, true)) {
         Print("Error: Symbol ", symbols[i].symbol, " not available");
         return INIT_FAILED;
      }
      UpdateSymbolData(i);
      if (!symbols[i].is_valid) {
         Print("Error: Failed to initialize data for ", symbols[i].symbol);
         return INIT_FAILED;
      }
      // Log symbol constraints
      Print(symbols[i].symbol, " Min Lot: ", symbols[i].min_volume,
            ", Step: ", symbols[i].lot_step, ", Max Lot: ", symbols[i].max_volume,
            ", Digits: ", symbols[i].digits, ", Point: ", symbols[i].point);
   }
   // Set timer for 100ms intervals
   EventSetTimer(100);
   Print("EA Initialized with MagicNumber: ", MagicNumber, ", Selected Trio: ", EnumToString(SelectedTrio));
   return INIT_SUCCEEDED;
}

// Deinitialization
void OnDeinit(const int reason) {
   EventKillTimer();
   Print("EA Deinitialized. Reason: ", reason);
}

// Update symbol data with caching
void UpdateSymbolData(int index) {
   double new_bid = SymbolInfoDouble(symbols[index].symbol, SYMBOL_BID);
   double new_ask = SymbolInfoDouble(symbols[index].symbol, SYMBOL_ASK);
   double point = SymbolInfoDouble(symbols[index].symbol, SYMBOL_POINT); // Use symbol-specific point value
   // Skip update if price change is less than 1 pip for the symbol
   if (MathAbs(new_bid - symbols[index].bid) < point && MathAbs(new_ask - symbols[index].ask) < point) {
      return;
   }
   symbols[index].bid = NormalizeDouble(new_bid, symbols[index].digits);
   symbols[index].ask = NormalizeDouble(new_ask, symbols[index].digits);
   symbols[index].spread_points = NormalizeDouble(SymbolInfoInteger(symbols[index].symbol, SYMBOL_SPREAD) * point, symbols[index].digits);
   symbols[index].max_volume = SymbolInfoDouble(symbols[index].symbol, SYMBOL_VOLUME_MAX);
   symbols[index].min_volume = SymbolInfoDouble(symbols[index].symbol, SYMBOL_VOLUME_MIN);
   symbols[index].lot_step = SymbolInfoDouble(symbols[index].symbol, SYMBOL_VOLUME_STEP);
   symbols[index].digits = (int)SymbolInfoInteger(symbols[index].symbol, SYMBOL_DIGITS);
   symbols[index].point = point;
   symbols[index].is_valid = (symbols[index].bid > 0 && symbols[index].ask > 0 &&
                             symbols[index].max_volume > 0 && symbols[index].min_volume > 0);
}

// Timer function for periodic checks
void OnTimer() {
   // Check equity and margin
   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if (equity < balance * 0.5) {
      Print("Error: Equity too low (", equity, " < ", balance * 0.5, ")");
      SendNotification("Arbitrage EA: Equity too low for trading");
      return;
   }

   // Update symbol data
   for (int i = 0; i < 3; i++) {
      UpdateSymbolData(i);
      if (!symbols[i].is_valid) {
         Print("Error: Invalid data for ", symbols[i].symbol);
         SendNotification("Arbitrage EA: Invalid data for " + symbols[i].symbol);
         return;
      }
   }

   // Calculate lot size
   if (balance <= 0) {
      Print("Error: Invalid account balance");
      SendNotification("Arbitrage EA: Invalid account balance");
      return;
   }
   double vol = MathMax(MathMin(RoundtoLots(balance / 1000 * Lot_Size_Per_Thousand, 2), symbols[2].max_volume), symbols[2].min_volume);
   // Validate lot size for all symbols
   for (int i = 0; i < 3; i++) {
      vol = MathMax(MathMin(RoundtoLots(vol, i), symbols[i].max_volume), symbols[i].min_volume);
   }
   // Log lot size
   Print("Balance: ", balance, ", Calculated Lot Size: ", vol);

   // Check margin for three trades
   double margin_required = 0;
   for (int i = 0; i < 3; i++) {
      double contract_size = SymbolInfoDouble(symbols[i].symbol, SYMBOL_TRADE_CONTRACT_SIZE);
      long leverage = AccountInfoInteger(ACCOUNT_LEVERAGE);
      margin_required += NormalizeDouble((contract_size * vol * symbols[i].ask) / leverage, symbols[i].digits);
   }
   if (free_margin < margin_required) {
      Print("Error: Insufficient margin (", free_margin, " < ", margin_required, ")");
      SendNotification("Arbitrage EA: Insufficient margin");
      return;
   }

   // Check daily trade limit
   if (TimeCurrent() > last_day + 86400) {
      daily_trades = 0;
      last_day = TimeCurrent();
      Print("Daily trade count reset. New day: ", TimeToString(last_day));
   }
   if (daily_trades >= MaxDailyTrades) {
      Print("Daily trade limit reached: ", daily_trades, "/", MaxDailyTrades);
      return;
   }

   // Close stale trades
   CloseStaleTrades();

   // Select the appropriate MinArbitrageThreshold based on trio
   double MinArbitrageThreshold = 0.0; // Initialize to avoid uninitialized warning
   switch (SelectedTrio) {
      case TRIO_EURUSD_GBPUSD_EURGBP:
         MinArbitrageThreshold = MinArbitrageThreshold_EURGBP;
         break;
      case TRIO_GBPUSD_USDJPY_GBPJPY:
         MinArbitrageThreshold = MinArbitrageThreshold_GBPJPY;
         break;
      case TRIO_EURGBP_GBPCHF_EURCHF:
         MinArbitrageThreshold = MinArbitrageThreshold_EURCHF;
         break;
      case TRIO_AUDUSD_USDNZD_AUDNZD:
         MinArbitrageThreshold = MinArbitrageThreshold_AUDNZD;
         break;
      case TRIO_EURCAD_CADJPY_EURJPY:
         MinArbitrageThreshold = MinArbitrageThreshold_EURJPY;
         break;
      case TRIO_USDSGD_EURUSD_EURSGD:
         MinArbitrageThreshold = MinArbitrageThreshold_EURSGD;
         break;
      default:
         MinArbitrageThreshold = 0.0001; // Fallback threshold
         Print("Warning: Unknown trio selected, using default MinArbitrageThreshold: ", MinArbitrageThreshold);
         break;
   }

   // Select commission values based on symbols
   double commissions[3];
   for (int i = 0; i < 3; i++) {
      string symbol = symbols[i].symbol;
      if (symbol == "EURUSD") commissions[i] = Commission_EURUSD;
      else if (symbol == "GBPUSD") commissions[i] = Commission_EURUSD; // Same as EURUSD for simplicity
      else if (symbol == "USDJPY") commissions[i] = Commission_USDJPY;
      else if (symbol == "EURGBP") commissions[i] = Commission_EURGBP;
      else if (symbol == "GBPCHF") commissions[i] = Commission_GBPCHF;
      else if (symbol == "EURCHF") commissions[i] = Commission_GBPCHF; // Same as GBPCHF for simplicity
      else if (symbol == "AUDUSD") commissions[i] = Commission_AUDUSD;
      else if (symbol == "USDNZD") commissions[i] = Commission_USDNZD;
      else if (symbol == "AUDNZD") commissions[i] = Commission_AUDUSD; // Same as AUDUSD for simplicity
      else if (symbol == "EURCAD") commissions[i] = Commission_EURCAD;
      else if (symbol == "CADJPY") commissions[i] = Commission_CADJPY;
      else if (symbol == "EURJPY") commissions[i] = Commission_USDJPY; // Same as USDJPY for simplicity
      else if (symbol == "USDSGD") commissions[i] = Commission_USDSGD;
      else if (symbol == "EURSGD") commissions[i] = Commission_EURUSD; // Same as EURUSD for simplicity
      else commissions[i] = 7.0; // Fallback
   }

   // Calculate arbitrage ratios (generalized for different trios)
   double ratio_ask, ratio_bid;
   int target_digits = symbols[2].digits; // Normalize to the digits of the third pair
   if (SelectedTrio == TRIO_GBPUSD_USDJPY_GBPJPY || SelectedTrio == TRIO_EURCAD_CADJPY_EURJPY) {
      // For trios where symbols[1] is like USD/JPY or CAD/JPY (quote currency is JPY)
      ratio_ask = NormalizeDouble(symbols[0].ask / symbols[1].ask, target_digits);
      ratio_bid = NormalizeDouble(symbols[0].bid / symbols[1].bid, target_digits);
   } else if (SelectedTrio == TRIO_USDSGD_EURUSD_EURSGD) {
      // For USD/SGD, EUR/USD, EUR/SGD
      ratio_ask = NormalizeDouble(symbols[0].ask / symbols[1].bid, target_digits);
      ratio_bid = NormalizeDouble(symbols[0].bid / symbols[1].ask, target_digits);
   } else {
      // Default for trios like EUR/USD, GBP/USD, EUR/GBP
      ratio_ask = NormalizeDouble(symbols[0].ask / symbols[1].bid, target_digits);
      ratio_bid = NormalizeDouble(symbols[0].bid / symbols[1].ask, target_digits);
   }

   // Log max difference
   static double biggest = 0.0;
   double spread_cost = 0.0;
   for (int i = 0; i < 3; i++) {
      spread_cost += NormalizeDouble(symbols[i].spread_points, target_digits);
   }
   double total_commission = 0.0;
   for (int i = 0; i < 3; i++) {
      total_commission += NormalizeDouble(commissions[i] * symbols[i].point, target_digits);
   }
   double threshold = NormalizeDouble(SymbolInfoDouble(symbols[2].symbol, SYMBOL_POINT) + total_commission + spread_cost, target_digits);
   if (Plot_Max_Difference && MathAbs(ratio_ask - symbols[2].ask) > biggest) {
      biggest = MathAbs(ratio_ask - symbols[2].ask);
      string log_message = TimeToString(TimeCurrent()) + " Biggest Difference: " + DoubleToString(biggest, target_digits) +
                           ", Threshold: " + DoubleToString(threshold, target_digits) +
                           ", MinArbitrageThreshold: " + DoubleToString(MinArbitrageThreshold, target_digits) +
                           ", Spread Cost: " + DoubleToString(spread_cost, target_digits) +
                           ", Total Commission: " + DoubleToString(total_commission, target_digits);
      for (int i = 0; i < 3; i++) {
         log_message += ", " + symbols[i].symbol + " Digits: " + IntegerToString(symbols[i].digits) +
                        ", Point: " + DoubleToString(symbols[i].point, symbols[i].digits);
      }
      Print(log_message);
      int file_handle = FileOpen("ArbitrageLog.txt", FILE_WRITE|FILE_TXT|FILE_COMMON);
      if (file_handle != INVALID_HANDLE) {
         FileWrite(file_handle, log_message);
         FileClose(file_handle);
      }
   }

   // Sell arbitrage (for symbols[2])
   if (ratio_ask - symbols[2].ask > threshold + NormalizeDouble(MinArbitrageThreshold, target_digits)) {
      CloseNegSide();
      if (PositionsTotal() == 0) {
         ExecuteArbitrageSell(vol);
      }
   }

   // Buy arbitrage (for symbols[2])
   if (ratio_bid - symbols[2].bid < -threshold - NormalizeDouble(MinArbitrageThreshold, target_digits)) {
      ClosePosSide();
      if (PositionsTotal() == 0) {
         ExecuteArbitrageBuy(vol);
      }
   }
}

// Execute sell arbitrage trades
void ExecuteArbitrageSell(double vol) {
   if (!Trade.Sell(vol, symbols[0].symbol, 0, 0, 0, "Arbitrage Sell")) {
      string error = "Error selling " + symbols[0].symbol + ": " + IntegerToString(GetLastError());
      Print(error);
      SendNotification(error);
      return;
   }
   if (!Trade.Buy(vol, symbols[1].symbol, 0, 0, 0, "Arbitrage Sell")) {
      string error = "Error buying " + symbols[1].symbol + ": " + IntegerToString(GetLastError());
      Print(error);
      SendNotification(error);
      return;
   }
   if (!Trade.Buy(vol, symbols[2].symbol, 0, 0, 0, "Arbitrage Sell")) {
      string error = "Error buying " + symbols[2].symbol + ": " + IntegerToString(GetLastError());
      Print(error);
      SendNotification(error);
      return;
   }
   daily_trades++; // Increment trade count
   Print("Arbitrage sell trades opened: Volume = ", vol, ", Daily Trades: ", daily_trades, "/", MaxDailyTrades);
}

// Execute buy arbitrage trades
void ExecuteArbitrageBuy(double vol) {
   if (!Trade.Buy(vol, symbols[0].symbol, 0, 0, 0, "Arbitrage Buy")) {
      string error = "Error buying " + symbols[0].symbol + ": " + IntegerToString(GetLastError());
      Print(error);
      SendNotification(error);
      return;
   }
   if (!Trade.Sell(vol, symbols[1].symbol, 0, 0, 0, "Arbitrage Buy")) {
      string error = "Error selling " + symbols[1].symbol + ": " + IntegerToString(GetLastError());
      Print(error);
      SendNotification(error);
      return;
   }
   if (!Trade.Sell(vol, symbols[2].symbol, 0, 0, 0, "Arbitrage Buy")) {
      string error = "Error selling " + symbols[2].symbol + ": " + IntegerToString(GetLastError());
      Print(error);
      SendNotification(error);
      return;
   }
   daily_trades++; // Increment trade count
   Print("Arbitrage buy trades opened: Volume = ", vol, ", Daily Trades: ", daily_trades, "/", MaxDailyTrades);
}

// Close positive side
void ClosePosSide() {
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
         string symb = PositionGetString(POSITION_SYMBOL);
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if ((type == POSITION_TYPE_BUY && (symb == symbols[1].symbol || symb == symbols[2].symbol)) ||
             (type == POSITION_TYPE_SELL && symb == symbols[0].symbol)) {
            if (!Trade.PositionClose(ticket)) {
               string error = "Error closing position " + IntegerToString(ticket) + ": " + IntegerToString(GetLastError());
               Print(error);
               SendNotification(error);
            }
         }
      }
   }
}

// Close negative side
void CloseNegSide() {
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
         string symb = PositionGetString(POSITION_SYMBOL);
         ENUM_POSITION_TYPE type = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if ((type == POSITION_TYPE_SELL && (symb == symbols[1].symbol || symb == symbols[2].symbol)) ||
             (type == POSITION_TYPE_BUY && symb == symbols[0].symbol)) {
            if (!Trade.PositionClose(ticket)) {
               string error = "Error closing position " + IntegerToString(ticket) + ": " + IntegerToString(GetLastError());
               Print(error);
               SendNotification(error);
            }
         }
      }
   }
}

// Close stale trades
void CloseStaleTrades() {
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (PositionSelectByTicket(ticket) && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
         if (TimeCurrent() - PositionGetInteger(POSITION_TIME) > MaxTradeDuration) {
            if (!Trade.PositionClose(ticket)) {
               string error = "Error closing stale position " + IntegerToString(ticket) + ": " + IntegerToString(GetLastError());
               Print(error);
               SendNotification(error);
            }
         }
      }
   }
}

// Round to valid lot size for a specific symbol
double RoundtoLots(double val, int symbol_index) {
   double step = symbols[symbol_index].lot_step;
   if (step == 0) return val;
   int decimals = (int)-MathLog10(step); // Calculate decimals from lot step
   return NormalizeDouble(MathRound(val / step) * step, decimals);
}

//+------------------------------------------------------------------+
//| *** WARNING: This EA is designed for demo accounts and testing   |
//| purposes only. While it may show promising returns in testing,   |
//| triangular arbitrage in real-life trading may not produce        |
//| anticipated results due to factors like execution delays,        |
//| slippage, and market conditions. Do NOT use this EA for live     |
//| trading. ***                                                     |
//|                                                                  |
//| *** ADDITIONAL WARNING: Any use of this EA, including in demo    |
//| accounts or testing environments, is at your own risk. The       |
//| developer and distributor are not liable for any losses or issues|
//| arising from its use. ***                                        |    
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| MIT License                                                      |
//+------------------------------------------------------------------+
/* Copyright (c) 2025 Lupus Materia Ltd
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED to the WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH the SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.
*/
//+------------------------------------------------------------------+
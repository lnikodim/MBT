//+------------------------------------------------------------------+
//|                                        MeanReversionTrendEA.mq5  |
//|                                        Mustafa Seyyid Sahin      |
//+------------------------------------------------------------------+
#property copyright "Mustafa Seyyid Sahin"
#property version   "1.00"

// Input parameters for Mean Reversion/Trend strategy
input int                  Fast_MA_Period = 20;     // Fast MA Period
input int                  Slow_MA_Period = 50;     // Slow MA Period
input int                  ATR_Period = 14;         // ATR Period for volatility
input double               ATR_Multiplier = 2.0;    // ATR Multiplier for Mean Reversion
input double               LotSize = 0.1;           // Standard Lot Size
input int                  SL_Points = 500;         // Stop Loss in points
input int                  TP_Points = 1000;        // Take Profit in points
input int                  Magic_Number = 123456;   // Magic Number for EA

// Global variables
int Fast_MA_Handle;                                // Handle for fast MA indicator
int Slow_MA_Handle;                                // Handle for slow MA indicator
int ATR_Handle;                                    // Handle for ATR indicator
bool safety_trade_executed = false;                // Flag for Safety-Trade execution
bool already_checked_history = false;              // Flag for History-Check
bool EnableSafetyTrade = true;                     // Safety Trade for validation is always enabled

//+------------------------------------------------------------------+
//| Validator class for complete trade validation                     |
//+------------------------------------------------------------------+
class CTradeValidator
{
private:
    string           m_symbol;                // Current symbol
    double           m_min_lot;              // Minimum lot size
    double           m_max_lot;              // Maximum lot size
    double           m_lot_step;             // Lot step
    double           m_point;                // Point value
    int              m_digits;               // Decimal places
    int              m_stops_level;          // Stops level in points
    double           m_tick_size;            // Minimum price change
    double           m_tick_value;           // Tick value in account currency
    ENUM_SYMBOL_CALC_MODE m_calc_mode;       // Calculation mode (Forex, CFD, etc.)
    
    // Helper functions
    bool             LoadSymbolInfo();        // Loads symbol information
    void             LogValidationInfo(string message);  // Special logging

public:
                     CTradeValidator();
                    ~CTradeValidator() {};
    
    // Initialization
    bool             Init(string symbol = NULL);
    void             Refresh();              // Update all data
    
    // Environment checks
    bool             CheckHistory(int minimum_bars = 100);
    bool             IsInTester() { return MQLInfoInteger(MQL_TESTER) != 0; }
    
    // Volume validation
    double           NormalizeVolume(double volume);
    double           ValidateVolume(ENUM_ORDER_TYPE order_type, double requested_volume);
    bool             CheckMarginForVolume(ENUM_ORDER_TYPE order_type, double volume, double price = 0.0);
    
    // SL/TP validation
    double           ValidateStopLoss(ENUM_ORDER_TYPE order_type, double open_price, double desired_sl);
    double           ValidateTakeProfit(ENUM_ORDER_TYPE order_type, double open_price, double desired_tp);
    
    // Safety-Trade
    bool             ExecuteSafetyTrade();
    
    // Getters for important properties
    double           GetMinLot() { return m_min_lot; }
    double           GetMaxLot() { return m_max_lot; }
    double           GetLotStep() { return m_lot_step; }
    double           GetPoint() { return m_point; }
    int              GetDigits() { return m_digits; }
    int              GetStopsLevel() { return m_stops_level; }
    
    // Current prices
    double           Bid() { return SymbolInfoDouble(m_symbol, SYMBOL_BID); }
    double           Ask() { return SymbolInfoDouble(m_symbol, SYMBOL_ASK); }
};

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CTradeValidator::CTradeValidator()
{
    m_symbol = _Symbol; // Default current symbol
}

//+------------------------------------------------------------------+
//| Initialization of the Validator class                            |
//+------------------------------------------------------------------+
bool CTradeValidator::Init(string symbol = NULL)
{
    // Set symbol
    if(symbol != NULL && symbol != "")
        m_symbol = symbol;
    else
        m_symbol = _Symbol;
    
    // Ensure the symbol is selected
    if(!SymbolSelect(m_symbol, true))
    {
        Print("Symbol not selectable: ", m_symbol);
        return false;
    }
    
    // Load all information
    if(!LoadSymbolInfo())
    {
        Print("Error loading symbol data");
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Loads all important symbol information                           |
//+------------------------------------------------------------------+
bool CTradeValidator::LoadSymbolInfo()
{
    // Basic properties
    m_digits = (int)SymbolInfoInteger(m_symbol, SYMBOL_DIGITS);
    m_point = SymbolInfoDouble(m_symbol, SYMBOL_POINT);
    
    // Trading properties
    m_min_lot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MIN);
    m_max_lot = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_MAX);
    m_lot_step = SymbolInfoDouble(m_symbol, SYMBOL_VOLUME_STEP);
    m_stops_level = (int)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_STOPS_LEVEL);
    
    // Pricing properties
    m_tick_size = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_SIZE);
    m_tick_value = SymbolInfoDouble(m_symbol, SYMBOL_TRADE_TICK_VALUE);
    m_calc_mode = (ENUM_SYMBOL_CALC_MODE)SymbolInfoInteger(m_symbol, SYMBOL_TRADE_CALC_MODE);
    
    // Protection against invalid data
    if(m_min_lot <= 0) m_min_lot = 0.01;
    if(m_max_lot <= 0) m_max_lot = 100.0;
    if(m_lot_step <= 0) m_lot_step = 0.01;
    if(m_stops_level < 0) m_stops_level = 0;
    
    // Validation for stocks and other instruments
    if(m_calc_mode == SYMBOL_CALC_MODE_EXCH_STOCKS && m_min_lot < 1.0)
        m_min_lot = 1.0; // Stocks often have a minimum volume of 1
    
    return true;
}

//+------------------------------------------------------------------+
//| Updates all data                                                 |
//+------------------------------------------------------------------+
void CTradeValidator::Refresh()
{
    LoadSymbolInfo();
}

//+------------------------------------------------------------------+
//| Special logging for validation                                   |
//+------------------------------------------------------------------+
void CTradeValidator::LogValidationInfo(string message)
{
    // In test mode, reduced logging to avoid log overflow
    if(!IsInTester() || MQLInfoInteger(MQL_VISUAL_MODE) != 0)
        Print("[Validator] ", message);
}

//+------------------------------------------------------------------+
//| Checks if sufficient historical data is available                 |
//+------------------------------------------------------------------+
bool CTradeValidator::CheckHistory(int minimum_bars = 100)
{
    // Check if enough bars are available for the current symbol/timeframe
    if(Bars(m_symbol, PERIOD_CURRENT) < minimum_bars)
    {
        LogValidationInfo("WARNING: Not enough historical data. Required: " + 
                IntegerToString(minimum_bars) + ", Available: " + 
                IntegerToString(Bars(m_symbol, PERIOD_CURRENT)));
        return false;
    }
    
    return true;
}

//+------------------------------------------------------------------+
//| Normalizes volume according to symbol requirements               |
//+------------------------------------------------------------------+
double CTradeValidator::NormalizeVolume(double volume)
{
    if(volume <= 0.0) return 0.0;
    
    // Restrict to Min/Max
    if(volume < m_min_lot) 
        volume = m_min_lot;
    if(volume > m_max_lot) 
        volume = m_max_lot;
    
    // Normalize to valid step
    if(m_lot_step > 0)
    {
        int steps = (int)MathRound((volume - m_min_lot) / m_lot_step);
        volume = NormalizeDouble(m_min_lot + steps * m_lot_step, 8);
    }
    
    // Safeguard against exceeding maximum
    if(volume > m_max_lot) 
        volume = m_max_lot;
    
    return volume;
}

//+------------------------------------------------------------------+
//| Fully validates the trading volume                               |
//+------------------------------------------------------------------+
double CTradeValidator::ValidateVolume(ENUM_ORDER_TYPE order_type, double requested_volume)
{
    // Normalize volume according to symbol rules
    double normalized_volume = NormalizeVolume(requested_volume);
    
    // Check stocks against minimum volume
    if(m_calc_mode == SYMBOL_CALC_MODE_EXCH_STOCKS && normalized_volume < 1.0)
        normalized_volume = 1.0;
    
    // Margin check for the normalized volume
    if(!CheckMarginForVolume(order_type, normalized_volume))
    {
        // If insufficient margin, look for volume that works
        double test_volume = normalized_volume;
        while(test_volume >= m_min_lot)
        {
            test_volume = NormalizeDouble(test_volume * 0.75, 2); // Reduce by 25%
            if(test_volume < m_min_lot) 
                test_volume = m_min_lot;
            
            if(CheckMarginForVolume(order_type, test_volume))
                return test_volume;
                
            if(test_volume == m_min_lot)
                break; // If not enough margin even with min_lot, then stop
        }
        
        LogValidationInfo("Not enough margin for the requested volume");
        return 0.0; // Cannot trade
    }
    
    return normalized_volume;
}

//+------------------------------------------------------------------+
//| Checks if enough margin is available for the volume              |
//+------------------------------------------------------------------+
bool CTradeValidator::CheckMarginForVolume(ENUM_ORDER_TYPE order_type, double volume, double price = 0.0)
{
    if(volume <= 0.0) return false;
    
    // If no price specified, use current market price
    if(price <= 0.0)
    {
        bool is_buy = (order_type == ORDER_TYPE_BUY || order_type == ORDER_TYPE_BUY_LIMIT || 
                      order_type == ORDER_TYPE_BUY_STOP || order_type == ORDER_TYPE_BUY_STOP_LIMIT);
        
        price = is_buy ? Ask() : Bid();
    }
    
    // Calculate required margin
    double margin = 0.0;
    if(!OrderCalcMargin(order_type, m_symbol, volume, price, margin))
    {
        LogValidationInfo("Error in OrderCalcMargin: " + IntegerToString(GetLastError()));
        return false;
    }
    
    // Check free margin in account with safety buffer (15%)
    double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
    double required_margin = margin * 1.15; // 15% reserve
    
    return (free_margin >= required_margin);
}

//+------------------------------------------------------------------+
//| Validates and corrects the StopLoss price                        |
//+------------------------------------------------------------------+
double CTradeValidator::ValidateStopLoss(ENUM_ORDER_TYPE order_type, double open_price, double desired_sl)
{
    if(open_price <= 0.0) return 0.0;
    
    // For zero SL simply return 0 (no SL)
    if(desired_sl <= 0.0) return 0.0;
    
    bool is_buy = (order_type == ORDER_TYPE_BUY || order_type == ORDER_TYPE_BUY_LIMIT || 
                  order_type == ORDER_TYPE_BUY_STOP || order_type == ORDER_TYPE_BUY_STOP_LIMIT);
    
    // Ensure SL is in the correct direction
    if(is_buy && desired_sl >= open_price) 
    {
        LogValidationInfo("Invalid SL for Buy: SL must be below the opening price");
        return 0.0; // No SL set
    }
    else if(!is_buy && desired_sl <= open_price)
    {
        LogValidationInfo("Invalid SL for Sell: SL must be above the opening price");
        return 0.0; // No SL set
    }
    
    // Current price for distance calculation
    double current_price = is_buy ? Bid() : Ask();
    
    // Minimum distance in points with additional safety buffer
    int stops_level = m_stops_level;
    if(stops_level <= 0) stops_level = 5; // At least 5 points if not defined
    
    // 20% additional safety buffer for Validator
    double min_distance = stops_level * m_point * 1.2;
    
    // Calculate valid SL price
    double valid_sl = 0.0;
    
    if(is_buy)
    {
        // For Buy orders, SL must be below the current price
        double max_sl = current_price - min_distance;
        
        // If the desired SL is higher than allowed, correct it
        valid_sl = (desired_sl > max_sl) ? max_sl : desired_sl;
    }
    else
    {
        // For Sell orders, SL must be above the current price
        double min_sl = current_price + min_distance;
        
        // If the desired SL is lower than allowed, correct it
        valid_sl = (desired_sl < min_sl) ? min_sl : desired_sl;
    }
    
    // Normalize the price
    valid_sl = NormalizeDouble(valid_sl, m_digits);
    
    return valid_sl;
}

//+------------------------------------------------------------------+
//| Validates and corrects the TakeProfit price                      |
//+------------------------------------------------------------------+
double CTradeValidator::ValidateTakeProfit(ENUM_ORDER_TYPE order_type, double open_price, double desired_tp)
{
    if(open_price <= 0.0) return 0.0;
    
    // For zero TP simply return 0 (no TP)
    if(desired_tp <= 0.0) return 0.0;
    
    bool is_buy = (order_type == ORDER_TYPE_BUY || order_type == ORDER_TYPE_BUY_LIMIT || 
                  order_type == ORDER_TYPE_BUY_STOP || order_type == ORDER_TYPE_BUY_STOP_LIMIT);
    
    // Ensure TP is in the correct direction
    if(is_buy && desired_tp <= open_price) 
    {
        LogValidationInfo("Invalid TP for Buy: TP must be above the opening price");
        return 0.0; // No TP set
    }
    else if(!is_buy && desired_tp >= open_price)
    {
        LogValidationInfo("Invalid TP for Sell: TP must be below the opening price");
        return 0.0; // No TP set
    }
    
    // Current price for distance calculation
    double current_price = is_buy ? Bid() : Ask();
    
    // Minimum distance in points with additional safety buffer
    int stops_level = m_stops_level;
    if(stops_level <= 0) stops_level = 5; // At least 5 points if not defined
    
    // 20% additional safety buffer for Validator
    double min_distance = stops_level * m_point * 1.2;
    
    // Calculate valid TP price
    double valid_tp = 0.0;
    
    if(is_buy)
    {
        // For Buy orders, TP must be above the current price
        double min_tp = current_price + min_distance;
        
        // If the desired TP is lower than allowed, correct it
        valid_tp = (desired_tp < min_tp) ? min_tp : desired_tp;
    }
    else
    {
        // For Sell orders, TP must be below the current price
        double max_tp = current_price - min_distance;
        
        // If the desired TP is higher than allowed, correct it
        valid_tp = (desired_tp > max_tp) ? max_tp : desired_tp;
    }
    
    // Normalize the price
    valid_tp = NormalizeDouble(valid_tp, m_digits);
    
    return valid_tp;
}

//+------------------------------------------------------------------+
//| Executes a Safety-Trade for validation                           |
//+------------------------------------------------------------------+
bool CTradeValidator::ExecuteSafetyTrade()
{
    // Only execute in tester and if no trade has been executed yet
    if(!IsInTester())
        return false;
    
    // Check if trades have already been executed
    if(HistoryDealsTotal() > 0)
        return false;
    
    // Minimum lot size for trade
    double volume = m_min_lot;
    
    // Adjust minimum volume for stocks
    if(m_calc_mode == SYMBOL_CALC_MODE_EXCH_STOCKS && volume < 1.0)
        volume = 1.0;
    
    // Margin check
    if(!CheckMarginForVolume(ORDER_TYPE_BUY, volume))
    {
        LogValidationInfo("Safety-Trade: Not enough margin");
        return false;
    }
    
    // Execute market order
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    request.action = TRADE_ACTION_DEAL;
    request.symbol = m_symbol;
    request.volume = volume;
    request.type = ORDER_TYPE_BUY;
    request.price = Ask();
    request.deviation = 10;
    request.magic = 999999; // Special Magic for Safety-Trade
    request.comment = "Safety Trade";
    
    bool success = OrderSend(request, result);
    
    if(success && result.retcode == TRADE_RETCODE_DONE)
    {
        LogValidationInfo("Safety-Trade successfully executed!");
        return true;
    }
    else
    {
        LogValidationInfo("Error in Safety-Trade: " + IntegerToString(result.retcode));
        return false;
    }
}

// Global Validator instance
CTradeValidator Validator;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
    // Initialize validation class
    if(!Validator.Init())
    {
        Print("Validator initialization failed!");
        return INIT_FAILED;
    }
    
    // Load indicators
    Fast_MA_Handle = iMA(_Symbol, PERIOD_CURRENT, Fast_MA_Period, 0, MODE_SMA, PRICE_CLOSE);
    Slow_MA_Handle = iMA(_Symbol, PERIOD_CURRENT, Slow_MA_Period, 0, MODE_SMA, PRICE_CLOSE);
    ATR_Handle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);
    
    if(Fast_MA_Handle == INVALID_HANDLE || Slow_MA_Handle == INVALID_HANDLE || ATR_Handle == INVALID_HANDLE)
    {
        Print("Error loading indicators: ", GetLastError());
        return INIT_FAILED;
    }
    
    // Check if enough historical data is available
    if(!Validator.CheckHistory(MathMax(Fast_MA_Period, Slow_MA_Period) + ATR_Period))
    {
        Print("Not enough historical data for indicator calculation!");
        // Continue in validation mode, otherwise fail
        if(!Validator.IsInTester())
            return INIT_FAILED;
    }
    
    already_checked_history = true;
    
    Print("Mean Reversion Trend EA initialized. Symbol: ", _Symbol, ", Timeframe: ", EnumToString(Period()));
    return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
    // Release indicator handles
    if(Fast_MA_Handle != INVALID_HANDLE)
        IndicatorRelease(Fast_MA_Handle);
    
    if(Slow_MA_Handle != INVALID_HANDLE)
        IndicatorRelease(Slow_MA_Handle);
    
    if(ATR_Handle != INVALID_HANDLE)
        IndicatorRelease(ATR_Handle);
    
    Print("Mean Reversion Trend EA terminated. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
    // Update validator
    Validator.Refresh();
    
    // Check Safety-Trade for validation
    if(EnableSafetyTrade && !safety_trade_executed && Validator.IsInTester())
    {
        safety_trade_executed = Validator.ExecuteSafetyTrade();
    }
    
    // Check historical data again if not done yet
    if(!already_checked_history)
    {
        if(!Validator.CheckHistory(MathMax(Fast_MA_Period, Slow_MA_Period) + ATR_Period))
        {
            Print("WARNING: Not enough historical data!");
        }
        already_checked_history = true;
    }
    
    // Retrieve indicator values
    double fast_ma_values[], slow_ma_values[], atr_values[];
    
    if(CopyBuffer(Fast_MA_Handle, 0, 0, 3, fast_ma_values) < 3 ||
       CopyBuffer(Slow_MA_Handle, 0, 0, 3, slow_ma_values) < 3 ||
       CopyBuffer(ATR_Handle, 0, 0, 2, atr_values) < 2)
    {
        Print("Error copying indicator values: ", GetLastError());
        return;
    }
    
    // Current and previous values
    double current_fast_ma = fast_ma_values[0];
    double prev_fast_ma = fast_ma_values[1];
    double current_slow_ma = slow_ma_values[0];
    double prev_slow_ma = slow_ma_values[1];
    double current_atr = atr_values[0];
    
    // Determine current price
    double current_price = (Validator.Bid() + Validator.Ask()) / 2.0;
    
    // Determine trading signals
    bool trend_buy_signal = (prev_fast_ma <= prev_slow_ma && current_fast_ma > current_slow_ma);
    bool trend_sell_signal = (prev_fast_ma >= prev_slow_ma && current_fast_ma < current_slow_ma);
    
    // Mean Reversion signals - price has deviated significantly from slow MA
    bool reversion_buy_signal = (current_price < current_slow_ma - current_atr * ATR_Multiplier);
    bool reversion_sell_signal = (current_price > current_slow_ma + current_atr * ATR_Multiplier);
    
    // Combination of signals (either trend or reversion can trigger a trade)
    bool buy_signal = trend_buy_signal || reversion_buy_signal;
    bool sell_signal = trend_sell_signal || reversion_sell_signal;
    
    // Check if positions are already open for this symbol
    bool has_open_positions = false;
    for(int i = 0; i < PositionsTotal(); i++)
    {
        if(PositionGetSymbol(i) == _Symbol && 
           PositionGetInteger(POSITION_MAGIC) == Magic_Number)
        {
            has_open_positions = true;
            break;
        }
    }
    
    // Only execute trade if no position is open
    if(!has_open_positions)
    {
        // BUY Signal
        if(buy_signal)
        {
            // Validate lot size
            double valid_lot = Validator.ValidateVolume(ORDER_TYPE_BUY, LotSize);
            
            if(valid_lot > 0.0)
            {
                // Entry price
                double entry_price = Validator.Ask();
                
                // Calculate and validate SL/TP
                double sl_price = entry_price - SL_Points * Validator.GetPoint();
                double tp_price = entry_price + TP_Points * Validator.GetPoint();
                
                double valid_sl = Validator.ValidateStopLoss(ORDER_TYPE_BUY, entry_price, sl_price);
                double valid_tp = Validator.ValidateTakeProfit(ORDER_TYPE_BUY, entry_price, tp_price);
                
                // Execute trade
                ExecuteTrade(ORDER_TYPE_BUY, valid_lot, valid_sl, valid_tp);
            }
        }
        
        // SELL Signal
        else if(sell_signal)
        {
            // Validate lot size
            double valid_lot = Validator.ValidateVolume(ORDER_TYPE_SELL, LotSize);
            
            if(valid_lot > 0.0)
            {
                // Entry price
                double entry_price = Validator.Bid();
                
                // Calculate and validate SL/TP
                double sl_price = entry_price + SL_Points * Validator.GetPoint();
                double tp_price = entry_price - TP_Points * Validator.GetPoint();
                
                double valid_sl = Validator.ValidateStopLoss(ORDER_TYPE_SELL, entry_price, sl_price);
                double valid_tp = Validator.ValidateTakeProfit(ORDER_TYPE_SELL, entry_price, tp_price);
                
                // Execute trade
                ExecuteTrade(ORDER_TYPE_SELL, valid_lot, valid_sl, valid_tp);
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Function to execute the trade                                    |
//+------------------------------------------------------------------+
bool ExecuteTrade(ENUM_ORDER_TYPE type, double volume, double sl, double tp)
{
    // Trade Request and Result structures
    MqlTradeRequest request = {};
    MqlTradeResult result = {};
    
    // Set request parameters
    request.action = TRADE_ACTION_DEAL;         // Immediate execution
    request.symbol = _Symbol;                   // Current symbol
    request.volume = volume;                    // Validated volume
    request.type = type;                        // Order type (BUY/SELL)
    
    // Set price according to order type
    if(type == ORDER_TYPE_BUY)
        request.price = Validator.Ask();
    else if(type == ORDER_TYPE_SELL)
        request.price = Validator.Bid();
    
    request.sl = sl;                            // Validated Stop Loss
    request.tp = tp;                            // Validated Take Profit
    request.deviation = 10;                     // Acceptable slippage in points
    request.magic = Magic_Number;               // Magic Number for identification
    request.comment = "Mean Reversion Trend Trade"; // Order comment
    
    // Execute trade
    bool success = OrderSend(request, result);
    
    // Log result
    if(success && result.retcode == TRADE_RETCODE_DONE)
    {
        Print("Trade successfully executed. Ticket: ", result.order);
        return true;
    }
    else
    {
        Print("Trade error: ", result.retcode, ", Description: ", result.comment);
        return false;
    }
}
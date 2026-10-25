#property copyright "Copyright 2025 "
#property description "RSI EA MT5"
#property version   "1.0"

//-INCLUDES-//
#include <Trade\Trade.mqh>

// Replacement for MQLTA Utils.mqh
enum ENUM_HOUR
{
    h00 = 0, h01 = 1, h02 = 2, h03 = 3, h04 = 4, h05 = 5,
    h06 = 6, h07 = 7, h08 = 8, h09 = 9, h10 = 10, h11 = 11,
    h12 = 12, h13 = 13, h14 = 14, h15 = 15, h16 = 16, h17 = 17,
    h18 = 18, h19 = 19, h20 = 20, h21 = 21, h22 = 22, h23 = 23
};

// Replacement for MQLTA ErrorHandling.mqh
string GetLastErrorText(int error_code)
{
    string error_text;
    
    switch(error_code)
    {
        case 0: error_text = "No error"; break;
        case 4001: error_text = "Wrong function pointer"; break;
        case 4002: error_text = "Array index out of range"; break;
        case 4003: error_text = "No memory for function call stack"; break;
        case 4004: error_text = "Recursive stack overflow"; break;
        case 4005: error_text = "Not enough stack for parameter"; break;
        case 4006: error_text = "No memory for parameter string"; break;
        case 4007: error_text = "No memory for temp string"; break;
        case 4008: error_text = "Not initialized string"; break;
        case 4009: error_text = "Not initialized string in array"; break;
        case 4010: error_text = "No memory for array string"; break;
        case 4011: error_text = "Too long string"; break;
        case 4012: error_text = "Remainder from zero divide"; break;
        case 4013: error_text = "Zero divide"; break;
        case 4014: error_text = "Unknown command"; break;
        case 4015: error_text = "Wrong jump"; break;
        case 4016: error_text = "Not initialized array"; break;
        case 4017: error_text = "DLL calls not allowed"; break;
        case 4018: error_text = "Cannot load library"; break;
        case 4019: error_text = "Cannot call function"; break;
        case 4020: error_text = "Expert function calls not allowed"; break;
        case 4021: error_text = "Not enough memory for temp string returned"; break;
        case 4022: error_text = "System is busy"; break;
        case 4023: error_text = "DLL-function call critical error"; break;
        case 4024: error_text = "Internal error"; break;
        case 4025: error_text = "Out of memory"; break;
        case 4026: error_text = "Invalid pointer"; break;
        case 4027: error_text = "Too many formatters in format function"; break;
        case 4028: error_text = "Parameters count exceeds formatters count"; break;
        case 4029: error_text = "Invalid array"; break;
        case 4030: error_text = "No reply from chart"; break;
        case 4050: error_text = "Invalid function parameters count"; break;
        case 4051: error_text = "Invalid function parameter value"; break;
        case 4052: error_text = "String function internal error"; break;
        case 4053: error_text = "Some array error"; break;
        case 4054: error_text = "Incorrect series array using"; break;
        case 4055: error_text = "Custom indicator error"; break;
        case 4056: error_text = "Arrays are incompatible"; break;
        case 4057: error_text = "Global variables processing error"; break;
        case 4058: error_text = "Global variable not found"; break;
        case 4059: error_text = "Function is not allowed in testing mode"; break;
        case 4060: error_text = "Function is not allowed for call"; break;
        case 4061: error_text = "Send mail error"; break;
        case 4062: error_text = "String parameter expected"; break;
        case 4063: error_text = "Integer parameter expected"; break;
        case 4064: error_text = "Double parameter expected"; break;
        case 4065: error_text = "Array as parameter expected"; break;
        case 4066: error_text = "Requested history data in updating state"; break;
        case 4067: error_text = "Internal trade error"; break;
        case 4068: error_text = "Resource not found"; break;
        case 4069: error_text = "Resource not supported"; break;
        case 4070: error_text = "Duplicate resource"; break;
        case 4071: error_text = "Custom indicator cannot initialize"; break;
        case 4072: error_text = "Cannot load custom indicator"; break;
        case 4073: error_text = "No history data"; break;
        case 4074: error_text = "No memory for history data"; break;
        case 4075: error_text = "Not enough memory for indicator calculation"; break;
        case 4099: error_text = "End of file"; break;
        case 4100: error_text = "Some file error"; break;
        case 4101: error_text = "Wrong file name"; break;
        case 4102: error_text = "Too many opened files"; break;
        case 4103: error_text = "Cannot open file"; break;
        case 4104: error_text = "Incompatible access to a file"; break;
        case 4105: error_text = "No order selected"; break;
        case 4106: error_text = "Unknown symbol"; break;
        case 4107: error_text = "Invalid price"; break;
        case 4108: error_text = "Invalid ticket"; break;
        case 4109: error_text = "Trade is not allowed"; break;
        case 4110: error_text = "Longs are not allowed"; break;
        case 4111: error_text = "Shorts are not allowed"; break;
        case 4112: error_text = "Automated trading disabled by client terminal"; break;
        case 4200: error_text = "Object already exists"; break;
        case 4201: error_text = "Unknown object property"; break;
        case 4202: error_text = "Object does not exist"; break;
        case 4203: error_text = "Unknown object type"; break;
        case 4204: error_text = "No object name"; break;
        case 4205: error_text = "Object coordinates error"; break;
        case 4206: error_text = "No specified subwindow"; break;
        case 4207: error_text = "Graphical object error"; break;
        case 5001: error_text = "Too many open files"; break;
        case 5002: error_text = "Wrong file name"; break;
        case 5003: error_text = "Too long file name"; break;
        case 5004: error_text = "Cannot open file"; break;
        case 5005: error_text = "Text file buffer allocation error"; break;
        case 5006: error_text = "Cannot delete file"; break;
        case 5007: error_text = "Invalid file handle"; break;
        case 5008: error_text = "Wrong file handle"; break;
        case 5009: error_text = "File must be opened with FILE_WRITE flag"; break;
        case 5010: error_text = "File must be opened with FILE_READ flag"; break;
        case 5011: error_text = "File must be opened with FILE_BIN flag"; break;
        case 5012: error_text = "File must be opened with FILE_TXT flag"; break;
        case 5013: error_text = "File must be opened with FILE_TXT or FILE_CSV flag"; break;
        case 5014: error_text = "File must be opened with FILE_CSV flag"; break;
        case 5015: error_text = "File read error"; break;
        case 5016: error_text = "File write error"; break;
        case 5017: error_text = "String size must be specified for binary file"; break;
        case 5018: error_text = "Incompatible file"; break;
        case 5019: error_text = "File is directory"; break;
        case 5020: error_text = "File does not exist"; break;
        case 5021: error_text = "File cannot be rewritten"; break;
        case 5022: error_text = "Wrong directory name"; break;
        case 5023: error_text = "Directory does not exist"; break;
        case 5024: error_text = "Specified file is not directory"; break;
        case 5025: error_text = "Cannot delete directory"; break;
        case 5026: error_text = "Cannot clean directory"; break;
        case 5027: error_text = "Array resize error"; break;
        case 5028: error_text = "String resize error"; break;
        case 5029: error_text = "Structure contains strings or dynamic arrays"; break;
        default: error_text = "Unknown error"; break;
    }
    
    return error_text;
}

bool AccountBalance()
{
    return AccountInfoDouble(ACCOUNT_BALANCE);
}

bool AccountEquity()
{
    return AccountInfoDouble(ACCOUNT_EQUITY);
}

bool AccountFreeMargin()
{
    return AccountInfoDouble(ACCOUNT_MARGIN_FREE);
}

bool IsCurrentTimeInInterval(int start_hour, int end_hour)
{
    MqlDateTime current_time;
    TimeToStruct(TimeCurrent(), current_time);
    int current_hour = current_time.hour;
    
    if (start_hour <= end_hour)
    {
        return (current_hour >= start_hour && current_hour < end_hour);
    }
    else
    {
        return (current_hour >= start_hour || current_hour < end_hour);
    }
}

enum ENUM_RISK_BASE
{
    RISK_BASE_EQUITY = 1,
    RISK_BASE_BALANCE = 2,
    RISK_BASE_FREEMARGIN = 3,
};

enum ENUM_RISK_DEFAULT_SIZE
{
    RISK_DEFAULT_FIXED = 1,
    RISK_DEFAULT_AUTO = 2,
};

enum ENUM_MODE_SL
{
    SL_FIXED = 0,
    SL_AUTO = 1,
};

enum ENUM_MODE_TP
{
    TP_FIXED = 0,
    TP_AUTO = 1,
};

// EA Configuration Parameters
input string Comment_0 = "==========";
input int MomentumPeriod = 14;
input double UpperThreshold = 80;
input double LowerThreshold = 20;
input ENUM_APPLIED_PRICE PriceMode = PRICE_CLOSE;

input string Comment_1 = "==========";
input bool EnableSessionFilter = false;
input ENUM_HOUR SessionStartHour = h07;
input ENUM_HOUR SessionEndHour = h19;

input string Comment_2 = "==========";
input int VolatilityPeriod = 100;
input ENUM_TIMEFRAMES VolatilityTimeframe = PERIOD_CURRENT;
input double VolatilityFactorSL = 2;
input double VolatilityFactorTP = 3;

input string Comment_a = "==========";
input ENUM_RISK_DEFAULT_SIZE PositionSizeMode = RISK_DEFAULT_FIXED;
input double FixedLotSize = 0.1;
input ENUM_RISK_BASE RiskCalculationBase = RISK_BASE_BALANCE;
input int RiskPercentage = 2;
input double MinimumLotSize = 0.01;
input double MaximumLotSize = 100;
input int MaxOpenPositions = 1;

input string Comment_b = "==========";
input ENUM_MODE_SL StopLossType = SL_FIXED;
input int FixedStopLoss = 0;
input int MinimumStopLoss = 0;
input int MaximumStopLoss = 5000;
input ENUM_MODE_TP TakeProfitType = TP_FIXED;
input int FixedTakeProfit = 0;
input int MinimumTakeProfit = 0;
input int MaximumTakeProfit = 5000;

input string Comment_c = "==========";
input bool EnableScaleOut = false;
input double ScaleOutPercent = 50;
input double VolatilityFactorSO = 1;

input string Comment_d = "==========";
input int IdentificationNumber = 0;
input string TradeComment = "";
input int SlippageTolerance = 5;
input int MaxSpreadAllowed = 50;

// Global Variables
CTrade TradeExecutor;
int VolatilityIndicatorHandle;
int SignalIndicatorHandle = -1;
double CurrentVolatility, PreviousVolatility;
double CurrentSignal, PreviousSignal;

//+-------------------------------------------------------------------+
int OnInit()
{
    if (!ValidateInputs())
    {
        return INIT_FAILED;
    }

    if (!CreateIndicatorHandles())
    {
        PrintFormat("Error initializing indicators - %s - %d", GetLastErrorText(GetLastError()), GetLastError());
        return INIT_FAILED;
    }

    ConfigureTradeSettings();

    return INIT_SUCCEEDED;
}

//+---------------------------------------------------------------------+
void OnDeinit(const int reason)
{
}

//+------------------------------------------------------------------+
void OnTick()
{
    ExecuteMainLogic();
}

//+------------------------------------------------------------------+
void OnTimer()
{
}

//+------------------------------------------------------------------------------+
void OnTrade()
{
}

//+--------------------------------------------------------------------------------+
double OnTester()
{
    double NetProfit = TesterStatistics(STAT_PROFIT);
    double InitialCapital = TesterStatistics(STAT_INITIAL_DEPOSIT);
    double MaxDrawdownPercent = TesterStatistics(STAT_EQUITYDD_PERCENT);
    double TotalTradesCount = TesterStatistics(STAT_TRADES);
    
    if (InitialCapital == 0) return 0;
    if (TotalTradesCount == 0) return -100;
    if ((TotalTradesCount > 0) && (MaxDrawdownPercent == 0)) MaxDrawdownPercent = 0.01;
    
    double ProfitPercent = NetProfit / InitialCapital * 100;

    double OptimizationScore = 0;
    if (ProfitPercent > 0) OptimizationScore = ProfitPercent / MaxDrawdownPercent;
    if (ProfitPercent < 0) OptimizationScore = ProfitPercent;

    return OptimizationScore;
}

void ExecuteMainLogic()
{
    if (!LoadIndicatorData()) return;
    
    if (GetOpenPositionsCount())
    {
        if (EnableScaleOut) ProcessScaleOut();
        EvaluateExitConditions();
    }

    static datetime last_bar_time = WRONG_VALUE;
    datetime previous_bar = last_bar_time;
    last_bar_time = iTime(Symbol(), Period(), 0);
    static int new_bar_ticks = 0;
    
    if (last_bar_time == previous_bar)
    {
        new_bar_ticks++;
        if (new_bar_ticks > 1) return;
    }
    else new_bar_ticks = 0;

    if (GetOpenPositionsCount() < MaxOpenPositions) EvaluateEntryConditions();
}

int GetOpenPositionsCount()
{
    int position_count = 0;
    int TotalPositions = PositionsTotal();
    
    for (int i = 0; i < TotalPositions; i++)
    {
        string SymbolName = PositionGetSymbol(i);
        if (SymbolName == "")
        {
            PrintFormat(__FUNCTION__, ": ERROR - Cannot select position - %s - %d.", GetLastErrorText(GetLastError()), GetLastError());
        }
        else
        {
            if (SymbolName != Symbol()) continue;
            if ((IdentificationNumber != 0) && (PositionGetInteger(POSITION_MAGIC) != IdentificationNumber)) continue;
            position_count++;
        }
    }
    return position_count;
}

bool CreateIndicatorHandles()
{
    SignalIndicatorHandle = iRSI(Symbol(), Period(), MomentumPeriod, PriceMode);
    if (SignalIndicatorHandle == INVALID_HANDLE)
    {
        PrintFormat("Cannot create signal indicator handle - %s - %d.", GetLastErrorText(GetLastError()), GetLastError());
        return false;
    }
    
    VolatilityIndicatorHandle = iATR(Symbol(), VolatilityTimeframe, VolatilityPeriod);
    if (VolatilityIndicatorHandle == INVALID_HANDLE)
    {
        PrintFormat("Cannot create volatility indicator handle - %s - %d.", GetLastErrorText(GetLastError()), GetLastError());
        return false;
    }
    return true;
}

void ConfigureTradeSettings()
{
    TradeExecutor.SetExpertMagicNumber(IdentificationNumber);
    TradeExecutor.SetDeviationInPoints(SlippageTolerance);
}

bool ExecuteLongEntry()
{
    double AskPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double BidPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double EntryPrice = AskPrice;
    double StopLossLevel = CalculateStopLoss(ORDER_TYPE_BUY, EntryPrice);
    double TakeProfitLevel = CalculateTakeProfit(ORDER_TYPE_BUY, EntryPrice);
    double PositionSize = CalculatePositionSize(StopLossLevel, EntryPrice);
    
    if (!TradeExecutor.Buy(PositionSize, Symbol(), EntryPrice, StopLossLevel, TakeProfitLevel))
    {
        PrintFormat("Failed to execute BUY: %s - %d", TradeExecutor.ResultRetcodeDescription(), TradeExecutor.ResultRetcode());
        return false;
    }
    return true;
}

bool ExecuteShortEntry()
{
    double AskPrice = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
    double BidPrice = SymbolInfoDouble(Symbol(), SYMBOL_BID);
    double EntryPrice = BidPrice;
    double StopLossLevel = CalculateStopLoss(ORDER_TYPE_SELL, EntryPrice);
    double TakeProfitLevel = CalculateTakeProfit(ORDER_TYPE_SELL, EntryPrice);
    double PositionSize = CalculatePositionSize(StopLossLevel, EntryPrice);
    
    if (!TradeExecutor.Sell(PositionSize, Symbol(), EntryPrice, StopLossLevel, TakeProfitLevel))
    {
        PrintFormat("Failed to execute SELL: %s - %d", TradeExecutor.ResultRetcodeDescription(), TradeExecutor.ResultRetcode());
        return false;
    }
    return true;
}

void CloseShortPositions()
{
    int total = PositionsTotal();

    for (int i = total - 1; i >= 0; i--)
    {
        if (PositionGetSymbol(i) == "")
        {
            PrintFormat(__FUNCTION__, ": ERROR - Cannot select position - %s - %d.", GetLastErrorText(GetLastError()), GetLastError());
            continue;
        }
        if (PositionGetString(POSITION_SYMBOL) != Symbol()) continue;
        if (PositionGetInteger(POSITION_TYPE) != POSITION_TYPE_SELL) continue;
        if (PositionGetInteger(POSITION_MAGIC) != IdentificationNumber) continue;

        for (int attempt = 0; attempt < 10; attempt++)
        {
            bool result = TradeExecutor.PositionClose(PositionGetInteger(POSITION_TICKET));
            if (!result)
            {
                PrintFormat(__FUNCTION__, ": ERROR - Cannot close position: %s - %d", TradeExecutor.ResultRetcodeDescription(), TradeExecutor.ResultRetcode());
            }
            else break;
        }
    }
}

void CloseLongPositions()
{
    int total = PositionsTotal();

    for (int i = total - 1; i >= 0; i--)
    {
        if (PositionGetSymbol(i) == "")
        {
            PrintFormat(__FUNCTION__, ": ERROR - Cannot select position - %s - %d.", GetLastErrorText(GetLastError()), GetLastError());
            continue;
        }
        if (PositionGetString(POSITION_SYMBOL) != Symbol()) continue;
        if (PositionGetInteger(POSITION_TYPE) != POSITION_TYPE_BUY) continue;
        if (PositionGetInteger(POSITION_MAGIC) != IdentificationNumber) continue;

        for (int attempt = 0; attempt < 10; attempt++)
        {
            bool result = TradeExecutor.PositionClose(PositionGetInteger(POSITION_TICKET));
            if (!result)
            {
                PrintFormat(__FUNCTION__, ": ERROR - Cannot close position: %s - %d", TradeExecutor.ResultRetcodeDescription(), TradeExecutor.ResultRetcode());
            }
            else break;
        }
    }
}

void CloseAllOpenPositions()
{
    int total = PositionsTotal();

    for (int i = total - 1; i >= 0; i--)
    {
        if (PositionGetSymbol(i) == "")
        {
            PrintFormat(__FUNCTION__, ": ERROR - Cannot select position - %s - %d.", GetLastErrorText(GetLastError()), GetLastError());
            continue;
        }
        if (PositionGetString(POSITION_SYMBOL) != Symbol()) continue;
        if (PositionGetInteger(POSITION_MAGIC) != IdentificationNumber) continue;

        for (int attempt = 0; attempt < 10; attempt++)
        {
            bool result = TradeExecutor.PositionClose(PositionGetInteger(POSITION_TICKET));
            if (!result)
            {
                PrintFormat(__FUNCTION__, ": ERROR - Cannot close position: %s - %d", TradeExecutor.ResultRetcodeDescription(), TradeExecutor.ResultRetcode());
            }
            else break;
        }
    }
}

bool ReducePositionSize(ulong ticket, double percentage)
{
    if (!PositionSelectByTicket(ticket))
    {
        PrintFormat("ERROR - Cannot select position #%d: %s - %d", ticket, GetLastErrorText(GetLastError()), GetLastError());
        return false;
    }
    
    double FullSize = PositionGetDouble(POSITION_VOLUME);
    double ReductionSize = FullSize * percentage / 100;
    double LotIncrement = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    double MaxVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double MinVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    
    ReductionSize = MathFloor(ReductionSize / LotIncrement) * LotIncrement;
    if (ReductionSize < MinVolume) return false;
    
    if (!TradeExecutor.PositionClosePartial(ticket, ReductionSize))
    {
        PrintFormat("ERROR - Cannot partially close position #%d: %s - %d", ticket, TradeExecutor.ResultRetcodeDescription(), TradeExecutor.ResultRetcode());
        return false;
    }
    return true;
}

double CalculateStopLoss(ENUM_ORDER_TYPE order_type, double entry_price)
{
    double StopLossLevel = 0;
    
    if (StopLossType == SL_FIXED)
    {
        if (FixedStopLoss == 0) return 0;
        
        if (order_type == ORDER_TYPE_BUY)
        {
            StopLossLevel = entry_price - FixedStopLoss * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
        }
        if (order_type == ORDER_TYPE_SELL)
        {
            StopLossLevel = entry_price + FixedStopLoss * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
        }
    }
    else
    {
        StopLossLevel = CalculateDynamicStopLoss(order_type, entry_price);
    }
    
    return NormalizeDouble(StopLossLevel, (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS));
}

double CalculateTakeProfit(ENUM_ORDER_TYPE order_type, double entry_price)
{
    double TakeProfitLevel = 0;
    
    if (TakeProfitType == TP_FIXED)
    {
        if (FixedTakeProfit == 0) return 0;
        
        if (order_type == ORDER_TYPE_BUY)
        {
            TakeProfitLevel = entry_price + FixedTakeProfit * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
        }
        if (order_type == ORDER_TYPE_SELL)
        {
            TakeProfitLevel = entry_price - FixedTakeProfit * SymbolInfoDouble(Symbol(), SYMBOL_POINT);
        }
    }
    else
    {
        TakeProfitLevel = CalculateDynamicTakeProfit(order_type, entry_price);
    }
    
    return NormalizeDouble(TakeProfitLevel, (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS));
}

double CalculatePositionSize(double stop_loss_price, double entry_price)
{
    double VolumeSize = FixedLotSize;
    
    if (PositionSizeMode == RISK_DEFAULT_AUTO)
    {
        if (stop_loss_price != 0)
        {
            double RiskBaseValue = 0;
            double TickValueAmount = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
            
            if (RiskCalculationBase == RISK_BASE_BALANCE) RiskBaseValue = AccountBalance();
            else if (RiskCalculationBase == RISK_BASE_EQUITY) RiskBaseValue = AccountEquity();
            else if (RiskCalculationBase == RISK_BASE_FREEMARGIN) RiskBaseValue = AccountFreeMargin();
            
            double StopLossPoints = MathAbs(entry_price - stop_loss_price) / SymbolInfoDouble(Symbol(), SYMBOL_POINT);
            VolumeSize = (RiskBaseValue * RiskPercentage / 100) / (StopLossPoints * TickValueAmount);
        }
        
        if (stop_loss_price == 0)
        {
            VolumeSize = FixedLotSize;
        }
    }
    
    double LotIncrement = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_STEP);
    double MaxVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MAX);
    double MinVolume = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    
    VolumeSize = MathFloor(VolumeSize / LotIncrement) * LotIncrement;
    
    if (VolumeSize > MaximumLotSize) VolumeSize = MaximumLotSize;
    if (VolumeSize > MaxVolume) VolumeSize = MaxVolume;
    if ((VolumeSize < MinimumLotSize) || (VolumeSize < MinVolume)) VolumeSize = 0;
    
    return VolumeSize;
}

bool ValidateInputs()
{
    if (MaximumLotSize < MinimumLotSize)
    {
        Print("MaximumLotSize cannot be less than MinimumLotSize");
        return false;
    }
    return true;
}

bool LoadIndicatorData()
{
    double data_buffer[2];
    int values_copied;
    bool DataComplete = false;
    int MaxDataAttempts = 5;
    int AttemptDelay = 200;
    int CurrentAttempt = 0;

    while ((!DataComplete) && (CurrentAttempt < MaxDataAttempts))
    {
        DataComplete = true;

        values_copied = CopyBuffer(VolatilityIndicatorHandle, 0, 0, 2, data_buffer);
        if ((values_copied < 2) || (data_buffer[0] == NULL) || (data_buffer[0] == EMPTY_VALUE))
        {
            Print("Cannot retrieve volatility indicator values.");
            DataComplete = false;
        }
        else
        {
            CurrentVolatility = data_buffer[1];
            PreviousVolatility = data_buffer[0];
        }
        
        values_copied = CopyBuffer(SignalIndicatorHandle, 0, 1, 2, data_buffer);
        if (values_copied < 2)
        {
            Print("Signal indicator buffer not ready.");
            DataComplete = false;
        }
        else
        {
            CurrentSignal = data_buffer[1];
            PreviousSignal = data_buffer[0];
        }

        CurrentAttempt++;
        Sleep(AttemptDelay);
    }

    if (!DataComplete)
    {
        Print("Cannot retrieve all indicator data, skipping bar.");
        return false;
    }

    return true;
}

void EvaluateEntryConditions()
{
    if ((EnableSessionFilter) && (!IsCurrentTimeInInterval(SessionStartHour, SessionEndHour))) return;

    bool LongEntrySignal = false;
    bool ShortEntrySignal = false;

    if ((CurrentSignal > LowerThreshold) && (PreviousSignal <= LowerThreshold)) LongEntrySignal = true;

    if (LongEntrySignal)
    {
        ExecuteLongEntry();
    }

    if ((CurrentSignal < UpperThreshold) && (PreviousSignal >= UpperThreshold)) ShortEntrySignal = true;

    if (ShortEntrySignal)
    {
        ExecuteShortEntry();
    }
}

void EvaluateExitConditions()
{
    bool ExitLongSignal = false;
    bool ExitShortSignal = false;

    if ((CurrentSignal > LowerThreshold) && (PreviousSignal <= LowerThreshold)) ExitShortSignal = true;
    else if ((CurrentSignal < UpperThreshold) && (PreviousSignal >= UpperThreshold)) ExitLongSignal = true;

    if (ExitLongSignal) CloseLongPositions();
    if (ExitShortSignal) CloseShortPositions();
}

double CalculateDynamicStopLoss(ENUM_ORDER_TYPE type, double entry_price)
{
    double StopLossLevel = 0;
    
    if (type == ORDER_TYPE_BUY)
    {
        StopLossLevel = entry_price - PreviousVolatility * VolatilityFactorSL;
    }
    else if (type == ORDER_TYPE_SELL)
    {
        StopLossLevel = entry_price + PreviousVolatility * VolatilityFactorSL;
    }
    
    return NormalizeDouble(StopLossLevel, (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS));
}

double CalculateDynamicTakeProfit(ENUM_ORDER_TYPE type, double entry_price)
{
    double TakeProfitLevel = 0;
    
    if (type == ORDER_TYPE_BUY)
    {
        TakeProfitLevel = entry_price + PreviousVolatility * VolatilityFactorTP;
    }
    else if (type == ORDER_TYPE_SELL)
    {
        TakeProfitLevel = entry_price - PreviousVolatility * VolatilityFactorTP;
    }
    
    return NormalizeDouble(TakeProfitLevel, (int)SymbolInfoInteger(Symbol(), SYMBOL_DIGITS));
}

void ProcessScaleOut()
{
    int total = PositionsTotal();

    for (int i = total - 1; i >= 0; i--)
    {
        if (PositionGetSymbol(i) == "")
        {
            Print(__FUNCTION__, ": ERROR - Cannot select position - ", GetLastError());
            continue;
        }
        if (PositionGetString(POSITION_SYMBOL) != Symbol()) continue;
        if (PositionGetInteger(POSITION_MAGIC) != IdentificationNumber) continue;

        int position_id = (int)PositionGetInteger(POSITION_TICKET);

        if (!HistorySelectByPosition(PositionGetInteger(POSITION_IDENTIFIER)))
        {
            PrintFormat("ERROR - Cannot get position history for %d - %s - %d", position_id, GetLastErrorText(GetLastError()), GetLastError());
            continue;
        }

        bool requires_scale_out = true;

        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
        {
            for (int j = HistoryDealsTotal() - 1; j >= 0; j--)
            {
                long deal_id = (int)HistoryDealGetTicket(j);
                if (!deal_id)
                {
                    PrintFormat("Cannot get deal for %d - %s - %d", position_id, GetLastErrorText(GetLastError()), GetLastError());
                    break;
                }
                if (HistoryDealGetInteger(deal_id, DEAL_TYPE) == DEAL_TYPE_SELL)
                {
                    requires_scale_out = false;
                    break;
                }
            }
            
            if ((requires_scale_out) && (SymbolInfoDouble(Symbol(), SYMBOL_BID) - PositionGetDouble(POSITION_PRICE_OPEN) > PreviousVolatility * VolatilityFactorSO))
            {
                ReducePositionSize(position_id, ScaleOutPercent);
            }
        }
        else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
        {
            for (int j = HistoryDealsTotal() - 1; j >= 0; j--)
            {
                long deal_id = (int)HistoryDealGetTicket(j);
                if (!deal_id)
                {
                    PrintFormat("Cannot get deal for %d - %s - %d", position_id, GetLastErrorText(GetLastError()), GetLastError());
                    return;
                }
                if (HistoryDealGetInteger(deal_id, DEAL_TYPE) == DEAL_TYPE_BUY)
                {
                    requires_scale_out = false;
                    break;
                }
            }
            
            if ((requires_scale_out) && (PositionGetDouble(POSITION_PRICE_OPEN) - SymbolInfoDouble(Symbol(), SYMBOL_ASK) > PreviousVolatility * VolatilityFactorSO))
            {
                ReducePositionSize(position_id, ScaleOutPercent);
            }
            return;
        }
    }
}
//+------------------------------------------------------------------+
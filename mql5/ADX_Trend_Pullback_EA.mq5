//+------------------------------------------------------------------+
//|                                            ADX Trend Pullback EA |
//|                                         Copyright 2026, DVN CORE |
//|                         https://www.mql5.com/en/users/wazatrader |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, DVN CORE"
#property link      "https://www.mql5.com/en/users/wazatrader"
#property version   "1.00"
#property description "ADX trend filter with EMA pullback entry and ATR-based SL/TP."
#property strict

enum ENUM_TRADE_DIR {
    TRADE_BOTH = 0,  // Buy and Sell (default)
    TRADE_BUY  = 1,  // Buy only
    TRADE_SELL = 2   // Sell only
};


input group "=== General ==="
input ENUM_TRADE_DIR InpTradeDirection  = TRADE_BOTH;  // Trade direction: BOTH / BUY only / SELL only
input int            InpMagicNumber     = 270601;      // Magic Number

input group "=== Lot Sizing ==="
input double InpLotSize              = 0.01;     // Fixed lot size

input group "=== Stop Loss / Take Profit (ATR-based) ==="
input double InpATR_SL_Multiplier    = 1.5;      // SL = ATR(14)[1] * this multiplier
input double InpRR_Ratio             = 2.0;      // TP = SL distance * this ratio

input group "=== Entry Settings ==="
input ENUM_TIMEFRAMES InpIndicatorTF = PERIOD_H1; // Primary timeframe for all indicators
input int    InpADXPeriod            = 14;        // ADX period
input int    InpEMAPeriod            = 20;        // EMA period (applied to Close)
input int    InpATRPeriod            = 14;        // ATR period
input double InpADXThreshold         = 25.0;      // ADX must be above this to allow entry
input double InpPullbackATRRatio     = 0.5;       // Pullback threshold = ATR * this ratio

int g_handleADX = INVALID_HANDLE;
int g_handleEMA = INVALID_HANDLE;
int g_handleATR = INVALID_HANDLE;

int CountOpenPositions() {
    int count = 0;
    for(int i = PositionsTotal() - 1; i >= 0; i--) {
        ulong ticket = PositionGetTicket(i);
        if(!PositionSelectByTicket(ticket)) continue;
        if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
        count++;
    }
    return count;
}

int OnInit() {
    g_handleADX = iADX(_Symbol, InpIndicatorTF, InpADXPeriod);
    g_handleEMA = iMA(_Symbol,  InpIndicatorTF, InpEMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
    g_handleATR = iATR(_Symbol, InpIndicatorTF, InpATRPeriod);

    if(g_handleADX == INVALID_HANDLE || g_handleEMA == INVALID_HANDLE ||
       g_handleATR == INVALID_HANDLE) {
        Print("Indicator handle creation failed");
        return INIT_FAILED;
    }

    return INIT_SUCCEEDED;
}

void OnDeinit(const int reason) {
    if(g_handleADX != INVALID_HANDLE) IndicatorRelease(g_handleADX);
    if(g_handleEMA != INVALID_HANDLE) IndicatorRelease(g_handleEMA);
    if(g_handleATR != INVALID_HANDLE) IndicatorRelease(g_handleATR);
}

bool IsNewBar(ENUM_TIMEFRAMES tf = PERIOD_CURRENT) {
    static datetime s_lastBarTime = 0;
    datetime currentBarTime = (datetime)SeriesInfoInteger(_Symbol, tf, SERIES_LASTBAR_DATE);
    if(currentBarTime == s_lastBarTime) return false;
    s_lastBarTime = currentBarTime;
    return true;
}

bool ComputeSignal(int &signal, double &atrValue) {
    signal   = 0;
    atrValue = 0.0;

    // ADX main, +DI, -DI — need bars [1] and [2]
    double adxMain[], diPlus[], diMinus[];
    ArraySetAsSeries(adxMain, true);
    ArraySetAsSeries(diPlus,  true);
    ArraySetAsSeries(diMinus, true);
    if(CopyBuffer(g_handleADX, 0, 1, 2, adxMain) <= 0) return false; // MAIN line
    if(CopyBuffer(g_handleADX, 1, 1, 1, diPlus)  <= 0) return false; // +DI
    if(CopyBuffer(g_handleADX, 2, 1, 1, diMinus) <= 0) return false; // -DI

    // EMA20 — need bars [1] and [2]
    double emaBuf[];
    ArraySetAsSeries(emaBuf, true);
    if(CopyBuffer(g_handleEMA, 0, 1, 2, emaBuf) <= 0) return false;

    // ATR — need bars [1] and [2]
    double atrBuf[];
    ArraySetAsSeries(atrBuf, true);
    if(CopyBuffer(g_handleATR, 0, 1, 2, atrBuf) <= 0) return false;

    // Close prices — bars [1] and [2]
    double close1 = iClose(_Symbol, InpIndicatorTF, 1);
    double close2 = iClose(_Symbol, InpIndicatorTF, 2);
    if(close1 <= 0 || close2 <= 0) return false;

    double adx1 = adxMain[0]; // bar[1]
    double adx2 = adxMain[1]; // bar[2]
    double ema1 = emaBuf[0];  // bar[1]
    double ema2 = emaBuf[1];  // bar[2]
    double atr1 = atrBuf[0];  // bar[1]
    double atr2 = atrBuf[1];  // bar[2]

    if(atr1 <= 0 || atr2 <= 0) return false;

    // Filter: ADX[1] > threshold AND ADX[1] > ADX[2]
    bool adxFilter = (adx1 > InpADXThreshold) && (adx1 > adx2);
    if(!adxFilter) { atrValue = atr1; return true; }

    // Pullback event: just touched EMA on bar[2], now away on bar[1]
    double dist1 = MathAbs(close1 - ema1) / atr1;
    double dist2 = MathAbs(close2 - ema2) / atr2;
    bool pullbackEvent = (dist1 < InpPullbackATRRatio) && (dist2 >= InpPullbackATRRatio);
    if(!pullbackEvent) { atrValue = atr1; return true; }

    // Direction via DI
    if(diPlus[0] > diMinus[0]) {
        signal = 1;  // BUY
    } else if(diMinus[0] > diPlus[0]) {
        signal = -1; // SELL
    }

    atrValue = atr1;
    return true;
}

//+------------------------------------------------------------------+
//| Get a filling mode supported by the broker for this symbol       |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetFillingMode(const string symbol) {
    int filling = (int)SymbolInfoInteger(symbol, SYMBOL_FILLING_MODE);

    if((filling & SYMBOL_FILLING_FOK) != 0)
        return ORDER_FILLING_FOK;
    if((filling & SYMBOL_FILLING_IOC) != 0)
        return ORDER_FILLING_IOC;

    return ORDER_FILLING_RETURN;
}

//+------------------------------------------------------------------+
//| Normalize lot size to broker's min/max/step constraints          |
//+------------------------------------------------------------------+
double NormalizeLot(const string symbol, double lot) {
    double minLot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
    double maxLot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
    double stepLot = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);

    if(stepLot <= 0) stepLot = minLot;
    if(stepLot <= 0) stepLot = 0.01;

    lot = MathRound(lot / stepLot) * stepLot;

    if(lot < minLot) lot = minLot;
    if(maxLot > 0 && lot > maxLot) lot = maxLot;

    int stepDigits = 2;
    if(stepLot >= 1.0)        stepDigits = 0;
    else if(stepLot >= 0.1)   stepDigits = 1;
    else if(stepLot >= 0.01)  stepDigits = 2;
    else                      stepDigits = 3;

    return NormalizeDouble(lot, stepDigits);
}

//+------------------------------------------------------------------+
//| Check there is enough free margin for this trade before sending   |
//| (avoids "not enough money" rejections from the trade server,      |
//| which is what triggers the validation Test-step errors)           |
//+------------------------------------------------------------------+
bool HasEnoughMargin(const string symbol, ENUM_ORDER_TYPE type, double volume, double price) {
    double marginRequired = 0.0;
    if(!OrderCalcMargin(type, symbol, volume, price, marginRequired)) {
        // If margin cannot be calculated, be conservative and skip the trade
        return false;
    }

    double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

    return marginRequired <= freeMargin;
}

//+------------------------------------------------------------------+
//| Check market is open and tick is fresh before sending orders      |
//+------------------------------------------------------------------+
bool IsMarketOpen() {
    if((ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE) == SYMBOL_TRADE_MODE_DISABLED) return false;

    MqlTick tick;
    if(!SymbolInfoTick(_Symbol, tick)) return false;
    if(tick.bid <= 0 || tick.ask <= 0) return false;
    datetime now = TimeTradeServer();
    MqlDateTime dt;
    TimeToStruct(now, dt);
    ENUM_DAY_OF_WEEK dow = (ENUM_DAY_OF_WEEK)dt.day_of_week;
    datetime dayStart = now - (dt.hour * 3600 + dt.min * 60 + dt.sec);

    bool inSession = false;
    for(int i = 0; i < 7; i++) {
        datetime from, to;
        if(!SymbolInfoSessionTrade(_Symbol, dow, (uint)i, from, to)) break;
        if(now >= dayStart + from && now < dayStart + to) {
            inSession = true;
            break;
        }
    }
    if(!inSession) return false;

    return true;
}

void OnTick() {
    // Recalculate signals only on new bar
    if(!IsNewBar(InpIndicatorTF)) return;

    // Skip if market is closed (avoids "Market closed" rejection on order send)
    if(!IsMarketOpen()) return;

    int    signal   = 0;
    double atrValue = 0.0;
    if(!ComputeSignal(signal, atrValue)) return;
    if(signal == 0 || atrValue <= 0) return;

    // Only one position at a time
    if(CountOpenPositions() != 0) return;

    double slDistance = atrValue * InpATR_SL_Multiplier;
    double tpDistance = slDistance * InpRR_Ratio;

    MqlTradeRequest request = {};
    MqlTradeResult  result  = {};
    ENUM_ORDER_TYPE_FILLING fillingMode = GetFillingMode(_Symbol);

    if(signal == 1 && InpTradeDirection != TRADE_SELL) {
        double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
        double sl    = NormalizeDouble(price - slDistance, _Digits);
        double tp    = NormalizeDouble(price + tpDistance, _Digits);
        double volume = NormalizeLot(_Symbol, InpLotSize);

        // Skip the trade instead of letting the server reject it with
        // "not enough money" (avoids validation Test-step errors)
        if(!HasEnoughMargin(_Symbol, ORDER_TYPE_BUY, volume, price)) return;

        request.action       = TRADE_ACTION_DEAL;
        request.symbol       = _Symbol;
        request.volume       = volume;
        request.type         = ORDER_TYPE_BUY;
        request.price        = price;
        request.sl           = sl;
        request.tp           = tp;
        request.deviation    = 10;
        request.magic        = InpMagicNumber;
        request.type_filling = fillingMode;
        request.comment      = "ADX_EMA_Pullback_BUY";

        if(!OrderSend(request, result))
            Print("Order failed, retcode: ", result.retcode);
    }
    else if(signal == -1 && InpTradeDirection != TRADE_BUY) {
        double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
        double sl    = NormalizeDouble(price + slDistance, _Digits);
        double tp    = NormalizeDouble(price - tpDistance, _Digits);
        double volume = NormalizeLot(_Symbol, InpLotSize);

        // Skip the trade instead of letting the server reject it with
        // "not enough money" (avoids validation Test-step errors)
        if(!HasEnoughMargin(_Symbol, ORDER_TYPE_SELL, volume, price)) return;

        request.action       = TRADE_ACTION_DEAL;
        request.symbol       = _Symbol;
        request.volume       = volume;
        request.type         = ORDER_TYPE_SELL;
        request.price        = price;
        request.sl           = sl;
        request.tp           = tp;
        request.deviation    = 10;
        request.magic        = InpMagicNumber;
        request.type_filling = fillingMode;
        request.comment      = "ADX_EMA_Pullback_SELL";

        if(!OrderSend(request, result))
            Print("Order failed, retcode: ", result.retcode);
    }
}
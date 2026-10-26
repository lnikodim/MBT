//+------------------------------------------------------------------+
//|                                       001-Turnaround-Tuesday.mq5 |
//|                        Copyright 2026, Sergei Ermolov (mql5.com) |
//|                        https://www.mql5.com/en/users/dj_ermoloff |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Sergei Ermolov | IT Trader"
#property link      "https://www.mql5.com/en/users/dj_ermoloff"
#property version   "1.1"

#include <Trade\Trade.mqh>
CTrade trade;

enum ENUM_LOT_TYPE {
   LOT_FIXED = 0, //Fixed Lot
   LOT_RISK  = 1  //% Risk from Start Balance
};

enum ENUM_ED {
   disabled = 0, //Disabled
   enabled  = 1  //Enabled
};

input ENUM_LOT_TYPE LotType        = LOT_RISK; //Lot Type
input double        Lots           = 0.1;      //Lot Size
input double        Risk           = 2;        //Risk per Transaction
input group "=== ATR Filter"
input ENUM_ED       FilterATR      = disabled; //ATR Filter
input int           DailyATRPeriod = 14;       //Daily ATR Period
input double        MinCheckDayATR = 1.5;      //Minimal ATR
input group "=== Position Settings"
input double        kDailyATR      = 0.5;      //StopLoss kf Daily ATR
input double        rrTP           = 2.5;      //TakeProfit (Risk\Reward)
input group "=== Close Position"
input int           CloseHour      = 22;       //Position Close Hour
input group "================="
input int           MagicNumber    = 1;

// Monday = check day, Reverse = trade against Monday's direction
const ENUM_DAY_OF_WEEK CHECK_DAY = MONDAY;

double      balance;
MqlDateTime mtc;
datetime    tc, lastBarTime = 0;
int         atrHandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
   balance = AccountInfoDouble(ACCOUNT_BALANCE);
   
   if (iBars(_Symbol, PERIOD_D1) < DailyATRPeriod + 5) {
      Print("OnInit: not enough history for ", _Symbol, 
            " — load at least ", DailyATRPeriod + 5, " daily bars and restart");
      return INIT_FAILED;
   }
   
   atrHandle = iATR(_Symbol, PERIOD_D1, DailyATRPeriod);
   if (atrHandle == INVALID_HANDLE) {
      Print("OnInit: failed to create ATR handle for ", _Symbol);
      return INIT_FAILED;
   }
   
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
   tc = TimeCurrent(mtc);
   if (mtc.hour >= CloseHour) CloseAllPositions();

   // Run only on new daily bar
   datetime currentBarTime = tc - tc % 86400;
   if (currentBarTime == lastBarTime) return;

   // Check if yesterday was Monday
   MqlDateTime dt;
   TimeToStruct(iTime(_Symbol, PERIOD_H1, 1), dt);
   ENUM_DAY_OF_WEEK closedDay = (ENUM_DAY_OF_WEEK)dt.day_of_week;

   if (closedDay != CHECK_DAY) {
      lastBarTime = currentBarTime;
      return;
   }

   if (PositionsTotal() > 0) return;

   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if (CopyBuffer(atrHandle, 0, 1, 1, atrBuf) <= 0) {
      Print("OnTick: failed to get ATR");
      return;
   }
   double atr = atrBuf[0];

   // Get Monday candle
   double highDay, lowDay, openDay, closeDay;
   if (!GetCheckDayData(highDay, lowDay, openDay, closeDay)) return;

   // ATR filter
   if (FilterATR == enabled) {
      double candleSize = highDay - lowDay;
      if (candleSize < MinCheckDayATR * atr) {
         Print("OnTick: ATR filter — candle too small, skip");
         lastBarTime = currentBarTime;
         return;
      }
   }

   // Trade against Monday's direction
   bool isBullish = closeDay > openDay;
   bool tradeUp   = !isBullish;

   // Calculate SL in price and points
   double ask        = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid        = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point      = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double slDistance = atr * kDailyATR;
   int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minStop = MathMax(stopsLevel, 2) * _Point;
   if (slDistance < minStop) slDistance = minStop;
   double slPoints   = slDistance / point;

   // Calculate lot
   double lots;
   if (LotType == LOT_FIXED) lots = Lots;
      else lots = CalcLot(Risk, slPoints);
   
   if (lots <= 0) {
      Print("OnTick: lot size is 0, not enough margin or invalid SL — skipping.");
      lastBarTime = currentBarTime;
      return;
   }

   // Open trade
   if (tradeUp) {
      double sl = ask - slDistance;
      double tp = rrTP > 0 ? ask + slDistance * rrTP : 0;
      if (kDailyATR == 0) { sl = 0; tp = 0; }      
      if (OpenBuy(lots, sl, tp, MagicNumber, "Revers_Tuesday")) lastBarTime = currentBarTime;
   } else {
      double sl = bid + slDistance;
      double tp = rrTP > 0 ? bid - slDistance * rrTP : 0;
      if (kDailyATR == 0) { sl = 0; tp = 0; }
      if (OpenSell(lots, sl, tp, MagicNumber, "Revers_Tuesday")) lastBarTime = currentBarTime;
   }
}

//+------------------------------------------------------------------+
//| Open a Buy trade                                                 |
//+------------------------------------------------------------------+
bool OpenBuy(double lots, double sl = 0, double tp = 0, ulong magic = 0, string comment = "") {
   trade.SetExpertMagicNumber(magic);
   trade.SetDeviationInPoints(10);
   
   if (!CheckMargin(lots, ORDER_TYPE_BUY)) return false;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if (ask <= 0) {
      Print("OpenBuy: failed to get Ask price for ", _Symbol);
      return false;
   }

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if (sl > 0) sl = NormalizeDouble(sl, digits);
   if (tp > 0) tp = NormalizeDouble(tp, digits);

   bool result = trade.Buy(lots, _Symbol, ask, sl > 0 ? sl : 0, tp > 0 ? tp : 0, comment);
   if (!result)
      Print("OpenBuy: failed to open — ", trade.ResultRetcodeDescription());

   return result;
}

//+------------------------------------------------------------------+
//| Open a Sell trade                                                |
//+------------------------------------------------------------------+
bool OpenSell(double lots, double sl = 0, double tp = 0, ulong magic = 0, string comment = "") {
   trade.SetExpertMagicNumber(magic);
   trade.SetDeviationInPoints(10);
   
   if (!CheckMargin(lots, ORDER_TYPE_SELL)) return false;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if (bid <= 0) {
      Print("OpenSell: failed to get Bid price for ", _Symbol);
      return false;
   }

   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if (sl > 0) sl = NormalizeDouble(sl, digits);
   if (tp > 0) tp = NormalizeDouble(tp, digits);

   bool result = trade.Sell(lots, _Symbol, bid, sl > 0 ? sl : 0, tp > 0 ? tp : 0, comment);
   if (!result)
      Print("OpenSell: failed to open — ", trade.ResultRetcodeDescription());

   return result;
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                      |
//+------------------------------------------------------------------+
double CalcLot(double riskPct, double slPoints) {
   double riskAmount = balance * riskPct / 100.0;
   double tickSize   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tickValue  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double lotStep    = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot     = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot     = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   if (tickSize <= 0 || tickValue <= 0 || slPoints <= 0) {
      Print("CalcLot: invalid symbol specs or SL = 0");
      return 0;
   }

   double pointValue = (tickValue / tickSize) * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double lots       = riskAmount / (slPoints * pointValue);
   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));

   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Close all positions for current symbol and magic number          |
//+------------------------------------------------------------------+
void CloseAllPositions() {
   for (int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if (ticket == 0) continue;
      if (MagicNumber != 0 && PositionGetInteger(POSITION_MAGIC) != (long)MagicNumber) continue;
      if (PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      if (!trade.PositionClose(ticket))
         Print("CloseAllPositions: failed to close #", ticket, " — ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
// Check if there is enough margin to open a trade
// lots     - lot size
// type     - ORDER_TYPE_BUY or ORDER_TYPE_SELL
//+------------------------------------------------------------------+
bool CheckMargin(double lots, ENUM_ORDER_TYPE type) {
   double margin = 0;
   if (!OrderCalcMargin(type, _Symbol, lots, SymbolInfoDouble(_Symbol, type == ORDER_TYPE_BUY ? SYMBOL_ASK : SYMBOL_BID), margin)) {
      Print("CheckMargin: failed to calculate margin");
      return false;
   }
   if (margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE)) {
      Print("CheckMargin: not enough margin — required=", margin, " free=", AccountInfoDouble(ACCOUNT_MARGIN_FREE));
      return false;
   }
   return true;
}

// Find all H1 candles of CheckDay and get high/low/open/close
bool GetCheckDayData(double &highDay, double &lowDay, double &openDay, double &closeDay) {
   highDay  = -1;
   lowDay   = DBL_MAX;
   openDay  = -1;
   closeDay = -1;

   MqlDateTime dtCurrent;
   TimeToStruct(iTime(_Symbol, PERIOD_H1, 0), dtCurrent);
   int currentHour = dtCurrent.hour;

   // Find next candle with same hour in history — that's our boundary
   int boundaryIdx = -1;
   for (int i = 1; i <= 50; i++) {
      MqlDateTime dtBar;
      TimeToStruct(iTime(_Symbol, PERIOD_H1, i), dtBar);
      if (dtBar.hour == currentHour) {
         boundaryIdx = i;
         break;
      }
   }

   if (boundaryIdx == -1) {
      Print("GetCheckDayData: boundary candle not found in last 50 bars");
      return false;
   }

   // Collect high/low between i=1 and boundary
   closeDay = iClose(_Symbol, PERIOD_H1, 1);

   for (int i = 1; i < boundaryIdx; i++) {
      double barHigh = iHigh(_Symbol, PERIOD_H1, i);
      double barLow  = iLow(_Symbol, PERIOD_H1, i);

      if (barHigh > highDay) highDay = barHigh;
      if (barLow  < lowDay)  lowDay  = barLow;

      openDay = iOpen(_Symbol, PERIOD_H1, i);
   }

   return true;
}
//+------------------------------------------------------------------+
#property copyright "© 2026, ChukwuBuikem"
#property link      "https://www.mql5.com/en/users/bikeen"
#define  _VERSION   "1.50"
#property  version _VERSION
#define _VolumeMin SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN)
#define PROG_NAME "Dominance EA"

#include <trade/trade.mqh>

enum ENUM_EA_MODE {
   MODE_NORMAL = 0, //Normal Mode
   MODE_INVERTED = 1 //Inverted Mode
};
//---+
enum ENUM_BIAS {
   BIAS_NEUTRAL = 0,
   BIAS_BUY = 1,
   BIAS_SELL = 2
};
//---+
struct st_Chart {
private:
   bool isSeparator;
public:
   st_Chart() {
      isSeparator = (bool)ChartGetInteger(0, CHART_SHOW_PERIOD_SEP, 0);
   }
   //---+
   void setSeparator() {
      ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, true);
      ChartRedraw();
   }
   //---+
   void restore() {
      ChartSetInteger(0, CHART_SHOW_PERIOD_SEP, isSeparator);
      ChartRedraw();
   }
} chart;
//---+
struct st_PMA {
//---
private:
   double high;
   double low;
   double close;
   double maValue, atrValue;
public:
//---+
   void fill(const double priceHigh, const double priceLow,
             const double priceClose, const double ma, const double atr) {
      high = NormalizeDouble(priceHigh, _Digits);
      low = NormalizeDouble(priceLow, _Digits);
      close = NormalizeDouble(priceClose, _Digits);
      maValue = NormalizeDouble(ma, _Digits);
      atrValue = NormalizeDouble(atr, _Digits);
   }
   //---+
   double getHigh() {
      return high;
   }
   //---+
   double getLow() {
      return low;
   }
   //---+
   double getClose() {
      return close;
   }
   //---+
   double getMaValue() {
      return maValue;
   }
   //---+
   double getAtrValue() {
      return atrValue;
   }
} barData;

input group "==+ EA Model Settings +=="
input ENUM_EA_MODE eaMode = MODE_NORMAL;//EA Mode
input int maPeriod = 14; //MA period
input ENUM_MA_METHOD maMethod = MODE_SMA; //MA method
input ENUM_APPLIED_PRICE maAppPrice = PRICE_CLOSE; //Ma applied price
input group "+== Trade Management Settings ==+"
input ENUM_ORDER_TYPE_FILLING ordFillType = ORDER_FILLING_FOK;// Order filling mode
input long eaMagic = 2026;// Unique EA identifier
input string tradeComment = PROG_NAME;//Trade comment
input group "==+ SL Settings +=="
input int atrPeriod = 14;//ATR period
input double atrMultiplier = 2.5; //

CTrade trade;
CPositionInfo pos;
int handleMa = -1, handleATR = -1;
int barsNeeded = -1;
ENUM_BIAS myBias;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   barsNeeded = 86400 / PeriodSeconds();
   //-Create ATR indicator
   if((handleATR = iATR(_Symbol, PERIOD_CURRENT, atrPeriod)) == INVALID_HANDLE) {
      Print("Failed to create ATR indicator handle. Deinitializing");
      return INIT_FAILED;
   }
   //-Create ATR indicator
   if((handleMa = iMA(_Symbol, PERIOD_CURRENT, maPeriod, 0, maMethod, maAppPrice)) == INVALID_HANDLE) {
      Print("Failed to create MA indicator handle. Deinitializing");
      return INIT_FAILED;
   }
   //-Validate inputs
   if(atrPeriod < 0 || atrMultiplier < 0) {
      Print("Invalid ATR inputs. Deinitializing");
      return INIT_FAILED;
   }
   if(maPeriod < 0) {
      Print("Invalid MA inputs. Deinitializing");
      return INIT_FAILED;
   }
   chart.setSeparator();
   trade.SetExpertMagicNumber(eaMagic);
   trade.SetTypeFilling(ordFillType);
   printf("[INIT] '%s' v%s Initialized successfully.", PROG_NAME, _VERSION);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   if(handleATR != INVALID_HANDLE)IndicatorRelease(handleATR);
   if(handleMa != INVALID_HANDLE)IndicatorRelease(handleMa);
   chart.restore();
}
//+------------------------------------------------------------------+
//| Expert tick function                                   |
//+------------------------------------------------------------------+
void OnTick() {
//---
   if(isNewDay()) {
   //-Once per day
      int bull = 0, bear = 0;
      if(countYesterdayBars(PERIOD_CURRENT, bull, bear, barData)) {
      //-Get today bias
         myBias = getTodayBias(barData);
         if(myBias == BIAS_BUY && !isTradeOpen(eaMagic)) {
            //-Buy
            executeBuy(barData);
            return;
         } else if(myBias == BIAS_SELL && !isTradeOpen(eaMagic)) {
            //-Sell
            executeSell(barData);
            return;
         }
      }
   }
}
//==============================
// Function to detect a new day
//==============================
bool isNewDay() {
//---
   static datetime lastDay = 0;
   datetime newDay = iTime(_Symbol, PERIOD_D1, 0);

   if(lastDay != newDay) {
      lastDay = newDay;
      MqlDateTime time;
      TimeToStruct(newDay, time);
      //-Avoid monday trades
      if((ENUM_DAY_OF_WEEK)time.day_of_week == MONDAY)return false;
      return true;
   }
   return false;
}
//==============================
// Function to detect if there's an open position
//==============================
bool isTradeOpen(long magicN) {
//---
   for(int w = 0; w < PositionsTotal(); w++) {
      if(pos.SelectByIndex(w)) {
         if(pos.Symbol() == _Symbol && pos.Magic() == magicN)return true;
      }
   }
   return false;
}
//==============================
// Function to detect a bullish bar
//==============================
bool isBullish(const MqlRates & bar) {
//---
   return bar.close > bar.open;
}
//==============================
// Function to detect a bearish bar
//==============================
bool isBearish(const MqlRates & bar) {
//---
   return bar.close < bar.open;
}
//==============================
// Function to get the ATR value of a bar with the specified open time
//==============================
double getBarATR(const datetime barTime) {
//---
   double atr[1];
   if(CopyBuffer(handleATR, 0, barTime, 1, atr) == 1)return NormalizeDouble(atr[0], _Digits);
   return EMPTY_VALUE;
}
//==============================
// Function to get the MA value of a bar with the specified open time
//==============================
double getBarMa(const datetime barTime) {
//---
   double ma[1];
   if(CopyBuffer(handleMa, 0, barTime, 1, ma) == 1)return NormalizeDouble(ma[0], _Digits);
   return -1;
}
//==============================
// Function to get the count of bullish and bearish bars formed the previous day
//==============================
bool countYesterdayBars(ENUM_TIMEFRAMES tf, int &bullish,
                        int &bearish, st_PMA & strct) {
//---
   datetime dayStart = iTime(_Symbol, PERIOD_D1, 1);
   datetime dayEnd = dayStart + (86400 - 10);
   bullish = 0;
   bearish = 0;
//-Get the bar indexes of the dayStart and dayEnd time valuess
   int startShift = iBarShift(_Symbol, PERIOD_CURRENT, dayStart, false);
   int endShift   = iBarShift(_Symbol, PERIOD_CURRENT, dayEnd,   false);
   if(startShift < 0 || endShift < 0)
      return false;
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, PERIOD_CURRENT,
                          iTime(_Symbol, PERIOD_CURRENT, startShift),
                          iTime(_Symbol, PERIOD_CURRENT, endShift), rates);

   if((CopyRates(_Symbol, PERIOD_CURRENT,
                 iTime(_Symbol, PERIOD_CURRENT, startShift),
                 iTime(_Symbol, PERIOD_CURRENT, endShift), rates)) < barsNeeded)
      return false;

   for(int w = 0; w < copied; w++) {
      if(isBullish(rates[w])) bullish++;
      if(isBearish(rates[w])) bearish++;
   }
   //-Get the ATR and MA values of the last bar to form the previous day
   double atrX = getBarATR(rates[0].time);
   double maX = getBarMa(rates[0].time);
   if(atrX == EMPTY_VALUE || maX == EMPTY_VALUE)return false;
   //-Fill the structure
   strct.fill(rates[0].high, rates[0].low,
              rates[0].close, maX, atrX);

   return true;
}
//==============================
// Function to get daily bias - analysing the bar counts and last bar above /below its MA
//==============================
ENUM_BIAS getTodayBias(st_PMA &destPMA) {
//---
   ENUM_BIAS todayBias = BIAS_NEUTRAL;
   int bull = 0, bear = 0;
   if(countYesterdayBars(PERIOD_CURRENT, bull, bear, destPMA)) {
      //-If EA was set to normal by user
      if(eaMode == MODE_NORMAL) {
         //-If bull count is greater than bear count and last bar close above its MA value
         if(bull > bear && destPMA.getClose() > destPMA.getMaValue()) {
            todayBias = BIAS_BUY;//-Normal
            return todayBias;
         } else if(bear > bull && destPMA.getClose() < destPMA.getMaValue()) {
            //-If bear count is greater than bull count and last bar close below its MA value
            todayBias = BIAS_SELL;
            return todayBias;
         }
      } else if(eaMode == MODE_INVERTED) {
         //-If EA was set to normal by user
         if(bull > bear && destPMA.getClose() > destPMA.getMaValue()) {
            //-If bull count is greater than bear count and last bar close above its MA value
            todayBias = BIAS_SELL;//-Inverted
            return todayBias;
         } else if(bear > bull && destPMA.getClose() < destPMA.getMaValue()) {
            //-If bull count is greater than bear count and last bar close below its MA value
            todayBias = BIAS_BUY;
            return todayBias;
         }
      }
   }
   return todayBias;
}
//==============================
// Function to open a buy position
//==============================
void executeBuy(st_PMA &strct) {
//---
   MqlTick tick;
   double margin = EMPTY_VALUE;
   if(SymbolInfoTick(_Symbol, tick)) {
      //-Place SL below the low of last bar formed previous day
      double sl = strct.getLow() - (strct.getAtrValue() * atrMultiplier);
      double slDistance = MathAbs(tick.bid - sl);
      //-Check SL distance
      if(slDistance < SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point) {
         Print(StringFormat("SL too tight: %d < minimum %d",
                            slDistance, (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)));
         return;
      }
      //-Margin check
      if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, _VolumeMin, tick.ask, margin))return;
      if(margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE)) {
         Print(StringFormat("Insufficient margin. Required: ", margin,
                            " Free: ", AccountInfoDouble(ACCOUNT_MARGIN_FREE)));
         return;
      }
      trade.Buy(_VolumeMin, _Symbol, tick.ask, sl, tick.ask + (slDistance * 2), tradeComment);
      if(trade.ResultRetcode() == TRADE_RETCODE_DONE) {
         Print(PROG_NAME + ". Buy trade successful");
         return;
      }
   }
}
//==============================
// Function to open a sell position
//==============================
void executeSell(st_PMA &strct) {
//---
   MqlTick tick;
   double margin = EMPTY_VALUE;
   if(SymbolInfoTick(_Symbol, tick)) {
      //-Place SL above the high of last bar formed previous day
      double sl = strct.getHigh() + (strct.getAtrValue() * atrMultiplier);
      double slDistance = MathAbs(tick.ask - sl);
      //-Check SL distance
      if(slDistance < SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)*_Point) {
         Print(StringFormat("SL too tight: %d < minimum %d",
                            slDistance, (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL)));
         return;
      }
      //-Margin check
      if(!OrderCalcMargin(ORDER_TYPE_SELL, _Symbol, _VolumeMin, tick.bid, margin))return;
      if(margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE)) {
         Print(StringFormat("Insufficient margin. Required: ", margin,
                            " Free: ", AccountInfoDouble(ACCOUNT_MARGIN_FREE)));
         return;
      }
      trade.Sell(_VolumeMin, _Symbol, tick.bid, sl, tick.bid - (slDistance * 2), tradeComment);
      if(trade.ResultRetcode() == TRADE_RETCODE_DONE) {
         Print(PROG_NAME + ". Sell trade successful");
         return;
      }
   }
}
//+------------------------------------------------------------------+

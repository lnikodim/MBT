//+------------------------------------------------------------------+
//| ORB_RiskManaged.mq5                                               |
//| Opening Range Breakout Expert Advisor with prop-firm style        |
//| risk management.                                                  |
//|                                                                   |
//| Logic:                                                            |
//|  - Marks the high/low of the first N minutes after session open.  |
//|  - Places a Buy Stop above and a Sell Stop below the range (OCO). |
//|  - One trade per day, everything is closed before session end.    |
//|                                                                   |
//| Risk management:                                                  |
//|  - Position size from % risk and stop distance                    |
//|  - Daily loss limit and maximum total drawdown limit              |
//|  - Positions are never carried into the next day                  |
//|                                                                   |
//| This is an educational template, not a profitable system.         |
//| Always test on a demo account before any live use.                |
//+------------------------------------------------------------------+
#property copyright "Matas936"
#property version   "1.10"
#property description "Opening Range Breakout with daily loss and max drawdown protection"

#include <Trade\Trade.mqh>

enum ENUM_TRADE_DIR
{
   DIR_BOTH  = 0,   // Both directions
   DIR_LONG  = 1,   // Long only
   DIR_SHORT = 2    // Short only
};

//--- NOTE: all times are in BROKER SERVER time
input group "Session (server time)"
input int    InpRangeStartHour   = 16;     // Range start: hour
input int    InpRangeStartMinute = 30;     // Range start: minute
input int    InpRangeMinutes     = 15;     // Range length (minutes)
input int    InpEntryEndHour     = 18;     // Last entry: hour
input int    InpEntryEndMinute   = 30;     // Last entry: minute
input int    InpCloseHour        = 22;     // Close all: hour
input int    InpCloseMinute      = 45;     // Close all: minute
input bool   InpTradeFriday      = true;   // Trade on Fridays

input group "Entry and risk"
input ENUM_TRADE_DIR InpDirection = DIR_BOTH; // Trade direction
input double InpRiskPercent      = 0.5;    // Risk per trade (% of balance)
input double InpRewardRisk       = 2.0;    // Take profit as R multiple (0 = none)
input double InpSLRangeFraction  = 1.0;    // Stop distance = range x this factor
input int    InpBufferPoints     = 20;     // Buffer above/below range (points)
input int    InpATRPeriod        = 14;     // Daily ATR period for range filter
input double InpMinRangeATR      = 0.05;   // Min range (x daily ATR, 0 = off)
input double InpMaxRangeATR      = 0.60;   // Max range (x daily ATR, 0 = off)

input group "Account protection"
input double InpDailyLossPct     = 3.0;    // Daily loss limit (%)
input double InpMaxTotalDDPct    = 8.0;    // Max total drawdown (%)
input double InpInitialBalance   = 0;      // Initial balance (0 = current balance)

input group "Other"
input ulong  InpMagic            = 240930; // Magic number

//--- state
CTrade   trade;
int      g_atrHandle      = INVALID_HANDLE;
datetime g_day            = 0;
double   g_dayStartEquity = 0;
double   g_initialBalance = 0;
double   g_rangeHigh      = 0;
double   g_rangeLow       = 0;
bool     g_rangeReady     = false;
bool     g_dayDone        = false;
bool     g_dayLocked      = false;
bool     g_hardStop       = false;

//+------------------------------------------------------------------+
int OnInit()
{
   if(InpRiskPercent <= 0 || InpRiskPercent > 2.0)
   {
      Print("Error: risk per trade must be between 0 and 2%");
      return INIT_PARAMETERS_INCORRECT;
   }
   if(InpRangeMinutes < 1)
   {
      Print("Error: range length must be at least 1 minute");
      return INIT_PARAMETERS_INCORRECT;
   }

   int rangeEndSec = InpRangeStartHour * 3600 + InpRangeStartMinute * 60 + InpRangeMinutes * 60;
   int entryEndSec = InpEntryEndHour * 3600 + InpEntryEndMinute * 60;
   int closeSec    = InpCloseHour * 3600 + InpCloseMinute * 60;
   if(!(rangeEndSec < entryEndSec && entryEndSec < closeSec))
   {
      Print("Error: required order is range end < last entry < close time");
      return INIT_PARAMETERS_INCORRECT;
   }

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(50);

   g_initialBalance = (InpInitialBalance > 0) ? InpInitialBalance : AccountInfoDouble(ACCOUNT_BALANCE);

   g_atrHandle = iATR(_Symbol, PERIOD_D1, InpATRPeriod);
   if(g_atrHandle == INVALID_HANDLE)
   {
      Print("Error: failed to create ATR handle");
      return INIT_FAILED;
   }
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
}

//+------------------------------------------------------------------+
datetime DayStart(datetime t)
{
   MqlDateTime dt;
   TimeToStruct(t, dt);
   dt.hour = 0;
   dt.min  = 0;
   dt.sec  = 0;
   return StructToTime(dt);
}

//+------------------------------------------------------------------+
double NormPrice(double p)
{
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(ts <= 0) ts = _Point;
   return NormalizeDouble(MathRound(p / ts) * ts, _Digits);
}

//+------------------------------------------------------------------+
bool IsOurPosition()
{
   return (PositionGetString(POSITION_SYMBOL) == _Symbol &&
           (ulong)PositionGetInteger(POSITION_MAGIC) == InpMagic);
}

//+------------------------------------------------------------------+
bool HasPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetTicket(i) == 0) continue;
      if(IsOurPosition()) return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| True if a position was opened before today's session day start.   |
//| Protects against positions carried overnight when no tick         |
//| arrives before the scheduled close time.                          |
//+------------------------------------------------------------------+
bool HasCarriedPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionGetTicket(i) == 0) continue;
      if(!IsOurPosition()) continue;
      if((datetime)PositionGetInteger(POSITION_TIME) < g_day)
         return true;
   }
   return false;
}

//+------------------------------------------------------------------+
void DeletePending()
{
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      ulong ticket = OrderGetTicket(i);
      if(ticket == 0) continue;
      if(OrderGetString(ORDER_SYMBOL) == _Symbol &&
         (ulong)OrderGetInteger(ORDER_MAGIC) == InpMagic)
         trade.OrderDelete(ticket);
   }
}

//+------------------------------------------------------------------+
void CloseAll()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(IsOurPosition())
         trade.PositionClose(ticket);
   }
   DeletePending();
}

//+------------------------------------------------------------------+
//| Lot size from risk. Returns 0 if even the minimum lot would       |
//| exceed the allowed risk (trade is skipped).                       |
//+------------------------------------------------------------------+
double CalcLots(double entry, double sl, ENUM_ORDER_TYPE pendingType)
{
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
   ENUM_ORDER_TYPE calcType = (pendingType == ORDER_TYPE_BUY_STOP) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

   double profit = 0;
   if(!OrderCalcProfit(calcType, _Symbol, 1.0, entry, sl, profit) || profit >= 0)
      return 0;

   double lots = riskMoney / (-profit);

   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step <= 0) step = 0.01;

   lots = MathFloor(lots / step) * step;
   if(lots < vmin) return 0;
   if(lots > vmax) lots = vmax;

   int volDigits = (int)MathMax(0, MathCeil(-MathLog10(step)));
   return NormalizeDouble(lots, volDigits);
}

//+------------------------------------------------------------------+
void CheckNewDay(datetime now)
{
   datetime d = DayStart(now);
   if(d != g_day)
   {
      g_day            = d;
      g_dayStartEquity = MathMax(AccountInfoDouble(ACCOUNT_BALANCE), AccountInfoDouble(ACCOUNT_EQUITY));
      g_rangeHigh      = 0;
      g_rangeLow       = 0;
      g_rangeReady     = false;
      g_dayDone        = false;
      g_dayLocked      = false;
   }
}

//+------------------------------------------------------------------+
bool CheckProtection()
{
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);

   if(!g_hardStop && equity <= g_initialBalance * (1.0 - InpMaxTotalDDPct / 100.0))
   {
      g_hardStop = true;
      Print("MAX DRAWDOWN reached. EA stopped until restart.");
   }
   if(!g_dayLocked && equity <= g_dayStartEquity * (1.0 - InpDailyLossPct / 100.0))
   {
      g_dayLocked = true;
      Print("DAILY LOSS LIMIT reached. No more trading today.");
   }

   if(g_hardStop || g_dayLocked)
   {
      CloseAll();
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
bool BuildRange(datetime rangeStart, datetime rangeEnd)
{
   MqlRates rates[];
   int n = CopyRates(_Symbol, PERIOD_M1, rangeStart, rangeEnd - 1, rates);
   if(n < MathMax(1, InpRangeMinutes / 2))
      return false;

   double hi = rates[0].high;
   double lo = rates[0].low;
   for(int i = 1; i < n; i++)
   {
      hi = MathMax(hi, rates[i].high);
      lo = MathMin(lo, rates[i].low);
   }
   g_rangeHigh = hi;
   g_rangeLow  = lo;
   return true;
}

//+------------------------------------------------------------------+
bool RangeFilterOK()
{
   double range = g_rangeHigh - g_rangeLow;
   if(range <= 0) return false;
   if(InpMinRangeATR <= 0 && InpMaxRangeATR <= 0) return true;

   double atr[];
   if(CopyBuffer(g_atrHandle, 0, 1, 1, atr) != 1) return false;

   if(InpMinRangeATR > 0 && range < InpMinRangeATR * atr[0]) return false;
   if(InpMaxRangeATR > 0 && range > InpMaxRangeATR * atr[0]) return false;
   return true;
}

//+------------------------------------------------------------------+
void PlaceOrders()
{
   double buffer  = InpBufferPoints * _Point;
   double range   = g_rangeHigh - g_rangeLow;
   double slDist  = range * InpSLRangeFraction + 2.0 * buffer;
   double ask     = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid     = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double minDist = (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) + 5) * _Point;

   //--- Buy Stop
   if(InpDirection != DIR_SHORT)
   {
      double price = NormPrice(g_rangeHigh + buffer);
      double sl    = NormPrice(price - slDist);
      double tp    = (InpRewardRisk > 0) ? NormPrice(price + slDist * InpRewardRisk) : 0;

      if(price - ask > minDist)
      {
         double lots = CalcLots(price, sl, ORDER_TYPE_BUY_STOP);
         if(lots > 0)
         {
            if(!trade.BuyStop(lots, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "ORB buy"))
               Print("Buy Stop failed, retcode: ", trade.ResultRetcode());
         }
         else Print("Buy side skipped: lot too small for allowed risk");
      }
      else Print("Price already above range, buy side skipped");
   }

   //--- Sell Stop
   if(InpDirection != DIR_LONG)
   {
      double price = NormPrice(g_rangeLow - buffer);
      double sl    = NormPrice(price + slDist);
      double tp    = (InpRewardRisk > 0) ? NormPrice(price - slDist * InpRewardRisk) : 0;

      if(bid - price > minDist)
      {
         double lots = CalcLots(price, sl, ORDER_TYPE_SELL_STOP);
         if(lots > 0)
         {
            if(!trade.SellStop(lots, price, _Symbol, sl, tp, ORDER_TIME_GTC, 0, "ORB sell"))
               Print("Sell Stop failed, retcode: ", trade.ResultRetcode());
         }
         else Print("Sell side skipped: lot too small for allowed risk");
      }
      else Print("Price already below range, sell side skipped");
   }

   g_dayDone = true;
}

//+------------------------------------------------------------------+
void OnTick()
{
   datetime now = TimeCurrent();
   CheckNewDay(now);

   if(!CheckProtection()) return;

   //--- safety: never carry a position into the next day
   if(HasCarriedPosition())
   {
      Print("Position carried from a previous day, closing");
      CloseAll();
      return;
   }

   datetime rangeStart = g_day + InpRangeStartHour * 3600 + InpRangeStartMinute * 60;
   datetime rangeEnd   = rangeStart + InpRangeMinutes * 60;
   datetime entryEnd   = g_day + InpEntryEndHour * 3600 + InpEntryEndMinute * 60;
   datetime closeTime  = g_day + InpCloseHour * 3600 + InpCloseMinute * 60;

   //--- session end: close everything
   if(now >= closeTime)
   {
      CloseAll();
      return;
   }

   //--- OCO: once a position is open, remove the opposite order
   if(HasPosition())
   {
      DeletePending();
      return;
   }

   //--- entry window over
   if(now >= entryEnd)
   {
      DeletePending();
      return;
   }

   if(g_dayDone) return;
   if(now < rangeEnd) return;

   MqlDateTime dt;
   TimeToStruct(now, dt);
   if(dt.day_of_week == 5 && !InpTradeFriday)
   {
      g_dayDone = true;
      return;
   }

   if(!g_rangeReady)
   {
      if(!BuildRange(rangeStart, rangeEnd)) return;  // data not ready yet, retry next tick
      g_rangeReady = true;

      if(!RangeFilterOK())
      {
         Print("Range outside ATR filter, no trade today");
         g_dayDone = true;
         return;
      }
   }

   PlaceOrders();
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                         GoldLondonBreakoutEA.mq5 |
//|                                            https://forge.mql5.io |
//+------------------------------------------------------------------+
#property copyright "Adeolu Gbadebo"
#property link      "https://forge.mql5.io"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>

//--- inputs -----------------------------------------------------------------
input group "=== Asian Range Window (server time) ==="
input int    InpAsianStartHour   = 0;    // Asian range window start hour
input int    InpAsianEndHour     = 7;    // Asian range window end hour (range is locked in here)
input int    InpDailyAtrPeriod   = 14;   // Daily ATR period used to scale the range filter
input double InpMinRangeATRFrac  = 0.15; // Skip the day if the Asian range is below this fraction of daily ATR
input double InpMaxRangeATRFrac  = 0.70; // Skip the day if the Asian range exceeds this fraction of daily ATR

input group "=== London Breakout Window (server time) ==="
input int    InpLondonStartHour  = 7;    // Earliest hour breakout orders may be placed/triggered
input int    InpLondonEndHour    = 11;   // Pending orders expire and are cancelled at this hour

input group "=== Trade Management ==="
input int    InpAtrPeriod        = 14;
input double InpBreakoutBufferATR= 0.15; // Entry buffer beyond the range, in ATR
input double InpStopATRMult      = 1.2;  // Stop distance from entry, in ATR
input double InpRewardMultiple   = 1.8;  // Take-profit as a multiple of the stop distance (R)
input double InpRiskPercent      = 1.0;  // Risk per trade, % of equity
input int    InpMaxSpreadPoints  = 350;  // Skip placing orders if spread exceeds this (gold spreads run wide)

input group "=== Housekeeping ==="
input int    InpMagicNumber      = 20260801;
input int    InpDeviationPoints  = 50;

//--- globals ------------------------------------------------------------------
CTrade   g_trade;
int      g_atrHandle      = INVALID_HANDLE;
int      g_dailyAtrHandle = INVALID_HANDLE;

datetime g_currentDay      = 0;
bool     g_rangeComputed   = false;
bool     g_ordersPlaced    = false;
double   g_rangeHigh       = 0.0;
double   g_rangeLow        = 0.0;
ulong    g_buyStopTicket   = 0;
ulong    g_sellStopTicket  = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                    |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpAsianEndHour <= InpAsianStartHour || InpLondonEndHour <= InpLondonStartHour)
     {
      Print("GoldLondonBreakoutEA: session hours must be same-day and start < end.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   g_atrHandle = iATR(_Symbol, _Period, InpAtrPeriod);
   if(g_atrHandle == INVALID_HANDLE)
     {
      Print("GoldLondonBreakoutEA: failed to create ATR handle, error ", GetLastError());
      return(INIT_FAILED);
     }

   g_dailyAtrHandle = iATR(_Symbol, PERIOD_D1, InpDailyAtrPeriod);
   if(g_dailyAtrHandle == INVALID_HANDLE)
     {
      Print("GoldLondonBreakoutEA: failed to create daily ATR handle, error ", GetLastError());
      return(INIT_FAILED);
     }

   g_trade.SetExpertMagicNumber(InpMagicNumber);
   g_trade.SetDeviationInPoints(InpDeviationPoints);

   g_currentDay = 0; // forces a fresh reset on the first tick
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
   if(g_dailyAtrHandle != INVALID_HANDLE)
      IndicatorRelease(g_dailyAtrHandle);

   //--- tidy up any of this EA's still-pending orders; open positions are left alone
   DeleteIfPending(g_buyStopTicket);
   DeleteIfPending(g_sellStopTicket);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                              |
//+------------------------------------------------------------------+
void OnTick()
  {
   datetime now = TimeCurrent();
   datetime todayStart = now - (now % 86400);

   if(todayStart != g_currentDay)
      ResetForNewDay(todayStart);

   MqlDateTime dt;
   TimeToStruct(now, dt);

   if(!g_rangeComputed && dt.hour >= InpAsianEndHour)
      ComputeAsianRange(todayStart);

   if(g_rangeComputed && !g_ordersPlaced && dt.hour >= InpLondonStartHour && dt.hour < InpLondonEndHour)
      PlaceBreakoutOrders(todayStart);

   if(g_ordersPlaced)
      ManageOrders();

   if(dt.hour >= InpLondonEndHour)
     {
      DeleteIfPending(g_buyStopTicket);
      DeleteIfPending(g_sellStopTicket);
      g_buyStopTicket  = 0;
      g_sellStopTicket = 0;
     }
  }

//+------------------------------------------------------------------+
//| Resets daily state and clears any leftover pending orders          |
//+------------------------------------------------------------------+
void ResetForNewDay(const datetime todayStart)
  {
   DeleteIfPending(g_buyStopTicket);
   DeleteIfPending(g_sellStopTicket);

   g_currentDay     = todayStart;
   g_rangeComputed  = false;
   g_ordersPlaced   = false;
   g_rangeHigh      = 0.0;
   g_rangeLow       = 0.0;
   g_buyStopTicket  = 0;
   g_sellStopTicket = 0;
  }

//+------------------------------------------------------------------+
//| Locks in the Asian session high/low once the window has closed    |
//+------------------------------------------------------------------+
void ComputeAsianRange(const datetime todayStart)
  {
   datetime rangeStart = todayStart + InpAsianStartHour * 3600;
   datetime rangeEnd   = todayStart + InpAsianEndHour   * 3600;

   MqlRates rates[];
   int copied = CopyRates(_Symbol, _Period, rangeStart, rangeEnd, rates);
   if(copied <= 0)
      return; // not enough data yet, try again next tick

   double hi = -DBL_MAX, lo = DBL_MAX;
   for(int i = 0; i < copied; i++)
     {
      if(rates[i].high > hi) hi = rates[i].high;
      if(rates[i].low  < lo) lo = rates[i].low;
     }

   g_rangeHigh     = hi;
   g_rangeLow      = lo;
   g_rangeComputed = true;
  }

//+------------------------------------------------------------------+
//| Places the OCO-style BuyStop/SellStop pair around the range        |
//+------------------------------------------------------------------+
void PlaceBreakoutOrders(const datetime todayStart)
  {
   g_ordersPlaced = true; // mark attempted regardless of outcome, so we don't retry all day

   double rangeSize = g_rangeHigh - g_rangeLow;

   double dailyAtrBuf[];
   ArraySetAsSeries(dailyAtrBuf, true);
   if(CopyBuffer(g_dailyAtrHandle, 0, 0, 1, dailyAtrBuf) < 1)
      return;
   double dailyAtr = dailyAtrBuf[0];
   if(dailyAtr <= 0.0)
      return;

   double minRange = InpMinRangeATRFrac * dailyAtr;
   double maxRange = InpMaxRangeATRFrac * dailyAtr;

   if(rangeSize < minRange || rangeSize > maxRange)
     {
      Print("GoldLondonBreakoutEA: Asian range ", DoubleToString(rangeSize, _Digits),
            " is ", DoubleToString(100.0 * rangeSize / dailyAtr, 1),
            "% of daily ATR (", DoubleToString(dailyAtr, _Digits), ") — outside [",
            DoubleToString(InpMinRangeATRFrac * 100.0, 0), "%, ",
            DoubleToString(InpMaxRangeATRFrac * 100.0, 0), "%] — sitting out today.");
      return;
     }

   long spreadPoints = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spreadPoints > InpMaxSpreadPoints)
     {
      Print("GoldLondonBreakoutEA: spread ", spreadPoints, " points too wide — sitting out today.");
      return;
     }

   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   if(CopyBuffer(g_atrHandle, 0, 0, 1, atrBuf) < 1)
      return;
   double atr = atrBuf[0];
   if(atr <= 0.0)
      return;

   //--- broker's own minimum distance for pending orders — ignoring this is what
   //--- produced the "Invalid price" rejections on tight-range days
   long stopsLevelPts  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long freezeLevelPts = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double minStopDistance = MathMax(stopsLevelPts, freezeLevelPts) * point;
   //--- add a small safety margin on top of the raw minimum so we don't sit exactly on the line
   minStopDistance *= 1.2;

   double buffer = MathMax(InpBreakoutBufferATR * atr, minStopDistance);
   double entryBuy  = NormalizePrice(g_rangeHigh + buffer);
   double entrySell = NormalizePrice(g_rangeLow  - buffer);

   double stopDist = MathMax(InpStopATRMult * atr, minStopDistance * 1.5);
   double slBuy = NormalizePrice(entryBuy - stopDist);
   double tpBuy = NormalizePrice(entryBuy + stopDist * InpRewardMultiple);

   double slSell = NormalizePrice(entrySell + stopDist);
   double tpSell = NormalizePrice(entrySell - stopDist * InpRewardMultiple);

   //--- validate each side is still a legitimate stop order relative to current price
   //--- before sending — if price already ran past the level, that side no longer
   //--- makes sense as a stop order and gets skipped rather than rejected by the broker
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   bool buySideValid  = (entryBuy  > ask + minStopDistance);
   bool sellSideValid = (entrySell < bid - minStopDistance);

   datetime expiration = todayStart + InpLondonEndHour * 3600;

   if(buySideValid)
     {
      double lotsBuy = CalcLotSize(MathAbs(entryBuy - slBuy));
      if(lotsBuy > 0.0 && HasEnoughMargin(ORDER_TYPE_BUY_STOP, lotsBuy, entryBuy))
        {
         if(g_trade.BuyStop(lotsBuy, entryBuy, _Symbol, slBuy, tpBuy, ORDER_TIME_SPECIFIED, expiration,
                             "Gold London Breakout"))
            g_buyStopTicket = g_trade.ResultOrder();
        }
      else if(lotsBuy > 0.0)
         Print("GoldLondonBreakoutEA: buy side skipped — insufficient free margin for the minimum lot size.");
     }
   else
      Print("GoldLondonBreakoutEA: buy side skipped — price already through the level at placement time.");

   if(sellSideValid)
     {
      double lotsSell = CalcLotSize(MathAbs(slSell - entrySell));
      if(lotsSell > 0.0 && HasEnoughMargin(ORDER_TYPE_SELL_STOP, lotsSell, entrySell))
        {
         if(g_trade.SellStop(lotsSell, entrySell, _Symbol, slSell, tpSell, ORDER_TIME_SPECIFIED, expiration,
                              "Gold London Breakout"))
            g_sellStopTicket = g_trade.ResultOrder();
        }
      else if(lotsSell > 0.0)
         Print("GoldLondonBreakoutEA: sell side skipped — insufficient free margin for the minimum lot size.");
     }
   else
      Print("GoldLondonBreakoutEA: sell side skipped — price already through the level at placement time.");
  }

//+------------------------------------------------------------------+
//| Checks the order is actually affordable before sending it, so an  |
//| under-funded account gets a clear skip instead of a broker reject |
//+------------------------------------------------------------------+
bool HasEnoughMargin(const ENUM_ORDER_TYPE orderType, const double volume, const double price)
  {
   double requiredMargin = 0.0;
   if(!OrderCalcMargin(orderType, _Symbol, volume, price, requiredMargin))
      return(true); // calculation unavailable — don't block the trade on that alone

   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   return(requiredMargin <= freeMargin);
  }

//+------------------------------------------------------------------+
//| OCO management: once one side fills, cancel the other              |
//+------------------------------------------------------------------+
void ManageOrders()
  {
   if(g_buyStopTicket == 0 && g_sellStopTicket == 0)
      return;

   bool positionOpen = PositionSelect(_Symbol);
   if(!positionOpen)
      return;

   if(PositionGetInteger(POSITION_MAGIC) != InpMagicNumber)
      return;

   //--- one side triggered into a live position — cancel whichever pending order is left
   DeleteIfPending(g_buyStopTicket);
   DeleteIfPending(g_sellStopTicket);
   g_buyStopTicket  = 0;
   g_sellStopTicket = 0;
  }

//+------------------------------------------------------------------+
//| Deletes an order only if it still exists and is still pending      |
//+------------------------------------------------------------------+
void DeleteIfPending(const ulong ticket)
  {
   if(ticket == 0)
      return;
   if(!OrderSelect(ticket))
      return;

   g_trade.OrderDelete(ticket);
  }

//+------------------------------------------------------------------+
//| Position sizing from risk percent and stop distance                |
//+------------------------------------------------------------------+
double CalcLotSize(const double stopDistance)
  {
   if(stopDistance <= 0.0)
      return(0.0);

   double equity   = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskMoney= equity * (InpRiskPercent / 100.0);
   double tickValue= SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0.0)
      return(0.0);

   double lossPerLot = (stopDistance / tickSize) * tickValue;
   if(lossPerLot <= 0.0)
      return(0.0);

   double lots = riskMoney / lossPerLot;

   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lots = MathFloor(lots / lotStep) * lotStep;
   lots = MathMax(minLot, MathMin(maxLot, lots));

   //--- defense in depth: even the floored minimum lot must be affordable.
   //--- checked here too (not just at the call site) so an unaffordable
   //--- trade can never reach OrderSend under any code path.
   double checkPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double requiredMargin = 0.0;
   if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lots, checkPrice, requiredMargin))
     {
      double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(requiredMargin > freeMargin)
        {
         Print("GoldLondonBreakoutEA: even the minimum lot (", DoubleToString(lots, 2),
               ") needs ~", DoubleToString(requiredMargin, 2), " margin, only ",
               DoubleToString(freeMargin, 2), " free — returning 0 lots.");
         return(0.0);
        }
     }

   return(lots);
  }

//+------------------------------------------------------------------+
//| Rounds a price to the symbol's tick size                           |
//+------------------------------------------------------------------+
double NormalizePrice(const double price)
  {
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0.0)
      return(NormalizeDouble(price, _Digits));

   return(NormalizeDouble(MathRound(price / tickSize) * tickSize, _Digits));
  }
//+------------------------------------------------------------------+
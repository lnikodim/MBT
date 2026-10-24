//+------------------------------------------------------------------+
//| ZoneUS30.mq5                                                    |
//| Isaac Carvalho                                                 |
//| isaacsilva100@gmail.com                                        |
//| © 2026 Isaac Carvalho. All rights reserved.                    |
//+------------------------------------------------------------------+
#property strict
#property copyright "© 2026 Isaac Carvalho. All rights reserved."
#property version   "1.01"
#property description "ZoneUS30 - Automated trading system for US30"
#property description "Author: Isaac Carvalho"
#property description "Contact: isaacsilva100@gmail.com"

#include <Trade/Trade.mqh>

// User settings
input double          Lot             = 5.00;
input ENUM_TIMEFRAMES SignalTimeframe = PERIOD_M30;

// Internal configuration
const long   EA_MAGIC             = 936001;
const int    MAX_SPREAD_POINTS    = 3000;
const int    DEVIATION_POINTS     = 20;
const double ZONE_PCT             = 0.12;
const double DISTANCE_PCT         = 0.40;
const double TAKE_PROFIT_PCT      = 0.75;
const double STOP_LOSS_PCT        = 4.00;
const string EA_ORDER_COMMENT     = "ZoneUS30";

CTrade   trade;
datetime lastSignalBar = 0;
datetime currentDay    = 0;
int      sellStage     = 0;

//+------------------------------------------------------------------+
//| Normalize volume to the broker's symbol rules                   |
//+------------------------------------------------------------------+
double NormalizeVolume(const double requestedVolume)
{
   double minVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step      = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(step <= 0.0)
      step = (minVolume > 0.0 ? minVolume : 0.01);

   double volume = MathMax(minVolume, MathMin(maxVolume, requestedVolume));
   volume = MathFloor((volume + 1e-12) / step) * step;
   return NormalizeDouble(volume, 8);
}


//+------------------------------------------------------------------+
//| Fit requested volume to the currently available free margin     |
//+------------------------------------------------------------------+
double FitVolumeToMargin(const double requestedVolume, const ENUM_ORDER_TYPE orderType, const double price)
{
   double volume = NormalizeVolume(requestedVolume);
   if(volume <= 0.0)
      return 0.0;

   double minVolume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double step      = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(step <= 0.0)
      step = (minVolume > 0.0 ? minVolume : 0.01);

   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(freeMargin <= 0.0)
      return 0.0;

   // Keep a small reserve instead of consuming all available margin.
   double marginBudget = freeMargin * 0.90;
   double requiredMargin = 0.0;

   if(OrderCalcMargin(orderType, _Symbol, volume, price, requiredMargin) &&
      requiredMargin > 0.0 && requiredMargin <= marginBudget)
      return volume;

   // Estimate an affordable volume proportionally, then normalize it.
   if(requiredMargin > 0.0)
   {
      double estimated = volume * marginBudget / requiredMargin;
      volume = NormalizeVolume(estimated);
   }

   // NormalizeVolume clamps to the symbol minimum, so explicitly verify
   // that even the resulting volume is affordable before trading.
   if(volume < minVolume)
      volume = minVolume;

   for(int i = 0; i < 1000 && volume >= minVolume - 1e-12; ++i)
   {
      requiredMargin = 0.0;
      if(OrderCalcMargin(orderType, _Symbol, volume, price, requiredMargin) &&
         requiredMargin > 0.0 && requiredMargin <= marginBudget)
      {
         return NormalizeDouble(volume, 8);
      }

      volume -= step;
      volume = MathFloor((volume + 1e-12) / step) * step;
      volume = NormalizeDouble(volume, 8);
   }

   return 0.0;
}

//+------------------------------------------------------------------+
//| Normalize price to the symbol tick size                         |
//+------------------------------------------------------------------+
double NormalizePrice(const double price)
{
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tickSize <= 0.0)
      tickSize = _Point;

   if(tickSize <= 0.0)
      return NormalizeDouble(price, _Digits);

   return NormalizeDouble(MathRound(price / tickSize) * tickSize, _Digits);
}

//+------------------------------------------------------------------+
//| Spread filter                                                    |
//+------------------------------------------------------------------+
bool SpreadAllowed()
{
   if(MAX_SPREAD_POINTS <= 0)
      return true;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick) || _Point <= 0.0)
      return false;

   return ((tick.ask - tick.bid) / _Point <= MAX_SPREAD_POINTS);
}

//+------------------------------------------------------------------+
//| Prevent more than one ZoneUS30 position on the symbol           |
//+------------------------------------------------------------------+
bool HasOpenPosition()
{
   for(int i = PositionsTotal() - 1; i >= 0; --i)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || !PositionSelectByTicket(ticket))
         continue;

      if(PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;

      if((long)PositionGetInteger(POSITION_MAGIC) == EA_MAGIC)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Previous trading day's high                                     |
//+------------------------------------------------------------------+
bool PreviousDayHigh(double &dayHigh)
{
   MqlRates daily[1];
   if(CopyRates(_Symbol, PERIOD_D1, 1, 1, daily) < 1)
      return false;

   dayHigh = daily[0].high;
   return (dayHigh > 0.0);
}

//+------------------------------------------------------------------+
//| Internal sell setup                                             |
//+------------------------------------------------------------------+
bool SellSignal()
{
   double previousHigh = 0.0;
   if(!PreviousDayHigh(previousHigh))
      return false;

   datetime day = iTime(_Symbol, PERIOD_D1, 0);
   if(day <= 0)
      return false;

   if(day != currentDay)
   {
      currentDay = day;
      sellStage  = 0;
   }

   double halfZone = previousHigh * ZONE_PCT / 100.0 / 2.0;
   double highTop  = previousHigh + halfZone;
   double highBot  = previousHigh - halfZone;

   MqlRates bar[1];
   if(CopyRates(_Symbol, SignalTimeframe, 1, 1, bar) < 1)
      return false;

   double closePrice = bar[0].close;

   if(sellStage == 0 && closePrice >= highBot)
      sellStage = 1;

   if(sellStage == 1 && closePrice <= highBot * (1.0 - DISTANCE_PCT / 100.0))
      sellStage = 2;

   if(sellStage == 2 && closePrice >= highBot && closePrice <= highTop)
      sellStage = 3;

   if(sellStage != 3)
      return false;

   sellStage = 0;
   return true;
}

//+------------------------------------------------------------------+
//| Open market sell                                                |
//+------------------------------------------------------------------+
bool OpenSell()
{
   if(!SpreadAllowed())
      return false;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick))
      return false;

   double volume = FitVolumeToMargin(Lot, ORDER_TYPE_SELL, tick.bid);
   if(volume <= 0.0)
   {
      Print("ZoneUS30: insufficient free margin even for the minimum allowed volume on ", _Symbol, ".");
      return false;
   }

   if(MathAbs(volume - Lot) > 1e-8)
      Print("ZoneUS30: requested lot ", DoubleToString(Lot, 2),
            " adjusted to ", DoubleToString(volume, 2),
            " to fit available margin on ", _Symbol, ".");

   double stopLoss   = NormalizePrice(tick.bid * (1.0 + STOP_LOSS_PCT / 100.0));
   double takeProfit = NormalizePrice(tick.bid * (1.0 - TAKE_PROFIT_PCT / 100.0));

   if(!trade.Sell(volume, _Symbol, 0.0, stopLoss, takeProfit, EA_ORDER_COMMENT))
   {
      Print("ZoneUS30: sell order failed. Retcode=", trade.ResultRetcode(),
            " | ", trade.ResultRetcodeDescription());
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Expert initialization                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   if(Lot <= 0.0)
   {
      Print("ZoneUS30: Lot must be greater than zero.");
      return INIT_PARAMETERS_INCORRECT;
   }

   if(PeriodSeconds(SignalTimeframe) <= 0)
   {
      Print("ZoneUS30: invalid signal timeframe.");
      return INIT_PARAMETERS_INCORRECT;
   }

   trade.SetExpertMagicNumber(EA_MAGIC);
   trade.SetDeviationInPoints(DEVIATION_POINTS);
   trade.SetTypeFillingBySymbol(_Symbol);

   lastSignalBar = 0;
   currentDay    = 0;
   sellStage     = 0;

   Print("ZoneUS30 initialized on ", _Symbol,
         " | Lot=", DoubleToString(Lot, 2),
         " | Timeframe=", EnumToString(SignalTimeframe));

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick                                                     |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime barTime = iTime(_Symbol, SignalTimeframe, 0);
   if(barTime <= 0 || barTime == lastSignalBar)
      return;

   lastSignalBar = barTime;

   bool signal = SellSignal();
   if(!signal || HasOpenPosition())
      return;

   OpenSell();
}
//+------------------------------------------------------------------+

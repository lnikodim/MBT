//+------------------------------------------------------------------+
//|                                          Multi_Divergence_EA.mq5 |
//|                              Copyright 2025, Le Trung Kien Hoang |
//|                        https://www.mql5.com/en/users/kienasiy123 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Le Trung Kien Hoang"
#property link      "https://www.mql5.com/en/users/kienasiy123"
#property version   "1.00"

#include <Trade\Trade.mqh>

//--- Input parameters
input group "=== Risk Management ==="
input double LotSize = 0.1;                // Lot size
input int StopLoss = 100;                  // Stop loss in points
input int TakeProfit = 200;                // Take profit in points
input int MaxSpread = 30;                  // Maximum spread allowed
input bool UseMoneyManagement = false;     // Use money management
input double RiskPercent = 2.0;            // Risk percentage per trade

input group "=== Divergence Settings ==="
input int RSI_Period = 14;                 // RSI period
input int MACD_Fast = 12;                  // MACD fast EMA
input int MACD_Slow = 26;                  // MACD slow EMA
input int MACD_Signal = 9;                 // MACD signal
input int Stoch_K = 5;                     // Stochastic %K
input int Stoch_D = 3;                     // Stochastic %D
input int Stoch_Slowing = 3;               // Stochastic slowing

input group "=== Divergence Detection ==="
input int BarsToCheck = 50;                // Bars to check for divergence
input int MinBarsDistance = 5;             // Minimum bars distance between peaks/troughs
input double MinDivergenceStrength = 0.7;  // Minimum divergence strength (0-1)
input int MinConfirmations = 3;            // Minimum confirmations needed (1-3)
input bool UseVolumeFilter = true;         // Use volume confirmation
input bool UseTrendFilter = true;          // Use trend filter

input group "=== Trading Settings ==="
input bool AllowBuy = true;                // Allow buy trades
input bool AllowSell = true;               // Allow sell trades
input int MaxTrades = 1;                   // Maximum concurrent trades
input int MagicNumber = 123456;            // Magic number

//--- Global variables
CTrade trade;
int rsi_handle, macd_handle, stoch_handle, ma_handle, volume_handle;
double rsi_buffer[], macd_main[], macd_signal[], stoch_main[], stoch_signal[];
double ma_buffer[], volume_buffer[];
double Ask = SYMBOL_ASK;
double Bid = SYMBOL_BID;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(MagicNumber);

   rsi_handle = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);
   macd_handle = iMACD(_Symbol, PERIOD_CURRENT, MACD_Fast, MACD_Slow, MACD_Signal, PRICE_CLOSE);
   stoch_handle = iStochastic(_Symbol, PERIOD_CURRENT, Stoch_K, Stoch_D, Stoch_Slowing, MODE_SMA, STO_LOWHIGH);
   ma_handle = iMA(_Symbol, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
   volume_handle = iVolumes(_Symbol, PERIOD_CURRENT, VOLUME_TICK);

   if(rsi_handle == INVALID_HANDLE || macd_handle == INVALID_HANDLE || stoch_handle == INVALID_HANDLE ||
      ma_handle == INVALID_HANDLE || volume_handle == INVALID_HANDLE)
     {
      Print("Error creating indicators");
      return INIT_FAILED;
     }

   ArraySetAsSeries(rsi_buffer, true);
   ArraySetAsSeries(macd_main, true);
   ArraySetAsSeries(macd_signal, true);
   ArraySetAsSeries(stoch_main, true);
   ArraySetAsSeries(stoch_signal, true);
   ArraySetAsSeries(ma_buffer, true);
   ArraySetAsSeries(volume_buffer, true);

   Print("Multi Divergence EA initialized successfully");
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                               |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(rsi_handle);
   IndicatorRelease(macd_handle);
   IndicatorRelease(stoch_handle);
   IndicatorRelease(ma_handle);
   IndicatorRelease(volume_handle);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   static datetime last_bar_time = 0;
   datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(current_bar_time == last_bar_time)
      return;
   last_bar_time = current_bar_time;

   double spread = (Ask - Bid) / Point();
   if(spread > MaxSpread)
      return;

   if(CountTrades() >= MaxTrades)
      return;

   if(!UpdateIndicatorData())
      return;

   int divergence_signal = AnalyzeDivergences();

   if(divergence_signal != 0)
     {
      if(UseTrendFilter && !ConfirmTrendDirection(divergence_signal))
         divergence_signal = 0;

      if(UseVolumeFilter && !ConfirmVolumePattern(divergence_signal))
         divergence_signal = 0;
     }

   if(divergence_signal == 1 && AllowBuy)
      OpenBuyTrade();
   else
      if(divergence_signal == -1 && AllowSell)
         OpenSellTrade();
  }

//+------------------------------------------------------------------+
//| Update indicator data                                            |
//+------------------------------------------------------------------+
bool UpdateIndicatorData()
  {
   int bars_needed = BarsToCheck + 10;

   if(CopyBuffer(rsi_handle, 0, 0, bars_needed, rsi_buffer) <= 0)
      return false;

   if(CopyBuffer(macd_handle, 0, 0, bars_needed, macd_main) <= 0)
      return false;
   if(CopyBuffer(macd_handle, 1, 0, bars_needed, macd_signal) <= 0)
      return false;

   if(CopyBuffer(stoch_handle, 0, 0, bars_needed, stoch_main) <= 0)
      return false;
   if(CopyBuffer(stoch_handle, 1, 0, bars_needed, stoch_signal) <= 0)
      return false;

   if(CopyBuffer(ma_handle, 0, 0, bars_needed, ma_buffer) <= 0)
      return false;

   if(CopyBuffer(volume_handle, 0, 0, bars_needed, volume_buffer) <= 0)
      return false;

   return true;
  }

//+------------------------------------------------------------------+
//| Analyze divergences across multiple indicators                   |
//+------------------------------------------------------------------+
int AnalyzeDivergences()
  {
   int bullish_count = 0;
   int bearish_count = 0;

   int rsi_div = CheckRSIDivergence();
   if(rsi_div == 1)
      bullish_count++;
   else
      if(rsi_div == -1)
         bearish_count++;

   int macd_div = CheckMACDDivergence();
   if(macd_div == 1)
      bullish_count++;
   else
      if(macd_div == -1)
         bearish_count++;

   int stoch_div = CheckStochasticDivergence();
   if(stoch_div == 1)
      bullish_count++;
   else
      if(stoch_div == -1)
         bearish_count++;

   if(bullish_count >= MinConfirmations)
      return 1; 
   else
      if(bearish_count >= MinConfirmations)
         return -1;

   return 0;
  }

//+------------------------------------------------------------------+
//| Check RSI divergence                                             |
//+------------------------------------------------------------------+
int CheckRSIDivergence()
  {
   double price_highs[], price_lows[], rsi_highs[], rsi_lows[];
   int high_bars[], low_bars[];

   if(!FindPeaksAndTroughs(price_highs, price_lows, rsi_highs, rsi_lows, high_bars, low_bars, rsi_buffer))
      return 0;

   if(ArraySize(price_lows) >= 2 && ArraySize(rsi_lows) >= 2)
     {
      if(price_lows[0] < price_lows[1] && rsi_lows[0] > rsi_lows[1])
        {
         double strength = CalculateDivergenceStrength(price_lows[0], price_lows[1], rsi_lows[0], rsi_lows[1]);
         if(strength >= MinDivergenceStrength)
            return 1; // Bullish divergence
        }
     }

   if(ArraySize(price_highs) >= 2 && ArraySize(rsi_highs) >= 2)
     {
      if(price_highs[0] > price_highs[1] && rsi_highs[0] < rsi_highs[1])
        {
         double strength = CalculateDivergenceStrength(price_highs[0], price_highs[1], rsi_highs[0], rsi_highs[1]);
         if(strength >= MinDivergenceStrength)
            return -1; // Bearish divergence
        }
     }

   return 0;
  }

//+------------------------------------------------------------------+
//| Check MACD divergence                                            |
//+------------------------------------------------------------------+
int CheckMACDDivergence()
  {
   double price_highs[], price_lows[], macd_highs[], macd_lows[];
   int high_bars[], low_bars[];

   if(!FindPeaksAndTroughs(price_highs, price_lows, macd_highs, macd_lows, high_bars, low_bars, macd_main))
      return 0;

   if(ArraySize(price_lows) >= 2 && ArraySize(macd_lows) >= 2)
     {
      if(price_lows[0] < price_lows[1] && macd_lows[0] > macd_lows[1])
        {
         double strength = CalculateDivergenceStrength(price_lows[0], price_lows[1], macd_lows[0], macd_lows[1]);
         if(strength >= MinDivergenceStrength)
            return 1;
        }
     }

   if(ArraySize(price_highs) >= 2 && ArraySize(macd_highs) >= 2)
     {
      if(price_highs[0] > price_highs[1] && macd_highs[0] < macd_highs[1])
        {
         double strength = CalculateDivergenceStrength(price_highs[0], price_highs[1], macd_highs[0], macd_highs[1]);
         if(strength >= MinDivergenceStrength)
            return -1;
        }
     }

   return 0;
  }

//+------------------------------------------------------------------+
//| Check Stochastic divergence                                      |
//+------------------------------------------------------------------+
int CheckStochasticDivergence()
  {
   double price_highs[], price_lows[], stoch_highs[], stoch_lows[];
   int high_bars[], low_bars[];

   if(!FindPeaksAndTroughs(price_highs, price_lows, stoch_highs, stoch_lows, high_bars, low_bars, stoch_main))
      return 0;

   if(ArraySize(price_lows) >= 2 && ArraySize(stoch_lows) >= 2)
     {
      if(price_lows[0] < price_lows[1] && stoch_lows[0] > stoch_lows[1])
        {
         double strength = CalculateDivergenceStrength(price_lows[0], price_lows[1], stoch_lows[0], stoch_lows[1]);
         if(strength >= MinDivergenceStrength)
            return 1;
        }
     }

   if(ArraySize(price_highs) >= 2 && ArraySize(stoch_highs) >= 2)
     {
      if(price_highs[0] > price_highs[1] && stoch_highs[0] < stoch_highs[1])
        {
         double strength = CalculateDivergenceStrength(price_highs[0], price_highs[1], stoch_highs[0], stoch_highs[1]);
         if(strength >= MinDivergenceStrength)
            return -1;
        }
     }

   return 0;
  }

//+------------------------------------------------------------------+
//| Find peaks and troughs                                           |
//+------------------------------------------------------------------+
bool FindPeaksAndTroughs(double &price_highs[], double &price_lows[],
                         double &ind_highs[], double &ind_lows[],
                         int &high_bars[], int &low_bars[], double &indicator[])
  {
   ArrayResize(price_highs, 0);
   ArrayResize(price_lows, 0);
   ArrayResize(ind_highs, 0);
   ArrayResize(ind_lows, 0);
   ArrayResize(high_bars, 0);
   ArrayResize(low_bars, 0);

   for(int i = MinBarsDistance; i < BarsToCheck - MinBarsDistance; i++)
     {
      bool is_peak = true;
      bool is_trough = true;

      double current_high = iHigh(_Symbol, PERIOD_CURRENT, i);
      double current_low = iLow(_Symbol, PERIOD_CURRENT, i);
      double current_ind = indicator[i];

      for(int j = 1; j <= MinBarsDistance; j++)
        {
         if(i-j < 0 || i+j >= BarsToCheck)
            continue;
         if(current_high <= iHigh(_Symbol, PERIOD_CURRENT, i-j) ||
            current_high <= iHigh(_Symbol, PERIOD_CURRENT, i+j))
           {
            is_peak = false;
            break;
           }
        }

      if(is_peak)
        {
         double avg_high = 0;
         int count = 0;
         for(int k = i-MinBarsDistance*2; k <= i+MinBarsDistance*2; k++)
           {
            if(k < 0 || k >= BarsToCheck || k == i)
               continue;
            avg_high += iHigh(_Symbol, PERIOD_CURRENT, k);
            count++;
           }
         if(count > 0 && current_high <= avg_high/count * 1.001) 
            is_peak = false;
        }

      for(int j = 1; j <= MinBarsDistance; j++)
        {
         if(i-j < 0 || i+j >= BarsToCheck)
            continue;
         if(current_low >= iLow(_Symbol, PERIOD_CURRENT, i-j) ||
            current_low >= iLow(_Symbol, PERIOD_CURRENT, i+j))
           {
            is_trough = false;
            break;
           }
        }

      if(is_trough)
        {
         double avg_low = 0;
         int count = 0;
         for(int k = i-MinBarsDistance*2; k <= i+MinBarsDistance*2; k++)
           {
            if(k < 0 || k >= BarsToCheck || k == i)
               continue;
            avg_low += iLow(_Symbol, PERIOD_CURRENT, k);
            count++;
           }
         if(count > 0 && current_low >= avg_low/count * 0.999) 
            is_trough = false;
        }

      if(is_peak)
        {
         int size = ArraySize(price_highs);
         ArrayResize(price_highs, size + 1);
         ArrayResize(ind_highs, size + 1);
         ArrayResize(high_bars, size + 1);

         price_highs[size] = current_high;
         ind_highs[size] = current_ind;
         high_bars[size] = i;
        }

      if(is_trough)
        {
         int size = ArraySize(price_lows);
         ArrayResize(price_lows, size + 1);
         ArrayResize(ind_lows, size + 1);
         ArrayResize(low_bars, size + 1);

         price_lows[size] = current_low;
         ind_lows[size] = current_ind;
         low_bars[size] = i;
        }
     }

   return (ArraySize(price_highs) > 0 || ArraySize(price_lows) > 0);
  }

//+------------------------------------------------------------------+
//| Calculate divergence strength                                    |
//+------------------------------------------------------------------+
double CalculateDivergenceStrength(double price1, double price2, double ind1, double ind2)
  {
   double price_change = MathAbs(price1 - price2) / MathMax(price1, price2);
   double ind_change = MathAbs(ind1 - ind2) / MathMax(MathAbs(ind1), MathAbs(ind2));

   return MathMin(price_change + ind_change, 1.0);
  }

//+------------------------------------------------------------------+
//| Open buy trade                                                   |
//+------------------------------------------------------------------+
void OpenBuyTrade()
  {
   double lot_size = CalculateLotSize();
   double sl = (StopLoss > 0) ? Bid - StopLoss * Point() : 0;
   double tp = (TakeProfit > 0) ? Ask + TakeProfit * Point() : 0;

   if(trade.Buy(lot_size, _Symbol, Ask, sl, tp, "Multi Divergence EA - Buy"))
     {
      Print("Buy order opened successfully");
     }
   else
     {
      Print("Failed to open buy order. Error: ", trade.ResultRetcode());
     }
  }

//+------------------------------------------------------------------+
//| Open sell trade                                                  |
//+------------------------------------------------------------------+
void OpenSellTrade()
  {
   double lot_size = CalculateLotSize();
   double sl = (StopLoss > 0) ? Ask + StopLoss * Point() : 0;
   double tp = (TakeProfit > 0) ? Bid - TakeProfit * Point() : 0;

   if(trade.Sell(lot_size, _Symbol, Bid, sl, tp, "Multi Divergence EA - Sell"))
     {
      Print("Sell order opened successfully");
     }
   else
     {
      Print("Failed to open sell order. Error: ", trade.ResultRetcode());
     }
  }

//+------------------------------------------------------------------+
//| Calculate lot size                                               |
//+------------------------------------------------------------------+
double CalculateLotSize()
  {
   if(!UseMoneyManagement)
      return LotSize;

   double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_amount = account_balance * RiskPercent / 100.0;
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);

   if(tick_value == 0 || StopLoss == 0)
      return LotSize;

   double calculated_lot = risk_amount / (StopLoss * tick_value);

   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   calculated_lot = MathMax(calculated_lot, min_lot);
   calculated_lot = MathMin(calculated_lot, max_lot);
   calculated_lot = MathFloor(calculated_lot / lot_step) * lot_step;

   return calculated_lot;
  }

//+------------------------------------------------------------------+
//| Count open trades                                                |
//+------------------------------------------------------------------+
int CountTrades()
  {
   int count = 0;
   for(int i = 0; i < PositionsTotal(); i++)
     {
      if(PositionGetSymbol(i) == _Symbol && PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         count++;
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Confirm trend direction                                          |
//+------------------------------------------------------------------+
bool ConfirmTrendDirection(int signal)
  {
   double current_price = iClose(_Symbol, PERIOD_CURRENT, 1);
   double ma_value = ma_buffer[1];

   if(signal == 1) 
      return (current_price > ma_value); 
   else
      if(signal == -1) 
         return (current_price < ma_value);

   return false;
  }

//+------------------------------------------------------------------+
//| Confirm volume pattern                                           |
//+------------------------------------------------------------------+
bool ConfirmVolumePattern(int signal)
  {
   double avg_volume = 0;
   int bars_to_check = 10;

   for(int i = 1; i <= bars_to_check; i++)
     {
      avg_volume += volume_buffer[i];
     }
   avg_volume /= bars_to_check;

   double recent_volume = volume_buffer[1];

   return (recent_volume > avg_volume * 1.2); 
  }

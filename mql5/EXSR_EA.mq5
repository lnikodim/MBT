//+------------------------------------------------------------------+
//|                                                         EXSR.mq5 |
//|                   Copyright 2025,Le Trung Kien Hoang-Kienasiy123 |
//|                              Extreme Strength Reversal EA        |
//+------------------------------------------------------------------+
#property copyright "Le Trung Kien Hoang"
#property link      "https://www.mql5.com/en/users/kienasiy123"
#property version   "1.0"
#property description " Extreme Strength Reversal EA"

#include <Trade\Trade.mqh>
CTrade trade;

//--- Input Parameters ---
input string g_section_risk   = "#### Risk Management ####";
input double Risk_Percent     = 1.0;      // Risk per trade as a percentage of account equity

input string g_section_trade  = "#### Trade Settings ####";
input ulong  MagicNumber      = 697988;   // Unique ID for EA's orders
input int    StopLoss_pips    = 150;      // Stop Loss in pips
input int    TakeProfit_pips  = 300;      // Take Profit in pips

input string g_section_ind    = "#### Indicator Settings ####";
input int    BB_Period        = 20;       // Bollinger Bands Period
input double BB_Deviation     = 2.0;      // Bollinger Bands Deviation
input int    RSI_Period       = 14;       // RSI Period
input double RSI_Overbought   = 80.0;     // Extreme Overbought Level for RSI
input double RSI_Oversold     = 20.0;     // Extreme Oversold Level for RSI

//--- Global Variables ---
int      g_rsi_handle;
int      g_bb_handle;
double   g_rsi_buffer[];
double   g_bb_upper_buffer[];
double   g_bb_lower_buffer[];
MqlRates g_price_data[];
datetime lastBarTime=0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Setup trade object
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetTypeFillingBySymbol(_Symbol);

//--- Create indicator handles
   g_rsi_handle = iRSI(_Symbol, _Period, RSI_Period, PRICE_CLOSE);
   if(g_rsi_handle == INVALID_HANDLE)
     {
      Print("Error creating RSI indicator handle. Error code: ", GetLastError());
      return(INIT_FAILED);
     }
   g_bb_handle = iBands(_Symbol, _Period, BB_Period, 0, BB_Deviation, PRICE_CLOSE);
   if(g_bb_handle == INVALID_HANDLE)
     {
      Print("Error creating Bollinger Bands indicator handle. Error code: ", GetLastError());
      return(INIT_FAILED);
     }

//--- Set arrays as time series
   ArraySetAsSeries(g_rsi_buffer, true);
   ArraySetAsSeries(g_bb_upper_buffer, true);
   ArraySetAsSeries(g_bb_lower_buffer, true);
   ArraySetAsSeries(g_price_data, true);

   Print("EXSR has been initialized. Risk per trade: ", Risk_Percent, "%");
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- Release indicator handles
   if(g_rsi_handle != INVALID_HANDLE)
      IndicatorRelease(g_rsi_handle);
   if(g_bb_handle != INVALID_HANDLE)
      IndicatorRelease(g_bb_handle);

   Print("EXSR EA has been removed.");
  }

//+------------------------------------------------------------------+
//| Normalize volume based on symbol specifications                  |
//+------------------------------------------------------------------+
double NormalizeVolume(double volume)
  {
   double vol_min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vol_max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vol_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(volume < vol_min) volume = vol_min;
   if(volume > vol_max) volume = vol_max;

   int steps = (int)MathRound(volume / vol_step);
   double normalized_volume = steps * vol_step;

   if(normalized_volume < vol_min) normalized_volume = vol_min;
   if(normalized_volume > vol_max) normalized_volume = vol_max;
   return(normalized_volume);
  }
//+------------------------------------------------------------------+
//| Calculate lot size based on risk percentage                      |
//+------------------------------------------------------------------+
double CalculateLotSize()
  {
   if(StopLoss_pips <= 0 || Risk_Percent <= 0)
      return(0.0);

//--- Get account and symbol info
   double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double risk_amount = account_equity * (Risk_Percent / 100.0);
   double tick_value = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tick_value <= 0 || tick_size <= 0) return(0.0);

//--- Calculate loss per lot
   double loss_per_lot = StopLoss_pips * _Point / tick_size * tick_value;
   if(loss_per_lot <= 0) return(0.0);

//--- Calculate and normalize lot size
   double desired_lot_size = risk_amount / loss_per_lot;
   double normalized_lot = NormalizeVolume(desired_lot_size);

//--- Check for free margin
   double margin_required = 0;
   if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, normalized_lot, SymbolInfoDouble(_Symbol, SYMBOL_ASK), margin_required))
     {
      if(margin_required > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
        {
         Print("Not enough free margin to open trade. Required: ", margin_required, ", Available: ", AccountInfoDouble(ACCOUNT_MARGIN_FREE));
         return(0.0);
        }
     }
   return(normalized_lot);
  }
//+------------------------------------------------------------------+
//| Copy fresh data into arrays                                      |
//+------------------------------------------------------------------+
bool CopyData()
  {
   if(CopyRates(_Symbol, _Period, 1, 2, g_price_data) < 2) return false;
   if(CopyBuffer(g_rsi_handle, 0, 1, 2, g_rsi_buffer) < 2) return false;
   if(CopyBuffer(g_bb_handle, 1, 1, 2, g_bb_upper_buffer) < 2) return false;
   if(CopyBuffer(g_bb_handle, 2, 1, 2, g_bb_lower_buffer) < 2) return false;
   return true;
  }
//+------------------------------------------------------------------+
//| Check for a BUY signal                                           |
//+------------------------------------------------------------------+
bool CheckBuySignal()
  {
   MqlRates prev_bar = g_price_data[1];
   return(g_rsi_buffer[1] < RSI_Oversold && g_rsi_buffer[1] > 0 &&
          prev_bar.low < g_bb_lower_buffer[1] && prev_bar.close > prev_bar.open);
  }
//+------------------------------------------------------------------+
//| Check for a SELL signal                                          |
//+------------------------------------------------------------------+
bool CheckSellSignal()
  {
   MqlRates prev_bar = g_price_data[1];
   return(g_rsi_buffer[1] > RSI_Overbought &&
          prev_bar.high > g_bb_upper_buffer[1] && prev_bar.close < prev_bar.open);
  }
//+------------------------------------------------------------------+
//| Expert Tick Function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- Use bar opening time instead of server time
   datetime barTime = iTime(_Symbol, _Period, 0);
   if(barTime <= lastBarTime)
      return;
   lastBarTime = barTime;

//--- Check for existing positions for this symbol
   if(PositionSelect(_Symbol))
      return;

//--- Copy fresh data from indicators and price
   if(!CopyData())
      return;

//--- Calculate lot size based on risk
   double lots_to_trade = CalculateLotSize();
   if(lots_to_trade <= 0)
      return;

//--- Check for trading signals and execute trades
   if(CheckBuySignal())
     {
      double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double sl = price - StopLoss_pips * _Point;
      double tp = price + TakeProfit_pips * _Point;
      trade.Buy(lots_to_trade, _Symbol, price, sl, tp, "EXSR Buy");
     }
   else if(CheckSellSignal())
     {
      double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl = price + StopLoss_pips * _Point;
      double tp = price - TakeProfit_pips * _Point;
      trade.Sell(lots_to_trade, _Symbol, price, sl, tp, "EXSR Sell");
     }
  }
//+------------------------------------------------------------------+
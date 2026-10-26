//+------------------------------------------------------------------+
//|                                                  fc_maenv_EA.mq5 |
//|                          Copyright 2026, Amarnath Kondiyan Mohan |
//|     https://www.linkedin.com/in/amarnath-kondiyan-mohan-546293a/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Amarnath Kondiyan Mohan"
#property link      "https://www.linkedin.com/in/amarnath-kondiyan-mohan-546293a/"
#property version   "1.02"

#include <Trade\Trade.mqh>

input int risk_percent = 99;
input int target_percent = 1;
input bool cycle1 = true;
input bool cycle2 = false;
input bool cycle3 = false;
input double LotSize = 0.01;
input int Slippage = 5;
input ulong c1_MagicNumber = 123;
input ulong c2_MagicNumber = 456;
input ulong c3_MagicNumber = 789;

// MA Settings
input int MAPeriod = 100;
input int MA_shift = 0;
input ENUM_MA_METHOD MA_method = MODE_EMA;
input ENUM_APPLIED_PRICE MA_appliedprice = PRICE_CLOSE;

// Envelopes Settings
input int                InpMAPeriod = 99;              // Period
input int                InpMAShift = 0;                // Shift
input ENUM_MA_METHOD     InpMAMethod = MODE_EMA;        // Method
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE; // Applied price
input double             c2_InpDeviation = 0.03;        // Deviation
input double             c3_InpDeviation = 0.3;         // Deviation

// Trade objects
CTrade trade1;
CTrade trade2;
CTrade trade3;

// Indicator Handles
int ma_handle;
int env2_handle;
int env3_handle;

// C1 Cycle Settings
double c1_account_equity_buy;
double c1_targetprice_buy;
double c1_riskprice_buy;
double c1_account_equity_sell;
double c1_targetprice_sell;
double c1_riskprice_sell;
bool c1_first_order = true;
bool c1_Buycycle = true;
bool c1_sellcycle = true;
bool c1_check_for_buy_close = false;
bool c1_check_for_sell_close = false;
double c1_open_price;
bool c1_place_order = false;
int c1_Buycount = 0;
int c1_Sellcount = 0;

// C2 Cycle Settings
double c2_account_equity_buy;
double c2_targetprice_buy;
double c2_riskprice_buy;
double c2_account_equity_sell;
double c2_targetprice_sell;
double c2_riskprice_sell;
bool c2_first_order = true;
bool c2_Buycycle = true;
bool c2_sellcycle = true;
bool c2_check_for_buy_close = false;
bool c2_check_for_sell_close = false;
double c2_open_price;
bool c2_place_order = false;
int c2_Buycount = 0;
int c2_Sellcount = 0;

// C3 Cycle Settings
double c3_account_equity_buy;
double c3_targetprice_buy;
double c3_riskprice_buy;
double c3_account_equity_sell;
double c3_targetprice_sell;
double c3_riskprice_sell;
bool c3_first_order = true;
bool c3_Buycycle = true;
bool c3_sellcycle = true;
bool c3_check_for_buy_close = false;
bool c3_check_for_sell_close = false;
double c3_open_price;
bool c3_place_order = false;
int c3_Buycount = 0;
int c3_Sellcount = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
// Setup Trade objects
   trade1.SetExpertMagicNumber(c1_MagicNumber);
   trade1.SetDeviationInPoints(Slippage);
   trade2.SetExpertMagicNumber(c2_MagicNumber);
   trade2.SetDeviationInPoints(Slippage);
   trade3.SetExpertMagicNumber(c3_MagicNumber);
   trade3.SetDeviationInPoints(Slippage);

// Initialize Indicator Handles
   ma_handle = iMA(_Symbol, _Period, MAPeriod, MA_shift, MA_method, MA_appliedprice);
   env2_handle = iEnvelopes(_Symbol, _Period, InpMAPeriod, InpMAShift, InpMAMethod, InpAppliedPrice, c2_InpDeviation);
   env3_handle = iEnvelopes(_Symbol, _Period, InpMAPeriod, InpMAShift, InpMAMethod, InpAppliedPrice, c3_InpDeviation);

   if(ma_handle == INVALID_HANDLE || env2_handle == INVALID_HANDLE || env3_handle == INVALID_HANDLE)
     {
      Print("Error creating indicator handles");
      return(INIT_FAILED);
     }

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(ma_handle);
   IndicatorRelease(env2_handle);
   IndicatorRelease(env3_handle);
  }

//+------------------------------------------------------------------+
//| Helper Function: Normalize Volume based on broker rules          |
//+------------------------------------------------------------------+
double CheckVolume(double volume)
  {
   double min_vol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_vol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step_vol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(volume < min_vol)
     {
      Print("Warning: Requested lot ", volume, " is below broker minimum. Adjusting to ", min_vol);
      volume = min_vol;
     }

   if(volume > max_vol)
      volume = max_vol;

   if(step_vol > 0)
     {
      volume = MathRound(volume / step_vol) * step_vol;
     }

   return volume;
  }

//+------------------------------------------------------------------+
//| Helper Function: Check if we have enough margin for the trade    |
//+------------------------------------------------------------------+
bool CheckMargin(ENUM_ORDER_TYPE order_type, double volume)
  {
   double margin_required = 0.0;
   double current_price = 0.0;

   if(order_type == ORDER_TYPE_BUY)
      current_price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   else
      current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(OrderCalcMargin(order_type, _Symbol, volume, current_price, margin_required))
     {
      double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

      if(free_margin < margin_required)
        {
         Print("Validation handled: Not enough margin. Required: ", margin_required, " Free: ", free_margin);
         return false;
        }
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
// Fetch generic pricing and bar data
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, _Period, 0, 2, rates) != 2)
      return;

   double open0 = rates[0].open;
   double close1 = rates[1].close;

// Fetch account info
   double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);

//+------------------------------------------------------------------+
//| Cycle 1 Execution
//+------------------------------------------------------------------+
   if(cycle1 == true)
     {
      double ma_val[];
      if(CopyBuffer(ma_handle, 0, 0, 1, ma_val) > 0)
        {
         double MA = ma_val[0];

         // Buy Order Trigger
         if(close1 > MA && open0 > MA && c1_Buycycle == true)
           {
            c1_check_for_sell_close = false;
            double c1_key = open0;
            if(c1_key != c1_open_price)
              {
               c1_open_price = c1_key;
               c1_place_order = true;
              }
            else
               c1_place_order = false;

            if(c1_Buycount == 0)
              {
               c1_account_equity_buy = account_equity;
               c1_targetprice_buy = (c1_account_equity_buy + ((c1_account_equity_buy * target_percent) / 1000));
               c1_riskprice_buy = (c1_account_equity_buy - ((c1_account_equity_buy * risk_percent) / 1000));
              }

            if(c1_place_order == true)
              {
               double safe_lot = CheckVolume(LotSize);
               if(CheckMargin(ORDER_TYPE_BUY, safe_lot) == true)
                 {
                  trade1.Buy(safe_lot, _Symbol);
                 }
              }

            c1_sellcycle = true;
            c1_check_for_buy_close = true;
            c1_Buycount++;
           }
         // Sell Order Trigger
         else
            if(close1 < MA && open0 < MA && c1_sellcycle == true)
              {
               c1_check_for_buy_close = false;
               double c1_key = open0;
               if(c1_key != c1_open_price)
                 {
                  c1_open_price = c1_key;
                  c1_place_order = true;
                 }
               else
                  c1_place_order = false;

               if(c1_Sellcount == 0)
                 {
                  c1_account_equity_sell = account_equity;
                  c1_targetprice_sell = (c1_account_equity_sell + ((c1_account_equity_sell * target_percent) / 100));
                  c1_riskprice_sell = (c1_account_equity_sell - ((c1_account_equity_sell * risk_percent) / 100));
                 }

               if(c1_place_order == true)
                 {
                  double safe_lot = CheckVolume(LotSize);
                  if(CheckMargin(ORDER_TYPE_SELL, safe_lot) == true)
                    {
                     trade1.Sell(safe_lot, _Symbol);
                    }
                 }

               c1_Buycycle = true;
               c1_check_for_sell_close = true;
               c1_Sellcount++;
              }
        }

      // Logic Check for Cycle 1
      double c1_check_profit_Buy = MyAccountProfit_Buy(c1_MagicNumber);
      double c1_check_profit_Sell = MyAccountProfit_Sell(c1_MagicNumber);

      double c1_profit_Buy = c1_account_equity_buy + c1_check_profit_Buy;
      double c1_profit_Sell = c1_account_equity_sell + c1_check_profit_Sell;

      // Target / Stop loss closing
      if((c1_profit_Sell >= c1_targetprice_sell || c1_profit_Sell <= c1_riskprice_sell) && c1_check_for_sell_close == true)
        {
         CloseAllByMagic(c1_MagicNumber, POSITION_TYPE_SELL, trade1);
         c1_sellcycle = false;
         c1_Sellcount = 0;
        }
      else
         if((c1_profit_Buy >= c1_targetprice_buy || c1_profit_Buy <= c1_riskprice_buy) && c1_check_for_buy_close == true)
           {
            CloseAllByMagic(c1_MagicNumber, POSITION_TYPE_BUY, trade1);
            c1_Buycycle = false;
            c1_Buycount = 0;
           }

      // Secondary risk closing conditions
      if(c1_profit_Buy <= c1_riskprice_buy && c1_check_for_buy_close == false)
        {
         CloseAllByMagic(c1_MagicNumber, POSITION_TYPE_BUY, trade1);
         c1_Buycount = 0;
        }
      else
         if(c1_profit_Sell <= c1_riskprice_sell && c1_check_for_sell_close == false)
           {
            CloseAllByMagic(c1_MagicNumber, POSITION_TYPE_SELL, trade1);
            c1_Sellcount = 0;
           }
     }

//+------------------------------------------------------------------+
//| Cycle 2 Execution
//+------------------------------------------------------------------+
   if(cycle2 == true)
     {
      double up_env2[], down_env2[];
      if(CopyBuffer(env2_handle, 0, 0, 1, up_env2) > 0 && CopyBuffer(env2_handle, 1, 0, 1, down_env2) > 0)
        {
         double up_envelope = up_env2[0];
         double down_envelope = down_env2[0];

         if(close1 > up_envelope && open0 > up_envelope && c2_Buycycle == true)
           {
            c2_check_for_sell_close = false;
            double c2_key = open0;
            if(c2_key != c2_open_price)
              {
               c2_open_price = c2_key;
               c2_place_order = true;
              }
            else
               c2_place_order = false;

            if(c2_Buycount == 0)
              {
               c2_account_equity_buy = account_equity;
               c2_targetprice_buy = (c2_account_equity_buy + ((c2_account_equity_buy * target_percent) / 100));
               c2_riskprice_buy = (c2_account_equity_buy - ((c2_account_equity_buy * risk_percent) / 100));
              }

            if(c2_place_order == true)
              {
               double safe_lot = CheckVolume(LotSize);
               if(CheckMargin(ORDER_TYPE_BUY, safe_lot) == true)
                 {
                  trade2.Buy(safe_lot, _Symbol);
                 }
              }
            c2_sellcycle = true;
            c2_check_for_buy_close = true;
            c2_Buycount++;
           }
         else
            if(close1 < down_envelope && open0 < down_envelope && c2_sellcycle == true)
              {
               c2_check_for_buy_close = false;
               double c2_key = open0;
               if(c2_key != c2_open_price)
                 {
                  c2_open_price = c2_key;
                  c2_place_order = true;
                 }
               else
                  c2_place_order = false;

               if(c2_Sellcount == 0)
                 {
                  c2_account_equity_sell = account_equity;
                  c2_targetprice_sell = (c2_account_equity_sell + ((c2_account_equity_sell * target_percent) / 100));
                  c2_riskprice_sell = (c2_account_equity_sell - ((c2_account_equity_sell * risk_percent) / 100));
                 }

               if(c2_place_order == true)
                 {
                  double safe_lot = CheckVolume(LotSize);
                  if(CheckMargin(ORDER_TYPE_SELL, safe_lot) == true)
                    {
                     trade2.Sell(safe_lot, _Symbol);
                    }
                 }
               c2_Buycycle = true;
               c2_check_for_sell_close = true;
               c2_Sellcount++;
              }
        }

      double c2_check_profit_Buy = MyAccountProfit_Buy(c2_MagicNumber);
      double c2_check_profit_Sell = MyAccountProfit_Sell(c2_MagicNumber);

      double c2_profit_Buy = c2_account_equity_buy + c2_check_profit_Buy;
      double c2_profit_Sell = c2_account_equity_sell + c2_check_profit_Sell;

      if((c2_profit_Sell >= c2_targetprice_sell || c2_profit_Sell <= c2_riskprice_sell) && c2_check_for_sell_close == true)
        {
         CloseAllByMagic(c2_MagicNumber, POSITION_TYPE_SELL, trade2);
         c2_sellcycle = false;
         c2_Sellcount = 0;
        }
      else
         if((c2_profit_Buy >= c2_targetprice_buy || c2_profit_Buy <= c2_riskprice_buy) && c2_check_for_buy_close == true)
           {
            CloseAllByMagic(c2_MagicNumber, POSITION_TYPE_BUY, trade2);
            c2_Buycycle = false;
            c2_Buycount = 0;
           }

      if(c2_profit_Buy <= c2_riskprice_buy && c2_check_for_buy_close == false)
        {
         CloseAllByMagic(c2_MagicNumber, POSITION_TYPE_BUY, trade2);
         c2_Buycount = 0;
        }
      else
         if(c2_profit_Sell <= c2_riskprice_sell && c2_check_for_sell_close == false)
           {
            CloseAllByMagic(c2_MagicNumber, POSITION_TYPE_SELL, trade2);
            c2_Sellcount = 0;
           }
     }

//+------------------------------------------------------------------+
//| Cycle 3 Execution
//+------------------------------------------------------------------+
   if(cycle3 == true)
     {
      double up_env3[], down_env3[];
      if(CopyBuffer(env3_handle, 0, 0, 1, up_env3) > 0 && CopyBuffer(env3_handle, 1, 0, 1, down_env3) > 0)
        {
         double up_envelope_c3 = up_env3[0];
         double down_envelope_c3 = down_env3[0];

         if(close1 > up_envelope_c3 && open0 > up_envelope_c3 && c3_Buycycle == true)
           {
            c3_check_for_sell_close = false;
            double c3_key = open0;
            if(c3_key != c3_open_price)
              {
               c3_open_price = c3_key;
               c3_place_order = true;
              }
            else
               c3_place_order = false;

            if(c3_Buycount == 0)
              {
               c3_account_equity_buy = account_equity;
               c3_targetprice_buy = (c3_account_equity_buy + ((c3_account_equity_buy * target_percent) / 100));
               c3_riskprice_buy = (c3_account_equity_buy - ((c3_account_equity_buy * risk_percent) / 100));
              }

            if(c3_place_order == true)
              {
               double safe_lot = CheckVolume(LotSize);
               if(CheckMargin(ORDER_TYPE_BUY, safe_lot) == true)
                 {
                  trade3.Buy(safe_lot, _Symbol);
                 }
              }
            c3_sellcycle = true;
            c3_check_for_buy_close = true;
            c3_Buycount++;
           }
         else
            if(close1 < down_envelope_c3 && open0 < down_envelope_c3 && c3_sellcycle == true)
              {
               c3_check_for_buy_close = false;
               double c3_key = open0;
               if(c3_key != c3_open_price)
                 {
                  c3_open_price = c3_key;
                  c3_place_order = true;
                 }
               else
                  c3_place_order = false;

               if(c3_Sellcount == 0)
                 {
                  c3_account_equity_sell = account_equity;
                  c3_targetprice_sell = (c3_account_equity_sell + ((c3_account_equity_sell * target_percent) / 100));
                  c3_riskprice_sell = (c3_account_equity_sell - ((c3_account_equity_sell * risk_percent) / 100));
                 }

               if(c3_place_order == true)
                 {
                  double safe_lot = CheckVolume(LotSize);
                  if(CheckMargin(ORDER_TYPE_SELL, safe_lot) == true)
                    {
                     trade3.Sell(safe_lot, _Symbol);
                    }
                 }
               c3_Buycycle = true;
               c3_check_for_sell_close = true;
               c3_Sellcount++;
              }
        }

      double c3_check_profit_Buy = MyAccountProfit_Buy(c3_MagicNumber);
      double c3_check_profit_Sell = MyAccountProfit_Sell(c3_MagicNumber);

      double c3_profit_Buy = c3_account_equity_buy + c3_check_profit_Buy;
      double c3_profit_Sell = c3_account_equity_sell + c3_check_profit_Sell;

      if((c3_profit_Sell >= c3_targetprice_sell || c3_profit_Sell <= c3_riskprice_sell) && c3_check_for_sell_close == true)
        {
         CloseAllByMagic(c3_MagicNumber, POSITION_TYPE_SELL, trade3);
         c3_sellcycle = false;
         c3_Sellcount = 0;
        }
      else
         if((c3_profit_Buy >= c3_targetprice_buy || c3_profit_Buy <= c3_riskprice_buy) && c3_check_for_buy_close == true)
           {
            CloseAllByMagic(c3_MagicNumber, POSITION_TYPE_BUY, trade3);
            c3_Buycycle = false;
            c3_Buycount = 0;
           }

      if(c3_profit_Buy <= c3_riskprice_buy && c3_check_for_buy_close == false)
        {
         CloseAllByMagic(c3_MagicNumber, POSITION_TYPE_BUY, trade3);
         c3_Buycount = 0;
        }
      else
         if(c3_profit_Sell <= c3_riskprice_sell && c3_check_for_sell_close == false)
           {
            CloseAllByMagic(c3_MagicNumber, POSITION_TYPE_SELL, trade3);
            c3_Sellcount = 0;
           }
     }
  }

//+------------------------------------------------------------------+
//| Custom Profit Functions adapted for MQL5                         |
//+------------------------------------------------------------------+
double MyAccountProfit_Buy(ulong MagicNumber)
  {
   double profit = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC) == MagicNumber)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
           {
            profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
           }
        }
     }
   return (profit);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MyAccountProfit_Sell(ulong MagicNumber)
  {
   double profit = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC) == MagicNumber)
        {
         if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
           {
            profit += PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
           }
        }
     }
   return (profit);
  }

//+------------------------------------------------------------------+
//| Helper Function for looping and closing matching positions       |
//+------------------------------------------------------------------+
void CloseAllByMagic(ulong MagicNumber, ENUM_POSITION_TYPE Type, CTrade &tradeObj)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong ticket = PositionGetTicket(i);
      if(PositionGetInteger(POSITION_MAGIC) == MagicNumber)
        {
         if(PositionGetInteger(POSITION_TYPE) == Type)
           {
            tradeObj.PositionClose(ticket);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

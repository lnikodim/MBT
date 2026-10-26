//+------------------------------------------------------------------+
//|                                                   CycleTrade.mq5 |
//|                                Copyright Amarnath Kondiyan Mohan |
//|     https://www.linkedin.com/in/amarnath-kondiyan-mohan-546293a/ |
//+------------------------------------------------------------------+
#property copyright "Amarnath Kondiyan Mohan"
#property link      "https://www.linkedin.com/in/amarnath-kondiyan-mohan-546293a/"
#property version   "1.01"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

CTrade         trade;
CPositionInfo  m_position;
CSymbolInfo    m_symbol;

input bool cycle1 = true;
input bool cycle2 = false;
input bool cycle3 = false;
input bool cycle4 = false;

input string C1 = "--- Cycle1 Settings -------------- ";
input int MAPeriod = 3;
input int MA_shift = 0;
input ENUM_MA_METHOD MA_method = MODE_EMA;
input ENUM_APPLIED_PRICE MA_appliedprice = PRICE_HIGH;
input bool MA1_Enable = false;
input ENUM_TIMEFRAMES MA_TimeFrame = PERIOD_CURRENT;

input int MA2Period = 20;
input int MA2_shift = 0;
input ENUM_MA_METHOD MA2_method = MODE_EMA;
input ENUM_APPLIED_PRICE MA2_appliedprice = PRICE_LOW;
input bool MA2_Enable = false;
input ENUM_TIMEFRAMES MA2_TimeFrame = PERIOD_CURRENT;

input int MA3Period = 50;
input int MA3_shift = 0;
input ENUM_MA_METHOD MA3_method = MODE_EMA;
input ENUM_APPLIED_PRICE MA3_appliedprice = PRICE_MEDIAN;
input ENUM_TIMEFRAMES MA3_TimeFrame = PERIOD_CURRENT;
input bool MA3_Enable = false;

input int RSI_Period = 200;
input ENUM_APPLIED_PRICE RSI_Price = PRICE_CLOSE;
input ENUM_TIMEFRAMES RSI_TF = PERIOD_CURRENT;
input int RSI_Buy_Level = 30;
input int RSI_Sell_Level = 70;
input bool RSI_Enable = false;

input int WPR_Period = 200;
input ENUM_TIMEFRAMES WPR_TF = PERIOD_CURRENT;
input int WPR_Buy_Level = -80;
input int WPR_Sell_Level = -20;
input bool WPR_Enable = true;

input double LotSize = 0.01;
input bool AutoLots = false;
input double Lots_Risk = 3;
input double Account_Risk_percent = 99;
input double target_percent = 1.0;
input double target_amount  = 0;

input bool Reverse_Signals = false;
input ulong c1_MagicNumber = 111;

input string C2 = "--- Cycle2 Settings --------------";
input int InpMAPeriod2 = 25;
input int InpMAShift2 = 0;
input ENUM_MA_METHOD InpMAMethod2 = MODE_EMA;
input ENUM_APPLIED_PRICE InpAppliedPrice2 = PRICE_CLOSE;
input double c2_InpDeviation = 0.3;
input double LotSize2 = 0.01;
input bool AutoLots2 = false;
input double Lots_Risk2 = 3;
input double Account_Risk_percent2 = 99;
input double target_percent2 = 1.0;
input double target_amount2  = 0;
input ENUM_TIMEFRAMES TimeFrame2 = PERIOD_CURRENT;
input bool Reverse_Signals2 = false;
input ulong c2_MagicNumber = 333;

input string C3 = "--- Cycle3 Settings --------------";
input int InpMAPeriod3 = 25;
input int InpMAShift3 = 0;
input ENUM_MA_METHOD InpMAMethod3 = MODE_EMA;
input ENUM_APPLIED_PRICE InpAppliedPrice3 = PRICE_CLOSE;
input double c3_InpDeviation = 0.7;
input double LotSize3 = 1.0;
input bool AutoLots3 = false;
input double Lots_Risk3 = 3;
input double Account_Risk_percent3 = 99;
input double target_percent3 = 0.0;
input double target_amount3  = 350;
input ENUM_TIMEFRAMES TimeFrame3 = PERIOD_CURRENT;
input bool Reverse_Signals3 = false;
input ulong c3_MagicNumber = 555;

input string C4 = "--- Cycle4 Settings --------------";
input int InpMAPeriod4 = 99;
input int InpMAShift4 = 0;
input ENUM_MA_METHOD InpMAMethod4 = MODE_EMA;
input ENUM_APPLIED_PRICE InpAppliedPrice4 = PRICE_CLOSE;
input double c4_InpDeviation = 0.7;
input int Distance = 10;
input double LotSize4 = 1.0;
input bool AutoLots4 = false;
input double Lots_Risk4 = 3;
input double Account_Risk_percent4 = 99;
input double target_percent4 = 0.0;
input double target_amount4  = 350;
input ENUM_TIMEFRAMES TimeFrame4 = PERIOD_CURRENT;
input bool Reverse_Signals4 = false;
input ulong c4_MagicNumber = 777;

input string s111 = "--- Basic Settings -------------- ";
input ulong Slippage = 5;

// Global Variables and Handles
double UsePoint;
ulong UseSlippage;

int h_ma1, h_ma2, h_ma3, h_rsi, h_wpr;
int h_env2, h_env3, h_env4;

// Cycle Settings Trackers
double c1_account_equity_buy, c1_targetprice_buy, c1_riskprice_buy;
double c1_account_equity_sell, c1_targetprice_sell, c1_riskprice_sell;
bool c1_Buycycle=true, c1_sellcycle=true, c1_check_for_buy_close=false, c1_check_for_sell_close=false;
double c1_open_price;
bool c1_place_order=false;
int c1_Buycount=0, c1_Sellcount=0;

double c2_account_equity_buy, c2_targetprice_buy, c2_riskprice_buy;
double c2_account_equity_sell, c2_targetprice_sell, c2_riskprice_sell;
bool c2_Buycycle=true, c2_sellcycle=true, c2_check_for_buy_close=false, c2_check_for_sell_close=false;
double c2_open_price;
bool c2_place_order=false;
int c2_Buycount=0, c2_Sellcount=0;

double c3_account_equity_buy, c3_targetprice_buy, c3_riskprice_buy;
double c3_account_equity_sell, c3_targetprice_sell, c3_riskprice_sell;
bool c3_Buycycle=true, c3_sellcycle=true, c3_check_for_buy_close=false, c3_check_for_sell_close=false;
double c3_open_price;
bool c3_place_order=false;
int c3_Buycount=0, c3_Sellcount=0;

double c4_account_equity_buy, c4_targetprice_buy, c4_riskprice_buy;
double c4_account_equity_sell, c4_targetprice_sell, c4_riskprice_sell;
bool c4_Buycycle=true, c4_sellcycle=true, c4_check_for_buy_close=false, c4_check_for_sell_close=false;
double c4_open_price;
bool c4_place_order=false;
int c4_Buycount=0, c4_Sellcount=0;

//+------------------------------------------------------------------+
//| Pre-Trade Margin Check (Codebase Validator Safe)                 |
//+------------------------------------------------------------------+
bool IsMarginSufficient(ENUM_ORDER_TYPE type, double lots)
  {
   double required_margin = 0.0;
   double price = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(OrderCalcMargin(type, _Symbol, lots, price, required_margin))
     {
      if(AccountInfoDouble(ACCOUNT_MARGIN_FREE) >= required_margin)
        {
         return true;
        }
     }
   return false;
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!m_symbol.Name(_Symbol))
      return(INIT_FAILED);
   m_symbol.Refresh();
   trade.SetExpertMagicNumber(0);

   UsePoint = m_symbol.Point();
   UseSlippage = GetSlippage(_Symbol, (int)Slippage);

   if(cycle1)
     {
      if(MA1_Enable)
         h_ma1 = iMA(_Symbol, MA_TimeFrame, MAPeriod, MA_shift, MA_method, MA_appliedprice);
      if(MA2_Enable)
         h_ma2 = iMA(_Symbol, MA2_TimeFrame, MA2Period, MA2_shift, MA2_method, MA2_appliedprice);
      if(MA3_Enable)
         h_ma3 = iMA(_Symbol, MA3_TimeFrame, MA3Period, MA3_shift, MA3_method, MA3_appliedprice);
      if(RSI_Enable)
         h_rsi = iRSI(_Symbol, RSI_TF, RSI_Period, RSI_Price);
      if(WPR_Enable)
         h_wpr = iWPR(_Symbol, WPR_TF, WPR_Period);
     }

   if(cycle2)
      h_env2 = iEnvelopes(_Symbol, TimeFrame2, InpMAPeriod2, InpMAShift2, InpMAMethod2, InpAppliedPrice2, c2_InpDeviation);
   if(cycle3)
      h_env3 = iEnvelopes(_Symbol, TimeFrame3, InpMAPeriod3, InpMAShift3, InpMAMethod3, InpAppliedPrice3, c3_InpDeviation);
   if(cycle4)
      h_env4 = iEnvelopes(_Symbol, TimeFrame4, InpMAPeriod4, InpMAShift4, InpMAMethod4, InpAppliedPrice4, c4_InpDeviation);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(h_ma1 != INVALID_HANDLE)
      IndicatorRelease(h_ma1);
   if(h_ma2 != INVALID_HANDLE)
      IndicatorRelease(h_ma2);
   if(h_ma3 != INVALID_HANDLE)
      IndicatorRelease(h_ma3);
   if(h_rsi != INVALID_HANDLE)
      IndicatorRelease(h_rsi);
   if(h_wpr != INVALID_HANDLE)
      IndicatorRelease(h_wpr);
   if(h_env2 != INVALID_HANDLE)
      IndicatorRelease(h_env2);
   if(h_env3 != INVALID_HANDLE)
      IndicatorRelease(h_env3);
   if(h_env4 != INVALID_HANDLE)
      IndicatorRelease(h_env4);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   m_symbol.RefreshRates();
   double Ask = m_symbol.Ask();
   double Bid = m_symbol.Bid();

   double Open[], Close[];
   ArraySetAsSeries(Open, true);
   ArraySetAsSeries(Close, true);

   if(CopyOpen(_Symbol, PERIOD_CURRENT, 0, 2, Open) < 2)
      return;
   if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 2, Close) < 2)
      return;

//--- CYCLE 1
   if(cycle1)
     {
      double ma1_arr[1], ma2_arr[1], ma3_arr[1], rsi_arr[1], wpr_arr[1];
      double MA = 0, MA2 = 0, MA3 = 0, rsi = 0, wpr = 0;

      if(MA1_Enable && CopyBuffer(h_ma1, 0, 0, 1, ma1_arr) > 0)
         MA = ma1_arr[0];
      if(MA2_Enable && CopyBuffer(h_ma2, 0, 0, 1, ma2_arr) > 0)
         MA2 = ma2_arr[0];
      if(MA3_Enable && CopyBuffer(h_ma3, 0, 0, 1, ma3_arr) > 0)
         MA3 = ma3_arr[0];
      if(RSI_Enable && CopyBuffer(h_rsi, 0, 0, 1, rsi_arr) > 0)
         rsi = rsi_arr[0];
      if(WPR_Enable && CopyBuffer(h_wpr, 0, 0, 1, wpr_arr) > 0)
         wpr = wpr_arr[0];

      int c1_signal = 0;

      if(MA1_Enable)
        {
         if(Close[1] > MA && Open[0] > MA)
            c1_signal = (c1_signal == 0) ? 1 : 0;
         if(Close[1] < MA && Open[0] < MA)
            c1_signal = (c1_signal == 0) ? 2 : 0;
        }
      if(MA2_Enable)
        {
         if(Close[1] > MA2 && Open[0] > MA2)
            c1_signal = (c1_signal == 0) ? 1 : 0;
         if(Close[1] < MA2 && Open[0] < MA2)
            c1_signal = (c1_signal == 0) ? 2 : 0;
        }
      if(MA3_Enable)
        {
         if(Close[1] > MA3 && Open[0] > MA3)
            c1_signal = (c1_signal == 0) ? 1 : 0;
         if(Close[1] < MA3 && Open[0] < MA3)
            c1_signal = (c1_signal == 0) ? 2 : 0;
        }
      if(RSI_Enable && rsi > 0)
        {
         if(rsi < RSI_Buy_Level)
            c1_signal = (c1_signal == 0) ? 1 : 0;
         if(rsi > RSI_Sell_Level)
            c1_signal = (c1_signal == 0) ? 2 : 0;
        }
      if(WPR_Enable && wpr != 0)
        {
         if(wpr < WPR_Buy_Level)
            c1_signal = (c1_signal == 0) ? 1 : 0;
         if(wpr > WPR_Sell_Level)
            c1_signal = (c1_signal == 0) ? 2 : 0;
        }

      if(Reverse_Signals && c1_signal != 0)
         c1_signal = (c1_signal == 1) ? 2 : 1;

      if(c1_signal == 1 && c1_Buycycle)
        {
         c1_check_for_sell_close = false;
         if(Open[0] != c1_open_price)
           {
            c1_open_price = Open[0];
            c1_place_order = true;
           }
         else
            c1_place_order = false;

         if(c1_Buycount == 0)
           {
            c1_account_equity_buy = AccountInfoDouble(ACCOUNT_EQUITY);
            c1_targetprice_buy = target_amount != 0 ? (c1_account_equity_buy + target_amount) : (c1_account_equity_buy + ((c1_account_equity_buy * target_percent) / 1000));
            c1_riskprice_buy = (c1_account_equity_buy - ((c1_account_equity_buy * Account_Risk_percent) / 1000));
           }

         if(c1_place_order)
           {
            double c1_lot = getLots(1);
            if(IsMarginSufficient(ORDER_TYPE_BUY, c1_lot))
              {
               trade.SetExpertMagicNumber(c1_MagicNumber);
               trade.SetDeviationInPoints(UseSlippage);
               if(trade.Buy(c1_lot, _Symbol, Ask))
                 {
                  c1_sellcycle = true;
                  c1_check_for_buy_close = true;
                  c1_Buycount++;
                 }
              }
           }
        }
      else
         if(c1_signal == 2 && c1_sellcycle)
           {
            c1_check_for_buy_close = false;
            if(Open[0] != c1_open_price)
              {
               c1_open_price = Open[0];
               c1_place_order = true;
              }
            else
               c1_place_order = false;

            if(c1_Sellcount == 0)
              {
               c1_account_equity_sell = AccountInfoDouble(ACCOUNT_EQUITY);
               c1_targetprice_sell = target_amount != 0 ? (c1_account_equity_sell + target_amount) : (c1_account_equity_sell + ((c1_account_equity_sell * target_percent) / 100));
               c1_riskprice_sell = (c1_account_equity_sell - ((c1_account_equity_sell * Account_Risk_percent) / 100));
              }

            if(c1_place_order)
              {
               double c1_lot = getLots(1);
               if(IsMarginSufficient(ORDER_TYPE_SELL, c1_lot))
                 {
                  trade.SetExpertMagicNumber(c1_MagicNumber);
                  trade.SetDeviationInPoints(UseSlippage);
                  if(trade.Sell(c1_lot, _Symbol, Bid))
                    {
                     c1_Buycycle = true;
                     c1_check_for_sell_close = true;
                     c1_Sellcount++;
                    }
                 }
              }
           }

      double c1_profit_Buy = c1_account_equity_buy + MyAccountProfit_Buy(c1_MagicNumber);
      double c1_profit_Sell = c1_account_equity_sell + MyAccountProfit_Sell(c1_MagicNumber);

      if((c1_profit_Sell >= c1_targetprice_sell || c1_profit_Sell <= c1_riskprice_sell))
        {
         ClosePositions(c1_MagicNumber, POSITION_TYPE_SELL);
         if(c1_check_for_sell_close)
            c1_sellcycle = false;
         c1_Sellcount = 0;
        }
      if((c1_profit_Buy >= c1_targetprice_buy || c1_profit_Buy <= c1_riskprice_buy))
        {
         ClosePositions(c1_MagicNumber, POSITION_TYPE_BUY);
         if(c1_check_for_buy_close)
            c1_Buycycle = false;
         c1_Buycount = 0;
        }
     }

//--- CYCLE 2
   if(cycle2)
     {
      double up_env2[1], dn_env2[1];
      CopyBuffer(h_env2, UPPER_LINE, 0, 1, up_env2);
      CopyBuffer(h_env2, LOWER_LINE, 0, 1, dn_env2);

      int c2_signal = 0;
      if(Close[1] > up_env2[0] && Open[0] > up_env2[0])
         c2_signal = 1;
      else
         if(Close[1] < dn_env2[0] && Open[0] < dn_env2[0])
            c2_signal = 2;

      if(Reverse_Signals2 && c2_signal != 0)
         c2_signal = (c2_signal == 1) ? 2 : 1;

      if(c2_signal == 1 && c2_Buycycle)
        {
         c2_check_for_sell_close = false;
         if(Open[0] != c2_open_price)
           {
            c2_open_price = Open[0];
            c2_place_order = true;
           }
         else
            c2_place_order = false;

         if(c2_Buycount == 0)
           {
            c2_account_equity_buy = AccountInfoDouble(ACCOUNT_EQUITY);
            c2_targetprice_buy = target_amount2 != 0 ? (c2_account_equity_buy + target_amount2) : (c2_account_equity_buy + ((c2_account_equity_buy * target_percent2) / 100));
            c2_riskprice_buy = (c2_account_equity_buy - ((c2_account_equity_buy * Account_Risk_percent2) / 100));
           }

         if(c2_place_order)
           {
            double c2_lot = getLots(2);
            if(IsMarginSufficient(ORDER_TYPE_BUY, c2_lot))
              {
               trade.SetExpertMagicNumber(c2_MagicNumber);
               trade.SetDeviationInPoints(UseSlippage);
               if(trade.Buy(c2_lot, _Symbol, Ask))
                 {
                  c2_sellcycle = true;
                  c2_check_for_buy_close = true;
                  c2_Buycount++;
                 }
              }
           }
        }
      else
         if(c2_signal == 2 && c2_sellcycle)
           {
            c2_check_for_buy_close = false;
            if(Open[0] != c2_open_price)
              {
               c2_open_price = Open[0];
               c2_place_order = true;
              }
            else
               c2_place_order = false;

            if(c2_Sellcount == 0)
              {
               c2_account_equity_sell = AccountInfoDouble(ACCOUNT_EQUITY);
               c2_targetprice_sell = target_amount2 != 0 ? (c2_account_equity_sell + target_amount2) : (c2_account_equity_sell + ((c2_account_equity_sell * target_percent2) / 100));
               c2_riskprice_sell = (c2_account_equity_sell - ((c2_account_equity_sell * Account_Risk_percent2) / 100));
              }

            if(c2_place_order)
              {
               double c2_lot = getLots(2);
               if(IsMarginSufficient(ORDER_TYPE_SELL, c2_lot))
                 {
                  trade.SetExpertMagicNumber(c2_MagicNumber);
                  trade.SetDeviationInPoints(UseSlippage);
                  if(trade.Sell(c2_lot, _Symbol, Bid))
                    {
                     c2_Buycycle = true;
                     c2_check_for_sell_close = true;
                     c2_Sellcount++;
                    }
                 }
              }
           }

      double c2_profit_Buy = c2_account_equity_buy + MyAccountProfit_Buy(c2_MagicNumber);
      double c2_profit_Sell = c2_account_equity_sell + MyAccountProfit_Sell(c2_MagicNumber);

      if((c2_profit_Sell >= c2_targetprice_sell || c2_profit_Sell <= c2_riskprice_sell))
        {
         ClosePositions(c2_MagicNumber, POSITION_TYPE_SELL);
         if(c2_check_for_sell_close)
            c2_sellcycle = false;
         c2_Sellcount = 0;
        }
      if((c2_profit_Buy >= c2_targetprice_buy || c2_profit_Buy <= c2_riskprice_buy))
        {
         ClosePositions(c2_MagicNumber, POSITION_TYPE_BUY);
         if(c2_check_for_buy_close)
            c2_Buycycle = false;
         c2_Buycount = 0;
        }
     }

//--- CYCLE 3
   if(cycle3)
     {
      double up_env3[1], dn_env3[1];
      CopyBuffer(h_env3, UPPER_LINE, 0, 1, up_env3);
      CopyBuffer(h_env3, LOWER_LINE, 0, 1, dn_env3);

      int c3_signal = 0;
      if(Close[1] > up_env3[0] && Open[0] > up_env3[0])
         c3_signal = 2;
      else
         if(Close[1] < dn_env3[0] && Open[0] < dn_env3[0])
            c3_signal = 1;

      if(Reverse_Signals3 && c3_signal != 0)
         c3_signal = (c3_signal == 1) ? 2 : 1;

      if(c3_signal == 1 && c3_Buycycle)
        {
         c3_check_for_sell_close = false;
         if(Open[0] != c3_open_price)
           {
            c3_open_price = Open[0];
            c3_place_order = true;
           }
         else
            c3_place_order = false;

         if(c3_Buycount == 0)
           {
            c3_account_equity_buy = AccountInfoDouble(ACCOUNT_EQUITY);
            c3_targetprice_buy = target_amount3 != 0 ? (c3_account_equity_buy + target_amount3) : (c3_account_equity_buy + ((c3_account_equity_buy * target_percent3) / 100));
            c3_riskprice_buy = (c3_account_equity_buy - ((c3_account_equity_buy * Account_Risk_percent3) / 100));
           }

         if(c3_place_order)
           {
            double c3_lot = getLots(3);
            if(IsMarginSufficient(ORDER_TYPE_BUY, c3_lot))
              {
               trade.SetExpertMagicNumber(c3_MagicNumber);
               trade.SetDeviationInPoints(UseSlippage);
               if(trade.Buy(c3_lot, _Symbol, Ask))
                 {
                  c3_sellcycle = true;
                  c3_check_for_buy_close = true;
                  c3_Buycount++;
                 }
              }
           }
        }
      else
         if(c3_signal == 2 && c3_sellcycle)
           {
            c3_check_for_buy_close = false;
            if(Open[0] != c3_open_price)
              {
               c3_open_price = Open[0];
               c3_place_order = true;
              }
            else
               c3_place_order = false;

            if(c3_Sellcount == 0)
              {
               c3_account_equity_sell = AccountInfoDouble(ACCOUNT_EQUITY);
               c3_targetprice_sell = target_amount3 != 0 ? (c3_account_equity_sell + target_amount3) : (c3_account_equity_sell + ((c3_account_equity_sell * target_percent3) / 100));
               c3_riskprice_sell = (c3_account_equity_sell - ((c3_account_equity_sell * Account_Risk_percent3) / 100));
              }

            if(c3_place_order)
              {
               double c3_lot = getLots(3);
               if(IsMarginSufficient(ORDER_TYPE_SELL, c3_lot))
                 {
                  trade.SetExpertMagicNumber(c3_MagicNumber);
                  trade.SetDeviationInPoints(UseSlippage);
                  if(trade.Sell(c3_lot, _Symbol, Bid))
                    {
                     c3_Buycycle = true;
                     c3_check_for_sell_close = true;
                     c3_Sellcount++;
                    }
                 }
              }
           }

      double c3_profit_Buy = c3_account_equity_buy + MyAccountProfit_Buy(c3_MagicNumber);
      double c3_profit_Sell = c3_account_equity_sell + MyAccountProfit_Sell(c3_MagicNumber);

      if((c3_profit_Sell >= c3_targetprice_sell || c3_profit_Sell <= c3_riskprice_sell))
        {
         ClosePositions(c3_MagicNumber, POSITION_TYPE_SELL);
         if(c3_check_for_sell_close)
            c3_sellcycle = false;
         c3_Sellcount = 0;
        }
      if((c3_profit_Buy >= c3_targetprice_buy || c3_profit_Buy <= c3_riskprice_buy))
        {
         ClosePositions(c3_MagicNumber, POSITION_TYPE_BUY);
         if(c3_check_for_buy_close)
            c3_Buycycle = false;
         c3_Buycount = 0;
        }
     }

//--- CYCLE 4
   if(cycle4)
     {
      double up_env4[2], dn_env4[2];
      CopyBuffer(h_env4, UPPER_LINE, 0, 2, up_env4);
      CopyBuffer(h_env4, LOWER_LINE, 0, 2, dn_env4);

      int c4_signal = 0;
      if(dn_env4[1] - Close[1] > Distance * UsePoint && dn_env4[0] - Bid > Distance * UsePoint)
         c4_signal = 1;
      else
         if(Close[1] - up_env4[1] > Distance * UsePoint && Bid - up_env4[0] > Distance * UsePoint)
            c4_signal = 2;

      if(Reverse_Signals4 && c4_signal != 0)
         c4_signal = (c4_signal == 1) ? 2 : 1;

      if(c4_signal == 1 && c4_Buycycle)
        {
         c4_check_for_sell_close = false;
         if(Open[0] != c4_open_price)
           {
            c4_open_price = Open[0];
            c4_place_order = true;
           }
         else
            c4_place_order = false;

         if(c4_Buycount == 0)
           {
            c4_account_equity_buy = AccountInfoDouble(ACCOUNT_EQUITY);
            c4_targetprice_buy = target_amount4 != 0 ? (c4_account_equity_buy + target_amount4) : (c4_account_equity_buy + ((c4_account_equity_buy * target_percent4) / 100));
            c4_riskprice_buy = (c4_account_equity_buy - ((c4_account_equity_buy * Account_Risk_percent4) / 100));
           }

         if(c4_place_order)
           {
            double c4_lot = getLots(4);
            if(IsMarginSufficient(ORDER_TYPE_BUY, c4_lot))
              {
               trade.SetExpertMagicNumber(c4_MagicNumber);
               trade.SetDeviationInPoints(UseSlippage);
               if(trade.Buy(c4_lot, _Symbol, Ask))
                 {
                  c4_sellcycle = true;
                  c4_check_for_buy_close = true;
                  c4_Buycount++;
                 }
              }
           }
        }
      else
         if(c4_signal == 2 && c4_sellcycle)
           {
            c4_check_for_sell_close = false;
            if(Open[0] != c4_open_price)
              {
               c4_open_price = Open[0];
               c4_place_order = true;
              }
            else
               c4_place_order = false;

            if(c4_Sellcount == 0)
              {
               c4_account_equity_sell = AccountInfoDouble(ACCOUNT_EQUITY);
               c4_targetprice_sell = target_amount4 != 0 ? (c4_account_equity_sell + target_amount4) : (c4_account_equity_sell + ((c4_account_equity_sell * target_percent4) / 100));
               c4_riskprice_sell = (c4_account_equity_sell - ((c4_account_equity_sell * Account_Risk_percent4) / 100));
              }

            if(c4_place_order)
              {
               double c4_lot = getLots(4);
               if(IsMarginSufficient(ORDER_TYPE_SELL, c4_lot))
                 {
                  trade.SetExpertMagicNumber(c4_MagicNumber);
                  trade.SetDeviationInPoints(UseSlippage);
                  if(trade.Sell(c4_lot, _Symbol, Bid))
                    {
                     c4_Buycycle = true;
                     c4_check_for_sell_close = true;
                     c4_Sellcount++;
                    }
                 }
              }
           }

      double c4_profit_Buy = c4_account_equity_buy + MyAccountProfit_Buy(c4_MagicNumber);
      double c4_profit_Sell = c4_account_equity_sell + MyAccountProfit_Sell(c4_MagicNumber);

      if((c4_profit_Sell >= c4_targetprice_sell || c4_profit_Sell <= c4_riskprice_sell))
        {
         ClosePositions(c4_MagicNumber, POSITION_TYPE_SELL);
         if(c4_check_for_sell_close)
            c4_sellcycle = false;
         c4_Sellcount = 0;
        }
      if((c4_profit_Buy >= c4_targetprice_buy || c4_profit_Buy <= c4_riskprice_buy))
        {
         ClosePositions(c4_MagicNumber, POSITION_TYPE_BUY);
         if(c4_check_for_buy_close)
            c4_Buycycle = false;
         c4_Buycount = 0;
        }
     }
  }

//+------------------------------------------------------------------+
//| Helper Functions                                                 |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MyAccountProfit_Buy(ulong MagicNumber)
  {
   double profit = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Magic() == MagicNumber && m_position.PositionType() == POSITION_TYPE_BUY)
           {
            profit += m_position.Profit() + m_position.Swap();
           }
        }
     }
   return profit;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double MyAccountProfit_Sell(ulong MagicNumber)
  {
   double profit = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Magic() == MagicNumber && m_position.PositionType() == POSITION_TYPE_SELL)
           {
            profit += m_position.Profit() + m_position.Swap();
           }
        }
     }
   return profit;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ClosePositions(ulong magic, ENUM_POSITION_TYPE type)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(m_position.SelectByIndex(i))
        {
         if(m_position.Magic() == magic && m_position.PositionType() == type)
           {
            trade.PositionClose(m_position.Ticket());
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int GetSlippage(string currency, int slippagePips)
  {
   int calcDigits = (int)SymbolInfoInteger(currency, SYMBOL_DIGITS);
   if(calcDigits == 2 || calcDigits == 4)
      return slippagePips;
   else
      if(calcDigits == 3 || calcDigits == 5)
         return slippagePips * 10;
   return slippagePips;
  }

//+------------------------------------------------------------------+
//| Robust Lot Calculation for MQL5 Codebase Compatibility           |
//+------------------------------------------------------------------+
double getLots(int c)
  {
   double risk = 0, manualLot = 0;
   bool autoL = false;

   if(c == 1)
     {
      autoL = AutoLots;
      manualLot = LotSize;
      risk = Lots_Risk;
     }
   else
      if(c == 2)
        {
         autoL = AutoLots2;
         manualLot = LotSize2;
         risk = Lots_Risk2;
        }
      else
         if(c == 3)
           {
            autoL = AutoLots3;
            manualLot = LotSize3;
            risk = Lots_Risk3;
           }
         else
            if(c == 4)
              {
               autoL = AutoLots4;
               manualLot = LotSize4;
               risk = Lots_Risk4;
              }

   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   double targetVolume = manualLot;

   if(autoL)
     {
      double margin;
      if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, 1.0, SymbolInfoDouble(_Symbol, SYMBOL_ASK), margin))
        {
         if(risk > 0 && margin > 0)
           {
            targetVolume = AccountInfoDouble(ACCOUNT_MARGIN_FREE) * risk / 100.0 / margin;
           }
        }
     }

   double lots = MathRound(targetVolume / step) * step;
   lots = MathMax(minLot, MathMin(lots, maxLot));

   int stepDigits = 2;
   if(step == 0.1)
      stepDigits = 1;
   else
      if(step == 0.001)
         stepDigits = 3;
      else
         if(step == 1.0)
            stepDigits = 0;

   return NormalizeDouble(lots, stepDigits);
  }
//+------------------------------------------------------------------+

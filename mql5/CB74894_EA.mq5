//+------------------------------------------------------------------+
//|                                            Supertrend_EA_AKM.mq5 |
//|                                          Amarnath Kondiyan Mohan |
//+------------------------------------------------------------------+
#property copyright "Amarnath Kondiyan Mohan"
#property link      "https://www.linkedin.com/in/amarnath-kondiyan-mohan-546293a/"
#property version   "5.20"
#property description "Continuous Hedging - Independent TP, Global SL & HTF Filter"

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>
#include <Trade/AccountInfo.mqh>

enum ENUM_TARGET_MODE
  {
   TARGET_PERCENT,
   TARGET_FIXED_DOLLAR
  };

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input int               InpATRPeriod       = 10;
input double            InpATRMultiplier   = 3.0;
input bool              InpChangeATRMethod = true;

//--- Higher Timeframe Filter Settings ---
input bool              InpUseHTFFilter    = true; // Enable Higher Timeframe trend filter
input ENUM_TIMEFRAMES   InpHTF             = PERIOD_H4; // Higher Timeframe to check

input double            InpLotSize         = 0.01; // Lot size to open on every single bar

//--- Basket Target Management ---
input ENUM_TARGET_MODE  InpTargetMode      = TARGET_PERCENT;
input double            InpMaxRiskValue    = 99.0; // Global Max Loss for ALL open positions combined
input double            InpTakeProfitValue = 1.0; // Independent Target Profit for each basket type

input int               InpMagicNumber     = 202306;
input int               InpSlippage        = 30;

//+------------------------------------------------------------------+
//| Global objects                                                   |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  position;
CAccountInfo   account;
datetime       lastProcessedBarTime = 0;
int            atrCurrentHandle = INVALID_HANDLE;
int            atrHTFHandle     = INVALID_HANDLE;
bool           isNettingAccount = false;

//+------------------------------------------------------------------+
//| Initialize                                                       |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpSlippage);

   int filling = (int)SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);
   if((filling & SYMBOL_FILLING_FOK) != 0)
      trade.SetTypeFilling(ORDER_FILLING_FOK);
   else
      if((filling & SYMBOL_FILLING_IOC) != 0)
         trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
         trade.SetTypeFilling(ORDER_FILLING_RETURN);

   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_NETTING ||
      AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_EXCHANGE)
     {
      isNettingAccount = true;
      Print("WARNING: Netting account detected. Strategy optimized for Hedging, but proceeding for validation.");
     }

   if(InpChangeATRMethod)
     {
      atrCurrentHandle = iATR(_Symbol, _Period, InpATRPeriod);
      if(atrCurrentHandle == INVALID_HANDLE)
        {
         Print("Failed to create Current ATR handle. Error: ", GetLastError());
         return INIT_FAILED;
        }

      if(InpUseHTFFilter)
        {
         atrHTFHandle = iATR(_Symbol, InpHTF, InpATRPeriod);
         if(atrHTFHandle == INVALID_HANDLE)
           {
            Print("Failed to create HTF ATR handle. Error: ", GetLastError());
            return INIT_FAILED;
           }
        }
     }

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Deinitialize                                                     |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(atrCurrentHandle != INVALID_HANDLE)
      IndicatorRelease(atrCurrentHandle);
   if(atrHTFHandle != INVALID_HANDLE)
      IndicatorRelease(atrHTFHandle);
  }

//+------------------------------------------------------------------+
//| Get Supertrend Trend Direction for a Specific Timeframe          |
//+------------------------------------------------------------------+
bool CalculateSupertrend(ENUM_TIMEFRAMES tf, int handle, int &out_trend)
  {
   out_trend = 0;
   int barsToCalc = 1500;
   int totalBars = Bars(_Symbol, tf);

   if(totalBars < barsToCalc)
      barsToCalc = totalBars;
   if(barsToCalc < InpATRPeriod + 5)
      return false;

   double high[], low[], close[], atrValues[];

   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(atrValues, true);

   int copiedClose = CopyClose(_Symbol, tf, 0, barsToCalc, close);
   int copiedHigh  = CopyHigh(_Symbol, tf, 0, barsToCalc, high);
   int copiedLow   = CopyLow(_Symbol, tf, 0, barsToCalc, low);
   if(copiedClose < InpATRPeriod + 5 || copiedHigh < InpATRPeriod + 5 || copiedLow < InpATRPeriod + 5)
      return false;
   int limit = MathMin(copiedClose, MathMin(copiedHigh, copiedLow));

   if(InpChangeATRMethod)
     {
      int copiedATR = CopyBuffer(handle, 0, 0, barsToCalc, atrValues);
      if(copiedATR < InpATRPeriod + 5)
         return false;
      limit = MathMin(limit, copiedATR);
     }

   double up_prev = 0, dn_prev = 0;
   int trend_prev = 1;
   int trendArray[];
   ArrayResize(trendArray, limit);
   ArrayInitialize(trendArray, 0);
   for(int i = limit - 1; i >= 0; i--)
     {
      double src = (high[i] + low[i]) / 2.0;
      double atr = 0;

      if(InpChangeATRMethod)
         atr = atrValues[i];
      else
        {
         if(i + InpATRPeriod >= limit)
            continue;
         double sumTR = 0.0;
         for(int k = 0; k < InpATRPeriod; k++)
           {
            double th = high[i+k];
            double tl = low[i+k];
            double tpc = close[i+k+1];
            sumTR += (MathMax(th, tpc) - MathMin(tl, tpc));
           }
         atr = sumTR / InpATRPeriod;
        }

      double up_basic = src - (InpATRMultiplier * atr);
      double dn_basic = src + (InpATRMultiplier * atr);
      double up_new, dn_new;
      int trend_current;
      if(up_prev == 0 && dn_prev == 0)
        {
         up_new = up_basic;
         dn_new = dn_basic;
         trend_current = (close[i] > up_new) ? 1 : -1;
        }
      else
        {
         double prev_close = close[i+1];
         if(prev_close > up_prev)
            up_new = MathMax(up_basic, up_prev);
         else
            up_new = up_basic;
         if(prev_close < dn_prev)
            dn_new = MathMin(dn_basic, dn_prev);
         else
            dn_new = dn_basic;
         if(trend_prev == -1 && close[i] > dn_prev)
            trend_current = 1;
         else
            if(trend_prev == 1 && close[i] < up_prev)
               trend_current = -1;
         else
               trend_current = trend_prev;
        }
      trendArray[i] = trend_current;
      up_prev = up_new;
      dn_prev = dn_new;
      trend_prev = trend_current;
     }

   out_trend = trendArray[1];
   return true;
  }

//+------------------------------------------------------------------+
//| Check Floating Equity for Real-Time Basket Closure               |
//+------------------------------------------------------------------+
void CheckBasketClosure()
  {
   if(PositionsTotal() == 0)
      return;

   double buyFloatingProfit = 0;
   double sellFloatingProfit = 0;
   int buyCount = 0;
   int sellCount = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(position.SelectByIndex(i) && position.Symbol() == _Symbol && position.Magic() == InpMagicNumber)
        {
         double tradeProfit = position.Profit() + position.Swap() + position.Commission();
         if(position.PositionType() == POSITION_TYPE_BUY)
           {
            buyFloatingProfit += tradeProfit;
            buyCount++;
           }
         else
            if(position.PositionType() == POSITION_TYPE_SELL)
              {
               sellFloatingProfit += tradeProfit;
               sellCount++;
              }
        }
     }

   int totalCount = buyCount + sellCount;
   if(totalCount == 0)
      return;

   double totalFloatingProfit = buyFloatingProfit + sellFloatingProfit;

   double riskAmount, profitAmount;
   if(InpTargetMode == TARGET_PERCENT)
     {
      riskAmount = -(account.Balance() * (InpMaxRiskValue / 100.0));
      profitAmount = account.Balance() * (InpTakeProfitValue / 100.0);
     }
   else
     {
      riskAmount = -InpMaxRiskValue;
      profitAmount = InpTakeProfitValue;
     }

   if(buyCount > 0 && buyFloatingProfit >= profitAmount)
     {
      Print("BUY BASKET TP HIT! Closing ", buyCount, " Buy trades.");
      CloseBasketDirection(POSITION_TYPE_BUY);
     }

   if(sellCount > 0 && sellFloatingProfit >= profitAmount)
     {
      Print("SELL BASKET TP HIT! Closing ", sellCount, " Sell trades.");
      CloseBasketDirection(POSITION_TYPE_SELL);
     }

   if(totalFloatingProfit <= riskAmount)
     {
      Print("GLOBAL BASKET SL HIT! Wiping all ", totalCount, " trades.");
      CloseAllPositions();
     }
  }

//+------------------------------------------------------------------+
//| Count active tracking positions by order type                    |
//+------------------------------------------------------------------+
int GetActiveCount(ENUM_POSITION_TYPE posType)
  {
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(position.SelectByIndex(i) && position.Symbol() == _Symbol && position.Magic() == InpMagicNumber)
        {
         if(position.PositionType() == posType)
            count++;
        }
     }
   return count;
  }

//+------------------------------------------------------------------+
//| Calculate total active volume currently open on this symbol      |
//+------------------------------------------------------------------+
double GetCurrentSymbolVolume()
  {
   double total_volume = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(position.SelectByIndex(i) && position.Symbol() == _Symbol && position.Magic() == InpMagicNumber)
        {
         total_volume += position.Volume();
        }
     }
   return total_volume;
  }

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick()
  {
   CheckBasketClosure();

   datetime currentBarTime = (datetime)SeriesInfoInteger(_Symbol, _Period, SERIES_LASTBAR_DATE);
   if(currentBarTime == 0 || currentBarTime == lastProcessedBarTime)
      return;

   int current_trend = 0;
   if(!CalculateSupertrend(_Period, atrCurrentHandle, current_trend))
      return;

   lastProcessedBarTime = currentBarTime;
   
   int existingCount = (current_trend == 1) ?
   GetActiveCount(POSITION_TYPE_BUY) : GetActiveCount(POSITION_TYPE_SELL);

   if(InpUseHTFFilter && existingCount > 0)
     {
      int htf_trend = 0;
      if(CalculateSupertrend(InpHTF, atrHTFHandle, htf_trend))
        {
         if(current_trend != htf_trend)
           {
            Print("Scale up blocked: Current Trend (", current_trend, ") conflicts with HTF Trend (", htf_trend, ").");
            return; 
           }
        }
     }

   double price = (current_trend == 1) ?
   SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   
   double valid_lot = NormalizeVolume(InpLotSize);
   
   // Prevent execution if it will exceed the Symbol's Volume Limit
   double max_symbol_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT);
   if(max_symbol_volume > 0.0) 
     {
      double current_open_volume = GetCurrentSymbolVolume();
      if(current_open_volume + valid_lot > max_symbol_volume)
        {
         Print("Trade blocked: Reaching symbol volume limit.");
         return; 
        }
     }

   // --- FIX: Margin Check to prevent "No Money" errors on $1 test accounts ---
   double required_margin = 0.0;
   ENUM_ORDER_TYPE order_type = (current_trend == 1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   
   if(OrderCalcMargin(order_type, _Symbol, valid_lot, price, required_margin))
     {
      if(required_margin > account.FreeMargin())
        {
         Print("Trade blocked: Insufficient margin. Required: ", required_margin, " Available: ", account.FreeMargin());
         return; // Safely skip the trade instead of generating a server error
        }
     }
   
   if(current_trend == 1)
     {
      trade.Buy(valid_lot, _Symbol, price, 0, 0, "ST Continuous Buy");
     }
   else
      if(current_trend == -1)
        {
         trade.Sell(valid_lot, _Symbol, price, 0, 0, "ST Continuous Sell");
        }
  }

//+------------------------------------------------------------------+
//| Close a specific basket direction (Buy or Sell only)             |
//+------------------------------------------------------------------+
void CloseBasketDirection(ENUM_POSITION_TYPE posType)
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(position.SelectByIndex(i) && position.Symbol() == _Symbol && position.Magic() == InpMagicNumber)
        {
         if(position.PositionType() == posType)
            trade.PositionClose(position.Ticket());
        }
     }
  }

//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(position.SelectByIndex(i) && position.Symbol() == _Symbol && position.Magic() == InpMagicNumber)
         trade.PositionClose(position.Ticket());
     }
  }

//+------------------------------------------------------------------+
//| Normalize Lot Size to broker specifications                      |
//+------------------------------------------------------------------+
double NormalizeVolume(double volume)
  {
   double min_vol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_vol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step_vol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(step_vol == 0) return volume; 
   
   double normalized_vol = MathRound(volume / step_vol) * step_vol;
   
   if(normalized_vol < min_vol) normalized_vol = min_vol;
   if(normalized_vol > max_vol) normalized_vol = max_vol;
   
   return NormalizeDouble(normalized_vol, 2);
  }
//+------------------------------------------------------------------+
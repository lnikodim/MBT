//+------------------------------------------------------------------+
//|                                                  SweepH4-M15.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                            https://forge.mql5.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://forge.mql5.io"
#property version   "1.00"
#include <Trade/Trade.mqh>       // Library for taking trades

CTrade trade;                    // Create the object for trading (used when putting positions)

input int Range = 21;            // Range
double SwingHighs[100];           // Array for storing swing highs
double SwingLows[100];            // Array for storing swing lows

int SwingHighCount = 0;          // Counting how many swing highs are
int SwingLowCount = 0;           // Counting how many swing lows are

input double sl_points = 100;     // SL Points

input double RR = 1;           // Risk Reward

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack);    // Color for the Background (Black in this case)
   ChartSetInteger(0, CHART_COLOR_GRID, false);             // Color for the grid (false = no color = no grid)
   ChartSetInteger(0, CHART_COLOR_CANDLE_BULL, clrGreen);   // Color for the bullish candles (Green = upward movement)
   ChartSetInteger(0, CHART_COLOR_CANDLE_BEAR, clrRed);     // Color for the bearish candles (Red = downward movement)
   ChartSetInteger(0, CHART_COLOR_CHART_UP, clrGreen);      // Color for the line chart when price goes up
   ChartSetInteger(0, CHART_COLOR_CHART_DOWN, clrRed);      // Color for the line chart when price goes down
   ChartSetInteger(0, CHART_COLOR_FOREGROUND, clrWhite);    // Color for axis, scales, and text
   ChartSetInteger(0, CHART_COLOR_CHART_LINE, clrGray);     // Color for the line chart itself
   ChartSetInteger(0, CHART_COLOR_BID, clrBisque);          // Color for the Bid price line
   ChartSetInteger(0, CHART_COLOR_LAST, clrAquamarine);     // Color for the Last price line
   ChartSetInteger(0, CHART_COLOR_STOP_LEVEL, clrLightGray);// Color for Stop Levels

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
//+--------------------------------------------+//
//|         CHECKING FOR NEW BARS ON M15       |//
//+--------------------------------------------+//

   bool isnewbarM15 = false;                    // bool value for checking new m15 candles

   int CurrBarM15 = iBars(_Symbol, PERIOD_M15); // count total bars on all M15 graph

   static int PrevBarM15 =  CurrBarM15;         // static varible for storing the quantity of bars

   if(PrevBarM15 == CurrBarM15)                 // Comparing is there is a new bar
     {
      isnewbarM15 = false;                      // returning false for not new bar
     }
   else
     {
      isnewbarM15 = true;                       // returing true for new bar
      PrevBarM15 = CurrBarM15;                  // updating the variable for the static variable
     }

//+--------------------------------------------+//
//|         CHECKING FOR BUYS OR SELLS         |//
//+--------------------------------------------+//

//+--------------------------------------------+//
//|                SWING HIGHS                 |//
//+--------------------------------------------+//

   if(isnewbarM15)                                                                        // new M15 bar
     {
      for(int i=0;i<ArraySize(SwingHighs)-1;i++)                                          // Checking for all the swings on SwingHighs
        {
         if(NormalizeDouble(SwingHighs[i],2) == 0.0)                                      // Checking for the swings that are equal to 0.0 (empty part of the array)
            break;
         if(close(1)<SwingHighs[i] && high(1)>SwingHighs[i])                              // checking for sweep criteria, closing below with high above the swing high
           {
            double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);                            // bid for the entry price (since is a sell)

            double sl = NormalizeDouble(bid+(sl_points*_Point),_Digits);                  // sl = bid + sl_points

            double tp = NormalizeDouble(bid - (sl-bid) * RR,_Digits);                     // tp = bid - sl_points * RR

            if(AccountInfoDouble(ACCOUNT_MARGIN_FREE) > 0)                                // Check for free margin
              {
               trade.Sell(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), _Symbol, bid, sl, tp);                          // sell position
              }

            ArrayModify(SwingHighs, SwingHighs[i]);                                       // deleting the swing high from our swing array (function ↓↓)
            SwingHighCount --;                                                            // decreasing swing high count

            //+-----------------------------------------------+
            //|              ADDING DOWN ARROW                |
            //+-----------------------------------------------+

            string sell = "MyTextPoint4_" + TimeToString(time(1));                        // Naming down arrows
            ObjectCreate(0, sell, OBJ_ARROW, 0, time(1), high(1));                        // Create down arrow on sweep
            ObjectSetInteger(0, sell, OBJPROP_ARROWCODE, 234);                            // 234 code for down arrow
            ObjectSetInteger(0, sell, OBJPROP_COLOR, clrWhite);                           // Change color to white
            ObjectSetInteger(0, sell, OBJPROP_WIDTH, 1);                                  // 1 as the width of the arrow
            ObjectSetInteger(0, sell, OBJPROP_ANCHOR, ANCHOR_UPPER);                      // Anchor arrow on the top
           }
         if(close(1)>SwingHighs[i] && SwingHighs[i] != 0.0)                               // Checking if the close of the last candle surpases any swing high
           {
            ArrayModify(SwingHighs, SwingHighs[i]);                                       // Erasing the swing high that was surpased  (function ↓↓)
            SwingHighCount --;                                                            // decreasing swing high count
           }
        }
      //+--------------------------------------------+//
      //|                SWING LOWS                  |//
      //+--------------------------------------------+//

      for(int i=0;i<ArraySize(SwingLows)-1;i++)                                           // Checking for all the swings on SwingLows
        {
         if(NormalizeDouble(SwingLows[i],2) == 0.0)                                       // Checking for the swings that are equal to 0.0 (empty part of the array)
            break;
         if(low(1)<SwingLows[i] && close(1)>SwingLows[i])                                 // checking for sweep criteria, closing above with low below the swing high
           {
            double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);                            // ask for the entry price (since is a buy)

            double sl = NormalizeDouble(ask-(sl_points*_Point), _Digits);                 // sl = ask - sl_points

            double tp = NormalizeDouble(ask + (ask-sl) * RR, _Digits);                    // tp = ask + sl_points * RR

            if(AccountInfoDouble(ACCOUNT_MARGIN_FREE) > 0)                                // Check for free margin
              {
               trade.Buy(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), _Symbol, ask, sl, tp);                           // buy position
              }

            ArrayModify(SwingLows, SwingLows[i]);                                         // deleting the swing low from our swing array (function ↓↓)
            SwingLowCount --;                                                             // decreasing swing low count

            //+-----------------------------------------------+
            //|               ADDING UP ARROW                 |
            //+-----------------------------------------------+

            string buy = "MyTextPoint4_" + TimeToString(time(1));                         // Naming up arrows
            ObjectCreate(0, buy, OBJ_ARROW, 0, time(1), low(1));                          // Create up arrow on sweep
            ObjectSetInteger(0, buy, OBJPROP_ARROWCODE, 233);                             // 233 code for down arrow
            ObjectSetInteger(0, buy, OBJPROP_COLOR, clrWhite);                            // Change color to white
            ObjectSetInteger(0, buy, OBJPROP_WIDTH, 1);                                   // 1 as the width of the arrow
            ObjectSetInteger(0, buy, OBJPROP_ANCHOR, 0);                                  // anchor bottom
           }
         if(close(1)<SwingLows[i] && SwingLows[i] != 0.0)                                 // Checking if the close of the last candle surpases any swing low
           {
            ArrayModify(SwingLows, SwingLows[i]);                                         // Erasing the swing high that was surpased
            SwingLowCount --;                                                             // decreasing swing low count
           }
        }
     }

//+--------------------------------------------+//
//|         CHECKING FOR NEW BARS ON H4        |//
//+--------------------------------------------+//

   bool isnewbarH4 = false;                                                               // bool value for checking new H4 candles

   int CurrBarH4 = iBars(_Symbol, PERIOD_H4);                                             // count total bars on all H4 graph

   static int PrevBarH4 =  CurrBarH4;                                                     // static varible for storing the quantity of bars

   if(PrevBarH4 == CurrBarH4)                                                             // Comparing is there is a new bar
     {
      isnewbarH4 = false;                                                                 // returning false for not new bar
     }
   else
     {
      isnewbarH4 = true;                                                                  // returing true for new bar
      PrevBarH4 = CurrBarH4;                                                              // updating the variable for the static variable
     }

   if(isnewbarH4)                                                                         // Checking for all the swings on SwingHighs
     {
      bool isSwingHigh = true;                                                            // bool variable for swing highs
      bool isSwingLow = true;                                                             // bool variable for swing lows

      //+-------------------------------------------------+
      //|      CHECKING FOR BARS ON THE RIGHT AND LEFT    |
      //+-------------------------------------------------+

      for(int i=1; i<=Range; i++)                                                         // check for all the bars on the right and left
        {
         if(high4(Range)<high4(Range-i) || high4(Range)<high4(Range+i))                   // check if there are higher highs than our candle high
           {
            isSwingHigh = false;                                                          // if there is a higher high, return false
           }
         if(low4(Range)>low4(Range-i) || low4(Range)>low4(Range+i))                       // check if there are lower lowers than our candle low
           {
            isSwingLow = false;                                                           // if there is a lower low, return false
           }
        }

      //+-------------------------------------------------+
      //|   ADD THE SWING HIGH TO OUR SWING HIGH ARRAYS   |
      //+-------------------------------------------------+

      if(isSwingHigh)
        {
         SwingHighs[SwingHighCount] = high4(Range);                                       // add swing high to our swing high array
         SwingHighCount ++;                                                               // adding swing high count
        }

      //+-------------------------------------------------+
      //|   ADD THE SWING LOW  TO OUR SWING HIGH ARRAYS   |
      //+-------------------------------------------------+

      if(isSwingLow)
        {
         SwingLows[SwingLowCount] = low4(Range);                                          // add swing low to our swing low array
         SwingLowCount ++;                                                                // adding swing low count
        }
     }
  }

//+------------------------------------------------------------------+
//|            FUNCTION FOR GETTING THE HIGH OF A CANDLE (H4)        |
//+------------------------------------------------------------------+
double high4(int index) {return (iHigh(_Symbol,PERIOD_H4,index));}
//+------------------------------------------------------------------+
//|            FUNCTION FOR GETTING THE LOW OF A CANDLE  (H4)        |
//+------------------------------------------------------------------+
double  low4(int index) {return (iLow(_Symbol,PERIOD_H4,index));}
//+------------------------------------------------------------------+
//|            FUNCTION FOR GETTING THE CLOSE OF A CANDLE  (H4)      |
//+------------------------------------------------------------------+
double close4(int index) {return (iClose(_Symbol,PERIOD_H4,index));}
//+------------------------------------------------------------------+
//|            FUNCTION FOR GETTING THE TIME OF A CANDLE   (H4)      |
//+------------------------------------------------------------------+
datetime time4(int index) {return (iTime(_Symbol,PERIOD_H4,index));}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|            FUNCTION FOR GETTING THE HIGH OF A CANDLE    (M15)    |
//+------------------------------------------------------------------+
double high(int index) {return (iHigh(_Symbol,PERIOD_M15,index));}
//+------------------------------------------------------------------+
//|            FUNCTION FOR GETTING THE LOW OF A CANDLE     (M15)    |
//+------------------------------------------------------------------+
double  low(int index) {return (iLow(_Symbol,PERIOD_M15,index));}
//+------------------------------------------------------------------+
//|            FUNCTION FOR GETTING THE CLOSE OF A CANDLE   (M15)    |
//+------------------------------------------------------------------+
double close(int index) {return (iClose(_Symbol,PERIOD_M15,index));}
//+------------------------------------------------------------------+
//|            FUNCTION FOR GETTING THE TIME OF A CANDLE    (M15)    |
//+------------------------------------------------------------------+
datetime time(int index) {return (iTime(_Symbol,PERIOD_M15,index));}
//+------------------------------------------------------------------+
//|  FUNCTION FOR DELETING SWING HIGHS OR LOWS AND REARRANGE ARRAY   |
//+------------------------------------------------------------------+
void ArrayModify(double &arr[], double swing)
  {
   int size = ArraySize(arr);              // Check array size
   for(int i=0;i<size-1;i++)
     {
      if(arr[i] == swing)                  // Find the swing high or low to substitute it with the next value
        {
         for(int j=i;j<size-1;j++)
           {
            arr[j]=arr[j+1];
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

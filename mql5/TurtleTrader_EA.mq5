//+------------------------------------------------------------------+
//|                                                 TurtleTrader.mq5 |
//|                                                        Oschenker |
//|                                            https://forge.mql5.io |
//+------------------------------------------------------------------+
#property copyright  "Oschenker"
#property link       "https://forge.mql5.io"
#property version    "1.00"
//#property icon       "RedValue 100x100.ico"
//--- input parameters
input int            NExit = 10;           //Donchian channel for exit breakout
input int            NST = 20;             //Donchian channel for system-1 breakout
input int            NLT = 55;             //Donchian channel for system-2 breakout
input double         MaxRisk = 0.01;       //Max. deposit share at risk in one trade
input double         VolumeLimit = 4;      //Max. amount of "Units" per symbol
input double         AddingInterval = 1;   //Adding interval (times ATR)
input double         StopLoss = 1;         //Stop loss       (times ATR)
input double         TakeProfit = 1;       //Take profit     (times ATR)
input int            Deviation = 3;        //Allowable trade slippage
input string         String = "-----------------------------------------------"; //SAR parameters---------------------------------------
input bool           SARFlag = false;      //Use SAR-system to trail SL
input double         AFStep = 0.02;        //SAR system step
input double         AFCap = 0.2;          //SAR system cap


// global variables
int                  Direction;
long                 PositionID;
double               Unit;
double               PriceOpen;
double               MaxExit;
double               MinExit;
double               MaxST;
double               MinST;
double               MaxLT;
double               MinLT;
double               SL;
double               TP;
double               EP;
double               AF;
double               ATR;
datetime             CheckTime;
datetime             CheckTimeSAR;
bool                 PrevBreakout;

MqlRates             Rates[];
MqlTradeRequest      Request;   // MBT compile fix: was "= {0}", which current MetaEditor rejects for the enum member; zeroed in OnInit
MqlTradeResult       Results = {0};
MqlTradeCheckResult  Check   = {0};

//+------------------------------------------------------------------+
//| Expert AverageTR function                                        |
//+------------------------------------------------------------------+
double   AverageTR(double  high,
                   double  low,
                   double  prev_close)
   {
    // calculate average true range
    double true_range = fmax(high - low, fmax(high - prev_close, prev_close - low));
    double account_equity  = AccountInfoDouble(ACCOUNT_EQUITY);
    double tick_value      = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
    double volume_min      = SymbolInfoDouble(Symbol(), SYMBOL_VOLUME_MIN);
    if(ATR == 0) ATR = true_range;
    ATR = (19 * ATR + true_range) / 20;
    // adjust ATR for dollar volatility to calculate Unit (trade value)
    int digits = (int)log10(volume_min); // number of digits after dechimal points in Min Value allowed
    Unit = fmin(VolumeLimit, fmax(volume_min, NormalizeDouble((MaxRisk * account_equity * Point()) / (ATR * tick_value), digits)));
    return(ATR);
   }
//+------------------------------------------------------------------+
//| Expert SARTrailing function                                      |
//+------------------------------------------------------------------+
bool SARTrailing(double high,
                 double low)
   {
    // calculate new SL value
    switch(Direction)
      {
       // position is BUY
       case 1:
         if(high > EP)
               {
                AF = fmin(AFCap, AF + AFStep * ATR * 1000);
                EP = high;
               }
         SL = SL + AF * (EP - SL);
         Print(EP, " ", SL);
         break;
       // position is SELL
       case -1:
         if(low < EP)
               {
                AF = fmin(AFCap, AF + AFStep * ATR * 1000);
                EP = low;
               }
         SL = SL - AF * (SL - EP);
         Print(EP, " ", SL);
         break;
      }
    Request.action = TRADE_ACTION_SLTP;
    Request.symbol = Symbol();
    Request.sl = SL;
    Request.position = PositionGetInteger(POSITION_TICKET);
    if(OrderCheck(Request, Check) && Check.retcode == 0)
      {
       if(!OrderSend(Request, Results) || Results.retcode != 10009) return(false);
       else return(true);
      }
    else
      {
       if(Check.retcode == 10019) Print("There is not enough money to complete the request");
       if(Check.retcode == 10025) Print("No changes in request");
       if(Check.retcode == 10014) Print("Invalid volume in the request");
       return(false);
      }             
    return(false);
   }
//+------------------------------------------------------------------+
//| Expert Breakout function                                         |
//+------------------------------------------------------------------+
int   Breakout(double   price,
               double   max,
               double   min)
   {
    int direction;
    // check breakout
    direction = 0;
    if(price > max) direction =  1;
    if(price < min) direction = -1;
    return(direction);
   }

//+------------------------------------------------------------------+
//| Expert MaxMin function                                           |
//+------------------------------------------------------------------+
bool  MaxMin()
   {
    // calculate price level of minimum and maximum over last n_... bars
    MaxLT = Rates[NLT - 1].high;
    MinLT = Rates[NLT - 1].low;
    for(int i = 2; i <= NLT; i++)
      {
       if(Rates[NLT - i].high > MaxLT) MaxLT = Rates[NLT - i].high;
       if(Rates[NLT - i].low  < MinLT) MinLT = Rates[NLT - i].low;
       if(i == NExit)
         {
          MaxExit = MaxLT;
          MinExit = MinLT;
         }
       if(i == NST)
         {
          MaxST = MaxLT;
          MinST = MinLT;
         }
      }
    //Print("Exit ", MaxExit, " ", MinExit);
    //Print("ST ",   MaxST,   " ", MinST);
    //Print("LT ",   MaxLT,   " ", MinLT);
    return(true);
   }

//+------------------------------------------------------------------+
//| Expert Trade Function                                            |
//+------------------------------------------------------------------+
bool Trade(int direction, double volume)
   {
    ZeroMemory(Request);
    ZeroMemory(Results);
    ZeroMemory(Check);
    Request.action    = TRADE_ACTION_DEAL;
    Request.symbol    = Symbol();
    Request.volume    = volume;
    Request.deviation = Deviation;
    if(direction == 1)
      {
       Request.type  = ORDER_TYPE_BUY;
       Request.price = EP = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
       Request.sl    = SL = Request.price - StopLoss * ATR;
       if(TakeProfit != 0) Request.tp = TP;
      }
    if(direction == -1)
      {
       Request.type  = ORDER_TYPE_SELL;
       Request.price = EP = SymbolInfoDouble(Symbol(), SYMBOL_BID);
       Request.sl    = SL = Request.price + StopLoss * ATR;
       if(TakeProfit != 0) Request.tp = TP;
      }
    if(OrderCheck(Request, Check) && Check.retcode == 0)
      {
       if(!OrderSend(Request, Results) || Results.retcode != 10009) return(false);
       PriceOpen = Results.price;
       return(true);
      }
    else
      {
       if(Check.retcode == 10025) Print("No changes in request");
       if(Check.retcode == 10019) Print("There is not enough money to complete the request");
       if(Check.retcode == 10014) Print("Invalid volume in the request");
       return(false);
      }
     return(true);
   }

//+------------------------------------------------------------------+ 
//| Expert DrawLevel function                                        | 
//+------------------------------------------------------------------+ 
bool  DrawLevels(datetime  lastbar_time)
   { 
    // wait for new bar
    string     name;
    uchar      arrow_code;
    color      clr;
    double     level;
    // 1 create Exit Max arrow 
    name = "MaxExit" + (string)lastbar_time;
    arrow_code = 158;
    level = MaxExit;
    clr = clrRed;
    if(ObjectCreate(0, name, OBJ_ARROW, 0, lastbar_time, level))
      {
       ObjectSetInteger(0, name, OBJPROP_ARROWCODE,arrow_code); 
       ObjectSetInteger(0, name, OBJPROP_COLOR,clr); 
       ObjectSetInteger(0, name, OBJPROP_BACK, false); 
      }
    else return(false);
    
    // 2 create Exit Min arrow 
    name = "MinExit" + (string)lastbar_time;
    arrow_code = 158;
    level = MinExit;
    clr = clrRed;
    if(ObjectCreate(0, name, OBJ_ARROW, 0, lastbar_time, level))
      {
       ObjectSetInteger(0, name, OBJPROP_ARROWCODE,arrow_code); 
       ObjectSetInteger(0, name, OBJPROP_COLOR,clr); 
       ObjectSetInteger(0, name, OBJPROP_BACK, false); 
      }
    else return(false);

    // 3 create ST Max arrow 
    name = "MaxST" + (string)lastbar_time;
    arrow_code = 159;
    level = MaxST;
    clr = clrBlue;
    if(ObjectCreate(0, name, OBJ_ARROW, 0, lastbar_time, level))
      {
       ObjectSetInteger(0, name, OBJPROP_ARROWCODE,arrow_code); 
       ObjectSetInteger(0, name, OBJPROP_COLOR,clr); 
       ObjectSetInteger(0, name, OBJPROP_BACK, false); 
      }
    else return(false);

    // 4 create ST Min arrow 
    name = "MinST" + (string)lastbar_time;
    arrow_code = 159;
    level = MinST;
    clr = clrBlue;
    if(ObjectCreate(0, name, OBJ_ARROW, 0, lastbar_time, level))
      {
       ObjectSetInteger(0, name, OBJPROP_ARROWCODE,arrow_code); 
       ObjectSetInteger(0, name, OBJPROP_COLOR,clr); 
       ObjectSetInteger(0, name, OBJPROP_BACK, false); 
      }
    else return(false);

    // 5 create LT Max arrow 
    name = "MaxLT" + (string)lastbar_time;
    arrow_code = 167;
    level = MaxLT;
    clr = clrGreen;
    if(ObjectCreate(0, name, OBJ_ARROW, 0, lastbar_time, level))
      {
       ObjectSetInteger(0, name, OBJPROP_ARROWCODE,arrow_code); 
       ObjectSetInteger(0, name, OBJPROP_COLOR,clr); 
       ObjectSetInteger(0, name, OBJPROP_BACK, false); 
      }
    else return(false);

    // 6 create LT Max arrow 
    name = "MinLT" + (string)lastbar_time;
    arrow_code = 167;
    level = MinLT;
    clr = clrGreen;
    if(ObjectCreate(0, name, OBJ_ARROW, 0, lastbar_time, level))
      {
       ObjectSetInteger(0, name, OBJPROP_ARROWCODE,arrow_code); 
       ObjectSetInteger(0, name, OBJPROP_COLOR,clr); 
       ObjectSetInteger(0, name, OBJPROP_BACK, false); 
      }
    else return(false);

    return(true); 
   }


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   ZeroMemory(Request);
   ENUM_ACCOUNT_MARGIN_MODE   marginMode;
   marginMode = (ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   if(marginMode == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
      {
       Print("This EA doesn't work in HEDGING mode");
       return(INIT_FAILED);
      }
   double volume_limit = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT);
   if(volume_limit < VolumeLimit && volume_limit != 0)
      {
       Print("Volume limit exceed Maximal volume limit ", volume_limit);
       return(INIT_FAILED);
      }
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   // clear all objects from the chart
   ObjectsDeleteAll(0, -1, -1); 
   // remove comments, if any
   ChartSetString( 0, CHART_COMMENT, "");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
   {
    if(CopyRates(Symbol(), 0, 0, NLT, Rates) <= 0) Print("There is no price data");
    else
       {
        double price = Rates[NLT - 1].close;
        datetime   lastbar_time = (datetime)SeriesInfoInteger(Symbol(), 0, SERIES_LASTBAR_DATE);
        if(CheckTime != lastbar_time) // wait for another bar to close
          {
           CheckTime = lastbar_time;
           // calculate volatility (ATR)
           ATR = AverageTR(Rates[NLT - 2].high, Rates[NLT - 2].low, Rates[NLT - 3].close);
           Comment("ATR = " + DoubleToString(ATR, 4) +"\n" + "Unit = " + DoubleToString(Unit, 2) + "\n" + "Previous breakout = " + (string)PrevBreakout);
          // calculate levels for Donchian channel
          if(!MaxMin()) Print("MaxMin failed");
          else if(!DrawLevels(lastbar_time)) Print("Level drawing failed");
          }

        // if there is open position   
        if(PositionSelect(Symbol()))
          {
           PositionID = PositionGetInteger(POSITION_IDENTIFIER);
           // if total volume opened < MaxVolume - add positions after every 0.5 * ATR price move
           double position_volume = PositionGetDouble(POSITION_VOLUME);
           if((position_volume + Unit) < VolumeLimit)
               {
                // price is higher than price of last open position
                if((price - PriceOpen) * Direction > AddingInterval * ATR)
                   {
                    if(!Trade(Direction, Unit)) Print("Unit addition is failed");
                   }
               }
           // exit all positions after backward breakout MMExit
           int back_ward = Breakout(price, MaxExit, MinExit);
           if(back_ward == -1 * Direction)
             {
              if(Trade(back_ward, position_volume)) Direction = 0;
             }
           if(SARFlag && CheckTimeSAR != lastbar_time) // wait for another bar to close
             {
              CheckTimeSAR = lastbar_time;
              SARTrailing(Rates[NLT - 2].high, Rates[NLT - 2].low);
             }
          }
        else
          {
           // if previous breakout was successful breakout
           if(PrevBreakout)
             {
              // check back-ward breakout of 10 days extremum
              int back_ward = Breakout(price, MaxExit, MinExit);
              if(back_ward == -1 * Direction)
                {
                 Direction = 0;
                 PrevBreakout = false;
                 return;
                }
              int LT_breakout = Breakout(price, MaxLT, MinLT);
              if(LT_breakout == Direction)
                {
                 PrevBreakout = false;
                 if(!Trade(Direction, Unit)) Print("Trade failed");
                }
              return;
             }
           else
             {
              // if previous breakout was not successful breakout - store breakout direction and trade
              Direction = Breakout(price, MaxST, MinST);
              if(Direction == 0) return;
              PrevBreakout = true;
              TP = price + Direction * TakeProfit * ATR;
              if(!Trade(Direction, Unit)) Print("Trade failed");
             }
           return;
          }
       }
   }
//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   int      deals_num;
   ulong    tiket;
   string   deal_comment;
   if(HistorySelectByPosition(PositionID))
      {
       deals_num = HistoryDealsTotal(); //--- total deals number in the list
       for( int i=0; i < deals_num && !IsStopped(); i++)
         {
          tiket = HistoryDealGetTicket(i);
          if(HistoryDealGetString(tiket, DEAL_COMMENT, deal_comment) && StringFind(deal_comment, "sl", 0) != -1)
            {
             Direction = 0;
             PrevBreakout = false;
             PositionID = 0;
            }
          if(HistoryDealGetString(tiket, DEAL_COMMENT, deal_comment) && StringFind(deal_comment, "tp", 0) != -1)
            {
             Direction = 0;
             PrevBreakout = true;
             PositionID = 0;
            }
         }
      }  
  } 

//+------------------------------------------------------------------+

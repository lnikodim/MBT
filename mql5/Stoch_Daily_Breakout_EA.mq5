//+------------------------------------------------------------------+
//|                                           StochDailyBreakout.mq5 |
//|                                                     Bruno Myrrha |
//+------------------------------------------------------------------+
//| Purpose:      Places a buy stop at yesterday's high when the     |
//|               stochastic signal line turns down and the open of  |
//|               three bars ago is below the upper Bollinger band;  |
//|               or a sell stop at yesterday's low when the signal  |
//|               line turns up and that open is above the lower     |
//|               band. Stop and target in percent of the entry; the |
//|               pending order is cancelled after a number of bars. |
//| Failure mode: Signals are evaluated once per bar, on the first   |
//|               tick of the new bar. The stochastic (close-to-close|
//|               range, SMMA smoothing) is computed inside the EA,  |
//|               because it differs from the built-in iStochastic.  |
//| Dependencies: none (built-in iBands only)                        |
//| Part of:      StochDailyBreakout Expert Advisor                  |
//+------------------------------------------------------------------+

#property copyright "Bruno Nunes Myrrha Ribeiro"
#property link      "https://www.mql5.com/en/users/bruno_myrrha"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
input double InpLots       = 0.01;     // volume per trade
input int    InpMagic      = 260931;   // magic number
input int    InpBandPeriod = 9;        // Bollinger period (weighted price, 2.0 deviations)
input int    InpKPeriod    = 23;       // stochastic %K period
input int    InpDPeriod    = 3;        // stochastic signal period
input int    InpSlowing    = 7;        // stochastic slowing
input double InpStopPct    = 1.9;      // stop distance, percent of entry
input double InpTargetPct  = 1.9;      // target distance, percent of entry
input int    InpExpiryBars = 9;        // bars a pending order stays alive

//+------------------------------------------------------------------+
//| Constants and state                                              |
//+------------------------------------------------------------------+
#define WINDOW   2000                  // bars used to seed the smoothed stochastic
#define MIN_BARS 30                    // bars required before trading
#define SHIFT    3                     // bar the band filter reads

int      g_bands    = INVALID_HANDLE;  // iBands handle
datetime g_last_bar = 0;               // open time of the last processed bar

//+------------------------------------------------------------------+
//| Rounds a price to the symbol tick size                           |
//+------------------------------------------------------------------+
double FixPrice(const double price)
  {
   double tick=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick==0)
      return(NormalizeDouble(price,_Digits));
   return(NormalizeDouble(MathRound(price/tick)*tick,_Digits));
  }

//+------------------------------------------------------------------+
//| True inside a trading session of the chart symbol, server time   |
//+------------------------------------------------------------------+
bool IsMarketOpen(void)
  {
   datetime now=TimeTradeServer();
   MqlDateTime dt;
   TimeToStruct(now,dt);
   int      tod=(int)(now%86400);
   datetime from,to;
   for(int s=0; SymbolInfoSessionTrade(_Symbol,(ENUM_DAY_OF_WEEK)dt.day_of_week,s,from,to); s++)
     {
      int f=(int)(from%86400),t=(int)(to%86400);
      if(f<t ? (tod>=f && tod<=t) : (tod>=f || tod<=t))
         return(true);
     }
   return(false);
  }

//+------------------------------------------------------------------+
//| Stochastic signal line, oldest first: %K on the close-to-close   |
//| range, SMMA slowing, SMMA signal (seed 50, standard library rule)|
//+------------------------------------------------------------------+
bool StochSignal(double &signal[])
  {
   int    count=MathMin(Bars(_Symbol,_Period),WINDOW);
   double close[];
   if(CopyClose(_Symbol,_Period,0,count,close)<count)
      return(false);
   double k[],main[];
   ArrayResize(k,count);
   ArrayResize(main,count);
   ArrayResize(signal,count);
   for(int i=0; i<count; i++)
     {
      double hi=50,lo=50;
      if(i>=InpKPeriod+1)
        {
         hi=close[i];
         lo=close[i];
         for(int a=i-InpKPeriod+1; a<=i; a++)
           {
            hi=MathMax(hi,close[a]);
            lo=MathMin(lo,close[a]);
           }
        }
      double nom=NormalizeDouble(close[i]-lo,8);
      double den=NormalizeDouble(hi-lo,8);
      if(MathAbs(den)<0.00000001)
         k[i]=(i==0) ? 50 : k[i-1];
      else
         k[i]=MathMin(100,MathMax(0,100*nom/den));
      double pm=(i==0) ? 50 : main[i-1];
      main[i]=(i+1>=InpSlowing) ? (pm*(InpSlowing-1)+k[i])/InpSlowing : 0;
      double ps=(i==0) ? 50 : signal[i-1];
      signal[i]=(i+1>=InpDPeriod) ? (ps*(InpDPeriod-1)+main[i])/InpDPeriod : 0;
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Sends a request and reports whether the server accepted it       |
//+------------------------------------------------------------------+
bool Send(MqlTradeRequest &request)
  {
   MqlTradeResult result;
   ZeroMemory(result);
   return(OrderSend(request,result) &&
          (result.retcode==TRADE_RETCODE_DONE || result.retcode==TRADE_RETCODE_PLACED));
  }

//+------------------------------------------------------------------+
//| Deletes a pending order                                          |
//+------------------------------------------------------------------+
bool DeleteOrder(const ulong ticket)
  {
   MqlTradeRequest request;
   ZeroMemory(request);
   request.action=TRADE_ACTION_REMOVE;
   request.order=ticket;
   return(Send(request));
  }

//+------------------------------------------------------------------+
//| Cancels pending orders that have lived the expiry, in bars       |
//+------------------------------------------------------------------+
void ManageExpiry(void)
  {
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(!OrderSelect(ticket) || OrderGetInteger(ORDER_MAGIC)!=InpMagic ||
         OrderGetString(ORDER_SYMBOL)!=_Symbol)
         continue;
      datetime setup=(datetime)OrderGetInteger(ORDER_TIME_SETUP);
      if(iBarShift(_Symbol,_Period,setup)>=InpExpiryBars)
         DeleteOrder(ticket);
     }
  }

//+------------------------------------------------------------------+
//| Places a stop order, replacing a previous one of the same side.  |
//| Skipped while a position is open or when the prices break the    |
//| broker's stop level                                              |
//+------------------------------------------------------------------+
void PlaceStop(const bool buy,const double price)
  {
   if(InpLots<SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN))
      return;
//--- one position at a time
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(PositionSelectByTicket(PositionGetTicket(i)) &&
         PositionGetInteger(POSITION_MAGIC)==InpMagic && PositionGetString(POSITION_SYMBOL)==_Symbol)
         return;
   ENUM_ORDER_TYPE type=buy ? ORDER_TYPE_BUY_STOP : ORDER_TYPE_SELL_STOP;
//--- replace the previous stop order of the same side
   for(int i=OrdersTotal()-1; i>=0; i--)
     {
      ulong ticket=OrderGetTicket(i);
      if(OrderSelect(ticket) && OrderGetInteger(ORDER_MAGIC)==InpMagic &&
         OrderGetString(ORDER_SYMBOL)==_Symbol && OrderGetInteger(ORDER_TYPE)==type && !DeleteOrder(ticket))
         return;
     }
   double dir=buy ? 1.0 : -1.0;
   double sl=FixPrice(price-dir*price*InpStopPct/100.0);
   double tp=FixPrice(price+dir*price*InpTargetPct/100.0);
//--- prices must respect the broker's minimum distance
   double market=buy ? SymbolInfoDouble(_Symbol,SYMBOL_ASK) : SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double gap=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point;
   double half=_Point/2;
   if(dir*(price-market)<gap-half || dir*(price-sl)<gap-half || dir*(tp-price)<gap-half)
      return;
   double margin=0;
   if(!OrderCalcMargin(buy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL,_Symbol,InpLots,price,margin) ||
      AccountInfoDouble(ACCOUNT_MARGIN_FREE)<=margin)
      return;
   MqlTradeRequest request;
   ZeroMemory(request);
   request.action=TRADE_ACTION_PENDING;
   request.symbol=_Symbol;
   request.type=type;
   request.volume=MathMin(InpLots,SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX));
   request.price=price;
   request.sl=sl;
   request.tp=tp;
   request.magic=InpMagic;
   request.type_filling=((SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE)&SYMBOL_FILLING_FOK)!=0) ?
                        ORDER_FILLING_FOK : ORDER_FILLING_IOC;
   if((SymbolInfoInteger(_Symbol,SYMBOL_EXPIRATION_MODE)&SYMBOL_EXPIRATION_GTC)==0)
      request.type_time=ORDER_TIME_DAY;
   Send(request);
  }

//+------------------------------------------------------------------+
//| Expert initialization: creates the Bollinger handle              |
//+------------------------------------------------------------------+
int OnInit(void)
  {
   g_bands=iBands(_Symbol,_Period,InpBandPeriod,0,2.0,PRICE_WEIGHTED);
   return(g_bands==INVALID_HANDLE ? INIT_FAILED : INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization: releases the Bollinger handle           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   IndicatorRelease(g_bands);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick(void)
  {
   datetime bar=iTime(_Symbol,_Period,0);
   if(bar==g_last_bar || Bars(_Symbol,_Period)<MIN_BARS)
      return;
   g_last_bar=bar;
   if(!IsMarketOpen())
      return;
   ManageExpiry();
//--- band filter on bar SHIFT+1 (buffer 1 upper, buffer 2 lower)
   double upper[],lower[],signal[];
   if(CopyBuffer(g_bands,1,SHIFT+1,1,upper)<1 || CopyBuffer(g_bands,2,SHIFT+1,1,lower)<1 ||
      !StochSignal(signal))
      return;
   double open3=iOpen(_Symbol,_Period,SHIFT);
   int    n=ArraySize(signal);
//--- signal line on bars 3, 2 and 1: a peak at bar 2 turns down, a trough turns up
   double s3=signal[n-4],s2=signal[n-3],s1=signal[n-2];
   bool   turn_down=(s3<s2 && s2>s1);
   bool   turn_up=(s3>s2 && s2<s1);
   bool   buy=(open3<upper[0] && turn_down);
   bool   sell=(open3>lower[0] && turn_up);
   if(buy)
      PlaceStop(true,FixPrice(iHigh(_Symbol,PERIOD_D1,1)));
   else
      if(sell)
         PlaceStop(false,FixPrice(iLow(_Symbol,PERIOD_D1,1)));
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                             Bago EA(barabashkakvn's edition).mq5 |
//|                                   Copyright © 2006, Hua Ai (aha) |
//+------------------------------------------------------------------+
#property copyright "Copyright @2006, Hua Ai (aha)"
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
/*
Bago system can be categorized as a trend following system based on 
the cross of ema 5 and ema 12. When used properly on hourly chart it 
can capture daily swings of 100+ pips.

The use of small number emas gives Bago system the sensitivity to 
generate early signals following 10-20 minutes scale waves, but also 
produces a great deal of false signals that can quickly drain a trader
's account. So filters are extremely important for Bago system.

While Bago system is largely a discretionary system, the integration of 
two excellent filters may make it possible to use a computer program
generate signals with great high successful rate. This program is 
writtern to investigate this possiblity.

The mechanism to generate a raw Bago signal is simple: ema 5 crosses 
ema 12 in the same direction as RSI 21 crosses 50 level. To abstract 
real signals, we need to pay attention to context: where the price are,
and when the crosses happens.

The greatest meaning of integrating Vegas tunnel into Bago system is, 
the tunnel as well as its fibo lines changes the original plain 2-d
space into a twisted 2-d space. The twisted price trends now have the
coordinates. With this coordinates system we may see the entry and exit
with higher accuracy.

So, this program will first construct the simple rules upon which the 
the raw signals are generated, then will add rules to filter those 
signals. Those new rules are quantified as parameters so they can be 
easily changed and optimized based on the output results.

Enough talking, now come to business.
*/
//--- input parameters
input double               InpLots                    = 3.0;               // Lots
input ushort               InpStopLoss                = 30;                // Stop Loss, in pips (1.00045-1.00055=1 pips)
input ushort               InpStopLossToFibo          = 20;                // Stop Loss to Fibo, in pips (1.00045-1.00055=1 pips)
input ushort               InpTrailingStop            = 30;                // Trailing Stop (min distance from price to Stop Loss, in pips
input ushort               InpTrailingStep1           = 55;                // Trailing Step 1, in pips (1.00045-1.00055=1 pips)
input double               InpLotsClosePartial1       = 1.0;               // Lots partially closes 1
input ushort               InpTrailingStep2           = 89;                // Trailing Step 2, in pips (1.00045-1.00055=1 pips)
input double               InpLotsClosePartial2       = 1.0;               // Lots partially closes 2
input ushort               InpTrailingStep3           = 144;               // Trailing Step 3, in pips (1.00045-1.00055=1 pips)
int                        CrossEffectiveTime         = 2;                 // Cross effective time
input ushort               InpTunnelBandWidth         = 5;                 // Tunnel BandWidth, in pips (1.00045-1.00055=1 pips)
input ushort               InpTunnelSafeZone          = 120;               // Tunnel Safe Zone, in pips (1.00045-1.00055=1 pips)
input bool                 LondonOpen                 = true;              // London open
input bool                 NewYorkOpen                = true;              // NewYork open
input bool                 TokyoOpen                  = false;             // Tokyo open
//--- input parameters MA's
input int                  Inp_MA_Fast_ma_period      = 5;                 // MA Fast: ma_period
input int                  Inp_MA_Slow_ma_period      = 12;                // MA Slow: ma_period
input int                  Inp_MA_ma_shift            = 0;                 // MA's: horizontal shift
input ENUM_MA_METHOD       Inp_MA_ma_method           = MODE_EMA;          // MA's: smoothing type
input ENUM_APPLIED_PRICE   Inp_MA_applied_price       = PRICE_CLOSE;       // MA's: type of price
//---
input int                  Inp_RSI_ma_period          = 21;                // RSI: averaging period 
input ENUM_APPLIED_PRICE   Inp_RSI_applied_price      = PRICE_CLOSE;       // RSI: type of price
//---
input ulong    m_magic=373062807;            // magic number
//---
ulong  m_slippage=10;                        // slippage
double ExtStopLoss;
double ExtStopLossToFibo;
double ExtTrailingStop;
double ExtTrailingStep1;
double ExtTrailingStep2;
double ExtTrailingStep3;
double ExtTunnelBandWidth;
double ExtTunnelSafeZone;

int    handle_iMA_Fast;                      // variable for storing the handle of the iMA indicator
int    handle_iMA_Slow;                      // variable for storing the handle of the iMA indicator
int    handle_iMA_Vegas_Fast;                // variable for storing the handle of the iMA indicator
int    handle_iMA_Vegas_Slow;                // variable for storing the handle of the iMA indicator
int    handle_iRSI;                          // variable for storing the handle of the iRSI indicator
double m_adjusted_point;                     // point value adjusted for 3 or 5 points
                                             // State registers store cross up/down information 
bool   EMACrossedUp;
bool   EMACrossedDown;
bool   RSICrossedUp;
bool   RSICrossedDown;
bool   TunnelCrossedUp;
bool   TunnelCrossedDown;
// Cross up/down info should expire in a couple of bars.
// Timer registers to control the expiration.
int    EMACrossedUpTimer;
int    RSICrossedUpTimer;
int    EMACrossedDownTimer;
int    RSICrossedDownTimer;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- No cross
   EMACrossedUp         = false;
   RSICrossedUp         = false;
   TunnelCrossedUp      = false;
   EMACrossedDown       = false;
   RSICrossedDown       = false;
   TunnelCrossedDown    = false;
//--- Reset timers
   EMACrossedUpTimer    = 0;
   RSICrossedUpTimer    = 0;
   EMACrossedDownTimer  = 0;
   RSICrossedDownTimer  = 0;
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();
//---
   m_trade.SetExpertMagicNumber(m_magic);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtStopLoss          = InpStopLoss        * m_adjusted_point;
   ExtStopLossToFibo    = InpStopLossToFibo  * m_adjusted_point;
   ExtTrailingStop      = InpTrailingStop    * m_adjusted_point;
   ExtTrailingStep1     = InpTrailingStep1   * m_adjusted_point;
   ExtTrailingStep2     = InpTrailingStep2   * m_adjusted_point;
   ExtTrailingStep3     = InpTrailingStep3   * m_adjusted_point;
   ExtTunnelBandWidth   = InpTunnelBandWidth * m_adjusted_point;
   ExtTunnelSafeZone    = InpTunnelSafeZone  * m_adjusted_point;
//--- check the input parameter "Lots"
   string err_text="";
   if(!CheckVolumeValue(InpLots,err_text))
     {
      //--- when testing, we will only output to the log about incorrect input parameters
      if(MQLInfoInteger(MQL_TESTER))
        {
         Print(__FUNCTION__,", Lots ERROR: ",err_text);
         return(INIT_FAILED);
        }
      else // if the Expert Advisor is run on the chart, tell the user about the error
        {
         Alert(__FUNCTION__,", Lots ERROR: ",err_text);
         return(INIT_PARAMETERS_INCORRECT);
        }
     }
   if(!CheckVolumeValue(InpLotsClosePartial1,err_text))
     {
      //--- when testing, we will only output to the log about incorrect input parameters
      if(MQLInfoInteger(MQL_TESTER))
        {
         Print(__FUNCTION__,", Lots partially closes 1 ERROR: ",err_text);
         return(INIT_FAILED);
        }
      else // if the Expert Advisor is run on the chart, tell the user about the error
        {
         Alert(__FUNCTION__,", Lots partially closes 1 ERROR: ",err_text);
         return(INIT_PARAMETERS_INCORRECT);
        }
     }
   if(!CheckVolumeValue(InpLotsClosePartial2,err_text))
     {
      //--- when testing, we will only output to the log about incorrect input parameters
      if(MQLInfoInteger(MQL_TESTER))
        {
         Print(__FUNCTION__,", Lots partially closes 2 ERROR: ",err_text);
         return(INIT_FAILED);
        }
      else // if the Expert Advisor is run on the chart, tell the user about the error
        {
         Alert(__FUNCTION__,", Lots partially closes 2 ERROR: ",err_text);
         return(INIT_PARAMETERS_INCORRECT);
        }
     }
//--- create handle of the indicator iMA
   handle_iMA_Fast=iMA(m_symbol.Name(),Period(),Inp_MA_Fast_ma_period,Inp_MA_ma_shift,
                       Inp_MA_ma_method,Inp_MA_applied_price);
//--- if the handle is not created 
   if(handle_iMA_Fast==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator (\"Fast\") for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_Slow=iMA(m_symbol.Name(),Period(),Inp_MA_Slow_ma_period,Inp_MA_ma_shift,
                       Inp_MA_ma_method,Inp_MA_applied_price);
//--- if the handle is not created 
   if(handle_iMA_Slow==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator (\"Fast\") for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_Vegas_Fast=iMA(m_symbol.Name(),Period(),144,Inp_MA_ma_shift,
                             Inp_MA_ma_method,Inp_MA_applied_price);
//--- if the handle is not created 
   if(handle_iMA_Vegas_Fast==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator (\"Fast\") for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_Vegas_Slow=iMA(m_symbol.Name(),Period(),169,Inp_MA_ma_shift,
                             Inp_MA_ma_method,Inp_MA_applied_price);
//--- if the handle is not created 
   if(handle_iMA_Vegas_Slow==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator (\"Fast\") for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iRSI
   handle_iRSI=iRSI(m_symbol.Name(),Period(),Inp_RSI_ma_period,Inp_RSI_applied_price);
//--- if the handle is not created 
   if(handle_iRSI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- No cross
   EMACrossedUp         = false;
   RSICrossedUp         = false;
   TunnelCrossedUp      = false;
   EMACrossedDown       = false;
   RSICrossedDown       = false;
   TunnelCrossedDown    = false;
//--- Reset timers
   EMACrossedUpTimer    = 0;
   RSICrossedUpTimer    = 0;
   EMACrossedDownTimer  = 0;
   RSICrossedDownTimer  = 0;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(m_symbol.Name(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   if(!RefreshRates())
     {
      PrevBars=0;
      return;
     }
//---
   double ma_fast[],ma_slow[],rsi[],ma_vegas_fast[],ma_vegas_slow[],open[],close[];
   ArraySetAsSeries(ma_fast,true);
   ArraySetAsSeries(ma_slow,true);
   ArraySetAsSeries(rsi,true);
   ArraySetAsSeries(ma_vegas_fast,true);
   ArraySetAsSeries(ma_vegas_slow,true);
   ArraySetAsSeries(open,true);
   ArraySetAsSeries(close,true);

   int buffer=0,start_pos=0,count=3;
   if(!iGetArray(handle_iMA_Fast,buffer,start_pos,count,ma_fast) || 
      !iGetArray(handle_iMA_Slow,buffer,start_pos,count,ma_slow) || 
      !iGetArray(handle_iRSI,buffer,start_pos,count,rsi) || 
      !iGetArray(handle_iMA_Vegas_Fast,buffer,start_pos,count,ma_vegas_fast) || 
      !iGetArray(handle_iMA_Vegas_Slow,buffer,start_pos,count,ma_vegas_slow) || 
      CopyOpen(m_symbol.Name(),Period(),start_pos,count,open)!=count || 
      CopyClose(m_symbol.Name(),Period(),start_pos,count,close)!=count)
     {
      PrevBars=0;
      return;
     }
//+------------------------------------------------------------------+
//| Based on the price and the calculated indicators determine       |
//| the states of the state machine                                  |
//+------------------------------------------------------------------+
//--- Check if there is a RSI cross up
   if((rsi[1]>50) && (rsi[2]<50) && (RSICrossedUp==false))
     {
      RSICrossedUp  =true;
      RSICrossedDown=false;
     }
   if(RSICrossedUp==true)
      RSICrossedUpTimer++;  // Record the number of bars the cross has happened
   else
      RSICrossedUpTimer=0;  // Reset the timer once the cross is reversed
   if(RSICrossedUpTimer>=CrossEffectiveTime)
      RSICrossedUp=false; // Reset state register when crossed 3 bars ago
//--- Check if there is a RSI cross down
   if((rsi[1]<50) && (rsi[2]>50) && (RSICrossedDown==false))
     {
      RSICrossedUp  =false;
      RSICrossedDown=true;
     }
   if(RSICrossedDown==true)
      RSICrossedDownTimer++;  // Record the number of bars the cross has happened
   else
      RSICrossedDownTimer=0;  // Reset the timer once the cross is reversed
   if(RSICrossedDownTimer>=CrossEffectiveTime)
      RSICrossedDown=false; // Reset register when crossed 3 bars ago
//--- Check if there is a EMA cross up
   if((ma_fast[1]>ma_slow[1]) && 
      (ma_fast[2]<ma_slow[2]) && 
      (EMACrossedUp==false))
     {
      EMACrossedUp  =true;
      EMACrossedDown=false;
     }
   if(EMACrossedUp==true)
      EMACrossedUpTimer++;  // Record the number of bars the cross has happened
   else
      EMACrossedUpTimer=0;  // Reset the timer once the cross is reversed
   if(EMACrossedUpTimer>=CrossEffectiveTime)
      EMACrossedUp=false; // Reset register when crossed 3 bars ago
//--- Check if there is a EMA cross down
   if((ma_fast[1]<ma_slow[1]) && 
      (ma_fast[2]>ma_slow[2]) && 
      (EMACrossedDown==false))
     {
      EMACrossedUp  =false;
      EMACrossedDown=true;
     }
   if(EMACrossedDown==true)
      EMACrossedDownTimer++;  // Record the number of bars the cross has happened
   else
      EMACrossedDownTimer=0;  // Reset the timer once the cross is reversed
   if(EMACrossedDownTimer>=CrossEffectiveTime)
      EMACrossedDown=false; // Reset register when crossed 3 bars ago
   if((close[1]>ma_vegas_fast[0] && close[1]>ma_vegas_slow[0]) && 
      (close[2]<ma_vegas_fast[0] || close[2]<ma_vegas_slow[0]))
     {
      TunnelCrossedUp  =true;
      TunnelCrossedDown=false;
     }
   if((close[1]<ma_vegas_fast[0] && close[1]<ma_vegas_slow[0]) && 
      (close[2]>ma_vegas_fast[0] || close[2]>ma_vegas_slow[0]))
     {
      TunnelCrossedUp  =false;
      TunnelCrossedDown=true;
     }
//+------------------------------------------------------------------+
//| Based on states, determine entry situations                      |
//+------------------------------------------------------------------+
//--- check the trading time
   MqlDateTime STime0;
   TimeToStruct(time_0,STime0);
   if(!(
      (LondonOpen==true && STime0.hour>=7 && STime0.hour<=16) || 
      (NewYorkOpen==true && STime0.hour>=12 && STime0.hour<=21) || 
      (TokyoOpen==true && STime0.hour>=0 && STime0.hour<=8) || 
      (STime0.hour>=23)
      ))
     {
      //--- outside the trading hours
      return;
     }
   else
     {
      //--- check Freeze and Stops levels
      if(!RefreshRates())
        {
         PrevBars=0;
         return;
        }
      double freeze_level=m_symbol.FreezeLevel()*m_symbol.Point();
      if(freeze_level==0.0)
         freeze_level=(m_symbol.Ask()-m_symbol.Bid())*3.0;
      freeze_level*=1.1;

      double stop_level=m_symbol.StopsLevel()*m_symbol.Point();
      if(stop_level==0.0)
         stop_level=(m_symbol.Ask()-m_symbol.Bid())*3.0;
      stop_level*=1.1;

      if(freeze_level<=0.0 || stop_level<=0.0)
        {
         PrevBars=0;
         return;
        }
      //--- long entry
      if((EMACrossedUp==true) && (RSICrossedUp==true) && // Raw long signal generating rules
         //--- Experimenting new filters here
         //--- 1. For long trade, should only enter on the top of the tunnel to avoid tunnel resistance
         //--- 2. Shouldn't enter long on the high fibo lines above tunnel because the price tends to 
         //---    go back to tunnel.
         //--- 3. Instead of push up from the tunnel, the price may drop from high fibo line area but with 
         //---    EMA and RSI crossed, should avoid enter long at such situation.
         //--- 4. Around tunnel there ususually have a lot whipsaw, should avoid enter a trade in the band
         //--- 5. Should allow the price push from below the tunnel and enter long trade.
         ((close[1]>=ma_vegas_slow[0]+ExtTunnelBandWidth && // Above whipsaw zone
         close[1]<=ma_vegas_slow[0]+ExtTunnelSafeZone && // Below high fibo line
         open[1]<close[1]) || // Price push up from a bull bar
         (close[1]<=ma_vegas_slow[0]-ExtTunnelBandWidth) // Testing from below the tunnel
         ))
        {
         double price=m_symbol.Ask();
         double sl=(InpStopLoss==0)?0.0:price-ExtStopLoss;
         if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0))
           {
            OpenBuy(sl,0.0);
            return;
           }
         return;
        }
      //--- short entry
      if((EMACrossedDown==true) && (RSICrossedDown==true) && // Raw short signal generating rules
         // Similar to long signal filtering rules.
         ((close[1]<=ma_vegas_slow[0]-ExtTunnelBandWidth && // Below whipsaw zone
         close[1]>=ma_vegas_slow[0]-ExtTunnelSafeZone && // Above high fibo line
         open[1]>close[1]) || // Price down from a bear bar
         (close[1]>=ma_vegas_slow[0]+ExtTunnelBandWidth) // Testing from above the tunnel
         ))
        {
         double price=m_symbol.Bid();
         double sl=(InpStopLoss==0)?0.0:price+ExtStopLoss;
         if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0))
           {
            OpenSell(sl,0.0);
            return;
           }
         return;
        }
     }
//--- trailing
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               //--- when EMA or RSI crosses reverse, exit all lots
               if((EMACrossedDown==true) || (RSICrossedDown==true))
                 {
                  m_trade.PositionClose(m_position.Ticket());
                  continue;
                 }
               //--- exits on fibo lines      
               if(TunnelCrossedUp==true)
                 {
                  if(m_symbol.Bid()>=(ma_vegas_slow[0]+ExtTrailingStep3))
                    {
                     if(m_position.StopLoss()<m_symbol.Bid()-ExtTrailingStop && 
                        !CompareDoubles(m_position.StopLoss(),m_symbol.Bid()-ExtTrailingStop,m_symbol.Digits()))
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(m_symbol.Bid()-ExtTrailingStop),
                           m_position.TakeProfit()))
                          {
                           //RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                     continue;
                    }
                  //--- reach 2nd TP level, close the 2nd lot, move up remainder stop to InpTrailingStep2-ExtStopLossToFibo
                  //--- or start trailing stop
                  else if(m_symbol.Bid()>=(ma_vegas_slow[0]+ExtTrailingStep2))
                    {
                     if(m_position.Volume()>InpLotsClosePartial2 && m_position.PriceOpen()<ma_vegas_slow[0]+ExtTrailingStep2)
                        m_trade.PositionClosePartial(m_position.Ticket(),InpLotsClosePartial2);
                     if(m_position.StopLoss()<m_symbol.Bid()-ExtTrailingStop && 
                        !CompareDoubles(m_position.StopLoss(),m_symbol.Bid()-ExtTrailingStop,m_symbol.Digits()))
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(m_symbol.Bid()-ExtTrailingStop),
                           m_position.TakeProfit()))
                          {
                           //RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                     continue;
                    }
                  //--- reach 1nd TP level, close the 1st lot, move up remainder stop to InpTrailingStep1-ExtStopLossToFibo
                  else if(m_symbol.Bid()>=(ma_vegas_slow[0]+ExtTrailingStep1))
                    {
                     if(m_position.Volume()>InpLotsClosePartial1 && m_position.PriceOpen()<ma_vegas_slow[0]+ExtTrailingStep1)
                        m_trade.PositionClosePartial(m_position.Ticket(),InpLotsClosePartial1);
                     if(m_position.StopLoss()<m_symbol.Bid()-ExtTrailingStop && 
                        !CompareDoubles(m_position.StopLoss(),m_symbol.Bid()-ExtTrailingStop,m_symbol.Digits()))
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(m_symbol.Bid()-ExtTrailingStop),
                           m_position.TakeProfit()))
                          {
                           //RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                     continue;
                    }
                  //--- tunnel crossed, move stop to below the tunnel; 
                  if(m_position.StopLoss()<ma_vegas_slow[0]-ExtTunnelBandWidth && 
                     !CompareDoubles(m_position.StopLoss(),ma_vegas_slow[0]-(ExtTunnelBandWidth+ExtStopLossToFibo),m_symbol.Digits()))
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(ma_vegas_slow[0]-(ExtTunnelBandWidth+ExtStopLossToFibo)),
                        m_position.TakeProfit()))
                       {
                        //RefreshRates();
                        m_position.SelectByIndex(i);
                        PrintResultModify(m_trade,m_symbol,m_position);
                       }
                  continue;
                 }
               else
                 {
                  if(m_symbol.Bid()>=(ma_vegas_slow[0]-ExtTrailingStep1))
                    {
                     if(m_position.StopLoss()<ma_vegas_slow[0]-(ExtTrailingStep1+ExtStopLossToFibo) && 
                        !CompareDoubles(m_position.StopLoss(),ma_vegas_slow[0]-(ExtTrailingStep1+ExtStopLossToFibo),m_symbol.Digits()))
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(ma_vegas_slow[0]-(ExtTrailingStep1+ExtStopLossToFibo)),
                           m_position.TakeProfit()))
                          {
                           //RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                     continue;
                    }
                  //--- reach 2nd TP level, close the 2nd lot, move up remainder stop to InpTrailingStep2-ExtStopLossToFibo
                  //--- or start trailing stop
                  else if(m_symbol.Bid()>=(ma_vegas_slow[0]-ExtTrailingStep2))
                    {
                     if(m_position.StopLoss()<ma_vegas_slow[0]-(ExtTrailingStep2+ExtStopLossToFibo) && 
                        !CompareDoubles(m_position.StopLoss(),ma_vegas_slow[0]-(ExtTrailingStep2+ExtStopLossToFibo),m_symbol.Digits()))
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(ma_vegas_slow[0]-(ExtTrailingStep2+ExtStopLossToFibo)),
                           m_position.TakeProfit()))
                          {
                           //RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                     continue;
                    }
                  //--- reach 1nd TP level, close the 1st lot, move up remainder stop to InpTrailingStep1-ExtStopLossToFibo
                  else if(m_symbol.Bid()>=(ma_vegas_slow[0]-ExtTrailingStep3))
                    {
                     if(m_position.StopLoss()<ma_vegas_slow[0]-(ExtTrailingStep3+ExtStopLossToFibo) && 
                        !CompareDoubles(m_position.StopLoss(),ma_vegas_slow[0]-(ExtTrailingStep3+ExtStopLossToFibo),m_symbol.Digits()))
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(ma_vegas_slow[0]-(ExtTrailingStep3+ExtStopLossToFibo)),
                           m_position.TakeProfit()))
                          {
                           //RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                     continue;
                    }
                 }
              }
            else
              {
               //--- when EMA or RSI crosses reverse, exit all lots
               if((EMACrossedUp==true) || (RSICrossedUp==true))
                 {
                  m_trade.PositionClose(m_position.Ticket());
                  continue;
                 }
               if(TunnelCrossedDown==true)
                 {
                  if(m_symbol.Ask()<=(ma_vegas_slow[0]-ExtTrailingStep3))
                    {
                     if(m_position.StopLoss()>m_symbol.Ask()+ExtTrailingStop && 
                        !CompareDoubles(m_position.StopLoss(),m_symbol.Ask()+ExtTrailingStop,m_symbol.Digits()))
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(m_symbol.Ask()+ExtTrailingStop),
                           m_position.TakeProfit()))
                          {
                           //RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                     continue;
                    }
                  //--- reach 2nd TP level, close the 2nd lot, move up remainder stop to InpTrailingStep2-ExtStopLossToFibo
                  //--- or start trailing stop
                  else if(m_symbol.Ask()<=(ma_vegas_slow[0]-ExtTrailingStep2))
                    {
                     if(m_position.Volume()>InpLotsClosePartial2 && m_position.PriceOpen()>ma_vegas_slow[0]-ExtTrailingStep2)
                        m_trade.PositionClosePartial(m_position.Ticket(),InpLotsClosePartial2);
                     if(m_position.StopLoss()>m_symbol.Ask()+ExtTrailingStop && 
                        !CompareDoubles(m_position.StopLoss(),m_symbol.Ask()+ExtTrailingStop,m_symbol.Digits()))
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(m_symbol.Ask()+ExtTrailingStop),
                           m_position.TakeProfit()))
                          {
                           //RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                     continue;
                    }
                  //--- reach 2nd TP level, close the 2nd lot, move up remainder stop to InpTrailingStep2-ExtStopLossToFibo
                  else if(m_symbol.Ask()<=(ma_vegas_slow[0]-ExtTrailingStep1))
                    {
                     if(m_position.Volume()>InpLotsClosePartial1 && m_position.PriceOpen()>ma_vegas_slow[0]-ExtTrailingStep1)
                        m_trade.PositionClosePartial(m_position.Ticket(),InpLotsClosePartial1);
                     if(m_position.StopLoss()>m_symbol.Ask()+ExtTrailingStop && 
                        !CompareDoubles(m_position.StopLoss(),m_symbol.Ask()+ExtTrailingStop,m_symbol.Digits()))
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(m_symbol.Ask()+ExtTrailingStop),
                           m_position.TakeProfit()))
                          {
                           //RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                     continue;
                    }
                  //--- tunnel crossed, move stop to above the tunnel; 
                  if(m_position.StopLoss()>ma_vegas_slow[0]+(ExtTunnelBandWidth+ExtStopLossToFibo) && 
                     !CompareDoubles(m_position.StopLoss(),ma_vegas_slow[0]+(ExtTunnelBandWidth+ExtStopLossToFibo),m_symbol.Digits()))
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(ma_vegas_slow[0]+(ExtTunnelBandWidth+ExtStopLossToFibo)),
                        m_position.TakeProfit()))
                       {
                        //RefreshRates();
                        m_position.SelectByIndex(i);
                        PrintResultModify(m_trade,m_symbol,m_position);
                       }
                  continue;
                 }
               else
                 {
                  if(m_symbol.Ask()<=(ma_vegas_slow[0]+ExtTrailingStep1))
                    {
                     if(m_position.StopLoss()>ma_vegas_slow[0]+(ExtTrailingStep1+ExtStopLossToFibo) && 
                        !CompareDoubles(m_position.StopLoss(),ma_vegas_slow[0]+(ExtTrailingStep1+ExtStopLossToFibo),m_symbol.Digits()))
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(ma_vegas_slow[0]+(ExtTrailingStep1+ExtStopLossToFibo)),
                           m_position.TakeProfit()))
                          {
                           //RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                     continue;
                    }
                  //--- reach 2nd TP level, close the 2nd lot, move up remainder stop to InpTrailingStep2-ExtStopLossToFibo
                  //--- or start trailing stop
                  else if(m_symbol.Ask()<=(ma_vegas_slow[0]+ExtTrailingStep2))
                    {
                     if(m_position.StopLoss()>ma_vegas_slow[0]+(ExtTrailingStep2+ExtStopLossToFibo) && 
                        !CompareDoubles(m_position.StopLoss(),ma_vegas_slow[0]+(ExtTrailingStep2+ExtStopLossToFibo),m_symbol.Digits()))
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(ma_vegas_slow[0]+(ExtTrailingStep2+ExtStopLossToFibo)),
                           m_position.TakeProfit()))
                          {
                           //RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                     continue;
                    }
                  //--- reach 1nd TP level, close the 1st lot, move up remainder stop to InpTrailingStep1-ExtStopLossToFibo
                  else if(m_symbol.Ask()<=(ma_vegas_slow[0]+ExtTrailingStep3))
                    {
                     if(m_position.StopLoss()>ma_vegas_slow[0]+(ExtTrailingStep3+ExtStopLossToFibo) && 
                        !CompareDoubles(m_position.StopLoss(),ma_vegas_slow[0]+(ExtTrailingStep3+ExtStopLossToFibo),m_symbol.Digits()))
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(ma_vegas_slow[0]+(ExtTrailingStep3+ExtStopLossToFibo)),
                           m_position.TakeProfit()))
                          {
                           //RefreshRates();
                           m_position.SelectByIndex(i);
                           PrintResultModify(m_trade,m_symbol,m_position);
                          }
                     continue;
                    }
                 }
              }
           }
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//---

  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates(void)
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print("RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Check the correctness of the position volume                     |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=m_symbol.LotsMin();
   if(volume<min_volume)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем меньше минимально допустимого SYMBOL_VOLUME_MIN=%.2f",min_volume);
      else
         error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }
//--- maximal allowed volume of trade operations
   double max_volume=m_symbol.LotsMax();
   if(volume>max_volume)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем больше максимально допустимого SYMBOL_VOLUME_MAX=%.2f",max_volume);
      else
         error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }
//--- get minimal step of volume changing
   double volume_step=m_symbol.LotsStep();
   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем не кратен минимальному шагу SYMBOL_VOLUME_STEP=%.2f, ближайший правильный объем %.2f",
                                        volume_step,ratio*volume_step);
      else
         error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                        volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
   return(true);
  }
//+------------------------------------------------------------------+
//| Get value of buffers                                             |
//+------------------------------------------------------------------+
double iGetArray(const int handle,const int buffer,const int start_pos,const int count,double &arr_buffer[])
  {
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
      Print("This a no dynamic array!");
      return(false);
     }
   ArrayFree(arr_buffer);
//--- reset error code 
   ResetLastError();
//--- fill a part of the iBands array with values from the indicator buffer
   int copied=CopyBuffer(handle,buffer,start_pos,count,arr_buffer);
   if(copied!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
   return(result);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double long_lot=InpLots;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check= m_account.FreeMarginCheck(m_symbol.Name(),ORDER_TYPE_BUY,long_lot,m_symbol.Ask());
   double margin_check     = m_account.MarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,long_lot,m_symbol.Bid());
   if(free_margin_check>margin_check)
     {
      if(m_trade.Buy(long_lot,m_symbol.Name(),m_symbol.Ask(),sl,tp))
        {
         if(m_trade.ResultDeal()==0)
           {
            Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
         else
           {
            Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of result: ",m_trade.ResultRetcodeDescription());
         PrintResultTrade(m_trade,m_symbol);
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CAccountInfo::FreeMarginCheck returned the value ",DoubleToString(free_margin_check,2));
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double short_lot=InpLots;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check= m_account.FreeMarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,short_lot,m_symbol.Bid());
   double margin_check     = m_account.MarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,short_lot,m_symbol.Bid());
   if(free_margin_check>margin_check)
     {
      if(m_trade.Sell(short_lot,m_symbol.Name(),m_symbol.Bid(),sl,tp))
        {
         if(m_trade.ResultDeal()==0)
           {
            Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
         else
           {
            Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of result: ",m_trade.ResultRetcodeDescription());
         PrintResultTrade(m_trade,m_symbol);
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CAccountInfo::FreeMarginCheck returned the value ",DoubleToString(free_margin_check,2));
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultTrade(CTrade &trade,CSymbolInfo &symbol)
  {
   Print("File: ",__FILE__,", symbol: ",m_symbol.Name());
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result as a string: "+trade.ResultRetcodeDescription());
   Print("Deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("Order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("Volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("Price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("Current bid price: "+DoubleToString(symbol.Bid(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("Current ask price: "+DoubleToString(symbol.Ask(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("Broker comment: "+trade.ResultComment());
  }
//+------------------------------------------------------------------+
//| Compare doubles                                                  |
//+------------------------------------------------------------------+
bool CompareDoubles(double number1,double number2,int digits)
  {
   digits--;
   if(digits<0)
      digits=0;
   if(NormalizeDouble(number1-number2,digits)==0)
      return(true);
   else
      return(false);
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultModify(CTrade &trade,CSymbolInfo &symbol,CPositionInfo &position)
  {
   Print("File: ",__FILE__,", symbol: ",m_symbol.Name());
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result as a string: "+trade.ResultRetcodeDescription());
   Print("Deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("Order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("Volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("Price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("Current bid price: "+DoubleToString(symbol.Bid(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("Current ask price: "+DoubleToString(symbol.Ask(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("Broker comment: "+trade.ResultComment());
   Print("Price of position opening: "+DoubleToString(position.PriceOpen(),symbol.Digits()));
   Print("Price of position's Stop Loss: "+DoubleToString(position.StopLoss(),symbol.Digits()));
   Print("Price of position's Take Profit: "+DoubleToString(position.TakeProfit(),symbol.Digits()));
   Print("Current price by position: "+DoubleToString(position.PriceCurrent(),symbol.Digits()));
   int d=0;
  }
//+------------------------------------------------------------------+

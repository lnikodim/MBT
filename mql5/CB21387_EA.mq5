//+------------------------------------------------------------------+
//|                      Arttrader_v1_5(barabashkakvn's edition).mq5 |
//+------------------------------------------------------------------+
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
CDealInfo      m_deal;                       // deals object
COrderInfo     m_order;                      // pending orders object
CMoneyFixedMargin *m_money;
//--- input parameters
//--- variables that can be changed outside the program code, even optimized
input double   NUM_LOTS       = 1.0;         // How many lots to deal with (may be less than one)
input int      EMA_SPEED      = 11.0;        // The period for the averager
input ushort   BIG_JUMP       = 30.0;        // Check for too-big candlesticks (avoid them)
input ushort   DOUBLE_JUMP    = 55.0;        // Check for pairs of big candlesticks
input ushort   STOP_LOSS      = 20.0;        // A smart stop-loss
input ushort   EMERGENCY_LOSS = 50.0;        // The trade's stop loss in case of program error
input ushort   TAKE_PROFIT    = 25.0;        // The trade's take profit
input ushort   SLOPE_SMALL    = 5.0;         // The minimum EMA slope to enter a trade
input ushort   SLOPE_LARGE    = 8.0;         // The maximum EMA slope to enter a trade
input int      MINUTES_BEGIN  = 25.0;        // Wait this long to determine candlestick lows/highs
input int      MINUTES_END    = 25.0;        // Wait this long to determine candlestick lows/highs
input ushort   SLIP_BEGIN     = 0.0;         // An allowance between the close and low/high price
input ushort   SLIP_END       = 0.0;         // An allowance between the close and low/high price
input long     MIN_VOLUME     = 0.0;         // If the previous volume is not above this, exit the trade
input ushort   ADJUST         = 1.0;         // A strange but functional imaginary spread adjustment
input ulong    m_magic        = 120600896;   // magic number
//---
ulong          m_slippage=10;                // slippage

double         ExtBIG_JUMP=0.0;
double         ExtDOUBLE_JUMP=0.0;
double         ExtSTOP_LOSS=0.0;
double         ExtEMERGENCY_LOSS=0.0;
double         ExtTAKE_PROFIT=0.0;
double         ExtSLOPE_SMALL=0.0;
double         ExtSLOPE_LARGE=0.0;
double         ExtSLIP_BEGIN=0.0;
double         ExtSLIP_END=0.0;
double         ExtADJUST=0.0;

int            handle_iMA;                   // variable for storing the handle of the iMA indicator 

double         m_adjusted_point;             // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();

   string err_text="";
   if(!CheckVolumeValue(NUM_LOTS,err_text))
     {
      Print(__FUNCTION__,", ERROR: ",err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
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

   ExtBIG_JUMP       = BIG_JUMP        * m_adjusted_point;
   ExtDOUBLE_JUMP    = DOUBLE_JUMP     * m_adjusted_point;
   ExtSTOP_LOSS      = STOP_LOSS       * m_adjusted_point;
   ExtEMERGENCY_LOSS = EMERGENCY_LOSS  * m_adjusted_point;
   ExtTAKE_PROFIT    = TAKE_PROFIT     * m_adjusted_point;
   ExtSLOPE_SMALL    = SLOPE_SMALL     * m_adjusted_point;
   ExtSLOPE_LARGE    = SLOPE_LARGE     * m_adjusted_point;
   ExtSLIP_BEGIN     = SLIP_BEGIN      * m_adjusted_point;
   ExtSLIP_END       = SLIP_END        * m_adjusted_point;
   ExtADJUST         = ADJUST          * m_adjusted_point;
//--- create handle of the indicator iMA
   handle_iMA=iMA(m_symbol.Name(),PERIOD_H1,EMA_SPEED,0,MODE_EMA,PRICE_OPEN);
//--- if the handle is not created 
   if(handle_iMA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
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
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   int ticket;
   double ema_old,ema_new,ema_slope;
   double begin_buy_chance,begin_sell_chance;
   double end_buy_chance,end_sell_chance;
   static double open_price;
//---
   begin_buy_chance=0; begin_sell_chance=0;
   end_buy_chance=0; end_sell_chance=0; ticket=0;
//--- find the existing order, if there is one
   int count_buys=0;
   int count_sells=0;
   CalculateAllPositions(count_buys,count_sells);
   if(count_buys+count_sells>1)
     {
      //--- it's error, close all
      CloseAllPositions();
      return;
     }
   if(count_buys==1)
     {
      //--- if ticket=+1, this means a long position is in progress
      ticket=1;
     }
   if(count_sells==1)
     {
      //--- if ticket=-1, this means a short position is in progress
      ticket=-1;
     }
//--- find the exponentially-weighted average, and its derivative
   double ma_array[];
   ArraySetAsSeries(ma_array,true);
   if(!iMAGetArray(0,2,ma_array))
      return;
   ema_old  = ma_array[1];
   ema_new  = ma_array[0];
   ema_slope= ema_new-ema_old;
//---
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   if(CopyRates(m_symbol.Name(),Period(),0,6,rates)!=6)
      return;
//--- are conditions correct to go long?     
   if(ema_slope>=ExtSLOPE_SMALL)
     {
      if(ema_slope<=ExtSLOPE_LARGE)
        {
         MqlDateTime STimeCurrent;
         TimeToStruct(TimeCurrent(),STimeCurrent);
         if((STimeCurrent.min>MINUTES_BEGIN) && (rates[0].close<=rates[0].open) && 
            (rates[0].close<=rates[0].low+ExtSLIP_BEGIN))
           {
            begin_buy_chance=1;
           }
        }
     }
//--- are conditions correct to go short?
   if(ema_slope<=-ExtSLOPE_SMALL)
     {
      if(ema_slope>=-ExtSLOPE_LARGE)
        {
         MqlDateTime STimeCurrent;
         TimeToStruct(TimeCurrent(),STimeCurrent);
         if((STimeCurrent.min>MINUTES_BEGIN) && (rates[0].close>=rates[0].open) && 
            (rates[0].close>=rates[0].high-ExtSLIP_BEGIN))
           {
            begin_sell_chance=1;
           }
        }
     }
//--- was there a sudden jump? ignore it...
   if(MathAbs(rates[1].open-rates[0].open)>=ExtBIG_JUMP)
     {
      begin_buy_chance=0;
      begin_sell_chance=0;
     }
   if(MathAbs(rates[2].open-rates[1].open)>=ExtBIG_JUMP)
     {
      begin_buy_chance=0;
      begin_sell_chance=0;
     }
   if(MathAbs(rates[3].open-rates[2].open)>=ExtBIG_JUMP)
     {
      begin_buy_chance=0;
      begin_sell_chance=0;
     }
   if(MathAbs(rates[4].open-rates[3].open)>=ExtBIG_JUMP)
     {
      begin_buy_chance=0;
      begin_sell_chance=0;
     }
   if(MathAbs(rates[5].open-rates[4].open)>=ExtBIG_JUMP)
     {
      begin_buy_chance=0;
      begin_sell_chance=0;
     }
   if(MathAbs(rates[2].open-rates[0].open)>=ExtDOUBLE_JUMP)
     {
      begin_buy_chance=0;
      begin_sell_chance=0;
     }
   if(MathAbs(rates[3].open-rates[1].open)>=ExtDOUBLE_JUMP)
     {
      begin_buy_chance=0;
      begin_sell_chance=0;
     }
   if(MathAbs(rates[4].open-rates[2].open)>=ExtDOUBLE_JUMP)
     {
      begin_buy_chance=0;
      begin_sell_chance=0;
     }
   if(MathAbs(rates[5].open-rates[3].open)>=ExtDOUBLE_JUMP)
     {
      begin_buy_chance=0;
      begin_sell_chance=0;
     }
//--- implement a stop-loss
   if(ticket>0)
     {
      if(rates[0].close-open_price<=-ExtSTOP_LOSS)
        {
         MqlDateTime STimeCurrent;
         TimeToStruct(TimeCurrent(),STimeCurrent);
         if((STimeCurrent.min>MINUTES_END) && (rates[0].close>=rates[0].open) && 
            (rates[0].close>=rates[0].high-ExtSLIP_END))
           {
            end_buy_chance=1;
           }
        }
     }
//--- implement a stop-loss
   if(ticket<0)
     {
      if(open_price-rates[0].close<=-ExtSTOP_LOSS)
        {
         MqlDateTime STimeCurrent;
         TimeToStruct(TimeCurrent(),STimeCurrent);
         if((STimeCurrent.min>MINUTES_END) && (rates[0].close<=rates[0].open) && 
            (rates[0].close<=rates[0].low+ExtSLIP_END))
           {
            end_sell_chance=1;
           }
        }
     }
//--- prevent duplicate orders
   if(ticket>0)
      begin_buy_chance=0;
   if(ticket<0)
      begin_sell_chance=0;
//--- was there no volume last time?  if so, end the trade...
   if(iVolume(m_symbol.Name(),Period(),1)<=MIN_VOLUME)
     {
      if(ticket>0)
         end_buy_chance=1;
      if(ticket<0)
         end_sell_chance=1;
     }
//--- was a long-exit signaled?
   if(end_buy_chance>=1)
     {
      ticket=0;
      CloseAllPositions();
     }
//--- was a short-exit signaled?
   if(end_sell_chance>=1)
     {
      ticket=0;
      CloseAllPositions();
     }
//--- was a long-enter signaled?
   if(!RefreshRates())
      return;
   if(begin_buy_chance>=1)
     {
      double sl=(EMERGENCY_LOSS==0)?0.0:m_symbol.Ask()-ExtEMERGENCY_LOSS;
      if(sl>=m_symbol.Bid()) // incident: the position isn't opened yet, and has to be already closed
        {
         return;
        }
      double tp=(TAKE_PROFIT==0)?0.0:m_symbol.Ask()+ExtTAKE_PROFIT;
      OpenBuy(sl,tp);
      open_price=rates[0].open-ExtADJUST+(m_symbol.Bid()-m_symbol.Ask());
     }
//--- was a short-enter signaled?
   if(begin_sell_chance>=1)
     {
      double sl=(EMERGENCY_LOSS==0)?0.0:m_symbol.Bid()+ExtEMERGENCY_LOSS;
      if(sl<=m_symbol.Ask()) // incident: the position isn't opened yet, and has to be already closed
        {
         return;
        }
      double tp=(TAKE_PROFIT==0)?0.0:m_symbol.Bid()-ExtTAKE_PROFIT;
      OpenSell(sl,tp);
      open_price=rates[0].open+ExtADJUST+(m_symbol.Ask()-m_symbol.Bid());
     }
//---
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
//| Get value of buffers for the iMA in the array                    |
//+------------------------------------------------------------------+
bool iMAGetArray(const int start_pos,const int count,double &arr_buffer[])
  {
//---
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
      Print("This a no dynamic array!");
      return(false);
     }
   ArrayFree(arr_buffer);
   int       buffer_num=0;          // indicator buffer number 
//--- reset error code 
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index 
   int copied=CopyBuffer(handle_iMA,buffer_num,start_pos,count,arr_buffer);
   if(copied<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
   else if(copied<count)
     {
      PrintFormat("Moving Average indicator: %d elements from %d were copied",copied,count);
      DebugBreak();
      return(false);
     }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Calculate all positions Buy and Sell                             |
//+------------------------------------------------------------------+
void CalculateAllPositions(int &count_buys,int &count_sells)
  {
   count_buys=0;
   count_sells=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
               count_buys++;

            if(m_position.PositionType()==POSITION_TYPE_SELL)
               count_sells++;
           }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),NUM_LOTS,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=NUM_LOTS)
        {
         if(m_trade.Buy(NUM_LOTS,m_symbol.Name(),m_symbol.Ask(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print(__FUNCTION__,", #1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
            else
              {
               Print(__FUNCTION__,", #2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< How many lots to deal with (",DoubleToString(NUM_LOTS,2),")");
         return;
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
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
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),NUM_LOTS,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=NUM_LOTS)
        {
         if(m_trade.Sell(NUM_LOTS,m_symbol.Name(),m_symbol.Bid(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print(__FUNCTION__,", #1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
            else
              {
               Print(__FUNCTION__,", #2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< How many lots to deal with (",DoubleToString(NUM_LOTS,2),")");
         return;
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultTrade(CTrade &trade,CSymbolInfo &symbol)
  {
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

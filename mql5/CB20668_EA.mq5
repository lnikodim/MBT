//+------------------------------------------------------------------+
//|                                 PLC(barabashkakvn's edition).mq5 |
//|                            Copyright © 2012, Vyacheslav Barbakov |
//|                                                  barbakov@bk.ru/ |
//+------------------------------------------------------------------+
#property copyright "Vyacheslav Barbakov"
#property link      "barbakov@bk.ru"
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Trade\OrderInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
COrderInfo     m_order;                      // pending orders object
//--- input parameters
input ushort   InpShiftOHLC                  = 15;    // Shift OHLC (in pips)
input double   InpMinProfit                  = 7;     // Minimum Profit
input ushort   InpShiftPos                   = 43;    // Shift of Positions (in pips)
input double   InpLotsBuy                    = 0.01;  // Lots buy
input double   InpLotsSell                   = 0.01;  // Lots sell
input uchar    InpLotIncreaseRateFractalsM5  = 2;     // Lot increase rate Fractals M5 ("0" -> off)
input uchar    InpLotIncreaseRateFractalsH1  = 4;     // Lot increase rate Fractals H1 ("0" -> off)
input ulong    m_magic=15489;                // magic number
//---
ulong          m_slippage=10;                // slippage

double         ExtShiftOHLC=0.0;
double         ExtShiftPos=0.0;

int            handle_iFractals_M5;          // variable for storing the handle of the iFractals indicator 
int            handle_iFractals_H1;          // variable for storing the handle of the iFractals indicator 
double         m_adjusted_point;             // point value adjusted for 3 or 5 points
bool           m_delete_orders=false;        // true -> you must delete all pending orders
bool           m_close_positions=false;      // true -> you must close all positions
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
   if(!CheckVolumeValue(InpLotsBuy,err_text))
     {
      Print(__FUNCTION__,", ERROR: ",err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
   err_text="";
   if(!CheckVolumeValue(InpLotsSell,err_text))
     {
      Print(__FUNCTION__,", ERROR: ",err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   m_trade.SetExpertMagicNumber(m_magic);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
//---
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtShiftOHLC=InpShiftOHLC*m_adjusted_point;
   ExtShiftPos=InpShiftPos*m_adjusted_point;
//--- create handle of the indicator iFractals
   handle_iFractals_M5=iFractals(m_symbol.Name(),PERIOD_M5);
//--- if the handle is not created 
   if(handle_iFractals_M5==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iFractals indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_M5),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iFractals
   handle_iFractals_H1=iFractals(m_symbol.Name(),PERIOD_H1);
//--- if the handle is not created 
   if(handle_iFractals_H1==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iFractals indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_H1),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//---
   m_delete_orders=false;        // true -> you must delete all pending orders
   m_close_positions=false;      // true -> you must close all positions
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
   int      count_buy_stop    =0,   count_sell_stop   =0;
   int      count_buys        =0,   count_sells       =0;
   double   price_highest_buy =0.0, price_lowest_sell =0.0;
   if(m_delete_orders)
     {
      CalculatePendingOrders(count_buy_stop,count_sell_stop);
      if(count_buy_stop+count_sell_stop==0)
         m_delete_orders=false;        // true -> you must delete all pending orders
      else
        {
         DeleteAllPendingOrders();
         return;
        }
     }
   if(m_close_positions)
     {
      CalculateAllPositions(count_buys,price_highest_buy,count_sells,price_lowest_sell);
      if(count_buys+count_sells==0)
         m_close_positions=false;      // true -> you must close all positions
      else
        {
         CloseAllPositions();
         return;
        }
     }
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
//---
   double up_M5=0.0,down_M5=0.0;
   double up_H1=0.0,down_H1=0.0;
   if(!iFractalsUpDown(handle_iFractals_M5,up_M5,down_M5) || !iFractalsUpDown(handle_iFractals_H1,up_H1,down_H1))
      return;
   CalculateAllPositions(count_buys,price_highest_buy,count_sells,price_lowest_sell);
   Comment("\n Price highest buy: ",DoubleToString(price_highest_buy,m_symbol.Digits()),
           "\n Price lowest sell: ",DoubleToString(price_lowest_sell,m_symbol.Digits()));
//---
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int count=1;                  // data count to copy 
   int copied=CopyRates(m_symbol.Name(),Period(),1,count,rates);
   if(copied!=count)
      return;
//---
   double high_1  =rates[0].high+ExtShiftOHLC;
   double low_1   =rates[0].low-ExtShiftOHLC;

   CalculatePendingOrders(count_buy_stop,count_sell_stop);

   if((high_1-price_highest_buy>ExtShiftPos && price_highest_buy!=0.0) || (price_highest_buy==0.0 && count_buy_stop==0))
     {
      double lots_buy=InpLotsBuy;
      int case_high=0;
      if(high_1-up_M5>0)
         case_high=1;
      if(high_1-up_H1>0)
         case_high=2;
      switch(case_high)
        {
         case 0:
            lots_buy=InpLotsBuy;
            break;
         case 1:
            lots_buy=(InpLotIncreaseRateFractalsM5==0)?InpLotsBuy:InpLotIncreaseRateFractalsM5*InpLotsBuy;
            break;
         case 2:
            lots_buy=(InpLotIncreaseRateFractalsH1==0)?InpLotsBuy:InpLotIncreaseRateFractalsH1*InpLotsBuy;
            break;
        }
      lots_buy=LotCheck(lots_buy);
      if(lots_buy>0.0)
        {
         if(m_trade.BuyStop(lots_buy,m_symbol.NormalizePrice(high_1),m_symbol.Name()))
            Print("BUY_STOP - > true. ticket of order = ",m_trade.ResultOrder());
         else
            Print("BUY_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
                  ", ticket of order: ",m_trade.ResultOrder());
        }
     }
   if((price_lowest_sell-low_1>ExtShiftPos && price_lowest_sell!=0.0) || (price_lowest_sell==0.0 && count_sell_stop==0))
     {
      double lots_sell=InpLotsSell;
      int case_low=0;
      if(down_M5-low_1>0)
         case_low=1;
      if(down_H1-low_1>0)
         case_low=2;
      switch(case_low)
        {
         case 0:
            lots_sell=InpLotsSell;
            break;
         case 1:
            lots_sell=(InpLotIncreaseRateFractalsM5==0)?InpLotsSell:InpLotIncreaseRateFractalsM5*InpLotsSell;
            break;
         case 2:
            lots_sell=(InpLotIncreaseRateFractalsH1==0)?InpLotsSell:InpLotIncreaseRateFractalsH1*InpLotsSell;
            break;
        }
      lots_sell=LotCheck(lots_sell);
      if(lots_sell>0.0)
        {
         if(m_trade.SellStop(lots_sell,m_symbol.NormalizePrice(low_1),m_symbol.Name()))
            Print("SELL_STOP - > true. ticket of order = ",m_trade.ResultOrder());
         else
            Print("SELL_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
                  ", ticket of order: ",m_trade.ResultOrder());
        }
     }
//--- calculate profit
   double profit=0.0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            profit+=m_position.Commission()+m_position.Swap()+m_position.Profit();
   if(profit>InpMinProfit)
      m_close_positions=true;       // true -> you must close all positions
//---

  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//--- get transaction type as enumeration value 
   ENUM_TRADE_TRANSACTION_TYPE type=trans.type;
//--- if transaction is result of addition of the transaction in history
   if(type==TRADE_TRANSACTION_DEAL_ADD)
     {
      long     deal_ticket       =0;
      long     deal_order        =0;
      long     deal_time         =0;
      long     deal_time_msc     =0;
      long     deal_type         =-1;
      long     deal_entry        =-1;
      long     deal_magic        =0;
      long     deal_reason       =-1;
      long     deal_position_id  =0;
      double   deal_volume       =0.0;
      double   deal_price        =0.0;
      double   deal_commission   =0.0;
      double   deal_swap         =0.0;
      double   deal_profit       =0.0;
      string   deal_symbol       ="";
      string   deal_comment      ="";
      string   deal_external_id  ="";
      if(HistoryDealSelect(trans.deal))
        {
         deal_ticket       =HistoryDealGetInteger(trans.deal,DEAL_TICKET);
         deal_order        =HistoryDealGetInteger(trans.deal,DEAL_ORDER);
         deal_time         =HistoryDealGetInteger(trans.deal,DEAL_TIME);
         deal_time_msc     =HistoryDealGetInteger(trans.deal,DEAL_TIME_MSC);
         deal_type         =HistoryDealGetInteger(trans.deal,DEAL_TYPE);
         deal_entry        =HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
         deal_magic        =HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
         deal_reason       =HistoryDealGetInteger(trans.deal,DEAL_REASON);
         deal_position_id  =HistoryDealGetInteger(trans.deal,DEAL_POSITION_ID);

         deal_volume       =HistoryDealGetDouble(trans.deal,DEAL_VOLUME);
         deal_price        =HistoryDealGetDouble(trans.deal,DEAL_PRICE);
         deal_commission   =HistoryDealGetDouble(trans.deal,DEAL_COMMISSION);
         deal_swap         =HistoryDealGetDouble(trans.deal,DEAL_SWAP);
         deal_profit       =HistoryDealGetDouble(trans.deal,DEAL_PROFIT);

         deal_symbol       =HistoryDealGetString(trans.deal,DEAL_SYMBOL);
         deal_comment      =HistoryDealGetString(trans.deal,DEAL_COMMENT);
         deal_external_id  =HistoryDealGetString(trans.deal,DEAL_EXTERNAL_ID);
        }
      else
         return;
      if(deal_reason!=-1)
         int d=0;;
      if(deal_symbol==m_symbol.Name() && deal_magic==m_magic)
         if(deal_entry==DEAL_ENTRY_IN)
            if(deal_type==DEAL_TYPE_BUY || deal_type==DEAL_TYPE_SELL)
               m_delete_orders=true;         // true -> you must delete all pending orders
     }
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
      error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }
//--- maximal allowed volume of trade operations
   double max_volume=m_symbol.LotsMax();
   if(volume>max_volume)
     {
      error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }
//--- get minimal step of volume changing
   double volume_step=m_symbol.LotsStep();
   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                     volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Checks if the specified filling mode is allowed                  | 
//+------------------------------------------------------------------+ 
bool IsFillingTypeAllowed(int fill_type)
  {
//--- Obtain the value of the property that describes allowed filling modes 
   int filling=m_symbol.TradeFillFlags();
//--- Return true, if mode fill_type is allowed 
   return((filling & fill_type)==fill_type);
  }
//+------------------------------------------------------------------+
//| Lot Check                                                        |
//+------------------------------------------------------------------+
double LotCheck(double lots)
  {
//--- calculate maximum volume
   double volume=NormalizeDouble(lots,2);
   double stepvol=m_symbol.LotsStep();
   if(stepvol>0.0)
      volume=stepvol*MathFloor(volume/stepvol);
//---
   double minvol=m_symbol.LotsMin();
   if(volume<minvol)
      volume=0.0;
//---
   double maxvol=m_symbol.LotsMax();
   if(volume>maxvol)
      volume=maxvol;
   return(volume);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iFractals                           |
//|  the buffer numbers are the following:                           |
//|   0 - UPPER_LINE, 1 - LOWER_LINE                                 |
//+------------------------------------------------------------------+
bool iFractalsUpDown(const int handle_iFractals,double &up,double &down)
  {
   up=down=0.0;
   double buffer_up_fractals[];
   double buffer_down_fractals[];
   ArraySetAsSeries(buffer_up_fractals,true);
   ArraySetAsSeries(buffer_down_fractals,true);
//--- reset error code 
   ResetLastError();
   int      start_pos   = 3;              // start position 
   int      count       = 100;            // amount to copy 
//--- fill a part of the iFractalsBuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iFractals,UPPER_LINE,start_pos,count,buffer_up_fractals)!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iFractals indicator (UP), error code %d",GetLastError());
      //--- quit with false result - it means that the indicator is considered as not calculated 
      return(false);
     }
//--- fill a part of the iFractalsBuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iFractals,LOWER_LINE,start_pos,count,buffer_down_fractals)!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iFractals indicator (DOWN), error code %d",GetLastError());
      //--- quit with false result - it means that the indicator is considered as not calculated 
      return(false);
     }
//---
   for(int i=0;i<count;i++)
     {
      if(buffer_up_fractals[i]!=0.0 && buffer_up_fractals[i]!=EMPTY_VALUE)
         if(up==0.0)
            up=buffer_up_fractals[i];
      if(buffer_down_fractals[i]!=0.0 && buffer_down_fractals[i]!=EMPTY_VALUE)
         if(down==0.0)
            down=buffer_down_fractals[i];
      //---
      if(up!=0.0 && down!=0.0)
         break;
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Calculate all positions                                          |
//+------------------------------------------------------------------+
void CalculateAllPositions(int &count_buys,double &price_highest_buy,
                           int &count_sells,double &price_lowest_sell)
  {
   count_buys  =0;   price_highest_buy =DBL_MIN;
   count_sells =0;   price_lowest_sell =DBL_MAX;
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               count_buys++;
               if(m_position.PriceOpen()>price_highest_buy) // the highest position of "BUY" is found
                  price_highest_buy=m_position.PriceOpen();
               continue;
              }
            else if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               count_sells++;
               if(m_position.PriceOpen()<price_lowest_sell) // the lowest position of "SELL" is found
                  price_lowest_sell=m_position.PriceOpen();
               continue;
              }
           }
  }
//+------------------------------------------------------------------+ 
//| Get Time for specified bar index                                 | 
//+------------------------------------------------------------------+ 
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[1];
   datetime time=0; // datetime "0" -> D'1970.01.01 00:00:00'
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0)
      time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+
//| Calculate BUY STOP and SELL STOP                                 |
//+------------------------------------------------------------------+
void CalculatePendingOrders(int &count_buy_stop,int &count_sell_stop)
  {
   count_buy_stop=0;
   count_sell_stop=0;

   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
           {
            if(m_order.OrderType()==ORDER_TYPE_BUY_STOP)
               count_buy_stop++;

            if(m_order.OrderType()==ORDER_TYPE_SELL_STOP)
               count_sell_stop++;
           }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Delete all pending orders                                        |
//+------------------------------------------------------------------+
void DeleteAllPendingOrders(void)
  {
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            m_trade.OrderDelete(m_order.Ticket());
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

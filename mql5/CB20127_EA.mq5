//+------------------------------------------------------------------+
//|                  Fractured Fractals(barabashkakvn's edition).mq5 |
//|                 Copyright © 2005, tageiger aka fxid10t@yahoo.com |
//|                MetaTrader_Experts_and_Indicators@yahoogroups.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, tageiger aka fxid10t@yahoo.com"
#property link      "MetaTrader_Experts_and_Indicators@yahoogroups.com"
#property version   "1.002"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\OrderInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
CDealInfo      m_deal;                       // deals object
COrderInfo     m_order;                      // pending orders object
//--- input parameters
input double   MaximumRisk    = 0.02;        // Maximum Risk in percentage
input double   DecreaseFactor = 10;          // Descrease factor
input uchar    Expiration     = 1;           // Life time of the pending order (in hours)
input ulong    m_magic        = 375558442;   // magic number
//---
double         fractal_upper,fractal_lower,cfu,pfu,cfd,pfd;
double         Up_youngest,Up_middle,Up_old,Down_youngest,Down_middle,Down_old;
//---
datetime       last_pforit_deal=0;           // date of last profit deal
int            handle_iFractals;             // variable for storing the handle of the iFractals indicator          
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();
//---
   m_trade.SetExpertMagicNumber(m_magic);
//---
   if(IsFillingTypeAllowed(SYMBOL_FILLING_FOK))
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if(IsFillingTypeAllowed(SYMBOL_FILLING_IOC))
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
//--- create handle of the indicator iFractals
   handle_iFractals=iFractals(m_symbol.Name(),Period());
//--- if the handle is not created 
   if(handle_iFractals==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iFractals indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//---
   last_pforit_deal=LastProfitDeal();
   fractal_upper=fractal_lower=cfu=pfu=cfd=pfd=Up_youngest=Up_middle=Up_old=Down_youngest=Down_middle=Down_old=EMPTY_VALUE;
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
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
//---
   fractal_upper=iFractalsGet(UPPER_LINE,3);
   fractal_lower=iFractalsGet(LOWER_LINE,3);
//----
   if(fractal_upper!=EMPTY_VALUE && !CompareDoubles(cfu,fractal_upper,m_symbol.Digits()))
     {
      cfu=fractal_upper; Up_old=Up_middle;Up_middle=Up_youngest;Up_youngest=cfu;
     }
   if(fractal_lower!=EMPTY_VALUE && !CompareDoubles(cfd,fractal_lower,m_symbol.Digits()))
     {
      cfd=fractal_lower; Down_old=Down_middle;Down_middle=Down_youngest;Down_youngest=cfd;
     }
   PrintComments();
//---
   int count_buys=0;
   int count_sells=0;
   CalculatePositions(count_buys,count_sells);
   int count_buy_stop=0;
   int count_sell_stop=0;
   CalculatePendingOrders(count_buy_stop,count_sell_stop);
   if(count_buys+count_buy_stop==0 && cfu!=EMPTY_VALUE && 
      Up_youngest!=EMPTY_VALUE && Up_middle!=EMPTY_VALUE && Up_youngest>Up_middle)
     {
      double lot=TradeSizeOptimized(ORDER_TYPE_BUY,cfu);
      if(lot==0.0)
         return;
      datetime expiration=TimeCurrent()+Expiration*3600;
      if(m_trade.BuyStop(lot,cfu,m_symbol.Name(),cfd,0.0,ORDER_TIME_SPECIFIED,expiration))
         Print("BUY_STOP - > true. ticket of order = ",m_trade.ResultOrder());
      else
         Print("BUY_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
               ", ticket of order: ",m_trade.ResultOrder());
      return;
     }
   if(count_sells+count_sell_stop==0 && cfd!=EMPTY_VALUE && Down_youngest!=EMPTY_VALUE && 
      Down_middle!=EMPTY_VALUE && Down_youngest<Down_middle)
     {
      double lot=TradeSizeOptimized(ORDER_TYPE_SELL,cfd);
      if(lot==0.0)
         return;
      datetime expiration=TimeCurrent()+Expiration*3600;
      if(m_trade.SellStop(lot,cfd,m_symbol.Name(),cfu,0.0,ORDER_TIME_SPECIFIED,expiration))
         Print("SELL_STOP - > true. ticket of order = ",m_trade.ResultOrder());
      else
         Print("SELL_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
               ", ticket of order: ",m_trade.ResultOrder());
      return;
     }
//---
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(!CompareDoubles(Down_youngest,m_position.StopLoss(),m_symbol.Digits()))
                  if(Down_youngest>m_position.StopLoss())
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        Down_youngest,
                        m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                     continue;
                    }
              }
            else
              {
               if(!CompareDoubles(Up_youngest,m_position.StopLoss(),m_symbol.Digits()))
                  if(Up_youngest<m_position.StopLoss())
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        Up_youngest,
                        m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
              }

           }
//---
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
           {
            if(m_order.OrderType()==ORDER_TYPE_BUY_STOP)
              {
               if(!CompareDoubles(Up_youngest,m_order.PriceOpen(),m_symbol.Digits()) && Up_youngest<m_order.PriceOpen())
                  m_trade.OrderDelete(m_order.Ticket());
              }
            else if(m_order.OrderType()==ORDER_TYPE_SELL_STOP)
              {
               if(!CompareDoubles(Down_youngest,m_order.PriceOpen(),m_symbol.Digits()) && Down_youngest>m_order.PriceOpen())
                  m_trade.OrderDelete(m_order.Ticket());
              }
           }
//---
   return;
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
//| Get Time for specified bar index                                 | 
//+------------------------------------------------------------------+ 
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[1];
   datetime time=0;
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0)
      time=Time[0];
   return(time);
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
      volume=m_symbol.LotsMin();
//---
   double maxvol=m_symbol.LotsMax();
   if(volume>maxvol)
      volume=maxvol;
   return(volume);
  }
//+------------------------------------------------------------------+
//| Get date of the last profit deal                                 |
//+------------------------------------------------------------------+
datetime LastProfitDeal(void)
  {
   datetime result=0;
//--- select history for access
   HistorySelect(0,TimeCurrent()+86400);
//---
   int deals=HistoryDealsTotal();      // total history deals

   for(int i=deals-1;i>=0;i--)
     {
      ulong ticket=HistoryDealGetTicket(i);
      if(ticket==0)
        {
         Print("HistoryDealGetTicket failed, no trade history");
         break;
        }
      //--- debug
      datetime time=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
      //--- check symbol
      if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=m_symbol.Name())
         continue;
      //--- check Expert Magic number
      if(HistoryDealGetInteger(ticket,DEAL_MAGIC)!=m_magic)
         continue;
      //--- check entry
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY)!=DEAL_ENTRY_OUT)
         continue;
      //--- check profit
      double profit=HistoryDealGetDouble(ticket,DEAL_COMMISSION)+
                    HistoryDealGetDouble(ticket,DEAL_SWAP)+
                    HistoryDealGetDouble(ticket,DEAL_PROFIT);
      if(profit>0.0)
         return(time);
     }
   return(result);
//---
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iFractals                           |
//|  the buffer numbers are the following:                           |
//|   0 - UPPER_LINE, 1 - LOWER_LINE                                 |
//+------------------------------------------------------------------+
double iFractalsGet(const int buffer,const int index)
  {
   double Fractals[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iFractalsBuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iFractals,buffer,index,1,Fractals)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iFractals indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Fractals[0]);
  }
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double TradeSizeOptimized(const ENUM_ORDER_TYPE trade_operation,const double price)
  {
   double margin=0.0;
   double lots=0.0;
//--- calculate margin requirements for 1 lot
   if(!OrderCalcMargin(trade_operation,m_symbol.Name(),1.0,price,margin) || margin<=0.0)
     {
      return(0.0);
     }
//---
   lots=m_account.FreeMargin()*MaximumRisk/margin;
//--- calculate number of losses orders without a break
   if(DecreaseFactor>0)
     {
      //--- select history for access
      HistorySelect(last_pforit_deal-60,TimeCurrent()+86400);
      //---
      int    orders=HistoryDealsTotal();  // total history deals
      int    losses=0;                    // number of losses orders without a break

      for(int i=orders-1;i>=0;i--)
        {
         ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0)
           {
            Print("HistoryDealGetTicket failed, no trade history");
            break;
           }
         //--- debug
         datetime time=(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         //--- check symbol
         if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=m_symbol.Name())
            continue;
         //--- check Expert Magic number
         if(HistoryDealGetInteger(ticket,DEAL_MAGIC)!=m_magic)
            continue;
         //--- check profit
         double profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         if(profit>0.0)
            break;
         if(profit<0.0)
            losses++;
        }
      //---
      if(losses>1)
         lots=lots-lots*(double)losses/DecreaseFactor;
     }
//--- return normalize and check limits
   return(LotCheck(lots));
  }
//+------------------------------------------------------------------+
//| Calculate positions Buy and Sell                                 |
//+------------------------------------------------------------------+
void CalculatePositions(int &count_buys,int &count_sells)
  {
   count_buys=0.0;
   count_sells=0.0;

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
//| Calculate pending orders                                         |
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
            else if(m_order.OrderType()==ORDER_TYPE_SELL_STOP)
               count_sell_stop++;
           }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Compare doubles                                                  |
//+------------------------------------------------------------------+
bool CompareDoubles(double number1,double number2,int digits)
  {
   if(NormalizeDouble(number1-number2,digits)==0)
      return(true);
   else
      return(false);
  }
//+------------------------------------------------------------------+
//| Print comments                                                   |
//+------------------------------------------------------------------+
void PrintComments()
  {
   Comment("Current Time: ",TimeToString(TimeCurrent(),TIME_MINUTES),"\n",
           "Up youngest ",Up_youngest,"\n",
           "Up middle ",Up_middle,"\n",
           "Up old ",Up_old,"\n",
           "Down youngest ",Down_youngest,"\n",
           "Down middle ",Down_middle,"\n",
           "Down old ",Down_old);
  }
//+------------------------------------------------------------------+

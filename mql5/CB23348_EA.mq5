//+------------------------------------------------------------------+
//|                                                Hoop master 2.mq5 |
//|                              Copyright © 2018, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
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
input int      InpLots           = 1;        // Min lots
input ushort   InpStopLoss       = 25;       // Stop Loss, in pips (1.00045-1.00055=1 pips)
input ushort   InpTakeProfit     = 70;       // Take Profit, in pips (1.00045-1.00055=1 pips)
input ushort   InpTrailingStop   = 0;        // Trailing Stop (min distance from price to Stop Loss, in pips
input ushort   InpTrailingStep   = 5;        // Trailing Step, in pips (1.00045-1.00055=1 pips)
input ushort   InpIndent         = 15;       // Indent, in pips (1.00045-1.00055=1 pips)
input bool     InpPrintLog       = false;    // Print log
input ulong    m_magic=46207360;             // magic number
//---
ulong  m_slippage=10;                        // slippage
double ExtStopLoss               = 0.0;
double ExtTakeProfit             = 0.0;
double ExtTrailingStop           = 0.0;
double ExtTrailingStep           = 0.0;
double ExtIndent                 = 0.0;
double ExtLot                    = 0.0;
double m_adjusted_point;                     // point value adjusted for 3 or 5 points
bool   m_need_delete_buy_stop    = false;
bool   m_need_delete_sell_stop   = false;
bool   m_need_place_buy_stop     = false;
bool   m_need_place_sell_stop    = false;
double m_max_equity=0.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   m_max_equity=m_account.Equity();
//---
   if(InpTrailingStop!=0 && InpTrailingStep==0)
     {
      string err_text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                      "Трейлинг невозможен: параметр \"Trailing Step\" равен нулю!":
                      "Trailing is not possible: parameter \"Trailing Step\" is zero!";
      //--- when testing, we will only output to the log about incorrect input parameters
      if(MQLInfoInteger(MQL_TESTER))
        {
         Print(__FUNCTION__,", ERROR: ",err_text);
         return(INIT_FAILED);
        }
      else // if the Expert Advisor is run on the chart, tell the user about the error
        {
         Alert(__FUNCTION__,", ERROR: ",err_text);
         return(INIT_PARAMETERS_INCORRECT);
        }
     }
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

   ExtStopLoss       = InpStopLoss        * m_adjusted_point;
   ExtTakeProfit     = InpTakeProfit      * m_adjusted_point;
   ExtTrailingStop   = InpTrailingStop    * m_adjusted_point;
   ExtTrailingStep   = InpTrailingStep    * m_adjusted_point;
   ExtIndent         = InpIndent          * m_adjusted_point;
   ExtLot            = m_symbol.LotsMin()*(double)InpLots;
//--- check the input parameter "Lots"
   string err_text="";
   if(!CheckVolumeValue(ExtLot,err_text))
     {
      //--- when testing, we will only output to the log about incorrect input parameters
      if(MQLInfoInteger(MQL_TESTER))
        {
         Print(__FUNCTION__,", ERROR: ",err_text);
         return(INIT_FAILED);
        }
      else // if the Expert Advisor is run on the chart, tell the user about the error
        {
         Alert(__FUNCTION__,", ERROR: ",err_text);
         return(INIT_PARAMETERS_INCORRECT);
        }
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
   if(m_need_delete_buy_stop || m_need_delete_sell_stop)
     {
      int count_buy_stops=0,count_sell_stops=0;
      CalculateAllPendingOrders(count_buy_stops,count_sell_stops);

      if(m_need_delete_buy_stop)
        {
         if(count_buy_stops>0)
           {
            double level;
            if(!FreezeStopsLevels(level))
               return;
            DeleteOrders(ORDER_TYPE_BUY_STOP,level);
            return;
           }
         else
           {
            m_need_delete_buy_stop=false;
            return;
           }
        }
      if(m_need_delete_sell_stop)
        {
         if(count_sell_stops>0)
           {
            double level;
            if(!FreezeStopsLevels(level))
               return;
            DeleteOrders(ORDER_TYPE_SELL_STOP,level);
            return;
           }
         else
           {
            m_need_delete_sell_stop=false;
            return;
           }
        }
     }
//---
   if(m_need_place_buy_stop || m_need_place_sell_stop)
     {
      int count_buy_stops=0,count_sell_stops=0;
      CalculateAllPendingOrders(count_buy_stops,count_sell_stops);

      if(m_need_place_buy_stop)
        {
         if(count_buy_stops==0)
           {
            double level;
            if(!FreezeStopsLevels(level))
               return;
            PlaceOrders(ORDER_TYPE_BUY_STOP,level);
            return;
           }
         else
           {
            m_need_place_buy_stop=false;
            return;
           }
        }
      if(m_need_place_sell_stop)
        {
         if(count_sell_stops==0)
           {
            double level;
            if(!FreezeStopsLevels(level))
               return;
            PlaceOrders(ORDER_TYPE_SELL_STOP,level);
            return;
           }
         else
           {
            m_need_place_sell_stop=false;
            return;
           }
        }
     }
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
   double level;
   if(!FreezeStopsLevels(level))
      PrevBars=0;

   int count_buy_stops=0,count_sell_stops=0;
   CalculateAllPendingOrders(count_buy_stops,count_sell_stops);
//---
   if(IsPositionExists())
     {
      //Trailing(level);
      m_need_delete_buy_stop=true;
      m_need_delete_sell_stop=true;
      return;
     }
   if(count_buy_stops+count_sell_stops==0)
     {
      m_need_place_buy_stop=true;
      m_need_place_sell_stop=true;
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
      if(deal_symbol==m_symbol.Name() && deal_magic==m_magic)
        {
         if(deal_entry==DEAL_ENTRY_IN)
           {
            if(deal_type==DEAL_TYPE_BUY || deal_volume==DEAL_TYPE_SELL)
              {
               m_need_delete_buy_stop  = true;
               m_need_delete_sell_stop = true;
               m_need_place_buy_stop   = true;
               m_need_place_sell_stop  = true;
              }
           }
         else if(deal_entry==DEAL_ENTRY_OUT)
           {
            if(m_account.Equity()<m_max_equity)
               ExtLot=deal_volume*2.0;
            else
              {
               m_max_equity=m_account.Equity();
               ExtLot=m_symbol.LotsMin()*(double)InpLots;
              }
            if(ExtLot>m_symbol.LotsMax() || ExtLot>=m_symbol.LotsLimit())
               ExtLot=m_symbol.LotsMin()*(double)InpLots;
           }
        }
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
//| Calculate all pending orders                                     |
//+------------------------------------------------------------------+
void CalculateAllPendingOrders(int &count_buy_stops,int &count_sell_stops)
  {
   count_buy_stops  = 0;
   count_sell_stops = 0;

   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
           {
            if(m_order.OrderType()==ORDER_TYPE_BUY_STOP)
               count_buy_stops++;
            else if(m_order.OrderType()==ORDER_TYPE_SELL_STOP)
               count_sell_stops++;
           }
  }
//+------------------------------------------------------------------+
//| Delete Orders                                                    |
//+------------------------------------------------------------------+
void DeleteOrders(const ENUM_ORDER_TYPE order_type,const double level)
  {
//--- check Freeze and Stops levels
/*
   Type of order/position  |  Activation price  |  Check
   ------------------------|--------------------|--------------------------------------------
   Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy Stop order          |  Ask	            |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Limit order        |  Bid	            |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Stop order	      |  Bid	            |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
*/
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            if(m_order.OrderType()==order_type)
              {
               if(!RefreshRates() || !m_symbol.Refresh())
                  continue;
               if(m_order.OrderType()==ORDER_TYPE_BUY_LIMIT)
                 {
                  if(m_symbol.Ask()-m_order.PriceOpen()>=level)
                     m_trade.OrderDelete(m_order.Ticket());
                  continue;
                 }
               if(m_order.OrderType()==ORDER_TYPE_BUY_STOP)
                 {
                  if(m_order.PriceOpen()-m_symbol.Ask()>=level)
                     m_trade.OrderDelete(m_order.Ticket());
                  continue;
                 }
               if(m_order.OrderType()==ORDER_TYPE_SELL_LIMIT)
                 {
                  if(m_order.PriceOpen()-m_symbol.Bid()>=level)
                     m_trade.OrderDelete(m_order.Ticket());
                  continue;
                 }
               if(m_order.OrderType()==ORDER_TYPE_SELL_STOP)
                 {
                  if(m_symbol.Bid()-m_order.PriceOpen()>=level)
                     m_trade.OrderDelete(m_order.Ticket());
                  continue;
                 }
              }
  }
//+------------------------------------------------------------------+
//| Is position exists                                               |
//+------------------------------------------------------------------+
bool IsPositionExists(void)
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Is pendinf orders exists                                         |
//+------------------------------------------------------------------+
bool IsPendingOrdersExists(void)
  {
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            return(true);
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Pending order                                                    |
//+------------------------------------------------------------------+
bool PendingOrder(ENUM_ORDER_TYPE order_type,double price,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   ENUM_ORDER_TYPE check_order_type=-1;
   switch(order_type)
     {
      case  ORDER_TYPE_BUY:
         check_order_type=ORDER_TYPE_BUY;
         break;
      case ORDER_TYPE_SELL:
         check_order_type=ORDER_TYPE_SELL;
         break;
      case ORDER_TYPE_BUY_LIMIT:
         check_order_type=ORDER_TYPE_BUY;
         break;
      case ORDER_TYPE_SELL_LIMIT:
         check_order_type=ORDER_TYPE_SELL;
         break;
      case ORDER_TYPE_BUY_STOP:
         check_order_type=ORDER_TYPE_BUY;
         break;
      case ORDER_TYPE_SELL_STOP:
         check_order_type=ORDER_TYPE_SELL;
         break;
      default:
         return(false);
         break;
     }
//---
   double long_lot   = ExtLot;
   double short_lot  = ExtLot;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_price=0;
   double check_lot=0;
   if(check_order_type==ORDER_TYPE_BUY)
     {
      check_price=m_symbol.Ask();
      check_lot=long_lot;
     }
   else
     {
      check_price=m_symbol.Bid();
      check_lot=short_lot;
     }
//---
   double free_margin_check=m_account.FreeMarginCheck(m_symbol.Name(),check_order_type,check_lot,check_price);
   if(free_margin_check>0.0)
     {
      if(m_trade.OrderOpen(m_symbol.Name(),order_type,check_lot,0.0,
         m_symbol.NormalizePrice(price),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp),ORDER_TIME_DAY))
        {
         if(m_trade.ResultOrder()==0)
           {
            if(InpPrintLog)
               Print("#1 ",EnumToString(order_type)," -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
            return(false);
           }
         else
           {
            Print("#2 ",EnumToString(order_type)," -> true. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
            return(true);
           }
        }
      else
        {
         if(InpPrintLog)
            Print("#3 ",EnumToString(order_type)," -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
         if(InpPrintLog)
            PrintResultTrade(m_trade,m_symbol);
         return(false);
        }
     }
   else
     {
      if(InpPrintLog)
         Print(__FUNCTION__,", ERROR: method CAccountInfo::FreeMarginCheck returned the value ",DoubleToString(free_margin_check,2));
      return(false);
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Trailing                                                         |
//|   InpTrailingStop: min distance from price to Stop Loss          |
//+------------------------------------------------------------------+
void Trailing(const double stop_level)
  {
/*
     Buying is done at the Ask price                 |  Selling is done at the Bid price
   ------------------------------------------------|----------------------------------
   TakeProfit        >= Bid                        |  TakeProfit        <= Ask
   StopLoss          <= Bid	                     |  StopLoss          >= Ask
   TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
   Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
*/
   if(InpTrailingStop==0)
      return;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtTrailingStop+ExtTrailingStep)
                  if(m_position.StopLoss()<m_position.PriceCurrent()-(ExtTrailingStop+ExtTrailingStep))
                     if(ExtTrailingStop>=stop_level)
                       {
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(m_position.PriceCurrent()-ExtTrailingStop),
                           m_position.TakeProfit()))
                           Print("Modify ",m_position.Ticket(),
                                 " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                 ", description of result: ",m_trade.ResultRetcodeDescription());
                        RefreshRates();
                        m_position.SelectByIndex(i);
                        PrintResultModify(m_trade,m_symbol,m_position);
                        continue;
                       }
              }
            else
              {
               if(m_position.PriceOpen()-m_position.PriceCurrent()>ExtTrailingStop+ExtTrailingStep)
                  if((m_position.StopLoss()>(m_position.PriceCurrent()+(ExtTrailingStop+ExtTrailingStep))) || 
                     (m_position.StopLoss()==0))
                     if(ExtTrailingStop>=stop_level)
                       {
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(m_position.PriceCurrent()+ExtTrailingStop),
                           m_position.TakeProfit()))
                           Print("Modify ",m_position.Ticket(),
                                 " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                 ", description of result: ",m_trade.ResultRetcodeDescription());
                        RefreshRates();
                        m_position.SelectByIndex(i);
                        PrintResultModify(m_trade,m_symbol,m_position);
                       }
              }

           }
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
   Print("Freeze Level: "+DoubleToString(m_symbol.FreezeLevel(),0),", Stops Level: "+DoubleToString(m_symbol.StopsLevel(),0));
   int d=0;
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
   Print("Freeze Level: "+DoubleToString(m_symbol.FreezeLevel(),0),", Stops Level: "+DoubleToString(m_symbol.StopsLevel(),0));
   Print("Price of position opening: "+DoubleToString(position.PriceOpen(),symbol.Digits()));
   Print("Price of position's Stop Loss: "+DoubleToString(position.StopLoss(),symbol.Digits()));
   Print("Price of position's Take Profit: "+DoubleToString(position.TakeProfit(),symbol.Digits()));
   Print("Current price by position: "+DoubleToString(position.PriceCurrent(),symbol.Digits()));
   int d=0;
  }
//+------------------------------------------------------------------+
//| Check Freeze and Stops levels                                    |
//+------------------------------------------------------------------+
bool FreezeStopsLevels(double &level)
  {
//--- check Freeze and Stops levels
/*
   Type of order/position  |  Activation price  |  Check
   ------------------------|--------------------|--------------------------------------------
   Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy Stop order          |  Ask	            |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Limit order        |  Bid	            |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Stop order	      |  Bid	            |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy position            |  Bid	            |  TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL 
                           |                    |  Bid-StopLoss   >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell position           |  Ask	            |  Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  StopLoss-Ask   >= SYMBOL_TRADE_FREEZE_LEVEL
                           
   Buying is done at the Ask price                 |  Selling is done at the Bid price
   ------------------------------------------------|----------------------------------
   TakeProfit        >= Bid                        |  TakeProfit        <= Ask
   StopLoss          <= Bid	                     |  StopLoss          >= Ask
   TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
   Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
*/
   if(!RefreshRates() || !m_symbol.Refresh())
      return(false);
//--- FreezeLevel -> for pending order and modification
   double freeze_level=m_symbol.FreezeLevel()*m_symbol.Point();
   if(freeze_level==0.0)
      freeze_level=(m_symbol.Ask()-m_symbol.Bid())*3.0;
   freeze_level*=1.1;
//--- StopsLevel -> for TakeProfit and StopLoss
   double stop_level=m_symbol.StopsLevel()*m_symbol.Point();
   if(stop_level==0.0)
      stop_level=(m_symbol.Ask()-m_symbol.Bid())*3.0;
   stop_level*=1.1;

   if(freeze_level<=0.0 || stop_level<=0.0)
      return(false);
//---
   level=(freeze_level>stop_level)?freeze_level:stop_level;
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Place Orders                                                     |
//+------------------------------------------------------------------+
void PlaceOrders(const ENUM_ORDER_TYPE order_type,const double level)
  {
//--- buy stop
   if(order_type==ORDER_TYPE_BUY_STOP)
     {
      double price=m_symbol.Ask()+ExtIndent;
      if(price-m_symbol.Ask()<level) // check price
         price=m_symbol.Ask()+level;

      double sl=(InpStopLoss==0)?0.0:price-ExtStopLoss;
      if(sl!=0.0 && ExtStopLoss<level)// check sl
         sl=price-level;

      double tp=(InpTakeProfit==0)?0.0:price+ExtTakeProfit;
      if(tp!=0.0 && ExtTakeProfit<level) // check price
         tp=price+ExtTakeProfit;

      PendingOrder(ORDER_TYPE_BUY_STOP,price,sl,tp);
     }
//--- sell stop
   if(order_type==ORDER_TYPE_SELL_STOP)
     {
      double price=m_symbol.Bid()-ExtIndent;
      if(m_symbol.Bid()-price<level) // check price
         price=m_symbol.Bid()-level;

      double sl=(InpStopLoss==0)?0.0:price+ExtStopLoss;
      if(sl!=0.0 && ExtStopLoss<level) // check sl
         sl=price+level;

      double tp=(InpTakeProfit==0)?0.0:price-ExtTakeProfit;
      if(tp!=0.0 && ExtTakeProfit<level) // check tp
         tp=price-level;

      PendingOrder(ORDER_TYPE_SELL_STOP,price,sl,tp);
     }
  }
//+------------------------------------------------------------------+

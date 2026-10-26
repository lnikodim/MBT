//+------------------------------------------------------------------+
//|                              GBP9AM(barabashkakvn's edition).mq5 |
//|                                                      forxexpoolo |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "forxexpoolo, coded by Michal Rutka"
#property link      ""
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\DealInfo.mqh>
#include <Trade\OrderInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CDealInfo      m_deal;                       // deals object
COrderInfo     m_order;                      // pending orders object
/* 
   Attach to GBPUSD chart. Timeframe is not important. System should put 
   trades on 9AM London time.

   I looking for system automat wich will be trade for me this
   9:00 GMT look for price GBP/USD 
   then price is 1.8230 example (bid)

   Robot do for me order waiting position 
   long and short 
   open long 18pips+4pips spread at this price so will be 
   LONG 1.8252 profit 40pips   stop 22pips 

   And short 
   open short 22pips-4pipsspread so
   1.8230-22-4=1.8204 
   so 1.8204 short profit 40pips stop 18pips 

   AND MAJOR IF I OPEN LONG POSITION AUTOMAT CANCEL SHORT POSITION 

   This system work nice month week day ?
   I will be glad if I see this in code 

   Version:    Date:       Comment:
   --------------------------------
   1.0         2005.10.16  First version according to the idea.
   1.1         2005.10.17  Bug removed (closing active orders when fired at the
                          look hour and issuing new wrong pair of orders).
                          Added close hour, request of Movieweb.
   1.2         2005.10.18  Bug removed (allowing more than one trades per day, e.g. 2005.07.20)
   1.3         2005.10.19  Feature added: look_price_min.
*/
//--- input parameters
input double   InpLots           = 0.1;      // Lots
input int      InpLookPriceHour  = 10;       // Change for your time zone (my is +1 Hour). Should be 9AM London time
input int      InpLookPriceMiin  = 0;        // Offset in minutes when to look on price
input int      InpCloseHour      = 18;       // Close all orders after this hour
input bool     InpUseCloseHour   = true;     // Set it to false to ignore Close Hour
input ushort   InpTakeProfit     = 40;       // Buy Stop and Sell Stop: Take Profit (in pips)
input ushort   InpDistanceBuy    = 18;       // Buy Stop: distance from current price (in pips)
input ushort   InpDistanceSell   = 22;       // Sell Stop: distance from current price (in pips)
input ushort   InpStopLossBuy    = 22;       // Buy Stop: Stop Loss (in pips)
input ushort   InpStopLossSell   = 18;       // Sell Stop: Stop Loss (in pips)
input int      InpReport         = 15;       // Report publication interval, seconds
input ulong    m_magic           = 20051016; // magic number
//---
ulong          m_slippage=10;                // slippage

double         ExtTakeProfit=0.0;
double         ExtDistanceBuy=0.0;
double         ExtDistanceSell=0.0;
double         ExtStopLossBuy=0.0;
double         ExtStopLossSell=0.0;

double         m_adjusted_point;             // point value adjusted for 3 or 5 points

bool clear_to_send=true;
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
   if(!CheckVolumeValue(InpLots,err_text))
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

   ExtTakeProfit     = InpTakeProfit   * m_adjusted_point;
   ExtDistanceBuy    = InpDistanceBuy  * m_adjusted_point;
   ExtDistanceSell   = InpDistanceSell * m_adjusted_point;
   ExtStopLossBuy    = InpStopLossBuy  * m_adjusted_point;
   ExtStopLossSell   = InpStopLossSell * m_adjusted_point;
//---
   ReportStrategy();
//--- create timer
   if(!EventSetTimer(InpReport))
     {
      Print(__FUNCTION__," ERROR Create timer #",GetLastError());
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
//--- destroy timer
   EventKillTimer();
//---
   Comment("");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   MqlDateTime STimeCurrent;
   TimeToStruct(TimeCurrent(),STimeCurrent);
   if(STimeCurrent.hour>=InpCloseHour && InpUseCloseHour)
     {
      CloseAllPositions();
      DeleteAllPendingOrders();
      return;
     }
//---
   if(STimeCurrent.hour==InpLookPriceHour && STimeCurrent.min>=InpLookPriceMiin && clear_to_send)
     {
      if(!RefreshRates())
         return;
      //-- Probably I need to close any old positions first:
      CloseAllPositions();
      DeleteAllPendingOrders();
      //--- Send orders:
      double price=m_symbol.Ask()+ExtDistanceBuy;
      double sl=(InpStopLossBuy==0)?0.0:m_symbol.Ask()-ExtStopLossBuy;
      double tp=(InpTakeProfit==0)?0.0:m_symbol.Ask()+ExtTakeProfit;
      PendingBuyStop(price,sl,tp);

      price=m_symbol.Bid()-ExtDistanceSell;
      sl=(InpStopLossSell==0)?0.0:m_symbol.Bid()+ExtStopLossSell;
      tp=(InpTakeProfit==0)?0.0:m_symbol.Bid()-ExtTakeProfit;
      PendingSellStop(price,sl,tp);

      clear_to_send=false; // mark that orders are sent

      return;
     }
   if(!clear_to_send)
     {
      //--- there are active orders
      int count_buy_stop=0;
      int count_sell_stop=0;
      CalculatePendingOrders(count_buy_stop,count_sell_stop);
      if((count_buy_stop==0 && count_sell_stop!=0) || (count_buy_stop!=0 && count_sell_stop==0))
        {
         DeleteAllPendingOrders();
         return;
        }
      if(count_buy_stop==0 && count_sell_stop==0 && IsPositionExists() && 
         STimeCurrent.hour!=InpLookPriceHour && STimeCurrent.min>=InpLookPriceMiin)
         clear_to_send=true;
      if(STimeCurrent.hour==(InpLookPriceHour-1) && 
         MathAbs(STimeCurrent.min-InpLookPriceMiin)<10)
         clear_to_send=true;
     }
//---
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   ReportStrategy();
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
//|                                                                  |
//+------------------------------------------------------------------+
void ReportStrategy()
  {
//--- select history for access
   HistorySelect(0,TimeCurrent()+86400);
//---
   int      deals=HistoryDealsTotal();    // total history deals
   double   StrategyProfit    = 0.0;
   double   StrategyProfitOpen= 0.0;
   int      StrategyDeals     = 0;
   int      StrategyPositions = 0;

   for(int i=deals-1;i>=0;i--)
      if(m_deal.SelectByIndex(i))
        {
         ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0)
           {
            Print("HistoryDealGetTicket failed, no trade history");
            break;
           }
         //--- check symbol
         if(m_deal.Symbol()!=m_symbol.Name())
            continue;
         //--- check Expert Magic number
         if(m_deal.Magic()!=m_magic)
            continue;
         //--- check profit
         if(m_deal.DealType()==DEAL_TYPE_BUY || m_deal.DealType()==DEAL_TYPE_SELL)
           {
            StrategyDeals++;
            StrategyProfit+=m_deal.Profit();
           }
        }
//---
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            StrategyPositions++;
            StrategyProfitOpen+=m_position.Profit();
           }
//---
   MqlDateTime STimeCurrent;
   TimeToStruct(TimeCurrent(),STimeCurrent);
   MqlDateTime STimeLocal;
   TimeToStruct(TimeLocal(),STimeLocal);
   Comment("Executed ",StrategyDeals,"+",StrategyPositions," trades with ",StrategyProfit,"+",
           StrategyProfitOpen," = ",StrategyProfit+StrategyProfitOpen," of profit\n",
           "Server hour: ",STimeCurrent.hour," Local hour: ",STimeLocal.hour);
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
//| Pending order of Buy Stop                                        |
//+------------------------------------------------------------------+
void PendingBuyStop(double price,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.BuyStop(InpLots,m_symbol.NormalizePrice(price),
            m_symbol.Name(),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp)))
           {
            if(m_trade.ResultOrder()==0)
              {
               Print("#1 Buy Stop -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Buy Stop -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Buy Stop -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< Lots (",DoubleToString(InpLots,2),")");
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
//| Pending order of Sell Stop                                       |
//+------------------------------------------------------------------+
void PendingSellStop(double price,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.SellStop(InpLots,m_symbol.NormalizePrice(price),
            m_symbol.Name(),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp)))
           {
            if(m_trade.ResultOrder()==0)
              {
               Print("#1 Sell Stop -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Sell Stop -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Sell Stop -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< Lots (",DoubleToString(InpLots,2),")");
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
//| Calculate pending orders                                         |
//+------------------------------------------------------------------+
void CalculatePendingOrders(int &count_buy_stop,int &count_sell_stop)
  {
   count_buy_stop    = 0;
   count_sell_stop   = 0;

   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
           {
            if(m_order.OrderType()==ORDER_TYPE_BUY_STOP)
               count_buy_stop++;
            if(m_order.OrderType()==ORDER_TYPE_SELL_STOP)
               count_sell_stop++;
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

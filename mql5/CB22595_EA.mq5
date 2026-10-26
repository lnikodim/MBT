//+------------------------------------------------------------------+
//|                     Constituents EA(barabashkakvn's edition).mq5 |
//+------------------------------------------------------------------+
#property version   "1.012"
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
//+------------------------------------------------------------------+
//| Enum Lor or Risk                                                 |
//+------------------------------------------------------------------+
enum ENUM_LOT_OR_RISK
  {
   lot=0,   // Constant lot
   risk=1,  // Risk in percent for a deal
  };
//+------------------------------------------------------------------+
//| Enum Limit or Stop                                               |
//+------------------------------------------------------------------+
enum ENUM_LIMIT_OR_STOP
  {
   limit=0, // Limit pending orders
   stop=1,  // Stop pending orders
  };
//--- input parameters
input ushort   InpStopLoss       = 0;        // Stop Loss (in pips)
input ushort   InpTakeProfit     = 0;        // Take Profit (in pips)
input ENUM_LOT_OR_RISK IntLotOrRisk=lot;     // Money management
input double   InpVolumeLorOrRisk= 1.0;      // The value for "Money management"
input ulong    m_magic           = 344676560;// magic number
input uchar    InpStartHour      = 10;       // Start hour
input uchar    InpSearchDepth    = 3;        // Search depth
input ENUM_LIMIT_OR_STOP InpOrderType=limit; // Order Type
//---
ulong  m_slippage=10;         // slippage
double ExtStopLoss=0.0;
double ExtTakeProfit=0.0;
int    handle_iMA;            // variable for storing the handle of the iMA indicator 
double m_adjusted_point;      // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();
//--- check the input parameter "Lots"
   string err_text="";
   if(!CheckVolumeValue(InpVolumeLorOrRisk,err_text))
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
   m_trade.SetExpertMagicNumber(m_magic);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtStopLoss    = InpStopLoss     * m_adjusted_point;
   ExtTakeProfit  = InpTakeProfit   * m_adjusted_point;
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
   if(IsPendingOrdersExists())
      return;
//---
   datetime time_current=TimeCurrent();
   if(time_current==D'1970.01.01')
      return;
   MqlDateTime STime_0;
   TimeToStruct(time_0,STime_0);
   if(STime_0.hour==InpStartHour)
     {
      MqlRates rates[];
      ArraySetAsSeries(rates,true);
      int start_pos=0,count=InpSearchDepth+1;
      if(CopyRates(m_symbol.Name(),Period(),start_pos,count,rates)!=count)
        {
         PrevBars=0;
         return;
        }
      double price_max=DBL_MIN,price_low=DBL_MAX;
      for(int i=1;i<count;i++)
        {
         if(rates[i].high>price_max)
            price_max=rates[i].high;
         if(rates[i].low<price_low)
            price_low=rates[i].low;
        }
      if(price_max==DBL_MIN || price_low==DBL_MAX)
         return;
      //---
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

      if(InpOrderType==limit)
        {
         double price=price_low;
         if(m_symbol.Bid()-price>freeze_level)
           {
            double sl=(InpStopLoss==0)?0.0:price-ExtStopLoss;
            double tp=(InpTakeProfit==0)?0.0:price+ExtTakeProfit;
            if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0) && ((tp!=0 && ExtTakeProfit>=stop_level) || tp==0.0))
              {
               ENUM_ORDER_TYPE order_type=ORDER_TYPE_BUY_LIMIT;
               PendingOrder(order_type,price,sl,tp);
              }
           }
         //---
         price=price_max;
         if(price-m_symbol.Ask()>freeze_level)
           {
            double sl=(InpStopLoss==0)?0.0:price+ExtStopLoss;
            double tp=(InpTakeProfit==0)?0.0:price-ExtTakeProfit;
            if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0) && ((tp!=0 && ExtTakeProfit>=stop_level) || tp==0.0))
              {
               ENUM_ORDER_TYPE order_type=ORDER_TYPE_SELL_LIMIT;
               PendingOrder(order_type,price,sl,tp);
              }
           }
         int d=0;
        }
      else
        {
         double price=price_max;
         if(price-m_symbol.Ask()>freeze_level)
           {
            double sl=(InpStopLoss==0)?0.0:price-ExtStopLoss;
            double tp=(InpTakeProfit==0)?0.0:price+ExtTakeProfit;
            if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0) && ((tp!=0 && ExtTakeProfit>=stop_level) || tp==0.0))
              {
               ENUM_ORDER_TYPE order_type=ORDER_TYPE_BUY_STOP;
               PendingOrder(order_type,price,sl,tp);
              }
           }
         //---
         price=price_low;
         if(m_symbol.Bid()-price>freeze_level)
           {
            double sl=(InpStopLoss==0)?0.0:price+ExtStopLoss;
            double tp=(InpTakeProfit==0)?0.0:price-ExtTakeProfit;
            if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0) && ((tp!=0 && ExtTakeProfit>=stop_level) || tp==0.0))
              {
               ENUM_ORDER_TYPE order_type=ORDER_TYPE_SELL_STOP;
               PendingOrder(order_type,price,sl,tp);
              }
           }

         int d=0;
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
         if(deal_entry==DEAL_ENTRY_IN)
           {
            DeleteAllPendingOrders();

            int d=0;
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
   double long_lot=0.0;
   double short_lot=0.0;
   if(IntLotOrRisk==risk)
     {
      bool error=false;
      long_lot=m_money.CheckOpenLong(m_symbol.Ask(),sl);
      Print("sl=",DoubleToString(sl,m_symbol.Digits()),
            ", CheckOpenLong: ",DoubleToString(long_lot,2),
            ", Balance: ",    DoubleToString(m_account.Balance(),2),
            ", Equity: ",     DoubleToString(m_account.Equity(),2),
            ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
      if(long_lot==0.0)
        {
         Print(__FUNCTION__,", ERROR: method CheckOpenLong returned the value of \"0.0\"");
         error=true;
        }
      //---
      short_lot=m_money.CheckOpenShort(m_symbol.Bid(),sl);
      Print("sl=",DoubleToString(sl,m_symbol.Digits()),
            ", CheckOpenLong: ",DoubleToString(short_lot,2),
            ", Balance: ",    DoubleToString(m_account.Balance(),2),
            ", Equity: ",     DoubleToString(m_account.Equity(),2),
            ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
      if(short_lot==0.0)
        {
         Print(__FUNCTION__,", ERROR: method CheckOpenShort returned the value of \"0.0\"");
         error=true;
        }
      //---
      if(error)
         return(false);
     }
   else if(IntLotOrRisk==lot)
     {
      long_lot=InpVolumeLorOrRisk;
      short_lot=InpVolumeLorOrRisk;
     }
   else
      return(false);
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
            Print("#1 ",EnumToString(order_type)," -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
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
         Print("#3 ",EnumToString(order_type)," -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of result: ",m_trade.ResultRetcodeDescription());
         PrintResultTrade(m_trade,m_symbol);
         return(false);
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CAccountInfo::FreeMarginCheck returned the value ",DoubleToString(free_margin_check,2));
      return(false);
     }
//---
   return(false);
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

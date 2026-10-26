//+------------------------------------------------------------------+
//|                                                  Daily range.mq5 |
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
//+------------------------------------------------------------------+
//| Enum daily range                                                 |
//+------------------------------------------------------------------+
enum ENUM_DAILY_RANGE
  {
   highest_lowest=0, // (Hihgset - Lowest)
   close_close=1,    // Average (Close #i - Close #i+1)
  };
//+------------------------------------------------------------------+
//| Enum Lor or Risk                                                 |
//+------------------------------------------------------------------+
enum ENUM_LOT_OR_RISK
  {
   lot=0,   // Constant lot
   risk=1,  // Risk in percent for a deal
  };
//--- input parameters
input ENUM_DAILY_RANGE InpDailyRange=highest_lowest;// Daily range
input double   InpProfit         = 15;       // Minimum profit
input uchar    InpSliding        = 3;        // Sliding window size (days)
input double   InpStopLoss       = 0.03;     // Stop Loss Coefficient
input double   InpTakeProfit     = 0.05;     // Take Profit Coefficient
input double   InpOffset         = 0.01;     // Offset Coefficient
input uchar    InpMaxPositions   = 3;        // Max Positions in day
input ENUM_LOT_OR_RISK IntLotOrRisk=risk;    // Money management: Lot OR Risk
input double   InpVolumeLorOrRisk=1.0;       // The value for "Money management"
input ulong    m_magic           = 31857468; // magic number
input uchar    InpStartHour      = 10;       // Start hour
input uchar    InpStartMinute    = 5;        // Start minute
//---
ulong  m_slippage                = 10;       // slippage
double m_adjusted_point;                     // point value adjusted for 3 or 5 points
bool   m_need_open_buy           = false;    // "true" -> need to open BUY
bool   m_need_open_sell          = false;    // "true" -> need to open SELL
bool   m_waiting_transaction     = false;    // "true" -> it's forbidden to trade, we expect a transaction
ulong  m_waiting_order_ticket    = 0;        // ticket of the expected order
bool   m_transaction_confirmed   = false;    // "true" -> transaction confirmed
double m_daily_range             = 0;
long   m_day                     = 0;
double m_highest                 = DBL_MIN;
double m_lowest                  = DBL_MAX;
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
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;
//--- check the input parameter "Lots"
   string err_text="";
   if(IntLotOrRisk==lot)
     {
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
     }
   else
     {
      if(m_money!=NULL)
         delete m_money;
      m_money=new CMoneyFixedMargin;
      if(m_money!=NULL)
        {
         if(!m_money.Init(GetPointer(m_symbol),Period(),m_symbol.Point()*digits_adjust))
            return(INIT_FAILED);
         m_money.Percent(InpVolumeLorOrRisk);
        }
      else
        {
         Print(__FUNCTION__,", ERROR: Object CMoneyFixedMargin is NULL");
         return(INIT_FAILED);
        }
     }
//---
   if(DailyRange(m_highest,m_lowest,m_daily_range))
     {
      m_highest+=m_daily_range*InpOffset;
      m_lowest-=m_daily_range*InpOffset;
      if(ObjectFind(0,"HLine highest")<0)
         HLineCreate(0,"HLine highest",0,m_highest,clrBlue);
      HLineMove(0,"HLine highest",m_highest);
      if(ObjectFind(0,"HLine lowest")<0)
         HLineCreate(0,"HLine lowest",0,m_lowest,clrRed);
      HLineMove(0,"HLine lowest",m_lowest);
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
   if(m_money!=NULL)
      delete m_money;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(m_waiting_transaction)
     {
      if(!m_transaction_confirmed)
        {
         Print("m_transaction_confirmed: ",m_transaction_confirmed);
         return;
        }
      else if(m_transaction_confirmed)
        {
         m_need_open_buy            = false;    // "true" -> need to open BUY
         m_need_open_sell           = false;    // "true" -> need to open SELL
         m_waiting_transaction      = false;    // "true" -> it's forbidden to trade, we expect a transaction
         m_waiting_order_ticket     = 0;        // ticket of the expected order
         m_transaction_confirmed    = false;    // "true" -> transaction confirmed
        }
     }
   if(m_need_open_buy)
     {
      double level;
      if(FreezeStopsLevels(level))
        {
         m_waiting_transaction=true;
         OpenPosition(POSITION_TYPE_BUY,level);
        }
      return;
     }
   if(m_need_open_sell)
     {
      double level;
      if(FreezeStopsLevels(level))
        {
         m_waiting_transaction=true;
         OpenPosition(POSITION_TYPE_SELL,level);
        }
      return;
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
//---
   int count_today_buys,count_today_sells;
   CalculateAllPositions(count_today_buys,count_today_sells);
   if(m_symbol.Bid()>=m_highest)
      if(count_today_buys<InpMaxPositions)
         m_need_open_buy=true;
   if(m_symbol.Ask()<=m_lowest)
      if(count_today_sells<InpMaxPositions)
         m_need_open_sell=true;
//---
   MqlDateTime STimeCurrent;
   datetime time_current=TimeCurrent();
   TimeToStruct(time_current,STimeCurrent);
   if(m_day==STimeCurrent.day_of_year)
      return;

   if(STimeCurrent.hour*60*60+STimeCurrent.min*60+STimeCurrent.sec<InpStartHour*60*60+InpStartMinute*60)
      return;
   m_day=STimeCurrent.day_of_year;
//---
   if(!DailyRange(m_highest,m_lowest,m_daily_range))
      return;
   m_highest   += m_daily_range * InpOffset;
   m_lowest    -= m_daily_range * InpOffset;
   if(ObjectFind(0,"HLine highest")<0)
      HLineCreate(0,"HLine highest",0,m_highest,clrBlue);
   HLineMove(0,"HLine highest",m_highest);
   if(ObjectFind(0,"HLine lowest")<0)
      HLineCreate(0,"HLine lowest",0,m_lowest,clrRed);
   HLineMove(0,"HLine lowest",m_lowest);
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
         if(deal_entry==DEAL_ENTRY_IN)
            if(deal_type==DEAL_TYPE_BUY || deal_type==DEAL_TYPE_SELL)
              {
               if(m_waiting_transaction)
                  if(m_waiting_order_ticket==deal_order)
                    {
                     Print(__FUNCTION__," Transaction confirmed");
                     m_transaction_confirmed=true;
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

   level=(freeze_level>stop_level)?freeze_level:stop_level;
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Open position                                                    |
//+------------------------------------------------------------------+
void OpenPosition(const ENUM_POSITION_TYPE pos_type,const double level)
  {
//--- buy
   if(pos_type==POSITION_TYPE_BUY)
     {
      double price=m_symbol.Ask();

      double ExtStopLoss=m_daily_range*InpStopLoss;
      double sl=(InpStopLoss==0)?0.0:price-ExtStopLoss;
      if(sl!=0.0 && ExtStopLoss<level) // check sl
         sl=price-level;

      double ExtTakeProfit=m_daily_range*InpTakeProfit;
      double tp=(InpTakeProfit==0)?0.0:price+ExtTakeProfit;
      if(tp!=0.0 && ExtTakeProfit<level) // check price
         tp=price+level;

      OpenBuy(sl,tp);
     }
//--- sell
   if(pos_type==POSITION_TYPE_SELL)
     {
      double price=m_symbol.Bid();

      double ExtStopLoss=m_daily_range*InpStopLoss;
      double sl=(InpStopLoss==0)?0.0:price+ExtStopLoss;
      if(sl!=0.0 && ExtStopLoss<level) // check sl
         sl=price+level;

      double ExtTakeProfit=m_daily_range*InpTakeProfit;
      double tp=(InpTakeProfit==0)?0.0:price-ExtTakeProfit;
      if(tp!=0.0 && ExtTakeProfit<level) // check tp
         tp=price-level;

      OpenSell(sl,tp);
     }
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double long_lot=0.0;
   if(IntLotOrRisk==risk)
     {
      long_lot=m_money.CheckOpenLong(m_symbol.Ask(),sl);
      Print("sl=",DoubleToString(sl,m_symbol.Digits()),
            ", CheckOpenLong: ",DoubleToString(long_lot,2),
            ", Balance: ",    DoubleToString(m_account.Balance(),2),
            ", Equity: ",     DoubleToString(m_account.Equity(),2),
            ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
      if(long_lot==0.0)
        {
         m_waiting_transaction=false;
         Print(__FUNCTION__,", ERROR: method CheckOpenLong returned the value of \"0.0\"");
         return;
        }
     }
   else if(IntLotOrRisk==lot)
      long_lot=InpVolumeLorOrRisk;
   else
     {
      m_waiting_transaction=false;
      return;
     }
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check= m_account.FreeMarginCheck(m_symbol.Name(),ORDER_TYPE_BUY,long_lot,m_symbol.Ask());
   double margin_check     = m_account.MarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,long_lot,m_symbol.Bid());
   if(free_margin_check>margin_check)
     {
      if(m_trade.Buy(long_lot,m_symbol.Name(),m_symbol.Ask(),sl,tp)) // CTrade::Buy -> "true"
        {
         if(m_trade.ResultDeal()==0)
           {
            if(m_trade.ResultRetcode()==10009) // trade order went to the exchange
              {
               m_waiting_transaction=true;  // "true" -> it's forbidden to trade, we expect a transaction
               m_waiting_order_ticket=m_trade.ResultOrder();
              }
            else
               m_waiting_transaction=false;
            Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
         else
           {
            if(m_trade.ResultRetcode()==10009)
              {
               m_waiting_transaction=true;  // "true" -> it's forbidden to trade, we expect a transaction
               m_waiting_order_ticket=m_trade.ResultOrder();
              }
            else
               m_waiting_transaction=false;
            Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         m_waiting_transaction=false;
         Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of result: ",m_trade.ResultRetcodeDescription());
         PrintResultTrade(m_trade,m_symbol);
        }
     }
   else
     {
      m_waiting_transaction=false;
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

   double short_lot=0.0;
   if(IntLotOrRisk==risk)
     {
      short_lot=m_money.CheckOpenShort(m_symbol.Bid(),sl);
      Print("sl=",DoubleToString(sl,m_symbol.Digits()),
            ", CheckOpenLong: ",DoubleToString(short_lot,2),
            ", Balance: ",    DoubleToString(m_account.Balance(),2),
            ", Equity: ",     DoubleToString(m_account.Equity(),2),
            ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
      if(short_lot==0.0)
        {
         m_waiting_transaction=false;
         Print(__FUNCTION__,", ERROR: method CheckOpenShort returned the value of \"0.0\"");
         return;
        }
     }
   else if(IntLotOrRisk==lot)
      short_lot=InpVolumeLorOrRisk;
   else
     {
      m_waiting_transaction=false;
      return;
     }
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check= m_account.FreeMarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,short_lot,m_symbol.Bid());
   double margin_check     = m_account.MarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,short_lot,m_symbol.Bid());
   if(free_margin_check>margin_check)
     {
      if(m_trade.Sell(short_lot,m_symbol.Name(),m_symbol.Bid(),sl,tp)) // CTrade::Sell -> "true"
        {
         if(m_trade.ResultDeal()==0)
           {
            if(m_trade.ResultRetcode()==10009) // trade order went to the exchange
              {
               m_waiting_transaction=true;  // "true" -> it's forbidden to trade, we expect a transaction
               m_waiting_order_ticket=m_trade.ResultOrder();
              }
            else
               m_waiting_transaction=false;
            Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
         else
           {
            if(m_trade.ResultRetcode()==10009)
              {
               m_waiting_transaction=true;  // "true" -> it's forbidden to trade, we expect a transaction
               m_waiting_order_ticket=m_trade.ResultOrder();
              }
            else
               m_waiting_transaction=false;
            Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         m_waiting_transaction=false;
         Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of result: ",m_trade.ResultRetcodeDescription());
         PrintResultTrade(m_trade,m_symbol);
        }
     }
   else
     {
      m_waiting_transaction=false;
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
//| Create the horizontal line                                       | 
//+------------------------------------------------------------------+ 
bool HLineCreate(const long            chart_ID=0,        // chart's ID 
                 const string          name="HLine",      // line name 
                 const int             sub_window=0,      // subwindow index 
                 double                price=0,           // line price 
                 const color           clr=clrRed,        // line color 
                 const ENUM_LINE_STYLE style=STYLE_DASHDOT,// line style 
                 const int             width=1,           // line width 
                 const bool            back=false,        // in the background 
                 const bool            selection=false,   // highlight to move 
                 const bool            hidden=true,       // hidden in the object list 
                 const long            z_order=0)         // priority for mouse click 
  {
//--- if the price is not set, set it at the current Bid price level 
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value 
   ResetLastError();
//--- create a horizontal line 
   if(!ObjectCreate(chart_ID,name,OBJ_HLINE,sub_window,0,price))
     {
      Print(__FUNCTION__,
            ": failed to create a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- set line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Move horizontal line                                             | 
//+------------------------------------------------------------------+ 
bool HLineMove(const long   chart_ID=0,   // chart's ID 
               const string name="HLine", // line name 
               double       price=0)      // line price 
  {
//--- if the line price is not set, move it to the current Bid price level 
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value 
   ResetLastError();
//--- move a horizontal line 
   if(!ObjectMove(chart_ID,name,0,0,price))
     {
      Print(__FUNCTION__,
            ": failed to move the horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Delete a horizontal line                                         | 
//+------------------------------------------------------------------+ 
bool HLineDelete(const long   chart_ID=0,   // chart's ID 
                 const string name="HLine") // line name 
  {
//--- reset the error value 
   ResetLastError();
//--- delete a horizontal line 
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete a horizontal line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+
//| Daily range                                                      |
//+------------------------------------------------------------------+
bool DailyRange(double &highest,double &lowest,double &range)
  {
   datetime start_time=TimeCurrent();     // start date and time
   if(start_time==D'1970.01.01 00:00:00')
      return(false);
   datetime stop_time=start_time-InpSliding*24*60*60;
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   if(CopyRates(m_symbol.Name(),Period(),start_time,stop_time,rates)==-1)
      return(false);
   int size=ArraySize(rates);
   if(size<=2)
      return(false);
   highest  = DBL_MIN;
   lowest   = DBL_MAX;
   range    = 0;
   for(int i=1;i<size-1;i++)
     {
      if(rates[i].high>highest)
         highest=rates[i].high;
      if(rates[i].low<lowest)
         lowest=rates[i].low;
      range+=rates[i].close-rates[i+1].close;
     }
   if(highest==DBL_MIN || lowest==DBL_MAX)
      return(false);
   if(InpDailyRange==highest_lowest)
      range=highest-lowest;
   else
      range/=size-1;
//---
   if(ObjectFind(0,"VLine start")<0)
      VLineCreate(0,"VLine start",0,start_time,clrOrange);
   VLineMove(0,"VLine start",start_time);
   if(ObjectFind(0,"VLine stop")<0)
      VLineCreate(0,"VLine stop",0,stop_time,clrOrange);
   VLineMove(0,"VLine stop",stop_time);
//---
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Create the vertical line                                         | 
//+------------------------------------------------------------------+ 
bool VLineCreate(const long            chart_ID=0,        // chart's ID 
                 const string          name="VLine",      // line name 
                 const int             sub_window=0,      // subwindow index 
                 datetime              time=0,            // line time 
                 const color           clr=clrRed,        // line color 
                 const ENUM_LINE_STYLE style=STYLE_DASHDOT,// line style 
                 const int             width=1,           // line width 
                 const bool            back=false,        // in the background 
                 const bool            selection=false,   // highlight to move 
                 const bool            ray=true,          // line's continuation down 
                 const bool            hidden=true,       // hidden in the object list 
                 const long            z_order=0)         // priority for mouse click 
  {
//--- if the line time is not set, draw it via the last bar 
   if(!time)
      time=TimeCurrent();
//--- reset the error value 
   ResetLastError();
//--- create a vertical line 
   if(!ObjectCreate(chart_ID,name,OBJ_VLINE,sub_window,time,0))
     {
      Print(__FUNCTION__,
            ": failed to create a vertical line! Error code = ",GetLastError());
      return(false);
     }
//--- set line color 
   ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
//--- set line display style 
   ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
//--- set line width 
   ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
//--- display in the foreground (false) or background (true) 
   ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
//--- enable (true) or disable (false) the mode of moving the line by mouse 
//--- when creating a graphical object using ObjectCreate function, the object cannot be 
//--- highlighted and moved by default. Inside this method, selection parameter 
//--- is true by default making it possible to highlight and move the object 
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
   ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
//--- enable (true) or disable (false) the mode of displaying the line in the chart subwindows 
   ObjectSetInteger(chart_ID,name,OBJPROP_RAY,ray);
//--- hide (true) or display (false) graphical object name in the object list 
   ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
//--- set the priority for receiving the event of a mouse click in the chart 
   ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Move the vertical line                                           | 
//+------------------------------------------------------------------+ 
bool VLineMove(const long   chart_ID=0,   // chart's ID 
               const string name="VLine", // line name 
               datetime     time=0)       // line time 
  {
//--- if line time is not set, move the line to the last bar 
   if(!time)
      time=TimeCurrent();
//--- reset the error value 
   ResetLastError();
//--- move the vertical line 
   if(!ObjectMove(chart_ID,name,0,time,0))
     {
      Print(__FUNCTION__,
            ": failed to move the vertical line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Delete the vertical line                                         | 
//+------------------------------------------------------------------+ 
bool VLineDelete(const long   chart_ID=0,   // chart's ID 
                 const string name="VLine") // line name 
  {
//--- reset the error value 
   ResetLastError();
//--- delete the vertical line 
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete the vertical line! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+
//| Calculate all positions                                          |
//+------------------------------------------------------------------+
void CalculateAllPositions(int &count_today_buys,int &count_today_sells)
  {
   count_today_buys  =0;
   count_today_sells =0;
   datetime time_d1=iTime(m_symbol.Name(),PERIOD_D1,0);
   if(time_d1==D'1970.01.01 00:00:00')
      return;

//--- select history for access
   datetime time=TimeTradeServer();
   HistorySelect(time_d1,time+60*60*24);
//---
   int    deals=HistoryDealsTotal();   // total history deals
   int    losses=0;                    // number of losses orders without a break

   for(int i=deals-1;i>=0;i--)
     {
      ulong ticket=HistoryDealGetTicket(i);
      if(ticket==0)
        {
         Print("HistoryDealGetTicket failed, no trade history");
         break;
        }
      //--- check symbol
      if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=m_symbol.Name())
         continue;
      //--- check Expert Magic number
      if(HistoryDealGetInteger(ticket,DEAL_MAGIC)!=m_magic)
         continue;
      //--- check time
      if(HistoryDealGetInteger(ticket,DEAL_TIME)>=(long)time_d1)
         if(HistoryDealGetInteger(ticket,DEAL_ENTRY)==DEAL_ENTRY_IN)
           {
            if(HistoryDealGetInteger(ticket,DEAL_TYPE)==DEAL_TYPE_BUY)
               count_today_buys++;
            if(HistoryDealGetInteger(ticket,DEAL_TYPE)==DEAL_TYPE_SELL)
               count_today_sells++;
           }
     }
  }
//+------------------------------------------------------------------+

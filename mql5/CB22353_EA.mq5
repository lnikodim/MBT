//+------------------------------------------------------------------+
//|                        MA Envelopes(barabashkakvn's edition).mq5 |
//|                        Copyright 2018, MetaQuotes Software Corp. |
//|                                            https://forge.mql5.io |
//+------------------------------------------------------------------+
#property copyright "2018, MetaQuotes Software Corp."
#property link      "https://forge.mql5.io"
#property version   "1.008"
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
//---
enum ENUM_TRAILING   // Enumeration of trailing 
  {
   trailing_classic     = 0,  // trailing classic ("Trailing Stop" and "Trailing Step")
   trailing_ma          = 1,  // trailing moving average
   trailing_envelopes   = 2,  // trailing envelopes
  };
//--- input parameters
input double   InpMaximumRisk          = 0.02;     // Maximum Risk in percentage
input double   InpDecreaseFactor       = 3;        // Descrease factor
input ushort   InpFirstSLTP            = 8;        // First Stop Loss and Take Profit (in pips)
input ushort   InpSeconSLTP            = 13;       // Secon Stop Loss and Take Profit (in pips)
input ushort   InpThirdSLTP            = 21;       // Third Stop Loss and Take Profit (in pips)
input uchar    InpStartHour            = 20;       // Start hour
input uchar    InpEndHour              = 22;       // End hour
input int                  Inp_MA_Env_ma_period       = 109;         // MA and Envelopes: averaging period
input int                  Inp_MA_Env_ma_shift        = 0;           // MA and Envelopes: horizontal shift  
input ENUM_MA_METHOD       Inp_MA_Env_ma_method       = MODE_EMA;    // MA and Envelopes: smoothing type 
input ENUM_APPLIED_PRICE   Inp_MA_Env_applied_price   = PRICE_CLOSE; // MA and Envelopes: type of price 
input double               Inp_Env_deviation          = 0.05;        // Envelopes: deviation of boundaries from the midline (in percents) 
input ulong    m_magic=474995670;                  // magic number
#define MAGIC_BUY_1 m_magic+1
#define MAGIC_BUY_2 m_magic+2
#define MAGIC_BUY_3 m_magic+3
#define MAGIC_SELL_1 m_magic-1
#define MAGIC_SELL_2 m_magic-2
#define MAGIC_SELL_3 m_magic-3
//---
ulong  m_slippage=10;                              // slippage

double ExtFirstSLTP=0.0;
double ExtSeconSLTP=0.0;
double ExtThirdSLTP=0.0;
double ExtTrailingStop=0.0;
double ExtTrailingStep=0.0;

int    handle_iMA;                           // variable for storing the handle of the iMA indicator  
int    handle_iEnvelopes;                    // variable for storing the handle of the iEnvelopes indicator 

double m_adjusted_point;                     // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(m_account.MarginMode()!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      string text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                  "Неттинг запрещён! Разрешены только хедж счета!":
                  "Netting is forbidden! Only hedge accounts are allowed!";
      Alert(__FUNCTION__," ERROR! ",text);
      return(INIT_FAILED);
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

   ExtFirstSLTP   = InpFirstSLTP * m_adjusted_point;
   ExtSeconSLTP   = InpSeconSLTP * m_adjusted_point;
   ExtThirdSLTP   = InpThirdSLTP * m_adjusted_point;
//--- create handle of the indicator iMA
   handle_iMA=iMA(m_symbol.Name(),Period(),Inp_MA_Env_ma_period,Inp_MA_Env_ma_shift,
                  Inp_MA_Env_ma_method,Inp_MA_Env_applied_price);
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
//--- create handle of the indicator iEnvelopes
   handle_iEnvelopes=iEnvelopes(m_symbol.Name(),Period(),Inp_MA_Env_ma_period,Inp_MA_Env_ma_shift,
                                Inp_MA_Env_ma_method,Inp_MA_Env_applied_price,Inp_Env_deviation);
//--- if the handle is not created 
   if(handle_iEnvelopes==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iEnvelopes indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_D1),
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
   double ma[];
   double bline[];
   double sline[];
   if(!iGetArray(handle_iMA,0,0,1,ma) || !iGetArray(handle_iEnvelopes,UPPER_LINE,0,1,bline) || 
      !iGetArray(handle_iEnvelopes,LOWER_LINE,0,1,sline))
      return;
//---
   ulong ticket_buy_1=0,ticket_buy_2=0,ticket_buy_3=0,ticket_sell_1=0,ticket_sell_2=0,ticket_sell_3=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name())
           {
            if(m_position.Magic()==MAGIC_BUY_1)
               ticket_buy_1=m_position.Ticket();
            if(m_position.Magic()==MAGIC_BUY_2)
               ticket_buy_2=m_position.Ticket();
            if(m_position.Magic()==MAGIC_BUY_3)
               ticket_buy_3=m_position.Ticket();
            if(m_position.Magic()==MAGIC_SELL_1)
               ticket_sell_1=m_position.Ticket();
            if(m_position.Magic()==MAGIC_SELL_2)
               ticket_sell_2=m_position.Ticket();
            if(m_position.Magic()==MAGIC_SELL_3)
               ticket_sell_3=m_position.Ticket();
           }
//---
   MqlDateTime STimeCurrent;
   if(!TimeToStruct(TimeCurrent(),STimeCurrent))
      return;
   if(STimeCurrent.hour>=InpStartHour && STimeCurrent.hour<InpEndHour)
     {
      double close_1=iClose(m_symbol.Name(),Period(),1);
      if(close_1==0.0)
         return;
      if(close_1>ma[0] && close_1<bline[0] && m_symbol.Ask()>ma[0])
        {
         if(ticket_buy_1==0)
           {
            double lot=TradeSizeOptimized();
            if(lot==0.0)
               return;
            double sl=sline[0];
            double tp=bline[0]+ExtFirstSLTP;
            int stoplevel=m_symbol.StopsLevel();
            if(stoplevel==0)
               stoplevel=3*m_symbol.Spread();
            if(ma[0]<m_symbol.Ask()-stoplevel*m_symbol.Point())
              {
               m_trade.SetExpertMagicNumber(MAGIC_BUY_1);
               if(PendingOrder(ORDER_TYPE_BUY_LIMIT,lot,ma[0],sl,tp))
                  return;
              }
           }
         if(ticket_buy_2==0)
           {
            double lot=TradeSizeOptimized();
            if(lot==0.0)
               return;
            double sl=sline[0];
            double tp=bline[0]+ExtSeconSLTP;
            int stoplevel=m_symbol.StopsLevel();
            if(stoplevel==0)
               stoplevel=3*m_symbol.Spread();
            if(ma[0]<m_symbol.Ask()-stoplevel*m_symbol.Point())
              {
               m_trade.SetExpertMagicNumber(MAGIC_BUY_2);
               if(PendingOrder(ORDER_TYPE_BUY_LIMIT,lot,ma[0],sl,tp))
                  return;
               return;
              }
           }
         if(ticket_buy_3==0)
           {
            double lot=TradeSizeOptimized();
            if(lot==0.0)
               return;
            double sl=sline[0];
            double tp=bline[0]+ExtThirdSLTP;
            int stoplevel=m_symbol.StopsLevel();
            if(stoplevel==0)
               stoplevel=3*m_symbol.Spread();
            if(ma[0]<m_symbol.Ask()-stoplevel*m_symbol.Point())
              {
               m_trade.SetExpertMagicNumber(MAGIC_BUY_3);
               if(PendingOrder(ORDER_TYPE_BUY_LIMIT,lot,ma[0],sl,tp))
                  return;
               return;
              }
           }
        }
      if(close_1<ma[0] && close_1>sline[0] && m_symbol.Bid()<ma[0])
        {
         if(ticket_sell_1==0)
           {
            double lot=TradeSizeOptimized();
            if(lot==0.0)
               return;
            double sl=bline[0];
            double tp=sline[0]-ExtFirstSLTP;
            int stoplevel=m_symbol.StopsLevel();
            if(stoplevel==0)
               stoplevel=3*m_symbol.Spread();
            if(ma[0]>m_symbol.Bid()+stoplevel*m_symbol.Point())
              {
               m_trade.SetExpertMagicNumber(MAGIC_SELL_1);
               if(PendingOrder(ORDER_TYPE_SELL_LIMIT,lot,ma[0],sl,tp))
                  return;
              }
           }
         if(ticket_sell_2==0)
           {
            double lot=TradeSizeOptimized();
            if(lot==0.0)
               return;
            double sl=bline[0];
            double tp=sline[0]-ExtSeconSLTP;
            int stoplevel=m_symbol.StopsLevel();
            if(stoplevel==0)
               stoplevel=3*m_symbol.Spread();
            if(ma[0]>m_symbol.Bid()+stoplevel*m_symbol.Point())
              {
               m_trade.SetExpertMagicNumber(MAGIC_SELL_2);
               if(PendingOrder(ORDER_TYPE_SELL_LIMIT,lot,ma[0],sl,tp))
                  return;
              }
           }
         if(ticket_sell_3==0)
           {
            double lot=TradeSizeOptimized();
            if(lot==0.0)
               return;
            double sl=bline[0];
            double tp=sline[0]-ExtThirdSLTP;
            int stoplevel=m_symbol.StopsLevel();
            if(stoplevel==0)
               stoplevel=3*m_symbol.Spread();
            if(ma[0]>m_symbol.Bid()+stoplevel*m_symbol.Point())
              {
               m_trade.SetExpertMagicNumber(MAGIC_SELL_3);
               if(PendingOrder(ORDER_TYPE_SELL_LIMIT,lot,ma[0],sl,tp))
                  return;
              }
           }
        }
     }
   else if(STimeCurrent.hour>=InpEndHour && IsPendingOrdersExists())
     {
      DeleteAllPendingOrders();
     }
//---

  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
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
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
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
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double TradeSizeOptimized(void)
  {
   RefreshRates();
   double price=m_symbol.Ask();
   double margin=0.0;
//--- select lot size
   if(!OrderCalcMargin(ORDER_TYPE_BUY,m_symbol.Name(),1.0,price,margin))
      return(0.0);
   if(margin<=0.0)
      return(0.0);
   double lot=NormalizeDouble(AccountInfoDouble(ACCOUNT_MARGIN_FREE)*InpMaximumRisk/margin,2);
//--- calculate number of losses deals without a break
   if(InpDecreaseFactor>0)
     {
      //--- select history for access
      HistorySelect(0,TimeCurrent()+60*60*24);
      //---
      int    deals=HistoryDealsTotal();  // total history deals
      int    losses=0;                    // number of losses deals without a break

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
         long history_magic=HistoryDealGetInteger(ticket,DEAL_MAGIC);
         if(history_magic!=MAGIC_BUY_1 || history_magic!=MAGIC_BUY_2 || history_magic!=MAGIC_BUY_3 ||
            history_magic!=MAGIC_SELL_1 || history_magic!=MAGIC_SELL_2 || history_magic!=MAGIC_SELL_3)
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
         lot=NormalizeDouble(lot-lot*losses/InpDecreaseFactor,1);
     }
//--- normalize and check limits
   double stepvol=m_symbol.LotsStep();
   lot=stepvol*NormalizeDouble(lot/stepvol,0);

   double minvol=m_symbol.LotsMin();
   if(lot<minvol)
      lot=minvol;

   double maxvol=m_symbol.LotsMax();
   if(lot>maxvol)
      lot=maxvol;
//--- return trading volume
   return(lot);
  }
//+------------------------------------------------------------------+
//| Is pendinf orders exists                                         |
//+------------------------------------------------------------------+
bool IsPendingOrdersExists(void)
  {
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name())
            if(m_order.Magic()==MAGIC_BUY_1 || m_order.Magic()==MAGIC_BUY_2 || m_order.Magic()==MAGIC_BUY_3 ||
               m_order.Magic()==MAGIC_SELL_1 || m_order.Magic()==MAGIC_SELL_2 || m_order.Magic()==MAGIC_SELL_3)
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
         if(m_order.Symbol()==m_symbol.Name())
            if(m_order.Magic()==MAGIC_BUY_1 || m_order.Magic()==MAGIC_BUY_2 || m_order.Magic()==MAGIC_BUY_3 ||
               m_order.Magic()==MAGIC_SELL_1 || m_order.Magic()==MAGIC_SELL_2 || m_order.Magic()==MAGIC_SELL_3)
               m_trade.OrderDelete(m_order.Ticket());
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
//| Pending order                                                    |
//+------------------------------------------------------------------+
bool PendingOrder(ENUM_ORDER_TYPE order_type,double volume,double price,double sl,double tp)
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
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),volume,m_symbol.Bid(),ORDER_TYPE_SELL);
   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=volume)
        {
         if(m_trade.OrderOpen(m_symbol.Name(),order_type,volume,0.0,
            m_symbol.NormalizePrice(price),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp)))
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
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2));
         return(false);
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return(false);
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+

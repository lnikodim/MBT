//+------------------------------------------------------------------+
//|                       ScalpWiz 9001(barabashkakvn's edition).mq5 |
//|                               Copyright © 2015, MCB Shenannegans |
//|                                             marchaxcpp@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2015, MCB Shenannegans."
#property link      "marchaxcpp@gmail.com"
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>
#include <Arrays\ArrayObj.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
COrderInfo     m_order;                      // pending orders object
CArrayObj      *m_array;
double         lot_or_risk_array[4];
double         levels_array[4];
//+------------------------------------------------------------------+
//| Enum Lor or Risk                                                 |
//+------------------------------------------------------------------+
enum ENUM_LOT_OR_RISK
  {
   lot=0,   // Constant lot
   risk=1,  // Risk in percent for a deal
  };
//--- input parameters
input ushort   InpStopLoss       = 50;       // Stop Loss (in pips)
input ushort   InpTakeProfit     = 50;       // Take Profit (in pips)
input ushort   InpTrailingStop   = 5;        // Trailing Stop (min distance from price to Stop Loss) (in pips)
input ushort   InpTrailingStep   = 15;       // Trailing Step (in pips)
input uchar    InpExpiration     = 15;       // Pending Stop orders expiration time (in minutes)
input ENUM_LOT_OR_RISK IntLotOrRisk=risk;    // Money management: Lot OR Risk
input double   InpVolumeLorOrRisk_Level_0=1.0;// The value for "Money management" Level #0
input double   InpVolumeLorOrRisk_Level_1=2.0;// The value for "Money management" Level #1
input double   InpVolumeLorOrRisk_Level_2=3.0;// The value for "Money management" Level #2
input double   InpVolumeLorOrRisk_Level_3=4.0;// The value for "Money management" Level #3
input ushort   InpLevel_0        = 10;       // Level #0 (in pips)
input ushort   InpLevel_1        = 12;       // Level #1 (in pips)
input ushort   InpLevel_2        = 15;       // Level #2 (in pips)
input ushort   InpLevel_3        = 20;       // Level #3 (in pips)
input ulong    m_magic           = 970369488;// magic number
//---
ulong  m_slippage=10;               // slippage
double ExtStopLoss=0.0;
double ExtTakeProfit=0.0;
double ExtTrailingStop=0.0;
double ExtTrailingStep=0.0;
double ExtLevel_0=0.0;
double ExtLevel_1=0.0;
double ExtLevel_2=0.0;
double ExtLevel_3=0.0;
int    handle_iBands;               // variable for storing the handle of the iBands indicator 
double m_adjusted_point;            // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
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
//---
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
   ExtLevel_0        = InpLevel_0         * m_adjusted_point;
   ExtLevel_1        = InpLevel_1         * m_adjusted_point;
   ExtLevel_2        = InpLevel_2         * m_adjusted_point;
   ExtLevel_3        = InpLevel_3         * m_adjusted_point;
//--- check the input parameter "Lots"
   lot_or_risk_array[0]=InpVolumeLorOrRisk_Level_0;
   lot_or_risk_array[1]=InpVolumeLorOrRisk_Level_1;
   lot_or_risk_array[2]=InpVolumeLorOrRisk_Level_2;
   lot_or_risk_array[3]=InpVolumeLorOrRisk_Level_3;
   levels_array[0]=ExtLevel_0;
   levels_array[1]=ExtLevel_1;
   levels_array[2]=ExtLevel_2;
   levels_array[3]=ExtLevel_3;
   string err_text="";
   if(IntLotOrRisk==lot)
     {
      for(int i=0;i<4;i++)
        {
         if(!CheckVolumeValue(lot_or_risk_array[i],err_text))
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
     }
   else
     {
      if(m_array!=NULL)
         delete m_array;
      //--- create array 
      m_array=new CArrayObj;
      if(m_array==NULL)
        {
         Print("Object CArrayObj create error");
         return(INIT_FAILED);
        }
      //--- 
      for(int i=0;i<4;i++)
        {
         CMoneyFixedMargin *m_money=new CMoneyFixedMargin;
         if(m_money!=NULL)
           {
            if(!m_money.Init(GetPointer(m_symbol),Period(),m_symbol.Point()*digits_adjust))
               return(INIT_FAILED);
            m_money.Percent(lot_or_risk_array[i]);
           }
         else
           {
            Print(__FUNCTION__,", ERROR: Object CMoneyFixedMargin is NULL");
            return(INIT_FAILED);
           }
         //---
         m_array.Add(m_money);
        }
     }
//--- create handle of the indicator iBands
   handle_iBands=iBands(m_symbol.Name(),Period(),20,0,2.0,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iBands==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iBands indicator for the symbol %s/%s, error code %d",
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
   if(m_array!=NULL)
      delete m_array;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(IsPendingOrdersExists())
      return;
/*
//--- we work only at the time of the birth of new bar
*/
   static datetime PrevBars=0;
/*
   datetime time_0=iTime(m_symbol.Name(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
*/
   if(!RefreshRates())
     {
      PrevBars=0;
      return;
     }
//---
   double bands_upper_array[];
   ArraySetAsSeries(bands_upper_array,true);
   double bands_lower_array[];
   ArraySetAsSeries(bands_lower_array,true);
   double close_array[];
   ArraySetAsSeries(close_array,true);

   int start_pos=0,count=3;
   if(!iGetArray(handle_iBands,UPPER_BAND,start_pos,count,bands_upper_array) || 
      !iGetArray(handle_iBands,LOWER_BAND,start_pos,count,bands_lower_array) || 
      CopyClose(m_symbol.Name(),Period(),start_pos,count,close_array)!=count)
     {
      PrevBars=0;
      return;
     }
//---
   if(!RefreshRates())
     {
      PrevBars=0;
      return;
     }
   double freeze_level=m_symbol.FreezeLevel()*m_symbol.Point();
   if(freeze_level==0.0)
      freeze_level=(m_symbol.Ask()-m_symbol.Bid())*3;
   freeze_level*=1.1;

   double stop_level=m_symbol.StopsLevel()*m_symbol.Point();
   if(stop_level==0.0)
      stop_level=(m_symbol.Ask()-m_symbol.Bid())*3;
   stop_level*=1.1;

   if(freeze_level<=0.0 || stop_level<=0.0)
     {
      PrevBars=0;
      return;
     }
//---
   if(close_array[0]-bands_upper_array[0]>=levels_array[3])
     {
      for(int i=0;i<4;i++)
        {
         double estimated_price=m_symbol.Bid()-levels_array[i];
         if(estimated_price>=freeze_level)
           {
            double sl=(InpStopLoss==0)?0.0:estimated_price+ExtStopLoss;
            double tp=(InpTakeProfit==0)?0.0:estimated_price-ExtTakeProfit;
            //--- Pending Sell stop
            PendingOrder(ORDER_TYPE_SELL_STOP,estimated_price,sl,tp,i);
            int d=0;
           }
        }
     }
   else if(bands_lower_array[0]-close_array[0]>=levels_array[3])
     {
      for(int i=0;i<4;i++)
        {
         double estimated_price=m_symbol.Ask()+levels_array[i];
         if(estimated_price>=freeze_level)
           {
            double sl=(InpStopLoss==0)?0.0:estimated_price-ExtStopLoss;
            double tp=(InpTakeProfit==0)?0.0:estimated_price+ExtTakeProfit;
            //--- Pending Buy stop
            PendingOrder(ORDER_TYPE_BUY_STOP,estimated_price,sl,tp,i);
            int d=0;
           }
        }
     }
//---
   Trailing();
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
//| Pending order                                                    |
//+------------------------------------------------------------------+
bool PendingOrder(ENUM_ORDER_TYPE order_type,double price,double sl,double tp,int index)
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
      CMoneyFixedMargin *m_money;
      m_money=m_array.At(index);
      if(m_money==NULL)
        {
         Print("CArrayObj At() error");
         return(false);
        }
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
      long_lot=lot_or_risk_array[index];
      short_lot=lot_or_risk_array[index];
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
      datetime time=TimeTradeServer()+InpExpiration*60;
      if(m_trade.OrderOpen(m_symbol.Name(),order_type,check_lot,0.0,
         m_symbol.NormalizePrice(price),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp),ORDER_TIME_SPECIFIED,time))
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
//| Trailing                                                         |
//|   InpTrailingStop: min distance from price to Stop Loss          |
//+------------------------------------------------------------------+
void Trailing()
  {
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
  }
//+------------------------------------------------------------------+

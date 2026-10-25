//+------------------------------------------------------------------+
//|                                MA MACD Position averaging v2.mq5 |
//|                              Copyright © 2018, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
#property version   "2.000"
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
input double   InpLots           = 1.0;      // Lots
input ushort   InpStopLoss       = 50;       // Stop Loss, in pips (1.00045-1.00055=1 pips)
input ushort   InpTakeProfit     = 50;       // Take Profit, in pips (1.00045-1.00055=1 pips)
input ushort   InpTrailingStop   = 5;        // Trailing Stop (min distance from price to Stop Loss, in pips
input ushort   InpTrailingStep   = 5;        // Trailing Step, in pips (1.00045-1.00055=1 pips)
input ushort   InpStepLossing    = 30;       // Step lossing, in pips (1.00045-1.00055=1 pips)
input double   InpLotCoefficient = 2.0;      // Lot coefficient if Step lossing
input uchar    InpBarCurrent     = 0;        // Bar Current
input bool     InpReverse        = false;    // Use reverse trade signal
//--- Moving Average parameters
input int                  Inp_MA_ma_period     = 15;             // MA: averaging period 
input int                  Inp_MA_ma_shift      = 0;              // MA: horizontal shift 
input ENUM_MA_METHOD       Inp_MA_ma_method     = MODE_LWMA;      // MA: smoothing type 
input ENUM_APPLIED_PRICE   Inp_MA_applied_price = PRICE_WEIGHTED; // MA: type of price 
input ushort               Inp_MA_Indent        = 4;              // Indent price from MA, in pips (1.00045-1.00055=1 pips)
//--- MACD parameters
input int                  Inp_MACD_fast_ema_period   = 12;             // MACD: period for Fast average calculation 
input int                  Inp_MACD_slow_ema_period   = 26;             // MACD: period for Slow average calculation 
input int                  Inp_MACD_signal_period     = 9;              // MACD: period for their difference averaging 
input ENUM_APPLIED_PRICE   Inp_MACD_applied_price     = PRICE_WEIGHTED; // MACD: type of price 
input double               Inp_MACD_ratio             = 0.9;            // Ratio of MAIN to SIGNAL
//---
input ulong    m_magic=837623162;            // magic number
//---
ulong  m_slippage=10;                        // slippage
double ExtStopLoss=0.0;
double ExtTakeProfit=0.0;
double ExtTrailingStop=0.0;
double ExtTrailingStep=0.0;
double ExtStepLossing=0.0;
double ExtIndent=0.0;
int    handle_iMA;                           // variable for storing the handle of the iMA indicator 
int    handle_iMACD;                         // variable for storing the handle of the iMACD indicator 
double m_adjusted_point;                     // point value adjusted for 3 or 5 points
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
   ExtStepLossing    = InpStepLossing     * m_adjusted_point;
   ExtIndent         = Inp_MA_Indent      * m_adjusted_point;
//--- check the input parameter "Lots"
   string err_text="";
   if(!CheckVolumeValue(InpLots,err_text))
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
//--- create handle of the indicator iMA
   handle_iMA=iMA(m_symbol.Name(),Period(),Inp_MA_ma_period,Inp_MA_ma_shift,
                  Inp_MA_ma_method,Inp_MA_applied_price);
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
//--- create handle of the indicator iMACD
   handle_iMACD=iMACD(m_symbol.Name(),Period(),Inp_MACD_fast_ema_period,Inp_MACD_slow_ema_period,
                      Inp_MACD_signal_period,Inp_MACD_applied_price);
//--- if the handle is not created 
   if(handle_iMACD==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMACD indicator for the symbol %s/%s, error code %d",
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
   Trailing();
//---
   int      count_buys           = 0;
   ulong    ticket_lowest_buy    = ULONG_MAX;
   double   volume_lowest_buy    = 0.0;

   int      count_sells          = 0;
   ulong    ticket_highest_sell  = ULONG_MAX;
   double   volume_highest_sell  = 0.0;

   CalculateAllPositions(count_buys,ticket_lowest_buy,volume_lowest_buy,
                         count_sells,ticket_highest_sell,volume_highest_sell,
                         ExtStepLossing);
//---
   if(count_buys>0 && count_sells>0)
     {
      PrintFormat("ERROR!!! BUY %d, SELL %d",count_buys,count_sells);
      CloseAllPositions();
      PrevBars=0;
      return;
     }
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
//---
   if(count_buys>0 && ticket_lowest_buy!=ULONG_MAX)
     {
      double price=m_symbol.Ask();
      double sl=(InpStopLoss==0)?0.0:price-ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:price+ExtTakeProfit;
      if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0) && ((tp!=0 && ExtTakeProfit>=stop_level) || tp==0.0))
        {
         double lot=LotCheck(volume_lowest_buy*InpLotCoefficient);
         if(lot>0.0)
            OpenBuy(lot,sl,tp);
         return;
        }
      return;
     }
//---
   if(count_sells>0 && ticket_highest_sell!=ULONG_MAX)
     {
      double price=m_symbol.Bid();
      double sl=(InpStopLoss==0)?0.0:price+ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:price-ExtTakeProfit;
      if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0) && ((tp!=0 && ExtTakeProfit>=stop_level) || tp==0.0))
        {
         double lot=LotCheck(volume_highest_sell*InpLotCoefficient);
         if(lot>0.0)
            OpenSell(lot,sl,tp);
         return;
        }
      return;
     }
//---
   if(count_buys+count_sells==0)
     {
      double ma_array[],macd_main_array[],macd_signal_array[];
      ArraySetAsSeries(ma_array,true);
      ArraySetAsSeries(macd_main_array,true);
      ArraySetAsSeries(macd_signal_array,true);
      int start_pos=0,count=InpBarCurrent+1;
      if(!iGetArray(handle_iMA,0,start_pos,count,ma_array) || 
         !iGetArray(handle_iMACD,MAIN_LINE,start_pos,count,macd_main_array) || 
         !iGetArray(handle_iMACD,SIGNAL_LINE,start_pos,count,macd_signal_array))
        {
         PrevBars=0;
         return;
        }
      //--- check BUY
      if(macd_main_array[InpBarCurrent]<0.0 && macd_signal_array[InpBarCurrent]<0.0 && 
         m_symbol.Ask()>ma_array[InpBarCurrent])
        {
         //--- MACD filter
         if((macd_signal_array[InpBarCurrent]!=0.0 && 
            macd_main_array[InpBarCurrent]/macd_signal_array[InpBarCurrent]>=Inp_MACD_ratio))
           {
            //--- Moving Average filter
            if(m_symbol.Ask()-ma_array[InpBarCurrent]>=ExtIndent)
              {
               if(!InpReverse)
                 {
                  double price=m_symbol.Ask();
                  double sl=(InpStopLoss==0)?0.0:price-ExtStopLoss;
                  double tp=(InpTakeProfit==0)?0.0:price+ExtTakeProfit;
                  if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0) && ((tp!=0 && ExtTakeProfit>=stop_level) || tp==0.0))
                    {
                     OpenBuy(InpLots,sl,tp);
                     return;
                    }
                 }
               else
                 {
                  double price=m_symbol.Bid();
                  double sl=(InpStopLoss==0)?0.0:price+ExtStopLoss;
                  double tp=(InpTakeProfit==0)?0.0:price-ExtTakeProfit;
                  if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0) && ((tp!=0 && ExtTakeProfit>=stop_level) || tp==0.0))
                    {
                     OpenSell(InpLots,sl,tp);
                     return;
                    }
                 }
               return;
              }
           }
        }
      //--- check SELL
      if(macd_main_array[InpBarCurrent]>0.0 && macd_signal_array[InpBarCurrent]>0.0 && 
         m_symbol.Bid()<ma_array[InpBarCurrent])
        {
         //--- MACD filter
         if((macd_signal_array[InpBarCurrent]!=0.0 && 
            macd_main_array[InpBarCurrent]/macd_signal_array[InpBarCurrent]>=Inp_MACD_ratio))
           {
            //--- Moving Average filter
            if(ma_array[InpBarCurrent]-m_symbol.Bid()>=ExtIndent)
              {
               if(!InpReverse)
                 {
                  double price=m_symbol.Bid();
                  double sl=(InpStopLoss==0)?0.0:price+ExtStopLoss;
                  double tp=(InpTakeProfit==0)?0.0:price-ExtTakeProfit;
                  if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0) && ((tp!=0 && ExtTakeProfit>=stop_level) || tp==0.0))
                    {
                     OpenSell(InpLots,sl,tp);
                     return;
                    }
                 }
               else
                 {
                  double price=m_symbol.Ask();
                  double sl=(InpStopLoss==0)?0.0:price-ExtStopLoss;
                  double tp=(InpTakeProfit==0)?0.0:price+ExtTakeProfit;
                  if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0) && ((tp!=0 && ExtTakeProfit>=stop_level) || tp==0.0))
                    {
                     OpenBuy(InpLots,sl,tp);
                     return;
                    }
                 }
               return;
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
//| Calculate all positions                                          |
//+------------------------------------------------------------------+
void CalculateAllPositions(int &count_buys,ulong &ticket_lowest_buy,double  &volume_lowest_buy,
                           int &count_sells,ulong &ticket_highest_sell,double  &volume_highest_sell,
                           const double lossing_points=0.0)
  {
   count_buys  =0;   ticket_lowest_buy    = ULONG_MAX;   volume_lowest_buy    =  0.0;
   count_sells =0;   ticket_highest_sell  = ULONG_MAX;   volume_highest_sell  =  0.0;
//--- auxiliary variables
   double price_lowest_buy    = DBL_MAX;
   double price_highest_sell  = DBL_MIN;
//---
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               count_buys++;
               if(m_position.PriceOpen()<price_lowest_buy) // the lowest position of "BUY" is found
                  if(m_position.PriceOpen()-m_position.PriceCurrent()>=lossing_points)
                    {
                     price_lowest_buy=m_position.PriceOpen();
                     ticket_lowest_buy=m_position.Ticket();
                    }
               continue;
              }
            else if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               count_sells++;
               if(m_position.PriceOpen()>price_highest_sell) // the highest position of "SELL" is found
                  if(m_position.PriceCurrent()-m_position.PriceOpen()>=lossing_points)
                    {
                     price_highest_sell=m_position.PriceOpen();
                     ticket_highest_sell=m_position.Ticket();
                    }
              }
           }
  }
//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions(void)
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(const double long_lot,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
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
void OpenSell(const double short_lot,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
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

//+------------------------------------------------------------------+
//|                               Sprut(barabashkakvn's edition).mq5 |
//|                              Copyright © 2018, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
#property version   "1.001"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\OrderInfo.mqh>
CPositionInfo  m_position;                      // trade position object
CTrade         m_trade;                         // trading object
CSymbolInfo    m_symbol;                        // symbol info object
COrderInfo     m_order;                         // pending orders object
//--- input parameters
input uchar    CountOrders          = 5;        // Count pending orders
input double   FirstBuyStop         = 0.0;      // Price First Buy Stop
input double   FirstBuyLimit        = 0.0;      // Price First Buy Limit
input double   FirstSellStop        = 0.0;      // Price First Sell Stop
input double   FirstSellLimit       = 0.0;      // Price First Sell Limit
input ushort   DeltaFirstBuyStop    = 15.0;     // Delta First Buy Stop (in pips)
input ushort   DeltaFirstBuyLimit   = 15.0;     // Delta First Buy Limit (in pips)
input ushort   DeltaFirstSellStop   = 15.0;     // Delta First Sell Stop (in pips)
input ushort   DeltaFirstSellLimit  = 15.0;     // Delta First Sell Limit (in pips)
input bool     UseBuyStop           = false;    // Use buy stop
input bool     UseBuyLimit          = false;    // Use buy limit
input bool     UseSellStop          = false;    // Use sell stop
input bool     UseSellLimit         = false;    // Use sell limit
input ushort   StepStop             = 50;       // Step stop (in pips)
input ushort   StepLimit            = 50;       // Step limit (in pips)
input double   VolumeStop           = 0.01;     // First volume stop
input double   VolumeLimit          = 0.01;     // First volume limit
input double   CoefficientStop      = 1.6;      // Coefficient stop
input double   CoefficientLimit     = 1.6;      // Coefficient limit
input double   ProfitClose          = 10.0;     // Profit Close
input double   LossClose            = -100.0;   // Loss Close
input int      Expiration           = 60;       // Expiration (in minutes)
input ushort   StopLoss             = 50.0;     // Stop Loss (in pips)
input ushort   TakeProfit           = 0.0;      // Take Profit (in pips)
input ulong    m_magic=56556720;                // magic number
//---
ulong  m_slippage=10;                           // slippage

double ExtDeltaFirstBuyStop   = 0.0;
double ExtDeltaFirstBuyLimit  = 0.0;
double ExtDeltaFirstSellStop  = 0.0;
double ExtDeltaFirstSellLimit = 0.0;
double ExtStepStop            = 0.0;
double ExtStepLimit           = 0.0;
double ExtStopLoss            = 0.0;
double ExtTakeProfit          = 0.0;

double m_adjusted_point;            // point value adjusted for 3 or 5 points

bool   m_close_all=false;
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
   if(UseBuyStop || UseSellStop)
      if(!CheckVolumeValue(VolumeStop,err_text))
        {
         Print(__FUNCTION__,", ERROR: ",err_text);
         return(INIT_PARAMETERS_INCORRECT);
        }
   err_text="";
   if(UseBuyLimit || UseSellLimit)
      if(!CheckVolumeValue(VolumeLimit,err_text))
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

   ExtDeltaFirstBuyStop    = DeltaFirstBuyStop     * m_adjusted_point;
   ExtDeltaFirstBuyLimit   = DeltaFirstBuyLimit    * m_adjusted_point;
   ExtDeltaFirstSellStop   = DeltaFirstSellStop    * m_adjusted_point;
   ExtDeltaFirstSellLimit  = DeltaFirstSellLimit   * m_adjusted_point;
   ExtStepStop             = StepStop              * m_adjusted_point;
   ExtStepLimit            = StepLimit             * m_adjusted_point;
   ExtStopLoss             = StopLoss              * m_adjusted_point;
   ExtTakeProfit           = TakeProfit            * m_adjusted_point;
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
   if(m_close_all)
     {
      if(IsPositionExists())
        {
         CloseAllPositions();
         return;
        }
      if(IsPendingOrdersExists())
        {
         DeleteAllPendingOrders();
         return;
        }
      m_close_all=false;
     }
//---
   double profit=ProfitAllPositions();
   if(profit>=ProfitClose || profit<=LossClose)
     {
      m_close_all=true;
      return;
     }
//---
   if(!IsPositionExists() && !IsPendingOrdersExists())
     {
      if(!RefreshRates())
         return;
      double price_buy_stop   =(FirstBuyStop==0.0)    ? m_symbol.Ask() + ExtDeltaFirstBuyStop  : FirstBuyStop;
      double price_buy_limit  =(FirstBuyLimit==0.0)   ? m_symbol.Bid() - ExtDeltaFirstBuyLimit : FirstBuyLimit;
      double price_sell_stop  =(FirstSellStop==0.0)   ? m_symbol.Bid() - ExtDeltaFirstSellStop : FirstSellStop;
      double price_sell_limit =(FirstSellLimit==0.0)  ? m_symbol.Ask() + ExtDeltaFirstSellLimit: FirstSellLimit;
      for(int i=0;i<CountOrders;i++)
        {
         double price= 0.0;
         double sl   = 0.0;
         double tp   = 0.0;
         if(UseBuyStop)
           {
            price=price_buy_stop+(double)i*ExtStepStop;
            sl=(StopLoss==0)?0.0:price-ExtStopLoss;
            tp=(TakeProfit==0)?0.0:price+ExtTakeProfit;
            double lot=(i==0 || CoefficientStop==1.0)?VolumeStop:LotCheck(VolumeStop*(double)i*CoefficientStop);
            if(lot==0.0)
               continue;
            PendingOrder(ORDER_TYPE_BUY_STOP,lot,price,sl,tp,Expiration);
           }
         if(UseBuyLimit)
           {
            price=price_buy_limit-(double)i*ExtStepLimit;
            sl=(StopLoss==0)?0.0:price-ExtStopLoss;
            tp=(TakeProfit==0)?0.0:price+ExtTakeProfit;
            double lot=(i==0 || CoefficientLimit==1.0)?VolumeLimit:LotCheck(VolumeLimit*(double)i*CoefficientLimit);
            if(lot==0.0)
               continue;
            PendingOrder(ORDER_TYPE_BUY_LIMIT,lot,price,sl,tp,Expiration);
           }
         if(UseSellStop)
           {
            price=price_sell_stop-(double)i*ExtStepStop;
            sl=(StopLoss==0)?0.0:price+ExtStopLoss;
            tp=(TakeProfit==0)?0.0:price-ExtTakeProfit;
            double lot=(i==0 || CoefficientStop==1.0)?VolumeStop:LotCheck(VolumeStop*(double)i*CoefficientStop);
            if(lot==0.0)
               continue;
            PendingOrder(ORDER_TYPE_SELL_STOP,lot,price,sl,tp,Expiration);
           }
         if(UseSellLimit)
           {
            price=price_sell_limit-(double)i*ExtStepLimit;
            sl=(StopLoss==0)?0.0:price+ExtStopLoss;
            tp=(TakeProfit==0)?0.0:price-ExtTakeProfit;
            double lot=(i==0 || CoefficientLimit==1.0)?VolumeLimit:LotCheck(VolumeLimit*(double)i*CoefficientLimit);
            if(lot==0.0)
               continue;
            PendingOrder(ORDER_TYPE_SELL_LIMIT,lot,price,sl,tp,Expiration);
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
//| Pending order                                                    |
//+------------------------------------------------------------------+
void PendingOrder(ENUM_ORDER_TYPE order_type,double volume,double price,double sl,double tp,int expiration)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   bool result=false;
   if(expiration<=0)
      result=m_trade.OrderOpen(m_symbol.Name(),order_type,volume,0.0,
                               m_symbol.NormalizePrice(price),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp));
   else
      result=m_trade.OrderOpen(m_symbol.Name(),order_type,volume,0.0,
                               m_symbol.NormalizePrice(price),m_symbol.NormalizePrice(sl),m_symbol.NormalizePrice(tp),
                               ORDER_TIME_SPECIFIED,TimeCurrent()+expiration*60);
   if(result)
     {
      if(m_trade.ResultOrder()==0)
        {
         Print("#1 ",EnumToString(order_type)," -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of result: ",m_trade.ResultRetcodeDescription());
         PrintResultTrade(m_trade,m_symbol);
        }
      else
        {
         Print("#2 ",EnumToString(order_type)," -> true. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of result: ",m_trade.ResultRetcodeDescription());
         PrintResultTrade(m_trade,m_symbol);
        }
     }
   else
     {
      Print("#3 ",EnumToString(order_type)," -> false. Result Retcode: ",m_trade.ResultRetcode(),
            ", description of result: ",m_trade.ResultRetcodeDescription());
      PrintResultTrade(m_trade,m_symbol);
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
//| Profit all positions                                             |
//+------------------------------------------------------------------+
double  ProfitAllPositions()
  {
   double profit=0.0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            profit+=m_position.Commission()+m_position.Swap()+m_position.Profit();
//---
   return(profit);
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
void DeleteAllPendingOrders()
  {
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            m_trade.OrderDelete(m_order.Ticket());
  }

//+------------------------------------------------------------------+

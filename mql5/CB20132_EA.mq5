//+------------------------------------------------------------------+
//|                          BHS system(barabashkakvn's edition).mq5 |
//|                                                        fortrader |
//|                                                 www.fortrader.ru |
//+------------------------------------------------------------------+
#property copyright "fortrader"
#property link      "www.fortrader.ru"
#property version   "1.002"
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
//--- input parameters
input double               InpLots              = 0.1;                        // Lots
input ushort               InpStopLossBuy       = 300;                        // Stop Loss BUY
input ushort               InpStopLossSell      = 300;                        // Stop Loss SELL
input ushort               InpTrailingStopBuy   = 100;                        // Trailing Stop BUY
input ushort               InpTrailingStopSell  = 100;                        // Trailing Stop SELL
ushort                     InpTrailingStep      = 10;                         // Trailing Step
input ushort               InpStep              = 500;                        // Step of the "round" number
input uchar                Expiration           = 1;                          // Life time of the pending order (in hours)
sinput string              _0_                  = "AMA indicator parameters"; // --- AMA indicator parameters ---
input int                  InpAma_period        = 15;                         // AMA: Period of calculation 
input int                  InpFast_ma_period    = 2;                          // AMA: Period of fast MA 
input int                  InpSlow_ma_period    = 30;                         // AMA: Period of slow MA 
input int                  InpAma_shift         = 0;                          // AMA: Horizontal shift 
input ENUM_APPLIED_PRICE   InpApplied_price     = PRICE_CLOSE;                // AMA: Type of price 
input ulong                m_magic              = 212626795;                  // magic number
//---
ulong          m_slippage=10;                // slippage

double         ExtStopLossBuy=0.0;
double         ExtStopLossSell=0.0;
double         ExtTrailingStopBuy=0.0;
double         ExtTrailingStopSell=0.0;
double         ExtTrailingStep=0.0;
//---
int            handle_iAMA;                  // variable for storing the handle of the iAMA indicator 
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
      Print(err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   m_trade.SetExpertMagicNumber(m_magic);
//---
   if(IsFillingTypeAllowed(SYMBOL_FILLING_FOK))
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if(IsFillingTypeAllowed(SYMBOL_FILLING_IOC))
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
//---
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   ExtStopLossBuy       =InpStopLossBuy      *m_symbol.Point();
   ExtStopLossSell      =InpStopLossSell     *m_symbol.Point();
   ExtTrailingStopBuy   =InpTrailingStopBuy  *m_symbol.Point();
   ExtTrailingStopSell  =InpTrailingStopSell *m_symbol.Point();
   ExtTrailingStep      =InpTrailingStep     *m_symbol.Point();
//--- create handle of the indicator iAMA
   handle_iAMA=iAMA(m_symbol.Name(),Period(),InpAma_period,InpFast_ma_period,InpSlow_ma_period,InpAma_shift,InpApplied_price);
//--- if the handle is not created 
   if(handle_iAMA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iAMA indicator for the symbol %s/%s, error code %d",
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
//--- how Math() function works:
   return;
//+------------------------------------------------------------------+
//| Input parameter: price                                           |
//|  price (for example 1.08003)                                     |
//|  step (for example 200, which means 20 points on a 5-digit)      |
//| output parameters:                                               |
//|  price_ceil - integer numeric value closest from above           |
//|  price_round - a value rounded off to the nearest integer        |
//|  price_floor - integer numeric value closest from below          |
//+------------------------------------------------------------------+
   double price=1.01561;
   int step=30;
   Print("\n","Start price: ",DoubleToString(price,5),", step: ",DoubleToString(step,0));
   for(int i=0;i<10;i++)
     {
      double price_ceil=0.0;
      double price_round=0.0;
      double price_floor=0.0;
      Math(price,(double)step,price_ceil,price_round,price_floor);
      Print("price(",DoubleToString(price,5),"), price+step(",
            DoubleToString(price+step*Point(),5),"), ceil(",
            DoubleToString(price,5),") ->  ",
            DoubleToString(price_ceil,5));
      Print("price(",DoubleToString(price,5),"),                    , round(",
            DoubleToString(price,5),") ->  ",
            DoubleToString(price_round,5));
      Print("price(",DoubleToString(price,5),"), price-step(",
            DoubleToString(price-step*Point(),5),"), floor(",
            DoubleToString(price,5),") ->  ",
            DoubleToString(price_floor,5));
      Print("");
      price+=1.9;
     }
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
   double price=iClose(0);
   if(price==0.0)
     {
      PrevBars=iTime(1);
      return;
     }
   double price_ceil=0.0;
   double price_round=0.0;
   double price_floor=0.0;
//+------------------------------------------------------------------+
//| Input parameter: price                                           |
//|  price (for example 1.08003)                                     |
//|  step (for example 200, which means 20 points on a 5-digit)      |
//| output parameters:                                               |
//|  price_ceil - integer numeric value closest from above           |
//|  price_round - a value rounded off to the nearest integer        |
//|  price_floor - integer numeric value closest from below          |
//+------------------------------------------------------------------+
   Math(price,(double)InpStep,price_ceil,price_round,price_floor);

   double AMA=iAMAGet(1);

   int count_buys=0;
   int count_sells=0;
   CalculatePositions(count_buys,count_sells);
   int count_buy_stop=0;
   int count_sell_stop=0;
   CalculatePendingOrders(count_buy_stop,count_sell_stop);

   if(count_buys+count_sells+count_buy_stop+count_sell_stop==0)
     {
      if(price>AMA)// 
        {
         PlacingBuyStop(InpLots,price_ceil);
         return;
        }

      if(price<AMA)
        {
         PlacingSellStop(InpLots,price_floor);
         return;
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
      //if(deal_reason!=-1)
      //   DebugBreak();
      if(deal_symbol==m_symbol.Name() && deal_magic==m_magic)
         if(deal_entry==DEAL_ENTRY_IN)
            if((ENUM_DEAL_TYPE)deal_type==DEAL_TYPE_BUY || (ENUM_DEAL_TYPE)deal_type==DEAL_TYPE_BUY)
               DeleteAllOrders();
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
//| Check the correctness of the order volume                        |
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
//| Get value of buffers for the iAMA                                |
//+------------------------------------------------------------------+
double iAMAGet(const int index)
  {
   double AMA[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iAMAarray with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iAMA,0,index,1,AMA)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iAMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(AMA[0]);
  }
//+------------------------------------------------------------------+ 
//| Get Close for specified bar index                                | 
//+------------------------------------------------------------------+ 
double iClose(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   double Close[1];
   double close=0;
   int copied=CopyClose(symbol,timeframe,index,1,Close);
   if(copied>0)
      close=Close[0];
   return(close);
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
//| Input parameter: price                                           |
//|  price (for example 1.08003)                                     |
//|  step (for example 200, which means 20 points on a 5-digit)      |
//| output parameters:                                               |
//|  price_ceil - integer numeric value closest from above           |
//|  price_round - a value rounded off to the nearest integer        |
//|  price_floor - integer numeric value closest from below          |
//+------------------------------------------------------------------+
void Math(const double price,const double step,double &price_ceil,double &price_round,double &price_floor)
  {
   double point=Point();

   double step1=MathRound(price*1/point/step);          // returns a value rounded off to the nearest integer of the specified numeric value
   price_round=step*step1*point;

   double step1_ceil=MathCeil((price_round+step/2.0*point)*1/point/step);      // returns integer numeric value closest from above
   double step1_floor=MathFloor((price_round-step/2.0*point)*1/point/step);    // returns integer numeric value closest from below

   price_ceil=step*step1_ceil*point;
   price_floor=step*step1_floor*point;
//---
   return;
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
//| Delete all pending orders                                        |
//+------------------------------------------------------------------+
void DeleteAllOrders()
  {
   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            m_trade.OrderDelete(m_order.Ticket());
  }
//+------------------------------------------------------------------+
//| Placing Buy Stop                                                 |
//+------------------------------------------------------------------+
void PlacingBuyStop(const double lot,double price)
  {
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot,price,ORDER_TYPE_BUY);
   if(check_volume_lot!=0.0 && check_volume_lot>=lot)
     {
      datetime expiration=TimeCurrent()+Expiration*3600-30;
      double sl=(InpStopLossBuy==0)?0.0:price-ExtStopLossBuy;
      if(m_trade.BuyStop(lot,m_symbol.NormalizePrice(price),m_symbol.Name(),
         m_symbol.NormalizePrice(sl),0.0,ORDER_TIME_SPECIFIED,expiration))
         Print("BUY_STOP - > true. ticket of order = ",m_trade.ResultOrder());
      else
         Print("BUY_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
               ", ticket of order: ",m_trade.ResultOrder());
     }
//---
  }
//+------------------------------------------------------------------+
//| Placing Sell Stop                                                |
//+------------------------------------------------------------------+
void PlacingSellStop(const double lot,double price)
  {
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot,price,ORDER_TYPE_SELL);
   if(check_volume_lot!=0.0 && check_volume_lot>=lot)
     {
      datetime expiration=TimeCurrent()+Expiration*3600-30;
      double sl=(InpStopLossSell==0)?0.0:price+ExtStopLossSell;
      if(m_trade.SellStop(lot,m_symbol.NormalizePrice(price),m_symbol.Name(),
         m_symbol.NormalizePrice(sl),0.0,ORDER_TIME_SPECIFIED,expiration))
         Print("SELL_STOP - > true. ticket of order = ",m_trade.ResultOrder());
      else
         Print("SELL_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of Retcode: ",m_trade.ResultRetcodeDescription(),
               ", ticket of order: ",m_trade.ResultOrder());
     }
//---
  }
//+------------------------------------------------------------------+
//| Trailing                                                         |
//+------------------------------------------------------------------+
void Trailing()
  {
   if(InpTrailingStopBuy==0 && InpTrailingStopSell==0)
      return;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(InpTrailingStopBuy!=0)
                  if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtTrailingStopBuy+ExtTrailingStep)
                     if(m_position.StopLoss()<m_position.PriceCurrent()-(ExtTrailingStopBuy+ExtTrailingStep))
                       {
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(m_position.PriceCurrent()-ExtTrailingStopBuy),
                           m_position.TakeProfit()))
                           Print("Modify BUY ",m_position.Ticket(),
                                 " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                 ", description of result: ",m_trade.ResultRetcodeDescription());
                        continue;
                       }
              }
            else
              {
               if(InpTrailingStopSell!=0)
                  if(m_position.PriceOpen()-m_position.PriceCurrent()>ExtTrailingStopSell+ExtTrailingStep)
                     if((m_position.StopLoss()>(m_position.PriceCurrent()+(ExtTrailingStopSell+ExtTrailingStep))) || 
                        (m_position.StopLoss()==0))
                       {
                        if(!m_trade.PositionModify(m_position.Ticket(),
                           m_symbol.NormalizePrice(m_position.PriceCurrent()+ExtTrailingStopSell),
                           m_position.TakeProfit()))
                           Print("Modify SELL ",m_position.Ticket(),
                                 " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                 ", description of result: ",m_trade.ResultRetcodeDescription());
                       }
              }

           }
  }
//+------------------------------------------------------------------+

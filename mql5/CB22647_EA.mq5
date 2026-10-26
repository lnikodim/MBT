//+------------------------------------------------------------------+
//|                             Starter(barabashkakvn's edition).mq5 |
//+------------------------------------------------------------------+
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
//--- input parameters
input double   InpMaximumRisk       = 0.02;     // Maximum Risk in percentage
input double   InpDecreaseFactor    = 3;        // Descrease factor
input ushort   InpHistoryDays       = 60;       // History days
input ushort   InpStopLoss          = 0;        // Stop Loss (in pips)
input ushort   InpTrailingStop      = 5;        // Trailing Stop (min distance from price to Stop Loss) (in pips)
input ushort   InpTrailingStep      = 5;        // Trailing Step (in pips)
//--- CCI parameters
input int      Inp_CCI_ma_period=14;            // CCI: averaging period 
input ENUM_APPLIED_PRICE Inp_CCI_applied_price=PRICE_TYPICAL;// CCI: type of price 
input uchar    Inp_CCI_level        = 100;      // CCI level
input uchar    Inp_CCI_bar_current  = 0;        // CCI current bar 
input uchar    Inp_CCI_bar_prev     = 1;        // CCI previous bar 
//--- ma_array[Inp_MA_bar_current] parameters
input int      Inp_MA_ma_period     = 120;      // MA: averaging period 
input ENUM_MA_METHOD Inp_MA_ma_method=MODE_SMA; // MA: smoothing type 
input int      Inp_MA_bar_current   = 0;        // MA bar current
input double   Inp_MA_delta         = 0.001;    // MA delta (MA current bar "-" MA previous bar) 
input ulong    m_magic              = 191318850;// magic number
//---
ulong  m_slippage=10;            // slippage
double ExtStopLoss=0.0;
double ExtTrailingStop=0.0;
double ExtTrailingStep=0.0;
int    handle_iCCI;              // variable for storing the handle of the iCCI indicator 
int    handle_iMA;               // variable for storing the handle of the iMA indicator 
double m_adjusted_point;         // point value adjusted for 3 or 5 points
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
//---
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtStopLoss          = InpStopLoss        * m_adjusted_point;
   ExtTrailingStop      = InpTrailingStop    * m_adjusted_point;
   ExtTrailingStep      = InpTrailingStep    * m_adjusted_point;
//--- create handle of the indicator iCCI
   handle_iCCI=iCCI(m_symbol.Name(),Period(),Inp_CCI_ma_period,Inp_CCI_applied_price);
//--- if the handle is not created 
   if(handle_iCCI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iCCI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA=iMA(m_symbol.Name(),Period(),Inp_MA_ma_period,0,Inp_MA_ma_method,PRICE_CLOSE);
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
   Trailing();
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
   double cci_array[];
   ArraySetAsSeries(cci_array,true);
   double ma_array[];
   ArraySetAsSeries(ma_array,true);

   int buffer=0,start_pos=0;
   int count=0;
   if(Inp_CCI_bar_current>count)
      count=Inp_CCI_bar_current;
   if(Inp_CCI_bar_prev>count)
      count=Inp_CCI_bar_prev;
   if(Inp_MA_bar_current>count)
      count=Inp_MA_bar_current;
   if(Inp_MA_bar_current+1>count)
      count=Inp_MA_bar_current+1;
   count++;

   if(!iGetArray(handle_iCCI,buffer,start_pos,count,cci_array) || !iGetArray(handle_iMA,buffer,start_pos,count,ma_array))
     {
      PrevBars=0;
      return;
     }
//---
   int RealTotal=CalculateAllPositions();
   if(RealTotal<1)
     {
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
      //--- check BUY
      if((ma_array[Inp_MA_bar_current]-ma_array[Inp_MA_bar_current+1]>Inp_MA_delta) && 
         (cci_array[Inp_CCI_bar_prev]<cci_array[Inp_CCI_bar_current]) && 
         ((int)cci_array[Inp_CCI_bar_current]>-Inp_CCI_level && (int)cci_array[Inp_CCI_bar_prev]<-Inp_CCI_level))
        {
         //---
         double lot=TradeSizeOptimized();
         if(lot==0.0)
            return;
         double price=m_symbol.Ask();
         double sl=(InpStopLoss==0)?0.0:price-ExtStopLoss;
         if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0))
           {
            OpenBuy(lot,sl,0.0);
            return;
           }
        }
      //--- check SELL
      if((ma_array[Inp_MA_bar_current]-ma_array[Inp_MA_bar_current+1]<-Inp_MA_delta) && 
         (cci_array[Inp_CCI_bar_prev]>cci_array[Inp_CCI_bar_current]) && 
         ((int)cci_array[Inp_CCI_bar_current]<Inp_CCI_level && (int)cci_array[Inp_CCI_bar_prev]>Inp_CCI_level))
        {
         double lot=TradeSizeOptimized();
         if(lot==0.0)
            return;
         double price=m_symbol.Bid();
         double sl=(InpStopLoss==0)?0.0:price+ExtStopLoss;
         if(((sl!=0 && ExtStopLoss>=stop_level) || sl==0.0))
           {
            OpenSell(lot,sl,0.0);
            return;
           }
        }
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
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double TradeSizeOptimized(void)
  {
   double price=m_symbol.Ask();
   double margin=0.0;
//--- select lot size
   margin=m_account.MarginCheck(m_symbol.Name(),ORDER_TYPE_BUY,1.0,price);
   if(margin<=0.0 || margin==EMPTY_VALUE)
      return(0.0);
   double lot=NormalizeDouble(m_account.FreeMargin()*InpMaximumRisk/margin,2);
//--- calculate number of losses orders without a break
   if(InpDecreaseFactor>0)
     {
      //--- select history for access
      datetime time=TimeTradeServer();
      HistorySelect(time-InpHistoryDays*60*60*24,time+60*60*24);
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
//| Calculate all positions                                          |
//+------------------------------------------------------------------+
int CalculateAllPositions()
  {
   int total=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            total++;
//---
   return(total);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double long_lot,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check=m_account.FreeMarginCheck(m_symbol.Name(),ORDER_TYPE_BUY,long_lot,m_symbol.Ask());
   if(free_margin_check>0.0)
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
void OpenSell(double short_lot,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check=m_account.FreeMarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,short_lot,m_symbol.Bid());
   if(free_margin_check>0.0)
     {
      if(m_trade.Sell(short_lot,NULL,m_symbol.Bid(),sl,tp))
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

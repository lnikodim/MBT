//+------------------------------------------------------------------+
//|                          Extreme EA(barabashkakvn's edition).mq5 |
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
input double   InpMaximumRisk    = 0.05;     // Maximum Risk in percentage
input double   InpDecreaseFactor = 6;        // Descrease factor
input ushort   InpHistoryDays    = 60;       // History days
input uchar    InpMaxPositions   = 3;        // Maximum positions
//--- CCI parameters
input ENUM_TIMEFRAMES      Inp_CCI_TimeFrame             = PERIOD_M30;     // CCI: timeframe
input int                  Inp_CCI_ma_period             = 12;             // CCI: averaging period 
input ENUM_APPLIED_PRICE   Inp_CCI_applied_price         = PRICE_TYPICAL;  // CCI: type of price 
input int                  Inp_CCI_Up_Level              = 50;             // CCI Up level
input int                  Inp_CCI_Down_Level            = -50;            // CCI Down level
input int                  Inp_CCI_Current_Bar           = 1;              // CCI Current Bar
//--- Moving Average parameters
input ENUM_TIMEFRAMES      Inp_MA_Fast_Slow_TimeFrame    = PERIOD_M15;     // MA Fast and Slow: timeframe 
input int                  Inp_MA_Fast_ma_period         = 15;             // MA Fast: averaging period
input int                  Inp_MA_Slow_ma_period         = 75;             // MA Slow: averaging period 
input int                  Inp_MA_Fast_Slow_ma_shift     = 0;              // MA Fast and Slow: horizontal shift 
input ENUM_MA_METHOD       Inp_MA_Fast_Slow_ma_method    = MODE_EMA;       // MA Fast and Slow: smoothing type 
input ENUM_APPLIED_PRICE   Inp_MA_Fast_Slow_applied_price= PRICE_MEDIAN;   // type of price or handle 
//---
input ulong    m_magic=216920074;// magic number
//---
ulong  m_slippage=10;            // slippage
int    handle_iCCI;              // variable for storing the handle of the iCCI indicator 
int    handle_iMA_Fast;          // variable for storing the handle of the iMA indicator 
int    handle_iMA_Slow;          // variable for storing the handle of the iMA indicator 
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
   m_trade.SetDeviationInPoints(m_slippage);
//--- create handle of the indicator iCCI
   handle_iCCI=iCCI(m_symbol.Name(),Inp_CCI_TimeFrame,Inp_CCI_ma_period,Inp_CCI_applied_price);
//--- if the handle is not created 
   if(handle_iCCI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iCCI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Inp_CCI_TimeFrame),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_Fast=iMA(m_symbol.Name(),Inp_MA_Fast_Slow_TimeFrame,Inp_MA_Fast_ma_period,
                       Inp_MA_Fast_Slow_ma_shift,Inp_MA_Fast_Slow_ma_method,Inp_MA_Fast_Slow_applied_price);
//--- if the handle is not created 
   if(handle_iMA_Fast==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Inp_MA_Fast_Slow_TimeFrame),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_Slow=iMA(m_symbol.Name(),Inp_MA_Fast_Slow_TimeFrame,Inp_MA_Slow_ma_period,
                       Inp_MA_Fast_Slow_ma_shift,Inp_MA_Fast_Slow_ma_method,Inp_MA_Fast_Slow_applied_price);
//--- if the handle is not created 
   if(handle_iMA_Slow==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Inp_MA_Fast_Slow_TimeFrame),
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
   double cci_array[],ma_fast_array[],ma_slow_array[];
   ArraySetAsSeries(cci_array,true);
   ArraySetAsSeries(ma_fast_array,true);
   ArraySetAsSeries(ma_slow_array,true);

   int buffer=0,start_pos=0;
   int count=(Inp_CCI_Current_Bar>=3)?Inp_CCI_Current_Bar+1:3;

   if(!iGetArray(handle_iCCI,buffer,start_pos,count,cci_array) || 
      !iGetArray(handle_iMA_Fast,buffer,start_pos,count,ma_fast_array) || 
      !iGetArray(handle_iMA_Slow,buffer,start_pos,count,ma_slow_array))
     {
      PrevBars=0;
      return;
     }
//---
   int all_positions=CalculateAllPositions();

   double freeze_level,stop_level;
   if(!RefreshRates())
     {
      PrevBars=0; return;
     }
   freeze_level=m_symbol.FreezeLevel()*m_symbol.Point();
   if(freeze_level==0.0)
      freeze_level=(m_symbol.Ask()-m_symbol.Bid())*3.0;
   freeze_level*=1.1;

   stop_level=m_symbol.StopsLevel()*m_symbol.Point();
   if(stop_level==0.0)
      stop_level=(m_symbol.Ask()-m_symbol.Bid())*3.0;
   stop_level*=1.1;

   if(freeze_level<=0.0 || stop_level<=0.0)
     {
      PrevBars=0; return;
     }
//---
   if(ma_slow_array[1]>ma_slow_array[2] && ma_fast_array[0]>ma_fast_array[1] && (int)cci_array[0]<Inp_CCI_Down_Level)
     {
      //-- Buy
      if(all_positions<InpMaxPositions)
        {
         double lot=TradeSizeOptimized();
         if(lot>0.0)
            OpenBuy(lot,0.0,0.0);
        }
     }
   else if(ma_slow_array[1]<=ma_slow_array[2])
     {
      ClosePositions(POSITION_TYPE_BUY);
     }
//---
   if(ma_slow_array[1]<ma_slow_array[2] && ma_fast_array[0]<ma_fast_array[1] && (int)cci_array[0]>Inp_CCI_Up_Level)
     {
      //-- Sell
      if(all_positions<InpMaxPositions)
        {
         double lot=TradeSizeOptimized();
         if(lot>0.0)
            OpenSell(lot,0.0,0.0);
        }
     }
   else if(ma_slow_array[1]>=ma_slow_array[2])
     {
      ClosePositions(POSITION_TYPE_SELL);
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
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double lot,double sl,double tp)
  {
   sl=0.0;
   tp=0.0;
   double long_lot=lot;
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
void OpenSell(double lot,double sl,double tp)
  {
   sl=0.0;
   tp=0.0;
   double short_lot=lot;
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
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultTrade(CTrade &trade,CSymbolInfo &symbol)
  {
   Print("File: ",__FILE__,", symbol: ",symbol.Name());
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
//| Close positions                                                  |
//+------------------------------------------------------------------+
void ClosePositions(const ENUM_POSITION_TYPE pos_type)
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==Symbol() && m_position.Magic()==m_magic)
            if(m_position.PositionType()==pos_type) // gets the position type
               m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+

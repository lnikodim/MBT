//+------------------------------------------------------------------+
//|                       TrueSort_1100(barabashkakvn's edition).mq5 |
//|                                                           MaxBau |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009, MaxBau"
#property version   "1.101"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
CMoneyFixedMargin *m_money;
//--- input parameters
input ushort               InpStopLoss          = 50;          // Stop Loss (in pips)
input ushort               InpTakeProfit        = 150;         // Take Profit (in pips)
input ushort               InpTrailingStop      = 5;           // Trailing Stop (in pips)
input ushort               InpTrailingStep      = 1;           // Trailing Step (in pips)
input double               Risk                 = 5;           // Risk in percent for a deal from a free margin
input int                  InpADX_adx_period    = 24;          // ADX: averaging period 
input int                  InpMA_ma_shift       = 0;           // MA's: horizontal shift 
input ENUM_MA_METHOD       InpMA_ma_method      = MODE_EMA;    // MA's: smoothing type 
input ENUM_APPLIED_PRICE   InpMA_applied_price  = PRICE_CLOSE; // MA's: type of price  
input ulong                m_magic=532830322;                  // magic number
//---
ulong          m_slippage=10;                // slippage

double         ExtStopLoss=0.0;
double         ExtTakeProfit=0.0;
double         ExtTrailingStop=0.0;
double         ExtTrailingStep=0.0;

int    handle_iADX;                          // variable for storing the handle of the iADX indicator 
int    handle_iMA_10;                        // variable for storing the handle of the iMA indicator 
int    handle_iMA_20;                        // variable for storing the handle of the iMA indicator 
int    handle_iMA_50;                        // variable for storing the handle of the iMA indicator 
int    handle_iMA_100;                       // variable for storing the handle of the iMA indicator 
int    handle_iMA_200;                       // variable for storing the handle of the iMA indicator 

double         m_adjusted_point;             // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpTrailingStop!=0 && InpTrailingStep==0)
     {
      Alert(__FUNCTION__," ERROR: Trailing is not possible: the parameter \"Trailing Step\" is zero!");
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();
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
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtStopLoss=InpStopLoss*m_adjusted_point;
   ExtTakeProfit=InpTakeProfit*m_adjusted_point;
   ExtTrailingStop=InpTrailingStop*m_adjusted_point;
   ExtTrailingStep=InpTrailingStep*m_adjusted_point;
//---
   if(m_money!=NULL)
      delete m_money;
   m_money=new CMoneyFixedMargin;
   if(m_money!=NULL)
     {
      if(!m_money.Init(GetPointer(m_symbol),Period(),m_symbol.Point()*digits_adjust))
         return(INIT_FAILED);
      m_money.Percent(Risk);
     }
   else
     {
      Print(__FUNCTION__,", ERROR: Object CMoneyFixedMargin is NULL");
      return(INIT_FAILED);
     }
//--- create handle of the indicator iADX
   handle_iADX=iADX(m_symbol.Name(),Period(),InpADX_adx_period);
//--- if the handle is not created 
   if(handle_iADX==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iADX indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_10=iMA(m_symbol.Name(),Period(),10,InpMA_ma_shift,InpMA_ma_method,InpMA_applied_price);
//--- if the handle is not created 
   if(handle_iMA_10==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA#10 indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_20=iMA(m_symbol.Name(),Period(),20,InpMA_ma_shift,InpMA_ma_method,InpMA_applied_price);
//--- if the handle is not created 
   if(handle_iMA_20==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA#20 indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_50=iMA(m_symbol.Name(),Period(),50,InpMA_ma_shift,InpMA_ma_method,InpMA_applied_price);
//--- if the handle is not created 
   if(handle_iMA_50==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA#50 indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_100=iMA(m_symbol.Name(),Period(),100,InpMA_ma_shift,InpMA_ma_method,InpMA_applied_price);
//--- if the handle is not created 
   if(handle_iMA_100==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA#100 indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_200=iMA(m_symbol.Name(),Period(),200,InpMA_ma_shift,InpMA_ma_method,InpMA_applied_price);
//--- if the handle is not created 
   if(handle_iMA_200==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA#200 indicator for the symbol %s/%s, error code %d",
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
   datetime time_0=iTime(0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
//---
   bool open_buy=false;
   bool open_sell=false;
   bool close_buy=false;
   bool close_sell=false;
   double adx_0=iADXGet(MAIN_LINE,0);
   double arr_ma_10[];
   double arr_ma_20[];
   double arr_ma_50[];
   double arr_ma_100[];
   double arr_ma_200[];
   int start_position=0;
   int count=2;
   if(adx_0==0.0 || 
      !iMAGetArray(handle_iMA_10,start_position,count,arr_ma_10) || 
      !iMAGetArray(handle_iMA_20,start_position,count,arr_ma_20) || 
      !iMAGetArray(handle_iMA_50,start_position,count,arr_ma_50) || 
      !iMAGetArray(handle_iMA_100,start_position,count,arr_ma_100) || 
      !iMAGetArray(handle_iMA_200,start_position,count,arr_ma_200) || 
      !RefreshRates())
     {
      PrevBars=iTime(1);
      return;
     }
//---
   ArraySetAsSeries(arr_ma_10,true);
   ArraySetAsSeries(arr_ma_20,true);
   ArraySetAsSeries(arr_ma_50,true);
   ArraySetAsSeries(arr_ma_100,true);
   ArraySetAsSeries(arr_ma_200,true);
//---
   if(adx_0>20.0)
     {
      if(arr_ma_10[0]>arr_ma_20[0] && arr_ma_20[0]>arr_ma_50[0] && arr_ma_50[0]>arr_ma_100[0] && arr_ma_100[0]>arr_ma_200[0])
         if(arr_ma_10[1]>arr_ma_20[1] && arr_ma_20[1]>arr_ma_50[1] && arr_ma_50[1]>arr_ma_100[1] && arr_ma_100[1]>arr_ma_200[1])
            open_buy=true;
      if(arr_ma_10[0]<arr_ma_20[0] && arr_ma_20[0]<arr_ma_50[0] && arr_ma_50[0]<arr_ma_100[0] && arr_ma_100[0]<arr_ma_200[0])
         if(arr_ma_10[1]<arr_ma_20[1] && arr_ma_20[1]<arr_ma_50[1] && arr_ma_50[1]<arr_ma_100[1] && arr_ma_100[1]<arr_ma_200[1])
            open_sell=true;
     }
   if(arr_ma_10[0]<=arr_ma_20[0] || arr_ma_20[0]<=arr_ma_50[0] || arr_ma_50[0]<=arr_ma_100[0] || arr_ma_100[0]<=arr_ma_200[0])
      close_buy=true;
   if(arr_ma_10[0]>=arr_ma_20[0] || arr_ma_20[0]>=arr_ma_50[0] || arr_ma_50[0]>=arr_ma_100[0] || arr_ma_100[0]>=arr_ma_200[0])
      close_sell=true;
   if(open_buy && close_buy)
      DebugBreak();
   if(open_sell && close_sell)
      DebugBreak();
//--- open buy
   if(open_buy)
     {
      double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol.Ask()+ExtTakeProfit;
      OpenBuy(sl,tp);
     }
//--- open sell
   if(open_sell)
     {
      double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
      double tp=(InpTakeProfit==0)?0.0:m_symbol.Bid()-ExtTakeProfit;
      OpenSell(sl,tp);
     }
   if(close_buy)
      ClosePositions(POSITION_TYPE_BUY);
   if(close_sell)
      ClosePositions(POSITION_TYPE_SELL);
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
//| Get Time for specified bar index                                 | 
//+------------------------------------------------------------------+ 
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[1];
   datetime time=0; // D'1970.01.01 00:00:00'
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0)
      time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iADX                                |
//|  the buffer numbers are the following:                           |
//|    0 - MAIN_LINE, 1 - PLUSDI_LINE, 2 - MINUSDI_LINE              |
//+------------------------------------------------------------------+
double iADXGet(const int buffer,const int index)
  {
   double ADX[];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iADXBuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iADX,buffer,index,1,ADX)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iADX indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(ADX[0]);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA in the array                    |
//+------------------------------------------------------------------+
bool iMAGetArray(const int indicator_handle,const int start_pos,const int count,double &arr_buffer[])
  {
/*
int  CopyBuffer( 
   int       indicator_handle,     // indicator handle 
   int       buffer_num,           // indicator buffer number 
   int       start_pos,            // start position 
   int       count,                // amount to copy 
   double    buffer[]              // target array to copy 
   );
*/
//---
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
      Print("This a no dynamic array!");
      return(false);
     }
   ArrayFree(arr_buffer);
   int       buffer_num=0;          // indicator buffer number 
//--- reset error code 
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index 
   int copied=CopyBuffer(indicator_handle,buffer_num,start_pos,count,arr_buffer);
   if(copied<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
   else if(copied<count)
     {
      PrintFormat("%d elements from %d were copied",copied,count);
      DebugBreak();
      return(false);
     }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Trailing                                                         |
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
                        Print("Modify BUY ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
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
                        Print("Modify SELL ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
              }

           }
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double check_open_long_lot=m_money.CheckOpenLong(m_symbol.Ask(),sl);
   Print("sl=",DoubleToString(sl,m_symbol.Digits()),
         ", CheckOpenLong: ",DoubleToString(check_open_long_lot,2),
         ", Balance: ",    DoubleToString(m_account.Balance(),2),
         ", Equity: ",     DoubleToString(m_account.Equity(),2),
         ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
   if(check_open_long_lot==0.0)
     {
      Print(__FUNCTION__,", ERROR: method CheckOpenLong returned the value of \"0.0\"");
      return;
     }

//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_long_lot,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=check_open_long_lot)
        {
         if(m_trade.Buy(check_open_long_lot,m_symbol.Name(),m_symbol.Ask(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print(__FUNCTION__,", #1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print(__FUNCTION__,", #2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< method CheckOpenLong (",DoubleToString(check_open_long_lot,2),")");
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
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double check_open_short_lot=m_money.CheckOpenShort(m_symbol.Bid(),sl);
   Print("sl=",DoubleToString(sl,m_symbol.Digits()),
         ", CheckOpenLong: ",DoubleToString(check_open_short_lot,2),
         ", Balance: ",    DoubleToString(m_account.Balance(),2),
         ", Equity: ",     DoubleToString(m_account.Equity(),2),
         ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
   if(check_open_short_lot==0.0)
     {
      Print(__FUNCTION__,", ERROR: method CheckOpenShort returned the value of \"0.0\"");
      return;
     }

//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_short_lot,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=check_open_short_lot)
        {
         if(m_trade.Sell(check_open_short_lot,m_symbol.Name(),m_symbol.Bid(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print(__FUNCTION__,", #1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print(__FUNCTION__,", #2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< method CheckOpenShort (",DoubleToString(check_open_short_lot,2),")");
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
void PrintResult(CTrade &trade,CSymbolInfo &symbol)
  {
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result: "+trade.ResultRetcodeDescription());
   Print("deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("current bid price: "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("current ask price: "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("broker comment: "+trade.ResultComment());
//DebugBreak();
  }
//+------------------------------------------------------------------+
//| Close positions                                                  |
//+------------------------------------------------------------------+
void ClosePositions(const ENUM_POSITION_TYPE pos_type)
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            if(m_position.PositionType()==pos_type) // gets the position type
               m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+

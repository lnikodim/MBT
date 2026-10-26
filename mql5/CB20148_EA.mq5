//+------------------------------------------------------------------+
//|                            Ichimoku(barabashkakvn's edition).mq5 |
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
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
//--- input parameters
input double   InpLots              = 0.10;  // Lots
input ushort   InpStopLossBuy       = 100;   // Stop Loss BUY (in pips)
input ushort   InpTakeProfitBuy     = 300;   // Take Profit BUY (in pips)
input ushort   InpStopLossSell      = 100;   // Stop Loss SELL (in pips)
input ushort   InpTakeProfitSell    = 300;   // Take Profit SELL (in pips)
input ushort   InpTrailingStopBuy   = 50;    // Trailing Stop BUY (in pips)
input ushort   InpTrailingStopSell  = 50;    // Trailing Stop SELL (in pips)
ushort         InpTrailingStep      = 5;     // Trailing Step (in pips)
input bool     lFlagUseHourTrade    = false; // Use trade hours
input uchar    nFromHourTrade       = 0;     // Start hour
input uchar    nToHourTrade         = 23;    // End hour 
input int      InpTenkanSen         = 9;     // Ichimoku: period of Tenkan-sen 
input int      InpKijunSen          = 26;    // Ichimoku: period of Kijun-sen 
input int      InpSenkouSpanB       = 52;    // Ichimoku: period of Senkou Span B 
input ulong    m_magic=67161684;             // magic number
//---
ulong          m_slippage=10;                // slippage

double         ExtStopLossBuy=0.0;
double         ExtTakeProfitBuy=0.0;
double         ExtStopLossSell=0.0;
double         ExtTakeProfitSell=0.0;
double         ExtTrailingStopBuy=0.0;
double         ExtTrailingStopSell=0.0;
double         ExtTrailingStep=0.0;

int            handle_iIchimoku;             // variable for storing the handle of the iIchimoku indicator 

double         m_adjusted_point;             // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(lFlagUseHourTrade)
     {
      if(nFromHourTrade>23)
        {
         Print(__FUNCTION__,", ERROR: \"Start hour\" can not be more than 23!");
         return(INIT_PARAMETERS_INCORRECT);
        }
      if(nToHourTrade>23)
        {
         Print(__FUNCTION__,", ERROR: \"End hour\" can not be more than 23!");
         return(INIT_PARAMETERS_INCORRECT);
        }
      if(nFromHourTrade>=nToHourTrade)
        {
         Print(__FUNCTION__,", ERROR: \"Start hour\" can not be more than or equal to \"End hour\"!");
         return(INIT_PARAMETERS_INCORRECT);
        }
     }
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
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtStopLossBuy       = InpStopLossBuy        * m_adjusted_point;
   ExtTakeProfitBuy     = InpTakeProfitBuy      * m_adjusted_point;
   ExtStopLossSell      = InpStopLossSell       * m_adjusted_point;
   ExtTakeProfitSell    = InpTakeProfitSell     * m_adjusted_point;
   ExtTrailingStopBuy   = InpTrailingStopBuy    * m_adjusted_point;
   ExtTrailingStopSell  = InpTrailingStopSell   * m_adjusted_point;
   ExtTrailingStep      = InpTrailingStep       * m_adjusted_point;
//---
//--- create handle of the indicator iIchimoku
   handle_iIchimoku=iIchimoku(m_symbol.Name(),Period(),InpTenkanSen,InpKijunSen,InpSenkouSpanB);
//--- if the handle is not created 
   if(handle_iIchimoku==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iIchimoku indicator for the symbol %s/%s, error code %d",
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
//---
   if(lFlagUseHourTrade)
     {
      MqlDateTime str1;
      TimeToStruct(TimeCurrent(),str1);
      if(!(nFromHourTrade>=str1.hour && str1.hour<=nToHourTrade))
        {
         Comment("Time for trade has not come else!");
         return;
        }
     }
   double Close_0=iClose(0);
   if(Close_0==0.0)
      return;
//+------------------------------------------------------------------+
//| Get value of buffers for the iIchimoku                           |
//|  the buffer numbers are the following:                           |
//|   0 - TENKANSEN_LINE, 1 - KIJUNSEN_LINE, 2 - SENKOUSPANA_LINE,   |
//|   3 - SENKOUSPANB_LINE, 4 - CHIKOUSPAN_LINE                      |
//+------------------------------------------------------------------+
   double TENKANSEN_LINE_0    = iIchimokuGet(TENKANSEN_LINE,0);
   double KIJUNSEN_LINE_0     = iIchimokuGet(KIJUNSEN_LINE,0);
   double SENKOUSPANA_LINE_0  = iIchimokuGet(SENKOUSPANA_LINE,0);
   double SENKOUSPANB_LINE_0  = iIchimokuGet(SENKOUSPANB_LINE,0);
   double TENKANSEN_LINE_1    = iIchimokuGet(TENKANSEN_LINE,1);

   bool lFlagBuyOpen=false,lFlagSellOpen=false,lFlagBuyClose=false,lFlagSellClose=false;
   datetime Time_0=iTime(0);
   if(Time_0==D'1970.01.01 00:00:00')
      return;
   bool iIchimokuBuy=(TENKANSEN_LINE_1<KIJUNSEN_LINE_0 && TENKANSEN_LINE_0>=KIJUNSEN_LINE_0 && Close_0>SENKOUSPANB_LINE_0);
   if(iIchimokuBuy)
      lFlagBuyOpen=CheckExists(POSITION_TYPE_BUY,Time_0);

   bool iIchimokuSell=(TENKANSEN_LINE_1>KIJUNSEN_LINE_0 && TENKANSEN_LINE_0<=KIJUNSEN_LINE_0 && Close_0<SENKOUSPANA_LINE_0);
   if(iIchimokuSell)
      lFlagSellOpen=(CheckExists(POSITION_TYPE_SELL,Time_0));

   if(CalculateAllPositions()==0)
     {
      if(lFlagBuyOpen)
        {
         if(!RefreshRates())
            return;
         double sl=(InpStopLossBuy==0)?0.0:m_symbol.Ask()-ExtStopLossBuy;
         double tp=(InpTakeProfitBuy==0)?0.0:m_symbol.Ask()+ExtTakeProfitBuy;
         OpenBuy(sl,tp);
         return;
        }
      if(lFlagSellOpen)
        {
         if(!RefreshRates())
            return;
         double sl=(InpStopLossSell==0)?0.0:m_symbol.Bid()+ExtStopLossSell;
         double tp=(InpTakeProfitSell==0)?0.0:m_symbol.Bid()-ExtTakeProfitSell;
         OpenSell(sl,tp);
         return;
        }
     }
   else
     {
      if(lFlagBuyOpen)
        {
         ClosePositions(POSITION_TYPE_SELL);
        }
      else if(lFlagSellOpen)
        {
         ClosePositions(POSITION_TYPE_BUY);
        }
     }
//---
   Trailing();
//---
   return;
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
      symbol=Symbol();
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
//| Get value of buffers for the iIchimoku                           |
//|  the buffer numbers are the following:                           |
//|   0 - TENKANSEN_LINE, 1 - KIJUNSEN_LINE, 2 - SENKOUSPANA_LINE,   |
//|   3 - SENKOUSPANB_LINE, 4 - CHIKOUSPAN_LINE                      |
//+------------------------------------------------------------------+
double iIchimokuGet(const int buffer,const int index)
  {
   double Ichimoku[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iIchimoku array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iIchimoku,buffer,index,1,Ichimoku)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iIchimoku indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Ichimoku[0]);
  }
//+------------------------------------------------------------------+
//| Посмотрим не открывались ли позы на текущем баре                 |
//+------------------------------------------------------------------+
bool CheckExists(const ENUM_POSITION_TYPE pos_type,datetime &time)
  {
//--- for all positions
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            if(m_position.PositionType()==pos_type) // gets the position type
               if(m_position.Time()>=time)
                  return(false);
//--- request trade history 
   HistorySelect(time-30,TimeCurrent()+86400);
//---
   uint     total=HistoryDealsTotal();
   ulong    ticket=0;
//--- for all deals 
   for(uint i=0;i<total;i++) // for(uint i=0;i<total;i++) => i #0 - 2016, i #1045 - 2017
     {
      //--- try to get deals ticket 
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         //--- get deals properties 
         long deal_time          =HistoryDealGetInteger(ticket,DEAL_TIME);
         long deal_type          =HistoryDealGetInteger(ticket,DEAL_TYPE);
         long deal_entry         =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         long deal_magic         =HistoryDealGetInteger(ticket,DEAL_MAGIC);
         string deal_symbol      =HistoryDealGetString(ticket,DEAL_SYMBOL);
         //--- only for current symbol and magic
         if(deal_magic==m_magic && deal_symbol==m_symbol.Name())
            if(ENUM_DEAL_ENTRY(deal_entry)==DEAL_ENTRY_IN)
              {
               if(pos_type==POSITION_TYPE_BUY)
                 {
                  if((ENUM_DEAL_TYPE)deal_type==DEAL_TYPE_BUY)
                     if((datetime)deal_time>=time)
                        return(false);
                 }
               else if(pos_type==POSITION_TYPE_SELL)
                 {
                  if((ENUM_DEAL_TYPE)deal_type==DEAL_TYPE_SELL)
                     if((datetime)deal_time>=time)
                        return(false);
                 }
              }
        }
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.Buy(InpLots,m_symbol.Name(),m_symbol.Ask(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               //PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               //PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            //PrintResult(m_trade,m_symbol);
           }
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

//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.Sell(InpLots,m_symbol.Name(),m_symbol.Bid(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               //PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               //PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            //PrintResult(m_trade,m_symbol);
           }
        }
//---
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

//+------------------------------------------------------------------+
//|                          SV v.4.2.5(barabashkakvn's edition).mq5 |
//|                                   Copyright © 2009-2010 gorby777 |
//|                                          gorby_e-mail@rambler.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009-2010 gorby777"
#property link      "gorby_e-mail@rambler.ru"
#property version   "1.000"

#define MODE_LOW 1
#define MODE_HIGH 2
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
//---
//+------------------------------------------------------------------+
//| Enum hours                                                       |
//+------------------------------------------------------------------+
enum ENUM_HOURS
  {
   hour_00     = 0,     // 00
   hour_01     = 1,     // 01
   hour_02     = 2,     // 02
   hour_03     = 3,     // 03
   hour_04     = 4,     // 04
   hour_05     = 5,     // 05
   hour_06     = 6,     // 06
   hour_07     = 7,     // 07
   hour_08     = 8,     // 08
   hour_09     = 9,     // 09
   hour_10     = 10,    // 10
   hour_11     = 11,    // 11
   hour_12     = 12,    // 12
   hour_13     = 13,    // 13
   hour_14     = 14,    // 14
   hour_15     = 15,    // 15
   hour_16     = 16,    // 16
   hour_17     = 17,    // 17
   hour_18     = 18,    // 18
   hour_19     = 19,    // 19
   hour_20     = 20,    // 20
   hour_21     = 21,    // 21
   hour_22     = 22,    // 22
   hour_23     = 23     // 23
  };
//+------------------------------------------------------------------+
//| ENUM MINUTES                                                     |
//+------------------------------------------------------------------+
enum ENUM_MINUTES
  {
   minute_0    = 0,     // 00
   minute_1    = 1,     // 01
   minute_2    = 2,     // 02
   minute_3    = 3,     // 03
   minute_4    = 4,     // 04
   minute_5    = 5,     // 05
   minute_6    = 6,     // 06
   minute_7    = 7,     // 07
   minute_8    = 8,     // 08
   minute_9    = 9,     // 09
   minute_10   = 10,    // 10
   minute_11   = 11,    // 11
   minute_12   = 12,    // 12
   minute_13   = 13,    // 13
   minute_14   = 14,    // 14
   minute_15   = 15,    // 15
   minute_16   = 16,    // 16
   minute_17   = 17,    // 17
   minute_18   = 18,    // 18
   minute_19   = 19,    // 19
   minute_20   = 20,    // 20
   minute_21   = 21,    // 21
   minute_22   = 22,    // 22
   minute_23   = 23,    // 23
   minute_24   = 24,    // 24
   minute_25   = 25,    // 25
   minute_26   = 26,    // 26
   minute_27   = 27,    // 27
   minute_28   = 28,    // 28
   minute_29   = 29,    // 29
   minute_30   = 30,    // 30
   minute_31   = 31,    // 31
   minute_32   = 32,    // 32
   minute_33   = 33,    // 33
   minute_34   = 34,    // 34
   minute_35   = 35,    // 35
   minute_36   = 36,    // 36
   minute_37   = 37,    // 37
   minute_38   = 38,    // 38
   minute_39   = 39,    // 39
   minute_40   = 40,    // 40
   minute_41   = 41,    // 41
   minute_42   = 42,    // 42
   minute_43   = 43,    // 43
   minute_44   = 44,    // 44
   minute_45   = 45,    // 45
   minute_46   = 46,    // 46
   minute_47   = 47,    // 47
   minute_48   = 48,    // 48
   minute_49   = 49,    // 49
   minute_50   = 50,    // 50
   minute_51   = 51,    // 51
   minute_52   = 52,    // 52
   minute_53   = 53,    // 53
   minute_54   = 54,    // 54
   minute_55   = 55,    // 55
   minute_56   = 56,    // 56
   minute_57   = 57,    // 57
   minute_58   = 58,    // 58
   minute_59   = 59     // 59
  };
//--- input parameters
input bool                 InpLotsManual     = false;          // Use Manual setting ("true" -> "Lots", "false" -> "Risk")
input double               InpLots           = 0.1;            // Lots
input ushort               InpStopLoss       = 50;             // Stop Loss (in pips)
input ushort               InpTakeProfit     = 50;             // Take Profit (in pips)
input ushort               InpTrailingStop   = 5;              // Trailing Stop (in pips)
input ushort               InpTrailingStep   = 5;              // Trailing Step (in pips)
input double               Risk              = 5;              // Risk in percent for a deal from a free margin
input ENUM_HOURS           InpStartHour      = hour_19;        // Start hour
input ENUM_MINUTES         InpStartMin       = minute_0;       // Start minute
input uchar                InpShift          = 6;              // Shift
input uchar                InpInterval       = 27;             // Analyzed interval
input int                  MA_Fast_ma_period       = 14;             // MA Fast: averaging period 
input int                  MA_Fast_ma_shift        = 0;              // MA Fast: horizontal shift 
input ENUM_MA_METHOD       MA_Fast_ma_method       = MODE_SMMA;      // MA Fast: smoothing type 
input ENUM_APPLIED_PRICE   MA_Fast_applied_price   = PRICE_MEDIAN;   // MA Fast: type of price  
input int                  MA_Slow_ma_period       = 41;             // MA Slow: averaging period 
input int                  MA_Slow_ma_shift        = 0;              // MA Slow: horizontal shift 
input ENUM_MA_METHOD       MA_Slow_ma_method       = MODE_SMMA;      // MA Slow: smoothing type 
input ENUM_APPLIED_PRICE   MA_Slow_applied_price   = PRICE_MEDIAN;   // MA Slow: type of price 
sinput ulong               m_magic                 = 13433244;       // magic number
//---
ulong    m_slippage=10;                                              // slippage

double   ExtStopLoss=0.0;
double   ExtTakeProfit=0.0;
double   ExtTrailingStop=0.0;
double   ExtTrailingStep=0.0;

int      m_day_of_last_trade=0;                    // day of last trade
long     m_start_time_in_sec=0;

int      handle_iMA_Fast;                          // variable for storing the handle of the iMA indicator 
int      handle_iMA_Slow;                          // variable for storing the handle of the iMA indicator 

double   m_adjusted_point;                         // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpTrailingStop!=0 && InpTrailingStep==0)
     {
      Print(__FUNCTION__,", ERROR: \"Trailing Step\" == 0 !");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpInterval==0)
     {
      Print(__FUNCTION__,", ERROR: \"Analyzed interval\" can not be zero !");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(MA_Fast_ma_period>=MA_Slow_ma_period)
     {
      Print(__FUNCTION__,", ERROR: \"MA Fast: averaging period\" (",IntegerToString(MA_Fast_ma_period),") can not ",
            "be greater than or equal ","to \"MA Slow: averaging period\" (",IntegerToString(MA_Slow_ma_period),") !");
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();
//---
   if(InpLotsManual)
     {
      string err_text="";
      if(!CheckVolumeValue(InpLots,err_text))
        {
         Print(__FUNCTION__,", ERROR: ",err_text);
         return(INIT_PARAMETERS_INCORRECT);
        }
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

   ExtStopLoss    = InpStopLoss     * m_adjusted_point;
   ExtTakeProfit  = InpTakeProfit   * m_adjusted_point;
   ExtTrailingStop= InpTrailingStop * m_adjusted_point;
   ExtTrailingStep= InpTrailingStep * m_adjusted_point;
//---
   if(!InpLotsManual)
     {
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
     }
//--- create handle of the indicator iMA
   handle_iMA_Fast=iMA(m_symbol.Name(),Period(),MA_Fast_ma_period,MA_Fast_ma_shift,
                       MA_Fast_ma_method,MA_Fast_applied_price);
//--- if the handle is not created 
   if(handle_iMA_Fast==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_Slow=iMA(m_symbol.Name(),Period(),MA_Slow_ma_period,MA_Slow_ma_shift,
                       MA_Slow_ma_method,MA_Slow_applied_price);
//--- if the handle is not created 
   if(handle_iMA_Slow==INVALID_HANDLE)
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
   IsDeals(m_day_of_last_trade);                // only one deal in day
   m_start_time_in_sec=InpStartHour*3600+InpStartMin*60;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   if(!InpLotsManual)
      if(m_money!=NULL)
         delete m_money;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   Trailing();
//---
   long sec_current=TimeCurrent()%86400;
   if(sec_current<=m_start_time_in_sec)
      return;
//---
   MqlDateTime STimeCurrent;
   TimeToStruct(TimeCurrent(),STimeCurrent);
   if(m_day_of_last_trade==STimeCurrent.day_of_year)
      return;
//---
   double Price_Lowest  = iLowest(m_symbol.Name(),Period(),MODE_LOW,InpInterval,InpShift);
   double Price_Highest = iHighest(m_symbol.Name(),Period(),MODE_HIGH,InpInterval,InpShift);
   if(Price_Lowest==0.0 || Price_Highest==0.0)
      return;
   double MA_Fast=iMAGet(handle_iMA_Fast,1);
   double MA_Slow=iMAGet(handle_iMA_Slow,1);
   if(MA_Fast==0.0 || MA_Slow==0.0)
      return;
   if(!RefreshRates())
      return;
//--- check open BUY
   if(Price_Highest<MA_Slow)
      if(Price_Lowest<MA_Fast)
        {
         double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
         double tp=(InpTakeProfit==0)?0.0:m_symbol.Ask()+ExtTakeProfit;
         OpenBuy(sl,tp);
         return;
        }
//--- check open SELL
   if(Price_Lowest>MA_Slow)
      if(Price_Highest>MA_Fast)
        {
         double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
         double tp=(InpTakeProfit==0)?0.0:m_symbol.Bid()-ExtTakeProfit;
         OpenSell(sl,tp);
         return;
        }

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
         if((ENUM_DEAL_ENTRY)deal_entry==DEAL_ENTRY_IN)
            if((ENUM_DEAL_TYPE)deal_type==DEAL_TYPE_BUY && (ENUM_DEAL_TYPE)deal_type==DEAL_TYPE_SELL)
              {
               MqlDateTime SDealTime;
               TimeToStruct(deal_time,SDealTime);
               m_day_of_last_trade=SDealTime.day_of_year;
               return;
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
//| Search for deals in a given period                               |
//+------------------------------------------------------------------+
void IsDeals(int &day_of_last_trade)
  {
   datetime from_date=TimeCurrent();
   MqlDateTime SFromDate;
   TimeToStruct(from_date,SFromDate);
   SFromDate.hour=0;
   SFromDate.min=0;
   SFromDate.sec=0;
   from_date=StructToTime(SFromDate);
//--- request trade history 
   HistorySelect(from_date,from_date+24*60*60);
//---
   uint     total=HistoryDealsTotal();
   ulong    ticket=0;
   long     position_id=0;
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

         double deal_commission  =HistoryDealGetDouble(ticket,DEAL_COMMISSION);
         double deal_swap        =HistoryDealGetDouble(ticket,DEAL_SWAP);
         double deal_profit      =HistoryDealGetDouble(ticket,DEAL_PROFIT);

         string deal_symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         //--- only for current symbol and magic
         if(deal_symbol==m_symbol.Name() && deal_magic==m_magic)
            if((ENUM_DEAL_ENTRY)deal_entry==DEAL_ENTRY_IN)
               if((ENUM_DEAL_TYPE)deal_type==DEAL_TYPE_BUY && (ENUM_DEAL_TYPE)deal_type==DEAL_TYPE_SELL)
                 {
                  TimeToStruct(deal_time,SFromDate);
                  day_of_last_trade=SFromDate.day_of_year;
                  return;
                 }
        }
     }
//---
   return;
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
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
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
                    }
              }

           }
  }
//+------------------------------------------------------------------+
//| Return lowest price                                              |
//+------------------------------------------------------------------+
double iLowest(string symbol,
               ENUM_TIMEFRAMES timeframe,
               int type,
               int count=WHOLE_ARRAY,
               int start=0)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   if(start<0)
      return(0.0);
   if(count<=0)
      count=Bars(symbol,timeframe);
   if(type==MODE_LOW)
     {
      double Low[];
      if(CopyLow(symbol,timeframe,start,count,Low)!=count)
         return(0.0);
      int index_min=ArrayMinimum(Low);
      return(Low[index_min]);
     }
//---
   return(0.0);
  }
//+------------------------------------------------------------------+
//| Return highest price                                             |
//+------------------------------------------------------------------+
double iHighest(string symbol,
                ENUM_TIMEFRAMES timeframe,
                int type,
                int count=WHOLE_ARRAY,
                int start=0)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   if(start<0)
      return(0.0);
   if(count<=0)
      count=Bars(symbol,timeframe);
   if(type==MODE_HIGH)
     {
      double High[];
      if(CopyHigh(symbol,timeframe,start,count,High)!=count)
         return(0.0);
      int index_max=ArrayMaximum(High);
      return(High[index_max]);
     }
//---
   return(0.0);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(const int handle_iMA,const int index)
  {
   double MA[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iMA,0,index,1,MA)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(MA[0]);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double check_open_long_lot=0.0;
   if(!InpLotsManual)
     {
      check_open_long_lot=m_money.CheckOpenLong(m_symbol.Ask(),sl);
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
     }
   else
      check_open_long_lot=InpLots;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_long_lot,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=check_open_long_lot)
        {
         if(m_trade.Buy(check_open_long_lot,NULL,m_symbol.Ask(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
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

   double check_open_short_lot=0.0;
   if(!InpLotsManual)
     {
      check_open_short_lot=m_money.CheckOpenShort(m_symbol.Bid(),sl);
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
     }
   else
      check_open_short_lot=InpLots;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_short_lot,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=check_open_short_lot)
        {
         if(m_trade.Sell(check_open_short_lot,NULL,m_symbol.Bid(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
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
   DebugBreak();
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                             Bands 2(barabashkakvn's edition).mq5 |
//|                                              Copyright, tageiger |
//|                                       https://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Copyright, tageiger"
#property link      "https://www.metaquotes.net"
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\OrderInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
COrderInfo     m_order;                      // pending orders object
//+------------------------------------------------------------------+
//| Enum type stop loss                                              |
//+------------------------------------------------------------------+
enum ENUM_TYPE_STOP_LOSS
  {
   sl_ma =           0,     // StopLoss Moving Average
   sl_bands =        1,     // StopLoss Bollinger Bands
   sl_NONE =         2,     // StopLoss NONE
  };
//--- input parameters
input double               InpLots              = 0.1;         // Lots
input uchar                HourStart            = 4;           // Hour start 
input uchar                HourEnd              = 18;          // Hour end
input ENUM_TYPE_STOP_LOSS  SL_MA_or_Bands       = sl_ma;       // Stop loss type
input ushort               FirstTP              = 21;          // First Take Profit (in pips)
input ushort               SecondTP             = 34;          // Second Take Profit (in pips)
input ushort               ThirdTP              = 55;          // Third Take Profit (in pips)
input ushort               InpTrailingStop      = 15;          // Trailing Stop (in pips)
input ushort               InpTrailingStep      = 5;           // Trailing Step (in pips)
input ushort               Step                 = 15;          // Step between pending orders (in pips)
//---
input int                  MA_ma_period         = 15;          // Moving Average: averaging period 
input int                  MA_ma_shift          = 3;           // Moving Average: horizontal shift 
input ENUM_MA_METHOD       MA_ma_method         = MODE_EMA;    // Moving Average: smoothing type 
input ENUM_APPLIED_PRICE   MA_applied_price     = PRICE_CLOSE; // Moving Average: type of price 
//---
input int                  Bands_bands_period   = 15;          // Bands: period for average line calculation 
input int                  Bands_bands_shift    = 0;           // Bands: horizontal shift of the indicator 
input double               Bands_deviation      = 2.0;         // Bands: number of standard deviations 
input ENUM_APPLIED_PRICE   Bands_applied_price  = PRICE_CLOSE; // Bands: type of price 
//---
input ulong                m_magic=7900444;     // magic number
//---
ulong          m_slippage=10;                // slippage

double         ExtFirstTP=0.0;
double         ExtSecondTP=0.0;
double         ExtThirdTP=0.0;
double         ExtTrailingStop=0.0;
double         ExtTrailingStep=0.0;
double         ExtStep=0.0;

int            handle_iMA;                   // variable for storing the handle of the iMA indicator 
int            handle_iBands;                // variable for storing the handle of the iBands indicator 

double         m_adjusted_point;             // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(HourStart>=HourEnd)
     {
      Alert(__FUNCTION__," ERROR: \"Hour start\" (",HourStart,") >= \"Hour end\" (",HourEnd,")");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpTrailingStop!=0 && InpTrailingStep==0)
     {
      Alert(__FUNCTION__," ERROR: Trailing is not possible: the parameter \"Trailing Step\" is zero!");
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();

   string err_text="";
   if(!CheckVolumeValue(InpLots,err_text))
     {
      Print(__FUNCTION__,", ERROR: ",err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
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

   ExtFirstTP     = FirstTP         * m_adjusted_point;
   ExtSecondTP    = SecondTP        * m_adjusted_point;
   ExtThirdTP     = ThirdTP         * m_adjusted_point;
   ExtTrailingStop= InpTrailingStop * m_adjusted_point;
   ExtTrailingStep= InpTrailingStep * m_adjusted_point;
   ExtStep        = Step            * m_adjusted_point;
//--- create handle of the indicator iMA
   handle_iMA=iMA(m_symbol.Name(),Period(),MA_ma_period,MA_ma_shift,MA_ma_method,MA_applied_price);
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
//--- create handle of the indicator iBands
   handle_iBands=iBands(m_symbol.Name(),Period(),Bands_bands_period,Bands_bands_shift,Bands_deviation,Bands_applied_price);
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

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   Trailing();
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   DeleteAllPendingOrders();
//---
   if(!RefreshRates())
     {
      PrevBars=iTime(1);
      return;
     }
//---
   MqlDateTime STimeBarsCurrent;
   TimeToStruct(PrevBars,STimeBarsCurrent);
//---
   double ma=iMAGet(0);
   double bands_upper=iBandsGet(UPPER_BAND,0);
   double bands_lower=iBandsGet(LOWER_BAND,0);
   double close=iClose(0);
//---
   if(CalculateAllPendingOrders()==0)
      if(STimeBarsCurrent.hour>=HourStart && STimeBarsCurrent.hour<HourEnd)
         if(bands_upper>close && close>bands_lower)
           {
            STimeBarsCurrent.hour=HourEnd;
            STimeBarsCurrent.min=0;
            STimeBarsCurrent.sec=0;
            datetime expiration=StructToTime(STimeBarsCurrent);
            for(int i=0;i<3;i++)
              {
               double price_buy_stop=bands_upper+i*ExtStep;
               double tp_buy_stop=0.0;

               double price_sell_stop=bands_lower-i*ExtStep;
               double tp_sell_stop=0.0;

               double sl_buy_stop   = 0.0;
               double sl_sell_stop  = 0.0;
               switch(SL_MA_or_Bands)
                 {
                  case  sl_ma:
                     sl_buy_stop = bands_lower+i*ExtStep;
                     sl_sell_stop= bands_upper-i*ExtStep;
                     break;
                  case  sl_bands:
                     sl_buy_stop = ma+i*ExtStep;
                     sl_sell_stop= ma-i*ExtStep;
                     break;
                  case  sl_NONE:
                     sl_buy_stop = 0.0;
                     sl_sell_stop= 0.0;
                     break;
                 }
               //---
               switch(i)
                 {
                  case  0:
                     tp_buy_stop=(FirstTP==0)?0.0:price_buy_stop+ExtFirstTP;
                     tp_sell_stop=(FirstTP==0)?0.0:price_sell_stop-ExtFirstTP;
                     break;
                  case  1:
                     tp_buy_stop=(SecondTP==0)?0.0:price_buy_stop+ExtSecondTP;
                     tp_sell_stop=(SecondTP==0)?0.0:price_sell_stop-ExtFirstTP;
                     break;
                  case  2:
                     tp_buy_stop=(ThirdTP==0)?0.0:price_buy_stop+ExtThirdTP;
                     tp_sell_stop=(ThirdTP==0)?0.0:price_sell_stop-ExtFirstTP;
                     break;
                 }
               m_trade.BuyStop(InpLots,m_symbol.NormalizePrice(price_buy_stop),m_symbol.Name(),
                               m_symbol.NormalizePrice(sl_buy_stop),
                               m_symbol.NormalizePrice(tp_buy_stop),ORDER_TIME_SPECIFIED,expiration);
               m_trade.SellStop(InpLots,m_symbol.NormalizePrice(price_sell_stop),m_symbol.Name(),
                                m_symbol.NormalizePrice(sl_sell_stop),
                                m_symbol.NormalizePrice(tp_sell_stop),ORDER_TIME_SPECIFIED,expiration);
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
         if(deal_entry==DEAL_ENTRY_IN)
            if(deal_type==DEAL_TYPE_BUY || deal_type==DEAL_TYPE_SELL)
               DeleteAllPendingOrders();
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
//| Check the correctness of the position volume                     |
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
   datetime time=0; // datetime "0" -> D'1970.01.01 00:00:00'
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0)
      time=Time[0];
   return(time);
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
//| Calculate all pending orders                                     |
//+------------------------------------------------------------------+
int CalculateAllPendingOrders(void)
  {
   int total=0;

   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i))     // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
            total++;
//---
   return(total);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(const int index)
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
//| Get value of buffers for the iBands                              |
//|  the buffer numbers are the following:                           |
//|   0 - BASE_LINE, 1 - UPPER_BAND, 2 - LOWER_BAND                  |
//+------------------------------------------------------------------+
double iBandsGet(const int buffer,const int index)
  {
   double Bands[1];
//ArraySetAsSeries(Bands,true);
//--- reset error code 
   ResetLastError();
//--- fill a part of the iBands array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iBands,buffer,index,1,Bands)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iBands indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Bands[0]);
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

//+------------------------------------------------------------------+
//|                             Freeman(barabashkakvn's edition).mq5 |
//|                           Copyright 2011 http://all-webmoney.com |
//|                                          http://all-webmoney.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2011 http://all-webmoney.com"
#property link      "http://all-webmoney.com"
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
//--- input parameters
input double   InpLots           = 0.01;        // Lots
input uchar    InpSLFactor       = 14;          // SL Factor: Stop Loss = SL Factor * ATR
input uchar    InpTPFactor       = 2;           // TP Factor: Take Profit = TP Factor * ATR
input ushort   InpTrailingStop   = 5;           // Trailing Stop (in pips)
input ushort   InpTrailingStep   = 5;           // Trailing Step (in pips)
input int      InpPositionsMax   = 5;           // Positions Maximum
input ushort   InpDistance       = 10;          // Distance between positions (in pips)
input bool     InpBarsControl    = true;        // Bars Control: "false" - trade on every tick
input double   InpCoefficient    = 1.61;        // Coefficient for position locking
//---
input bool     InpRsiTeacher     = true;        // Use Rsi Teacher #1
input bool     InpRsiTeacher2    = true;        // Use Rsi Teacher #2
//---
input int      Inp_MA_First_ma_period  = 5;     // MA First, ATR: averaging period
input int      Inp_MA_Second_ma_period = 9;     // MA Second: averaging period
input int      Inp_MA_Filter_ma_period = 20;    // MA Filter: averaging period
input ENUM_MA_METHOD Inp_ma_method=MODE_SMA; // MA First, MA Second, MA Filter: smoothing type 
input ENUM_APPLIED_PRICE Inp_applied_price=PRICE_CLOSE; // MA First, MA Second, MA Filter: type of price 
//---
input int      Inp_RSI_First_ma_period = 15;    // RSI First: averaging period   
input int      Inp_RSI_Second_ma_period= 20;    // RSI Second: averaging period   
//---
input int      RSISellLevel      = 34;          // RSI Sell Level #1
input int      RSIBuyLevel       = 70;          // RSI Buy Level #1
input int      RSISellLevel2     = 34;          // RSI Sell Level 2
input int      RSIBuyLevel2      = 68;          // RSI Buy Level 2
input int      Shift             = 0;           // Signal Bar number
input bool     TrendFilter       = false;       // Trend filter
//---
input bool     InpTradeOnFriday  = true;        // Trade on Friday
input int      InpBeginTradeHour = 0;           // Begin trade hour
input int      InpEndTradeHour   = 0;           // End trade hour
input ulong    m_magic           = 368265384;   // magic number
//---
ulong          m_slippage=10;                   // slippage

double         ExtTrailingStop=0.0;
double         ExtTrailingStep=0.0;
double         ExtDistance=0.0;

int            handle_iMA_First;                // variable for storing the handle of the iMA indicator
int            handle_iMA_Second;               // variable for storing the handle of the iMA indicator
int            handle_iMA_Filter;               // variable for storing the handle of the iMA indicator
int            handle_iATR;                     // variable for storing the handle of the iATR indicator 
int            handle_iRSI_First;               // variable for storing the handle of the iRSI indicator
int            handle_iRSI_Second;              // variable for storing the handle of the iRSI indicator
int            handle_iRSI_H1_14;               // variable for storing the handle of the iRSI indicator

double         m_adjusted_point;                // point value adjusted for 3 or 5 points

bool           m_last_OUT_buy_loss  = false;
double         m_last_IN_buy_price  = 0.0;
bool           m_last_OUT_sell_loss = false;
double         m_last_IN_sell_price = 0.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(InpTrailingStop!=0 && InpTrailingStep==0)
     {
      string text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                  "Трейлинг невозможен: параметр \"Trailing Step\" равен нулю!":
                  "Trailing is not possible: parameter \"Trailing Step\" is zero!";
      Alert(__FUNCTION__," ERROR! ",text);
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
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtTrailingStop= InpTrailingStop * m_adjusted_point;
   ExtTrailingStep= InpTrailingStep * m_adjusted_point;
   ExtDistance    = InpDistance     * m_adjusted_point;
//--- create handle of the indicator iMA
   handle_iMA_First=iMA(m_symbol.Name(),Period(),Inp_MA_First_ma_period,0,Inp_ma_method,Inp_applied_price);
//--- if the handle is not created 
   if(handle_iMA_First==INVALID_HANDLE)
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
   handle_iMA_Second=iMA(m_symbol.Name(),Period(),Inp_MA_Second_ma_period,0,Inp_ma_method,Inp_applied_price);
//--- if the handle is not created 
   if(handle_iMA_Second==INVALID_HANDLE)
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
   handle_iMA_Filter=iMA(m_symbol.Name(),PERIOD_H1,Inp_MA_Filter_ma_period,0,Inp_ma_method,Inp_applied_price);
//--- if the handle is not created 
   if(handle_iMA_Filter==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iATR
   handle_iATR=iATR(m_symbol.Name(),Period(),Inp_MA_First_ma_period);
//--- if the handle is not created 
   if(handle_iATR==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iATR indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iRSI
   handle_iRSI_First=iRSI(m_symbol.Name(),Period(),Inp_RSI_First_ma_period,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iRSI_First==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iRSI
   handle_iRSI_Second=iRSI(m_symbol.Name(),Period(),Inp_RSI_Second_ma_period,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iRSI_Second==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iRSI
   handle_iRSI_H1_14=iRSI(m_symbol.Name(),PERIOD_H1,14,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iRSI_H1_14==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
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
//---
   bool   tradeAllow=false;

   static datetime PrevBars=0;
   if(InpBarsControl)
     {
      //--- we work only at the time of the birth of new bar
      datetime time_0=iTime(m_symbol.Name(),Period(),0);
      if(time_0==PrevBars)
         return;
      PrevBars=time_0;
     }
   if(!InpTradeOnFriday)
     {
      MqlDateTime STimeCurrent;
      TimeToStruct(TimeCurrent(),STimeCurrent);
      if(STimeCurrent.day_of_week==5)
         return;
     }
   if(InpBeginTradeHour>0 && InpEndTradeHour>0)
     {
      MqlDateTime STimeCurrent;
      TimeToStruct(TimeCurrent(),STimeCurrent);
      if(STimeCurrent.hour>=InpBeginTradeHour && STimeCurrent.hour<=InpEndTradeHour)
         tradeAllow=true;
     }
   else
     {
      tradeAllow=true;
     }
//---
   int count_buys=0;
   int count_sells=0;
   CalculateAllPositions(count_buys,count_sells);
   bool SignalBuy=false;
   bool SignalSell=false;
   Signals(SignalBuy,SignalSell);
//---
   if(count_buys+count_sells<InpPositionsMax || (InpPositionsMax==0 && tradeAllow))
     {
      double atr_array[];
      if(!iATRGetArray(Shift,1,atr_array))
         return;
      //--- buy signal
      if(count_buys==0)
        {
         if(SignalBuy)
           {
            if(!RefreshRates())
               return;
            double sl=(InpSLFactor==0)?0.0:m_symbol.Ask()-atr_array[0]*(double)InpSLFactor;
            if(sl>=m_symbol.Bid()) // incident: the position isn't opened yet, and has to be already closed
              {
               if(InpBarsControl)
                  PrevBars=0;
               return;
              }
            double tp=(InpTPFactor==0)?0.0:m_symbol.Ask()+atr_array[0]*(double)InpTPFactor;
            OpenBuy(InpLots,sl,tp);
            return;
           }
        }
      else
        {
         if(!RefreshRates())
            return;
         if(SignalBuy && MathAbs(m_symbol.Ask()-m_last_IN_buy_price)>ExtDistance)
           {
            if(m_last_OUT_buy_loss) // Lock
              {
               double lot_lock=LotCheck(InpLots*InpCoefficient);
               if(lot_lock==0.0)
                 {
                  Print("Calcalate lot for lock BUY: ERROR, \"LotCheck\" get 0.0");
                  return;
                 }
               double sl=(InpSLFactor==0)?0.0:m_symbol.Ask()-atr_array[0]*(double)InpSLFactor;
               if(sl>=m_symbol.Bid()) // incident: the position isn't opened yet, and has to be already closed
                 {
                  if(InpBarsControl)
                     PrevBars=0;
                  return;
                 }
               double tp=(InpTPFactor==0)?0.0:m_symbol.Ask()+atr_array[0]*(double)InpTPFactor;
               OpenBuy(lot_lock,sl,tp);
               return;
              }
            else
              {
               double sl=(InpSLFactor==0)?0.0:m_symbol.Ask()-atr_array[0]*(double)InpSLFactor;
               if(sl>=m_symbol.Bid()) // incident: the position isn't opened yet, and has to be already closed
                 {
                  if(InpBarsControl)
                     PrevBars=0;
                  return;
                 }
               double tp=(InpTPFactor==0)?0.0:m_symbol.Ask()+atr_array[0]*(double)InpTPFactor;
               OpenBuy(InpLots,sl,tp);
               return;
              }
           }
        }
      //--- sell signal
      if(count_sells==0)
        {
         if(SignalSell)
           {
            if(!RefreshRates())
               return;
            double sl=(InpSLFactor==0)?0.0:m_symbol.Bid()+atr_array[0]*(double)InpSLFactor;
            if(sl<=m_symbol.Ask()) // incident: the position isn't opened yet, and has to be already closed
              {
               if(InpBarsControl)
                  PrevBars=0;
               return;
              }
            double tp=(InpTPFactor==0)?0.0:m_symbol.Bid()-atr_array[0]*(double)InpSLFactor;
            OpenSell(InpLots,sl,tp);
            return;
           }
        }
      else
        {
         if(!RefreshRates())
            return;
         if(SignalSell && MathAbs(m_symbol.Bid()-m_last_IN_sell_price)>ExtDistance)
           {
            if(m_last_OUT_sell_loss) // Lock
              {
               double lot_lock=LotCheck(InpLots*InpCoefficient);
               if(lot_lock==0.0)
                 {
                  Print("Calcalate lot for lock SELL: ERROR, \"LotCheck\" get 0.0");
                  return;
                 }
               double sl=(InpSLFactor==0)?0.0:m_symbol.Bid()+atr_array[0]*(double)InpSLFactor;
               if(sl<=m_symbol.Ask()) // incident: the position isn't opened yet, and has to be already closed
                 {
                  if(InpBarsControl)
                     PrevBars=0;
                  return;
                 }
               double tp=(InpTPFactor==0)?0.0:m_symbol.Bid()-atr_array[0]*(double)InpSLFactor;
               OpenSell(lot_lock,sl,tp);
               return;
              }
            else
              {
               double sl=(InpSLFactor==0)?0.0:m_symbol.Bid()+atr_array[0]*(double)InpSLFactor;
               if(sl<=m_symbol.Ask()) // incident: the position isn't opened yet, and has to be already closed
                 {
                  if(InpBarsControl)
                     PrevBars=0;
                  return;
                 }
               double tp=(InpTPFactor==0)?0.0:m_symbol.Bid()-atr_array[0]*(double)InpSLFactor;
               OpenSell(InpLots,sl,tp);
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
        {
         if(deal_entry==DEAL_ENTRY_OUT)
           {
            if(deal_type==DEAL_TYPE_BUY)
              {
               if(deal_profit<0.0)
                 {
                  m_last_OUT_buy_loss=false;
                  m_last_OUT_sell_loss=true;
                 }
               else
                  m_last_OUT_sell_loss=false;
              }
            if(deal_type==DEAL_TYPE_SELL)
              {
               if(deal_profit<0.0)
                 {
                  m_last_OUT_buy_loss=true;
                  m_last_OUT_sell_loss=false;
                 }
               else
                  m_last_OUT_buy_loss=false;
              }
           }
         if(deal_entry==DEAL_ENTRY_IN)
           {
            if(deal_type==DEAL_TYPE_BUY)
               m_last_IN_buy_price=deal_price;
            if(deal_type==DEAL_TYPE_SELL)
               m_last_IN_sell_price=deal_price;
           }
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
//|                                                                  |
//+------------------------------------------------------------------+
void Signals(bool &SignalBuy,bool &SignalSell)
  {
   SignalBuy=false;
   SignalSell=false;

   double MA_First[];
   if(!iMAGetArray(handle_iMA_First,0,Shift+2,MA_First))
      return;
//double RSIMAnow_     = iMA(NULL,0, Inp_MA_First_ma_period, 0, Inp_ma_method, Inp_applied_price, Shift);
//double RSIMApre_     = iMA(NULL,0, Inp_MA_First_ma_period, 0, Inp_ma_method, Inp_applied_price, Shift+1);
   double MA_Second[];
   if(!iMAGetArray(handle_iMA_Second,0,Shift+2,MA_Second))
      return;
//double RSIMAnow2_    = iMA(NULL,0,Inp_MA_Second_ma_period,0,Inp_ma_method,Inp_applied_price,Shift);
//double RSIMApre2_    = iMA(NULL,0,Inp_MA_Second_ma_period,0,Inp_ma_method,Inp_applied_price,Shift+1);
   double MA_Filter[];
   if(!iMAGetArray(handle_iMA_Filter,0,Shift+2,MA_Filter))
      return;
//double MAFilterNow_  = iMA(NULL,PERIOD_H1,Inp_MA_Filter_ma_period,0,Inp_ma_method,Inp_applied_price,Shift);
//double MAFilterPrev_ = iMA(NULL,PERIOD_H1,Inp_MA_Filter_ma_period,0,Inp_ma_method,Inp_applied_price,Shift+1);
   double RSI_First[];
   if(!iRSIGetArray(handle_iRSI_First,0,Shift+2,RSI_First))
      return;
//double RSInow_       = iRSI(NULL,0,Inp_RSI_First_ma_period,PRICE_CLOSE,Shift);
//double RSIprev_      = iRSI(NULL,0,Inp_RSI_First_ma_period,PRICE_CLOSE,Shift+1);
   double RSI_Second[];
   if(!iRSIGetArray(handle_iRSI_Second,0,Shift+2,RSI_Second))
      return;
//double RSInow2_      = iRSI(NULL,0,Inp_RSI_Second_ma_period,PRICE_CLOSE,Shift);
//double RSIprev2_     = iRSI(NULL,0,Inp_RSI_Second_ma_period,PRICE_CLOSE,Shift+1);
   double RSI_H1_14[];
   if(!iRSIGetArray(handle_iRSI_H1_14,0,Shift+1,RSI_H1_14))
      return;
//double RSInowH1_     = iRSI(NULL,PERIOD_H1,14,PRICE_CLOSE,Shift);

//--- Buy signal
   if(((MA_Filter[Shift]>MA_Filter[Shift+1] && TrendFilter) || (!TrendFilter)) && 
      (InpRsiTeacher2 && (RSI_Second[Shift+1]<RSISellLevel2) && (RSI_Second[Shift]>RSI_Second[Shift+1]) && (RSI_H1_14[Shift]<RSIBuyLevel2) && (MA_Second[Shift]>MA_Second[Shift+1])) || 
      (InpRsiTeacher && (RSI_First[Shift+1]<RSISellLevel) && (RSI_First[Shift]>RSI_First[Shift+1]) && (RSI_H1_14[Shift]<RSIBuyLevel) && (MA_First[Shift]>MA_First[Shift+1])))
     {
      SignalBuy=true;
     }
//--- Sell signal                
   if(((MA_Filter[Shift]<MA_Filter[Shift+1] && TrendFilter) || (!TrendFilter)) && 
      (InpRsiTeacher2 && (RSI_Second[Shift+1]>RSIBuyLevel2) && (RSI_Second[Shift]<RSI_Second[Shift+1]) && (RSI_H1_14[Shift]>RSISellLevel2) && (MA_Second[Shift]<MA_Second[Shift+1])) || 
      (InpRsiTeacher && (RSI_First[Shift+1]>RSIBuyLevel) && (RSI_First[Shift]<RSI_First[Shift+1]) && (RSI_H1_14[Shift]>RSISellLevel) && (MA_First[Shift]<MA_First[Shift+1])))
     {
      SignalSell=true;
     }
  }
//+------------------------------------------------------------------+
//| Calculate all positions Buy and Sell                             |
//+------------------------------------------------------------------+
void CalculateAllPositions(int &count_buys,int &count_sells)
  {
   count_buys=0;
   count_sells=0;

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
//| Get value of buffers for the iMA in the array                    |
//+------------------------------------------------------------------+
bool iMAGetArray(const int handle_iMA,const int start_pos,const int count,double &arr_buffer[])
  {
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
   int copied=CopyBuffer(handle_iMA,buffer_num,start_pos,count,arr_buffer);
   if(copied!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iATR in the array                   |
//+------------------------------------------------------------------+
bool iATRGetArray(const int start_pos,const int count,double &arr_buffer[])
  {
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
//--- fill a part of the iATRBuffer array with values from the indicator buffer that has 0 index 
   int copied=CopyBuffer(handle_iATR,buffer_num,start_pos,count,arr_buffer);
   if(copied!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iATR indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iRSI in the array                   |
//+------------------------------------------------------------------+
bool iRSIGetArray(const int handle_iRSI,const int start_pos,const int count,double &arr_buffer[])
  {
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
//--- fill a part of the iRSIBuffer array with values from the indicator buffer
   int copied=CopyBuffer(handle_iRSI,buffer_num,start_pos,count,arr_buffer);
   if(copied!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iRSI indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double lot,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=lot)
        {
         if(m_trade.Buy(lot,m_symbol.Name(),m_symbol.Ask(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print(__FUNCTION__,", #1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
            else
              {
               Print(__FUNCTION__,", #2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< Lots (",DoubleToString(lot,2),")");
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
void OpenSell(double lot,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=lot)
        {
         if(m_trade.Sell(lot,m_symbol.Name(),m_symbol.Bid(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print(__FUNCTION__,", #1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
            else
              {
               Print(__FUNCTION__,", #2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< Lots (",DoubleToString(lot,2),")");
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

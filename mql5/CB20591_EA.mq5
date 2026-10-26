//+------------------------------------------------------------------+
//|                                                      BSS 1_0.mq5 |
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
input double               InpLots                    = 0.1;            // Lots
input uchar                InpMaxPosition             = 2;              // Maximum quantity of positions
input uint                 InpMinimumDistance         = 5;              // Minimum distance between MA's  (in pips)
input ushort               InpMinimumPause            = 600;            // Minimum pause between trades (in seconds)
input int                  InpMA_First_ma_period      = 5;              // MA First: averaging period 
input int                  InpMA_First_ma_shift       = 0;              // MA First: horizontal shift 
input ENUM_MA_METHOD       InpMA_First_ma_method      = MODE_EMA;       // MA First: smoothing type 
input ENUM_APPLIED_PRICE   InpMA_First_applied_price  = PRICE_CLOSE;    // MA First: type of price 

input int                  InpMA_Second_ma_period     = 25;             // MA Second: averaging period 
input int                  InpMA_Second_ma_shift      = 0;              // MA Second: horizontal shift 
input ENUM_MA_METHOD       InpMA_Second_ma_method     = MODE_EMA;       // MA Second: smoothing type 
input ENUM_APPLIED_PRICE   InpMA_Second_applied_price = PRICE_CLOSE;    // MA Second: type of price 

input int                  InpMA_Third_ma_period      = 125;            // MA Third: averaging period 
input int                  InpMA_Third_ma_shift       = 0;              // MA Third: horizontal shift 
input ENUM_MA_METHOD       InpMA_Third_ma_method      = MODE_EMA;       // MA Third: smoothing type 
input ENUM_APPLIED_PRICE   InpMA_Third_applied_price  = PRICE_CLOSE;    // MA Third: type of price 
input ulong                m_magic=282317256;                           // magic number
//---
ulong          m_slippage=10;                // slippage
double         ExtMinimumDistance=0.0;

int            handle_iMA_First;             // variable for storing the handle of the iMA indicator
int            handle_iMA_Second;            // variable for storing the handle of the iMA indicator
int            handle_iMA_Third;             // variable for storing the handle of the iMA indicator

double         m_adjusted_point;             // point value adjusted for 3 or 5 points

long           m_last_trade_IN=0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(InpMaxPosition<1)
     {
      Alert(__FUNCTION__," ERROR: You have forbidden trade: the parameter \"Maximum quantity of positions\" can't be less than one!");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpMA_First_ma_period>=InpMA_Second_ma_period)
     {
      Alert(__FUNCTION__," ERROR: \"MA First: averaging period\" can't be more or equally \"MA Second: averaging period\"!");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpMA_Second_ma_period>=InpMA_Third_ma_period)
     {
      Alert(__FUNCTION__," ERROR: \"MA Second: averaging period\" can't be more or equally \"MA Third: averaging period\"!");
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

   ExtMinimumDistance=InpMinimumDistance*m_adjusted_point;
//--- create handle of the indicator iMA
   handle_iMA_First=iMA(m_symbol.Name(),Period(),InpMA_First_ma_period,InpMA_First_ma_shift,
                        InpMA_First_ma_method,InpMA_First_applied_price);
//--- if the handle is not created 
   if(handle_iMA_First==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator (\"First\") for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_Second=iMA(m_symbol.Name(),Period(),InpMA_Second_ma_period,InpMA_Second_ma_shift,
                         InpMA_Second_ma_method,InpMA_Second_applied_price);
//--- if the handle is not created 
   if(handle_iMA_Second==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator (\"Second\") for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA_Third=iMA(m_symbol.Name(),Period(),InpMA_Third_ma_period,InpMA_Third_ma_shift,
                        InpMA_Third_ma_method,InpMA_Third_applied_price);
//--- if the handle is not created 
   if(handle_iMA_Third==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator (\"Third\") for the symbol %s/%s, error code %d",
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
   int total_positions=CalculateAllPositions();
//---
   double MA_First   = iMAGet(handle_iMA_First,0);
   double MA_Second  = iMAGet(handle_iMA_Second,0);
   double MA_Third   = iMAGet(handle_iMA_Third,0);
//--- buy
   if(MA_Third-MA_Second>=ExtMinimumDistance && MA_Second-MA_First>=ExtMinimumDistance)
     {
      long time_current=(long)TimeCurrent();
      if(total_positions<InpMaxPosition && time_current-m_last_trade_IN>=InpMinimumPause)
         m_trade.Buy(InpLots);
      ClosePositions(POSITION_TYPE_SELL);
      return;
     }
//--- sell
   if(MA_First-MA_Second>=ExtMinimumDistance && MA_Second-MA_Third>=ExtMinimumDistance)
     {
      long time_current=(long)TimeCurrent();
      if(total_positions<InpMaxPosition && time_current-m_last_trade_IN>=InpMinimumPause)
         m_trade.Sell(InpLots);
      ClosePositions(POSITION_TYPE_BUY);
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
      if(deal_reason!=-1)
         int d=0;
      if(deal_symbol==m_symbol.Name() && deal_magic==m_magic)
         if(deal_entry==DEAL_ENTRY_IN)
            if(deal_type==DEAL_TYPE_BUY || deal_type==DEAL_TYPE_SELL)
               m_last_trade_IN=deal_time;
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

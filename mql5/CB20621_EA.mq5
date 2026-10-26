//+------------------------------------------------------------------+
//|                  UniversalMACrossEA(barabashkakvn's edition).mq5 |
//|                                       Copyright © 2006, firedave | 
//|                    Partial Function Copyright © 2006, codersguru | 
//|                        Partial Function Copyright © 2006, pengie |
//|                                        http://www.fx-review.com/ | 
//|                                        http://www.forex-tsd.com/ | 
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, firedave"
#property link      "http://www.fx-review.com"
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
CDealInfo      m_deal;                       // deals object
COrderInfo     m_order;                      // pending orders object
CMoneyFixedMargin *m_money;
//--- input parameters
input ushort               InpStopLoss          = 100;         // Stop Loss (in pips)   
input ushort               InpTakeProfit        = 200;         // Take Profit (in pips)                    
input ushort               InpTrailingStop      = 40;          // Trailing Stop (in pips)
input ushort               InpTrailingStep      = 5;           // Trailing Step (in pips)
input string               Indicator_Setting    = "---------- Indicator Setting";
input int                  FastMAPeriod         = 10;          // MA Fast: averaging period
input ENUM_MA_METHOD       FastMAType           = MODE_EMA;    // MA Fast: smoothing type 
input ENUM_APPLIED_PRICE   FastMAPrice          = PRICE_CLOSE; // MA Fast: type of price
input int                  SlowMAPeriod         = 80;          // MA Slow: averaging period
input ENUM_MA_METHOD       SlowMAType           = MODE_EMA;    // MA Slow: smoothing type 
input ENUM_APPLIED_PRICE   SlowMAPrice          = PRICE_CLOSE; // MA Slow: type of price
input ushort               InpMinCrossDistance  = 0;           // MA Fast and Slow: Minimum Cross Distance ("0" -> disable)
input string               Exit_Setting         = "---------- Exit Setting";
input bool                 ReverseCondition     = false;       // Reverse Condition (true: buy-sell, false: sell-buy)
input bool                 ConfirmedOnEntry     = true;        // Confirmed On Entry (true: entry on the next signal bar)
input bool                 OneEntryPerBar       = true;        // One Entry Per Bar
input bool                 StopAndReverse       = true;        // Stop And Reverse (true: if signal change, exit and reverse position)
input bool                 PureSAR              = false;       // PureSAR (true: no SL, no TP, no TS)
input string               Time_Parameters      = "---------- EA Active Time";
input bool                 UseHourTrade         = false;       // Use Hour Trade
input int                  StartHour            = 10;          // Start Hour
input int                  EndHour              = 11;          // End Hour
input string               MM_Parameters        = "---------- Money Management";
input double               InpLots              = 0;           // Lots (or "Lots">0 and "Risk"==0 or "Lots"==0 and "Risk">0)
input double               Risk                 = 5;           // Risk (or "Lots">0 and "Risk"==0 or "Lots"==0 and "Risk">0)
input string               Testing_Parameters="---------- Back Test Parameter";
input bool                 PrintControl         = true;        // Print on tab "Experts"
input bool                 Show_Settings        = true;        // Show Settings
input ulong                m_magic              = 15489;       // magic number
//---
ulong                      m_slippage=10;                      // slippage

double                     ExtStopLoss=0.0;
double                     ExtTakeProfit=0.0;
double                     ExtTrailingStop=0.0;
double                     ExtTrailingStep=0.0;
double                     ExtMinCrossDistance=0.0;

int                        handle_iMA_Fast;                    // variable for storing the handle of the iMA indicator 
int                        handle_iMA_Slow;                    // variable for storing the handle of the iMA indicator 

double                     m_adjusted_point;                   // point value adjusted for 3 or 5 points
//--- GLOBAL VARIABLE
string                     LastTrade;
datetime                   CheckTime;
datetime                   CheckEntryTime;
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

   ExtStopLoss          = InpStopLoss        *m_adjusted_point;
   ExtTakeProfit        = InpTakeProfit      *m_adjusted_point;
   ExtTrailingStop      = InpTrailingStop    *m_adjusted_point;
   ExtTrailingStep      = InpTrailingStep    *m_adjusted_point;
   ExtMinCrossDistance  = InpMinCrossDistance*m_adjusted_point;
//---
   if(InpLots<0.0 && Risk<0.0)
     {
      Print(__FUNCTION__,", ERROR: Parameter (\"Lots\" or \"Risk\") can't be less than zero");
      return(false);
     }
   if(InpLots==0.0 && Risk==0.0)
     {
      Print(__FUNCTION__,", ERROR: Trade is impossible: You have set \"Lots\" == 0.0 and \"Risk\" == 0.0");
      return(false);
     }
   if(InpLots>0.0 && Risk>0.0)
     {
      Print(__FUNCTION__,", ERROR: Trade is impossible: You have set \"Lots\" > 0.0 and \"Risk\" > 0.0");
      return(false);
     }
   if(InpLots>0.0)
     {
      string err_text="";
      if(!CheckVolumeValue(InpLots,err_text))
        {
         Print(__FUNCTION__,", ERROR: ",err_text);
         return(false);
        }
     }
   else if(Risk>0.0)
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
   handle_iMA_Fast=iMA(m_symbol.Name(),Period(),FastMAPeriod,0,FastMAType,FastMAPrice);
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
   handle_iMA_Slow=iMA(m_symbol.Name(),Period(),SlowMAPeriod,0,SlowMAType,SlowMAPrice);
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
//--- SHOW EA SETTING ON THE CHART
//--- SOURCE : CODERSGURU
   if(Show_Settings) subPrintDetails();
   else Comment("");
//--- INITIALIZE PURE Stop And Reverse
//--- NO STOP LOSS, NO TAKE PROFIT, NO TRAILING STOP
   if(PureSAR)
     {
      ExtStopLoss      =0.0;
      ExtTakeProfit    =0.0;
      ExtTrailingStop  =0.0;
      ExtTrailingStep  =0.0;
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(m_money!=NULL)
      delete m_money;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   double FastMAPrevious,FastMACurrent,SlowMAPrevious,SlowMACurrent;
   int total;
   bool BuyCondition=false,SellCondition=false;
//--- TIME FILTER
   MqlDateTime STimeCurrent;
   TimeToStruct(TimeCurrent(),STimeCurrent);
   if(UseHourTrade)
     {
      if(!(STimeCurrent.hour>=StartHour && STimeCurrent.hour<=EndHour))
        {
         Comment("Non-Trading Hours!");
         return;
        }
     }
//--- CHECK CHART NEED MORE THAN 100 BARS
   if(Bars(m_symbol.Name(),Period())<100)
     {
      Print("bars less than 100");
      return;
     }
//--- TRAILING STOP SECTION
   Trailing();
   if(!RefreshRates())
      return;
//--- SET VALUE FOR VARIABLE
   if(ConfirmedOnEntry)
     {
      if(CheckTime==iTime(0))
         return;
      else
         CheckTime=iTime(0);
      //---
      FastMAPrevious=iMAGet(handle_iMA_Fast,2);
      FastMACurrent =iMAGet(handle_iMA_Fast,1);
      SlowMAPrevious=iMAGet(handle_iMA_Slow,2);
      SlowMACurrent =iMAGet(handle_iMA_Slow,1);
     }
   else
     {
      FastMAPrevious=iMAGet(handle_iMA_Fast,1);
      FastMACurrent =iMAGet(handle_iMA_Fast,0);
      SlowMAPrevious=iMAGet(handle_iMA_Slow,1);
      SlowMACurrent =iMAGet(handle_iMA_Slow,0);
     }
//--- CONDITION CHECK
   if(!ReverseCondition)
     {
      //--- BUY CONDITION   
      BuyCondition=(FastMAPrevious<SlowMAPrevious && 
                    FastMACurrent>SlowMACurrent && 
                    (FastMACurrent-SlowMACurrent)>=ExtMinCrossDistance);
      //--- SELL CONDITION   
      SellCondition=(FastMAPrevious>SlowMAPrevious && 
                     FastMACurrent<SlowMACurrent && 
                     (SlowMACurrent-FastMACurrent)>=ExtMinCrossDistance);
     }
   else
     {
      //--- BUY CONDITION   
      SellCondition=(FastMAPrevious<SlowMAPrevious && 
                     FastMACurrent>SlowMACurrent && 
                     (FastMACurrent-SlowMACurrent)>=ExtMinCrossDistance);
      //--- SELL CONDITION   
      BuyCondition=(FastMAPrevious>SlowMAPrevious && 
                    FastMACurrent<SlowMACurrent && 
                    (SlowMACurrent-FastMACurrent)>=ExtMinCrossDistance);
     }
//--- EXIT CONDITION
//--- not available
//--- STOP AND REVERSE
   if(StopAndReverse && CalculateAllPositions()>0)
     {
      if((LastTrade=="BUY" && SellCondition) || (LastTrade=="SELL" && BuyCondition))
        {
         CloseAllPositions();
         if(PrintControl)
            Print("STOP AND REVERSE!");
        }
     }
//--- ENTRY
//--- TOTAL ORDER BASE ON MAGICNUMBER AND SYMBOL
   total=CalculateAllPositions();
//--- IF NO TRADE
   if(total<1)
     {
      //--- ONE ENTRY PER BAR
      if(OneEntryPerBar)
        {
         if(CheckEntryTime==iTime(0))
            return;
         else
            CheckEntryTime=iTime(0);
        }
      //--- BUY CONDITION   
      if(BuyCondition)
        {
         double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
         double tp=(InpTakeProfit==0)?0.0:m_symbol.Ask()+ExtTakeProfit;
         if(OpenBuy(sl,tp))
            LastTrade="BUY";
         return;
        }
      //---- SELL CONDITION   
      if(SellCondition)
        {
         double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
         double tp=(InpTakeProfit==0)?0.0:m_symbol.Bid()-ExtTakeProfit;
         if(OpenSell(sl,tp))
            LastTrade="SELL";
         return;
        }
      return;
     }
   return;
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
//| Trailing                                                         |
//+------------------------------------------------------------------+
void Trailing()
  {
   if(ExtTrailingStop==0)
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
//| PRINT COMMENT FUNCTION                                           |
//| SOURCE : CODERSGURU                                              |
//+------------------------------------------------------------------+
void subPrintDetails()
  {
   string sComment  ="";
   string sp        ="----------------------------------------\n";
   string NL        ="\n";
//
   sComment=sp;
   sComment=sComment + "StopLoss=" + IntegerToString(InpStopLoss) + " | ";
   sComment=sComment + "TakeProfit=" + IntegerToString(InpTakeProfit) + " | ";
   sComment=sComment + "TrailingStop=" + IntegerToString(InpTrailingStop) + " | ";
   sComment=sComment + "TrailingStep=" + IntegerToString(InpTrailingStep) + NL;
   sComment=sComment + sp;
   sComment=sComment + "Reverse Entry Condition=" + subBoolToStr(ReverseCondition) + NL;
   sComment=sComment + "Confirmed On Entry=" + subBoolToStr(ConfirmedOnEntry) + NL;
   sComment=sComment + "Stop And Reverse=" + subBoolToStr(StopAndReverse) + NL;
   sComment=sComment + "Pure SAR=" + subBoolToStr(PureSAR) + NL;
   sComment=sComment + sp;
   sComment=sComment + "Lots=" + DoubleToString(InpLots,2) + " | ";
   sComment=sComment + "Risk=" + DoubleToString(Risk,0) + "%" + NL;
   sComment=sComment + sp;
//
   Comment(sComment);
  }
//+------------------------------------------------------------------+
//| BOOLEN VARIABLE TO STRING FUNCTION                               |
//| SOURCE : CODERSGURU                                              |
//+------------------------------------------------------------------+
string subBoolToStr(bool value)
  {
   if(value) return("true");
   else return("false");
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
bool OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double check_open_long_lot=0.0;
   if(Risk>0.0)
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
         return(false);
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
               return(false);
              }
            else
              {
               Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
               return(true);
              }
           }
         else
           {
            Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,m_symbol);
            return(false);
           }
        }
      else
        {
         string text="";
         if(Risk>0.0)
            text="< method CheckOpenLong ("+DoubleToString(check_open_long_lot,2)+")";
         else
            text="< Lots ("+DoubleToString(InpLots,2)+")";
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               text);
         return(false);
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return(false);
     }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
bool OpenSell(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double check_open_short_lot=0.0;
   if(Risk>0.0)
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
         return(false);
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
               return(false);
              }
            else
              {
               Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
               return(true);
              }
           }
         else
           {
            Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,m_symbol);
            return(false);
           }
        }
      else
        {
         string text="";
         if(Risk>0.0)
            text="< method CheckOpenShort ("+DoubleToString(check_open_short_lot,2)+")";
         else
            text="< Lots ("+DoubleToString(InpLots,2)+")";
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               text);
         return(false);
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return(false);
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

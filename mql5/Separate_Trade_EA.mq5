//+------------------------------------------------------------------+
//|                      Separate trade(barabashkakvn's edition).mq5 |
//|                                               valick2004@mail.ru |
//+------------------------------------------------------------------+
#property link      "valick2004@mail.ru"
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
input double   InpLots                 = 0.1;      // Lots
input ushort   InpStopLossBuy          = 50;       // Stop Loss Buy (in pips)
input ushort   InpStopLossSell         = 50;       // Stop Loss Sell (in pips)
input ushort   InpTakeProfitBuy        = 50;       // Take Profit Buy (in pips)
input ushort   InpTakeProfitSell       = 50;       // Take Profit Sell (in pips)
input ushort   InpTrailingStop         = 5;        // Trailing Stop (in pips)
input ushort   InpTrailingStep         = 5;        // Trailing Step (in pips)
input int      InpMaxPositions         = 1;        // Maximum positions
//---
input int                  InpMA_First_ma_period   = 65;          // MA First: averaging period 
input int                  InpMA_Second_ma_period  = 14;          // MA Second: averaging period 
input ENUM_MA_METHOD       InpMA_ma_method         = MODE_EMA;    // MA First and Second: smoothing type 
input ENUM_APPLIED_PRICE   InpMA_applied_price     = PRICE_CLOSE; // MA First and Second: type of price 
input ushort               InpMAs_Delta_Buy        = 2;           // Minimum distance between MA's for Buy ("0" -> off) (in pips)
input ushort               InpMAs_Delta_Sell       = 2;           // Minimum distance between MA's for Sell ("0" -> off) (in pips)
//---
input int      InpATR_ma_period_Buy    = 26;       // ATR Buy: averaging period
input int      InpATR_ma_period_Sell   = 26;       // ATR Sell: averaging period
input double   InpATR_Level_Buy        = 0.0016;   // ATR Buy: Level (if ATR < "ATR Buy" -> BUY)
input double   InpATR_Level_Sell       = 0.0016;   // ATR Sell: Level (if ATR > "ATR Sell" -> Sell)
//---
input int      InpStdDev_ma_period_Buy = 54;       // StdDev Buy: averaging period
input int      InpStdDev_ma_period_Sell= 54;       // StdDev Sell: averaging period
input double   InpStdDev_Level_Buy     = 0.0051;   // StdDev Buy: Level (if StdDev < "StdDev Buy" -> BUY)
input double   InpStdDev_Level_Sell    = 0.0051;   // StdDev Sell: Level (if StdDev > "StdDev Sell" -> Sell)
input ulong    m_magic                 = 518341490;// magic number
//---
ulong          m_slippage=10;                // slippage

double         ExtStopLossBuy=0.0;
double         ExtStopLossSell=0.0;
double         ExtTakeProfitBuy=0.0;
double         ExtTakeProfitSell=0.0;
double         ExtTrailingStop=0.0;
double         ExtTrailingStep=0.0;
double         ExtMAs_Delta_Buy=0.0;
double         ExtMAs_Delta_Sell=0.0;

int            handle_iMA_First;             // variable for storing the handle of the iMA indicator
int            handle_iMA_Second;            // variable for storing the handle of the iMA indicator
int            handle_iATR_Buy;              // variable for storing the handle of the iATR indicator 
int            handle_iATR_Sell;             // variable for storing the handle of the iATR indicator 
int            handle_iStdDev_Buy;           // variable for storing the handle of the iStdDev indicator 
int            handle_iStdDev_Sell;          // variable for storing the handle of the iStdDev indicator 

double         m_adjusted_point;             // point value adjusted for 3 or 5 points
datetime       m_last_deal_IN_buy=0;
datetime       m_last_deal_IN_sell=0;
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
      Print(__FUNCTION__,", ERROR Lots: ",err_text);
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

   ExtStopLossBuy    = InpStopLossBuy     * m_adjusted_point;
   ExtStopLossSell   = InpStopLossSell    * m_adjusted_point;
   ExtTakeProfitBuy  = InpTakeProfitBuy   * m_adjusted_point;
   ExtTakeProfitSell = InpTakeProfitSell  * m_adjusted_point;
   ExtTrailingStop   = InpTrailingStop    * m_adjusted_point;
   ExtTrailingStep   = InpTrailingStep    * m_adjusted_point;
   ExtMAs_Delta_Buy  = InpMAs_Delta_Buy   * m_adjusted_point;
   ExtMAs_Delta_Sell = InpMAs_Delta_Sell  * m_adjusted_point;
//--- create handle of the indicator iMA
   handle_iMA_First=iMA(m_symbol.Name(),Period(),InpMA_First_ma_period,0,InpMA_ma_method,InpMA_applied_price);
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
   handle_iMA_Second=iMA(m_symbol.Name(),Period(),InpMA_Second_ma_period,0,InpMA_ma_method,InpMA_applied_price);
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
//--- create handle of the indicator iATR
   handle_iATR_Buy=iATR(m_symbol.Name(),Period(),InpATR_ma_period_Buy);
//--- if the handle is not created 
   if(handle_iATR_Buy==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iATR indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iATR
   handle_iATR_Sell=iATR(m_symbol.Name(),Period(),InpATR_ma_period_Sell);
//--- if the handle is not created 
   if(handle_iATR_Sell==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iATR indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iStdDev   
   handle_iStdDev_Buy=iStdDev(m_symbol.Name(),Period(),InpStdDev_ma_period_Buy,0,MODE_SMA,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iStdDev_Buy==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iStdDev indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iStdDev   
   handle_iStdDev_Sell=iStdDev(m_symbol.Name(),Period(),InpStdDev_ma_period_Sell,0,MODE_SMA,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iStdDev_Sell==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iStdDev indicator for the symbol %s/%s, error code %d",
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
//---
   int count_buys = 0;
   int count_sells= 0;
   CalculateAllPositions(count_buys,count_sells);

   if(count_buys+count_sells>InpMaxPositions)
      return;
//---
   double MA_First   = iMAGet(handle_iMA_First,1);
   double MA_Second  = iMAGet(handle_iMA_Second,1);
   double ATR_Buy    = iATRGet(handle_iATR_Buy,1);
   double ATR_Sell   = iATRGet(handle_iATR_Sell,1);
   double StdDev_Buy = iStdDevGet(handle_iStdDev_Buy,1);
   double StdDev_Sell= iStdDevGet(handle_iStdDev_Sell,1);
//---
   if(!RefreshRates())
     {
      PrevBars=0;
      return;
     }
//--- BUY
   if(PrevBars>m_last_deal_IN_buy)
     {
      if((MA_First<MA_Second) && (ATR_Buy<InpATR_Level_Buy) && 
         ((MA_Second-MA_First)<InpMAs_Delta_Buy) && (StdDev_Buy<InpStdDev_Level_Buy))
        {
         double sl=(InpStopLossBuy==0)?0.0:m_symbol.Ask()-ExtStopLossBuy;
         if(sl>=m_symbol.Bid()) // incident: the position isn't opened yet, and has to be already closed
           {
            PrevBars=0;
            return;
           }
         double tp=(InpTakeProfitBuy==0)?0.0:m_symbol.Ask()+ExtTakeProfitBuy;
         OpenBuy(sl,tp);
        }
     }
//--- SELL
   if(PrevBars>m_last_deal_IN_sell)
     {
      if((MA_First>MA_Second) && (ATR_Sell<InpATR_Level_Sell) && 
         ((MA_First-MA_Second)<InpMAs_Delta_Sell) && (StdDev_Sell<InpStdDev_Level_Sell))
        {
         double sl=(InpStopLossSell==0)?0.0:m_symbol.Bid()+ExtStopLossSell;
         if(sl<=m_symbol.Ask()) // incident: the position isn't opened yet, and has to be already closed
           {
            PrevBars=0;
            return;
           }
         double tp=(InpTakeProfitSell==0)?0.0:m_symbol.Bid()-ExtTakeProfitSell;
         OpenSell(sl,tp);
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
           {
            if(deal_type==DEAL_TYPE_BUY)
               m_last_deal_IN_buy=iTime(m_symbol.Name(),Period(),0);
            else if(deal_type==DEAL_TYPE_SELL)
               m_last_deal_IN_sell=iTime(m_symbol.Name(),Period(),0);
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
//| Get value of buffers for the iATR                                |
//+------------------------------------------------------------------+
double iATRGet(const int handle_iATR,const int index)
  {
   double ATR[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iATR array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iATR,0,index,1,ATR)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iATR indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(ATR[0]);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iStdDev                             |
//+------------------------------------------------------------------+
double iStdDevGet(const int handle_iStdDev,const int index)
  {
   double StdDev[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iStdDev array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iStdDev,0,index,1,StdDev)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iStdDev indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(StdDev[0]);
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
     {
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.Buy(InpLots,m_symbol.Name(),m_symbol.Ask(),sl,tp))
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
               "< Lots (",DoubleToString(InpLots,2),")");
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
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.Sell(InpLots,m_symbol.Name(),m_symbol.Bid(),sl,tp))
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
               "< Lots (",DoubleToString(InpLots,2),")");
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

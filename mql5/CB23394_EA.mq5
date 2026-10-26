//+------------------------------------------------------------------+
//|                                                    FitFul 13.mq5 |
//|                              Copyright © 2018, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
#property version   "1.000"
#property description "RU: Успешность или неуспешность торговой операции подтверждается через OnTradeTransaction"
#property description "EN: Success or failure of a trade operation is confirmed through OnTradeTransaction"
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
//+------------------------------------------------------------------+
//| Enum Lor or Risk                                                 |
//+------------------------------------------------------------------+
enum ENUM_LOT_OR_RISK
  {
   lot=0,   // Constant lot
   risk=1,  // Risk in percent for a deal
  };
//--- input parameters
input ENUM_LOT_OR_RISK IntLotOrRisk=risk;    // Money management: Lot OR Risk
input double   InpVolumeLorOrRisk=1.0;       // The value for "Money management"
input ushort   InpTrailingStop   = 150;      // Trailing Stop (min distance from price to Stop Loss, in pips
input ushort   InpTrailingStep   = 5;        // Trailing Step, in pips (1.00045-1.00055=1 pips)
input ushort   InpIndent         = 3;        // Indent, in pips (1.00045-1.00055=1 pips)
input ENUM_TIMEFRAMES TimeFrame_1= PERIOD_H1;// TimeFrame 1
input ENUM_TIMEFRAMES TimeFrame_3=PERIOD_M15;// TimeFrame 3
input bool     InpPrintLog=false;            // Print log
input ulong    m_magic=645138312;// magic number
//---
ulong  m_slippage                = 10;       // slippage
double ExtTrailingStop           = 0.0;      // Trailing Stop -> double
double ExtTrailingStep           = 0.0;      // Trailing Step -> double
double ExtIndent                 = 0.0;      // Indent -> double
double ExtStopLoss               = 0.0;      // Stop Loss -> double
double ExtTakeProfit             = 0.0;      // Take Profit -> double
double m_adjusted_point;                     // point value adjusted for 3 or 5 points
bool   m_need_open_buy           = false;    // "true" -> need to open BUY
bool   m_need_open_sell          = false;    // "true" -> need to open SELL
bool   m_waiting_transaction     = false;    // "true" -> it's forbidden to trade, we expect a transaction
ulong  m_waiting_order_ticket    = 0;        // ticket of the expected order
bool   m_transaction_confirmed   = false;    // "true" -> transaction confirmed
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
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtTrailingStop   = InpTrailingStop    * m_adjusted_point;
   ExtTrailingStep   = InpTrailingStep    * m_adjusted_point;
   ExtIndent         = InpIndent          * m_adjusted_point;
//--- check the input parameter "Lots"
   string err_text="";
   if(IntLotOrRisk==lot)
     {
      if(!CheckVolumeValue(InpVolumeLorOrRisk,err_text))
        {
         //--- when testing, we will only output to the log about incorrect input parameters
         if(MQLInfoInteger(MQL_TESTER))
           {
            Print(__FUNCTION__,", ERROR: ",err_text);
            return(INIT_FAILED);
           }
         else // if the Expert Advisor is run on the chart, tell the user about the error
           {
            Alert(__FUNCTION__,", ERROR: ",err_text);
            return(INIT_PARAMETERS_INCORRECT);
           }
        }
     }
   else
     {
      if(m_money!=NULL)
         delete m_money;
      m_money=new CMoneyFixedMargin;
      if(m_money!=NULL)
        {
         if(!m_money.Init(GetPointer(m_symbol),Period(),m_symbol.Point()*digits_adjust))
            return(INIT_FAILED);
         m_money.Percent(InpVolumeLorOrRisk);
        }
      else
        {
         Print(__FUNCTION__,", ERROR: Object CMoneyFixedMargin is NULL");
         return(INIT_FAILED);
        }
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
   if(m_money!=NULL)
      delete m_money;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(m_waiting_transaction)
     {
      if(!m_transaction_confirmed)
        {
         Print("m_transaction_confirmed: ",m_transaction_confirmed);
         return;
        }
      else if(m_transaction_confirmed)
        {
         m_need_open_buy            = false;    // "true" -> need to open BUY
         m_need_open_sell           = false;    // "true" -> need to open SELL
         m_waiting_transaction      = false;    // "true" -> it's forbidden to trade, we expect a transaction
         m_waiting_order_ticket     = 0;        // ticket of the expected order
         m_transaction_confirmed    = false;    // "true" -> transaction confirmed
        }
     }
   if(m_need_open_buy)
     {
      double level;
      if(FreezeStopsLevels(level))
        {
         m_waiting_transaction=true;
         OpenPosition(POSITION_TYPE_BUY,level);
        }
      return;
     }
   if(m_need_open_sell)
     {
      double level;
      if(FreezeStopsLevels(level))
        {
         m_waiting_transaction=true;
         OpenPosition(POSITION_TYPE_SELL,level);
        }
      return;
     }
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
   ExtStopLoss=0.0;
   ExtTakeProfit=0.0;

   int count_buys=0,count_sells=0;
   CalculateAllPositions(count_buys,count_sells);

   if(count_buys+count_sells>=3)
     {
      return;
     }
   else
     {
      double level;
      if(FreezeStopsLevels(level))
         Trailing(level);

      MqlRates rates_tf_1[],rates_tf_3[],rates_w1[];
      ArraySetAsSeries(rates_tf_1,true);
      ArraySetAsSeries(rates_tf_3,true);
      ArraySetAsSeries(rates_w1,true);

      if(CopyRates(m_symbol.Name(),TimeFrame_1,0,6,rates_tf_1)!=6 ||
         CopyRates(m_symbol.Name(),TimeFrame_3,0,6,rates_tf_3)!=6 ||
         CopyRates(m_symbol.Name(),PERIOD_W1,0,6,rates_w1)!=6)
         return;

      //--- calculation of weekly levels
      double HW=rates_w1[1].high;
      double LW=rates_w1[1].low;
      double CW=rates_w1[1].close;
      //---
      double PriceTypical=(HW+LW+CW)/3.0;
      double R1= 2.0*PriceTypical-LW;
      double S1= 2.0*PriceTypical-HW;
      double R05=(PriceTypical+R1)/2.0;
      double S05=(PriceTypical+S1)/2.0;
      double R2= PriceTypical+(HW-LW);
      double S2= PriceTypical-(HW-LW);
      double R15=(R1+R2)/2.0;
      double S15=(S1+S2)/2.0;
      double R3= 2.0*PriceTypical+(HW-2.0*LW);
      double S3= 2.0*PriceTypical-(2.0*HW-LW);
      double R25=(R2+R3)/2.0;
      double S25=(S2+S3)/2.0;

      if(rates_tf_1[1].open<=rates_tf_1[1].close)
        {
         if(rates_tf_1[2].open<=PriceTypical && rates_tf_1[2].close>=PriceTypical)
           {
            ExtStopLoss=S1-ExtIndent;
            ExtTakeProfit=R1+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if(rates_tf_1[2].open<=R05 && rates_tf_1[2].close>=R05)
           {
            ExtStopLoss=S05-ExtIndent;
            ExtTakeProfit=R15+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if(rates_tf_1[2].open<=R1 && rates_tf_1[2].close>=R1)
           {
            ExtStopLoss=PriceTypical-ExtIndent;
            ExtTakeProfit=R2+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if(rates_tf_1[2].open<=R15 && rates_tf_1[2].close>=R15)
           {
            ExtStopLoss=R05-ExtIndent;
            ExtTakeProfit=R25+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if(rates_tf_1[2].open<=R2 && rates_tf_1[2].close>=R2)
           {
            ExtStopLoss=R1-ExtIndent;
            ExtTakeProfit=R3+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if(rates_tf_1[2].open<=R25 && rates_tf_1[2].close>=R25)
           {
            ExtStopLoss=R15-ExtIndent;
            ExtTakeProfit=R3+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if(rates_tf_1[2].open<=S1 && rates_tf_1[2].close>=S1)
           {
            ExtStopLoss=S2-ExtIndent;
            ExtTakeProfit=PriceTypical+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if(rates_tf_1[2].open<=S05 && rates_tf_1[2].close>=S05)
           {
            ExtStopLoss=S15-ExtIndent;
            ExtTakeProfit=R05+ExtIndent;
            m_need_open_buy=true;
            return;
           }
        }
      // - ПРОБОЙ (ВВЕРХУ СНИЗ)!!! 
      if(rates_tf_1[1].open>=rates_tf_1[1].close)
        {
         if(rates_tf_1[2].open>=PriceTypical && rates_tf_1[2].close<=PriceTypical)
           {
            ExtStopLoss=R1+ExtIndent;
            ExtTakeProfit=S1-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if(rates_tf_1[2].open>=S05 && rates_tf_1[2].close<=S05)
           {
            ExtStopLoss=R05+ExtIndent;
            ExtTakeProfit=S15-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if(rates_tf_1[2].open>=S1 && rates_tf_1[2].close<=S1)
           {
            ExtStopLoss=PriceTypical+ExtIndent;
            ExtTakeProfit=S2-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if(rates_tf_1[2].open>=S15 && rates_tf_1[2].close<=S15)
           {
            ExtStopLoss=S05+ExtIndent;
            ExtTakeProfit=S25-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if(rates_tf_1[2].open>=S2 && rates_tf_1[2].close<=S2)
           {
            ExtStopLoss=S1+ExtIndent;
            ExtTakeProfit=S3-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if(rates_tf_1[2].open>=S25 && rates_tf_1[2].close<=S25)
           {
            ExtStopLoss=S15+ExtIndent;
            ExtTakeProfit=S3-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if(rates_tf_1[2].open>=R1 && rates_tf_1[2].close<=R1)
           {
            ExtStopLoss=R2+ExtIndent;
            ExtTakeProfit=PriceTypical-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if(rates_tf_1[2].open>=R05 && rates_tf_1[2].close<=R05)
           {
            ExtStopLoss=R15+ExtIndent;
            ExtTakeProfit=S05-ExtIndent;
            m_need_open_sell=true;
            return;
           }
        }
      // - ОТБОЙ (СВЕРХУ ВНИЗ И ВВЕРХ)!!! 
      if(rates_tf_3[1].open<=rates_tf_3[1].close)
        {
         if((rates_tf_3[3].low<=PriceTypical && rates_tf_3[3].close>=PriceTypical) && (rates_tf_3[2].low<=PriceTypical && rates_tf_3[2].close>=PriceTypical))
           {
            ExtStopLoss=S1-ExtIndent;
            ExtTakeProfit=R1+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if((rates_tf_3[3].low<=R05 && rates_tf_3[3].close>=R05) && (rates_tf_3[2].low<=R05 && rates_tf_3[2].close>=R05))
           {
            ExtStopLoss=S05-ExtIndent;
            ExtTakeProfit=R15+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if((rates_tf_3[3].low<=R1 && rates_tf_3[3].close>=R1) && (rates_tf_3[2].low<=R1 && rates_tf_3[2].close>=R1))
           {
            ExtStopLoss=PriceTypical-ExtIndent;
            ExtTakeProfit=R2+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if((rates_tf_3[3].low<=R15 && rates_tf_3[3].close>=R15) && (rates_tf_3[2].low<=R15 && rates_tf_3[2].close>=R15))
           {
            ExtStopLoss=R05-ExtIndent;
            ExtTakeProfit=R25+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if((rates_tf_3[3].low<=R2 && rates_tf_3[3].close>=R2) && (rates_tf_3[2].low<=R2 && rates_tf_3[2].close>=R2))
           {
            ExtStopLoss=R1-ExtIndent;
            ExtTakeProfit=R3+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if((rates_tf_3[3].low<=R25 && rates_tf_3[3].close>=R25) && (rates_tf_3[2].low<=R25 && rates_tf_3[2].close>=R25))
           {
            ExtStopLoss=R15-ExtIndent;
            ExtTakeProfit=R3+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if((rates_tf_3[3].low<=S1 && rates_tf_3[3].close>=S1) && (rates_tf_3[2].low<=S1 && rates_tf_3[2].close>=S1))
           {
            ExtStopLoss=S2-ExtIndent;
            ExtTakeProfit=PriceTypical+ExtIndent;
            m_need_open_buy=true;
            return;
           }
         if((rates_tf_3[3].low<=S05 && rates_tf_3[3].close>=S05) && (rates_tf_3[2].low<=S05 && rates_tf_3[2].close>=S05))
           {
            ExtStopLoss=S15-ExtIndent;
            ExtTakeProfit=R05+ExtIndent;
            m_need_open_buy=true;
            return;
           }
        }
      // - ОТБОЙ (СНИЗУ ВВЕРХ И ВНИЗ)!!!    
      if(rates_tf_3[1].open>=rates_tf_3[1].close)
        {
         if((rates_tf_3[3].high>=PriceTypical && rates_tf_3[3].close<=PriceTypical) && (rates_tf_3[2].high>=PriceTypical && rates_tf_3[2].close<=PriceTypical))
           {
            ExtStopLoss=R1+ExtIndent;
            ExtTakeProfit=S1-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if((rates_tf_3[3].high>=S05 && rates_tf_3[3].close<=S05) && (rates_tf_3[2].high>=S05 && rates_tf_3[2].close<=S05))
           {
            ExtStopLoss=R05+ExtIndent;
            ExtTakeProfit=S15-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if((rates_tf_3[3].high>=S1 && rates_tf_3[3].close<=S1) && (rates_tf_3[2].high>=S1 && rates_tf_3[2].close<=S1))
           {
            ExtStopLoss=PriceTypical+ExtIndent;
            ExtTakeProfit=S2-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if((rates_tf_3[3].high>=S15 && rates_tf_3[3].close<=S15) && (rates_tf_3[2].high>=S15 && rates_tf_3[2].close<=S15))
           {
            ExtStopLoss=S05+ExtIndent;
            ExtTakeProfit=S25-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if((rates_tf_3[3].high>=S2 && rates_tf_3[3].close<=S2) && (rates_tf_3[2].high>=S2 && rates_tf_3[2].close<=S2))
           {
            ExtStopLoss=S1+ExtIndent;
            ExtTakeProfit=S3-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if((rates_tf_3[3].high>=S25 && rates_tf_3[3].close<=S25) && (rates_tf_3[2].high>=S25 && rates_tf_3[2].close<=S25))
           {
            ExtStopLoss=S15+ExtIndent;
            ExtTakeProfit=S3-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if((rates_tf_3[3].high>=R1 && rates_tf_3[3].close<=R1) && (rates_tf_3[2].high>=R1 && rates_tf_3[2].close<=R1))
           {
            ExtStopLoss=R2+ExtIndent;
            ExtTakeProfit=PriceTypical-ExtIndent;
            m_need_open_sell=true;
            return;
           }
         if((rates_tf_3[3].high>=R05 && rates_tf_3[3].close<=R05) && (rates_tf_3[2].high>=R05 && rates_tf_3[2].close<=R05))
           {
            ExtStopLoss=R15+ExtIndent;
            ExtTakeProfit=S05-ExtIndent;
            m_need_open_sell=true;
            return;
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
         if(deal_entry==DEAL_ENTRY_IN)
            if(deal_type==DEAL_TYPE_BUY || deal_type==DEAL_TYPE_SELL)
              {
               if(m_waiting_transaction)
                  if(m_waiting_order_ticket==deal_order)
                    {
                     Print(__FUNCTION__," Transaction confirmed");
                     m_transaction_confirmed=true;
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
//| Check Freeze and Stops levels                                    |
//+------------------------------------------------------------------+
bool FreezeStopsLevels(double &level)
  {
//--- check Freeze and Stops levels
/*
   Type of order/position  |  Activation price  |  Check
   ------------------------|--------------------|--------------------------------------------
   Buy Limit order         |  Ask               |  Ask-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy Stop order          |  Ask	            |  OpenPrice-Ask  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Limit order        |  Bid	            |  OpenPrice-Bid  >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell Stop order	      |  Bid	            |  Bid-OpenPrice  >= SYMBOL_TRADE_FREEZE_LEVEL
   Buy position            |  Bid	            |  TakeProfit-Bid >= SYMBOL_TRADE_FREEZE_LEVEL 
                           |                    |  Bid-StopLoss   >= SYMBOL_TRADE_FREEZE_LEVEL
   Sell position           |  Ask	            |  Ask-TakeProfit >= SYMBOL_TRADE_FREEZE_LEVEL
                           |                    |  StopLoss-Ask   >= SYMBOL_TRADE_FREEZE_LEVEL
                           
   Buying is done at the Ask price                 |  Selling is done at the Bid price
   ------------------------------------------------|----------------------------------
   TakeProfit        >= Bid                        |  TakeProfit        <= Ask
   StopLoss          <= Bid	                     |  StopLoss          >= Ask
   TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
   Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
*/
   if(!RefreshRates() || !m_symbol.Refresh())
      return(false);
//--- FreezeLevel -> for pending order and modification
   double freeze_level=m_symbol.FreezeLevel()*m_symbol.Point();
   if(freeze_level==0.0)
      freeze_level=(m_symbol.Ask()-m_symbol.Bid())*3.0;
   freeze_level*=1.1;
//--- StopsLevel -> for TakeProfit and StopLoss
   double stop_level=m_symbol.StopsLevel()*m_symbol.Point();
   if(stop_level==0.0)
      stop_level=(m_symbol.Ask()-m_symbol.Bid())*3.0;
   stop_level*=1.1;

   if(freeze_level<=0.0 || stop_level<=0.0)
      return(false);

   level=(freeze_level>stop_level)?freeze_level:stop_level;
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Open position                                                    |
//+------------------------------------------------------------------+
void OpenPosition(const ENUM_POSITION_TYPE pos_type,const double level)
  {
//--- buy
   if(pos_type==POSITION_TYPE_BUY)
     {
/*
   Buying is done at the Ask price                 |  Selling is done at the Bid price
   ------------------------------------------------|----------------------------------
   TakeProfit        >= Bid                        |  TakeProfit        <= Ask
   StopLoss          <= Bid	                     |  StopLoss          >= Ask
   TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
   Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
*/
      double price=m_symbol.Bid();

      double sl=ExtStopLoss;
      if(sl!=0.0 && price-ExtStopLoss<level) // check sl
         sl=price-level;

      double tp=ExtTakeProfit;
      if(tp!=0.0 && ExtTakeProfit-price<level) // check price
         tp=price+level;

      OpenBuy(sl,tp);
     }
//--- sell
   if(pos_type==POSITION_TYPE_SELL)
     {
      double price=m_symbol.Ask();

      double sl=ExtStopLoss;
      if(sl!=0.0 && ExtStopLoss-price<level) // check sl
         sl=price+level;

      double tp=ExtTakeProfit;
      if(tp!=0.0 && price-ExtTakeProfit<level) // check tp
         tp=price-level;

      OpenSell(sl,tp);
     }
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double long_lot=0.0;
   if(IntLotOrRisk==risk)
     {
      long_lot=m_money.CheckOpenLong(m_symbol.Ask(),sl);
      if(InpPrintLog)
         Print("sl=",DoubleToString(sl,m_symbol.Digits()),
               ", CheckOpenLong: ",DoubleToString(long_lot,2),
               ", Balance: ",    DoubleToString(m_account.Balance(),2),
               ", Equity: ",     DoubleToString(m_account.Equity(),2),
               ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
      if(long_lot==0.0)
        {
         m_waiting_transaction=false;
         if(InpPrintLog)
            Print(__FUNCTION__,", ERROR: method CheckOpenLong returned the value of \"0.0\"");
         return;
        }
     }
   else if(IntLotOrRisk==lot)
      long_lot=InpVolumeLorOrRisk;
   else
     {
      m_waiting_transaction=false;
      return;
     }
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check= m_account.FreeMarginCheck(m_symbol.Name(),ORDER_TYPE_BUY,long_lot,m_symbol.Ask());
   double margin_check     = m_account.MarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,long_lot,m_symbol.Bid());
   if(free_margin_check>margin_check)
     {
      if(m_trade.Buy(long_lot,m_symbol.Name(),m_symbol.Ask(),sl,tp)) // CTrade::Buy -> "true"
        {
         if(m_trade.ResultDeal()==0)
           {
            if(m_trade.ResultRetcode()==10009) // trade order went to the exchange
              {
               m_waiting_transaction=true;  // "true" -> it's forbidden to trade, we expect a transaction
               m_waiting_order_ticket=m_trade.ResultOrder();
              }
            else
               m_waiting_transaction=false;
            if(InpPrintLog)
               Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
           }
         else
           {
            if(m_trade.ResultRetcode()==10009)
              {
               m_waiting_transaction=true;  // "true" -> it's forbidden to trade, we expect a transaction
               m_waiting_order_ticket=m_trade.ResultOrder();
              }
            else
               m_waiting_transaction=false;
            if(InpPrintLog)
               Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         m_waiting_transaction=false;
         if(InpPrintLog)
            Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
         if(InpPrintLog)
            PrintResultTrade(m_trade,m_symbol);
        }
     }
   else
     {
      m_waiting_transaction=false;
      if(InpPrintLog)
         Print(__FUNCTION__,", ERROR: method CAccountInfo::FreeMarginCheck returned the value ",DoubleToString(free_margin_check,2));
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

   double short_lot=0.0;
   if(IntLotOrRisk==risk)
     {
      short_lot=m_money.CheckOpenShort(m_symbol.Bid(),sl);
      if(InpPrintLog)
         Print("sl=",DoubleToString(sl,m_symbol.Digits()),
               ", CheckOpenLong: ",DoubleToString(short_lot,2),
               ", Balance: ",    DoubleToString(m_account.Balance(),2),
               ", Equity: ",     DoubleToString(m_account.Equity(),2),
               ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2));
      if(short_lot==0.0)
        {
         m_waiting_transaction=false;
         if(InpPrintLog)
            Print(__FUNCTION__,", ERROR: method CheckOpenShort returned the value of \"0.0\"");
         return;
        }
     }
   else if(IntLotOrRisk==lot)
      short_lot=InpVolumeLorOrRisk;
   else
     {
      m_waiting_transaction=false;
      return;
     }
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check= m_account.FreeMarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,short_lot,m_symbol.Bid());
   double margin_check     = m_account.MarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,short_lot,m_symbol.Bid());
   if(free_margin_check>margin_check)
     {
      if(m_trade.Sell(short_lot,m_symbol.Name(),m_symbol.Bid(),sl,tp)) // CTrade::Sell -> "true"
        {
         if(m_trade.ResultDeal()==0)
           {
            if(m_trade.ResultRetcode()==10009) // trade order went to the exchange
              {
               m_waiting_transaction=true;  // "true" -> it's forbidden to trade, we expect a transaction
               m_waiting_order_ticket=m_trade.ResultOrder();
              }
            else
               m_waiting_transaction=false;
            if(InpPrintLog)
               Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
           }
         else
           {
            if(m_trade.ResultRetcode()==10009)
              {
               m_waiting_transaction=true;  // "true" -> it's forbidden to trade, we expect a transaction
               m_waiting_order_ticket=m_trade.ResultOrder();
              }
            else
               m_waiting_transaction=false;
            if(InpPrintLog)
               Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            if(InpPrintLog)
               PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         m_waiting_transaction=false;
         if(InpPrintLog)
            Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
         if(InpPrintLog)
            PrintResultTrade(m_trade,m_symbol);
        }
     }
   else
     {
      m_waiting_transaction=false;
      if(InpPrintLog)
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
//| Trailing                                                         |
//|   InpTrailingStop: min distance from price to Stop Loss          |
//+------------------------------------------------------------------+
void Trailing(const double stop_level)
  {
/*
     Buying is done at the Ask price                 |  Selling is done at the Bid price
   ------------------------------------------------|----------------------------------
   TakeProfit        >= Bid                        |  TakeProfit        <= Ask
   StopLoss          <= Bid	                     |  StopLoss          >= Ask
   TakeProfit - Bid  >= SYMBOL_TRADE_STOPS_LEVEL   |  Ask - TakeProfit  >= SYMBOL_TRADE_STOPS_LEVEL
   Bid - StopLoss    >= SYMBOL_TRADE_STOPS_LEVEL   |  StopLoss - Ask    >= SYMBOL_TRADE_STOPS_LEVEL
*/
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
                     if(ExtTrailingStop>=stop_level)
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
                     if(ExtTrailingStop>=stop_level)
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
   Print("Freeze Level: "+DoubleToString(m_symbol.FreezeLevel(),0),", Stops Level: "+DoubleToString(m_symbol.StopsLevel(),0));
   Print("Price of position opening: "+DoubleToString(position.PriceOpen(),symbol.Digits()));
   Print("Price of position's Stop Loss: "+DoubleToString(position.StopLoss(),symbol.Digits()));
   Print("Price of position's Take Profit: "+DoubleToString(position.TakeProfit(),symbol.Digits()));
   Print("Current price by position: "+DoubleToString(position.PriceCurrent(),symbol.Digits()));
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                      Firebird v0.60(barabashkakvn's edition).mq5 |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2005, TraderSeven"
#property link      "TraderSeven@gmx.net"
//            \\|//             +-+-+-+-+-+-+-+-+-+-+-+             \\|// 
//           ( o o )            |T|r|a|d|e|r|S|e|v|e|n|            ( o o )
//    ~~~~oOOo~(_)~oOOo~~~~     +-+-+-+-+-+-+-+-+-+-+-+     ~~~~oOOo~(_)~oOOo~~~~
// Firebird calculates a 10 day SMA and then shifts it up and down 2% to for a channel.
// For the calculation of this SMA either close (more trades) or H+L (safer trades) is used.
// When the price breaks a band a postion in the opposite of the current trend is taken.
// If the position goes against us we simply open an extra position to average.
// 50% of the trades last a day. 45% 2-6 days 5% longer or just fail.
//----------------------- TO DO LIST
// 1st days profit target is the 30 pip line *not* 30 pips below average as usually. -----> Day()
// Trailing stop -> trailing or S/R or pivot target
// Realistic stop loss
// Avoid overly big positions
// EUR/USD  30 pips / use same value as current_pips_step
// GBP/CHF  50 pips / use same value as current_pips_step 
// USD/CAD  35 pips / use same value as current_pips_step 
//----------------------- OBSERVATIONS
// GBPUSD not suited for this system due to not reversing exhaustions. Maybe use other types of MA
// EURGBP often sharp reversals-> good for trailing stops?
// EURJPY deep pockets needed.
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
//--- input parameters
input double               InpLots           = 0.1;         // Lots
input ushort               InpStopLoss       = 50;          // Stop Loss (in pips) (do not use "0")
input ushort               InpTakeProfit     = 150;         // Take Profit (in pips) (do not use "0")
input int                  Ma_ma_period      = 10;          // MA: averaging period 
input int                  Ma_ma_shift       = 0;           // MA: horizontal shift 
input ENUM_MA_METHOD       Ma_ma_method      = MODE_EMA;    // MA: smoothing type 
input ENUM_APPLIED_PRICE   Ma_applied_price  = PRICE_CLOSE; // MA: type of price 
input double               InpMaPricePercent = 0.3;         // Distance between "MA" and the price (as a percentage)
input bool                 InpTradeOnFriday  = true;        // Trade on friday
input int                  InpStep           = 30;          // Step: distance between positions (in pips)
input uchar                InpIncreaseStep   = 0;           // Increase in a step depending on quantity of positions
input ulong                m_magic=189326592;               // magic number
//---
ulong          m_slippage=10;                // slippage

double         ExtStopLoss=0.0;
double         ExtTakeProfit=0.0;
double         ExtStep=0.0;

datetime       last_OUT_position_time=0;     // последнее время закрытия позиции
int            handle_iMA;                   // variable for storing the handle of the iMA indicator 

double         m_adjusted_point;             // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(InpStep<=0)
     {
      Print(__FUNCTION__," ERROR: the \"Step\" parameter can not be less than or equal to zero");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpStopLoss<=0)
     {
      Print(__FUNCTION__," ERROR: the \"StopLoss\" parameter can not be less than or equal to zero");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpTakeProfit<=0)
     {
      Print(__FUNCTION__," ERROR: the \"TakeProfit\" parameter can not be less than or equal to zero");
      return(INIT_PARAMETERS_INCORRECT);
     }
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

   ExtStopLoss=InpStopLoss*m_adjusted_point;
   ExtTakeProfit=InpTakeProfit*m_adjusted_point;
//--- create handle of the indicator iMA
   handle_iMA=iMA(m_symbol.Name(),Period(),Ma_ma_period,Ma_ma_shift,Ma_ma_method,Ma_applied_price);
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
   double AveragePrice=0.0;
   int OpeningDay=0;

   int positions_total=0;              // количество открытых позиций
   datetime last_IN_position_time=0;   // время открытия последней позиции
   double last_IN_position_price=0;    // цена последней открытой позиции

   CalculatePositions(positions_total,last_IN_position_time,last_IN_position_price);

   double current_pips_step=(InpIncreaseStep==0)?ExtStep:MathPow(positions_total,InpIncreaseStep)*InpStep*m_adjusted_point;
   if(current_pips_step==0.0)
      current_pips_step=ExtStep;
//---
   MqlDateTime STimeCurrent;
   TimeToStruct(TimeCurrent(),STimeCurrent);

   if(STimeCurrent.day!=5 || InpTradeOnFriday)
     {
      int flag=0;
      int period_seconds=PeriodSeconds(Period())*2;
      if((long)(TimeCurrent()-last_IN_position_time)<PeriodSeconds(Period())*2)
         flag=1;
      if(flag!=1 && RefreshRates())
        {
         if((iMAGet(0)*(1.0-InpMaPricePercent/100.0))>m_symbol.Ask() && 
            (m_symbol.Ask()<=(last_IN_position_price-(current_pips_step*m_symbol.Point())) || positions_total==0)) // Go LONG -> Only buy if >= 30 pips below previous position entry	 
           {
            double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
            double tp=(InpTakeProfit==0)?0.0:m_symbol.Ask()+ExtTakeProfit;
            OpenBuy(sl,tp);
            return;
           }
         if((iMAGet(0)*(1.0+InpMaPricePercent/100.0))<m_symbol.Bid() && 
            (m_symbol.Bid()>=(last_IN_position_price+(current_pips_step*m_symbol.Point())) || positions_total==0)) // Go SHORT -> Only sell if >= 30 pips above previous position entry	
           {
            double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
            double tp=(InpTakeProfit==0)?0.0:m_symbol.Bid()-ExtTakeProfit;
            OpenSell(sl,tp);
            return;
           }
        }
     }
//--- CALCULATE AVERAGE OPENING PRICE
   if(positions_total>1)
     {
      AveragePrice=0.0;
      for(int i=PositionsTotal()-1;i>=0;i--)
         if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
            if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
               AveragePrice+=m_position.PriceOpen();
      //---
      AveragePrice/=positions_total;
      //--- RECALCULATE STOPLOSS & PROFIT TARGET BASED ON AVERAGE OPENING PRICE
      for(int i=PositionsTotal()-1;i>=0;i--)
         if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
            if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
              {
               if(m_position.PositionType()==POSITION_TYPE_BUY)// Calculate profit/stop target for long 
                 {
                  //--- set all positions to averaged levels
                  double sl=AveragePrice-(((ExtStopLoss)/positions_total));
                  double tp=AveragePrice+(ExtTakeProfit);
                  if(sl<m_position.PriceCurrent()-m_symbol.Spread()*m_adjusted_point)
                    {
                     if(CompareDoubles(sl,m_position.StopLoss(),m_symbol.Digits()) && CompareDoubles(tp,m_position.TakeProfit(),m_symbol.Digits()))
                        continue;
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(sl),
                        m_symbol.NormalizePrice(tp)))
                        Print("Modify BUY ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
                 }
               else // Calculate profit/stop target for short
                 {
                  //--- set all positions to averaged levels
                  double sl=AveragePrice+(((ExtStopLoss)/positions_total));
                  double tp=AveragePrice-(ExtTakeProfit);
                  if(sl>m_position.PriceCurrent()+m_symbol.Spread()*m_adjusted_point)
                    {
                     if(CompareDoubles(sl,m_position.StopLoss(),m_symbol.Digits()) && CompareDoubles(tp,m_position.TakeProfit(),m_symbol.Digits()))
                        continue;
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(sl),
                        m_symbol.NormalizePrice(tp)))
                        Print("Modify SELL ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
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
//---
   double res=0.0;
   int losses=0.0;
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
         if(deal_entry==DEAL_ENTRY_OUT)
            if(deal_type==DEAL_TYPE_BUY || deal_type==DEAL_TYPE_SELL)
               last_OUT_position_time=(datetime)deal_time;
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
//| Calculate positions Buy and Sell                                 |
//+------------------------------------------------------------------+
void CalculatePositions(int &count_positions,datetime &time_last_open,double &price_last_open)
  {
   count_positions=0;
   time_last_open=0;
   price_last_open=0.0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            count_positions++;
            if(m_position.Time()>time_last_open)
              {
               time_last_open=m_position.Time();
               price_last_open=m_position.PriceOpen();
              }
           }
//---
   return;
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
   int d=0;
  }
//+------------------------------------------------------------------+
//| Compare doubles                                                  |
//+------------------------------------------------------------------+
bool CompareDoubles(double number1,double number2,int digits)
  {
   digits=(digits-1<0)?0:digits-1;
   bool res=(fabs(number1-number2)<=16*DBL_EPSILON*fmax(fabs(number1),fabs(number2)));
   if(NormalizeDouble(number1-number2,digits)==0)
      return(true);
   else
      return(false);
  }
//+------------------------------------------------------------------+

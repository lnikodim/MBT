//+------------------------------------------------------------------+
//|                      CCI and Martin(barabashkakvn's edition).mq5 |
//|                                                    Voloshin Yuri |
//|                                       https://www.metaquotes.net |
//+------------------------------------------------------------------+
#property copyright "Voloshin Yuri"
#property link      "https://www.metaquotes.net"
#property version   "1.002"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
//+------------------------------------------------------------------+
//| ENUM_STEP                                                        |
//+------------------------------------------------------------------+
enum ENUM_STEP
  {
   loss =            -1, // ... lossing
   profit=           1,  // ... profitable
  };
//--- input parameters
input double               InpLots                       = 0.1;            // Lots
input ushort               InpStopLoss                   = 20;             // Stop Loss ("0.0" -> off) (in pips)
input ushort               InpTakeProfit                 = 50;             // Take Profit ("0.0" -> off) (in pips)
input ushort               InpTrailingStop               = 5;              // Trailing Stop ("0.0" -> off) (in pips)
input ushort               InpTrailingStep               = 15;             // Trailing Step (in pips)
//--- CCI
input int                  Inp_ma_period                 = 27;             // CCI: averaging period
input ENUM_APPLIED_PRICE   Inp_applied_price             = PRICE_TYPICAL;  // CCI: type of price
//--- martingale
input bool                 InpMartin                     = true;           // Use martingale
input double               InpMartinCoeff                = 3.0;            // Martingale coefficient
input int                  InpMartinOrdinalNumber        = 1;              // Ordinal number of the losing trade
input int                  InpMartinMaxMultiplications   = 3;              // Maximum number of multiplications
//--- step by step
input bool                 InpStep                       = false;          // Use step by step
input double               InpStepLots                   = 0.1;            // Step lots
input double               InpStepLotsMax                = 1.5;            // Maximum lots
input ENUM_STEP            InpStepProfit                 = loss;           // Use step afte ...       
input ulong                m_magic                       = 930873054;      // magic number
//---
ulong    m_slippage=10;          // slippage

double   ExtStopLoss=0.0;
double   ExtTakeProfit=0.0;
double   ExtTrailingStop=0.0;
double   ExtTrailingStep=0.0;

int      handle_iCCI;            // variable for storing the handle of the iCCI indicator 

double   m_adjusted_point;       // point value adjusted for 3 or 5 points

double   m_lots=0.0;
int      m_martin=0;
int      m_loss=0;
int      m_profit=0;
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
   if(InpMartin && InpStep)
     {
      string text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                  "Торговля запрещена: \"Use martingale\" = "+((InpMartin)?"true":"false")+
                  ", \"Use step by step\" = "+((InpStep)?"true":"false")+"!":
                  "Trade is prohibited: \"Use martingale\" = "+((InpMartin)?"true":"false")+
                  ", \"Use step by step\" = "+((InpStep)?"true":"false")+"!";
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
   if(InpStep)
     {
      err_text="";
      if(!CheckVolumeValue(InpStepLots,err_text))
        {
         Print(__FUNCTION__,", ERROR Step lots: ",err_text);
         return(INIT_PARAMETERS_INCORRECT);
        }
      err_text="";
      if(!CheckVolumeValue(InpStepLotsMax,err_text))
        {
         Print(__FUNCTION__,", ERROR Maximum lots: ",err_text);
         return(INIT_PARAMETERS_INCORRECT);
        }
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

   ExtStopLoss    = InpStopLoss     * m_adjusted_point;
   ExtTakeProfit  = InpTakeProfit   * m_adjusted_point;
   ExtTrailingStop= InpTrailingStop * m_adjusted_point;
   ExtTrailingStep= InpTrailingStep * m_adjusted_point;
//--- create handle of the indicator iCCI
   handle_iCCI=iCCI(m_symbol.Name(),Period(),Inp_ma_period,Inp_applied_price);
//--- if the handle is not created 
   if(handle_iCCI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iCCI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//---
   m_lots=InpLots;
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
   if(!IsPositionExists())
     {
      MqlDateTime STimeCurrent;
      TimeToStruct(TimeCurrent(),STimeCurrent);
      if(STimeCurrent.sec<40)
         return;
      //---
      double cci[];
      ArraySetAsSeries(cci,true);
      MqlRates rates[];
      ArraySetAsSeries(rates,true);

      if(iCCIGetArray(0,4,cci)) // get CCI values on bars: #0, #1, #2 and #3
         if(CopyRates(m_symbol.Name(),Period(),0,3,rates)==3) // get OHLC values on bars: #0, #1 and #2
           {
            //--- BUY
/* BUY
    #2       #1       #0
                     close
   open              |   |
   |||||             |   |
   |||||    open     open
   close    |||||   
            |||||
            close
*/
            if(cci[1]<5.0 && cci[2]<cci[3] && cci[1]<cci[2] && cci[0]>cci[1] &&
               rates[2].open>rates[2].close && rates[1].open>rates[1].close &&
               rates[0].open<rates[0].close && rates[1].open<rates[0].close)
              {
               if(!RefreshRates())
                  return;
               double sl=(InpStopLoss==0)?0.0:m_symbol.Ask()-ExtStopLoss;
               if(sl>=m_symbol.Bid()) // incident: the position isn't opened yet, and has to be already closed
                  return;

               double tp=(InpTakeProfit==0)?0.0:m_symbol.Ask()+ExtTakeProfit;
               OpenBuy(sl,tp);
              }
            //--- SELL
/* SELL
    #2       #1       #0
    
            close
            |   |    open
   close    |   |    |||||
   |   |    open     |||||
   |   |             close
   open      
*/
            if(cci[1]>-5 && cci[2]>cci[3] && cci[1]>cci[2] && cci[0]<cci[1] && 
               rates[2].open<rates[2].close && rates[1].open<rates[1].close  &&
               rates[0].open>rates[0].close && rates[1].open>rates[0].close)
              {
               if(!RefreshRates())
                  return;
               double sl=(InpStopLoss==0)?0.0:m_symbol.Bid()+ExtStopLoss;
               if(sl<=m_symbol.Ask()) // incident: the position isn't opened yet, and has to be already closed
                  return;

               double tp=(InpTakeProfit==0)?0.0:m_symbol.Bid()-ExtTakeProfit;
               OpenSell(sl,tp);
              }
           }
     }
//---
   Trailing();
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
         if(deal_type==DEAL_TYPE_BUY || deal_type==DEAL_TYPE_SELL)
            if(deal_entry==DEAL_ENTRY_OUT)
              {
               if(!InpMartin && !InpStep)
                 {
                  m_lots=InpLots;
                  return;
                 }
               //---
               if(deal_profit<0)
                  m_loss++;
               else
                  m_profit++;
               //---

               if(InpMartin)
                 {
/*       
InpMartinCoeff                = 1.51;           // Martingale coefficient
InpMartinOrdinalNumber        = 1;              // Ordinal number of the losing trade
InpMartinMaxMultiplications   = 3;              // Maximum number of multiplications
*/
                  if(deal_profit<0)
                    {
                     if(m_martin<=InpMartinMaxMultiplications)
                        if(m_loss>=InpMartinOrdinalNumber)
                          {
                           double lot_check=LotCheck(m_lots*InpMartinCoeff);
                           if(lot_check==0)
                              m_lots=InpLots;  // protection (just in case)
                           else
                              m_lots=lot_check;
                           m_martin++;
                           return;
                          }
                    }
                  else
                    {
                     m_lots   = InpLots;        // start lot
                     m_martin = 0;              // Maximum number of multiplications == "0"
                     m_loss   = 0;              // count loss == "0"
                     m_profit = 0;              // count profit == "0" (so that the counter does not overflow)
                    }
                 }

               if(InpStep)
                 {
/*
InpStepLots                   = 0.1;            // Step lots
InpStepLotsMax                = 1.5;            // Maximum lots
InpStepProfit                 = loss;           // Use step afte ...  
*/
                  if(InpStepProfit==loss)
                    {
                     if(deal_profit<0)
                       {
                        double lot_check=LotCheck(m_lots+InpStepLots);
                        if(lot_check==0.0)
                           m_lots=InpLots;     // protection (just in case)
                        if(lot_check<=InpStepLotsMax)
                           m_lots=InpLots;
                       }
                     else
                        m_lots=InpLots;
                    }
                  else // InpStepProfit==profit
                    {
                     if(deal_profit>=0)
                       {
                        double lot_check=LotCheck(m_lots+InpStepLots);
                        if(lot_check==0.0)
                           m_lots=InpLots;     // protection (just in case)
                        if(lot_check<=InpStepLotsMax)
                           m_lots=InpLots;
                       }
                     else
                        m_lots=InpLots;
                    }
                  //---
                  m_loss      = 0;              // count loss == "0" (so that the counter does not overflow)
                  m_profit    = 0;              // count profit == "0" (so that the counter does not overflow)
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
//| Get value of buffers for the iCCI array                          |
//+------------------------------------------------------------------+
double iCCIGetArray(const int start_pos,const int count,double &arr_buffer[])
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
//--- fill a part of the iCCI array with values from the indicator buffer
   int copied=CopyBuffer(handle_iCCI,0,start_pos,count,arr_buffer);
   if(copied!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iCCI indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
   return(result);
  }
//+------------------------------------------------------------------+
//| Is position exists                                               |
//+------------------------------------------------------------------+
bool IsPositionExists(void)
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            return(true);
//---
   return(false);
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
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),m_lots,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=m_lots)
        {
         if(m_trade.Buy(m_lots,m_symbol.Name(),m_symbol.Ask(),sl,tp))
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
               "< Lots (",DoubleToString(m_lots,2),")");
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
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),m_lots,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=m_lots)
        {
         if(m_trade.Sell(m_lots,m_symbol.Name(),m_symbol.Bid(),sl,tp))
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
               "< Lots (",DoubleToString(m_lots,2),")");
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

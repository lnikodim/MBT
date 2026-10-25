//+------------------------------------------------------------------+
//|                          AMA Trader(barabashkakvn's edition).mq5 |
//+------------------------------------------------------------------+
#property version   "1.000"
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
//--- input parameters
input double               InpLots                 = 0.1;         // Lots
input int                  Inp_RSI_ma_period       = 14;          // RSI: averaging period 
input ENUM_APPLIED_PRICE   Inp_RSI_applied_price   = PRICE_CLOSE; // RSI: type of price 
input int                  Inp_AMA_ama_period      = 9;           // AMA: average period  
input int                  Inp_AMA_fast_ma_period  = 2;           // AMA: fast MA period 
input int                  Inp_AMA_slow_ma_period  = 30;          // AMA: slow MA period 
input int                  Inp_AMA_ama_shift       = 0;           // AMA: horizontal shift of the indicator 
input ENUM_APPLIED_PRICE   Inp_AMA_applied_price   = PRICE_CLOSE; // AMA: type of the price 
//---
input double               Inp_RSI_level_up        = 70.0;        // RSI Level Up
input double               Inp_RSI_level_down      = 30.0;        // RSI Level Down
input uchar                InpStepLength           = 3;           // Step Length
input double               InpProfit               = 50.0;        // Profit limit for close all
input double               InpWithdrawal           = 1000.0;      // Withdrawal
input ulong    m_magic=248845656;// magic number
//---
ulong  m_slippage=10;            // slippage

int    handle_iRSI;              // variable for storing the handle of the iRSI indicator
int    handle_iAMA;              // variable for storing the handle of the iAMA indicator 

double m_adjusted_point;         // point value adjusted for 3 or 5 points

double m_balance=0.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   m_balance=m_account.Balance();
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
//--- create handle of the indicator iRSI
   handle_iRSI=iRSI(m_symbol.Name(),Period(),Inp_RSI_ma_period,Inp_RSI_applied_price);
//--- if the handle is not created 
   if(handle_iRSI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iAMA
   handle_iAMA=iAMA(m_symbol.Name(),Period(),Inp_AMA_ama_period,Inp_AMA_fast_ma_period,
                    Inp_AMA_slow_ma_period,Inp_AMA_ama_shift,Inp_AMA_applied_price);
//--- if the handle is not created 
   if(handle_iAMA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iAMA indicator for the symbol %s/%s, error code %d",
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
   if(ProfitAllPositions()>InpProfit)
      CloseAllPositions();
   if(m_account.Balance()-m_balance>InpWithdrawal)
     {
      CloseAllPositions();
      TesterWithdrawal(InpWithdrawal);
      m_balance=m_account.Balance();
     }
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(m_symbol.Name(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
//---
   if(!RefreshRates())
     {
      PrevBars=0;
      return;
     }
//---
   double ama=iAMAGet(0);
   if(m_symbol.Ask()>ama)
     {
      double rsi[];
      ArraySetAsSeries(rsi,true);
      int count=(InpStepLength==0)?1:InpStepLength;
      if(!iRSIGetArray(0,count,rsi))
         return;
      int size=ArraySize(rsi);
      for(int i=0;i<size;i++)
        {
         if(rsi[i]<Inp_RSI_level_down)
           {
            double profit_buy=0.0;
            double profit_sell=0.0;
            ProfitPositions(profit_buy,profit_sell);
            if(profit_buy<0.0)
               OpenBuy(0.0,0.0);
            OpenBuy(0.0,0.0);
            return;
           }
        }
     }
//---
   if(m_symbol.Bid()<ama)
     {
      double rsi[];
      ArraySetAsSeries(rsi,true);
      int count=(InpStepLength==0)?1:InpStepLength;
      if(!iRSIGetArray(0,count,rsi))
         return;
      int size=ArraySize(rsi);
      for(int i=0;i<size;i++)
        {
         if(rsi[i]>Inp_RSI_level_up)
           {
            double profit_buy=0.0;
            double profit_sell=0.0;
            ProfitPositions(profit_buy,profit_sell);
            if(profit_sell<0.0)
               OpenSell(0.0,0.0);
            OpenSell(0.0,0.0);
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
//| Get value of buffers for the iRSI in the array                   |
//+------------------------------------------------------------------+
bool iRSIGetArray(const int start_pos,const int count,double &arr_buffer[])
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
//| Get value of buffers for the iAMA                                |
//+------------------------------------------------------------------+
double iAMAGet(const int index)
  {
   double AMA[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iAMAarray with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iAMA,0,index,1,AMA)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iAMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(AMA[0]);
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
      CloseAllPositions();
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
      CloseAllPositions();
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
//| Profit positions                                                 |
//+------------------------------------------------------------------+
void  ProfitPositions(double &profit_buy,double &profit_sell)
  {
   profit_buy=0.0;
   profit_sell=0.0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            double profit=m_position.Commission()+m_position.Swap()+m_position.Profit();
            if(m_position.PositionType()==POSITION_TYPE_BUY)
               profit_buy+=profit;
            if(m_position.PositionType()==POSITION_TYPE_SELL)
               profit_sell+=profit;
           }
   Comment("Profit BUY ",DoubleToString(profit_buy,2),"\n",
           "Profit SELL ",DoubleToString(profit_sell,2));
//---
  }
//+------------------------------------------------------------------+
//| Profit all positions                                             |
//+------------------------------------------------------------------+
double  ProfitAllPositions()
  {
   double profit=0.0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            profit+=m_position.Commission()+m_position.Swap()+m_position.Profit();
//---
   return(profit);
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

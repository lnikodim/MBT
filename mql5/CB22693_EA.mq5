//+------------------------------------------------------------------+
//|                      Peceptron_Mult(barabashkakvn's edition).mq5 |
//+------------------------------------------------------------------+
#property version   "1.003"
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
CSymbolInfo    m_symbol_1;                   // symbol info object
CSymbolInfo    m_symbol_2;                   // symbol info object
CSymbolInfo    m_symbol_3;                   // symbol info object
CAccountInfo   m_account;                    // account info wrapper
CDealInfo      m_deal;                       // deals object
COrderInfo     m_order;                      // pending orders object
CMoneyFixedMargin *m_money;
//--- input parameters
input int      InpNumberLots_1   = 1.0;      // Number of minimum lots for Symbol #1
input int      InpNumberLots_2   = 1.0;      // Number of minimum lots for Symbol #2
input int      InpNumberLots_3   = 1.0;      // Number of minimum lots for Symbol #3
//---
input string   s1="EURUSD";                  // Symbol #1
input int      x1 = 100;
input int      x2 = 20;
input int      x3 = 60;
input int      x4 = 40;
input double   sl1 = 40;
input int      tp1 = 95;
input string   s2="GBPJPY";                  // Symbol #2
input int      x5 = 100;
input int      x6 = 20;
input int      x7 = 60;
input int      x8 = 40;
input double   sl2 = 40;
input int      tp2 = 95;
input string   s3="AUDNZD";                  // Symbol #3
input int      x9  = 100;
input int      x10 = 20;
input int      x11 = 60;
input int      x12 = 40;
input double   sl3 = 40;
input int      tp3 = 95;
//---
input ulong    m_magic=122665745;   // magic number
//---
ulong  m_slippage=10;               // slippage
int    handle_iAC_1;                // variable for storing the handle of the iAC indicator 
int    handle_iAC_2;                // variable for storing the handle of the iAC indicator 
int    handle_iAC_3;                // variable for storing the handle of the iAC indicator 
double m_adjusted_point_1;          // point value adjusted for 3 or 5 points
double m_adjusted_point_2;          // point value adjusted for 3 or 5 points
double m_adjusted_point_3;          // point value adjusted for 3 or 5 points
bool   m_use_1;
bool   m_use_2;
bool   m_use_3;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   m_use_1=m_symbol_1.Name(s1);  // sets symbol #1 name
   if(m_use_1)
      RefreshRates(m_symbol_2);

   m_use_2=m_symbol_2.Name(s2);  // sets symbol #2 name
   if(m_use_2)
      RefreshRates(m_symbol_2);

   m_use_3=m_symbol_3.Name(s3);  // sets symbol #3 name
   if(m_use_3)
      RefreshRates(m_symbol_3);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_use_1)
     {
      if(m_symbol_1.Digits()==3 || m_symbol_1.Digits()==5)
         digits_adjust=10;
      m_adjusted_point_1=m_symbol_1.Point()*digits_adjust;
     }

   digits_adjust=1;
   if(m_use_2)
     {
      if(m_symbol_2.Digits()==3 || m_symbol_2.Digits()==5)
         digits_adjust=10;
      m_adjusted_point_2=m_symbol_2.Point()*digits_adjust;
     }

   digits_adjust=1;
   if(m_use_3)
     {
      if(m_symbol_3.Digits()==3 || m_symbol_3.Digits()==5)
         digits_adjust=10;
      m_adjusted_point_3=m_symbol_3.Point()*digits_adjust;
     }
//--- create handle of the indicator iAC
   if(m_use_1)
     {
      handle_iAC_1=iAC(m_symbol_1.Name(),Period());
      //--- if the handle is not created 
      if(handle_iAC_1==INVALID_HANDLE)
        {
         //--- tell about the failure and output the error code 
         PrintFormat("Failed to create handle of the iAC indicator for the symbol %s/%s, error code %d",
                     m_symbol_1.Name(),
                     EnumToString(Period()),
                     GetLastError());
         //--- the indicator is stopped early 
         return(INIT_FAILED);
        }
     }
   if(m_use_2)
     {
      handle_iAC_2=iAC(m_symbol_2.Name(),Period());
      //--- if the handle is not created 
      if(handle_iAC_2==INVALID_HANDLE)
        {
         //--- tell about the failure and output the error code 
         PrintFormat("Failed to create handle of the iAC indicator for the symbol %s/%s, error code %d",
                     m_symbol_2.Name(),
                     EnumToString(Period()),
                     GetLastError());
         //--- the indicator is stopped early 
         return(INIT_FAILED);
        }
     }
   if(m_use_3)
     {
      handle_iAC_3=iAC(m_symbol_3.Name(),Period());
      //--- if the handle is not created 
      if(handle_iAC_3==INVALID_HANDLE)
        {
         //--- tell about the failure and output the error code 
         PrintFormat("Failed to create handle of the iAC indicator for the symbol %s/%s, error code %d",
                     m_symbol_3.Name(),
                     EnumToString(Period()),
                     GetLastError());
         //--- the indicator is stopped early 
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

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- we work only at the time of the birth of new bar
   static datetime PrevBars_1=0;
   static datetime PrevBars_2=0;
   static datetime PrevBars_3=0;
   datetime time_1=D'01.01.1970';
   if(m_use_1)
      time_1=iTime(m_symbol_1.Name(),Period(),0);

   datetime time_2=D'01.01.1970';
   if(m_use_2)
      time_2=iTime(m_symbol_2.Name(),Period(),0);

   datetime time_3=D'01.01.1970';
   if(m_use_3)
      time_3=iTime(m_symbol_3.Name(),Period(),0);

   if(((m_use_1 && time_1==PrevBars_1) || !m_use_1) &&
      ((m_use_2 && time_2==PrevBars_2) || !m_use_2) &&
      ((m_use_3 && time_3==PrevBars_3) || !m_use_3))
      return;
   PrevBars_1=time_1; PrevBars_2=time_2; PrevBars_3=time_3;

   int d=0;

   bool exists_1=false,exists_2=false,exists_3=false;
   IsPositionExists(exists_1,exists_2,exists_3);
//--- check symbol #1
   if(m_use_1 && !exists_1)
     {
      double ac_1_array[];
      ArraySetAsSeries(ac_1_array,true);
      int buffer=0,start_pos=0,count=22;
      if(!iGetArray(handle_iAC_1,buffer,start_pos,count,ac_1_array))
        {
         PrevBars_1=0; PrevBars_2=0; PrevBars_3=0; return;
        }
      double result=Perceptron(ac_1_array,x1,x2,x3,x4);
      double freeze_level,stop_level;
      //---
      if(!RefreshRates(m_symbol_1))
        {
         PrevBars_1=0; PrevBars_2=0; PrevBars_3=0; return;
        }
      freeze_level=m_symbol_1.FreezeLevel()*m_symbol_1.Point();
      if(freeze_level==0.0)
         freeze_level=(m_symbol_1.Ask()-m_symbol_1.Bid())*3.0;
      freeze_level*=1.1;

      stop_level=m_symbol_1.StopsLevel()*m_symbol_1.Point();
      if(stop_level==0.0)
         stop_level=(m_symbol_1.Ask()-m_symbol_1.Bid())*3.0;
      stop_level*=1.1;

      if(freeze_level<=0.0 || stop_level<=0.0)
        {
         PrevBars_1=0; PrevBars_2=0; PrevBars_3=0; return;
        }
      //---
      if(result>0)
        {
         //-- Buy
         double price=m_symbol_1.Ask();
         double sl=(sl1<=0)?0.0:price-sl1*m_adjusted_point_1;
         double tp=(tp1<=0)?0.0:price+tp1*m_adjusted_point_1;
         if(((sl!=0 && sl1*m_adjusted_point_1>=stop_level) || sl==0.0) &&
            ((tp!=0 && tp1*m_adjusted_point_1>=stop_level) || tp==0.0))
           {
            OpenBuy(m_symbol_1,InpNumberLots_1*m_symbol_1.LotsMin(),sl,tp);
           }
        }
      else  if(result<0)
        {
         //-- Sell
         double price=m_symbol_1.Bid();
         double sl=(sl1==0)?0.0:price+sl1*m_adjusted_point_1;
         double tp=(tp1==0)?0.0:price-tp1*m_adjusted_point_1;
         if(((sl!=0 && sl1*m_adjusted_point_1>=stop_level) || sl==0.0) &&
            ((tp!=0 && tp1*m_adjusted_point_1>=stop_level) || tp==0.0))
           {
            OpenSell(m_symbol_1,InpNumberLots_1*m_symbol_1.LotsMin(),sl,tp);
           }
        }
     }
//--- check symbol #2
   if(m_use_2 && !exists_2)
     {
      double ac_2_array[];
      ArraySetAsSeries(ac_2_array,true);
      int buffer=0,start_pos=0,count=22;
      if(!iGetArray(handle_iAC_2,buffer,start_pos,count,ac_2_array))
        {
         PrevBars_1=0; PrevBars_2=0; PrevBars_3=0; return;
        }
      double result=Perceptron(ac_2_array,x5,x6,x7,x8);
      double freeze_level,stop_level;
      //---
      if(!RefreshRates(m_symbol_2))
        {
         PrevBars_1=0; PrevBars_2=0; PrevBars_3=0; return;
        }
      freeze_level=m_symbol_2.FreezeLevel()*m_symbol_2.Point();
      if(freeze_level==0.0)
         freeze_level=(m_symbol_2.Ask()-m_symbol_2.Bid())*3.0;
      freeze_level*=1.1;

      stop_level=m_symbol_2.StopsLevel()*m_symbol_2.Point();
      if(stop_level==0.0)
         stop_level=(m_symbol_2.Ask()-m_symbol_2.Bid())*3.0;
      stop_level*=1.1;

      if(freeze_level<=0.0 || stop_level<=0.0)
        {
         PrevBars_1=0; PrevBars_2=0; PrevBars_3=0; return;
        }
      //---
      if(result>0)
        {
         //-- Buy
         double price=m_symbol_2.Ask();
         double sl=(sl2<=0)?0.0:price-sl2*m_adjusted_point_2;
         double tp=(tp2<=0)?0.0:price+tp2*m_adjusted_point_2;
         if(((sl!=0 && sl2*m_adjusted_point_2>=stop_level) || sl==0.0) &&
            ((tp!=0 && tp2*m_adjusted_point_2>=stop_level) || tp==0.0))
           {
            OpenBuy(m_symbol_2,InpNumberLots_2*m_symbol_2.LotsMin(),sl,tp);
           }
        }
      else  if(result<0)
        {
         //-- Sell
         double price=m_symbol_2.Bid();
         double sl=(sl2==0)?0.0:price+sl2*m_adjusted_point_2;
         double tp=(tp2==0)?0.0:price-tp2*m_adjusted_point_2;
         if(((sl!=0 && sl2*m_adjusted_point_2>=stop_level) || sl==0.0) &&
            ((tp!=0 && tp2*m_adjusted_point_2>=stop_level) || tp==0.0))
           {
            OpenSell(m_symbol_2,InpNumberLots_2*m_symbol_2.LotsMin(),sl,tp);
           }
        }
     }
//--- check symbol #3
   if(m_use_3 && !exists_3)
     {
      double ac_3_array[];
      ArraySetAsSeries(ac_3_array,true);
      int buffer=0,start_pos=0,count=22;
      if(!iGetArray(handle_iAC_3,buffer,start_pos,count,ac_3_array))
        {
         PrevBars_1=0; PrevBars_2=0; PrevBars_3=0; return;
        }
      double result=Perceptron(ac_3_array,x9,x10,x11,x12);
      double freeze_level,stop_level;
      //---
      if(!RefreshRates(m_symbol_3))
        {
         PrevBars_1=0; PrevBars_2=0; PrevBars_3=0; return;
        }
      freeze_level=m_symbol_3.FreezeLevel()*m_symbol_3.Point();
      if(freeze_level==0.0)
         freeze_level=(m_symbol_3.Ask()-m_symbol_3.Bid())*3.0;
      freeze_level*=1.1;

      stop_level=m_symbol_3.StopsLevel()*m_symbol_3.Point();
      if(stop_level==0.0)
         stop_level=(m_symbol_3.Ask()-m_symbol_3.Bid())*3.0;
      stop_level*=1.1;

      if(freeze_level<=0.0 || stop_level<=0.0)
        {
         PrevBars_1=0; PrevBars_2=0; PrevBars_3=0; return;
        }
      //---
      if(result>0)
        {
         //-- Buy
         double price=m_symbol_3.Ask();
         double sl=(sl3<=0)?0.0:price-sl3*m_adjusted_point_3;
         double tp=(tp3<=0)?0.0:price+tp3*m_adjusted_point_3;
         if(((sl!=0 && sl3*m_adjusted_point_3>=stop_level) || sl==0.0) &&
            ((tp!=0 && tp3*m_adjusted_point_3>=stop_level) || tp==0.0))
           {
            OpenBuy(m_symbol_3,InpNumberLots_3*m_symbol_3.LotsMin(),sl,tp);
           }
        }
      else  if(result<0)
        {
         //-- Sell
         double price=m_symbol_3.Bid();
         double sl=(sl3==0)?0.0:price+sl3*m_adjusted_point_3;
         double tp=(tp3==0)?0.0:price-tp3*m_adjusted_point_3;
         if(((sl!=0 && sl3*m_adjusted_point_3>=stop_level) || sl==0.0) &&
            ((tp!=0 && tp3*m_adjusted_point_3>=stop_level) || tp==0.0))
           {
            OpenSell(m_symbol_3,InpNumberLots_3*m_symbol_3.LotsMin(),sl,tp);
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
bool RefreshRates(CSymbolInfo &m_symbol)
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
//| Is position exists                                               |
//+------------------------------------------------------------------+
void IsPositionExists(bool &exists_1,bool &exists_2,bool &exists_3)
  {
   exists_1=false;
   exists_2=false;
   exists_3=false;
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
        {
         if(m_use_1 && m_position.Symbol()==m_symbol_1.Name() && m_position.Magic()==m_magic)
           {
            exists_1=true;
            continue;
           }
         if(m_use_2 && m_position.Symbol()==m_symbol_2.Name() && m_position.Magic()==m_magic)
           {
            exists_2=true;
            continue;
           }
         if(m_use_3 && m_position.Symbol()==m_symbol_3.Name() && m_position.Magic()==m_magic)
           {
            exists_3=true;
            continue;
           }
        }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Get value of buffers                                             |
//+------------------------------------------------------------------+
double iGetArray(const int handle,const int buffer,const int start_pos,const int count,double &arr_buffer[])
  {
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
      Print("This a no dynamic array!");
      return(false);
     }
   ArrayFree(arr_buffer);
//--- reset error code 
   ResetLastError();
//--- fill a part of the iBands array with values from the indicator buffer
   int copied=CopyBuffer(handle,buffer,start_pos,count,arr_buffer);
   if(copied!=count)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
   return(result);
  }
//+------------------------------------------------------------------+
//| Perceptron                                                       |
//+------------------------------------------------------------------+
double Perceptron(double &array[],int y1,int y2,int y3,int y4)
  {
   double w1 = y1 - 100;
   double w2 = y2 - 100;
   double w3 = y3 - 100;
   double w4 = y4 - 100;
   double a1 = array[0];
   double a2 = array[7];
   double a3 = array[14];
   double a4 = array[21];
   return(w1 * a1 + w2 * a2 + w3 * a3 + w4 * a4);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(CSymbolInfo &m_symbol,double lot,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double long_lot=lot;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check= m_account.FreeMarginCheck(m_symbol.Name(),ORDER_TYPE_BUY,long_lot,m_symbol.Ask());
   double margin_check     = m_account.MarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,long_lot,m_symbol.Bid());
   if(free_margin_check>margin_check)
     {
      if(m_trade.Buy(long_lot,m_symbol.Name(),m_symbol.Ask(),sl,tp))
        {
         if(m_trade.ResultDeal()==0)
           {
            Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
         else
           {
            Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of result: ",m_trade.ResultRetcodeDescription());
         PrintResultTrade(m_trade,m_symbol);
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CAccountInfo::FreeMarginCheck returned the value ",DoubleToString(free_margin_check,2));
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(CSymbolInfo &m_symbol,double lot,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);

   double short_lot=lot;
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double free_margin_check= m_account.FreeMarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,short_lot,m_symbol.Bid());
   double margin_check     = m_account.MarginCheck(m_symbol.Name(),ORDER_TYPE_SELL,short_lot,m_symbol.Bid());
   if(free_margin_check>margin_check)
     {
      if(m_trade.Sell(short_lot,m_symbol.Name(),m_symbol.Bid(),sl,tp))
        {
         if(m_trade.ResultDeal()==0)
           {
            Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
         else
           {
            Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
           }
        }
      else
        {
         Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of result: ",m_trade.ResultRetcodeDescription());
         PrintResultTrade(m_trade,m_symbol);
        }
     }
   else
     {
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

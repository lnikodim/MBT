//+------------------------------------------------------------------+
//|                                                      CCFp EA.mq5 |
//|                                       Copyright © 2010,Lexandros |
//|                                              lexandros@yandex.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009,Lexandros"
#property link      "lexandros@yandex.ru"
#property version   "1.001"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
//--- input parameters
input double   InpLots           = 0.1;      // Lots
input ushort   InpStopLoss       = 500;      // Stop Loss
input ushort   InpTakeProfit     = 500;      // Take Profit
input ushort   InpTrailingStop   = 50;       // Trailing Stop 
input ushort   InpTrailingStep   = 50;       // Trailing Step
input double   InpStep           = 0.0001;   // Step
input bool     InpCloseOpposite  = true;     // Close opposite positions
input ulong    m_magic           = 10965350; // magic number
//---

double ccfp[8,2],ccfp_old[8,2],cc[8,2],cc_old[8,2];
int cnt,n,x,y;
string day,ArrayVal[8]={"USD","EUR","GBP","CHF","JPY","AUD","CAD","NZD"};
//---
int            handle_iCustom;               // variable for storing the handle of the iCustom indicator 

double         m_adjusted_point;             // point value adjusted for 3 or 5 points
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpTrailingStop!=0 && InpTrailingStep==0)
     {
      string text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                  "Трейлинг невозможен: параметр \"Trailing Step\" равен нулю!":
                  "Trailing is not possible: parameter \"Trailing Step\" is zero!";
      Alert(__FUNCTION__," ERROR! ",text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   m_trade.SetExpertMagicNumber(m_magic);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(Symbol());
//--- create handle of the indicator iCustom
   handle_iCustom=iCustom(m_symbol.Name(),Period(),"CCFp");
//--- if the handle is not created 
   if(handle_iCustom==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iCustom indicator for the symbol %s/%s, error code %d",
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
   datetime time_0=iTime(Symbol(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;

   int bars_calculated=BarsCalculated(handle_iCustom);
//Print("BarsCalculated: ",bars_calculated);
   if(bars_calculated==-1 || bars_calculated!=Bars(Symbol(),Period()))
      PrevBars=0;
//--- Заполнение массива данными индикатора CCFp
   for(cnt=0;cnt<8;cnt++)
     {
      ccfp [cnt,1]=iCustomGet(handle_iCustom,cnt,1);
      ccfp [cnt,0]=cnt+1;
      ccfp_old [cnt,1]=iCustomGet(handle_iCustom,cnt,2);
      ccfp_old [cnt,0]=cnt+1;
     }
//--- Проверка сигнала
   for(x=0;x<8;x++)
     {
      for(y=0;y<8;y++)
        {
         double x_0=ccfp[x,0];
         double y_0=ccfp[y,0];
         if(ccfp[x,0]==ccfp[y,0])
            continue;
         if(ccfp[x,1]-ccfp[y,1]>InpStep && 
            ccfp_old[x,1]-ccfp_old[y,1]<=InpStep && 
            ccfp[x,1]>ccfp_old[x,1] && ccfp[y,1]<ccfp_old[y,1])
           {
            oper_up((int)ccfp[x,0],(int)ccfp[y,0]);
           }
        }
     }
//---
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
//| Get value of buffers for the iCustom                             |
//|  the buffer numbers are the following:                           |
//+------------------------------------------------------------------+
double iCustomGet(int handle,const int buffer,const int index)
  {
   double Custom[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iCustom array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle,buffer,index,1,Custom)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iCustom indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Custom[0]);
  }
//+------------------------------------------------------------------+
//| Открытие/закрытие позиций                                        |
//|  top    номер валюты идущией вверх                               |
//|  down   номер валюты идущей вниз                                 |
//+------------------------------------------------------------------+
void oper_up(int top,int down)
  {
   ENUM_POSITION_TYPE op1=WRONG_VALUE,op2=WRONG_VALUE;
   int no_open1=0,no_open2=0;
   string sym1="",sym2="",comment="";
   double price=0.0,st=0.0,pr=0.0;

   StringConcatenate(comment,"(",ArrayVal[top-1],ArrayVal[down-1],")");
//--- USD
   if(top==1)
     {
      if(down==2){ sym1="EURUSD"; op1=POSITION_TYPE_SELL;}
      if(down==3){ sym1="GBPUSD"; op1=POSITION_TYPE_SELL;}
      if(down==4){ sym1="USDCHF"; op1=POSITION_TYPE_BUY;}
      if(down==5){ sym1="USDJPY"; op1=POSITION_TYPE_BUY;}
      if(down==6){ sym1="AUDUSD"; op1=POSITION_TYPE_SELL;}
      if(down==7){ sym1="USDCAD"; op1=POSITION_TYPE_BUY;}
      if(down==8){ sym1="NZDUSD"; op1=POSITION_TYPE_SELL;}
     }
//--- EUR
   if(top==2)
     {
      if(down==1){ if(ccfp[1,1]>ccfp[0,1]) {sym1="EURUSD";op1=POSITION_TYPE_BUY;}}
      if(down==3){ if(ccfp[1,1]>ccfp[0,1]) {sym1="EURUSD";op1=POSITION_TYPE_BUY;} if(ccfp[2,1]<ccfp[0,1]){sym2="GPBUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==4){ if(ccfp[1,1]>ccfp[0,1]) {sym1="EURUSD";op1=POSITION_TYPE_BUY;} if(ccfp[0,1]>ccfp[2,1]){sym2="USDCHF"; op2=POSITION_TYPE_BUY;}}
      if(down==5){ if(ccfp[1,1]>ccfp[0,1]) {sym1="EURUSD";op1=POSITION_TYPE_BUY;} if(ccfp[0,1]>ccfp[4,1]){sym2="USDJPY"; op2=POSITION_TYPE_BUY;}}
      if(down==6){ if(ccfp[1,1]>ccfp[0,1]) {sym1="EURUSD";op1=POSITION_TYPE_BUY;} if(ccfp[5,1]<ccfp[0,1]){sym2="AUDUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==7){ if(ccfp[1,1]>ccfp[0,1]) {sym1="EURUSD";op1=POSITION_TYPE_BUY;} if(ccfp[0,1]>ccfp[6,1]){sym2="USDCAD"; op2=POSITION_TYPE_BUY;}}
      if(down==8){ if(ccfp[1,1]>ccfp[0,1]) {sym1="EURUSD";op1=POSITION_TYPE_BUY;} if(ccfp[7,1]<ccfp[0,1]){sym2="NZDUSD"; op2=POSITION_TYPE_SELL;}}
     }
//--- GBP
   if(top==3)
     {
      if(down==1){ if(ccfp[2,1]>ccfp[0,1]) {sym1="GBPUSD"; op1=POSITION_TYPE_BUY;}}
      if(down==2){ if(ccfp[2,1]>ccfp[0,1]) {sym1="GBPUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[1,1]<ccfp[0,1]){sym2="EURUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==4){ if(ccfp[2,1]>ccfp[0,1]) {sym1="GBPUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[0,1]>ccfp[3,1]){sym2="USDCHF"; op2=POSITION_TYPE_BUY;}}
      if(down==5){ if(ccfp[2,1]>ccfp[0,1]) {sym1="GBPUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[0,1]>ccfp[4,1]){sym2="USDJPY"; op2=POSITION_TYPE_BUY;}}
      if(down==6){ if(ccfp[2,1]>ccfp[0,1]) {sym1="GBPUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[5,1]<ccfp[0,1]){sym2="AUDUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==7){ if(ccfp[2,1]>ccfp[0,1]) {sym1="GBPUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[0,1]>ccfp[6,1]){sym2="USDCAD"; op2=POSITION_TYPE_BUY;}}
      if(down==8){ if(ccfp[2,1]>ccfp[0,1]) {sym1="GBPUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[7,1]<ccfp[0,1]){sym2="NZDUSD"; op2=POSITION_TYPE_SELL;}}
     }
//--- CHF
   if(top==4)
     {
      if(down==1){ if(ccfp[0,1]<ccfp[3,1]) {sym1="USDCHF"; op1=POSITION_TYPE_SELL;}}
      if(down==2){ if(ccfp[0,1]<ccfp[3,1]) {sym1="USDCHF"; op1=POSITION_TYPE_SELL;} if(ccfp[1,1]<ccfp[0,1]){sym2="EURUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==3){ if(ccfp[0,1]<ccfp[3,1]) {sym1="USDCHF"; op1=POSITION_TYPE_SELL;} if(ccfp[2,1]<ccfp[0,1]){sym2="GBPUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==5){ if(ccfp[0,1]<ccfp[3,1]) {sym1="USDCHF"; op1=POSITION_TYPE_SELL;} if(ccfp[0,1]>ccfp[4,1]){sym2="USDJPY"; op2=POSITION_TYPE_BUY;}}
      if(down==6){ if(ccfp[0,1]<ccfp[3,1]) {sym1="USDCHF"; op1=POSITION_TYPE_SELL;} if(ccfp[5,1]<ccfp[0,1]){sym2="AUDUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==7){ if(ccfp[0,1]<ccfp[3,1]) {sym1="USDCHF"; op1=POSITION_TYPE_SELL;} if(ccfp[0,1]>ccfp[6,1]){sym2="USDCAD"; op2=POSITION_TYPE_BUY;}}
      if(down==8){ if(ccfp[0,1]<ccfp[3,1]) {sym1="USDCHF"; op1=POSITION_TYPE_SELL;} if(ccfp[7,1]<ccfp[0,1]){sym2="NZDUSD"; op2=POSITION_TYPE_SELL;}}
     }
//--- JPY
   if(top==5)
     {
      if(down==1){ if(ccfp[0,1]<ccfp[4,1]) {sym1="USDJPY"; op1=POSITION_TYPE_SELL;}}
      if(down==2){ if(ccfp[0,1]<ccfp[4,1]) {sym1="USDJPY"; op1=POSITION_TYPE_SELL;} if(ccfp[1,1]<ccfp[0,1]){sym2="EURUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==3){ if(ccfp[0,1]<ccfp[4,1]) {sym1="USDJPY"; op1=POSITION_TYPE_SELL;} if(ccfp[2,1]<ccfp[0,1]){sym2="GBPUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==4){ if(ccfp[0,1]<ccfp[4,1]) {sym1="USDJPY"; op1=POSITION_TYPE_SELL;} if(ccfp[0,1]>ccfp[3,1]){sym2="USDCHF"; op2=POSITION_TYPE_BUY;}}
      if(down==6){ if(ccfp[0,1]<ccfp[4,1]) {sym1="USDJPY"; op1=POSITION_TYPE_SELL;} if(ccfp[5,1]<ccfp[0,1]){sym2="AUDUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==7){ if(ccfp[0,1]<ccfp[4,1]) {sym1="USDJPY"; op1=POSITION_TYPE_SELL;} if(ccfp[0,1]>ccfp[6,1]){sym2="USDCAD"; op2=POSITION_TYPE_BUY;}}
      if(down==8){ if(ccfp[0,1]<ccfp[4,1]) {sym1="USDJPY"; op1=POSITION_TYPE_SELL;} if(ccfp[7,1]<ccfp[0,1]){sym2="NZDUSD"; op2=POSITION_TYPE_SELL;}}
     }
//--- AUD
   if(top==6)
     {
      if(down==1){ if(ccfp[5,1]>ccfp[0,1]) {sym1="AUDUSD"; op1=POSITION_TYPE_BUY;}}
      if(down==2){ if(ccfp[5,1]>ccfp[0,1]) {sym1="AUDUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[1,1]<ccfp[0,1]){sym2="EURUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==3){ if(ccfp[5,1]>ccfp[0,1]) {sym1="AUDUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[2,1]<ccfp[0,1]){sym2="GBPUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==4){ if(ccfp[5,1]>ccfp[0,1]) {sym1="AUDUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[0,1]>ccfp[3,1]){sym2="USDCHF"; op2=POSITION_TYPE_BUY;}}
      if(down==5){ if(ccfp[5,1]>ccfp[0,1]) {sym1="AUDUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[0,1]>ccfp[4,1]){sym2="USDJPY"; op2=POSITION_TYPE_BUY;}}
      if(down==7){ if(ccfp[5,1]>ccfp[0,1]) {sym1="AUDUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[0,1]>ccfp[6,1]){sym2="USDCAD"; op2=POSITION_TYPE_BUY;}}
      if(down==8){ if(ccfp[5,1]>ccfp[0,1]) {sym1="AUDUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[7,1]<ccfp[0,1]){sym2="NZDUSD"; op2=POSITION_TYPE_SELL;}}
     }
//--- CAD
   if(top==7)
     {
      if(down==1){ if(ccfp[0,1]<ccfp[6,1]) {sym1="USDCAD"; op1=POSITION_TYPE_SELL;}}
      if(down==2){ if(ccfp[0,1]<ccfp[6,1]) {sym1="USDCAD"; op1=POSITION_TYPE_SELL;} if(ccfp[1,1]<ccfp[0,1]){sym2="EURUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==3){ if(ccfp[0,1]<ccfp[6,1]) {sym1="USDCAD"; op1=POSITION_TYPE_SELL;} if(ccfp[2,1]<ccfp[0,1]){sym2="GBPUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==4){ if(ccfp[0,1]<ccfp[6,1]) {sym1="USDCAD"; op1=POSITION_TYPE_SELL;} if(ccfp[0,1]>ccfp[3,1]){sym2="USDCHF"; op2=POSITION_TYPE_BUY;}}
      if(down==5){ if(ccfp[0,1]<ccfp[6,1]) {sym1="USDCAD"; op1=POSITION_TYPE_SELL;} if(ccfp[0,1]>ccfp[4,1]){sym2="USDJPY"; op2=POSITION_TYPE_BUY;}}
      if(down==6){ if(ccfp[0,1]<ccfp[6,1]) {sym1="USDCAD"; op1=POSITION_TYPE_SELL;} if(ccfp[5,1]<ccfp[0,1]){sym2="AUDUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==8){ if(ccfp[0,1]<ccfp[6,1]) {sym1="USDCAD"; op1=POSITION_TYPE_SELL;} if(ccfp[7,1]<ccfp[0,1]){sym2="NZDUSD"; op2=POSITION_TYPE_SELL;}}
     }
//--- NZD
   if(top==8)
     {
      if(down==1){ if(ccfp[7,1]>ccfp[0,1]) {sym1="NZDUSD"; op1=POSITION_TYPE_BUY;}}
      if(down==2){ if(ccfp[7,1]>ccfp[0,1]) {sym1="NZDUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[1,1]<ccfp[0,1]){sym2="EURUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==3){ if(ccfp[7,1]>ccfp[0,1]) {sym1="NZDUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[2,1]<ccfp[0,1]){sym2="GBPUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==4){ if(ccfp[7,1]>ccfp[0,1]) {sym1="NZDUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[0,1]>ccfp[3,1]){sym2="USDCHF"; op2=POSITION_TYPE_BUY;}}
      if(down==5){ if(ccfp[7,1]>ccfp[0,1]) {sym1="NZDUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[0,1]>ccfp[4,1]){sym2="USDJPY"; op2=POSITION_TYPE_BUY;}}
      if(down==6){ if(ccfp[7,1]>ccfp[0,1]) {sym1="NZDUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[5,1]<ccfp[0,1]){sym2="AUDUSD"; op2=POSITION_TYPE_SELL;}}
      if(down==7){ if(ccfp[7,1]>ccfp[0,1]) {sym1="NZDUSD"; op1=POSITION_TYPE_BUY;} if(ccfp[0,1]>ccfp[6,1]){sym2="USDCAD"; op2=POSITION_TYPE_BUY;}}
     }
//---
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==m_magic && m_position.Comment()==comment)
           {
            if(m_position.Symbol()==sym1 && m_position.PositionType()==op1)
               sym1="";

            if(m_position.Symbol()==sym2 && m_position.PositionType()==op2)
               sym2="";
           }
   if(sym1=="" && sym2=="")
      return;
//--- закрываем позиции, если "Close opposite positions" == true
   if(InpCloseOpposite)
      for(int i=PositionsTotal()-1;i>=0;i--)
         if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
            if(m_position.Magic()==m_magic)
              {
               if(sym1!="")
                 {
                  if(m_position.Symbol()==sym1 && m_position.PositionType()!=op1)
                    {
                     Print("Противоположное закрытие ",m_position.Symbol(),
                           " ",EnumToString(m_position.PositionType())," ",comment);
                     m_trade.PositionClose(m_position.Ticket());
                    }
                 }
               if(sym2!="")
                 {
                  if(m_position.Symbol()==sym2 && m_position.PositionType()!=op2)
                    {
                     Print("Противоположное закрытие ",m_position.Symbol(),
                           " ",EnumToString(m_position.PositionType())," ",comment);
                     m_trade.PositionClose(m_position.Ticket());
                    }
                 }
              }
//--- открываем позиции
   if(sym1!="")
     {
      MqlTick tick;
      double point=0.0;
      long stops_level=0;
      long spread=0;
      if(SymbolInfoTick(sym1,tick) && SymbolInfoDouble(sym1,SYMBOL_POINT,point) && 
         SymbolInfoInteger(sym1,SYMBOL_TRADE_STOPS_LEVEL,stops_level) && 
         SymbolInfoInteger(sym1,SYMBOL_SPREAD,spread))
        {
         if(stops_level>0)
           {
            if(InpStopLoss>0 && InpStopLoss<stops_level)
              {
               Print("Стоп-лосс (",InpStopLoss,") по инструменту ",sym1," меньше разрешенного ДЦ (",stops_level,")!!!");
               no_open1=1;
              }
            if(InpTakeProfit>0 && InpTakeProfit<stops_level)
              {
               Print("Тейк-профит (",InpTakeProfit,") по инструменту ",sym1," меньше разрешенного ДЦ (",stops_level,")!!!");
               no_open1=1;
              }
           }
         else if(stops_level==0)
           {
            if(InpStopLoss>0 && InpStopLoss<spread*3)
              {
               Print("Стоп-лосс (",InpStopLoss,") по инструменту ",sym1," меньше разрешенного ДЦ (",spread*3,")!!!");
               no_open1=1;
              }
            if(InpTakeProfit>0 && InpTakeProfit<spread*3)
              {
               Print("Тейк-профит (",InpTakeProfit,") по инструменту ",sym1," меньше разрешенного ДЦ (",spread*3,")!!!");
               no_open1=1;
              }
           }
         if(no_open1==0)
           {
            if(op1==POSITION_TYPE_BUY)
              {
               price=tick.ask;
               st=(InpStopLoss==0)?0.0:price-InpStopLoss*point;
               pr=(InpTakeProfit==0)?0.0:price+InpTakeProfit*point;
               Print("Открываем ",sym1," ",EnumToString(op1)," ",comment);
               m_trade.Buy(InpLots,sym1,price,st,pr,comment);
              }
            if(op1==POSITION_TYPE_SELL)
              {
               price=tick.bid;
               st=(InpStopLoss==0)?0.0:price+InpStopLoss*point;
               pr=(InpTakeProfit==0)?0.0:price-InpTakeProfit*point;
               Print("Открываем ",sym1," ",EnumToString(op1)," ",comment);
               m_trade.Sell(InpLots,sym1,price,st,pr,comment);
              }
           }
        }
     }
   if(sym2!="")
     {
      MqlTick tick;
      double point=0.0;
      long stops_level=0;
      long spread=0;
      if(SymbolInfoTick(sym2,tick) && SymbolInfoDouble(sym2,SYMBOL_POINT,point) && 
         SymbolInfoInteger(sym2,SYMBOL_TRADE_STOPS_LEVEL,stops_level) && 
         SymbolInfoInteger(sym2,SYMBOL_SPREAD,spread))
        {
         if(stops_level>0)
           {
            if(InpStopLoss>0 && InpStopLoss<stops_level)
              {
               Print("Стоп-лосс (",InpStopLoss,") по инструменту ",sym2," меньше разрешенного ДЦ (",stops_level,")!!!");
               no_open2=1;
              }
            if(InpTakeProfit>0 && InpTakeProfit<stops_level)
              {
               Print("Тейк-профит (",InpTakeProfit,") по инструменту ",sym2," меньше разрешенного ДЦ (",stops_level,")!!!");
               no_open2=1;
              }
           }
         else if(stops_level==0)
           {
            if(InpStopLoss>0 && InpStopLoss<spread*3)
              {
               Print("Стоп-лосс (",InpStopLoss,") по инструменту ",sym2," меньше разрешенного ДЦ (",spread*3,")!!!");
               no_open2=1;
              }
            if(InpTakeProfit>0 && InpTakeProfit<spread*3)
              {
               Print("Тейк-профит (",InpTakeProfit,") по инструменту ",sym2," меньше разрешенного ДЦ (",spread*3,")!!!");
               no_open2=1;
              }
           }
         if(no_open2==0)
           {
            if(op1==POSITION_TYPE_BUY)
              {
               price=tick.ask;
               st=(InpStopLoss==0)?0.0:price-InpStopLoss*point;
               pr=(InpTakeProfit==0)?0.0:price+InpTakeProfit*point;
               Print("Открываем ",sym2," ",EnumToString(op1)," ",comment);
               m_trade.Buy(InpLots,sym2,price,st,pr,comment);
              }
            if(op1==POSITION_TYPE_SELL)
              {
               price=tick.bid;
               st=(InpStopLoss==0)?0.0:price+InpStopLoss*point;
               pr=(InpTakeProfit==0)?0.0:price-InpTakeProfit*point;
               Print("Открываем ",sym2," ",EnumToString(op1)," ",comment);
               m_trade.Sell(InpLots,sym2,price,st,pr,comment);
              }
           }
        }
     }
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
         if(m_position.Magic()==m_magic)
           {
            if(!m_symbol.Name(m_position.Symbol())) // sets symbol name
               continue;
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.PriceCurrent()-m_position.PriceOpen()>(InpTrailingStop*m_symbol.Point()+InpTrailingStep*m_symbol.Point()))
                  if(m_position.StopLoss()<m_position.PriceCurrent()-(InpTrailingStop*m_symbol.Point()+InpTrailingStep*m_symbol.Point()))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()-InpTrailingStop*m_symbol.Point()),
                        m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                     continue;
                    }
              }
            else
              {
               if(m_position.PriceOpen()-m_position.PriceCurrent()>InpTrailingStop*m_symbol.Point()+InpTrailingStep*m_symbol.Point())
                  if((m_position.StopLoss()>(m_position.PriceCurrent()+(InpTrailingStop*m_symbol.Point()+InpTrailingStep*m_symbol.Point()))) || 
                     (m_position.StopLoss()==0))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()+InpTrailingStop*m_symbol.Point()),
                        m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
              }
           }
  }
//+------------------------------------------------------------------+

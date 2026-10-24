//+------------------------------------------------------------------+
//|                                                  yy_cross_ma.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                             https://it-yy.site/  |
//|                                                eurweb@gmail.com  |
//+------------------------------------------------------------------+
#property copyright "eurweb@gmail.com copyright 2024"
#property link      "https://it-yy.site"
#property version   "1.22"
#property description "the intersection of 2 averages as a signal"
#property description ""
#property description "WARNING: Use this software at your own risk."

#define MAGIC 1234

#include <Trade\Trade.mqh>
CTrade ExtTrade;



input group  "Настройки"
input double      lotStart                   = 0.01; //Стартовый лот
input double      lotMax                     = 0.1;  //Максимальный лот
input int         ext_profit_ptk             = 300;// T.P.
input int         ext_sl_ptk                 = 0;// S.L.
input string      commnt                     = "it-yy.site";//комментарий к ордеру

input group  "+ Настройки MA+"
input int    fast_ma_period = 72;  // Moving Average period fastMA 
input int    slow_ma_period = 150;// Moving Average period slowMA
input ENUM_APPLIED_PRICE ma_applied_price = PRICE_CLOSE;
input int    ma_shift       = 0;  // Moving Average shift
//input ma_bar ma_bar_set = b1b0;



//// generel settings

double STOPLEVEL;
double LOTSTEP   = 0.0;
int    LOTDIGITS = 2;
double LOTMIN    = 0.01;
double LOTMAX    = 1;

/// sys vars 

bool   ExtHedging=false;
ENUM_ACCOUNT_TRADE_MODE account_type;

int    maFastHandle = 0;
int    maSlowHandle = 0;

double Ask = 0.0;
double Bid = 0.0;

int file_handle = 0;
string error_msg;
string info_msg;
bool  is_log = true;
string  infos = " ";


//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{

    if (isNewBar() == false)
        return;
     
   ENUM_ORDER_TYPE signal = checkCrossMa();
    
   myOrderSend(signal);
 }
 
 
 
//+------------------------------------------------------------------+
//|  myOrderSend                                                     |
//+------------------------------------------------------------------+
int myOrderSend( ENUM_ORDER_TYPE ordertype)
{

   if(ordertype != ORDER_TYPE_BUY && ordertype != ORDER_TYPE_SELL) return -1;
 
   ExtTrade.SetExpertMagicNumber(MAGIC);      
   double price = getOrderPrice(ordertype);
   double tp    = getOrderTakeprofit(ordertype);
   double sl    = getOrderStopLoss(ordertype);
   double lot = getOrderLot(ordertype);
   if (lot < LOTMIN) return -1;
   
   if (ExtTrade.PositionOpen(_Symbol, ordertype, lot, price, sl, tp, commnt))
   {
      if(ExtTrade.ResultDeal() < 1)
      {
          Print("#ERROR PositionOpen false. Result Retcode: ",ExtTrade.ResultRetcode(),", description of result: ",ExtTrade.ResultRetcodeDescription(), " lot ", lot);
      }
      else
      {
         //string type  = EnumToString(ENUM_ORDER_TYPE(ordertype));
         //if (file_handle)
         //FileWriteString(file_handle,TimeCurrent() + " Open #"+ Trade.ResultDeal() +" "+ type + " " +price+"/"+lotvolume+" \r\n");
      }
   }
   else
   {  
      Print("#ERROR PositionOpen false. Result Retcode: ",ExtTrade.ResultRetcode(),", description of result: ",ExtTrade.ResultRetcodeDescription());
   }
   return 1;

}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getOrderLot(ENUM_ORDER_TYPE type)
{
   double tradeLot = lotStart;
   
   tradeLot = checkOrderLot(type, tradeLot);
   
   return(tradeLot);
}



double checkOrderLot(ENUM_ORDER_TYPE type, double lot)
{
   double price = 0, n_margin;
   if (type == ORDER_TYPE_BUY)  price = Ask;
   if (type == ORDER_TYPE_SELL) price = Bid;
   
   if (lot > lotMax) lot = lotMax;
   if (lot > LOTMAX) lot = LOTMAX;
   if (lot < LOTMIN) lot = LOTMIN;
   
   if (!OrderCalcMargin(type, _Symbol, lot, price, n_margin) || !n_margin) 
   {
      Print("Insufficient funds. Required margin: ", n_margin);
      return(0);
   }
   
   if (AccountInfoDouble(ACCOUNT_FREEMARGIN) < n_margin) 
   {
      Print("Insufficient funds. Required margin: ", n_margin);
      return(0);
   }
   
   lot = NormalizeDouble(lot, LOTDIGITS);
   
   return lot;
}
 
//+------------------------------------------------------------------+
//|   getOrderPrice                                                  |
//+------------------------------------------------------------------+
double getOrderPrice(ENUM_ORDER_TYPE ordertype)
{

   Ask  =   SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   Bid  =   SymbolInfoDouble(Symbol(), SYMBOL_BID);
  double price = Bid;

  if (ordertype == ORDER_TYPE_SELL)
  {
    price = Bid;
  }
  if (ordertype == ORDER_TYPE_BUY)
  {
    price = Ask;
  }

  price = NormalizeDouble(price,_Digits);
  
  return price;
}

//+------------------------------------------------------------------+
//|   getOrderTakeprofit                                             |
//+------------------------------------------------------------------+
double getOrderTakeprofit(ENUM_ORDER_TYPE ordertype)
{
  double tp = 0.0;
  
  if (ext_profit_ptk == 0) return tp;

  if (ordertype == ORDER_TYPE_SELL)
  {
    tp = Bid - ext_profit_ptk * _Point;
  }
  
  if (ordertype == ORDER_TYPE_BUY)
  {
     tp = Ask + ext_profit_ptk * _Point;
  }

  tp = NormalizeDouble(tp,_Digits);
  
  return tp;
}

//+------------------------------------------------------------------+
//|   getOrderStopLoss                                            |
//+------------------------------------------------------------------+
double getOrderStopLoss(ENUM_ORDER_TYPE ordertype)
{
  double sl = 0;
  
  if (ext_sl_ptk == 0) return sl;

  if (ordertype == ORDER_TYPE_SELL)
  {
    sl = Bid + ext_sl_ptk * _Point;
  }
  if (ordertype == ORDER_TYPE_BUY)
  {
     sl = Ask - ext_sl_ptk * _Point;
  }

  sl = NormalizeDouble(sl,_Digits);
  
  return sl;
} 
  
//+------------------------------------------------------------------+
//|  check Cross Ma  moving averages return signal                   |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE checkCrossMa()
{

int bar = 0;
ENUM_ORDER_TYPE signal = WRONG_VALUE;


/*
int  CopyBuffer(
   int       indicator_handle,     // indicator handle
   int       buffer_num,           // indicator buffer number
   int       start_pos,            // start position
   int       count,                // amount to copy
   double    buffer[]              // target array to copy
   );
*/   
    
//--- get current Moving Average
double   maSlow[2];
if(CopyBuffer(maSlowHandle,0,1,2,maSlow)!=2)
{
   Print("CopyBuffer from iMA maSlowHandle failed, no data");
   return signal;
}
double   maFast[2];
if(CopyBuffer(maFastHandle,0,1,2,maFast)!=2)
{
   Print("CopyBuffer from iMA failed, no data");
   return signal;
}

   // Getting current moving average values
   double ma1_0 =  maSlow[0];
   double ma2_0 =  maFast[0];

   double ma1_1 =  maSlow[1];
   double ma2_1 =  maFast[1];
   
   if(ma2_1 > ma1_1  && ma2_0 < ma1_0)
   {
      return ORDER_TYPE_BUY;
   }

   if(ma2_1 < ma1_1 && ma2_0 > ma1_0)
   {
      return ORDER_TYPE_SELL;
   }

   return signal;
}

  
  
bool isNewBar() 
{
    static datetime dt;
    if(dt != iTime(Symbol(),PERIOD_CURRENT,0))   
    {
        dt =iTime(Symbol(),PERIOD_CURRENT,0);
        return true;
    }
   return false;
}



//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   ExtTrade.SetExpertMagicNumber(MAGIC);
   ExtTrade.SetMarginMode();
   ExtTrade.SetTypeFillingBySymbol(Symbol());
//--- Moving Average indicator
   maFastHandle = iMA(_Symbol,_Period, fast_ma_period, ma_shift, MODE_SMA, ma_applied_price);
   if(maFastHandle == INVALID_HANDLE)
     {
      printf("Error creating MA indicator");
      return(INIT_FAILED);
     }
   maSlowHandle = iMA(_Symbol,_Period, slow_ma_period, ma_shift, MODE_SMA, ma_applied_price);
   if(maSlowHandle == INVALID_HANDLE)
     {
      printf("Error creating MA indicator");
      return(INIT_FAILED);
     }
     
     
     STOPLEVEL = SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL); // MarketInfo(Symbol(),MODE_STOPLEVEL);
  
  if (STOPLEVEL < 1) STOPLEVEL = 3;
  
   LOTSTEP  = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);/// MarketInfo(Symbol(),MODE_LOTSTEP);
   LOTMIN   = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN) ; //MarketInfo(Symbol(),MODE_MINLOT);
   LOTMAX   = SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX) ;
   if (LOTMIN < 0.001) LOTMIN   = 0.01;
  
   if (LOTSTEP == 1)     LOTDIGITS = 0;
   if (LOTSTEP == 0.1)   LOTDIGITS = 1;
   if (LOTSTEP == 0.01)  LOTDIGITS = 2;
   if (LOTSTEP == 0.001) LOTDIGITS = 3;  
     
//--- ok
   return(INIT_SUCCEEDED);
  } 
  
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
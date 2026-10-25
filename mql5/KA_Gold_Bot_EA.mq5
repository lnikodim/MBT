//+------------------------------------------------------------------+
//|                                                  KA-Gold Bot.mq5 |
//|                           Copyright 2024, Hung_tthanh@yahoo.com. |
//|                                            https://forge.mql5.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Hung_tthanh@yahoo.com."
#property link      "https://forge.mql5.io"
#property version   "1.00"
#property strict

#define ExtBotName "KA-Gold Bot" //Bot Name
#define Version "1.00"

//Import inputal class
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Trade\OrderInfo.mqh>

//--- introduce predefined variables for code readability 
#define Ask    SymbolInfoDouble(_Symbol, SYMBOL_ASK)
#define Bid    SymbolInfoDouble(_Symbol, SYMBOL_BID)

//--- input parameters
input string  IndicatorSettings = "---------------------------------------------"; //-------- <Indicators Settings> --------
input int      InpKeltnerPeriod     = 50;          //Keltner length
input int      InpEMA10             = 10;          //EMA 1 period
input int      InpEMA200            = 200;         //EMA 2 period  

input string  TradingSettings = "---------------------------------------------"; //-------- <Trading Settings> --------
input double   Inpuser_lot          = 0.01;        //Volume trade
input double   InpSL_Pips           = 500;         //Stoploss (in Pips)
input double   InpTP_Pips           = 500;         //TP (in Pips) (0 = No TP)
input int      InpMax_slippage      = 3;           // Maximum slippage allow_Pips.
input double   InpMax_spread        = 65;          //Maximum allowed spread (in Point) (0 = floating)

input string  TrailingSettings = "---------------------------------------------"; //-------- <Trailing Settings> --------
input double   InpTrailingTrigger   = 300;         //Trailing Trigger Pips (0 = Inactive)
input double   InpTrailingStop      = 300;         //Trailing stop (in Pips)
input double   InpTrailingStep      = 100;         //Trailing Step (in Pips)

input string  TimeSettings = "---------------------------------------------"; //-------- <Trading Time Settings> --------
input bool     InpTimeFilter        = true;        //Trading Time Filter
input int      InpStartHour         = 2;           //Start Hour
input int      InpStartMinute       = 30;          //Start Minute
input int      InpEndHour           = 21;          //End Hour
input int      InpEndMinute         = 0;           //End Minute

input string  MoneyManagementSettings = "---------------------------------------------"; //-------- <Money Settings> --------
input bool     isVolume_Percent     = true;        //Allow Volume Percent
input double   InpRisk              = 1;           //Risk Percentage of Balance (%)

input string  GeneralSettings = "---------------------------------------------"; //-------- <Generral Settings> --------
input int      InpMagic             = 240219;      //Magic Number

//Local parameters
int      Pips2Points;    // slippage  3 pips    3=points    30=points
double   Pips2Double;    // Stoploss 15 pips    0.015      0.0150
int      slippage;
long     acSpread;
double   ExtTrailingTrigger   = 0.0;
double   ExtTrailingStop      = 0.0;
double   ExtTrailingStep      = 0.0;
string   strComment = "";
bool     isOrder = false;
bool     isSLSellOrd_Trigger = false;
bool     isSLBuyOrd_Trigger  = false;
datetime last;

CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
COrderInfo     m_order;                      // pending orders object

// Handles and buffers for the moving averages
int    EMA10Handle;
double EMA10Buffer[];
int    EMA200Handle;
double EMA200Buffer[];
int    EMAKeltnerHandle;
double EMAKeltnerBuffer[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() {
//---
   //3 or 5 digits detection
   //Pip and point
   if(_Digits % 2 == 1) {
      Pips2Double  = _Point*10;
      Pips2Points  = 10;
      slippage = 10* InpMax_slippage;
   }
   else {
      Pips2Double  = _Point;
      Pips2Points  =  1;
      slippage = InpMax_slippage;
   }
     
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
      
   RefreshRates();
//---
   m_trade.SetExpertMagicNumber(InpMagic);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
   m_trade.SetDeviationInPoints(slippage);
        
   //---
   ExtTrailingTrigger = InpTrailingTrigger * Pips2Double;
   ExtTrailingStop = InpTrailingStop * Pips2Double;
   ExtTrailingStep = InpTrailingStep * Pips2Double;
   
   //---
   EMA10Handle = iMA( Symbol(), Period(), InpEMA10, 0, MODE_EMA, PRICE_CLOSE );
   ArraySetAsSeries( EMA10Buffer, true );

   EMA200Handle = iMA( Symbol(), Period(), InpEMA200, 0, MODE_EMA, PRICE_CLOSE );
   ArraySetAsSeries( EMA200Buffer, true );

   EMAKeltnerHandle = iMA( Symbol(), Period(), InpKeltnerPeriod, 0, MODE_EMA, PRICE_CLOSE );
   ArraySetAsSeries( EMAKeltnerBuffer, true );
   
   if ( EMA10Handle == INVALID_HANDLE || EMA200Handle == INVALID_HANDLE || EMAKeltnerHandle == INVALID_HANDLE) {
      Print( "Error creating handles to moving averages" );
      return INIT_FAILED;
   }
   
//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//---
   IndicatorRelease( EMA10Handle );
   IndicatorRelease( EMA200Handle );
   IndicatorRelease( EMAKeltnerHandle );
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
//---
   if(TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) == false) {
      Comment("KA-Gold Bot\nTrade not allowed.");
      return;
   }
     
    MqlDateTime structTime;
    TimeCurrent(structTime);
    structTime.sec = 0;
    
    //Set starting time
    structTime.hour = InpStartHour;
    structTime.min = InpStartMinute;       
    datetime timeStart = StructToTime(structTime);
    
    //Set Ending time
    structTime.hour = InpEndHour;
    structTime.min = InpEndMinute;
    datetime timeEnd = StructToTime(structTime);
    
    acSpread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
    
   
   strComment = "\n" + ExtBotName + " - v." + (string)Version;
   strComment += "\nSever time = " + TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS) + " day of week " + DayOfWeekDescription(structTime.day_of_week);
   strComment += "\nTrading time = [" + (string)InpStartHour + "h" + (string)InpStartMinute + " --> " +  (string)InpEndHour + "h" + (string)InpEndMinute + "]";
   
   strComment += "\nCurrent Spread = " + (string)acSpread + " Points";
   
   // Get the fast and slow ma values for bar 1 and bar 2
   if ( CopyBuffer( EMA10Handle, 0, 0, 3, EMA10Buffer ) < 3 ) {
      Print( "Insufficient results from fast MA" );
      return;
   }
   if ( CopyBuffer( EMA200Handle, 0, 0, 3, EMA200Buffer ) < 3 ) {
      Print( "Insufficient results from slow MA" );
      return;
   }
   if ( CopyBuffer( EMAKeltnerHandle, 0, 0, 3, EMAKeltnerBuffer ) < 3 ) {
      Print( "Insufficient results from Keltner" );
      return;
   }
   
   //Update Values
   UpdateOrders();      
   
   TrailingStop();
   
   // Signal Calculation
   ENUM_ORDER_TYPE Signal = CalculateSignal(InpKeltnerPeriod);
   
   if(last != iTime(Symbol(), PERIOD_CURRENT, 0)) {
      //Dieu kien giao dich theo phien My
      if(InpTimeFilter) {
         if(TimeCurrent() >= timeStart && TimeCurrent() < timeEnd) {
            if(!isOrder) OpenTrades(Signal);
         }
      }
      else {
         if(!isOrder) OpenTrades(Signal);
      }
      
      //update last time
      last = iTime(Symbol(), PERIOD_CURRENT, 0);
   }
   //---
   Comment(strComment);
}
//+------------------------------------------------------------------+

ENUM_ORDER_TYPE CalculateSignal(int period) {

   ENUM_ORDER_TYPE result = -1;
   double avg;

   double middle1 = EMAKeltnerBuffer[1];  //iMA(NULL, 0, period, 0, MODE_EMA, PRICE_CLOSE, 1);
   avg  = findAvg(period, 1);
   double upper1 = middle1 + avg;
   double lower1 = middle1 - avg;

   double middle2 = EMAKeltnerBuffer[2];  //iMA(NULL, 0, period, 0, MODE_EMA, PRICE_CLOSE, 2);
   avg  = findAvg(period, 2);
   double upper2 = middle2 + avg;
   double lower2 = middle2 - avg;

   strComment += "\nUpper 1 = " + (string)NormalizeDouble(upper1, Digits());
   strComment += "\nUpper 2 = " + (string)NormalizeDouble(upper2, Digits());
   strComment += "\nLower 1 = " + (string)NormalizeDouble(lower1, Digits());
   strComment += "\nLower 2 = " + (string)NormalizeDouble(lower2, Digits());

   // Đường EMA 10
   double EMA10_1 = EMA10Buffer[1];  //iMA(NULL,0, InpEMA10, 0, MODE_EMA, PRICE_CLOSE, 1);
   double EMA10_2 = EMA10Buffer[2];  //iMA(NULL,0, InpEMA10, 0, MODE_EMA, PRICE_CLOSE, 2);

   // Đường EMA 200
   double EMA200_1 = EMA200Buffer[1];  //iMA(NULL,0, InpEMA200, 0, MODE_EMA, PRICE_CLOSE, 1);
   double EMA200_2 = EMA200Buffer[2];  //iMA(NULL,0, InpEMA200, 0, MODE_EMA, PRICE_CLOSE, 2);
   
   // BUY SIGNAL ---------------------
   bool EntryBuy1 = false;
   bool EntryBuy2 = false;
   bool EntryBuy3 = false;
   
   if(iClose(_Symbol, PERIOD_CURRENT, 1) > upper1) EntryBuy1 = true;   
   if(iClose(_Symbol, PERIOD_CURRENT, 1) > EMA200_1) EntryBuy2 = true;
   if(EMA10_2 < upper2  && EMA10_1 > upper1) EntryBuy3 = true;
   
   if(EntryBuy1 && EntryBuy2 && EntryBuy3) result = ORDER_TYPE_BUY;
   
   // SELL SIGNAL --------------------
   bool EntrySell1 = false;
   bool EntrySell2 = false;
   bool EntrySell3 = false;
   
   if(iClose(_Symbol, PERIOD_CURRENT, 1) < lower1) EntrySell1 = true;
   if(iClose(_Symbol, PERIOD_CURRENT, 1) < EMA200_1) EntrySell2 = true;
   if(EMA10_2 > lower2 && EMA10_1 < lower1) EntrySell3 = true;
   
   if(EntrySell1 && EntrySell2 && EntrySell3) result = true;   
   
   //---
   return result;
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double findAvg(int period, int shift) {

   double sum=0;
   for(int x = shift ; x <(shift + period); x++)
     {
      sum += iHigh(_Symbol, PERIOD_CURRENT, x) - iLow(_Symbol, PERIOD_CURRENT, x);
     }
   sum = sum / period;
   return (sum);
}

//+------------------------------------------------------------------+
//| SEND ORDER                                                       |
//+------------------------------------------------------------------+
void OpenTrades(ENUM_ORDER_TYPE entrySignal) {

   double TP = 0, SL = 0;
   double OpenPrice = (entrySignal == ORDER_TYPE_BUY)? Ask : Bid;

   string comment = ExtBotName;
   //Calculate Lots
   double lot1 = CalculateVolume();
   
   if(entrySignal == ORDER_TYPE_BUY) {
      //For BUY --------------------------------
      TP = OpenPrice + NormalizeDouble(InpTP_Pips* Pips2Double, Digits());
      SL = OpenPrice - NormalizeDouble(InpSL_Pips * Pips2Double, Digits());
      
      if(CheckSpreadAllow()                                    //Check Spread
         && CheckVolumeValue(lot1)                             //Check volume
         && CheckStopLoss(OpenPrice,  SL, TP)                  //Check Dist from SL, TP to OpenPrice         
         && CheckMoneyForTrade(Symbol(), lot1, ORDER_TYPE_BUY))        //Check Balance khi lenh cho duoc Hit
      {
         if(!m_trade.Buy(lot1, _Symbol, OpenPrice, SL, TP, comment))
         Print(__FUNCTION__,"--> OrderSend error ",GetLastError());
      }   
   }
   else if(entrySignal == ORDER_TYPE_SELL) {
      //For SELL --------------------------------
      TP = OpenPrice - NormalizeDouble(InpTP_Pips* Pips2Double, Digits());
      SL = OpenPrice + NormalizeDouble(InpSL_Pips * Pips2Double, Digits());   
   
      if(CheckSpreadAllow()                                    //Check Spread
         && CheckVolumeValue(lot1)                             //Check volume
         && CheckStopLoss(OpenPrice,  SL, TP)                  //Check Dist from SL, TP to OpenPrice
         && CheckMoneyForTrade(_Symbol, lot1, ORDER_TYPE_SELL))        //Check Balance khi lenh cho duoc Hit
      {
         if(!m_trade.Sell(lot1, _Symbol, OpenPrice, SL, TP, comment))
         Print(__FUNCTION__,"--> OrderSend error ",GetLastError());
      }
   }
   
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailingStop() {

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(m_position.SelectByIndex(i)) {
         if((m_position.Magic() == InpMagic) && (m_position.Symbol() == Symbol())) {
            // For Buy order
            if(m_position.PositionType() == POSITION_TYPE_BUY) {
               double Profit_Buy_point = Bid - m_position.PriceOpen();
               
               //Check Profit to get Trailing condition
               if(!isSLBuyOrd_Trigger && Profit_Buy_point > ExtTrailingTrigger) {
                   isSLBuyOrd_Trigger = true;
               }

               if(isSLBuyOrd_Trigger) {//--1               
                  if(Profit_Buy_point > ExtTrailingStop + ExtTrailingStep){
                     if((m_position.StopLoss()<(Bid - (ExtTrailingStop + ExtTrailingStep)))) {
                        double newSL = NormalizeDouble(Bid - ExtTrailingStop, _Digits);
                       
                        double newTP = 0;
                        if(InpTP_Pips != 0) newTP = m_position.TakeProfit();
                           
                        if(CheckStopLoss(Bid, newSL, newTP)) {
                              if(!m_trade.PositionModify(m_position.Ticket(), newSL, newTP)) {
                                 Print(__FUNCTION__,"--> OrderModify BUY error ", m_trade.ResultComment());
                                 continue;
                           }
                        }
                     }
                  }

               }//--1
               
            }
            //For Sell Order
            else if(m_position.PositionType() == POSITION_TYPE_SELL) {
               double Profit_Sell_point = m_position.PriceOpen() - Ask;
               //Check Profit to get Trailing condition
               if(!isSLSellOrd_Trigger && Profit_Sell_point > ExtTrailingTrigger) {
                   isSLSellOrd_Trigger = true;
               }

               if(isSLSellOrd_Trigger) {//--1               
                  if(Profit_Sell_point > ExtTrailingStop + ExtTrailingStep){
                     if((m_position.StopLoss()>(Ask + (ExtTrailingStop + ExtTrailingStep))) || (m_position.StopLoss()==0)) {
                        double newSL = NormalizeDouble(Ask + ExtTrailingStop, _Digits);
                       
                        double newTP = 0;
                        if(InpTP_Pips != 0) newTP = m_position.TakeProfit();
                           
                        if(CheckStopLoss(Ask, newSL, newTP)) {
                              if(!m_trade.PositionModify(m_position.Ticket(), newSL, newTP)) {
                                 Print(__FUNCTION__, "--> OrderModify SELL error ", m_trade.ResultComment());
                                 continue;
                           }
                        }
                     }
                  }

               }//--1
            }
         }
      }
   } 
}//end function

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void UpdateOrders() {

   isOrder = false;
  
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!m_position.SelectByIndex(i)) continue;

      if(m_position.Symbol() == _Symbol && m_position.Magic() == InpMagic) {
         if(m_position.PositionType() == POSITION_TYPE_BUY || m_position.PositionType() == POSITION_TYPE_SELL) {
            isOrder = true;
         }
         
         if(m_position.PositionType() == POSITION_TYPE_BUY) {
            isSLSellOrd_Trigger = false;
         }
         else if(m_position.PositionType() == POSITION_TYPE_SELL) {
            isSLBuyOrd_Trigger = false;
         }
         else {
            isSLSellOrd_Trigger = false;
            isSLBuyOrd_Trigger = false;
         }         
      }       
   }
}

//+------------------------------------------------------------------+
//| CALCULATE VOLUME                                                 |
//+------------------------------------------------------------------+
double CalculateVolume() {

   double LotSize = 0;

   if(isVolume_Percent == false) {
      LotSize = Inpuser_lot;
     }
   else {
      LotSize = (InpRisk) * m_account.FreeMargin();
      LotSize = LotSize /100000;
      double n = MathFloor(LotSize/Inpuser_lot);
      //Comment((string)n);
      LotSize = n * Inpuser_lot;
      
      if(LotSize < Inpuser_lot)
         LotSize = Inpuser_lot;

      if(LotSize > m_symbol.LotsMax()) LotSize = m_symbol.LotsMax();

      if(LotSize < m_symbol.LotsMin()) LotSize = m_symbol.LotsMin();
   }
     
//---
   return(LotSize);
}
//+------------------------------------------------------------------+
//| Check Spread Allow                                               |
//+------------------------------------------------------------------+
bool CheckSpreadAllow() {

   //double acSpread = NormalizeDouble(MarketInfo(_Symbol, MODE_SPREAD), _Digits) / Pips2Points;
   //acSpread = MarketInfo(_Symbol, MODE_SPREAD);// / Pips2Points;
   if(InpMax_spread != 0){
      if(acSpread > InpMax_spread){
         Print(__FUNCTION__," > current Spread = " + (string)acSpread + " > greater than user Spread!...");
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume) {

//--- minimal allowed volume for trade operations
  double min_volume=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(volume < min_volume)
     {
      //description = StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
   double max_volume=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      //description = StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
   double volume_step=SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   int ratio = (int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      //description = StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f", volume_step,ratio*volume_step);
      return(false);
     }
      
   return(true);
}
//+------------------------------------------------------------------+
//|CHECK SL AND TP FOR PENDING ORDER                                 |
//+------------------------------------------------------------------+

bool CheckStopLoss(double price, double SL, double TP) {

//--- get the SYMBOL_TRADE_STOPS_LEVEL level
   int stops_level = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   if(stops_level != 0)
     {
      PrintFormat("SYMBOL_TRADE_STOPS_LEVEL=%d: StopLoss and TakeProfit must"+
                  " not be nearer than %d points from the closing price", stops_level, stops_level);
     }
//---
   bool SL_check = true;
   bool TP_check = true;
   
   if(SL != 0)
   {
      //--- check the StopLoss
      SL_check = MathAbs(price - SL) > (stops_level * _Point);
   }
   
   if(TP != 0)
   {
      //--- check the Takeprofit
      TP_check = MathAbs(price - TP) > (stops_level * _Point);
   }
      //--- return the result of checking
      return(TP_check&&SL_check);  
}

//+------------------------------------------------------------------+
//| Check Money for Trade                                            |
//+------------------------------------------------------------------+
bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type) {
//--- Getting the opening price
   MqlTick mqltick;
   SymbolInfoTick(symb,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- values of the required and free margin
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   //--- call of the checking function
   if(!OrderCalcMargin(type,symb,lots,price,margin))
     {
      //--- something went wrong, report and return false
      Print("Error in ",__FUNCTION__," code=",m_trade.ResultComment());
      return(false);
     }
   //--- if there are insufficient funds to perform the operation
   if(margin>free_margin)
     {
      //--- report the error and return false
      Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",m_trade.ResultComment());
      return(false);
     }
   //--- checking successful
   return(true);
}

//+------------------------------------------------------------------+
//| Day Of Week Description                                          |
//+------------------------------------------------------------------+
string DayOfWeekDescription(const int day_of_week) {

   string text="";
   switch(day_of_week)
     {
      case  0:
         text="Sunday";
         break;
      case  1:
         text="Monday";
         break;
      case  2:
         text="Tuesday";
         break;
      case  3:
         text="Wednesday";
         break;
      case  4:
         text="Thursday";
         break;
      case  5:
         text="Friday";
         break;
      case  6:
         text="Saturday";
         break;
      default:
         text="Another day";
         break;
     }
//---
   return(text);
}

  
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates(void) {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print("RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(Ask==0 || Bid==0)
      return(false);
//---
   return(true);
}
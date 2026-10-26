
#property copyright "Copyright 2010, vsebastien3"
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\OrderInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
CDealInfo      m_deal;                       // deals object
COrderInfo     m_order;                      // pending orders object


//--- input parameters
input int bands_period= 20;        // Bollinger Bands period
input int rsi_period =13;          //rsi period
input int rsi_up=70;               //rsi overbought lvl
input int rsi_down=30;            // rsi oversold lvl
input double Lot=0.1;             // Lot if autolot inactive
input double SL=0.0238;            //stop lose value 
input int MAperiod = 200;          // Period of the MA
input int magic=1234;





input bool autolot = true ;        // activate or not autolot
input double risk=0.05;           // risk per trade of total equity


//--- global variables
//--- initialize global variables

bool           m_need_modify=false;
bool           m_OnTradeTransaction=false;
long           m_last_closed_position_type=-1;
double         m_last_closed_position_volume=0.0;
double         m_last_closed_position_profit=0.0;


bool                 InpAllMagic    = false;
int bands_shift = 0;         // Bollinger Bands shift
double deviation= 2;         // Standard deviation
 int MAshift=0;              // Ma shift
double usedlot;
double usedlot2;                  
int BolBandsHandle;                // Bolinger Bands handle
int rsiHandle;
int MAHandle;
double BBUp[],BBLow[],BBMidle[];   // dynamic arrays for numerical values of Bollinger Bands 


ulong orderTicket;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Do we have sufficient bars to work
   if(Bars(_Symbol,_Period)<60) // total number of bars is less than 60?
     {
      Alert("We have less than 60 bars on the chart, an Expert Advisor terminated!!");
      return(-1);
     }
     
//-------------------------------------------- last closed position
    
     
//--- get handle of the Bollinger Bands and RSI indicators
   BolBandsHandle=iBands(NULL,PERIOD_CURRENT,bands_period,bands_shift,deviation,PRICE_CLOSE);
   rsiHandle=iRSI(NULL,0,rsi_period,PRICE_CLOSE);
   MAHandle=iMA(NULL,PERIOD_D1,MAperiod,MAshift,MODE_EMA,PRICE_CLOSE);
   
     if ( MAHandle == INVALID_HANDLE )
    {
      Print("Creating MA failed. Error #", GetLastError());
      return(-1);
    }
   
   if ( rsiHandle == INVALID_HANDLE )
    {
      Print("Creating RSI failed. Error #", GetLastError());
      return(-1);
    }
//--- Check for Invalid Handle
   if((BolBandsHandle<0))
     {
      Alert("Error in creation of indicators - error: ",GetLastError(),"!!");
      return(-1);
     }

   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- release indicator handles
   IndicatorRelease(BolBandsHandle);
   IndicatorRelease(rsiHandle);
   IndicatorRelease(MAHandle);
   
  }
  
  //--------------------------------------------------------------------------------------------------
  double RsiValue() {
//---
   double rsi[2];
  
   ResetLastError();
   if ( CopyBuffer(rsiHandle, 0, 0, 2, rsi) == 2 ) {
      return(rsi[0]);
   } else {
      Print(__FUNCTION__, ": getting RSI data failed. Error #", GetLastError());
   }
//---
   return(-1.0);
}

//----------------------------------------------------------------------------------------

  double MAvalue() {
//---
   double MA[2];
  
   ResetLastError();
   if ( CopyBuffer(MAHandle, 0, 0, 2, MA) == 2 ) {
      return(MA[0]);
   } else {
      Print(__FUNCTION__, ": getting MA data failed. Error #", GetLastError());
   }
//---
   return(-1.0);
}

//-----------------------------------------------------------
  
   double Autolot()

  {
  double balance=AccountInfoDouble(ACCOUNT_BALANCE);
  double pertem=balance*risk;
  double perte=SL*SymbolInfoDouble(_Symbol,SYMBOL_BID);
  double maxvol=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
  double minvol=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
  double lotsize=SymbolInfoDouble(Symbol(),SYMBOL_TRADE_CONTRACT_SIZE);

   if(autolot==true)
    {
    usedlot=(pertem/perte)/lotsize;

     usedlot2 = NormalizeDouble(usedlot,2);
          if(usedlot2<minvol)
         {
         usedlot2=minvol;
         }
         
         if(usedlot2>maxvol)
         {
         usedlot2=maxvol;
         }
         
    
    }
    else usedlot2=Lot;
  
         if(usedlot2<minvol)
         {
         usedlot2=minvol;
         }
         
         if(usedlot2>maxvol)
         {
         usedlot2=maxvol;
         }
  
  
  return(0.01);
  }
  
  //------------------------------------------------------------
  
 
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- we will use the static Old_Time variable to serve the bar time.
//--- at each OnTick execution we will check the current bar time with the saved one.
//--- if the bar time isn't equal to the saved time, it indicates that we have a new tick.

   static datetime Old_Time;
   datetime New_Time[1];
   bool IsNewBar=false;
   
   Autolot();
   
   double rsi_value = RsiValue();
   double MA_value = MAvalue();
   bool Ismoney=CheckMoneyForTrade(_Symbol,usedlot2,0);
   
     
   

   
   
   
 

//--- copying the last bar time to the element New_Time[0]
   int copied=CopyTime(_Symbol,_Period,0,1,New_Time);
   if(copied>0) // ok, the data has been copied successfully
     {
      if(Old_Time!=New_Time[0]) // if old time isn't equal to new bar time
        {
         IsNewBar=true;   // if it isn't a first call, the new bar has appeared
         if(MQL5InfoInteger(MQL5_DEBUGGING)) Print("We have new bar here ",New_Time[0]," old time was ",Old_Time);
         Old_Time=New_Time[0];            // saving bar time
        }
     }
   else
     {
      Alert("Error in copying historical times data, error =",GetLastError());
      ResetLastError();
      return;
     }

//--- EA should only check for new trade if we have a new bar
   if(IsNewBar==false)
     {
      return;
     }

//--- do we have enough bars to work with
   int Mybars=Bars(_Symbol,_Period);
   if(Mybars<60) // if total bars is less than 60 bars
     {
      Alert("We have less than 60 bars, EA will now exit!!");
      return;
     }

   MqlRates mrate[];          // To be used to store the prices, volumes and spread of each bar   

/*
     Let's make sure our arrays values for the Rates and Indicators 
     is stored serially similar to the timeseries array
*/

// the rates arrays
   ArraySetAsSeries(mrate,true);
 
// the indicator arrays
   ArraySetAsSeries(BBUp,true);
   ArraySetAsSeries(BBLow,true);
   ArraySetAsSeries(BBMidle,true);

//--- Get the details of the latest 3 bars
   if(CopyRates(_Symbol,_Period,0,3,mrate)<0)
     {
      Alert("Error copying rates/history data - error:",GetLastError(),"!!");
      return;
     }

//--- Copy the new values of our indicators to buffers (arrays) using the handle
   if(CopyBuffer(BolBandsHandle,0,0,3,BBMidle)<0 || CopyBuffer(BolBandsHandle,1,0,3,BBUp)<0
      || CopyBuffer(BolBandsHandle,2,0,3,BBLow)<0)
     {
      Alert("Error copying Bollinger Bands indicator Buffers - error:",GetLastError(),"!!");
      return;
     }


   double Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);   // Ask price
   double Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);   // Bid price
   
 //--- Declare bool type variables to hold our Buy and Sell Conditions
   bool Buy_Condition =(mrate[1].close < BBLow[1] &&   //closing candle under lowest BB
                        rsi_value<rsi_down &&          // rsi value lower than oversold limit
                         mrate[1].close>MA_value);     // closing candle above MA     

   bool Sell_Condition = (mrate[1].close > BBUp[1] &&  //closing candle above Highest BB
                          rsi_value>rsi_up &&          // rsi value higher than overbought limit
                          mrate[1].close<MA_value);    // closing candle under MA    
                          

   if(Buy_Condition && !PositionSelect(_Symbol) && Ismoney==true)    // Open long position
     {                                              // DEÌÀ is growing up
      LongPositionOpen();                           // and white candle crossed the Lower Band from below to above
     }

   if(Sell_Condition && !PositionSelect(_Symbol)&& Ismoney==true)    // Open short position
     {                                              // DEÌÀ is falling down
      ShortPositionOpen();                          // and Black candle crossed the Upper Band from above to below
     }

  
   return;
  }
//+------------------------------------------------------------------+
//| Open Long position                                               |
//+------------------------------------------------------------------+
void LongPositionOpen()
  {
   MqlTradeRequest mrequest;                             // Will be used for trade requests
   MqlTradeResult mresult;                               // Will be used for results of trade requests
   
   ZeroMemory(mrequest);
   ZeroMemory(mresult);
   
   double Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);    // Ask price
   double Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);    // Bid price

   if(!PositionSelect(_Symbol))
     {
      mrequest.action = TRADE_ACTION_DEAL;               // Immediate order execution
      mrequest.price = NormalizeDouble(Ask,_Digits);     // Lastest Ask price
      mrequest.sl = BBLow[1]-SL;                         // Stop Loss
      mrequest.tp = BBMidle[1];                          // Take Profit
      mrequest.symbol = _Symbol;                         // Symbol
      mrequest.volume = usedlot2;                             // Number of lots to trade
      mrequest.magic = magic;                                // Magic Number
      mrequest.type = ORDER_TYPE_BUY;                    // Buy Order
      mrequest.type_filling = ORDER_FILLING_FOK;         // Order execution type
      mrequest.deviation=5;                              // Deviation from current price
      OrderSend(mrequest,mresult);                       // Send order
     }
  }
//+------------------------------------------------------------------+
//| Open Short position                                              |
//+------------------------------------------------------------------+
void ShortPositionOpen()
  {
   MqlTradeRequest mrequest;                             // Will be used for trade requests
   MqlTradeResult mresult;                               // Will be used for results of trade requests
   
   ZeroMemory(mrequest);
   ZeroMemory(mresult);
   
   double Ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);    // Ask price
   double Bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);    // Bid price

   if(!PositionSelect(_Symbol))
     {
      mrequest.action = TRADE_ACTION_DEAL;               // Immediate order execution
      mrequest.price = NormalizeDouble(Bid,_Digits);     // Lastest Bid price
      mrequest.sl = BBUp[1]+SL;                          // Stop Loss
      mrequest.tp = BBMidle[1];                          // Take Profit
      mrequest.symbol = _Symbol;                         // Symbol
      mrequest.volume = usedlot2;                             // Number of lots to trade
      mrequest.magic = magic;                                // Magic Number
      mrequest.type= ORDER_TYPE_SELL;                    // Sell order
      mrequest.type_filling = ORDER_FILLING_FOK;         // Order execution type
      mrequest.deviation=5;                              // Deviation from current price
      OrderSend(mrequest,mresult);                       // Send order
     }
  }

  
  
  //-----------------------------------------------------
  
  
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
  
  
  
  //---------------------------------------------------------
  
  
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
      long     deal_entry        =0;
      string   deal_symbol       ="";
      long     deal_magic        =0;
      double   deal_profit=0;
      if(HistoryDealSelect(trans.deal))
        {
         deal_entry=HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
         deal_symbol=HistoryDealGetString(trans.deal,DEAL_SYMBOL);
         deal_magic=HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
         deal_profit=HistoryDealGetDouble(trans.deal,DEAL_PROFIT);
        }
      else
         return;
      if(deal_symbol==Symbol() && deal_magic==magic)
         if(deal_entry==DEAL_ENTRY_OUT)
           {
            if(deal_profit>0)
              {
               Print("profit > 0.0");
              }
            else
              {
              Print("profit < 0.0");
              }
           }
     }
  }
  
  
  //----------------------------------
  bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type)
  {
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
      Print("Error in ",__FUNCTION__," code=",GetLastError());
      return(false);
     }
   //--- if there are insufficient funds to perform the operation
   if(margin>free_margin)
     {
      //--- report the error and return false
      Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",GetLastError());
      return(false);
     }
//--- checking successful
   return(true);
  }
  
  

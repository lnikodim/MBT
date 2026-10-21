//+------------------------------------------------------------------+
//|                                             LarryConnersRSI2.mq5 
//|                                         FOREX - 1 Hour TimeFrame
//|                                Copyright 2017, algotrading.co.za
//|                                         http://algotrading.co.za
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, algotrading.co.za"
#property link      "http://algotrading.co.za"
#property version   "1.01"

#include <Trade\Trade.mqh> // Get code from other places

//--- Input Variables 

input double   lot = 1;                  //Lots
input int      shortSmaPeriods = 5;      //Fast MA period
input int      longSmaPeriods = 200;     //Slow MA period
input int      RSIPeriods = 2;           //RSI Period 
input int      RSILongEntry = 6;         //RSI Long Entry
input int      RSIShortEntry = 95;       //RSI Short Entry

                                         //standard trade management inputs

input int      slippage=3;
input bool     useStopLoss=true;       //Use Stop Loss
input double   stopLossPips=30;        //Stop Loss (pips)
input bool     useTakeProfit=true;     //Use Take Profit
input double   takeProfitPips=60;      //Take Profit (pips)
input ulong    InpMagic=261022;        //Magic number

//--- Service Variables 

CTrade myTradingControlPanel;
MqlRates PriceDataTable[];

double shortSmaData[],longSmaData[],RSIData[];
int numberOfShortSmaData,numberOfLongSmaData,numberOfPriceDataPoints,numberOfRSIData;
int shortSmaControlPanel,longSmaControlPanel,RSIControlPanel;
int P;
double currentBid,currentAsk;
double stopLossPipsFinal,takeProfitPipsFinal,stopLevelPips;
double stopLossLevel,takeProfitLevel;
double shortSma1,shortSma2,longSma1,longSma2,RSI1;
datetime g_lastEntryBar=0,g_loadBar=0; // v1.01: one entry attempt per bar; live: no entry on the bar the EA was loaded in
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   ArraySetAsSeries(PriceDataTable,true);
   ArraySetAsSeries(shortSmaData,true);
   ArraySetAsSeries(longSmaData,true);
   ArraySetAsSeries(RSIData,true);

   shortSmaControlPanel= iMA(_Symbol,_Period,shortSmaPeriods,0,MODE_SMA,PRICE_CLOSE);
   longSmaControlPanel = iMA(_Symbol,_Period,longSmaPeriods,0,MODE_SMA,PRICE_CLOSE);
   RSIControlPanel=iRSI(_Symbol,_Period,RSIPeriods,PRICE_CLOSE);
   if(shortSmaControlPanel==INVALID_HANDLE || longSmaControlPanel==INVALID_HANDLE || RSIControlPanel==INVALID_HANDLE) return(INIT_FAILED);
   myTradingControlPanel.SetExpertMagicNumber(InpMagic);
   g_loadBar=iTime(_Symbol,_Period,0);

   if(_Digits==5 || _Digits==3 || _Digits==1) P=10;else P=1;

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---Release indicators
   IndicatorRelease(shortSmaControlPanel);
   IndicatorRelease(longSmaControlPanel);
   IndicatorRelease(RSIControlPanel);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
// -------------------- Collect most current data --------------------

   currentBid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   currentAsk = SymbolInfoDouble(_Symbol,SYMBOL_ASK);

   numberOfPriceDataPoints=CopyRates(_Symbol,0,0,10,PriceDataTable);
   numberOfShortSmaData= CopyBuffer(shortSmaControlPanel,0,0,3,shortSmaData);
   numberOfLongSmaData = CopyBuffer(longSmaControlPanel,0,0,3,longSmaData);
   numberOfRSIData=CopyBuffer(RSIControlPanel,0,0,3,RSIData);
   if(numberOfPriceDataPoints<2 || numberOfShortSmaData<3 || numberOfLongSmaData<3 || numberOfRSIData<3) return; // v1.01: data not ready

   shortSma1 = shortSmaData[1];
   shortSma2 = shortSmaData[2];
   longSma1 = longSmaData[1];
   longSma2 = longSmaData[2];
   RSI1=RSIData[1];

// -------------------- Technical Requirements --------------------

   stopLevelPips=(double)(SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)+SymbolInfoInteger(_Symbol,SYMBOL_SPREAD))/P;

   if(stopLossPips<stopLevelPips)
     {
      stopLossPipsFinal=stopLevelPips;
     }
   else
     {
      stopLossPipsFinal=stopLossPips;
     }

   if(takeProfitPips<stopLevelPips)
     {
      takeProfitPipsFinal=stopLevelPips;
     }
   else
     {
      takeProfitPipsFinal=takeProfitPips;
     }

// -------------------- EXITS --------------------

   if(SelectOwnPosition()) // We have an open position (v1.01: this EA's magic only)
     {

      // --- Exit Rules (Long Trades) ---

      // --------------------------------------------------------- //

      if(PriceDataTable[1].close>shortSma1) // Rule to exit long trades

         // --------------------------------------------------------- //

        {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) // If it is Buy position
           {

            myTradingControlPanel.PositionClose(PositionGetInteger(POSITION_TICKET)); // Closes this EA's position

            if(myTradingControlPanel.ResultRetcode()==10008 || myTradingControlPanel.ResultRetcode()==10009) //Request is completed or order placed
              {
               Print("Exit rules: A close order has been successfully placed with Ticket#: ",myTradingControlPanel.ResultOrder());
              }
            else
              {
               Print("Exit rules: The close order request could not be completed.Error: ",myTradingControlPanel.ResultRetcode());
               ResetLastError();
               return;
              }

           }
        }

      // --------------------------------------------------------- //

      if(PriceDataTable[1].close<shortSma1) // Rule to exit short trades

         // --------------------------------------------------------- //  

        {
         if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) // If it is Sell position
           {

            myTradingControlPanel.PositionClose(PositionGetInteger(POSITION_TICKET)); // Closes this EA's position

            if(myTradingControlPanel.ResultRetcode()==10008 || myTradingControlPanel.ResultRetcode()==10009) //Request is completed or order placed
              {
               Print("Exit rules: A close order has been successfully placed with Ticket#: ",myTradingControlPanel.ResultOrder());
              }
            else
              {
               Print("Exit rules: The close order request could not be completed. Error: ",myTradingControlPanel.ResultRetcode());
               ResetLastError();
               return;
              }
           }
        }

     }

// -------------------- ENTRIES --------------------  

   if(!SelectOwnPosition() && PriceDataTable[0].time!=g_lastEntryBar && (MQLInfoInteger(MQL_TESTER) || PriceDataTable[0].time!=g_loadBar)) // We have no open position (v1.01: one entry attempt per bar)
     {

      // --- Entry Rules (Long Trades) ---

      // --------------------------------------------------------- //

      if(RSI1<RSILongEntry && PriceDataTable[1].close>longSma1) // Rule to enter long trades

         // --------------------------------------------------------- //

        {

         if(useStopLoss) stopLossLevel=currentAsk-stopLossPipsFinal*_Point*P; else stopLossLevel=0.0;
         if(useTakeProfit) takeProfitLevel=currentAsk+takeProfitPipsFinal*_Point*P; else takeProfitLevel=0.0;

         g_lastEntryBar=PriceDataTable[0].time;
         myTradingControlPanel.PositionOpen(_Symbol,ORDER_TYPE_BUY,lot,currentAsk,stopLossLevel,takeProfitLevel,"Buy Trade. Magic Number #"+(string) myTradingControlPanel.RequestMagic()); // Open a Buy position

         if(myTradingControlPanel.ResultRetcode()==10008 || myTradingControlPanel.ResultRetcode()==10009) //Request is completed or order placed
           {
            Print("Entry rules: A Buy order has been successfully placed with Ticket#: ",myTradingControlPanel.ResultOrder());
           }
         else
           {
            Print("Entry rules: The Buy order request could not be completed. Error: ",myTradingControlPanel.ResultRetcode());
            ResetLastError();
            return;
           }

        }

      // --- Entry Rules (Short Trades) ---

      // --------------------------------------------------------- //

      if(RSI1>RSIShortEntry && PriceDataTable[1].close<longSma1) // Rule to enter short trades

         // --------------------------------------------------------- //

        {

         if(useStopLoss) stopLossLevel=currentBid+stopLossPipsFinal*_Point*P; else stopLossLevel=0.0;
         if(useTakeProfit) takeProfitLevel=currentBid-takeProfitPipsFinal*_Point*P; else takeProfitLevel=0.0;

         g_lastEntryBar=PriceDataTable[0].time;
         myTradingControlPanel.PositionOpen(_Symbol,ORDER_TYPE_SELL,lot,currentBid,stopLossLevel,takeProfitLevel,"Sell Trade. Magic Number #"+(string) myTradingControlPanel.RequestMagic()); // Open a Sell position

         if(myTradingControlPanel.ResultRetcode()==10008 || myTradingControlPanel.ResultRetcode()==10009) //Request is completed or order placed
           {
            Print("Entry rules: A Sell order has been successfully placed with Ticket#: ",myTradingControlPanel.ResultOrder());
           }
         else
           {
            Print("Entry rules: The Sell order request could not be completed.Error: ",myTradingControlPanel.ResultRetcode());
            ResetLastError();
            return;
           }

        }

     }

  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| v1.01: select this EA's position on the symbol (by magic)        |
//+------------------------------------------------------------------+
bool SelectOwnPosition()
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket>0 && PositionGetString(POSITION_SYMBOL)==_Symbol && PositionGetInteger(POSITION_MAGIC)==(long)InpMagic)
         return(true);
     }
   return(false);
  }
//+------------------------------------------------------------------+

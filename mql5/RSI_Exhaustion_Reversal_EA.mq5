//+------------------------------------------------------------------+
//| RSI Exhaustion Reversal                                         |
//| Version: v1                                                     |
//| Author: Isaac Carvalho                                          |
//| Contact: isaacsilva100@gmail.com                                |
//| Copyright: © 2026 Isaac Carvalho. All rights reserved.          |
//|                                                                  |
//| RSI exhaustion reversal strategy for EURUSD.                    |
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"
#property copyright "© 2026 Isaac Carvalho. All rights reserved."
#property link      "mailto:isaacsilva100@gmail.com"
#property description "RSI Exhaustion Reversal v1"
#property description "Author: Isaac Carvalho"
#property description "Contact: isaacsilva100@gmail.com"
#property description "RSI exhaustion reversal strategy for EURUSD."
#property description "Intraday EURUSD RSI exhaustion reversal strategy."

#include <Trade/Trade.mqh>

CTrade trade;

//-------------------------------------------------------------------
// VISIBLE INPUTS
//-------------------------------------------------------------------
input group "=== CORE SETTINGS ==="
input ENUM_TIMEFRAMES InpTimeframe       = PERIOD_M5;   // Timeframe

input group "=== POSITION SIZE ==="
input double          InpFixedLot        = 1.00;        // Position Size

input group "=== EXECUTION ==="
input ulong           InpMagic           = 26092601;    // Magic Number

//-------------------------------------------------------------------
// HIDDEN CORE PARAMETERS
// These values define the validated EURUSD CORE and are intentionally
// not exposed in the Inputs menu.
//-------------------------------------------------------------------
const int      InpRSIPeriod             = 14;
const double   InpRSISellLevel          = 65.0;
const int      InpStartHourServer       = 14;
const int      InpEndHourServer         = 18;
const int      InpATRPeriod             = 14;
const double   InpMaxSpreadATR          = 0.15;
const double   InpStopATR               = 4.0;
const double   InpTakeATR               = 4.0;
const int      InpMaxBarsInTrade        = 96;
const bool     InpUseRiskPercent        = false;
const double   InpRiskPercent           = 1.0;
const int      InpDeviationPoints       = 20;

//-------------------------------------------------------------------
// CONSTANTS / STATE
//-------------------------------------------------------------------
string   EA_NAME    = "RSI Exhaustion Reversal";
string   EA_VERSION = "v1";

int      g_rsiHandle = INVALID_HANDLE;
int      g_atrHandle = INVALID_HANDLE;
datetime g_lastBarOpen = 0;
string   g_forcedExitReason = "";

//-------------------------------------------------------------------
// TESTER-ONLY RESTRICTION
//-------------------------------------------------------------------
bool IsAllowedEnvironment()
{
   return (bool)MQLInfoInteger(MQL_TESTER);
}

//-------------------------------------------------------------------
// INDICATOR HELPERS
//-------------------------------------------------------------------
double ReadBufferValue(const int handle,const int buffer,const int shift)
{
   if(handle==INVALID_HANDLE)
      return EMPTY_VALUE;

   double values[];
   ArraySetAsSeries(values,true);

   if(CopyBuffer(handle,buffer,shift,1,values)!=1)
      return EMPTY_VALUE;

   return values[0];
}

double GetRSI(const int shift)
{
   return ReadBufferValue(g_rsiHandle,0,shift);
}

double GetATR(const int shift)
{
   return ReadBufferValue(g_atrHandle,0,shift);
}

//-------------------------------------------------------------------
// VOLUME
//-------------------------------------------------------------------
int VolumeDigits()
{
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);

   if(step<=0.0)
      return 2;

   int digits=0;
   double value=step;

   while(digits<8 && MathAbs(value-MathRound(value))>1e-12)
   {
      value*=10.0;
      digits++;
   }

   return digits;
}

double NormalizeVolume(double volume)
{
   double minLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step  =SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);

   if(step<=0.0)
      step=0.01;

   volume=MathMax(minLot,MathMin(maxLot,volume));
   volume=MathFloor((volume+1e-12)/step)*step;

   return NormalizeDouble(volume,VolumeDigits());
}

double CalculateRiskVolume(const double entryPrice,const double stopPrice)
{
   if(!InpUseRiskPercent)
      return NormalizeVolume(InpFixedLot);

   if(InpRiskPercent<=0.0)
      return NormalizeVolume(InpFixedLot);

   double balance=AccountInfoDouble(ACCOUNT_BALANCE);
   double riskMoney=balance*(InpRiskPercent/100.0);

   double tickSize =SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);

   double stopDistance=MathAbs(entryPrice-stopPrice);

   if(riskMoney<=0.0 || tickSize<=0.0 || tickValue<=0.0 || stopDistance<=0.0)
      return NormalizeVolume(InpFixedLot);

   double moneyPerLot=(stopDistance/tickSize)*tickValue;

   if(moneyPerLot<=0.0)
      return NormalizeVolume(InpFixedLot);

   return NormalizeVolume(riskMoney/moneyPerLot);
}

//-------------------------------------------------------------------
// MARGIN SAFETY
//-------------------------------------------------------------------
bool HasEnoughMargin(const ENUM_ORDER_TYPE orderType,
                     const double volume,
                     const double price,
                     double &requiredMargin)
{
   requiredMargin=0.0;

   if(volume<=0.0 || price<=0.0)
      return false;

   if(!OrderCalcMargin(orderType,_Symbol,volume,price,requiredMargin))
   {
      Print(EA_NAME,": OrderCalcMargin failed. Error=",GetLastError());
      return false;
   }

   double freeMargin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   return (requiredMargin<=freeMargin);
}

double FitVolumeToAvailableMargin(const ENUM_ORDER_TYPE orderType,
                                  const double requestedVolume,
                                  const double price)
{
   double volume=NormalizeVolume(requestedVolume);
   double requiredMargin=0.0;

   if(HasEnoughMargin(orderType,volume,price,requiredMargin))
      return volume;

   double freeMargin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   double minLot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);

   if(step<=0.0)
      step=0.01;

   // Estimate an affordable volume from the margin ratio, then verify it.
   if(requiredMargin>0.0 && freeMargin>0.0)
      volume=NormalizeVolume(requestedVolume*(freeMargin*0.98/requiredMargin));

   if(volume>requestedVolume)
      volume=NormalizeVolume(requestedVolume);

   // If the estimated volume is still too large, reduce it by valid steps.
   while(volume>=minLot-1e-12)
   {
      if(HasEnoughMargin(orderType,volume,price,requiredMargin))
      {
         if(volume+1e-12<requestedVolume)
         {
            Print(EA_NAME,
                  ": requested volume ",
                  DoubleToString(requestedVolume,VolumeDigits()),
                  " reduced to ",
                  DoubleToString(volume,VolumeDigits()),
                  " due to available margin.");
         }
         return volume;
      }

      volume=NormalizeDouble(volume-step,VolumeDigits());
   }

   Print(EA_NAME,
         ": insufficient margin even for minimum volume on ",
         _Symbol,
         ". Trade skipped.");
   return 0.0;
}

//-------------------------------------------------------------------
// POSITION HELPERS
//-------------------------------------------------------------------
bool HasPositionOnSymbol()
{
   return PositionSelect(_Symbol);
}

bool IsOurPosition()
{
   if(!PositionSelect(_Symbol))
      return false;

   ulong magic=(ulong)PositionGetInteger(POSITION_MAGIC);
   return (magic==InpMagic);
}

int BarsSinceEntry()
{
   if(!IsOurPosition())
      return 0;

   datetime positionTime=(datetime)PositionGetInteger(POSITION_TIME);
   int shift=iBarShift(_Symbol,InpTimeframe,positionTime,false);

   if(shift<0)
      return 0;

   return shift;
}

//-------------------------------------------------------------------
// ENTRY
//-------------------------------------------------------------------
bool OpenSell(const datetime signalTime,const double atr,const double spreadATR)
{
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
      return false;

   double entry=tick.bid;
   double sl=entry+InpStopATR*atr;
   double tp=entry-InpTakeATR*atr;

   int digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   sl=NormalizeDouble(sl,digits);
   tp=NormalizeDouble(tp,digits);

   double volume=CalculateRiskVolume(entry,sl);
   volume=FitVolumeToAvailableMargin(ORDER_TYPE_SELL,volume,entry);

   if(volume<=0.0)
   {
      Print(EA_NAME,": no valid volume available for this trade.");
      return false;
   }

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   bool ok=trade.Sell(volume,_Symbol,0.0,sl,tp,EA_NAME);

   if(!ok)
   {
      Print(EA_NAME,
            ": sell order failed. Retcode=",
            trade.ResultRetcode(),
            " | ",
            trade.ResultRetcodeDescription());
      return false;
   }

   Print(EA_NAME,
         " | SELL opened",
         " | signal=",
         TimeToString(signalTime,TIME_DATE|TIME_MINUTES),
         " | volume=",
         DoubleToString(volume,VolumeDigits()),
         " | ATR=",
         DoubleToString(atr,_Digits),
         " | spread/ATR=",
         DoubleToString(spreadATR,3));

   return true;
}

void EvaluateEntry()
{
   if(HasPositionOnSymbol())
      return;

   datetime signalTime=iTime(_Symbol,InpTimeframe,1);

   if(signalTime==0)
      return;

   MqlDateTime signalDate;
   TimeToStruct(signalTime,signalDate);

   if(signalDate.hour<InpStartHourServer || signalDate.hour>=InpEndHourServer)
      return;

   double rsiNow =GetRSI(1);
   double rsiPrev=GetRSI(2);

   if(rsiNow==EMPTY_VALUE || rsiPrev==EMPTY_VALUE)
      return;

   // SELL exhaustion trigger:
   // RSI crosses the sell threshold from below to above.
   if(!(rsiPrev<InpRSISellLevel && rsiNow>=InpRSISellLevel))
      return;

   double atr=GetATR(1);

   if(atr==EMPTY_VALUE || atr<=0.0)
      return;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
      return;

   double spread=tick.ask-tick.bid;
   double spreadATR=spread/atr;

   if(spreadATR>InpMaxSpreadATR)
      return;

   OpenSell(signalTime,atr,spreadATR);
}

//-------------------------------------------------------------------
// TIMEOUT EXIT
//-------------------------------------------------------------------
void ManageTimeout()
{
   if(!IsOurPosition())
      return;

   if(BarsSinceEntry()<InpMaxBarsInTrade)
      return;

   g_forcedExitReason="TIMEOUT";

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpDeviationPoints);

   if(!trade.PositionClose(_Symbol))
   {
      Print(EA_NAME,
            ": timeout close failed. Retcode=",
            trade.ResultRetcode(),
            " | ",
            trade.ResultRetcodeDescription());
      g_forcedExitReason="";
   }
}

//-------------------------------------------------------------------
// MT5 EVENTS
//-------------------------------------------------------------------
int OnInit()
{
   if(!IsAllowedEnvironment())
   {
      Print(EA_NAME," ",EA_VERSION,
            " - Experimental version. Strategy Tester use only.");
      Print("Author: Isaac Carvalho | Contact: isaacsilva100@gmail.com");
      return INIT_FAILED;
   }

   if(InpTimeframe==PERIOD_CURRENT)
   {
      Print(EA_NAME,": PERIOD_CURRENT is not allowed. Select an explicit timeframe in the Inputs menu.");
      return INIT_PARAMETERS_INCORRECT;
   }

   if(InpRSIPeriod<=0 ||
      InpATRPeriod<=0 ||
      InpRSISellLevel<=0.0 ||
      InpRSISellLevel>=100.0 ||
      InpStartHourServer<0 ||
      InpStartHourServer>23 ||
      InpEndHourServer<1 ||
      InpEndHourServer>24 ||
      InpStartHourServer>=InpEndHourServer ||
      InpMaxSpreadATR<=0.0 ||
      InpStopATR<=0.0 ||
      InpTakeATR<=0.0 ||
      InpMaxBarsInTrade<=0 ||
      InpFixedLot<=0.0)
   {
      Print(EA_NAME,": invalid input parameters.");
      return INIT_PARAMETERS_INCORRECT;
   }

   g_rsiHandle=iRSI(_Symbol,InpTimeframe,InpRSIPeriod,PRICE_CLOSE);
   g_atrHandle=iATR(_Symbol,InpTimeframe,InpATRPeriod);

   if(g_rsiHandle==INVALID_HANDLE || g_atrHandle==INVALID_HANDLE)
   {
      Print(EA_NAME,": failed to create indicator handles. Error=",GetLastError());
      return INIT_FAILED;
   }

   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpDeviationPoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   g_lastBarOpen=iTime(_Symbol,InpTimeframe,0);

   Print(EA_NAME," ",EA_VERSION,
         " initialized in Strategy Tester.",
         " | Symbol=",_Symbol,
         " | Internal timeframe=",EnumToString(InpTimeframe),
         " | Sell RSI cross=",DoubleToString(InpRSISellLevel,1),
         " | Hours=",InpStartHourServer,"-",InpEndHourServer,
         " | Max spread/ATR=",DoubleToString(InpMaxSpreadATR,2),
         " | SL=",DoubleToString(InpStopATR,1)," ATR",
         " | TP=",DoubleToString(InpTakeATR,1)," ATR");

   return INIT_SUCCEEDED;
}

void OnTick()
{
   datetime currentBarOpen=iTime(_Symbol,InpTimeframe,0);

   if(currentBarOpen==0)
      return;

   if(currentBarOpen!=g_lastBarOpen)
   {
      g_lastBarOpen=currentBarOpen;

      ManageTimeout();

      if(!HasPositionOnSymbol())
         EvaluateEntry();
   }
}

void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD || trans.deal==0)
      return;

   if(!HistoryDealSelect(trans.deal))
      return;

   if(HistoryDealGetString(trans.deal,DEAL_SYMBOL)!=_Symbol)
      return;

   ulong magic=(ulong)HistoryDealGetInteger(trans.deal,DEAL_MAGIC);

   if(magic!=InpMagic)
      return;

   long entryType=HistoryDealGetInteger(trans.deal,DEAL_ENTRY);

   if(entryType!=DEAL_ENTRY_OUT && entryType!=DEAL_ENTRY_OUT_BY)
      return;

   long dealReason=HistoryDealGetInteger(trans.deal,DEAL_REASON);
   string reason=g_forcedExitReason;

   if(reason=="")
   {
      if(dealReason==DEAL_REASON_TP)
         reason="TP";
      else if(dealReason==DEAL_REASON_SL)
         reason="SL";
      else
         reason="OTHER";
   }

   double profit=HistoryDealGetDouble(trans.deal,DEAL_PROFIT);
   double commission=HistoryDealGetDouble(trans.deal,DEAL_COMMISSION);
   double swap=HistoryDealGetDouble(trans.deal,DEAL_SWAP);

   Print(EA_NAME,
         " | position closed",
         " | reason=",reason,
         " | profit=",DoubleToString(profit,2),
         " | commission=",DoubleToString(commission,2),
         " | swap=",DoubleToString(swap,2));

   g_forcedExitReason="";
}

void OnDeinit(const int reason)
{
   if(g_rsiHandle!=INVALID_HANDLE)
      IndicatorRelease(g_rsiHandle);

   if(g_atrHandle!=INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
}
//+------------------------------------------------------------------+

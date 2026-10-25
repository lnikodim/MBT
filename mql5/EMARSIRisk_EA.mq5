//+------------------------------------------------------------------+
//|                                         EMA_RSI_Risk_EA_MQL5.mq5 |
//| EMA crossover + RSI filter + risk-based sizing (MetaTrader 5)    |
//+------------------------------------------------------------------+
#property strict
#include <Trade/Trade.mqh>

CTrade trade;

//--- Inputs
input int    FastEMA          = 12;
input int    SlowEMA          = 26;
input int    RSIPeriod        = 14;
input int    RSI_Buy_Thresh   = 55;
input int    RSI_Sell_Thresh  = 45;
input double RiskPercent      = 1.0;   // % of equity per trade
input int    SL_Pips          = 30;
input int    TP_Pips          = 60;
input int    Trailing_Pips    = 20;    // 0 = off
input int    Breakeven_Pips   = 15;    // 0 = off
input int    MaxSpread_Points = 30;
input bool   TradeLong        = true;
input bool   TradeShort       = true;
input int    StartHour        = 1;     // server time
input int    EndHour          = 23;    // exclusive
input bool   OneTradePerBar   = true;
input ulong  MagicNumber      = 20250817;

//--- Globals
datetime lastBarTime = 0;

//--- Indicator handles
int hFastMA = INVALID_HANDLE;
int hSlowMA = INVALID_HANDLE;
int hRSI    = INVALID_HANDLE;

//------------------------- Helpers ---------------------------------
double PipSize()
{
   return (_Digits==3 || _Digits==5) ? (_Point*10.0) : _Point;
}

bool TradingWindow()
{
   MqlDateTime tm;
   TimeToStruct(TimeCurrent(), tm);
   int h = tm.hour;
   if (StartHour <= EndHour)  return (h >= StartHour && h < EndHour);
   return (h >= StartHour || h < EndHour); // overnight windows like 22→6
}

bool SpreadOK()
{
   long spread = (long)SymbolInfoInteger(_Symbol, SYMBOL_SPREAD); // points
   return (spread <= MaxSpread_Points);
}

double LotSizeByRisk(double stopPips)
{
   if (stopPips <= 0) return 0.0;

   double equity   = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskCash = equity * (RiskPercent/100.0);

   double tickVal  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double pip      = PipSize();

   if (tickVal<=0 || tickSize<=0) return 0.0;

   double pipValPerLot = tickVal * (pip / tickSize); // approx
   if (pipValPerLot<=0) return 0.0;

   double lots = riskCash / (stopPips * pipValPerLot);

   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   // snap to step
   lots = MathFloor(lots/lotStep)*lotStep;
   lots = MathMax(minLot, MathMin(lots, maxLot));

   int volDigits = (int)MathRound(-MathLog10(lotStep));
   return NormalizeDouble(lots, volDigits);
}

bool NewBar()
{
   datetime t = iTime(_Symbol, _Period, 0);
   if (t != lastBarTime)
   {
      lastBarTime = t;
      return true;
   }
   return false;
}

void ManageOpenPosition()
{
   double pip = PipSize();
   if (!PositionSelect(_Symbol)) return;

   long   type      = (long)PositionGetInteger(POSITION_TYPE);
   double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
   double sl        = PositionGetDouble(POSITION_SL);
   double tp        = PositionGetDouble(POSITION_TP);

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // broker stop distance (points)
   double minStopPts = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minStop    = minStopPts * _Point;

   if (type == POSITION_TYPE_BUY)
   {
      double profitPips = (bid - openPrice)/pip;
      double newSL = sl;

      if (Breakeven_Pips>0 && profitPips >= Breakeven_Pips)
         newSL = MathMax(newSL, openPrice);

      if (Trailing_Pips>0 && profitPips > Trailing_Pips)
      {
         double trailSL = bid - Trailing_Pips*pip;
         newSL = MathMax(newSL, trailSL);
      }

      // respect stop distance
      if (newSL>0 && (bid - newSL) >= minStop && newSL > sl)
         trade.PositionModify(_Symbol, newSL, tp);
   }
   else if (type == POSITION_TYPE_SELL)
   {
      double profitPips = (openPrice - ask)/pip;
      double newSL = sl;

      if (Breakeven_Pips>0 && profitPips >= Breakeven_Pips)
         newSL = (sl==0) ? openPrice : MathMin(newSL, openPrice);

      if (Trailing_Pips>0 && profitPips > Trailing_Pips)
      {
         double trailSL = ask + Trailing_Pips*pip;
         newSL = (sl==0) ? trailSL : MathMin(newSL, trailSL);
      }

      if (newSL>0 && (newSL - ask) >= minStop && (sl==0 || newSL < sl))
         trade.PositionModify(_Symbol, newSL, tp);
   }
}

//------------------------- EA Lifecycle ----------------------------
int OnInit()
{
   trade.SetExpertMagicNumber(MagicNumber);

   // create indicator handles (no shift params in MT5)
   hFastMA = iMA(_Symbol, _Period, FastEMA, 0, MODE_EMA, PRICE_CLOSE);
   hSlowMA = iMA(_Symbol, _Period, SlowEMA, 0, MODE_EMA, PRICE_CLOSE);
   hRSI    = iRSI(_Symbol, _Period, RSIPeriod, PRICE_CLOSE);

   if (hFastMA==INVALID_HANDLE || hSlowMA==INVALID_HANDLE || hRSI==INVALID_HANDLE)
   {
      Print("Indicator handle creation failed. fast=",hFastMA," slow=",hSlowMA," rsi=",hRSI);
      return(INIT_FAILED);
   }

   lastBarTime = iTime(_Symbol, _Period, 0);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if (hFastMA!=INVALID_HANDLE) IndicatorRelease(hFastMA);
   if (hSlowMA!=INVALID_HANDLE) IndicatorRelease(hSlowMA);
   if (hRSI   !=INVALID_HANDLE) IndicatorRelease(hRSI);
}

void OnTick()
{
   ManageOpenPosition();

   if (!TradingWindow() || !SpreadOK()) return;
   if (OneTradePerBar && !NewBar())     return;

   //--- Read indicator values from buffers
   double fastBuf[2], slowBuf[2], rsiBuf[1];
   if (CopyBuffer(hFastMA, 0, 1, 2, fastBuf) != 2) return;   // 1=last closed bar, need 2 bars
   if (CopyBuffer(hSlowMA, 0, 1, 2, slowBuf) != 2) return;
   if (CopyBuffer(hRSI,    0, 1, 1, rsiBuf)  != 1) return;

   double fastNow  = fastBuf[0];
   double fastPrev = fastBuf[1];
   double slowNow  = slowBuf[0];
   double slowPrev = slowBuf[1];
   double rsi      = rsiBuf[0];

   bool bullCross = (fastPrev <= slowPrev) && (fastNow > slowNow);
   bool bearCross = (fastPrev >= slowPrev) && (fastNow < slowNow);

   double pip = PipSize();
   bool hasPos = PositionSelect(_Symbol);

   // volume by risk
   double lots = LotSizeByRisk(SL_Pips);
   if (lots <= 0) return;

   // min stop distance
   double minStopPts = (double)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minStop    = minStopPts * _Point;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   int    p   = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   // BUY
   if (TradeLong && bullCross && rsi >= RSI_Buy_Thresh && !hasPos)
   {
     double sl = ask - SL_Pips*pip;
     double tp = ask + TP_Pips*pip;

     // enforce broker stop distance
     if ((ask - sl) < minStop) sl = ask - MathMax(minStop, SL_Pips*pip);
     if ((tp - ask) < minStop) tp = ask + MathMax(minStop, TP_Pips*pip);

     sl = NormalizeDouble(sl, p);
     tp = NormalizeDouble(tp, p);

     // price = 0.0 uses current market price (safer than passing Ask)
     trade.Buy(lots, _Symbol, 0.0, sl, tp, "EMA-RSI Buy");
   }

   // SELL
   if (TradeShort && bearCross && rsi <= RSI_Sell_Thresh && !hasPos)
   {
     double sl = bid + SL_Pips*pip;
     double tp = bid - TP_Pips*pip;

     if ((sl - bid) < minStop) sl = bid + MathMax(minStop, SL_Pips*pip);
     if ((bid - tp) < minStop) tp = bid - MathMax(minStop, TP_Pips*pip);

     sl = NormalizeDouble(sl, p);
     tp = NormalizeDouble(tp, p);

     trade.Sell(lots, _Symbol, 0.0, sl, tp, "EMA-RSI Sell");
   }
}
//+------------------------------------------------------------------+

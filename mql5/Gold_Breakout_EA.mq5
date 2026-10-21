//+------------------------------------------------------------------+
//|                                              GoldBreakoutEA.mq5  |
//|                                                      Ali Rajput  |
//|                                                                  |
//| Turtle-style Donchian breakout EA, built for XAUUSD H4.          |
//|                                                                  |
//| Entry: a closed bar closes beyond the highest high (lowest low)  |
//| of the previous N bars, and the bar before it did not. The EA    |
//| enters at the open of the next bar with a stop k x ATR away.     |
//|                                                                  |
//| Exit, chosen with InpExitMode:                                   |
//|   A. ATR trail: the stop trails the best price by m x ATR        |
//|   B. Turtle exit: the stop follows the M-bar opposite channel    |
//|   C. Fixed target: take profit at a fixed R multiple (default)   |
//|                                                                  |
//| One position at a time. Lots are sized from the stop distance    |
//| with OrderCalcProfit(), because SYMBOL_TRADE_TICK_VALUE is wrong |
//| for gold on some servers. The order goes out without stops, and  |
//| the stops are attached to the real fill. If they cannot be       |
//| attached, the position is closed at once.                        |
//|                                                                  |
//| Default: buys only with the EMA 200 filter. In 2020-2026 gold    |
//| rose most of the time and sell breakouts lost money overall.     |
//| Turn InpAllowShort on if you expect gold to fall.                |
//|                                                                  |
//| Same signal rules as the Breakout Exit Lab indicator.            |
//| Past results do not promise future profit. Demo first.           |
//+------------------------------------------------------------------+
#property copyright "Ali Rajput"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Includes                                                         |
//+------------------------------------------------------------------+
#include <Trade/Trade.mqh>

//+------------------------------------------------------------------+
//| Exit method                                                      |
//+------------------------------------------------------------------+
enum ENUM_EXIT_MODE
  {
   EXIT_ATR_TRAIL = 0,                                 // A. ATR trail
   EXIT_CHANNEL   = 1,                                 // B. Turtle exit channel
   EXIT_FIXED     = 2                                  // C. Fixed target
  };

//+------------------------------------------------------------------+
//| Input parameters                                                 |
//+------------------------------------------------------------------+
input group "=== Entry ==="
input int            InpEntryBars       = 20;          // Entry channel, bars
input int            InpATRPeriod       = 20;          // ATR period
input double         InpStopATR         = 2.0;         // Initial stop, ATR multiples
input bool           InpUseTrend        = true;        // Only trade on the side of the trend EMA
input int            InpTrendEMA        = 200;         // Trend EMA period (chart timeframe)
input bool           InpAllowLong       = true;        // Take buy breakouts
input bool           InpAllowShort      = false;       // Take sell breakouts (off: shorts lost money on gold 2020-2026)

input group "=== Exit ==="
input ENUM_EXIT_MODE InpExitMode        = EXIT_FIXED;  // Exit method
input double         InpTargetR         = 2.0;         // C: take profit, R multiples
input double         InpTrailATR        = 3.0;         // A: trail distance, ATR multiples
input int            InpExitBars        = 10;          // B: exit channel, bars

input group "=== Risk ==="
input double         InpRiskPercent     = 1.0;         // Risk per trade, % of balance
input double         InpMaxSpreadToRisk = 0.10;        // Skip if the spread is more than this share of the stop
input int            InpSlippagePoints  = 50;          // Allowed slippage, points
input bool           InpCloseFriday     = false;       // Close before the weekend
input int            InpFridayHour      = 20;          // Friday server hour for that close (checked at each new bar)
input ulong          InpMagic           = 555001;      // Magic number

//+------------------------------------------------------------------+
//| Global objects and state                                         |
//+------------------------------------------------------------------+
CTrade   trade;                                        // trade helper
int      g_atrHandle   = INVALID_HANDLE;               // ATR on the chart timeframe
int      g_emaHandle   = INVALID_HANDLE;               // trend EMA
datetime g_lastBar     = 0;                            // last bar seen by IsNewBar()
long     g_posId       = 0;                            // identifier of our open position
double   g_entry       = 0.0;                          // its fill price
double   g_risk        = 0.0;                          // entry to initial stop, price units
double   g_best        = 0.0;                          // best price since entry (exit A)
int      g_modFails    = 0;                            // failed stop moves in a row

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpEntryBars < 2 || InpExitBars < 2 || InpATRPeriod < 1 || InpStopATR <= 0.0)
      return(INIT_PARAMETERS_INCORRECT);
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpSlippagePoints);
   trade.SetTypeFillingBySymbol(_Symbol);

   g_atrHandle = iATR(_Symbol, _Period, InpATRPeriod);
   if(g_atrHandle == INVALID_HANDLE)
      return(INIT_FAILED);
   if(InpUseTrend)
     {
      g_emaHandle = iMA(_Symbol, _Period, InpTrendEMA, 0, MODE_EMA, PRICE_CLOSE);
      if(g_emaHandle == INVALID_HANDLE)
         return(INIT_FAILED);
     }

   //--- pick up a position left open by a restart
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk != 0 && PositionGetString(POSITION_SYMBOL) == _Symbol
         && (ulong)PositionGetInteger(POSITION_MAGIC) == InpMagic)
        {
         g_posId = PositionGetInteger(POSITION_IDENTIFIER);
         g_entry = PositionGetDouble(POSITION_PRICE_OPEN);
         g_risk  = MathAbs(g_entry - PositionGetDouble(POSITION_SL));
         g_best  = g_entry;
        }
     }
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(g_atrHandle != INVALID_HANDLE)
      IndicatorRelease(g_atrHandle);
   if(g_emaHandle != INVALID_HANDLE)
      IndicatorRelease(g_emaHandle);
  }

//+------------------------------------------------------------------+
//| Tester function                                                  |
//| Print the headline numbers into the journal                      |
//+------------------------------------------------------------------+
double OnTester()
  {
   PrintFormat("TESTER STATS | trades %.0f | net profit %.2f | gross profit %.2f | gross loss %.2f"
               " | profit factor %.2f | max equity DD %.2f%% | max balance DD %.2f%% | sharpe %.2f",
               TesterStatistics(STAT_TRADES), TesterStatistics(STAT_PROFIT),
               TesterStatistics(STAT_GROSS_PROFIT), TesterStatistics(STAT_GROSS_LOSS),
               TesterStatistics(STAT_PROFIT_FACTOR), TesterStatistics(STAT_EQUITY_DDREL_PERCENT),
               TesterStatistics(STAT_BALANCE_DDREL_PERCENT), TesterStatistics(STAT_SHARPE_RATIO));
   return(TesterStatistics(STAT_PROFIT_FACTOR));
  }

//+------------------------------------------------------------------+
//| IsNewBar                                                         |
//| True once per bar of the chart timeframe                         |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   datetime t = iTime(_Symbol, _Period, 0);
   if(t == g_lastBar)
      return(false);
   g_lastBar = t;
   return(true);
  }

//+------------------------------------------------------------------+
//| MarketOpenForEntry                                               |
//| Trade session open and not ending within 15 minutes              |
//+------------------------------------------------------------------+
bool MarketOpenForEntry()
  {
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int      nowSec = dt.hour * 3600 + dt.min * 60 + dt.sec;
   datetime from, to;
   for(uint i = 0; SymbolInfoSessionTrade(_Symbol, (ENUM_DAY_OF_WEEK)dt.day_of_week, i, from, to); i++)
      if(nowSec >= (int)from && nowSec < (int)to - 900)
         return(true);
   return(false);
  }

//+------------------------------------------------------------------+
//| FridayCutoff                                                     |
//| True from the Friday close hour, when that option is on          |
//+------------------------------------------------------------------+
bool FridayCutoff()
  {
   if(!InpCloseFriday)
      return(false);
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   return(dt.day_of_week == 5 && dt.hour >= InpFridayHour);
  }

//+------------------------------------------------------------------+
//| LotForRisk                                                       |
//| Volume that loses InpRiskPercent of balance over riskDist        |
//+------------------------------------------------------------------+
double LotForRisk(const double riskDist)
  {
   double ask  = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double pnl  = 0.0;
   if(ask <= 0.0 || step <= 0.0 || riskDist <= 0.0)
      return(0.0);
   //--- money lost on one lot over the stop distance, asked from the server
   if(!OrderCalcProfit(ORDER_TYPE_BUY, _Symbol, 1.0, ask, ask - riskDist, pnl) || pnl >= 0.0)
      return(0.0);
   double risk = AccountInfoDouble(ACCOUNT_BALANCE) * InpRiskPercent / 100.0;
   double lot  = MathFloor(risk / (-pnl) / step) * step;
   lot = MathMin(lot, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
   if(lot < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
      return(0.0);
   return(NormalizeDouble(lot, 2));
  }

//+------------------------------------------------------------------+
//| FindTicket                                                       |
//| Ticket of our open position, 0 if it is gone                     |
//+------------------------------------------------------------------+
ulong FindTicket()
  {
   if(g_posId == 0)
      return(0);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      ulong tk = PositionGetTicket(i);
      if(tk != 0 && PositionGetInteger(POSITION_IDENTIFIER) == g_posId)
         return(tk);
     }
   return(0);
  }

//+------------------------------------------------------------------+
//| CheckBreakout                                                    |
//| +1 buy, -1 sell, 0 none, for the bar that just closed (shift 1)  |
//+------------------------------------------------------------------+
int CheckBreakout()
  {
   int    need = InpEntryBars + 3;
   double h[], l[], c[];
   ArraySetAsSeries(h, true);
   ArraySetAsSeries(l, true);
   ArraySetAsSeries(c, true);
   if(CopyHigh(_Symbol, _Period, 0, need, h) < need || CopyLow(_Symbol, _Period, 0, need, l) < need
      || CopyClose(_Symbol, _Period, 0, need, c) < need)
      return(0);

   //--- channel of the N bars before shift 1, and before shift 2
   double up = h[2], dn = l[2], upPrev = h[3], dnPrev = l[3];
   for(int k = 2; k < 2 + InpEntryBars; k++)
     {
      up = MathMax(up, h[k]);
      dn = MathMin(dn, l[k]);
     }
   for(int k = 3; k < 3 + InpEntryBars; k++)
     {
      upPrev = MathMax(upPrev, h[k]);
      dnPrev = MathMin(dnPrev, l[k]);
     }

   int dir = 0;
   if(c[1] > up && c[2] <= upPrev)
      dir = 1;
   if(c[1] < dn && c[2] >= dnPrev)
      dir = -1;
   if(dir == 0 || (dir == 1 && !InpAllowLong) || (dir == -1 && !InpAllowShort))
      return(0);

   if(InpUseTrend)
     {
      double ema[1];
      if(CopyBuffer(g_emaHandle, 0, 1, 1, ema) < 1)
         return(0);
      if((dir == 1 && c[1] < ema[0]) || (dir == -1 && c[1] > ema[0]))
         return(0);
     }
   return(dir);
  }

//+------------------------------------------------------------------+
//| OpenTrade                                                        |
//| Size, send without stops, then attach them to the real fill      |
//+------------------------------------------------------------------+
void OpenTrade(const bool isBuy)
  {
   if(!MarketOpenForEntry() || FridayCutoff())
      return;
   double atr[1];
   if(CopyBuffer(g_atrHandle, 0, 1, 1, atr) < 1 || atr[0] <= 0.0)
      return;

   double riskDist = InpStopATR * atr[0];
   double spread   = SymbolInfoDouble(_Symbol, SYMBOL_ASK) - SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(spread > InpMaxSpreadToRisk * riskDist)
     {
      PrintFormat("Breakout skipped: spread %.2f is too wide for a %.2f stop.", spread, riskDist);
      return;
     }
   double lot = LotForRisk(riskDist);
   if(lot <= 0.0)
     {
      Print("Breakout skipped: the risk is too small for the minimum lot.");
      return;
     }
   double price  = isBuy ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double margin = 0.0;
   if(OrderCalcMargin(isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, lot, price, margin)
      && margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
     {
      PrintFormat("Breakout skipped: %.2f lots needs %.2f margin.", lot, margin);
      return;
     }

   bool sent = isBuy ? trade.Buy(lot, _Symbol, 0.0, 0.0, 0.0, "GoldBreakout")
                     : trade.Sell(lot, _Symbol, 0.0, 0.0, 0.0, "GoldBreakout");
   if(!sent || trade.ResultDeal() == 0)
     {
      PrintFormat("Order failed: %u %s", trade.ResultRetcode(), trade.ResultRetcodeDescription());
      return;
     }

   //--- the position this deal created
   g_posId = 0;
   if(HistoryDealSelect(trade.ResultDeal()))
      g_posId = HistoryDealGetInteger(trade.ResultDeal(), DEAL_POSITION_ID);
   ulong tk = FindTicket();
   if(tk == 0 || !PositionSelectByTicket(tk))
      return;

   //--- stops from the real fill, outside the broker's minimum distance
   double fill   = PositionGetDouble(POSITION_PRICE_OPEN);
   double minGap = (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) + 5) * _Point;
   double r      = MathMax(riskDist, minGap);
   double sl     = NormalizeDouble(isBuy ? fill - r : fill + r, _Digits);
   double tp     = 0.0;
   if(InpExitMode == EXIT_FIXED)
      tp = NormalizeDouble(isBuy ? fill + InpTargetR * r : fill - InpTargetR * r, _Digits);

   if(!trade.PositionModify(tk, sl, tp))
     {
      //--- never leave a position without a stop
      Print("Stop attach failed, closing the position: ", trade.ResultRetcodeDescription());
      trade.PositionClose(tk);
      g_posId = 0;
      return;
     }
   g_entry    = fill;
   g_risk     = r;
   g_best     = fill;
   g_modFails = 0;
   PrintFormat("Entered %s at %.2f, SL %.2f, TP %.2f, lot %.2f", isBuy ? "BUY" : "SELL", fill, sl, tp, lot);
  }

//+------------------------------------------------------------------+
//| ManagePosition                                                   |
//| Once per bar: forget a closed position, trail the stop (A, B),   |
//| optional Friday close                                            |
//+------------------------------------------------------------------+
void ManagePosition()
  {
   if(g_posId == 0)
      return;
   ulong tk = FindTicket();
   if(tk == 0 || !PositionSelectByTicket(tk))
     {
      g_posId = 0;                  // closed by the stop or the target
      return;
     }
   if(FridayCutoff())
     {
      trade.PositionClose(tk);
      return;
     }
   if(InpExitMode == EXIT_FIXED || !MarketOpenForEntry())
      return;

   bool   isBuy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
   double curSL = PositionGetDouble(POSITION_SL);
   double newSL = curSL;

   //--- the bar that just closed decides the new stop
   double hi1 = iHigh(_Symbol, _Period, 1), lo1 = iLow(_Symbol, _Period, 1);
   g_best = isBuy ? MathMax(g_best, hi1) : MathMin(g_best, lo1);
   if(InpExitMode == EXIT_ATR_TRAIL)
     {
      double atr[1];
      if(CopyBuffer(g_atrHandle, 0, 1, 1, atr) < 1 || atr[0] <= 0.0)
         return;
      newSL = isBuy ? g_best - InpTrailATR * atr[0] : g_best + InpTrailATR * atr[0];
     }
   else
     {
      double ch[];
      ArraySetAsSeries(ch, true);
      if(isBuy ? CopyLow(_Symbol, _Period, 1, InpExitBars, ch) < InpExitBars
               : CopyHigh(_Symbol, _Period, 1, InpExitBars, ch) < InpExitBars)
         return;
      newSL = isBuy ? ch[ArrayMinimum(ch)] : ch[ArrayMaximum(ch)];
     }
   newSL = NormalizeDouble(newSL, _Digits);

   //--- only tighten, keep the broker's minimum distance, cap retries
   double bid    = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask    = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double minGap = (SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) + 5) * _Point;
   bool   better = isBuy ? newSL > curSL + _Point : newSL < curSL - _Point;
   bool   roomOk = isBuy ? bid - newSL > minGap : newSL - ask > minGap;
   if(!better || !roomOk || g_modFails >= 3)
      return;
   if(trade.PositionModify(tk, newSL, PositionGetDouble(POSITION_TP)))
      g_modFails = 0;
   else
      g_modFails++;
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!IsNewBar())
      return;
   ManagePosition();
   if(g_posId != 0)
      return;
   int dir = CheckBreakout();
   if(dir != 0)
      OpenTrade(dir == 1);
  }
//+------------------------------------------------------------------+

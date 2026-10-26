//+------------------------------------------------------------------+
//|                                            SessionReopenEA.mq5  |
//|      One trade a night at the CME gold reopen, and the honest    |
//|      size of what that is worth                                  |
//+------------------------------------------------------------------+
#property copyright "SessionReopenEA"
#property version   "1.00"
#property description "Buys gold at the first hour after the CME daily maintenance break and"
#property description "holds for a fixed time with a volatility-scaled server-side stop. One"
#property description "trade per session, no averaging, no grid, no martingale."
#property description ""
#property description "Measured over 11 years: +1.60 bps per trade AFTER the execution cost was"
#property description "corrected against a real-tick backtest, t=3.42, 10 of 11 years positive."
#property description "That is about +3.3% a year on the capital exposed. It is a small, slow"
#property description "edge and the header says so - read WHAT IT IS NOT before running it."
#property strict


//+------------------------------------------------------------------+
//| WHAT THIS IS, AND WHAT IT IS NOT                                  |
//|                                                                   |
//| WHAT IT IS. Gold has a daily maintenance break on the CME. The    |
//| first hour of trading after it rises more than chance explains.   |
//| Measured on 11 years of hourly data, entering at the reopen and   |
//| holding two hours with a volatility-scaled stop:                  |
//|                                                                   |
//|     +3.34 bps per trade, t = 7.40, 59.3% winners, PF 1.63,        |
//|     positive in all 11 calendar years, while EVERY other hour     |
//|     of the day measures flat (|t| < 2).                           |
//|                                                                   |
//| Then the cost model turned out to be wrong. A real-tick backtest  |
//| in MT5 showed the true round-trip cost at the reopen is about 60  |
//| points, not the 19 the research had charged - the M1 bar `spread` |
//| field is a per-bar summary and understates the reopen spread by   |
//| roughly three times. Re-running 11 years at the corrected cost:   |
//|                                                                   |
//|     +1.60 bps per trade, t = 3.42, 50.8% winners, PF 1.30,        |
//|     10 of 11 years positive, return/drawdown 6.5                  |
//|                                                                   |
//| The edge survives, at LESS THAN HALF the original strength, and   |
//| the win rate becomes a coin flip carried by a favourable payoff   |
//| rather than by frequency. That second number is the real one.     |
//|                                                                   |
//| WHAT IT IS NOT. It is not a living. On capital sized for a 20%    |
//| drawdown it measures about +3.3% a year with 4.6% maximum         |
//| drawdown, Sharpe 1.23, roughly 200 trades a year - which means    |
//| roughly one year in nine is negative. At 0.01 lots that is about  |
//| 130 currency units a year, and that figure measures the POSITION  |
//| SIZE, not the strategy.                                           |
//|                                                                   |
//| A 2.5-year window of it, taken alone, gives t = +1.12 - not       |
//| significant. A profitable two-year backtest of this proves        |
//| nothing by itself; the 11-year sample is what carries it.         |
//|                                                                   |
//| Test it yourself before believing any of the above, and test it   |
//| with "every tick based on real ticks". On bar-modelled data this  |
//| project once turned a -15,627 result into +79,000 without         |
//| changing a line of code.                                          |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>

input group "--- Entry window (SERVER time) ---"
// The break is anchored to the 17:00-18:00 New York maintenance window, and this broker's clock follows
// US daylight saving, so the reopen sits at a FIXED server hour all year (01:00). Working in server time
// is therefore DST-proof, whereas a UTC-based trigger would drift by an hour twice a year.
input int    InpEntryHour      = 1;      // Server hour of the reopen
input int    InpEntryWindowMin = 10;     // Only enter within this many minutes of the hour
input int    InpHoldHours      = 2;      // Hours to hold before closing on time

input group "--- Which sessions ---"
// The weekly reopen behaves differently from the daily ones: measured over 479 Sundays it is +1.11 bps
// with t=0.88 (indistinguishable from noise), against +3.90 bps and t=8.32 for the daily reopens. That
// Sunday 22:00 UTC reopen lands on MONDAY 01:00 in server time - which is why the skip is on Monday and
// the traded days are Tuesday to Friday.
input bool   InpSkipMonday     = true;   // Skip the weekly reopen (Monday here)

input group "--- Risk ---"
input double InpLots           = 0.01;   // Fixed lot - no scaling, ever
// 2.0 rather than the 1.5 the first version used. The real-tick backtest showed execution costs about
// 40 points/trade more than the research charged, which makes every stop-out relatively more expensive:
// at the true cost 1.5x gives +1.60 bps (t=3.42) while 2.0x gives +1.91 (t=4.07) and is hit on 1.3% of
// trades instead of 2.6%. Wider still keeps improving, but the stop is what bounds a tail event, and
// "remove the stop, the backtest improves" is exactly the reasoning that made the grid look profitable.
input double InpStopAtrMult    = 2.0;    // Stop = this x the mean hourly range
input int    InpRangeBars      = 480;    // H1 bars in the mean-range unit (480 = ~20 sessions)
// Left at 60 on purpose: the real-tick backtest ran with this cap and took 530 of ~530 available
// sessions, so it never bound on real quotes. Raising it "to be safe" would make the live EA differ from
// the configuration that was actually validated.
input int    InpMaxSpreadPts   = 60;     // Refuse to enter if the spread is worse than this

input group "--- Identification ---"
input long   InpMagic          = 77701;  // Change if another EA here uses it

CTrade   g_trade;
datetime g_lastEntry = 0;    // server time of our most recent entry, so one session = one trade

//+------------------------------------------------------------------+
int OnInit()
{
   if(InpLots <= 0 || InpHoldHours <= 0 || InpStopAtrMult <= 0 || InpRangeBars < 24)
      return INIT_PARAMETERS_INCORRECT;

   g_trade.SetExpertMagicNumber(InpMagic);
   g_trade.SetTypeFillingBySymbol(_Symbol);

   // Re-derive the last entry from history rather than assuming none: a restart inside the entry window
   // would otherwise open a second position for the same session.
   g_lastEntry = LastEntryFromHistory();

   double mr = MeanRange();
   Print("SessionReopen on ", _Symbol, " | entry ", InpEntryHour, ":00 server (+", InpEntryWindowMin, "min)",
         " hold ", InpHoldHours, "h | stop ", DoubleToString(InpStopAtrMult, 2), " x mean range",
         " (now ", DoubleToString(mr, 2), " -> ", DoubleToString(InpStopAtrMult * mr, 2), " $)",
         " | skipMonday=", InpSkipMonday, " | lots ", DoubleToString(InpLots, 2));

   // Il lotto si risolve gia' qui, cosi' chi attacca l'EA sa subito cosa verra' tradato
   // invece di scoprirlo dal primo ordine - o, peggio, dal saldo.
   BrokerLots(InpLots, true);
   if(g_lastEntry > 0)
      Print("SessionReopen: last entry found in history at ", TimeToString(g_lastEntry), " (server time)");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Summarise();
}

//+------------------------------------------------------------------+
void OnTick()
{
   ulong ticket = OpenTicket();
   if(ticket != 0)
   {
      ManageOpen(ticket);
      return;                 // never two positions at once
   }
   TryEnter();
}

//+------------------------------------------------------------------+
//| The lot the BROKER will accept, from the lot that was asked for.  |
//|                                                                   |
//| Added after the MQL5 CodeBase validator rejected every single      |
//| order with "Invalid volume" while testing on EURUSD: the EA sent   |
//| InpLots straight to Buy() and never looked at what the symbol      |
//| actually allows. 0.01 is valid on most gold symbols and is not     |
//| universal - minimum, maximum and step all vary by symbol and by    |
//| broker, and a volume off the step is rejected outright.            |
//|                                                                   |
//| It clamps and rounds, and it SAYS SO. Silently trading ten times   |
//| the size that was asked for is the failure mode that costs real    |
//| money - an open-source system lost 20.5% in fifteen days that way, |
//| rounding a 0.0006 lot up to a 0.01 minimum. Here the clamp is      |
//| printed once at start and again on the first order, so the number  |
//| actually being traded is never a surprise.                         |
//+------------------------------------------------------------------+
double BrokerLots(double wanted, bool announce)
{
   double vmin  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double vstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   if(vstep <= 0.0)
      vstep = 0.01;

   double lots = wanted;
   if(vmin > 0.0 && lots < vmin)
      lots = vmin;
   if(vmax > 0.0 && lots > vmax)
      lots = vmax;

   lots = MathRound(lots / vstep) * vstep;
   int digits = (int)MathMax(0, MathCeil(-MathLog10(vstep) - 0.0000001));
   lots = NormalizeDouble(lots, digits);

   if(announce && MathAbs(lots - wanted) > 1e-8)
      PrintFormat("SessionReopen: WARNING - %.2f lots is not tradable on %s "
                  "(min %.2f, max %.2f, step %.2f). Trading %.2f instead, which is "
                  "%.1f times the size you asked for.",
                  wanted, _Symbol, vmin, vmax, vstep, lots,
                  (wanted > 0 ? lots / wanted : 0.0));
   return lots;
}

//+------------------------------------------------------------------+
//| The volatility unit: mean hourly range over the last N complete   |
//| H1 bars. Deliberately mean(high-low) and not iATR() - that is     |
//| what the research measured, and true range would include the      |
//| break gap, making the stop wider than the one that was tested.    |
//+------------------------------------------------------------------+
double MeanRange()
{
   double hi[], lo[];
   if(CopyHigh(_Symbol, PERIOD_H1, 1, InpRangeBars, hi) < InpRangeBars) return 0.0;
   if(CopyLow(_Symbol, PERIOD_H1, 1, InpRangeBars, lo) < InpRangeBars) return 0.0;
   double sum = 0;
   for(int i = 0; i < InpRangeBars; i++)
      sum += (hi[i] - lo[i]);
   return sum / InpRangeBars;
}

//+------------------------------------------------------------------+
ulong OpenTicket()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(t == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != InpMagic) continue;
      return t;
   }
   return 0;
}

//+------------------------------------------------------------------+
//| Time exit. The stop is a real server-side SL, so it needs no code |
//| here - and it keeps protecting the position if this EA stops      |
//| running, which is the exposure most grid EAs carry.              |
//+------------------------------------------------------------------+
void ManageOpen(ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return;
   datetime opened = (datetime)PositionGetInteger(POSITION_TIME);
   if(TimeCurrent() >= opened + InpHoldHours * 3600)
   {
      double pl = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      if(g_trade.PositionClose(ticket))
         Print("SessionReopen: time exit after ", InpHoldHours, "h, P/L=", DoubleToString(pl, 2));
      else
         Print("SessionReopen: WARNING time exit failed, retcode=", g_trade.ResultRetcode(),
               " ", g_trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
void TryEnter()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(dt.hour != InpEntryHour || dt.min >= InpEntryWindowMin)
      return;
   if(InpSkipMonday && dt.day_of_week == 1)      // Monday server = the weekly (Sunday UTC) reopen
      return;
   // One trade per session: any entry within the last 12h means this session is already done.
   if(g_lastEntry > 0 && TimeCurrent() - g_lastEntry < 12 * 3600)
      return;

   long spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD);
   if(spread > InpMaxSpreadPts)
   {
      // Safety valve, not part of the edge: the research measured a median 17-point spread at the reopen,
      // so this only fires on a genuinely broken quote. Logged because a filter that silently removes
      // trades would quietly change what is being tested.
      Print("SessionReopen: skipping entry, spread ", spread, " pts > limit ", InpMaxSpreadPts);
      return;
   }

   double range = MeanRange();
   if(range <= 0)
   {
      Print("SessionReopen: skipping entry, not enough H1 history for the range unit");
      return;
   }

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double sl  = NormalizeDouble(ask - InpStopAtrMult * range, _Digits);

   // Respect the broker's minimum stop distance, or the order is simply rejected.
   long stopsLevel = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist = stopsLevel * SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(minDist > 0 && ask - sl < minDist)
      sl = NormalizeDouble(ask - minDist, _Digits);

   // UN SOLO TENTATIVO PER SESSIONE, riuscito o no.
   //
   // Prima g_lastEntry veniva impostato solo in caso di successo, quindi dopo un rifiuto
   // l'EA riprovava al tick dopo, e a quello dopo ancora. Il validatore del CodeBase l'ha
   // mostrato senza appello: un ordine fallito al secondo per tutta la finestra d'ingresso.
   // Un EA che martella il broker dopo un rifiuto e' rotto su qualunque broker - il rifiuto
   // e' un'informazione, non un invito a insistere.
   g_lastEntry = TimeCurrent();

   double lots = BrokerLots(InpLots, true);
   if(lots <= 0.0)
   {
      Print("SessionReopen: cannot resolve a tradable lot size on ", _Symbol, " - no entry.");
      return;
   }

   // CAN THE ACCOUNT AFFORD IT? Asked before sending, not discovered from the rejection.
   //
   // This check exists because the previous fix created the need for it. Clamping the lot up
   // to the symbol minimum makes the EA work on brokers whose minimum is larger than the lot
   // you asked for - but on a small account that same clamp turns a 0.01 request into a
   // position the balance cannot carry. The CodeBase validator showed it immediately: on a
   // 1.00 account with a 0.20 minimum, every session sent an order needing 220 of margin and
   // got "No money" back.
   //
   // An order the account cannot carry is not a trading decision, it is a mistake sent to the
   // broker. So the margin is computed first and the entry is skipped with a message that says
   // what would have been needed - which is also the number a reader needs in order to size
   // the account, and it is not printed anywhere else.
   double needed = 0.0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lots, ask, needed))
   {
      Print("SessionReopen: cannot compute the margin for ", DoubleToString(lots, 2),
            " lots on ", _Symbol, " - no entry.");
      return;
   }
   double free = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(needed > free)
   {
      PrintFormat("SessionReopen: skipping entry - %.2f lots on %s needs %.2f of margin and "
                  "only %.2f is free. The smallest tradable size on this symbol already asks "
                  "for more than this account has.",
                  lots, _Symbol, needed, free);
      return;
   }

   if(g_trade.Buy(lots, _Symbol, 0, sl, 0, "reopen"))
   {
      Print("SessionReopen: BUY ", DoubleToString(lots, 2), " at ", DoubleToString(ask, _Digits),
            " sl ", DoubleToString(sl, _Digits), " (", DoubleToString(ask - sl, 2), " $ away)",
            " spread ", spread, " pts | ", TimeToString(TimeCurrent()), " server");
   }
   else
   {
      Print("SessionReopen: BUY FAILED retcode=", g_trade.ResultRetcode(), " ",
            g_trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
datetime LastEntryFromHistory()
{
   if(!HistorySelect(TimeCurrent() - 7 * 24 * 3600, TimeCurrent()))
      return 0;
   datetime latest = 0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_IN) continue;
      datetime t = (datetime)HistoryDealGetInteger(d, DEAL_TIME);
      if(t > latest) latest = t;
   }
   return latest;
}

//+------------------------------------------------------------------+
//| End-of-run summary. The tester's own report covers the account as |
//| a whole; this reports THIS magic only, and in basis points, which |
//| is the unit the research is stated in - dollars are not           |
//| comparable across a sample where gold tripled.                    |
//+------------------------------------------------------------------+
void Summarise()
{
   if(!HistorySelect(0, TimeCurrent()))
      return;

   int trades = 0, wins = 0, stopped = 0;
   double net = 0, bpsSum = 0;
   int total = HistoryDealsTotal();
   for(int i = 0; i < total; i++)
   {
      ulong d = HistoryDealGetTicket(i);
      if(d == 0) continue;
      if(HistoryDealGetString(d, DEAL_SYMBOL) != _Symbol) continue;
      if(HistoryDealGetInteger(d, DEAL_MAGIC) != InpMagic) continue;
      if((ENUM_DEAL_ENTRY)HistoryDealGetInteger(d, DEAL_ENTRY) != DEAL_ENTRY_OUT) continue;

      double pl = HistoryDealGetDouble(d, DEAL_PROFIT)
                + HistoryDealGetDouble(d, DEAL_SWAP)
                + HistoryDealGetDouble(d, DEAL_COMMISSION);
      double price = HistoryDealGetDouble(d, DEAL_PRICE);
      trades++;
      net += pl;
      if(pl > 0) wins++;
      if(HistoryDealGetInteger(d, DEAL_REASON) == DEAL_REASON_SL) stopped++;
      // BASIS POINTS FROM THE VOLUME THAT WAS ACTUALLY TRADED, not the one that was asked for.
      //
      // This used InpLots, which was the same thing until the lot started being clamped to the
      // broker's minimum. On a symbol whose minimum is twenty times the requested size, the
      // summary would have divided a twenty-times-larger P/L by the small number and reported
      // an edge twenty times too big - a wrong number produced by a correct fix elsewhere,
      // which is the kind that survives review.
      double vol = HistoryDealGetDouble(d, DEAL_VOLUME);
      if(price > 0 && vol > 0)
         bpsSum += (pl / (vol * 100.0)) / price * 1e4;
   }

   Print("=== SessionReopen SUMMARY ===================================");
   Print("  trades=", trades, "  wins=", wins,
         trades > 0 ? StringFormat(" (%.1f%%)", 100.0 * wins / trades) : "",
         "  stopped out=", stopped);
   Print("  net=", DoubleToString(net, 2), " account currency",
         trades > 0 ? StringFormat("  avg %.4f", net / trades) : "");
   if(trades > 0)
      Print("  avg ", DoubleToString(bpsSum / trades, 2), " bps per trade",
            "  (research said +3.34 bps with a 1.5 x range stop)");
   Print("==========================================================");
}

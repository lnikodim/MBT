//+------------------------------------------------------------------+
//|                                              GBPJPY_Monday.mq5   |
//|                                        Copyright Orangutang Trading |
//|                                                                  |
//|  ATTACH TO: GBPJPY, M1 chart.                                    |
//|                                                                  |
//|  Buys GBPJPY at 11:00 SERVER time on MONDAY.                     |
//|  Closes it at 23:00 SERVER time the same day.                    |
//|  Monday only. One trade a week. Long only. No stop loss.         |
//|                                                                  |
//|  Execution only. No panel, no statistics, no dynamic sizing.     |
//+------------------------------------------------------------------+
//
//  WHICH CHART
//    Attach the EA to a GBPJPY chart. It trades the symbol of the chart it is attached to, so
//    on any other symbol it would trade that symbol instead, using rules researched on GBPJPY.
//    Use the M1 timeframe. The logic runs on a one second timer and does not read bars, so the
//    timeframe does not change the trades, but M1 is the setting the results were produced on.
//
//  WHEN IT TRADES
//    Day:    Monday only (InpDayMask = 1).
//    Entry:  11:00 server time, or up to 5 minutes later if the terminal is late.
//    Exit:   23:00 server time, the same Monday.
//    Hold:   12 hours, from the European morning through the New York session.
//    It is flat before the 00:00 server roll, so it never pays swap.
//
//  THE SERVER TIME IT WAS TESTED ON
//    GMT+3 in summer and GMT+2 in winter, switching with US daylight saving. This is the
//    "New York close" server time most MetaTrader brokers use. On such a server the trade is
//    always 04:00 to 16:00 New York time, all year round.
//
//                     Summer (server GMT+3)       Winter (server GMT+2)
//      Server         11:00  ->  23:00            11:00  ->  23:00
//      New York       04:00  ->  16:00            04:00  ->  16:00
//      UTC / GMT      08:00  ->  20:00            09:00  ->  21:00
//      London         09:00  ->  21:00            09:00  ->  21:00
//      Stockholm      10:00  ->  22:00            10:00  ->  22:00
//      Tokyo          17:00  ->  05:00 Tue        18:00  ->  06:00 Tue
//
//    For a few weeks in March and in October/November, the US and Europe change clocks on
//    different dates, and London and Stockholm times shift by one hour during that gap.
//
//    If your broker uses a different server time, the EA still enters at 11:00 SERVER time,
//    which is a different real-world hour. Change InpEntryHour and InpExitHour so the trade
//    runs 04:00 to 16:00 New York time. The EA prints your server's GMT offset when it starts.
//
//  THE TRADE
//    Robust to timing. In backtest the trade stays profitable with the entry moved anywhere
//    from 09:00 to 13:00 server time, 11:00 plus or minus two hours. An edge that only works
//    at one exact minute is usually noise. One that survives a four hour window is far less
//    likely to be. InpEntryHour can be moved inside that window without breaking the trade.
//
//  WHY MONDAY, AND WHY THAT IS NOT JUST BEING LONG A RISING MARKET
//    A long-only trade in a market that rose for five years is positive on almost ANY subset
//    of days, so "Monday pays" proves nothing on its own. The real test is to run the same
//    trade on Tuesday to Friday with InpDayMask and compare. Run it yourself: the inputs are
//    all here.
//
//  VALIDATION CODE AT THE BOTTOM OF THIS FILE
//    The last section, VALIDATION, exists only so the EA passes the automatic tests that run
//    it on other symbols and timeframes. It is NOT part of the trade and changes nothing on
//    GBPJPY. Read the notes there before judging the strategy by it.
//
//  NO STOP LOSS
//    The trade is a timed hold. It exits on the clock, not on price. A large move against the
//    position during the 12 hours is taken in full. Size accordingly.
//
#property copyright "Orangutang Trading"
#property version   "1.30"
#property strict
#property description "Attach to GBPJPY, M1. Buys Monday 11:00 server time, closes 23:00 server time."
#property description "Tested on a GMT+3 summer / GMT+2 winter server: 04:00 to 16:00 New York time."
#property description "Monday only. Long only. No stop loss. Flat before the roll, so no swap."

#include <Trade/Trade.mqh>
#include <Trade/PositionInfo.mqh>

//======================================================================================
//  SIZE
//======================================================================================
input double InpLots             = 0.05;   // Lot size (base 0.05)

//======================================================================================
//  THE WINDOW -- SERVER time. Defaults assume a GMT+3 summer / GMT+2 winter server,
//  where 11:00 -> 23:00 server is 04:00 -> 16:00 New York.
//======================================================================================
input int    InpEntryHour        = 11;     // Entry hour, SERVER time (11 = 04:00 New York, tested 09-13)
input int    InpEntryMin         = 0;      // Entry minute
input int    InpExitHour         = 23;     // Exit hour, SERVER time (23 = 16:00 New York)
input int    InpExitMin          = 0;      // Exit minute
input int    InpEntryGraceMin    = 5;      // Still enter up to this many minutes late

//--- Mon=1 Tue=2 Wed=4 Thu=8 Fri=16, added together. 1 is Monday alone, which is the whole
//--- trade.
input int    InpDayMask          = 1;      // Days to trade: 1=Mon only (default) 2=Tue 4=Wed 8=Thu 16=Fri

//======================================================================================
//  THE TWO GUARDS, and only these two
//======================================================================================
//  Spread. A guard against broken quotes, not a tuning parameter. Normal GBPJPY spreads sit
//  well under 1.5 pips; the filter exists to refuse the rare quote that does not.
input double InpMaxSpreadPips    = 1.5;    // Skip the trade above this spread, in pips

//--- Margin. One check: would opening this position leave the account below this level?
input double InpMinMarginLevel   = 300.0;  // Do not open if margin level would fall under this

//======================================================================================
//  IDENTITY
//======================================================================================
input long   InpMagic            = 770531; // Magic number
input bool   InpDemoOnly         = true;   // Refuse to start on a live account

input int    InpMaxSlippagePts   = 20;     // Maximum slippage, in points
input int    InpMaxRetries       = 3;      // Order attempts before giving up

//--- defined in the VALIDATION section at the bottom of the file
double CheckedVolume(double lots);
bool   SpreadGuardApplies();

CTrade         Trade;
CPositionInfo  Pos;

string   gSym = "";
int      SRV_IN = 0, SRV_OUT = 0;
bool     gOpen = false;
bool     gDoneToday = false;
datetime gDay = 0;

//+------------------------------------------------------------------+
//| helpers                                                          |
//+------------------------------------------------------------------+
datetime SrvDay() { return((datetime)((long)TimeCurrent() / 86400 * 86400)); }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int SrvMin()
  {
   MqlDateTime t;
   TimeToStruct(TimeCurrent(), t);
   return(t.hour * 60 + t.min);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ArmedToday()
  {
   MqlDateTime t;
   TimeToStruct(TimeCurrent(), t);
   if(t.day_of_week < 1 || t.day_of_week > 5)
      return(false);
   return((InpDayMask & (1 << (t.day_of_week - 1))) != 0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double SpreadPips()
  {
   double pt = SymbolInfoDouble(gSym, SYMBOL_POINT);
   if(pt <= 0)
      return(9999.0);
   double sp = (SymbolInfoDouble(gSym, SYMBOL_ASK) - SymbolInfoDouble(gSym, SYMBOL_BID)) / pt;
   int dg = (int)SymbolInfoInteger(gSym, SYMBOL_DIGITS);
//--- on a 5- or 3-digit quote one pip is ten points
   return((dg == 5 || dg == 3) ? sp / 10.0 : sp);
  }

//--- Days in the mask, written out, so the start-up log says exactly what will trade.
string DaysText()
  {
   string names[5] = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday"};
   string s = "";
   for(int i = 0; i < 5; i++)
      if((InpDayMask & (1 << i)) != 0)
         s += (s == "" ? "" : ", ") + names[i];
   return(s);
  }

//--- Clock time shifted by a number of hours, as HH:MM, wrapping past midnight.
string ShiftedTime(int minutes, int hours)
  {
   int m = ((minutes + hours * 60) % 1440 + 1440) % 1440;
   return(StringFormat("%02d:%02d", m / 60, m % 60));
  }

//--- A restart must not lose track of a live trade. gOpen lives in memory only, so without this
//--- the EA would come back believing it is flat and would never close the position.
void RestoreOpen()
  {
   gOpen = false;
   if(!Pos.SelectByMagic(gSym, InpMagic))
      return;
   gOpen = true;
   gDoneToday = true;
   PrintFormat("restored an open position: %.2f lots from %s",
               Pos.Volume(), TimeToString(Pos.Time(), TIME_DATE | TIME_MINUTES));
  }

//--- The one portfolio guard. Margin level is account-wide, so this looks at the whole account
//--- rather than only this EA's own position: a liquidation takes everything.
bool MarginOk(double lots, string &why)
  {
   double eq   = AccountInfoDouble(ACCOUNT_EQUITY);
   double used = AccountInfoDouble(ACCOUNT_MARGIN);
   double ask  = SymbolInfoDouble(gSym, SYMBOL_ASK);
   double need = 0;
   if(eq <= 0)
     {
      why = "no equity";
      return(false);
     }
   if(ask <= 0)
     {
      why = "no quote";
      return(false);
     }
   if(!OrderCalcMargin(ORDER_TYPE_BUY, gSym, lots, ask, need))
     { why = "margin calculation failed"; return(false); }
   double lvl = (used + need) > 0 ? eq / (used + need) * 100.0 : 999999.0;
   if(lvl < InpMinMarginLevel)
     {
      why = StringFormat("margin level would be %.0f%%, floor is %.0f%%", lvl, InpMinMarginLevel);
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| open and close                                                   |
//+------------------------------------------------------------------+
void TryOpen()
  {
   gDoneToday = true;          // one attempt a day, whatever happens below

   double lots = CheckedVolume(InpLots);
   if(lots <= 0)
     { Print("no trade -- no valid volume for ", gSym); return; }

   double pips = SpreadPips();
   if(SpreadGuardApplies() && pips > InpMaxSpreadPips)
     {
      PrintFormat("no trade -- spread %.2f pips over the %.2f limit", pips, InpMaxSpreadPips);
      return;
     }

   string why = "";
   if(!MarginOk(lots, why))
     { Print("no trade -- ", why); return; }

   for(int a = 0; a < InpMaxRetries; a++)
     {
      if(Trade.Buy(lots, gSym, 0, 0, 0, "GBPJPY Monday") &&
         Trade.ResultRetcode() == TRADE_RETCODE_DONE)
        {
         gOpen = true;
         PrintFormat("BUY %.2f at %.3f  (spread %.2f pips, margin level %.0f%%)",
                     lots, Trade.ResultPrice(), pips,
                     AccountInfoDouble(ACCOUNT_MARGIN) > 0
                     ? AccountInfoDouble(ACCOUNT_EQUITY)
                     / AccountInfoDouble(ACCOUNT_MARGIN) * 100.0 : 0);
         return;
        }
      PrintFormat("buy attempt %d failed: %d %s", a + 1, Trade.ResultRetcode(),
                  Trade.ResultRetcodeDescription());
      Sleep(300);
     }
   Print("no trade -- all order attempts failed");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TryClose()
  {
   if(!Pos.SelectByMagic(gSym, InpMagic))
     {
      gOpen = false;
      return;
     }
   for(int a = 0; a < InpMaxRetries; a++)
     {
      double prof = Pos.Profit() + Pos.Swap();
      if(Trade.PositionClose(Pos.Ticket(), InpMaxSlippagePts) &&
         Trade.ResultRetcode() == TRADE_RETCODE_DONE)
        {
         gOpen = false;
         PrintFormat("CLOSED at %.3f  (%+.2f %s)", Trade.ResultPrice(), prof,
                     AccountInfoString(ACCOUNT_CURRENCY));
         return;
        }
      PrintFormat("close attempt %d failed: %d %s", a + 1, Trade.ResultRetcode(),
                  Trade.ResultRetcodeDescription());
      Sleep(300);
     }
   Print("*** COULD NOT CLOSE -- the position is still open, close it by hand ***");
  }

//+------------------------------------------------------------------+
//| lifecycle                                                        |
//+------------------------------------------------------------------+
int OnInit()
  {
   gSym = _Symbol;

//--- This EA is built for GBPJPY on an M1 chart. It does not block other charts, but it says
//--- so loudly, because on another symbol it would trade that symbol with GBPJPY rules.
   string sym = gSym;
   StringToUpper(sym);
   if(StringFind(sym, "GBPJPY") < 0)
     {
      string msg = StringFormat("GBPJPY Monday is built for GBPJPY. It is attached to %s and will "
                                "trade %s with rules researched on GBPJPY.", gSym, gSym);
      Print("WARNING: ", msg);
      if(!MQLInfoInteger(MQL_TESTER))
         Alert(msg);
     }
   if(_Period != PERIOD_M1)
      PrintFormat("NOTE: attach to an M1 chart. Current chart is %s. The trades are the same "
                  "on any timeframe, but M1 is the setting the results were produced on.",
                  EnumToString(_Period));

   if(InpDemoOnly && (ENUM_ACCOUNT_TRADE_MODE)AccountInfoInteger(ACCOUNT_TRADE_MODE)
      != ACCOUNT_TRADE_MODE_DEMO)
     { Print("REFUSING TO START: not a demo account. Set InpDemoOnly = false to trade live."); return(INIT_FAILED); }

   SRV_IN  = InpEntryHour * 60 + InpEntryMin;
   SRV_OUT = InpExitHour * 60 + InpExitMin;
   if(SRV_OUT <= SRV_IN)
     {
      Print("REFUSING TO START: the exit must be after the entry on the same day.");
      return(INIT_FAILED);
     }
   if(InpDayMask < 1 || InpDayMask > 31)
     { Print("REFUSING TO START: InpDayMask must be 1 to 31."); return(INIT_FAILED); }
   if(InpLots <= 0)
     { Print("REFUSING TO START: InpLots must be above zero."); return(INIT_FAILED); }

   Trade.SetExpertMagicNumber(InpMagic);
   Trade.SetDeviationInPoints(InpMaxSlippagePts);
   Trade.SetTypeFillingBySymbol(gSym);

   gDay = SrvDay();
//--- if the EA starts mid-window, do not open late: the window is the trade
   gDoneToday = (ArmedToday() && SrvMin() >= SRV_IN + InpEntryGraceMin);
   RestoreOpen();

//--- Say exactly when it trades, in server time and in UTC, so there is no guessing.
   int gmtOffset = (int)MathRound((double)(TimeCurrent() - TimeGMT()) / 3600.0);
   PrintFormat("SYMBOL %s | DAYS %s | ENTRY %02d:%02d server | EXIT %02d:%02d server",
               gSym, DaysText(), SRV_IN / 60, SRV_IN % 60, SRV_OUT / 60, SRV_OUT % 60);

   if(!MQLInfoInteger(MQL_TESTER))
     {
      PrintFormat("Your server is GMT%+d, so entry is %s UTC and exit is %s UTC.",
                  gmtOffset, ShiftedTime(SRV_IN, -gmtOffset), ShiftedTime(SRV_OUT, -gmtOffset));
      if(gmtOffset != 2 && gmtOffset != 3)
         PrintFormat("WARNING: tested on a GMT+2 (winter) / GMT+3 (summer) server. Yours is GMT%+d, "
                     "so 11:00 server is a different real-world hour. Adjust InpEntryHour and "
                     "InpExitHour so the trade runs 04:00 to 16:00 New York time.", gmtOffset);
     }

   PrintFormat("GBPJPY Monday ready. %.3f lots, magic %d.", InpLots, (int)InpMagic);
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }

void OnDeinit(const int reason) { EventKillTimer(); }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer()
  {
   datetime d = SrvDay();
   if(d != gDay)
     {
      gDay = d;
      gDoneToday = false;
     }

   int now = SrvMin();

//--- close first, so an exit is never delayed by anything below it
   if(gOpen)
     {
      if(!Pos.SelectByMagic(gSym, InpMagic))
        {
         gOpen = false;
         return;
        }
      if(now >= SRV_OUT)
         TryClose();
      return;
     }

   if(gDoneToday)
      return;
   if(!ArmedToday())
      return;
   if(now < SRV_IN)
      return;
//--- Enter in the entry minute, or within InpEntryGraceMin after it. Demanding the exact
//--- minute fails in the Strategy Tester, whose clock advances in sparse jumps and can step
//--- straight over one minute, and live whenever the terminal stalls. Filling a few minutes
//--- late costs very little on a twelve hour hold; skipping the day costs the whole trade.
   if(now > SRV_IN + InpEntryGraceMin)
     {
      gDoneToday = true;
      PrintFormat("no trade -- entry minute %02d:%02d missed by more than %d minutes (now %02d:%02d)",
                  SRV_IN / 60, SRV_IN % 60, InpEntryGraceMin, now / 60, now % 60);
      return;
     }
   TryOpen();
  }
//+------------------------------------------------------------------+

//======================================================================================
//
//  VALIDATION -- NOT PART OF THE TRADE
//
//  Before this EA is published, an automatic check runs it on several symbols and
//  timeframes it was never designed for, such as EURUSD H1, XAUUSD D1 and EURUSD M1, on
//  netting accounts. It must place trades on all of them without errors, or it is rejected.
//
//  Two parts of the EA break on those tests, and the two functions below fix them. Neither
//  changes a single trade on GBPJPY, the symbol the strategy was built and tested on.
//
//  1. CheckedVolume()   -- fixes [Invalid volume]
//     Every symbol has its own minimum lot, maximum lot and lot step. A size that is valid on
//     GBPJPY can be refused on another symbol: the test account rejected 0.03 on EURUSD.
//     This rounds the requested size down to the nearest valid step and keeps it inside the
//     symbol's minimum and maximum. On a standard GBPJPY contract, with a 0.01 step, the
//     default 0.05 is already valid and passes through unchanged.
//
//  2. SpreadGuardApplies()  -- prevents "there are no trading operations"
//     The spread guard is measured in pips, and pips only mean the same thing on forex quotes
//     with 3 or 5 digits. Gold, indices and other instruments are quoted differently, where a
//     normal spread would read as several "pips" and the guard would refuse every trade.
//     So the guard applies to 3- and 5-digit quotes only. GBPJPY is quoted with 3 digits, so
//     on GBPJPY the guard always applies, exactly as designed.
//
//  If you only ever run this on GBPJPY, you can read this section once and ignore it.
//
//======================================================================================

//--- A lot size the symbol will accept, or 0 if none can be formed.
double CheckedVolume(double lots)
  {
   double vmin  = SymbolInfoDouble(gSym, SYMBOL_VOLUME_MIN);
   double vmax  = SymbolInfoDouble(gSym, SYMBOL_VOLUME_MAX);
   double vstep = SymbolInfoDouble(gSym, SYMBOL_VOLUME_STEP);

   if(vstep > 0)
      lots = MathFloor(lots / vstep + 1e-9) * vstep;

   if(vmin > 0 && lots < vmin)
      lots = vmin;

   if(vmax > 0 && lots > vmax)
      lots = vmax;

   int stepDigits = 0;
   if(vstep > 0)
      stepDigits = (int)MathMax(0, MathCeil(-MathLog10(vstep) - 1e-9));

   return(NormalizeDouble(lots, stepDigits));
  }

//--- True where the pip-based spread guard means what it says: 3- and 5-digit forex quotes.
bool SpreadGuardApplies()
  {
   int dg = (int)SymbolInfoInteger(gSym, SYMBOL_DIGITS);
   return(dg == 3 || dg == 5);
  }
//+------------------------------------------------------------------+
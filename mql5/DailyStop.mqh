//+------------------------------------------------------------------+
//| DailyStop.mqh -- MBT                                              |
//| EACore's daily loss stop for the EAs not built on EACore.         |
//|                                                                  |
//| DailyStop(magic) runs every tick or timer. Account equity at or   |
//| below the day-start balance minus InpDailyLossPct % turns it on   |
//| until the next server day: it closes this EA's positions (magic + |
//| symbol) and returns true, so the EA opens nothing more today. The |
//| day-start balance is rebuilt from the deal history, so a restart  |
//| keeps it. 0 = off.                                                |
//|                                                                  |
//| Include it inside the EA's "2. Account protection" input group   |
//| (docs/ea-inputs.md): its input has no group of its own.           |
//+------------------------------------------------------------------+
#ifndef DAILY_STOP_MQH
#define DAILY_STOP_MQH

#include <Trade\Trade.mqh>

#ifndef EA_DAILY_LOSS_PCT
#define EA_DAILY_LOSS_PCT 0.0           // an EA may #define a different compiled default before including
#endif

input double InpDailyLossPct = EA_DAILY_LOSS_PCT;   // Daily loss limit, % of day start (0 = off)

datetime g_dsDay     = 0;
double   g_dsBalance = 0.0;
bool     g_dsOn      = false;
long     g_dsLogin   = 0;
datetime g_dsTried   = 0;

//--- balance at time t: today's balance minus the trading P/L booked since (EACore's BalanceAt)
double DailyStop_BalanceAt(const datetime t)
  {
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   if(!HistorySelect(t, TimeCurrent() + 86400))
      return(bal);
   for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
     {
      const ulong d = HistoryDealGetTicket(i);
      const long  k = HistoryDealGetInteger(d, DEAL_TYPE);
      if(d != 0 && k != DEAL_TYPE_BALANCE && k != DEAL_TYPE_CREDIT)
         bal -= HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) +
                HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
     }
   return(bal);
  }

bool DailyStop(const ulong magic)
  {
   if(InpDailyLossPct <= 0.0)
      return(false);
   const long login = AccountInfoInteger(ACCOUNT_LOGIN);
   if(login != g_dsLogin)
     {
      g_dsLogin = login;               // account switched: the cached balance belongs to the old account
      g_dsDay   = 0;
     }
   if(!MQLInfoInteger(MQL_TESTER) && !TerminalInfoInteger(TERMINAL_CONNECTED))
      return(g_dsOn);                  // balance and history may still be the previous account's
   const datetime now = TimeCurrent();
   const datetime day = now - now % 86400;
   if(day != g_dsDay)
     {
      g_dsDay     = day;
      g_dsBalance = DailyStop_BalanceAt(day);
      g_dsOn      = false;
     }
   const double floor = g_dsBalance * (1.0 - InpDailyLossPct / 100.0);
   if(!g_dsOn)
     {
      if(AccountInfoDouble(ACCOUNT_EQUITY) > floor)
         return(false);
      g_dsOn = true;
      PrintFormat("DAILY STOP: equity %.2f <= floor %.2f (-%.1f%% of day start %.2f) -- closing own positions, no entries until next server day",
                  AccountInfoDouble(ACCOUNT_EQUITY), floor, InpDailyLossPct, g_dsBalance);
     }
   if(now - g_dsTried < 10)
      return(true);                    // a failed close (market closed, requote) is retried every 10 seconds
   g_dsTried = now;
   CTrade dsTrade;
   dsTrade.SetExpertMagicNumber(magic);
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      const ulong ticket = PositionGetTicket(i);
      if(ticket == 0 || PositionGetInteger(POSITION_MAGIC) != (long)magic || PositionGetString(POSITION_SYMBOL) != _Symbol)
         continue;
      if(dsTrade.PositionClose(ticket))
         PrintFormat("DAILY STOP: closed #%I64u", ticket);
      else
         PrintFormat("DAILY STOP: close #%I64u failed: %u %s -- retrying", ticket, dsTrade.ResultRetcode(), dsTrade.ResultRetcodeDescription());
     }
   return(true);
  }

#endif

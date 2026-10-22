//+------------------------------------------------------------------+
//| AccountThrottle.mqh -- MBT                                        |
//| Account-level drawdown throttle (spec 2026-10-22-dd-reduction).   |
//|                                                                  |
//| ThrottleFactor() is the risk multiplier for a new entry:          |
//| InpThrottleFactor while the account's closed trading P/L is at    |
//| least InpThrottleDDPct % of the initial deposit below its running |
//| high, otherwise 1.0. It reads the whole account deal history, so  |
//| every EA on the account sees the same drawdown. Deposits and      |
//| withdrawals (balance deals) do not move it. 0 = off.              |
//+------------------------------------------------------------------+
#ifndef ACCOUNT_THROTTLE_MQH
#define ACCOUNT_THROTTLE_MQH

#ifndef ACCOUNT_THROTTLE_DD_PCT
#define ACCOUNT_THROTTLE_DD_PCT 0.0     // an EA may #define a different compiled default before including
#endif

input group "=== Account drawdown throttle ==="
input double InpThrottleDDPct  = ACCOUNT_THROTTLE_DD_PCT;   // Cut risk when closed P/L is this % of the initial deposit below its high (0 = off)
input double InpThrottleFactor = 0.5;   // Risk multiplier while the account is in that drawdown

double ThrottleFactor()
  {
   if(InpThrottleDDPct <= 0.0)
      return(1.0);
   if(!HistorySelect(0, TimeCurrent()))
     {
      Print("AccountThrottle: deal history not available - sizing at the throttled risk.");
      return(InpThrottleFactor);
     }
   double initial = 0.0, pnl = 0.0, peak = 0.0;
   const int n = HistoryDealsTotal();
   for(int i = 0; i < n; i++)
     {
      const ulong d = HistoryDealGetTicket(i);
      const long type = HistoryDealGetInteger(d, DEAL_TYPE);
      const double v = HistoryDealGetDouble(d, DEAL_PROFIT) + HistoryDealGetDouble(d, DEAL_SWAP) +
                       HistoryDealGetDouble(d, DEAL_COMMISSION) + HistoryDealGetDouble(d, DEAL_FEE);
      if(type == DEAL_TYPE_BALANCE)
        {
         if(initial <= 0.0 && v > 0.0)
            initial = v;                       // the first deposit is the initial balance
         continue;
        }
      if(type != DEAL_TYPE_BUY && type != DEAL_TYPE_SELL)
         continue;                             // credits, bonuses, corrections: not trading P/L
      pnl += v;
      peak = MathMax(peak, pnl);
     }
   if(initial <= 0.0)
      initial = AccountInfoDouble(ACCOUNT_BALANCE) - pnl;
   return((peak - pnl) >= initial * InpThrottleDDPct / 100.0 ? InpThrottleFactor : 1.0);
  }

#endif

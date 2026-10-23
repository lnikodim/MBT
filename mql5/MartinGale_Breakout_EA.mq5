


#property copyright "Müller Péter"
#property link      "https://www.mql5.com/en/users/mullerp04/seller"
#property version   "1.00"
#include <ExpertFunctions.mqh>

input int TakeProfPoints = 50;
input double BalancePercentageAvailable = 50;
input double TP_Percentage_of_Balance = 0.1;
input double SL_Percentage_of_Balance = 10;
input double Start_The_Recovery = 0.1;
input double TP_Points_Multiplier = 1;
input int MagicNumber = 89758029;

CTrade Trading;


int OnInit()
  {
   Trading.SetExpertMagicNumber(MagicNumber);
   Trading.SetDeviationInPoints(50);
   return(INIT_SUCCEEDED);
  }


void OnTick()
{
   double Balance = AccountInfoDouble(ACCOUNT_BALANCE);
   static double StopLoss = SL_Percentage_of_Balance*Start_The_Recovery*Balance/100;
   static double TakeProfit = TP_Percentage_of_Balance*Balance/100;
   double CurrentProfit = Profits(MagicNumber,_Symbol);
   static bool Recovering = false;
   if(CurrentProfit < -StopLoss || CurrentProfit >TakeProfit)
   {
      if(CurrentProfit < -StopLoss && StopLoss < SL_Percentage_of_Balance/100*Balance)
      {
         CloseAllOrders(_Symbol,MagicNumber);
         TakeProfit -= CurrentProfit;
         StopLoss = SL_Percentage_of_Balance/100*Balance;
         Recovering = true;
         return;
      }
      CloseAllOrders(_Symbol,MagicNumber);
      TakeProfit = TP_Percentage_of_Balance/100*Balance;
      StopLoss = SL_Percentage_of_Balance/100*Balance*Start_The_Recovery;
      Recovering = false;
      return;
   }
   if(!IsNewCandle() || TotalopenOrders(MagicNumber,_Symbol) || !MarketOpen())
      return;
   double ask = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   if(BullBreakout(_Symbol,PERIOD_CURRENT))
   {
      double Vol;
      if(Recovering)
         Vol = RoundtoLots(CalcLotWithTP(TakeProfit,ask,ask+TakeProfPoints*TP_Points_Multiplier*_Point));
      else Vol = RoundtoLots(CalcLotWithTP(TakeProfit,ask,ask+TakeProfPoints*_Point));
      if(Vol*LotSize() < Balance*BalancePercentageAvailable/100 && CheckVolumeValue(Vol))
      {
         Trading.Buy(Vol);
      }
   }
   if(BearBreakout(_Symbol,PERIOD_CURRENT))
   {
      double Vol;
      if(Recovering)
         Vol = RoundtoLots(CalcLotWithTP(TakeProfit,bid,bid-TakeProfPoints*TP_Points_Multiplier*_Point));
      else Vol = RoundtoLots(CalcLotWithTP(TakeProfit,bid,bid-TakeProfPoints*_Point));
      if(Vol*LotSize() < Balance*BalancePercentageAvailable/100 && CheckVolumeValue(Vol))
      {
         Trading.Sell(Vol);
      }
   }

}
//+------------------------------------------------------------------+

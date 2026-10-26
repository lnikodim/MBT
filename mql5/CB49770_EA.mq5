//+------------------------------------------------------------------+
//| Probability theory.mq5                                           |
//| Copyright 2024                                                   |
//| https://www.mql5.com/ru/users/koshtenko                          |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property link      "https://www.mql5.com/ru/users/koshtenko"
#property version   "1.00"
#property description "Calculates probabilities for bullish and bearish scenarios"
#property strict

#define HISTORY_BARS 1000 // количество баров истории
input double Lots        = 0.1;      // лот
input double Risk    = 2;     // риск
input int StopLoss      = 0;        // лось
input int TakeProfit    = 0;        // язь
input int ClasterBars=50; // кластер
input int Pips=400; // дельта
input int    Magic      = 777;    // Magic
input int    CloseSig  = 0;    // CloseSig
#include <Trade\Trade.mqh>
CTrade trade;
int bullcount, bearcount;
double bull, bear;
datetime t=0;
double delta_min, delta_max;
input bool EnableCheckBars = false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   trade.SetExpertMagicNumber(Magic);
   CheckBars();
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment("");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckBars()
  {
   bullcount=0;
   bearcount=0;
   delta_min=1000;
   delta_max=-10;
   for(int i=HISTORY_BARS-ClasterBars; i>=0; i-=ClasterBars)
     {
      if(iClose(NULL,0,i+ClasterBars)>iOpen(NULL,0,i) && iClose(NULL,0,i+ClasterBars)-iOpen(NULL,0,i)>=Pips*_Point)
         bullcount++;
      if(iClose(NULL,0,i+ClasterBars)<iOpen(NULL,0,i) && iOpen(NULL,0,i)-iClose(NULL,0,i+ClasterBars)>=Pips*_Point)
         bearcount++;
      if(MathAbs(iClose(NULL,0,i+ClasterBars)-iOpen(NULL,0,i))>delta_max)
         delta_max=MathAbs(iClose(NULL,0,i+ClasterBars)-iOpen(NULL,0,i));
      if(MathAbs(iClose(NULL,0,i+ClasterBars)-iOpen(NULL,0,i))<delta_min)
         delta_min=MathAbs(iClose(NULL,0,i+ClasterBars)-iOpen(NULL,0,i));
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int CountTrades()
  {
   int count=0;

   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(PositionSelectByTicket(PositionGetTicket(i)))
        {
         if(PositionGetString(POSITION_SYMBOL)==_Symbol)
           {
            count++;
           }
        }
     }
   return(count);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAll(int type=-1)
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
     {
      if(PositionSelectByTicket(PositionGetTicket(i)))
        {
         if(PositionGetInteger(POSITION_MAGIC)==Magic)
           {
            if(PositionGetInteger(POSITION_TYPE)==type || type==-1)
               trade.PositionClose(PositionGetTicket(i));
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Lot()
  {
   double lot=Lots;

   if(Risk>0)
      lot=AccountInfoDouble(ACCOUNT_BALANCE)*Risk/100000;

   return(NormalizeDouble(lot,2));
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   static bool enableCheckBars = EnableCheckBars;
   if(!enableCheckBars)
      return;

   if(t!=iTime(NULL,0,0))
     {
      CheckBars();
      t=iTime(NULL,0,0);
     }
   if(bullcount>0 && bearcount>0)
     {
      bull=NormalizeDouble(bullcount*100/(bullcount+bearcount),2);
      bear=NormalizeDouble(bearcount*100/(bullcount+bearcount),2);
     }

   string comment="\n\n";
   comment+=StringFormat("    =================  ПАНЕЛЬ КОЛИЧЕСТВЕННОГО АНАЛИЗА  =================", "SHTENCO");
   comment+="\n";
   comment+=StringFormat("    Число наблюдений бычьей логики: %d", bullcount);
   comment+="\n";
   comment+=StringFormat("    Число наблюдений медвежьей логики: %d", bearcount);
   comment+="\n\n";
   comment+=StringFormat("    Вероятность бычьего сценария: %.2f%%", bull);
   comment+="\n";
   comment+=StringFormat("    Вероятность медвежьего сценария: %.2f%%", bear);
   comment+="\n\n";
   comment+=StringFormat("    Макс. дельта кластера %d баров: %d пунктов", ClasterBars, (int)(delta_max/_Point));
   comment+="\n";
   comment+=StringFormat("    Мин. дельта кластера %d баров: %d пунктов", ClasterBars, (int)(delta_min/_Point));
   comment+="\n";
   comment+="    =======================================================";
   Comment(comment);
   double pr=0,sl=0,tp=0,hi=0,lo=0;
   double Ask=SymbolInfoDouble(NULL,SYMBOL_ASK);
   double Bid=SymbolInfoDouble(NULL,SYMBOL_BID);
   double Price=iClose(NULL,PERIOD_CURRENT,1);
   int dg=(int)SymbolInfoInteger(NULL,SYMBOL_DIGITS);
   bool sell  = bull<49;
   bool buy  = bull>51;
   if(CloseSig > 0)
     {
      if(buy)
         CloseAll(1);
      if(sell)
         CloseAll(0);
     }
   if(buy && CountTrades()<1)
     {
      if(StopLoss>0)
         sl=NormalizeDouble(Bid-StopLoss*_Point,_Digits);
      if(TakeProfit>0)
         tp=NormalizeDouble(Bid+TakeProfit*_Point,_Digits);
      pr=NormalizeDouble(Bid,dg);
      trade.Buy(Lot(),NULL,pr,sl,tp,"");
     }
   if(sell && CountTrades()<1)
     {
      if(StopLoss>0)
         sl=NormalizeDouble(Ask+StopLoss*_Point,_Digits);
      if(TakeProfit>0)
         tp=NormalizeDouble(Ask-TakeProfit*_Point,_Digits);
      pr=NormalizeDouble(Ask,dg);
      trade.Sell(Lot(),NULL,Ask,sl,tp,"");
     }

  }
//+------------------------------------------------------------------+

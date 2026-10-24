//+------------------------------------------------------------------+
//|                                               Indices Tester.mq5 |
//|                              Copyright 2024,  Beratung24Stunden  |
//|                                                  https://b24s.eu |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Igor Widiger"
#property link      "https://www.mql5.com/de/users/deinschanz/seller"
#property description "=======  ======="
#property version   "1.00"

input group       "---------- General ----------"
input string      comentar                   = "Indices Tester";        // Commentar
input string      TimeStart                  = "01:30";                 // Strat trade
input string      TimeEnd                    = "01:35";                 // End trade
input string      TimeClose                  = "23:30";                 // Order is closed
input group       "---------- Risk- and Moneymanagement ----------"
input double      Lots                       = 0.10;                    // Lots
input int         LimitOpenPosSym            = 1;                       // Limit of open positions for each symbol
input int         DailyNumPositions          = 1;                       // Daily limit for the number of deals for every symbol

#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>
CTrade m_trade;
CSymbolInfo m_symbol;
CPositionInfo  m_position;
CHistoryOrderInfo m_history;

static double lot = 0;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
//--- create timer
   EventSetTimer(1);

   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
//--- destroy timer
   EventKillTimer();

}

void OnTick() {


}
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer() {

//--- Time of OnTimer() when it is first called
   static datetime start_time=TimeCurrent();
//--- The trading server time when first called OnTimer()
   static datetime start_tradeserver_time=0;
//--- Calculated server time
   static datetime calculated_server_time=0;
//--- PV local time
   datetime local_time=TimeLocal();
//--- current estimated server time
   datetime trade_server_time=TimeTradeServer();
//--- If the server time is unknown for whatever reason, exit ahead of time
   if(trade_server_time==0)
      return;
//--- If the server's first time has not yet been saved
   if(start_tradeserver_time==0) {
      start_tradeserver_time=trade_server_time;
      //--- Setting and calculating trading server values
      calculated_server_time=trade_server_time;
   } else {
      //--- Increasing the first time of OnTimer()
      if(start_tradeserver_time!=0)
         calculated_server_time=calculated_server_time+1;;
   }
//---

   //--- Show the values of all counters
   string serverdatum = TimeToString(calculated_server_time,TIME_DATE);
   string serverzeit = TimeToString(calculated_server_time,TIME_MINUTES|TIME_SECONDS);

   // Trade period
   IsInTradingSession(_Symbol, trade_server_time);

}
//+------------------------------------------------------------------+
bool IsInTradingSession(string symbole, datetime ServerTime) {
   MqlDateTime mqt;
   if(TimeToStruct(ServerTime,mqt)) {
      //flatten
      ENUM_DAY_OF_WEEK dow=(ENUM_DAY_OF_WEEK)mqt.day_of_week;
      mqt.hour=0;
      mqt.min=0;
      mqt.sec=0;
      datetime base=StructToTime(mqt),get_from=0,get_to=0;
      //now loop in all the trading sessions
      uint session=0;
      while(SymbolInfoSessionTrade(symbole,dow,session,get_from,get_to)) {
         //so if this succeeds a session exists and fills up get from and get to , but it just fills up with hour , minute + second
         //that means we have to project it on the base time we flattened above for today
         get_from=(datetime)(base+get_from);
         get_to=(datetime)(base+get_to);
         // Print("Session [ "+IntegerToString(session)+" ] ("+TimeToString(get_from,TIME_DATE|TIME_MINUTES|TIME_SECONDS)+")->("+TimeToString(get_to,TIME_DATE|TIME_MINUTES|TIME_SECONDS)+")");
         //and we pump one session in
         session++;
         //and we check , if we happen to be inside that range , we return true because we can trade


         // Check trading time
         if(ServerTime > get_from && ServerTime < get_to) {

            datetime timeclose = StringToTime((string)TimeClose);

            if(ServerTime >= timeclose) {
               // Close order
               ClosePos();
            }

            // Number of deals
            if(NumberDeals(_Symbol, 0) >= DailyNumPositions) continue;
            if(CalculateOnePositions() >= LimitOpenPosSym) continue;

            if(ServerTime > StringToTime((string)TimeStart) && ServerTime < StringToTime((string)TimeEnd)) {
               // Buy Order
               if(CalculateOnePositions() == 0) {
                  BuyOrder(_Symbol,NULL,NULL);
               }
            }

            return(true);

         } else {

            // Market Closed
         }
      }
   }
   return(false);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Calculate one positions                                          |
//+------------------------------------------------------------------+
int CalculateOnePositions() {
   int total=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol() == _Symbol) { // Checks by Symbol
            total++;
//---
         }
   return(total);
}
//+------------------------------------------------------------------+
// Buy Order
void BuyOrder(string symBolBuy, double SlPrice, double TpPrice) {

   int    digits  = (int)SymbolInfoInteger(symBolBuy,SYMBOL_DIGITS); // number of decimal places
   double Points  = SymbolInfoDouble(symBolBuy, SYMBOL_POINT);
   double ask     = SymbolInfoDouble(symBolBuy,SYMBOL_ASK);
   ask = NormalizeDouble(ask,digits);

   lot= Lots;

   double volume = lot;
   volume=LotCheck(volume, symBolBuy);
   if(volume==0)
      return;

   double tp = TpPrice;
   tp = NormalizeDouble(tp,digits);

   double sl;
   sl = SlPrice;
   sl = NormalizeDouble(sl,digits);


   // Check free Margin
   if(!CheckMoneyForTrade(symBolBuy,volume,ORDER_TYPE_BUY)) {
      return;
   }


   if(!m_trade.Buy(volume,symBolBuy,ask,sl,tp,comentar)) {

      //--- failure message
      Print("Sell() method failed. Return code=",m_trade.ResultRetcode(),
            ". Code description: ",m_trade.ResultRetcodeDescription());
   } else {
      Print("Sell() method executed successfully. Return code=",m_trade.ResultRetcode(),
            " (",m_trade.ResultRetcodeDescription(),")");
   }

}

//+------------------------------------------------------------------+
//| Lot Check                                                        |
//+------------------------------------------------------------------+
double LotCheck(double lots, string SymName) {
//--- calculate maximum volume
   double volume=NormalizeDouble(lots,2);
   double stepvol=SymbolInfoDouble(SymName,SYMBOL_VOLUME_STEP);
   if(stepvol>0.0)
      volume=stepvol*MathFloor(volume/stepvol);
//---
   double minvol=SymbolInfoDouble(SymName,SYMBOL_VOLUME_MIN);
   if(volume<minvol)
      volume=0.0;
//---
   double maxvol=SymbolInfoDouble(SymName,SYMBOL_VOLUME_MAX);
   if(volume>maxvol)
      volume=maxvol;
   return(volume);
}
//+------------------------------------------------------------------+
bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type) {
//--- Erhalten wir den Eröffnungspreis
   MqlTick mqltick;
   SymbolInfoTick(symb,mqltick);
   double price=mqltick.ask;
   if(type==ORDER_TYPE_SELL)
      price=mqltick.bid;
//--- Die Werte der notwendigen und freien Marge
   double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   //--- Rufen wir die Funktion der Überprüfung auf
   if(!OrderCalcMargin(type,symb,lots,price,margin)) {
      //--- etwas ging schief, berichten wir es und geben false zurück
      Print("Error in ",__FUNCTION__," code=",GetLastError());
      return(false);
   }
   //--- wenn es Mittel für die Durchführung der Handelsoperationen nicht ausreichend sind
   if(margin>free_margin) {
      //--- berichten wir über den Fehler und geben false zurück
      Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",GetLastError());
      return(false);
   }
//--- die Überprüfung ist erfolgreich gelaufen
   return(true);
}
//------------- Anzahl Orders Funktion ---------------------------
double NumberDeals(string symbolss, int ai_0) {

// HistorySelect(von_datum,zum_datum);
   HistorySelect(iTime(symbolss,PERIOD_D1,ai_0),iTime(symbolss,PERIOD_D1,ai_0)+60*60*24);
   double verlorene_trade=0.0;
   uint total=HistoryDealsTotal();
   ulong    ticket=0;

//--- for all deals
   for(uint i=0; i<total; i++) {
      //--- Sucht nach Tickets die grösser als Null sind
      if((ticket=HistoryDealGetTicket(i))>0) {
         long entry=HistoryDealGetInteger(ticket,DEAL_ENTRY);
         if(entry==DEAL_ENTRY_IN)
            continue;

         string          symbol = HistoryDealGetString(ticket,DEAL_SYMBOL);
         long       order_magic = HistoryDealGetInteger(ticket,DEAL_MAGIC);
         double deal_commission = HistoryDealGetDouble(ticket,DEAL_COMMISSION);
         double       deal_swap = HistoryDealGetDouble(ticket,DEAL_SWAP);
         double     deal_profit = HistoryDealGetDouble(ticket,DEAL_PROFIT);
         double          profit = deal_commission+deal_swap+deal_profit;
         // if(order_magic ==Magic) {
         //... processing of deal with some DEAL_MAGIC
         if(symbol==_Symbol) {
            if(profit<0.0 || profit>0.0)
               verlorene_trade++;
            // }
         }
      }
   }
   return(verlorene_trade);
}
// Close position function
void ClosePos() {
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol() == _Symbol) { // Checks by symbol
            m_trade.PositionClose(m_position.Ticket());
         }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                             BollingerBandsEA.mq5 |
//|                                     Copyright 2024, Igor Widiger |
//|                         https://www.mql5.com/en/users/deinschanz |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, Igor Widiger"
#property link      "https://www.mql5.com/en/users/deinschanz"
#property version   "3.00"
#property description "Update: The positions will only be opened after the bearish or bullish candle."
#property description "Indicators such as Moving Average and Bollinger Bands removed from the chat after closing the EA."
#property description "Small errors with closing the positions after time."

input group                 "---------- General ----------"
input ulong       Magic                      = 111111111111;            // Magic number
input group                "---------- Risk- and Moneymanagement ----------"
enum my_lots {
   fixed_volume                              = 1,                       // Fixed volume
   procent_volume                            = 2,                       // Procent volume
};
input my_lots     volumetype                 = procent_volume;          // Volume type

input double      Risk                       = 1;                       // Risk for Position
input double      Lots                       = 0.10;                    // Lots
input int         Stopp                      = 100;                     // Stoploss in points
input group                "---------- Session start - and end ----------"
input int         MinutesAfterSessionStart   = 420;                     // Trading (minutes) begins after session start
input int         MinutesBeforSessionStart   = 5;                       // Trading (minutes) end before session
input group                "---------- Close positions ----------"
input bool        ClosePos                   = false;                   // Close position after indicator
input bool        Trall                      = true;                    // Allow trailing stop?
input int         ProfitFactor               = 2;                       // Profit factor (RR) after stop is pulled
input bool        Break                      = false;                   // Allow breakeven?
input int         ProfitFactor2              = 1;                       // Profit factor (RR) after stop is pulled
input int         ClosePosMinutes            = 30;                      // Close position if it is in minus (after minutes)


#include <Trade/Trade.mqh>
#include <Trade/SymbolInfo.mqh>


int handleBp, handleMa;
static datetime timestamp;
static double lot = 0;

CTrade trade;
CSymbolInfo m_symbol;
CPositionInfo  m_position;
CHistoryOrderInfo m_history;
CDealInfo m_deal;

int OnInit() {

   handleBp  = iBands(_Symbol,PERIOD_CURRENT,20,0,2.000,PRICE_CLOSE);
   handleMa  = iMA(_Symbol,PERIOD_D1,100,0,MODE_SMA,PRICE_CLOSE);


//---
   trade.SetExpertMagicNumber(Magic);
//---
   trade.SetMarginMode();
   trade.SetTypeFillingBySymbol(m_symbol.Name());

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {

   ActionsOnTheChart(0);

}

void OnTick() {


   // Sessioncheck
   if(IsInTradingSession(_Symbol) == false)  return;

   int bars             = iBars(_Symbol,PERIOD_CURRENT);

   datetime time        = iTime(_Symbol,PERIOD_CURRENT,0);

   double DayHigh       = iHigh(NULL,PERIOD_D1,0); // Day High Period
   double DayLow        = iLow(NULL,PERIOD_D1,0);  // Day Low Period
   double DayHigh1      = iHigh(NULL,PERIOD_D1,1); // Day High Period
   double DayLow1       = iLow(NULL,PERIOD_D1,1);  // Day Low Period

   double DayHighPrice  = 0;
   double DayLowPrice   = 0;
   double DayHighPrice1 = 0;
   double DayLowPrice1  = 0;

   if(timestamp        != time) {
      timestamp         = time;

      DayHighPrice      = DayHigh;
      DayLowPrice       = DayLow;

      DayHighPrice1     = DayHigh1;
      DayLowPrice1      = DayLow1;

   }

   double close1        = iClose(_Symbol,PERIOD_CURRENT,1); // Close candle 1
   double open1         = iOpen(_Symbol,PERIOD_CURRENT,1);  // Open candle 1
   double high1         = iHigh(_Symbol,PERIOD_CURRENT,1);  // High candle 1
   double low1          = iLow(_Symbol,PERIOD_CURRENT,1);   // Low candle 1
   double high0         = iHigh(_Symbol,PERIOD_CURRENT,0);  // High cadle current
   double low0          = iLow(_Symbol,PERIOD_CURRENT,0);   // Low candle current

   double ask           = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   ask = NormalizeDouble(ask,_Digits);
   double bid           = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   bid = NormalizeDouble(bid,_Digits);


   double bbUpper[], bbLowwer[], bbMiddle[];
   CopyBuffer(handleBp,BASE_LINE,1,2,bbMiddle);
   CopyBuffer(handleBp,UPPER_BAND,1,2,bbUpper);
   CopyBuffer(handleBp,LOWER_BAND,1,2,bbLowwer);

   // Range middle upper and lowwer line
   double rangeUpper = (bbUpper[1] - bbMiddle[1])/_Point;
   double rangeLowwer = (bbMiddle[1] -bbLowwer[1])/_Point;

   // Ma indikator
   double ma[];
   CopyBuffer(handleMa,MAIN_LINE,1,1,ma);


   // Close position after indicator
   if(ClosePos == true) {
      for(int i=PositionsTotal()-1; i>=0; i--) // Returns the number of open positions
         if(m_position.SelectByIndex(i)) {
            //---
            if(m_position.Symbol()== _Symbol && m_position.Magic()==Magic) { // Checks for symbol and magic number
               if(m_position.PositionType()==POSITION_TYPE_BUY) {

                  if(bid >= bbMiddle[0]) {
                     ClosePosByTime(_Symbol);
                  }

               } else {
                  if(ask <= bbMiddle[0]) {
                     ClosePosByTime(_Symbol);
                  }

               }

            }
         }
   }

   // Trailingstop
   if(Trall == true) {
      Trailing(_Symbol);
   }
   // Breakeven
   if(Break == true) {
      Breakeven(_Symbol);
   }

   // End trade after time if order is positiv
   datetime AktZeit=TimeCurrent();
   HistorySelect(0,TimeCurrent());
   for(int pos=HistoryDealsTotal()-1; pos>=0; pos--) {
      if(m_position.SelectByIndex(pos)) {
         // Read deal out and get deal time
         if(m_position.Symbol()==_Symbol && m_position.Magic()==Magic) {
            datetime close_time = m_position.Time();
            datetime adierentime = close_time + (ClosePosMinutes*60);

            if(AktZeit >= adierentime && AProfit() < 0) {
               ClosePosByTime(_Symbol);
               return;
            }
         }
      }
   }

   // Start trading for profit the next day!
   if(Profit(0) > 0) {
      return;
   }


   if(CalculateOnePositions(_Symbol) >= 1)
      return;

   if(open1 > close1 && close1 > bbUpper[1] && bid > bbUpper[1] && rangeUpper > Stopp*2 && ask < ma[0]) {
      if(bid > DayHighPrice || bid > DayHighPrice1) {

         if(ProfitSell(0) < 0) return;

         double newSl = 0;
         if(high1 > high0) {
            newSl = high1;
         } else if(high1 < high0) {
            newSl = high0;
         } else {
            return;  // Kein Trade
         }

         double sl      = newSl + Stopp*_Point;
         double tp      = DayLow;



         // Calculate SL in points
         double Points  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         double SlPoints = (sl - ask) / _Point;

         if(volumetype == 2) {
            lot = NormalizeDouble(LotsByRisk(ORDER_TYPE_SELL,Risk,(int)SlPoints,_Symbol,Points),2);
         } else {
            lot= Lots;
         }


         double volume = lot;
         volume=LotCheck(volume, _Symbol);
         if(volume==0)
            return;

         if(!CheckStopLoss_Takeprofit(ORDER_TYPE_SELL,sl,tp)) {
            return;
         }
         double max_volume=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_LIMIT);
         double current_lots=getAllVolume();

         if(max_volume>0 && max_volume-volume<=0) {
            return;
         }

         trade.Sell(volume,_Symbol,bid,sl,tp);

      }
   } else if(close1 > open1 && close1 < bbLowwer[1] && ask < bbLowwer[1] && rangeLowwer > Stopp*2 && bid > ma[0]) {
      if(ask < DayLowPrice || ask < DayLowPrice1) {

         if(ProfitBuy(0) < 0) return;

         double newSl = 0;
         if(low1 > low0) {
            newSl = low0;
         } else if(low1 < low0) {
            newSl = low1;
         } else {
            return;  // Kein Trade
         }
         double sl      = newSl - Stopp*_Point;
         double tp      = DayHigh;

         // Calculate SL in points
         double Points  = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
         double SlPoints = (bid - sl)/_Point;

         if(volumetype == 2) {
            lot = NormalizeDouble(LotsByRisk(ORDER_TYPE_BUY,Risk,(int)SlPoints,_Symbol,Points),2);
         } else {
            lot= Lots;
         }

         double volume = lot;
         volume=LotCheck(volume, _Symbol);
         if(volume==0)
            return;

         if(!CheckStopLoss_Takeprofit(ORDER_TYPE_BUY,sl,tp)) {
            return;
         }
         double max_volume=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_LIMIT);
         double current_lots=getAllVolume();

         if(max_volume>0 && max_volume-volume<=0) {
            return;
         }

         trade.Buy(volume,_Symbol,ask,sl,tp);

      }
   }




}
//+------------------------------------------------------------------+
//| Calculate one positions                                          |
//+------------------------------------------------------------------+
int CalculateOnePositions(string ssymBol) {
   int total=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol() == ssymBol && m_position.Magic()==Magic) { // Checks by magic number end Symbol
            total++;
            //---
         }
   return(total);
}
//+------------------------------------------------------------------+
// Close position function
void ClosePosByTime(string symbolss) {
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()== _Symbol && m_position.Magic()==Magic) { // Checks by symbol and magic number
            trade.PositionClose(m_position.Ticket());
         }
}
//------------- Profit sell ausrechnen Funktion ---------------------------
double ProfitSell(int ai_0) {

// HistorySelect(von_datum,zum_datum);
   HistorySelect(iTime(_Symbol,PERIOD_D1,ai_0),iTime(_Symbol,PERIOD_D1,ai_0)+60*60*24);
   double gewonnene_trade=0.0;
   double verlorene_trade=0.0;
   double total_profit=0.0;
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
         double profit=deal_commission+deal_swap+deal_profit;

         ENUM_DEAL_TYPE  deal_type= (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
         long dreason= (int)HistoryDealGetInteger(ticket,DEAL_REASON);

         if(deal_type!=DEAL_TYPE_BUY)
            continue;

         if(order_magic==Magic) {
            //... processing of deal with some DEAL_MAGIC
            if(symbol==_Symbol && dreason==(DEAL_REASON_SL)) {
               if(profit<0.0)
                  verlorene_trade+=profit;
               total_profit+=profit;
            }
         }
      }
   }
   return(total_profit);
}
//------------- Profit sell ausrechnen Funktion ---------------------------
double ProfitBuy(int ai_0) {

// HistorySelect(von_datum,zum_datum);
   HistorySelect(iTime(_Symbol,PERIOD_D1,ai_0),iTime(_Symbol,PERIOD_D1,ai_0)+60*60*24);
   double gewonnene_trade=0.0;
   double verlorene_trade=0.0;
   double total_profit=0.0;
   uint total=HistoryDealsTotal();
   ulong    ticket=0;

//--- for all deals
   for(uint i=0; i<total; i++) {
      //--- Searches for tickets greater than zero
      if((ticket=HistoryDealGetTicket(i))>0) {
         long entry=HistoryDealGetInteger(ticket,DEAL_ENTRY);
         if(entry==DEAL_ENTRY_IN)
            continue;

         string          symbol = HistoryDealGetString(ticket,DEAL_SYMBOL);
         long       order_magic = HistoryDealGetInteger(ticket,DEAL_MAGIC);
         double deal_commission = HistoryDealGetDouble(ticket,DEAL_COMMISSION);
         double       deal_swap = HistoryDealGetDouble(ticket,DEAL_SWAP);
         double     deal_profit = HistoryDealGetDouble(ticket,DEAL_PROFIT);
         double profit=deal_commission+deal_swap+deal_profit;


         ENUM_DEAL_TYPE  deal_type= (ENUM_DEAL_TYPE)HistoryDealGetInteger(ticket, DEAL_TYPE);
         if(deal_type!=DEAL_TYPE_SELL)
            continue;

         long dreason= (int)HistoryDealGetInteger(ticket,DEAL_REASON);

         if(order_magic==Magic) {
            //... processing of deal with some DEAL_MAGIC
            if(symbol==_Symbol && dreason==(DEAL_REASON_SL)) {
               if(profit<0.0)
                  verlorene_trade+=profit;
               total_profit+=profit;
            }
         }
      }
   }
   return(total_profit);
}
//------------- Profit ausrechnen Funktion ---------------------------
double Profit(int ai_0) {

// HistorySelect(von_datum,zum_datum);
   HistorySelect(iTime(_Symbol,PERIOD_D1,ai_0),iTime(_Symbol,PERIOD_D1,ai_0)+60*60*24);
   double gewonnene_trade=0.0;
   double verlorene_trade=0.0;
   double total_profit=0.0;
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
         double profit=deal_commission+deal_swap+deal_profit;
         if(order_magic==Magic) {
            //... processing of deal with some DEAL_MAGIC
            if(symbol==_Symbol) {
               if(profit>0.0)
                  gewonnene_trade+=profit;
               if(profit<0.0)
                  verlorene_trade+=profit;
               total_profit+=profit;
            }
         }
      }
   }
   return(total_profit);
}
//+------------------------------------------------------------------+
double AProfit() {
   double pft=0;
   for(int i=PositionsTotal()-1; i>=0; i--) {
      ulong ticket=PositionGetTicket(i);
      if(ticket>0) {
         if(PositionGetInteger(POSITION_MAGIC)==Magic && PositionGetString(POSITION_SYMBOL)==_Symbol) {
            pft+=PositionGetDouble(POSITION_PROFIT);
         }
      }
   }
   return(pft);
}
//+------------------------------------------------------------------+
// Trailing in %  Function
void Trailing(string symssBol) {

   int total=0;
   for(int j=PositionsTotal()-1; j>=0; j--)
      if(m_position.SelectByIndex(j)) // selects the position by index for further access to its properties
         if(m_position.Symbol()== symssBol && m_position.Magic()==Magic) { // Checks by symbol and magic number
            total++;
         }

   if(total<=0) {
      //Trailing no Positions
      return;
   }

// Spannefunktion
   double RangeHigh      = iHigh(NULL,PERIOD_D1,0);
   double RangeLow       = iLow(NULL,PERIOD_D1,0);
   double RangeProzent  = NormalizeDouble(((RangeHigh - RangeLow) / RangeHigh * 100),2);
// 1
   double RangeHigh1      = iHigh(NULL,PERIOD_D1,1);
   double RangeLow1       = iLow(NULL,PERIOD_D1,1);
   double RangeProzent1  = NormalizeDouble(((RangeHigh1 - RangeLow1) / RangeHigh1 * 100),2);
// 2
   double RangeHigh2      = iHigh(NULL,PERIOD_D1,2);
   double RangeLow2       = iLow(NULL,PERIOD_D1,2);
   double RangeProzent2  = NormalizeDouble(((RangeHigh2 - RangeLow2) / RangeHigh2 * 100),2);
// 3
   double RangeHigh3      = iHigh(NULL,PERIOD_D1,3);
   double RangeLow3       = iLow(NULL,PERIOD_D1,3);
   double RangeProzent3  = NormalizeDouble(((RangeHigh3 - RangeLow3) / RangeHigh3 * 100),2);
// 4
   double RangeHigh4      = iHigh(NULL,PERIOD_D1,4);
   double RangeLow4       = iLow(NULL,PERIOD_D1,4);
   double RangeProzent4  = NormalizeDouble(((RangeHigh4 - RangeLow4) / RangeHigh4 * 100),2);

   double RangeGes = (RangeProzent + RangeProzent1 + RangeProzent2 + RangeProzent3 + RangeProzent4)/5;


// Trailling in procent
   int ProfitProzent;
   if(RangeProzent < RangeGes) {
      ProfitProzent = 50;
   } else {
      ProfitProzent = 75;
   }

   for(int i=PositionsTotal()-1; i>=0; i--) // Returns the number of open positions

      if(m_position.SelectByIndex(i)) {
         double price_current = m_position.PriceCurrent();
         double price_open    = m_position.PriceOpen();
         double stop_loss     = m_position.StopLoss();
         double take_profit   = m_position.TakeProfit();
         datetime price_time  = m_position.Time();


         //---
         if(m_position.Symbol()== symssBol && m_position.Magic()==Magic) { // Checks for symbol and magic number
            if(m_position.PositionType()==POSITION_TYPE_BUY) {


               int    digits=(int)SymbolInfoInteger(symssBol,SYMBOL_DIGITS); // number of decimal places
               double point=SymbolInfoDouble(symssBol,SYMBOL_POINT);         // point
               double Ask = NormalizeDouble(SymbolInfoDouble(symssBol,SYMBOL_ASK),digits); // Define Ask
               double Bid = NormalizeDouble(SymbolInfoDouble(symssBol,SYMBOL_BID),digits); // Define Bid
               double priceRangePoints = (Ask - price_open)/point;
               double price = price_open + (priceRangePoints/100*ProfitProzent)*point;

               // SL Range Buy
               double NeuSl = (((price_open - stop_loss)/point)*ProfitFactor);
               double SlRangeBuy = price_open + NeuSl * point;


               if(price > SlRangeBuy && price > stop_loss) {
                  trade.PositionModify(m_position.Ticket(),price+(100/ProfitProzent)*_Point,take_profit);
               }

            } else if(m_position.PositionType()==POSITION_TYPE_SELL) {

               int    digits=(int)SymbolInfoInteger(symssBol,SYMBOL_DIGITS); // number of decimal places
               double point=SymbolInfoDouble(symssBol,SYMBOL_POINT);         // point
               double Ask = NormalizeDouble(SymbolInfoDouble(symssBol,SYMBOL_ASK),digits); // Define Ask
               double Bid = NormalizeDouble(SymbolInfoDouble(symssBol,SYMBOL_BID),digits); // Define Bid
               double priceRangePoints = (price_open - Bid)/point;
               double price = price_open - (priceRangePoints/100*ProfitProzent)*point;

               // SL Range Sell
               double NeuSl = (((stop_loss - price_open)/point)*ProfitFactor);
               double SlRangeSell = price_open - NeuSl * point;


               if(price < SlRangeSell && stop_loss > price) {
                  trade.PositionModify(m_position.Ticket(),price-(100/ProfitProzent)*_Point,take_profit);
               }
            } else {

            }
         }
      }
   ChartRedraw(0);

}

// Breakeven
void Breakeven(string symBreakeven) {
   for(int i=PositionsTotal()-1; i>=0; i--) // Returns the number of open positions
      if(m_position.SelectByIndex(i)) {

         double price_current = m_position.PriceCurrent();
         double price_open    = m_position.PriceOpen();
         double stop_loss     = m_position.StopLoss();
         double take_profit   = m_position.TakeProfit();

         int    digits = (int)SymbolInfoInteger(symBreakeven,SYMBOL_DIGITS); // number of decimal places
         double point = SymbolInfoDouble(symBreakeven,SYMBOL_POINT);         // point
         ulong  Spread        = SymbolInfoInteger(_Symbol,SYMBOL_SPREAD);                      // Define Spread

         //---
         if(m_position.Symbol()== symBreakeven && m_position.Magic()==Magic) { // Checks for symbol and magic number
            if(m_position.PositionType()==POSITION_TYPE_BUY) {

               double SlNewPrice = 0.0;
               double SlRangeBuy = (price_open - stop_loss)/point;
               SlNewPrice  =  price_open + ((SlRangeBuy*ProfitFactor2)*point);


               if(stop_loss < price_open && price_current > SlNewPrice) {
                  if(price_current > price_open)
                     trade.PositionModify(m_position.Ticket(),price_open,take_profit);
               }
            } else {

               double SlNewPrice = 0.0;
               double SlRangeSell = (stop_loss - price_open)/point;
               SlNewPrice  =  price_open - ((SlRangeSell*ProfitFactor2)*point);

               if(stop_loss > price_open && price_current <  SlNewPrice) {
                  if(price_current< price_open)
                     trade.PositionModify(m_position.Ticket(),price_open,take_profit);
               }
            }
         }
      }
}
//+------------------------------------------------------------------+
bool IsInTradingSession(string symbole) {
   MqlDateTime mqt;
   if(TimeToStruct(TimeTradeServer(),mqt)) {
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
         //and we pump one session in
         session++;
         //and we check , if we happen to be inside that range , we return true because we can trade
         if(TimeTradeServer()>=get_from&&TimeTradeServer()<=get_to) {

            // Start trading after the specified time after the start of the season!
            datetime TimeStart = get_from + MinutesAfterSessionStart*60; // Start Trading
            datetime TimeSesEnd = get_to - MinutesBeforSessionStart*60;  // Ends Trading

            // Trading Start
            if(TimeTradeServer()>=get_from && TimeTradeServer()<= TimeStart) {
               return(true);
            }
            // trading end
            if(TimeTradeServer()<=get_to && TimeTradeServer()>= TimeSesEnd) {
               return(true);
            }

            return(true);
         } else {
            // Print("market closed: ");
         }
      }
   }
   return(false);
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Calculate Volume with stop in %                                  |
//+------------------------------------------------------------------+
double LotsByRisk(int op_type,double risk,int sloss, string Sym_Name, double points) {
   double  lot_min = SymbolInfoDouble(Sym_Name,SYMBOL_VOLUME_MIN);
   double  lot_max = SymbolInfoDouble(Sym_Name,SYMBOL_VOLUME_MAX);
   double lot_step = SymbolInfoDouble(Sym_Name,SYMBOL_VOLUME_STEP);
   double  lotcost = ((SymbolInfoDouble(Sym_Name, SYMBOL_TRADE_TICK_VALUE)*points)/(SymbolInfoDouble(Sym_Name,SYMBOL_TRADE_TICK_SIZE)));
   lot = 0.0;
   double UsdPerPip = 0.0;

   lot = AccountInfoDouble(ACCOUNT_BALANCE)*risk/100;
   UsdPerPip = lot/sloss;
   if(UsdPerPip <= 0.0)
      return(0);
   lot = NormalizeDouble(UsdPerPip/lotcost, 2);
   if(lot <= 0.0)
      return(0);
   lot = NormalizeDouble(lot/lot_step, 0) * lot_step;
   if(lot < lot_min)
      lot = lot_min;
   if(lot > lot_max)
      lot = lot_max;
   return(lot);
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
// Check Sl TP
bool CheckStopLoss_Takeprofit(ENUM_ORDER_TYPE type,double SL,double TP) {

   double Ask           = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
   double Bid           = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
//---  Let's get the SYMBOL_TRADE_STOPS_LEVEL level
   int stops_level=(int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   if(stops_level!=0) {
      PrintFormat("SYMBOL_TRADE_STOPS_LEVEL=%d: StopLoss and TakeProfit must not be closer"+
                  " as %d points from the exit price",stops_level,stops_level);
   }
//---
   bool SL_check=false,TP_check=false;
//--- Let's examine only two types of orders
   switch(type) {
//--- The buying operation
   case  ORDER_TYPE_BUY: {
      //--- Let's check StopLoss
      SL_check=(Bid-SL>stops_level*_Point);
      if(!SL_check)
         PrintFormat("For order %s StopLoss=%.5f must be less than %.5f"+
                     " (Bid=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                     EnumToString(type),SL,Bid-stops_level*_Point,Bid,stops_level);
      //--- Let's check TakeProfit
      TP_check=(TP-Bid>stops_level*_Point);
      if(!TP_check)
         PrintFormat("For order %s TakeProfit=%.5f must be greater than %.5f"+
                     " (Bid=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                     EnumToString(type),TP,Bid+stops_level*_Point,Bid,stops_level);
      //--- we return the result of the verification
      return(SL_check&&TP_check);
   }
//--- The sale operation
   case  ORDER_TYPE_SELL: {
      //--- Let's check StopLoss
      SL_check=(SL-Ask>stops_level*_Point);
      if(!SL_check)
         PrintFormat("For order %s StopLoss=%.5f must be greater than %.5f "+
                     " (Ask=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                     EnumToString(type),SL,Ask+stops_level*_Point,Ask,stops_level);
      //--- Let's check TakeProfit
      TP_check=(Ask-TP>stops_level*_Point);
      if(!TP_check)
         PrintFormat("For order %s TakeProfit=%.5f must be less than %.5f "+
                     " (Ask=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d points)",
                     EnumToString(type),TP,Ask-stops_level*_Point,Ask,stops_level);
      //--- we return the result of the verification
      return(TP_check&&SL_check);
   }
   break;
   }
//--- For the pending orders you need another function
   return false;
}
//+------------------------------------------------------------------+
//volume counting function
double getAllVolume() {
   int itotal=PositionsTotal();
   ulong uticket=-1;
   double dVolume=0;

   for(int i=itotal-1; i>=0; i--) {
      if(!(uticket=PositionGetTicket(i))) continue;

      if(PositionGetString(POSITION_SYMBOL)==m_symbol.Name())
         dVolume+=PositionGetDouble(POSITION_VOLUME);
   }

   itotal=OrdersTotal();

   for(int i=itotal-1; i>=0; i--) {
      if(!(uticket=OrderGetTicket(i))) continue;

      if(OrderGetString(ORDER_SYMBOL)==m_symbol.Name())
         dVolume+=OrderGetDouble(ORDER_VOLUME_CURRENT);
   }

   return dVolume;
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool ActionsOnTheChart(const long chart_id) {
   int sub_windows_total =-1;
   int indicators_total  =0;
//---
   if(!ChartWindowsTotal(chart_id,sub_windows_total)) {
      return(false);
   }
//---
   for(int i=sub_windows_total-1; i>=0; i--) {
      indicators_total=ChartIndicatorsTotal(chart_id,i);
      //---
      if(indicators_total>0) {
         ChIndicatorsDelete(chart_id,i,indicators_total);
      }
   }
//---
   return(true);
}
//+------------------------------------------------------------------+
bool ChartWindowsTotal(const long chart_ID,int &sub_windows_total) {
   long value=-1;
//---
   if(!ChartGetInteger(chart_ID,CHART_WINDOWS_TOTAL,0,value)) {
      // Print(__FUNCTION__," Error = ",GetLastError());
      return(false);
   }
//---
   sub_windows_total=(int)value;
//---
   return(true);
}
//+------------------------------------------------------------------+
void ChIndicatorsDelete(const long  chart_id,
                        const int   sub_window,
                        const int   indicators_total) {
   for(int i=indicators_total-1; i>=0; i--) {
      string indicator_name=ChartIndicatorName(chart_id,sub_window,i);
      //---
      ChIndicatorDelete(indicator_name,chart_id,sub_window);
   }
//---
   return;
}
//+------------------------------------------------------------------+
bool ChIndicatorDelete(const string short_name,
                       const long   chart_id=0,
                       const int    sub_window=0) {
   bool res=ChartIndicatorDelete(chart_id,sub_window,short_name);
//---
   if(!res) {
      Print("Failed to delete indicator:\"",short_name,"\". Error: ",GetLastError());
      //---
      return(false);
   }
//---
   return(true);
}
//+------------------------------------------------------------------+

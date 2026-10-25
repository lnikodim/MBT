//+------------------------------------------------------------------+
//| DailyZoneRecovery.mq5                                            |
//+------------------------------------------------------------------+
#property copyright "by Ramil Kireev"
#property link      "https://www.mql5.com/en/users/kirramil/seller"
#property version   "1.0"
#property description "Daily Zone Recovery EA"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+

input group "General Settings"
input double          InpLot                  = 0.01;      // Lot size
input long            InpMagic                = 180187;    // Magic number (S1=Magic, S2=Magic+1, S3=Magic+2)
input bool            InpStrategyLock         = false;     // Only one strategy trades at a time
input string          InpComment              = "Daily Zone Recovery"; // Order comment
input int             InpMaxSpread            = 3000;      // Max spread in points

input group "ATR Filter (for all strategies)"
input bool            InpAtrFilterEnabled     = true;      // ATR filter on/off
input int             InpAtrPeriod            = 4;         // ATR period (days)
input double          InpAtrMinRangePct       = 25.0;      // Min yesterday range in % of ATR
input double          InpAtrMaxRangePct       = 150.0;     // Max yesterday range in % of ATR

input group "Strategy 1 - Level breakout and retest"
input bool            InpStrategy1Enabled     = true;      // Strategy 1 enabled
input double          InpStrategy1ZonePct     = 0.13;      // Zone size near level (%)
input double          InpStrategy1DistancePct = 0.25;      // Breakout distance from zone (%)
input ENUM_TIMEFRAMES InpStrategy1Timeframe   = PERIOD_M15;// Signal timeframe
input bool            InpStrategy1GridEnabled = true;      // Grid on/off
input double          InpStrategy1GridStepPct = 0.34;      // Grid step (%)
input double          InpStrategy1TpPct       = 0.15;      // TP (% of avg price)
input double          InpStrategy1SlPct       = 1.5;       // SL (% of avg price)

input group "Strategy 2 - Level retest and breakout"
input bool            InpStrategy2Enabled     = true;      // Strategy 2 enabled
input double          InpStrategy2ZonePct     = 0.31;      // Zone size (%)
input double          InpStrategy2DistancePct = 0.4;       // Breakout distance (%)
input ENUM_TIMEFRAMES InpStrategy2Timeframe   = PERIOD_M12;// Signal timeframe
input bool            InpStrategy2GridEnabled = true;      // Grid on/off
input double          InpStrategy2GridStepPct = 0.01;      // Grid step (%)
input double          InpStrategy2TpPct       = 0.01;      // TP (%)
input double          InpStrategy2SlPct       = 1.5;       // SL (%)

input group "Strategy 3 - Level retest, pullback, retest"
input bool            InpStrategy3Enabled     = true;      // Strategy 3 enabled
input double          InpStrategy3ZonePct     = 0.28;      // Zone size (%)
input double          InpStrategy3DistancePct = 0.4;       // Pullback distance (%)
input ENUM_TIMEFRAMES InpStrategy3Timeframe   = PERIOD_M6; // Signal timeframe
input bool            InpStrategy3GridEnabled = true;      // Grid on/off
input double          InpStrategy3GridStepPct = 0.32;      // Grid step (%)
input double          InpStrategy3TpPct       = 0.06;      // TP (%)
input double          InpStrategy3SlPct       = 1.5;       // SL (%)

//+------------------------------------------------------------------+
//| Structs                                                          |
//+------------------------------------------------------------------+
struct SeriesParams
{
   ulong  magic;
   string comment;
   bool   gridOn;
   double gridStep;
   double tpValue;
   double slValue;
};

struct SymbolState
{
   string symbol;
   int    digits;
   ENUM_ORDER_TYPE_FILLING fillMode;

   int      strategy2BuyStage;
   int      strategy2SellStage;
   datetime strategy2LastDayTime;

   int      strategy3BuyStage;
   int      strategy3SellStage;
   datetime strategy3LastDayTime;

   datetime lastBarTime;
   datetime lastGridBarTime;

   datetime lastTradeBarS1;
   datetime lastTradeBarS2;
   datetime lastTradeBarS3;

   datetime lastCloseBarS1;
   datetime lastCloseBarS2;
   datetime lastCloseBarS3;

   bool gridKneeOpenedThisBarS1;
   bool gridKneeOpenedThisBarS2;
   bool gridKneeOpenedThisBarS3;

   // Tester statistics
   int    seriesHourBuyS1;
   int    seriesHourSellS1;
   double seriesMinProfitBuyS1;
   double seriesMinProfitSellS1;
   double seriesCloseProfitBuyS1;
   double seriesCloseProfitSellS1;

   int    seriesHourBuyS2;
   int    seriesHourSellS2;
   double seriesMinProfitBuyS2;
   double seriesMinProfitSellS2;
   double seriesCloseProfitBuyS2;
   double seriesCloseProfitSellS2;

   int    seriesHourBuyS3;
   int    seriesHourSellS3;
   double seriesMinProfitBuyS3;
   double seriesMinProfitSellS3;
   double seriesCloseProfitBuyS3;
   double seriesCloseProfitSellS3;

   double hourMaxDD_S1[24];
   double hourTotalDD_S1[24];
   double hourTotalProfit_S1[24];
   int    hourSeriesCount_S1[24];

   double hourMaxDD_S2[24];
   double hourTotalDD_S2[24];
   double hourTotalProfit_S2[24];
   int    hourSeriesCount_S2[24];

   double hourMaxDD_S3[24];
   double hourTotalDD_S3[24];
   double hourTotalProfit_S3[24];
   int    hourSeriesCount_S3[24];
};

//+------------------------------------------------------------------+
//| Globals                                                          |
//+------------------------------------------------------------------+
CTrade        tradeS1, tradeS2, tradeS3;
CPositionInfo posInfo;
SeriesParams g_s1Params, g_s2Params, g_s3Params;
SymbolState  g_state;
bool g_isHedging = true;

//+------------------------------------------------------------------+
//| Init symbol state                                                |
//+------------------------------------------------------------------+
void InitSymbolState(SymbolState &s, string sym)
{
   s.symbol = sym;
   s.digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);

   long fillingFlags = SymbolInfoInteger(sym, SYMBOL_FILLING_MODE);
   s.fillMode = ORDER_FILLING_RETURN;
   if((fillingFlags & SYMBOL_FILLING_FOK) == SYMBOL_FILLING_FOK) s.fillMode = ORDER_FILLING_FOK;
   else if((fillingFlags & SYMBOL_FILLING_IOC) == SYMBOL_FILLING_IOC) s.fillMode = ORDER_FILLING_IOC;

   s.strategy2BuyStage    = 0;
   s.strategy2SellStage   = 0;
   s.strategy2LastDayTime = 0;

   s.strategy3BuyStage    = 0;
   s.strategy3SellStage   = 0;
   s.strategy3LastDayTime = 0;

   s.lastBarTime     = 0;
   s.lastGridBarTime = 0;

   s.lastTradeBarS1 = 0; s.lastTradeBarS2 = 0; s.lastTradeBarS3 = 0;
   s.lastCloseBarS1 = 0; s.lastCloseBarS2 = 0; s.lastCloseBarS3 = 0;

   s.gridKneeOpenedThisBarS1 = false;
   s.gridKneeOpenedThisBarS2 = false;
   s.gridKneeOpenedThisBarS3 = false;

   s.seriesHourBuyS1 = -1; s.seriesHourSellS1 = -1;
   s.seriesMinProfitBuyS1 = 0; s.seriesMinProfitSellS1 = 0;
   s.seriesCloseProfitBuyS1 = 0; s.seriesCloseProfitSellS1 = 0;

   s.seriesHourBuyS2 = -1; s.seriesHourSellS2 = -1;
   s.seriesMinProfitBuyS2 = 0; s.seriesMinProfitSellS2 = 0;
   s.seriesCloseProfitBuyS2 = 0; s.seriesCloseProfitSellS2 = 0;

   s.seriesHourBuyS3 = -1; s.seriesHourSellS3 = -1;
   s.seriesMinProfitBuyS3 = 0; s.seriesMinProfitSellS3 = 0;
   s.seriesCloseProfitBuyS3 = 0; s.seriesCloseProfitSellS3 = 0;

   for(int h = 0; h < 24; h++)
   {
      s.hourMaxDD_S1[h] = 0; s.hourTotalDD_S1[h] = 0; s.hourTotalProfit_S1[h] = 0; s.hourSeriesCount_S1[h] = 0;
      s.hourMaxDD_S2[h] = 0; s.hourTotalDD_S2[h] = 0; s.hourTotalProfit_S2[h] = 0; s.hourSeriesCount_S2[h] = 0;
      s.hourMaxDD_S3[h] = 0; s.hourTotalDD_S3[h] = 0; s.hourTotalProfit_S3[h] = 0; s.hourSeriesCount_S3[h] = 0;
   }
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   g_s1Params.magic    = (ulong)InpMagic;
   g_s1Params.comment  = InpComment + "_S1";
   g_s1Params.gridOn   = InpStrategy1GridEnabled;
   g_s1Params.gridStep = InpStrategy1GridStepPct;
   g_s1Params.tpValue  = InpStrategy1TpPct;
   g_s1Params.slValue  = InpStrategy1SlPct;

   g_s2Params.magic    = (ulong)InpMagic + 1;
   g_s2Params.comment  = InpComment + "_S2";
   g_s2Params.gridOn   = InpStrategy2GridEnabled;
   g_s2Params.gridStep = InpStrategy2GridStepPct;
   g_s2Params.tpValue  = InpStrategy2TpPct;
   g_s2Params.slValue  = InpStrategy2SlPct;

   g_s3Params.magic    = (ulong)InpMagic + 2;
   g_s3Params.comment  = InpComment + "_S3";
   g_s3Params.gridOn   = InpStrategy3GridEnabled;
   g_s3Params.gridStep = InpStrategy3GridStepPct;
   g_s3Params.tpValue  = InpStrategy3TpPct;
   g_s3Params.slValue  = InpStrategy3SlPct;

   tradeS1.SetExpertMagicNumber(g_s1Params.magic); tradeS1.SetDeviationInPoints(10);
   tradeS2.SetExpertMagicNumber(g_s2Params.magic); tradeS2.SetDeviationInPoints(10);
   tradeS3.SetExpertMagicNumber(g_s3Params.magic); tradeS3.SetDeviationInPoints(10);

   InitSymbolState(g_state, _Symbol);
   g_isHedging = ((ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE) == ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
   Print("DailyZoneRecovery UltraClean initialized on ", _Symbol, " (", (g_isHedging ? "hedging" : "netting"), ")");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Tester stats                                                     |
//+------------------------------------------------------------------+
void PrintHourlyStats(const SymbolState &st, int num, const double &maxDD[], const double &totalDD[], const int &cnt[], const double &totalProfit[])
{
   Print("========== ", st.symbol, " STRATEGY #", num, " STATS BY HOUR (UTC) ==========");
   Print("Hour | Series | MaxDD($)  | AvgDD($)  | TotalProfit($) | AvgProfit($)");
   for(int h = 0; h < 24; h++)
   {
      if(cnt[h]==0) continue;
      Print(StringFormat("%02d:00 | %6d | %9.2f | %9.2f | %14.2f | %14.2f", h, cnt[h], maxDD[h], totalDD[h]/cnt[h], totalProfit[h], totalProfit[h]/cnt[h]));
   }
}
void OnDeinit(const int reason)
{
   if(MQLInfoInteger(MQL_TESTER))
   {
      PrintHourlyStats(g_state,1,g_state.hourMaxDD_S1,g_state.hourTotalDD_S1,g_state.hourSeriesCount_S1,g_state.hourTotalProfit_S1);
      PrintHourlyStats(g_state,2,g_state.hourMaxDD_S2,g_state.hourTotalDD_S2,g_state.hourSeriesCount_S2,g_state.hourTotalProfit_S2);
      PrintHourlyStats(g_state,3,g_state.hourMaxDD_S3,g_state.hourTotalDD_S3,g_state.hourSeriesCount_S3,g_state.hourTotalProfit_S3);
   }
}

//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
double GetDistance(double percent, double ref){ return ref * percent / 100.0; }

double CalcLot(string symbol)
{
   double lot = InpLot;
   if(lot < 0.01) lot = 0.01;
   double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double minVol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   lot = MathFloor(lot / step) * step;
   return MathMax(minVol, MathMin(maxVol, lot));
}

bool CheckVolumeValue(string symbol, double volume)
{
   double minVol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);
   double step = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   if(volume < minVol || volume > maxVol) return false;
   int ratio = (int)MathRound(volume / step);
   return (MathAbs(ratio * step - volume) <= 0.0000001);
}

bool CanOpenVolume(string symbol, double lot)
{
   double limit = SymbolInfoDouble(symbol, SYMBOL_VOLUME_LIMIT);
   if(limit <= 0) return true;
   double total = 0;
   for(int i=PositionsTotal()-1;i>=0;i--){ if(!posInfo.SelectByIndex(i)) continue; if(posInfo.Symbol()!=symbol) continue; total+=posInfo.Volume(); }
   for(int i=OrdersTotal()-1;i>=0;i--){ ulong t=OrderGetTicket(i); if(t==0) continue; if(OrderGetString(ORDER_SYMBOL)!=symbol) continue; total+=OrderGetDouble(ORDER_VOLUME_CURRENT); }
   return total + lot <= limit;
}

bool CheckMoneyForTrade(string symbol, double lots, ENUM_ORDER_TYPE type)
{
   MqlTick tick; SymbolInfoTick(symbol, tick);
   double price = (type==ORDER_TYPE_SELL)?tick.bid:tick.ask;
   double margin, freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);
   if(!OrderCalcMargin(type,symbol,lots,price,margin)) return false;
   return margin <= freeMargin;
}

bool IsNewOrderAllowed(){ int max=(int)AccountInfoInteger(ACCOUNT_LIMIT_ORDERS); if(max==0) return true; return OrdersTotal()+PositionsTotal()<max; }

bool IsTradeAllowed(string symbol)
{
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) return false;
   if((ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE)==SYMBOL_TRADE_MODE_DISABLED) return false;
   MqlTick tick; if(!SymbolInfoTick(symbol,tick)) return false;
   if(tick.bid<=0 || tick.ask<=0) return false;
   if(SymbolInfoInteger(symbol,SYMBOL_SPREAD)<=0) return false;
   MqlDateTime dt; TimeToStruct(TimeCurrent(),dt);
   datetime from,to;
   if(!SymbolInfoSessionTrade(symbol,(ENUM_DAY_OF_WEEK)dt.day_of_week,0,from,to)) return false;
   int nowSec = dt.hour*3600+dt.min*60+dt.sec;
   for(int i=0;i<10;i++)
   {
      if(!SymbolInfoSessionTrade(symbol,(ENUM_DAY_OF_WEEK)dt.day_of_week,i,from,to)) break;
      MqlDateTime df,dtt; TimeToStruct(from,df); TimeToStruct(to,dtt);
      int sf=df.hour*3600+df.min*60+df.sec;
      int st=dtt.hour*3600+dtt.min*60+dtt.sec;
      if(nowSec>=sf && nowSec<st) return true;
   }
   return false;
}

bool CanOpenTrade(string symbol, double lot, ENUM_ORDER_TYPE type)
{
   return IsTradeAllowed(symbol) && CheckVolumeValue(symbol,lot) && CanOpenVolume(symbol,lot) && IsNewOrderAllowed() && CheckMoneyForTrade(symbol,lot,type);
}

//+------------------------------------------------------------------+
//| Position helpers - only used functions kept                       |
//+------------------------------------------------------------------+
int CountPositionsByMagicType(ulong magic, int ptype, string symbol)
{
   int c=0;
   for(int i=PositionsTotal()-1;i>=0;i--){ if(!posInfo.SelectByIndex(i)) continue; if(posInfo.Symbol()!=symbol||posInfo.Magic()!=magic) continue; if((int)posInfo.PositionType()!=ptype) continue; c++; }
   return c;
}
bool HasPositionsOfMagicType(ulong magic, int ptype, string symbol)
{
   for(int i=PositionsTotal()-1;i>=0;i--){ if(!posInfo.SelectByIndex(i)) continue; if(posInfo.Symbol()!=symbol||posInfo.Magic()!=magic) continue; if((int)posInfo.PositionType()==ptype) return true; }
   return false;
}
double GetWeightedAvgPrice(ulong magic, int ptype, string symbol)
{
   double sumPV=0,sumV=0;
   for(int i=PositionsTotal()-1;i>=0;i--){ if(!posInfo.SelectByIndex(i)) continue; if(posInfo.Symbol()!=symbol||posInfo.Magic()!=magic) continue; if((int)posInfo.PositionType()!=ptype) continue; sumPV+=posInfo.PriceOpen()*posInfo.Volume(); sumV+=posInfo.Volume(); }
   return sumV==0?0:sumPV/sumV;
}
double GetTotalProfit(ulong magic, int ptype, string symbol)
{
   double p=0;
   for(int i=PositionsTotal()-1;i>=0;i--){ if(!posInfo.SelectByIndex(i)) continue; if(posInfo.Symbol()!=symbol||posInfo.Magic()!=magic) continue; if((int)posInfo.PositionType()!=ptype) continue; p+=posInfo.Profit()+posInfo.Swap()+posInfo.Commission(); }
   return p;
}
double GetFirstOrderLot(ulong magic, int ptype, string symbol)
{
   datetime earliest=D'2099.01.01'; double lot=0;
   for(int i=PositionsTotal()-1;i>=0;i--){ if(!posInfo.SelectByIndex(i)) continue; if(posInfo.Symbol()!=symbol||posInfo.Magic()!=magic) continue; if((int)posInfo.PositionType()!=ptype) continue; if(posInfo.Time()<earliest){ earliest=posInfo.Time(); lot=posInfo.Volume(); } }
   return lot;
}
double GetLastGridPrice(ulong magic, int ptype, string symbol)
{
   datetime last=0; double pr=0;
   for(int i=PositionsTotal()-1;i>=0;i--){ if(!posInfo.SelectByIndex(i)) continue; if(posInfo.Symbol()!=symbol||posInfo.Magic()!=magic) continue; if((int)posInfo.PositionType()!=ptype) continue; if(posInfo.Time()>last){ last=posInfo.Time(); pr=posInfo.PriceOpen(); } }
   return pr;
}
void ClosePositionsByMagicType(ulong magic, int ptype, CTrade &trade, string symbol)
{
   if(!IsTradeAllowed(symbol)) return;
   for(int i=PositionsTotal()-1;i>=0;i--){ if(!posInfo.SelectByIndex(i)) continue; if(posInfo.Symbol()!=symbol||posInfo.Magic()!=magic) continue; if((int)posInfo.PositionType()!=ptype) continue; if(posInfo.StopLoss()!=0||posInfo.TakeProfit()!=0) trade.PositionModify(posInfo.Ticket(),0,0); }
   for(int i=PositionsTotal()-1;i>=0;i--){ if(!posInfo.SelectByIndex(i)) continue; if(posInfo.Symbol()!=symbol||posInfo.Magic()!=magic) continue; if((int)posInfo.PositionType()!=ptype) continue; trade.PositionClose(posInfo.Ticket()); }
}

//+------------------------------------------------------------------+
//| SL/TP/Grid                                                       |
//+------------------------------------------------------------------+
void CheckSL(const SeriesParams &par, CTrade &trade, datetime barTime, datetime &lastCloseBar, string symbol)
{
   if(par.slValue<=0) return;
   int types[2]={POSITION_TYPE_BUY,POSITION_TYPE_SELL};
   for(int i=0;i<2;i++)
   {
      int t=types[i];
      if(!HasPositionsOfMagicType(par.magic,t,symbol)) continue;
      double avg=GetWeightedAvgPrice(par.magic,t,symbol); if(avg<=0) continue;
      double dist=GetDistance(par.slValue,avg);
      double cur=(t==POSITION_TYPE_BUY)?SymbolInfoDouble(symbol,SYMBOL_BID):SymbolInfoDouble(symbol,SYMBOL_ASK);
      if((t==POSITION_TYPE_BUY && cur<=avg-dist) || (t==POSITION_TYPE_SELL && cur>=avg+dist))
      {
         Print("SL ",symbol," ",par.comment," ",(t==POSITION_TYPE_BUY?"Buy":"Sell")," Profit=",DoubleToString(GetTotalProfit(par.magic,t,symbol),2));
         ClosePositionsByMagicType(par.magic,t,trade,symbol);
         lastCloseBar=barTime;
      }
   }
}
void CheckTP(const SeriesParams &par, CTrade &trade, datetime barTime, datetime &lastCloseBar, string symbol)
{
   if(par.tpValue<=0) return;
   int types[2]={POSITION_TYPE_BUY,POSITION_TYPE_SELL};
   for(int i=0;i<2;i++)
   {
      int t=types[i];
      if(!HasPositionsOfMagicType(par.magic,t,symbol)) continue;
      double avg=GetWeightedAvgPrice(par.magic,t,symbol); if(avg<=0) continue;
      double dist=GetDistance(par.tpValue,avg); if(dist<=0) continue;
      double ask=SymbolInfoDouble(symbol,SYMBOL_ASK), bid=SymbolInfoDouble(symbol,SYMBOL_BID);
      if((t==POSITION_TYPE_BUY && bid>=avg+dist) || (t==POSITION_TYPE_SELL && ask<=avg-dist))
      {
         ClosePositionsByMagicType(par.magic,t,trade,symbol);
         lastCloseBar=barTime;
      }
   }
}
void ProcessGrid(const SeriesParams &par, CTrade &trade, bool &kneeOpened, string symbol)
{
   int types[2]={POSITION_TYPE_BUY,POSITION_TYPE_SELL};
   for(int i=0;i<2;i++)
   {
      int ptype=types[i];
      if(CountPositionsByMagicType(par.magic,ptype,symbol)==0) continue;
      if(kneeOpened) continue;
      double ask=SymbolInfoDouble(symbol,SYMBOL_ASK), bid=SymbolInfoDouble(symbol,SYMBOL_BID);
      double lastPrice=GetLastGridPrice(par.magic,ptype,symbol);
      double firstLot=GetFirstOrderLot(par.magic,ptype,symbol);
      if(lastPrice==0||firstLot==0) continue;
      double step=GetDistance(par.gridStep,lastPrice);
      if(ptype==POSITION_TYPE_BUY)
      {
         if(bid<=lastPrice-step && CanOpenTrade(symbol,firstLot,ORDER_TYPE_BUY))
            if(trade.Buy(firstLot,symbol,ask,0,0,par.comment+" B_G")) kneeOpened=true;
      }
      else
      {
         if(ask>=lastPrice+step && CanOpenTrade(symbol,firstLot,ORDER_TYPE_SELL))
            if(trade.Sell(firstLot,symbol,bid,0,0,par.comment+" S_G")) kneeOpened=true;
      }
   }
}

//+------------------------------------------------------------------+
//| ATR Filter                                                       |
//+------------------------------------------------------------------+
bool IsATRFilterPassed(string symbol)
{
   if(!InpAtrFilterEnabled) return true;
   int period=InpAtrPeriod; if(period<2) period=2;
   double hi[],lo[];
   if(CopyHigh(symbol,PERIOD_D1,1,period,hi)<period) return true;
   if(CopyLow(symbol,PERIOD_D1,1,period,lo)<period) return true;
   double yesterday=hi[period-1]-lo[period-1];
   double sum=0; for(int i=0;i<period;i++) sum+=hi[i]-lo[i];
   double atr=sum/period; if(atr<=0) return true;
   double pct=yesterday/atr*100.0;
   return !(pct<InpAtrMinRangePct || pct>InpAtrMaxRangePct);
}

//+------------------------------------------------------------------+
//| Signals                                                          |
//+------------------------------------------------------------------+
int CheckSignalS1(SymbolState &st)
{
   string sym=st.symbol;
   double hi[],lo[]; if(CopyHigh(sym,PERIOD_D1,1,1,hi)<1) return 0; if(CopyLow(sym,PERIOD_D1,1,1,lo)<1) return 0;
   double dH=hi[ArrayMaximum(hi)], dL=lo[ArrayMinimum(lo)];
   double zone=dH*InpStrategy1ZonePct/100.0/2.0;
   double hTop=dH+zone, hBot=dH-zone, lTop=dL+zone, lBot=dL-zone;
   double c1[]; if(CopyClose(sym,InpStrategy1Timeframe,1,1,c1)<1) return 0;
   bool inHigh=(c1[0]>=hBot && c1[0]<=hTop), inLow=(c1[0]>=lBot && c1[0]<=lTop);
   if(!inHigh && !inLow && c1[0]>lTop && c1[0]<hBot) return -2;
   int res=-2;
   int tf=PeriodSeconds(InpStrategy1Timeframe); if(tf<=0) return 0;
   int lb=86400/tf; if(lb<2) lb=2;
   double closes[], highs[], lows[];
   if(CopyClose(sym,InpStrategy1Timeframe,2,lb,closes)<lb) return 0;
   if(CopyHigh(sym,InpStrategy1Timeframe,2,lb,highs)<lb) return 0;
   if(CopyLow(sym,InpStrategy1Timeframe,2,lb,lows)<lb) return 0;
   if(inHigh)
   {
      double thr=hTop*(1.0+InpStrategy1DistancePct/100.0);
      bool wasAbove=false, hadBreak=false;
      for(int i=lb-1;i>=0;i--){ if(highs[i]>=thr) hadBreak=true; if(closes[i]<hBot||closes[i]>hTop){ if(closes[i]>hTop) wasAbove=true; break; } }
      if(wasAbove&&hadBreak) res=+1;
   }
   if(inLow)
   {
      double thr=lBot*(1.0-InpStrategy1DistancePct/100.0);
      bool wasBelow=false, hadBreak=false;
      for(int i=lb-1;i>=0;i--){ if(lows[i]<=thr) hadBreak=true; if(closes[i]<lBot||closes[i]>lTop){ if(closes[i]<lBot) wasBelow=true; break; } }
      if(wasBelow&&hadBreak){ if(res==+1) res=0; else res=-1; }
   }
   return res;
}

int CheckSignalS2(SymbolState &st)
{
   string sym=st.symbol;
   double hi[],lo[]; if(CopyHigh(sym,PERIOD_D1,1,1,hi)<1) return -2; if(CopyLow(sym,PERIOD_D1,1,1,lo)<1) return -2;
   double dH=hi[ArrayMaximum(hi)], dL=lo[ArrayMinimum(lo)];
   double zone=dH*InpStrategy2ZonePct/100.0/2.0;
   double hTop=dH+zone, hBot=dH-zone, lTop=dL+zone, lBot=dL-zone;
   double c1[]; if(CopyClose(sym,InpStrategy2Timeframe,1,1,c1)<1) return -2;
   double cc=c1[0]; int res=-2;
   datetime dt=iTime(sym,PERIOD_D1,0);
   if(dt!=st.strategy2LastDayTime){ st.strategy2BuyStage=0; st.strategy2SellStage=0; }
   st.strategy2LastDayTime=dt;
   if(st.strategy2BuyStage==0 && cc<=lTop) st.strategy2BuyStage=1;
   if(st.strategy2BuyStage==1 && cc>=hTop*(1.0+InpStrategy2DistancePct/100.0)) st.strategy2BuyStage=2;
   if(st.strategy2SellStage==0 && cc>=hBot) st.strategy2SellStage=1;
   if(st.strategy2SellStage==1 && cc<=lBot*(1.0-InpStrategy2DistancePct/100.0)) st.strategy2SellStage=2;
   if(st.strategy2BuyStage==2 && st.strategy2SellStage==2) res=0;
   else if(st.strategy2BuyStage==2) res=+1;
   else if(st.strategy2SellStage==2) res=-1;
   return res;
}

int CheckSignalS3(SymbolState &st)
{
   string sym=st.symbol;
   double hi[],lo[]; if(CopyHigh(sym,PERIOD_D1,1,1,hi)<1) return -2; if(CopyLow(sym,PERIOD_D1,1,1,lo)<1) return -2;
   double dH=hi[ArrayMaximum(hi)], dL=lo[ArrayMinimum(lo)];
   double zone=dH*InpStrategy3ZonePct/100.0/2.0;
   double hTop=dH+zone, hBot=dH-zone, lTop=dL+zone, lBot=dL-zone;
   double c1[]; if(CopyClose(sym,InpStrategy3Timeframe,1,1,c1)<1) return -2;
   double cc=c1[0]; int res=-2;
   datetime dt=iTime(sym,PERIOD_D1,0);
   if(dt!=st.strategy3LastDayTime){ st.strategy3BuyStage=0; st.strategy3SellStage=0; }
   st.strategy3LastDayTime=dt;
   if(st.strategy3SellStage==0 && cc>=hBot) st.strategy3SellStage=1;
   if(st.strategy3SellStage==1 && cc<=hBot*(1.0-InpStrategy3DistancePct/100.0)) st.strategy3SellStage=2;
   if(st.strategy3SellStage==2 && cc>=hBot && cc<=hTop) st.strategy3SellStage=3;
   if(st.strategy3BuyStage==0 && cc<=lTop) st.strategy3BuyStage=1;
   if(st.strategy3BuyStage==1 && cc>=lTop*(1.0+InpStrategy3DistancePct/100.0)) st.strategy3BuyStage=2;
   if(st.strategy3BuyStage==2 && cc>=lBot && cc<=lTop) st.strategy3BuyStage=3;
   if(st.strategy3BuyStage==3 && st.strategy3SellStage==3) res=0;
   else if(st.strategy3BuyStage==3) res=+1;
   else if(st.strategy3SellStage==3) res=-1;
   return res;
}

//+------------------------------------------------------------------+
//| Stats tracking (tester only)                                     |
//+------------------------------------------------------------------+
void TrackSeries(ulong magic, int ptype, string sym, int &hour, double &minProfit, double &closeProfit, double &maxDD[], double &totalDD[], int &cnt[], double &totalProfit[])
{
   bool has=HasPositionsOfMagicType(magic,ptype,sym);
   if(has && hour>=0){ double p=GetTotalProfit(magic,ptype,sym); if(p<minProfit) minProfit=p; closeProfit=p; }
   if(!has && hour>=0){ int h=hour; double dd=-minProfit; if(dd<0) dd=0; if(dd>maxDD[h]) maxDD[h]=dd; totalDD[h]+=dd; cnt[h]++; totalProfit[h]+=closeProfit; hour=-1; minProfit=0; closeProfit=0; }
}

//+------------------------------------------------------------------+
//| Open first                                                       |
//+------------------------------------------------------------------+
void TryOpenFirst(bool buySig, bool sellSig, const SeriesParams &par, CTrade &trade, datetime curBar, datetime tradeBar, datetime &lastTradeBar, datetime &lastCloseBar, int &hourBuy, double &minBuy, int &hourSell, double &minSell, string symbol)
{
   double ask=SymbolInfoDouble(symbol,SYMBOL_ASK), bid=SymbolInfoDouble(symbol,SYMBOL_BID);
   if(buySig && !HasPositionsOfMagicType(par.magic,POSITION_TYPE_BUY,symbol) && lastCloseBar!=curBar)
   {
      double lot=CalcLot(symbol);
      if(CanOpenTrade(symbol,lot,ORDER_TYPE_BUY) && trade.Buy(lot,symbol,ask,0,0,par.comment+" B_1"))
      { lastTradeBar=tradeBar; MqlDateTime tm; TimeToStruct(TimeCurrent(),tm); hourBuy=tm.hour; minBuy=0; }
   }
   if(sellSig && !HasPositionsOfMagicType(par.magic,POSITION_TYPE_SELL,symbol) && lastCloseBar!=curBar)
   {
      double lot=CalcLot(symbol);
      if(CanOpenTrade(symbol,lot,ORDER_TYPE_SELL) && trade.Sell(lot,symbol,bid,0,0,par.comment+" S_1"))
      { lastTradeBar=tradeBar; MqlDateTime tm; TimeToStruct(TimeCurrent(),tm); hourSell=tm.hour; minSell=0; }
   }
}

bool IsStrategyBlocked(ulong magic, string symbol)
{
   if(!InpStrategyLock && g_isHedging) return false;
   bool self=false, other=false;
   for(int i=PositionsTotal()-1;i>=0;i--){ if(!posInfo.SelectByIndex(i)) continue; if(posInfo.Symbol()!=symbol) continue; ulong m=posInfo.Magic(); if(m!=g_s1Params.magic&&m!=g_s2Params.magic&&m!=g_s3Params.magic) continue; if(m==magic){ self=true; break; } else other=true; }
   return self?false:other;
}

//+------------------------------------------------------------------+
//| Main processor                                                   |
//+------------------------------------------------------------------+
void ProcessSymbol(SymbolState &st)
{
   string sym=st.symbol;
   if(!InpStrategy1Enabled && !InpStrategy2Enabled && !InpStrategy3Enabled) return;
   if(InpStrategy1Enabled) tradeS1.SetTypeFilling(st.fillMode);
   if(InpStrategy2Enabled) tradeS2.SetTypeFilling(st.fillMode);
   if(InpStrategy3Enabled) tradeS3.SetTypeFilling(st.fillMode);

   if(MQLInfoInteger(MQL_TESTER))
   {
      if(InpStrategy1Enabled){ TrackSeries(g_s1Params.magic,POSITION_TYPE_BUY,sym,st.seriesHourBuyS1,st.seriesMinProfitBuyS1,st.seriesCloseProfitBuyS1,st.hourMaxDD_S1,st.hourTotalDD_S1,st.hourSeriesCount_S1,st.hourTotalProfit_S1); TrackSeries(g_s1Params.magic,POSITION_TYPE_SELL,sym,st.seriesHourSellS1,st.seriesMinProfitSellS1,st.seriesCloseProfitSellS1,st.hourMaxDD_S1,st.hourTotalDD_S1,st.hourSeriesCount_S1,st.hourTotalProfit_S1); }
      if(InpStrategy2Enabled){ TrackSeries(g_s2Params.magic,POSITION_TYPE_BUY,sym,st.seriesHourBuyS2,st.seriesMinProfitBuyS2,st.seriesCloseProfitBuyS2,st.hourMaxDD_S2,st.hourTotalDD_S2,st.hourSeriesCount_S2,st.hourTotalProfit_S2); TrackSeries(g_s2Params.magic,POSITION_TYPE_SELL,sym,st.seriesHourSellS2,st.seriesMinProfitSellS2,st.seriesCloseProfitSellS2,st.hourMaxDD_S2,st.hourTotalDD_S2,st.hourSeriesCount_S2,st.hourTotalProfit_S2); }
      if(InpStrategy3Enabled){ TrackSeries(g_s3Params.magic,POSITION_TYPE_BUY,sym,st.seriesHourBuyS3,st.seriesMinProfitBuyS3,st.seriesCloseProfitBuyS3,st.hourMaxDD_S3,st.hourTotalDD_S3,st.hourSeriesCount_S3,st.hourTotalProfit_S3); TrackSeries(g_s3Params.magic,POSITION_TYPE_SELL,sym,st.seriesHourSellS3,st.seriesMinProfitSellS3,st.seriesCloseProfitSellS3,st.hourMaxDD_S3,st.hourTotalDD_S3,st.hourSeriesCount_S3,st.hourTotalProfit_S3); }
   }

   datetime gbt=iTime(sym,PERIOD_M1,0);
   if(gbt!=st.lastGridBarTime)
   {
      st.lastGridBarTime=gbt;
      st.gridKneeOpenedThisBarS1=false; st.gridKneeOpenedThisBarS2=false; st.gridKneeOpenedThisBarS3=false;
      if(InpStrategy1Enabled){ CheckSL(g_s1Params,tradeS1,gbt,st.lastCloseBarS1,sym); CheckTP(g_s1Params,tradeS1,gbt,st.lastCloseBarS1,sym); if(g_s1Params.gridOn) ProcessGrid(g_s1Params,tradeS1,st.gridKneeOpenedThisBarS1,sym); }
      if(InpStrategy2Enabled){ CheckSL(g_s2Params,tradeS2,gbt,st.lastCloseBarS2,sym); CheckTP(g_s2Params,tradeS2,gbt,st.lastCloseBarS2,sym); if(g_s2Params.gridOn) ProcessGrid(g_s2Params,tradeS2,st.gridKneeOpenedThisBarS2,sym); }
      if(InpStrategy3Enabled){ CheckSL(g_s3Params,tradeS3,gbt,st.lastCloseBarS3,sym); CheckTP(g_s3Params,tradeS3,gbt,st.lastCloseBarS3,sym); if(g_s3Params.gridOn) ProcessGrid(g_s3Params,tradeS3,st.gridKneeOpenedThisBarS3,sym); }
   }

   datetime cbt=iTime(sym,PERIOD_M1,0);
   if(cbt==st.lastBarTime) return;
   st.lastBarTime=cbt;
   if((int)SymbolInfoInteger(sym,SYMBOL_SPREAD)>InpMaxSpread) return;
   datetime tbt=cbt;
   bool atrOk=IsATRFilterPassed(sym);

   if(InpStrategy1Enabled && atrOk && !IsStrategyBlocked(g_s1Params.magic,sym) && tbt!=st.lastTradeBarS1)
   {
      int sig=CheckSignalS1(st); bool b=sig==+1||sig==0, s=sig==-1||sig==0;
      if(b||s) TryOpenFirst(b,s,g_s1Params,tradeS1,cbt,tbt,st.lastTradeBarS1,st.lastCloseBarS1,st.seriesHourBuyS1,st.seriesMinProfitBuyS1,st.seriesHourSellS1,st.seriesMinProfitSellS1,sym);
   }
   if(InpStrategy2Enabled && atrOk && !IsStrategyBlocked(g_s2Params.magic,sym) && tbt!=st.lastTradeBarS2)
   {
      int sig=CheckSignalS2(st); bool b=sig==+1||sig==0, s=sig==-1||sig==0;
      if(b||s){ TryOpenFirst(b,s,g_s2Params,tradeS2,cbt,tbt,st.lastTradeBarS2,st.lastCloseBarS2,st.seriesHourBuyS2,st.seriesMinProfitBuyS2,st.seriesHourSellS2,st.seriesMinProfitSellS2,sym);
         if(b && st.strategy2BuyStage==2) st.strategy2BuyStage=0; if(s && st.strategy2SellStage==2) st.strategy2SellStage=0; }
   }
   if(InpStrategy3Enabled && atrOk && !IsStrategyBlocked(g_s3Params.magic,sym) && tbt!=st.lastTradeBarS3)
   {
      int sig=CheckSignalS3(st); bool b=sig==+1||sig==0, s=sig==-1||sig==0;
      if(b||s){ TryOpenFirst(b,s,g_s3Params,tradeS3,cbt,tbt,st.lastTradeBarS3,st.lastCloseBarS3,st.seriesHourBuyS3,st.seriesMinProfitBuyS3,st.seriesHourSellS3,st.seriesMinProfitSellS3,sym);
         if(b && st.strategy3BuyStage==3) st.strategy3BuyStage=0; if(s && st.strategy3SellStage==3) st.strategy3SellStage=0; }
   }
}

void OnTick(){ ProcessSymbol(g_state); }
//+------------------------------------------------------------------+

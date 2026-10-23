//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Francesc Jordi Mallol Nolden"
#property version   "1.50"
#property strict

#include <Trade\Trade.mqh>

CTrade Trade;

enum ENUM_SESSION_TIME_MODE
  {
   SESSION_JST_DARWINEX_AUTO=0,
   SESSION_MANUAL_SERVER=1
  };

input group "Cash session"
input ENUM_SESSION_TIME_MODE InpSessionTimeMode = SESSION_JST_DARWINEX_AUTO; // Session time mode
input int      InpSessionOpenHour          = 9;      // Session open hour
input int      InpSessionOpenMinute        = 0;      // Session open minute
input int      InpSessionCloseHour         = 15;     // Session close hour
input int      InpSessionCloseMinute       = 30;     // Session close minute
input int      InpOpeningRangeMinutes      = 10;     // Opening range duration in minutes (5-15)
input int      InpMaxEntryMinutesFromOpen  = 90;     // Maximum entry time after session open (minutes)
input int      InpExitMinutesBeforeClose   = 5;      // Forced exit before session close (minutes)

input group "BUY - bullish gaps"
input bool     InpEnableBuyGaps            = true;   // Enable BUY trades on bullish gaps
input double   InpMinimumBuyGapPercent     = 1.0;    // Minimum bullish gap (%)

input group "SELL - bearish gaps"
input bool     InpEnableSellGaps           = true;   // Enable SELL trades on bearish gaps
input double   InpMinimumSellGapPercent    = 1.0;    // Minimum bearish gap (%)

input group "Common signal filters"
input bool     InpUseRealVolumeIfAvailable = true;   // Use real volume when available
input double   InpMaxSpreadPoints          = 0.0;    // Maximum spread in points (0 = disabled)
input double   InpMaxSpreadToStopPercent   = 10.0;   // Maximum spread as % of stop (0 = disabled)
input double   InpStopBufferPoints         = 0.0;    // Stop-loss buffer in points

input group "BUY risk"
input double   InpBuyRiskPercent           = 0.50;   // BUY risk per trade (% of equity)

input group "SELL risk"
input double   InpSellRiskPercent          = 0.50;   // Full SELL risk per trade (% of equity)
input bool     InpReduceRiskOnSmallSellGap = true;   // Reduce risk on smaller SELL gaps
input double   InpSellFullRiskFromGapPct   = 1.25;   // Gap required for full SELL risk (%)
input double   InpSmallSellRiskPercent     = 0.25;   // Reduced SELL risk (% of equity)

input group "Volume and exits"
input double   InpFixedLots                = 0.0;    // Fixed lot size (0 = risk-based sizing)
input double   InpMaxLots                  = 0.0;    // Maximum lot size (0 = broker limit)
input double   InpPartialClosePercent      = 40.0;   // Partial close size (%)
input double   InpPartialTargetR           = 1.0;    // Partial close target (R multiple)
input double   InpFinalTargetR             = 2.0;    // Final take-profit target (R multiple)
input bool     InpMoveStopToBreakEven      = true;   // Move stop to break-even after partial close

input group "Execution"
input ulong    InpMagicNumber              = 2250101; // Expert Advisor magic number
input ulong    InpMaxSlippagePoints        = 30;      // Maximum slippage in points
input bool     InpShowStatusOnChart        = true;    // Show status panel on chart
input bool     InpPrintDailyDiagnostics    = true;    // Print daily diagnostic messages

// Daily state
int      g_day_key          = -1;
datetime g_session_open     = 0;
datetime g_session_close    = 0;
datetime g_range_end        = 0;
datetime g_entry_deadline   = 0;
datetime g_force_exit       = 0;

double   g_previous_close   = 0.0;
double   g_session_open_px  = 0.0;
double   g_gap_percent      = 0.0;
double   g_half_gap_level   = 0.0;
double   g_range_high       = 0.0;
double   g_range_low        = 0.0;
double   g_vwap             = 0.0;

bool     g_setup_ready      = false;
bool     g_cancelled        = false;
bool     g_traded_today     = false;
string   g_status           = "Initializing";

// Position state; also stored in terminal global variables.
double   g_initial_risk     = 0.0;
double   g_initial_volume   = 0.0;
bool     g_partial_done     = false;
double   g_last_loss_per_lot= 0.0;
double   g_last_raw_volume  = 0.0;

//+------------------------------------------------------------------+
//| Date and state utilities                                         |
//+------------------------------------------------------------------+
int DateKey(const datetime value)
  {
   MqlDateTime parts;
   TimeToStruct(value,parts);
   return(parts.year*10000+parts.mon*100+parts.day);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime TimeOnSameDate(const datetime base,const int hour,const int minute)
  {
   MqlDateTime parts;
   TimeToStruct(base,parts);
   parts.hour=hour;
   parts.min=minute;
   parts.sec=0;
   return(StructToTime(parts));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int NthSundayOfMonth(const int year,const int month,const int occurrence)
  {
   MqlDateTime parts;
   ZeroMemory(parts);
   parts.year=year;
   parts.mon=month;
   parts.day=1;
   parts.hour=12;
   datetime first_day=StructToTime(parts);
   TimeToStruct(first_day,parts);

   int first_sunday=1+((7-parts.day_of_week)%7);
   return(first_sunday+(occurrence-1)*7);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsDarwinexUsSummerTime(const datetime server_date)
  {
// US rule in effect since 2007:
// second Sunday in March through the first Sunday in November.
// Japanese sessions run Monday through Friday, so the exact intraday
// time of the Sunday clock change does not need to be modeled.
   MqlDateTime parts;
   TimeToStruct(server_date,parts);

   if(parts.mon<3 || parts.mon>11)
      return(false);
   if(parts.mon>3 && parts.mon<11)
      return(true);

   int start_day=NthSundayOfMonth(parts.year,3,2);
   int end_day=NthSundayOfMonth(parts.year,11,1);
   if(parts.mon==3)
      return(parts.day>=start_day);
   return(parts.day<end_day);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int DarwinexServerUtcOffset(const datetime server_date)
  {
   return(IsDarwinexUsSummerTime(server_date) ? 3 : 2);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
datetime SessionTimeForDate(const datetime base,const int session_hour,const int session_minute)
  {
   if(InpSessionTimeMode==SESSION_MANUAL_SERVER)
      return(TimeOnSameDate(base,session_hour,session_minute));

// Tokyo uses JST (UTC+9) year-round. Darwinex uses UTC+2/UTC+3.
   int server_offset=DarwinexServerUtcOffset(base);
   int total_minutes=session_hour*60+session_minute-9*60+server_offset*60;
   int day_shift=0;
   while(total_minutes<0)
     {
      total_minutes+=1440;
      day_shift--;
     }
   while(total_minutes>=1440)
     {
      total_minutes-=1440;
      day_shift++;
     }

   int server_hour=total_minutes/60;
   int server_minute=total_minutes%60;
   return(TimeOnSameDate(base,server_hour,server_minute)+day_shift*86400);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string SessionModeDescription(const datetime now)
  {
   if(InpSessionTimeMode==SESSION_MANUAL_SERVER)
      return("Manual: server time");
   return("JST->Darwinex automatic (GMT+"+
          IntegerToString(DarwinexServerUtcOffset(now))+")");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string StateKey(const string suffix)
  {
   string key="N225GAP."+IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN))+"."+
              IntegerToString((long)InpMagicNumber)+"."+_Symbol;
   if(StringLen(key)>50)
      key=StringSubstr(key,0,50);
   return(key+"."+suffix);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SavePositionState(const int position_day)
  {
   GlobalVariableSet(StateKey("DAY"),(double)position_day);
   GlobalVariableSet(StateKey("RISK"),g_initial_risk);
   GlobalVariableSet(StateKey("VOL"),g_initial_volume);
   GlobalVariableSet(StateKey("PART"),g_partial_done ? 1.0 : 0.0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void LoadPositionState(const ulong ticket)
  {
   if(ticket==0 || !PositionSelectByTicket(ticket))
      return;

   datetime position_time=(datetime)PositionGetInteger(POSITION_TIME);
   int position_day=DateKey(position_time);

   if(GlobalVariableCheck(StateKey("DAY")) &&
      (int)GlobalVariableGet(StateKey("DAY"))==position_day)
     {
      g_initial_risk=GlobalVariableGet(StateKey("RISK"));
      g_initial_volume=GlobalVariableGet(StateKey("VOL"));
      g_partial_done=(GlobalVariableGet(StateKey("PART"))>0.5);
      return;
     }

   double entry=PositionGetDouble(POSITION_PRICE_OPEN);
   double stop=PositionGetDouble(POSITION_SL);
   g_initial_risk=(stop>0.0 ? MathAbs(entry-stop) : 0.0);
   g_initial_volume=PositionGetDouble(POSITION_VOLUME);
   g_partial_done=false;
   SavePositionState(position_day);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetDay(const datetime now)
  {
   g_day_key=DateKey(now);
   g_session_open=SessionTimeForDate(now,InpSessionOpenHour,InpSessionOpenMinute);
   g_session_close=SessionTimeForDate(now,InpSessionCloseHour,InpSessionCloseMinute);
   g_range_end=g_session_open+InpOpeningRangeMinutes*60;
   g_entry_deadline=g_session_open+InpMaxEntryMinutesFromOpen*60;
   g_force_exit=g_session_close-InpExitMinutesBeforeClose*60;

   g_previous_close=0.0;
   g_session_open_px=0.0;
   g_gap_percent=0.0;
   g_half_gap_level=0.0;
   g_range_high=0.0;
   g_range_low=0.0;
   g_vwap=0.0;
   g_setup_ready=false;
   g_cancelled=false;
   g_traded_today=false;
   g_status="Waiting for session open";

   g_initial_risk=0.0;
   g_initial_volume=0.0;
   g_partial_done=false;
   g_last_loss_per_lot=0.0;
   g_last_raw_volume=0.0;
  }

//+------------------------------------------------------------------+
//| Position and history access                                      |
//+------------------------------------------------------------------+
ulong FindOurPosition()
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0)
         continue;
      if(PositionGetString(POSITION_SYMBOL)==_Symbol &&
         (ulong)PositionGetInteger(POSITION_MAGIC)==InpMagicNumber)
         return(ticket);
     }
   return(0);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HasAnyPositionOnSymbol()
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket>0 && PositionGetString(POSITION_SYMBOL)==_Symbol)
         return(true);
     }
   return(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool HasEnteredToday()
  {
   if(!HistorySelect(g_session_open,TimeCurrent()))
      return(false);

   int total=HistoryDealsTotal();
   for(int i=total-1;i>=0;i--)
     {
      ulong deal=HistoryDealGetTicket(i);
      if(deal==0)
         continue;
      if(HistoryDealGetString(deal,DEAL_SYMBOL)!=_Symbol)
         continue;
      if((ulong)HistoryDealGetInteger(deal,DEAL_MAGIC)!=InpMagicNumber)
         continue;

      ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal,DEAL_ENTRY);
      if(entry==DEAL_ENTRY_IN || entry==DEAL_ENTRY_INOUT)
         return(true);
     }
   return(false);
  }

//+------------------------------------------------------------------+
//| Session, range and VWAP data                                     |
//+------------------------------------------------------------------+
bool FindPreviousSessionClose(double &close_price)
  {
// Search up to seven calendar days back to cover weekends.
   for(int days_back=1;days_back<=7;days_back++)
     {
      datetime candidate=g_session_open-days_back*86400;
      datetime from=SessionTimeForDate(candidate,InpSessionOpenHour,InpSessionOpenMinute);
      datetime to=SessionTimeForDate(candidate,InpSessionCloseHour,InpSessionCloseMinute)-1;

      MqlRates rates[];
      int copied=CopyRates(_Symbol,PERIOD_M1,from,to,rates);
      if(copied>0)
        {
         close_price=rates[copied-1].close;
         return(close_price>0.0);
        }
     }
   return(false);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool LoadOpeningRange()
  {
   MqlRates rates[];
   int copied=CopyRates(_Symbol,PERIOD_M1,g_session_open,g_range_end-1,rates);
   if(copied<=0)
      return(false);

   g_session_open_px=rates[0].open;
   g_range_high=rates[0].high;
   g_range_low=rates[0].low;

   for(int i=1;i<copied;i++)
     {
      g_range_high=MathMax(g_range_high,rates[i].high);
      g_range_low=MathMin(g_range_low,rates[i].low);
     }
   return(g_session_open_px>0.0 && g_range_high>g_range_low);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CalculateSessionMetrics(const datetime now,double &vwap,double &session_high,double &session_low)
  {
   MqlRates rates[];
   int copied=CopyRates(_Symbol,PERIOD_M1,g_session_open,now,rates);
   if(copied<=0)
      return(false);

   double weighted_sum=0.0;
   double volume_sum=0.0;
   session_high=rates[0].high;
   session_low=rates[0].low;

   for(int i=0;i<copied;i++)
     {
      double typical=(rates[i].high+rates[i].low+rates[i].close)/3.0;
      double volume=0.0;
      if(InpUseRealVolumeIfAvailable && rates[i].real_volume>0)
         volume=(double)rates[i].real_volume;
      else
         volume=(double)rates[i].tick_volume;
      if(volume<=0.0)
         volume=1.0;

      weighted_sum+=typical*volume;
      volume_sum+=volume;
      session_high=MathMax(session_high,rates[i].high);
      session_low=MathMin(session_low,rates[i].low);
     }

   if(volume_sum<=0.0)
      return(false);
   vwap=weighted_sum/volume_sum;
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PrepareSetup()
  {
   if(g_setup_ready || g_cancelled)
      return(g_setup_ready);

   if(!FindPreviousSessionClose(g_previous_close))
     {
      g_status="Previous session close data unavailable";
      return(false);
     }

   if(!LoadOpeningRange())
     {
      g_status="Waiting for opening range bars";
      return(false);
     }

   g_gap_percent=(g_session_open_px/g_previous_close-1.0)*100.0;

   if(g_gap_percent>0.0 && !InpEnableBuyGaps)
     {
      g_cancelled=true;
      g_status="Cancelled: BUY gaps disabled";
      return(false);
     }
   if(g_gap_percent<0.0 && !InpEnableSellGaps)
     {
      g_cancelled=true;
      g_status="Cancelled: SELL gaps disabled";
      return(false);
     }

   double minimum_gap=(g_gap_percent>0.0 ?
                       InpMinimumBuyGapPercent :
                       InpMinimumSellGapPercent);
   if(MathAbs(g_gap_percent)<minimum_gap)
     {
      g_cancelled=true;
      g_status=(g_gap_percent>0.0 ?
                "Cancelled: BUY gap below minimum" :
                "Cancelled: SELL gap below minimum");
      if(InpPrintDailyDiagnostics)
         PrintFormat("DIAG %s | SKIPPED %s gap=%.2f%% (< %.2f%%) | previous close=%.2f open=%.2f",
                     TimeToString(g_session_open,TIME_DATE),
                     (g_gap_percent>0.0 ? "BUY" : "SELL"),g_gap_percent,
                     minimum_gap,g_previous_close,g_session_open_px);
      return(false);
     }

   g_half_gap_level=g_previous_close+0.5*(g_session_open_px-g_previous_close);
   g_setup_ready=true;
   g_status="Setup active: waiting for breakout and VWAP";
   if(InpPrintDailyDiagnostics)
      PrintFormat("DIAG %s | SETUP gap=%.2f%% | previous=%.2f open=%.2f range=%.2f-%.2f half_gap=%.2f",
                  TimeToString(g_session_open,TIME_DATE),g_gap_percent,g_previous_close,
                  g_session_open_px,g_range_low,g_range_high,g_half_gap_level);
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool UpdateSetupMetrics(const datetime now)
  {
   double session_high=0.0;
   double session_low=0.0;
   if(!CalculateSessionMetrics(now,g_vwap,session_high,session_low))
     {
      g_status="Unable to calculate VWAP";
      return(false);
     }

// Once more than 50% of the gap is filled, cancellation is permanent for the day.
   if(g_gap_percent>0.0 && session_low<=g_half_gap_level)
     {
      g_cancelled=true;
      g_setup_ready=false;
      g_status="Cancelled: bullish gap filled by more than 50%";
      if(InpPrintDailyDiagnostics)
         PrintFormat("DIAG %s | CANCELLED 50%% bullish gap fill | low=%.2f level=%.2f",
                     TimeToString(g_session_open,TIME_DATE),session_low,g_half_gap_level);
      return(false);
     }
   if(g_gap_percent<0.0 && session_high>=g_half_gap_level)
     {
      g_cancelled=true;
      g_setup_ready=false;
      g_status="Cancelled: bearish gap filled by more than 50%";
      if(InpPrintDailyDiagnostics)
         PrintFormat("DIAG %s | CANCELLED 50%% bearish gap fill | high=%.2f level=%.2f",
                     TimeToString(g_session_open,TIME_DATE),session_high,g_half_gap_level);
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Volume and execution validation                                  |
//+------------------------------------------------------------------+
int VolumeDigits()
  {
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   int digits=0;
   while(step<1.0 && digits<8)
     {
      step*=10.0;
      digits++;
     }
   return(digits);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NormalizeVolumeDown(double volume)
  {
   double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maximum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step<=0.0 || minimum<=0.0)
      return(0.0);

   volume=MathMin(volume,maximum);
   volume=MathFloor((volume+1e-12)/step)*step;
   volume=NormalizeDouble(volume,VolumeDigits());
   if(volume<minimum)
      return(0.0);
   return(volume);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateEntryVolume(const double entry,const double stop,const double risk_percent)
  {
   if(InpFixedLots>0.0)
      return(NormalizeVolumeDown(InpFixedLots));

   if(risk_percent<=0.0)
      return(0.0);

   double distance=MathAbs(entry-stop);
   if(distance<=0.0)
      return(0.0);

   double risk_money=AccountInfoDouble(ACCOUNT_EQUITY)*risk_percent/100.0;
   ENUM_ORDER_TYPE order_type=(entry>stop ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   double calculated_profit=0.0;
   double loss_per_lot=0.0;

// Returns the loss already converted to the account currency.
// Avoids incorrect tick-value scaling on JPY-denominated CFDs.
   ResetLastError();
   if(OrderCalcProfit(order_type,_Symbol,1.0,entry,stop,calculated_profit))
      loss_per_lot=MathAbs(calculated_profit);

// Fallback if the server does not allow OrderCalcProfit at that moment.
   if(loss_per_lot<=0.0)
     {
      double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
      double tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE_LOSS);
      if(tick_value<=0.0)
         tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
      if(tick_size<=0.0 || tick_value<=0.0)
         return(0.0);
      loss_per_lot=(distance/tick_size)*tick_value;
     }

   if(loss_per_lot<=0.0)
      return(0.0);

   g_last_loss_per_lot=loss_per_lot;
   g_last_raw_volume=risk_money/loss_per_lot;
   if(InpMaxLots>0.0)
      g_last_raw_volume=MathMin(g_last_raw_volume,InpMaxLots);
   return(NormalizeVolumeDown(g_last_raw_volume));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CurrentSellRiskPercent()
  {
   if(!InpReduceRiskOnSmallSellGap)
      return(InpSellRiskPercent);

   if(MathAbs(g_gap_percent)<InpSellFullRiskFromGapPct)
      return(InpSmallSellRiskPercent);

   return(InpSellRiskPercent);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TradeResultSucceeded()
  {
   uint code=Trade.ResultRetcode();
   return(code==TRADE_RETCODE_DONE ||
          code==TRADE_RETCODE_DONE_PARTIAL ||
          code==TRADE_RETCODE_PLACED ||
          code==TRADE_RETCODE_NO_CHANGES);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ReportTradeFailure(const string action)
  {
   Print(action," failed. Retcode=",Trade.ResultRetcode(),
         " (",Trade.ResultRetcodeDescription(),")");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool SpreadIsAcceptable(const MqlTick &tick)
  {
   if(InpMaxSpreadPoints<=0.0)
      return(true);
   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   if(point<=0.0)
      return(false);
   return((tick.ask-tick.bid)/point<=InpMaxSpreadPoints);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool DynamicSpreadIsAcceptable(const MqlTick &tick,
                               const double stop_distance,
                               double &spread_percent)
  {
   spread_percent=0.0;
   if(InpMaxSpreadToStopPercent<=0.0)
      return(true);

   double spread=tick.ask-tick.bid;
   if(spread<0.0 || stop_distance<=0.0)
     {
      spread_percent=DBL_MAX;
      return(false);
     }

   spread_percent=100.0*spread/stop_distance;
   return(spread_percent<=InpMaxSpreadToStopPercent);
  }

//+------------------------------------------------------------------+
//| Entry                                                            |
//+------------------------------------------------------------------+
void StoreNewPositionState(const ulong ticket)
  {
   if(ticket==0 || !PositionSelectByTicket(ticket))
      return;

   double entry=PositionGetDouble(POSITION_PRICE_OPEN);
   double stop=PositionGetDouble(POSITION_SL);
   g_initial_risk=MathAbs(entry-stop);
   g_initial_volume=PositionGetDouble(POSITION_VOLUME);
   g_partial_done=false;
   SavePositionState(DateKey((datetime)PositionGetInteger(POSITION_TIME)));

   ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   int digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   double current_target=PositionGetDouble(POSITION_TP);
   double final_target=(type==POSITION_TYPE_BUY ?
                        entry+InpFinalTargetR*g_initial_risk :
                        entry-InpFinalTargetR*g_initial_risk);
   final_target=NormalizeDouble(final_target,digits);

// Avoid modifying a newly opened order when the TP already matches.
// Some servers reject this redundant modification due to the freeze level.
   double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(current_target>0.0 && MathAbs(current_target-final_target)<=tick_size)
      return;

   if(!Trade.PositionModify(ticket,stop,final_target) || !TradeResultSucceeded())
      ReportTradeFailure("Final target adjustment");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TryEntry(const datetime now)
  {
   if(now>g_entry_deadline)
     {
      g_cancelled=true;
      g_setup_ready=false;
      g_status="Cancelled: entry window expired";
      if(InpPrintDailyDiagnostics)
         PrintFormat("DIAG %s | CANCELLED no valid breakout before %s",
                     TimeToString(g_session_open,TIME_DATE),
                     TimeToString(g_entry_deadline,TIME_MINUTES));
      return;
     }

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick) || tick.ask<=0.0 || tick.bid<=0.0)
      return;

   if(!SpreadIsAcceptable(tick))
     {
      g_status="Waiting: spread too wide";
      return;
     }

   double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
   int digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   double broker_stop_distance=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*point;
   double buffer=InpStopBufferPoints*point;

   if(g_gap_percent>0.0)
     {
      if(!(tick.bid>g_range_high && tick.bid>g_vwap))
        {
         g_status="Bullish gap: waiting for breakout above range and VWAP";
         return;
        }

      double stop=MathMin(g_range_low-buffer,tick.bid-broker_stop_distance);
      stop=NormalizeDouble(stop,digits);
      double risk=tick.ask-stop;
      if(risk<=0.0)
         return;
      double spread_percent=0.0;
      if(!DynamicSpreadIsAcceptable(tick,risk,spread_percent))
        {
         g_status=StringFormat("Waiting: spread %.1f%% of stop (max %.1f%%)",
                               spread_percent,InpMaxSpreadToStopPercent);
         return;
        }
      double target=NormalizeDouble(tick.ask+InpFinalTargetR*risk,digits);
      double applied_risk_percent=InpBuyRiskPercent;
      double volume=CalculateEntryVolume(tick.ask,stop,applied_risk_percent);
      if(volume<=0.0)
        {
         g_cancelled=true;
         g_setup_ready=false;
         g_status="Cancelled: minimum volume exceeds allowed risk";
         if(InpPrintDailyDiagnostics)
            PrintFormat("DIAG %s | CANCELLED volume | entry=%.2f stop=%.2f loss_per_lot=%.2f raw_volume=%.4f minimum=%.2f",
                        TimeToString(g_session_open,TIME_DATE),tick.ask,stop,
                        g_last_loss_per_lot,g_last_raw_volume,
                        SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN));
         return;
        }

      if(InpPrintDailyDiagnostics)
         PrintFormat("DIAG %s | LONG ENTRY | entry=%.2f stop=%.2f volume=%.2f risk=%.2f%% loss_per_lot=%.2f spread_to_stop=%.2f%%",
                     TimeToString(g_session_open,TIME_DATE),tick.ask,stop,volume,
                     applied_risk_percent,g_last_loss_per_lot,spread_percent);

      bool sent=Trade.Buy(volume,_Symbol,0.0,stop,target,"N225 gap long");
      if(!sent || !TradeResultSucceeded())
        {
         ReportTradeFailure("Long entry");
         g_status="Failed to execute long entry";
         return;
        }
     }
   else
     {
      if(!(tick.ask<g_range_low && tick.ask<g_vwap))
        {
         g_status="Bearish gap: waiting for breakout below range and VWAP";
         return;
        }

      double stop=MathMax(g_range_high+buffer,tick.ask+broker_stop_distance);
      stop=NormalizeDouble(stop,digits);
      double risk=stop-tick.bid;
      if(risk<=0.0)
         return;
      double spread_percent=0.0;
      if(!DynamicSpreadIsAcceptable(tick,risk,spread_percent))
        {
         g_status=StringFormat("Waiting: spread %.1f%% of stop (max %.1f%%)",
                               spread_percent,InpMaxSpreadToStopPercent);
         return;
        }
      double target=NormalizeDouble(tick.bid-InpFinalTargetR*risk,digits);
      double applied_risk_percent=CurrentSellRiskPercent();
      double volume=CalculateEntryVolume(tick.bid,stop,applied_risk_percent);
      if(volume<=0.0)
        {
         g_cancelled=true;
         g_setup_ready=false;
         g_status="Cancelled: minimum volume exceeds allowed risk";
         if(InpPrintDailyDiagnostics)
            PrintFormat("DIAG %s | CANCELLED volume | entry=%.2f stop=%.2f loss_per_lot=%.2f raw_volume=%.4f minimum=%.2f",
                        TimeToString(g_session_open,TIME_DATE),tick.bid,stop,
                        g_last_loss_per_lot,g_last_raw_volume,
                        SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN));
         return;
        }

      if(InpPrintDailyDiagnostics)
         PrintFormat("DIAG %s | SHORT ENTRY | entry=%.2f stop=%.2f volume=%.2f risk=%.2f%% gap=%.2f%% loss_per_lot=%.2f spread_to_stop=%.2f%%",
                     TimeToString(g_session_open,TIME_DATE),tick.bid,stop,volume,
                     applied_risk_percent,MathAbs(g_gap_percent),
                     g_last_loss_per_lot,spread_percent);

      bool sent=Trade.Sell(volume,_Symbol,0.0,stop,target,"N225 gap short");
      if(!sent || !TradeResultSucceeded())
        {
         ReportTradeFailure("Short entry");
         g_status="Failed to execute short entry";
         return;
        }
     }

   ulong ticket=FindOurPosition();
   if(ticket>0)
     {
      StoreNewPositionState(ticket);
      g_traded_today=true;
      g_status="Position open";
     }
  }

//+------------------------------------------------------------------+
//| Position management                                              |
//+------------------------------------------------------------------+
double PartialCloseVolume(const double current_volume)
  {
   double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double desired=NormalizeVolumeDown(current_volume*InpPartialClosePercent/100.0);
   double maximum_close=NormalizeVolumeDown(current_volume-minimum);
   if(desired<=0.0 || maximum_close<=0.0)
      return(0.0);
   return(MathMin(desired,maximum_close));
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ClosePartial(const ulong ticket,const double volume)
  {
   if(!PositionSelectByTicket(ticket))
      return(false);

   ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   ENUM_ACCOUNT_MARGIN_MODE mode=(ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
   bool sent=false;

   if(mode==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
      sent=Trade.PositionClosePartial(ticket,volume,InpMaxSlippagePoints);
   else
     {
      // In netting mode, an opposite trade reduces the position volume.
      if(type==POSITION_TYPE_BUY)
         sent=Trade.Sell(volume,_Symbol,0.0,0.0,0.0,"N225 partial");
      else
         sent=Trade.Buy(volume,_Symbol,0.0,0.0,0.0,"N225 partial");
     }

   if(!sent || !TradeResultSucceeded())
     {
      ReportTradeFailure("Partial close");
      return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MoveStopToBreakEven()
  {
   ulong ticket=FindOurPosition();
   if(ticket==0 || !PositionSelectByTicket(ticket))
      return;

   double entry=PositionGetDouble(POSITION_PRICE_OPEN);
   double target=PositionGetDouble(POSITION_TP);
   int digits=(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS);
   entry=NormalizeDouble(entry,digits);

   if(!Trade.PositionModify(ticket,entry,target) || !TradeResultSucceeded())
      ReportTradeFailure("Move stop to break-even");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAtSessionEnd(const ulong ticket)
  {
   if(!Trade.PositionClose(ticket,InpMaxSlippagePoints) || !TradeResultSucceeded())
     {
      ReportTradeFailure("End-of-session close");
      g_status="Unable to close at the end of the session";
      return;
     }
   g_status="Position closed at the end of the session";
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ManagePosition(const ulong ticket,const datetime now)
  {
   if(!PositionSelectByTicket(ticket))
      return;

// Also closes a residual position when reconnecting outside the session.
   if(now<g_session_open || now>=g_force_exit)
     {
      CloseAtSessionEnd(ticket);
      return;
     }

   if(g_initial_risk<=0.0)
      LoadPositionState(ticket);
   if(g_initial_risk<=0.0)
     {
      g_status="Position open, but initial risk could not be restored";
      return;
     }

   ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
   double entry=PositionGetDouble(POSITION_PRICE_OPEN);
   double current_volume=PositionGetDouble(POSITION_VOLUME);

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick))
      return;

   double partial_target=(type==POSITION_TYPE_BUY ?
                          entry+InpPartialTargetR*g_initial_risk :
                          entry-InpPartialTargetR*g_initial_risk);
   bool target_hit=(type==POSITION_TYPE_BUY ? tick.bid>=partial_target : tick.ask<=partial_target);

   if(!g_partial_done && target_hit)
     {
      double close_volume=PartialCloseVolume(current_volume);
      if(close_volume<=0.0)
        {
         // The lot is too small to split. Avoid repeated attempts.
         g_partial_done=true;
         SavePositionState(g_day_key);
         g_status="1R reached; insufficient volume for partial close";
         return;
        }

      if(ClosePartial(ticket,close_volume))
        {
         g_partial_done=true;
         SavePositionState(g_day_key);
         g_status="Partial close executed at 1R";
         if(InpMoveStopToBreakEven)
            MoveStopToBreakEven();
        }
     }
   else
      g_status=(g_partial_done ? "Managing remaining volume until target/close" :
                "Position open: waiting for 1R");
  }

//+------------------------------------------------------------------+
//| Information panel                                                |
//+------------------------------------------------------------------+
void UpdateChartStatus(const datetime now)
  {
   if(!InpShowStatusOnChart)
      return;

   string gap_text=(g_session_open_px>0.0 ? DoubleToString(g_gap_percent,2)+"%" : "n/a");
   string vwap_text=(g_vwap>0.0 ? DoubleToString(g_vwap,_Digits) : "n/a");
   string range_text=(g_range_high>0.0 ?
                      DoubleToString(g_range_low,_Digits)+" - "+DoubleToString(g_range_high,_Digits) : "n/a");

   Comment("Nikkei 225 - Gap Continuation EA\n",
           "Server time: ",TimeToString(now,TIME_DATE|TIME_SECONDS),"\n",
           "Schedule: ",SessionModeDescription(now),"\n",
           "Effective session: ",TimeToString(g_session_open,TIME_MINUTES)," - ",
           TimeToString(g_session_close,TIME_MINUTES),"\n",
           "Gap: ",gap_text," | VWAP: ",vwap_text,"\n",
           "Opening range: ",range_text,"\n",
           "Status: ",g_status);
  }

//+------------------------------------------------------------------+
//| Events                                                           |
//+------------------------------------------------------------------+
int OnInit()
  {
   int open_minutes=InpSessionOpenHour*60+InpSessionOpenMinute;
   int close_minutes=InpSessionCloseHour*60+InpSessionCloseMinute;

   if(InpSessionOpenHour<0 || InpSessionOpenHour>23 ||
      InpSessionCloseHour<0 || InpSessionCloseHour>23 ||
      InpSessionOpenMinute<0 || InpSessionOpenMinute>59 ||
      InpSessionCloseMinute<0 || InpSessionCloseMinute>59 ||
      close_minutes<=open_minutes)
     {
      Print("Invalid session parameters.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpOpeningRangeMinutes<5 || InpOpeningRangeMinutes>15 ||
      InpMaxEntryMinutesFromOpen<InpOpeningRangeMinutes ||
      InpExitMinutesBeforeClose<0 ||
      InpExitMinutesBeforeClose>=close_minutes-open_minutes)
     {
      Print("Invalid opening range, entry window or session exit parameters.");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpMinimumBuyGapPercent<=0.0 || InpMinimumSellGapPercent<=0.0 ||
      InpBuyRiskPercent<=0.0 || InpSellRiskPercent<=0.0 ||
      (InpReduceRiskOnSmallSellGap &&
       (InpSmallSellRiskPercent<=0.0 ||
        InpSmallSellRiskPercent>InpSellRiskPercent ||
        InpSellFullRiskFromGapPct<InpMinimumSellGapPercent)) ||
      InpFixedLots<0.0 ||
      InpMaxLots<0.0 ||
      InpMaxSpreadPoints<0.0 || InpMaxSpreadToStopPercent<0.0 ||
      InpStopBufferPoints<0.0 ||
      InpPartialClosePercent<=0.0 || InpPartialClosePercent>=100.0 ||
      InpPartialTargetR<=0.0 || InpFinalTargetR<=InpPartialTargetR)
     {
      Print("Invalid signal/risk parameters.");
      return(INIT_PARAMETERS_INCORRECT);
     }

   if(!SymbolSelect(_Symbol,true))
     {
      Print("Unable to select symbol ",_Symbol);
      return(INIT_FAILED);
     }

   Trade.SetExpertMagicNumber(InpMagicNumber);
   Trade.SetDeviationInPoints(InpMaxSlippagePoints);
   Trade.SetTypeFillingBySymbol(_Symbol);
   Trade.SetAsyncMode(false);

   datetime now=TimeCurrent();
   ResetDay(now);
   ulong ticket=FindOurPosition();
   if(ticket>0)
      LoadPositionState(ticket);

   Print("Nikkei225 Gap Continuation EA started on ",_Symbol,
         ". Time mode: ",SessionModeDescription(now),
         ". Effective server session: ",TimeToString(g_session_open,TIME_MINUTES),
         "-",TimeToString(g_session_close,TIME_MINUTES));
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   if(InpShowStatusOnChart)
      Comment("");
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {
   datetime now=TimeCurrent();
   if(now<=0)
      return;

   if(DateKey(now)!=g_day_key)
      ResetDay(now);

   ulong our_position=FindOurPosition();
   if(our_position>0)
     {
      ManagePosition(our_position,now);
      UpdateChartStatus(now);
      return;
     }

   if(now<g_session_open)
     {
      g_status="Waiting for session open";
      UpdateChartStatus(now);
      return;
     }
   if(now>=g_force_exit)
     {
      g_status="Session finished";
      UpdateChartStatus(now);
      return;
     }

   if(g_traded_today || HasEnteredToday())
     {
      g_traded_today=true;
      g_status="Daily trade already completed";
      UpdateChartStatus(now);
      return;
     }

   if(HasAnyPositionOnSymbol())
     {
      g_status="Blocked: another position exists on the symbol";
      UpdateChartStatus(now);
      return;
     }

   if(now<g_range_end)
     {
      g_status="Building opening range";
      UpdateChartStatus(now);
      return;
     }

   if(!PrepareSetup())
     {
      UpdateChartStatus(now);
      return;
     }

   if(!UpdateSetupMetrics(now))
     {
      UpdateChartStatus(now);
      return;
     }

   TryEntry(now);
   UpdateChartStatus(now);
  }
//+------------------------------------------------------------------+

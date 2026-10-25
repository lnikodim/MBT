//+------------------------------------------------------------------+
//|              GDS Renko RSI MACD Demo EA                          |
//|       Educational Renko + RSI / MACD example for MT5               |
//+------------------------------------------------------------------+
#property copyright "Golden Delta"
#property link      "https://goldendeltaea.com/"
#property version   "0.11"
#property strict
#property description "Educational Renko + RSI / MACD Expert Advisor for MetaTrader 5."
#property description "Builds classic fixed-size Renko internally from BID ticks."
#property description "Four selectable modes: RSI re-entry / RSI 50 / MACD signal / MACD zero."
#property description "Initial educational candidate: defaults are not optimized or evidence of a trading edge."
#property description "TP/SL are virtual: the EA and terminal must remain running."
#property description "Requested volume is normalized to the symbol minimum, maximum and volume step."
#property description "No external indicators, DLLs, custom symbols or offline charts are required."

enum ENUM_GDS_MODE
  {
   RSI_REENTRY=0,  // RSI returns above lower / below upper threshold
   RSI_MIDLINE=1,  // RSI crosses 50
   MACD_SIGNAL=2,  // MACD crosses its SMA signal line
   MACD_ZERO=3     // MACD crosses zero
  };
enum ENUM_GDS_BRICK_UNIT
  {
   BRICK_POINTS=0, // BrickSize multiplied by symbol point
   BRICK_PRICE=1   // BrickSize in absolute price units
  };
input ENUM_GDS_MODE InpMode=RSI_MIDLINE; // One active strategy
input ENUM_GDS_BRICK_UNIT InpBrickUnit=BRICK_POINTS;
input double InpBrickSize=100.0;
input int InpRSIPeriod=14;               // Completed close changes
input double InpRSILower=30.0;          // Upper is 100-Lower; re-entry only
input int InpMACDFast=12;
input int InpMACDSlow=26;
input int InpMACDSignal=9;              // SMA signal period
input double InpTakeProfitBricks=8.0;   // Virtual TP; terminal must run
input double InpStopLossBricks=6.0;     // Virtual SL; terminal must run
input int InpMaxHoldMinutes=1440;       // 0 disables time exit
input int InpCooldownBricks=3;
input double InpMaxSpreadFraction=0.35; // Entry only: spread / brick
input double InpLots=0.01;              // Clamped to broker minimum; rounded down otherwise
input ulong InpMagic=26101944;          // Unique per instance; do not optimize

struct SRenkoBrick
  {
   double open;
   double close;
   int    direction; // +1 up, -1 down
   int    run;       // consecutive bricks in current direction
  };

//+------------------------------------------------------------------+
//| Classic fixed-size Renko builder, two-brick reversal             |
//+------------------------------------------------------------------+
const int MAX_BRICKS_PER_TICK=4096;
class CRenkoBuilder
  {
private:
   double m_tick_size;
   long m_size,m_close;
   int m_dir,m_run;
   bool m_anchor;
public:
   void Init(const double tick_size,const long size)
     {
      m_tick_size=tick_size; m_size=size; m_close=0;
      m_dir=0; m_run=0; m_anchor=false;
     }
   int PushPrice(const double price,SRenkoBrick &out[])
     {
      ArrayResize(out,0);
      const long p=(long)MathRound(price/m_tick_size);
      if(!m_anchor) { m_close=p; m_anchor=true; return 0; }
      const long delta=p-m_close;
      int dir=m_dir;
      long count=0;
      bool reversal=false;
      if(m_dir==0)
        {
         if(delta>=m_size) { dir=1; count=delta/m_size; }
         else if(delta<=-m_size) { dir=-1; count=(-delta)/m_size; }
        }
      else if(m_dir>0)
        {
         if(delta>=m_size) count=delta/m_size;
         else if(delta<=-2*m_size)
           { dir=-1; reversal=true; count=(-delta)/m_size-1; }
        }
      else
        {
         if(delta<=-m_size) count=(-delta)/m_size;
         else if(delta>=2*m_size)
           { dir=1; reversal=true; count=delta/m_size-1; }
        }
      if(count>MAX_BRICKS_PER_TICK) return -1; // Atomic failure: do not truncate a tick.
      if(count==0) return 0;
      if(ArrayResize(out,(int)count)!=(int)count) return -1;
      for(int i=0;i<(int)count;i++)
        {
         const long open=m_close+((reversal && i==0) ? dir*m_size : 0);
         m_close=open+dir*m_size;
         if(dir==m_dir) m_run++;
         else { m_dir=dir; m_run=1; }
         out[i].open=open*m_tick_size;
         out[i].close=m_close*m_tick_size;
         out[i].direction=dir; out[i].run=m_run;
        }
      return (int)count;
     }
  };

// Wilder RSI: arithmetic seed of N close changes, then Wilder smoothing.
// MACD: EMA(fast)-EMA(slow), each seeded with its own SMA.
// Signal line: SMA of the latest S valid MACD values (MT5 convention).
// First valid reading seeds crossing state; it cannot produce an entry.
class CRenkoOscillator
  {
private:
   int m_rsi_period,m_fast_period,m_slow_period,m_signal_period,m_mode;
   int m_count,m_head,m_macd_count;
   double m_level,m_previous_close,m_gain,m_loss,m_rsi;
   double m_fast,m_slow,m_fast_sum,m_slow_sum,m_macd,m_signal;
   double m_previous_value,m_previous_signal,m_buffer[];
   bool m_ready;
public:
   bool Init(const int mode,const int rsi_period,const double level,
             const int fast_period,const int slow_period,const int signal_period)
     {
      m_mode=mode; m_rsi_period=rsi_period; m_level=level;
      m_fast_period=fast_period; m_slow_period=slow_period; m_signal_period=signal_period;
      m_count=0; m_head=0; m_macd_count=0; m_ready=false;
      m_previous_close=0; m_gain=0; m_loss=0; m_rsi=50;
      m_fast=0; m_slow=0; m_fast_sum=0; m_slow_sum=0;
      m_macd=0; m_signal=0; m_previous_value=0; m_previous_signal=0;
      return ArrayResize(m_buffer,signal_period)==signal_period;
     }
   int Push(const SRenkoBrick &brick)
     {
      const double close=brick.close;
      m_count++;
      bool valid=false;
      if(m_mode<=1)
        {
         if(m_count>1)
           {
            const double delta=close-m_previous_close;
            const double gain=MathMax(delta,0.0),loss=MathMax(-delta,0.0);
            if(m_count<=m_rsi_period+1)
              {
               m_gain+=gain; m_loss+=loss;
               if(m_count==m_rsi_period+1)
                 { m_gain/=m_rsi_period; m_loss/=m_rsi_period; }
              }
            else
              {
               m_gain=(m_gain*(m_rsi_period-1)+gain)/m_rsi_period;
               m_loss=(m_loss*(m_rsi_period-1)+loss)/m_rsi_period;
              }
            if(m_count>=m_rsi_period+1)
              {
               m_rsi=(m_loss==0.0 ? (m_gain==0.0 ? 50.0 : 100.0) :
                      100.0-100.0/(1.0+m_gain/m_loss));
               valid=true;
              }
           }
        }
      else
        {
         if(m_count<=m_fast_period)
           { m_fast_sum+=close; m_fast=m_fast_sum/m_count; }
         else m_fast+=(2.0/(m_fast_period+1))*(close-m_fast);
         if(m_count<=m_slow_period)
           { m_slow_sum+=close; m_slow=m_slow_sum/m_count; }
         else m_slow+=(2.0/(m_slow_period+1))*(close-m_slow);
         if(m_count>=m_slow_period)
           {
            m_macd=m_fast-m_slow;
            m_buffer[m_head]=m_macd;
            m_head=(m_head+1)%m_signal_period;
            if(m_macd_count<m_signal_period) m_macd_count++;
            // Small bounded sum avoids accumulated rolling-sum drift.
            m_signal=0;
            for(int i=0;i<m_macd_count;i++) m_signal+=m_buffer[i];
            m_signal/=m_macd_count;
            valid=(m_mode==3 || m_macd_count==m_signal_period);
           }
        }
      m_previous_close=close;
      if(!valid) return 0;
      const double value=(m_mode<=1 ? m_rsi : m_macd);
      int result=0;
      if(m_ready)
        {
         if(m_mode==0)
           {
            if(m_previous_value<=m_level && value>m_level) result=1;
            else if(m_previous_value>=100.0-m_level && value<100.0-m_level) result=-1;
           }
         else
           {
            double previous=m_previous_value,current=value;
            if(m_mode==1) { previous-=50; current-=50; }
            if(m_mode==2) { previous-=m_previous_signal; current-=m_signal; }
            if(previous<=0 && current>0) result=1;
            else if(previous>=0 && current<0) result=-1;
           }
        }
      m_previous_value=value; m_previous_signal=m_signal; m_ready=true;
      return result;
     }
   double RSI(void) { return m_rsi; }
   double MACD(void) { return m_macd; }
   double Signal(void) { return m_signal; }
   bool Ready(void) { return m_ready; }
  };

CRenkoBuilder g_renko;
CRenkoOscillator g_oscillator;
bool          g_builder_failed=false;
double        g_effective_brick_size=0.0;
int           g_cooldown_left=0;
bool          g_closed_this_tick=false;
bool          g_exit_pending=false;
string        g_exit_reason="";
bool          g_request_this_tick=false;
datetime      g_retry_after=0;
datetime      g_request_session_end=0;
int           g_request_failures=0;
ulong         g_wait_order=0;
bool          g_execution_uncertain=false;
bool          g_uncertain_exit=false;
const int     GDS_MAX_REQUEST_FAILURES=3;

//+------------------------------------------------------------------+
double NormalizeVolume(const double requested)
  {
   double vmin=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double vmax=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);

   if(!MathIsValidNumber(requested) || requested<=0.0) return 0.0;
   if(!MathIsValidNumber(vmin) || !MathIsValidNumber(vmax) ||
      !MathIsValidNumber(step) || vmin<=0.0 || vmax<vmin) return 0.0;
   if(step<=0.0) step=vmin;
   if(step<=0.0) return 0.0;

   // In portable CodeBase examples the same default input is validated on
   // symbols with different contract specifications. Normalize the requested
   // volume to the broker's legal range instead of rejecting OnInit merely
   // because the symbol minimum is larger than the requested demonstration lot.
   double volume=MathFloor(MathMin(requested,vmax)/step+1.0e-9)*step;
   volume=MathMax(vmin,MathMin(vmax,volume));
   volume=NormalizeDouble(volume,8);
   if(volume<vmin-1.0e-10 || volume>vmax+1.0e-10) return 0.0;
   return volume;
  }

//+------------------------------------------------------------------+
bool GetFillingMode(ENUM_ORDER_TYPE_FILLING &filling)
  {
   const long flags=SymbolInfoInteger(_Symbol,SYMBOL_FILLING_MODE);
   const ENUM_SYMBOL_TRADE_EXECUTION execution=(ENUM_SYMBOL_TRADE_EXECUTION)
      SymbolInfoInteger(_Symbol,SYMBOL_TRADE_EXEMODE);
   filling=ORDER_FILLING_FOK;
   if(execution==SYMBOL_TRADE_EXECUTION_INSTANT ||
      execution==SYMBOL_TRADE_EXECUTION_REQUEST) return true;
   if((flags & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK) return true;
   if((flags & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC)
     {
      filling=ORDER_FILLING_IOC;
      return true;
     }
   if(execution==SYMBOL_TRADE_EXECUTION_MARKET) return false;
   filling=ORDER_FILLING_RETURN;
   return true;
  }

//+------------------------------------------------------------------+
bool FindOurPosition(ulong &ticket,long &type,double &volume,
                     double &open_price,datetime &open_time)
  {
   ticket=0;
   type=-1;
   volume=0.0;
   open_price=0.0;
   open_time=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      const ulong t=PositionGetTicket(i);
      if(t==0) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC)!=InpMagic) continue;

      ticket=t;
      type=PositionGetInteger(POSITION_TYPE);
      volume=PositionGetDouble(POSITION_VOLUME);
      open_price=PositionGetDouble(POSITION_PRICE_OPEN);
      open_time=(datetime)PositionGetInteger(POSITION_TIME);
      return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
bool AnyPositionOnSymbol(void)
  {
   for(int i=PositionsTotal()-1;i>=0;i--)
     {
      const ulong t=PositionGetTicket(i);
      if(t==0) continue;
      if(PositionGetString(POSITION_SYMBOL)==_Symbol)
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
bool SpreadIsAcceptable(const MqlTick &tick)
  {
   if(!ValidTick(tick)) return false;
   const double spread=tick.ask-tick.bid;
   return (spread<=g_effective_brick_size*InpMaxSpreadFraction);
  }

//+------------------------------------------------------------------+
// Only completed bricks update the oscillator history.
int ProcessCompletedBrick(const SRenkoBrick &brick)
  {
   return g_oscillator.Push(brick);
  }

//+------------------------------------------------------------------+
//| Convert datetime to seconds from midnight.                        |
//+------------------------------------------------------------------+
int SecondsOfDay(const datetime value)
  {
   MqlDateTime part={};
   if(!TimeToStruct(value,part))
      return -1;
   return part.hour*3600+part.min*60+part.sec;
  }

//+------------------------------------------------------------------+
//| Today's sessions plus the overnight tail of the previous day.    |
//| A missing schedule is NOT permission to trade. End is exclusive. |
//+------------------------------------------------------------------+
datetime TradingSessionEnd(const datetime now)
  {
   MqlDateTime current={};
   if(now<=0 || !TimeToStruct(now,current)) return 0;
   const int seconds=current.hour*3600+current.min*60+current.sec;
   const datetime midnight=now-seconds;
   for(int offset=0;offset<=1;offset++)
     {
      const ENUM_DAY_OF_WEEK day=(ENUM_DAY_OF_WEEK)
         ((current.day_of_week-offset+7)%7);
      for(uint session=0;session<24;session++)
        {
         datetime from=0,to=0;
         if(!SymbolInfoSessionTrade(_Symbol,day,session,from,to)) break;
         const int start_seconds=SecondsOfDay(from);
         const int end_seconds=SecondsOfDay(to);
         if(start_seconds<0 || end_seconds<0) continue;
         const datetime start=midnight-offset*86400+start_seconds;
         datetime end=midnight-offset*86400+end_seconds;
         // Equal endpoints in a returned session denote a full day.
         if(end<=start) end+=86400;
         if(now>=start && now<end) return end;
        }
     }
   return 0;
  }

//+------------------------------------------------------------------+
bool TradingSessionIsOpen(const datetime when=0)
  {
   return TradingSessionEnd(when>0 ? when : TimeCurrent())>0;
  }

//+------------------------------------------------------------------+
bool ValidTick(const MqlTick &tick)
  {
   return MathIsValidNumber(tick.bid) && MathIsValidNumber(tick.ask) &&
          tick.bid>0.0 && tick.ask>=tick.bid && tick.time>0;
  }

//+------------------------------------------------------------------+
bool HasActiveOrder(const bool only_ours)
  {
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      if(OrderGetTicket(i)==0) continue;
      if(OrderGetString(ORDER_SYMBOL)!=_Symbol) continue;
      if(!only_ours || (ulong)OrderGetInteger(ORDER_MAGIC)==InpMagic)
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
void MarkExitCompleted(void)
  {
   g_exit_pending=false;
   g_exit_reason="";
   g_cooldown_left=InpCooldownBricks;
   g_closed_this_tick=true;
  }

//+------------------------------------------------------------------+
//| An accepted order may still be working. Never submit it again.   |
//+------------------------------------------------------------------+
bool ResolveExecution(void)
  {
   if(g_wait_order!=0)
     {
      if(OrderSelect(g_wait_order)) return false;
      if(!HistoryOrderSelect(g_wait_order)) return false;
      const ENUM_ORDER_STATE state=(ENUM_ORDER_STATE)
         HistoryOrderGetInteger(g_wait_order,ORDER_STATE);
      if(state!=ORDER_STATE_FILLED && state!=ORDER_STATE_CANCELED &&
         state!=ORDER_STATE_REJECTED && state!=ORDER_STATE_EXPIRED)
         return false;
      g_wait_order=0;
      g_execution_uncertain=false;
     }
   if(g_execution_uncertain)
     {
      ulong ticket=0;
      long type=-1;
      double volume=0.0,price=0.0;
      datetime opened=0;
      const bool exists=FindOurPosition(ticket,type,volume,price,opened);
      if((g_uncertain_exit && !exists) || (!g_uncertain_exit && exists))
         g_execution_uncertain=false;
     }
   return !g_execution_uncertain;
  }

//+------------------------------------------------------------------+
bool RequestWindowIsOpen(void)
  {
   if(g_request_this_tick || !ResolveExecution()) return false;
   if(!TerminalInfoInteger(TERMINAL_CONNECTED) ||
      !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ||
      !MQLInfoInteger(MQL_TRADE_ALLOWED) ||
      !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) ||
      !AccountInfoInteger(ACCOUNT_TRADE_EXPERT)) return false;
   const datetime now=TimeCurrent();
   const datetime end=TradingSessionEnd(now);
   if(end<=0) return false;
   if(g_request_session_end!=end)
     {
      g_request_session_end=end;
      g_request_failures=0;
      g_retry_after=0;
     }
   return now>=g_retry_after;
  }

//+------------------------------------------------------------------+
void RegisterFailure(const uint retcode,const string details)
  {
   g_request_failures++;
   const datetime now=TimeCurrent();
   const datetime end=TradingSessionEnd(now);
   // Three failed checks/sends per session, or one MARKET_CLOSED.
   // An unexpected closure pauses requests until the scheduled interval ends.
   if(retcode==TRADE_RETCODE_MARKET_CLOSED ||
      g_request_failures>=GDS_MAX_REQUEST_FAILURES)
      g_retry_after=(end>now ? end : now+300);
   else
      g_retry_after=now+(g_request_failures==1 ? 5 : 30);
   Print("GDS Renko RSI MACD Demo: request deferred. Retcode ",retcode,
         ", ",details,", next attempt no earlier than ",
         TimeToString(g_retry_after,TIME_DATE|TIME_SECONDS));
  }

//+------------------------------------------------------------------+
bool SubmitDeal(MqlTradeRequest &request,const bool is_exit)
  {
   if(!RequestWindowIsOpen()) return false;
   g_request_this_tick=true;
   MqlTradeCheckResult check={};
   ResetLastError();
   if(!OrderCheck(request,check))
     {
      RegisterFailure(check.retcode,check.comment);
      return false;
     }
   // Recheck the current SERVER session immediately before OrderSend.
   if(!TradingSessionIsOpen(TimeCurrent())) return false;
   MqlTradeResult result={};
   ResetLastError();
   const bool sent=OrderSend(request,result);
   const int error=GetLastError();
   if(!sent || (result.retcode!=TRADE_RETCODE_DONE &&
                result.retcode!=TRADE_RETCODE_DONE_PARTIAL &&
                result.retcode!=TRADE_RETCODE_PLACED))
     {
      if(result.retcode==TRADE_RETCODE_TIMEOUT ||
         result.retcode==TRADE_RETCODE_CONNECTION || result.retcode==0)
        {
         // Unknown execution is reconciled, never blindly retried.
         g_execution_uncertain=true;
         g_uncertain_exit=is_exit;
         g_wait_order=result.order;
         Print("GDS Renko RSI MACD Demo: execution unconfirmed; requests paused. ",
               "Check account orders/positions if automatic reconciliation cannot finish.");
        }
      RegisterFailure(result.retcode,result.comment+" error="+IntegerToString(error));
      return false;
     }
   // The failure budget is reset only when the session interval changes.
   g_retry_after=0;
   g_wait_order=result.order;
   // Even DONE is not used as evidence that the position has disappeared.
   if(result.order==0)
     {
      g_execution_uncertain=true;
      g_uncertain_exit=is_exit;
      ResolveExecution();
     }
   return true;
  }

//+------------------------------------------------------------------+
bool TradeModeAllowsEntry(const int direction)
  {
   const ENUM_SYMBOL_TRADE_MODE mode=
      (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE);

   if(mode==SYMBOL_TRADE_MODE_DISABLED || mode==SYMBOL_TRADE_MODE_CLOSEONLY)
      return false;
   if(mode==SYMBOL_TRADE_MODE_LONGONLY && direction<0)
      return false;
   if(mode==SYMBOL_TRADE_MODE_SHORTONLY && direction>0)
      return false;
   return true;
  }

//+------------------------------------------------------------------+
bool TradeModeAllowsClose(void)
  {
   const ENUM_SYMBOL_TRADE_MODE mode=
      (ENUM_SYMBOL_TRADE_MODE)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_MODE);
   return (mode!=SYMBOL_TRADE_MODE_DISABLED);
  }

//+------------------------------------------------------------------+
void RequestExit(const string reason)
  {
   if(!g_exit_pending)
      g_exit_reason=reason;
   g_exit_pending=true;
  }

//+------------------------------------------------------------------+
bool SendMarket(const int direction)
  {
   if(direction!=1 && direction!=-1) return false;
   if(g_exit_pending || AnyPositionOnSymbol() || HasActiveOrder(false)) return false;
   if(!TradeModeAllowsEntry(direction)) return false;
   if((SymbolInfoInteger(_Symbol,SYMBOL_ORDER_MODE)&SYMBOL_ORDER_MARKET)==0)
      return false;
   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick) || !ValidTick(tick)) return false;
   if(!SpreadIsAcceptable(tick)) return false;
   MqlTradeRequest request={};
   if(!GetFillingMode(request.type_filling)) return false;
   request.volume=NormalizeVolume(InpLots);
   if(request.volume<=0.0) return false;
   request.action=TRADE_ACTION_DEAL;
   request.magic=InpMagic;
   request.symbol=_Symbol;
   request.deviation=50;
   request.comment="GDS Renko RSI MACD";
   request.type=(direction>0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
   request.price=(direction>0 ? tick.ask : tick.bid);
   return SubmitDeal(request,false);
  }

//+------------------------------------------------------------------+
bool CloseOurPosition(const string reason)
  {
   ulong ticket=0;
   long type=-1;
   double volume=0.0,open_price=0.0;
   datetime open_time=0;
   if(!FindOurPosition(ticket,type,volume,open_price,open_time)) return false;
   if(!TradeModeAllowsClose() || HasActiveOrder(true)) return false;
   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick) || !ValidTick(tick)) return false;
   MqlTradeRequest request={};
   if(!GetFillingMode(request.type_filling)) return false;
   request.action=TRADE_ACTION_DEAL;
   request.magic=InpMagic;
   request.position=ticket;
   request.symbol=_Symbol;
   request.volume=volume;
   request.deviation=50;
   request.comment="GDS RSI MACD exit";
   request.type=(type==POSITION_TYPE_BUY ? ORDER_TYPE_SELL : ORDER_TYPE_BUY);
   request.price=(type==POSITION_TYPE_BUY ? tick.bid : tick.ask);
   if(!SubmitDeal(request,true)) return false;
   g_closed_this_tick=true;
   // Partial fills retain the original exit reason and pending flag.
   if(!FindOurPosition(ticket,type,volume,open_price,open_time))
     {
      Print("GDS Renko RSI MACD Demo exit: ",reason);
      MarkExitCompleted();
     }
   return true;
  }


//+------------------------------------------------------------------+
//| Execute an already-due exit only when trading is possible.       |
//+------------------------------------------------------------------+
void TryPendingExit(void)
  {
   if(!g_exit_pending || !ResolveExecution())
      return;

   ulong ticket=0;
   long type=-1;
   double volume=0.0;
   double open_price=0.0;
   datetime open_time=0;

   if(!FindOurPosition(ticket,type,volume,open_price,open_time))
     {
      MarkExitCompleted();
      return;
     }

   CloseOurPosition(g_exit_reason);
  }

//+------------------------------------------------------------------+
void CheckPriceExit(const MqlTick &tick)
  {
   ulong ticket=0;
   long type=-1;
   double volume=0.0;
   double open_price=0.0;
   datetime open_time=0;
   if(!FindOurPosition(ticket,type,volume,open_price,open_time)) return;

   const int direction=(type==POSITION_TYPE_BUY ? +1 : -1);
   const double executable=(direction>0 ? tick.bid : tick.ask);
   if(executable<=0.0) return;

   const double move=direction*(executable-open_price);
   const double tp=InpTakeProfitBricks*g_effective_brick_size;
   const double sl=InpStopLossBricks*g_effective_brick_size;

   if(move>=tp)
     {
      RequestExit("TP");
      return;
     }

   if(move<=-sl)
     {
      RequestExit("SL");
      return;
     }

   if(InpMaxHoldMinutes>0 && open_time>0)
     {
      const long held_seconds=(long)(TimeCurrent()-open_time);
      if(held_seconds>=(long)InpMaxHoldMinutes*60)
         RequestExit("TIME");
     }
  }

//+------------------------------------------------------------------+
void UpdateRenkoAndTrade(const double price)
  {
   if(g_builder_failed) return;
   SRenkoBrick bricks[];
   const int n=g_renko.PushPrice(price,bricks);
   if(n<0)
     {
      g_builder_failed=true;
      Print("GDS RSI MACD: excessive gap/memory failure. New entries paused; existing exits remain active. Increase brick size and restart.");
      return;
     }
   if(n==0) return;

   // Keep only the signal of the newest completed brick on this tick.
   // This prevents a synthetic same-tick chain from producing stale entries.
   int final_signal=0;
   for(int i=0;i<n;i++)
      final_signal=ProcessCompletedBrick(bricks[i]);

   if(g_cooldown_left>0 && !g_closed_this_tick)
     {
      g_cooldown_left-=n;
      if(g_cooldown_left<0) g_cooldown_left=0;
     }

   ulong ticket=0;
   long type=-1;
   double volume=0.0;
   double open_price=0.0;
   datetime open_time=0;
   const bool have_position=FindOurPosition(ticket,type,volume,open_price,open_time);

   if(have_position) return; // Exits are TP, SL or time only.

   if(g_closed_this_tick) return;
   if(AnyPositionOnSymbol()) return;
   if(g_cooldown_left>0) return;
   if(final_signal==0) return;

   SendMarket(final_signal);
  }

//+------------------------------------------------------------------+
// Validate only values that participate in the selected strategy.
// Unused oscillator parameters must not invalidate an otherwise valid pass.
bool ValidateInputs(string &reason)
  {
   reason="";
   if(InpMode<RSI_REENTRY || InpMode>MACD_ZERO)
      reason="InpMode must be 0..3";
   else if(InpBrickUnit!=BRICK_POINTS && InpBrickUnit!=BRICK_PRICE)
      reason="InpBrickUnit must be 0 (points) or 1 (price)";
   else if(!MathIsValidNumber(InpBrickSize) || InpBrickSize<=0)
      reason="InpBrickSize must be positive";
   else if(!MathIsValidNumber(InpTakeProfitBricks) || InpTakeProfitBricks<=0)
      reason="InpTakeProfitBricks must be positive";
   else if(!MathIsValidNumber(InpStopLossBricks) || InpStopLossBricks<=0)
      reason="InpStopLossBricks must be positive";
   else if(!MathIsValidNumber(InpMaxSpreadFraction) || InpMaxSpreadFraction<=0)
      reason="InpMaxSpreadFraction must be positive";
   else if(!MathIsValidNumber(InpLots) || InpLots<=0)
      reason="InpLots must be positive";
   else if(InpMagic==0)
      reason="InpMagic must be nonzero";
   else if(InpMaxHoldMinutes<0)
      reason="InpMaxHoldMinutes must be nonnegative";
   else if(InpCooldownBricks<0)
      reason="InpCooldownBricks must be nonnegative";
   if(reason!="") return false;

   if(InpMode==RSI_REENTRY || InpMode==RSI_MIDLINE)
     {
      if(InpRSIPeriod<2 || InpRSIPeriod>200)
         reason="InpRSIPeriod must be 2..200 for RSI modes";
      else if(InpMode==RSI_REENTRY &&
              (!MathIsValidNumber(InpRSILower) || InpRSILower<=0 || InpRSILower>=50))
         reason="InpRSILower must be strictly between 0 and 50 for RSI_REENTRY";
     }
   else
     {
      if(InpMACDFast<2 || InpMACDFast>=300)
         reason="InpMACDFast must be 2..299 for MACD modes";
      else if(InpMACDSlow<=InpMACDFast || InpMACDSlow>300)
         reason="InpMACDSlow must exceed InpMACDFast and be <=300";
      else if(InpMode==MACD_SIGNAL && (InpMACDSignal<2 || InpMACDSignal>100))
         reason="InpMACDSignal must be 2..100 for MACD_SIGNAL";
     }
   return reason=="";
  }

void PrintInputValues(void)
  {
   Print("Mode=",(int)InpMode," Unit=",(int)InpBrickUnit," Brick=",InpBrickSize,
         " RSI=",InpRSIPeriod," Lower=",InpRSILower,
         " Fast=",InpMACDFast," Slow=",InpMACDSlow," Signal=",InpMACDSignal,
         " TP=",InpTakeProfitBricks," SL=",InpStopLossBricks,
         " Hold=",InpMaxHoldMinutes," Cooldown=",InpCooldownBricks,
         " Spread=",InpMaxSpreadFraction," Lots=",InpLots," Magic=",InpMagic);
  }

// Allocate only bounded working parameters. Inputs of inactive modes are ignored.
bool InitSelectedOscillator(void)
  {
   const bool rsi=(InpMode==RSI_REENTRY || InpMode==RSI_MIDLINE);
   const int rsi_period=(rsi ? InpRSIPeriod : 14);
   const double lower=(InpMode==RSI_REENTRY ? InpRSILower : 30.0);
   const int fast=(rsi ? 12 : InpMACDFast);
   const int slow=(rsi ? 26 : InpMACDSlow);
   const int signal=(InpMode==MACD_SIGNAL ? InpMACDSignal : 2);
   return g_oscillator.Init((int)InpMode,rsi_period,lower,fast,slow,signal);
  }

int OnInit(void)
  {
   string input_error="";
   if(!ValidateInputs(input_error))
     {
      Print("GDS Renko RSI MACD: invalid input: ",input_error,
            ". Load the v0.11 preset; optimize only rows marked Y.");
      PrintInputValues();
      return INIT_PARAMETERS_INCORRECT;
     }

   g_request_this_tick=false;
   g_retry_after=0;
   g_request_session_end=0;
   g_request_failures=0;
   g_wait_order=0;
   g_execution_uncertain=false;
   g_uncertain_exit=false;
   const double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(!MathIsValidNumber(tick_size) || tick_size<=0)
     { Print("GDS RSI MACD: symbol tick size unavailable."); return INIT_FAILED; }
   const double requested_brick=InpBrickSize*(InpBrickUnit==BRICK_POINTS ? _Point : 1.0);
   const double units_raw=requested_brick/tick_size;
   if(!MathIsValidNumber(units_raw) || units_raw<0.5 || units_raw>1e9)
     { Print("GDS RSI MACD: brick size cannot be represented for this symbol."); return INIT_FAILED; }
   const long units=(long)MathMax(1.0,MathRound(units_raw));
   g_effective_brick_size=(double)units*tick_size;

   const double effective_volume=NormalizeVolume(InpLots);
   if(effective_volume<=0.0)
     { Print("GDS RSI MACD: symbol volume settings unavailable or invalid."); return INIT_FAILED; }
   if(effective_volume>InpLots+1e-10)
      Print("Requested lot is below symbol minimum. Effective lot: ",DoubleToString(effective_volume,8));
   Print("Virtual SL/TP require the EA and terminal to remain running. Use an isolated demo symbol for testing.");
   g_renko.Init(tick_size,units);
   if(!InitSelectedOscillator()) return INIT_FAILED;
   g_builder_failed=false;
   g_cooldown_left=0;
   g_closed_this_tick=false;
   g_exit_pending=false;
   g_exit_reason="";

   Print("GDS Renko RSI MACD Demo v0.11 started. RequestedBrick=",
         DoubleToString(InpBrickSize,_Digits),
         ", EffectiveBrick=",DoubleToString(g_effective_brick_size,_Digits),
         ", Mode=",EnumToString(InpMode),
         ", BrickUnit=",EnumToString(InpBrickUnit),
         ", TP=",DoubleToString(InpTakeProfitBricks,2),
         ", SL=",DoubleToString(InpStopLossBricks,2),
         ", HoldMin=",InpMaxHoldMinutes,
         ", RequestedLots=",DoubleToString(InpLots,2),
         ", EffectiveLots=",DoubleToString(effective_volume,2));
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
void OnTick(void)
  {
   g_closed_this_tick=false;
   g_request_this_tick=false;
   ResolveExecution();

   MqlTick tick={};
   if(!SymbolInfoTick(_Symbol,tick) || !ValidTick(tick)) return;

   // A due exit remains pending across a closed trading session and is
   // executed when the session and request guards allow it.
   TryPendingExit();

   // Price-based exits use executable BID/ASK on every tester tick.
   CheckPriceExit(tick);
   TryPendingExit();

   // Renko and oscillator state are updated from completed BID bricks.
   UpdateRenkoAndTrade(tick.bid);
  }
//+------------------------------------------------------------------+

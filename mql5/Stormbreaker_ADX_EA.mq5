#property strict
#property version "1.10"
#property description "Stormbreaker ADX"

#include <Trade\Trade.mqh>

CTrade STTrade;
const double ST_FIXED_RISK_PERCENT = 0.5;
int STATRHandle=INVALID_HANDLE;
int STADXHandle=INVALID_HANDLE;

bool STNewBar(const ENUM_TIMEFRAMES timeframe, datetime &last_bar)
{
   datetime current=iTime(_Symbol,timeframe,0);
   if(current==0 || current==last_bar) return false;
   last_bar=current;
   return true;
}

double STNormalizePrice(const double price)
{
   double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double aligned=(tick_size>0.0 ? MathRound(price/tick_size)*tick_size : price);
   return NormalizeDouble(aligned,(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS));
}

double STAlignPrice(const double price,const bool round_up)
{
   double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   if(tick_size<=0.0) return STNormalizePrice(price);
   double aligned=(round_up ? MathCeil(price/tick_size) : MathFloor(price/tick_size))*tick_size;
   return NormalizeDouble(aligned,(int)SymbolInfoInteger(_Symbol,SYMBOL_DIGITS));
}

double STFloorVolume(double volume)
{
   double minimum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maximum=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   if(step<=0.0 || volume<minimum) return 0.0;
   volume=MathMin(volume,maximum);
   volume=MathFloor((volume+1e-12)/step)*step;
   if(volume<minimum) return 0.0;
   int digits=0;
   double probe=step;
   while(digits<8 && MathAbs(probe-MathRound(probe))>1e-10)
   {
      probe*=10.0;
      digits++;
   }
   return NormalizeDouble(volume,digits);
}

ulong STPositionTicket(const long magic)
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0) continue;
      if(PositionGetString(POSITION_SYMBOL)==_Symbol &&
         PositionGetInteger(POSITION_MAGIC)==magic) return ticket;
   }
   return 0;
}

int STPositionDirection(const long magic)
{
   ulong ticket=STPositionTicket(magic);
   if(ticket==0 || !PositionSelectByTicket(ticket)) return 0;
   return PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY ? 1 : -1;
}

bool STClosePosition(const long magic)
{
   ulong ticket=STPositionTicket(magic);
   if(ticket==0) return true;
   STTrade.SetExpertMagicNumber(magic);
   STTrade.SetTypeFillingBySymbol(_Symbol);
   if(!STTrade.PositionClose(ticket))
      Print("Close failed: ",STTrade.ResultRetcode()," ",STTrade.ResultRetcodeDescription());
   return STTrade.ResultRetcode()==TRADE_RETCODE_DONE ||
          STTrade.ResultRetcode()==TRADE_RETCODE_DONE_PARTIAL ||
          STTrade.ResultRetcode()==TRADE_RETCODE_PLACED;
}

double STRiskVolume(const bool is_long,const double entry,const double stop,const double max_volume)
{
   if(entry<=0.0 || stop<=0.0 || MathAbs(entry-stop)<_Point) return 0.0;
   double one_lot_profit=0.0;
   ENUM_ORDER_TYPE type=is_long ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!OrderCalcProfit(type,_Symbol,1.0,entry,stop,one_lot_profit)) return 0.0;
   double one_lot_loss=MathAbs(one_lot_profit);
   if(one_lot_loss<=0.0) return 0.0;

   double risk_cash=AccountInfoDouble(ACCOUNT_EQUITY)*ST_FIXED_RISK_PERCENT/100.0;
   double volume=STFloorVolume(MathMin(risk_cash/one_lot_loss,max_volume));
   if(volume<=0.0) return 0.0;

   double margin=0.0;
   if(OrderCalcMargin(type,_Symbol,volume,entry,margin))
   {
      double free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(margin>free_margin*0.95)
         volume=STFloorVolume(volume*(free_margin*0.95/margin));
   }
   return volume;
}

bool STOpenPosition(const bool is_long,double stop,double take_profit,const long magic,
                    const string comment,const double max_volume,const int deviation_points)
{
   int current=STPositionDirection(magic);
   int wanted=is_long ? 1 : -1;
   if(current==wanted) return true;
   if(current!=0 && !STClosePosition(magic)) return false;

   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick)) return false;
   double entry=is_long ? tick.ask : tick.bid;
   double min_distance=(double)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL)*_Point;
   min_distance=MathMax(min_distance,_Point);
   if(is_long)
   {
      if(stop>=entry-min_distance) stop=entry-min_distance;
      if(take_profit>0.0 && take_profit<=entry+min_distance) take_profit=entry+min_distance;
   }
   else
   {
      if(stop<=entry+min_distance) stop=entry+min_distance;
      if(take_profit>0.0 && take_profit>=entry-min_distance) take_profit=entry-min_distance;
   }
   stop=STAlignPrice(stop,!is_long);
   if(take_profit>0.0) take_profit=STAlignPrice(take_profit,is_long);

   double volume=STRiskVolume(is_long,entry,stop,max_volume);
   if(volume<=0.0)
   {
      Print("Trade skipped: broker minimum volume would exceed 0.5% risk, or margin is insufficient.");
      return false;
   }

   STTrade.SetExpertMagicNumber(magic);
   STTrade.SetDeviationInPoints(deviation_points);
   STTrade.SetTypeFillingBySymbol(_Symbol);
   bool sent=is_long ? STTrade.Buy(volume,_Symbol,0.0,stop,take_profit,comment)
                     : STTrade.Sell(volume,_Symbol,0.0,stop,take_profit,comment);
   uint retcode=STTrade.ResultRetcode();
   bool accepted=sent && (retcode==TRADE_RETCODE_DONE || retcode==TRADE_RETCODE_DONE_PARTIAL ||
                          retcode==TRADE_RETCODE_PLACED);
   if(!accepted)
      Print("Entry failed: ",STTrade.ResultRetcode()," ",STTrade.ResultRetcodeDescription());
   return accepted;
}

bool STGetBar(const ENUM_TIMEFRAMES timeframe,const int shift,MqlRates &bar)
{
   MqlRates data[];
   ArraySetAsSeries(data,true);
   if(CopyRates(_Symbol,timeframe,shift,1,data)!=1) return false;
   bar=data[0];
   return true;
}

bool STValue(const ENUM_TIMEFRAMES timeframe,const double factor,const int atr_period,
             const int shift,double &value,int &direction)
{
   int requested=MathMax(350,atr_period*20+shift+20);
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   int count=CopyRates(_Symbol,timeframe,0,requested,rates);
   if(count<=atr_period+shift+5) return false;

   double previous_atr=0.0,previous_upper=0.0,previous_lower=0.0,previous_line=0.0;
   for(int i=count-1;i>=shift;i--)
   {
      double previous_close=(i==count-1 ? rates[i].close : rates[i+1].close);
      double tr=MathMax(rates[i].high-rates[i].low,
                MathMax(MathAbs(rates[i].high-previous_close),MathAbs(rates[i].low-previous_close)));
      double atr=(i==count-1 ? tr : (previous_atr*(atr_period-1)+tr)/atr_period);
      double midpoint=(rates[i].high+rates[i].low)/2.0;
      double basic_upper=midpoint+factor*atr;
      double basic_lower=midpoint-factor*atr;
      double upper,lower,line;
      if(i==count-1)
      {
         upper=basic_upper;
         lower=basic_lower;
         line=rates[i].close<=upper ? upper : lower;
      }
      else
      {
         upper=(basic_upper<previous_upper || rates[i+1].close>previous_upper) ? basic_upper : previous_upper;
         lower=(basic_lower>previous_lower || rates[i+1].close<previous_lower) ? basic_lower : previous_lower;
         bool previous_was_upper=MathAbs(previous_line-previous_upper)<=_Point*0.5;
         if(previous_was_upper)
            line=rates[i].close<=upper ? upper : lower;
         else
            line=rates[i].close>=lower ? lower : upper;
      }
      previous_atr=atr;
      previous_upper=upper;
      previous_lower=lower;
      previous_line=line;
   }
   value=previous_line;
   direction=rates[shift].close>=previous_line ? -1 : 1;
   return true;
}

double STBufferValue(const int handle,const int buffer,const int shift)
{
   if(handle==INVALID_HANDLE) return EMPTY_VALUE;
   double values[];
   ArraySetAsSeries(values,true);
   double result=EMPTY_VALUE;
   if(CopyBuffer(handle,buffer,shift,1,values)==1) result=values[0];
   IndicatorRelease(handle);
   return result;
}

double STATR(const ENUM_TIMEFRAMES timeframe,const int period,const int shift)
{
   if(STATRHandle==INVALID_HANDLE) STATRHandle=iATR(_Symbol,timeframe,period);
   if(STATRHandle==INVALID_HANDLE) return EMPTY_VALUE;
   double values[];
   if(CopyBuffer(STATRHandle,0,shift,1,values)!=1) return EMPTY_VALUE;
   return values[0];
}

double STMA(const ENUM_TIMEFRAMES timeframe,const int period,const int shift,
            const ENUM_MA_METHOD method=MODE_EMA)
{
   return STBufferValue(iMA(_Symbol,timeframe,period,0,method,PRICE_CLOSE),0,shift);
}

double STRSI(const ENUM_TIMEFRAMES timeframe,const int period,const int shift)
{
   return STBufferValue(iRSI(_Symbol,timeframe,period,PRICE_CLOSE),0,shift);
}

bool STADX(const ENUM_TIMEFRAMES timeframe,const int period,const int shift,
           double &adx,double &plus_di,double &minus_di)
{
   if(STADXHandle==INVALID_HANDLE) STADXHandle=iADX(_Symbol,timeframe,period);
   if(STADXHandle==INVALID_HANDLE) return false;
   double a[],p[],m[];
   ArraySetAsSeries(a,true); ArraySetAsSeries(p,true); ArraySetAsSeries(m,true);
   bool ok=CopyBuffer(STADXHandle,0,shift,1,a)==1 && CopyBuffer(STADXHandle,1,shift,1,p)==1 &&
           CopyBuffer(STADXHandle,2,shift,1,m)==1;
   if(!ok) return false;
   adx=a[0]; plus_di=p[0]; minus_di=m[0];
   return true;
}

bool STBands(const ENUM_TIMEFRAMES timeframe,const int period,const double deviations,
             const int shift,double &middle,double &upper,double &lower)
{
   int handle=iBands(_Symbol,timeframe,period,0,deviations,PRICE_CLOSE);
   if(handle==INVALID_HANDLE) return false;
   double b0[],b1[],b2[];
   ArraySetAsSeries(b0,true); ArraySetAsSeries(b1,true); ArraySetAsSeries(b2,true);
   bool ok=CopyBuffer(handle,0,shift,1,b0)==1 && CopyBuffer(handle,1,shift,1,b1)==1 &&
           CopyBuffer(handle,2,shift,1,b2)==1;
   IndicatorRelease(handle);
   if(!ok) return false;
   middle=b0[0]; upper=b1[0]; lower=b2[0];
   return true;
}

bool STExtreme(const ENUM_TIMEFRAMES timeframe,const int start_shift,const int count,
               double &highest,double &lowest)
{
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   if(CopyRates(_Symbol,timeframe,start_shift,count,rates)!=count) return false;
   highest=rates[0].high; lowest=rates[0].low;
   for(int i=1;i<count;i++)
   {
      highest=MathMax(highest,rates[i].high);
      lowest=MathMin(lowest,rates[i].low);
   }
   return true;
}

double STAverageVolume(const ENUM_TIMEFRAMES timeframe,const int start_shift,const int count)
{
   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   if(CopyRates(_Symbol,timeframe,start_shift,count,rates)!=count) return 0.0;
   double total=0.0;
   for(int i=0;i<count;i++) total+=(double)rates[i].tick_volume;
   return total/count;
}

bool STSessionVWAP(const ENUM_TIMEFRAMES timeframe,const datetime session_start,
                   const datetime session_end,double &vwap)
{
   MqlRates rates[];
   int copied=CopyRates(_Symbol,timeframe,session_start,session_end,rates);
   if(copied<=0) return false;
   double pv=0.0,volume=0.0;
   for(int i=0;i<copied;i++)
   {
      double v=(double)rates[i].tick_volume;
      pv+=((rates[i].high+rates[i].low+rates[i].close)/3.0)*v;
      volume+=v;
   }
   if(volume<=0.0) return false;
   vwap=pv/volume;
   return true;
}

datetime STDayStart(const datetime time_value)
{
   MqlDateTime parts;
   TimeToStruct(time_value,parts);
   parts.hour=0; parts.min=0; parts.sec=0;
   return StructToTime(parts);
}


// ======================= End standalone support ====================

input ENUM_TIMEFRAMES SignalTimeframe=PERIOD_H4;
input double SupertrendFactor=3.0;
input int SupertrendATRPeriod=10;
input int ADXPeriod=14;
input double EntryADX=23.0;
input double ExitADX=18.0;
input double StopATRMultiple=2.0;
input double MaxVolume=100.0;
input int DeviationPoints=20;
input bool EnableBuy=true;
input bool EnableSell=true;
input long MagicNumber=51003;
datetime LastBar=0;

int OnInit(){ SymbolSelect(_Symbol,true); return INIT_SUCCEEDED; }

void OnDeinit(const int reason)
{
   if(STATRHandle!=INVALID_HANDLE) IndicatorRelease(STATRHandle);
   if(STADXHandle!=INVALID_HANDLE) IndicatorRelease(STADXHandle);
}

void OnTick()
{
   if(!STNewBar(SignalTimeframe,LastBar)) return;
   double st; int direction;
   double adx,plus_di,minus_di;
   MqlRates bar;
   double atr=STATR(SignalTimeframe,SupertrendATRPeriod,1);
   if(!STValue(SignalTimeframe,SupertrendFactor,SupertrendATRPeriod,1,st,direction) ||
      !STADX(SignalTimeframe,ADXPeriod,1,adx,plus_di,minus_di) ||
      !STGetBar(SignalTimeframe,1,bar) || atr==EMPTY_VALUE) return;

   bool long_signal=EnableBuy && direction<0 && adx>=EntryADX && plus_di>minus_di;
   bool short_signal=EnableSell && direction>0 && adx>=EntryADX && minus_di>plus_di;
   int position=STPositionDirection(MagicNumber);
   if(long_signal)
      STOpenPosition(true,bar.close-StopATRMultiple*atr,0.0,MagicNumber,"ST ADX long",MaxVolume,DeviationPoints);
   else if(short_signal)
      STOpenPosition(false,bar.close+StopATRMultiple*atr,0.0,MagicNumber,"ST ADX short",MaxVolume,DeviationPoints);
   else if(position!=0 && (adx<ExitADX || (position>0 && direction>0) || (position<0 && direction<0)))
      STClosePosition(MagicNumber);
}

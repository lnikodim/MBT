//+------------------------------------------------------------------+
//|                                          ChaosLyapunovFilter.mq5 |
//|                                                Copyright jojoalb |
//+------------------------------------------------------------------+
#property copyright   "jojoalb" 
#property link        ""
#property version     "1.01"
#property description "Chaos Theory and Lyapunov Exponent Filter EA (Quant Safe)"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//--- input parameters
input group "Chaos Theory: Lyapunov Filter"
input int    InpLyaLookback    = 100;     // Phase Space Lookback
input int    InpLyaEmbedding   = 3;       // Embedding Dimension (m)
input int    InpLyaKSteps      = 5;       // Projection Steps (k)
input double InpLyaThreshold   = 0.00;    // Chaos Threshold

input group "Directional Trigger (Momentum)"
input int    InpFastEma        = 9;       // Fast EMA Period
input int    InpSlowEma        = 21;      // Slow EMA Period

input group "Risk Management"
input double InpRiskPercent    = 0.15;    // Risk Per Trade (%)
input int    InpAtrPeriod      = 14;      // ATR Period for Stop Loss
input double InpSlAtrMult      = 1.5;     // Stop Loss Multiplier
input double InpTpAtrMult      = 2.5;     // Take Profit Multiplier
input ulong  InpMagicNumber    = 202610;  // Expert Magic Number

//+------------------------------------------------------------------+
//| Chaos Lyapunov expert class                                      |
//+------------------------------------------------------------------+
class CChaosLyapunovExpert
  {
private:
   CTrade            m_trade;
   CPositionInfo     m_position;
   
   int               m_atr_handle;
   int               m_ema_fast;
   int               m_ema_slow;
   
   double            m_atr_buf[];
   double            m_fast_buf[];
   double            m_slow_buf[];
   
   datetime          m_last_bar_time;

   double            CalculateLyapunov(void);
   double            CalcLotSafe(double sl_dist, ENUM_ORDER_TYPE order_type, double price);
   bool              HasActivePosition(void);

public:
                     CChaosLyapunovExpert(void);
                    ~CChaosLyapunovExpert(void);
   bool              Init(void);
   void              Deinit(void);
   void              OnTick(void);
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
CChaosLyapunovExpert::CChaosLyapunovExpert(void) : m_atr_handle(INVALID_HANDLE),
                                                   m_ema_fast(INVALID_HANDLE),
                                                   m_ema_slow(INVALID_HANDLE),
                                                   m_last_bar_time(0)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
CChaosLyapunovExpert::~CChaosLyapunovExpert(void)
  {
  }

//+------------------------------------------------------------------+
//| Initialization and checking for input parameters                 |
//+------------------------------------------------------------------+
bool CChaosLyapunovExpert::Init(void)
  {
   m_trade.SetExpertMagicNumber(InpMagicNumber);
   
   m_atr_handle=iATR(_Symbol,PERIOD_CURRENT,InpAtrPeriod);
   m_ema_fast=iMA(_Symbol,PERIOD_CURRENT,InpFastEma,0,MODE_EMA,PRICE_CLOSE);
   m_ema_slow=iMA(_Symbol,PERIOD_CURRENT,InpSlowEma,0,MODE_EMA,PRICE_CLOSE);
   
   if(m_atr_handle==INVALID_HANDLE || m_ema_fast==INVALID_HANDLE || m_ema_slow==INVALID_HANDLE)
     {
      Print("Error creating indicators");
      return(false);
     }
   
   ArraySetAsSeries(m_atr_buf,true);
   ArraySetAsSeries(m_fast_buf,true);
   ArraySetAsSeries(m_slow_buf,true);
   
   return(true);
  }

//+------------------------------------------------------------------+
//| Deinitialization                                                 |
//+------------------------------------------------------------------+
void CChaosLyapunovExpert::Deinit(void)
  {
   if(m_atr_handle!=INVALID_HANDLE) IndicatorRelease(m_atr_handle);
   if(m_ema_fast!=INVALID_HANDLE) IndicatorRelease(m_ema_fast);
   if(m_ema_slow!=INVALID_HANDLE) IndicatorRelease(m_ema_slow);
  }

//+------------------------------------------------------------------+
//| Approximation of the Largest Lyapunov Exponent (LLE)             |
//+------------------------------------------------------------------+
double CChaosLyapunovExpert::CalculateLyapunov(void)
  {
   double prices[];
   ArraySetAsSeries(prices,true);
   
   int required_bars=InpLyaLookback+InpLyaKSteps+InpLyaEmbedding;
   if(CopyClose(_Symbol,PERIOD_CURRENT,0,required_bars,prices)<required_bars)
      return(0.0);

   double min_dist=999999.0;
   int nearest_idx=-1;

   for(int i=InpLyaKSteps+1; i<InpLyaLookback; i++) 
     {
      double dist=0;
      for(int j=0; j<InpLyaEmbedding; j++) 
        {
         dist+=MathPow(prices[InpLyaKSteps+j]-prices[i+j],2);
        }
      dist=MathSqrt(dist);
      
      if(dist>0.000001 && dist<min_dist) 
        {
         min_dist=dist;
         nearest_idx=i;
        }
     }

   if(nearest_idx==-1 || min_dist==0) return(0.0);

   double dist_k=0;
   for(int j=0; j<InpLyaEmbedding; j++) 
     {
      dist_k+=MathPow(prices[0+j]-prices[nearest_idx-InpLyaKSteps+j],2);
     }
   dist_k=MathSqrt(dist_k);

   if(dist_k==0) return(0.0);
   
   return(MathLog(dist_k/min_dist)/InpLyaKSteps);
  }

//+------------------------------------------------------------------+
//| Calculate safe lot size with Margin and Quant protections        |
//+------------------------------------------------------------------+
double CChaosLyapunovExpert::CalcLotSafe(double sl_dist, ENUM_ORDER_TYPE order_type, double price) 
  {
   if(sl_dist<=0) return(0.0);
      
   double tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tick_value=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   if(tick_size<=0 || tick_value<=0) return(0.0);
   
   double risk_money=AccountInfoDouble(ACCOUNT_BALANCE)*(InpRiskPercent/100.0);
   double lot=risk_money/((sl_dist/tick_size)*tick_value);
   
   double min_lot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double max_lot=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   
   double final_lot=MathFloor(lot/step)*step;
   
//--- Protect against insufficient balance (No Money Error Fix)
   if(final_lot<min_lot) return(0.0); // Account cannot afford the risk
   if(final_lot>max_lot) final_lot=max_lot;
   
//--- Verify available free margin before trading
   double margin_required=0.0;
   if(OrderCalcMargin(order_type,_Symbol,final_lot,price,margin_required))
     {
      if(margin_required > AccountInfoDouble(ACCOUNT_FREEMARGIN))
         return(0.0); // Not enough free margin
     }
   
   return(final_lot);
  }

//+------------------------------------------------------------------+
//| Check if there is an active position                             |
//+------------------------------------------------------------------+
bool CChaosLyapunovExpert::HasActivePosition(void) 
  {
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==_Symbol && m_position.Magic()==InpMagicNumber)
            return(true);
   return(false);
  }

//+------------------------------------------------------------------+
//| Main logic executed on every tick                                |
//+------------------------------------------------------------------+
void CChaosLyapunovExpert::OnTick(void)
  {
   datetime current_time=iTime(_Symbol,PERIOD_CURRENT,0);
   if(current_time==m_last_bar_time) return; 
      
   if(HasActivePosition()) return;
   
   double lyapunov_exponent=CalculateLyapunov();
   
   if(lyapunov_exponent>InpLyaThreshold) 
     {
      m_last_bar_time=current_time;
      return; 
     }
   
   if(CopyBuffer(m_atr_handle,0,1,1,m_atr_buf)<=0) return;
   if(CopyBuffer(m_ema_fast,0,1,2,m_fast_buf)<=0) return;
   if(CopyBuffer(m_ema_slow,0,1,2,m_slow_buf)<=0) return;
   
   double atr=m_atr_buf[0];
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   
//--- Broker constraints (Invalid Stops Error Fix)
   double min_stop_level = SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL) * _Point;
   double min_dist = MathMax(min_stop_level, _Point * 10); // Minimum 10 points fallback
   
   double sl_dist = MathMax(InpSlAtrMult * atr, min_dist);
   double tp_dist = MathMax(InpTpAtrMult * atr, min_dist);
   
   bool cross_up=(m_fast_buf[1]<=m_slow_buf[1]) && (m_fast_buf[0]>m_slow_buf[0]);
   bool cross_dn=(m_fast_buf[1]>=m_slow_buf[1]) && (m_fast_buf[0]<m_slow_buf[0]);
   
   if(cross_up)
     {
      double sl=NormalizeDouble(ask-sl_dist, _Digits);
      double tp=NormalizeDouble(ask+tp_dist, _Digits);
      double lot=CalcLotSafe(ask-sl, ORDER_TYPE_BUY, ask);
      if(lot>0)
         m_trade.Buy(lot,_Symbol,ask,sl,tp,"Lya_Momentum_Long");
     }
   else if(cross_dn)
     {
      double sl=NormalizeDouble(bid+sl_dist, _Digits);
      double tp=NormalizeDouble(bid-tp_dist, _Digits);
      double lot=CalcLotSafe(sl-bid, ORDER_TYPE_SELL, bid);
      if(lot>0)
         m_trade.Sell(lot,_Symbol,bid,sl,tp,"Lya_Momentum_Short");
     }
   
   m_last_bar_time=current_time;
  }

//--- global expert object
CChaosLyapunovExpert ExtExpert;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit() { return(ExtExpert.Init() ? INIT_SUCCEEDED : INIT_FAILED); }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) { ExtExpert.Deinit(); }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() { ExtExpert.OnTick(); }
//+------------------------------------------------------------------+

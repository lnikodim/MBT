//+------------------------------------------------------------------+
//|                                               RenkoLiveChart.mq5 |
//|  MT5 rewrite of the MT4 RenkoLiveChart v3.4 EA (clean room, from  |
//|  its inputs and the public v3.x brick logic; no .mq4 available).  |
//|                                                                  |
//|  MT4 wrote an offline .hst chart and poked it via user32.dll.    |
//|  MT5 has no offline charts, so the bricks go into a custom       |
//|  symbol <Symbol>_R<box> (M1 bars, one brick per bar) that this   |
//|  EA builds from M1 history, opens, and keeps live on every tick. |
//|  The custom symbol's history stays after the EA is removed, so   |
//|  other EAs can be backtested on it (1-min OHLC model: it has     |
//|  bars, not real ticks).                                          |
//|                                                                  |
//|  Dropped MT4 inputs: RenkoTimeFrame (offline period id),         |
//|  EmulateOnLineChart, StrangeSymbolName (.hst workarounds).       |
//+------------------------------------------------------------------+
#property strict
#property version   "1.00"
#property description "Live Renko chart as a custom symbol (MT5 port of RenkoLiveChart v3.4)."

input int  RenkoBoxSize   = 10;    // box size, points
input int  RenkoBoxOffset = 0;     // grid offset, points (|offset| < box)
input bool ShowWicks      = true;  // draw wicks on bricks
input int  MaxBars        = 0;     // M1 bars to build history from (0 = all the terminal holds)

//+------------------------------------------------------------------+
//| Brick engine: fixed grid, 1-box continuation, 2-box reversal.     |
//| Fed M1 bars (history) or single-price bars (live ticks).          |
//+------------------------------------------------------------------+
class CRenko
  {
private:
   double            m_box, m_off, m_eps;
   int               m_digits;
   bool              m_wicks, m_seeded;
   double            m_hi, m_lo, m_close, m_up, m_dn, m_prevHL;
   datetime          m_t;           // time of the brick now forming
   long              m_vol;
   int               m_spread;

   void              Emit(const double open, const double high, const double low, const double close, const datetime src)
     {
      const int n = ArraySize(bricks);
      ArrayResize(bricks, n + 1, 4096);
      bricks[n].time        = m_t;
      bricks[n].open        = open;
      bricks[n].high        = high;
      bricks[n].low         = low;
      bricks[n].close       = close;
      bricks[n].tick_volume = m_vol > 0 ? m_vol : 1;
      bricks[n].spread      = m_spread;
      bricks[n].real_volume = 0;
      // MT5 bars need distinct minutes (MT4 used PrevTime++ seconds).
      // ponytail: a fast move runs brick times ahead of the clock until it slows; per-second custom ticks if that matters
      m_t     = src > m_t + 60 ? src : m_t + 60;
      m_vol   = 0;
      m_up    = 0;
      m_dn    = DBL_MAX;
      m_close = close;
     }

   void              Ups(const MqlRates &r)
     {
      while(r.high >= m_hi + m_box - m_eps)
        {
         m_hi = NormalizeDouble(m_hi + m_box, m_digits);
         m_lo = NormalizeDouble(m_lo + m_box, m_digits);
         Emit(m_lo, m_hi, (m_wicks && m_dn < m_lo) ? m_dn : m_lo, m_hi, r.time);
        }
     }

   void              Downs(const MqlRates &r)
     {
      while(r.low <= m_lo - m_box + m_eps)
        {
         m_hi = NormalizeDouble(m_hi - m_box, m_digits);
         m_lo = NormalizeDouble(m_lo - m_box, m_digits);
         Emit(m_hi, (m_wicks && m_up > m_hi) ? m_up : m_hi, m_lo, m_lo, r.time);
        }
     }

public:
   MqlRates          bricks[];

   void              Init(const double box, const double off, const int digits, const bool wicks)
     {
      m_box    = box;
      m_off    = off;
      m_digits = digits;
      m_eps    = 0.5 * MathPow(10, -digits);
      m_wicks  = wicks;
      m_seeded = false;
      ArrayResize(bricks, 0);
     }

   void              Feed(const MqlRates &r)
     {
      if(!m_seeded)
        {
         m_lo     = NormalizeDouble(m_off + MathFloor((r.close + m_eps) / m_box) * m_box, m_digits);
         m_hi     = NormalizeDouble(m_lo + m_box, m_digits);
         m_close  = m_hi;
         m_up     = 0;
         m_dn     = DBL_MAX;
         m_vol    = 0;
         m_spread = r.spread;
         m_prevHL = r.high + r.low;
         m_t      = r.time;
         m_seeded = true;
         return;
        }
      m_vol   += r.tick_volume;
      m_spread = r.spread;
      m_up     = MathMax(m_up, r.high);
      m_dn     = MathMin(m_dn, r.low);
      // v3.x intrabar order guess: a rising bar made its low first
      const bool upTrend = r.high + r.low > m_prevHL;
      if(upTrend)
         Downs(r);
      Ups(r);
      if(!upTrend)
         Downs(r);
      m_prevHL = r.high + r.low;
     }

   // The live last bar: from the last brick's close to the current price.
   MqlRates          Forming(const double price) const
     {
      MqlRates b;
      b.time        = m_t;
      b.open        = m_close;
      b.high        = MathMax(MathMax(m_up, m_close), price);
      b.low         = MathMin(MathMin(m_dn, m_close), price);
      b.close       = price;
      b.tick_volume = m_vol > 0 ? m_vol : 1;
      b.spread      = m_spread;
      b.real_volume = 0;
      return(b);
     }
  };

CRenko g_renko;
string g_name;
bool   g_built = false;
int    g_sent  = 0;      // bricks already pushed to the custom symbol

//+------------------------------------------------------------------+
//| Fixed price path on a 1-pip box; fails init if the engine breaks. |
//+------------------------------------------------------------------+
bool SelfTest()
  {
   CRenko r;
   r.Init(0.00010, 0.0, 5, true);
   double path[] = {1.10000, 1.10025, 1.10005, 1.09995, 1.10050};
   for(int i = 0; i < ArraySize(path); i++)
     {
      MqlRates b;
      ZeroMemory(b);
      b.time = D'2024.01.02 10:00' + i * 60;
      b.open = b.high = b.low = b.close = path[i];
      r.Feed(b);
     }
   // up, 2-box reversal down, then a 4-box gap up
   double closes[] = {1.10020, 1.10000, 1.10020, 1.10030, 1.10040, 1.10050};
   if(ArraySize(r.bricks) != ArraySize(closes))
      return(false);
   for(int i = 0; i < ArraySize(closes); i++)
     {
      if(MathAbs(r.bricks[i].close - closes[i]) > 1e-9)
         return(false);
      if(MathAbs(MathAbs(r.bricks[i].close - r.bricks[i].open) - 0.00010) > 1e-9)
         return(false);
      if(i > 0 && r.bricks[i].time <= r.bricks[i - 1].time)
         return(false);
     }
   return(MathAbs(r.bricks[1].high - 1.10010) < 1e-9);   // no false wick on the reversal brick
  }

//+------------------------------------------------------------------+
//| Rebuild the whole custom symbol from M1 history.                  |
//+------------------------------------------------------------------+
bool Build()
  {
   MqlRates src[];
   const int want = MaxBars > 0 ? MaxBars : TerminalInfoInteger(TERMINAL_MAXBARS);
   const int n = CopyRates(_Symbol, PERIOD_M1, 1, want, src);   // closed bars, oldest first
   if(n < 2)
     {
      Print("Waiting for M1 history of ", _Symbol, " (", GetLastError(), ")");
      return(false);
     }
   g_renko.Init(RenkoBoxSize * _Point, RenkoBoxOffset * _Point, _Digits, ShowWicks);
   for(int i = 0; i < n; i++)
      g_renko.Feed(src[i]);

   MqlRates out[];
   const int b = ArrayCopy(out, g_renko.bricks);
   ArrayResize(out, b + 1);
   out[b] = g_renko.Forming(src[n - 1].close);
   if(CustomRatesReplace(g_name, 0, D'3000.01.01', out) < 0)
     {
      Print("CustomRatesReplace failed: ", GetLastError());
      return(false);
     }
   g_sent = b;
   PrintFormat("%s: %d bricks from %d M1 bars (%s .. %s)", g_name, b, n,
               TimeToString(src[0].time), TimeToString(src[n - 1].time));

   for(long id = ChartFirst(); id >= 0; id = ChartNext(id))
      if(ChartSymbol(id) == g_name)
         return(true);
   if(ChartOpen(g_name, PERIOD_M1) == 0)
      Print("ChartOpen failed: ", GetLastError(), " - open ", g_name, " M1 by hand");
   return(true);
  }

int OnInit()
  {
   if(!SelfTest())
     {
      Print("SelfTest FAILED: brick engine is broken");
      return(INIT_FAILED);
     }
   Print("SelfTest OK");
   if(RenkoBoxSize <= 0)
     {
      Print("Error: RenkoBoxSize must be positive!");
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(MathAbs(RenkoBoxOffset) >= RenkoBoxSize)
     {
      Print("Error: |RenkoBoxOffset| should be less than RenkoBoxSize!");
      return(INIT_PARAMETERS_INCORRECT);
     }

   g_name = _Symbol + "_R" + IntegerToString(RenkoBoxSize);
   bool custom = false;
   if(SymbolExist(g_name, custom))
     {
      if(!custom)
        {
         Print("Error: ", g_name, " is a broker symbol, not a custom one");
         return(INIT_FAILED);
        }
     }
   else if(!CustomSymbolCreate(g_name, "Renko", _Symbol))
     {
      Print("Error: can't create custom symbol ", g_name, ": ", GetLastError());
      return(INIT_FAILED);
     }
   SymbolSelect(g_name, true);

   g_built = Build();   // history not synced yet -> retried on the next tick
   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
   if(!g_built)
     {
      g_built = Build();
      return;
     }
   MqlTick tk;
   if(!SymbolInfoTick(_Symbol, tk) || tk.bid <= 0)
      return;
   MqlRates r;
   r.time        = (datetime)(tk.time / 60 * 60);
   r.open        = r.high = r.low = r.close = tk.bid;
   r.tick_volume = 1;
   r.spread      = (int)MathRound((tk.ask - tk.bid) / _Point);
   r.real_volume = 0;
   g_renko.Feed(r);

   MqlRates out[];
   const int total = ArraySize(g_renko.bricks);
   const int b = total > g_sent ? ArrayCopy(out, g_renko.bricks, 0, g_sent) : 0;
   ArrayResize(out, b + 1);
   out[b] = g_renko.Forming(tk.bid);
   if(CustomRatesUpdate(g_name, out) < 0)
      Print("CustomRatesUpdate failed: ", GetLastError());
   else
      g_sent = total;
  }
//+------------------------------------------------------------------+

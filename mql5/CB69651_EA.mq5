//+------------------------------------------------------------------+
//|                          ImpulseContinuationEngine [ICE_Pro].mq5 |
//|                                    Copyright 2026, MT5 Developer |
//|                          https://www.mql5.com/en/users/ritzfalih |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MT5 Developer"
#property link      "https://www.mql5.com/en/users/ritzfalih/seller"
#property version   "1.0"
#property description "RITZ Impulse Continuation Engine Pro.\nAdaptive filters for reliable entries"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\HistoryOrderInfo.mqh>

//--- Global Configuration
#define ICE_PREFIX "ICE_"
#define UPDATE_INTERVAL_MS 100

//--- Enumerations
enum ENUM_TRADING_MODE
  {
   TRADING_MODE_DISABLED,
   TRADING_MODE_DEMO,
   TRADING_MODE_LIVE
  };

enum ENUM_MARKET_SESSION
  {
   SESSION_ASIAN,
   SESSION_LONDON,
   SESSION_NEWYORK,
   SESSION_PACIFIC
  };

enum ENUM_TRAILING_MODE
  {
   TRAIL_NONE,          // No trailing
   TRAIL_BREAKEVEN,     // Move to breakeven only
   TRAIL_ATR_FIXED,     // Fixed ATR trailing
   TRAIL_ATR_DYNAMIC,   // Dynamic ATR trailing
   TRAIL_HYBRID         // Hybrid trailing (breakeven + ATR)
  };

//--- Input Parameters - OPTIMIZED & CALIBRATED
input group "───────── CORE SETTINGS ───────────"
input ENUM_TRADING_MODE   InpTradingMode    = TRADING_MODE_DEMO;   // Trading mode selection (Live / Test / Visual)
input string              InpTradeSymbol    = "";                  // Trading symbol (empty = current chart symbol)
input int                 InpMagicNumber    = 888888;              // Unique magic number for order identification
input string              InpTradeComment   = "Ritz-ICE-Pro";      // Trade comment shown in terminal & history
input bool                InpDebugMode      = true;                // Enable detailed debug logging
input bool                InpEnableAdaptive = true;                // Enable adaptive logic based on market conditions

input group "───────── ICE DETECTION ───────────"
input int                 InpLookbackPeriod = 20;                  // Historical bars used for ICE pattern detection
input double              InpVolumeMultiplier = 1.3;               // Minimum volume multiplier to confirm impulse
input double              InpMinBodyRatio   = 0.5;                 // Minimum candle body-to-range ratio (impulse strength)
input double              InpClosePosition  = 0.6;                 // Minimum close position within candle range (0–1)
input int                 InpMinImpulseBars = 2;                   // Minimum bars required for a valid impulse
input int                 InpMaxImpulseBars = 5;                   // Maximum bars allowed for impulse sequence
input bool                InpUseSessionFilter = true;              // Allow trades only during active trading sessions

input group "───────── RISK MANAGEMENT ───────────"
input double              InpRiskPerTrade   = 0.1;                 // Risk per trade in percent of account balance
input bool                InpReduceAfterLoss = false;              // Reduce risk after a losing trade
input double              InpReductionFactor = 0.2;                // Risk reduction factor after loss (0.8 = -20%)
input double              InpMinEquityToTrade = 10.0;              // Minimum funds to keep trading (USD)
input double              InpMinMarginLevel   = 110.0;             // Minimum Margin Level (%)

input group "───────── TRADE EXECUTION ───────────"
input double              InpATRMultiplierSL = 1.2;                // Stop Loss distance based on ATR multiplier
input double              InpATRMultiplierTP = 1.8;                // Take Profit distance based on ATR multiplier
input int                 InpSlippagePoints  = 30;                 // Maximum allowed slippage (in points)

input group "───────── ENTRY OPTIMIZATION ───────────"
input bool                InpImmediateEntry  = true;               // Enter immediately after impulse detection
input double              InpMaxEntryBars    = 3;                  // Maximum bars to wait for entry after detection

input group "───────── SMART TRAILING ───────────"
input ENUM_TRAILING_MODE  InpTrailingMode    = TRAIL_ATR_FIXED;    // Trailing stop mode (Fixed / ATR / Hybrid)
input double              InpBreakevenAt    = 0.5;                 // Move SL to breakeven at % of TP reached
input double              InpTrailATRMulti  = 1.0;                 // ATR multiplier for trailing stop distance
input double              InpTrailActivation = 0.3;                // Profit % required to activate trailing logic
input bool                InpUseVolatilityAdjust = true;           // Dynamically adjust trailing based on volatility

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
input group "───────── SAFETY FILTERS (CALIBRATED) ───────────"
input double              InpMaxSpread      = 40.0;                // Maximum allowed spread (points)
input int                 InpMinATRPoints   = 50;                  // Minimum ATR volatility filter (≈ 5 pips)
input int                 InpMaxATRPoints   = 1500;                // Maximum ATR volatility filter (≈ 150 pips)
input bool                InpFilterLowVolume = true;               // Block trades during low-volume conditions

//--- Global Variables
CTrade           *Trade;
CPositionInfo     Position;
CHistoryOrderInfo History;

//--- Market State
string            CurrentSymbol;
double            SymbolPoint;
int               SymbolDigits;
double            TickSize;
double            TickValue;
double            MinLot;
double            MaxLot;
double            LotStep;
int               StopsLevel;

//--- Market prices untuk trailing
double MarketBid;
double MarketAsk;
double MarketSpread;

//--- Impulse State dengan adaptive parameters
struct SImpulseState
  {
   bool              active;
   bool              bullish;
   int               start_bar;
   int               expected_bars;
   double            strength;
   double            volume_ratio;
   double            body_ratio;
   double            close_position;
   datetime          detection_time;
   double            detection_price;
   double            highest_since;
   double            lowest_since;
   double            entry_price;
   double            sl_price;
   double            tp_price;
   double            current_multiplier;
  };

SImpulseState    Impulse;

//--- Timing
datetime          last_bar_time;
bool              new_bar = false;

//--- Handles
int               hATR;
int               hMA;       // NEW: Untuk trend confirmation

//--- Adaptive variables
double            avg_volume_global = 0;
int               total_bars_analyzed = 0;

ENUM_MARKET_SESSION current_session = SESSION_ASIAN;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("──────────────────────────────────");
   Print("RITZ ICE Pro - Smart Trailing System Initializing...");

   CurrentSymbol = (InpTradeSymbol == "") ? _Symbol : InpTradeSymbol;

   if(!SymbolSelect(CurrentSymbol, true))
      return INIT_FAILED;

// Refresh data market terbaru agar properti simbol tidak nol
   SymbolPoint = SymbolInfoDouble(CurrentSymbol, SYMBOL_POINT);
   SymbolDigits = (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_DIGITS);
   TickSize = SymbolInfoDouble(CurrentSymbol, SYMBOL_TRADE_TICK_SIZE);
   TickValue = SymbolInfoDouble(CurrentSymbol, SYMBOL_TRADE_TICK_VALUE);
   MinLot = SymbolInfoDouble(CurrentSymbol, SYMBOL_VOLUME_MIN);
   MaxLot = SymbolInfoDouble(CurrentSymbol, SYMBOL_VOLUME_MAX);
   LotStep = SymbolInfoDouble(CurrentSymbol, SYMBOL_VOLUME_STEP);
   StopsLevel = (int)SymbolInfoInteger(CurrentSymbol, SYMBOL_TRADE_STOPS_LEVEL);

// Inisialisasi CTrade secara dinamis dengan pengecekan pointer
   if(CheckPointer(Trade) == POINTER_INVALID)
      Trade = new CTrade();

   Trade.SetExpertMagicNumber(InpMagicNumber);
   Trade.SetDeviationInPoints(InpSlippagePoints);

// Create handles
   hATR = iATR(CurrentSymbol, _Period, InpLookbackPeriod);
   hMA  = iMA(CurrentSymbol, _Period, 50, 0, MODE_SMA, PRICE_CLOSE);

   if(hATR == INVALID_HANDLE || hMA == INVALID_HANDLE)
     {
      Print("ICE Error: Indicator handles failed.");
      return INIT_FAILED;
     }

// FORCE SYNC: Menunggu sebentar agar indikator mulai menghitung
// Ini mencegah ATR Out of Range saat detik pertama EA dipasang
   int retry = 0;
   while(BarsCalculated(hATR) < InpLookbackPeriod && retry < 20)
     {
      Sleep(100);
      retry++;
     }

   ResetImpulse();
   last_bar_time = iTime(CurrentSymbol, _Period, 0);
   CalculateInitialAverages();

   Print("RITZ ICE Pro Initialized Successfully!");
   Print("──────────────────────────────────");

   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CalculateInitialAverages()
  {
   long volumes[];
   ArraySetAsSeries(volumes, true);

   if(CopyTickVolume(CurrentSymbol, _Period, 1, 100, volumes) >= 50)
     {
      double sum = 0;
      int count = 0;
      for(int i = 0; i < 100 && i < ArraySize(volumes); i++)
        {
         if(volumes[i] > 0)
           {
            sum += (double)volumes[i];
            count++;
           }
        }
      if(count > 0)
         avg_volume_global = sum / count;
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsAccountSafe()
  {
   double equity      = AccountInfoDouble(ACCOUNT_EQUITY);
   double balance     = AccountInfoDouble(ACCOUNT_BALANCE);
   double margin_lev  = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);

// 1. Cek apakah Equity sudah habis atau di bawah batas minimum
   if(equity <= InpMinEquityToTrade || equity <= 0)
     {
      if(InpDebugMode)
         Print("ICE Critical: Equity insufficient ($", equity, "). EA Halted.");
      return false;
     }

// 2. Cek Margin Level (mencegah pembukaan posisi saat margin mepet)
// Margin Level 0 berarti tidak ada posisi terbuka, jadi kita abaikan cek ini jika 0
   if(margin_lev > 0 && margin_lev < InpMinMarginLevel)
     {
      if(InpDebugMode)
         Print("ICE Critical: Margin Level too low (", margin_lev, "%). EA Halted.");
      return false;
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Comment(""); // Clear dashboard

   if(hATR != INVALID_HANDLE)
      IndicatorRelease(hATR);
   if(hMA != INVALID_HANDLE)
      IndicatorRelease(hMA);
   if(CheckPointer(Trade) == POINTER_DYNAMIC)
      delete Trade;

   Print("RITZ ICE Pro Deinitialized. Reason: ", GetReasonText(reason));
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- Update market prices
   UpdateMarketPrices();

//--- Update current session
   UpdateMarketSession();

//--- Check for new bar
   datetime current_bar_time = iTime(CurrentSymbol, _Period, 0);
   if(current_bar_time > last_bar_time)
     {
      last_bar_time = current_bar_time;
      new_bar = true;
     }
   else
     {
      new_bar = false;
     }

//--- Process on new bar only
   if(new_bar)
     {
      if(InpDebugMode)
         Print("--- NEW BAR [", GetSessionName(current_session), "] ---");
      ProcessNewBar();
     }

//--- Apply smart trailing on every tick (for real-time trailing)
   if(InpTrailingMode != TRAIL_NONE)
     {
      ApplySmartTrailing();
     }

//--- Update dashboard
   UpdateDashboard();
  }

//+------------------------------------------------------------------+
//| Update market prices                                             |
//+------------------------------------------------------------------+
void UpdateMarketPrices()
  {
   MarketBid = SymbolInfoDouble(CurrentSymbol, SYMBOL_BID);
   MarketAsk = SymbolInfoDouble(CurrentSymbol, SYMBOL_ASK);
   MarketSpread = (MarketAsk - MarketBid) / SymbolPoint;
  }

//+------------------------------------------------------------------+
//| SMART TRAILING SYSTEM - FIXED REFERENCES                       |
//+------------------------------------------------------------------+
void ApplySmartTrailing()
  {
// Loop melalui posisi yang terbuka
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(Position.SelectByIndex(i))
        {
         // Filter berdasarkan Symbol dan Magic Number
         if(Position.Symbol() == CurrentSymbol && Position.Magic() == InpMagicNumber)
           {
            double entry    = Position.PriceOpen();
            double tp       = Position.TakeProfit();
            double current  = (Position.PositionType() == POSITION_TYPE_BUY) ? MarketBid : MarketAsk;
            double current_sl = Position.StopLoss();
            ulong ticket    = Position.Ticket();

            // Skip if no TP set
            if(tp <= 0)
               continue;

            // Calculate distances
            double total_tp_dist = MathAbs(tp - entry);
            double current_dist  = MathAbs(current - entry);

            //--- LOGIKA 1: MOVE TO BREAK EVEN (BEP) ---
            if(InpTrailingMode == TRAIL_BREAKEVEN || InpTrailingMode == TRAIL_HYBRID)
              {
               if(total_tp_dist > 0 && current_dist >= (total_tp_dist * InpBreakevenAt))
                 {
                  // Jika Buy, pastikan harga saat ini di atas entry
                  if(Position.PositionType() == POSITION_TYPE_BUY)
                    {
                     if(current_sl < entry || current_sl == 0)
                       {
                        double new_sl = NormalizePrice(entry);
                        if(Trade.PositionModify(ticket, new_sl, tp))
                          {
                           Print("ICE Trailing: SL moved to Break Even (Buy) at ", new_sl);
                          }
                       }
                    }
                  // Jika Sell
                  else
                     if(Position.PositionType() == POSITION_TYPE_SELL)
                       {
                        if(current_sl > entry || current_sl == 0)
                          {
                           double new_sl = NormalizePrice(entry);
                           if(Trade.PositionModify(ticket, new_sl, tp))
                             {
                              Print("ICE Trailing: SL moved to Break Even (Sell) at ", new_sl);
                             }
                          }
                       }
                 }
              }

            //--- LOGIKA 2: ATR TRAILING ---
            if((InpTrailingMode == TRAIL_ATR_FIXED ||
                InpTrailingMode == TRAIL_ATR_DYNAMIC ||
                InpTrailingMode == TRAIL_HYBRID) &&
               current_dist >= (total_tp_dist * InpTrailActivation))
              {
               double atr = GetATRValue();
               if(atr <= 0)
                  continue;

               double trail_distance = atr * InpTrailATRMulti;

               // Apply trailing stop
               if(Position.PositionType() == POSITION_TYPE_BUY)
                 {
                  double new_sl = current - trail_distance;
                  new_sl = NormalizePrice(new_sl);

                  // Only move SL if it's higher than current SL and above breakeven
                  if(new_sl > current_sl && new_sl >= entry)
                    {
                     if(Trade.PositionModify(ticket, new_sl, tp))
                       {
                        Print("ICE Trailing: BUY SL updated to ", new_sl);
                       }
                    }
                 }
               else
                  if(Position.PositionType() == POSITION_TYPE_SELL)
                    {
                     double new_sl = current + trail_distance;
                     new_sl = NormalizePrice(new_sl);

                     // Only move SL if it's lower than current SL and below breakeven
                     if((new_sl < current_sl || current_sl == 0) && new_sl <= entry)
                       {
                        if(Trade.PositionModify(ticket, new_sl, tp))
                          {
                           Print("ICE Trailing: SELL SL updated to ", new_sl);
                          }
                       }
                    }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//| Helper functions (existing code with additions)                 |
//+------------------------------------------------------------------+
void UpdateMarketSession()
  {
   MqlDateTime dt;
   TimeCurrent(dt);

   if(dt.hour >= 0 && dt.hour < 8)
      current_session = SESSION_ASIAN;
   else
      if(dt.hour >= 8 && dt.hour < 13)
         current_session = SESSION_LONDON;
      else
         if(dt.hour >= 13 && dt.hour < 22)
            current_session = SESSION_NEWYORK;
         else
            current_session = SESSION_PACIFIC;
  }

//+------------------------------------------------------------------+
//| Get session name                                                 |
//+------------------------------------------------------------------+
string GetSessionName(ENUM_MARKET_SESSION session)
  {
   switch(session)
     {
      case SESSION_ASIAN:
         return "ASIAN";
      case SESSION_LONDON:
         return "LONDON";
      case SESSION_NEWYORK:
         return "NEW YORK";
      case SESSION_PACIFIC:
         return "PACIFIC";
      default:
         return "UNKNOWN";
     }
  }

//+------------------------------------------------------------------+
//| Get adaptive volume multiplier based on session                  |
//+------------------------------------------------------------------+
double GetAdaptiveVolumeMultiplier()
  {
   if(!InpEnableAdaptive)
      return InpVolumeMultiplier;

// Adjust multiplier based on session
   switch(current_session)
     {
      case SESSION_LONDON:
      case SESSION_NEWYORK:
         return InpVolumeMultiplier * 0.9;  // Lower requirement in high volume sessions

      case SESSION_ASIAN:
      case SESSION_PACIFIC:
         return InpVolumeMultiplier * 1.3;  // Higher requirement in low volume sessions

      default:
         return InpVolumeMultiplier;
     }
  }

//+------------------------------------------------------------------+
//| Get adaptive body ratio based on volatility                     |
//+------------------------------------------------------------------+
double GetAdaptiveBodyRatio()
  {
   if(!InpEnableAdaptive)
      return InpMinBodyRatio;

   double atr = GetATRValue();
   double atr_percent = atr / SymbolInfoDouble(CurrentSymbol, SYMBOL_BID);

// Lower body ratio requirement in high volatility
   if(atr_percent > 0.001)
      return InpMinBodyRatio * 0.8;  // High volatility
   if(atr_percent < 0.0003)
      return InpMinBodyRatio * 1.2; // Low volatility

   return InpMinBodyRatio;
  }

/* // Pilihan Anda dapat menggunakan Kode Berikut
//+------------------------------------------------------------------+
//| Process new bar - Enhanced Safety & State Management             |
//+------------------------------------------------------------------+
void ProcessNewBar()
  {
//--- Step 1: Validasi ATR & Kondisi Pasar
// Jika ATR "Out of Range", CheckTradingConditions() akan mengembalikan false
// sehingga EA berhenti di sini dan tidak merusak State Impulse.
   if(!CheckTradingConditions())
     {
      // Jika kondisi pasar tidak layak, kita pertimbangkan untuk reset impuls yang menggantung
      if(Impulse.active && IsImpulseDecayed())
         ResetImpulse();

      if(InpDebugMode)
         Print("ICE Info: Trading conditions NOT met. skipping bar...");
      return;
     }

//--- Step 2: Manajemen State Impulse
   if(!Impulse.active)
     {
      // Deteksi impuls baru hanya jika kondisi ATR/Spread benar-benar valid
      if(DetectImpulse())
        {
         // Fungsi ini biasanya berisi notifikasi atau inisialisasi awal
         OnImpulseDetected();
        }
     }
   else
     {
      // Jika impuls sedang aktif, monitor apakah masih valid (decay)
      // MonitorImpulse sekarang aman karena CheckTradingConditions sudah lewat
      MonitorImpulse();
     }

//--- Step 3: Eksekusi (Hanya jika Impulse masih aktif setelah monitor)
   if(Impulse.active)
     {
      if(CheckEntryConditions())
        {
         ExecuteTrade();
        }
      else
         if(InpDebugMode)
           {
            PrintFormat("ICE Info: Impulse Active (Strength: %.2f) but Entry Setup not ready.", Impulse.strength);
           }
     }
  }
*/

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ProcessNewBar()
  {
//--- Step 1: Validate Market Conditions
   if(!CheckTradingConditions())
     {
      if(InpDebugMode)
         Print("ICE Info: Trading conditions NOT met. skipping bar...");
      return;
     }

//--- Step 2: Impulse State Management
   if(!Impulse.active)
     {
      // Try to detect new impulse
      if(DetectImpulse())
        {
         OnImpulseDetected();

         // Immediately check for entry on this bar (aggressive entry)
         if(CheckEntryConditions())
           {
            ExecuteTrade();
            return;
           }
        }
     }
   else
     {
      // Update impulse bar count
      Impulse.start_bar++;

      // Update high/low
      double current_high = iHigh(CurrentSymbol, _Period, 0);
      double current_low = iLow(CurrentSymbol, _Period, 0);

      if(current_high > Impulse.highest_since)
         Impulse.highest_since = current_high;
      if(current_low < Impulse.lowest_since)
         Impulse.lowest_since = current_low;

      // Check for entry
      if(CheckEntryConditions())
        {
         ExecuteTrade();
        }
      else
        {
         // Check for decay
         if(IsImpulseDecayed())
           {
            if(InpDebugMode)
               Print("Impulse decayed after ", Impulse.start_bar, " bars");
            ResetImpulse();
           }
         else
            if(InpDebugMode)
              {
               PrintFormat("ICE Info: Impulse Active (Strength: %.2f) Bar %d/%d - Waiting for entry...",
                           Impulse.strength, Impulse.start_bar, Impulse.expected_bars);
              }
        }
     }
  }

/* // Pilihan Anda dapat menggunakan Kode Berikut
//+------------------------------------------------------------------+
//| Process new bar - High Performance & Adaptive Execution          |
//+------------------------------------------------------------------+
void ProcessNewBar()
{
   //--- Step 1: Dasar Keamanan (Filter Market & Koneksi)
   // Kita tetap disiplin di sini: jika spread melebar atau ATR ngaco, jangan lakukan apa pun.
   if(!CheckTradingConditions())
   {
      // Jika kondisi pasar memburuk saat ada impuls aktif, kita reset agar tidak 'nyangkut'
      if(Impulse.active) ResetImpulse();
      return;
   }

   //--- Step 2: Manajemen State Impuls
   if(!Impulse.active)
   {
      // DETEKSI: Mencari ledakan harga baru
      if(DetectImpulse())
      {
         OnImpulseDetected();

         // AGRESIF: Jangan tunggu bar berikutnya. Jika bar deteksi sudah
         // memenuhi syarat entry (misal: breakout langsung), ambil resikonya sekarang!
         if(CheckEntryConditions())
         {
            ExecuteTrade();
            return; // Exit setelah eksekusi untuk efisiensi
         }
      }
   }
   else
   {
      // MAINTENANCE: Update data impuls yang sedang berjalan
      Impulse.start_bar++;

      // Update High/Low secara presisi untuk kalkulasi Pullback/Fibonacci
      double high0 = iHigh(CurrentSymbol, _Period, 0);
      double low0  = iLow(CurrentSymbol, _Period, 0);

      if(high0 > Impulse.highest_since) Impulse.highest_since = high0;
      if(low0  < Impulse.lowest_since)  Impulse.lowest_since  = low0;

      //--- Step 3: Evaluasi Eksekusi vs Peluruhan (Decay)

      // Prioritas 1: Cek Peluang Entry
      if(CheckEntryConditions())
      {
         ExecuteTrade();
         // Setelah trade, ResetImpulse() biasanya dipanggil di dalam ExecuteTrade
         // atau setelah posisi berhasil dibuka untuk mencegah double entry.
         return;
      }

      // Prioritas 2: Cek apakah Impuls sudah basi (Decay)
      // Kita disiplin: jika momentum hilang atau harga berbalik > 61.8%, buang impuls ini.
      if(IsImpulseDecayed())
      {
         if(InpDebugMode)
            PrintFormat("ICE Info: Impulse discarded at bar %d (Decayed or Timed out)", Impulse.start_bar);
         ResetImpulse();
         return;
      }

      // DEBUG: Memberikan info status jika sedang menunggu setup
      if(InpDebugMode)
      {
         PrintFormat("ICE Watch: [%s] Strength: %.2f | Bar: %d/%d | Tracking H: %.5f L: %.5f",
                     (Impulse.bullish ? "BULL" : "BEAR"), Impulse.strength,
                     Impulse.start_bar, Impulse.expected_bars + 2,
                     Impulse.highest_since, Impulse.lowest_since);
      }
   }
}
*/

//+------------------------------------------------------------------+
//| Check trading conditions with adaptive session & safety filters  |
//+------------------------------------------------------------------+
bool CheckTradingConditions()
  {
// 1. HARDWARE & PERMISSION CHECK (Safety First)
// Mengecek apakah tombol 'Algo Trading' aktif dan terminal terhubung ke server
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED) || !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      static datetime last_print_auth = 0;
      if(InpDebugMode && TimeCurrent() - last_print_auth > 3600)
        {
         Print("ICE Pro: Trading not allowed by Platform/Terminal settings.");
         last_print_auth = TimeCurrent();
        }
      return false;
     }

// 2. SYMBOL PERMISSION CHECK
// Memastikan broker mengizinkan transaksi penuh (Bukan Close Only/Disabled)
   if(SymbolInfoInteger(CurrentSymbol, SYMBOL_TRADE_MODE) != SYMBOL_TRADE_MODE_FULL)
     {
      if(InpDebugMode)
         Print("ICE Pro: Symbol trading mode is restricted.");
      return false;
     }

// 3. ADAPTIVE SPREAD CHECK
// Menggunakan normalisasi MathRound agar perbandingan point presisi
   double current_ask = SymbolInfoDouble(CurrentSymbol, SYMBOL_ASK);
   double current_bid = SymbolInfoDouble(CurrentSymbol, SYMBOL_BID);
   double spread_points = (current_ask - current_bid) / SymbolPoint;
   double max_allowed_spread = GetAdaptiveMaxSpread();

   if(spread_points > max_allowed_spread)
     {
      if(InpDebugMode)
         PrintFormat("ICE Filter: Spread too high (Current: %.0f > Max: %.0f)", spread_points, max_allowed_spread);
      return false;
     }

// 4. VOLATILITY CHECK (ATR)
// Menggunakan GetATRValue() yang sudah kita refactor dengan proteksi Array-Sync
// Transformasi nilai ATR mentah menjadi Points untuk validasi yang konsisten
   double atr_raw = GetATRValue();
   double atr_in_points = atr_raw / SymbolPoint; // Mengubah desimal ke Points (misal: 0.00100 -> 100)

// 1. Cek Batas Bawah (Mencegah market mati/stagnan)
   if(atr_in_points < (double)InpMinATRPoints)
     {
      if(InpDebugMode)
         PrintFormat("ICE Filter: Volatility too low (%.1f < %d pts)", atr_in_points, InpMinATRPoints);
      return false;
     }

// 2. Cek Batas Atas (Mencegah "Out of Range" / News Spikes)
   if(atr_in_points > (double)InpMaxATRPoints)
     {
      if(InpDebugMode)
         PrintFormat("ICE Filter: Volatility abnormal (%.1f > %d pts)", atr_in_points, InpMaxATRPoints);
      return false;
     }

// 5. SESSION FILTER
// Menggabungkan logika waktu trading utama (London/NY)
   if(InpUseSessionFilter && !IsGoodTradingSession())
     {
      if(InpDebugMode)
         PrintFormat("ICE Filter: Restricted Session [%s]", GetSessionName(current_session));
      return false;
     }

// 6. ADAPTIVE VOLUME FILTER
// Memastikan ada partisipasi pasar yang cukup (menghindari fake impulse)
   if(InpFilterLowVolume && IsLowVolumeSession())
     {
      if(InpDebugMode)
         Print("ICE Filter: Low market activity detected (Volume Filter)");
      return false;
     }
   if(!IsAccountSafe())
      return false;

// Filter lainnya (Spread, Session, dll)
   if(MarketSpread > GetAdaptiveMaxSpread())
      return false;
   if(!IsGoodTradingSession())
      return false;

// Semua kondisi terpenuhi
   return true;
  }

//+------------------------------------------------------------------+
//| Get adaptive max spread based on session (Unit: Points)          |
//+------------------------------------------------------------------+
double GetAdaptiveMaxSpread()
  {
   double base_spread = InpMaxSpread;

// 1. Jika adaptive dimatikan, kembalikan nilai input langsung
   if(!InpEnableAdaptive)
      return base_spread;

   double multiplier = 1.0;

// 2. Tentukan multiplier berdasarkan volatilitas sesi
   switch(current_session)
     {
      case SESSION_LONDON:
      case SESSION_NEWYORK:
         // Di sesi aktif, volatilitas tinggi sering membuat spread melebar sesaat.
         // Kita beri toleransi sedikit lebih longgar agar tidak kehilangan peluang.
         multiplier = 1.2;
         break;

      case SESSION_ASIAN:
      case SESSION_PACIFIC:
         // Di sesi sepi, spread harusnya tipis. Jika melebar, itu tanda likuiditas
         // buruk/berbahaya, maka kita perketat syaratnya.
         multiplier = 0.8;
         break;

      default:
         multiplier = 1.0;
         break;
     }

// 3. Normalisasi hasil agar sesuai dengan sistem pembulatan point (Integer-friendly)
// Kita gunakan MathRound karena spread dalam point tidak mungkin memiliki desimal
   return MathRound(base_spread * multiplier);
  }

//+------------------------------------------------------------------+
//| Check if current session is good for trading (Adaptive Version)  |
//+------------------------------------------------------------------+
bool IsGoodTradingSession()
  {
// 1. DATA ACQUISITION
   MqlDateTime dt;
   TimeCurrent(dt);

// 2. TIME-BASED SAFETY (Server Agnostic)
// Menghindari 1 jam pertama pembukaan market (Rollover)
// di mana spread sangat liar dan likuiditas palsu.
   if(dt.hour == 0)
      return false;

// 3. ADAPTIVE VOLATILITY CHECK
// Alih-alih menebak jam London/NY, kita tanya pada pasar:
// "Apakah volatilitas saat ini cukup kuat untuk sebuah impuls?"
   double current_atr = GetATRValue();
   double avg_atr_long = 0;

// Kita bandingkan ATR saat ini (misal periode 20) dengan ATR jangka panjang (misal 100)
// untuk mengetahui apakah kita berada di sesi yang 'hidup'
   int handle_long = iATR(CurrentSymbol, _Period, 100);
   double buffer_long[];
   ArraySetAsSeries(buffer_long, true);

   if(CopyBuffer(handle_long, 0, 1, 1, buffer_long) > 0)
     {
      avg_atr_long = buffer_long[0];
     }

// 4. LOGIKA ADAPTIF: "The 80% Rule"
// Sesi dianggap "Good" jika volatilitas saat ini minimal 80% dari rata-rata harian.
// Ini secara otomatis akan memblokir Sesi Asia yang sepi dan
// memperbolehkan Sesi London/NY tanpa peduli jam broker Anda.
   if(current_atr < (avg_atr_long * 0.8))
     {
      if(InpDebugMode)
         PrintFormat("ICE Session: Low Volatility Context (ATR %.5f < %.5f). Skipping...", current_atr, avg_atr_long * 0.8);
      return false;
     }

// 5. SESSION CLASSIFICATION (Optional Filter)
// Tetap gunakan filter jam sebagai 'pintu terakhir' jika InpUseSessionFilter aktif
   if(InpUseSessionFilter)
     {
      // Menggunakan current_session yang diupdate oleh UpdateMarketSession()
      if(current_session == SESSION_ASIAN || current_session == SESSION_PACIFIC)
        {
         // Di sesi Asia, kita hanya izinkan trade jika volatilitas benar-benar meledak (Overdrive)
         if(current_atr < (avg_atr_long * 1.2))
            return false;
        }
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Check if current market activity is too low for trading          |
//+------------------------------------------------------------------+
bool IsLowVolumeSession()
  {
// 1. DATA ACQUISITION
// Kita gunakan bar index [1] (yang sudah tertutup) sebagai referensi aktivitas terakhir
   long last_bar_volume = iTickVolume(CurrentSymbol, _Period, 1);

// 2. GET DYNAMIC AVERAGE VOLUME
// Menggunakan fungsi GetAverageVolume yang sudah kita bahas (misal periode 20 bar terakhir)
   double avg_vol = GetAverageVolume(InpLookbackPeriod);

   if(avg_vol <= 0)
      return false; // Safety exit jika data belum siap

// 3. LOGIKA EVALUASI VOLUME
// Kita membandingkan volume bar terakhir dengan rata-rata volume periodik
   double volume_ratio = (double)last_bar_volume / avg_vol;

// Filter 1: Low Activity Threshold
// Jika volume bar terakhir kurang dari 40% rata-rata, sesi dianggap tidak likuid.
   if(volume_ratio < 0.4)
     {
      if(InpDebugMode)
         PrintFormat("ICE Filter: Low Volume Session (Ratio: %.2f < 0.40)", volume_ratio);
      return true;
     }

// 4. SPREAD ADAPTIVITY (Integrasi tambahan)
// Volume rendah biasanya dibarengi dengan spread yang melebar.
// Jika spread saat ini > 2x rata-rata spread, ini juga indikasi Low Volume/Bad Liquidity.
   double current_spread = (double)SymbolInfoInteger(CurrentSymbol, SYMBOL_SPREAD);
   if(current_spread > (GetAdaptiveMaxSpread() * 1.5))
     {
      if(InpDebugMode)
         Print("ICE Filter: Low liquidity detected via Spread spike.");
      return true;
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Detect impulse with adaptive parameters & safety guards           |
//+------------------------------------------------------------------+
bool DetectImpulse()
  {
// 1. DATA ACQUISITION & SYNC GUARD
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

// Kita ambil 4 bar untuk memastikan prev2 (index 3) tersedia
   if(CopyRates(CurrentSymbol, _Period, 0, 4, rates) < 4)
      return false;

// Index 0 adalah bar yang sedang berjalan (running)
// Kita deteksi impuls pada bar yang baru saja TERTUTUP (Index 1)
   MqlRates current = rates[1];
   MqlRates prev1   = rates[2];
   MqlRates prev2   = rates[3];

// 2. INDICATOR VALIDATION (Anti ATR Out-of-Range)
   double atr = GetATRValue();
   double avg_volume = GetAverageVolume(InpLookbackPeriod);

// Jika ATR tidak masuk akal (Out of Range), batalkan deteksi
   if(atr <= 0 || atr > (current.open * 0.1))
      return false;
   if(avg_volume <= 0)
      avg_volume = 100;

// 3. CORE METRICS CALCULATION
   double range = current.high - current.low;
   if(range <= 0)
      return false;

// Body Ratio: Seberapa solid candle tersebut
   double body_size = MathAbs(current.close - current.open);
   double body_ratio = body_size / range;

// Close Position: Dimana harga tutup relatif terhadap range (Bullish: atas, Bearish: bawah)
   bool is_bullish = (current.close > current.open);
   double close_position = is_bullish ?
                           (current.close - current.low) / range :
                           (current.high - current.close) / range;

// Range Expansion: Membandingkan besar candle sekarang dengan candle sebelumnya
   double prev_range = prev1.high - prev1.low;
   double range_ratio = (prev_range > 0) ? range / prev_range : 1.0;

// 4. ADAPTIVE THRESHOLDS
   double req_vol_multi = GetAdaptiveVolumeMultiplier();
   double req_body      = GetAdaptiveBodyRatio();
   double req_close     = InpClosePosition;

// Adjustment: Jika body sangat kuat (>80%), toleransi close position diperlonggar
   if(body_ratio > 0.8)
      req_close *= 0.9;

// 5. CONDITION CHECKING (The Gauntlet)
   string fail_reason = "";

   if((double)current.tick_volume < (avg_volume * req_vol_multi))
      fail_reason = "Low Volume";
   else
      if(body_ratio < req_body)
         fail_reason = "Weak Body";
      else
         if(close_position < req_close)
            fail_reason = "Poor Close Position";
         else
            if(range_ratio < 1.05)
               fail_reason = "No Range Expansion";
            else
               if(!CheckTrendConfirmation(is_bullish))
                  fail_reason = "Trend Mismatch";

   if(fail_reason != "")
     {
      // Optional: Log hanya jika benar-benar butuh debug untuk hemat performa
      // if(InpDebugMode) Print("Impulse Rejected: ", fail_reason);
      return false;
     }

// 6. SUCCESS: SET IMPULSE STATE
   Impulse.active         = true;
   Impulse.bullish        = is_bullish;
   Impulse.start_bar      = 0;
   Impulse.detection_time = current.time;
   Impulse.detection_price= current.close;
   Impulse.highest_since  = current.high;
   Impulse.lowest_since   = current.low;

// Simpan rasio untuk monitoring decay nanti
   Impulse.volume_ratio   = (double)current.tick_volume / avg_volume;
   Impulse.body_ratio     = body_ratio;
   Impulse.current_multiplier = req_vol_multi;

// Strength Calculation (Normalized 0.0 - 1.0+)
// Kita beri bobot: Volume(40%), Body(30%), ClosePos(30%)
   Impulse.strength = (Impulse.volume_ratio / (req_vol_multi * 2.0) * 0.4) +
                      (body_ratio * 0.3) +
                      (close_position * 0.3);

// Duration: Semakin kuat impuls, semakin lama kita "menahan" ekspektasi setup
   double duration_factor = MathMin(Impulse.strength, 1.0);
   Impulse.expected_bars = (int)MathRound(InpMinImpulseBars + (duration_factor * (InpMaxImpulseBars - InpMinImpulseBars)));

   if(InpDebugMode)
     {
      PrintFormat("ICE DETECTED: %s | Strength: %.2f | Vol Ratio: %.1fx",
                  (is_bullish ? "BULL" : "BEAR"), Impulse.strength, Impulse.volume_ratio);
     }

   return true;
  }

//+------------------------------------------------------------------+
//| Check trend confirmation with MA Slope & Position                |
//+------------------------------------------------------------------+
bool CheckTrendConfirmation(bool is_bullish)
  {
   if(hMA == INVALID_HANDLE)
      return true;

   double ma_buffer[];
   ArraySetAsSeries(ma_buffer, true);

// Kita ambil 3 data untuk menghitung slope (kemiringan) MA
   if(CopyBuffer(hMA, 0, 0, 3, ma_buffer) < 3)
      return true;

   double ma_now  = ma_buffer[0];
   double ma_prev = ma_buffer[1];
   double current_price = SymbolInfoDouble(CurrentSymbol, SYMBOL_BID);

// 1. POSITIONAL FILTER
// Bullish: Harga harus di atas MA (dengan toleransi tipis)
// Bearish: Harga harus di bawah MA (dengan toleransi tipis)
   if(is_bullish && current_price < ma_now)
     {
      if(InpDebugMode)
         Print("ICE Trend Filter: Bullish impulse but price below MA.");
      return false;
     }
   if(!is_bullish && current_price > ma_now)
     {
      if(InpDebugMode)
         Print("ICE Trend Filter: Bearish impulse but price above MA.");
      return false;
     }

// 2. SLOPE FILTER (Momentum)
// Memastikan MA sedang "menanjak" untuk Buy atau "menurun" untuk Sell
// Ini mencegah entry saat MA sedang datar (sideways)
   bool ma_trending_up   = (ma_now > ma_prev);
   bool ma_trending_down = (ma_now < ma_prev);

   if(is_bullish && !ma_trending_up)
     {
      if(InpDebugMode)
         Print("ICE Trend Filter: Bullish impulse but MA slope is not Up.");
      return false;
     }
   if(!is_bullish && !ma_trending_down)
     {
      if(InpDebugMode)
         Print("ICE Trend Filter: Bearish impulse but MA slope is not Down.");
      return false;
     }

   return true;
  }

/* // Pilihan Anda dapat menggunakan Kode Berikut
//+------------------------------------------------------------------+
//| Check if impulse momentum has decayed or reversed                |
//+------------------------------------------------------------------+
bool IsImpulseDecayed()
  {
// 1. DURATION CHECK
// Jika waktu tunggu sudah melebihi batas, impuls dianggap kadaluarsa.
   if(Impulse.start_bar > Impulse.expected_bars)
     {
      if(InpDebugMode)
         PrintFormat("ICE Decay: Duration exceeded (%d > %d bars)", Impulse.start_bar, Impulse.expected_bars);
      return true;
     }

// 2. DATA ACQUISITION
   MqlRates current[];
   ArraySetAsSeries(current, true);
   if(CopyRates(CurrentSymbol, _Period, 0, 1, current) < 1)
      return false;

// 3. PRICE REVERSAL CHECK (Guard Baru)
// Jika harga berbalik menembus 50% dari body candle impuls, momentum dianggap patah.
   double impulse_open = iOpen(CurrentSymbol, _Period, Impulse.start_bar);
   double impulse_close = Impulse.detection_price;
   double mid_point = (impulse_open + impulse_close) / 2.0;

   if(Impulse.bullish && current[0].close < mid_point)
     {
      if(InpDebugMode)
         Print("ICE Decay: Price reversed below 50% of impulse body.");
      return true;
     }
   if(!Impulse.bullish && current[0].close > mid_point)
     {
      if(InpDebugMode)
         Print("ICE Decay: Price reversed above 50% of impulse body.");
      return true;
     }

// 4. VOLUME DECAY CHECK (Adaptive)
   double avg_volume = GetAverageVolume(InpLookbackPeriod);
   if(avg_volume > 0)
     {
      double current_vol_ratio = (double)current[0].tick_volume / avg_volume;

      // Jika volume turun drastis di bawah 30% dari volume impuls asli, market kehilangan minat.
      if(current_vol_ratio < (Impulse.volume_ratio * 0.3))
        {
         if(InpDebugMode)
            PrintFormat("ICE Decay: Volume dropped (%.2fx < %.2fx)", current_vol_ratio, Impulse.volume_ratio * 0.3);
         return true;
        }
     }

   return false;
  }
*/

//+------------------------------------------------------------------+
//|  Fibonacci Golden Ratio Guard                                    |
//+------------------------------------------------------------------+
bool IsImpulseDecayed()
  {
// 1. DURATION CHECK - Increase tolerance
   if(Impulse.start_bar > (Impulse.expected_bars + 2)) // Allow 2 extra bars
     {
      if(InpDebugMode)
         PrintFormat("ICE Decay: Duration exceeded (%d > %d bars)", Impulse.start_bar, Impulse.expected_bars);
      return true;
     }

// 2. DATA ACQUISITION
   MqlRates current[];
   ArraySetAsSeries(current, true);
   if(CopyRates(CurrentSymbol, _Period, 0, 1, current) < 1)
      return false;

// 3. PRICE REVERSAL CHECK - Relax to 61.8% Fibonacci level
   double impulse_open = iOpen(CurrentSymbol, _Period, Impulse.start_bar);
   double impulse_close = Impulse.detection_price;

// Use 61.8% Fibonacci retracement level instead of 50%
   double fib_level = Impulse.bullish ?
                      impulse_close - (impulse_close - impulse_open) * 0.618 :
                      impulse_close + (impulse_open - impulse_close) * 0.618;

   if(Impulse.bullish && current[0].close < fib_level)
     {
      if(InpDebugMode)
         Print("ICE Decay: Price reversed below 61.8% Fibonacci level.");
      return true;
     }
   if(!Impulse.bullish && current[0].close > fib_level)
     {
      if(InpDebugMode)
         Print("ICE Decay: Price reversed above 61.8% Fibonacci level.");
      return true;
     }

// 4. VOLUME DECAY CHECK - Relax threshold
   double avg_volume = GetAverageVolume(InpLookbackPeriod);
   if(avg_volume > 0)
     {
      double current_vol_ratio = (double)current[0].tick_volume / avg_volume;

      // Relax from 30% to 25% of original volume
      if(current_vol_ratio < (Impulse.volume_ratio * 0.25))
        {
         if(InpDebugMode)
            PrintFormat("ICE Decay: Volume dropped significantly (%.2fx < %.2fx)",
                        current_vol_ratio, Impulse.volume_ratio * 0.25);
         return true;
        }
     }

   return false;
  }

/* // Pilihan Anda dapat menggunakan Kode Berikut
//+------------------------------------------------------------------+
//| Check if impulse has decayed with Adaptive Fibonacci Tolerance   |
//+------------------------------------------------------------------+
bool IsImpulseDecayed()
{
   // 1. DURATION CHECK (Aggressive)
   // Memberikan toleransi +2 bar agar EA tidak terburu-buru menghapus setup
   // saat market sedang sideways sebentar.
   if(Impulse.start_bar > (Impulse.expected_bars + 2))
   {
      if(InpDebugMode)
         PrintFormat("ICE Decay: Duration exceeded (%d > %d bars)", Impulse.start_bar, Impulse.expected_bars + 2);
      return true;
   }

   // 2. DATA ACQUISITION
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(CurrentSymbol, _Period, 0, 1, rates) < 1) return false;

   // 3. FIBONACCI GOLDEN RATIO GUARD (61.8%)
   // Mengambil harga Open dari bar saat impuls pertama kali terdeteksi
   double impulse_open = iOpen(CurrentSymbol, _Period, Impulse.start_bar);
   double impulse_close = Impulse.detection_price;
   double range = MathAbs(impulse_close - impulse_open);

   if(range > 0)
   {
      // Menghitung batas toleransi maksimal di 61.8% Retracement
      if(Impulse.bullish)
      {
         double fib_618 = impulse_close - (range * 0.618);
         // Jika harga Bid saat ini jatuh di bawah 61.8% body impuls,
         // maka momentum dianggap gagal/patah.
         if(SymbolInfoDouble(CurrentSymbol, SYMBOL_BID) < fib_618)
         {
            if(InpDebugMode) Print("ICE Decay: Price broke below 61.8% Golden Ratio.");
            return true;
         }
      }
      else // Bearish
      {
         double fib_618 = impulse_close + (range * 0.618);
         // Jika harga Ask saat ini naik di atas 61.8% body impuls
         if(SymbolInfoDouble(CurrentSymbol, SYMBOL_ASK) > fib_618)
         {
            if(InpDebugMode) Print("ICE Decay: Price broke above 61.8% Golden Ratio.");
            return true;
         }
      }
   }

   // 4. VOLUME DECAY CHECK (Relaxed)
   // Kita turunkan ambang batas ke 25% (0.25) agar tidak terlalu sensitif
   // terhadap penurunan volume sesaat di pertengahan bar.
   double avg_volume = GetAverageVolume(InpLookbackPeriod);
   if(avg_volume > 0)
   {
      double current_vol_ratio = (double)rates[0].tick_volume / avg_volume;

      if(current_vol_ratio < (Impulse.volume_ratio * 0.25))
      {
         // Tambahan: Hanya anggap decay jika bar sudah berjalan minimal 50%
         // (untuk menghindari false alert di awal pembukaan candle)
         if(InpDebugMode)
            PrintFormat("ICE Decay: Momentum lost (Vol Ratio: %.2f)", current_vol_ratio);
         return true;
      }
   }

   return false;
}
*/

//+------------------------------------------------------------------+
//| Monitor impulse                                                  |
//+------------------------------------------------------------------+
void MonitorImpulse()
  {
   Impulse.start_bar++;

//--- Update high/low
   double current_high = iHigh(CurrentSymbol, _Period, 0);
   double current_low = iLow(CurrentSymbol, _Period, 0);

   if(current_high > Impulse.highest_since)
      Impulse.highest_since = current_high;
   if(current_low < Impulse.lowest_since)
      Impulse.lowest_since = current_low;

//--- Check for decay
   if(IsImpulseDecayed())
     {
      if(InpDebugMode)
         Print("Impulse decayed after ", Impulse.start_bar, " bars");
      ResetImpulse();
     }
  }

/* // Pilihan Anda dapat menggunakan Kode Berikut
//+------------------------------------------------------------------+
//| Check entry conditions - MORE AGGRESSIVE                        |
//+------------------------------------------------------------------+
bool CheckEntryConditions()
  {
//--- Wait minimal time after detection
   if(Impulse.start_bar < 1)
     {
      if(InpDebugMode)
         Print("Waiting for entry setup (bar ", Impulse.start_bar, ")");
      return false;
     }

//--- Get current bar
   MqlRates current;
   if(!GetCurrentBar(current))
      return false;

//--- SIMPLE ENTRY: Enter if still in impulse direction
   if(Impulse.bullish)
     {
      // For bullish: Allow small pullbacks but not strong bearish bars
      double body_ratio = MathAbs(current.close - current.open) / (current.high - current.low);
      if(body_ratio > 0.6 && current.close < current.open)
        {
         // Too strong bearish reversal
         if(InpDebugMode)
            Print("Rejection: Strong bearish bar in bullish impulse");
         return false;
        }

      // Price should not drop below impulse low
      if(current.close < Impulse.lowest_since * 0.9995)
        {
         if(InpDebugMode)
            Print("Rejection: Price below impulse low");
         return false;
        }
     }
   else
     {
      // For bearish: Allow small bounces but not strong bullish bars
      double body_ratio = MathAbs(current.close - current.open) / (current.high - current.low);
      if(body_ratio > 0.6 && current.close > current.open)
        {
         // Too strong bullish reversal
         if(InpDebugMode)
            Print("Rejection: Strong bullish bar in bearish impulse");
         return false;
        }

      // Price should not rise above impulse high
      if(current.close > Impulse.highest_since * 1.0005)
        {
         if(InpDebugMode)
            Print("Rejection: Price above impulse high");
         return false;
        }
     }

   return true;
  }

bool CheckEntryConditions()
{
    //--- Remove the strict bar count requirement
    // Instead of waiting for specific bar count, check if we have valid setup

    //--- Get current bar
    MqlRates current;
    if(!GetCurrentBar(current))
        return false;

    //--- Check if impulse is still valid
    if(Impulse.start_bar > Impulse.expected_bars)
    {
        if(InpDebugMode)
            Print("Impulse expired - no entry");
        ResetImpulse();
        return false;
    }

    //--- SIMPLE ENTRY: Enter on next bar after detection
    // For bullish: enter on pullback or continuation
    if(Impulse.bullish)
    {
        // Option 1: Enter immediately on next bar if still bullish
        if(current.close > current.open && current.close > Impulse.detection_price)
        {
            return true;
        }

        // Option 2: Enter on small pullback
        double pullback_ratio = (current.close - Impulse.lowest_since) / (Impulse.highest_since - Impulse.lowest_since);
        if(pullback_ratio >= 0.3 && pullback_ratio <= 0.7)
        {
            return true;
        }
    }
    else // Bearish
    {
        // Option 1: Enter immediately on next bar if still bearish
        if(current.close < current.open && current.close < Impulse.detection_price)
        {
            return true;
        }

        // Option 2: Enter on small retracement
        double retrace_ratio = (Impulse.highest_since - current.close) / (Impulse.highest_since - Impulse.lowest_since);
        if(retrace_ratio >= 0.3 && retrace_ratio <= 0.7)
        {
            return true;
        }
    }

    return false;
}
*/

//+------------------------------------------------------------------+
//| Check entry conditions - Optimized for Adaptive Risk Taking      |
//+------------------------------------------------------------------+
bool CheckEntryConditions()
  {
// 1. DATA SYNC
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(CurrentSymbol, _Period, 0, 2, rates) < 2)
      return false;

   double current_bid = SymbolInfoDouble(CurrentSymbol, SYMBOL_BID);
   double current_ask = SymbolInfoDouble(CurrentSymbol, SYMBOL_ASK);

// 2. EXPIRATION GUARD (Berikan sedikit ruang ekstra)
   if(Impulse.start_bar > (Impulse.expected_bars + 1))
     {
      if(InpDebugMode)
         Print("ICE Info: Opportunity window expired.");
      ResetImpulse();
      return false;
     }

   if(!Impulse.active)
      return false;

// 3. LOGIKA ENTRY ADAPTIF
   if(Impulse.bullish)
     {
      // --- SKENARIO A: AGGRESSIVE CONTINUATION (Breakout) ---
      if(current_bid >= Impulse.highest_since)
        {
         if(InpDebugMode)
            Print("ICE Entry: Bullish Breakout!");
         return true;
        }

      // --- SKENARIO B: SMART PULLBACK (Disiplin Fibonacci) ---
      double range = Impulse.highest_since - Impulse.lowest_since;
      if(range > 0)
        {
         double pullback_level = (Impulse.highest_since - current_bid) / range;

         // Ambil risiko: Jika harga sudah diskon (min 20%) dan ada tanda pantulan
         if(pullback_level >= 0.20 && pullback_level <= 0.65) // Sedikit lebih longgar dari 61.8
           {
            if(rates[0].close > rates[0].open || current_bid > rates[1].high)
              {
               if(InpDebugMode)
                  PrintFormat("ICE Entry: Pullback Buy at %.2f level", pullback_level);
               return true;
              }
           }
        }

      // --- SKENARIO C: MOMENTUM ACCELERATION (NEW) ---
      // Jika harga bergerak cepat searah impuls meski belum breakout
      if(rates[0].close > rates[1].high && (double)rates[0].tick_volume > (GetAverageVolume(InpLookbackPeriod) * 0.8))
        {
         if(InpDebugMode)
            Print("ICE Entry: Bullish Velocity detected.");
         return true;
        }
     }
   else // BEARISH
     {
      // --- SKENARIO A: AGGRESSIVE CONTINUATION ---
      if(current_ask <= Impulse.lowest_since)
        {
         if(InpDebugMode)
            Print("ICE Entry: Bearish Breakout!");
         return true;
        }

      // --- SKENARIO B: SMART PULLBACK ---
      double range = Impulse.highest_since - Impulse.lowest_since;
      if(range > 0)
        {
         double retrace_level = (current_ask - Impulse.lowest_since) / range;

         if(retrace_level >= 0.20 && retrace_level <= 0.65)
           {
            if(rates[0].close < rates[0].open || current_ask < rates[1].low)
              {
               if(InpDebugMode)
                  PrintFormat("ICE Entry: Retrace Sell at %.2f level", retrace_level);
               return true;
              }
           }
        }

      // --- SKENARIO C: MOMENTUM ACCELERATION (NEW) ---
      if(rates[0].close < rates[1].low && (double)rates[0].tick_volume > (GetAverageVolume(InpLookbackPeriod) * 0.8))
        {
         if(InpDebugMode)
            Print("ICE Entry: Bearish Velocity detected.");
         return true;
        }
     }

   return false;
  }

/* // Pilihan Anda dapat menggunakan Kode Berikut
//+------------------------------------------------------------------+
//| Check entry conditions - Menggunakan Global Market State         |
//+------------------------------------------------------------------+
bool CheckEntryConditions()
{
   // 1. DATA SYNC
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   // Ambil 2 bar: Index 0 (running), Index 1 (setup bar)
   if(CopyRates(CurrentSymbol, _Period, 0, 2, rates) < 2) return false;

   // Kita pastikan harga Bid/Ask terbaru sudah terupdate di struct Market
   double current_bid = SymbolInfoDouble(CurrentSymbol, SYMBOL_BID);
   double current_ask = SymbolInfoDouble(CurrentSymbol, SYMBOL_ASK);

   // 2. EXPIRATION GUARD
   if(Impulse.start_bar > Impulse.expected_bars)
   {
      if(InpDebugMode) Print("ICE Info: Opportunity window expired.");
      ResetImpulse();
      return false;
   }

   // 3. ADAPTIVE ENTRY LOGIC
   if(Impulse.active)
   {
      if(Impulse.bullish)
      {
         // --- SKENARIO A: AGGRESSIVE CONTINUATION (Breakout) ---
         // Jika harga Bid menembus High candle impuls
         if(current_bid > Impulse.highest_since)
         {
            if(InpDebugMode) Print("ICE Entry: Bullish Continuation detected.");
            return true;
         }

         // --- SKENARIO B: SMART PULLBACK (Retracement) ---
         double range = Impulse.highest_since - Impulse.lowest_since;
         if(range > 0)
         {
            double pullback_level = (Impulse.highest_since - current_bid) / range;

            // Masuk di area diskon 20% - 61.8% saat candle running mulai Bullish
            if(pullback_level >= 0.20 && pullback_level <= 0.618)
            {
               if(rates[0].close > rates[0].open)
               {
                  if(InpDebugMode) PrintFormat("ICE Entry: Bullish Pullback (Level: %.2f)", pullback_level);
                  return true;
               }
            }
         }
      }
      else // BEARISH
      {
         // --- SKENARIO A: AGGRESSIVE CONTINUATION (Breakout) ---
         // Jika harga Ask menembus Low candle impuls
         if(current_ask < Impulse.lowest_since)
         {
            if(InpDebugMode) Print("ICE Entry: Bearish Continuation detected.");
            return true;
         }

         // --- SKENARIO B: SMART PULLBACK (Retracement) ---
         double range = Impulse.highest_since - Impulse.lowest_since;
         if(range > 0)
         {
            double retrace_level = (current_ask - Impulse.lowest_since) / range;

            if(retrace_level >= 0.20 && retrace_level <= 0.618)
            {
               if(rates[0].close < rates[0].open)
               {
                  if(InpDebugMode) PrintFormat("ICE Entry: Bearish Retrace (Level: %.2f)", retrace_level);
                  return true;
               }
            }
         }
      }
   }

   return false;
}
*/

/* // Pilihan Anda dapat menggunakan Kode Berikut
//+------------------------------------------------------------------+
//| Execute trade dengan trailing consideration                     |
//+------------------------------------------------------------------+
void ExecuteTrade()
  {
   double atr = GetATRValue();
// KILL SWITCH: Jika saat eksekusi ATR tiba-tiba tidak valid, batalkan semua.
   if(atr <= 0 || atr > (SymbolInfoDouble(CurrentSymbol, SYMBOL_BID) * 0.1))
     {
      Print("ICE Critical: Trade aborted due to abnormal ATR value during execution.");
      ResetImpulse(); // Bersihkan state agar tidak mencoba entry terus menerus
      return;
     }

//--- Calculate prices
   double entry_price, sl_price, tp_price;

   if(Impulse.bullish)
     {
      entry_price = MarketAsk;
      sl_price = entry_price - (atr * InpATRMultiplierSL);
      tp_price = entry_price + (atr * InpATRMultiplierTP);
     }
   else
     {
      entry_price = MarketBid;
      sl_price = entry_price + (atr * InpATRMultiplierSL);
      tp_price = entry_price - (atr * InpATRMultiplierTP);
     }

//--- Normalize prices
   entry_price = NormalizePrice(entry_price);
   sl_price = NormalizePrice(sl_price);
   tp_price = NormalizePrice(tp_price);

//--- Validate stops
   double min_distance = StopsLevel * SymbolPoint;
   if(MathAbs(entry_price - sl_price) < min_distance)
     {
      Print("ERROR: SL too close to entry");
      return;
     }

//--- Calculate lot size
   double sl_distance = MathAbs(entry_price - sl_price);
   double lot_size = CalculateLotSize(sl_distance);

   if(lot_size <= 0)
     {
      Print("ERROR: Invalid lot size");
      return;
     }

//--- Adjust TP for trailing system
   if(InpTrailingMode != TRAIL_NONE)
     {
      // Set TP farther to allow room for trailing
      if(Impulse.bullish)
        {
         tp_price = entry_price + (atr * InpATRMultiplierTP * 1.2);
        }
      else
        {
         tp_price = entry_price - (atr * InpATRMultiplierTP * 1.2);
        }
      tp_price = NormalizePrice(tp_price);
     }

//--- Execute trade
   bool success = false;

   if(Impulse.bullish)
     {
      success = Trade.Buy(lot_size, CurrentSymbol, entry_price, sl_price, tp_price, InpTradeComment);
     }
   else
     {
      success = Trade.Sell(lot_size, CurrentSymbol, entry_price, sl_price, tp_price, InpTradeComment);
     }

   if(success)
     {
      Print("TRADE EXECUTED: ",
            Impulse.bullish ? "BUY" : "SELL",
            " | Lot: ", lot_size,
            " | Entry: ", entry_price,
            " | SL: ", sl_price,
            " | TP: ", tp_price,
            " | Trailing: ", EnumToString(InpTrailingMode));

      ResetImpulse();
     }
   else
     {
      Print("TRADE FAILED: ", Trade.ResultRetcodeDescription());
     }
  }
*/

//+------------------------------------------------------------------+
//| Execute trade dengan proteksi margin dan validasi presisi        |
//+------------------------------------------------------------------+
void ExecuteTrade()
  {
// 1. DATA VALIDATION (ATR & Account Safety)
   double atr = GetATRValue();
   if(atr <= 0 || atr > (SymbolInfoDouble(CurrentSymbol, SYMBOL_BID) * 0.1) || !IsAccountSafe())
     {
      Print("ICE Critical: Trade aborted. Abnormal market/account conditions.");
      ResetImpulse();
      return;
     }

// 2. INITIAL PRICE CALCULATION
   double entry_price = (Impulse.bullish) ? MarketAsk : MarketBid;
   double sl_dist = atr * InpATRMultiplierSL;
   double tp_dist = atr * InpATRMultiplierTP;

// Sesuaikan TP jika Trailing aktif (Memberikan ruang untuk profit besar)
   if(InpTrailingMode != TRAIL_NONE)
      tp_dist *= 1.2;

   double sl_price = (Impulse.bullish) ? (entry_price - sl_dist) : (entry_price + sl_dist);
   double tp_price = (Impulse.bullish) ? (entry_price + tp_dist) : (entry_price - tp_dist);

// Normalize agar sesuai digit broker (e.g., 5 digit)
   entry_price = NormalizePrice(entry_price);
   sl_price    = NormalizePrice(sl_price);
   tp_price    = NormalizePrice(tp_price);

// 3. LOT SIZE & MARGIN CHECK (Mencegah error 'No Money')
   double sl_points = MathAbs(entry_price - sl_price) / SymbolPoint;
   double lot_size  = CalculateLotSize(sl_points * SymbolPoint);

   if(lot_size <= 0)
     {
      Print("ICE Error: Lot calculation failed. Lot: ", lot_size);
      ResetImpulse();
      return;
     }

// Lapis Keamanan: Cek apakah margin cukup untuk lot ini
   double margin_req = 0;
   ENUM_ORDER_TYPE type = (Impulse.bullish) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   if(!OrderCalcMargin(type, CurrentSymbol, lot_size, entry_price, margin_req))
      return;

// MENGGUNAKAN ACCOUNT_MARGIN_FREE (Standar Terbaru)
   double free_margin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

   if(margin_req > free_margin)
     {
      PrintFormat("ICE Error: Insufficient Margin. Req: %.2f | Free: %.2f", margin_req, free_margin);
      ResetImpulse();
      return;
     }

// 4. STOP LEVEL COMPLIANCE (Disiplin Broker)
   double min_dist = (double)SymbolInfoInteger(CurrentSymbol, SYMBOL_TRADE_STOPS_LEVEL) * SymbolPoint;
   if(MathAbs(entry_price - sl_price) < min_dist || MathAbs(entry_price - tp_price) < min_dist)
     {
      Print("ICE Error: SL/TP too close to StopsLevel. Adjusting to minimum...");
      // Auto-adjustment jika terlalu dekat (Opsional, atau bisa return false)
     }

// 5. EXECUTION
   bool success = false;
   if(Impulse.bullish)
      success = Trade.Buy(lot_size, CurrentSymbol, entry_price, sl_price, tp_price, InpTradeComment);
   else
      success = Trade.Sell(lot_size, CurrentSymbol, entry_price, sl_price, tp_price, InpTradeComment);

// 6. POST-TRADE LOGGING & CLEANUP
   if(success)
     {
      uint retcode = Trade.ResultRetcode();
      if(retcode == TRADE_RETCODE_DONE || retcode == TRADE_RETCODE_PLACED)
        {
         PrintFormat("TRADE EXECUTED: %s | Lot: %.2f | SL: %.5f | TP: %.5f | Type: %s",
                     (Impulse.bullish ? "BUY" : "SELL"), lot_size, sl_price, tp_price, EnumToString(InpTrailingMode));
         ResetImpulse(); // Bersihkan agar tidak double entry
        }
     }
   else
     {
      Print("TRADE FAILED: ", Trade.ResultRetcodeDescription(), " Code: ", Trade.ResultRetcode());
      // Jika gagal karena harga berubah (Requote), kita tidak ResetImpulse agar bisa coba lagi di tick berikutnya
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateLotSize(double sl_distance)
  {
// 1. Sanity Check: Jika SL distance tidak masuk akal (efek ATR out of range)
// Kita batasi maksimal SL adalah 2% dari harga saat ini (misal untuk Forex)
   double current_price = SymbolInfoDouble(CurrentSymbol, SYMBOL_BID);
   double max_sl_allowed = current_price * 0.02;

   if(sl_distance <= 0 || sl_distance > max_sl_allowed)
     {
      PrintFormat("ICE Error: Abnormal SL Distance detected (%.5f). Lot calculation aborted.", sl_distance);
      return 0;
     }

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_amount = balance * (InpRiskPerTrade / 100.0);

   if(TickSize <= 0 || TickValue <= 0)
     {
      Print("ICE Error: Invalid tick properties.");
      return 0;
     }

// 2. Kalkulasi Risk
   double risk_per_lot = (sl_distance / TickSize) * TickValue;

   if(risk_per_lot <= 0)
      return 0;

   double lots = risk_amount / risk_per_lot;

// 3. Normalisasi & Batasan Broker
   lots = MathFloor(lots / LotStep) * LotStep;

   if(lots < MinLot)
     {
      if(InpDebugMode)
         Print("ICE Info: Calculated lot below MinLot. Using MinLot.");
      lots = MinLot;
     }

   if(lots > MaxLot)
      lots = MaxLot;

   return lots;
  }

//+------------------------------------------------------------------+
//| Get ATR Value with Sanity Check & Sync Guard                     |
//+------------------------------------------------------------------+
double GetATRValue()
  {
   if(hATR == INVALID_HANDLE)
      return 0.0;

// 1. GUARD: Pastikan indikator sudah selesai menghitung data history
// BarsCalculated mengembalikan jumlah bar yang sudah dihitung oleh indikator
   if(BarsCalculated(hATR) < InpLookbackPeriod)
     {
      if(InpDebugMode)
         Print("ICE Pro: ATR is still calculating...");
      return 0.0;
     }

   double buffer[];
   ArraySetAsSeries(buffer, true);

// 2. GUARD: CopyBuffer dengan penanganan error sinkronisasi
   ResetLastError();
   if(CopyBuffer(hATR, 0, 1, 1, buffer) < 1)
     {
      // Jika error 4806 (Data not synchronized), EA akan mencoba lagi tick berikutnya
      return 0.0;
     }

   double raw_atr = buffer[0];

// 3. SANITY CHECK: Validasi apakah nilai ATR masuk akal
// Mengatasi masalah "ATR Out of Range" seperti 1.75805 pada Forex

// A. Cek apakah ATR bernilai 0 atau NaN (Not a Number)
   if(raw_atr <= 0 || MathIsValidNumber(raw_atr) == false)
      return 0.0;

// B. Cek apakah ATR lebih besar dari harga saat ini (Kondisi Mustahil)
// Jika ATR > 10% dari harga saat ini, kemungkinan besar data indikator rusak/ngaco
   double current_price = SymbolInfoDouble(CurrentSymbol, SYMBOL_BID);
   if(current_price > 0 && raw_atr > (current_price * 0.1))
     {
      if(InpDebugMode)
         PrintFormat("ICE Guard: Abnormal ATR detected (%.5f). Waiting for data sync...", raw_atr);
      return 0.0;
     }

   return raw_atr;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetAverageVolume(int period)
  {
   long volumes[];
   ArraySetAsSeries(volumes, true);

// Validasi jumlah bar yang tersedia di terminal
   int available = Bars(CurrentSymbol, _Period);
   int fetch = MathMin(period, available - 1);

   if(fetch <= 0)
      return 0.0;

   if(CopyTickVolume(CurrentSymbol, _Period, 1, fetch, volumes) < fetch)
      return 0.0;

   double sum = 0;
   for(int i = 0; i < fetch; i++)
      sum += (double)volumes[i];
   return sum / fetch;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool GetCurrentBar(MqlRates &rate)
  {
   MqlRates buffer[];
   ArraySetAsSeries(buffer, true);

   if(CopyRates(CurrentSymbol, _Period, 0, 1, buffer) < 1)
      return false;
   rate = buffer[0];
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NormalizePrice(double price)
  {
   return NormalizeDouble(price, SymbolDigits);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ResetImpulse()
  {
   ZeroMemory(Impulse);
   Impulse.active = false;
  }

//+------------------------------------------------------------------+
//| Update dashboard with trailing info                             |
//+------------------------------------------------------------------+
void UpdateDashboard()
  {
   string session_name = GetSessionName(current_session);
   string trailing_status = EnumToString(InpTrailingMode);

   string dashboard =
      "─── RITZ ICE Pro ───\n" +
      "Symbol: " + CurrentSymbol + "\n" +
      "Session: " + session_name + " | Trailing: " + trailing_status + "\n" +
      "Time: " + TimeToString(TimeCurrent(), TIME_SECONDS) + "\n" +
      "Bid/Ask: " + DoubleToString(MarketBid, SymbolDigits) +
      "/" + DoubleToString(MarketAsk, SymbolDigits) + "\n" +
      "Spread: " + DoubleToString(MarketSpread, 1) + " pts\n" +
      "ATR: " + DoubleToString(GetATRValue(), SymbolDigits) + "\n\n";

//--- Show open positions info
   int open_positions = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(Position.SelectByIndex(i))
        {
         if(Position.Symbol() == CurrentSymbol && Position.Magic() == InpMagicNumber)
           {
            open_positions++;
            double profit = Position.Profit();
            double sl = Position.StopLoss();
            double tp = Position.TakeProfit();
            double current = (Position.PositionType() == POSITION_TYPE_BUY) ? MarketBid : MarketAsk;
            double entry = Position.PriceOpen();

            dashboard += "Position #" + IntegerToString(Position.Ticket()) +
                         ": " + (Position.PositionType() == POSITION_TYPE_BUY ? "BUY" : "SELL") + "\n" +
                         "   P/L: $" + DoubleToString(profit, 2) +
                         " | Entry: " + DoubleToString(entry, SymbolDigits) +
                         " | Current: " + DoubleToString(current, SymbolDigits) + "\n" +
                         "   SL: " + (sl > 0 ? DoubleToString(sl, SymbolDigits) : "None") +
                         " | TP: " + (tp > 0 ? DoubleToString(tp, SymbolDigits) : "None") + "\n";
           }
        }
     }

   if(open_positions == 0)
     {
      dashboard += "─── NO OPEN POSITIONS ───\n";
     }

   if(Impulse.active)
     {
      dashboard +=
         "\n─── IMPULSE ACTIVE ───\n" +
         "Direction: " + (Impulse.bullish ? "BULLISH ▲" : "BEARISH ▼") + "\n" +
         "Strength: " + DoubleToString(Impulse.strength, 2) + "\n" +
         "Duration: " + IntegerToString(Impulse.start_bar) + "/" +
         IntegerToString(Impulse.expected_bars) + " bars\n";
     }
   else
     {
      dashboard += "\n─── WAITING FOR IMPULSE ───\n";
     }

   dashboard += "──────────────────────────";

   Comment(dashboard);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnImpulseDetected()
  {
   double current_atr = GetATRValue();

// Validasi Terakhir: Jika ATR tiba-tiba tidak valid saat event ini dipicu
   if(current_atr <= 0)
     {
      Print("ICE Warning: Impulse discarded due to invalid ATR data sync.");
      ResetImpulse();
      return;
     }

   Print("──────────────────────────────────");
   Print("RITZ ICE IMPULSE DETECTED!");
   Print("Time: ", TimeToString(TimeCurrent()));
   Print("Direction: ", Impulse.bullish ? "BULLISH ▲" : "BEARISH ▼");
   Print("Strength: ", DoubleToString(Impulse.strength, 2));
   Print("ATR Context: ", DoubleToString(current_atr, SymbolDigits)); // Tambahkan log ATR
   Print("Expected Duration: ", Impulse.expected_bars, " bars");
   Print("──────────────────────────────────");
  }

//+------------------------------------------------------------------+
//| Helper functions                                                 |
//+------------------------------------------------------------------+
string GetReasonText(int reason)
  {
   switch(reason)
     {
      case REASON_ACCOUNT:
         return "Account changed";
      case REASON_CHARTCHANGE:
         return "Chart changed";
      case REASON_CHARTCLOSE:
         return "Chart closed";
      case REASON_PARAMETERS:
         return "Parameters changed";
      case REASON_RECOMPILE:
         return "Code recompiled";
      case REASON_REMOVE:
         return "EA removed";
      case REASON_TEMPLATE:
         return "Template changed";
      default:
         return "Unknown reason";
     }
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                    Quantum_Follower.mq5                          |
//|              Development & Research Base Version                 |
//|                                                                  |
//|  Copyright ©2026. Ritz EAneha                                    |
//|  https://www.mql5.com/en/users/ritzfalih/seller                  |
//+------------------------------------------------------------------+
#property copyright "Copyright©2026. Ritz EAneha"
#property link      "https://www.mql5.com/en/users/ritzfalih/seller"
#property version   "1.2"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| DEVELOPMENT AND RESEARCH PURPOSES                                |
//+------------------------------------------------------------------+
//| This source code is provided for development, research,          |
//| learning, and educational purposes.                              |
//|                                                                  |
//| The original entry concept remains intentionally simple:         |
//| Parabolic SAR direction following.                               |
//|                                                                  |
//| Additional protection and execution controls have been added     |
//| without changing the core entry signal logic.                    |
//|                                                                  |
//| This EA is not a guaranteed profitable trading system and should |
//| not be considered production-ready without further development,  |
//| testing, validation, and optimization.                           |
//|                                                                  |
//| Trading financial markets involves substantial financial risk.   |
//| Users are solely responsible for their trading decisions and     |
//| any consequences resulting from the use or modification of this  |
//| source code.                                                     |
//+------------------------------------------------------------------+

input group "=== TRADE SETTINGS ==="
input double   InpLotSize       = 0.01;        // Fixed trading lot size
input ulong    InpMagicNumber   = 20260831;    // EA Magic Number
input int      InpDeviation     = 20;          // Maximum price deviation (points)

input group "=== MARKET FILTER ==="
input int      InpMaxSpread     = 200;         // Maximum entry spread (points)
input int      InpStartHour     = 2;           // Trading start hour
input int      InpEndHour       = 22;          // Trading end hour

input group "=== QUANTUM / SAR ENGINE ==="
input double   InpSarStep       = 0.02;        // Parabolic SAR step
input double   InpSarMax        = 0.2;         // Parabolic SAR maximum

input group "=== OPTIONAL PROTECTION ==="
input int      InpStopLossPoints = 0;          // Stop Loss (points, 0 = disabled)
input int      InpTakeProfitPoints = 0;        // Take Profit (points, 0 = disabled)

CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;

int            sarHandle = INVALID_HANDLE;
double         ExtLotSize; // Global variable for Auto-Corrected Lot Size

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   if(!symInfo.Name(_Symbol)) return(INIT_FAILED);
   symInfo.Refresh();
   sarHandle = iSAR(_Symbol, _Period, InpSarStep, InpSarMax);
   if(sarHandle == INVALID_HANDLE) return(INIT_FAILED);
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(InpDeviation);
   trade.SetTypeFillingBySymbol(_Symbol);
   // Auto-Correct Lot Size
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   ExtLotSize = InpLotSize;
   if(minLot > 0 && ExtLotSize < minLot) ExtLotSize = minLot;
   if(maxLot > 0 && ExtLotSize > maxLot) ExtLotSize = maxLot;
   if(lotStep > 0) ExtLotSize = MathRound(ExtLotSize / lotStep) * lotStep;
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(sarHandle != INVALID_HANDLE) {
      IndicatorRelease(sarHandle);
      sarHandle = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
//| Helper: Check if Free Margin is enough for the trade             |
//+------------------------------------------------------------------+
bool CheckMarginForTrade(ENUM_ORDER_TYPE order_type, double volume, double price)
{
   double margin_required = 0.0;
   // Hitung berapa margin (uang) yang dibutuhkan untuk membuka posisi ini
   if(!OrderCalcMargin(order_type, _Symbol, volume, price, margin_required)) {
      return false; // Gagal menghitung margin
   }
   // Apakah sisa uang di akun (Free Margin) cukup?
   if(AccountInfoDouble(ACCOUNT_MARGIN_FREE) <= margin_required) {
      return false; // Tidak cukup uang, abaikan eksekusi (Mencegah log spam "Not enough money")
   }
   return true;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
// 1. CHECK BROKER OPERATING HOURS
   MqlDateTime time;
   TimeCurrent(time);
   if(time.hour < InpStartHour || time.hour >= InpEndHour)
      return;
// 2. CHECK MARKET SPREAD
   if(!symInfo.RefreshRates()) return;
   if(symInfo.Spread() > InpMaxSpread)
      return;
// 3. READ PARABOLIC SAR
   double sarArray[];
   double closeArray[];
   ArraySetAsSeries(sarArray, true);
   ArraySetAsSeries(closeArray, true);
   if(CopyBuffer(sarHandle, 0, 0, 2, sarArray) < 2) return;
   if(CopyClose(_Symbol, _Period, 0, 2, closeArray) < 2) return;
// 4. ORIGINAL QUANTUM DIRECTION LOGIC
   bool isQuantumUp = (closeArray[0] > sarArray[0]);
   bool isQuantumDn = (closeArray[0] < sarArray[0]);
// 5. CHECK CURRENT EA POSITIONS
   bool hasBuy  = false;
   bool hasSell = false;
   ulong buyTicket  = 0;
   ulong sellTicket = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(!posInfo.SelectByIndex(i)) continue;
      if(posInfo.Symbol() != _Symbol) continue;
      if((ulong)posInfo.Magic() != InpMagicNumber) continue;
      ENUM_POSITION_TYPE positionType = posInfo.PositionType();
      if(positionType == POSITION_TYPE_BUY) {
         hasBuy = true;
         buyTicket = posInfo.Ticket();
      } else if(positionType == POSITION_TYPE_SELL) {
         hasSell = true;
         sellTicket = posInfo.Ticket();
      }
   }
// 6. SELL / BEARISH FLOW
   if(isQuantumDn) {
      if(hasBuy) {
         if(trade.PositionClose(buyTicket)) hasBuy = false;
      }
      if(!hasSell) OpenSell();
   }
// 7. BUY / BULLISH FLOW
   else if(isQuantumUp) {
      if(hasSell) {
         if(trade.PositionClose(sellTicket)) hasSell = false;
      }
      if(!hasBuy) OpenBuy();
   }
}

//+------------------------------------------------------------------+
//| Execution: BUY                                                   |
//+------------------------------------------------------------------+
bool OpenBuy()
{
   double ask = symInfo.Ask();
   if(ask <= 0) return false;
   double sl = 0.0, tp = 0.0;
   if(InpStopLossPoints > 0) sl = ask - (InpStopLossPoints * _Point);
   if(InpTakeProfitPoints > 0) tp = ask + (InpTakeProfitPoints * _Point);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if(sl > 0) sl = NormalizeDouble(sl, digits);
   if(tp > 0) tp = NormalizeDouble(tp, digits);
   // --- MQL5 VALIDATOR FIX: Cek apakah margin cukup sebelum menembak order ---
   if(!CheckMarginForTrade(ORDER_TYPE_BUY, ExtLotSize, ask))
      return false; // Jangan menyepam server jika margin kurang
   bool result = trade.Buy(ExtLotSize, _Symbol, 0.0, sl, tp, "Quantum Follower BUY");
   return result;
}

//+------------------------------------------------------------------+
//| Execution: SELL                                                  |
//+------------------------------------------------------------------+
bool OpenSell()
{
   double bid = symInfo.Bid();
   if(bid <= 0) return false;
   double sl = 0.0, tp = 0.0;
   if(InpStopLossPoints > 0) sl = bid + (InpStopLossPoints * _Point);
   if(InpTakeProfitPoints > 0) tp = bid - (InpTakeProfitPoints * _Point);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   if(sl > 0) sl = NormalizeDouble(sl, digits);
   if(tp > 0) tp = NormalizeDouble(tp, digits);
   // --- MQL5 VALIDATOR FIX: Cek apakah margin cukup sebelum menembak order ---
   if(!CheckMarginForTrade(ORDER_TYPE_SELL, ExtLotSize, bid))
      return false; // Jangan menyepam server jika margin kurang
   bool result = trade.Sell(ExtLotSize, _Symbol, 0.0, sl, tp, "Quantum Follower SELL");
   return result;
}



/*
//+------------------------------------------------------------------+
//|  2026/08/31 (GMT) +7 | 15:52                                     |
//|  This EA can be further developed with advanced trading, risk,   |
//|  and market-analysis capabilities, including:                    |
//|                                                                  |
//|  1.  Stop Loss and Take Profit management                        |
//|  2.  Money and position management                               |
//|  3.  Risk-based and adaptive position sizing                     |
//|  4.  Trailing Stop and Break-Even protection                     |
//|  5.  Market session and trading-hour filters                     |
//|  6.  Symbol-specific trading conditions                          |
//|  7.  Higher-timeframe trend confirmation                         |
//|  8.  Spread, volatility, and liquidity filters                   |
//|  9.  Drawdown, exposure, and daily risk limits                   |
//| 10.  Advanced entry and exit confirmation                        |
//| 11.  Multi-position, grid, layering, and recovery management     |
//| 12.  Dynamic SL/TP based on ATR and market volatility            |
//| 13.  Market regime detection and adaptive strategy logic         |
//| 14.  Price action and market-structure analysis                  |
//| 15.  Support, resistance, liquidity, and breakout analysis       |
//| 16.  Momentum, trend, reversal, and volatility detection         |
//| 17.  Economic news and fundamental-event filters                 |
//| 18.  AI-assisted market analysis and decision support            |
//| 19.  Machine Learning-based signal classification                |
//| 20.  Online learning and adaptive parameter optimization         |
//| 21.  Predictive models for trend, volatility, and market regime  |
//| 22.  Feature engineering and statistical market analysis         |
//| 23.  AI-based trade scoring and signal confidence                |
//| 24.  Dynamic risk adjustment based on market conditions          |
//| 25.  Reinforcement Learning and adaptive decision systems        |
//| 26.  External AI/ML integration through APIs or local services   |
//| 27.  Trade logging, analytics, and performance monitoring        |
//| 28.  Automated parameter optimization and calibration            |
//| 29.  Backtesting, forward testing, and walk-forward validation   |
//| 30.  Monte Carlo simulation and robustness analysis              |
//| 31.  Execution optimization, slippage control, and order routing |
//| 32.  Multi-symbol and portfolio-level risk management            |
//| 33.  Correlation and cross-market analysis                       |
//| 34.  Fail-safe mechanisms and emergency risk controls            |
//| 35.  Custom dashboards, alerts, and real-time monitoring         |
//| 36.  Additional trading, analytical, and risk-management logic   |
//|      according to the required strategy and market conditions.   |
//|                                                                  |
//|  These capabilities can be implemented independently or combined |
//|  to create a more adaptive, intelligent, and robust trading      |
//|  architecture.                                                   |
//|                                                                  |
//|  Always validate new features through rigorous backtesting,      |
//|  forward testing, and out-of-sample analysis before deploying    |
//|  them in a live trading environment.                             |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|     Simple Code                             Quantum_Follower.mq5 |
//|                                     "Mengikuti Kehendak Kuantum" |
//+------------------------------------------------------------------+
#property copyright "Copyright©2026. Ritz EAneha"
#property link      "https://www.mql5.com/en/users/ritzfalih/seller"
#property version   "1.0"
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

input double   InpLotSize     = 0.01;       // Lot Size (Money Management)
input int      InpMaxSpread   = 200;         // Maximum entry spread (points)
input int      InpStartHour   = 2;          // Trading start time (Avoid overnight spreads)
input int      InpEndHour     = 22;         // Trading halt time
input double   InpSarStep     = 0.02;       // Quantum Logic Sensitivity (SAR Step)
input double   InpSarMax      = 0.2;        // Maximum Sensitivity Limit (Max SAR)

CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;
int            sarHandle;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   symInfo.Name(_Symbol);
   // Reading the pulse of quantum logic via Parabolic SAR
   sarHandle = iSAR(_Symbol, _Period, InpSarStep, InpSarMax);
   if(sarHandle == INVALID_HANDLE) return(INIT_FAILED);

   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   // 1. Check Broker Operating Hours
   MqlDateTime time;
   TimeCurrent(time);
   if(time.hour < InpStartHour || time.hour >= InpEndHour) return;

   // 2. Check Market Greed (Spread)
   symInfo.RefreshRates();
   if(symInfo.Spread() > InpMaxSpread) return; // The spread is too high; wait a bit.

   // 3. Currently reading "The Will of Quantum Logic"
   double sarArray[];
   double closeArray[];
   CopyBuffer(sarHandle, 0, 0, 2, sarArray);
   CopyClose(_Symbol, _Period, 0, 2, closeArray);

   ArraySetAsSeries(sarArray, true);
   ArraySetAsSeries(closeArray, true);

   bool isQuantumUp = (closeArray[0] > sarArray[0]); // The market wants to rise.
   bool isQuantumDn = (closeArray[0] < sarArray[0]); // The market is looking to move lower.

   bool hasBuy = false, hasSell = false;
   ulong buyTicket = 0, sellTicket = 0;

   // 4. Checking our current position
   for(int i = PositionsTotal() - 1; i >= 0; i--)
     {
      if(posInfo.SelectByIndex(i))
        {
         if(posInfo.Symbol() == _Symbol)
           {
            if(posInfo.PositionType() == POSITION_TYPE_BUY)  { hasBuy = true; buyTicket = posInfo.Ticket(); }
            if(posInfo.PositionType() == POSITION_TYPE_SELL) { hasSell = true; sellTicket = posInfo.Ticket(); }
           }
        }
     }

   // 5. EXECUTION: Going with the Flow

   // If Quantum wants to go down but we have a BUY position -> Close the BUY, open a SELL.
   if(isQuantumDn)
     {
      if(hasBuy) trade.PositionClose(buyTicket); // Close positions that go against the trend.
      if(!hasSell) trade.Sell(InpLotSize, _Symbol); // Go with the downstream current.
     }

   // If Quantum wants to go UP but we have a SELL position -> Close the SELL, open a BUY.
   else if(isQuantumUp)
     {
      if(hasSell) trade.PositionClose(sellTicket); // Close positions that go against the trend.
      if(!hasBuy) trade.Buy(InpLotSize, _Symbol);  // Go with the rising tide.
     }
  }

//+------------------------------------------------------------------+

*/

// Specific Trend Follower Code

/*

//+------------------------------------------------------------------+
//|                             KCI_Quantum_F1_Embedded_Follower.mq5 |
//|           Otak KCI Ditanam Langsung + F1 Tracker (Tanpa MA)      |
//|                    Framework: Advanced MM, Time Zones, & Style   |
//+------------------------------------------------------------------+
#property copyright "Copyright©2026. Ritz EAneha"
#property link      "https://www.mql5.com/en/users/ritzfalih/seller"
#property version   "1.0"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- ENUM DEFINITIONS ---
enum ENUM_MM_MODE {
   MM_FIXED = 0,   // Fixed Lot
   MM_RISK = 1     // Risk % of Balance
};

enum ENUM_TRADE_DAYS {
   DAYS_MON_FRI = 0, // Senin - Jumat (Forex)
   DAYS_MON_SUN = 1  // Senin - Minggu (Crypto 24/7)
};

enum ENUM_TIME_MODE {
   TIME_CUSTOM = 0,  // Custom Time Trading (24 Jam)
   TIME_ZONES = 1    // Zone Time Trading (5 Zona GMT)
};

enum ENUM_ZONES {
   ZONE_ALL = 0, // Semua Zona (1-5) Aktif
   ZONE_1 = 1,   // Hanya Zona 1
   ZONE_2 = 2,   // Hanya Zona 2
   ZONE_3 = 3,   // Hanya Zona 3
   ZONE_4 = 4,   // Hanya Zona 4
   ZONE_5 = 5    // Hanya Zona 5
};

enum ENUM_TRADE_STYLE {
   STYLE_SCALPING = 0,    // Scalping (Default)
   STYLE_INTRADAY = 1,    // Intraday (Menunggu KCI-Directional_X)
   STYLE_SHORT_SWING = 2, // Short Swing
   STYLE_LONG_SWING = 3   // Long Swing
};

//--- INPUT PARAMETERS ---

input group "=== EA Identity & Style ==="
input int              InpCustomMagic    = 123;            // Custom Magic Number
input ENUM_TRADE_STYLE InpTradeStyle     = STYLE_SCALPING; // Style Trading (Placeholder Tren)

input group "=== Money Management & Risk ==="
input ENUM_MM_MODE     InpMM_Mode        = MM_FIXED;       // Metode Lot
input double           InpFixLot         = 0.01;           // Lot Fix (Jika Mode Fixed)
input double           InpRiskPercent    = 2.0;            // Risk % dari Balance (Jika Mode Risk)
input double           InpDailyDD        = 5.0;            // Batas DD Harian % (Otomatis Aktif di Mode Risk)

input group "=== Time Trading Filters ==="
input ENUM_TRADE_DAYS  InpTradeDays      = DAYS_MON_FRI;   // Hari Aktif Trading
input ENUM_TIME_MODE   InpTimeMode       = TIME_CUSTOM;    // Mode Waktu Trading
// Mode Custom Time
input string           InpCustomStart    = "00:00";        // Custom Start (HH:MM)
input string           InpCustomEnd      = "22:30";        // Custom End (HH:MM)
// Mode Zone Time
input ENUM_ZONES       InpSelectedZone   = ZONE_ALL;       // Pilihan Eksekusi Zona
input string           InpZone1_Start    = "01:00";        // Zona 1 Start
input string           InpZone1_End      = "09:00";        // Zona 1 End
input string           InpZone2_Start    = "09:00";        // Zona 2 Start
input string           InpZone2_End      = "13:00";        // Zona 2 End
input string           InpZone3_Start    = "13:00";        // Zona 3 Start
input string           InpZone3_End      = "17:00";        // Zona 3 End
input string           InpZone4_Start    = "17:00";        // Zona 4 Start
input string           InpZone4_End      = "21:00";        // Zona 4 End
input string           InpZone5_Start    = "21:00";        // Zona 5 Start
input string           InpZone5_End      = "01:00";        // Zona 5 End

input group "=== KCI Computing Core ==="
input int              InpKCI_BasePeriod = 9;              // KCI Kinetic Base Period
input int              InpMaxSpread      = 50;             // Maksimal Spread (Point)

input group "=== F1 Engine (Proteksi) ==="
input int              InpSL             = 3000;           // Stop Loss (Point)
input int              InpTP             = 9000;           // Take Profit (Point)
input int              InpF1Speed        = 1500;           // Kecepatan Trailing Stop F1 (Point)

//--- GLOBAL VARIABLES ---
CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;
int            EA_Magic_Number;

//+------------------------------------------------------------------+
//| Helper: String HH:MM ke Menit                                    |
//+------------------------------------------------------------------+
int TimeToMins(string time_str) {
   string arr[];
   if(StringSplit(time_str, ':', arr) >= 2) {
      return (int)StringToInteger(arr[0]) * 60 + (int)StringToInteger(arr[1]);
   }
   return 0;
}

//+------------------------------------------------------------------+
//| Helper: Validasi Waktu Berdasarkan Rentang                       |
//+------------------------------------------------------------------+
bool IsTimeInRange(string start_str, string end_str, int current_mins) {
   int start_m = TimeToMins(start_str);
   int end_m = TimeToMins(end_str);
   if(start_m == end_m) return true; // 24 Jam Penuh
   if(start_m < end_m) return (current_mins >= start_m && current_mins <= end_m);
   else return (current_mins >= start_m || current_mins <= end_m); // Lintas Hari (Midnight)
}

//+------------------------------------------------------------------+
//| Fungsi: Mengecek Validitas Waktu Trading Keseluruhan             |
//+------------------------------------------------------------------+
bool IsTradingTimeValid() {
   MqlDateTime dt;
   TimeCurrent(dt);

   // 1. Cek Hari (Forex vs Crypto)
   if(InpTradeDays == DAYS_MON_FRI && (dt.day_of_week == 0 || dt.day_of_week == 6)) return false;

   int current_mins = dt.hour * 60 + dt.min;

   // 2. Cek Mode Waktu
   if(InpTimeMode == TIME_CUSTOM) {
      return IsTimeInRange(InpCustomStart, InpCustomEnd, current_mins);
   } else { // TIME_ZONES
      if(InpSelectedZone == ZONE_ALL) {
         return (IsTimeInRange(InpZone1_Start, InpZone1_End, current_mins) ||
                 IsTimeInRange(InpZone2_Start, InpZone2_End, current_mins) ||
                 IsTimeInRange(InpZone3_Start, InpZone3_End, current_mins) ||
                 IsTimeInRange(InpZone4_Start, InpZone4_End, current_mins) ||
                 IsTimeInRange(InpZone5_Start, InpZone5_End, current_mins));
      } else if(InpSelectedZone == ZONE_1) return IsTimeInRange(InpZone1_Start, InpZone1_End, current_mins);
        else if(InpSelectedZone == ZONE_2) return IsTimeInRange(InpZone2_Start, InpZone2_End, current_mins);
        else if(InpSelectedZone == ZONE_3) return IsTimeInRange(InpZone3_Start, InpZone3_End, current_mins);
        else if(InpSelectedZone == ZONE_4) return IsTimeInRange(InpZone4_Start, InpZone4_End, current_mins);
        else if(InpSelectedZone == ZONE_5) return IsTimeInRange(InpZone5_Start, InpZone5_End, current_mins);
   }
   return false;
}

//+------------------------------------------------------------------+
//| Fungsi: Mengecek Drawdown Harian (Hanya aktif jika Risk Mode)    |
//+------------------------------------------------------------------+
bool IsDailyDrawdownHit() {
   if(InpMM_Mode == MM_FIXED) return false; // Instruksi 8: Fix Lot abaikan DD
   if(InpDailyDD <= 0) return false;

   double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);

   // Ambil saldo awal hari ini dengan menghitung profit realisasi hari ini
   MqlDateTime dt;
   TimeCurrent(dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   HistorySelect(StructToTime(dt), TimeCurrent());

   double today_pnl = 0;
   for(int i = 0; i < HistoryDealsTotal(); i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0) {
         today_pnl += HistoryDealGetDouble(ticket, DEAL_PROFIT);
         today_pnl += HistoryDealGetDouble(ticket, DEAL_SWAP);
         today_pnl += HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      }
   }

   double start_of_day_balance = current_balance - today_pnl;
   double max_loss_allowed = start_of_day_balance * (InpDailyDD / 100.0);
   double current_loss = start_of_day_balance - current_equity;

   return (current_loss >= max_loss_allowed); // True = Kena DD (Blokir Trade)
}

//+------------------------------------------------------------------+
//| Fungsi: Menghitung Lot Dinamis                                   |
//+------------------------------------------------------------------+
double CalculateLotSize() {
   if(InpMM_Mode == MM_FIXED) return InpFixLot;

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double risk_money = balance * (InpRiskPercent / 100.0);

   double tick_val = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

   double risk_per_lot = InpSL * (tick_val / (tick_size / point));
   if(risk_per_lot <= 0) return InpFixLot;

   double calc_lot = risk_money / risk_per_lot;

   // Normalisasi Sesuai Broker
   double min_l = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_l = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double step_l = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   calc_lot = MathRound(calc_lot / step_l) * step_l;
   if(calc_lot < min_l) calc_lot = min_l;
   if(calc_lot > max_l) calc_lot = max_l;

   return calc_lot;
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   symInfo.Name(_Symbol);

   // 1. Dinamis Magic Number: Akun + Custom Input
   EA_Magic_Number = (int)AccountInfoInteger(ACCOUNT_LOGIN) + InpCustomMagic;
   trade.SetExpertMagicNumber(EA_Magic_Number);

   Print("KCI Quantum F1 [Advanced] Init. Magic Number: ", EA_Magic_Number);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Fungsi Mobil F1 (Trailing Stop Dinamis)                          |
//+------------------------------------------------------------------+
void RunF1Tracker()
{
   double ask = NormalizeDouble(symInfo.Ask(), _Digits);
   double bid = NormalizeDouble(symInfo.Bid(), _Digits);
   double point = symInfo.Point();

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      // PERHATIAN: Membaca posisi dengan Magic Number Dinamis
      if(posInfo.SelectByIndex(i) && posInfo.Symbol() == _Symbol && posInfo.Magic() == EA_Magic_Number) {

         if(posInfo.PositionType() == POSITION_TYPE_BUY) {
            if(bid - posInfo.PriceOpen() > InpF1Speed * point) {
               double newSL = NormalizeDouble(bid - (InpF1Speed * point), _Digits);
               if(posInfo.StopLoss() < newSL || posInfo.StopLoss() == 0.0)
                  trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
            }
         }
         else if(posInfo.PositionType() == POSITION_TYPE_SELL) {
            if(posInfo.PriceOpen() - ask > InpF1Speed * point) {
               double newSL = NormalizeDouble(ask + (InpF1Speed * point), _Digits);
               if(posInfo.StopLoss() > newSL || posInfo.StopLoss() == 0.0)
                  trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   if(!symInfo.RefreshRates()) return;

   // F1 Tracker (TETAP SEMPURNA)
   RunF1Tracker();

   // =================================================================
   // EMBEDDED KCI KINEMATICS ENGINE (TETAP SEMPURNA)
   // =================================================================
   double closeArray[];
   ArraySetAsSeries(closeArray, true);

   if(CopyClose(_Symbol, _Period, 0, InpKCI_BasePeriod, closeArray) < InpKCI_BasePeriod) return;

   double sum_price = 0;
   for(int j = 0; j < InpKCI_BasePeriod; j++) sum_price += closeArray[j];

   double mean_price = sum_price / InpKCI_BasePeriod;
   double buf_kd = closeArray[0] - mean_price;

   bool isQuantumUp = (buf_kd >= 0.0);
   bool isQuantumDn = (buf_kd < 0.0);

   // =================================================================

   bool hasBuy = false, hasSell = false;
   ulong buyTicket = 0, sellTicket = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Symbol() == _Symbol && posInfo.Magic() == EA_Magic_Number) {
         if(posInfo.PositionType() == POSITION_TYPE_BUY)  { hasBuy = true; buyTicket = posInfo.Ticket(); }
         if(posInfo.PositionType() == POSITION_TYPE_SELL) { hasSell = true; sellTicket = posInfo.Ticket(); }
      }
   }

   if(isQuantumDn && hasBuy) {
      if(trade.PositionClose(buyTicket)) hasBuy = false;
   }
   if(isQuantumUp && hasSell) {
      if(trade.PositionClose(sellTicket)) hasSell = false;
   }

   // =================================================================
   // NEW: FILTER WAKTU, DRAWDOWN & SPREAD SEBELUM ENTRY
   // =================================================================
   if(symInfo.Spread() > InpMaxSpread) return;
   if(!IsTradingTimeValid()) return;
   if(IsDailyDrawdownHit()) return; // Batalkan entry jika limit rugi harian tersentuh

   double sl, tp;
   double ask = NormalizeDouble(symInfo.Ask(), _Digits);
   double bid = NormalizeDouble(symInfo.Bid(), _Digits);
   double point = symInfo.Point();
   double final_lot = CalculateLotSize(); // Mengambil lot sesuai pengaturan Fix / Risk

   // =================================================================
   // TAHAP EKSEKUSI MURNI KCI (TETAP SEMPURNA)
   // =================================================================

   if(isQuantumDn && !hasSell) {
      sl = NormalizeDouble(bid + (InpSL * point), _Digits);
      tp = NormalizeDouble(bid - (InpTP * point), _Digits);

      if(!trade.Sell(final_lot, _Symbol, bid, sl, tp)) {
         Print("GAGAL SELL | Retcode=", trade.ResultRetcode());
      }
   }

   else if(isQuantumUp && !hasBuy) {
      sl = NormalizeDouble(ask - (InpSL * point), _Digits);
      tp = NormalizeDouble(ask + (InpTP * point), _Digits);

      if(!trade.Buy(final_lot, _Symbol, ask, sl, tp)) {
         Print("GAGAL BUY | Retcode=", trade.ResultRetcode());
      }
   }
}
//+------------------------------------------------------------------+

*/


/*
//+------------------------------------------------------------------+
//|                        KCI_Quantum_F1_Diagnostic_Follower.mq5    |
//|                 Perbaikan State, Bid/Ask, dan Laporan Diagnostik |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

input double   InpLotSize           = 0.01;
input int      InpMaxSpread         = 50;
input int      InpStartHour         = 2;
input int      InpEndHour           = 22;

input int      InpKCI_ZScorePeriod  = 30;
input double   InpKCI_CompThreshold = 2.0;
input int      InpKCI_BasePeriod    = 9;

input bool     InpUseMAFilter       = false;   // SEMENTARA DIMATIKAN untuk menguji KCI
input int      InpMA_Fast           = 10;
input int      InpMA_Middle         = 50;
input int      InpMA_Slow           = 200;

input int      InpSL                = 300;
input int      InpTP                = 900;
input int      InpF1Speed           = 150;

CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;

int            kciHandle, maFastHandle, maMiddleHandle, maSlowHandle;

int OnInit()
{
   symInfo.Name(_Symbol);
   trade.SetExpertMagicNumber(123456);

   kciHandle = iCustom(_Symbol, _Period, "KCI Trend", InpKCI_ZScorePeriod, InpKCI_CompThreshold, InpKCI_BasePeriod);
   maFastHandle   = iMA(_Symbol, _Period, InpMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   maMiddleHandle = iMA(_Symbol, _Period, InpMA_Middle, 0, MODE_EMA, PRICE_CLOSE);
   maSlowHandle   = iMA(_Symbol, _Period, InpMA_Slow, 0, MODE_EMA, PRICE_CLOSE);

   if(kciHandle == INVALID_HANDLE) return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}

void RunF1Tracker()
{
   double ask = NormalizeDouble(symInfo.Ask(), _Digits);
   double bid = NormalizeDouble(symInfo.Bid(), _Digits);
   double point = symInfo.Point();

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Symbol() == _Symbol && posInfo.Magic() == 123456) {
         if(posInfo.PositionType() == POSITION_TYPE_BUY) {
            if(bid - posInfo.PriceOpen() > InpF1Speed * point) {
               double newSL = NormalizeDouble(bid - (InpF1Speed * point), _Digits);
               if(posInfo.StopLoss() < newSL || posInfo.StopLoss() == 0.0)
                  trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
            }
         }
         else if(posInfo.PositionType() == POSITION_TYPE_SELL) {
            if(posInfo.PriceOpen() - ask > InpF1Speed * point) {
               double newSL = NormalizeDouble(ask + (InpF1Speed * point), _Digits);
               if(posInfo.StopLoss() > newSL || posInfo.StopLoss() == 0.0)
                  trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
            }
         }
      }
   }
}

void OnTick()
{
   symInfo.RefreshRates();
   RunF1Tracker();

   double kciColorArray[], fast[], middle[], slow[];
   CopyBuffer(kciHandle, 1, 0, 2, kciColorArray);
   CopyBuffer(maFastHandle, 0, 0, 2, fast);
   CopyBuffer(maMiddleHandle, 0, 0, 2, middle);
   CopyBuffer(maSlowHandle, 0, 0, 2, slow);

   ArraySetAsSeries(kciColorArray, true);
   ArraySetAsSeries(fast, true); ArraySetAsSeries(middle, true); ArraySetAsSeries(slow, true);

   // --- 1. VALIDASI KCI EKSPLISIT (Saran #7) ---
   bool validKCI = (kciColorArray[0] != EMPTY_VALUE);
   bool isQuantumUp = false;
   bool isQuantumDn = false;

   if(validKCI)
   {
      isQuantumUp = (kciColorArray[0] < 0.5); // Buffer 0 (Biru)
      isQuantumDn = (kciColorArray[0] >= 0.5); // Buffer 1 (Merah)
   }

   bool isLightAlignedUp = (fast[0] > middle[0] && middle[0] > slow[0]);
   bool isLightAlignedDn = (fast[0] < middle[0] && middle[0] < slow[0]);

   bool validBuySignal  = InpUseMAFilter ? isLightAlignedUp : true;
   bool validSellSignal = InpUseMAFilter ? isLightAlignedDn : true;

   bool hasBuy = false, hasSell = false;
   ulong buyTicket = 0, sellTicket = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Symbol() == _Symbol && posInfo.Magic() == 123456) {
         if(posInfo.PositionType() == POSITION_TYPE_BUY)  { hasBuy = true; buyTicket = posInfo.Ticket(); }
         if(posInfo.PositionType() == POSITION_TYPE_SELL) { hasSell = true; sellTicket = posInfo.Ticket(); }
      }
   }

   // --- 2. PERBAIKAN STATE POSISI (Saran #6) ---
   if(isQuantumDn && hasBuy) {
      if(trade.PositionClose(buyTicket)) hasBuy = false; // Langsung update state
   }
   if(isQuantumUp && hasSell) {
      if(trade.PositionClose(sellTicket)) hasSell = false; // Langsung update state
   }

   // --- 3. LOG DIAGNOSTIK KONDISI (Saran #8) ---
   // Print berjalan setiap tick mungkin akan membuat jurnal penuh,
   // Kita batasi hanya Print ketika ada Niat Kuantum yang valid namun tidak ada posisi yang terbuka.
   if(validKCI && (!hasBuy && !hasSell))
   {
      Print("DIAGNOSTIC CHECK | ",
         "KCI Color=", DoubleToString(kciColorArray[0], 1),
         " | Q_Dn=", isQuantumDn,
         " | MA_Dn=", isLightAlignedDn,
         " | ValidSell=", validSellSignal,
         " | HasSell=", hasSell,
         " | Spread=", symInfo.Spread()
      );
   }

   MqlDateTime time;
   TimeCurrent(time);
   if(time.hour < InpStartHour || time.hour >= InpEndHour) return;
   if(symInfo.Spread() > InpMaxSpread) return;

   double sl, tp;
   double ask = NormalizeDouble(symInfo.Ask(), _Digits);
   double bid = NormalizeDouble(symInfo.Bid(), _Digits);
   double point = symInfo.Point();

   // --- 4. EKSEKUSI SELL DENGAN BID & LOG DETAIL (Saran #4 & #5) ---
   if(isQuantumDn && validSellSignal && !hasSell) {
      // PERBAIKAN: Kalkulasi SL/TP menggunakan BID sebagai basis untuk order SELL
      sl = NormalizeDouble(bid + (InpSL * point), _Digits);
      tp = NormalizeDouble(bid - (InpTP * point), _Digits);

      if(!trade.Sell(InpLotSize, _Symbol, bid, sl, tp)) {
         Print("GAGAL SELL | Retcode=", trade.ResultRetcode(),
               " | ", trade.ResultRetcodeDescription(),
               " | Bid=", DoubleToString(bid, _Digits),
               " | SL=", DoubleToString(sl, _Digits),
               " | TP=", DoubleToString(tp, _Digits)
         );
      }
   }

   // EKSEKUSI BUY
   else if(isQuantumUp && validBuySignal && !hasBuy) {
      sl = NormalizeDouble(ask - (InpSL * point), _Digits);
      tp = NormalizeDouble(ask + (InpTP * point), _Digits);

      if(!trade.Buy(InpLotSize, _Symbol, ask, sl, tp)) {
         Print("GAGAL BUY | Retcode=", trade.ResultRetcode(),
               " | ", trade.ResultRetcodeDescription(),
               " | Ask=", DoubleToString(ask, _Digits),
               " | SL=", DoubleToString(sl, _Digits),
               " | TP=", DoubleToString(tp, _Digits)
         );
      }
   }
}
//+------------------------------------------------------------------+

*/

/*


//+------------------------------------------------------------------+
//|   2026/05/25              KCI_Quantum_F1_Grandmaster_Edition.mq5 |
//|                     Otak KCI Core + KCI-DX Embedded + F1 Tracker |
//|                                KCI-VD Dynamic SL/TP & Hysteresis |
//+------------------------------------------------------------------+
#property copyright "Copyright©2026. Ritz EAneha"
#property link      "https://www.mql5.com/en/users/ritzfalih/seller"
#property version   "1.0"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- ENUM DEFINITIONS ---
enum ENUM_MM_MODE { MM_FIXED = 0, MM_RISK = 1 };
enum ENUM_TRADE_DAYS { DAYS_MON_FRI = 0, DAYS_MON_SUN = 1 };
enum ENUM_TIME_MODE { TIME_CUSTOM = 0, TIME_ZONES = 1 };
enum ENUM_ZONES { ZONE_ALL=0, ZONE_TOKYO=1, ZONE_LONDON=2, ZONE_OVERLAP=3, ZONE_NEW_YORK=4, ZONE_SYDNEY=5 };
enum ENUM_TRADE_STYLE { STYLE_SCALPING=0, STYLE_INTRADAY=1, STYLE_SHORT_SWING=2, STYLE_LONG_SWING=3 };

//--- INPUT PARAMETERS ---
input group "=== EA Identity & Style ==="
input int              InpCustomMagic    = 123;
input ENUM_TRADE_STYLE InpTradeStyle     = STYLE_SCALPING;

input group "=== Money Management & Risk ==="
input ENUM_MM_MODE     InpMM_Mode        = MM_FIXED;
input double           InpFixLot         = 0.01;
input double           InpRiskPercent    = 2.0;
input double           InpDailyDD        = 5.0;

input group "=== Time Trading Filters ==="
input ENUM_TRADE_DAYS  InpTradeDays      = DAYS_MON_FRI;
input ENUM_TIME_MODE   InpTimeMode       = TIME_CUSTOM;
input string           InpCustomStart    = "00:00";
input string           InpCustomEnd      = "22:30";
input ENUM_ZONES       InpSelectedZone   = ZONE_ALL;
input string           InpZone1_Tokyo_Start     = "01:00";
input string           InpZone1_Tokyo_End       = "09:00";
input string           InpZone2_London_Start    = "09:00";
input string           InpZone2_London_End      = "13:00";
input string           InpZone3_Overlap_Start   = "13:00";
input string           InpZone3_Overlap_End     = "17:00";
input string           InpZone4_NewYork_Start   = "17:00";
input string           InpZone4_NewYork_End     = "21:00";
input string           InpZone5_Sydney_Start    = "21:00";
input string           InpZone5_Sydney_End      = "01:00";

input group "=== KCI Computing Core ==="
input int              InpKCI_BasePeriod = 9;
input int              InpMaxSpread      = 200;
input int              InpNoiseFilter    = 30;             // Hysteresis Anti-Flickering (Poin)

input group "=== KCI-DX Swing & Intraday Sensor ==="
input int              InpKCIDX_ZPeriod  = 30;
input double           InpKCIDX_Sens     = 1.5;

input group "=== KCI Volatility Distance (Dynamic SL/TP) ==="
input bool             InpUseDynamicVD   = true;           // Auto SL/TP dari KCI-VD
input int              InpVD_Period      = 14;             // Periode Kalkulasi Volatilitas
input double           InpVD_SL_Mult     = 1.5;            // SL = KCI-VD * 1.5
input double           InpVD_TP_Mult     = 3.0;            // TP = KCI-VD * 3.0
input double           InpVD_Trail_Mult  = 1.0;            // F1 Speed = KCI-VD * 1.0
input int              InpVD_MinVolPnts  = 50;             // Syarat Minimal Volatilitas (Poin) untuk Entry

input group "=== F1 Engine (Static Fallback) ==="
input int              InpSL             = 3000;           // Statis SL (Jika Dynamic FALSE)
input int              InpTP             = 9000;           // Statis TP (Jika Dynamic FALSE)
input int              InpF1Speed        = 1500;           // Statis Trailing (Jika Dynamic FALSE)

// ===================================================================
//   KCI VOLATILITY DISTANCE CORE ENGINE (OOP EMBEDDED)
// ===================================================================
class CKCIVolatilityDistance
{
private:
   int      m_kinetic_period;
   double   m_point;

public:
            CKCIVolatilityDistance(void) { m_kinetic_period = 14; m_point = _Point; }
           ~CKCIVolatilityDistance(void) {}

   bool Init(const int period) {
      if(period < 2) return(false);
      m_kinetic_period = period;
      m_point = _Point;
      if(m_point <= 0) m_point = 0.00001;
      return(true);
   }

   double Calculate(const int index, const double &high[], const double &low[], const double &close[]) {
      double sum_TR = 0.0, sum_sq_TR = 0.0, path_length = 0.0;
      for(int j = 0; j < m_kinetic_period; j++) {
         int curr_idx = index + j;
         double hl = high[curr_idx] - low[curr_idx];
         double hc = MathAbs(high[curr_idx] - close[curr_idx + 1]);
         double lc = MathAbs(low[curr_idx] - close[curr_idx + 1]);
         double tr = hl;
         if(hc > tr) tr = hc;
         if(lc > tr) tr = lc;
         sum_TR    += tr;
         sum_sq_TR += (tr * tr);
         if(j < m_kinetic_period - 1) path_length += MathAbs(close[curr_idx] - close[curr_idx + 1]);
      }
      double net_distance = MathAbs(close[index] - close[index + m_kinetic_period - 1]);
      if(path_length < net_distance) path_length = net_distance;
      if(path_length == 0.0)         path_length = m_point;
      double efficiency_ratio = net_distance / path_length;
      double mean_TR  = sum_TR / m_kinetic_period;
      double variance = (sum_sq_TR / m_kinetic_period) - (mean_TR * mean_TR);
      if(variance < 0.0) variance = 0.0;
      double std_TR = MathSqrt(variance);
      return(std_TR * (2.0 - efficiency_ratio));
   }
};

//--- GLOBAL VARIABLES ---
CTrade                  trade;
CPositionInfo           posInfo;
CSymbolInfo             symInfo;
int                     EA_Magic_Number;
CKCIVolatilityDistance  kci_vd_engine;

//+------------------------------------------------------------------+
//| Pembantu (Waktu & Drawdown)
//+------------------------------------------------------------------+
int TimeToMins(string time_str) {
   string arr[];
   if(StringSplit(time_str, ':', arr) >= 2) return (int)StringToInteger(arr[0]) * 60 + (int)StringToInteger(arr[1]);
   return 0;
}

bool IsTimeInRange(string start_str, string end_str, int current_mins) {
   int start_m = TimeToMins(start_str);
   int end_m = TimeToMins(end_str);
   if(start_m == end_m) return true;
   if(start_m < end_m) return (current_mins >= start_m && current_mins <= end_m);
   else return (current_mins >= start_m || current_mins <= end_m);
}

bool IsTradingTimeValid() {
   MqlDateTime dt; TimeCurrent(dt);
   if(InpTradeDays == DAYS_MON_FRI && (dt.day_of_week == 0 || dt.day_of_week == 6)) return false;
   int current_mins = dt.hour * 60 + dt.min;
   if(InpTimeMode == TIME_CUSTOM) return IsTimeInRange(InpCustomStart, InpCustomEnd, current_mins);
   else {
      if(InpSelectedZone == ZONE_ALL) {
         return (IsTimeInRange(InpZone1_Tokyo_Start, InpZone1_Tokyo_End, current_mins) ||
                 IsTimeInRange(InpZone2_London_Start, InpZone2_London_End, current_mins) ||
                 IsTimeInRange(InpZone3_Overlap_Start, InpZone3_Overlap_End, current_mins) ||
                 IsTimeInRange(InpZone4_NewYork_Start, InpZone4_NewYork_End, current_mins) ||
                 IsTimeInRange(InpZone5_Sydney_Start, InpZone5_Sydney_End, current_mins));
      } else if(InpSelectedZone == ZONE_TOKYO)    return IsTimeInRange(InpZone1_Tokyo_Start, InpZone1_Tokyo_End, current_mins);
        else if(InpSelectedZone == ZONE_LONDON)   return IsTimeInRange(InpZone2_London_Start, InpZone2_London_End, current_mins);
        else if(InpSelectedZone == ZONE_OVERLAP)  return IsTimeInRange(InpZone3_Overlap_Start, InpZone3_Overlap_End, current_mins);
        else if(InpSelectedZone == ZONE_NEW_YORK) return IsTimeInRange(InpZone4_NewYork_Start, InpZone4_NewYork_End, current_mins);
        else if(InpSelectedZone == ZONE_SYDNEY)   return IsTimeInRange(InpZone5_Sydney_Start, InpZone5_Sydney_End, current_mins);
   }
   return false;
}

bool IsDailyDrawdownHit() {
   if(InpMM_Mode == MM_FIXED) return false;
   if(InpDailyDD <= 0) return false;
   double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double current_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   MqlDateTime dt; TimeCurrent(dt);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   HistorySelect(StructToTime(dt), TimeCurrent());
   double today_pnl = 0;
   for(int i = 0; i < HistoryDealsTotal(); i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket > 0) today_pnl += (HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_SWAP) + HistoryDealGetDouble(ticket, DEAL_COMMISSION));
   }
   double start_of_day_balance = current_balance - today_pnl;
   return ((start_of_day_balance - current_equity) >= (start_of_day_balance * (InpDailyDD / 100.0)));
}

//---  Kalkulasi Lot menggunakan SL Dinamis ---
double CalculateLotSize(int active_sl_points) {
   if(InpMM_Mode == MM_FIXED) return InpFixLot;
   double risk_money = AccountInfoDouble(ACCOUNT_BALANCE) * (InpRiskPercent / 100.0);
   double tick_val = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   double risk_per_lot = active_sl_points * (tick_val / (tick_size / point));
   if(risk_per_lot <= 0) return InpFixLot;

   double calc_lot = risk_money / risk_per_lot;
   double step_l = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   calc_lot = MathRound(calc_lot / step_l) * step_l;
   if(calc_lot < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN)) calc_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   if(calc_lot > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX)) calc_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   return calc_lot;
}

double GetZScoreCustom(const double &data_array[], int period) {
   if(period < 2) return 0.0;
   double sum = 0.0, sum_sq = 0.0;
   for(int i = 0; i < period; i++) { sum += data_array[i]; sum_sq += data_array[i] * data_array[i]; }
   double mean = sum / period;
   double variance = (sum_sq / period) - (mean * mean);
   if(variance <= 1e-10) return 0.0;
   return (data_array[0] - mean) / MathSqrt(variance);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   symInfo.Name(_Symbol);
   EA_Magic_Number = (int)AccountInfoInteger(ACCOUNT_LOGIN) + InpCustomMagic;
   trade.SetExpertMagicNumber(EA_Magic_Number);
   kci_vd_engine.Init(InpVD_Period);
   Print("KCI Quantum F1 [Grandmaster+VD] Init. Magic: ", EA_Magic_Number);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Fungsi Mobil F1 (menerima Kecepatan Dinamis)                     |
//+------------------------------------------------------------------+
void RunF1Tracker(int active_f1_speed) {
   double ask = NormalizeDouble(symInfo.Ask(), _Digits);
   double bid = NormalizeDouble(symInfo.Bid(), _Digits);
   double point = symInfo.Point();
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Symbol() == _Symbol && posInfo.Magic() == EA_Magic_Number) {
         if(posInfo.PositionType() == POSITION_TYPE_BUY) {
            if(bid - posInfo.PriceOpen() > active_f1_speed * point) {
               double newSL = NormalizeDouble(bid - (active_f1_speed * point), _Digits);
               if(posInfo.StopLoss() < newSL || posInfo.StopLoss() == 0.0) trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
            }
         } else if(posInfo.PositionType() == POSITION_TYPE_SELL) {
            if(posInfo.PriceOpen() - ask > active_f1_speed * point) {
               double newSL = NormalizeDouble(ask + (active_f1_speed * point), _Digits);
               if(posInfo.StopLoss() > newSL || posInfo.StopLoss() == 0.0) trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick() {
   if(!symInfo.RefreshRates()) return;

   // =================================================================
   // DATA ACQUISITION UNTUK SEMUA ENGINE KCI
   // =================================================================
   int max_bars = MathMax(InpKCIDX_ZPeriod + InpKCI_BasePeriod + 1, InpVD_Period + 2);
   double c_arr[], h_arr[], l_arr[];
   ArraySetAsSeries(c_arr, true); ArraySetAsSeries(h_arr, true); ArraySetAsSeries(l_arr, true);

   if(CopyClose(_Symbol, _Period, 0, max_bars, c_arr) < max_bars) return;
   if(CopyHigh(_Symbol, _Period, 0, max_bars, h_arr) < max_bars) return;
   if(CopyLow(_Symbol, _Period, 0, max_bars, l_arr) < max_bars) return;

   // =================================================================
   // ENGINE 1: KCI VOLATILITY DISTANCE (SL, TP, F1 Dinamis)
   // =================================================================
   double current_vd_price = kci_vd_engine.Calculate(0, h_arr, l_arr, c_arr);
   int current_vd_points = (int)MathRound(current_vd_price / symInfo.Point());

   // Menentukan SL, TP, dan Kecepatan F1 yang aktif saat ini
   int active_sl = InpUseDynamicVD ? (int)(current_vd_points * InpVD_SL_Mult) : InpSL;
   int active_tp = InpUseDynamicVD ? (int)(current_vd_points * InpVD_TP_Mult) : InpTP;
   int active_f1 = InpUseDynamicVD ? (int)(current_vd_points * InpVD_Trail_Mult) : InpF1Speed;

   // Safety Minimum Points (mencegah SL 0 saat market mati)
   if(active_sl < 10) active_sl = 10;
   if(active_tp < 10) active_tp = 10;
   if(active_f1 < 5)  active_f1 = 5;

   // F1 Tracker (Dijalankan menggunakan kecepatan aktif)
   RunF1Tracker(active_f1);

   // =================================================================
   // ENGINE 2: KCI CORE + HYSTERESIS ANTI-FLICKERING
   // =================================================================
   double sum_price = 0;
   for(int j = 0; j < InpKCI_BasePeriod; j++) sum_price += c_arr[j];
   double mean_price = sum_price / InpKCI_BasePeriod;
   double buf_kd = c_arr[0] - mean_price;

   double noise_zone = InpNoiseFilter * symInfo.Point();
   bool isQuantumUp = (buf_kd > noise_zone);
   bool isQuantumDn = (buf_kd < -noise_zone);

   // =================================================================
   // ENGINE 3: KCI-DX (Sensor Swing & Intraday)
   // =================================================================
   bool isStyleConditionMet = true; // Default True untuk SCALPING
   if(InpTradeStyle != STYLE_SCALPING) {
      double raw_p[], raw_m[], raw_t[];
      ArrayResize(raw_p, InpKCIDX_ZPeriod); ArrayResize(raw_m, InpKCIDX_ZPeriod); ArrayResize(raw_t, InpKCIDX_ZPeriod);

      for(int i = 0; i < InpKCIDX_ZPeriod; i++) {
         double path_len = 0.000001, net_up = 0.0, net_dn = 0.0, m_p = 0.0;
         for(int j = 0; j < InpKCI_BasePeriod; j++) {
            double diff = c_arr[i + j] - c_arr[i + j + 1];
            path_len += MathAbs(diff);
            if(diff > 0) net_up += diff; else net_dn -= diff;
            m_p += c_arr[i + j];
         }
         m_p /= InpKCI_BasePeriod;
         double var_p = 0.0;
         for(int j = 0; j < InpKCI_BasePeriod; j++) var_p += MathPow(c_arr[i + j] - m_p, 2);
         double energy = MathSqrt(var_p / InpKCI_BasePeriod);
         raw_p[i] = (net_up / path_len) * energy;
         raw_m[i] = (net_dn / path_len) * energy;
         raw_t[i] = (MathAbs(net_up - net_dn) / path_len) * energy;
      }

      double z_plus  = GetZScoreCustom(raw_p, InpKCIDX_ZPeriod);
      double z_minus = GetZScoreCustom(raw_m, InpKCIDX_ZPeriod);
      double z_trend = GetZScoreCustom(raw_t, InpKCIDX_ZPeriod);

      double kdi_plus  = 100.0 / (1.0 + MathExp(-InpKCIDX_Sens * z_plus));
      double kdi_minus = 100.0 / (1.0 + MathExp(-InpKCIDX_Sens * z_minus));
      double kci_main  = 100.0 / (1.0 + MathExp(-InpKCIDX_Sens * z_trend));

      double threshold = 20.0;
      if(InpTradeStyle == STYLE_SHORT_SWING) threshold = 30.0;
      if(InpTradeStyle == STYLE_LONG_SWING)  threshold = 40.0;

      if(isQuantumUp)      isStyleConditionMet = (kci_main >= threshold && kdi_plus > kdi_minus);
      else if(isQuantumDn) isStyleConditionMet = (kci_main >= threshold && kdi_minus > kdi_plus);
   }

   // =================================================================
   // MANAJEMEN POSISI & PEMBUANGAN (EXIT RULE KCI CORE)
   // =================================================================
   bool hasBuy = false, hasSell = false;
   ulong buyTicket = 0, sellTicket = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Symbol() == _Symbol && posInfo.Magic() == EA_Magic_Number) {
         if(posInfo.PositionType() == POSITION_TYPE_BUY)  { hasBuy = true; buyTicket = posInfo.Ticket(); }
         if(posInfo.PositionType() == POSITION_TYPE_SELL) { hasSell = true; sellTicket = posInfo.Ticket(); }
      }
   }

   if(isQuantumDn && hasBuy) { if(trade.PositionClose(buyTicket)) hasBuy = false; }
   if(isQuantumUp && hasSell) { if(trade.PositionClose(sellTicket)) hasSell = false; }

   // =================================================================
   // FILTER LINGKUNGAN SEBELUM ENTRY (Termasuk Volatilitas Minimal)
   // =================================================================
   if(symInfo.Spread() > InpMaxSpread) return;
   if(!IsTradingTimeValid()) return;
   if(IsDailyDrawdownHit()) return;

   // Syarat KCI-VD: Volatilitas harus cukup agar kita tidak masuk di pasar mati
   bool isVolatileEnough = (!InpUseDynamicVD || current_vd_points >= InpVD_MinVolPnts);

   double sl, tp;
   double ask = NormalizeDouble(symInfo.Ask(), _Digits);
   double bid = NormalizeDouble(symInfo.Bid(), _Digits);
   double point = symInfo.Point();
   double final_lot = CalculateLotSize(active_sl); // Lot dihitung berdasarkan SL Dinamis!

   // =================================================================
   // TAHAP EKSEKUSI
   // =================================================================
   if(isQuantumDn && isStyleConditionMet && isVolatileEnough && !hasSell) {
      sl = NormalizeDouble(bid + (active_sl * point), _Digits);
      tp = NormalizeDouble(bid - (active_tp * point), _Digits);
      if(!trade.Sell(final_lot, _Symbol, bid, sl, tp)) Print("GAGAL SELL | Retcode=", trade.ResultRetcode());
   }

   else if(isQuantumUp && isStyleConditionMet && isVolatileEnough && !hasBuy) {
      sl = NormalizeDouble(ask - (active_sl * point), _Digits);
      tp = NormalizeDouble(ask + (active_tp * point), _Digits);
      if(!trade.Buy(final_lot, _Symbol, ask, sl, tp)) Print("GAGAL BUY | Retcode=", trade.ResultRetcode());
   }
}

//+------------------------------------------------------------------+

*/

/*

//+------------------------------------------------------------------+
//|   2026/03/12                                            FWTM.mq5 |
//|                                  "Follow the will of the market" |
//+------------------------------------------------------------------+
#property copyright "Copyright©2026. Ritz EAneha"
#property link      "https://www.mql5.com/en/users/ritzfalih/seller"
#property version   "1.0"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

input double   InpLotSize     = 0.01;       // Trading lot size
input int      InpMaxSpread   = 200;         // Maximum allowed spread in points
input int      InpStartHour   = 0;          // Trading start hour
input int      InpEndHour     = 23;         // Trading end hour
input double   InpSarStep     = 0.02;       // Parabolic SAR step sensitivity
input double   InpSarMax      = 0.2;        // Maximum Parabolic SAR sensitivity

CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;
int            sarHandle;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   symInfo.Name(_Symbol);
// Reading the market's logical pulse via Parabolic SAR
   sarHandle = iSAR(_Symbol, _Period, InpSarStep, InpSarMax);
   if(sarHandle == INVALID_HANDLE) return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
{
// 1. Check Broker's Active Hours
   MqlDateTime time;
   TimeCurrent(time);
   if(time.hour < InpStartHour || time.hour >= InpEndHour) return;
// 2. Check market activity (spread)
   symInfo.RefreshRates();
   if(symInfo.Spread() > InpMaxSpread) return; // The spread is too high; wait a bit.
// 3. Reading "The Will of Market Logic" Today
   double sarArray[];
   double closeArray[];
   CopyBuffer(sarHandle, 0, 0, 2, sarArray);
   CopyClose(_Symbol, _Period, 0, 2, closeArray);
   ArraySetAsSeries(sarArray, true);
   ArraySetAsSeries(closeArray, true);
   bool isFWTMUp = (closeArray[0] > sarArray[0]); // The market wants to rise.
   bool isFWTMDn = (closeArray[0] < sarArray[0]); // The market is looking to move lower.
   bool hasBuy = false, hasSell = false;
   ulong buyTicket = 0, sellTicket = 0;
// 4. Checking our current position
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i)) {
         if(posInfo.Symbol() == _Symbol) {
            if(posInfo.PositionType() == POSITION_TYPE_BUY)  {
               hasBuy = true;
               buyTicket = posInfo.Ticket();
            }
            if(posInfo.PositionType() == POSITION_TYPE_SELL) {
               hasSell = true;
               sellTicket = posInfo.Ticket();
            }
         }
      }
   }
// 5. EXECUTION: Going with the Flow
// If the market is poised to fall but we hold a BUY position, close the BUY and open a SELL.
   if(isFWTMDn) {
      if(hasBuy) trade.PositionClose(buyTicket); // Close positions that go against the trend.
      if(!hasSell) trade.Sell(InpLotSize, _Symbol); // Go with the downstream current.
   }
// If the market is poised to rise but we hold a SELL position -> Close the SELL position, open a BUY position.
   else if(isFWTMUp) {
      if(hasSell) trade.PositionClose(sellTicket); // Close positions that go against the trend.
      if(!hasBuy) trade.Buy(InpLotSize, _Symbol);  // Go with the rising tide.
   }
}

//+------------------------------------------------------------------+

*/



/*

#property copyright "Copyright©2026. Ritz EAneha"
#property link      "https://www.mql5.com/en/users/ritzfalih/seller"
#property version   "1.0"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//--- Safety & Money Management Parameters
input double   InpLotSize     = 0.01;       // Trading lot size
input int      InpSL          = 3000;       // Stop Loss in points
input int      InpTP          = 9000;       // Take Profit in points
input int      InpF1Speed     = 1500;       // F1 trailing distance in points

//--- Light Reference (Moving Average)
input bool     InpUseMAFilter = true;       // Enable Moving Average trend filter
input int      InpMA_Fast     = 10;         // Fast Moving Average period
input int      InpMA_Middle   = 50;         // Medium Moving Average period
input int      InpMA_Slow     = 200;        // Slow Moving Average period

CTrade         trade;
CPositionInfo  posInfo;
CSymbolInfo    symInfo;

int            maFastHandle;
int            maMiddleHandle;
int            maSlowHandle;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
{
   symInfo.Name(_Symbol);
   //--- Initialize the three Light Reference EMAs for faster trend response
   maFastHandle   = iMA(_Symbol, _Period, InpMA_Fast, 0, MODE_EMA, PRICE_CLOSE);
   maMiddleHandle = iMA(_Symbol, _Period, InpMA_Middle, 0, MODE_EMA, PRICE_CLOSE);
   maSlowHandle   = iMA(_Symbol, _Period, InpMA_Slow, 0, MODE_EMA, PRICE_CLOSE);
   if(maFastHandle == INVALID_HANDLE || maMiddleHandle == INVALID_HANDLE || maSlowHandle == INVALID_HANDLE)
      return(INIT_FAILED);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void RunF1Tracker()
{
   double ask = symInfo.Ask();
   double bid = symInfo.Bid();
   double point = symInfo.Point();
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Symbol() == _Symbol) {
         //--- BUY: Raise the Stop Loss progressively as price moves higher
         if(posInfo.PositionType() == POSITION_TYPE_BUY) {
            //--- Start trailing once the position moves at least one F1 distance into profit
            if(bid - posInfo.PriceOpen() > InpF1Speed * point) {
               double newSL = bid - (InpF1Speed * point);
               if(posInfo.StopLoss() < newSL || posInfo.StopLoss() == 0.0) {
                  trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
               }
            }
         }
         //--- SELL: Lower the Stop Loss progressively as price moves lower
         else if(posInfo.PositionType() == POSITION_TYPE_SELL) {
            //--- Start trailing once the position moves at least one F1 distance into profit
            if(posInfo.PriceOpen() - ask > InpF1Speed * point) {
               double newSL = ask + (InpF1Speed * point);
               if(posInfo.StopLoss() > newSL || posInfo.StopLoss() == 0.0) {
                  trade.PositionModify(posInfo.Ticket(), newSL, posInfo.TakeProfit());
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                   |
//+------------------------------------------------------------------+
void OnTick()
{
   symInfo.RefreshRates();
   //--- 1. Run the F1 tracker to protect and lock in existing profits
   RunF1Tracker();
   //--- 2. Read the Light Reference EMA values when enabled
   bool maBullish = true;
   bool maBearish = true;
   if(InpUseMAFilter)
  {
   double fast[], middle[], slow[];

   if(CopyBuffer(maFastHandle, 0, 0, 2, fast) < 2 ||
      CopyBuffer(maMiddleHandle, 0, 0, 2, middle) < 2 ||
      CopyBuffer(maSlowHandle, 0, 0, 2, slow) < 2)
      return;

   ArraySetAsSeries(fast, true);
   ArraySetAsSeries(middle, true);
   ArraySetAsSeries(slow, true);

   //--- Bullish MA alignment
   maBullish = (fast[0] > middle[0] && middle[0] > slow[0]);

   //--- Bearish MA alignment
   maBearish = (fast[0] < middle[0] && middle[0] < slow[0]);
  }
   bool hasBuy = false, hasSell = false;
   ulong buyTicket = 0, sellTicket = 0;
   //--- 4. Check existing positions for the current symbol
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(posInfo.SelectByIndex(i) && posInfo.Symbol() == _Symbol) {
         if(posInfo.PositionType() == POSITION_TYPE_BUY) {
            hasBuy = true;
            buyTicket = posInfo.Ticket();
         }
         if(posInfo.PositionType() == POSITION_TYPE_SELL) {
            hasSell = true;
            sellTicket = posInfo.Ticket();
         }
      }
   }
   double sl, tp;
   //--- 5. Execute the Quantum Trend Logic
   //--- Bearish trend
   if(maBearish)
     {
      if(hasBuy)
         trade.PositionClose(buyTicket);

      if(!hasSell)
        {
         sl = symInfo.Ask() + (InpSL * symInfo.Point());
         tp = symInfo.Ask() - (InpTP * symInfo.Point());

         trade.Sell(InpLotSize, _Symbol, symInfo.Bid(), sl, tp);
        }
     }

   //--- Bullish trend
   else if(maBullish)
     {
      if(hasSell)
         trade.PositionClose(sellTicket);

      if(!hasBuy)
        {
         sl = symInfo.Bid() - (InpSL * symInfo.Point());
         tp = symInfo.Bid() + (InpTP * symInfo.Point());

         trade.Buy(InpLotSize, _Symbol, symInfo.Ask(), sl, tp);
        }
     }
      //--- Neutral condition: EMA alignment is mixed or undefined.
      //--- The EA takes no new action and maintains the existing position.
}

//+------------------------------------------------------------------+
*/

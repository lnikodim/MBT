//+------------------------------------------------------------------+
//|                                          PLAYGROUND_EA_v1.04.mq5 |
//|                                  Copyright 2024, MetaQuotes Ltd. |
//|                                            https://forge.mql5.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024, MetaQuotes Ltd."
#property link      "https://forge.mql5.io"
#property version   "1.04"
#property description "Disciplined Encroachment Scalping with Session DOL Targeting"
/*
Playground v1.04 - Made by loki ☠️✨

CHANGELOG v1.04:
- Fixed time zone handling for Silver Bullet sessions (matches LiquidityLibrary implementation)
- Each SB window now targets specific session DOL:
  * SB1 (3-4am GMT) → Sydney Session High/Low
  * SB2 (10-11am GMT) → Tokyo Session High/Low  
  * SB3 (2-3pm GMT) → London Session High/Low
- Added one-trade-per-window rule: if trade is open in one SB window, skip other windows
- Added Silver Bullet sub-mode toggle:
  * When ON: Use Eprofit/Eloss targets (fixed profit/loss)
  * When OFF: Use DOL-based targets relative to session
- Removed partial profit taking logic
- Stop losses placed few pips below FVG boundaries for better protection
- Both modes can still run independently with separate magic numbers
- Simple mode remains unchanged (one trade at a time, Eprofit/Eloss)

Entry Logic:
- Close above ENC = BUY, Close below ENC = SELL
- Silver Bullet mode uses session-specific liquidity targets
- Simple mode uses fixed profit/loss targets
*/

#include <FVGLibrary.mqh>
#include <LiquidityLibrary.mqh>

//--- Input parameters
input group "=== MODE SELECTION (Both can be active) ==="
input bool InpUseSilverBulletMode = true;        // Use Silver Bullet ENC Mode
input bool InpUseSimpleMode = false;             // Use Simple ENC Mode (One at a time)

input group "=== FVG Settings ==="
input double InpMinGapSize = 50.0;               // Minimum gap size in points
input ENUM_TIMEFRAMES InpTimeframe = PERIOD_M5;  // FVG detection timeframe
input ENUM_TIMEFRAMES InpAccuracyTF = PERIOD_M1; // Accuracy timeframe
input bool InpAccuracy = false;                  // Use 1M entry precision
input bool InpDrawObjects = true;                // Draw visual objects

input group "=== Trading Settings ==="
input double InpLotSize = 0.01;                  // Lot size
input double InpEProfit = 10.0;                  // Profit target ($) - SIMPLE mode only
input double InpELoss = 10.0;                    // Loss threshold ($) - Both modes

input group "=== Silver Bullet Settings ==="
input int InpGMTOffset = 0;                      // GMT offset for session timing (0 for GMT+0, -4 for NY)
input bool InpTradeSB1 = true;                   // Trade Silver Bullet 1 (3-4am GMT) → Sydney DOL
input bool InpTradeSB2 = true;                   // Trade Silver Bullet 2 (10-11am GMT) → Tokyo DOL
input bool InpTradeSB3 = true;                   // Trade Silver Bullet 3 (2-3pm GMT) → London DOL
input bool InpSBUseFixedTargets = true;          // Use Eprofit/Eloss (ON) or DOL targets (OFF)
input double InpMinDOLDistance = 20.0;           // Minimum pips to DOL target (when using DOL mode)
input double InpDOLTargetPercent = 80.0;         // Target % to DOL (when using DOL mode)
input double InpSLBufferPoints = 5.0;            // Stop loss buffer points below FVG

input group "=== Encroachment Filters ==="
input bool InpEncScalpUseFilters = false;        // Use additional filters
input int InpEncScalpMinGapPoints = 30;          // Minimum gap size for entry
input bool InpEncScalpCheckTrend = false;        // Check trend alignment
input int InpEncScalpTrendPeriod = 20;           // Trend MA period

//--- Global variables
CFVGLibrary* fvg_lib;
CLiquidityLibrary* liq_lib;
int trend_ma_handle = INVALID_HANDLE;

//--- EA Magic numbers (different for each mode)
const int MAGIC_SB = 1004;      // Silver Bullet mode
const int MAGIC_SIMPLE = 1005;  // Simple mode

//--- Trade tracking for Silver Bullet mode
struct SilverBulletTrade
{
   ulong ticket;
   int fvg_id;
   string dol_target;
   double target_price;
   double entry_price;
   double stop_loss_price;
   datetime entry_time;
   ENUM_SESSION_TYPE session;
};
SilverBulletTrade sb_trades[];
int sb_trade_count = 0;

//--- Simple mode tracking
bool simple_mode_has_trade = false;

//--- Silver Bullet window tracking (one trade per window)
bool sb1_trade_active = false;
bool sb2_trade_active = false;
bool sb3_trade_active = false;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("=== PLAYGROUND EA v1.04 - Session DOL Targeting ===");
   Print("Silver Bullet Mode: ", (InpUseSilverBulletMode ? "ENABLED" : "DISABLED"));
   Print("Simple Mode: ", (InpUseSimpleMode ? "ENABLED" : "DISABLED"));
   
   if(!InpUseSilverBulletMode && !InpUseSimpleMode)
   {
      Print("ERROR: At least one mode must be enabled!");
      return(INIT_FAILED);
   }
   
   // Initialize FVG Library
   fvg_lib = new CFVGLibrary(_Symbol, InpTimeframe, InpAccuracyTF, 
                            InpMinGapSize, InpAccuracy, InpDrawObjects);
   
   if(!fvg_lib.Init())
   {
      Print("Failed to initialize FVG Library!");
      return(INIT_FAILED);
   }
   fvg_lib.SetCallback(OnFVGEvent);
   
   // Initialize Liquidity Library
   liq_lib = new CLiquidityLibrary(_Symbol, InpTimeframe, InpGMTOffset, InpDrawObjects);
   
   if(!liq_lib.Init())
   {
      Print("Failed to initialize Liquidity Library!");
      return(INIT_FAILED);
   }
   liq_lib.SetCallback(OnLiquidityEvent);
   
   // Initialize trend MA if needed
   if(InpEncScalpCheckTrend)
   {
      trend_ma_handle = iMA(_Symbol, InpTimeframe, InpEncScalpTrendPeriod, 0, MODE_EMA, PRICE_CLOSE);
      if(trend_ma_handle == INVALID_HANDLE)
      {
         Print("Failed to create trend MA indicator!");
         return(INIT_FAILED);
      }
   }
   
   // Initialize trade arrays
   ArrayResize(sb_trades, 50);
   sb_trade_count = 0;
   simple_mode_has_trade = false;
   
   PrintConfiguration();
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   if(fvg_lib != NULL)
   {
      fvg_lib.PrintFVGStats();
      fvg_lib.Deinit();
      delete fvg_lib;
      fvg_lib = NULL;
   }
   
   if(liq_lib != NULL)
   {
      liq_lib.PrintLiquidityStats();
      liq_lib.PrintDailyBias();
      liq_lib.Deinit();
      delete liq_lib;
      liq_lib = NULL;
   }
   
   if(trend_ma_handle != INVALID_HANDLE)
      IndicatorRelease(trend_ma_handle);
   
   Print("=== PLAYGROUND EA v1.04 Deinitialized ===");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Update libraries
   if(fvg_lib != NULL) 
      fvg_lib.OnTick();
   
   if(liq_lib != NULL) 
      liq_lib.OnTick();
   
   // Manage open positions
   ManageOpenPositions();
   
   // Update simple mode trade status
   if(InpUseSimpleMode)
      UpdateSimpleModeStatus();
   
   // Update Silver Bullet window status
   if(InpUseSilverBulletMode)
      UpdateSilverBulletWindowStatus();
}

//+------------------------------------------------------------------+
//| FVG Event Callback                                               |
//+------------------------------------------------------------------+
void OnFVGEvent(FVGInfo& fvg, string event_type)
{
   if(event_type == "FVG_FORMED")
   {
      Print("=== FVG FORMED ===");
      Print("ID: ", fvg.fvg_id, " | Type: ", (fvg.is_bullish ? "BULLISH" : "BEARISH"));
      Print("Size: ", DoubleToString(fvg.gap_size, 1), " points");
   }
   else if(event_type == "FVG_ENCROACHED" || event_type == "FVG_ENCROACHED_HA")
   {
      Print("=== FVG ENCROACHED ===");
      Print("ID: ", fvg.fvg_id, " | Bias: ", fvg.directional_bias);
      
      // Handle both modes independently
      if(InpUseSilverBulletMode)
      {
         HandleSilverBulletEncroachment(fvg);
      }
      
      if(InpUseSimpleMode)
      {
         HandleSimpleEncroachment(fvg);
      }
   }
   else if(event_type == "FVG_RESET")
   {
      Print("=== FVG RESET ===");
      Print("ID: ", fvg.fvg_id, " invalidated by inverse candle");
   }
}

//+------------------------------------------------------------------+
//| Liquidity Event Callback                                         |
//+------------------------------------------------------------------+
void OnLiquidityEvent(LiquidityInfo& liq, string event_type)
{
   if(event_type == "LIQUIDITY_CREATED")
   {
      Print("=== LIQUIDITY CREATED ===");
      Print("ID: ", liq.liquidity_id, " | Type: ", EnumToString(liq.type));
      Print("Price: ", DoubleToString(liq.price_level, _Digits));
   }
   else if(event_type == "LIQUIDITY_SWEPT")
   {
      Print("=== LIQUIDITY SWEPT ===");
      Print("ID: ", liq.liquidity_id, " | Type: ", EnumToString(liq.type));
      Print("Price: ", DoubleToString(liq.price_level, _Digits));
   }
}

//+------------------------------------------------------------------+
//| Handle Silver Bullet Encroachment                                |
//+------------------------------------------------------------------+
void HandleSilverBulletEncroachment(FVGInfo& fvg)
{
   // Check if in Silver Bullet window
   if(!IsInSilverBulletWindow())
   {
      Print("Outside Silver Bullet window - FVG noted but no SB trade");
      return;
   }
   
   // Get current session
   ENUM_SESSION_TYPE current_session = GetCurrentSilverBulletSession();
   if(current_session == -1)
   {
      Print("Cannot determine Silver Bullet session");
      return;
   }
   
   // Check if this window already has an active trade (one trade per window rule)
   if(IsWindowTradeActive(current_session))
   {
      Print("Trade already active in this Silver Bullet window - skipping");
      return;
   }
   
   // Check filters
   if(!ShouldEnterEncScalp(fvg))
   {
      Print("Encroachment filters not met - skipping SB trade");
      return;
   }
   
   // Get DOL for current session
   string session_dol = GetSessionDOL(current_session);
   double dol_price = GetSessionDOLPrice(current_session);
   
   if(dol_price == 0.0)
   {
      Print("No valid session DOL found");
      return;
   }
   
   // If using DOL mode (not fixed targets), check minimum distance
   if(!InpSBUseFixedTargets)
   {
      double current_price = iClose(_Symbol, InpTimeframe, 0);
      double distance_pips = MathAbs(dol_price - current_price) / (SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10);
      
      if(distance_pips < InpMinDOLDistance)
      {
         Print("DOL too close (", DoubleToString(distance_pips, 1), " pips) - minimum: ", InpMinDOLDistance);
         return;
      }
   }
   
   // Determine trade direction based on ENC logic
   double current_close = iClose(_Symbol, InpTimeframe, 0);
   string trade_direction = "";
   
   if(current_close > fvg.enc_point)
      trade_direction = "BUY";
   else if(current_close < fvg.enc_point)
      trade_direction = "SELL";
   else
   {
      Print("Close exactly at ENC point - no SB trade");
      return;
   }
   
   Print("=== SILVER BULLET ENC SIGNAL ===");
   Print("Session: ", GetSessionName(current_session));
   Print("FVG ID: ", fvg.fvg_id);
   Print("ENC Point: ", DoubleToString(fvg.enc_point, _Digits));
   Print("Current Close: ", DoubleToString(current_close, _Digits));
   Print("Direction: ", trade_direction);
   Print("Session DOL: ", session_dol, " (", DoubleToString(dol_price, _Digits), ")");
   
   // Open trade
   ulong ticket = 0;
   if(trade_direction == "BUY")
      ticket = OpenBuy(InpLotSize, MAGIC_SB);
   else if(trade_direction == "SELL")
      ticket = OpenSell(InpLotSize, MAGIC_SB);
   
   if(ticket > 0)
   {
      double current_price = iClose(_Symbol, InpTimeframe, 0);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      
      // Calculate target based on mode
      double target_price = 0.0;
      if(InpSBUseFixedTargets)
      {
         // Fixed target mode - will use Eprofit in position management
         target_price = 0.0;
         Print("Using fixed profit target: $", DoubleToString(InpEProfit, 2));
      }
      else
      {
         // DOL target mode
         double distance_to_dol = MathAbs(dol_price - current_price);
         target_price = current_price + (distance_to_dol * InpDOLTargetPercent / 100.0) * (trade_direction == "BUY" ? 1 : -1);
         Print("DOL Target (", InpDOLTargetPercent, "%): ", DoubleToString(target_price, _Digits));
      }
      
      // Calculate stop loss - few pips below FVG boundary
      double stop_price = 0.0;
      if(trade_direction == "BUY")
         stop_price = fvg.bottom_price - (InpSLBufferPoints * point);
      else
         stop_price = fvg.top_price + (InpSLBufferPoints * point);
      
      // Store Silver Bullet trade
      if(sb_trade_count >= ArraySize(sb_trades))
         ArrayResize(sb_trades, ArraySize(sb_trades) + 20);
      
      sb_trades[sb_trade_count].ticket = ticket;
      sb_trades[sb_trade_count].fvg_id = fvg.fvg_id;
      sb_trades[sb_trade_count].dol_target = session_dol;
      sb_trades[sb_trade_count].target_price = target_price;
      sb_trades[sb_trade_count].entry_price = current_price;
      sb_trades[sb_trade_count].stop_loss_price = stop_price;
      sb_trades[sb_trade_count].entry_time = TimeCurrent();
      sb_trades[sb_trade_count].session = current_session;
      sb_trade_count++;
      
      // Mark window as having active trade
      SetWindowTradeActive(current_session, true);
      
      // Associate with FVG
      fvg_lib.AssociateTradeWithFVG(fvg.fvg_id, ticket);
      
      Print("=== SILVER BULLET ENC OPENED ===");
      Print("Ticket: ", ticket);
      Print("Stop Loss: ", DoubleToString(stop_price, _Digits), " (", InpSLBufferPoints, " pts buffer)");
      Print("Target Mode: ", (InpSBUseFixedTargets ? "FIXED ($" + DoubleToString(InpEProfit, 2) + ")" : "DOL-BASED"));
      Print("================================");
   }
}

//+------------------------------------------------------------------+
//| Handle Simple Encroachment                                       |
//+------------------------------------------------------------------+
void HandleSimpleEncroachment(FVGInfo& fvg)
{
   // Check if we already have a trade
   if(simple_mode_has_trade)
   {
      Print("Simple mode already has an active trade - skipping");
      return;
   }
   
   // Check filters
   if(!ShouldEnterEncScalp(fvg))
   {
      Print("Encroachment filters not met - skipping simple trade");
      return;
   }
   
   // Determine trade direction based on ENC logic
   double current_close = iClose(_Symbol, InpTimeframe, 0);
   string trade_direction = "";
   
   if(current_close > fvg.enc_point)
      trade_direction = "BUY";
   else if(current_close < fvg.enc_point)
      trade_direction = "SELL";
   else
   {
      Print("Close exactly at ENC point - no simple trade");
      return;
   }
   
   Print("=== SIMPLE ENC SIGNAL ===");
   Print("FVG ID: ", fvg.fvg_id);
   Print("ENC Point: ", DoubleToString(fvg.enc_point, _Digits));
   Print("Current Close: ", DoubleToString(current_close, _Digits));
   Print("Direction: ", trade_direction);
   
   // Open trade
   ulong ticket = 0;
   if(trade_direction == "BUY")
      ticket = OpenBuy(InpLotSize, MAGIC_SIMPLE);
   else if(trade_direction == "SELL")
      ticket = OpenSell(InpLotSize, MAGIC_SIMPLE);
   
   if(ticket > 0)
   {
      simple_mode_has_trade = true;
      
      // Associate with FVG
      fvg_lib.AssociateTradeWithFVG(fvg.fvg_id, ticket);
      
      Print("=== SIMPLE ENC OPENED ===");
      Print("Ticket: ", ticket);
      Print("Profit Target: $", DoubleToString(InpEProfit, 2));
      Print("Loss Threshold: $", DoubleToString(InpELoss, 2));
      Print("=========================");
   }
}

//+------------------------------------------------------------------+
//| Check if should enter encroachment scalp                        |
//+------------------------------------------------------------------+
bool ShouldEnterEncScalp(FVGInfo& fvg)
{
   if(!InpEncScalpUseFilters)
      return true;
   
   // Check minimum gap size
   if(fvg.gap_size < InpEncScalpMinGapPoints)
   {
      Print("FVG gap too small: ", fvg.gap_size, " < ", InpEncScalpMinGapPoints);
      return false;
   }
   
   // Check trend alignment if enabled
   if(InpEncScalpCheckTrend)
   {
      if(!IsTrendAligned(fvg))
      {
         Print("Trend not aligned with FVG");
         return false;
      }
   }
   
   return true;
}

//+------------------------------------------------------------------+
//| Check if trend is aligned                                        |
//+------------------------------------------------------------------+
bool IsTrendAligned(FVGInfo& fvg)
{
   if(trend_ma_handle == INVALID_HANDLE)
      return true;
   
   double ma_values[2];
   if(CopyBuffer(trend_ma_handle, 0, 0, 2, ma_values) < 2)
      return true;
   
   double current_price = iClose(_Symbol, InpTimeframe, 0);
   bool is_uptrend = (current_price > ma_values[0] && ma_values[0] > ma_values[1]);
   bool is_downtrend = (current_price < ma_values[0] && ma_values[0] < ma_values[1]);
   
   // For bullish FVG, prefer uptrend
   if(fvg.is_bullish && is_uptrend)
      return true;
   
   // For bearish FVG, prefer downtrend
   if(!fvg.is_bullish && is_downtrend)
      return true;
   
   return false;
}

//+------------------------------------------------------------------+
//| Check if in Silver Bullet window                                |
//+------------------------------------------------------------------+
bool IsInSilverBulletWindow()
{
   if(liq_lib == NULL) return false;
   
   return (liq_lib.IsInSession(SESSION_SILVER_BULLET_1) && InpTradeSB1) ||
          (liq_lib.IsInSession(SESSION_SILVER_BULLET_2) && InpTradeSB2) ||
          (liq_lib.IsInSession(SESSION_SILVER_BULLET_3) && InpTradeSB3);
}

//+------------------------------------------------------------------+
//| Get current Silver Bullet session                               |
//+------------------------------------------------------------------+
ENUM_SESSION_TYPE GetCurrentSilverBulletSession()
{
   if(liq_lib == NULL) return (ENUM_SESSION_TYPE)-1;
   
   if(liq_lib.IsInSession(SESSION_SILVER_BULLET_1) && InpTradeSB1)
      return SESSION_SILVER_BULLET_1;
   else if(liq_lib.IsInSession(SESSION_SILVER_BULLET_2) && InpTradeSB2)
      return SESSION_SILVER_BULLET_2;
   else if(liq_lib.IsInSession(SESSION_SILVER_BULLET_3) && InpTradeSB3)
      return SESSION_SILVER_BULLET_3;
   
   return (ENUM_SESSION_TYPE)-1;
}

//+------------------------------------------------------------------+
//| Get session DOL string                                          |
//+------------------------------------------------------------------+
string GetSessionDOL(ENUM_SESSION_TYPE session)
{
   switch(session)
   {
      case SESSION_SILVER_BULLET_1: return "SYDNEY_SESSION";
      case SESSION_SILVER_BULLET_2: return "TOKYO_SESSION";
      case SESSION_SILVER_BULLET_3: return "LONDON_SESSION";
      default: return "UNKNOWN";
   }
}

//+------------------------------------------------------------------+
//| Get session DOL price                                           |
//+------------------------------------------------------------------+
double GetSessionDOLPrice(ENUM_SESSION_TYPE session)
{
   if(liq_lib == NULL) return 0.0;
   
   SessionData session_data;
   double current_price = iClose(_Symbol, InpTimeframe, 0);
   
   switch(session)
   {
      case SESSION_SILVER_BULLET_1:
         // Sydney session
         session_data = liq_lib.GetSessionData(SESSION_SYDNEY);
         // Return high if price below it, low if price above it
         if(current_price < session_data.session_high && session_data.session_high != 0)
            return session_data.session_high;
         else if(session_data.session_low != 0)
            return session_data.session_low;
         break;
         
      case SESSION_SILVER_BULLET_2:
         // Tokyo session
         session_data = liq_lib.GetSessionData(SESSION_TOKYO);
         if(current_price < session_data.session_high && session_data.session_high != 0)
            return session_data.session_high;
         else if(session_data.session_low != 0)
            return session_data.session_low;
         break;
         
      case SESSION_SILVER_BULLET_3:
         // London session
         session_data = liq_lib.GetSessionData(SESSION_LONDON);
         if(current_price < session_data.session_high && session_data.session_high != 0)
            return session_data.session_high;
         else if(session_data.session_low != 0)
            return session_data.session_low;
         break;
   }
   
   return 0.0;
}

//+------------------------------------------------------------------+
//| Get session name                                                 |
//+------------------------------------------------------------------+
string GetSessionName(ENUM_SESSION_TYPE session)
{
   switch(session)
   {
      case SESSION_SILVER_BULLET_1: return "SB1 (3-4am)";
      case SESSION_SILVER_BULLET_2: return "SB2 (10-11am)";
      case SESSION_SILVER_BULLET_3: return "SB3 (2-3pm)";
      default: return "UNKNOWN";
   }
}

//+------------------------------------------------------------------+
//| Check if window has active trade                                |
//+------------------------------------------------------------------+
bool IsWindowTradeActive(ENUM_SESSION_TYPE session)
{
   switch(session)
   {
      case SESSION_SILVER_BULLET_1: return sb1_trade_active;
      case SESSION_SILVER_BULLET_2: return sb2_trade_active;
      case SESSION_SILVER_BULLET_3: return sb3_trade_active;
      default: return false;
   }
}

//+------------------------------------------------------------------+
//| Set window trade active status                                   |
//+------------------------------------------------------------------+
void SetWindowTradeActive(ENUM_SESSION_TYPE session, bool active)
{
   switch(session)
   {
      case SESSION_SILVER_BULLET_1: sb1_trade_active = active; break;
      case SESSION_SILVER_BULLET_2: sb2_trade_active = active; break;
      case SESSION_SILVER_BULLET_3: sb3_trade_active = active; break;
   }
}

//+------------------------------------------------------------------+
//| Update Silver Bullet window status                              |
//+------------------------------------------------------------------+
void UpdateSilverBulletWindowStatus()
{
   // Check each Silver Bullet trade and update window status
   for(int i = 0; i < sb_trade_count; i++)
   {
      if(!PositionSelectByTicket(sb_trades[i].ticket))
      {
         // Trade closed - mark window as available
         SetWindowTradeActive(sb_trades[i].session, false);
      }
   }
}

//+------------------------------------------------------------------+
//| Update simple mode trade status                                  |
//+------------------------------------------------------------------+
void UpdateSimpleModeStatus()
{
   // Check if we still have an active SIMPLE mode trade
   bool has_active = false;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol && 
            (int)PositionGetInteger(POSITION_MAGIC) == MAGIC_SIMPLE)
         {
            has_active = true;
            break;
         }
      }
   }
   
   simple_mode_has_trade = has_active;
}

//+------------------------------------------------------------------+
//| Trading functions                                                |
//+------------------------------------------------------------------+
ulong OpenBuy(double lotSize, int magic) 
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lotSize;
    request.type = ORDER_TYPE_BUY;
    request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    request.deviation = 20;
    request.type_filling = ORDER_FILLING_FOK;
    request.magic = magic;
    
    if (OrderSend(request, result)) {
        if (result.deal > 0) {
            Print("Buy order opened. Ticket: ", result.deal, " | Magic: ", magic);
            return result.deal;
        }
    }
    return 0;
}

ulong OpenSell(double lotSize, int magic) 
{
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = lotSize;
    request.type = ORDER_TYPE_SELL;
    request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    request.deviation = 20;
    request.type_filling = ORDER_FILLING_FOK;
    request.magic = magic;
    
    if (OrderSend(request, result)) {
        if (result.deal > 0) {
            Print("Sell order opened. Ticket: ", result.deal, " | Magic: ", magic);
            return result.deal;
        }
    }
    return 0;
}


void CloseBuyByTicket(ulong ticket) 
{
    if (!PositionSelectByTicket(ticket)) return;
    double volume = PositionGetDouble(POSITION_VOLUME);
    double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    int magic = (int)PositionGetInteger(POSITION_MAGIC);
    
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = volume;
    request.type = ORDER_TYPE_SELL;
    request.price = price;
    request.deviation = 20;
    request.type_filling = ORDER_FILLING_FOK;
    request.position = ticket;
    request.magic = magic;
    
    if (OrderSend(request, result)) {
        Print("Buy position closed. Ticket: ", ticket);
    }
}

void CloseSellByTicket(ulong ticket) 
{
    if (!PositionSelectByTicket(ticket)) return;
    double volume = PositionGetDouble(POSITION_VOLUME);
    double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    int magic = (int)PositionGetInteger(POSITION_MAGIC);
    
    MqlTradeRequest request;
    MqlTradeResult result;
    ZeroMemory(request);
    ZeroMemory(result);
    request.action = TRADE_ACTION_DEAL;
    request.symbol = _Symbol;
    request.volume = volume;
    request.type = ORDER_TYPE_BUY;
    request.price = price;
    request.deviation = 20;
    request.type_filling = ORDER_FILLING_FOK;
    request.position = ticket;
    request.magic = magic;
    
    if (OrderSend(request, result)) {
        Print("Sell position closed. Ticket: ", ticket);
    }
}

//+------------------------------------------------------------------+
//| Manage open positions                                            |
//+------------------------------------------------------------------+
void ManageOpenPositions()
{
    for (int i = PositionsTotal() - 1; i >= 0; i--) 
    {
        ulong ticket = PositionGetTicket(i);
        if (PositionSelectByTicket(ticket)) 
        {
            if (PositionGetString(POSITION_SYMBOL) == _Symbol)
            {
                int magic = (int)PositionGetInteger(POSITION_MAGIC);
                double profit = PositionGetDouble(POSITION_PROFIT);
                
                // Handle SIMPLE mode trades
                if(magic == MAGIC_SIMPLE && InpUseSimpleMode)
                {
                    // Simple mode: Use Eprofit and Eloss
                    if (profit >= InpEProfit) 
                    {
                        Print(">>> PROFIT TARGET REACHED (SIMPLE) <<<");
                        Print("Ticket: ", ticket, " | Profit: $", DoubleToString(profit, 2));
                        
                        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) 
                            CloseBuyByTicket(ticket);
                        else 
                            CloseSellByTicket(ticket);
                        
                        simple_mode_has_trade = false;
                        continue;
                    }
                    
                    if (profit <= -InpELoss) 
                    {
                        Print(">>> LOSS THRESHOLD HIT (SIMPLE) <<<");
                        Print("Ticket: ", ticket, " | Loss: $", DoubleToString(profit, 2));
                        
                        if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) 
                            CloseBuyByTicket(ticket);
                        else 
                            CloseSellByTicket(ticket);
                        
                        simple_mode_has_trade = false;
                        continue;
                    }
                }
                
                // Handle SILVER BULLET mode trades
                if(magic == MAGIC_SB && InpUseSilverBulletMode)
                {
                    // Find trade in tracking array
                    int trade_index = -1;
                    for(int j = 0; j < sb_trade_count; j++)
                    {
                        if(sb_trades[j].ticket == ticket)
                        {
                            trade_index = j;
                            break;
                        }
                    }
                    
                    if(trade_index != -1)
                    {
                        // Check stop loss first
                        if(CheckSilverBulletStopLoss(ticket, trade_index))
                            continue;
                        
                        // Check targets based on mode
                        if(InpSBUseFixedTargets)
                        {
                            // Fixed target mode: Use Eprofit and Eloss
                            if (profit >= InpEProfit) 
                            {
                                Print(">>> PROFIT TARGET REACHED (SILVER BULLET - FIXED) <<<");
                                Print("Ticket: ", ticket, " | Profit: $", DoubleToString(profit, 2));
                                
                                if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) 
                                    CloseBuyByTicket(ticket);
                                else 
                                    CloseSellByTicket(ticket);
                                
                                // Mark window as available
                                SetWindowTradeActive(sb_trades[trade_index].session, false);
                                continue;
                            }
                            
                            if (profit <= -InpELoss) 
                            {
                                Print(">>> LOSS THRESHOLD HIT (SILVER BULLET - FIXED) <<<");
                                Print("Ticket: ", ticket, " | Loss: $", DoubleToString(profit, 2));
                                
                                if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) 
                                    CloseBuyByTicket(ticket);
                                else 
                                    CloseSellByTicket(ticket);
                                
                                // Mark window as available
                                SetWindowTradeActive(sb_trades[trade_index].session, false);
                                continue;
                            }
                        }
                        else
                        {
                            // DOL target mode: Check if price reached target
                            double current_price = iClose(_Symbol, InpTimeframe, 0);
                            bool is_buy = (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY);
                            bool target_reached = false;
                            
                            if(is_buy && current_price >= sb_trades[trade_index].target_price)
                                target_reached = true;
                            else if(!is_buy && current_price <= sb_trades[trade_index].target_price)
                                target_reached = true;
                            
                            if(target_reached)
                            {
                                Print(">>> DOL TARGET REACHED (SILVER BULLET) <<<");
                                Print("Ticket: ", ticket);
                                Print("Target: ", DoubleToString(sb_trades[trade_index].target_price, _Digits));
                                Print("Current: ", DoubleToString(current_price, _Digits));
                                Print("Profit: $", DoubleToString(profit, 2));
                                
                                if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) 
                                    CloseBuyByTicket(ticket);
                                else 
                                    CloseSellByTicket(ticket);
                                
                                // Mark window as available
                                SetWindowTradeActive(sb_trades[trade_index].session, false);
                                continue;
                            }
                            
                            // Still check loss threshold in DOL mode
                            if (profit <= -InpELoss) 
                            {
                                Print(">>> LOSS THRESHOLD HIT (SILVER BULLET - DOL) <<<");
                                Print("Ticket: ", ticket, " | Loss: $", DoubleToString(profit, 2));
                                
                                if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) 
                                    CloseBuyByTicket(ticket);
                                else 
                                    CloseSellByTicket(ticket);
                                
                                // Mark window as available
                                SetWindowTradeActive(sb_trades[trade_index].session, false);
                                continue;
                            }
                        }
                    }
                }
            }
        }
    }
}

//+------------------------------------------------------------------+
//| Check Silver Bullet stop loss                                   |
//+------------------------------------------------------------------+
bool CheckSilverBulletStopLoss(ulong ticket, int trade_index)
{
    if(trade_index < 0 || trade_index >= sb_trade_count) return false;
    
    double current_bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    double current_ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    bool should_close = false;
    
    if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
    {
        if(current_bid <= sb_trades[trade_index].stop_loss_price)
        {
            should_close = true;
            Print(">>> STOP LOSS HIT (BUY) <<<");
            Print("Ticket: ", ticket);
            Print("SL: ", DoubleToString(sb_trades[trade_index].stop_loss_price, _Digits));
            Print("Bid: ", DoubleToString(current_bid, _Digits));
        }
    }
    else
    {
        if(current_ask >= sb_trades[trade_index].stop_loss_price)
        {
            should_close = true;
            Print(">>> STOP LOSS HIT (SELL) <<<");
            Print("Ticket: ", ticket);
            Print("SL: ", DoubleToString(sb_trades[trade_index].stop_loss_price, _Digits));
            Print("Ask: ", DoubleToString(current_ask, _Digits));
        }
    }
    
    if(should_close)
    {
        if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            CloseBuyByTicket(ticket);
        else
            CloseSellByTicket(ticket);
        
        // Mark window as available
        SetWindowTradeActive(sb_trades[trade_index].session, false);
        return true;
    }
    
    return false;
}

//+------------------------------------------------------------------+
//| Print configuration                                              |
//+------------------------------------------------------------------+
void PrintConfiguration()
{
   Print("=== PLAYGROUND EA v1.04 CONFIGURATION ===");
   Print("Silver Bullet Mode: ", (InpUseSilverBulletMode ? "ENABLED" : "DISABLED"));
   Print("Simple Mode: ", (InpUseSimpleMode ? "ENABLED" : "DISABLED"));
   Print("Timeframe: ", EnumToString(InpTimeframe));
   Print("Min Gap Size: ", InpMinGapSize, " points");
   Print("Lot Size: ", InpLotSize);
   Print("");
   
   if(InpUseSilverBulletMode)
   {
      Print("=== SILVER BULLET ENC MODE ===");
      Print("GMT Offset: ", InpGMTOffset);
      Print("SB1 (3-4am GMT): ", (InpTradeSB1 ? "ON → SYDNEY DOL" : "OFF"));
      Print("SB2 (10-11am GMT): ", (InpTradeSB2 ? "ON → TOKYO DOL" : "OFF"));
      Print("SB3 (2-3pm GMT): ", (InpTradeSB3 ? "ON → LONDON DOL" : "OFF"));
      Print("");
      Print("Target Mode: ", (InpSBUseFixedTargets ? "FIXED PROFIT/LOSS" : "DOL-BASED"));
      if(InpSBUseFixedTargets)
      {
         Print("Profit Target: $", DoubleToString(InpEProfit, 2));
         Print("Loss Threshold: $", DoubleToString(InpELoss, 2));
      }
      else
      {
         Print("Min DOL Distance: ", InpMinDOLDistance, " pips");
         Print("DOL Target: ", InpDOLTargetPercent, "% to session DOL");
         Print("Loss Threshold: $", DoubleToString(InpELoss, 2));
      }
      Print("SL Buffer: ", InpSLBufferPoints, " points below FVG");
      Print("One Trade Per Window: ENABLED");
      Print("");
      Print("Session DOL Mapping:");
      Print("  SB1 → Sydney Session High/Low");
      Print("  SB2 → Tokyo Session High/Low");
      Print("  SB3 → London Session High/Low");
   }
   
   if(InpUseSimpleMode)
   {
      Print("");
      Print("=== SIMPLE ENC MODE ===");
      Print("Profit Target: $", DoubleToString(InpEProfit, 2));
      Print("Loss Threshold: $", DoubleToString(InpELoss, 2));
      Print("Trading Rule: One trade at a time");
   }
   
   Print("");
   Print("=== ENCROACHMENT LOGIC ===");
   Print("Entry Rule: Close above ENC = BUY | Close below ENC = SELL");
   Print("Use Filters: ", (InpEncScalpUseFilters ? "YES" : "NO"));
   if(InpEncScalpUseFilters)
   {
      Print("Min Gap Points: ", InpEncScalpMinGapPoints);
      Print("Check Trend: ", (InpEncScalpCheckTrend ? "YES" : "NO"));
      if(InpEncScalpCheckTrend)
         Print("Trend MA Period: ", InpEncScalpTrendPeriod);
   }
   Print("=========================================");
}


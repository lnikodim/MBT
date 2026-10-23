//+------------------------------------------------------------------+
//|                                                   Hon-Matrix.mq5 |
//|                                   Copyright 2025, KSQUANTITATIVE |
//|                                         https://www.ksquants.com |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#property copyright "Copyright 2025, KSQUANTITATIVE";
#property link "https://www.ksquants.com";
#property version "1.2";
#property strict
//+------------------------------------------------------------------+
//| Enumerations (Must be defined first)                             |
//+------------------------------------------------------------------+
enum ENUM_MARKET_PHASE
  {
   MARKET_RANGING,
   MARKET_TRENDING,
   MARKET_CONSOLIDATING,
   MARKET_UNKNOWN
  };

enum ENUM_TREND_DIRECTION
  {
   TREND_BULLISH,
   TREND_BEARISH,
   TREND_NEUTRAL
  };
input group "=== BACKTEST VALIDATION ===";
input datetime Start_Date = D'2020.01.01';     // Backtest Start Date (Min 1 Year)
input double   StartCapital = 10000;           // Starting Capital for Validation
input bool     EnableBacktestValidation = true; // Enable Backtest Validation
//--- Input Parameters with Safe Defaults
input group "=== RISK MANAGEMENT ===";
input double MaxAccountExposure = 15.0;       // Max Account Exposure (%)
input double CloseLosesAtPercent = 30.0;      // Close all if loss reaches this % of account (0=disable)
input double CloseProfitsAtPercent = 40.0;    // Close all if profit reaches this % of account (0=disable)
input double InitialLotSize = 0.06;           // Initial Lot Size
input double MaxLotSize = 1.0;                // Maximum Lot Size
input double LotMultiplier = 1.1;             // Lot Multiplier (Safe Default)
input int    MaxGridOrders = 5;               // Max Grid Orders (Safe Default)
input double TakeProfitPips = 50.0;           // Ultimate Take Profit (Pips)
input double BreakevenTrigger = 20.0;         // Breakeven Trigger (Pips)
input double TrailingDistance = 15.0;         // Trailing Stop Distance (Pips)
input bool   UseTrailingStop = true;          // Use Trailing Stop & Breakeven

//+------------------------------------------------------------------+
//| NEWS FILTER SETTINGS - Integrated Robust News Filter            |
//+------------------------------------------------------------------+
input group "=== NEWS FILTER SETTINGS ===";
input bool     EnableNewsFilter = true;       // Enable/Disable the news filter
input int      StopBeforeNewsMin = 30;        // Stop trading Before News (minutes)
input int      StopAfterNewsMin = 30;         // Stop trading After News (minutes)
input bool     EnableHighImpact = true;       // Enable high impact news filter
input bool     EnableMediumImpact = true;     // Enable medium impact news filter
input bool     EnableLowImpact = false;       // Enable low impact news filter
input bool     UseInternalCalendar = true;    // Use MT5 internal calendar (recommended)
input string   NewsSymbols = "USD,EUR,GBP,CHF,CAD,AUD,NZD,JPY"; // Currencies for news filter
input bool     ClosePositionsBeforeNews = false; // Close all positions before news
input bool     AlertOnUpcomingNews = true;    // Alert for upcoming news
input bool     DrawNewsLines = true;          // Draw news lines on chart
input color    HighImpactColor = clrRed;      // High impact news line color
input color    MediumImpactColor = clrOrange; // Medium impact news line color
input color    LowImpactColor = clrYellow;    // Low impact news line color

input group "=== MARKET ANALYSIS ===";
input int    AMA_Period = 21;                 // AMA Period
input int    ATR_Period = 14;                 // ATR Period
input double ATR_Threshold = 1.5;             // ATR Volatility Threshold
input ENUM_TIMEFRAMES TrendTimeframe = PERIOD_H4; // Trend Filter Timeframe
input int    TrendMA_Period = 100;            // Trend MA Period

input group "=== FIBONACCI SETTINGS ===";
input int    SwingLookback = 50;              // Swing Points Lookback
input bool   UseFibonacciGrid = true;         // Use Fibonacci Grid Spacing
input double FibLevel1 = 38.2;                // Fibonacci Level 1
input double FibLevel2 = 50.0;                // Fibonacci Level 2
input double FibLevel3 = 61.8;                // Fibonacci Level 3
input double FibLevel4 = 78.6;                // Fibonacci Level 4

input group "=== ENHANCED SIMPLE ENTRY ===";
input bool   UseEnhancedEntry = true;          // Use Enhanced S/R Entry System
input int    SR_LookbackPeriod = 100;          // S/R Detection Lookback Period
input double SR_MinStrength = 3.0;             // Minimum S/R Touch Count
input double SR_ZoneBuffer = 20.0;             // S/R Zone Buffer (Pips)
input bool   UseChannelTrading = true;         // Enable Channel Trading
input int    ChannelMinBars = 50;              // Minimum Channel Length
input double ChannelThreshold = 0.8;           // Channel Strength Threshold
input bool   UseDynamicLotSizing = true;       // Dynamic Lot Sizing based on S/R strength
input group "=== BREAKOUT DETECTION SETTINGS ===";
input double BreakoutMinPips = 5.0;               // Minimum Breakout Distance (Pips)
input double BreakoutMaxPips = 50.0;              // Maximum Breakout Distance (Pips)
input bool   UseMomentumFilter = true;            // Use Momentum Filter
input double MomentumThreshold = 1.2;             // Momentum Threshold
input bool   UseVolumeFilter = true;              // Use Volume Filter
input double VolumeMultiplier = 1.5;              // Volume Multiplier
input double FalseBreakoutFilter = 0.6;           // False Breakout Filter (0-1)
input int    VolumeConfirmPeriod = 10;            // Volume Confirmation Period
input int    BreakoutConfirmBars = 3;             // Breakout Confirmation Bars
input group "=== ENTRY FILTERS ===";
input bool   UseRSIFilter = false;            // Use RSI Filter
input int    RSI_Period = 14;                 // RSI Period
input double RSI_Oversold = 30.0;             // RSI Oversold Level
input double RSI_Overbought = 70.0;           // RSI Overbought Level
input double EntryDistance = 30.0;            // Entry Distance from Fib (Pips)
input bool   UseSimpleEntry = false;          // Use simple trend-following entry

input group "=== TIME FILTER ===";
input bool   UseTimeFilter = false;           // Use Time Filter
input string StartTime = "08:00";             // Trading Start Time
input string EndTime = "18:00";               // Trading End Time

input group "=== ADVANCED ===";
input int    MagicNumber = 777777;            // Magic Number
input string Commentary = "Hon-Matrix";       // Order Comment
input bool   ShowPanel = true;                // Show Control Panel

//--- Global Variables
CTrade trade;
CPositionInfo position;
COrderInfo order;
// Global variables for live adjustments (only used during active trading)
double g_live_multiplier = 0.0;    // 0.0 = use input parameter
double g_live_start_lot = 0.0;     // 0.0 = use input parameter
bool g_live_adjustments_active = false;
//+------------------------------------------------------------------+
//| Enhanced News Filter Class - Fixed Version                       |
//+------------------------------------------------------------------+
struct NewsWebData
  {
   string            time_str;
   string            currency;
   string            impact;
   string            title;

                     NewsWebData()
     {
      time_str = "";
      currency = "";
      impact = "";
      title = "";
     }
  };
struct NewsEvent
  {
   datetime          time;
   string            currency;
   string            title;
   int               impact;  // 1=Low, 2=Medium, 3=High
   bool              processed;

                     NewsEvent()
     {
      time = 0;
      currency = "";
      title = "";
      impact = 0;
      processed = false;
     }
   // ✅ ADD: Copy constructor to eliminate warnings
                     NewsEvent(const NewsEvent &other)
     {
      time = other.time;
      currency = other.currency;
      title = other.title;
      impact = other.impact;
      processed = other.processed;
     }
  };
struct SRLevel
  {
   double            price;
   int               touch_count;
   datetime          first_touch;
   datetime          last_touch;
   bool              is_support;
   double            strength;
   bool              is_active;

                     SRLevel()
     {
      price = 0.0;
      touch_count = 0;
      first_touch = 0;
      last_touch = 0;
      is_support = true;
      strength = 0.0;
      is_active = false;
     }
   // ✅ ADD: Copy constructor to eliminate warnings
                     SRLevel(const SRLevel &other)
     {
      price = other.price;
      touch_count = other.touch_count;
      first_touch = other.first_touch;
      last_touch = other.last_touch;
      is_support = other.is_support;
      strength = other.strength;
      is_active = other.is_active;
     }
  };
struct ChannelInfo
  {
   double            upper_line;
   double            lower_line;
   double            slope;
   int               bar_count;
   double            strength;
   bool              is_active;
   datetime          start_time;

                     ChannelInfo()
     {
      upper_line = 0.0;
      lower_line = 0.0;
      slope = 0.0;
      bar_count = 0;
      strength = 0.0;
      is_active = false;
      start_time = 0;
     }
  };
struct BreakoutInfo
  {
   double            sr_level;
   bool              is_resistance_break;
   datetime          break_time;
   double            break_price;
   double            momentum_score;
   double            volume_score;
   bool              is_confirmed;
   int               confirmation_bars;

                     BreakoutInfo()
     {
      sr_level = 0.0;
      is_resistance_break = false;
      break_time = 0;
      break_price = 0.0;
      momentum_score = 0.0;
      volume_score = 0.0;
      is_confirmed = false;
      confirmation_bars = 0;
     }
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CAdvancedNewsFilter
  {
private:

   NewsEvent         m_news_events[];
   int               m_news_count;
   datetime          m_last_update;
   datetime          m_last_alert_time;
   bool              m_trading_halted;
   string            m_halt_reason;
   string            m_filtered_symbols[];

   // WebRequest fallback variables
   NewsWebData       m_web_news_records[];
   int               m_web_news_count;

public:
                     CAdvancedNewsFilter() : m_news_count(0), m_last_update(0), m_last_alert_time(0),
                     m_trading_halted(false), m_web_news_count(0)
     {
      ParseFilteredSymbols();
     }

   bool              Initialize()
     {
      if(!EnableNewsFilter)
         return true;

      Print("News Filter: Initializing advanced news filter...");

      // Note: WebRequest permission must be set manually in terminal settings
      Print("News Filter: Please ensure WebRequest is enabled in Tools->Options->Expert Advisors");

      UpdateNewsData();
      m_last_update = TimeCurrent();

      Print("News Filter: Initialized successfully with ", m_news_count, " upcoming events");
      return true;
     }

private:
   void              ParseFilteredSymbols()
     {
      string symbols = NewsSymbols;
      StringReplace(symbols, " ", "");

      string parts[];
      int total = StringSplit(symbols, ',', parts);

      ArrayResize(m_filtered_symbols, total);
      for(int i = 0; i < total; i++)
        {
         m_filtered_symbols[i] = parts[i];
         StringToUpper(m_filtered_symbols[i]);
        }
     }

   bool              IsSymbolFiltered(string currency)
     {
      StringToUpper(currency);
      for(int i = 0; i < ArraySize(m_filtered_symbols); i++)
        {
         if(m_filtered_symbols[i] == currency)
            return true;
        }
      return false;
     }

   void              UpdateNewsData()
     {
      m_news_count = 0;
      m_trading_halted = false;
      m_halt_reason = "";

      if(UseInternalCalendar)
        {
         LoadFromInternalCalendar();
        }
      else
        {
         LoadFromWebSource();
        }

      // Sort events by time
      SortNewsByTime();

      // Draw news lines if enabled
      if(DrawNewsLines)
        {
         DrawNewsVerticalLines();
        }
     }

   void              LoadFromInternalCalendar()
     {
      MqlCalendarValue calendar_values[];

      datetime from_time = TimeCurrent();
      datetime to_time = from_time + 7 * 24 * 3600; // Next 7 days

      // Get calendar values for the period
      int total = CalendarValueHistory(calendar_values, from_time, to_time);

      if(total <= 0)
        {
         Print("News Filter: No calendar data available from internal calendar");
         return;
        }

      ArrayResize(m_news_events, total);

      for(int i = 0; i < total && m_news_count < total; i++)
        {
         MqlCalendarEvent event_info;
         MqlCalendarCountry country_info;

         // Get event details
         if(!CalendarEventById(calendar_values[i].event_id, event_info))
            continue;
         if(!CalendarCountryById(event_info.country_id, country_info))
            continue;

         // Filter by impact level
         if(!ShouldProcessImpact(event_info.importance))
            continue;

         // Filter by currency
         if(!IsSymbolFiltered(country_info.currency))
            continue;

         // Store the news event
         m_news_events[m_news_count].time = calendar_values[i].time;
         m_news_events[m_news_count].currency = country_info.currency;
         m_news_events[m_news_count].title = event_info.name;
         m_news_events[m_news_count].impact = (int)event_info.importance;
         m_news_events[m_news_count].processed = false;

         m_news_count++;
        }

      Print("News Filter: Loaded ", m_news_count, " events from internal calendar");
     }

   void              LoadFromWebSource()
     {
      // Simplified web source loading - WebRequest must be configured manually
      string html_content = FetchWebNewsData();
      if(StringLen(html_content) == 0)
        {
         Print("News Filter: Web source unavailable, using internal calendar only");
         return;
        }

      ParseWebNewsData(html_content);

      // Convert web data to internal format
      ArrayResize(m_news_events, m_web_news_count);
      for(int i = 0; i < m_web_news_count; i++)
        {
         m_news_events[i].time = ParseWebTime(m_web_news_records[i].time_str);
         m_news_events[i].currency = m_web_news_records[i].currency;
         m_news_events[i].title = m_web_news_records[i].title;
         m_news_events[i].impact = ParseWebImpact(m_web_news_records[i].impact);
         m_news_events[i].processed = false;
        }
      m_news_count = m_web_news_count;

      Print("News Filter: Loaded ", m_news_count, " events from web source");
     }

   string            FetchWebNewsData()
     {
      string cookie = NULL, headers;
      string reqheaders = "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36\r\n";
      char post[], result[];

      string news_url = "https://nfs.faireconomy.media/ff_calendar_thisweek.json";

      ResetLastError();
      int timeout = 10000;
      int res = WebRequest("GET", news_url, reqheaders, timeout, post, result, headers);

      if(res == -1)
        {
         int error_code = GetLastError();
         Print("News Filter: WebRequest failed. Error: ", error_code);
         if(error_code == 4060) // ERR_FUNCTION_NOT_CONFIRMED
           {
            Print("News Filter: Please add ", news_url, " to allowed URLs in terminal settings");
           }
         return "";
        }

      return CharArrayToString(result);
     }

   void              ParseWebNewsData(string html_content)
     {
      // Simplified parsing - in real implementation, parse JSON/HTML properly
      m_web_news_count = 0;
      ArrayResize(m_web_news_records, 100); // Reasonable initial size

      // This is a placeholder - implement actual parsing based on your data source
      Print("News Filter: Web parsing completed (placeholder implementation)");
     }

   datetime          ParseWebTime(string time_str)
     {
      // Parse time string from web format
      return StringToTime(time_str);
     }

   int               ParseWebImpact(string impact_str)
     {
      if(StringFind(impact_str, "High") >= 0 || StringFind(impact_str, "3") >= 0)
         return 3;
      if(StringFind(impact_str, "Medium") >= 0 || StringFind(impact_str, "Moderate") >= 0 || StringFind(impact_str, "2") >= 0)
         return 2;
      return 1;
     }

   bool              ShouldProcessImpact(ENUM_CALENDAR_EVENT_IMPORTANCE importance)
     {
      switch(importance)
        {
         case CALENDAR_IMPORTANCE_LOW:
            return EnableLowImpact;
         case CALENDAR_IMPORTANCE_MODERATE:
            return EnableMediumImpact;
         case CALENDAR_IMPORTANCE_HIGH:
            return EnableHighImpact;
         default:
            return false;
        }
     }

   void              SortNewsByTime()
     {
      // Simple bubble sort by time
      for(int i = 0; i < m_news_count - 1; i++)
        {
         for(int j = 0; j < m_news_count - i - 1; j++)
           {
            if(m_news_events[j].time > m_news_events[j + 1].time)
              {
               NewsEvent temp = m_news_events[j];
               m_news_events[j] = m_news_events[j + 1];
               m_news_events[j + 1] = temp;
              }
           }
        }
     }

   void              DrawNewsVerticalLines()
     {
      // Clean up old lines first
      ObjectsDeleteAll(0, "NewsLine_");

      for(int i = 0; i < m_news_count; i++)
        {
         datetime news_time = m_news_events[i].time;
         if(news_time < TimeCurrent())
            continue; // Skip past events

         color line_color = GetImpactColor(m_news_events[i].impact);
         string obj_name = "NewsLine_" + IntegerToString((int)news_time);

         ObjectCreate(0, obj_name, OBJ_VLINE, 0, news_time, 0);
         ObjectSetInteger(0, obj_name, OBJPROP_COLOR, line_color);
         ObjectSetInteger(0, obj_name, OBJPROP_STYLE, STYLE_DOT);
         ObjectSetInteger(0, obj_name, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, obj_name, OBJPROP_BACK, true);

         string tooltip = StringFormat("%s\n%s - %s\nImpact: %s",
                                       TimeToString(news_time),
                                       m_news_events[i].currency,
                                       m_news_events[i].title,
                                       GetImpactString(m_news_events[i].impact));
         ObjectSetString(0, obj_name, OBJPROP_TOOLTIP, tooltip);
        }
     }

   color             GetImpactColor(int impact)
     {
      switch(impact)
        {
         case 3:
            return HighImpactColor;
         case 2:
            return MediumImpactColor;
         case 1:
            return LowImpactColor;
         default:
            return clrGray;
        }
     }

   string            GetImpactString(int impact)
     {
      switch(impact)
        {
         case 3:
            return "HIGH";
         case 2:
            return "MEDIUM";
         case 1:
            return "LOW";
         default:
            return "UNKNOWN";
        }
     }



public:
   bool              IsTradingAllowed()
     {
      if(!EnableNewsFilter)
         return true;

      // Update news data periodically (every 6 hours)
      if(TimeCurrent() - m_last_update >= 21600)
        {
         UpdateNewsData();
         m_last_update = TimeCurrent();
        }

      datetime current_time = TimeCurrent();
      m_trading_halted = false;
      m_halt_reason = "";

      // Check each news event
      for(int i = 0; i < m_news_count; i++)
        {
         datetime news_time = m_news_events[i].time;
         datetime start_halt = news_time - StopBeforeNewsMin * 60;
         datetime end_halt = news_time + StopAfterNewsMin * 60;

         if(current_time >= start_halt && current_time <= end_halt)
           {
            m_trading_halted = true;
            m_halt_reason = StringFormat("NEWS: %s %s (%s) in %d min",
                                         m_news_events[i].currency,
                                         m_news_events[i].title,
                                         GetImpactString(m_news_events[i].impact),
                                         (int)((news_time - current_time) / 60));

            // Send alert if enabled and not already alerted recently
            if(AlertOnUpcomingNews && (current_time - m_last_alert_time > 300)) // 5 min cooldown
              {
               Alert("Trading Halted: ", m_halt_reason);
               m_last_alert_time = current_time;
              }

            // Close positions if configured
            if(ClosePositionsBeforeNews && current_time <= news_time && !m_news_events[i].processed)
              {
               CloseAllNewsPositions();
               m_news_events[i].processed = true;
              }

            return false;
           }
        }

      return true;
     }

 void              CloseAllNewsPositions()
     {
      Print("News Filter: Closing all positions due to upcoming high-impact news");

      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(position.SelectByIndex(i) && position.Magic() == MagicNumber && position.Symbol() == _Symbol)
           {
            trade.PositionClose(position.Ticket());
            Sleep(100);
           }
        }

      // ✅ FIX: Safe Pending Order Deletion with Freeze Level Check
      double freeze_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
      
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         if(order.SelectByIndex(i) && order.Magic() == MagicNumber && order.Symbol() == _Symbol)
           {
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double order_price = order.PriceOpen();
            bool is_frozen = false;

            if(order.OrderType() == ORDER_TYPE_BUY_LIMIT || order.OrderType() == ORDER_TYPE_BUY_STOP)
              {
               if(MathAbs(ask - order_price) <= freeze_level) is_frozen = true;
              }
            else if(order.OrderType() == ORDER_TYPE_SELL_LIMIT || order.OrderType() == ORDER_TYPE_SELL_STOP)
              {
               if(MathAbs(bid - order_price) <= freeze_level) is_frozen = true;
              }

            if(!is_frozen)
              {
               trade.OrderDelete(order.Ticket());
               Sleep(100);
              }
            else
              {
               Print("⚠️ News Filter: Order #", order.Ticket(), " is frozen and cannot be canceled.");
              }
           }
        }
     }
   bool              IsTradingHalted() { return m_trading_halted; }
   string            GetHaltReason() { return m_halt_reason; }

   string            GetNextNewsInfo()
     {
      if(!EnableNewsFilter || m_news_count == 0)
         return "No upcoming news";

      datetime current_time = TimeCurrent();

      for(int i = 0; i < m_news_count; i++)
        {
         if(m_news_events[i].time > current_time)
           {
            int minutes_to_news = (int)((m_news_events[i].time - current_time) / 60);
            return StringFormat("%s %s in %d min (%s)",
                                m_news_events[i].currency,
                                m_news_events[i].title,
                                minutes_to_news,
                                GetImpactString(m_news_events[i].impact));
           }
        }

      return "No upcoming news today";
     }

   void              Cleanup()
     {
      ObjectsDeleteAll(0, "NewsLine_");
     }
  };

//+------------------------------------------------------------------+
//| Market Analyzer Class (Existing - keeping as is)                 |
//+------------------------------------------------------------------+
class CMarketAnalyzer
  {
private:
   int               m_ema_fast_handle;
   int               m_ema_slow_handle;
   int               m_atr_handle;
   int               m_rsi_handle;
   int               m_trend_ma_handle;

   double            m_ema_fast_buffer[];
   double            m_ema_slow_buffer[];
   double            m_atr_buffer[];
   double            m_rsi_buffer[];
   double            m_trend_ma_buffer[];

public:
                     CMarketAnalyzer() : m_ema_fast_handle(INVALID_HANDLE), m_ema_slow_handle(INVALID_HANDLE),
                     m_atr_handle(INVALID_HANDLE), m_rsi_handle(INVALID_HANDLE),
                     m_trend_ma_handle(INVALID_HANDLE) {}

                    ~CMarketAnalyzer() { Release(); }

   bool              Initialize()
     {
      m_ema_fast_handle = iMA(_Symbol, PERIOD_CURRENT, 10, 0, MODE_EMA, PRICE_CLOSE);
      m_ema_slow_handle = iMA(_Symbol, PERIOD_CURRENT, AMA_Period, 0, MODE_EMA, PRICE_CLOSE);
      m_atr_handle = iATR(_Symbol, PERIOD_CURRENT, ATR_Period);

      if(UseRSIFilter)
         m_rsi_handle = iRSI(_Symbol, PERIOD_CURRENT, RSI_Period, PRICE_CLOSE);

      m_trend_ma_handle = iMA(_Symbol, TrendTimeframe, TrendMA_Period, 0, MODE_EMA, PRICE_CLOSE);

      ArraySetAsSeries(m_ema_fast_buffer, true);
      ArraySetAsSeries(m_ema_slow_buffer, true);
      ArraySetAsSeries(m_atr_buffer, true);
      ArraySetAsSeries(m_rsi_buffer, true);
      ArraySetAsSeries(m_trend_ma_buffer, true);

      return (m_ema_fast_handle != INVALID_HANDLE && m_ema_slow_handle != INVALID_HANDLE &&
              m_atr_handle != INVALID_HANDLE && m_trend_ma_handle != INVALID_HANDLE);
     }

   void              Release()
     {
      if(m_ema_fast_handle != INVALID_HANDLE)
         IndicatorRelease(m_ema_fast_handle);
      if(m_ema_slow_handle != INVALID_HANDLE)
         IndicatorRelease(m_ema_slow_handle);
      if(m_atr_handle != INVALID_HANDLE)
         IndicatorRelease(m_atr_handle);
      if(m_rsi_handle != INVALID_HANDLE)
         IndicatorRelease(m_rsi_handle);
      if(m_trend_ma_handle != INVALID_HANDLE)
         IndicatorRelease(m_trend_ma_handle);
     }

   bool              UpdateData()
     {
      bool result = true;
      result &= (CopyBuffer(m_ema_fast_handle, 0, 0, 3, m_ema_fast_buffer) > 0);
      result &= (CopyBuffer(m_ema_slow_handle, 0, 0, 3, m_ema_slow_buffer) > 0);
      result &= (CopyBuffer(m_atr_handle, 0, 0, 3, m_atr_buffer) > 0);
      result &= (CopyBuffer(m_trend_ma_handle, 0, 0, 3, m_trend_ma_buffer) > 0);

      if(UseRSIFilter && m_rsi_handle != INVALID_HANDLE)
         result &= (CopyBuffer(m_rsi_handle, 0, 0, 3, m_rsi_buffer) > 0);

      return result;
     }

   ENUM_MARKET_PHASE GetMarketPhase()
     {
      if(!UpdateData())
         return MARKET_UNKNOWN;

      double ema_diff = MathAbs(m_ema_fast_buffer[0] - m_ema_slow_buffer[0]) / _Point;
      double atr_current = m_atr_buffer[0] / _Point;
      double atr_avg = (m_atr_buffer[0] + m_atr_buffer[1] + m_atr_buffer[2]) / 3.0 / _Point;

      if(ema_diff > 50 && atr_current > atr_avg * 2.0)
         return MARKET_TRENDING;

      return MARKET_RANGING;
     }

   ENUM_TREND_DIRECTION GetTrendDirection()
     {
      if(!UpdateData())
         return TREND_NEUTRAL;

      double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double trend_ma = m_trend_ma_buffer[0];

      if(current_price > trend_ma * 1.0005)
         return TREND_BULLISH;
      else
         if(current_price < trend_ma * 0.9995)
            return TREND_BEARISH;

      double ma_slope = (m_trend_ma_buffer[0] - m_trend_ma_buffer[2]) / _Point;
      if(ma_slope > 5)
         return TREND_BULLISH;
      if(ma_slope < -5)
         return TREND_BEARISH;

      return TREND_NEUTRAL;
     }

   bool              IsRSIOversold()
     {
      if(!UseRSIFilter || m_rsi_handle == INVALID_HANDLE)
         return true;
      return m_rsi_buffer[0] < 40.0;
     }

   bool              IsRSIOverbought()
     {
      if(!UseRSIFilter || m_rsi_handle == INVALID_HANDLE)
         return true;
      return m_rsi_buffer[0] > 60.0;
     }

   bool              GetSwingLevels(double &swing_high, double &swing_low)
     {
      double high_buffer[], low_buffer[];
      ArraySetAsSeries(high_buffer, true);
      ArraySetAsSeries(low_buffer, true);

      if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, SwingLookback, high_buffer) <= 0 ||
         CopyLow(_Symbol, PERIOD_CURRENT, 0, SwingLookback, low_buffer) <= 0)
         return false;

      swing_high = high_buffer[ArrayMaximum(high_buffer)];
      swing_low = low_buffer[ArrayMinimum(low_buffer)];

      return true;
     }

   double            CalculateFibonacciLevel(double high, double low, double fib_percent, bool is_retracement = true)
     {
      if(is_retracement)
         return high - (high - low) * fib_percent / 100.0;
      else
         return low + (high - low) * fib_percent / 100.0;
     }

   double            GetATR() { return UpdateData() ? m_atr_buffer[0] : 0; }
   double            GetRSI() { return (UseRSIFilter && UpdateData()) ? m_rsi_buffer[0] : 50; }
  };
//+------------------------------------------------------------------+
//| Enhanced Support/Resistance Detection Class                      |
//+------------------------------------------------------------------+
class CEnhancedSRDetector
  {
private:


   SRLevel           m_sr_levels[];
   int               m_sr_count;


   ChannelInfo       m_current_channel;
   bool              m_in_channel;


   BreakoutInfo      m_last_breakout;
   bool              m_breakout_pending;

public:
                     CEnhancedSRDetector() : m_sr_count(0), m_in_channel(false) {}

   bool              Initialize()
     {
      ArrayResize(m_sr_levels, 50); // Max 50 S/R levels
      DetectSupportResistanceLevels();
      DetectCurrentChannel();
      return true;
     };
   bool              DetectBreakout(double current_price, double &breakout_level, bool &is_bullish_breakout, double &confidence_score)
     {
      if(!IsNewBar())
         return false; // Only check on new bars

      double nearest_resistance, nearest_support;
      double resistance_strength, support_strength;

      bool near_resistance = IsNearResistanceLevel(current_price, nearest_resistance, resistance_strength);
      bool near_support = IsNearSupportLevel(current_price, nearest_support, support_strength);

      // Check for resistance breakout (bullish)
      if(CheckResistanceBreakout(current_price, nearest_resistance, resistance_strength, breakout_level, confidence_score))
        {
         is_bullish_breakout = true;
         return true;
        }

      // Check for support breakdown (bearish)
      if(CheckSupportBreakdown(current_price, nearest_support, support_strength, breakout_level, confidence_score))
        {
         is_bullish_breakout = false;
         return true;
        }

      return false;
     }
   bool              IsBreakoutPending() { return m_breakout_pending; }



private:
   void              DetectSupportResistanceLevels()
     {
      double high_buffer[], low_buffer[];
      ArraySetAsSeries(high_buffer, true);
      ArraySetAsSeries(low_buffer, true);

      if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, SR_LookbackPeriod, high_buffer) <= 0 ||
         CopyLow(_Symbol, PERIOD_CURRENT, 0, SR_LookbackPeriod, low_buffer) <= 0)
         return;

      m_sr_count = 0;

      // Detect swing highs and lows using ZigZag-like approach
      for(int i = 5; i < SR_LookbackPeriod - 5; i++)
        {
         // Check for swing high
         if(IsSwingHigh(high_buffer, i, 3))
           {
            double level = high_buffer[i];
            AddOrUpdateSRLevel(level, false); // resistance
           }

         // Check for swing low
         if(IsSwingLow(low_buffer, i, 3))
           {
            double level = low_buffer[i];
            AddOrUpdateSRLevel(level, true); // support
           }
        }

      // Calculate strength for each level
      CalculateSRStrengths();

      // Sort by strength and keep only the strongest levels
      SortSRLevelsByStrength();

      Print("✓ Detected ", m_sr_count, " S/R levels");
     }

   bool              IsSwingHigh(const double &highs[], int index, int lookback)
     {
      double current = highs[index];
      for(int i = index - lookback; i <= index + lookback; i++)
        {
         if(i != index && highs[i] >= current)
            return false;
        }
      return true;
     }

   bool              IsSwingLow(const double &lows[], int index, int lookback)
     {
      double current = lows[index];
      for(int i = index - lookback; i <= index + lookback; i++)
        {
         if(i != index && lows[i] <= current)
            return false;
        }
      return true;
     }

   void              AddOrUpdateSRLevel(double price, bool is_support)
     {
      double buffer = SR_ZoneBuffer * _Point;

      // Check if level already exists nearby
      for(int i = 0; i < m_sr_count; i++)
        {
         if(MathAbs(m_sr_levels[i].price - price) <= buffer &&
            m_sr_levels[i].is_support == is_support)
           {
            m_sr_levels[i].touch_count++;
            m_sr_levels[i].last_touch = TimeCurrent();
            return;
           }
        }

      // Add new level
      if(m_sr_count < ArraySize(m_sr_levels))
        {
         m_sr_levels[m_sr_count].price = price;
         m_sr_levels[m_sr_count].is_support = is_support;
         m_sr_levels[m_sr_count].touch_count = 1;
         m_sr_levels[m_sr_count].first_touch = TimeCurrent();
         m_sr_levels[m_sr_count].last_touch = TimeCurrent();
         m_sr_levels[m_sr_count].is_active = true;
         m_sr_count++;
        }
     }

   void              CalculateSRStrengths()
     {
      for(int i = 0; i < m_sr_count; i++)
        {
         double time_factor = 1.0;
         double touch_factor = m_sr_levels[i].touch_count;
         double age_hours = (TimeCurrent() - m_sr_levels[i].first_touch) / 3600.0;

         // Newer levels get slightly higher weight
         if(age_hours < 24)
            time_factor = 1.2;
         else
            if(age_hours < 168)
               time_factor = 1.0; // 1 week
            else
               time_factor = 0.8;

         m_sr_levels[i].strength = touch_factor * time_factor;
        }
     }

   void              SortSRLevelsByStrength()
     {
      // Simple bubble sort by strength
      for(int i = 0; i < m_sr_count - 1; i++)
        {
         for(int j = 0; j < m_sr_count - i - 1; j++)
           {
            if(m_sr_levels[j].strength < m_sr_levels[j + 1].strength)
              {
               SRLevel temp = m_sr_levels[j];
               m_sr_levels[j] = m_sr_levels[j + 1];
               m_sr_levels[j + 1] = temp;
              }
           }
        }

      // Keep only strongest levels (max 20)
      if(m_sr_count > 20)
         m_sr_count = 20;
     }

   void              DetectCurrentChannel()
     {
      m_in_channel = false;

      double high_buffer[], low_buffer[];
      ArraySetAsSeries(high_buffer, true);
      ArraySetAsSeries(low_buffer, true);

      if(CopyHigh(_Symbol, PERIOD_CURRENT, 0, ChannelMinBars, high_buffer) <= 0 ||
         CopyLow(_Symbol, PERIOD_CURRENT, 0, ChannelMinBars, low_buffer) <= 0)
         return;

      // Find channel using linear regression on highs and lows
      double upper_slope, upper_intercept, lower_slope, lower_intercept;
      double upper_correlation = CalculateLinearRegression(high_buffer, ChannelMinBars, upper_slope, upper_intercept);
      double lower_correlation = CalculateLinearRegression(low_buffer, ChannelMinBars, lower_slope, lower_intercept);

      // Check if we have a valid channel
      if(MathAbs(upper_correlation) > ChannelThreshold &&
         MathAbs(lower_correlation) > ChannelThreshold &&
         MathAbs(upper_slope - lower_slope) < 0.0001) // Parallel lines
        {
         m_current_channel.upper_line = upper_intercept;
         m_current_channel.lower_line = lower_intercept;
         m_current_channel.slope = (upper_slope + lower_slope) / 2.0;
         m_current_channel.strength = (MathAbs(upper_correlation) + MathAbs(lower_correlation)) / 2.0;
         m_current_channel.is_active = true;
         m_current_channel.start_time = TimeCurrent();
         m_in_channel = true;

         Print("✓ Channel detected - Upper: ", m_current_channel.upper_line,
               " Lower: ", m_current_channel.lower_line,
               " Strength: ", m_current_channel.strength);
        }
     }

   double            CalculateLinearRegression(const double &prices[], int period, double &slope, double &intercept)
     {
      double sum_x = 0, sum_y = 0, sum_xy = 0, sum_x2 = 0;

      for(int i = 0; i < period; i++)
        {
         sum_x += i;
         sum_y += prices[i];
         sum_xy += i * prices[i];
         sum_x2 += i * i;
        }

      slope = (period * sum_xy - sum_x * sum_y) / (period * sum_x2 - sum_x * sum_x);
      intercept = (sum_y - slope * sum_x) / period;

      // Calculate correlation coefficient
      double sum_y2 = 0;
      for(int i = 0; i < period; i++)
         sum_y2 += prices[i] * prices[i];

      double numerator = period * sum_xy - sum_x * sum_y;
      double denominator = MathSqrt((period * sum_x2 - sum_x * sum_x) * (period * sum_y2 - sum_y * sum_y));

      return (denominator != 0) ? numerator / denominator : 0;
     }
   bool              IsNewBar()
     {
      static datetime last_bar_time = 0;
      datetime current_bar_time = iTime(_Symbol, PERIOD_CURRENT, 0);

      if(current_bar_time != last_bar_time)
        {
         last_bar_time = current_bar_time;
         return true;
        }
      return false;
     }
   bool              CheckResistanceBreakout(double current_price, double resistance_level, double strength,
                                double &breakout_level, double &confidence_score)
     {
      if(resistance_level == 0 || strength < SR_MinStrength)
         return false;

      double breakout_distance = (current_price - resistance_level) / _Point;

      // Check if we have a valid breakout distance
      if(breakout_distance < BreakoutMinPips || breakout_distance > BreakoutMaxPips)
         return false;

      // Check momentum
      double momentum_score = CalculateMomentumScore(true);
      if(UseMomentumFilter && momentum_score < MomentumThreshold)
         return false;

      // Check volume
      double volume_score = CalculateVolumeScore();
      if(UseVolumeFilter && volume_score < VolumeMultiplier)
         return false;

      // Check for false breakout prevention
      if(!PassesFalseBreakoutFilter(current_price, resistance_level, true))
         return false;

      // Calculate confidence score
      confidence_score = CalculateBreakoutConfidence(strength, momentum_score, volume_score, breakout_distance);

      if(confidence_score >= FalseBreakoutFilter)
        {
         breakout_level = resistance_level;

         // Store breakout info for confirmation
         m_last_breakout.sr_level = resistance_level;
         m_last_breakout.is_resistance_break = true;
         m_last_breakout.break_time = TimeCurrent();
         m_last_breakout.break_price = current_price;
         m_last_breakout.momentum_score = momentum_score;
         m_last_breakout.volume_score = volume_score;
         m_last_breakout.is_confirmed = false;
         m_last_breakout.confirmation_bars = 0;
         m_breakout_pending = true;

         return true;
        }

      return false;
     }
   bool              CheckSupportBreakdown(double current_price, double support_level, double strength,
                              double &breakout_level, double &confidence_score)
     {
      if(support_level == 0 || strength < SR_MinStrength)
         return false;

      double breakout_distance = (support_level - current_price) / _Point;

      // Check if we have a valid breakout distance
      if(breakout_distance < BreakoutMinPips || breakout_distance > BreakoutMaxPips)
         return false;

      // Check momentum
      double momentum_score = CalculateMomentumScore(false);
      if(UseMomentumFilter && momentum_score < MomentumThreshold)
         return false;

      // Check volume
      double volume_score = CalculateVolumeScore();
      if(UseVolumeFilter && volume_score < VolumeMultiplier)
         return false;

      // Check for false breakout prevention
      if(!PassesFalseBreakoutFilter(current_price, support_level, false))
         return false;

      // Calculate confidence score
      confidence_score = CalculateBreakoutConfidence(strength, momentum_score, volume_score, breakout_distance);

      if(confidence_score >= FalseBreakoutFilter)
        {
         breakout_level = support_level;

         // Store breakout info for confirmation
         m_last_breakout.sr_level = support_level;
         m_last_breakout.is_resistance_break = false;
         m_last_breakout.break_time = TimeCurrent();
         m_last_breakout.break_price = current_price;
         m_last_breakout.momentum_score = momentum_score;
         m_last_breakout.volume_score = volume_score;
         m_last_breakout.is_confirmed = false;
         m_last_breakout.confirmation_bars = 0;
         m_breakout_pending = true;

         return true;
        }

      return false;
     }

   double            CalculateMomentumScore(bool bullish_breakout)
     {
      // Get ATR for momentum measurement
      double atr_current = g_market_analyzer.GetATR();
      double atr_buffer[];
      ArraySetAsSeries(atr_buffer, true);

      int atr_handle = iATR(_Symbol, PERIOD_CURRENT, 14);
      if(CopyBuffer(atr_handle, 0, 0, 10, atr_buffer) <= 0)
         return 0;

      double atr_avg = 0;
      for(int i = 1; i < 10; i++) // Skip current bar
         atr_avg += atr_buffer[i];
      atr_avg /= 9;

      double momentum_ratio = (atr_avg > 0) ? atr_current / atr_avg : 1.0;

      // Get price velocity
      double close_buffer[];
      ArraySetAsSeries(close_buffer, true);
      if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 5, close_buffer) <= 0)
         return momentum_ratio;

      double price_velocity = 0;
      if(bullish_breakout)
         price_velocity = (close_buffer[0] - close_buffer[4]) / (4 * _Point);
      else
         price_velocity = (close_buffer[4] - close_buffer[0]) / (4 * _Point);

      // Combine ATR momentum and price velocity
      double velocity_score = MathMax(0, price_velocity / 20.0); // Normalize velocity

      return momentum_ratio + velocity_score;
     }

   double            CalculateVolumeScore()
     {
      if(!UseVolumeFilter)
         return VolumeMultiplier; // Pass if not using volume

      long volume_buffer[];
      ArraySetAsSeries(volume_buffer, true);

      if(CopyTickVolume(_Symbol, PERIOD_CURRENT, 0, VolumeConfirmPeriod + 1, volume_buffer) <= 0)
         return 1.0; // Default if no volume data

      long current_volume = volume_buffer[0];
      long avg_volume = 0;

      for(int i = 1; i <= VolumeConfirmPeriod; i++)
         avg_volume += volume_buffer[i];

      avg_volume /= VolumeConfirmPeriod;

      return (avg_volume > 0) ? (double)current_volume / (double)avg_volume : 1.0;
     }

   bool              PassesFalseBreakoutFilter(double current_price, double sr_level, bool is_resistance_break)
     {
      // Check if price has enough conviction to break through
      double close_buffer[];
      ArraySetAsSeries(close_buffer, true);

      if(CopyClose(_Symbol, PERIOD_CURRENT, 0, 3, close_buffer) <= 0)
         return true; // Default pass if no data

      double min_penetration = BreakoutMinPips * _Point;

      if(is_resistance_break)
        {
         // For resistance breakout, ensure price closed above resistance
         return (close_buffer[0] > sr_level + min_penetration);
        }
      else
        {
         // For support breakdown, ensure price closed below support
         return (close_buffer[0] < sr_level - min_penetration);
        }
     }

   double            CalculateBreakoutConfidence(double sr_strength, double momentum_score, double volume_score, double breakout_distance)
     {
      // Normalize components
      double strength_score = MathMin(sr_strength / 10.0, 1.0); // Max 10 touches
      double momentum_normalized = MathMin(momentum_score / 3.0, 1.0); // Max 3x momentum
      double volume_normalized = MathMin(volume_score / 3.0, 1.0); // Max 3x volume
      double distance_score = MathMin(breakout_distance / BreakoutMaxPips, 1.0);

      // Weighted combination
      double confidence = (strength_score * 0.3) +
                          (momentum_normalized * 0.3) +
                          (volume_normalized * 0.2) +
                          (distance_score * 0.2);

      return confidence;
     }



public:
   bool              IsNearSupportLevel(double price, double &support_level, double &strength)
     {
      double buffer = SR_ZoneBuffer * _Point;

      for(int i = 0; i < m_sr_count; i++)
        {
         if(m_sr_levels[i].is_support && m_sr_levels[i].is_active &&
            m_sr_levels[i].strength >= SR_MinStrength)
           {
            if(MathAbs(price - m_sr_levels[i].price) <= buffer)
              {
               support_level = m_sr_levels[i].price;
               strength = m_sr_levels[i].strength;
               return true;
              }
           }
        }
      return false;
     }

   bool              IsNearResistanceLevel(double price, double &resistance_level, double &strength)
     {
      double buffer = SR_ZoneBuffer * _Point;

      for(int i = 0; i < m_sr_count; i++)
        {
         if(!m_sr_levels[i].is_support && m_sr_levels[i].is_active &&
            m_sr_levels[i].strength >= SR_MinStrength)
           {
            if(MathAbs(price - m_sr_levels[i].price) <= buffer)
              {
               resistance_level = m_sr_levels[i].price;
               strength = m_sr_levels[i].strength;
               return true;
              }
           }
        }
      return false;
     }

   bool              IsInChannel() { return m_in_channel && UseChannelTrading; }

   bool              IsNearChannelSupport(double price)
     {
      if(!m_in_channel)
         return false;
      double buffer = SR_ZoneBuffer * _Point;
      return MathAbs(price - m_current_channel.lower_line) <= buffer;
     }

   bool              IsNearChannelResistance(double price)
     {
      if(!m_in_channel)
         return false;
      double buffer = SR_ZoneBuffer * _Point;
      return MathAbs(price - m_current_channel.upper_line) <= buffer;
     }

   double            GetChannelSupport() { return m_current_channel.lower_line; }
   double            GetChannelResistance() { return m_current_channel.upper_line; }
   double            GetChannelStrength() { return m_current_channel.strength; }

   void              UpdateSRLevels()
     {
      DetectSupportResistanceLevels();
      DetectCurrentChannel();
     }
   bool              IsBreakoutConfirmed(double current_price)
     {
      if(!m_breakout_pending)
         return false;

      m_last_breakout.confirmation_bars++;

      // Check if price is still above/below the breakout level
      bool still_valid = false;
      double min_distance = BreakoutMinPips * _Point * 0.5; // Half the minimum distance

      if(m_last_breakout.is_resistance_break)
        {
         still_valid = (current_price > m_last_breakout.sr_level + min_distance);
        }
      else
        {
         still_valid = (current_price < m_last_breakout.sr_level - min_distance);
        }

      if(!still_valid)
        {
         m_breakout_pending = false; // Failed breakout
         return false;
        }

      // Confirm after required bars
      if(m_last_breakout.confirmation_bars >= BreakoutConfirmBars)
        {
         m_last_breakout.is_confirmed = true;
         m_breakout_pending = false;
         return true;
        }

      return false;
     }
  //+------------------------------------------------------------------+
   //| Complete CheckSRBreakoutEntry Implementation                     |
   //+------------------------------------------------------------------+
   bool              CheckSRBreakoutEntry(double current_price, ENUM_TREND_DIRECTION trend, datetime &last_trade_time)
     {
      // Prevent too frequent breakout trades
      static datetime last_breakout_trade = 0;
      if(TimeCurrent() - last_breakout_trade < 7200)
         return false; // 2 hours minimum

      double breakout_level = 0, confidence_score = 0;
      bool is_bullish_breakout = false;

      // Step 1: Detect initial breakout
      if(DetectBreakout(current_price, breakout_level, is_bullish_breakout, confidence_score))
        {
         Print("⚡ Potential breakout detected at level: ", breakout_level,
               " Direction: ", is_bullish_breakout ? "BULLISH" : "BEARISH",
               " Confidence: ", confidence_score);
         return false; // Wait for confirmation
        }

      // Step 2: Check if previous breakout is now confirmed
      if(IsBreakoutConfirmed(current_price))
        {
         // Get the confirmed breakout details
         bool is_resistance_break = (current_price > breakout_level);

         // Additional filters for breakout entry
         if(!PassesBreakoutFilters(is_resistance_break, trend))
            return false;

         // Calculate position size based on confidence
         double base_lot = g_risk_manager.CalculatePositionSize(1);
         double confidence_multiplier = MathMin(confidence_score * 2.0, 1.5); // Max 1.5x
         double lot_size = base_lot * confidence_multiplier;
         lot_size = MathMin(lot_size, MaxLotSize);
         
         // ✅ FIX: Force strict normalization before sending to broker
         lot_size = NormalizeLots(lot_size);

         // Execute breakout trade
         if(is_resistance_break)
           {
            // Bullish breakout - Buy
            if(g_risk_manager.ValidateTrade(lot_size, ORDER_TYPE_BUY))
              {
               if(g_trade_manager.OpenInitialPosition(ORDER_TYPE_BUY, lot_size, Commentary + "_Breakout_Buy"))
                 {
                  Print("✅ BREAKOUT BUY executed at: ", current_price,
                        " Breaking resistance: ", breakout_level,
                        " Lot size: ", lot_size,
                        " Confidence: ", confidence_score);
                  last_trade_time = TimeCurrent();
                  last_breakout_trade = TimeCurrent();
                  return true;
                 }
              }
           }
         else
           {
            // Bearish breakout - Sell
            if(g_risk_manager.ValidateTrade(lot_size, ORDER_TYPE_SELL))
              {
               if(g_trade_manager.OpenInitialPosition(ORDER_TYPE_SELL, lot_size, Commentary + "_Breakout_Sell"))
                 {
                  Print("✅ BREAKOUT SELL executed at: ", current_price,
                        " Breaking support: ", breakout_level,
                        " Lot size: ", lot_size,
                        " Confidence: ", confidence_score);
                  last_trade_time = TimeCurrent();
                  last_breakout_trade = TimeCurrent();
                  return true;
                 }
              }
           }
        }

      return false;
     }
   //+------------------------------------------------------------------+
   //| Additional Breakout Filters                                     |
   //+------------------------------------------------------------------+
   bool              PassesBreakoutFilters(bool is_bullish_breakout, ENUM_TREND_DIRECTION trend)
     {
      // Filter 1: Trend alignment (optional but recommended)
      if(trend != TREND_NEUTRAL)
        {
         if(is_bullish_breakout && trend == TREND_BEARISH)
            return false;
         if(!is_bullish_breakout && trend == TREND_BULLISH)
            return false;
        }

      // Filter 2: Market volatility check
      double atr_current = g_market_analyzer.GetATR();
      if(atr_current < 20 * _Point)
         return false; // Minimum volatility required

      // Filter 3: RSI momentum alignment
      if(UseRSIFilter)
        {
         double rsi = g_market_analyzer.GetRSI();
         if(is_bullish_breakout && rsi > 80)
            return false; // Avoid extreme overbought
         if(!is_bullish_breakout && rsi < 20)
            return false; // Avoid extreme oversold
        }

      // Filter 4: Time of day filter (avoid low-liquidity hours)
      MqlDateTime current_time;
      TimeToStruct(TimeCurrent(), current_time);

      // Avoid breakout trades during Asian session (low liquidity)
      if(current_time.hour >= 22 || current_time.hour <= 6)
         return false;

      return true;
     }
   //+------------------------------------------------------------------+
   //| Enhanced Dashboard Update for Breakout Info                     |
   //+------------------------------------------------------------------+
   // Add this to your dashboard update function:

   void              UpdateBreakoutInfo()
     {
      // Add breakout status to your panel
      string breakout_status = "No active breakouts";

      if(g_sr_detector.IsBreakoutPending())
        {
         breakout_status = "Breakout pending confirmation...";
        }


     }

  };

//+------------------------------------------------------------------+
//| Enhanced Simple Entry Function                                  |
//+------------------------------------------------------------------+
void CheckEnhancedSimpleEntry()
  {
   if(!UseEnhancedEntry)
      return;

   static datetime last_update = 0;
   static datetime last_trade_time = 0;

// Update S/R levels every hour
   if(TimeCurrent() - last_update > 3600)
     {
      g_sr_detector.UpdateSRLevels();
      last_update = TimeCurrent();
     }

// Prevent too frequent trading
   if(TimeCurrent() - last_trade_time < 14400)
      return; // 4 hours minimum

   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   ENUM_MARKET_PHASE market_phase = g_market_analyzer.GetMarketPhase();
   ENUM_TREND_DIRECTION trend = g_market_analyzer.GetTrendDirection();

// Strategy 1: Channel Trading (Ranging Markets)
   if(g_sr_detector.IsInChannel() && market_phase == MARKET_RANGING)
     {
      if(CheckChannelEntry(current_price, last_trade_time))
         return;
     }

// Strategy 2: S/R Bounce Trading (Trending Markets)
   if(market_phase == MARKET_TRENDING && trend != TREND_NEUTRAL)
     {
      if(CheckSRBounceEntry(current_price, trend, last_trade_time))
         return;
     }

// Strategy 3: S/R Breakout Trading
   if(CheckSRBreakoutEntry(current_price, trend, last_trade_time))
      return;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckChannelEntry(double current_price, datetime &last_trade_time)
  {
// Buy at channel support
   if(g_sr_detector.IsNearChannelSupport(current_price))
     {
      if(g_market_analyzer.IsRSIOversold())
        {
         double lot_size = CalculateEnhancedLotSize(g_sr_detector.GetChannelStrength());

         if(g_risk_manager.ValidateTrade(lot_size, ORDER_TYPE_BUY))
           {
            if(g_trade_manager.OpenInitialPosition(ORDER_TYPE_BUY, lot_size, Commentary + "_Channel_Support"))
              {
               Print("✓ CHANNEL BUY at support: ", g_sr_detector.GetChannelSupport(),
                     " Strength: ", g_sr_detector.GetChannelStrength());
               last_trade_time = TimeCurrent();
               return true;
              }
           }
        }
     }

// Sell at channel resistance
   if(g_sr_detector.IsNearChannelResistance(current_price))
     {
      if(g_market_analyzer.IsRSIOverbought())
        {
         double lot_size = CalculateEnhancedLotSize(g_sr_detector.GetChannelStrength());

         if(g_risk_manager.ValidateTrade(lot_size, ORDER_TYPE_SELL))
           {
            if(g_trade_manager.OpenInitialPosition(ORDER_TYPE_SELL, lot_size, Commentary + "_Channel_Resistance"))
              {
               Print("✓ CHANNEL SELL at resistance: ", g_sr_detector.GetChannelResistance(),
                     " Strength: ", g_sr_detector.GetChannelStrength());
               last_trade_time = TimeCurrent();
               return true;
              }
           }
        }
     }

   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckSRBounceEntry(double current_price, ENUM_TREND_DIRECTION trend, datetime &last_trade_time)
  {
   double level, strength;

// Buy at support in uptrend
   if(trend == TREND_BULLISH && g_sr_detector.IsNearSupportLevel(current_price, level, strength))
     {
      if(g_market_analyzer.IsRSIOversold())
        {
         double lot_size = CalculateEnhancedLotSize(strength);

         if(g_risk_manager.ValidateTrade(lot_size, ORDER_TYPE_BUY))
           {
            if(g_trade_manager.OpenInitialPosition(ORDER_TYPE_BUY, lot_size, Commentary + "_SR_Support"))
              {
               Print("✓ S/R BUY bounce at: ", level, " Strength: ", strength);
               last_trade_time = TimeCurrent();
               return true;
              }
           }
        }
     }

// Sell at resistance in downtrend
   if(trend == TREND_BEARISH && g_sr_detector.IsNearResistanceLevel(current_price, level, strength))
     {
      if(g_market_analyzer.IsRSIOverbought())
        {
         double lot_size = CalculateEnhancedLotSize(strength);

         if(g_risk_manager.ValidateTrade(lot_size, ORDER_TYPE_SELL))
           {
            if(g_trade_manager.OpenInitialPosition(ORDER_TYPE_SELL, lot_size, Commentary + "_SR_Resistance"))
              {
               Print("✓ S/R SELL bounce at: ", level, " Strength: ", strength);
               last_trade_time = TimeCurrent();
               return true;
              }
           }
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckSRBreakoutEntry(double current_price, ENUM_TREND_DIRECTION trend, datetime &last_trade_time)
  {
// Prevent too frequent breakout trades
   static datetime last_breakout_trade = 0;
   if(TimeCurrent() - last_breakout_trade < 7200)
      return false; // 2 hours minimum

// Check for resistance breakout (bullish)
   double resistance_level, resistance_strength;
   if(g_sr_detector.IsNearResistanceLevel(current_price, resistance_level, resistance_strength))
     {
      // Check if price has broken above resistance
      double breakout_distance = (current_price - resistance_level) / _Point;

      if(breakout_distance >= BreakoutMinPips && breakout_distance <= BreakoutMaxPips)
        {
         // Additional filters
         if(trend == TREND_BEARISH)
            return false; // Don't trade against strong trend

         // Check momentum
         if(UseMomentumFilter)
           {
            double atr_current = g_market_analyzer.GetATR();
            if(atr_current < 20 * _Point)
               return false; // Minimum volatility required
           }

         // Check RSI
         if(UseRSIFilter)
           {
            double rsi = g_market_analyzer.GetRSI();
            if(rsi > 80)
               return false; // Avoid extreme overbought
           }

         // Calculate position size
         double confidence_score = MathMin(resistance_strength / 5.0, 1.0); // Normalize strength
         double base_lot = g_risk_manager.CalculatePositionSize(1);
         double lot_size = base_lot * (0.5 + confidence_score * 0.5); // 50%-100% based on confidence
         lot_size = MathMin(lot_size, MaxLotSize);

         // ✅ FIX: Force strict normalization before sending to broker
         lot_size = NormalizeLots(lot_size);

         // Execute bullish breakout
         if(g_risk_manager.ValidateTrade(lot_size, ORDER_TYPE_BUY))
           {
            if(g_trade_manager.OpenInitialPosition(ORDER_TYPE_BUY, lot_size, Commentary + "_Breakout_Buy"))
              {
               Print("✅ RESISTANCE BREAKOUT BUY at: ", current_price,
                     " Breaking resistance: ", resistance_level,
                     " Distance: ", breakout_distance, " pips",
                     " Strength: ", resistance_strength,
                     " Lot size: ", lot_size);
               last_trade_time = TimeCurrent();
               last_breakout_trade = TimeCurrent();
               return true;
              }
           }
        }
     }

// Check for support breakdown (bearish)
   double support_level, support_strength;
   if(g_sr_detector.IsNearSupportLevel(current_price, support_level, support_strength))
     {
      // Check if price has broken below support
      double breakout_distance = (support_level - current_price) / _Point;

      if(breakout_distance >= BreakoutMinPips && breakout_distance <= BreakoutMaxPips)
        {
         // Additional filters
         if(trend == TREND_BULLISH)
            return false; // Don't trade against strong trend

         // Check momentum
         if(UseMomentumFilter)
           {
            double atr_current = g_market_analyzer.GetATR();
            if(atr_current < 20 * _Point)
               return false; // Minimum volatility required
           }

         // Check RSI
         if(UseRSIFilter)
           {
            double rsi = g_market_analyzer.GetRSI();
            if(rsi < 20)
               return false; // Avoid extreme oversold
           }

         // Calculate position size
         double confidence_score = MathMin(support_strength / 5.0, 1.0); // Normalize strength
         double base_lot = g_risk_manager.CalculatePositionSize(1);
         double lot_size = base_lot * (0.5 + confidence_score * 0.5); // 50%-100% based on confidence
         lot_size = MathMin(lot_size, MaxLotSize);

         // ✅ FIX: Force strict normalization before sending to broker
         lot_size = NormalizeLots(lot_size);

         // Execute bearish breakout
         if(g_risk_manager.ValidateTrade(lot_size, ORDER_TYPE_SELL))
           {
            if(g_trade_manager.OpenInitialPosition(ORDER_TYPE_SELL, lot_size, Commentary + "_Breakout_Sell"))
              {
               Print("✅ SUPPORT BREAKDOWN SELL at: ", current_price,
                     " Breaking support: ", support_level,
                     " Distance: ", breakout_distance, " pips",
                     " Strength: ", support_strength,
                     " Lot size: ", lot_size);
               last_trade_time = TimeCurrent();
               last_breakout_trade = TimeCurrent();
               return true;
              }
           }
        }
     }

   return false;
  }
// ✅ FIX: Make enhanced lot sizing respect grid multiplier
double CalculateEnhancedLotSize(double sr_strength)
  {
   int current_positions = g_risk_manager.GetGridPositionCount();
   double base_lot = g_risk_manager.CalculatePositionSize(current_positions);

   if(!UseDynamicLotSizing)
      return base_lot;

// Apply S/R strength multiplier on top of grid multiplier
   double strength_multiplier = 1.0;
   if(sr_strength >= 5.0)
      strength_multiplier = 1.2; // Reduced from 1.5 to avoid over-sizing
   else
      if(sr_strength >= 3.0)
         strength_multiplier = 1.1;
      else
         strength_multiplier = 0.9;

   double final_lot = base_lot * strength_multiplier;

// --- CRITICAL FIX: Normalize the final lot size before returning ---
   return NormalizeLots(final_lot);
  }
//+------------------------------------------------------------------+
//| Risk Manager Class (keeping existing implementation)             |
//+------------------------------------------------------------------+
class CRiskManager
  {
private:
   double            m_initial_balance;
   datetime          m_last_check_time;

public:
                     CRiskManager() : m_initial_balance(AccountInfoDouble(ACCOUNT_BALANCE)), m_last_check_time(0) {}

   double            GetCurrentExposure()
     {
      double total_profit = 0.0;
      double total_floating = 0.0;

      for(int i = 0; i < PositionsTotal(); i++)
        {
         if(position.SelectByIndex(i) && position.Magic() == MagicNumber && position.Symbol() == _Symbol)
           {
            total_profit += position.Profit();
            total_floating += position.Swap() + position.Commission();
           }
        }

      double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
      if(current_equity <= 0)
         return 0;

      return ((total_profit + total_floating) / current_equity) * 100.0;
     }

   bool              IsExposureAcceptable()
     {
      return GetCurrentExposure() > -MaxAccountExposure;
     }

   double            CalculatePositionSize(int grid_level)
     {
      // Grid level should be:
      // 0 for first position
      // 1 for second position
      // 2 for third position, etc.

      bool trades_active = g_trade_manager.IsBasketActive();

      double base_lot = InitialLotSize;
      double multiplier = LotMultiplier;

      // Use live adjustments if active
      if(trades_active && g_live_adjustments_active && g_live_multiplier > 0)
        {
         base_lot = (g_live_start_lot > 0) ? g_live_start_lot : InitialLotSize;
         multiplier = g_live_multiplier;
        }

      // Calculate lot size using power function (more accurate than loop)
      double lot_size = base_lot * MathPow(multiplier, grid_level);

      // Debug print
      Print("📊 Position Sizing Debug:");
      Print("  - Grid Level: ", grid_level);
      Print("  - Base Lot: ", base_lot);
      Print("  - Multiplier: ", multiplier);
      Print("  - Calculated: ", base_lot, " * ", multiplier, "^", grid_level, " = ", lot_size);

      // Normalize to broker requirements
      double final_lot_size = NormalizeLots(lot_size);

      Print("  - Final Lot Size: ", final_lot_size);
      return final_lot_size;
     }
   bool              ValidateTrade(double lot_size, ENUM_ORDER_TYPE order_type)
     {
      // Check total count (positions + pending orders) against limit
      if(GetTotalGridCount() >= MaxGridOrders)
        {
         Print("Validation failed: Total grid count (", GetTotalGridCount(), ") >= MaxGridOrders (", MaxGridOrders, ")");
         return false;
        }

      if(!IsExposureAcceptable())
         return false;

      if(lot_size < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) ||
         lot_size > SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX))
         return false;

      double price = (order_type == ORDER_TYPE_BUY || order_type == ORDER_TYPE_BUY_LIMIT || order_type == ORDER_TYPE_BUY_STOP) ?
                     SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

      double required_margin;
      if(!OrderCalcMargin(order_type, _Symbol, lot_size, price, required_margin))
         return false;

      return AccountInfoDouble(ACCOUNT_MARGIN_FREE) > required_margin * 2;
     }
   int               GetGridPositionCount()
     {
      int count = 0;
      for(int i = 0; i < PositionsTotal(); i++)
        {
         if(position.SelectByIndex(i) && position.Magic() == MagicNumber && position.Symbol() == _Symbol)
            count++;
        }
      return count;
     }


   int               GetPendingOrderCount()
     {
      int count = 0;
      for(int i = 0; i < OrdersTotal(); i++)
        {
         if(order.SelectByIndex(i) && order.Magic() == MagicNumber && order.Symbol() == _Symbol)
            count++;
        }
      return count;
     }


   int               GetTotalGridCount()
     {
      return GetGridPositionCount() + GetPendingOrderCount();
     }
   double            GetTotalProfit()
     {
      double total = 0;
      for(int i = 0; i < PositionsTotal(); i++)
        {
         if(position.SelectByIndex(i) && position.Magic() == MagicNumber && position.Symbol() == _Symbol)
            total += position.Profit() + position.Swap() + position.Commission();
        }
      return total;
     }
  };

//+------------------------------------------------------------------+
//| Trade Manager Class (keeping existing implementation)            |
//+------------------------------------------------------------------+
class CTradeManager
  {
private:
   double            m_basket_avg_price;
   double            m_basket_total_lots;
   ENUM_POSITION_TYPE m_basket_direction;
   bool              m_basket_active;
   datetime          m_last_grid_time;

   double            m_best_price;
   bool              m_breakeven_activated;
   double            m_trailing_stop_level;
   bool              m_trailing_active;

public:
                     CTradeManager() : m_basket_avg_price(0), m_basket_total_lots(0),
                     m_basket_direction(POSITION_TYPE_BUY), m_basket_active(false), m_last_grid_time(0),
                     m_best_price(0), m_breakeven_activated(false), m_trailing_stop_level(0), m_trailing_active(false) {}

   bool              OpenInitialPosition(ENUM_ORDER_TYPE order_type, double lot_size, string comment = "")
     {
      double price = (order_type == ORDER_TYPE_BUY) ?
                     SymbolInfoDouble(_Symbol, SYMBOL_ASK) :
                     SymbolInfoDouble(_Symbol, SYMBOL_BID);

      trade.SetExpertMagicNumber(MagicNumber);
      trade.SetDeviationInPoints(10);

      bool result = false;
      if(order_type == ORDER_TYPE_BUY)
         result = trade.Buy(lot_size, _Symbol, price, 0, 0, comment);
      else
         result = trade.Sell(lot_size, _Symbol, price, 0, 0, comment);

      if(result)
        {
         m_basket_direction = (order_type == ORDER_TYPE_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
         m_basket_active = true;

         m_best_price = price;
         m_breakeven_activated = false;
         m_trailing_stop_level = 0;
         m_trailing_active = false;

         UpdateBasketInfo();
         Print("Initial position opened: ", EnumToString(order_type), " Lot: ", lot_size, " Price: ", price);
         return true;
        }

      return false;
     }


   bool              AddToGrid(double target_price, double lot_size, double fib_percent)
     {
      if(!m_basket_active)
         return false;
      if(TimeCurrent() - m_last_grid_time < 300)
         return false;

      // 1. Normalize the price first
      double normalized_price = NormalizePrice(target_price);

      // 2. Check Broker Stops Level
      double stops_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL) * _Point;
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      ENUM_ORDER_TYPE order_type = (m_basket_direction == POSITION_TYPE_BUY) ?
                                   ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT;

      // 3. Ensure the price isn't too close to market or on the wrong side
      if(order_type == ORDER_TYPE_BUY_LIMIT)
        {
         // Buy Limit must be BELOW Ask by at least the Stops Level
         if(normalized_price > ask - stops_level)
           {
            Print("⚠️ Buy Limit price adjusted/skipped: Too close to Ask. Price: ", normalized_price, " Ask: ", ask);
            return false;
           }
        }
      else // SELL_LIMIT
        {
         // Sell Limit must be ABOVE Bid by at least the Stops Level
         if(normalized_price < bid + stops_level)
           {
            Print("⚠️ Sell Limit price adjusted/skipped: Too close to Bid. Price: ", normalized_price, " Bid: ", bid);
            return false;
           }
        }

      trade.SetExpertMagicNumber(MagicNumber);
      string trade_comment = Commentary + "_Fib_" + DoubleToString(fib_percent, 1);

      bool result = false;
      if(order_type == ORDER_TYPE_BUY_LIMIT)
         result = trade.BuyLimit(lot_size, normalized_price, _Symbol, 0, 0, 0, 0, trade_comment);
      else
         result = trade.SellLimit(lot_size, normalized_price, _Symbol, 0, 0, 0, 0, trade_comment);

      if(result)
        {
         m_last_grid_time = TimeCurrent();
         Print("✅ Grid order placed: ", EnumToString(order_type), " at ", normalized_price);
         return true;
        }

      return false;
     }
   void              UpdateBasketInfo()
     {
      m_basket_total_lots = 0;
      double weighted_price = 0;
      bool has_positions = false;

      for(int i = 0; i < PositionsTotal(); i++)
        {
         if(position.SelectByIndex(i) && position.Magic() == MagicNumber && position.Symbol() == _Symbol)
           {
            has_positions = true;
            double pos_lots = position.Volume();
            double pos_price = position.PriceOpen();

            weighted_price += pos_price * pos_lots;
            m_basket_total_lots += pos_lots;
            m_basket_direction = position.PositionType();
           }
        }

      if(has_positions && m_basket_total_lots > 0)
        {
         m_basket_avg_price = weighted_price / m_basket_total_lots;
        }
      else
        {
         m_basket_active = false;
         m_basket_avg_price = 0;
         m_basket_total_lots = 0;
         m_best_price = 0;
         m_breakeven_activated = false;
         m_trailing_stop_level = 0;
         m_trailing_active = false;
        }
     }

   void              CheckBasketTakeProfit()
     {
      if(!m_basket_active)
         return;

      UpdateBasketInfo();

      double current_price = (m_basket_direction == POSITION_TYPE_BUY) ?
                             SymbolInfoDouble(_Symbol, SYMBOL_BID) :
                             SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      double current_profit_pips = 0;
      bool should_close = false;
      string close_reason = "";

      if(m_basket_direction == POSITION_TYPE_BUY)
        {
         current_profit_pips = (current_price - m_basket_avg_price) / _Point;

         if(current_price > m_best_price)
           {
            m_best_price = current_price;
           }
        }
      else
        {
         current_profit_pips = (m_basket_avg_price - current_price) / _Point;

         if(current_price < m_best_price)
           {
            m_best_price = current_price;
           }
        }

      if(UseTrailingStop)
        {
         if(!m_breakeven_activated && current_profit_pips >= BreakevenTrigger)
           {
            m_breakeven_activated = true;
            m_trailing_active = true;
            m_trailing_stop_level = m_basket_avg_price;
            Print("✓ Breakeven activated at ", current_profit_pips, " pips profit");
           }

         if(m_trailing_active)
           {
            double new_trailing_level = 0;

            if(m_basket_direction == POSITION_TYPE_BUY)
              {
               new_trailing_level = m_best_price - (TrailingDistance * _Point);

               if(new_trailing_level > m_trailing_stop_level)
                 {
                  m_trailing_stop_level = new_trailing_level;
                 }

               if(current_price <= m_trailing_stop_level)
                 {
                  should_close = true;
                  close_reason = "Trailing Stop Hit";
                 }
              }
            else
              {
               new_trailing_level = m_best_price + (TrailingDistance * _Point);

               if(new_trailing_level < m_trailing_stop_level || m_trailing_stop_level == 0)
                 {
                  m_trailing_stop_level = new_trailing_level;
                 }

               if(current_price >= m_trailing_stop_level)
                 {
                  should_close = true;
                  close_reason = "Trailing Stop Hit";
                 }
              }
           }
        }

      if(current_profit_pips >= TakeProfitPips)
        {
         should_close = true;
         close_reason = "Ultimate Take Profit";
        }

      if(should_close)
        {
         CloseAllBasketPositions();
         Print("✓ Basket closed: ", close_reason);
        }
     }

  void              CloseAllBasketPositions()
     {
      for(int i = PositionsTotal() - 1; i >= 0; i--)
        {
         if(position.SelectByIndex(i) && position.Magic() == MagicNumber && position.Symbol() == _Symbol)
           {
            trade.PositionClose(position.Ticket());
            Sleep(100);
           }
        }

      // ✅ FIX: Safe Pending Order Deletion with Freeze Level Check
      double freeze_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL) * _Point;
      
      for(int i = OrdersTotal() - 1; i >= 0; i--)
        {
         if(order.SelectByIndex(i) && order.Magic() == MagicNumber && order.Symbol() == _Symbol)
           {
            double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
            double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
            double order_price = order.PriceOpen();
            bool is_frozen = false;

            if(order.OrderType() == ORDER_TYPE_BUY_LIMIT || order.OrderType() == ORDER_TYPE_BUY_STOP)
              {
               if(MathAbs(ask - order_price) <= freeze_level) is_frozen = true;
              }
            else if(order.OrderType() == ORDER_TYPE_SELL_LIMIT || order.OrderType() == ORDER_TYPE_SELL_STOP)
              {
               if(MathAbs(bid - order_price) <= freeze_level) is_frozen = true;
              }

            if(!is_frozen)
              {
               trade.OrderDelete(order.Ticket());
               Sleep(100);
              }
            else
              {
               Print("⚠️ Trade Manager: Order #", order.Ticket(), " is frozen and cannot be canceled.");
              }
           }
        }

      // Reset live adjustments when basket closes
      g_live_adjustments_active = false;
      g_live_multiplier = 0.0;
      g_live_start_lot = 0.0;

      Print("🔄 Live adjustments reset - will use input parameters for next trades");

      m_basket_active = false;  
      m_best_price = 0;
      m_breakeven_activated = false;
      m_trailing_stop_level = 0;
      m_trailing_active = false;
     }
   bool              IsBasketActive() { return m_basket_active; }
   double            GetBasketAvgPrice() { return m_basket_avg_price; }
   double            GetBasketTotalLots() { return m_basket_total_lots; }
   ENUM_POSITION_TYPE GetBasketDirection() { return m_basket_direction; }
   bool              IsBreakevenActivated() { return m_breakeven_activated; }
   bool              IsTrailingActive() { return m_trailing_active; }
   double            GetTrailingStopLevel() { return m_trailing_stop_level; }
   double            GetBestPrice() { return m_best_price; }

   bool              HasPendingOrderAt(double price, double tolerance_pips = 5.0)
     {
      double tolerance = tolerance_pips * _Point;

      for(int i = 0; i < OrdersTotal(); i++)
        {
         if(order.SelectByIndex(i) && order.Magic() == MagicNumber && order.Symbol() == _Symbol)
           {
            if(MathAbs(order.PriceOpen() - price) <= tolerance)
               return true;
           }
        }
      return false;
     }
  };

//+------------------------------------------------------------------+
//| Enhanced Dashboard with News Integration                         |
//+------------------------------------------------------------------+
class CEnhancedDashboard
  {
private:
   string            m_panel_prefix;
   int               m_main_x, m_main_y;
   bool              m_is_minimized;

   color             m_bg_color;
   color             m_header_color;
   color             m_text_color;
   color             m_accent_color;
   color             m_button_color;
   color             m_border_color;

public:
                     CEnhancedDashboard() : m_panel_prefix("HonMatrix_"), m_main_x(10), m_main_y(50),
                     m_is_minimized(false)
     {
      m_bg_color = C'25,25,35';
      m_header_color = C'45,45,65';
      m_text_color = clrWhite;
      m_accent_color = C'0,150,255';
      m_button_color = C'60,60,80';
      m_border_color = C'100,100,120';
     }

   void              CreateAdvancedDashboard()
     {
      if(!ShowPanel)
         return;

      RemoveAllPanels();

      CreateLeftPanel();
      CreateCenterPanel();
      CreateRightPanel();
      CreateBottomPanel();
      CreateNewsPanel(); // New news-specific panel
     }

private:
   void              CreateCenterPanel()
     {
      int panel_width = 280;
      int panel_height = 300;
      int x = m_main_x + 340;
      int y = m_main_y;

      // Create panel background and header
      CreateRectangle(m_panel_prefix + "CenterBG", x, y, panel_width, panel_height, m_bg_color, m_border_color);
      CreateRectangle(m_panel_prefix + "CenterHeader", x, y, panel_width, 35, m_header_color, m_border_color);
      CreateLabel(m_panel_prefix + "CenterTitle", x + 10, y + 8, "LIVE PARAMETERS", clrYellow, 11, "Arial Bold");

      int status_y = y + 50;
      int param_y = status_y + 45;

      // ✅ CONDITIONAL LAYOUT based on trading status
      bool trades_active = g_trade_manager.IsBasketActive();

      if(trades_active)
        {
         // ✅ Show live adjustment controls when trades are active
         color btn_color = g_live_adjustments_active ? clrDarkGreen : clrDarkBlue;
         string btn_text = g_live_adjustments_active ? "LIVE ADJUST: ON" : "LIVE ADJUST: OFF";

         CreateButton(m_panel_prefix + "LiveAdjustBtn", x + 10, status_y, panel_width - 20, 30,
                      btn_text, btn_color, clrWhite);

         if(g_live_adjustments_active)
           {
            // Show editable controls
            CreateLabel(m_panel_prefix + "MultiplierLabel", x + 15, param_y, "Live Multiplier:", clrLime, 9);
            string current_mult = (g_live_multiplier > 0) ? DoubleToString(g_live_multiplier, 2) : DoubleToString(LotMultiplier, 2);
            CreateEditBox(m_panel_prefix + "MultiplierEdit", x + 120, param_y - 3, 60, 20, current_mult);

            param_y += 35;
            CreateLabel(m_panel_prefix + "StartLotLabel", x + 15, param_y, "Live Start Lot:", clrLime, 9);
            string current_lot = (g_live_start_lot > 0) ? DoubleToString(g_live_start_lot, 2) : DoubleToString(InitialLotSize, 2);
            CreateEditBox(m_panel_prefix + "StartLotEdit", x + 120, param_y - 3, 60, 20, current_lot);

            param_y += 35;
            CreateLabel(m_panel_prefix + "StepSizeLabel", x + 15, param_y, "Step Size:", m_text_color, 9);
            CreateEditBox(m_panel_prefix + "StepSizeEdit", x + 120, param_y - 3, 60, 20, IntegerToString((int)EntryDistance));

            param_y += 50;
            CreateButton(m_panel_prefix + "ApplyBtn", x + 15, param_y, 80, 25, "APPLY", clrDarkGreen, clrWhite);
            CreateButton(m_panel_prefix + "ResetBtn", x + 105, param_y, 80, 25, "RESET", clrDarkBlue, clrWhite);
           }
         else
           {
            // Show current input values (read-only)
            CreateLabel(m_panel_prefix + "InputMultiplier", x + 15, param_y,
                        "Using Input Multiplier: " + DoubleToString(LotMultiplier, 2), clrGray, 9);
            param_y += 25;
            CreateLabel(m_panel_prefix + "InputLot", x + 15, param_y,
                        "Using Input Lot: " + DoubleToString(InitialLotSize, 2), clrGray, 9);
            param_y += 35;
            CreateLabel(m_panel_prefix + "EnableInfo", x + 15, param_y,
                        "Click 'LIVE ADJUST: OFF' to enable editing", clrYellow, 8);
           }
        }
      else
        {
         // ✅ No trades active - show information only
         CreateLabel(m_panel_prefix + "NoTradesInfo", x + 10, status_y,
                     "No Active Trades", clrOrange, 12, "Arial Bold");

         CreateLabel(m_panel_prefix + "InfoText", x + 15, param_y,
                     "Live adjustments available only", clrGray, 9);
         param_y += 20;
         CreateLabel(m_panel_prefix + "InfoText2", x + 15, param_y,
                     "when trades are running.", clrGray, 9);

         param_y += 40;
         CreateLabel(m_panel_prefix + "CurrentInputs", x + 15, param_y,
                     "Current EA Settings:", clrWhite, 10, "Arial Bold");
         param_y += 25;
         CreateLabel(m_panel_prefix + "InputMultiplier", x + 15, param_y,
                     "• Multiplier: " + DoubleToString(LotMultiplier, 2), clrWhite, 9);
         param_y += 20;
         CreateLabel(m_panel_prefix + "InputLot", x + 15, param_y,
                     "• Initial Lot: " + DoubleToString(InitialLotSize, 2), clrWhite, 9);
         param_y += 20;
         CreateLabel(m_panel_prefix + "InputStep", x + 15, param_y,
                     "• Entry Distance: " + IntegerToString((int)EntryDistance), clrWhite, 9);
        }
     }
   void              CreateLeftPanel()
     {
      int panel_width = 320;
      int panel_height = 400;
      int x = m_main_x;
      int y = m_main_y;

      CreateRectangle(m_panel_prefix + "LeftBG", x, y, panel_width, panel_height, m_bg_color, m_border_color);
      CreateRectangle(m_panel_prefix + "LeftHeader", x, y, panel_width, 35, m_header_color, m_border_color);
      CreateLabel(m_panel_prefix + "LeftTitle", x + 10, y + 8, "ADVANCED TRADING SYSTEM", clrYellow, 11, "Arial Bold");

      int section_y = y + 45;
      CreateLabel(m_panel_prefix + "AccLabel", x + 10, section_y, "Account Information", m_accent_color, 10, "Arial Bold");

      CreateLabel(m_panel_prefix + "Balance", x + 15, section_y + 25, "Balance:", m_text_color, 9);
      CreateLabel(m_panel_prefix + "Equity", x + 15, section_y + 45, "Equity:", m_text_color, 9);
      CreateLabel(m_panel_prefix + "FreeMargin", x + 15, section_y + 65, "Free Margin:", m_text_color, 9);
      CreateLabel(m_panel_prefix + "MarginLevel", x + 15, section_y + 85, "Margin Level:", m_text_color, 9);

      section_y += 120;
      CreateLabel(m_panel_prefix + "StatusLabel", x + 10, section_y, "Trading Status", m_accent_color, 10, "Arial Bold");
      CreateLabel(m_panel_prefix + "ActivePos", x + 15, section_y + 25, "Active Positions:", m_text_color, 9);
      CreateLabel(m_panel_prefix + "TotalLots", x + 15, section_y + 45, "Total Lots:", m_text_color, 9);
      CreateLabel(m_panel_prefix + "FloatingPL", x + 15, section_y + 65, "Floating P&L:", m_text_color, 9);
      CreateLabel(m_panel_prefix + "TodayTrades", x + 15, section_y + 85, "Today's Trades:", m_text_color, 9);

      section_y += 120;
      CreateLabel(m_panel_prefix + "MarketLabel", x + 10, section_y, "Market Analysis", m_accent_color, 10, "Arial Bold");
      CreateLabel(m_panel_prefix + "MarketState", x + 15, section_y + 25, "Market State:", m_text_color, 9);
      CreateLabel(m_panel_prefix + "Spread", x + 15, section_y + 45, "Spread:", m_text_color, 9);
      CreateLabel(m_panel_prefix + "ATRInfo", x + 15, section_y + 65, "ATR:", m_text_color, 9);
     }

   void              CreateNewsPanel()
     {
      int panel_width = 400;
      int panel_height = 120;
      int x = m_main_x;
      int y = m_main_y + 510; // Below the main panels

      CreateRectangle(m_panel_prefix + "NewsBG", x, y, panel_width, panel_height, m_bg_color, m_border_color);
      CreateRectangle(m_panel_prefix + "NewsHeader", x, y, panel_width, 35, m_header_color, m_border_color);
      CreateLabel(m_panel_prefix + "NewsTitle", x + 10, y + 8, "NEWS FILTER STATUS", clrYellow, 11, "Arial Bold");

      // News status indicators
      int news_y = y + 50;
      CreateLabel(m_panel_prefix + "NewsStatus", x + 15, news_y, "News Filter:", m_text_color, 10);
      CreateLabel(m_panel_prefix + "TradingStatus", x + 15, news_y + 25, "Trading Status:", m_text_color, 10);
      CreateLabel(m_panel_prefix + "NextNews", x + 15, news_y + 45, "Next News:", m_text_color, 9);

      // News filter controls
      CreateButton(m_panel_prefix + "NewsToggleBtn", x + 250, news_y, 120, 25, "Toggle Filter", m_button_color, clrWhite);
     }

   void              CreateButton(string name, int x, int y, int width, int height, string text, color bg_color, color text_color)
     {
      // Create background rectangle
      CreateRectangle(name + "_BG", x, y, width, height, bg_color, m_border_color);

      // SAFER text positioning - use simple left padding
      int text_x = x + 8; // Fixed left padding
      int text_y = y + (height - 9) / 2; // Center vertically

      CreateLabel(name + "_Text", text_x, text_y, text, text_color, 9, "Arial Bold");

      // Make button clickable
      ObjectSetInteger(0, name + "_BG", OBJPROP_SELECTABLE, true);
      ObjectSetInteger(0, name + "_BG", OBJPROP_SELECTED, false);
      ObjectSetInteger(0, name + "_BG", OBJPROP_STATE, false);
     }
   void              CreateRightPanel()
     {
      int panel_width = 200;
      int panel_height = 180;
      int x = m_main_x + 640;
      int y = m_main_y;

      CreateRectangle(m_panel_prefix + "RightBG", x, y, panel_width, panel_height, m_bg_color, m_border_color);
      CreateRectangle(m_panel_prefix + "RightHeader", x, y, panel_width, 45, m_header_color, m_border_color);
      CreateLabel(m_panel_prefix + "BrandName", x + 10, y + 8, "HON", clrLime, 12, "Arial Bold");
      CreateLabel(m_panel_prefix + "AutoText", x + 10, y + 25, "MATRIX", clrRed, 10, "Arial Bold");

      int btn_y = y + 60;

      CreateButton(m_panel_prefix + "LossCloseBtn", x + 15, btn_y, panel_width - 30, 25, "Close Loss", clrDarkRed, clrWhite);

      btn_y += 35;
      CreateButton(m_panel_prefix + "ProfitCloseBtn", x + 15, btn_y, panel_width - 30, 25, "Close Profit", clrDarkGreen, clrWhite);

      btn_y += 35;
      CreateButton(m_panel_prefix + "CloseAllBtn", x + 15, btn_y, panel_width - 30, 25, "Close All", clrDarkBlue, clrWhite);
     }

   void              CreateBottomPanel()
     {
      int panel_width = 850;
      int panel_height = 80;
      int x = m_main_x;
      int y = m_main_y + 420;

      CreateRectangle(m_panel_prefix + "BottomBG", x, y, panel_width, panel_height, m_bg_color, m_border_color);
      CreateLabel(m_panel_prefix + "PerfLabel", x + 10, y + 8, "Performance Dashboard", m_accent_color, 10, "Arial Bold");

      int perf_y = y + 30;
      CreateLabel(m_panel_prefix + "TodayPL", x + 15, perf_y, "Today P&L:", m_text_color, 9);
      CreateLabel(m_panel_prefix + "WeekPL", x + 150, perf_y, "This Week P&L:", m_text_color, 9);
      CreateLabel(m_panel_prefix + "MonthPL", x + 300, perf_y, "This Month P&L:", m_text_color, 9);
      CreateLabel(m_panel_prefix + "TotalPL", x + 450, perf_y, "Total P&L:", m_text_color, 9);
      CreateLabel(m_panel_prefix + "WinRate", x + 600, perf_y, "Win Rate:", m_text_color, 9);
      CreateLabel(m_panel_prefix + "MaxDD", x + 720, perf_y, "Max DD:", m_text_color, 9);

      perf_y += 25;
      CreateLabel(m_panel_prefix + "ProtectionStatus", x + 15, perf_y, "Protection: ACTIVE | Trailing: ON | Breakeven: SET", clrLime, 9);
     }

public:
   void              UpdateDashboard(CRiskManager &risk_mgr, CTradeManager &trade_mgr, CMarketAnalyzer &market_analyzer, CAdvancedNewsFilter &news_filter)
     {
      if(!ShowPanel)
         return;

      // Update account information
      UpdateLabel(m_panel_prefix + "Balance", "Balance: $" + DoubleToString(AccountInfoDouble(ACCOUNT_BALANCE), 2));
      UpdateLabel(m_panel_prefix + "Equity", "Equity: $" + DoubleToString(AccountInfoDouble(ACCOUNT_EQUITY), 2));
      UpdateLabel(m_panel_prefix + "FreeMargin", "Free Margin: $" + DoubleToString(AccountInfoDouble(ACCOUNT_MARGIN_FREE), 2));

      double margin_level = AccountInfoDouble(ACCOUNT_MARGIN_LEVEL);
      color margin_color = (margin_level > 1000) ? clrLime : (margin_level > 500) ? clrYellow : clrRed;
      UpdateLabelColor(m_panel_prefix + "MarginLevel", "Margin Level: " + DoubleToString(margin_level, 2) + "%", margin_color);

      // Update trading status
      int positions = risk_mgr.GetGridPositionCount();
      UpdateLabel(m_panel_prefix + "ActivePos", "Active Positions: " + IntegerToString(positions));
      UpdateLabel(m_panel_prefix + "TotalLots", "Total Lots: " + DoubleToString(trade_mgr.GetBasketTotalLots(), 2));

      double floating_pl = risk_mgr.GetTotalProfit();
      color pl_color = (floating_pl > 0) ? clrLime : (floating_pl < 0) ? clrRed : clrWhite;
      UpdateLabelColor(m_panel_prefix + "FloatingPL", "Floating P&L: $" + DoubleToString(floating_pl, 2), pl_color);

      // Update market analysis
      ENUM_MARKET_PHASE phase = market_analyzer.GetMarketPhase();
      string phase_text = "";
      color phase_color = clrWhite;

      switch(phase)
        {
         case MARKET_RANGING:
            phase_text = "RANGING ✓";
            phase_color = clrLime;
            break;
         case MARKET_TRENDING:
            phase_text = "TRENDING ⚠";
            phase_color = clrOrange;
            break;
         default:
            phase_text = "CONSOLIDATING";
            phase_color = clrYellow;
        }

      UpdateLabelColor(m_panel_prefix + "MarketState", "Market State: " + phase_text, phase_color);
      UpdateLabel(m_panel_prefix + "Spread", "Spread: " + IntegerToString((int)(SymbolInfoInteger(_Symbol, SYMBOL_SPREAD))));
      UpdateLabel(m_panel_prefix + "ATRInfo", "ATR: " + DoubleToString(market_analyzer.GetATR() / _Point, 1) + " pips");

      // Update news filter status
      string news_status = EnableNewsFilter ? "ACTIVE" : "DISABLED";
      color news_color = EnableNewsFilter ? clrLime : clrGray;
      UpdateLabelColor(m_panel_prefix + "NewsStatus", "News Filter: " + news_status, news_color);

      // Update trading status based on news
      bool trading_allowed = news_filter.IsTradingAllowed();
      string trading_status = trading_allowed ? "ALLOWED" : "HALTED";
      color trading_color = trading_allowed ? clrLime : clrRed;

      if(!trading_allowed)
        {
         trading_status += " - " + news_filter.GetHaltReason();
        }

      UpdateLabelColor(m_panel_prefix + "TradingStatus", "Trading: " + trading_status, trading_color);

      // Update next news info
      string next_news = news_filter.GetNextNewsInfo();
      UpdateLabel(m_panel_prefix + "NextNews", "Next: " + next_news);

      // Update protection status
      if(trade_mgr.IsBasketActive())
        {
         string protection_status = "Protection: ";
         if(trade_mgr.IsBreakevenActivated())
           {
            protection_status += "ACTIVE | Trailing: ";
            protection_status += trade_mgr.IsTrailingActive() ? "ON" : "STANDBY";
            protection_status += " | Breakeven: SET";
           }
         else
           {
            protection_status += "WAITING | Breakeven: " + DoubleToString(BreakevenTrigger, 1) + " pips to go";
           }
         UpdateLabelColor(m_panel_prefix + "ProtectionStatus", protection_status, clrLime);
        }
      else
        {
         UpdateLabel(m_panel_prefix + "ProtectionStatus", "Protection: INACTIVE | Waiting for entry signal...");
        }

      // Update performance metrics
      UpdateLabel(m_panel_prefix + "TodayPL", "Today P&L: $" + DoubleToString(floating_pl, 2));
      UpdateLabel(m_panel_prefix + "TotalPL", "Total P&L: $" + DoubleToString(floating_pl, 2));
     }

   bool              HandleButtonClick(string button_name)
     {
      Print("Handling button: ", button_name); // Debug line

      if(button_name == "HonMatrix_LossCloseBtn")
        {
         if(g_trade_manager.IsBasketActive())
           {
            g_trade_manager.CloseAllBasketPositions();
            Print("✓ Manual Loss Close executed");
            return true;
           }
        }
      else
         if(button_name == "HonMatrix_ProfitCloseBtn")
           {
            if(g_trade_manager.IsBasketActive())
              {
               g_trade_manager.CloseAllBasketPositions();
               Print("✓ Manual Profit Close executed");
               return true;
              }
           }
         else
            if(button_name == "HonMatrix_CloseAllBtn")
              {
               if(g_trade_manager.IsBasketActive())
                 {
                  g_trade_manager.CloseAllBasketPositions();
                  Print("✓ Manual Close All executed");
                  return true;
                 }
              }
            else
               if(button_name == "HonMatrix_NewsToggleBtn")
                 {
                  Print("✓ News Filter toggle clicked (requires restart to change)");
                  return true;
                 }

      return false;
     }
private:
   void              CreateRectangle(string name, int x, int y, int width, int height, color bg_color, color border_color)
     {
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_color);
      ObjectSetInteger(0, name, OBJPROP_COLOR, border_color);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
     }

   void              CreateLabel(string name, int x, int y, string text, color text_color = clrWhite, int font_size = 9, string font = "Arial")
     {
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, font);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
      ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
     }


   void              CreateEditBox(string name, int x, int y, int width, int height, string initial_value)
     {
      ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
      ObjectSetString(0, name, OBJPROP_TEXT, initial_value);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlack);
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrWhite);
      ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, m_border_color);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
     }

   void              UpdateLabel(string name, string new_text)
     {
      if(ObjectFind(0, name) >= 0)
         ObjectSetString(0, name, OBJPROP_TEXT, new_text);
     }

   void              UpdateLabelColor(string name, string new_text, color new_color)
     {
      if(ObjectFind(0, name) >= 0)
        {
         ObjectSetString(0, name, OBJPROP_TEXT, new_text);
         ObjectSetInteger(0, name, OBJPROP_COLOR, new_color);
        }
     }

public:
   void              RemoveAllPanels()
     {
      int total = ObjectsTotal(0);
      for(int i = total - 1; i >= 0; i--)
        {
         string obj_name = ObjectName(0, i);
         if(StringFind(obj_name, m_panel_prefix) >= 0)
            ObjectDelete(0, obj_name);
        }
     }
  };
//+------------------------------------------------------------------+
//| Backtest Validation Class - Minimal Implementation              |
//+------------------------------------------------------------------+
class CBacktestValidator
  {
private:
   datetime          m_start_date;
   double            m_start_capital;
   bool              m_validation_enabled;
   bool              m_validation_passed;

public:
                     CBacktestValidator() : m_start_date(0), m_start_capital(0), m_validation_enabled(false), m_validation_passed(false) {}

   bool              Initialize()
     {
      m_start_date = Start_Date;
      m_start_capital = StartCapital;
      m_validation_enabled = EnableBacktestValidation;

      if(!m_validation_enabled)
        {
         Print("✓ Backtest Validation: DISABLED");
         return true;
        }

      // For backtesting, check if we have enough historical data
      // Get the actual test period from HistorySelect
      if(!HistorySelect(m_start_date, TimeCurrent()))
        {
         Print("❌ BACKTEST VALIDATION FAILED: Cannot select history period");
         return false;
        }

      // Check if we have at least 1 year of testing period
      datetime test_period = TimeCurrent() - m_start_date;
      int seconds_in_year = 365 * 24 * 3600;

      if(test_period < seconds_in_year)
        {
         Print("❌ BACKTEST VALIDATION FAILED: Test period too short");
         Print("   Start Date: ", TimeToString(m_start_date, TIME_DATE));
         Print("   End Date: ", TimeToString(TimeCurrent(), TIME_DATE));
         Print("   Testing Period: ", test_period / (24 * 3600), " days");
         Print("   Required: 365 days minimum");
         return false;
        }

      m_validation_passed = true;
      return true;
     }
   // Simple profit calculation from start date
   double            CalculateTotalProfit()
     {
      if(!m_validation_enabled)
         return 0;

      HistorySelect(m_start_date, TimeCurrent());
      double total_profit = 0.0;
      uint total = HistoryDealsTotal();

      for(uint i = 0; i < total; i++)
        {
         ulong ticket = HistoryDealGetTicket(i);
         if(ticket > 0)
           {
            long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
            if(entry == DEAL_ENTRY_IN)
               continue;

            string symbol = HistoryDealGetString(ticket, DEAL_SYMBOL);
            long order_magic = HistoryDealGetInteger(ticket, DEAL_MAGIC);

            if(order_magic == MagicNumber && symbol == _Symbol)
              {
               double deal_commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
               double deal_swap = HistoryDealGetDouble(ticket, DEAL_SWAP);
               double deal_profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
               total_profit += deal_commission + deal_swap + deal_profit;
              }
           }
        }

      return total_profit;
     }

   // Get validation status for dashboard
   bool              IsValidationPassed() { return m_validation_passed; }
   bool              IsValidationEnabled() { return m_validation_enabled; }

   // Get basic stats for display
   string            GetValidationStatus()
     {
      if(!m_validation_enabled)
         return "Validation: DISABLED";

      if(!m_validation_passed)
         return "Validation: FAILED";

      datetime current_time = TimeCurrent();
      int testing_days = (int)((current_time - m_start_date) / (24 * 3600));
      double total_profit = CalculateTotalProfit();
      double profit_percent = (total_profit / m_start_capital) * 100.0;

      return StringFormat("Validation: PASSED | %d days | %.1f%%", testing_days, profit_percent);
     }
  };
//+------------------------------------------------------------------+
//| Global Class Instances                                           |
//+------------------------------------------------------------------+
CMarketAnalyzer g_market_analyzer;
CRiskManager g_risk_manager;
CTradeManager g_trade_manager;
CEnhancedDashboard g_enhanced_panel;
CAdvancedNewsFilter g_news_filter; // New global news filter instance
CEnhancedSRDetector g_sr_detector;
CBacktestValidator g_backtest_validator;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double NormalizePrice(double price)
  {
   double tick_size = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   if(tick_size <= 0)
      return NormalizeDouble(price, _Digits);
   return NormalizeDouble(MathRound(price / tick_size) * tick_size, _Digits);
  }
//+------------------------------------------------------------------+
//| Lot Size Normalization Helper Function                           |
//+------------------------------------------------------------------+
double NormalizeLots(double lot_size)
  {
   double lot_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double min_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double max_lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

// Ensure the lot size is a correct multiple of the lot step
   if(lot_step > 0)
     {
      lot_size = MathRound(lot_size / lot_step) * lot_step;
     }

// Enforce minimum and maximum lot sizes
   lot_size = MathMax(lot_size, min_lot);
   lot_size = MathMin(lot_size, max_lot); // Broker's max
   lot_size = MathMin(lot_size, MaxLotSize); // EA's input max

// CRITICAL FIX: Eliminate trailing floating-point errors
   int decimals = 2; // Default for 0.01 step
   if (lot_step == 0.1) decimals = 1;
   else if (lot_step == 0.01) decimals = 2;
   else if (lot_step == 0.001) decimals = 3;

   return NormalizeDouble(lot_size, decimals);
  }
//+------------------------------------------------------------------+
//| Time Filter Function                                             |
//+------------------------------------------------------------------+
bool IsWithinTradingHours()
  {
   if(!UseTimeFilter)
      return true;

   MqlDateTime current_time;
   TimeToStruct(TimeCurrent(), current_time);

   string start_parts[], end_parts[];
   int start_count = StringSplit(StartTime, ':', start_parts);
   int end_count = StringSplit(EndTime, ':', end_parts);

   if(start_count < 2 || end_count < 2)
      return true;

   int start_hour = (int)StringToInteger(start_parts[0]);
   int start_min = (int)StringToInteger(start_parts[1]);
   int end_hour = (int)StringToInteger(end_parts[0]);
   int end_min = (int)StringToInteger(end_parts[1]);

   int current_minutes = current_time.hour * 60 + current_time.min;
   int start_minutes = start_hour * 60 + start_min;
   int end_minutes = end_hour * 60 + end_min;

   return (current_minutes >= start_minutes && current_minutes <= end_minutes);
  }

//+------------------------------------------------------------------+
//| Check Account Profit/Loss Levels                                 |
//+------------------------------------------------------------------+
bool CheckAccountProfitLossLevels()
  {
   if(CloseLosesAtPercent <= 0 && CloseProfitsAtPercent <= 0)
      return false;

   if(g_risk_manager.GetGridPositionCount() == 0)
      return false;

   double total_profit = g_risk_manager.GetTotalProfit();
   double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);

   if(account_balance <= 0)
      return false;

   double profit_loss_percent = (total_profit / account_balance) * 100.0;

   if(CloseLosesAtPercent > 0 && total_profit < 0)
     {
      if(MathAbs(profit_loss_percent) >= CloseLosesAtPercent)
        {
         Print("!! EMERGENCY CLOSE: Total loss of ", DoubleToString(total_profit, 2),
               " (", DoubleToString(profit_loss_percent, 2), "%) has reached limit");
         g_trade_manager.CloseAllBasketPositions();
         return true;
        }
     }

   if(CloseProfitsAtPercent > 0 && total_profit > 0)
     {
      if(profit_loss_percent >= CloseProfitsAtPercent)
        {
         Print("!! PROFIT TARGET CLOSE: Total profit of ", DoubleToString(total_profit, 2),
               " (", DoubleToString(profit_loss_percent, 2), "%) has reached target");
         g_trade_manager.CloseAllBasketPositions();
         return true;
        }
     }

   return false;
  }

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   Print("=== Initializing Hon-Matrix Pro EA with Advanced News Filter ===");

// Validate inputs
   if(MaxAccountExposure <= 0 || MaxAccountExposure > 50)
     {
      Print("ERROR: MaxAccountExposure must be between 0 and 50%");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(MaxGridOrders < 1 || MaxGridOrders > 20)
     {
      Print("ERROR: MaxGridOrders must be between 1 and 20");
      return INIT_PARAMETERS_INCORRECT;
     }

   if(InitialLotSize <= 0)
     {
      Print("ERROR: InitialLotSize must be greater than 0");
      return INIT_PARAMETERS_INCORRECT;
     }

// Validate news filter inputs
   if(EnableNewsFilter)
     {
      if(StopBeforeNewsMin < 0 || StopAfterNewsMin < 0)
        {
         Print("ERROR: News filter minutes must be >= 0");
         return INIT_PARAMETERS_INCORRECT;
        }

      if(!EnableHighImpact && !EnableMediumImpact && !EnableLowImpact)
        {
         Print("WARNING: All news impact levels disabled. News filter will have no effect.");
        }
     }

// Initialize trade object
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetMarginMode();
   trade.SetTypeFillingBySymbol(_Symbol);
   trade.SetDeviationInPoints(10);

// Initialize market analyzer
   if(!g_market_analyzer.Initialize())
     {
      Print("ERROR: Failed to initialize Market Analyzer");
      return INIT_FAILED;
     }

// Initialize news filter
   if(!g_news_filter.Initialize())
     {
      Print("ERROR: Failed to initialize News Filter");
      return INIT_FAILED;
     }

// Create enhanced panel with news integration
   g_enhanced_panel.CreateAdvancedDashboard();

// Print configuration
   Print("✓ EA initialized successfully");
   Print("✓ Symbol: ", _Symbol);
   Print("✓ Max Account Exposure: ", MaxAccountExposure, "%");
   Print("✓ Close at Loss Percent: ", (CloseLosesAtPercent > 0 ? DoubleToString(CloseLosesAtPercent, 1) + "%" : "Disabled"));
   Print("✓ Close at Profit Percent: ", (CloseProfitsAtPercent > 0 ? DoubleToString(CloseProfitsAtPercent, 1) + "%" : "Disabled"));
   Print("✓ Max Grid Orders: ", MaxGridOrders);
   Print("✓ News Filter: ", EnableNewsFilter ? "ENABLED" : "DISABLED");

   if(EnableNewsFilter)
     {
      Print("  - Stop Before News: ", StopBeforeNewsMin, " minutes");
      Print("  - Stop After News: ", StopAfterNewsMin, " minutes");
      Print("  - High Impact: ", EnableHighImpact ? "YES" : "NO");
      Print("  - Medium Impact: ", EnableMediumImpact ? "YES" : "NO");
      Print("  - Low Impact: ", EnableLowImpact ? "YES" : "NO");
      Print("  - Monitored Currencies: ", NewsSymbols);
      Print("  - Close Positions Before News: ", ClosePositionsBeforeNews ? "YES" : "NO");
      Print("  - Use Internal Calendar: ", UseInternalCalendar ? "YES" : "NO");
      Print("  - Draw News Lines: ", DrawNewsLines ? "YES" : "NO");
     }

   Print("✓ Ultimate Take Profit: ", TakeProfitPips, " pips");
   Print("✓ Trailing Stop: ", UseTrailingStop ? "Enabled" : "Disabled");
// Initialize enhanced S/R detector
   if(UseEnhancedEntry)
     {
      if(!g_sr_detector.Initialize())
        {
         Print("ERROR: Failed to initialize Enhanced S/R Detector");
         return INIT_FAILED;
        }
      Print("✓ Enhanced S/R Entry System initialized");
      Print("  - S/R Lookback: ", SR_LookbackPeriod, " bars");
      Print("  - Min S/R Strength: ", SR_MinStrength);
      Print("  - S/R Zone Buffer: ", SR_ZoneBuffer, " pips");
      Print("  - Channel Trading: ", UseChannelTrading ? "Enabled" : "Disabled");
      Print("  - Dynamic Lot Sizing: ", UseDynamicLotSizing ? "Enabled" : "Disabled");
     }
   return INIT_SUCCEEDED;
  }

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   Print("=== Hon-Matrix Pro EA with News Filter Deinitialized ===");
   Print("Reason: ", reason);

   g_market_analyzer.Release();
   g_news_filter.Cleanup();
   g_enhanced_panel.RemoveAllPanels();

   ObjectsDeleteAll(0, "Hon-MatrixProPanel");
   ObjectsDeleteAll(0, "HonMatrix_");
   ObjectsDeleteAll(0, "NewsLine_");
  }

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   static datetime last_update = 0;

   if(TimeCurrent() - last_update < 10)
      return;
   last_update = TimeCurrent();

   if(!g_market_analyzer.UpdateData())
      return;

   g_trade_manager.UpdateBasketInfo();

// Check account protection levels first
   if(CheckAccountProfitLossLevels())
      return;

// Update panel every 30 seconds with news filter integration
   static datetime last_panel_update = 0;
   if(TimeCurrent() - last_panel_update >= 30)
     {
      g_enhanced_panel.UpdateDashboard(g_risk_manager, g_trade_manager, g_market_analyzer, g_news_filter);
      last_panel_update = TimeCurrent();
     }

// Check basket take profit
   g_trade_manager.CheckBasketTakeProfit();

// Main trading logic with news filter integration
   if(IsWithinTradingHours() &&
      g_risk_manager.IsExposureAcceptable() &&
      g_news_filter.IsTradingAllowed()) // NEW: News filter check
     {
      ProcessTradingLogic();
     }
   else
      if(!g_news_filter.IsTradingAllowed())
        {
         // Optional: Update comment to show news halt reason
         static string last_comment = "";
         string current_comment = "Trading Halted: " + g_news_filter.GetHaltReason();
         if(last_comment != current_comment)
           {
            Comment(current_comment);
            last_comment = current_comment;
           }
        }
  }

//+------------------------------------------------------------------+
//| Main Trading Logic (keeping existing implementation)             |
//+------------------------------------------------------------------+
void ProcessTradingLogic()
  {
   if(!g_trade_manager.IsBasketActive())
     {
      // Try enhanced entry first
      if(UseEnhancedEntry)
        {
         CheckEnhancedSimpleEntry();
        }
      else
        {
         CheckForNewEntry(); // Original Fibonacci entry
        }

      // Fallback to simple trend entry
      if(UseSimpleEntry)
        {
         static datetime last_simple_check = 0;
         if(TimeCurrent() - last_simple_check > 3600)
           {
            if(!g_trade_manager.IsBasketActive())
              {
               CheckSimpleEntry();
              }
            last_simple_check = TimeCurrent();
           }
        }
     }
   else
     {
      CheckForGridAddition();
     }
  }



//+------------------------------------------------------------------+
//| Simple Entry System                                               |
//+------------------------------------------------------------------+
void CheckSimpleEntry()
  {
   ENUM_TREND_DIRECTION trend = g_market_analyzer.GetTrendDirection();
   if(trend == TREND_NEUTRAL)
      return;

   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atr = g_market_analyzer.GetATR();

   if(atr > 100 * _Point)
      return;

   static datetime last_simple_trade = 0;
   if(TimeCurrent() - last_simple_trade < 86400)
      return;

   double lot_size = g_risk_manager.CalculatePositionSize(0);

   if(trend == TREND_BULLISH)
     {
      if(g_risk_manager.ValidateTrade(lot_size, ORDER_TYPE_BUY))
        {
         if(g_trade_manager.OpenInitialPosition(ORDER_TYPE_BUY, lot_size, Commentary + "_Simple_Buy"))
           {
            Print("✓ Simple BUY entry executed - Trend: BULLISH, Price: ", current_price);
            last_simple_trade = TimeCurrent();
           }
        }
     }
   else
      if(trend == TREND_BEARISH)
        {
         if(g_risk_manager.ValidateTrade(lot_size, ORDER_TYPE_SELL))
           {
            if(g_trade_manager.OpenInitialPosition(ORDER_TYPE_SELL, lot_size, Commentary + "_Simple_Sell"))
              {
               Print("✓ Simple SELL entry executed - Trend: BEARISH, Price: ", current_price);
               last_simple_trade = TimeCurrent();
              }
           }
        }
  }

//+------------------------------------------------------------------+
//| Check for New Entry Signal                                       |
//+------------------------------------------------------------------+
void CheckForNewEntry()
  {
   static datetime last_debug_time = 0;
   bool debug_this_tick = (TimeCurrent() - last_debug_time > 3600);
   double lot_size = g_risk_manager.CalculatePositionSize(0);
   ENUM_MARKET_PHASE phase = g_market_analyzer.GetMarketPhase();
   if(debug_this_tick)
      Print("DEBUG: Market Phase = ", EnumToString(phase));

   if(phase == MARKET_TRENDING)
     {
      if(debug_this_tick)
         Print("DEBUG: Skipping entry - Market is TRENDING");
      return;
     }

   ENUM_TREND_DIRECTION trend = g_market_analyzer.GetTrendDirection();
   if(debug_this_tick)
      Print("DEBUG: Trend Direction = ", EnumToString(trend));

   if(trend == TREND_NEUTRAL)
     {
      if(debug_this_tick)
         Print("DEBUG: Skipping entry - Trend is NEUTRAL");
      return;
     }

   double swing_high, swing_low;
   if(!g_market_analyzer.GetSwingLevels(swing_high, swing_low))
     {
      if(debug_this_tick)
         Print("DEBUG: Failed to get swing levels");
      return;
     }

   if(debug_this_tick)
      Print("DEBUG: Swing High = ", swing_high, ", Swing Low = ", swing_low);

   double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double entry_distance = EntryDistance * _Point;

   if(trend == TREND_BULLISH)
     {
      bool rsi_ok = g_market_analyzer.IsRSIOversold();
      double fib_support = g_market_analyzer.CalculateFibonacciLevel(swing_high, swing_low, FibLevel3, true);
      double distance = MathAbs(current_price - fib_support);
      bool near_fib = (distance <= entry_distance);

      if(debug_this_tick)
        {
         Print("DEBUG: BUY Check - RSI OK: ", rsi_ok, ", Current RSI: ", g_market_analyzer.GetRSI());
         Print("DEBUG: BUY Check - Fib Support: ", fib_support, ", Current Price: ", current_price);
         Print("DEBUG: BUY Check - Distance: ", distance/_Point, " pips, Max Distance: ", EntryDistance, " pips");
         Print("DEBUG: BUY Check - Near Fib: ", near_fib);
        }

      if(rsi_ok && near_fib)
        {
         double lot_size = g_risk_manager.CalculatePositionSize(0);

         if(g_risk_manager.ValidateTrade(lot_size, ORDER_TYPE_BUY))
           {
            if(g_trade_manager.OpenInitialPosition(ORDER_TYPE_BUY, lot_size, Commentary + "_Initial_Buy"))
              {
               Print("✓ BUY signal executed at Fibonacci support: ", fib_support);
               Print("  Current price: ", current_price, " Distance: ", distance / _Point, " pips");
               Print("  RSI: ", g_market_analyzer.GetRSI(), " Lot size: ", lot_size);
              }
           }
         else
           {
            if(debug_this_tick)
               Print("DEBUG: BUY trade validation failed");
           }
        }
     }
   else
      if(trend == TREND_BEARISH)
        {
         bool rsi_ok = g_market_analyzer.IsRSIOverbought();
         double fib_resistance = g_market_analyzer.CalculateFibonacciLevel(swing_high, swing_low, FibLevel3, true);
         double distance = MathAbs(current_price - fib_resistance);
         bool near_fib = (distance <= entry_distance);

         if(debug_this_tick)
           {
            Print("DEBUG: SELL Check - RSI OK: ", rsi_ok, ", Current RSI: ", g_market_analyzer.GetRSI());
            Print("DEBUG: SELL Check - Fib Resistance: ", fib_resistance, ", Current Price: ", current_price);
            Print("DEBUG: SELL Check - Distance: ", distance/_Point, " pips, Max Distance: ", EntryDistance, " pips");
            Print("DEBUG: SELL Check - Near Fib: ", near_fib);
           }

         if(rsi_ok && near_fib)
           {
            double lot_size = g_risk_manager.CalculatePositionSize(0);

            if(g_risk_manager.ValidateTrade(lot_size, ORDER_TYPE_SELL))
              {
               if(g_trade_manager.OpenInitialPosition(ORDER_TYPE_SELL, lot_size, Commentary + "_Initial_Sell"))
                 {
                  Print("✓ SELL signal executed at Fibonacci resistance: ", fib_resistance);
                  Print("  Current price: ", current_price, " Distance: ", distance / _Point, " pips");
                  Print("  RSI: ", g_market_analyzer.GetRSI(), " Lot size: ", lot_size);
                 }
              }
            else
              {
               if(debug_this_tick)
                  Print("DEBUG: SELL trade validation failed");
              }
           }
        }

   if(debug_this_tick)
      last_debug_time = TimeCurrent();
  }

//+------------------------------------------------------------------+
//| Check for Grid Addition                                          |
//+------------------------------------------------------------------+
void CheckForGridAddition()
  {
   if(!UseFibonacciGrid)
      return;

// 1. Limit check (Positions + Pending)
   int total_count = g_risk_manager.GetTotalGridCount();
   if(total_count >= MaxGridOrders)
      return;

   if(!g_risk_manager.IsExposureAcceptable())
      return;

// 2. Get data for calculation
   int current_positions = g_risk_manager.GetGridPositionCount();
   double swing_high, swing_low;

   if(!g_market_analyzer.GetSwingLevels(swing_high, swing_low))
      return;

   double fib_levels[] = {FibLevel1, FibLevel2, FibLevel3, FibLevel4};
   ENUM_POSITION_TYPE basket_direction = g_trade_manager.GetBasketDirection();

// 3. Loop through Fibonacci levels
   for(int i = 0; i < 4; i++)
     {
      double fib_level = g_market_analyzer.CalculateFibonacciLevel(swing_high, swing_low, fib_levels[i], true);

      // Skip if an order already exists at this price
      if(g_trade_manager.HasPendingOrderAt(fib_level, 10.0))
         continue;

      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      // --- CRITICAL FIX: Declare the boolean variable ---
      bool should_place_order = false;

      if(basket_direction == POSITION_TYPE_BUY && fib_level < ask)
         should_place_order = true;
      else
         if(basket_direction == POSITION_TYPE_SELL && fib_level > bid)
            should_place_order = true;

      if(should_place_order)
        {
         // Calculate lot size based on current open positions
         double next_lot = g_risk_manager.CalculatePositionSize(current_positions);
         ENUM_ORDER_TYPE order_type = (basket_direction == POSITION_TYPE_BUY) ? ORDER_TYPE_BUY_LIMIT : ORDER_TYPE_SELL_LIMIT;

         if(g_risk_manager.ValidateTrade(next_lot, order_type))
           {
            if(g_trade_manager.AddToGrid(fib_level, next_lot, fib_levels[i]))
              {
               Print("✓ Grid order placed at Fib ", fib_levels[i], "%: ", fib_level);
               break; // Place only one order per tick to prevent duplicates
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Chart Event Handler                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
  {
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      Print("DEBUG: Object clicked: ", sparam);

      // Reset button state first
      if(StringFind(sparam, "_BG") >= 0)
        {
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
        }

      // Handle specific button clicks
      if(sparam == "HonMatrix_LiveAdjustBtn_BG")
        {
         if(!g_trade_manager.IsBasketActive())
           {
            Alert("⚠️ No active trades to adjust!");
            return;
           }

         g_live_adjustments_active = !g_live_adjustments_active;

         if(!g_live_adjustments_active)
           {
            // Reset to input parameters
            g_live_multiplier = 0.0;
            g_live_start_lot = 0.0;
            Print("🔄 Switched back to INPUT parameters");
            Alert("Switched back to EA input settings");
           }
         else
           {
            // Initialize with current input values
            g_live_multiplier = LotMultiplier;
            g_live_start_lot = InitialLotSize;
            Print("🎛️ Live adjustments ENABLED");
            Alert("Live adjustments enabled - you can now modify multiplier");
           }

         ChartRedraw();
        }
      else
         if(sparam == "HonMatrix_ApplyBtn_BG")
           {
            // ✅ Only allow changes during active trading
            if(!g_trade_manager.IsBasketActive())
              {
               Alert("⚠️ Live adjustments only available during active trading!");
               Print("❌ Cannot change multiplier - no active trades");
               return;
              }

            string mult_str = ObjectGetString(0, "HonMatrix_MultiplierEdit", OBJPROP_TEXT);
            double new_multiplier = StringToDouble(mult_str);

            // Validate range
            if(new_multiplier >= 1.0 && new_multiplier <= 3.0)
              {
               g_live_multiplier = new_multiplier;
               g_live_adjustments_active = true;

               Print("✅ LIVE multiplier changed to: ", g_live_multiplier);
               Print("  Next grid trade will use new multiplier");
               Print("  Current trades remain unchanged");

               Alert("Multiplier updated to " + DoubleToString(g_live_multiplier, 2) + " for future trades");
              }
            else
              {
               Alert("❌ Invalid multiplier. Use 1.0 to 3.0");
              }

            ChartRedraw();
           }
         else
            if(sparam == "HonMatrix_LossCloseBtn_BG")
              {
               if(g_trade_manager.IsBasketActive())
                 {
                  g_trade_manager.CloseAllBasketPositions();
                  Print("✓ Manual Loss Close executed");
                 }
               ChartRedraw();
              }
            else
               if(sparam == "HonMatrix_ProfitCloseBtn_BG")
                 {
                  if(g_trade_manager.IsBasketActive())
                    {
                     g_trade_manager.CloseAllBasketPositions();
                     Print("✓ Manual Profit Close executed");
                    }
                  ChartRedraw();
                 }
               else
                  if(sparam == "HonMatrix_CloseAllBtn_BG")
                    {
                     if(g_trade_manager.IsBasketActive())
                       {
                        g_trade_manager.CloseAllBasketPositions();
                        Print("✓ Manual Close All executed");
                       }
                     ChartRedraw();
                    }
                  else
                     if(sparam == "HonMatrix_NewsToggleBtn_BG")
                       {
                        Print("✓ News Filter toggle clicked (requires restart to change)");
                        Alert("News Filter toggle clicked. Restart EA to modify news filter settings.");
                        ChartRedraw();
                       }
                     else
                        if(sparam == "HonMatrix_ResetBtn_BG")
                          {
                           // Reset to current input values (only works if live adjustments are active)
                           if(g_live_adjustments_active)
                             {
                              ObjectSetString(0, "HonMatrix_MultiplierEdit", OBJPROP_TEXT, DoubleToString(LotMultiplier, 2));
                              Print("✓ Reset to EA input values");
                             }
                           else
                             {
                              Alert("Enable live adjustments first");
                             }
                           ChartRedraw();
                          }
     }
  }
//+------------------------------------------------------------------+
//| Trade Event Handler                                              |
//+------------------------------------------------------------------+
void OnTrade()
  {
   g_trade_manager.UpdateBasketInfo();

   static datetime last_trade_time = 0;
   if(TimeCurrent() - last_trade_time >= 1)
     {
      Print("Trade event detected - updating basket info");
      last_trade_time = TimeCurrent();
     }
  }

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                     BarDump.mq5  |
//|  Tester helper: writes every closed M1 bar of the test symbol to |
//|  Common\Files\bars_<symbol>_M1.csv for offline trade replays.    |
//|  Run with 1-min OHLC modelling. Places no trades.                |
//+------------------------------------------------------------------+
#property copyright "2026"
#property version   "1.00"
#property strict

int      g_file = INVALID_HANDLE;
datetime g_last = 0;

int OnInit()
  {
   g_file = FileOpen("bars_" + _Symbol + "_M1.csv", FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
   if(g_file == INVALID_HANDLE)
      return(INIT_FAILED);
   FileWriteString(g_file, "time,open,high,low,close\n");
   return(INIT_SUCCEEDED);
  }

void OnTick()
  {
   const datetime t = iTime(_Symbol, PERIOD_M1, 0);
   if(t == g_last)
      return;
   g_last = t;
   MqlRates r[];
   if(CopyRates(_Symbol, PERIOD_M1, 1, 1, r) == 1)
      FileWriteString(g_file, StringFormat("%s,%s,%s,%s,%s\n", TimeToString(r[0].time, TIME_DATE | TIME_MINUTES),
                                           DoubleToString(r[0].open, _Digits), DoubleToString(r[0].high, _Digits),
                                           DoubleToString(r[0].low, _Digits), DoubleToString(r[0].close, _Digits)));
  }

void OnDeinit(const int reason) { if(g_file != INVALID_HANDLE) FileClose(g_file); }

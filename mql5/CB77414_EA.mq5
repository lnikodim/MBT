//+------------------------------------------------------------------+
//|                                              MACrossoverEA.mq5   |
//|                                 Musa Khunarikov, Copyright 2026. |
//|                      https://www.mql5.com/ru/users/musa1994/news |
//+------------------------------------------------------------------+
#property copyright "Musa Khunarikov, 2026"
#property link      "https://www.mql5.com/ru/users/musa1994/news"
#property version   "1.00"

#property description "MA Crossover EA — советник на пересечении двух скользящих средних."
#property description "BUY/SELL при пересечении Fast и Slow MA. Одна позиция, SL/TP."
#property description "Нормализация объема + проверка маржи."

//--- Настройки
input double Lot            = 0.01;      // Размер лота
input int    FastMAPeriod   = 5;         // Период быстрой MA
input int    SlowMAPeriod   = 21;        // Период медленной MA
input int    StopLoss       = 300;       // SL в пунктах
input int    TakeProfit     = 600;       // TP в пунктах
input int    MagicNumber    = 123456;    // Магический номер
input bool   TradeOnNewBar  = true;      // Торговать только на новом баре

//--- Глобальные переменные
int      fastHandle, slowHandle;
datetime lastBarTime = 0;

//+------------------------------------------------------------------+
//| Инициализация                                                     |
//+------------------------------------------------------------------+
int OnInit()
{
   fastHandle = iMA(_Symbol, _Period, FastMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   slowHandle = iMA(_Symbol, _Period, SlowMAPeriod, 0, MODE_SMA, PRICE_CLOSE);

   if(fastHandle == INVALID_HANDLE || slowHandle == INVALID_HANDLE) {
      Print("Ошибка создания MA. Код: ", GetLastError());
      return(INIT_FAILED);
   }

   Print("MA Crossover EA запущен. Fast=", FastMAPeriod, " Slow=", SlowMAPeriod);
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Деинициализация                                                   |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(fastHandle);
   IndicatorRelease(slowHandle);
   Print("MA Crossover EA остановлен. Причина: ", reason);
}

//+------------------------------------------------------------------+
//| Главная торговая логика                                           |
//+------------------------------------------------------------------+
void OnTick()
{
   if(TradeOnNewBar) {
      datetime curBar = iTime(_Symbol, _Period, 0);
      if(curBar == lastBarTime) return;
      lastBarTime = curBar;
   }

   if(PositionExists()) return;

   double fast[2], slow[2];
   if(CopyBuffer(fastHandle, 0, 1, 2, fast) <= 0) return;
   if(CopyBuffer(slowHandle, 0, 1, 2, slow) <= 0) return;

   bool buySignal  = (fast[0] > slow[0] && fast[1] <= slow[1]);
   bool sellSignal = (fast[0] < slow[0] && fast[1] >= slow[1]);

   if(buySignal)  OpenOrder(ORDER_TYPE_BUY);
   if(sellSignal) OpenOrder(ORDER_TYPE_SELL);
}

//+------------------------------------------------------------------+
//| Проверка достаточности маржи                                     |
//+------------------------------------------------------------------+
bool CheckMargin(ENUM_ORDER_TYPE type, double volume, double price)
{
   double marginRequired = 0;
   if(!OrderCalcMargin(type, _Symbol, volume, price, marginRequired)) {
      Print("Ошибка расчёта маржи. Код: ", GetLastError());
      return false;
   }

   double freeMargin = AccountInfoDouble(ACCOUNT_MARGIN_FREE);

   if(marginRequired > freeMargin) {
      Print("Недостаточно средств. Нужно: ", marginRequired,
            ", Доступно: ", freeMargin);
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Открытие ордера                                                   |
//+------------------------------------------------------------------+
void OpenOrder(ENUM_ORDER_TYPE type)
{
   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   double volume = Lot;
   if(volume < minLot) volume = minLot;
   if(volume > maxLot) volume = maxLot;
   volume = MathFloor(volume / lotStep) * lotStep;

   if(volume < minLot) {
      Print("Ошибка: объем ", volume, " меньше минимального ", minLot);
      return;
   }

   MqlTradeRequest req = {};
   MqlTradeResult  res = {};

   double price = (type == ORDER_TYPE_BUY)
                  ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                  : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double sl = 0, tp = 0;
   if(StopLoss > 0)
      sl = (type == ORDER_TYPE_BUY) ? price - StopLoss * _Point : price + StopLoss * _Point;
   if(TakeProfit > 0)
      tp = (type == ORDER_TYPE_BUY) ? price + TakeProfit * _Point : price - TakeProfit * _Point;

   //--- Проверка маржи ПЕРЕД отправкой
   if(!CheckMargin(type, volume, price)) return;

   req.action    = TRADE_ACTION_DEAL;
   req.symbol    = _Symbol;
   req.volume    = volume;
   req.price     = price;
   req.sl        = sl;
   req.tp        = tp;
   req.deviation = 10;
   req.magic     = MagicNumber;
   req.type      = type;
   req.comment   = "MA Crossover";

   if(OrderSend(req, res)) {
      Print("Открыт ", (type == ORDER_TYPE_BUY ? "BUY" : "SELL"),
            ". Объем: ", volume, " Цена: ", price, " SL: ", sl, " TP: ", tp);
   } else {
      Print("Ошибка открытия. Код: ", res.retcode, " | ", res.comment);
   }
}

//+------------------------------------------------------------------+
//| Проверка наличия позиции                                          |
//+------------------------------------------------------------------+
bool PositionExists()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket)) {
         if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
            return true;
      }
   }
   return false;
}
//+------------------------------------------------------------------+
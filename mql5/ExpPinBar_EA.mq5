//+------------------------------------------------------------------+
//|                                                    ExpPinBar.mq5 |
//|                                  Copyright 2025, MetaQuotes Ltd. |
//|                                            https://forge.mql5.io |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, MetaQuotes Ltd."
#property link      "https://forge.mql5.io"
#property version   "1.00"

//+------------------------------------------------------------------+
//| Включаемые файлы                                                 |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Arrays\ArrayLong.mqh>
#include <Trailings\Trailings.mqh>

//+------------------------------------------------------------------+
//| Перечисления и структуры                                         |
//+------------------------------------------------------------------+
//--- Типы сигналов
enum ENUM_SIGNAL_TYPE
  {
   SIGNAL_TYPE_NONE,                                                 // Нет сигнала
   SIGNAL_TYPE_LONG,                                                 // Сигнал на покупку
   SIGNAL_TYPE_SHORT,                                                // Сигнал на покупку
  };

//--- Типы трейлингов
enum ENUM_TRAILING_TYPE
  {
   TRAILING_TYPE_NONE,                                               // None
   TRAILING_TYPE_SIMPLE,                                             // Simple
   TRAILING_TYPE_PSAR,                                               // By Parabolic SAR
   TRAILING_TYPE_AMA,                                                // By Adaptive Moving Average
   TRAILING_TYPE_DEMA,                                               // By Double Exponential Moving Average
   TRAILING_TYPE_FRAMA,                                              // By Fractal Adaptive Moving Average
   TRAILING_TYPE_MA,                                                 // By Moving Average
   TRAILING_TYPE_TEMA,                                               // By Triple Exponential Moving Average
   TRAILING_TYPE_VIDYA,                                              // By Variable Index Dynamic Average
   TRAILING_TYPE_VALUE,                                              // At the specified levels for long and short positions
  };

//--- Структура сделки
struct SDataDeal
  {
   ENUM_DEAL_TYPE    type;                                           // Тип
   datetime          time;                                           // Время
   double            price;                                          // Цена
   double            volume;                                         // Объём
  };

//--- Структура позиций
struct SData
  {
   CArrayLong  list_tickets;                                         // Список тикетов открытых позиций
   double      total_volume;                                         // Общий объём открытых позиций
  };

//--- Структура данных позиций по типам
struct SDataPositions
  {
   SData       Buy;                                                  // Данные позиций Buy
   SData       Sell;                                                 // Данные позиций Sell
  }
Data;

//+------------------------------------------------------------------+
//| Макроподстановки                                                 |
//+------------------------------------------------------------------+
#define  DATA_COUNT        3                                         // Количество получаемых данных от индикаторов (3 и более)
#define  ENV_ATTEMPTS      3                                         // Количество попыток ожидания получения окружения
#define  ENV_WAIT_ATTEMPT  1000                                      // Количество миллисекунд ожидания обновления окружения
#define  SPREAD_MLTP       2                                         // Множитель спреда для дистанции стоп-приказов

//+------------------------------------------------------------------+
//| Входные параметры                                                |
//+------------------------------------------------------------------+
//--- PinBar
input int                  InpMinCandleSizePT      = 10;                   /* Minimum size of a candle from low to high                */ // Минимальный размер свечи от минимума до максимума
input double               InpMaxCandleBodySize    = 0.33;                 /* Maximum size of the candle body relative to its shadows  */ // Максимальный размер тела свечи относительно ее теней
input double               InpRelativeToPrevCandle = 0.33;                 /* Position of the body relative to the previous candle     */ // Положение тела относительно предыдущей свечи
input double               InpAspectRatioShadows   = 2.0;                  /* Aspect ratio of the shadows                              */ // Соотношение размеров теней

//--- Торговля
input double               InpVolume               =  0.1;                 /* Position volume                                          */ // Объем позиции
sinput ulong               InpDeviation            =  10;                  /* Slippage (in points)                                     */ // Проскальзывание (в пунктах)
sinput ulong               InpMagic                =  1234567;             /* Magic number                                             */ // Магик
input int                  InpStopLoss             = -1;                   /* Stop loss (in points), 0 - none, -1 - by PinBar shadow   */ // Stop loss (в пунктах), 0 - отсутствует, -1 - по цене тени пин-бара
input uint                 InpTakeProfit           =  500;                 /* Take profit (in points), 0 - none                        */ // Take profit (в пунктах), 0 - отсутствует
input int                  InpSLDev                =  600;                 /* Stop loss deviation (in points)                          */ // Отступ Stop loss от тени пин-бара в пунктах

//--- Трейлинг
input ENUM_TRAILING_TYPE   InpTrailingType         =  TRAILING_TYPE_NONE;  /* Trailing type                                            */ // Тип трала
input int                  InpTrailingStart        =  150;                 /* Trailing start                                           */ // Прибыль в пунктах для старта трейлинга
input int                  InpTrailingStep         =  50;                  /* Trailing step in points                                  */ // Шаг трала в пунктах цены
input int                  InpTrailingOffset       =  50;                  /* Trailing offset in points                                */ // Отступ трала от цены в пунктах

input ENUM_TIMEFRAMES      InpIndTimeframe         =  PERIOD_CURRENT;      /* Indicator's timeframe                                    */ // Таймфрейм индикатора, используемого в расчёте трала
input int                  InpMAPeriod             =  0;                   /* MA Period                                                */ // Период расчёта скользящей средней
input int                  InpMAShift              =  0;                   /* MA Shift                                                 */ // Горизонтальный сдвиг скользящей средней
input int                  InpFastEMAPeriod        =  2;                   /* AMA Fast EMA Period                                      */ // Период расчёта быстрой EMA адаптивной скользящей средней
input int                  InpSlowEMAPeriod        =  30;                  /* AMA Slow EMA Period                                      */ // Период расчёта медленной EMA адаптивной скользящей средней
input int                  InpCMOPeriod            =  9;                   /* VIDYA CMO Period                                         */ // Период CMO скользящей средней с динамическим периодом усреднения
input double               InpSARStep              =  0.02;                /* Parabolic SAR Step                                       */ // Шаг Parabolic SAR
input double               InpSARMax               =  0.2;                 /* Parabolic SAR Max                                        */ // Максимум Parabolic SAR
input ENUM_APPLIED_PRICE   InpAppliedPrice         =  PRICE_CLOSE;         /* MA Applied Price                                         */ // Цена для расчёта скользящей средней
input ENUM_MA_METHOD       InpMAMethod             =  MODE_SMA;            /* MA Smoothing Method                                      */ // Тип сглаживания скользящей средней
input int                  InpDataIndex            =  1;                   /* Indicator data index                                     */ // Бар данных, получаемых от индикатора

//+------------------------------------------------------------------+
//| Глобальные переменные                                            |
//+------------------------------------------------------------------+
CTrade            trade;                                             // Объект торгового класса
int               handle_pb;                                         // Хэндл индикатора PinBars
double            pb0[DATA_COUNT]={};                                // Массив значений PinBars, буфер 0 (PinBar Lower)
double            pb1[DATA_COUNT]={};                                // Массив значений PinBars, буфер 1 (PinBar Upper)
double            pb2[DATA_COUNT]={};                                // Массив значений PinBars, буфер 2 (PinBar Buy signal)
double            pb3[DATA_COUNT]={};                                // Массив значений PinBars, буфер 3 (PinBar Sell signal)
MqlRates          prc[DATA_COUNT]={};                                // Массив цен и времени

int               min_candle_size;                                   // Минимальный размер свечи от минимума до максимума
double            max_candle_body_size;                              // Максимальный размер тела свечи относительно ее теней
double            relative_to_prev_candle;                           // Положение тела относительно предыдущей свечи
double            aspect_ratio_shadows;                              // Соотношение размеров теней
int               stop_loss_dev;                                     // Отступ Stop loss от тени пин-бара

double            lot;                                               // Объём позиции
string            program_name;                                      // Имя программы
int               prev_total_pos;                                    // Количество позиций на прошлой проверке
int               prev_total_deal;                                   // Количество сделок на прошлой проверке
SDataDeal         last_deal;                                         // Последняя сделка

CSimpleTrailing   trailing_simple;                                   // Объект простого трала
CTrailingBySAR    trailing_sar;                                      // Объект трала по Parabolic SAR
CTrailingByAMA    trailing_ama;                                      // Объект трала по Adaptive Moving Average
CTrailingByDEMA   trailing_dema;                                     // Объект трала по Double Exponential Moving Average
CTrailingByFRAMA  trailing_frama;                                    // Объект трала по Fractal Adaptive Moving Average
CTrailingByMA     trailing_ma;                                       // Объект трала по Moving Average
CTrailingByTEMA   trailing_tema;                                     // Объект трала по Triple Exponential Moving Average
CTrailingByVIDYA  trailing_vidya;                                    // Объект трала по Variable Index Dynamic Average
CTrailingByValue  trailing_value;                                    // Объект трала по указанным уровням для длинных и коротких позиций

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Если счёт не с типом хеджинг - сообщаем и уходим
   if(AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      Print("Sorry. The advisor is intended for hedging accounts only");
      return INIT_FAILED;
     }
   
//--- Устанавливаем и корректируем входные переменные индикатора
   min_candle_size = (InpMinCandleSizePT < 1 ? 1 : InpMinCandleSizePT);
   max_candle_body_size = (InpMaxCandleBodySize <= 0 ? 0.01 : InpMaxCandleBodySize > 1 ? 1.0 : InpMaxCandleBodySize);
   relative_to_prev_candle = (InpRelativeToPrevCandle < 0 ? 0 : InpRelativeToPrevCandle > 1 ? 1.0 : InpRelativeToPrevCandle);
   aspect_ratio_shadows = (InpAspectRatioShadows <= 0 ? 0.1 : InpAspectRatioShadows);
   stop_loss_dev=InpSLDev;
   
//--- Инициализируем массивы значений индикатора
   ArrayInitialize(pb0,EMPTY_VALUE);
   ArrayInitialize(pb1,EMPTY_VALUE);
   ArrayInitialize(pb2,EMPTY_VALUE);
   ArrayInitialize(pb3,EMPTY_VALUE);
   ZeroMemory(prc);
   ZeroMemory(last_deal);

//--- Создаём хэндл индикатора
//--- WPR
   handle_pb=iCustom(Symbol(),PERIOD_CURRENT,"PriceAction\\iPinBars",min_candle_size,max_candle_body_size,relative_to_prev_candle,aspect_ratio_shadows);
   if(handle_pb==INVALID_HANDLE)
     {
      PrintFormat("%s: Failed to create custom \"iPinBars\" indicator handle",__FUNCTION__);
      return INIT_FAILED;
     }

//--- Имя программы и количество позиций и сделок на прошлой проверке
   program_name=MQLInfoString(MQL_PROGRAM_NAME);
   prev_total_pos=0;
   prev_total_deal=0;
   
//--- Автоматическая установка типа заполнения
   trade.SetTypeFilling(GetTypeFilling());
//--- Установка магика
   trade.SetExpertMagicNumber(InpMagic);
//--- Установка проскальзывания
   trade.SetDeviationInPoints(InpDeviation);
//--- Установка лота с корректировкой введённого значения
   lot=CorrectLots(InpVolume);

//--- Инициализация тралов
   trailing_simple.SetActive(InpTrailingType==TRAILING_TYPE_SIMPLE);
   trailing_sar.SetActive(InpTrailingType==TRAILING_TYPE_PSAR);
   trailing_ama.SetActive(InpTrailingType==TRAILING_TYPE_AMA);
   trailing_dema.SetActive(InpTrailingType==TRAILING_TYPE_DEMA);
   trailing_frama.SetActive(InpTrailingType==TRAILING_TYPE_FRAMA);
   trailing_ma.SetActive(InpTrailingType==TRAILING_TYPE_MA);
   trailing_tema.SetActive(InpTrailingType==TRAILING_TYPE_TEMA);
   trailing_vidya.SetActive(InpTrailingType==TRAILING_TYPE_VIDYA);
   trailing_value.SetActive(InpTrailingType==TRAILING_TYPE_VALUE);
   
   if(trailing_simple.IsActive())
     {
      TrailingInit(&trailing_simple);
     }
   
   if(trailing_sar.IsActive())
     {
      TrailingInit(&trailing_sar);
      trailing_sar.Initialize(Symbol(),InpIndTimeframe,InpSARStep,InpSARMax);
     }
   
   if(trailing_ama.IsActive())
     {
      TrailingInit(&trailing_ama);
      trailing_ama.Initialize(Symbol(),InpIndTimeframe,InpMAPeriod,InpFastEMAPeriod,InpSlowEMAPeriod,InpMAShift,InpAppliedPrice);
     }
   
   if(trailing_dema.IsActive())
     {
      TrailingInit(&trailing_dema);
      trailing_dema.Initialize(Symbol(),InpIndTimeframe,InpMAPeriod,InpMAShift,InpAppliedPrice);
     }
   
   if(trailing_frama.IsActive())
     {
      TrailingInit(&trailing_frama);
     }
   
   if(trailing_ma.IsActive())
     {
      TrailingInit(&trailing_ma);
     }
   
   if(trailing_tema.IsActive())
     {
      TrailingInit(&trailing_tema);
     }
   
   if(trailing_vidya.IsActive())
     {
      TrailingInit(&trailing_vidya);
     }
   
   if(trailing_value.IsActive())
     {
      TrailingInit(&trailing_value);
     }
     
//--- Всё успешно
   PrintFormat("%s::%s: Initialization was successful",program_name,__FUNCTION__);
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- Получаем в массивы данные трёх баров индикаторов и цен
   if(!CopyIndicatorsData() || !CopyPricesData())
      return;
   
//--- Заполнение списков тикетов позиций
   int positions_total=PositionsTotal();
   if(prev_total_pos!=positions_total)
     {
      if(!FillingListTickets(Symbol(),InpMagic))
         return;
      prev_total_pos=positions_total;
     }
   
//--- Общий сигнал
   ENUM_SIGNAL_TYPE signal=SignalPinBars();
   
//--- Торгуем по сигналам
   TradeProcess(signal);
   
//--- Для трейлинга по значениям будем тралить по теням свечей
   double l1=PriceLow(1);              // Low  свечи с индексом 1
   double l2=PriceLow(2);              // Low  свечи с индексом 2
   double h1=PriceHigh(1);             // High свечи с индексом 1
   double h2=PriceHigh(2);             // High свечи с индексом 2
   double sl_value_long =fmin(l1,l2);  // мин.  значение Low  1 и 2 свечей
   double sl_value_short=fmax(h1,h2);  // макс. значение High 1 и 2 свечей
//--- Трейлинг
   Trailing(InpTrailingType,sl_value_long,sl_value_short);;
  }
//+------------------------------------------------------------------+ 
//| Expert TradeTransaction handler                                  | 
//+------------------------------------------------------------------+ 
void OnTradeTransaction(const MqlTradeTransaction& trans, 
                        const MqlTradeRequest& request, 
                        const MqlTradeResult& result) 
  { 
   //--- если транзакция - добавление сделки в историю 
   if(trans.type==TRADE_TRANSACTION_DEAL_ADD) 
     { 
      //--- выбираем сделку по тикету, и сохраняем её свойства
      DealSave(trans.deal); 
     } 
  }  
//+------------------------------------------------------------------+
//| Получает значения Open для трёх баров                            |
//+------------------------------------------------------------------+
bool CopyPricesData(void)
  {
   ResetLastError();
   if(CopyRates(Symbol(),PERIOD_CURRENT,0,DATA_COUNT,prc)!=DATA_COUNT)
     {
      PrintFormat("%s: Failed to get price Open data. Error %d",__FUNCTION__,GetLastError());
      return false;
     }
   return true;
  }
//+------------------------------------------------------------------+
//| Получает значения PinBars для трёх баров                         |
//+------------------------------------------------------------------+
bool CopyPinBarsData(void)
  {
   ResetLastError();
   if(CopyBuffer(handle_pb,0,0,DATA_COUNT,pb0)!=DATA_COUNT)
     {
      PrintFormat("%s: Failed to get PinBar Lower data. Error %d",__FUNCTION__,GetLastError());
      return false;
     }
   if(CopyBuffer(handle_pb,1,0,DATA_COUNT,pb1)!=DATA_COUNT)
     {
      PrintFormat("%s: Failed to get PinBar Upper data. Error %d",__FUNCTION__,GetLastError());
      return false;
     }
   if(CopyBuffer(handle_pb,2,0,DATA_COUNT,pb2)!=DATA_COUNT)
     {
      PrintFormat("%s: Failed to get PinBar Buy signal data. Error %d",__FUNCTION__,GetLastError());
      return false;
     }
   if(CopyBuffer(handle_pb,3,0,DATA_COUNT,pb3)!=DATA_COUNT)
     {
      PrintFormat("%s: Failed to get PinBar Sell signal data. Error %d",__FUNCTION__,GetLastError());
      return false;
     }
   return true;
  }
//+------------------------------------------------------------------+
//| Получает значения индикаторов для трёх баров                     |
//+------------------------------------------------------------------+
bool CopyIndicatorsData(void)
  {
   return CopyPinBarsData();
  }
//+------------------------------------------------------------------+
//| Возвращает из массива цену Open по индексу таймсерии (0 - 2)     |
//+------------------------------------------------------------------+
double PriceOpen(const int index)
  {
   return(index<0 || index>DATA_COUNT-1 ? 0 : prc[DATA_COUNT-index-1].open);
  }
//+------------------------------------------------------------------+
//|Возвращает из массива цену High по индексу таймсерии (0 - 2)|
//+------------------------------------------------------------------+
double PriceHigh(const int index)
  {
   return(index<0 || index>DATA_COUNT-1 ? 0 : prc[DATA_COUNT-index-1].high);
  }
//+------------------------------------------------------------------+
//| Возвращает из массива цену Low по индексу таймсерии (0 - 2)      |
//+------------------------------------------------------------------+
double PriceLow(const int index)
  {
   return(index<0 || index>DATA_COUNT-1 ? 0 : prc[DATA_COUNT-index-1].low);
  }
//+------------------------------------------------------------------+
//| Возвращает из массива цену Close по индексу таймсерии (0 - 2)    |
//+------------------------------------------------------------------+
double PriceClose(const int index)
  {
   return(index<0 || index>DATA_COUNT-1 ? 0 : prc[DATA_COUNT-index-1].close);
  }
//+------------------------------------------------------------------+
//| Возвращает из массива время бара по индексу таймсерии (0 - 2)    |
//+------------------------------------------------------------------+
datetime Time(const int index)
  {
   return(index<0 || index>DATA_COUNT-1 ? 0 : prc[DATA_COUNT-index-1].time);
  }
//+------------------------------------------------------------------+
//|Возвращает из массива данные PB Lower по индексу таймсерии (0 - 2)|
//+------------------------------------------------------------------+
double PinBarLower(const int index)
  {
   return(index<0 || index>DATA_COUNT-1 ? EMPTY_VALUE : pb0[DATA_COUNT-index-1]);
  }
//+------------------------------------------------------------------+
//|Возвращает из массива данные PB Upper по индексу таймсерии (0 - 2)|
//+------------------------------------------------------------------+
double PinBarUpper(const int index)
  {
   return(index<0 || index>DATA_COUNT-1 ? EMPTY_VALUE : pb1[DATA_COUNT-index-1]);
  }
//+------------------------------------------------------------------+
//| Возвращает из массива данные PB Buy по индексу таймсерии (0 - 2) |
//+------------------------------------------------------------------+
double PinBarBuy(const int index)
  {
   return(index<0 || index>DATA_COUNT-1 ? EMPTY_VALUE : pb2[DATA_COUNT-index-1]);
  }
//+------------------------------------------------------------------+
//| Возвращает из массива данные PB Sell по индексу таймсерии (0 - 2)|
//+------------------------------------------------------------------+
double PinBarSell(const int index)
  {
   return(index<0 || index>DATA_COUNT-1 ? EMPTY_VALUE : pb3[DATA_COUNT-index-1]);
  }
//+------------------------------------------------------------------+
//| Сигнал PinBars                                                   |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE SignalPinBars(void)
  {
//--- Сигнал на покупку
   if(PinBarBuy(0)!=EMPTY_VALUE)
      return SIGNAL_TYPE_LONG;
//--- Сигнал на продажу
   if(PinBarSell(0)!=EMPTY_VALUE)
      return SIGNAL_TYPE_SHORT;
//--- Нет сигнала
   return SIGNAL_TYPE_NONE;
  }
//+------------------------------------------------------------------+
//| Возвращает тип исполнения ордера, равный type,                   |
//| если он доступен на символе, иначе - корректный вариант          |
//| https://www.mql5.com/ru/forum/170952/page4#comment_4128864       |
//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetTypeFilling(const ENUM_ORDER_TYPE_FILLING type=ORDER_FILLING_RETURN)
  {
   const ENUM_SYMBOL_TRADE_EXECUTION exe_mode=(ENUM_SYMBOL_TRADE_EXECUTION)::SymbolInfoInteger(Symbol(),SYMBOL_TRADE_EXEMODE);
   const int filling_mode=(int)::SymbolInfoInteger(Symbol(),SYMBOL_FILLING_MODE);

   return((filling_mode==0 || (type>=ORDER_FILLING_RETURN) || ((filling_mode &(type+1))!=type+1)) ?
          (((exe_mode==SYMBOL_TRADE_EXECUTION_EXCHANGE) || (exe_mode==SYMBOL_TRADE_EXECUTION_INSTANT)) ?
          ORDER_FILLING_RETURN :((filling_mode==SYMBOL_FILLING_IOC) ? ORDER_FILLING_IOC : ORDER_FILLING_FOK)) : type);
  }
//+------------------------------------------------------------------+
//| Возвращает корректный лот                                        |
//+------------------------------------------------------------------+
double CorrectLots(const double lots,const bool to_min_correct=true)
  {
   double min=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   double max=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   double step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);
   return(to_min_correct ? VolumeRoundToSmaller(lots,min,max,step) : VolumeRoundToCorrect(lots,min,max,step));
  }
//+------------------------------------------------------------------+
//| Возвращает ближайший корректный лот                              |
//+------------------------------------------------------------------+
double VolumeRoundToCorrect(const double volume,const double min,const double max,const double step)
  {
   return(step==0 ? min : fmin(fmax(round(volume/step)*step,min),max));
  }
//+------------------------------------------------------------------+
//| Возвращает ближайший в меньшую сторону корректный лот            |
//+------------------------------------------------------------------+
double VolumeRoundToSmaller(const double volume,const double min,const double max,const double step)
  {
   return(step==0 ? min : fmin(fmax(floor(volume/step)*step,min),max));
  }
//+------------------------------------------------------------------+
//| Возвращает флаг не превышения общего объёма на счёте             |
//+------------------------------------------------------------------+
bool CheckLotForLimitAccount(const ENUM_POSITION_TYPE position_type,const double volume)
  {
   double lots_limit=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_LIMIT);
   if(lots_limit==0)
      return true;
   double total_volume=(position_type==POSITION_TYPE_BUY ? Data.Buy.total_volume : Data.Sell.total_volume);
   return(total_volume+volume<=lots_limit);
  }
//+------------------------------------------------------------------+
//| Возвращает корректный StopLoss относительно StopLevel            |
//+------------------------------------------------------------------+
double CorrectStopLoss(const ENUM_POSITION_TYPE position_type,const int stop_loss)
  {
   if(stop_loss==0)
      return 0;
   double pt=Point();
   if(pt==0)
      return 0;
   double price=(position_type==POSITION_TYPE_BUY ? SymbolInfoDouble(Symbol(),SYMBOL_ASK) : SymbolInfoDouble(Symbol(),SYMBOL_BID));
   int lv=StopLevel(), dg=Digits();
   return(position_type==POSITION_TYPE_BUY   ?  NormalizeDouble(fmin(price-lv*pt,price-stop_loss*pt),dg) :
                                                NormalizeDouble(fmax(price+lv*pt,price+stop_loss*pt),dg));
  }
//+------------------------------------------------------------------+
//| Возвращает корректный StopLoss относительно StopLevel            |
//+------------------------------------------------------------------+
double CorrectStopLoss(const ENUM_POSITION_TYPE position_type,const double stop_loss)
  {
   if(stop_loss==0) return 0;
   double pt=Point();
   if(pt==0)
      return 0;
   double price=(position_type==POSITION_TYPE_BUY ? SymbolInfoDouble(Symbol(),SYMBOL_BID) : SymbolInfoDouble(Symbol(),SYMBOL_ASK));
   int lv=StopLevel(), dg=Digits();
   return(position_type==POSITION_TYPE_BUY   ?  NormalizeDouble(::fmin(price-lv*pt,stop_loss),dg) :
                                                NormalizeDouble(::fmax(price+lv*pt,stop_loss),dg));
}
//+------------------------------------------------------------------+
//| Возвращает корректный TakeProfit относительно StopLevel          |
//+------------------------------------------------------------------+
double CorrectTakeProfit(const ENUM_POSITION_TYPE position_type,const int take_profit)
  {
   if(take_profit==0)
      return 0;
   double pt=Point();
   if(pt==0)
      return 0;
   double price=(position_type==POSITION_TYPE_BUY ? SymbolInfoDouble(Symbol(),SYMBOL_ASK) : SymbolInfoDouble(Symbol(),SYMBOL_BID));
   int lv=StopLevel(), dg=Digits();
   return(position_type==POSITION_TYPE_BUY   ?  NormalizeDouble(fmax(price+lv*pt,price+take_profit*pt),dg) :
                                                NormalizeDouble(fmin(price-lv*pt,price-take_profit*pt),dg));
  }
//+------------------------------------------------------------------+
//| Возвращает рассчитанный StopLevel                                |
//+------------------------------------------------------------------+
int StopLevel(void)
  {
   int sp=(int)SymbolInfoInteger(Symbol(),SYMBOL_SPREAD);
   int lv=(int)SymbolInfoInteger(Symbol(),SYMBOL_TRADE_STOPS_LEVEL);
   return(lv==0 ? sp*SPREAD_MLTP : lv);
  }
//+------------------------------------------------------------------+
//| Возвращает "неопределённое" состояние торгового окружения        |
//+------------------------------------------------------------------+
bool IsUncertainStateEnv(const string symbol_name,const ulong magic_number)
  {
//--- В тестере сосотояние окружения всегда корректно
   if(MQLInfoInteger(MQL_TESTER))
      return false;
//--- В цикле по количеству ордеров
   int total=OrdersTotal();
   for(int i=total-1; i>=0; i--)
     {
      //--- выбираем ордер для получения его свойств
      if(OrderGetTicket(i)==0)
         continue;
      //--- если магик ордера не соответствует искомому - пропускаем
      if(OrderGetInteger(ORDER_MAGIC)!=magic_number)
         continue;
      //--- если тип ордера не Buy и не Sell - пропускаем
      ENUM_ORDER_TYPE type=(ENUM_ORDER_TYPE)OrderGetInteger(ORDER_TYPE);
      if(type!=ORDER_TYPE_BUY && type!=ORDER_TYPE_SELL)
         continue;
      //--- если символ ордера соответствует искомому, но в ордере нет записи об идентификаторе позиции,
      //--- значит данные об открывающейся позиции ещё не добавлены в историю ордеров.
      //--- Это неопределённое состояние окружения - возвращаем true
      if(!OrderGetInteger(ORDER_POSITION_ID) && OrderGetString(ORDER_SYMBOL)==symbol_name)
         return true;
     }
//--- Окружение в порядке
   return false;
  }
//+------------------------------------------------------------------+
//| Проверка состояния окружения                                     |
//+------------------------------------------------------------------+
bool CheckUncertainStateEnv(const string symbol_name,const ulong magic_number,const int attempts,const int wait)
  {
//--- Если окружение в порядке - возвращаем true
   if(IsUncertainStateEnv(symbol_name,magic_number))
      return true;
//--- Делаем цикле ENV_ATTEMPTS попыток получения корректного окружения с ожиданием ENV_WAIT_ATTEMPT между попытками
   int n=0;
   while(!IsStopped() && n<attempts && IsUncertainStateEnv(symbol_name,magic_number))
     {
      n++;
      Sleep(wait);
     }
//--- Если по завершении ожидания окружение всё ещё неопределённое - сообщаем об этом и возвращаем false
   if(n>=attempts && IsUncertainStateEnv(symbol_name,magic_number))
     {
      PrintFormat("%s: Uncertain state of the environment. Please try again.",__FUNCTION__);
      return false;
     }
//--- Окружение корректно
   return true;
  }
//+------------------------------------------------------------------+
//| Заполняет массивы тикетов позиций                                |
//+------------------------------------------------------------------+
bool FillingListTickets(const string symbol_name,const ulong magic_number)
  {
//--- Если торговое окружение не корректно - возвращаем false
   if(!CheckUncertainStateEnv(symbol_name,magic_number,ENV_ATTEMPTS,ENV_WAIT_ATTEMPT))
      return false;

//--- Очищаем списки и инициализируем переменные
   Data.Buy.list_tickets.Clear();
   Data.Sell.list_tickets.Clear();
   Data.Buy.total_volume=0;
   Data.Sell.total_volume=0;
   
//--- В цикле по открытым позициям
   int total=PositionsTotal();
   for(int i=total-1; i>WRONG_VALUE; i--)
     {
      //--- выбираем позицию для получения свойств
      ulong ticket=PositionGetTicket(i);
      if(ticket==0)
         continue;
      //--- Если магик или символ не соответствуют переданным в функцию - идём дальше
      if(PositionGetInteger(POSITION_MAGIC)!=InpMagic || PositionGetString(POSITION_SYMBOL)!=symbol_name)
         continue;
      //--- Получаем тип и объём позиции
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      double volume=PositionGetDouble(POSITION_VOLUME);
      //--- В зависимости от типа позиции добавляем тикет и объём в соответствующие списки
      if(type==POSITION_TYPE_BUY)
        {
         Data.Buy.list_tickets.Add(ticket);
         Data.Buy.total_volume+=volume;
        }
      //--- POSITION_TYPE_SELL
      else
        {
         Data.Sell.list_tickets.Add(ticket);
         Data.Sell.total_volume+=volume;
        }
     }
//--- Всё успешно
   return true;
  }
//+------------------------------------------------------------------+ 
//| Выбирает сделку по тикету и сохраняет её свойства                | 
//+------------------------------------------------------------------+ 
void DealSave(const ulong deal_ticket) 
  { 
//--- выбираем историческую сделку по тикету, указанному в deal_ticket 
   ResetLastError(); 
   if(!HistoryDealSelect(deal_ticket)) 
     { 
      PrintFormat("HistoryDealSelect(%I64u) failed. Error %d", deal_ticket, GetLastError()); 
      return; 
     } 
  
//--- если сделка успешно выбрана, получаем и сохраняем её данные
   ENUM_DEAL_TYPE    deal_type  = (ENUM_DEAL_TYPE)HistoryDealGetInteger(deal_ticket, DEAL_TYPE); 
   ENUM_DEAL_ENTRY   deal_entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY); 
   ulong             deal_magic = HistoryDealGetInteger(deal_ticket, DEAL_MAGIC); 

//--- Если магик не наш, или тип сделки не торговый, или это не сделка выхода из рынка - уходим
   if(deal_magic!=InpMagic || (deal_type!=DEAL_TYPE_BUY && deal_type!=DEAL_TYPE_SELL) || (deal_entry!=DEAL_ENTRY_OUT && deal_entry!=DEAL_ENTRY_OUT_BY))
      return;

//--- Если символ не наш - уходим
   if(HistoryDealGetString(deal_ticket, DEAL_SYMBOL)!=Symbol())
      return;
   
//--- Сохраняем данные сделки
   last_deal.type  = deal_type;
   last_deal.price = HistoryDealGetDouble(deal_ticket, DEAL_PRICE);
   last_deal.volume= HistoryDealGetDouble(deal_ticket, DEAL_VOLUME);
   last_deal.time  = (datetime)HistoryDealGetInteger(deal_ticket,DEAL_TIME);
  }
//+------------------------------------------------------------------+
//| Возвращает номер бара, на котором была закрыта последняя позиция |
//+------------------------------------------------------------------+
int PositionLastCloseBar(void)
  {
//--- Возвращаем номер бара по времени последней сделки
   return iBarShift(Symbol(),PERIOD_CURRENT,last_deal.time);
  }
//+------------------------------------------------------------------+
//| Возвращает тип последней закрытой позиции                        |
//+------------------------------------------------------------------+
ENUM_POSITION_TYPE PositionLastCloseType(void)
  {
   return(last_deal.time!=0 ? (last_deal.type==DEAL_TYPE_BUY ? POSITION_TYPE_SELL : POSITION_TYPE_BUY) : (ENUM_POSITION_TYPE)WRONG_VALUE);
  }
//+------------------------------------------------------------------+
//| Возвращает цену последней закрытой позиции                       |
//+------------------------------------------------------------------+
double PositionLastClosePrice(void)
  {
   return last_deal.price;
  }
//+------------------------------------------------------------------+
//| Возвращает объём последней закрытой позиции                      |
//+------------------------------------------------------------------+
double PositionLastCloseVolume(void)
  {
   return last_deal.volume;
  }
//+------------------------------------------------------------------+
//| Возвращает количество позиций Buy                                |
//+------------------------------------------------------------------+
int TotalBuy(void)
  {
   return Data.Buy.list_tickets.Total();
  }
//+------------------------------------------------------------------+
//| Возвращает количество позиций Sell                               |
//+------------------------------------------------------------------+
int TotalSell(void)
  {
   return Data.Sell.list_tickets.Total();
  }
//+------------------------------------------------------------------+
//| Возвращает последний добавленный тикет позиции по типу           |
//+------------------------------------------------------------------+
ulong LastAddedTicket(const ENUM_POSITION_TYPE type)
  {
   return(type==POSITION_TYPE_BUY ? (TotalBuy()>0 ? Data.Buy.list_tickets.At(0) : 0) : (TotalSell()>0 ? Data.Sell.list_tickets.At(0) : 0));
  }
//+------------------------------------------------------------------+
//| Возвращает номер бара, на котором была открыта позиция           |
//+------------------------------------------------------------------+
int PositionOpenBar(const ulong ticket)
  {
//--- Выбираем позицию по тикету
   ResetLastError();
   if(!PositionSelectByTicket(ticket))
     {
      PrintFormat("%s: Failed to select position by ticket #%I64u. Error %d",__FUNCTION__,GetLastError());
      return -1;
     }
//--- Получаем время открытия и символ позиции
   datetime time=(datetime)PositionGetInteger(POSITION_TIME);
   string   symbol=PositionGetString(POSITION_SYMBOL);
   
//--- Возвращаем номер бара по времени открытия позиции
   return iBarShift(symbol,PERIOD_CURRENT,time);
  }
//+------------------------------------------------------------------+
//| Возвращает наличие указанной позиции, открытой на текущем баре   |
//+------------------------------------------------------------------+
bool IsPresentPosOnCurrentBar(const ENUM_POSITION_TYPE type)
  {
   ulong ticket=LastAddedTicket(type);
   return(ticket>0 ? PositionOpenBar(ticket)==0 : false);
  }
//+------------------------------------------------------------------+
//| Возвращает цену открытия позиции по тикету                       |
//+------------------------------------------------------------------+
double PositionPriceOpen(const ulong ticket)
  {
//--- Проверяем тикет
   if(ticket==0)
      return 0;
//--- Выбираем позицию по тикету
   ResetLastError();
   if(!PositionSelectByTicket(ticket))
     {
      PrintFormat("%s: Failed to select position by ticket #%I64u. Error %d",__FUNCTION__,GetLastError());
      return 0;
     }
//--- Возвращаем цену открытия позиции
   return PositionGetDouble(POSITION_PRICE_OPEN);
  }
//+------------------------------------------------------------------+
//| Закрывает позиции Buy                                            |
//+------------------------------------------------------------------+
bool CloseBuy(void)
  {
   int total=TotalBuy();
   bool res=true;
   for(int i=total-1; i>=0; i--)
     {
      ulong ticket=Data.Buy.list_tickets.At(i);
      if(ticket==NULL)
         continue;
      if(!trade.PositionClose(ticket,InpDeviation))
         res=false;
     }
   return res;
  }
//+------------------------------------------------------------------+
//| Закрывает позиции Sell                                           |
//+------------------------------------------------------------------+
bool CloseSell(void)
  {
   int total=TotalSell();
   bool res=true;
   for(int i=total-1; i>=0; i--)
     {
      ulong ticket=Data.Sell.list_tickets.At(i);
      if(ticket==NULL)
         continue;
      if(!trade.PositionClose(ticket,InpDeviation))
         res=false;
     }
   return res;
  }
//+------------------------------------------------------------------+
//| Открытие позиции                                                 |
//+------------------------------------------------------------------+
bool OpenPosition(const string symbol_name,const ENUM_POSITION_TYPE type,const double volume,const string comment)
  {
//--- Рассчитываем значения для стоп-приказов
   double pbextr=(type==POSITION_TYPE_BUY ? PinBarLower(1)-stop_loss_dev*Point() : PinBarUpper(1)+stop_loss_dev*Point());
   if(pbextr==EMPTY_VALUE)
     {
      PrintFormat("%s: Error. Failed to get pin bar shadow price",__FUNCTION__);
      return false;
     }
   double sl=(InpStopLoss==0   ? 0 : InpStopLoss<0 ? CorrectStopLoss(type,pbextr) : CorrectStopLoss(type,InpStopLoss));
   double tp=(InpTakeProfit==0 ? 0 : CorrectTakeProfit(type,InpTakeProfit));
   
//--- Получаем цены
   MqlTick tick={};
   if(!SymbolInfoTick(symbol_name,tick))
     {
      PrintFormat("%s: Unable to get prices");
      return false;
     }
//--- Проверяем и получаем нормализованный лот открываемой позиции
   double ll=trade.CheckVolume(symbol_name,volume,(type==POSITION_TYPE_BUY ? tick.ask : tick.bid),(ENUM_ORDER_TYPE)type);
   if(ll==0)
     {
      PrintFormat("%s: Error. CheckVolume() returned a zero lot",__FUNCTION__);
      return false;
     }
     
//--- Проверяем ограничение на максимальный объём открытых позиций на счёте
   if(!CheckLotForLimitAccount(type,ll))
     {
      PrintFormat("%s: CheckLotForLimitAccount() returned an error",__FUNCTION__);
      return false;
     }

//--- Может быть ситуация, когда торговый приказ уже был отправлен, но он ещё не полностью обработан,
//--- что может привести к задвоению открываемой позиции.
//--- Если торговое окружение не корректно - возвращаем false
   if(!CheckUncertainStateEnv(symbol_name,InpMagic,ENV_ATTEMPTS,ENV_WAIT_ATTEMPT))
      return false;

//--- Ожидание получения корректного торгового окружения может занять некоторое время
//--- Ещё раз получим цены
   if(!SymbolInfoTick(symbol_name,tick))
     {
      PrintFormat("%s: Unable to get prices");
      return false;
     }

//--- Возвращаем результат отправки торгового запроса на сервер
   return(type==POSITION_TYPE_BUY ? trade.Buy(ll,symbol_name,tick.ask,sl,tp,comment) : trade.Sell(ll,symbol_name,tick.bid,sl,tp,comment));
  }
//+------------------------------------------------------------------+
//| Процесс торговли                                                 |
//+------------------------------------------------------------------+
void TradeProcess(const ENUM_SIGNAL_TYPE signal)
  {
//--- Нет сигнала - уходим
   if(signal==SIGNAL_TYPE_NONE)
      return;
   
//--- Сигнал на покупку
   if(signal==SIGNAL_TYPE_LONG)
     {
      //--- Если нет открытой позиции Buy на этом баре
      if(!IsPresentPosOnCurrentBar(POSITION_TYPE_BUY))
        {
         //--- Если последняя позиция была закрыта не на текущем баре, либо это закрыта не Buy-позиция -
         //--- отсылаем запрос на открытие позиции Buy
         if(PositionLastCloseBar()!=0 || (PositionLastCloseBar()==0 && PositionLastCloseType()!=POSITION_TYPE_BUY))
           {
            //--- Если позиция открыта - обновляем списки тикетов открытых позиций
            if(OpenPosition(Symbol(),POSITION_TYPE_BUY,lot,""))
               FillingListTickets(Symbol(),InpMagic);
           }
        }
     }
   
//--- Сигнал на продажу
   if(signal==SIGNAL_TYPE_SHORT)
     {
      //--- Если нет открытой позиции Sell на этом баре
      if(!IsPresentPosOnCurrentBar(POSITION_TYPE_SELL))
        {
         //--- Если последняя позиция была закрыта не на текущем баре, либо это закрыта не Sell-позиция -
         //--- отсылаем запрос на открытие позиции Sell
         if(PositionLastCloseBar()!=0 || (PositionLastCloseBar()==0 && PositionLastCloseType()!=POSITION_TYPE_SELL))
           {
            //--- Если позиция открыта - обновляем списки тикетов открытых позиций
            if(OpenPosition(Symbol(),POSITION_TYPE_SELL,lot,""))
               FillingListTickets(Symbol(),InpMagic);
           }
        }
     }
  }
//+------------------------------------------------------------------+
//| Инициализация параметров трала                                   |
//+------------------------------------------------------------------+
void TrailingInit(CSimpleTrailing *trailing_obj)
  {
//--- Устанавливаем параметры трала
   trailing_obj.SetSymbol(Symbol());
   trailing_obj.SetMagicNumber(InpMagic);
   trailing_obj.SetSpreadMultiplier(SPREAD_MLTP);
   trailing_obj.SetStopLossOffset(InpTrailingOffset);
   trailing_obj.SetTrailingStart(InpTrailingStart);
   trailing_obj.SetTrailingStep(InpTrailingStep);
   
//--- Устанавливаем параметры Parabolic SAR
   if(trailing_obj.Type()==TRAILING_PSAR)
      trailing_sar.Initialize(Symbol(),InpIndTimeframe,InpSARStep,InpSARMax);
      
//--- Устанавливаем параметры Adaptive Moving Average
   if(trailing_obj.Type()==TRAILING_AMA)
      trailing_ama.Initialize(Symbol(),InpIndTimeframe,InpMAPeriod,InpFastEMAPeriod,InpSlowEMAPeriod,InpMAShift,InpAppliedPrice);
      
//--- Устанавливаем параметры Double Exponential Moving Average
   if(trailing_obj.Type()==TRAILING_DEMA)
      trailing_dema.Initialize(Symbol(),InpIndTimeframe,InpMAPeriod,InpMAShift,InpAppliedPrice);
      
//--- Устанавливаем параметры Fractal Adaptive Moving Average
   if(trailing_obj.Type()==TRAILING_FRAMA)
      trailing_frama.Initialize(Symbol(),InpIndTimeframe,InpMAPeriod,InpMAShift,InpAppliedPrice);
      
//--- Устанавливаем параметры Moving Average
   if(trailing_obj.Type()==TRAILING_MA)
      trailing_ma.Initialize(Symbol(),InpIndTimeframe,InpMAPeriod,InpMAShift,InpMAMethod,InpAppliedPrice);
      
//--- Устанавливаем параметры Triple Exponential Moving Average
   if(trailing_obj.Type()==TRAILING_TEMA)
      trailing_tema.Initialize(Symbol(),InpIndTimeframe,InpMAPeriod,InpMAShift,InpAppliedPrice);
      
//--- Устанавливаем параметры Variable Index Dynamic Average
   if(trailing_obj.Type()==TRAILING_VIDYA)
      trailing_vidya.Initialize(Symbol(),InpIndTimeframe,InpCMOPeriod,InpMAPeriod,InpMAShift,InpAppliedPrice);
  }
//+------------------------------------------------------------------+
//| Трейлинг                                                         |
//+------------------------------------------------------------------+
void Trailing(const ENUM_TRAILING_TYPE trail_type,const double sl_value_long,const double sl_value_short)
  {
   switch(trail_type)
     {
      case TRAILING_TYPE_AMA     : trailing_ama.Run();                                 break;
      case TRAILING_TYPE_DEMA    : trailing_dema.Run();                                break;
      case TRAILING_TYPE_FRAMA   : trailing_frama.Run();                               break;
      case TRAILING_TYPE_MA      : trailing_ma.Run();                                  break;
      case TRAILING_TYPE_PSAR    : trailing_sar.Run();                                 break;
      case TRAILING_TYPE_SIMPLE  : trailing_simple.Run();                              break;
      case TRAILING_TYPE_TEMA    : trailing_tema.Run();                                break;
      case TRAILING_TYPE_VIDYA   : trailing_vidya.Run();                               break;
      case TRAILING_TYPE_VALUE   : trailing_value.Run(sl_value_long,sl_value_short);   break;
      default: break;
     }
  }
//+------------------------------------------------------------------+

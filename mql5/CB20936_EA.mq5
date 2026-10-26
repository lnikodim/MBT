//+------------------------------------------------------------------+
//|                         Interceptor(barabashkakvn's edition).mq5 |
//|                                                           Sergey |
//|                                                mserega@yandex.ru |
//+------------------------------------------------------------------+
#property copyright "Sergey"
#property link      "mserega@yandex.ru"
#property version   "1.001"
//---
#define MODE_LOW 1
#define MODE_HIGH 2
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Trade\DealInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Expert\Money\MoneyFixedMargin.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
CDealInfo      m_deal;                       // deals object
COrderInfo     m_order;                      // pending orders object
CMoneyFixedMargin *m_money;
//--- input parameters
input double   OrdinaryLot                   = 0.01;  // лот при обычном открытии позиции (если нет совпадения сигналов)
input double   CoefFlatnessM5                = 0.35;  // коэффициент флета на М5 (количество пунктов на 1 бар)
input int      StopLoss                      = 500;   // начальный стоп лосс  (если меньше 100, то стоп лосс не ставится)
input int      TakeProfit                    = 0;     // тейк профит (если меньше 100, то тейк профит не ставится)
input int      TakeProfitAfterBreakeven      = 0;     // минимальная прибыль в пунктах после перевода в безубыток
input int      StopLossAfterBreakeven        = 450;   // стоп-лосс после перевода в безубыток (переводим в б/у, если параметр больше 9)
input int      MaxFanDistanceM5              = 250;   // максимально допустимое расстояние между МА для веера на графике  М5 (только в сигнал 1)
input int      MaxFanDistanceM15             = 200;   // максимально допустимое расстояние между МА для веера на графике М15 (только в сигнал 4)
input int      MaxFanDistanceH1              = 600;   // максимально допустимое расстояние между МА для веера на графике М15 (только в сигнал 6)
input int      StochasticKperiodM5           = 24;    // период стохастика (для М5)
input int      StochasticUpM5                = 85;    // верхний уровень стохастика (для М5)
input int      StochasticDownM5              = 15;    // нижний уровень стохастика (для М5)
input int      StochasticKperiodM15          = 24;    // период стохастика (для М15)
input int      StochasticUpM15               = 85;    // верхний уровень стохастика (для М15)
input int      StochasticDownM15             = 15;    // нижний уровень стохастика (для М15)
input int      MinBody                       = 150;   // минимальный размер тела свечи (только в сигнал 1)
input int      MinFlatInBars                 = 10;    // маленький флет (минимальная длина флета в барах)
input int      MaxFlatInPoints               = 150;   // высокий флет (максимальная высота флета в пунктах)
input int      MinDivergencesInBarsM5        = 75;    // минимальное расстояние в барах между пиками индикатора для дивергенции на М5
input int      HammerMinPercentageLongShadow = 80;    // минимальный  процент длинной  тени молота
input int      HammerMaxPercentageShortShadow= 10;    // максимальный процент короткой тени молота
input int      HammerMinSizeInPoints         = 11;    // минимальный  размер  молота в пунктах (на графике М5)
input int      HammerBarHowLongAgo           = 8;     // как давно был молот (максимальный номер его бара)
input int      HammerPeriodOnBars            = 15;    // на скольких барах молот является максимумом (только в сигнал 6)
input int      MaxFanWidthAtNarrowestM5      = 30;    // узкий источник (максимальная ширина веера на М5 в самой узкой точке)
input int      FanConvergedToPointIinBars    = 5;     // сколько баров назад веер сходился в "узкий источник" (практически в точку)
input int      RangeMaxOrMinBreaksThrough    = 10;    // диапазон максимума или минимума, который пробивается ("узкий источник" в барах)
input ulong    m_magic                       = 1214;  // пометка своих позиций таким номером
input int      StepTral                      = 500;   // минимальный сдвиг трейлинг-стопа
input int      DistTral                      = 3000;  // расстояние от трейлинг-стопа до цены (если меньше 100, то трал не работает)
//--- лоты открытых позиций
double lot_buy,lot_sel;
//--- вееры скользящих средних, коэффициэнт лота (если совпали несколько сигналов сразу, то открываем двойной лот)
int veer_m5,veer_15,veer_h1,lt_koef;
//--- пересечение стохастика и сигнальной линии на графике М5, на графике М15, бар для цикла
int stoch_crosM5,stoh_per15;
//--- пробой скользящих средних M5 и M15, пробой флета на М5, горн (улучшенная версия веера МА)
int prob_m5,prob_15,prb_flt,hrn_bull,hrn_bear,prb_yz;
//--- дивергенция на стохастике М5, бар где есть молот, значение молота
int div_buy,div_sel,mltbr,molot;
//--- сигналы управления ордерами
int zakr_buy=-1,zakr_sel=-1,otkr_buy=-1,otkr_sel=-1;
//--- время открытия бара 1 на текущем и предыдущем тике
datetime vrem_new,vrem_old;
//--- комментарий к ордеру (причина открытия)
string signal_name;
//---
int    handle_iMA_34_M5;                     // variable for storing the handle of the iMA indicator 
int    handle_iMA_55_M5;                     // variable for storing the handle of the iMA indicator 
int    handle_iMA_89_M5;                     // variable for storing the handle of the iMA indicator 
int    handle_iMA_144_M5;                    // variable for storing the handle of the iMA indicator 
int    handle_iMA_233_M5;                    // variable for storing the handle of the iMA indicator 

int    handle_iMA_34_M15;                    // variable for storing the handle of the iMA indicator 
int    handle_iMA_55_M15;                    // variable for storing the handle of the iMA indicator 
int    handle_iMA_89_M15;                    // variable for storing the handle of the iMA indicator 
int    handle_iMA_144_M15;                   // variable for storing the handle of the iMA indicator 
int    handle_iMA_233_M15;                   // variable for storing the handle of the iMA indicator 

int    handle_iMA_34_H1;                     // variable for storing the handle of the iMA indicator 
int    handle_iMA_55_H1;                     // variable for storing the handle of the iMA indicator 
int    handle_iMA_89_H1;                     // variable for storing the handle of the iMA indicator 
int    handle_iMA_144_H1;                    // variable for storing the handle of the iMA indicator 
int    handle_iMA_233_H1;                    // variable for storing the handle of the iMA indicator 

int    handle_iStochastic_M5;                // variable for storing the handle of the iStochastic indicator 
int    handle_iStochastic_M15;               // variable for storing the handle of the iStochastic indicator 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();

   string err_text="";
   if(!CheckVolumeValue(OrdinaryLot,err_text))
     {
      Print(__FUNCTION__,", ERROR: ",err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   m_trade.SetExpertMagicNumber(m_magic);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
//---
   Comment("\nЗАПУСК СОВЕТНИКА");

   if(Period()!=PERIOD_M5)
      MessageBox("Нужно выбрать период M5");

   if(Symbol()!="GBPUSD")
      MessageBox("Нужно выбрать валюту GBP/USD");

   vrem_old=iTime(m_symbol.Name(),Period(),2);

   if(!CreateMA(handle_iMA_34_M5,PERIOD_M5,34))
      return(INIT_FAILED);
   if(!CreateMA(handle_iMA_55_M5,PERIOD_M5,55))
      return(INIT_FAILED);
   if(!CreateMA(handle_iMA_89_M5,PERIOD_M5,89))
      return(INIT_FAILED);
   if(!CreateMA(handle_iMA_144_M5,PERIOD_M5,144))
      return(INIT_FAILED);
   if(!CreateMA(handle_iMA_233_M5,PERIOD_M5,233))
      return(INIT_FAILED);

   if(!CreateMA(handle_iMA_34_M15,PERIOD_M15,34))
      return(INIT_FAILED);
   if(!CreateMA(handle_iMA_55_M15,PERIOD_M15,55))
      return(INIT_FAILED);
   if(!CreateMA(handle_iMA_89_M15,PERIOD_M15,89))
      return(INIT_FAILED);
   if(!CreateMA(handle_iMA_144_M15,PERIOD_M15,144))
      return(INIT_FAILED);
   if(!CreateMA(handle_iMA_233_M15,PERIOD_M15,233))
      return(INIT_FAILED);

   if(!CreateMA(handle_iMA_34_H1,PERIOD_H1,34))
      return(INIT_FAILED);
   if(!CreateMA(handle_iMA_55_H1,PERIOD_H1,55))
      return(INIT_FAILED);
   if(!CreateMA(handle_iMA_89_H1,PERIOD_H1,89))
      return(INIT_FAILED);
   if(!CreateMA(handle_iMA_144_H1,PERIOD_H1,144))
      return(INIT_FAILED);
   if(!CreateMA(handle_iMA_233_H1,PERIOD_H1,233))
      return(INIT_FAILED);
//--- create handle of the indicator iStochastic
   handle_iStochastic_M5=iStochastic(m_symbol.Name(),PERIOD_M5,StochasticKperiodM5,4,3,MODE_SMA,STO_LOWHIGH);
//--- if the handle is not created 
   if(handle_iStochastic_M5==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iStochastic indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_M5),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iStochastic
   handle_iStochastic_M15=iStochastic(m_symbol.Name(),PERIOD_M15,StochasticKperiodM15,4,3,MODE_SMA,STO_LOWHIGH);
//--- if the handle is not created 
   if(handle_iStochastic_M15==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iStochastic indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(PERIOD_M15),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//--- расстояния между крайними скользящими средними
   int dist_m5,dist_15,dist_h1;
//--- время открытия бара 1 на текущем тике
   vrem_new=iTime(m_symbol.Name(),Period(),1);
//--- если это новый бар
   if(vrem_new!=vrem_old)
     {
      //--- обнуляем сигналы управления ордерами, выполняем анализ и расчеты
      zakr_buy=0; zakr_sel=0; otkr_buy=0; otkr_sel=0; signal_name="СИГНАЛОВ НЕ БЫЛО"; lt_koef=0;

      TimeframeAnalysisM5(veer_m5,dist_m5,prob_m5);

      TimeframeAnalysisM15(veer_15,dist_15,prob_15);

      TimeframeAnalysisH1(veer_h1,dist_h1);

      stoch_crosM5=StochasticAnalysis();

      prb_flt=IsBreakdownFlat();

      hrn_bull=IsGornBull(1);

      hrn_bear=IsGornBear(1);

      prb_yz=BreaksThrough(1);

      div_buy=DivergenceBull(4);

      div_sel=DivergenceBear(4);
      //--- пересечение стохастика и сигнальной линии в крайней зоне на М15
      stoh_per15=СrossingStochasticM15(1);
      //--- находим ближайший бар, где есть молот и направление молота
      //--- если у нас есть два молота, засчитывается только ближайший
      molot=0; mltbr=0;

      for(mltbr=1; mltbr<20; mltbr++)
        {
         molot=IsHammer(mltbr);

         if(molot!=0)
            break;
        }
      MqlRates rates[1];
      if(CopyRates(m_symbol.Name(),PERIOD_M5,1,1,rates)!=1)
         return;
      //--- сигнал 1 : узкий веер на М5, большая свеча, пересечение стохастика в крайней зоне
      if(dist_m5<MaxFanDistanceM5)
        {
         if((veer_m5>0) && (veer_15>0) && (veer_h1>0) && (stoch_crosM5>0))
           {
            if((rates[0].open+MinBody*Point())<rates[0].close)
              {
               otkr_buy=1;
               lt_koef++;
               signal_name="veer and stoch";
              }
           }
         //--- 
         if((veer_m5<0) && (veer_15<0) && (veer_h1<0) && (stoch_crosM5<0))
           {
            if((rates[0].open-MinBody*Point())>rates[0].close)
              {
               otkr_sel=1;
               lt_koef++;
               signal_name="veer and stoch";
              }
           }
        }
      //--- сигнал 2 : пробой веера средних на М5, у свечи нет задней тени
      if(prob_m5>0)
        {
         if((veer_m5>0) && (veer_15>0) && (veer_h1>0) && (rates[0].open==rates[0].low))
           {
            otkr_buy=1;
            lt_koef++;
            signal_name="proboy m5";
           }
        }
      //--- 
      if(prob_m5<0)
        {
         if((veer_m5<0) && (veer_15<0) && (veer_h1<0) && (rates[0].open==rates[0].high))
           {
            otkr_sel=1;
            lt_koef++;
            signal_name="proboy m5";
           }
        }
      //--- сигнал 3 : пробой узкого флета по тренду на графике М5
      if(prb_flt>0)
        {
         if((veer_m5>0) && (veer_15>0) && (veer_h1>0))
           {
            otkr_buy=1;
            lt_koef++;
            signal_name="proboy fleta";
           }
        }
      //--- 
      if(prb_flt<0)
        {
         if((veer_m5<0) && (veer_15<0) && (veer_h1<0))
           {
            otkr_sel=1;
            lt_koef++;
            signal_name="proboy fleta";
           }
        }
      //--- сигнал 4 : пробой скользящих средних на М5 и на М15, узость МА на М15
      if(prob_15>0)
        {
         if((prob_m5>0) && (veer_15>0) && (veer_h1>0) && (dist_15<MaxFanDistanceM15))
           {
            otkr_buy=1;
            lt_koef++;
            signal_name="proboy 3x";
           }
        }
      //--- 
      if(prob_15<0)
        {
         if((prob_m5<0) && (veer_15<0) && (veer_h1<0) && (dist_15<MaxFanDistanceM15))
           {
            otkr_sel=1;
            lt_koef++;
            signal_name="proboy 3x";
           }
        }
      //--- сигнал 5 : дивергенция стохастика на М5
      if(div_buy>0)
        {
         if((veer_m5>0) && (veer_15>0) && (veer_h1>0))
           {
            otkr_buy=1;
            lt_koef++;
            signal_name="diver stoch";
           }
        }
      //--- 
      if(div_sel>0)
        {
         if((veer_m5<0) && (veer_15<0) && (veer_h1<0))
           {
            otkr_sel=1;
            lt_koef++;
            signal_name="diver stoch";
           }
        }
      //--- сигнал 6 : молот на М5 по тренду
      if((mltbr<=HammerBarHowLongAgo) && (dist_h1<MaxFanDistanceH1))
        {
         int      bar_highest=-1;
         double   price_highest  = 0.0;
         int      bar_lowest     = -1;
         double   price_lowest   = 0.0;

         if(Highest(bar_highest,price_highest,m_symbol.Name(),PERIOD_M5,MODE_HIGH,HammerPeriodOnBars,1) && 
            Lowest(bar_lowest,price_lowest,m_symbol.Name(),PERIOD_M5,MODE_LOW,HammerPeriodOnBars,1))
           {
            if((molot>0) && (mltbr==bar_lowest) && (rates[0].open<rates[0].close))
              {
               if((veer_m5>0) && (veer_15>0) && (veer_h1>0))
                 {
                  otkr_buy=1;

                  lt_koef++;

                  signal_name="molot";
                 }
              }
            //--- 
            if((molot<0) && (mltbr==bar_highest) && (rates[0].open>rates[0].close))
              {
               if((veer_m5<0) && (veer_15<0) && (veer_h1<0))
                 {
                  otkr_sel=1;

                  lt_koef++;

                  signal_name="molot";
                 }
              }
           }
        }
      //--- сигнал 7 : пересечение стохастика на М15 в крайней зоне по тренду
      if(stoh_per15>0)
        {
         if((veer_m5>0) && (veer_15>0) && (veer_h1>0))
           {
            otkr_buy=1;

            lt_koef++;

            signal_name="stoh15";
           }
        }
      //--- 
      if(stoh_per15<0)
        {
         if((veer_m5<0) && (veer_15<0) && (veer_h1<0))
           {
            otkr_sel=1;

            lt_koef++;

            signal_name="stoh15";
           }
        }
      //--- сигнал 8 : горн (очень узкий веер на М5), цена пробивает диапазон
      if(prb_yz>0)
        {
         if((hrn_bull>0) && (veer_15>0) && (veer_h1>0) && (hrn_bull<FanConvergedToPointIinBars))
           {
            otkr_buy=1;

            lt_koef++;

            signal_name="horn_bull";
           }
        }
      //--- 
      if(prb_yz<0)
        {
         if((hrn_bear>0) && (veer_15<0) && (veer_h1<0) && (hrn_bear<FanConvergedToPointIinBars))
           {
            otkr_sel=1;

            lt_koef++;

            signal_name="horn_bear";
           }
        }
      //--- если открываем позицию, то закрываем противоположную
      if(otkr_buy==1)
         zakr_sel=2;

      if(otkr_sel==1)
         zakr_buy=2;
      //--- если закрываем позицию, то отменяем сигнал к открытию
      if(zakr_buy==2)
         otkr_buy=0;

      if(zakr_sel==2)
         otkr_sel=0;
      //--- вывод на экран результатов расчетов
      Comment("\nVEER_M5 = ",veer_m5,"   DIST_M5 = ",dist_m5,
              "\n\nVEER_15 = ",veer_15,"   DIST_15 = ",dist_15,
              "\n\nVEER_h1 = ",veer_h1,"   dist_h1 = ",dist_h1,
              "\n\nPRB_FLT = ",prb_flt,
              "\n\nSTOCH_CROSM5 = ",stoch_crosM5);

      //--- расчеты выполнены, теперь это не новый бар
      vrem_old=vrem_new;
     }
//--- закрываем и модифицируем имеющиеся ордера
   perebor_orderov(zakr_buy,zakr_sel);
//--- подсчитываем лоты открытых позиций
   CalculateVolumePositions(lot_buy,lot_sel);
//--- установка бая
   if((otkr_buy==1) && (lot_buy<0.01))
      if(RefreshRates())
         ystanovit_buy(signal_name,lt_koef);
//--- установка села
   if((otkr_sel==1) && (lot_sel<0.01))
      if(RefreshRates())
         ystanovit_sel(signal_name,lt_koef);
  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//---

  }
//+------------------------------------------------------------------+
//| Анализ скользящих средних на графике М5 (на текущем графике)     |
//+------------------------------------------------------------------+
void TimeframeAnalysisM5(int &veer,int &dist,int &prob)
  {
   double ma[5];
   int v,n;
   double vma,nma,rast;
   veer=0;  prob=0;
//--- считываем скользящие средние на баре 1
   ma[0] = iMAGet(handle_iMA_34_M5,1);
   ma[1] = iMAGet(handle_iMA_55_M5,1);
   ma[2] = iMAGet(handle_iMA_89_M5,1);
   ma[3] = iMAGet(handle_iMA_144_M5,1);
   ma[4] = iMAGet(handle_iMA_233_M5,1);
   for(int i=0;i<5;i++)
      if(ma[i]==0.0)
         return;
//--- верхняя скользящая средняя
   v=ArrayMaximum(ma);
   vma=ma[v];
//--- нижняя скользящая средняя
   n=ArrayMinimum(ma);
   nma=ma[n];
//--- расстояние между верхней и нижней МА в пунктах
   rast = (vma-nma)/Point();
   dist = (int)NormalizeDouble(rast, 0);
//--- округлим три легкие МА до ... знаков после запятой
   ma[0] = NormalizeDouble(ma[0], m_symbol.Digits());
   ma[1] = NormalizeDouble(ma[1], m_symbol.Digits());
   ma[2] = NormalizeDouble(ma[2], m_symbol.Digits());
//--- веер вверх
   if((ma[4]<ma[3]) && (ma[3]<ma[2]) && (ma[2]<=ma[1]) && (ma[1]<=ma[0]))
      veer=1;
//--- веер вниз
   if((ma[4]>ma[3]) && (ma[3]>ma[2]) && (ma[2]>=ma[1]) && (ma[1]>=ma[0]))
      veer=-1;

   MqlRates rates[1];
   if(CopyRates(m_symbol.Name(),PERIOD_M5,1,1,rates)!=1)
      return;
//--- пробой вверх
   if((rates[0].open<nma) && (rates[0].close>vma))
      prob=1;
//---пробой вниз
   if((rates[0].open>vma) && (rates[0].close<nma))
      prob=-1;
   return;
  }
//+------------------------------------------------------------------+
//| Анализ скользящих средних на графике М15                         |
//+------------------------------------------------------------------+
void TimeframeAnalysisM15(int &veer,int &dist,int &prob)
  {
   double ma[5];
   int v,n;
   double vma,nma,rast,op_15,cl_15;
   veer=0; prob=0;
//--- считываем скользящие средние на баре 1
   ma[0] = iMAGet(handle_iMA_34_M15,1);
   ma[1] = iMAGet(handle_iMA_55_M15,1);
   ma[2] = iMAGet(handle_iMA_89_M15,1);
   ma[3] = iMAGet(handle_iMA_144_M15,1);
   ma[4] = iMAGet(handle_iMA_233_M15,1);
   for(int i=0;i<5;i++)
      if(ma[i]==0.0)
         return;
//--- верхняя скользящая средняя
   v=ArrayMaximum(ma);
   vma=ma[v];
//--- нижняя скользящая средняя
   n=ArrayMinimum(ma);
   nma=ma[n];
//--- расстояние между верхней и нижней МА в пунктах
   rast = (vma-nma)/Point();
   dist = (int)NormalizeDouble(rast, 0);
//--- округлим две легкие МА до ... знаков после запятой
   ma[0] = NormalizeDouble(ma[0], m_symbol.Digits());
   ma[1] = NormalizeDouble(ma[1], m_symbol.Digits());
//--- веер вверх
   if((ma[4]<ma[3]) && (ma[3]<ma[2]) && (ma[2]<ma[1]) && (ma[1]<=ma[0]))
      veer=1;
//--- веер вниз
   if((ma[4]>ma[3]) && (ma[3]>ma[2]) && (ma[2]>ma[1]) && (ma[1]>=ma[0]))
      veer=-1;
//--- определение пробоя трех быстрых скользящих средних на графике М15
   MqlRates rates[1];
   if(CopyRates(m_symbol.Name(),PERIOD_M15,1,1,rates)!=1)
      return;
   op_15=rates[0].open;
   cl_15=rates[0].close;
   if((op_15>0) && (cl_15>0))
     {
      if((op_15<ma[0]) && (op_15<ma[1]) && (op_15<ma[2]))
        {
         if((cl_15>ma[0]) && (cl_15>ma[1]) && (cl_15>ma[2]))
            prob=1;
        }

      if((op_15>ma[0]) && (op_15>ma[1]) && (op_15>ma[2]))
        {
         if((cl_15<ma[0]) && (cl_15<ma[1]) && (cl_15<ma[2]))
            prob=-1;
        }
     }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Анализ скользящих средних на графике H1                          |
//+------------------------------------------------------------------+
void TimeframeAnalysisH1(int &veer,int &dist)
  {
   double ma[5];
   int v,n;
   double vma,nma,rast;
   veer=0;
//--- считываем скользящие средние на баре 1
   ma[0] = iMAGet(handle_iMA_34_H1,1);
   ma[1] = iMAGet(handle_iMA_55_H1,1);
   ma[2] = iMAGet(handle_iMA_89_H1,1);
   ma[3] = iMAGet(handle_iMA_144_H1,1);
   ma[4] = iMAGet(handle_iMA_233_H1,1);
   for(int i=0;i<5;i++)
      if(ma[i]==0.0)
         return;
//--- верхняя скользящая средняя
   v=ArrayMaximum(ma);
   vma=ma[v];
//--- нижняя скользящая средняя
   n=ArrayMinimum(ma);
   nma=ma[n];
//--- расстояние между верхней и нижней МА в пунктах
   rast = (vma-nma)/Point();
   dist = (int)NormalizeDouble(rast, 0);
//--- веер вверх
   if((ma[4]<ma[3]) && (ma[3]<ma[2]) && (ma[2]<ma[1]) && (ma[1]<ma[0]))
      veer=1;
//--- веер вниз
   if((ma[4]>ma[3]) && (ma[3]>ma[2]) && (ma[2]>ma[1]) && (ma[1]>ma[0]))
      veer=-1;
//---
   return;
  }
//+------------------------------------------------------------------+
//| Если правильный веер расширяется из очень узкого источника,      |
//| то это "горн"                                                    |
//+------------------------------------------------------------------+
int IsGornBull(int b)
  {
   double ma5=0.0,ma4=0.0,ma3=0.0,ma2=0.0,ma1=0.0;
   double rast_i=0.0,rast_b=0.0;
//--- считываем скользящие средние на баре b
   double ma[5];
   ma[0] = iMAGet(handle_iMA_34_M5,b);
   ma[1] = iMAGet(handle_iMA_55_M5,b);
   ma[2] = iMAGet(handle_iMA_89_M5,b);
   ma[3] = iMAGet(handle_iMA_144_M5,b);
   ma[4] = iMAGet(handle_iMA_233_M5,b);
   for(int i=0;i<5;i++)
      if(ma[i]==0.0)
         return(-1);
//--- если это правильный веер вверх
   if((ma5<ma4) && (ma4<ma3) && (ma3<ma2) && (ma2<ma1))
     {
      rast_b=ma1-ma5;
      double array_iMA_34_M5[];
      double array_iMA_55_M5[];
      double array_iMA_89_M5[];
      double array_iMA_144_M5[];
      double array_iMA_233_M5[];
      ArraySetAsSeries(array_iMA_34_M5,true);
      ArraySetAsSeries(array_iMA_55_M5,true);
      ArraySetAsSeries(array_iMA_89_M5,true);
      ArraySetAsSeries(array_iMA_144_M5,true);
      ArraySetAsSeries(array_iMA_233_M5,true);
      int start_pos  = b;
      int count      = 300;
      if(!iMAGetArray(handle_iMA_34_M5,start_pos,count,array_iMA_34_M5) && 
         !iMAGetArray(handle_iMA_55_M5,start_pos,count,array_iMA_55_M5) && 
         !iMAGetArray(handle_iMA_89_M5,start_pos,count,array_iMA_89_M5) && 
         !iMAGetArray(handle_iMA_144_M5,start_pos,count,array_iMA_144_M5) && 
         !iMAGetArray(handle_iMA_233_M5,start_pos,count,array_iMA_233_M5))
         return(-1);
      //--- начинаем просмотр пучка скользящих средних назад от точки b
      //for(i=(b+1); i<(b+300); i++)
      for(int i=0;i<count;i++)
        {
         //--- считываем значения МА
         ma1 = NormalizeDouble(array_iMA_34_M5[i],m_symbol.Digits());
         ma2 = NormalizeDouble(array_iMA_55_M5[i],m_symbol.Digits());
         ma3 = NormalizeDouble(array_iMA_89_M5[i],m_symbol.Digits());
         ma4 = NormalizeDouble(array_iMA_144_M5[i],m_symbol.Digits());
         ma5 = NormalizeDouble(array_iMA_233_M5[i],m_symbol.Digits());
         //--- если почти правильный веер сохраняется
         if(((ma5<=ma3) && (ma4<=ma3) && (ma3<=ma2) && (ma2<=ma1)) || ((ma5<=ma4) && (ma4<=ma3) && (ma3<=ma2) && (ma3<=ma1)))
           {
            rast_i=MathMax(ma2,ma1)-MathMin(ma5,ma4);
            //--- если веер становится шире, чем в точке bx он нам не подходит
            if(rast_i>(rast_b+2*Point()))
               return(0);
            //--- ищем бар, где веер сходится в узкий источник и возвращаем его   
            if((rast_i<(MaxFanWidthAtNarrowestM5*Point())) && (rast_i<rast_b))
               return(i);
           }
         else
            return(0);
        }
     }
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Если правильный веер расширяется из очень узкого источника,      |
//| то это "горн"                                                    |
//+------------------------------------------------------------------+
int IsGornBear(int b)
  {
   double ma5=0.0,ma4=0.0,ma3=0.0,ma2=0.0,ma1=0.0;
   double rast_i=0.0,rast_b=0.0;
//--- считываем скользящие средние на баре b
   double ma[5];
   ma[0] = iMAGet(handle_iMA_34_M5,b);
   ma[1] = iMAGet(handle_iMA_55_M5,b);
   ma[2] = iMAGet(handle_iMA_89_M5,b);
   ma[3] = iMAGet(handle_iMA_144_M5,b);
   ma[4] = iMAGet(handle_iMA_233_M5,b);
   for(int i=0;i<5;i++)
      if(ma[i]==0.0)
         return(-1);
//--- если это правильный веер вниз
   if((ma5>ma4) && (ma4>ma3) && (ma3>ma2) && (ma2>ma1))
     {
      rast_b=ma5-ma1;
      double array_iMA_34_M5[];
      double array_iMA_55_M5[];
      double array_iMA_89_M5[];
      double array_iMA_144_M5[];
      double array_iMA_233_M5[];
      ArraySetAsSeries(array_iMA_34_M5,true);
      ArraySetAsSeries(array_iMA_55_M5,true);
      ArraySetAsSeries(array_iMA_89_M5,true);
      ArraySetAsSeries(array_iMA_144_M5,true);
      ArraySetAsSeries(array_iMA_233_M5,true);
      int start_pos  = b;
      int count      = 300;
      if(!iMAGetArray(handle_iMA_34_M5,start_pos,count,array_iMA_34_M5) && 
         !iMAGetArray(handle_iMA_55_M5,start_pos,count,array_iMA_55_M5) && 
         !iMAGetArray(handle_iMA_89_M5,start_pos,count,array_iMA_89_M5) && 
         !iMAGetArray(handle_iMA_144_M5,start_pos,count,array_iMA_144_M5) && 
         !iMAGetArray(handle_iMA_233_M5,start_pos,count,array_iMA_233_M5))
         return(-1);
      //--- начинаем просмотр пучка скользящих средних назад от точки b
      //for(i=(b+1); i<(b+300); i++)
      for(int i=0;i<count;i++)
        {
         //--- считываем значения МА
         ma1 = NormalizeDouble(array_iMA_34_M5[i],m_symbol.Digits());
         ma2 = NormalizeDouble(array_iMA_55_M5[i],m_symbol.Digits());
         ma3 = NormalizeDouble(array_iMA_89_M5[i],m_symbol.Digits());
         ma4 = NormalizeDouble(array_iMA_144_M5[i],m_symbol.Digits());
         ma5 = NormalizeDouble(array_iMA_233_M5[i],m_symbol.Digits());
         //--- если почти правильный веер сохраняется
         if(((ma5>=ma3) && (ma4>=ma3) && (ma3>=ma2) && (ma2>=ma1)) || ((ma5>=ma4) && (ma4>=ma3) && (ma3>=ma2) && (ma3>=ma1)))
           {
            rast_i=MathMax(ma5,ma4)-MathMin(ma2,ma1);
            //--- если веер становится шире, чем в точке b он нам не подходит
            if(rast_i>(rast_b+2*Point()))
               return(0);
            //--- ищем бар, где веер сходится в узкий источник и возвращаем его   
            if((rast_i<(MaxFanWidthAtNarrowestM5*Point())) && (rast_i<rast_b))
               return(i);
           }
         else
            return(0);
        }
     }
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Определение пробоя диапазона для сигнала узости на баре b        |
//+------------------------------------------------------------------+
int BreaksThrough(int b)
  {
   int      bar_highest    = -1;
   double   price_highest  = 0.0;
   int      bar_lowest     = -1;
   double   price_lowest   = 0.0;
   if(!Highest(bar_highest,price_highest,m_symbol.Name(),PERIOD_M5,MODE_HIGH,RangeMaxOrMinBreaksThrough,b+1) || 
      !Lowest(bar_lowest,price_lowest,m_symbol.Name(),PERIOD_M5,MODE_LOW,RangeMaxOrMinBreaksThrough,b+1))
      return(0);

   MqlRates rates[1];
   if(CopyRates(m_symbol.Name(),PERIOD_M5,1,1,rates)!=1)
      return(0);

   if((rates[0].open<price_highest) && (rates[0].close>price_highest))
      return(1);
   if((rates[0].open>price_lowest) && (rates[0].close<price_lowest))
      return(-1);
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Есть ли дивергенция сигнал к покупке на баре b                   |
//|   (правый минимум индикатора)                                    |
//+------------------------------------------------------------------+
int DivergenceBull(int b)
  {
   double stoh_min,yama1,lw2,lw1;

   if(b<4)
      return(0);

   double array_iStochastic_M5[];
   ArraySetAsSeries(array_iStochastic_M5,true);
   int start_pos  = 0;
   int count      = 321;
   if(!iStochasticGetArray(handle_iStochastic_M5,MAIN_LINE,start_pos,count,array_iStochastic_M5))
      return(0);

   double st1 = array_iStochastic_M5[b-3];
   double st2 = array_iStochastic_M5[b-2];
   double st3 = array_iStochastic_M5[b-1];
   double st4 = array_iStochastic_M5[b];
   double st5 = array_iStochastic_M5[b+1];
   double st6 = array_iStochastic_M5[b+2];
   double st7 = array_iStochastic_M5[b+3];
//--- если точка b это яма на индикаторе стохастик
   if((st7>st4) && (st6>st4) && (st5>st4))
     {
      if((st4<st3) && (st3<st2) && (st2<st1))
        {
         //--- объявляем ее минимумом
         yama1    = st4;
         stoh_min = st4;
         //--- минимальная цена в этой области
         int      bar_lowest     = -1;
         double   price_lowest   = 0.0;
         if(!Lowest(bar_lowest,price_lowest,m_symbol.Name(),PERIOD_M5,MODE_LOW,7,b-3))
            return(0);
         lw1=price_lowest;//Low[iLowest(NULL,0,MODE_LOW,7,(b-3))];

         double Low[];
         ArraySetAsSeries(Low,true);
         if(CopyLow(m_symbol.Name(),PERIOD_M5,start_pos,count,Low)!=count)
            return(0);

         for(int i=(b+4); i<300; i++)
           {
            //--- цена не должна опускаться ниже первого минимума
            if(Low[i]<lw1)
               return(0);

            st1 = array_iStochastic_M5[i-3];
            st2 = array_iStochastic_M5[i-2];
            st3 = array_iStochastic_M5[i-1];
            st4 = array_iStochastic_M5[i];
            st5 = array_iStochastic_M5[i+1];
            st6 = array_iStochastic_M5[i+2];
            st7 = array_iStochastic_M5[i+3];

            if((st7>st4) && (st6>st4) && (st5>st4))
              {
               if((st4<st3) && (st4<st2) && (st4<st1))
                 {
                  if((st4<stoh_min) && (i>(b+MinDivergencesInBarsM5)))
                    {
                     if(!Lowest(bar_lowest,price_lowest,m_symbol.Name(),PERIOD_M5,MODE_LOW,7,i-3))
                        return(0);
                     lw2=price_lowest;//Low[iLowest(NULL,0,MODE_LOW,7,(i-3))];

                     if(lw2>lw1)
                        return(i);
                    }
                  //--- правый минимум должен быть ниже всех, кроме левого
                  if(st4<yama1)
                     return(0);
                 }
              }
            if(st4<stoh_min)
               stoh_min=st4;
           }
        }
     }
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Есть ли дивергенция сигнал к продаже на баре b                   |
//| (правый максимум индикатора)                                     |
//+------------------------------------------------------------------+
int DivergenceBear(int b)
  {
   double stoh_max,xolm1,hi2,hi1;

   if(b<4)
      return(0);

   double array_iStochastic_M5[];
   ArraySetAsSeries(array_iStochastic_M5,true);
   int start_pos  = 0;
   int count      = 321;
   if(!iStochasticGetArray(handle_iStochastic_M5,MAIN_LINE,start_pos,count,array_iStochastic_M5))
      return(0);

   double st1 = array_iStochastic_M5[b-3];
   double st2 = array_iStochastic_M5[b-2];
   double st3 = array_iStochastic_M5[b-1];
   double st4 = array_iStochastic_M5[b];
   double st5 = array_iStochastic_M5[b+1];
   double st6 = array_iStochastic_M5[b+2];
   double st7 = array_iStochastic_M5[b+3];
//--- если точка b это холм на индикаторе стохастик
   if((st7<st4) && (st6<st4) && (st5<st4))
     {
      if((st4>st3) && (st3>st2) && (st2>st1))
        {
         //--- объявляем ее максимумом
         xolm1    = st4;
         stoh_max = st4;
         //--- максимальная цена в этой области
         int      bar_highest    = -1;
         double   price_highest  = 0.0;
         if(!Highest(bar_highest,price_highest,m_symbol.Name(),PERIOD_M5,MODE_HIGH,7,b-3))
            return(0);
         hi1=price_highest;//High[iHighest(NULL,0,MODE_HIGH,7,(b-3))];

         double High[];
         ArraySetAsSeries(High,true);
         if(CopyHigh(m_symbol.Name(),PERIOD_M5,start_pos,count,High)!=count)
            return(0);

         for(int i=(b+4); i<300; i++)
           {
            //--- цена не должна подниматься выше первого максимума
            if(High[i]>hi1)
               return(0);

            st1 = array_iStochastic_M5[i-3];
            st2 = array_iStochastic_M5[i-2];
            st3 = array_iStochastic_M5[i-1];
            st4 = array_iStochastic_M5[i];
            st5 = array_iStochastic_M5[i+1];
            st6 = array_iStochastic_M5[i+2];
            st7 = array_iStochastic_M5[i+3];

            if((st7<st4) && (st6<st4) && (st5<st4))
              {
               if((st4>st3) && (st4>st2) && (st4>st1))
                 {
                  if((st4>stoh_max) && (i>(b+MinDivergencesInBarsM5)))
                    {
                     if(!Highest(bar_highest,price_highest,m_symbol.Name(),PERIOD_M5,MODE_LOW,7,i-3))
                        return(0);
                     hi2=price_highest;//High[iHighest(NULL,0,MODE_HIGH,7,(i-3))];

                     if(hi2<hi1)
                        return(i);
                    }
                  //--- правый максимум должен быть выше всех, кроме левого
                  if(st4>xolm1)
                     return(0);
                 }
              }
            if(st4>stoh_max)
               stoh_max=st4;
           }
        }
     }
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Анализ стохастика на графике М5 (на текущем графике)             |
//+------------------------------------------------------------------+
int StochasticAnalysis()
  {
   double array_iStochastic_MAIN_M5[];
   ArraySetAsSeries(array_iStochastic_MAIN_M5,true);
   int start_pos  = 0;
   int count      = 3;
   if(!iStochasticGetArray(handle_iStochastic_M5,MAIN_LINE,start_pos,count,array_iStochastic_MAIN_M5))
      return(0);

   double array_iStochastic_SIGNAL_M5[];
   ArraySetAsSeries(array_iStochastic_SIGNAL_M5,true);
   start_pos=0;
   count=3;
   if(!iStochasticGetArray(handle_iStochastic_M5,SIGNAL_LINE,start_pos,count,array_iStochastic_SIGNAL_M5))
      return(0);
//--- стохастик на барах 2, 1
   double st2 = array_iStochastic_MAIN_M5[2];
   double st1 = array_iStochastic_MAIN_M5[1];
//--- сигнальная линия на барах 2, 1
   double si2 = array_iStochastic_SIGNAL_M5[2];
   double si1 = array_iStochastic_SIGNAL_M5[1];
//--- пересечение снизу вверх
   if((st2<si2) && (st2<StochasticDownM5) && (st1>si1))
      return(1);
//--- пересечение сверху вниз
   if((st2>si2) && (st2>StochasticUpM5) && (st1<si1))
      return(-1);
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Анализ стохастика на графике М15 (поиск пересечения              |
//| с сигнальной линией + подтверждение движением цены)              |
//| проверяется факт наличия пересечения на баре b М15 в крайней зоне|
//+------------------------------------------------------------------+
int СrossingStochasticM15(int b)
  {
   double array_iStochastic_MAIN_M15[];
   ArraySetAsSeries(array_iStochastic_MAIN_M15,true);
   int start_pos  = b;
   int count      = 3;
   if(!iStochasticGetArray(handle_iStochastic_M15,MAIN_LINE,start_pos,count,array_iStochastic_MAIN_M15))
      return(0);

   double array_iStochastic_SIGNAL_M5[];
   ArraySetAsSeries(array_iStochastic_SIGNAL_M5,true);
   start_pos  = b;
   count      = 3;
   if(!iStochasticGetArray(handle_iStochastic_M15,SIGNAL_LINE,start_pos,count,array_iStochastic_SIGNAL_M5))
      return(0);
//--- стохастик на барах 3, 2, 1 (бар 1 это бар b)
   double st3 = array_iStochastic_MAIN_M15[2];
   double st2 = array_iStochastic_MAIN_M15[1];
   double st1 = array_iStochastic_MAIN_M15[0];
//--- сигнальная линия на барах 2, 1
   double si2 = array_iStochastic_SIGNAL_M5[1];
   double si1 = array_iStochastic_SIGNAL_M5[0];
//--- открытие и закрытие бара 1 на М15
   MqlRates rates[1];
   if(CopyRates(m_symbol.Name(),PERIOD_M15,1,0,rates)!=1)
      return(0);

   double op1=rates[0].open;
   double cl1=rates[0].close;

   if((op1==0.0) || (cl1==0.0))
      return(0);

//--- сигнал к покупке
   if((st2<si2) && (st1>si1) && (op1<cl1))
     {
      if((st3<StochasticDownM15) || (st2<StochasticDownM15))
         return(1);
     }
//--- сигнал к продаже
   if((st2>si2) && (st1<si1) && (op1>cl1))
     {
      if((st3>StochasticUpM15) || (st2>StochasticUpM15))
         return(-1);
     }
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Поиск флета на заданном баре (возвращает количество              |
//| баров, верх, низ флета)                                          |
//+------------------------------------------------------------------+
void SearchFlat(int b,int &flt_kl,double &flt_up,double &flt_dn)
  {
   double ver_fl,niz_fl,nash_razm;
   int kol;
   flt_kl=0; flt_up=0; flt_dn=0;
   kol=1;

   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   if(CopyRates(m_symbol.Name(),PERIOD_M5,b,500,rates)!=500)
      return;

   ver_fl=rates[0].high;
   niz_fl=rates[0].low;
//--- ищем длинный и узкий участок
   for(int i=1; i<500; i++)
     {
      if(rates[i].high>ver_fl)
         ver_fl=rates[i].high;
      if(rates[i].low<niz_fl)
         niz_fl=rates[i].low;
      //--- если превысили максимальную высоту выходим
      if((ver_fl-niz_fl)>(MaxFlatInPoints*Point()))
         return;
      kol++;

      if(kol>MinFlatInBars)
        {
         //--- наш размах флета (для данного количества баров)
         nash_razm=NormalizeDouble(((kol*CoefFlatnessM5)*Point()),m_symbol.Digits());

         if((ver_fl-niz_fl)<nash_razm)
           {
            flt_kl=kol;
            flt_up=ver_fl;
            flt_dn=niz_fl;
            return;
           }
        }
     }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Есть ли пробой флета на графике М5 (на текущем графике)          |
//+------------------------------------------------------------------+
int IsBreakdownFlat()
  {
//--- верхняя и нижняя граница флета
   double v_gr,n_gr;
//--- количество баров во флете
   int fk;
//--- ищем флет на баре 2 (пробой баром 1)
   SearchFlat(2,fk,v_gr,n_gr);

   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   if(CopyRates(m_symbol.Name(),PERIOD_M5,0,3,rates)!=3)
      return(0);

   if(fk>0)
     {
      if((rates[1].open<v_gr) && (rates[1].close>v_gr))
         return(1);
      if((rates[1].open>n_gr) && (rates[1].close<n_gr))
         return(-1);
     }
//--- ищем флет на баре 3, пробой двумя барами (2 и 1)
   SearchFlat(3,fk,v_gr,n_gr);

   if(fk>0)
     {
      if((rates[1].open<v_gr) && (rates[2].close>v_gr) && (rates[1].open<rates[1].close) && (rates[2].open<rates[2].close))
         return(1);
      if((rates[1].open>n_gr) && (rates[2].close<n_gr) && (rates[1].open>rates[1].close) && (rates[2].open>rates[2].close))
         return(-1);
     }
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Проверка, есть ли молот на баре br                               |
//+------------------------------------------------------------------+
int IsHammer(int br)
  {
   double razm_br,ver_ten,niz_ten;

   MqlRates rates[1];
   if(CopyRates(m_symbol.Name(),PERIOD_M5,br,1,rates)!=1)
      return(0);

   razm_br=rates[0].high-rates[0].low;

   ver_ten=rates[0].high-MathMax(rates[0].open,rates[0].close);

   niz_ten=MathMin(rates[0].open,rates[0].close)-rates[0].low;

   if(razm_br>(HammerMinSizeInPoints*Point()))
     {
      if((100*niz_ten)>(HammerMinPercentageLongShadow*razm_br))
        {
         if((100*ver_ten)<(HammerMaxPercentageShortShadow*razm_br))
           {
            return(1);
           }
        }
      if((100*ver_ten)>(HammerMinPercentageLongShadow*razm_br))
        {
         if((100*niz_ten)<(HammerMaxPercentageShortShadow*razm_br))
           {
            return(-1);
           }
        }
     }
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Подсчет лотов баев и селов  (переведенные в б/у не считаем)      |
//+------------------------------------------------------------------+
void CalculateVolumePositions(double &volume_buys,double &volume_sells)
  {
   volume_buys=0.0;
   volume_sells=0.0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if((m_position.StopLoss()==0) || (m_position.StopLoss()<m_position.PriceOpen()))
                  volume_buys+=m_position.Volume();
              }
            if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               if((m_position.StopLoss()==0) || (m_position.StopLoss()>m_position.PriceOpen()))
                  volume_sells+=m_position.Volume();
              }
           }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Действия с ордером BUY                                           |
//+------------------------------------------------------------------+
void obr_open_buy(int cl_b)
  {
//--- закрытие во избежание потерь
   if(cl_b==2)
     {
      m_trade.PositionClose(m_position.Ticket());
      return;
     }
//--- перевод стоп-лосса в безубыток
   if(StopLossAfterBreakeven>99)
     {
      if((m_position.StopLoss()==0) || (m_position.StopLoss()<m_position.PriceOpen()))
        {
         if((m_symbol.Bid()-StopLossAfterBreakeven*Point())>(m_position.PriceOpen()+TakeProfitAfterBreakeven*Point()))
           {
            if(!m_trade.PositionModify(m_position.Ticket(),
               m_symbol.NormalizePrice(m_symbol.Bid()-StopLossAfterBreakeven*Point()),
               m_position.TakeProfit()))
               Print("Modify ",m_position.Ticket(),
                     " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            return;
           }
        }
     }
//--- передвижение трейлинг-стопа
   if(DistTral>99)
     {
      if((m_symbol.Bid()-DistTral*Point())>m_position.PriceOpen())
        {
         if((m_symbol.Bid()-DistTral*Point())>(m_position.StopLoss()+StepTral*Point()))
           {
            if(!m_trade.PositionModify(m_position.Ticket(),
               m_symbol.NormalizePrice(m_symbol.Bid()-DistTral*Point()),
               m_position.TakeProfit()))
               Print("Modify ",m_position.Ticket(),
                     " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            return;
           }
        }
     }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Действия с ордером SELL                                          |
//+------------------------------------------------------------------+
void obr_open_sell(int cl_s)
  {
//--- закрытие во избежание потерь
   if(cl_s==2)
     {
      m_trade.PositionClose(m_position.Ticket());
      return;
     }
//--- перевод в стоп-лосса безубыток
   if(StopLossAfterBreakeven>99)
     {
      if((m_position.StopLoss()==0) || (m_position.StopLoss()>m_position.PriceOpen()))
        {
         if((m_symbol.Ask()+StopLossAfterBreakeven*Point())<(m_position.PriceOpen()-TakeProfitAfterBreakeven*Point()))
           {
            if(!m_trade.PositionModify(m_position.Ticket(),
               m_symbol.NormalizePrice(m_symbol.Ask()+StopLossAfterBreakeven*Point()),
               m_position.TakeProfit()))
               Print("Modify ",m_position.Ticket(),
                     " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            return;
           }
        }
     }
//--- передвижение трейлинг-стопа
   if(DistTral>99)
     {
      if((m_symbol.Ask()+DistTral*Point())<m_position.PriceOpen())
        {
         if((m_symbol.Ask()+DistTral*Point())<(m_position.StopLoss()-StepTral*Point()))
           {
            if(!m_trade.PositionModify(m_position.Ticket(),
               m_symbol.NormalizePrice(m_symbol.Ask()+DistTral*Point()),
               m_position.TakeProfit()))
               Print("Modify ",m_position.Ticket(),
                     " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
            return;
           }
        }
     }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Закрытие и модификация                                           |
//+------------------------------------------------------------------+
void perebor_orderov(int zak_b,int zak_s)
  {
   if(!RefreshRates())
      return;
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
               obr_open_buy(zak_b);

            if(m_position.PositionType()==POSITION_TYPE_SELL)
               obr_open_sell(zak_s);
           }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Открытие BUY                                                     |
//+------------------------------------------------------------------+
void ystanovit_buy(string prich,int kf)
  {
   double sl=0.0;
   if(StopLoss>99)
      sl=m_symbol.Bid()-StopLoss*Point();

   double tp=0.0;
   if(TakeProfit>99)
      tp=m_symbol.Ask()+TakeProfit*Point();

   double lt=OrdinaryLot;

   if(kf>1)
     {
      //--- если совпало несколько сигналов - открываем двойной лот
      lt=LotCheck(lt*2);
     }
   if(lt>0.0)
      OpenBuy(sl,tp,lt,prich);
  }
//+------------------------------------------------------------------+
//| Открытие SELL                                                    |
//+------------------------------------------------------------------+
void ystanovit_sel(string prich,int kf)
  {
   double sl=0.0;
   if(StopLoss>99)
      sl=m_symbol.Ask()+StopLoss*Point();

   double tp=0;
   if(TakeProfit>99)
      tp=m_symbol.Bid()-TakeProfit*Point();

   double lt=OrdinaryLot;

   if(kf>1)
     {
      //--- если совпало несколько сигналов - открываем двойной лот
      lt=LotCheck(lt*2);
     }
   if(lt>0.0)
      OpenSell(sl,tp,lt,prich);
  }
//+------------------------------------------------------------------+
//| Create Moving Average                                            |
//+------------------------------------------------------------------+
bool CreateMA(int &handle_iMA,const ENUM_TIMEFRAMES timeframe,const int ma_period)
  {
//--- create handle of the indicator iMA
   handle_iMA=iMA(m_symbol.Name(),timeframe,ma_period,0,MODE_EMA,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iMA==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(timeframe),
                  GetLastError());
      //--- the indicator is stopped early 
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(int handle_iMA,const int index)
  {
   double MA[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iMA,0,index,1,MA)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(MA[0]);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA in the array                    |
//+------------------------------------------------------------------+
bool iMAGetArray(const int handle_iMA,const int start_pos,const int count,double &arr_buffer[])
  {
//---
   bool result=true;
   if(!ArrayIsDynamic(arr_buffer))
     {
      Print("This a no dynamic array!");
      return(false);
     }
   ArrayFree(arr_buffer);
   int       buffer_num=0;          // indicator buffer number 
//--- reset error code 
   ResetLastError();
//--- fill a part of the iMABuffer array with values from the indicator buffer that has 0 index 
   int copied=CopyBuffer(handle_iMA,buffer_num,start_pos,count,arr_buffer);
   if(copied<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
   else if(copied<count)
     {
      PrintFormat("Moving Average indicator: %d elements from %d were copied",copied,count);
      DebugBreak();
      return(false);
     }
//---
   return(result);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iStochastic                         |
//|  the buffer numbers are the following:                           |
//|   0 - MAIN_LINE, 1 - SIGNAL_LINE                                 |
//+------------------------------------------------------------------+
bool iStochasticGetArray(const int handle_iStochastic,const int buffer,const int start_pos,const int count,double &array[])
  {
//--- reset error code 
   ResetLastError();
//--- fill a part of the iStochastic array with values from the indicator buffer that has 0 index 
   int copy_buffer=CopyBuffer(handle_iStochastic,buffer,start_pos,count,array);
   if(copy_buffer<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iStochastic indicator, error code %d",GetLastError());
      //--- quit with false result - it means that the indicator is considered as not calculated 
      return(false);
     }
   else if(copy_buffer!=count)
     {
      //--- if it is copied less, than set 
      PrintFormat("%d elements have been requested, only %d are copied",count,copy_buffer);
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Highest                                                          |
//+------------------------------------------------------------------+
bool Highest(int &bar_highest,double &price_highest,
             string symbol,
             ENUM_TIMEFRAMES timeframe,
             int type,
             int count=WHOLE_ARRAY,
             int start=0)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   if(start<0)
      return(false);
   if(count<=0)
      count=Bars(symbol,timeframe);
   if(type==MODE_HIGH)
     {
      double High[];
      if(CopyHigh(symbol,timeframe,start,count,High)!=count)
         return(false);
      bar_highest    = ArrayMaximum(High);
      price_highest  = High[bar_highest];
      return(true);
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Lowest                                                           |
//+------------------------------------------------------------------+
bool Lowest(int &bar_lowest,double &price_lowest,string symbol,
            ENUM_TIMEFRAMES timeframe,
            int type,
            int count=WHOLE_ARRAY,
            int start=0)
  {
   if(symbol==NULL)
      symbol=m_symbol.Name();
   if(timeframe==0)
      timeframe=Period();
   if(start<0)
      return(false);
   if(count<=0)
      count=Bars(symbol,timeframe);
   if(type==MODE_LOW)
     {
      double Low[];
      if(CopyLow(symbol,timeframe,start,count,Low)!=count)
         return(false);
      bar_lowest     = ArrayMinimum(Low);
      price_lowest   = Low[bar_lowest];
      return(true);
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Lot Check                                                        |
//+------------------------------------------------------------------+
double LotCheck(double lots)
  {
//--- calculate maximum volume
   double volume=NormalizeDouble(lots,2);
   double stepvol=m_symbol.LotsStep();
   if(stepvol>0.0)
      volume=stepvol*MathFloor(volume/stepvol);
//---
   double minvol=m_symbol.LotsMin();
   if(volume<minvol)
      volume=0.0;
//---
   double maxvol=m_symbol.LotsMax();
   if(volume>maxvol)
      volume=maxvol;
   return(volume);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp,double lot,string comment)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=lot)
        {
         if(m_trade.Buy(lot,m_symbol.Name(),m_symbol.Ask(),sl,tp,comment))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print(__FUNCTION__,", #1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print(__FUNCTION__,", #2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< Lot (",DoubleToString(lot,2),")");
         return;
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl,double tp,double lot,string comment)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=lot)
        {
         if(m_trade.Sell(lot,m_symbol.Name(),m_symbol.Bid(),sl,tp,comment))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print(__FUNCTION__,", #1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
            else
              {
               Print(__FUNCTION__,", #2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResult(m_trade,m_symbol);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResult(m_trade,m_symbol);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< Lot (",DoubleToString(lot,2),")");
         return;
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return;
     }
//---
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResult(CTrade &trade,CSymbolInfo &symbol)
  {
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result: "+trade.ResultRetcodeDescription());
   Print("deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("current bid price: "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("current ask price: "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("broker comment: "+trade.ResultComment());
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates(void)
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
     {
      Print("RefreshRates error");
      return(false);
     }
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Check the correctness of the position volume                     |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=m_symbol.LotsMin();
   if(volume<min_volume)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем меньше минимально допустимого SYMBOL_VOLUME_MIN=%.2f",min_volume);
      else
         error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }
//--- maximal allowed volume of trade operations
   double max_volume=m_symbol.LotsMax();
   if(volume>max_volume)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем больше максимально допустимого SYMBOL_VOLUME_MAX=%.2f",max_volume);
      else
         error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }
//--- get minimal step of volume changing
   double volume_step=m_symbol.LotsStep();
   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      if(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")
         error_description=StringFormat("Объем не кратен минимальному шагу SYMBOL_VOLUME_STEP=%.2f, ближайший правильный объем %.2f",
                                        volume_step,ratio*volume_step);
      else
         error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                        volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
   return(true);
  }
//+------------------------------------------------------------------+

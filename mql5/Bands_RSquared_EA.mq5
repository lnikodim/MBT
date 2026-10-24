//+------------------------------------------------------------------+
//|                                                        Bands.mq5 |
//|                                                  Andrei Korolkov |
//+------------------------------------------------------------------+
#property copyright "Andrei Korolkov"
#property link      ""
#property version   "1.00"

#include <Trade\Trade.mqh>

CTrade          trade;

input ulong    Magic       = 123; // Магик ордера
input double   Lots        = 0.1; // Объем сделки
input int      BPeriod     = 100; // Период для Bollinger Bands
input double   BDeviation  = 1;   // Отклонение для Bollinger Bands
input int      DonchPeriod = 100; // Период для Donchian Chanel
input int      CPeriod     = 100; // Период для проверки тренда (Max и Min цен растут либо падают на этом периоде)
input int      AtrPeriod   = 21;  // Период для ATR
input double   Stop        = 4;   // Стоплосс в ATR
input double   Take        = 4;   // Тейкпрофит в ATR
input ulong    Slippage    = 30;  // Проскальзывание в пунктах

int _donch, _atr, _bb;
int zone;

double donch_up[], donch_down[], bb_up[], bb_down[], atr[], equity_values[];

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
      zone = CPeriod;
      trade.SetExpertMagicNumber(Magic);
      trade.SetDeviationInPoints(Slippage);
      
      _atr = iATR(_Symbol, PERIOD_CURRENT, AtrPeriod);
      if (_atr == INVALID_HANDLE)
      {
            Print("Не удалось получить хэндл ATR");
            return(INIT_FAILED);
      }
      _bb = iBands(_Symbol, PERIOD_CURRENT, BPeriod, 0, BDeviation, PRICE_CLOSE);
      if (_bb == INVALID_HANDLE)
      {
            Print("Не удалось получить хэндл Bollinger Bands");
      }
      _donch = iCustom(_Symbol, PERIOD_CURRENT, "\\Indicators\\Free Indicators\\Donchian Channel", DonchPeriod, false);
      if (_donch == INVALID_HANDLE)
      {
            Print("Не удалось получить хэндл Donchian Chanel");
            return(INIT_FAILED);
      }
      return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
      if (_atr != INVALID_HANDLE)
         IndicatorRelease(_atr);
      if (_bb != INVALID_HANDLE)
         IndicatorRelease(_bb);
      if (_donch != INVALID_HANDLE)
         IndicatorRelease(_donch);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
      static datetime ltime = WRONG_VALUE;
             datetime ctime = iTime(_Symbol, PERIOD_CURRENT, 0);
      if (ctime == ltime) return;
      ltime = ctime;
      if (CopyBuffer(_atr, MAIN_LINE, 0, zone + 10, atr) != zone + 10)
      {
            Print("Не удалось скопировать хэндл ATR");
            return;
      }
      if (CopyBuffer(_donch, BASE_LINE, 0, zone + 10, donch_up) != zone + 10)
      {
            Print("Не удалось скопировать хэндл Donchian Channel UP");
            return;
      }
      if (CopyBuffer(_donch, LOWER_BAND, 0, zone + 10, donch_down) != zone + 10)
      {
            Print("Не удалось скопировать хэндл Donchian Channel DOWN");
            return;
      }
      if (CopyBuffer(_bb, LOWER_BAND, 0, zone + 10, bb_down) != zone + 10)
      {
            Print("Не удалось сопировать хэндл Bollinger Bands Down");
            return;
      }
      if (CopyBuffer(_bb, UPPER_BAND, 0, zone + 10, bb_up) != zone + 10)
      {
            Print("Не удалось сопировать хэндл Bollinger Bands UP");
            return;
      }
            
      ArraySetAsSeries(atr, true);
      ArraySetAsSeries(donch_up, true);
      ArraySetAsSeries(donch_down, true);
      ArraySetAsSeries(bb_down, true);
      ArraySetAsSeries(bb_up, true);
      
      if (PositionsTotal() == 0 && iOpen(_Symbol, PERIOD_CURRENT, 1) < bb_down[1] && iClose(_Symbol, PERIOD_CURRENT, 1) > bb_down[1])
      {
            int count = 0;
            for (int i = 0; i <= zone; i++)
            {
                  if (donch_down[i] >= donch_down[i + 1])
                        count++;
            }
            if (count > zone)
            {
                  Print("Получен сигнал на покупку");
                  if (CheckMoneyForTrade(_Symbol, GetLot(), ORDER_TYPE_BUY))
                  {
                        double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
                        double SL  = NormalizeDouble(Ask - atr[1] * Stop, _Digits);
                        double TP  = NormalizeDouble(Ask + atr[1] * Take, _Digits);
                        if (CheckSLTP(ORDER_TYPE_BUY, SL, TP))
                        {
                              if (!trade.Buy(GetLot(), _Symbol, Ask, SL, TP))
                                    Print("Не удалось открыть позицию BUY");
                              else
                              {
                                     // Получаем текущее значение эквити
                                     double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
                                     
                                     // Добавляем в массив
                                     int size = ArraySize(equity_values);
                                     ArrayResize(equity_values, size + 1);
                                     equity_values[size] = current_equity;
                                     
                                     // Периодически рассчитываем R-квадрат
                                     if(size % 100 == 0 && size > 0)
                                     {
                                         double r_squared = CalculateRSquared(equity_values);
                                         Print("R-квадрат эквити: ", r_squared);
                                     }
                              }
                        }
                  }
            }
      }
      if (PositionsTotal() == 0 && iOpen(_Symbol, PERIOD_CURRENT, 1) > bb_up[1] && iClose(_Symbol, PERIOD_CURRENT, 1) < bb_up[1])
      {
            int count = 0;
            for (int i = 0; i <= zone; i++)
            {
                  if (donch_up[i] <= donch_up[i + 1])
                        count++;
            }
            if (count > zone)
            {
                  Print("Получен сигнал на продажу");
                  if (CheckMoneyForTrade(_Symbol, GetLot(), ORDER_TYPE_SELL))
                  {
                        double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
                        double SL  = NormalizeDouble(Bid + atr[1] * Stop, _Digits);
                        double TP  = NormalizeDouble(Bid - atr[1] * Take, _Digits);
                        if (CheckSLTP(ORDER_TYPE_SELL, SL, TP))
                        {
                              if (!trade.Sell(GetLot(), _Symbol, Bid, SL, TP))
                                    Print("Не удалось открыть позицию SELL");
                              else
                              {
                                     // Получаем текущее значение эквити
                                     double current_equity = AccountInfoDouble(ACCOUNT_EQUITY);
                                     
                                     // Добавляем в массив
                                     int size = ArraySize(equity_values);
                                     ArrayResize(equity_values, size + 1);
                                     equity_values[size] = current_equity;
                                     
                                     // Периодически рассчитываем R-квадрат
                                     if(size % 100 == 0 && size > 0)
                                     {
                                         double r_squared = CalculateRSquared(equity_values);
                                         Print("R-квадрат эквити: ", r_squared);
                                     }
                              }
                        }
                  }
            }
      }
      if (PositionSelect(_Symbol))
      {
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY)
            {
                  if (iClose(_Symbol, PERIOD_CURRENT, 1) > donch_up[1] || iClose(_Symbol, PERIOD_CURRENT, 1) < donch_down[1])
                  {
                        if (trade.PositionClose(_Symbol, 20))
                            Print("Позиция на покупку закрыта");
                  }
            }
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL)
            {
                  if (iClose(_Symbol, PERIOD_CURRENT, 1) < donch_down[1] || iClose(_Symbol, PERIOD_CURRENT, 1) > donch_up[1])
                        if (trade.PositionClose(_Symbol, 20))
                            Print("Позиция на покупку закрыта");
            }
      }
}
//+------------------------------------------------------------------+
double GetLot()
{
      double     lot   = Lots;
      datetime   tim   = 0;
      ulong      tick  = 0;
      double min_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN); 
      double max_volume = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      if(lot < min_volume) lot = min_volume;
      if(lot > max_volume) lot = max_volume;
      return(lot);
}
//+------------------------------------------------------------------+
bool CheckMoneyForTrade(string symb,double lots,ENUM_ORDER_TYPE type)
{
      MqlTick mqltick;
      SymbolInfoTick(symb,mqltick);
      double price=mqltick.ask;
      if(type==ORDER_TYPE_SELL)
         price=mqltick.bid;
      double margin,free_margin=AccountInfoDouble(ACCOUNT_MARGIN_FREE);
      if(!OrderCalcMargin(type,symb,lots,price,margin))
      {
            Print("Error in ",__FUNCTION__," code=",GetLastError());
            return(false);
      }
      if(margin>free_margin)
      {
            Print("Not enough money for ",EnumToString(type)," ",lots," ",symb," Error code=",GetLastError());
            return(false);
      }
      return(true);
}
//+------------------------------------------------------------------+
bool CheckSLTP(ENUM_ORDER_TYPE type,double SL,double TP)
{
      double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
//--- получим уровень SYMBOL_TRADE_STOPS_LEVEL
      int stops_level = (int)SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
      if (stops_level != 0)
      {
            PrintFormat("SYMBOL_TRADE_STOPS_LEVEL=%d: StopLoss и TakeProfit должны быть"+
                        " не ближе %d пунктов от цены закрытия",stops_level,stops_level);
      }
//---
      bool SL_check = false, TP_check = false;
//--- проверяем только два типа ордеров
      switch(type)
     {
      //--- операция покупка
      case  ORDER_TYPE_BUY:
        {
         //--- проверим StopLoss
         SL_check = (Bid -SL>stops_level*_Point);
         if(!SL_check)
            PrintFormat("For order %s StopLoss=%.5f must be less than %.5f"+
                        " (Bid=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d пунктов)",
                        EnumToString(type),SL,Bid-stops_level*_Point,Bid,stops_level);
         //--- проверим TakeProfit
         TP_check=(TP-Bid>stops_level*_Point);
         if(!TP_check)
            PrintFormat("For order %s TakeProfit=%.5f must be greater than %.5f"+
                        " (Bid=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d пунктов)",
                        EnumToString(type),TP,Bid+stops_level*_Point,Bid,stops_level);
         //--- вернем результат проверки
         return(SL_check&&TP_check);
        }
      //--- операция продажа
      case  ORDER_TYPE_SELL:
        {
         //--- проверим StopLoss
         SL_check=(SL-Ask>stops_level*_Point);
         if(!SL_check)
            PrintFormat("For order %s StopLoss=%.5f must be greater than %.5f "+
                        " (Ask=%.5f + SYMBOL_TRADE_STOPS_LEVEL=%d пунктов)",
                        EnumToString(type),SL,Ask+stops_level*_Point,Ask,stops_level);
         //--- проверим TakeProfit
         TP_check=(Ask-TP>stops_level*_Point);
         if(!TP_check)
            PrintFormat("For order %s TakeProfit=%.5f must be less than %.5f "+
                        " (Ask=%.5f - SYMBOL_TRADE_STOPS_LEVEL=%d пунктов)",
                        EnumToString(type),TP,Ask-stops_level*_Point,Ask,stops_level);
         //--- вернем результат проверки
         return(TP_check&&SL_check);
        }
      break;
     }
//--- для отложенных ордеров нужна немного другая функция
   return false;
}
//+------------------------------------------------------------------+
double CalculateRSquared(const double &equity_array[])
{
    int size = ArraySize(equity_array);
    if(size <= 1) return 0.0; // Недостаточно данных
    
    // Рассчитываем линейную регрессию (y = a + b*x)
    double sum_x = 0.0, sum_y = 0.0, sum_xy = 0.0, sum_x2 = 0.0;
    
    for(int i = 0; i < size; i++)
    {
        sum_x += i;
        sum_y += equity_array[i];
        sum_xy += i * equity_array[i];
        sum_x2 += i * i;
    }
    
    double x_mean = sum_x / size;
    double y_mean = sum_y / size;
    
    double b = (sum_xy - sum_x * y_mean) / (sum_x2 - sum_x * x_mean); // Коэффициент наклона
    double a = y_mean - b * x_mean;
    // Рассчитываем SS_total и SS_residual
    double ss_total = 0.0;
    double ss_residual = 0.0;
    
    for(int i = 0; i < size; i++)
    {
        double y_actual = equity_array[i];
        double y_predicted = a + b * i;
        
        ss_total += MathPow(y_actual - y_mean, 2);
        ss_residual += MathPow(y_actual - y_predicted, 2);
    }
    
    // Избегаем деления на ноль
    if(ss_total == 0.0) return 1.0;
    
    // Базовый R² (0..1)
    double r_squared = 1.0 - (ss_residual / ss_total);
    
    // Учитываем направление тренда (если наклон отрицательный, R² становится отрицательным)
    if(b < 0) 
        r_squared = -r_squared;
    
    return r_squared;
}
double OnTester()
{
      double r_squared = CalculateRSquared(equity_values);
      return(r_squared);
}
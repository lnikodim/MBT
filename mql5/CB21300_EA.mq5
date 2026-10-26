//+------------------------------------------------------------------+
//|   Bollinger Band Two MA and Zig-Zag(barabashkakvn's edition).mq5 |
//+------------------------------------------------------------------+
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
//--- input parameters
input string               rem2                 = "=== Количество лотов ===";
input double               Inp_Lots0_1          =          0.1;   // Базовый уровень 1-й позиции
input double               Inp_Lots0_2          =          0.1;   // Базовый уровень 2-й позиции
                                                                  //
input string               rem3                 = "=== Дополнительные параметры ===";
input int                  Inp_TakeProfit1_Proc =           50;   // Процент риска для тейк-профита 1-й позиции
input int                  Inp_SpaseFromMaxMin  =           10;   // Отступ от Вершины/Дна
                                                                  //
input string               rem4                 = "=== Параметры безубытка ===";
input bool                 Inp_IsStopLoss_0     =         true;   // Включение использования уровня безубытка
input int                  Inp_StopLoss_0_From  =           80;   // Отступ от уровеня безубытка (в пунктах)
input int                  Inp_StopLoss_0_Level =           10;   // Уровень безубытка
                                                                  //
input string               rem5                 = "=== Параметры трейлинг стопа ===";
input ushort               Inp_TrailingStop     =           80;   // Уровень трейлинг стопа
input ushort               Inp_TrailingStep     =          120;   // Шаг перемещения трейлинг стопа
                                                                  //
input string               rem6                 = "=== Настройки инструмента ===";
input string               Inp_Symbol           =            "";  // Символьное имя инструмента: "" - текущий символ
input ENUM_TIMEFRAMES      Inp_Timeframe        =PERIOD_CURRENT;  // Таймфрейм
input ulong                Inp_Slippage         =             2;  // Проскальзывание
input ulong                Inp_Magic1           =          1281;  // Уникальный идентификатор 1-й позиции
input ulong                Inp_Magic2           =          1282;  // Уникальный идентификатор 2-й позиции
                                                                  //
input string               rem7                 = "=== Параметры индикатора MA1 ===";
input ENUM_TIMEFRAMES      Inp_MA1_Timeframe    =     PERIOD_D1;  // Таймфрейм
input int                  Inp_MA1_Period       =            20;  // Период усреднения для вычисления скользящего среднего
input int                  Inp_MA1_Shift        =             0;  // Сдвиг индикатора относительно ценового графика
input ENUM_MA_METHOD       Inp_MA1_Method       =      MODE_SMA;  // Метод усреднения 
input ENUM_APPLIED_PRICE   Inp_MA1_Applied_Price=   PRICE_CLOSE;  // Используемая цена
                                                                  //
input string               rem8                 = "=== Параметры индикатора MA2 ===";
input ENUM_TIMEFRAMES      Inp_MA2_Timeframe    =     PERIOD_H4;  // Таймфрейм
input int                  Inp_MA2_Period       =            20;  // Период усреднения для вычисления скользящего среднего
input int                  Inp_MA2_Shift        =             0;  // Сдвиг индикатора относительно ценового графика
input ENUM_MA_METHOD       Inp_MA2_Method       =      MODE_SMA;  // Метод усреднения 
input ENUM_APPLIED_PRICE   Inp_MA2_Applied_Price=   PRICE_CLOSE;  // Используемая цена
                                                                  //
input string               rem9                 = "=== Параметры индикатора Bollinger Bands ===";
input int                  Inp_BB_Period        =            20;  // Период усреднения основной линии индикатора
input int                  Inp_BB_Deviation     =             2;  // Отклонение от основной линии
input int                  Inp_BB_Bands_Shift   =             0;  // Сдвиг индикатора относительно ценового графика
input ENUM_APPLIED_PRICE   Inp_BB_Applied_Price =   PRICE_CLOSE;  // Используемая цена
                                                                  //
input string               rem10                = "=== Параметры индикатора ZigZag ===";
input int                  Inp_ZZ_ExtDepth      =            12;  // Depth 
input int                  Inp_ZZ_Deviation     =             5;  // Deviation
input int                  Inp_ZZ_Backstep      =             3;  // Backstep 
                                                                  //
datetime time_previous;
datetime time_current;
//
string fstr;
int    _tp;

int    handle_iMA1;                          // variable for storing the handle of the iMA indicator
int    handle_iMA2;                          // variable for storing the handle of the iMA indicator
int    handle_iBands;                        // variable for storing the handle of the iBands indicator 
int    handle_iCustom;                       // variable for storing the handle of the iCustom indicator 
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   string symbol=(Inp_Symbol=="")?Symbol():Inp_Symbol;
   if(!m_symbol.Name(symbol)) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();

   string err_text="";
   if(!CheckVolumeValue(Inp_Lots0_1,err_text))
     {
      Print(__FUNCTION__,", ERROR: ",err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
   err_text="";
   if(!CheckVolumeValue(Inp_Lots0_2,err_text))
     {
      Print(__FUNCTION__,", ERROR: ",err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
   m_trade.SetDeviationInPoints(Inp_Slippage);
//--- create handle of the indicator iMA
   handle_iMA1=iMA(m_symbol.Name(),Inp_MA1_Timeframe,Inp_MA1_Period,Inp_MA1_Shift,Inp_MA1_Method,Inp_MA1_Applied_Price);
//--- if the handle is not created 
   if(handle_iMA1==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Inp_MA1_Timeframe),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iMA
   handle_iMA2=iMA(m_symbol.Name(),Inp_MA2_Timeframe,Inp_MA2_Period,Inp_MA2_Shift,Inp_MA2_Method,Inp_MA2_Applied_Price);
//--- if the handle is not created 
   if(handle_iMA2==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iMA indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Inp_MA2_Timeframe),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iBands
   handle_iBands=iBands(m_symbol.Name(),Inp_Timeframe,Inp_BB_Period,Inp_BB_Bands_Shift,Inp_BB_Deviation,Inp_BB_Applied_Price);
//--- if the handle is not created 
   if(handle_iBands==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iBands indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Inp_Timeframe),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iCustom
   handle_iCustom=iCustom(m_symbol.Name(),Period(),"Examples\\ZigZag",Inp_ZZ_ExtDepth,Inp_ZZ_Deviation,Inp_ZZ_Backstep);
//--- if the handle is not created 
   if(handle_iCustom==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iCustom indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//---
   Print(" -> init() >> Таймфрейм ",(Inp_Timeframe==PERIOD_CURRENT)?EnumToString(Period()):EnumToString(Inp_Timeframe),
         ", \"Включение использования уровня безубытка\" ",Inp_IsStopLoss_0);
//---
   fstr="Bollinger Band Two MA and Zig-Zag";
   _tp=(int)_FileReadWriteDouble(fstr+"tp.dat",0); // убедиться в наличии файла, если его нет - создать
   Print("Bollinger Band Two MA and Zig-Zag > init() >> Таймфрейм ",(Inp_Timeframe==PERIOD_CURRENT)?EnumToString(Period()):EnumToString(Inp_Timeframe),", tp=",_tp);
//---
   time_previous=iTime(m_symbol.Name(),Inp_Timeframe,0);
//---
   Print(" -> Завершено: init() >> time_previous ",time_previous," (",TimeToString(time_previous,TIME_DATE|TIME_MINUTES),")");
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
//---
   double P_Close1,P_Close2;
   double BB_1_upper,BB_1_lower;
   double MA1_0,MA2_0;
   double P_ask,P_bid;
   bool is_signal_2_buy=false,is_signal_2_sell=false;
   double P1_buy,P2_buy,P3_buy;
   double P1_sell,P2_sell,P3_sell;
   bool is_b1 = false, is_s1 = false;
   bool is_b2 = false, is_s2 = false;
//---
   time_current=iTime(m_symbol.Name(),Inp_Timeframe,0);
   if(time_current!=time_previous)
     {
      if(!RefreshRates())
         return;
      MA1_0       = iMAGet(handle_iMA1,0);
      MA2_0       = iMAGet(handle_iMA2,0);
      BB_1_upper  = iBandsGet(UPPER_BAND,1);
      BB_1_lower  = iBandsGet(LOWER_BAND,1);
      P_Close1    = iClose(m_symbol.Name(),Inp_Timeframe,1);
      P_Close2    = iClose(m_symbol.Name(),Inp_Timeframe,2);
      P_ask       = m_symbol.Ask();
      P_bid       = m_symbol.Bid();
      Print(" -> ",m_symbol.Name()," | ",(Inp_Timeframe==PERIOD_CURRENT)?EnumToString(Period()):EnumToString(Inp_Timeframe),
            " -> MA1_0=",DoubleToString(MA1_0,m_symbol.Digits()+1)," | MA2_0=",DoubleToString(MA2_0,m_symbol.Digits()+1),
            " -> BB_1_upper=",DoubleToString(BB_1_upper,m_symbol.Digits()+1)," | BB_1_lower=",DoubleToString(BB_1_lower,m_symbol.Digits()+1),
            " -> P_Close1=",DoubleToString(P_Close1,m_symbol.Digits())," | P_Close2=",DoubleToString(P_Close2,m_symbol.Digits()),
            " -> ask=",DoubleToString(P_ask,m_symbol.Digits())," | bid=",DoubleToString(P_bid,m_symbol.Digits()));
      //---
      is_signal_2_buy  = P_bid >= MA1_0 && P_bid >= MA2_0 && P_Close1 >= BB_1_lower && P_Close2 <= BB_1_lower && P_bid >= BB_1_lower;
      is_signal_2_sell = P_bid <= MA1_0 && P_bid <= MA2_0 && P_Close1 <= BB_1_upper && P_Close2 >= BB_1_upper && P_bid <= BB_1_upper;
      Print("--> ",m_symbol.Name()," | ",(Inp_Timeframe==PERIOD_CURRENT)?EnumToString(Period()):EnumToString(Inp_Timeframe),
            " -> is_signal2 -> buy ",is_signal_2_buy," | sell ",is_signal_2_sell);
      //--- по рынку
      //--- открытие BUY
      if(is_signal_2_buy)
        {
         Print("--> ",m_symbol.Name()," | ",(Inp_Timeframe==PERIOD_CURRENT)?EnumToString(Period()):EnumToString(Inp_Timeframe),
               " -> сигнал на открытие BUY");
         ClosePositions(POSITION_TYPE_SELL);
         //---
         if(!is_b1 || !is_b2)
           {
            P1_buy   = P_ask;
            P3_buy   = FindPriceMinMax(false)-Inp_SpaseFromMaxMin*m_symbol.Point();
            _tp      = (int)((P1_buy-P3_buy)/m_symbol.Point() *(Inp_TakeProfit1_Proc/100.0));
            P2_buy   = DoubleTestZero(_tp,P1_buy+_tp*m_symbol.Point());
            //---
            _FileWriteDouble(fstr+"tp.dat",_tp);
            //---
            Print("--> ",m_symbol.Name()," | ",(Inp_Timeframe==PERIOD_CURRENT)?EnumToString(Period()):EnumToString(Inp_Timeframe),
                  " -> BUY -> P1_buy=",DoubleToString(P1_buy,m_symbol.Digits()),
                  " | P2_buy=",DoubleToString(P2_buy,m_symbol.Digits()),
                  " | P3_buy=",DoubleToString(P3_buy,m_symbol.Digits()),
                  " | tp=",_tp);
            //---
            m_trade.SetExpertMagicNumber(Inp_Magic1);
            if(!OpenBuy(Inp_Lots0_1,P3_buy,P2_buy))
               Print("--> ",m_symbol.Name()," | ",(Inp_Timeframe==PERIOD_CURRENT)?EnumToString(Period()):EnumToString(Inp_Timeframe),
                     " -> BUY (1) > Ошибка (открытие)");
            else
               is_b1=true;
            //---
            m_trade.SetExpertMagicNumber(Inp_Magic2);
            if(!OpenBuy(Inp_Lots0_2,P3_buy,0.0))
               Print("--> ",m_symbol.Name()," | ",(Inp_Timeframe==PERIOD_CURRENT)?EnumToString(Period()):EnumToString(Inp_Timeframe),
                     " -> BUY (2) > Ошибка (открытие)");
            else
               is_b2=true;
           }
         else
           {
            is_b1=true;
            is_b2=true;
           }
        }
      else
        {
         is_b1=true;
         is_b2=true;
        }
      //--- открытие SELL
      if(is_signal_2_sell)
        {
         Print("--> ",m_symbol.Name()," | ",(Inp_Timeframe==PERIOD_CURRENT)?EnumToString(Period()):EnumToString(Inp_Timeframe),
               " -> сигнал на открытие SELL");
         ClosePositions(POSITION_TYPE_BUY);
         //
         if(!is_s1 || !is_s2)
           {
            P1_sell  = P_bid;
            P3_sell  = FindPriceMinMax(true)+Inp_SpaseFromMaxMin*m_symbol.Point();
            _tp      = (int)((P3_sell-P1_sell)/m_symbol.Point() *(Inp_TakeProfit1_Proc/100.0));
            P2_sell  = DoubleTestZero(_tp,P1_sell-_tp*m_symbol.Point());
            //---
            _FileWriteDouble(fstr+"tp.dat",_tp);
            //---
            Print("--> ",m_symbol.Name()," | ",(Inp_Timeframe==PERIOD_CURRENT)?EnumToString(Period()):EnumToString(Inp_Timeframe),
                  " -> BUY -> P1_sell=",DoubleToString(P1_sell,m_symbol.Digits()),
                  " | P2_sell=",DoubleToString(P2_sell,m_symbol.Digits()),
                  " | P3_sell=",DoubleToString(P3_sell,m_symbol.Digits()));
            //---
            m_trade.SetExpertMagicNumber(Inp_Magic1);
            if(!OpenSell(Inp_Lots0_1,P3_sell,P2_sell))
               Print("--> ",m_symbol.Name()," | ",(Inp_Timeframe==PERIOD_CURRENT)?EnumToString(Period()):EnumToString(Inp_Timeframe),
                     " -> SELL (1) > Ошибка (открытие)");
            else
               is_s1=true;
            //---
            m_trade.SetExpertMagicNumber(Inp_Magic2);
            if(!OpenSell(Inp_Lots0_2,P3_sell,0.0))
               Print("--> ",m_symbol.Name()," | ",(Inp_Timeframe==PERIOD_CURRENT)?EnumToString(Period()):EnumToString(Inp_Timeframe),
                     " -> SELL (2) > Ошибка (открытие) ");
            else
               is_s2=true;
           }
         else
           {
            is_s1=true;
            is_s2=true;
           }
        }
      else
        {
         is_s1=true;
         is_s2=true;
        }
      //---
      if(is_b1 && is_s1 && is_b2 && is_s2)
         time_previous=time_current;
     }
//---
   TrailingStop(_tp);

//---
   if(Inp_IsStopLoss_0)
      StopLoss_0(Inp_StopLoss_0_From);
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
//| Cчитать переменную из файла.                                     |
//|  В случае отсутствия файла - создать файл                        |
//|  и записать переменную в файл                                    |
//+------------------------------------------------------------------+
double _FileReadWriteDouble(string filename,double value)
  {
   int h1=FileOpen(filename,FILE_BIN);
   if(h1>0)
     {
      value=FileReadDouble(h1);
      FileClose(h1);
     }
   else
     {
      h1=FileOpen(filename,FILE_BIN|FILE_WRITE);
      FileWriteDouble(h1,value);
      FileClose(h1);
     }
   return(value);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iMA                                 |
//+------------------------------------------------------------------+
double iMAGet(const int handle_iMA,const int index)
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
//| Get value of buffers for the iBands                              |
//|  the buffer numbers are the following:                           |
//|   0 - BASE_LINE, 1 - UPPER_BAND, 2 - LOWER_BAND                  |
//+------------------------------------------------------------------+
double iBandsGet(const int buffer,const int index)
  {
   double Bands[1];
//ArraySetAsSeries(Bands,true);
//--- reset error code 
   ResetLastError();
//--- fill a part of the iBands array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iBands,buffer,index,1,Bands)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iBands indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Bands[0]);
  }
//+------------------------------------------------------------------+
//| Get value of buffers for the iCustom                             |
//|  the buffer numbers are the following:                           |
//+------------------------------------------------------------------+
double iCustomGet(const int buffer,const int index)
  {
   double Custom[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iCustom array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iCustom,buffer,index,1,Custom)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iCustom indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Custom[0]);
  }
//+------------------------------------------------------------------+
//| Close positions                                                  |
//+------------------------------------------------------------------+
void ClosePositions(const ENUM_POSITION_TYPE pos_type)
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && (m_position.Magic()==Inp_Magic1 || m_position.Magic()==Inp_Magic1))
            if(m_position.PositionType()==pos_type) // gets the position type
               m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+
//|Поиск локального дна. Возвращает цену                             |
//+------------------------------------------------------------------+
double FindPriceMinMax(bool isUp)
  {
   int shift=1;
   double price= 0,p0,p1,p2;
   while(price == 0)
     {
      p0 = iCustomGet(0,shift);
      p1 = iCustomGet(1,shift);
      p2 = iCustomGet(2,shift);
      if(isUp)
        {
         if(p0!=0 && p0==p1) // найдена вершина
            price=p0;
        }
      else
        {
         if(p0!=0 && p0==p2) // найдено дно
            price=p0;
        }
      shift++;
     }
//---
   return(price);
  }
//+------------------------------------------------------------------+
//| Записать переменную в файл                                       |
//+------------------------------------------------------------------+
void _FileWriteDouble(string filename,double value)
  {
   int h1=FileOpen(filename,FILE_BIN|FILE_WRITE);
   FileWriteDouble(h1,value);
   FileClose(h1);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
bool OpenBuy(const double lot,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=lot)
        {
         if(m_trade.Buy(lot,m_symbol.Name(),m_symbol.Ask(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print(__FUNCTION__,", #1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
               return(false);
              }
            else
              {
               Print(__FUNCTION__,", #2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
               return(true);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
            return(false);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< lot (",DoubleToString(lot,2),")");
         return(false);;
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return(false);;
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
bool OpenSell(const double lot,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=lot)
        {
         if(m_trade.Sell(lot,m_symbol.Name(),m_symbol.Bid(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print(__FUNCTION__,", #1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
               return(false);
              }
            else
              {
               Print(__FUNCTION__,", #2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
               PrintResultTrade(m_trade,m_symbol);
               return(true);
              }
           }
         else
           {
            Print(__FUNCTION__,", #3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
            PrintResultTrade(m_trade,m_symbol);
            return(false);
           }
        }
      else
        {
         Print(__FUNCTION__,", ERROR: method CheckVolume (",DoubleToString(check_volume_lot,2),") ",
               "< lot (",DoubleToString(lot,2),")");
         return(false);;
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return(false);;
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double DoubleTestZero(double value,double new_value)
  {
   if(value==0)
      return(value);
   else
      return(new_value);
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultTrade(CTrade &trade,CSymbolInfo &symbol)
  {
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result as a string: "+trade.ResultRetcodeDescription());
   Print("Deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("Order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("Volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("Price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("Current bid price: "+DoubleToString(symbol.Bid(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("Current ask price: "+DoubleToString(symbol.Ask(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("Broker comment: "+trade.ResultComment());
  }
//+------------------------------------------------------------------+
//| Отработка уровня безубытка                                       |
//+------------------------------------------------------------------+
void StopLoss_0(int from)
  {
   double profitpoint=0.0;
   bool   is=false;
   double P3_buy=0.0,P3_sell=0.0;
//---
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && (m_position.Magic()==Inp_Magic1 || m_position.Magic()==Inp_Magic2))
           {
            if(!RefreshRates())
               continue;
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               //bid=m_position.PriceCurrent();
               profitpoint=(m_position.PriceCurrent()-m_position.PriceOpen())/m_symbol.Point();
               is=profitpoint>=Inp_StopLoss_0_Level+from;
               P3_buy=m_position.PriceOpen()+from*m_symbol.Point();
               //---
               if(is && (m_position.StopLoss()==0.0 || m_position.StopLoss()<P3_buy))
                 {
                  m_trade.SetExpertMagicNumber(m_position.Magic());
                  m_trade.PositionModify(m_position.Ticket(),m_symbol.NormalizePrice(P3_buy),m_position.TakeProfit());
                  m_position.SelectByIndex(i);
                  PrintResultModify(m_trade,m_symbol,m_position);
                 }
              }
            else
              {
               //ask         = MarketInfo(_Symbol, MODE_ASK);
               profitpoint=(m_position.PriceOpen()-m_position.PriceCurrent())/m_symbol.Point();
               is=profitpoint>=Inp_StopLoss_0_Level+from;
               P3_sell=m_position.PriceOpen()-from*m_symbol.Point();
               //---
               if(is && (m_position.StopLoss()==0.0 || m_position.StopLoss()>P3_sell))
                 {
                  m_trade.SetExpertMagicNumber(m_position.Magic());
                  m_trade.PositionModify(m_position.Ticket(),m_symbol.NormalizePrice(P3_sell),m_position.TakeProfit());
                  m_position.SelectByIndex(i);
                  PrintResultModify(m_trade,m_symbol,m_position);
                 }
              }
           }
//---
  }
//+------------------------------------------------------------------+
//| Отработка трейлинг стопа                                         |
//+------------------------------------------------------------------+
void TrailingStop(int from)
  {
   if(Inp_TrailingStop==0)
      return;
   double profitpoint=0.0;
   double fromprice=0.0;
//---
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && (m_position.Magic()==Inp_Magic1 || m_position.Magic()==Inp_Magic2))
           {
            if(!RefreshRates())
               continue;
            fromprice=m_position.StopLoss();
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               profitpoint=(m_position.PriceCurrent()-fromprice)/m_symbol.Point();
               //---
               if(profitpoint>=Inp_TrailingStop && 
                  m_position.PriceCurrent()>(m_position.StopLoss()+(Inp_TrailingStop+Inp_TrailingStep)*m_symbol.Point()))
                 {
                  m_trade.SetExpertMagicNumber(m_position.Magic());
                  m_trade.PositionModify(m_position.Ticket(),
                                         m_symbol.NormalizePrice(m_position.PriceCurrent() -(Inp_TrailingStop)*m_symbol.Point()),
                                         m_position.TakeProfit());
                  m_position.SelectByIndex(i);
                  PrintResultModify(m_trade,m_symbol,m_position);
                 }
              }
            else
              {
               profitpoint=(fromprice-m_position.PriceCurrent())/m_symbol.Point();
               //
               if(profitpoint>=Inp_TrailingStop && 
                  m_position.PriceCurrent()<(m_position.StopLoss() -(Inp_TrailingStop+Inp_TrailingStep)*m_symbol.Point()))
                 {
                  m_trade.SetExpertMagicNumber(m_position.Magic());
                  m_trade.PositionModify(m_position.Ticket(),
                                         m_symbol.NormalizePrice(m_position.PriceCurrent()+(Inp_TrailingStop)*m_symbol.Point()),
                                         m_position.TakeProfit());
                  m_position.SelectByIndex(i);
                  PrintResultModify(m_trade,m_symbol,m_position);
                 }
              }

           }
//---
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultModify(CTrade &trade,CSymbolInfo &symbol,CPositionInfo &position)
  {
   Print("Code of request result: "+IntegerToString(trade.ResultRetcode()));
   Print("code of request result as a string: "+trade.ResultRetcodeDescription());
   Print("Deal ticket: "+IntegerToString(trade.ResultDeal()));
   Print("Order ticket: "+IntegerToString(trade.ResultOrder()));
   Print("Volume of deal or order: "+DoubleToString(trade.ResultVolume(),2));
   Print("Price, confirmed by broker: "+DoubleToString(trade.ResultPrice(),symbol.Digits()));
   Print("Current bid price: "+DoubleToString(symbol.Bid(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultBid(),symbol.Digits()));
   Print("Current ask price: "+DoubleToString(symbol.Ask(),symbol.Digits())+" (the requote): "+DoubleToString(trade.ResultAsk(),symbol.Digits()));
   Print("Broker comment: "+trade.ResultComment());
   Print("Price of position opening: "+DoubleToString(position.PriceOpen(),symbol.Digits()));
   Print("Price of position's Stop Loss: "+DoubleToString(position.StopLoss(),symbol.Digits()));
   Print("Price of position's Take Profit: "+DoubleToString(position.TakeProfit(),symbol.Digits()));
   Print("Current price by position: "+DoubleToString(position.PriceCurrent(),symbol.Digits()));
  }
//+------------------------------------------------------------------+

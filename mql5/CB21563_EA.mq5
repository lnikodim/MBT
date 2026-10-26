//+------------------------------------------------------------------+
//|                      Market Capture(barabashkakvn's edition).mq5 |
//|                             Copyright © 2010, Trishkin Artyom A. |
//|                                           support@goldsuccess.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2010, Trishkin Artyom A."
#property link      "support@goldsuccess.ru"
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
//--- input parameters
input string P_Expert= "-- Experts Variables --";
input bool   TradeBuy=true;                                   // Торговля в Buy, true = разрешена, false = не разрешена
input bool   TradeSell=true;                                  // Торговля в Sell, true = разрешена, false = не разрешена
input bool   UseEquClose=true;                                // Использовать ли ф-цию закрытия по эквити true = да, false = нет
input bool   TrackLossEquity=true;                            // Использовать ли закрытие по эквити в просадке true = да, false = нет
input double   InpLots                    = 0.1;               // Lots
input ushort   InpTakeProfit              = 10;                // Take Profit (in pips)
input ushort   InpDistanceOpenPositions   = 10;                // Distance between positions (in pips)
input double PercentEquityForClose=5.0;                       // Процент прироста эквити для закрытия убыточных позиций
input double PercentLossEquityForClose=5.0;                   // Процент падения эквити для закрытия убыточных позиций
input int    NumberLossPoseForCloseEquUP=5;                   // Количество закрываемых убыточных позиций при увеличении эквити
input int    NumberLossPoseForCloseEquDN=5;                   // Количество закрываемых убыточных позиций при просадке эквити
//--- Параметры исполнения торговых приказов
input string P_Performanc="-- Parameters for Trades --";
input ulong    m_magic=9938165;           // magic number
//---
ulong          m_slippage=10;                // slippage
//---
int      Level_old,Level_new,TradeDirection;
int      NumberUpLevels=1;                                     // Количество уровней выше цены
int      NumberDnLevels=1;                                     // Количество уровней ниже цены
int      MassUpLen,MassDnLen;
string   Prefix,Exp_Name,NameGL_Equ,NameGL_Add,NameGL_Loss,PriceFirstSell;
color    clUP,clDN;
double   EquStart,EquAdd,EquClose,EquLoss,EquPercLoss;
double   CenterLevel,GL_CenterLevel;
double   m_adjusted_point;             // point value adjusted for 3 or 5 points
double   ExtTakeProfit=0;
double   ExtDistanceOpenPositions=0;

double   MassUpLev[];
double   MassDnLev[];
double   MassCtLev[1];
double   HighestLev;
double   LowestLev;
bool     CloseFact=true;
bool     FirstStart=true;
//--- Переменные для функций
bool   AllMessages,PrintEnable;
bool   gbDisabled=false;           // Флаг блокировки советника
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();

   string err_text="";
   if(!CheckVolumeValue(InpLots,err_text))
     {
      Print(__FUNCTION__,", ERROR: ",err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   m_trade.SetExpertMagicNumber(m_magic);
   m_trade.SetMarginMode();
   m_trade.SetTypeFillingBySymbol(m_symbol.Name());
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtTakeProfit           = InpTakeProfit            * m_adjusted_point;
   ExtDistanceOpenPositions= InpDistanceOpenPositions * m_adjusted_point;
//---
   Level_old=m_symbol.StopsLevel();             // Миним. дистаниция установки стопов
   if(Level_old==0)
      Level_old=(int)((m_symbol.Ask()-m_symbol.Bid())/Point()*3.0);
//---
   Exp_Name=MQLInfoString(MQL_PROGRAM_NAME);    // Имя эксперта
   Prefix=Exp_Name+"_M"+EnumToString(Period()); // Префикс для имён объектов
   NameGL_Equ=Prefix+"_GL_Equ";
   NameGL_Add=Prefix+"_GL_Add";
   NameGL_Loss=Prefix+"_GL_Loss";
   PriceFirstSell=Prefix+"_GL_PFSell";
   if(!GlobalVariableCheck(NameGL_Equ)) // Если нету глобальной переменной терминала с именем NameGL_Equ
     {
      EquStart=m_account.Equity();                                // Стартовый эквити = эквити
      EquAdd=NormalizeDouble(EquStart/100.0*PercentEquityForClose,m_symbol.Digits()); // Процент от средств, на который они должны увеличиться для закрытия
      EquPercLoss=NormalizeDouble(EquStart/100.0*PercentLossEquityForClose,m_symbol.Digits());// Процент средств, при падении на который закрыть уб. позы
      GlobalVariableSet(NameGL_Equ,EquStart);                  // Создадим глобальную переменную терминала и присвоим ей значение эквити
      GlobalVariableSet(NameGL_Add,EquAdd);
      GlobalVariableSet(NameGL_Loss,EquLoss);
     }
   else
     {
      EquStart=GlobalVariableGet(NameGL_Equ);      // Если переменная терминала уже есть, то стартовый эквити = значению этой переменной
      EquAdd=GlobalVariableGet(NameGL_Add);
      EquPercLoss=GlobalVariableGet(NameGL_Loss);
     }
   double p1=GlobalVariableGet(NameGL_Equ);
   double p2=GlobalVariableGet(NameGL_Add);
   double p3=GlobalVariableGet(NameGL_Loss);
   EquClose=NormalizeDouble(p1+p2,m_symbol.Digits());
   EquLoss=NormalizeDouble(p1-p3,m_symbol.Digits());
   if(PercentEquityForClose<=0)
     {
      Print(__FUNCTION__," ERROR Процент прироста эквити для закрытия убыточных позиций: ",PercentEquityForClose);
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(NumberLossPoseForCloseEquUP<=0)
     {
      Print(__FUNCTION__," ERROR Количество закрываемых убыточных позиций при увеличении эквити: ",NumberLossPoseForCloseEquUP);
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(NumberLossPoseForCloseEquDN<=0)
     {
      Print(__FUNCTION__," ERROR Количество закрываемых убыточных позиций при просадке эквити: ",NumberLossPoseForCloseEquUP);
      return(INIT_PARAMETERS_INCORRECT);
     }
   if(InpDistanceOpenPositions==0 || InpDistanceOpenPositions*m_adjusted_point<=Level_old*m_symbol.Point())
      ExtDistanceOpenPositions=(Level_old+1)*m_symbol.Point();
   if(InpTakeProfit*m_adjusted_point<=Level_old*m_symbol.Point())
      ExtTakeProfit=(Level_old+1)*m_symbol.Point();
//-- Заполнение массивов данными о ценовых уровнях
   ArrayResize(MassUpLev, NumberUpLevels);                     // Увеличим размеры массивов ...
   ArrayResize(MassDnLev, NumberDnLevels);                     // ... под количество уровней
   ArrayInitialize(MassCtLev, 0);                              // Инициализируем массив нулями
   ArrayInitialize(MassUpLev, 0);                              // Инициализируем массив нулями
   ArrayInitialize(MassDnLev, 0);                              // Инициализируем массив нулями
   CenterLevel=m_symbol.Ask();
   MassCtLev[0]=CenterLevel;
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- удаления всех объектов, построенных советником на графике
   ObjectsDeleteAll(0,Prefix,0);
//--- Конец блока удаления всех объектов, построенных советником на графике
//if(!IsTesting())
//{
   Comment("");// Удаление комментариев (не при отладке)
               //}                               
//else if(IsTesting()) // Если в тестере, то ...
//if(GlobalVariableCheck(NameGL_Equ))
//  {                       // ... если есть глобальная переменная терминала с именем NameGL_Equ ...
//   GlobalVariableDel(NameGL_Equ);                           // ... удалим её
//   GlobalVariableDel(NameGL_Add);
//   GlobalVariableDel(NameGL_Loss);
//   GlobalVariableDel(PriceFirstSell);
//  }
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
   if(!RefreshRates())
      return;
//---
   Level_new=m_symbol.StopsLevel();                      // Последнее минимальное значение уровня установки стопов
   if(Level_new==0)
      Level_new=(int)((m_symbol.Ask()-m_symbol.Bid())/Point()*3.0);
   if(Level_old!=Level_new) // Новое не равно старому, значит изменился уровень                         
      Level_old=Level_new; // Новое "старое значение" 
   if(InpDistanceOpenPositions*m_adjusted_point<=Level_new*m_symbol.Point())
      ExtDistanceOpenPositions=(Level_new+1)*m_symbol.Point();
   if(InpTakeProfit*m_adjusted_point<=Level_new*m_symbol.Point())
      ExtTakeProfit=(Level_new+1)*m_symbol.Point();
//--- Вывод дистанций StopLevel на график
   string RectUP=Prefix+"_RectUp_StLevel";
   double pUP1=m_symbol.Ask();
   double pUP2=m_symbol.Ask()+Level_new*m_symbol.Point();
   RectangleCreate(0,RectUP,0,
                   iTime(m_symbol.Name(),Period(),3),pUP1,
                   iTime(m_symbol.Name(),Period(),0)+3*PeriodSeconds(),pUP2,clrFireBrick);
   string RectDN=Prefix+"_RectDn_StLevel";
   double pDN1=m_symbol.Bid();
   double pDN2=m_symbol.Bid()-Level_new*m_symbol.Point();
   RectangleCreate(0,RectDN,0,
                   iTime(m_symbol.Name(),Period(),3),pDN1,
                   iTime(m_symbol.Name(),Period(),0)+3*PeriodSeconds(),pDN2,clrFireBrick);
   Informations();
//--- Открытие первой позиции Sell
   if(FirstStart)
     {                                              // Если это первый старт советника
      if(!GlobalVariableCheck(PriceFirstSell))
        {
         //--- Если нет глобальной перем. терминала PriceFirstSell (не перезагрузка)
         GlobalVariableSet(PriceFirstSell,0);                     // Ставим её в 0
         double tp=m_symbol.Bid()-ExtTakeProfit;
         string New_Comm="Первая_позиция_Sell";
         Print("Первый старт: открываем Sell");
         if(OpenSell(0.0,tp,New_Comm))
            GlobalVariableSet(PriceFirstSell,m_trade.ResultPrice());
        }
     }
//--- Отслеживание уровней относительно цены
   SetLevels();
   if(m_symbol.Ask()>CenterLevel+ExtDistanceOpenPositions)
     {
      CenterLevel=CenterLevel+ExtDistanceOpenPositions;
      MassCtLev[0]=CenterLevel;
      SetLevels();
     }
   if(m_symbol.Bid()<CenterLevel-ExtDistanceOpenPositions)
     {
      CenterLevel=CenterLevel-ExtDistanceOpenPositions;
      MassCtLev[0]=CenterLevel;
      SetLevels();
     }
   if(m_symbol.Ask()-CenterLevel>0.5*m_adjusted_point && 
      CenterLevel-iLow(m_symbol.Name(),Period(),1)>=0.5*m_adjusted_point)
      OpenPosOnTradeMode(POSITION_TYPE_BUY,CenterLevel);
   if(CenterLevel-m_symbol.Bid()>0.5*m_adjusted_point && 
      iHigh(m_symbol.Name(),Period(),1)-CenterLevel>=0.5*m_adjusted_point)
      OpenPosOnTradeMode(POSITION_TYPE_SELL,CenterLevel);
//--- Отслеживание эквити и закрытие убыточных позиций
   int    TotalLoss=0;
   int    NumPoseForClose=0;
   double loss=0;
   double p1=GlobalVariableGet(NameGL_Equ);
   double p2=GlobalVariableGet(NameGL_Add);
   double p3=GlobalVariableGet(NameGL_Loss);
   EquClose=p1+p2;
   EquLoss=p1-p3;
   if(UseEquClose)
     {
      if(m_account.Equity()>=EquClose)
        {
         EquStart=m_account.Equity();
         GlobalVariableSet(NameGL_Equ,EquStart);
         int count_buys=0;
         int count_sells=0;
         CalculateLossPositions(count_buys,count_sells);
         if(count_buys+count_sells==0)
           {
            Print("Средства достигли заданного значения ",DoubleToString(EquClose,2),", убыточных позиций нет");
            CloseFact=false;
            return;
           }
         if(NumberLossPoseForCloseEquUP==1)
           {
            string type="";
            if(ClosePosWithMaxLossInCurrency(loss,type))
               Print("Средства достигли заданного значения ",DoubleToString(EquClose,2),
                     ", закрыли позицию ",type," с наибольшим убытком (",DoubleToString(loss,2),")");
           }
         else if(NumberLossPoseForCloseEquUP>1)
           {
            TotalLoss=count_buys+count_sells;
            if(TotalLoss<NumberLossPoseForCloseEquUP)
               NumPoseForClose=TotalLoss;
            else
               NumPoseForClose=NumberLossPoseForCloseEquUP;
            Print("Средства достигли заданного значения ",DoubleToString(EquClose,2),
                  ", закрываем ",NumPoseForClose," убыточных позиций");
            double loss_temp=0;
            string type_temp="";
            for(int i=0; i<NumPoseForClose; i++)
               ClosePosWithMaxLossInCurrency(loss_temp,type_temp);
           }
         CloseFact=false;
        }
      else if(m_account.Equity()<=EquLoss)
        {
         if(TrackLossEquity)
           {
            int count_buys=0;
            int count_sells=0;
            CalculateLossPositions(count_buys,count_sells);
            if(count_buys+count_sells==0)
              {
               Print("Просадка больше заданного значения ",DoubleToString(EquLoss,2),", убыточных позиций нет");
               CloseFact=false;
               return;
              }
            if(NumberLossPoseForCloseEquDN==1)
              {
               string type="";
               if(ClosePosWithMaxLossInCurrency(loss,type))
                  Print("Просадка больше заданного значения ",DoubleToString(EquLoss,2),
                        ", закрыли позицию ",type," с наибольшим убытком (",DoubleToString(loss,2),")");
              }
            else if(NumberLossPoseForCloseEquDN>1)
              {
               TotalLoss=count_buys+count_sells;
               if(TotalLoss<NumberLossPoseForCloseEquDN)
                  NumPoseForClose=TotalLoss;
               else
                  NumPoseForClose=NumberLossPoseForCloseEquDN;
               Print("Просадка больше заданного значения ",DoubleToString(EquLoss,2),
                     ", закрываем ",NumPoseForClose," убыточных позиций");
               double loss_temp=0;
               string type_temp="";
               for(int i=0; i<NumPoseForClose; i++)
                  ClosePosWithMaxLossInCurrency(loss_temp,type_temp);
              }
            CloseFact=true;
            EquStart=m_account.Equity();              // Стартовый эквити = эквити
            EquPercLoss=EquStart/100.0*PercentLossEquityForClose;// Процент средств, при падении на который закрыть уб. позы
            GlobalVariableSet(NameGL_Equ,EquStart);   // Создадим глобальную переменную терминала и присвоим ей значение эквити
            GlobalVariableSet(NameGL_Loss,EquPercLoss);
            p1=GlobalVariableGet(NameGL_Equ);
            p2=GlobalVariableGet(NameGL_Add);
            p3=GlobalVariableGet(NameGL_Loss);
            EquClose=p1+p2;
            EquLoss=p1-p3;
            Print("Новый стартовый эквити = ",EquStart,
                  ", новый процент просадки = ",EquPercLoss,", уровень след. закрытия = ",EquLoss);
           }
        }
     }
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
//| Create rectangle by the given coordinates                        | 
//+------------------------------------------------------------------+ 
bool RectangleCreate(const long            chart_ID=0,        // chart's ID 
                     const string          name="Rectangle",  // rectangle name 
                     const int             sub_window=0,      // subwindow index  
                     datetime              time1=0,           // first point time 
                     double                price1=0,          // first point price 
                     datetime              time2=0,           // second point time 
                     double                price2=0,          // second point price 
                     const color           clr=clrRed,        // rectangle color 
                     const ENUM_LINE_STYLE style=STYLE_SOLID, // style of rectangle lines 
                     const int             width=1,           // width of rectangle lines 
                     const bool            fill=false,        // filling rectangle with color 
                     const bool            back=false,        // in the background 
                     const bool            selection=false,   // highlight to move 
                     const bool            hidden=true,       // hidden in the object list 
                     const long            z_order=0)         // priority for mouse click 
  {
//--- set anchor points' coordinates if they are not set 
   ChangeRectangleEmptyPoints(time1,price1,time2,price2);
   if(ObjectFind(0,name)<0)
     {
      //--- reset the error value 
      ResetLastError();
      //--- create a rectangle by the given coordinates 
      if(!ObjectCreate(chart_ID,name,OBJ_RECTANGLE,sub_window,time1,price1,time2,price2))
        {
         Print(__FUNCTION__,
               ": failed to create a rectangle! Error code = ",GetLastError());
         return(false);
        }
      //--- set rectangle color 
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
      //--- set the style of rectangle lines 
      ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
      //--- set width of the rectangle lines 
      ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
      //--- enable (true) or disable (false) the mode of filling the rectangle 
      ObjectSetInteger(chart_ID,name,OBJPROP_FILL,fill);
      //--- display in the foreground (false) or background (true) 
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      //--- enable (true) or disable (false) the mode of highlighting the rectangle for moving 
      //--- when creating a graphical object using ObjectCreate function, the object cannot be 
      //--- highlighted and moved by default. Inside this method, selection parameter 
      //--- is true by default making it possible to highlight and move the object 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      //--- hide (true) or display (false) graphical object name in the object list 
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      //--- set the priority for receiving the event of a mouse click in the chart 
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
     }
   else
     {
      RectanglePointChange(chart_ID,name,0,time1,price1);
      RectanglePointChange(chart_ID,name,1,time2,price2);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Move the rectangle anchor point                                  | 
//+------------------------------------------------------------------+ 
bool RectanglePointChange(const long   chart_ID=0,       // chart's ID 
                          const string name="Rectangle", // rectangle name 
                          const int    point_index=0,    // anchor point index 
                          datetime     time=0,           // anchor point time coordinate 
                          double       price=0)          // anchor point price coordinate 
  {
//--- if point position is not set, move it to the current bar having Bid price 
   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value 
   ResetLastError();
//--- move the anchor point 
   if(!ObjectMove(chart_ID,name,point_index,time,price))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Check the values of rectangle's anchor points and set default    | 
//| values for empty ones                                            | 
//+------------------------------------------------------------------+ 
void ChangeRectangleEmptyPoints(datetime &time1,double &price1,
                                datetime &time2,double &price2)
  {
//--- if the first point's time is not set, it will be on the current bar 
   if(!time1)
      time1=TimeCurrent();
//--- if the first point's price is not set, it will have Bid value 
   if(!price1)
      price1=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- if the second point's time is not set, it is located 9 bars left from the second one 
   if(!time2)
     {
      //--- array for receiving the open time of the last 10 bars 
      datetime temp[10];
      CopyTime(Symbol(),Period(),time1,10,temp);
      //--- set the second point 9 bars left from the first one 
      time2=temp[0];
     }
//--- if the second point's price is not set, move it 300 points lower than the first one 
   if(!price2)
      price2=price1-300*SymbolInfoDouble(Symbol(),SYMBOL_POINT);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Informations()
  {
   string name="",text="",font="Lucida Console";
   int    xDist=0,yDist=0;
   int yDistStart=(ChartGetInteger(0,CHART_SHOW_ONE_CLICK)==true)?10+65:10;
//---
   text="Баланс счёта: ";
   name=Prefix+"_txt_Balance";
   xDist=10; yDist=yDistStart+70;
   LabelCreate(0,name,0,xDist,yDist,CORNER_LEFT_UPPER,text,font,10,clrLightBlue);
//---
   text=DoubleToString(m_account.Balance(),2); // Числовое значение баланса
   name=Prefix+"_num_AccBalance";
   xDist=170; yDist=yDistStart+70;
   LabelCreate(0,name,0,xDist,yDist,CORNER_LEFT_UPPER,text,font,10,clrNavajoWhite);
//---
   text="Свободные средства: ";
   name=Prefix+"_txt_Equity";
   xDist=10; yDist=yDistStart+50;
   LabelCreate(0,name,0,xDist,yDist,CORNER_LEFT_UPPER,text,font,10,clrLightBlue);
//---
   text=DoubleToString(m_account.Equity(),2); // Числовое значение эквити
   name=Prefix+"_num_AccEquity";
   xDist=170; yDist=yDistStart+50;
   LabelCreate(0,name,0,xDist,yDist,CORNER_LEFT_UPPER,text,font,10,clrNavajoWhite);
//---
   text="Закрытие на уровне: ";
   name=Prefix+"_txt_CloseEquity";
   xDist=10; yDist=yDistStart+30;
   LabelCreate(0,name,0,xDist,yDist,CORNER_LEFT_UPPER,text,font,10,clrLightBlue);
//---
   text=DoubleToString(EquClose,2); // Числовое значение эквити
   name=Prefix+"_num_ClsEquity";
   xDist=170; yDist=yDistStart+30;
   LabelCreate(0,name,0,xDist,yDist,CORNER_LEFT_UPPER,text,font,10,clrNavajoWhite);
//---
   text="Критический уровень: ";
   name=Prefix+"_txt_CriticEquity";
   xDist=10; yDist=yDistStart+10;
   LabelCreate(0,name,0,xDist,yDist,CORNER_LEFT_UPPER,text,font,10,clrLightBlue);
//---
   text=DoubleToString(EquLoss,2); // Числовое значение эквити
   name=Prefix+"_num_CriticEquity";
   xDist=170; yDist=yDistStart+10;
   LabelCreate(0,name,0,xDist,yDist,CORNER_LEFT_UPPER,text,font,10,clrNavajoWhite);
//---
   text="Убыточных Buy: ";
   name=Prefix+"_txt_LossBuy";
   xDist=270; yDist=yDistStart+50;
   LabelCreate(0,name,0,xDist,yDist,CORNER_LEFT_UPPER,text,font,10,clrLightBlue);
//---
   int count_buys=0;
   int count_sells=0;
   CalculateLossPositions(count_buys,count_sells);

   text=DoubleToString(count_buys,0);
   name=Prefix+"_num_LossBuy";
   xDist=400; yDist=yDistStart+50;
   LabelCreate(0,name,0,xDist,yDist,CORNER_LEFT_UPPER,text,font,10,clrNavajoWhite);
//---
   text="Убыточных Sell: ";
   name=Prefix+"_txt_LossSell";
   xDist=270; yDist=yDistStart+30;
   LabelCreate(0,name,0,xDist,yDist,CORNER_LEFT_UPPER,text,font,10,clrLightBlue);
//---
   text=DoubleToString(count_sells,0);
   name=Prefix+"_num_LossSell";
   xDist=400; yDist=yDistStart+30;
   LabelCreate(0,name,0,xDist,yDist,CORNER_LEFT_UPPER,text,font,10,clrNavajoWhite);
  }
//+------------------------------------------------------------------+ 
//| Create a text label                                              | 
//+------------------------------------------------------------------+ 
bool LabelCreate(const long              chart_ID=0,               // chart's ID 
                 const string            name="Label",             // label name 
                 const int               sub_window=0,             // subwindow index 
                 const int               x=0,                      // X coordinate 
                 const int               y=0,                      // Y coordinate 
                 const ENUM_BASE_CORNER  corner=CORNER_LEFT_UPPER, // chart corner for anchoring 
                 const string            text="Label",             // text 
                 const string            font="Arial",             // font 
                 const int               font_size=10,             // font size 
                 const color             clr=clrRed,               // color 
                 const double            angle=0.0,                // text slope 
                 const ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER, // anchor type 
                 const bool              back=false,               // in the background 
                 const bool              selection=false,          // highlight to move 
                 const bool              hidden=true,              // hidden in the object list 
                 const long              z_order=0)                // priority for mouse click 
  {
//--- reset the error value 
   ResetLastError();
   if(ObjectFind(0,name)<0)
     {
      //--- create a text label 
      if(!ObjectCreate(chart_ID,name,OBJ_LABEL,sub_window,0,0))
        {
         Print(__FUNCTION__,
               ": failed to create text label! Error code = ",GetLastError());
         return(false);
        }
      //--- set label coordinates 
      ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y);
      //--- set the chart's corner, relative to which point coordinates are defined 
      ObjectSetInteger(chart_ID,name,OBJPROP_CORNER,corner);
      //--- set the text 
      ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
      //--- set text font 
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      //--- set font size 
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      //--- set the slope angle of the text 
      ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
      //--- set anchor type 
      ObjectSetInteger(chart_ID,name,OBJPROP_ANCHOR,anchor);
      //--- set color 
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
      //--- display in the foreground (false) or background (true) 
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      //--- enable (true) or disable (false) the mode of moving the label by mouse 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      //--- hide (true) or display (false) graphical object name in the object list 
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      //--- set the priority for receiving the event of a mouse click in the chart 
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
     }
   else
     {
      LabelMove(chart_ID,name,x,y);
      LabelTextChange(chart_ID,name,text);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Move the text label                                              | 
//+------------------------------------------------------------------+ 
bool LabelMove(const long   chart_ID=0,   // chart's ID 
               const string name="Label", // label name 
               const int    x=0,          // X coordinate 
               const int    y=0)          // Y coordinate 
  {
//--- reset the error value 
   ResetLastError();
//--- move the text label 
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_XDISTANCE,x))
     {
      Print(__FUNCTION__,
            ": failed to move X coordinate of the label! Error code = ",GetLastError());
      return(false);
     }
   if(!ObjectSetInteger(chart_ID,name,OBJPROP_YDISTANCE,y))
     {
      Print(__FUNCTION__,
            ": failed to move Y coordinate of the label! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Change the label text                                            | 
//+------------------------------------------------------------------+ 
bool LabelTextChange(const long   chart_ID=0,   // chart's ID 
                     const string name="Label", // object name 
                     const string text="Text")  // text 
  {
//--- reset the error value 
   ResetLastError();
//--- change object text 
   if(!ObjectSetString(chart_ID,name,OBJPROP_TEXT,text))
     {
      Print(__FUNCTION__,
            ": failed to change the text! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+
//| Calculate lossing positions Buy and Sell                         |
//+------------------------------------------------------------------+
void CalculateLossPositions(int &count_buys,int &count_sells)
  {
   count_buys=0;
   count_sells=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            bool loss=(m_position.Commission()+m_position.Swap()+m_position.Profit()<0);
            if(m_position.PositionType()==POSITION_TYPE_BUY && loss)
               count_buys++;

            if(m_position.PositionType()==POSITION_TYPE_SELL && loss)
               count_sells++;
           }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
bool OpenBuy(double sl,double tp,const string comment)
  {
   if(!TradeBuy)
     {
      Print("Торговля в Buy отключена в настройках советника");
      return(false);
     }
//---
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.Buy(InpLots,m_symbol.Name(),m_symbol.Ask(),sl,tp,comment))
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
               "< Lots (",DoubleToString(InpLots,2),")");
         return(false);
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return(false);
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
bool OpenSell(double sl,double tp,const string comment)
  {
   if(!TradeSell)
     {
      Print("Торговля в Sell отключена в настройках советника");
      return(false);
     }
//---
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),InpLots,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=InpLots)
        {
         if(m_trade.Sell(InpLots,m_symbol.Name(),m_symbol.Bid(),sl,tp,comment))
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
               "< Lots (",DoubleToString(InpLots,2),")");
         return(false);
        }
     }
   else
     {
      Print(__FUNCTION__,", ERROR: method CheckVolume returned the value of \"0.0\"");
      return(false);
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//| Print CTrade result                                              |
//+------------------------------------------------------------------+
void PrintResultTrade(CTrade &trade,CSymbolInfo &symbol)
  {
   Print("File: ",__FILE__,", symbol: ",m_symbol.Name());
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
//|                                                                  |
//+------------------------------------------------------------------+
void SetLevels()
  {
   int i;
   double step,lev;
   MassCtLev[0]=CenterLevel;
   string NameLevelCT=Prefix+"_CenterLevel";                   // Имя центральной линии
   ArrowRightPriceCreate(0,NameLevelCT,0,iTime(m_symbol.Name(),Period(),0),CenterLevel,clrMediumSpringGreen);
//--- Вывод верхних уровней на график
   for(i=0; i<NumberUpLevels; i++)
     {
      step=((i+1)*ExtDistanceOpenPositions);                   // Шаг приращения цены
      lev=NormalizeDouble(MassCtLev[0]+step,m_symbol.Digits());               // Ценовое значение i-го уровня
      MassUpLev[i]=lev;                                        // Заполним массив
      string NameLevelUP=Prefix+"_UpLevel_"+DoubleToString(i,0);  // Имя линии
      //--- Нарисуем i-уровень
      ArrowRightPriceCreate(0,NameLevelUP,0,iTime(m_symbol.Name(),Period(),0),lev,clrDeepSkyBlue);
     }
//--- Вывод нижних уровней на график
   for(i=0; i<NumberDnLevels; i++)
     {
      step=((i+1)*ExtDistanceOpenPositions);                  // Шаг приращения цены
      lev=NormalizeDouble(MassCtLev[0]-step,m_symbol.Digits());               // Ценовое значение i-го уровня
      MassDnLev[i]=lev;                                        // Заполним массив
      string NameLevelDN=Prefix+"_DnLevel_"+DoubleToString(i,0);  // Имя линии
      //--- Нарисуем i-уровень
      ArrowRightPriceCreate(0,NameLevelDN,0,iTime(m_symbol.Name(),Period(),0),lev,clrGold);
     }
   MassUpLen=ArrayRange(MassUpLev,0);
   MassDnLen=ArrayRange(MassDnLev,0);
   HighestLev=MassUpLev[MassUpLen-1];
   LowestLev =MassDnLev[MassDnLen-1];
   return;
  }
//+------------------------------------------------------------------+ 
//| Create the right price label                                     | 
//+------------------------------------------------------------------+ 
bool ArrowRightPriceCreate(const long            chart_ID=0,        // chart's ID 
                           const string          name="RightPrice", // price label name 
                           const int             sub_window=0,      // subwindow index 
                           datetime              time=0,            // anchor point time 
                           double                price=0,           // anchor point price 
                           const color           clr=clrRed,        // price label color 
                           const ENUM_LINE_STYLE style=STYLE_SOLID, // border line style 
                           const int             width=1,           // price label size 
                           const bool            back=false,        // in the background 
                           const bool            selection=true,    // highlight to move 
                           const bool            hidden=true,       // hidden in the object list 
                           const long            z_order=0)         // priority for mouse click 
  {
//--- set anchor point coordinates if they are not set 
   ChangeArrowEmptyPoint(time,price);
   if(ObjectFind(0,name)<0)
     {
      //--- reset the error value 
      ResetLastError();
      //--- create a price label 
      if(!ObjectCreate(chart_ID,name,OBJ_ARROW_RIGHT_PRICE,sub_window,time,price))
        {
         Print(__FUNCTION__,
               ": failed to create the right price label! Error code = ",GetLastError());
         return(false);
        }
      //--- set the label color 
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
      //--- set the border line style 
      ObjectSetInteger(chart_ID,name,OBJPROP_STYLE,style);
      //--- set the label size 
      ObjectSetInteger(chart_ID,name,OBJPROP_WIDTH,width);
      //--- display in the foreground (false) or background (true) 
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      //--- enable (true) or disable (false) the mode of moving the label by mouse 
      //--- when creating a graphical object using ObjectCreate function, the object cannot be 
      //--- highlighted and moved by default. Inside this method, selection parameter 
      //--- is true by default making it possible to highlight and move the object 
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      //--- hide (true) or display (false) graphical object name in the object list 
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      //--- set the priority for receiving the event of a mouse click in the chart 
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
     }
   else
     {
      ArrowRightPriceMove(chart_ID,name,time,price);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Move the anchor point                                            | 
//+------------------------------------------------------------------+ 
bool ArrowRightPriceMove(const long   chart_ID=0,        // chart's ID 
                         const string name="RightPrice", // label name 
                         datetime     time=0,            // anchor point time coordinate 
                         double       price=0)           // anchor point price coordinate 
  {
//--- if point position is not set, move it to the current bar having Bid price 
   if(!time)
      time=TimeCurrent();
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
//--- reset the error value 
   ResetLastError();
//--- move the anchor point 
   if(!ObjectMove(chart_ID,name,0,time,price))
     {
      Print(__FUNCTION__,
            ": failed to move the anchor point! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution 
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Check anchor point values and set default values                 | 
//| for empty ones                                                   | 
//+------------------------------------------------------------------+ 
void ChangeArrowEmptyPoint(datetime &time,double &price)
  {
//--- if the point's time is not set, it will be on the current bar 
   if(!time)
      time=TimeCurrent();
//--- if the point's price is not set, it will have Bid value 
   if(!price)
      price=SymbolInfoDouble(Symbol(),SYMBOL_BID);
  }
//+------------------------------------------------------------------+
//| Открытие позиций при работе по рынку                             |
//+------------------------------------------------------------------+
void OpenPosOnTradeMode(ENUM_POSITION_TYPE type,double price)
  {
   double tp=0,pp=0;
   string New_Comm="";
   Print("Цена пересекла уровень ",price,", проверим необходимость открытия рыночной позиции");
   if(type==POSITION_TYPE_BUY)
     {
      tp=m_symbol.Ask()+ExtTakeProfit;
      New_Comm="Работа по рынку_Buy";
      if(!PresentPosNearestLev(type,price))
        {
         Print("Вблизи уровня ",DoubleToString(price,m_symbol.Digits())," нет позиций, открываем Buy");
         OpenBuy(0.0,tp,New_Comm);
         return;
        }
     }
   else if(type==POSITION_TYPE_SELL)
     {
      tp=NormalizeDouble(m_symbol.Bid()-ExtTakeProfit,m_symbol.Digits());
      New_Comm="Работа по рынку_Sell";
      if(!PresentPosNearestLev(type,price))
        {
         Print("Вблизи уровня ",DoubleToString(price,m_symbol.Digits())," нет позиций, открываем Sell");
         OpenSell(0.0,tp,New_Comm);
        }
     }
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PresentPosNearestLev(ENUM_POSITION_TYPE type,double price)
  {
   double delta=ExtDistanceOpenPositions/2.0;
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==type)
               if(MathAbs(m_position.PriceOpen()-price)<=delta)
                 {
                  string pos=(m_position.PositionType()==POSITION_TYPE_BUY)?"Buy":"Sell";
                  Print("Вблизи уровня ",DoubleToString(price,m_symbol.Digits()),
                        " уже есть позиция ",pos,
                        ", открытая по цене ",DoubleToString(m_position.PriceOpen(),m_symbol.Digits()));
                  return(true);
                 }
           }
//---
   return(false);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool ClosePosWithMaxLossInCurrency(double lossing,string &type)
  {
   lossing=DBL_MAX;
   ulong ticket=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            double profit=m_position.Commission()+m_position.Swap()+m_position.Profit();
            if(profit<lossing)
              {
               lossing=profit;
               type=(m_position.PositionType()==POSITION_TYPE_BUY)?"Buy":"Sell";
               ticket=m_position.Ticket();
              }
           }
   if(lossing<0)
     {
      m_trade.PositionClose(ticket);
      return(true);
     }
//---
   return(false);
  }
//+------------------------------------------------------------------+

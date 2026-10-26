//+------------------------------------------------------------------+
//|                                                N-_Candles_v7.mq5 |
//|                              Copyright © 2018, Vladimir Karputov |
//|                                           http://wmua.ru/slesar/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2018, Vladimir Karputov"
#property link      "http://wmua.ru/slesar/"
#property version   "7.001"
#property description "We look for N-of identical candles which go in a row"
#property description "New in version 2: Take Profit, Stop Loss, Trailing"
#property description "New in version 3: Maximum number of open positions in a certain direction"
#property description "New in version 4: On netting-accounts we set the maximum volume of a position,"
#property description "                  but not quantity of positions"
#property description "New in version 5: Add parameter parameter \"working time\""
#property description "New in version 6: The parameter \"black sheep\""
#property description "New in version 7: The parameter \"Closing of positions at achievement of the general profit\""
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
//+------------------------------------------------------------------+
//| Enum hours                                                       |
//+------------------------------------------------------------------+
enum ENUM_HOURS
  {
   hour_00  =0,   // 00
   hour_01  =1,   // 01
   hour_02  =2,   // 02
   hour_03  =3,   // 03
   hour_04  =4,   // 04
   hour_05  =5,   // 05
   hour_06  =6,   // 06
   hour_07  =7,   // 07
   hour_08  =8,   // 08
   hour_09  =9,   // 09
   hour_10  =10,  // 10
   hour_11  =11,  // 11
   hour_12  =12,  // 12
   hour_13  =13,  // 13
   hour_14  =14,  // 14
   hour_15  =15,  // 15
   hour_16  =16,  // 16
   hour_17  =17,  // 17
   hour_18  =18,  // 18
   hour_19  =19,  // 19
   hour_20  =20,  // 20
   hour_21  =21,  // 21
   hour_22  =22,  // 22
   hour_23  =23,  // 23
  };
//+------------------------------------------------------------------+
//| Type of trade                                                    |
//+------------------------------------------------------------------+
enum ENUM_type_of_trade
  {
   all=0,            // closing all positions
   oposite=1,        // closing of opposite positions
   unidirectional=2, // closing of unidirectional positions
  };
//--- input parameter
input uchar       InpN_candles   = 3;           // N identical candles which go in a row 
input double      InpLot         = 0.01;        // Lot
input ushort      InpTakeProfit  = 50;          // Take Profit ("0" -> not Take Profit) (in pips)
input ushort      InpStopLoss    = 50;          // Stop Loss ("0" -> not Stop Loss) (in pips)
input ushort      InpTrailingStop= 10;          // Trailing Stop ("0" -> not trailing)
input ushort      InpTrailingStep= 4;           // Trailing Step (use if Trailing Stop >0)
input uchar       InpMaxPositions= 2;           // Max positions certain direction (only for hedging)
input double      InpMaxPositionVolume = 2.0;   // Max position volume (only for netting)
input bool        InpUseTradeHours = true;      // Use trade hours
input ENUM_HOURS  InpStartHour   = hour_11;     // Start hour
input ENUM_HOURS  InpEndHour     = hour_18;     // End hour
input double      InpMinProfit   = 3.0;         // Closing of positions at achievement of the general profit
input ulong       m_magic        = 427475216;   // magic number
input ENUM_type_of_trade InpClosing=all;        // The type of closure at the meeting of the "black sheep"
//---
ulong    m_slippage=30;          // slippage
ENUM_ACCOUNT_MARGIN_MODE m_margin_mode;
double         m_adjusted_point;             // point value adjusted for 3 or 5 points
double         ExtTakeProfit  = 0.0;
double         ExtStopLoss    = 0.0;
double         ExtTrailingStop= 0.0;
double         ExtTrailingStep= 0.0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(InpUseTradeHours)
      if(InpStartHour>=InpEndHour)
        {
         Print("The parameter \"Start hour\" can't be more or is equal to the parameter \"End hour\"");
         return(INIT_PARAMETERS_INCORRECT);
        }
   if(InpTrailingStep==0 && InpTrailingStop!=0)
     {
      string text="\"Trailing Step\" can't be equal to zero if the \"Trailing Stop\" parameter is allowed";
      Alert(text);
      Print(text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   m_margin_mode=-1;
   m_margin_mode=m_account.MarginMode();
//--- protection
   if(m_margin_mode!=ACCOUNT_MARGIN_MODE_RETAIL_NETTING &&
      m_margin_mode!=ACCOUNT_MARGIN_MODE_EXCHANGE &&
      m_margin_mode!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
     {
      Print(IntegerToString(m_margin_mode),": unknown margin calculation mode.");
      return(INIT_FAILED);
     }
//---
   m_symbol.Name(Symbol());                  // sets symbol name
   RefreshRates();
   m_symbol.Refresh();

   string err_text="";
   if(!CheckVolumeValue(InpLot,err_text))
     {
      Print(err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
   err_text="";
   if(m_margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_NETTING)
     {
      if(!CheckVolumeValue(InpMaxPositionVolume,err_text))
        {
         Print(err_text);
         return(INIT_PARAMETERS_INCORRECT);
        }
     }
//---
   m_trade.SetExpertMagicNumber(m_magic);
//---
   if(IsFillingTypeAllowed(Symbol(),SYMBOL_FILLING_FOK))
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if(IsFillingTypeAllowed(Symbol(),SYMBOL_FILLING_IOC))
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
//---
   m_trade.SetDeviationInPoints(m_slippage);
//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;
   ExtTakeProfit  = InpTakeProfit   * m_adjusted_point;
   ExtStopLoss    = InpStopLoss     * m_adjusted_point;
   ExtTrailingStop= InpTrailingStop * m_adjusted_point;
   ExtTrailingStep= InpTrailingStep * m_adjusted_point;
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
//--- we work only at the time of the birth of new bar
   static datetime PrevBars=0;
   datetime time_0=iTime(0);
   if(time_0==PrevBars)
      return;

   double total_profit=0.0;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            total_profit+=m_position.Commission()+m_position.Swap()+m_position.Profit();
   if(total_profit>=InpMinProfit)
     {
      CloseAllPositions();
      PrevBars==iTime(1);
      return;
     }

   string text="";
   if(InpUseTradeHours)
     {
      MqlDateTime str1;
      TimeToStruct(time_0,str1);
      text="Current time: "+TimeToString(time_0,TIME_MINUTES)+"\n"+
           "Working interval with "+IntegerToString(InpStartHour)+" on "+IntegerToString(InpEndHour)+"\n";
      if(str1.hour<InpStartHour || InpEndHour<str1.hour)
         text=text+"Trading is forbidden";
      else
         text=text+"Trading is allowed";
     }

   if(time_0==PrevBars)
     {
      if(InpUseTradeHours)
         Comment(text);
      return;
     }
   PrevBars=time_0;

   if(InpUseTradeHours)
      Comment(text);

   Trailing();

   MqlRates rates[];
   int copied=CopyRates(NULL,0,1,InpN_candles,rates);
//--- Example:
//--- rates[0].time -> D'2015.05.28 00:00:00'
//--- rates[2].time -> D'2015.06.01 00:00:00'
   if(copied<=0)
     {
      Print("Error copying price data ",GetLastError());
      return;
     }
   bool result=true;
//--- bull candle. Bear candle.
   int type_of_candles=0;     // "1" -> Bull candle. "-1" ->Bear candle
   for(int i=0;i<copied;i++)
     {
      //--- we define type of the most distant candle
      if(i==0)
        {
         if(rates[i].open<rates[i].close)
            type_of_candles=1;
         else if(rates[i].open>rates[i].close)
            type_of_candles=-1;
         else
           {
            result=false;
            break;
           }
         continue;
        }
      if(type_of_candles==1) // "1" -> Bull candle
        {
         if(rates[i].open>rates[i].close)
           {
            result=false;
            break;
           }
        }
      else // "-1" -> Bear candle
        {
         if(rates[i].open<rates[i].close)
           {
            result=false;
            break;
           }
        }
     }
   static bool black_sheep=false;
   if(!result)
     {
      if(!black_sheep)
        {
         if(InpClosing==all)
            CloseAllPositions();
         else if(InpClosing==oposite && type_of_candles!=0) // closing of opposite positions
           {
            ENUM_POSITION_TYPE pos_type=(type_of_candles==1)?POSITION_TYPE_SELL:POSITION_TYPE_BUY;
            ClosePositions(pos_type);
           }
         else if(InpClosing==unidirectional && type_of_candles!=0) // closing of unidirectional positions
           {
            ENUM_POSITION_TYPE pos_type=(type_of_candles==1)?POSITION_TYPE_BUY:POSITION_TYPE_SELL;
            ClosePositions(pos_type);
           }
         black_sheep=true;
        }
      return;
     }
//--- we here. Means we have found N-of candles in a row
   if(type_of_candles==1) // "1" -> Bull candle
     {
      if(!RefreshRates())
        {
         PrevBars=iTime(1);
         return;
        }
      double sl=(InpStopLoss!=0)?m_symbol.Ask()-ExtStopLoss:0.0;
      double tp=(InpTakeProfit!=0)?m_symbol.Ask()+ExtTakeProfit:0.0;
      if(m_margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
        {
         if(CalculatePositions(POSITION_TYPE_BUY)<InpMaxPositions)
           {
            OpenBuy(sl,tp);
            black_sheep=false;
           }
        }
      else if(m_margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_NETTING)
        {
         OpenBuy(sl,tp);
         black_sheep=false;
        }
     }
   else
     {
      if(!RefreshRates())
        {
         PrevBars=iTime(1);
         return;
        }
      double sl=(InpStopLoss!=0)?m_symbol.Bid()+ExtStopLoss:0.0;
      double tp=(InpTakeProfit!=0)?m_symbol.Bid()-ExtTakeProfit:0.0;
      if(m_margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING)
        {
         if(CalculatePositions(POSITION_TYPE_SELL)<InpMaxPositions)
           {
            OpenSell(sl,tp);
            black_sheep=false;
           }
        }
      else if(m_margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_NETTING)
        {
         OpenSell(sl,tp);
         black_sheep=false;
        }
     }
   int d=0;
  }
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MIN);
   if(volume<min_volume)
     {
      error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }

//--- maximal allowed volume of trade operations
   double max_volume=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_MAX);
   if(volume>max_volume)
     {
      error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }

//--- get minimal step of volume changing
   double volume_step=SymbolInfoDouble(Symbol(),SYMBOL_VOLUME_STEP);

   int ratio=(int)MathRound(volume/volume_step);
   if(MathAbs(ratio*volume_step-volume)>0.0000001)
     {
      error_description=StringFormat("Volume is not a multiple of the minimal step SYMBOL_VOLUME_STEP=%.2f, the closest correct volume is %.2f",
                                     volume_step,ratio*volume_step);
      return(false);
     }
   error_description="Correct volume value";
   return(true);
  }
//+------------------------------------------------------------------+ 
//| Checks if the specified filling mode is allowed                  | 
//+------------------------------------------------------------------+ 
bool IsFillingTypeAllowed(string symbol,int fill_type)
  {
//--- Obtain the value of the property that describes allowed filling modes 
   int filling=(int)SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
//--- Return true, if mode fill_type is allowed 
   return((filling & fill_type)==fill_type);
  }
//+------------------------------------------------------------------+ 
//| Get Open for specified bar index                                 | 
//+------------------------------------------------------------------+ 
double iOpen(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   double Open[1];
   double open=0;
   int copied=CopyOpen(symbol,timeframe,index,1,Open);
   if(copied>0) open=Open[0];
   return(open);
  }
//+------------------------------------------------------------------+ 
//| Get Close for specified bar index                                | 
//+------------------------------------------------------------------+ 
double iClose(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   double Close[1];
   double close=0;
   int copied=CopyClose(symbol,timeframe,index,1,Close);
   if(copied>0) close=Close[0];
   return(close);
  }
//+------------------------------------------------------------------+ 
//| Get Time for specified bar index                                 | 
//+------------------------------------------------------------------+ 
datetime iTime(const int index,string symbol=NULL,ENUM_TIMEFRAMES timeframe=PERIOD_CURRENT)
  {
   if(symbol==NULL)
      symbol=Symbol();
   if(timeframe==0)
      timeframe=Period();
   datetime Time[1];
   datetime time=0;
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0) time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double chek_volime_lot=m_trade.CheckVolume(m_symbol.Name(),InpLot,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(chek_volime_lot!=0.0)
      if(chek_volime_lot>=InpLot)
        {
         if(m_margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_NETTING)
           {
            double current_volume=0.0;
            if(m_position.Select(m_symbol.Name()))
               current_volume=(m_position.PositionType()==POSITION_TYPE_BUY)?m_position.Volume():-m_position.Volume();
            if(MathAbs(current_volume+InpLot)>InpMaxPositionVolume)
               return;
           }
         if(m_trade.Buy(InpLot,NULL,m_symbol.Ask(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
              }
            else
              {
               Print("Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
              }
           }
         else
           {
            Print("Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
           }
        }
//---
  }
//+------------------------------------------------------------------+
//| Open Sell position                                               |
//+------------------------------------------------------------------+
void OpenSell(double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double chek_volime_lot=m_trade.CheckVolume(m_symbol.Name(),InpLot,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(chek_volime_lot!=0.0)
      if(chek_volime_lot>=InpLot)
        {
         if(m_margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_NETTING)
           {
            double current_volume=0.0;
            if(m_position.Select(m_symbol.Name()))
               current_volume=(m_position.PositionType()==POSITION_TYPE_SELL)?m_position.Volume():-m_position.Volume();
            if(MathAbs(current_volume+InpLot)>InpMaxPositionVolume)
               return;
           }
         if(m_trade.Sell(InpLot,NULL,m_symbol.Bid(),sl,tp))
           {
            if(m_trade.ResultDeal()==0)
              {
               Print("Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
              }
            else
              {
               Print("Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                     ", description of result: ",m_trade.ResultRetcodeDescription());
              }
           }
         else
           {
            Print("Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
           }
        }
//---
  }
//+------------------------------------------------------------------+
//| Trailing                                                         |
//+------------------------------------------------------------------+
void Trailing()
  {
   if(InpTrailingStop==0)
      return;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtTrailingStop+ExtTrailingStep)
                  if(m_position.StopLoss()<m_position.PriceCurrent()-(ExtTrailingStop+ExtTrailingStep))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()-ExtTrailingStop),
                        m_position.TakeProfit()))
                        Print("Modify BUY ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                     continue;
                    }
              }
            else
              {
               if(m_position.PriceOpen()-m_position.PriceCurrent()>ExtTrailingStop+ExtTrailingStep)
                  if((m_position.StopLoss()>(m_position.PriceCurrent()+(ExtTrailingStop+ExtTrailingStep))) || 
                     (m_position.StopLoss()==0))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()+ExtTrailingStop),
                        m_position.TakeProfit()))
                        Print("Modify SELL ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
              }

           }
  }
//+------------------------------------------------------------------+
//| Calculate positions                                              |
//+------------------------------------------------------------------+
int CalculatePositions(ENUM_POSITION_TYPE pos_type)
  {
   int count=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            if(m_position.PositionType()==pos_type)
               count++;
//---
   return(count);
  }
//+------------------------------------------------------------------+
//| Close positions                                                  |
//+------------------------------------------------------------------+
void ClosePositions(const ENUM_POSITION_TYPE pos_type)
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==Symbol() && m_position.Magic()==m_magic)
            if(m_position.PositionType()==pos_type) // gets the position type
               m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+
//| Close all positions                                              |
//+------------------------------------------------------------------+
void CloseAllPositions()
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                          ExFractals(barabashkakvn's edition).mq5 |
//|                           Copyright © 2006, Alex Sidd (Executer) |
//|                                           mailto:work_st@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2006, Alex Sidd (Executer)"
#property link      "mailto:work_st@mail.ru"
#property version   "1.003"
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
input double   InpMaximumRisk       = 0.02;     // Maximum Risk in percentage
input double   InpDecreaseFactor    = 3;        // Descrease factor
input ushort   InpStopLossBuy       = 40;       // Stop Loss Buy (in pips)
input ushort   InpStopLossSell      = 40;       // Stop Loss Sell (in pips)
input ushort   InpTakeProfitBuy     = 100;      // Take Profit Buy (in pips)
input ushort   InpTakeProfitSell    = 100;      // Take Profit Sell (in pips)
input ushort   InpTrailingStopBuy   = 30;       // Trailing Stop Buy (in pips)
input ushort   InpTrailingStopSell  = 30;       // Trailing Stop Sell (in pips)
input ushort   InpTrailingStep      = 5;        // Trailing Step (in pips)
input uint     InpExPeriod          = 15;       // ExVol: ExPeriod
input ulong    m_magic              = 26513850; // magic number
//---
ulong          m_slippage=10;                // slippage

double         ExtStopLossBuy=0.0;
double         ExtStopLossSell=0.0;
double         ExtTakeProfitBuy=0.0;
double         ExtTakeProfitSell=0.0;
double         ExtTrailingStopBuy=0.0;
double         ExtTrailingStopSell=0.0;
double         ExtTrailingStep=0.0;

int            handle_iFractals;             // variable for storing the handle of the iFractals indicator 
int            handle_iCustom;               // variable for storing the handle of the iCustom indicator 

double         m_adjusted_point;             // point value adjusted for 3 or 5 points
string         m_comment="";
//---
int            m_what=0;
double         m_FractUp1=0;
double         m_FractUp2=0;
double         m_FractDn1=0;
double         m_FractDn2=0;
datetime       m_FTimeUp1=0, m_FTimeUp2=0, m_FTimeDn1=0, m_FTimeDn2=0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if((InpTrailingStopBuy!=0 || InpTrailingStopSell!=0) && InpTrailingStep==0)
     {
      string text=(TerminalInfoString(TERMINAL_LANGUAGE)=="Russian")?
                  "Трейлинг невозможен: параметр \"Trailing Step\" равен нулю!":
                  "Trailing is not possible: parameter \"Trailing Step\" is zero!";
      Alert(__FUNCTION__," ERROR! ",text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();
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

   ExtStopLossBuy       = InpStopLossBuy        * m_adjusted_point;
   ExtStopLossSell      = InpStopLossSell       * m_adjusted_point;
   ExtTakeProfitBuy     = InpTakeProfitBuy      * m_adjusted_point;
   ExtTakeProfitSell    = InpTakeProfitSell     * m_adjusted_point;
   ExtTrailingStopBuy   = InpTrailingStopBuy    * m_adjusted_point;
   ExtTrailingStopSell  = InpTrailingStopSell   * m_adjusted_point;
   ExtTrailingStep      = InpTrailingStep       * m_adjusted_point;
//--- create handle of the indicator iFractals
   handle_iFractals=iFractals(m_symbol.Name(),Period());
//--- if the handle is not created 
   if(handle_iFractals==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iFractals indicator for the symbol %s/%s, error code %d",
                  m_symbol.Name(),
                  EnumToString(Period()),
                  GetLastError());
      //--- the indicator is stopped early 
      return(INIT_FAILED);
     }
//--- create handle of the indicator iCustom
   handle_iCustom=iCustom(m_symbol.Name(),Period(),"exvol",InpExPeriod);
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
   m_comment=IntegerToString(m_magic);
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
   datetime time_0=iTime(m_symbol.Name(),Period(),0);
   if(time_0==PrevBars)
      return;
   PrevBars=time_0;
   if(!RefreshRates())
     {
      PrevBars=0;
      return;
     }
//---
   double Fup     = iFractalsGet(UPPER_LINE,3);
   double Fdn     = iFractalsGet(LOWER_LINE,3);
   datetime time_3=iTime(m_symbol.Name(),Period(),3);
   if(Fup>0 && Fup!=EMPTY_VALUE)
     {
      if(m_FractUp1==0 && m_FractUp2==0)
        {
         m_FractUp1 = Fup;
         m_FTimeUp1 = time_3;
        }
      if(m_FractUp1!=0 && m_FractUp2==0 && m_FTimeUp1!=time_3)
        {
         m_FractUp2 = Fup;
         m_FTimeUp2 = time_3;
        }
      if(m_FractUp1!=0 && m_FractUp2!=0 && m_FTimeUp2!=time_3)
        {
         m_FractUp1 = m_FractUp2;
         m_FTimeUp1 = m_FTimeUp2;
         m_FractUp2 = Fup;
         m_FTimeUp2 = time_3;
        }
     }
   if(Fdn>0 && Fdn!=EMPTY_VALUE)
     {
      if(m_FractDn1==0 && m_FractDn2==0)
        {
         m_FractDn1 = Fdn;
         m_FTimeDn1 = time_3;
        }
      if(m_FractDn1!=0 && m_FractDn2==0 && m_FTimeDn1!=time_3)
        {
         m_FractDn2 = Fdn;
         m_FTimeDn2 = time_3;
        }
      if(m_FractDn1!=0 && m_FractDn2!=0 && m_FTimeDn2!=time_3)
        {
         m_FractDn1 = m_FractDn2;
         m_FTimeDn1 = m_FTimeDn2;
         m_FractDn2 = Fdn;
         m_FTimeDn2 = time_3;
        }
     }
   double lvldn,lvlup;
   double I1=iCustomGet(0,1);

   bool buys=false,sells=false;
   IsPositionExists(buys,sells);

   if(m_FractUp1!=0 && m_FractUp1!=EMPTY_VALUE && m_FractUp2!=0 && m_FractUp2!=EMPTY_VALUE)
     {
      lvlup = LevelCalculate(m_FractUp1, m_FTimeUp1, m_FractUp2, m_FTimeUp2, time_0);
      lvldn = LevelCalculate(m_FractDn1, m_FTimeDn1, m_FractDn2, m_FTimeDn2, time_0);

      if(m_symbol.Ask()>lvlup && iClose(m_symbol.Name(),Period(),1)>lvlup && I1<0)
        {
         double Lot=TradeSizeOptimized();
         double sl=(InpStopLossBuy==0)?0.0:m_symbol.Ask()-ExtStopLossBuy;
         double tp=(InpTakeProfitBuy==0)?0.0:m_symbol.Ask()+ExtTakeProfitBuy;
         OpenBuy(Lot,sl,tp);
         ClosePositions(POSITION_TYPE_SELL);
         return;
        }
     }
   if(m_FractDn1!=0 && m_FractDn1!=EMPTY_VALUE && m_FractDn2!=0 && m_FractDn2!=EMPTY_VALUE)
     {
      lvldn = LevelCalculate(m_FractDn1, m_FTimeDn1, m_FractDn2, m_FTimeDn2, time_0);
      lvlup = LevelCalculate(m_FractUp1, m_FTimeUp1, m_FractUp2, m_FTimeUp2, time_0);

      if(lvldn>m_symbol.Bid() && iClose(m_symbol.Name(),Period(),1)<lvldn && I1>0)
        {
         double Lot=TradeSizeOptimized();
         double sl=(InpStopLossSell==0)?0.0:m_symbol.Bid()+ExtStopLossSell;
         double tp=(InpTakeProfitSell==0)?0.0:m_symbol.Bid()-ExtTakeProfitSell;
         OpenSell(Lot,sl,tp);
         ClosePositions(POSITION_TYPE_BUY);
         return;
        }
     }
//---
   Trailing();
//---

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
//| Get value of buffers for the iFractals                           |
//|  the buffer numbers are the following:                           |
//|   0 - UPPER_LINE, 1 - LOWER_LINE                                 |
//+------------------------------------------------------------------+
double iFractalsGet(const int buffer,const int index)
  {
   double Fractals[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iFractalsBuffer array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iFractals,buffer,index,1,Fractals)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iFractals indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(Fractals[0]);
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
//| Level calculate                                                  |
//+------------------------------------------------------------------+
double LevelCalculate(const double Price1,const double Time1,const double Price2,
                      const double Time2,const double NewTime)
  {
   double level;
   level=(Price1+Price2)/2.0;
//---
   return(level);
  }
//+------------------------------------------------------------------+
//| Is Buy and Sell Position Exists                                  |
//+------------------------------------------------------------------+
void IsPositionExists(bool &buys,bool &sells)
  {
   buys=false;
   sells=false;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
               buys=true;

            if(m_position.PositionType()==POSITION_TYPE_SELL)
               sells=true;

            if(buys && sells)
               return;
           }
//---
   return;
  }
//+------------------------------------------------------------------+
//| Close positions                                                  |
//+------------------------------------------------------------------+
void ClosePositions(const ENUM_POSITION_TYPE pos_type)
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current positions
      if(m_position.SelectByIndex(i))     // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
            if(m_position.PositionType()==pos_type) // gets the position type
               m_trade.PositionClose(m_position.Ticket()); // close a position by the specified symbol
  }
//+------------------------------------------------------------------+
//| Trailing                                                         |
//+------------------------------------------------------------------+
void Trailing()
  {
   if(InpTrailingStopBuy==0 && InpTrailingStopSell==0)
      return;
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtTrailingStopBuy+ExtTrailingStep)
                  if(m_position.StopLoss()<m_position.PriceCurrent()-(ExtTrailingStopBuy+ExtTrailingStep))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()-ExtTrailingStopBuy),
                        m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                     continue;
                    }
              }
            else
              {
               if(m_position.PriceOpen()-m_position.PriceCurrent()>ExtTrailingStopSell+ExtTrailingStep)
                  if((m_position.StopLoss()>(m_position.PriceCurrent()+(ExtTrailingStopSell+ExtTrailingStep))) || 
                     (m_position.StopLoss()==0))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),
                        m_symbol.NormalizePrice(m_position.PriceCurrent()+ExtTrailingStopSell),
                        m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                    }
              }

           }
  }
//+------------------------------------------------------------------+
//| Calculate optimal lot size                                       |
//+------------------------------------------------------------------+
double TradeSizeOptimized(void)
  {
   double price=m_symbol.Ask();
   double margin=0.0;
//--- select lot size
   margin=m_account.MarginCheck(m_symbol.Name(),ORDER_TYPE_BUY,1.0,price);
   if(margin<=0.0 || margin==EMPTY_VALUE)
      return(0.0);
   double lot=NormalizeDouble(m_account.FreeMargin()*InpMaximumRisk/margin,2);
//--- calculate number of losses orders without a break
   if(InpDecreaseFactor>0)
     {
      //--- select history for access
      HistorySelect(0,TimeCurrent());
      //---
      int    orders=HistoryDealsTotal();  // total history deals
      int    losses=0;                    // number of losses orders without a break

      for(int i=orders-1;i>=0;i--)
        {
         ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0)
           {
            Print("HistoryDealGetTicket failed, no trade history");
            break;
           }
         //--- check symbol
         if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=m_symbol.Name())
            continue;
         //--- check Expert Magic number
         if(HistoryDealGetInteger(ticket,DEAL_MAGIC)!=m_magic)
            continue;
         //--- check profit
         double profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         if(profit>0.0)
            break;
         if(profit<0.0)
            losses++;
        }
      //---
      if(losses>1)
         lot=NormalizeDouble(lot-lot*losses/InpDecreaseFactor,1);
     }
//--- normalize and check limits
   double stepvol=m_symbol.LotsStep();
   lot=stepvol*NormalizeDouble(lot/stepvol,0);

   double minvol=m_symbol.LotsMin();
   if(lot<minvol)
      lot=minvol;

   double maxvol=m_symbol.LotsMax();
   if(lot>maxvol)
      lot=maxvol;
//--- return trading volume
   return(lot);
  }
//+------------------------------------------------------------------+
//| Open Buy position                                                |
//+------------------------------------------------------------------+
void OpenBuy(double lot,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot,m_symbol.Ask(),ORDER_TYPE_BUY);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=lot)
        {
         if(m_trade.Buy(lot,m_symbol.Name(),m_symbol.Ask(),sl,tp,m_comment))
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
void OpenSell(double lot,double sl,double tp)
  {
   sl=m_symbol.NormalizePrice(sl);
   tp=m_symbol.NormalizePrice(tp);
//--- check volume before OrderSend to avoid "not enough money" error (CTrade)
   double check_volume_lot=m_trade.CheckVolume(m_symbol.Name(),lot,m_symbol.Bid(),ORDER_TYPE_SELL);

   if(check_volume_lot!=0.0)
     {
      if(check_volume_lot>=lot)
        {
         if(m_trade.Sell(lot,m_symbol.Name(),m_symbol.Bid(),sl,tp,m_comment))
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
   int d=0;
  }
//+------------------------------------------------------------------+

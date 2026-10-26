//+------------------------------------------------------------------+
//|                              RSI EA(barabashkakvn's edition).mq5 |
//|                        Copyright 2015, MetaQuotes Software Corp. |
//|                           http://free-bonus-deposit.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, dXerof"
#property link      "http://free-bonus-deposit.blogspot.com"
#property version   "1.001"
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Expert\Money\MoneyFixedMargin.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CMoneyFixedMargin m_money;
//---
input bool     OpenBUY           = true;     // Buy positions
input bool     OpenSELL          = true;     // Sell positions
input bool     CloseBySignal     = true;     // CloseBySignal
input ushort   InpStopLoss       = 0.0;      // StopLoss
input ushort   InpTakeProfit     = 0.0;      // TakeProfit
input ushort   InpTrailingStop   = 0;        // TrailingStop
input int      RSIperiod         = 14;       // RSIperiod
input double   RsiBuyLevel       = 30.0;     // RsiBuyLevel
input double   RsiSellLevel      = 70.0;     // RsiSellLevel
input bool     AutoLot           = true;     // AutoLot (percent from a free margin)
input double   Risk              = 10;       // Risk percent from a free margin
input double   ManualLots        = 0.1;      // ManualLots
input ulong    m_magic           = 123;      // Magic number
input string   TradeComment      = "RSI EA"; // TradeComment
input ulong    InpSlippage       = 1;        // Slippage
//---
int LotDigits;
//---
double         ExtStopLoss=0.0;
double         ExtTakeProfit=0.0;
double         ExtTrailingStop=0.0;
ulong          ExtSlippage=0;
ENUM_ACCOUNT_MARGIN_MODE m_margin_mode;
double         m_adjusted_point;             // point value adjusted for 3 or 5 points
int            handle_iRSI;                  // variable for storing the handle of the iRSI indicator
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   SetMarginMode();
   if(!IsHedging())
     {
      Print("Hedging only!");
      return(INIT_FAILED);
     }
//---
   m_symbol.Name(Symbol());                  // sets symbol name
   if(!RefreshRates())
     {
      Print("Error RefreshRates. Bid=",DoubleToString(m_symbol.Bid(),Digits()),
            ", Ask=",DoubleToString(m_symbol.Ask(),Digits()));
      return(INIT_FAILED);
     }
   m_symbol.Refresh();
//---
   m_trade.SetExpertMagicNumber(m_magic);    // sets magic number

//--- tuning for 3 or 5 digits
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
   m_adjusted_point=m_symbol.Point()*digits_adjust;

   ExtStopLoss       = InpStopLoss     * m_adjusted_point;
   ExtTakeProfit     = InpTakeProfit   * m_adjusted_point;
   ExtTrailingStop   = InpTrailingStop * m_adjusted_point;
   ExtSlippage       = InpSlippage     * digits_adjust;

   m_trade.SetDeviationInPoints(ExtSlippage);
//---
   if(!m_money.Init(GetPointer(m_symbol),Period(),m_adjusted_point))
      return(INIT_FAILED);
   m_money.Percent(10); // 10% risk
//--- create handle of the indicator iRSI
   handle_iRSI=iRSI(Symbol(),Period(),RSIperiod,PRICE_CLOSE);
//--- if the handle is not created 
   if(handle_iRSI==INVALID_HANDLE)
     {
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d",
                  Symbol(),
                  EnumToString(Period()),
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
//---
   int total_buy=0;
   int total_sell=0;
//--- считаем позиции Buy и Sell, а также модифицируем (если задано во входных параметрах)
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               total_buy++;
               if(ExtTrailingStop>0)
                 {
                  if(m_position.PriceCurrent()>m_position.PriceOpen())
                     if(m_position.PriceCurrent()-2*ExtTrailingStop>m_position.StopLoss())
                       {
                        double sl=NormalizeDouble(m_position.PriceCurrent()-ExtTrailingStop,m_symbol.Digits());
                        m_trade.PositionModify(m_position.Ticket(),sl,m_position.TakeProfit());
                       }
                 }
              }

            if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               total_sell++;
               if(ExtTrailingStop>0)
                 {
                  if(m_position.PriceCurrent()<m_position.PriceOpen())
                     if(m_position.PriceCurrent()+2*ExtTrailingStop<m_position.StopLoss())
                       {
                        double sl=NormalizeDouble(m_position.PriceCurrent()+ExtTrailingStop,m_symbol.Digits());
                        m_trade.PositionModify(m_position.Ticket(),sl,m_position.TakeProfit());
                       }
                 }
              }
           }
//---
   double rsi_0=iRSIGet(0);
   double rsi_1=iRSIGet(1);
//--- close position by signal
   if(CloseBySignal)
     {
      if(total_buy>0 && rsi_0<RsiSellLevel && rsi_1>RsiSellLevel)
         ClosePositions(POSITION_TYPE_BUY);
      if(total_sell>0 && rsi_0>RsiBuyLevel && rsi_1<RsiBuyLevel)
         ClosePositions(POSITION_TYPE_SELL);
     }
//--- open position
   if(OpenSELL && total_sell<1 && rsi_0<RsiSellLevel && rsi_1>RsiSellLevel)
      OPSELL();
   if(OpenBUY && total_buy<1 && rsi_0>RsiBuyLevel && rsi_1<RsiBuyLevel)
      OPBUY();
//---
   return;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OPBUY()
  {
   if(!RefreshRates())
      return;

   double StopLossLevel=0.0;
   double TakeProfitLevel=0.0;

   if(ExtStopLoss>0)
      StopLossLevel=m_symbol.NormalizePrice(m_symbol.Ask()-ExtStopLoss);
   if(ExtTakeProfit>0)
      TakeProfitLevel=m_symbol.NormalizePrice(m_symbol.Ask()+ExtTakeProfit);

   double volume=LOT();
   if(volume!=0.0)
      m_trade.Buy(volume,NULL,m_symbol.Ask(),StopLossLevel,TakeProfitLevel,TradeComment);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OPSELL()
  {
   if(!RefreshRates())
      return;

   double StopLossLevel=0.0;
   double TakeProfitLevel=0.0;

   if(ExtStopLoss>0)
      StopLossLevel=m_symbol.NormalizePrice(m_symbol.Bid()+ExtStopLoss);
   if(ExtTakeProfit>0)
      TakeProfitLevel=m_symbol.NormalizePrice(m_symbol.Bid()-ExtTakeProfit);
//---
   double volume=LOT();
   if(volume!=0.0)
      m_trade.Sell(volume,NULL,m_symbol.Bid(),StopLossLevel,TakeProfitLevel,TradeComment);
  }
//+------------------------------------------------------------------+
//| Close Positions                                                  |
//+------------------------------------------------------------------+
void ClosePositions(ENUM_POSITION_TYPE pos_type)
  {
   for(int i=PositionsTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==Symbol() && m_position.Magic()==m_magic)
            if(m_position.PositionType()==pos_type)
               m_trade.PositionClose(m_position.Ticket());
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double LOT()
  {
   double lots=0.0;
//---
   if(AutoLot)
     {
      lots=0.0;
      //--- getting lot size for open long position (CMoneyFixedMargin)
      double sl=0.0;
      double check_open_long_lot=m_money.CheckOpenLong(m_symbol.Ask(),sl);

      if(check_open_long_lot==0.0)
         return(0.0);

      //--- check volume before OrderSend to avoid "not enough money" error (CTrade)
      double chek_volime_lot=m_trade.CheckVolume(m_symbol.Name(),check_open_long_lot,m_symbol.Ask(),ORDER_TYPE_BUY);

      if(chek_volime_lot!=0.0)
         if(chek_volime_lot>=check_open_long_lot)
            lots=check_open_long_lot;
     }
   else
      lots=ManualLots;
//---
   return(LotCheck(lots));
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
//|                                                                  |
//+------------------------------------------------------------------+
void SetMarginMode(void)
  {
   m_margin_mode=(ENUM_ACCOUNT_MARGIN_MODE)AccountInfoInteger(ACCOUNT_MARGIN_MODE);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsHedging(void)
  {
   return(m_margin_mode==ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
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
//| Get value of buffers for the iRSI                                |
//+------------------------------------------------------------------+
double iRSIGet(const int index)
  {
   double RSI[1];
//--- reset error code 
   ResetLastError();
//--- fill a part of the iRSI array with values from the indicator buffer that has 0 index 
   if(CopyBuffer(handle_iRSI,0,index,1,RSI)<0)
     {
      //--- if the copying fails, tell the error code 
      PrintFormat("Failed to copy data from the iRSI indicator, error code %d",GetLastError());
      //--- quit with zero result - it means that the indicator is considered as not calculated 
      return(0.0);
     }
   return(RSI[0]);
  }
//+------------------------------------------------------------------+

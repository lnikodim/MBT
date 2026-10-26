//+------------------------------------------------------------------+
//|                      Universal 1.64(barabashkakvn's edition).mq5 |
//|                                                            Drknn |
//|                   02.03.2007                       drknn@mail.ru |
//+------------------------------------------------------------------+
#property copyright "Drknn"
#property link      "drknn@mail.ru"
#property version   "1.000"
//---
#include <Trade\PositionInfo.mqh>
#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>  
#include <Trade\AccountInfo.mqh>
#include <Trade\OrderInfo.mqh>
CPositionInfo  m_position;                   // trade position object
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
COrderInfo     m_order;                      // pending orders object
//+------------------------------------------------------------------+
//| The adviser is able to:                                          |
//| - Trailing orders of any type (both market and deferred)         |
//| - Pipsing                                                        |
//| - Catch an increase in the deposit by NNN percent and            |
//| -- notify that the deposit is increased by NNN percent           |
//| - Establish those pending orders, which allow the user           |
//| - Shows what's on the screen and how it's tuned,                 |
//| -- so that each time it does not climb into the settings         |
//| - The adviser was conceived as a universal trailing,             |
//| -- and everything else was added only for convenience.           |
//| - Если пользователь разрешил советнику устанавливать отложенный ордер какого либо типа,         |
//|   то этот ордер будет установлен от текущей цены на расстоянии _Step для ордеров данного типа.  |
//+-------------------------------------------------------------------------------------------------+
//--- input parameters
input string   t1="------ For all open manually, the magic number is \"0\" ------";
input ulong    m_magic=0;              // magic number 
input double   Lot=0.2;                // Lot
input string   t2="------ Pending Order Switches ------";
input bool     WaitClose=true;         // Wait close position
input bool     Ustan_BuyStop=true;     // Allow/prohibit BUY STOP
input bool     Ustan_SellLimit=false;  // Allow/prohibit SELL LIMIT
input bool     Ustan_SellStop=true;    // Allow/prohibit SELL STOP
input bool     Ustan_BuyLimit=false;   // Allow/prohibit BUY LIMIT
input string   t3="------ Position parameters ------";
input int      ryn_MaxOrderov=2;       // Maximum number of positions of one type
input int      ryn_TakeProfit=200;     // TakeProfit of positions
input int      ryn_StopLoss=100;       // StopLoss of positions
input int      ryn_TrStop=100;         // Trailing Stop of positions. "0" --> off 
input int      ryn_TrStep=10;          // Trailing Step of positions
input bool     WaitProfit=true;        // Wait profit, "true" -> wait breakeven
input string   t4="------ Stop order parameters ------";
input int      st_Step=50;             // Distance from current price to Stop Order level
input int      st_TakeProfit=200;      // TakeProfit Stop Orders
input int      st_StopLoss=100;        // StopLoss Stop Orders
input int      st_TrStop=0;            // Trailing Stop of a Stop Orders. "0" --> off and Trailing Step is not important
input int      st_TrStep=3;            // Trailing Step of a Stop Orders
input string   t5="------ Limit order parameters ------";
input int      lim_Step=50;            // Distance from current price to Limit Order level
input int      lim_TakeProfit=200;     // TakeProfit Limit Orders 
input int      lim_StopLoss=100;       // StopLoss Limit Orders 
input int      lim_TrStop=0;           // Trailing Stop of a Limit Orders. "0" --> off and Trailing Step is not important
input int      lim_TrStep=3;           // Trailing Step of a Limit Orders
input string   t6="------ Only for work on time ------";
input bool     UseTime=true;           // Use time
input uchar    Hhour=23;               // Terminal hours of the deals
input uchar    Mminute=59;             // Terminal minutes of the deals
input bool     TIME_Buy=false;         // Use open Buy on time
input bool     TIME_Sell=false;        // Use open Sell on time
input bool     TIME_BuyStop=true;      // Use pending Buy Stop on time
input bool     TIME_SellLimit=false;   // Use pending Sell Limit on time
input bool     TIME_SellStop=true;     // Use pending Sell Stop on time
input bool     TIME_BuyLimit=false;    // Use pending Buy Limit on time
input string   t7="------ Pipsing ------";
input int      PipsProfit=0;           // Pipsing profit
input string   t8="------ Глобальные уровни ------";
input bool     UseGlobalLevels=true;   // To catch the increase/decrease of the deposit by NNN percent
input double   Global_TakeProfit=2.0;  // Global TakeProfit (given in percent)
input double   Global_StopLoss=2.0;    // Global StopLoss (given in percent)
//---   
string     Comm1,Comm2,Comm3,Comm4,Comm5,Comm6,Comm7,ED;
double     NewPrice,SL,TP,Balans,Free;
long       MinLevel,m_MinLevel,GTP,GSL;
int        SchBuyStop,SchSellStop,SchBuyLimit,SchSellLimit,SchSell,SchBuy,SBid,SAsk,BBid,BAsk,GLE;
bool       fm,Rezult,SigBuy,SigSell,NewOrder;
bool       SigTIME_Buy,SigTIME_Sell,SigTIME_BuyStop,SigTIME_SellLimit,SigTIME_SellStop,SigTIME_BuyLimit;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   if(!m_symbol.Name(Symbol())) // sets symbol name
      return(INIT_FAILED);
   RefreshRates();

   string err_text="";
   if(!CheckVolumeValue(Lot,err_text))
     {
      Print(__FUNCTION__,", ERROR: ",err_text);
      return(INIT_PARAMETERS_INCORRECT);
     }
//---
   m_trade.SetExpertMagicNumber(m_magic);
//---
   if(IsFillingTypeAllowed(SYMBOL_FILLING_FOK))
      m_trade.SetTypeFilling(ORDER_FILLING_FOK);
   else if(IsFillingTypeAllowed(SYMBOL_FILLING_IOC))
      m_trade.SetTypeFilling(ORDER_FILLING_IOC);
   else
      m_trade.SetTypeFilling(ORDER_FILLING_RETURN);
//---
   if(!IsTradeAllowed())
     {
      return(INIT_FAILED);
     }
   else
     {
      Comment("As soon as the price changes, Advisor to start work");
      Alert("As soon as the price changes, Advisor to start work");
     }
   if(m_symbol.Point()==0)
     {
      Alert(__FUNCTION__,", ERROR: SYMBOL_POINT == 0");
      return(INIT_FAILED);
     }
//--- The minimum allowable level of stop-loss / take-profit in points
//--- If it is zero, then it takes the size of three spreads
   MinLevel=m_symbol.StopsLevel();
   Verification();
//---
   Balans=m_account.Balance();      // Account balance in the deposit currency
   Free=m_account.Equity();         // Account equity in the deposit currency
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
//--- Primary Data Validation
   if(!IsTradeAllowed())
      return;
   Verification();
//--- End of primary data checks
   if(ryn_TrStop>0 && ryn_TrStop>=MinLevel)
      Comm1="Trailing market - On";
   else
      Comm1="Trailing market - Off";
   if(lim_TrStop>0 && lim_TrStop>=MinLevel)
      Comm2="Trailing Limit Orders - On";
   else
      Comm2="Trailing Limit Orders - Off";
   if(st_TrStop>0 && st_TrStop>=MinLevel)
      Comm3="Trailing Stop Orders - On";
   else
      Comm3="Trailing Stop Orders - Off";
   if(PipsProfit>0)
      Comm4="Pipsing - On";
   else
      Comm4="Pipsing - Off";
   double OtlTP=(Balans/100.0*Global_TakeProfit+Balans);
   double OtlSL=(Balans-Balans/100.0*Global_StopLoss);
   GTP=(long)MathCeil(OtlTP);
   GSL=(long)MathCeil(OtlSL);
   if(UseGlobalLevels)
     {
      Comm5="- - - - Global levels - - - -";
      Comm6="Global TakeProfit = "+IntegerToString(GTP)+" "+AccountInfoString(ACCOUNT_CURRENCY);
      Comm7="Global StopLoss   = "+IntegerToString(GSL)+" "+AccountInfoString(ACCOUNT_CURRENCY);
     }
   else
     {
      Comm5="Global levels - Off"; Comm6=""; Comm7="";
     }
   SchOrders();
   Comment("Number of positions and pending orders for ",m_symbol.Name()," :","\n","Buy = ",SchBuy,"       Sell = ",SchSell,"\n","BuyStop = ",SchBuyStop,
           "   SellLimit = ",SchSellLimit,"\n","SellStop = ",SchSellStop,"    BuyLimit = ",SchBuyLimit,"\n",Comm1,
           "\n",Comm2,"\n",Comm3,"\n",Comm4,"\n",Comm5,"\n",Comm6,"\n",Comm7);
//--- Placing Pending Orders 
   if(Ustan_BuyStop || Ustan_SellLimit || Ustan_SellStop || Ustan_BuyLimit)
      UstanOtlozh();
//--- Work on a given time 
   if(UseTime)
     {
      SigTIME_Buy=false;  SigTIME_BuyStop=false;   SigTIME_SellStop=false;
      SigTIME_Sell=false; SigTIME_SellLimit=false; SigTIME_BuyLimit=false;
      MqlDateTime str1;
      TimeToStruct(TimeCurrent(),str1);
      if(str1.hour==Hhour && str1.min==Mminute) // if the current hour and minute coincide
        {
         if(TIME_Buy)
           {
            SigTIME_Buy=true;
            UstanRyn();
           }
         if(TIME_Sell)
           {
            SigTIME_Sell=true;
            UstanRyn();
           }
         if(TIME_BuyStop)
           {
            SigTIME_BuyStop=true;
            UstanOtlozh();
           }
         if(TIME_SellLimit)
           {
            SigTIME_SellLimit=true;
            UstanOtlozh();
           }
         if(TIME_SellStop)
           {
            SigTIME_SellStop=true;
            UstanOtlozh();
           }
         if(TIME_BuyLimit)
           {
            SigTIME_BuyLimit=true;
            UstanOtlozh();
           }
        }
     }
//--- We catch the increase in the deposit by NNN percent 
   if(UseGlobalLevels) // If it is allowed to catch a percentage increase / decrease in deposit
     {
      Balans=m_account.Balance();      // Account balance in the deposit currency
      Free=m_account.Equity();         // Account equity in the deposit currency
      if((Free-Balans)>=(Balans/100.0*Global_TakeProfit))
        {
         Print("The deposit is increased by ",Global_TakeProfit," percent. Total profit = ",Free);
         Comment("The deposit is increased by ",Global_TakeProfit," percent. Total profit = ",Free);
        }
      if((Balans-Free)>=(Balans/100.0*Global_StopLoss))
        {
         Print("The deposit is reduced by ",Global_StopLoss," percent. Total StopLoss = ",Free);
         Comment("The deposit is reduced by ",Global_StopLoss," percent. Total StopLoss = ",Free);
        }
     }
//--- Pipsing
   if(PipsProfit>0)
     {
      for(int i=PositionsTotal()-1;i>=0;i--)
         if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
            if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
              {
               if(m_position.PositionType()==POSITION_TYPE_BUY)
                  if(m_position.PriceCurrent()>=m_position.PriceOpen()+PipsProfit*m_symbol.Point())
                     m_trade.PositionClose(m_position.Ticket());

               if(m_position.PositionType()==POSITION_TYPE_SELL)
                  if(m_position.PriceOpen()>=m_position.PriceCurrent()+PipsProfit*m_symbol.Point())
                     m_trade.PositionClose(m_position.Ticket());
              }
     }
//--- Trailing positions
   SchOrders();
   if(SchBuy>0 || SchSell>0)
     {
      if(ryn_TrStop>=MinLevel && ryn_TrStep>0)
        {
         for(int i=PositionsTotal()-1;i>=0;i--)
            if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
               if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
                 {
                  if(m_position.PositionType()==POSITION_TYPE_BUY)
                    {
                     if(!WaitProfit || (m_position.PriceCurrent()-m_position.PriceOpen())>ryn_TrStop*m_symbol.Point())
                       {
                        if(m_position.StopLoss()<m_position.PriceCurrent()-(ryn_TrStop+ryn_TrStep-1)*m_symbol.Point())
                          {
                           if(!m_trade.PositionModify(m_position.Ticket(),
                              m_symbol.NormalizePrice(m_position.PriceCurrent()-ryn_TrStop*m_symbol.Point()),
                              m_position.TakeProfit()))
                              Print("Modify BUY ",m_position.Ticket(),
                                    " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                    ", description of result: ",m_trade.ResultRetcodeDescription());
                           continue;
                          }
                       }
                    }

                  if(m_position.PositionType()==POSITION_TYPE_SELL)
                    {
                     if(!WaitProfit || m_position.PriceOpen()-m_position.PriceCurrent()>ryn_TrStop*m_symbol.Point())
                       {
                        if(m_position.StopLoss()>m_position.PriceCurrent()+(ryn_TrStop+ryn_TrStep-1)*m_symbol.Point() || m_position.StopLoss()==0.0)
                          {

                           if(!m_trade.PositionModify(m_position.Ticket(),
                              m_symbol.NormalizePrice(m_position.PriceCurrent()+ryn_TrStop*m_symbol.Point()),
                              m_position.TakeProfit()))
                              Print("Modify SELL ",m_position.Ticket(),
                                    " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                    ", description of result: ",m_trade.ResultRetcodeDescription());
                           continue;
                          }
                       }
                    }
                 }
        }
      else if(ryn_TrStop>=MinLevel && ryn_TrStep==0)
        {
         Print("ERROR: \"Trailing Step of positions\" can not be 0");
         Comment("ERROR: \"Trailing Step of positions\" can not be 0");
        }
     }
//--- Trailing pending orders =============================================================
   SchOrders();
   if((st_TrStop>0 && SchBuyStop+SchSellStop>0) || (SchBuyLimit+SchSellLimit>0 && lim_TrStop>0))
     {
      //---
      for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
         if(m_order.SelectByIndex(i)) // selects the pending order by index for further access to its properties
            if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
              {
               if(m_order.OrderType()==ORDER_TYPE_BUY_LIMIT) // He's downstairs and goes up
                  if(m_order.PriceCurrent()>m_order.PriceOpen()+(lim_TrStop+lim_TrStep)*m_symbol.Point())
                    {
                     NewPrice=m_order.PriceCurrent()-lim_TrStop*m_symbol.Point();
                     if(lim_StopLoss==0)
                        SL=0.0;
                     else
                        SL=NewPrice-lim_StopLoss*m_symbol.Point();
                     if(lim_TakeProfit==0)
                        TP=0.0;
                     else
                        TP=NewPrice+lim_TakeProfit*m_symbol.Point();
                     if(m_trade.OrderModify(m_order.Ticket(),
                        m_symbol.NormalizePrice(NewPrice),
                        m_symbol.NormalizePrice(SL),
                        m_symbol.NormalizePrice(TP),
                        m_order.TypeTime(),
                        m_order.TimeExpiration()))
                        Print("Modify BUY LIMIT - > true. ticket of order = ",m_trade.ResultOrder());
                     else
                        Print("Modify BUY LIMIT -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of Retcode: ",m_trade.ResultRetcodeDescription());
                    }
               if(m_order.OrderType()==ORDER_TYPE_SELL_LIMIT) // He's upstairs and is driving down
                  if(m_order.PriceCurrent()<m_order.PriceOpen()-(lim_TrStop+lim_TrStep)*m_symbol.Point())
                    {
                     NewPrice=m_order.PriceCurrent()+lim_TrStop*m_symbol.Point();
                     if(lim_StopLoss==0)
                        SL=0.0;
                     else
                        SL=NewPrice+lim_StopLoss*m_symbol.Point();
                     if(lim_TakeProfit==0)
                        TP=0.0;
                     else
                        TP=NewPrice-lim_TakeProfit*m_symbol.Point();
                     if(m_trade.OrderModify(m_order.Ticket(),
                        m_symbol.NormalizePrice(NewPrice),
                        m_symbol.NormalizePrice(SL),
                        m_symbol.NormalizePrice(TP),
                        m_order.TypeTime(),
                        m_order.TimeExpiration()))
                        Print("Modify SELL LIMIT - > true. ticket of order = ",m_trade.ResultOrder());
                     else
                        Print("Modify SELL LIMIT -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of Retcode: ",m_trade.ResultRetcodeDescription());
                    }
               if(m_order.OrderType()==ORDER_TYPE_BUY_STOP) // He's upstairs and is driving down
                  if(m_order.PriceCurrent()<m_order.PriceOpen()-(st_TrStop+st_TrStep)*m_symbol.Point())
                    {
                     NewPrice=m_order.PriceCurrent()+st_TrStop*m_symbol.Point();
                     if(st_StopLoss==0)
                        SL=0.0;
                     else
                        SL=NewPrice-st_StopLoss*m_symbol.Point();
                     if(st_TakeProfit==0)
                        TP=0.0;
                     else
                        TP=NewPrice+st_TakeProfit*m_symbol.Point();
                     if(m_trade.OrderModify(m_order.Ticket(),
                        m_symbol.NormalizePrice(NewPrice),
                        m_symbol.NormalizePrice(SL),
                        m_symbol.NormalizePrice(TP),
                        m_order.TypeTime(),
                        m_order.TimeExpiration()))
                        Print("Modify BUY STOP - > true. ticket of order = ",m_trade.ResultOrder());
                     else
                        Print("Modify BUY STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of Retcode: ",m_trade.ResultRetcodeDescription());
                    }
               if(m_order.OrderType()==ORDER_TYPE_SELL_STOP) // He's downstairs and goes up !!!!
                  if(m_order.PriceCurrent()>m_order.PriceOpen()+(st_TrStop+st_TrStep)*m_symbol.Point())
                    {
                     NewPrice=m_order.PriceCurrent()-st_TrStop*m_symbol.Point();
                     if(st_StopLoss==0)
                        SL=0.0;
                     else
                        SL=NewPrice+st_StopLoss*m_symbol.Point();
                     if(st_TakeProfit==0)
                        TP=0.0;
                     else
                        TP=NewPrice-st_TakeProfit*m_symbol.Point();
                     if(m_trade.OrderModify(m_order.Ticket(),
                        m_symbol.NormalizePrice(NewPrice),
                        m_symbol.NormalizePrice(SL),
                        m_symbol.NormalizePrice(TP),
                        m_order.TypeTime(),
                        m_order.TimeExpiration()))
                        Print("Modify SELL STOP - > true. ticket of order = ",m_trade.ResultOrder());
                     else
                        Print("Modify SELL STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of Retcode: ",m_trade.ResultRetcodeDescription());
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
//| Check the correctness of the order volume                        |
//+------------------------------------------------------------------+
bool CheckVolumeValue(double volume,string &error_description)
  {
//--- minimal allowed volume for trade operations
   double min_volume=m_symbol.LotsMin();
   if(volume<min_volume)
     {
      error_description=StringFormat("Volume is less than the minimal allowed SYMBOL_VOLUME_MIN=%.2f",min_volume);
      return(false);
     }
//--- maximal allowed volume of trade operations
   double max_volume=m_symbol.LotsMax();
   if(volume>max_volume)
     {
      error_description=StringFormat("Volume is greater than the maximal allowed SYMBOL_VOLUME_MAX=%.2f",max_volume);
      return(false);
     }
//--- get minimal step of volume changing
   double volume_step=m_symbol.LotsStep();
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
bool IsFillingTypeAllowed(int fill_type)
  {
//--- Obtain the value of the property that describes allowed filling modes 
   int filling=m_symbol.TradeFillFlags();
//--- Return true, if mode fill_type is allowed 
   return((filling & fill_type)==fill_type);
  }
//+------------------------------------------------------------------+
//| Gets the information about permission to trade                   |
//+------------------------------------------------------------------+
bool IsTradeAllowed()
  {
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
     {
      Alert(__FUNCTION__,", ERROR: Check if automated trading is allowed in the terminal settings!");
      return(false);
     }
   else
     {
      if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         Alert(__FUNCTION__,", ERROR: Automated trading is forbidden in the program settings for ",__FILE__);
         return(false);
        }
     }
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
     {
      Alert(__FUNCTION__,", ERROR: Automated trading is forbidden for the account ",AccountInfoInteger(ACCOUNT_LOGIN),
            " at the trade server side");
      return(false);
     }
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
     {
      Comment(__FUNCTION__,", ERROR: Trading is forbidden for the account ",AccountInfoInteger(ACCOUNT_LOGIN),
              ".\n Perhaps an investor password has been used to connect to the trading account.",
              "\n Check the terminal journal for the following entry:",
              "\n\'",AccountInfoInteger(ACCOUNT_LOGIN),"\': trading has been disabled - investor mode.");
      return(false);
     }
//---
   return(true);
  }
//+------------------------------------------------------------------+
//| Verify that the user settings are correct                        |
//+------------------------------------------------------------------+
void Verification()
  {
   m_MinLevel=m_symbol.StopsLevel();
   if(m_MinLevel==0)
     {
      MinLevel=3*m_symbol.Spread();
      Print("\"MinLevel\" is equal to three spreads (",MinLevel,")");
      Comment("\"MinLevel\" is equal to three spreads (",MinLevel,")");
     }
   else
      MinLevel=m_MinLevel;
   if(ryn_TrStop<MinLevel && ryn_TrStop!=0)
     {
      Print("ERROR: \"Trailing Stop of positions\" can not be less than ",MinLevel);
      Comment("ERROR: \"Trailing Stop of positions\" can not be less than ",MinLevel);
      return;
     }
   if(ryn_TrStop>=MinLevel && ryn_TrStep==0)
     {
      Print("ERROR: \"Trailing Step of positions\" can not be 0");
      Comment("ERROR: \"Trailing Step of positions\" can not be 0");
      return;
     }
   if(ryn_TakeProfit<MinLevel && ryn_TakeProfit!=0)
     {
      Print("ERROR: \"TakeProfit of positions\" can not be less than ",MinLevel);
      Comment("ERROR: \"TakeProfit of positions\" can not be less than ",MinLevel);
      return;
     }
   if(ryn_StopLoss<MinLevel && ryn_StopLoss!=0)
     {
      Print("ERROR: \"StopLoss of positions\" can not be less than ",MinLevel);
      Comment("ERROR: \"StopLoss of positions\" can not be less than ",MinLevel);
      return;
     }
   if(st_TakeProfit<MinLevel && st_TakeProfit!=0)
     {
      Print("ERROR: \"TakeProfit Stop Orders\" can not be less than ",MinLevel);
      Comment("ERROR: \"TakeProfit Stop Orders\" can not be less than ",MinLevel);
      return;
     }
   if(st_StopLoss<MinLevel && st_StopLoss!=0)
     {
      Print("ERROR: \"StopLoss Stop Orders\" can not be less than ",MinLevel);
      Comment("ERROR: \"StopLoss Stop Orders\" can not be less than ",MinLevel);
      return;
     }
   if(st_TrStop<MinLevel && st_TrStop!=0)
     {
      Print("ERROR: \"Trailing Stop of a Stop Orders\" can not be less than ",MinLevel);
      Comment("ERROR: \"Trailing Stop of a Stop Orders\" can not be less than ",MinLevel);
      return;
     }
   if(st_TrStop>=MinLevel && st_TrStep==0)
     {
      Print("ERROR: \"Trailing Step of a Stop Orders\" can not be 0");
      Comment("ERROR: \"Trailing Step of a Stop Orders\" can not be 0");
      return;
     }
   if(st_Step<MinLevel)
     {
      Print("ERROR: \"Distance from current price to stop order level\" can not be less than ",MinLevel);
      Comment("ERROR: \"Distance from current price to stop order level\" can not be less than ",MinLevel);
      return;
     }
   if(lim_TakeProfit<MinLevel && lim_TakeProfit!=0)
     {
      Print("ERROR: \"TakeProfit Limit Orders\" can not be less than ",MinLevel);
      Comment("ERROR: \"TakeProfit Limit Orders\" can not be less than ",MinLevel);
      return;
     }
   if(lim_StopLoss<MinLevel && lim_StopLoss!=0)
     {
      Print("ERROR: \"StopLoss Limit Orders\" can not be less than ",MinLevel);
      Comment("ERROR: \"StopLoss Limit Orders\" can not be less than ",MinLevel);
      return;
     }
   if(lim_TrStop<MinLevel && lim_TrStop!=0)
     {
      Print("ERROR: \"Trailing Stop of a Limit Orders\" can not be less than ",MinLevel);
      Comment("ERROR: \"Trailing Stop of a Limit Orders\" can not be less than ",MinLevel);
      return;
     }
   if(lim_TrStop>=MinLevel && lim_TrStep==0)
     {
      Print("ERROR: \"Trailing Step of a Limit Orders\" can not be 0");
      Comment("ERROR: \"Trailing Step of a Limit Orders\" can not be 0");
      return;
     }
   if(lim_Step<MinLevel)
     {
      Print("ERROR: \"Distance from current price to Limit Order level\" can not be less than ",MinLevel);
      Comment("ERROR: \"Distance from current price to Limit Order level\" can not be less than ",MinLevel);
      return;
     }
   if(Hhour>23)
     {
      Print("ERROR: \"Terminal hours of the deals\" can be no more 23");
      Comment("ERROR: \"Terminal hours of the deals\" can be no more 23");
      return;
     }
   if(Mminute>59)
     {
      Print("ERROR: \"Terminal minutes of the deals\" can be no more 59");
      Comment("ERROR: \"Terminal minutes of the deals\" can be no more 59");
      return;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SchOrders()
  {
//--- Before starting work, we reset the counters
   SchBuy=0;   SchSell=0;
   SchBuyLimit=0; SchSellLimit=0; SchBuyStop=0; SchSellStop=0;

   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
               SchBuy++;
            if(m_position.PositionType()==POSITION_TYPE_SELL)
               SchSell++;
           }

   for(int i=OrdersTotal()-1;i>=0;i--) // returns the number of current orders
      if(m_order.SelectByIndex(i)) // selects the pending order by index for further access to its properties
         if(m_order.Symbol()==m_symbol.Name() && m_order.Magic()==m_magic)
           {
            if(m_order.OrderType()==ORDER_TYPE_BUY_LIMIT)
               SchBuyLimit++;
            if(m_order.OrderType()==ORDER_TYPE_SELL_LIMIT)
               SchSellLimit++;
            if(m_order.OrderType()==ORDER_TYPE_BUY_STOP)
               SchBuyStop++;
            if(m_order.OrderType()==ORDER_TYPE_SELL_STOP)
               SchSellStop++;
           }
  }
//+------------------------------------------------------------------+
//| Placing Pending Orders                                           |
//+------------------------------------------------------------------+
void UstanOtlozh()
  {
   if(!RefreshRates())
      return;
   SchOrders();
//--- BUY LIMIT
   if(
      (SchBuyLimit==0 && (SchBuy<ryn_MaxOrderov || !WaitClose))
      && ((Ustan_BuyLimit && lim_Step>=MinLevel) || (SigTIME_BuyLimit && lim_Step>=MinLevel))
      )
     {
      NewPrice=m_symbol.Ask()-lim_Step*m_symbol.Point();
      if(lim_StopLoss==0)
         SL=0.0;
      else
         SL=NewPrice-lim_StopLoss*m_symbol.Point();
      if(lim_TakeProfit==0)
         TP=0.0;
      else
         TP=NewPrice+st_TakeProfit*m_symbol.Point();
      if(m_trade.BuyLimit(Lot,
         m_symbol.NormalizePrice(NewPrice),
         m_symbol.Name(),
         m_symbol.NormalizePrice(SL),
         m_symbol.NormalizePrice(TP)))
         Print("BUY_LIMIT - > true. ticket of order = ",m_trade.ResultOrder());
      else
         Print("BUY_LIMIT -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of Retcode: ",m_trade.ResultRetcodeDescription());
     }
//--- BUY STOP
   if(
      (SchBuyStop==0 && (SchBuy<ryn_MaxOrderov || !WaitClose))
      && ((Ustan_BuyStop && st_Step>=MinLevel) || (SigTIME_BuyStop && st_Step>=MinLevel))
      )
     {
      NewPrice=m_symbol.Ask()+st_Step*m_symbol.Point();
      if(st_StopLoss==0)
         SL=0.0;
      else
         SL=NewPrice-st_StopLoss*m_symbol.Point();
      if(st_TakeProfit==0)
         TP=0.0;
      else
         TP=NewPrice+st_TakeProfit*m_symbol.Point();
      if(m_trade.BuyStop(Lot,
         m_symbol.NormalizePrice(NewPrice),
         m_symbol.Name(),
         m_symbol.NormalizePrice(SL),
         m_symbol.NormalizePrice(TP)))
         Print("BUY_STOP - > true. ticket of order = ",m_trade.ResultOrder());
      else
         Print("BUY_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of Retcode: ",m_trade.ResultRetcodeDescription());
     }
//--- SELL LIMIT
   if(
      (SchSellLimit==0 && (SchSell<ryn_MaxOrderov || !WaitClose))
      && ((Ustan_SellLimit && lim_Step>=MinLevel) || (SigTIME_SellLimit && lim_Step>=MinLevel))
      )
     {
      NewPrice=m_symbol.Bid()+lim_Step*m_symbol.Point();
      if(lim_StopLoss==0)
         SL=0.0;
      else
         SL=NewPrice+lim_StopLoss*m_symbol.Point();
      if(lim_TakeProfit==0)
         TP=0.0;
      else
         TP=NewPrice-lim_TakeProfit*m_symbol.Point();
      if(m_trade.SellLimit(Lot,
         m_symbol.NormalizePrice(NewPrice),
         m_symbol.Name(),
         m_symbol.NormalizePrice(SL),
         m_symbol.NormalizePrice(TP)))
         Print("SELL_LIMIT - > true. ticket of order = ",m_trade.ResultOrder());
      else
         Print("SELL_LIMIT -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of Retcode: ",m_trade.ResultRetcodeDescription());
     }
//--- SELL STOP
   if(
      (SchSellStop==0 && (SchSell<ryn_MaxOrderov || !WaitClose))
      && ((Ustan_SellStop && st_Step>=MinLevel) || (SigTIME_SellStop && st_Step>=MinLevel))
      )
     {
      NewPrice=m_symbol.Bid()-st_Step*m_symbol.Point();
      if(st_StopLoss==0)
         SL=0.0;
      else
         SL=NewPrice+st_StopLoss*m_symbol.Point();
      if(st_TakeProfit==0)
         TP=0.0;
      else
         TP=NewPrice-st_TakeProfit*m_symbol.Point();
      if(m_trade.SellStop(Lot,
         m_symbol.NormalizePrice(NewPrice),
         m_symbol.Name(),
         m_symbol.NormalizePrice(SL),
         m_symbol.NormalizePrice(TP)))
         Print("SELL_STOP - > true. ticket of order = ",m_trade.ResultOrder());
      else
         Print("SELL_STOP -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of Retcode: ",m_trade.ResultRetcodeDescription());
     }
  }
//+------------------------------------------------------------------+
//| Open positions                                                   |
//+------------------------------------------------------------------+
void UstanRyn()
  {
   bool NewOrderSell=false,NewOrderBuy=false;
   datetime  OldTimeBuy=0,OldTimeSell=0,time_0=0;
   time_0=iTime(0);
   if(!RefreshRates())
      return;
   SchOrders();
//--- Controlling the time of the last open position 
//--- This control unit is needed in order to open only one position on one candle
//--- If in work for a given time there will be permission to open both Buy and Sell,
//--- the adviser can open both positions on the same candle
   for(int i=PositionsTotal()-1;i>=0;i--)
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==m_magic)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.Time()>=OldTimeBuy) // if the opening time of the position is longer, then ...
                  OldTimeBuy=m_position.Time();   // remember the opening time of the last position Buy
              }
            if(m_position.PositionType()==POSITION_TYPE_SELL)
              {
               if(m_position.Time()>=OldTimeSell) // if the opening time of the position is longer, then ...
                  OldTimeSell=m_position.Time();   // remember the opening time of the last position Sell
              }
           }
//---
   if(OldTimeBuy>=time_0)
      NewOrderBuy=false;
   if(OldTimeBuy<time_0)
      NewOrderBuy=true;
   if(OldTimeSell>=time_0)
      NewOrderSell=false;
   if(OldTimeSell<time_0)
      NewOrderSell=true;
//--- If you can position Buy   
   if(NewOrderBuy && SigTIME_Buy && SchBuy==0)
     {
      if(ryn_StopLoss==0)
         SL=0.0;
      else
         SL=m_symbol.Ask()-ryn_StopLoss*m_symbol.Point();
      if(ryn_TakeProfit==0)
         TP=0.0;
      else
         TP=m_symbol.Ask()+ryn_TakeProfit*m_symbol.Point();
      if(m_trade.Buy(Lot,m_symbol.Name(),
         m_symbol.Ask(),
         m_symbol.NormalizePrice(SL),
         m_symbol.NormalizePrice(TP)))
        {
         if(m_trade.ResultDeal()==0)
           {
            Print("#1 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
           }
         else
           {
            Print("#2 Buy -> true. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
           }
        }
      else
        {
         Print("#3 Buy -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of result: ",m_trade.ResultRetcodeDescription());
        }
     }
//--- If you can position Sell   
   if(NewOrderSell && SigTIME_Sell && SchSell==0)
     {
      if(ryn_StopLoss==0)
         SL=0.0;
      else
         SL=m_symbol.Bid()+ryn_StopLoss*m_symbol.Point();
      if(ryn_TakeProfit==0)
         TP=0.0;
      else
         TP=m_symbol.Bid()-ryn_TakeProfit*m_symbol.Point();
      if(m_trade.Sell(Lot,m_symbol.Name(),
         m_symbol.Bid(),
         m_symbol.NormalizePrice(SL),
         m_symbol.NormalizePrice(TP)))
        {
         if(m_trade.ResultDeal()==0)
           {
            Print("#1 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
           }
         else
           {
            Print("#2 Sell -> true. Result Retcode: ",m_trade.ResultRetcode(),
                  ", description of result: ",m_trade.ResultRetcodeDescription());
           }
        }
      else
        {
         Print("#3 Sell -> false. Result Retcode: ",m_trade.ResultRetcode(),
               ", description of result: ",m_trade.ResultRetcodeDescription());
        }
     }
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
   datetime time=0; // D'1970.01.01 00:00:00'
   int copied=CopyTime(symbol,timeframe,index,1,Time);
   if(copied>0)
      time=Time[0];
   return(time);
  }
//+------------------------------------------------------------------+

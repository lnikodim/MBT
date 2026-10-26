//+------------------------------------------------------------------+
//|                                                   SteepMA_EA.mq5 |
//|                                                  陡峭均线双向策略（开仓+止损） |
//|                                             V0.7t2：开仓时直接设置止损，无修改 |
//+------------------------------------------------------------------+
#property copyright "Your Name"
#property link      ""
#property version   "0.7t2"

enum ENUM_TRADE_DIRECTION
{
   TRADE_DIRECTION_LONG  = 0,
   TRADE_DIRECTION_SHORT = 1,
   TRADE_DIRECTION_BOTH  = 2
};

input int      InpMAPeriod      = 30;
input int      InpAngleSpan     = 60;
input double   InpBuyDeviation  = 7.0;
input double   InpSellDeviation = 10.0;
input double   InpAngleThreshold= 25.0;
input double   InpRiskPercent   = 70.0;
input ENUM_TRADE_DIRECTION InpTradeDirection = TRADE_DIRECTION_BOTH;
input bool     InpUseFixedLots  = false;
input double   InpFixedLots     = 0.1;
input int      InpMinAngleFilter = 10;

int            maHandle;
datetime       lastBarTime;
bool           everReachedSellDevLong  = false;
bool           everReachedSellDevShort = false;

int OnInit()
{
   maHandle = iMA(_Symbol, _Period, InpMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   if(maHandle == INVALID_HANDLE) return(INIT_FAILED);
   lastBarTime = 0;
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   if(maHandle != INVALID_HANDLE) IndicatorRelease(maHandle);
}

bool IsNewBar()
{
   datetime cur = iTime(_Symbol, _Period, 0);
   if(cur != lastBarTime) { lastBarTime = cur; return true; }
   return false;
}

double CalcAngle()
{
   double maNow[1], maAgo[1];
   if(CopyBuffer(maHandle,0,1,1,maNow)<=0 || CopyBuffer(maHandle,0,InpAngleSpan+1,1,maAgo)<=0) return 0.0;
   return MathArctan((maNow[0]-maAgo[0])/InpAngleSpan)*180.0/M_PI;
}

double CalcDeviation()
{
   double ma[1], close[1];
   if(CopyBuffer(maHandle,0,1,1,ma)<=0 || CopyClose(_Symbol,_Period,1,1,close)<=0 || ma[0]==0.0) return 0.0;
   return (close[0]-ma[0])/ma[0]*100.0;
}

double CalculateLots()
{
   if(InpUseFixedLots) return InpFixedLots;
   double equity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(equity<=0) return 0.0;
   double riskMoney = equity * InpRiskPercent/100.0;
   double price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   if(price<=0) return 0.0;
   double nominal = price * SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   if(nominal<=0) return 0.0;
   double lots = riskMoney / nominal;
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lots = MathFloor(lots/step)*step;
   lots = MathMax(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN), MathMin(lots, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX)));
   return lots;
}

int GetPositionDirection()
{
   for(int i = PositionsTotal()-1; i>=0; i--)
   {
      ulong t = PositionGetTicket(i);
      if(PositionSelectByTicket(t) && PositionGetString(POSITION_SYMBOL)==_Symbol)
         return (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ? 1 : -1;
   }
   return 0;
}

bool OpenPosition(ENUM_ORDER_TYPE orderType, double lots)
{
   // 计算止损价格（净值30%）
   double equity     = AccountInfoDouble(ACCOUNT_EQUITY);
   double riskAmount = equity * 0.3;
   double contract   = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);
   double priceShift = (lots * contract > 0) ? riskAmount / (lots * contract) : 0;
   
   double openPrice = (orderType == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                                                    : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double slPrice = (orderType == ORDER_TYPE_BUY) ? openPrice - priceShift : openPrice + priceShift;
   slPrice = NormalizeDouble(slPrice, _Digits);

   MqlTradeRequest req = {};
   MqlTradeResult  res = {};
   req.action    = TRADE_ACTION_DEAL;
   req.symbol    = _Symbol;
   req.volume    = lots;
   req.type      = orderType;
   req.deviation = 10;
   req.type_filling = ORDER_FILLING_FOK;
   req.price     = openPrice;
   req.sl        = slPrice;       // 直接带上止损
   req.tp        = 0;

   if(!OrderSend(req, res))
   {
      Print("开仓失败: ", GetLastError());
      return false;
   }
   Print((orderType == ORDER_TYPE_BUY ? "buy" : "sell"), " 成功，手数:", lots, " 价格:", openPrice, " 止损:", slPrice);
   return true;
}

void OnTick()
{
   if(!IsNewBar()) return;
   double deviation = CalcDeviation(), angle = CalcAngle();
   if(deviation == 0.0 && angle == 0.0) return;
   double ma[1], close[1];
   if(CopyBuffer(maHandle,0,1,1,ma)<=0 || CopyClose(_Symbol,_Period,1,1,close)<=0) return;
   int dir = GetPositionDirection();
   bool canLong = (InpTradeDirection==TRADE_DIRECTION_LONG || InpTradeDirection==TRADE_DIRECTION_BOTH);
   bool canShort = (InpTradeDirection==TRADE_DIRECTION_SHORT || InpTradeDirection==TRADE_DIRECTION_BOTH);
   bool angleFilterOK = (MathAbs(angle) > InpMinAngleFilter);

   bool longSignal = (canLong && close[0]>ma[0] && MathAbs(deviation)<InpBuyDeviation && angle>=InpAngleThreshold && angleFilterOK);
   bool shortSignal = (canShort && close[0]<ma[0] && MathAbs(deviation)<InpBuyDeviation && angle<=-InpAngleThreshold && angleFilterOK);

   if(dir == 0)
   {
      if(longSignal) { double lots = CalculateLots(); if(lots>0 && OpenPosition(ORDER_TYPE_BUY, lots)) { everReachedSellDevLong = false; everReachedSellDevShort = false; } }
      else if(shortSignal) { double lots = CalculateLots(); if(lots>0 && OpenPosition(ORDER_TYPE_SELL, lots)) { everReachedSellDevShort = false; everReachedSellDevLong = false; } }
   }
   // 盘中动态止损修改已全部移除，持仓完全依靠开仓时设置的初始止损
}
//+------------------------------------------------------------------+
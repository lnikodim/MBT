//+------------------------------------------------------------------+
//|  CODE GENERATED with Bots Builder Pro v.1.0.1                    |
//|  --------------------------------------------------------------  |
//|  Code generation date: 2022.12.09 09:27:19                       |
//|  --------------------------------------------------------------  |
//|                     https://www.mql5.com/en/users/wahoo          |
//|  --------------------------------------------------------------  |
#property strict
#property version                                                              "1.0"
#property link                                                                 "https://www.mql5.com/en/users/wahoo"
#property copyright                                                            "Generated with Bots Builder Pro: 2022.12.09 09:27:19"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//#define DEBUG_TRACEERRORS
//#define DEBUG_ASSERTIONS
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum eTradeType
  {
   TRADETYPE_BUY,                                          // Buy
   TRADETYPE_SELL                                          // Sell
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum eError
  {
   ERROR_NOERROR,                                          // No error
   ERROR_UNKNOWN,                                          // Unknown error
   ERROR_NUMBER,                                           // Error number
   ERROR_TERMINALDISCONNECTED,                             // Terminal disconnected!
   ERROR_AUTOTRADINGNOTALLOWED,                            // AutoTrading disabled!
   ERROR_OPERATIONISNOTALLOWED,                            // Operation is not allowed
   ERROR_POINTERINVALID,                                   // Pointer invalid
   ERROR_MISSINGSWITCHCASE,                                // Missing case
   ERROR_EMPTYBODYMETHODCALL,                              // Empty body method call
   ERROR_FAILEDTOSETTIMER,                                 // Failed to set timer
   ERROR_INVALIDVALUE,                                     // Invalid value!
   ERROR_INVALIDCHARACTER,                                 // Invalid character!
   ERROR_NOINPUTSTOARRANGE,                                // There is no inputs to arrange!
   ERROR_NOENDSTOARRANGE,                                  // There is no ends to arrange!
   ERROR_NOLEVELSINGRID,                                   // There is no levels in grid!
   ERROR_MASTERIDALREADYEXIST,                             // Master ID already exist!
   ERROR_INVALIDMASTERID,                                  // Invalid master ID!
   ERROR_FAILEDTOWRITEEXCHANGEFILE,                        // Failed to write exchange file!
   ERROR_FAILEDTOREADEXCHANGEFILE,                         // Failed to read exchange file!
   ERROR_EXCHANGEFILEDOESNOTEXIST,                         // Exchange file does not exist!
   ERROR_NOTENOUGHHISTORYDATA,                             // Not enough history!
   RETCODE_ORDERCHECKFAILED,                               // OrderCheck() failed
   RETCODE_NOFREEMARGIN,                                   // No free margin
   RETCODE_OPENINGNOTALLOWED,                              // Opening not allowed
   RETCODE_CLOSINGNOTALLOWED,                              // Closing not allowed
   RETCODE_TRADETYPENOTALLOWED,                            // Trade type not allowed
   RETCODE_MAXORDERS,                                      // Max orders
   RETCODE_WRONGVOLUME,                                    // Invalid volume
   RETCODE_MAXVOLUME,                                      // Max volume
   RETCODE_WRONGSTOPS,                                     // Invalid stops
   RETCODE_TRADENOTFOUND,                                  // Trade not found
   RETCODE_WRONGORDERPRICE,                                // Invalid order price
   RETCODE_ALREADYPLACED,                                  // Already placed
   RETCODE_NOTICKDATA                                      // No tick data
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum eAllowedTrades
  {
   ALLOWEDTRADES_ALL,                                      // ALL
   ALLOWEDTRADES_BUYONLY,                                  // BUY Only
   ALLOWEDTRADES_SELLONLY,                                 // SELL Only
   ALLOWEDTRADES_NONE                                      // NONE
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ePendingOrderType
  {
   PENDINGORDERTYPE_BUYSTOP,                               // Buy Stop
   PENDINGORDERTYPE_SELLSTOP,                              // Sell Stop
   PENDINGORDERTYPE_BUYLIMIT,                              // Buy Limit
   PENDINGORDERTYPE_SELLLIMIT                              // Sell Limit
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum eRelationType
  {
   RELATIONTYPE_GTEATER,                                   // Greater
   RELATIONTYPE_GTEATEROREQUAL,                            // Greater or Equal
   RELATIONTYPE_EQUAL,                                     // Equal
   RELATIONTYPE_LESS,                                      // Less
   RELATIONTYPE_LESSOREQUAL                                // Less or Equal
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum eTradeStatus
  {
   TRADESTATUS_ALL,                                        // All
   TRADESTATUS_CURRENT,                                    // Current
   TRADESTATUS_HISTORY                                     // History
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ePendingOrderStatus
  {
   ORDERSTATUS_ALL,                                        // All
   ORDERSTATUS_PENDING,                                    // Pending
   ORDERSTATUS_HISTORY                                     // History
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum eTradeInfo
  {
   TRADEINFO_TYPE,                                         // Type
   TRADEINFO_STATUS,                                       // Status
   TRADEINFO_TICKET,                                       // Ticket
   TRADEINFO_IDENTIFIER,                                   // Identifier
   TRADEINFO_SYMBOL,                                       // Symbol
   TRADEINFO_MAGIC,                                        // Magic
   TRADEINFO_COMMENT,                                      // Comment
   TRADEINFO_PROFITMONEY,                                  // Profit in Money
   TRADEINFO_COMMISSION,                                   // Commission
   TRADEINFO_SWAP,                                         // Swap
   TRADEINFO_PROFITPOINTS,                                 // Profit in Points
   TRADEINFO_LOTS,                                         // Lots
   TRADEINFO_OPENPRICE,                                    // Open Price
   TRADEINFO_CLOSEPRICE,                                   // Close Price
   TRADEINFO_STOPLOSS,                                     // Stop Loss
   TRADEINFO_TAKEPROFIT,                                   // Take Profit
   TRADEINFO_OPENTIME,                                     // Open Time
   TRADEINFO_CLOSETIME                                     // Close Time
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ePendingOrderInfo
  {
   PENDINGORDERINFO_TYPE,                                  // Type
   PENDINGORDERINFO_STATUS,                                // Status
   PENDINGORDERINFO_TICKET,                                // Ticket
   PENDINGORDERINFO_SYMBOL,                                // Symbol
   PENDINGORDERINFO_MAGIC,                                 // Magic
   PENDINGORDERINFO_COMMENT,                               // Comment
   PENDINGORDERINFO_LOTS,                                  // Lots
   PENDINGORDERINFO_OPENPRICE,                             // Open Price
   PENDINGORDERINFO_STOPLOSS,                              // Stop Loss
   PENDINGORDERINFO_TAKEPROFIT,                            // Take Profit
   PENDINGORDERINFO_EXPIRATION,                            // Expiration Time
   PENDINGORDERINFO_OPENTIME,                              // Open Time
   PENDINGORDERINFO_CLOSETIME                              // Close Time
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum eTradesGroupInfo
  {
   TRADESGROUPINFO_TRADESNUMBER,                           // Trades Number
   TRADESGROUPINFO_PROFITMONEY,                            // Profit in Money
   TRADESGROUPINFO_PROFITPOINTS,                           // Profit in Points
   TRADESGROUPINFO_TOTALLOTS,                              // Total Lots
   TRADESGROUPINFO_AVERAGEPRICE,                           // Average Price
   TRADESGROUPINFO_LOWESTOPENPRICETRADETICKET,             // Lowest Open Price Trade Ticket
   TRADESGROUPINFO_HIGHESTOPENPRICETRADETICKET,            // Highest Open Price Trade Ticket
   TRADESGROUPINFO_LOWESTCLOSEPRICETRADETICKET,            // Lowest Close Price Trade Ticket
   TRADESGROUPINFO_HIGHESTCLOSEPRICETRADETICKET,           // Highest Close Price Trade Ticket
   TRADESGROUPINFO_EARLIESTOPENTIMETRADETICKET,            // Earliest Open Time Trade Ticket
   TRADESGROUPINFO_LATESTOPENTIMETRADETICKET,              // Latest Open Time Trade Ticket
   TRADESGROUPINFO_EARLIESTCLOSETIMETRADETICKET,           // Earliest Close Time Trade Ticket
   TRADESGROUPINFO_LATESTCLOSETIMETRADETICKET,             // Latest Close Time Trade Ticket
   TRADESGROUPINFO_MAXPROFITMONEYTRADETICKET,              // Max Profit Money Trade Ticket
   TRADESGROUPINFO_MINPROFITMONEYTRADETICKET,              // Min Profit Money Trade Ticket
   TRADESGROUPINFO_MAXPROFITPOINTSTRADETICKET,             // Max Profit Points Trade Ticket
   TRADESGROUPINFO_MINPROFITPOINTSTRADETICKET,             // Min Profit Points Trade Ticket
   TRADESGROUPINFO_MAXLOTTRADETICKET,                      // Max Lot Trade Ticket
   TRADESGROUPINFO_MINLOTTRADETICKET,                      // Min Lot Trade Ticket
   TRADESGROUPINFO_SYMBOLSNUMBER                           // Symbols Number
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ePendingOrdersGroupInfo
  {
   PENDINGSGROUPINFO_ORDERSNUMBER,                         // Orders Number
   PENDINGSGROUPINFO_TOTALLOTS,                            // Total Lots
   PENDINGSGROUPINFO_AVERAGEPRICE,                         // Average Price
   PENDINGSGROUPINFO_LOWESTOPENPRICEORDERTICKET,           // Lowest Open Price Order Ticket
   PENDINGSGROUPINFO_HIGHESTOPENPRICEORDERTICKET,          // Highest Open Price Order Ticket
   PENDINGSGROUPINFO_EARLIESTOPENTIMEORDERTICKET,          // Earliest Open Time Order Ticket
   PENDINGSGROUPINFO_LATESTOPENTIMEORDERTICKET,            // Latest Open Time Order Ticket
   PENDINGSGROUPINFO_EARLIESTCLOSETIMEORDERTICKET,         // Earliest Close Time Order Ticket
   PENDINGSGROUPINFO_LATESTCLOSETIMEORDERTICKET,           // Latest Close Time Order Ticket
   PENDINGSGROUPINFO_MAXLOTORDERTICKET,                    // Max Lots Order Ticket
   PENDINGSGROUPINFO_MINLOTORDERTICKET,                    // Min Lots Order Ticket
   PENDINGSGROUPINFO_SYMBOLSNUMBER                         // Symbols Number
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum eTickInfo
  {
   TICKINFO_BID,                                           // Bid Price
   TICKINFO_ASK,                                           // Ask Price
   TICKINFO_SPREADPOINTS,                                  // Spread Points
   TICKINFO_SPREADPRICE,                                   // Spread Price
   TICKINFO_LAST,                                          // Last Price
   TICKINFO_TIME,                                          // Time
   TICKINFO_VOLUME,                                        // Volume
   TICKINFO_TIMEMSC                                        // Time msc
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum ePriceHistoryInfo
  {
   PRICEHISTORYINFO_HIGHESTPRICE,                          // Highest Price
   PRICEHISTORYINFO_LOWESTPRICE,                           // Lowest Price
   PRICEHISTORYINFO_HIGHESTPRICEBARNUMBER,                 // Highest Price Bar Number
   PRICEHISTORYINFO_LOWESTPRICEBARNUMBER                   // Lowest Price Bar Number
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum eMathOperation
  {
   MATHOPERATION_SUM,                                      // Sum
   MATHOPERATION_ADD,                                      // Add
   MATHOPERATION_PROPORTIONALTOBALANCE,                    // Proportional (Balance)
   MATHOPERATION_PROPORTIONALTOEQUITY,                     // Proportional (Equity)
   MATHOPERATION_SUBTRACT,                                 // Subtract
   MATHOPERATION_DIVIDE,                                   // Divide
   MATHOPERATION_REMAINDER,                                // Remainder
   MATHOPERATION_MULTIPLY,                                 // Multiply
   MATHOPERATION_POWER,                                    // Power
   MATHOPERATION_MAXIMUM,                                  // Maximum
   MATHOPERATION_MINIMUM,                                  // Minimum
   MATHOPERATION_ROUND,                                    // Round
   MATHOPERATION_ABSOLUTE,                                 // Absolute
   MATHOPERATION_SQUAREROOT,                               // Square Root
   MATHOPERATION_LOGARITHM,                                // Logarithm
   MATHOPERATION_EXPONENT,                                 // Exponent
   MATHOPERATION_FLOOR,                                    // Floor
   MATHOPERATION_CEIL,                                     // Ceil
   MATHOPERATION_PRICETOPOINTS,                            // Price to Points
   MATHOPERATION_POINTSTOPRICE,                            // Points to Price
   MATHOPERATION_DONTSYNC,                                 // Don't sync
   MATHOPERATION_SYNCLEVELS,                               // Sync Levels
   MATHOPERATION_SYNCPOINTS,                               // Sync Points
   MATHOPERATION_OVERWRITEWITH,                            // Overwrite
   MATHOPERATION_OVERWRITEPOINTS,                          // Overwrite Points
   MATHOPERATION_KEEPORIGINAL                              // Keep original
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
sinput string                                       Inp_element_7917643        = "=== RANGE ===";                                // === RANGE ===
input #ifdef __MQL4__ int #else long #endif         Inp_element_7231121        = 10;                                             // Range, bars
input #ifdef __MQL4__ int #else long #endif         Inp_element_7184116        = 300;                                            // Max Range, points
sinput string                                       Inp_element_6544879        = "=== TRADE ===";                                // === TRADE ===
input double                                        Inp_element_3632865        = 0.1;                                            // Lots
input #ifdef __MQL4__ int #else long #endif         Inp_element_3649488        = 500;                                            // Stop Loss, points
input #ifdef __MQL4__ int #else long #endif         Inp_element_3632359        = 1000;                                           // Take Profit, points
input #ifdef __MQL4__ int #else long #endif         Inp_element_3634918        = 5555;                                           // Magic
sinput string                                       Inp_element_3640359        = "Range Break Out EA";                           // Comment
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//===============
// Forward Declaration
//===============
/*                                                             */class cInfo;
//
/*                   = final = public cInfo =                          */class cTradeInfo;
/*                   = final = public cInfo =                          */class cPendingOrderInfo;
//
/*                                                             */class cGroupInfo;
//
/*                   = final = public cGroupInfo =                     */class cTradesGroupInfo;
/*                   = final = public cGroupInfo =                     */class cPendingOrdersGroupInfo;
//
/*                                                             */class cFilter;
//
/*                   = final = public cFilter =                        */class cTradesFilter;
/*                   = final = public cFilter =                        */class cPendingOrdersFilter;
//
/*                   = final =                                 */class cTrade;
/*                   = final =                                 */class cPointer;
/*                   = final =                                 */class cArray;
/*                   = final =                                 */class cRunner;
/*                   = final =                                 */class cExecutableParameter;
//
/*                                                             */class cObject;
//
/*                   = final = public cObject    */template<typename T>class cVariable;
//
/*                                                             */class cExecutable;
/*                   = final = public cExecutable =                    */class cExecutableInputLongValue;
/*                   = final = public cExecutable =                    */class cExecutableInputDoubleValue;
/*                   = final = public cExecutable =                    */class cExecutableInputStringValue;
/*                   = final = public cExecutable =                    */class cExecutableTick;
/*                           = public cExecutable =                    */class cExecutableTickInfo;
/*                   = final = public cExecutableTickInfo =                    */class cExecutableTickInfoDouble;
/*                   = final = public cExecutable =                    */class cExecutablePriceHistory;
/*                           = public cExecutable =                    */class cExecutablePriceHistoryInfo;
/*                   = final = public cExecutablePriceHistoryInfo =            */class cExecutablePriceHistoryInfoDouble;
/*                           = public cExecutable =                    */class cExecutableOpen;
/*                   = final = public cExecutableOpen =                        */class cExecutableOpenTrade;
/*                           = public cExecutable =                    */class cExecutableModify;
/*                           = public cExecutableModify =                      */class cExecutableModifyCurrent;
/*                           = public cExecutableModify =                      */class cExecutableModifyPending;
/*                   = final = public cExecutableModifyCurrent =                       */class cExecutableModifyTradesGroup;
/*                           = public cExecutable =                    */class cExecutableTrades;
/*                   = final = public cExecutableTrades =                      */class cExecutableTradesGroup;
/*                   = final = public cExecutableTrades =                      */class cExecutableCombineTradesGroups;
/*                           = public cExecutable =                    */class cExecutableTradesGroupInfo;
/*                   = final = public cExecutableTradesGroupInfo =             */class cExecutableTradesGroupInfoInteger;
/*                   = final = public cExecutable =                    */class cExecutableArithmetic;
/*                   = final = public cExecutable =                    */class cExecutablePriceTransformation;
/*                   = final = public cExecutable =                    */class cExecutableAnd;
/*                   = final = public cExecutable =                    */class cExecutableOr;
/*                   = final = public cExecutable =                    */class cExecutableCompare;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
enum eElementParameter
  {
   ELEMENTPARAMETER_TRIGGER,                               // Trigger
   ELEMENTPARAMETER_LONGVALUE,                             // Value (Integer)
   ELEMENTPARAMETER_DOUBLEVALUE,                           // Value (Decimal)
   ELEMENTPARAMETER_BOOLVALUE,                             // Logical True/False
   ELEMENTPARAMETER_STRINGVALUE,                           // Value (String)
   ELEMENTPARAMETER_TIMEVALUE,                             // Value (Time)
   ELEMENTPARAMETER_CONDITION,                             // Condition
   ELEMENTPARAMETER_ORDERPRICE,                            // Order Price
   ELEMENTPARAMETER_EXPIRATION,                            // Expiration
   ELEMENTPARAMETER_TIGHTENSTOPSONLY,                      // Tighten Stops Only
   ELEMENTPARAMETER_PRICEHISTORY,                          // Price History
   ELEMENTPARAMETER_TICK,                                  // Tick
   ELEMENTPARAMETER_TRADESGROUP,                           // Trades
   ELEMENTPARAMETER_BARFROM,                               // From Bar Number
   ELEMENTPARAMETER_BARTILL,                               // Till Bar Number
   ELEMENTPARAMETER_MAGIC,                                 // Magic
   ELEMENTPARAMETER_STOPLOSSPOINTS,                        // Stop Loss (Points)
   ELEMENTPARAMETER_TAKEPROFITPOINTS,                      // Take Profit (Points)
   ELEMENTPARAMETER_TICKETGREATEROREQUALTHAN,              // Ticket Greater or Equal than
   ELEMENTPARAMETER_TICKETLESSOREQUALTHAN,                 // Ticket Less or Equal than
   ELEMENTPARAMETER_SLIPPAGE,                              // Slippage
   ELEMENTPARAMETER_SYMBOLNAME,                            // Symbol Name
   ELEMENTPARAMETER_COMMENT,                               // Comment
   ELEMENTPARAMETER_EXACTCOMMENT,                          // Exact Comment
   ELEMENTPARAMETER_COMMENTPARTIAL,                        // Partial Comment
   ELEMENTPARAMETER_OPENTIMEGREATEROREQUALTHAN,            // Open Time Greater or Equal than
   ELEMENTPARAMETER_OPENTIMELESSOREQUALTHAN,               // Open Time Less or Equal than
   ELEMENTPARAMETER_CLOSETIMEGREATEROREQUALTHAN,           // Close Time Greater or Equal than
   ELEMENTPARAMETER_CLOSETIMELESSOREQUALTHAN,              // Close Time Less or Equal than
   ELEMENTPARAMETER_STOPLOSSPRICE,                         // Stop Loss (Price)
   ELEMENTPARAMETER_STOPLOSSMONEY,                         // Stop Loss (Money)
   ELEMENTPARAMETER_TAKEPROFITPRICE,                       // Take Profit (Price)
   ELEMENTPARAMETER_TAKEPROFITMONEY,                       // Take Profit (Money)
   ELEMENTPARAMETER_DOUBLEVALUE1,                          // Value #1
   ELEMENTPARAMETER_DOUBLEVALUE2,                          // Value #2
   ELEMENTPARAMETER_PROFITGREATEROREQUALTHAN,              // Profit Greater or Equal than
   ELEMENTPARAMETER_PROFITLESSOREQUALTHAN,                 // Profit Less or Equal than
   ELEMENTPARAMETER_OPENPRICEGREATEROREQUALTHAN,           // Open Price Greater or Equal than
   ELEMENTPARAMETER_OPENPRICELESSOREQUALTHAN,              // Open Price Less or Equal than
   ELEMENTPARAMETER_CLOSEPRICEGREATEROREQUALTHAN,          // Close Price Greater or Equal than
   ELEMENTPARAMETER_CLOSEPRICELESSOREQUALTHAN,             // Close Price Less or Equal than
   ELEMENTPARAMETER_LOTSGREATEROREQUALTHAN,                // Lots Greater or Equal than
   ELEMENTPARAMETER_LOTSLESSOREQUALTHAN,                   // Lots Less or Equal than
   ELEMENTPARAMETER_LOTS,                                  // Lots
   ELEMENTPARAMETER_TIMEFRAME,                             // Time Frame
   ELEMENTPARAMETER_TRADETYPE,                             // Trade Type
   ELEMENTPARAMETER_TRADESGROUPINFO,                       // Trades Information
   ELEMENTPARAMETER_TICKINFO,                              // Tick Information
   ELEMENTPARAMETER_PRICEHISTORYINFO,                      // Price History Information
   ELEMENTPARAMETER_RELATIONTYPE,                          // Relation Type
   ELEMENTPARAMETER_TRADESTATUS,                           // Trade Status
   ELEMENTPARAMETER_MATHOPERATION                          // Math Operation
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define OUTPUTNONE 
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define OUTPUTLONG \
   long              OutputValue;\
   virtual bool      OutPutValueGet(long &to)override final const{to=this.OutputValue;return(true);}\
   virtual bool      OutPutValueGet(double &to)override final const{to=(double)this.OutputValue;return(true);}\
   virtual bool      OutPutValueGet(string &to)override final const{to=(string)this.OutputValue;return(true);}\
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define OUTPUTBOOL \
   bool              OutputValue;\
   virtual bool      OutPutValueGet(long &to)override final const{to=(long)this.OutputValue;return(true);}\
   virtual bool      OutPutValueGet(double &to)override final const{to=(double)this.OutputValue;return(true);}\
   virtual bool      OutPutValueGet(string &to)override final const{to=(string)this.OutputValue;return(true);}\
   virtual bool      OutPutValueGet(bool &to)override final const{to=this.OutputValue;return(true);}\
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define OUTPUTDOUBLE \
   double            OutputValue;\
   virtual bool      OutPutValueGet(double &to)override final const{to=this.OutputValue;return(true);}\
   virtual bool      OutPutValueGet(string &to)override final const{to=(string)this.OutputValue;return(true);}\
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define OUTPUTSTRING \
   string            OutputValue;\
   virtual bool      OutPutValueGet(string &to)override final const{to=this.OutputValue;return(true);}\
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define OUTPUTDATETIME \
   datetime          OutputValue;\
   virtual bool      OutPutValueGet(datetime &to)override final const{to=this.OutputValue;return(true);}\
   virtual bool      OutPutValueGet(string &to)override final const{to=::TimeToString(this.OutputValue,TIME_DATE|TIME_MINUTES|TIME_SECONDS);return(true);}\
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define OUTPUTENUM(enumname) \
   enumname          OutputValue;\
   virtual bool      OutPutValueGet(enumname &to)override final const{to=this.OutputValue;return(true);}\
   virtual bool      OutPutValueGet(string &to)override final const{to=::EnumToString(this.OutputValue);return(true);}\
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define OUTPUTPOINTER \
   virtual bool      OutPutValueGet(const cExecutable *&to)const{to=::GetPointer(this);return(true);}\
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#define VERTICALBAR             " | "
#define TOSTRING(expression) (#expression +" = " + (string)(expression))
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//===============
//===============
#ifdef  DEBUG_TRACEERRORS
//===============
//===============
#define TRACEERRORS_START \
int lasterror=::GetLastError();\
if(lasterror>0)\
  {\
  ::Alert("!!! TRACE ERRORS !!! (START): ",lasterror,VERTICALBAR,__FUNCSIG__,VERTICALBAR,__FILE__,VERTICALBAR,__LINE__);\
  ::DebugBreak();\
  ::ResetLastError();\
  }
//===============
//===============
#define TRACEERRORS_END \
lasterror=::GetLastError();\
if(lasterror>0)\
  {\
  string errordescription=(string)lasterror;\
  if(lasterror>=ERR_USER_ERROR_FIRST)errordescription="CUSTOM: "+(string)(lasterror-ERR_USER_ERROR_FIRST);\
  ::Alert("!!! TRACE ERRORS !!! (END): ",errordescription,VERTICALBAR,__FUNCSIG__,VERTICALBAR,__FILE__,VERTICALBAR,__LINE__);\
  ::DebugBreak();\
  ::ResetLastError();\
  }
//===============
//===============
#else
//===============
//===============
#define TRACEERRORS_START
#define TRACEERRORS_END
//===============
//===============
#endif
//===============
//===============
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//===============
//===============
#ifdef DEBUG_ASSERTIONS
//===============
//===============
#define ASSERT(executebefore,condition,skipped,executeiffailed) \
{executebefore}\
if(!(condition))\
  {\
  ::Alert("!!! ASSERT <<",#condition,">> FAILED !!! Function ",((skipped)?"Execution Skipped!!!":"Executed => "),VERTICALBAR,\
  __FUNCSIG__,VERTICALBAR,__FILE__,VERTICALBAR,__LINE__);\
  ::DebugBreak();\
  {executeiffailed}\
  }
//===============
//===============
#else
//===============
//===============
#define ASSERT(executebefore,condition,skipped,executeiffailed)
//===============
//===============
#endif
//===============
//===============
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
cRunner *Runner;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit(void)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============
 
//===============
   Runner=new cRunner;
//===============
 
//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(Runner),true,{})
//===============
 
//===============
   if(!cPointer::Valid(Runner))return(INIT_FAILED);
//===============
 
//===============
// Element: === RANGE ===
//===============
   cExecutableInputStringValue *const element_7917643 = new cExecutableInputStringValue;
//===============
   Runner.Add(element_7917643,true);
//===============
   element_7917643.ParameterAdd((string)Inp_element_7917643,ELEMENTPARAMETER_STRINGVALUE,0,true);
//===============
 
//===============
// Element: Range, bars
//===============
   cExecutableInputLongValue *const element_7231121 = new cExecutableInputLongValue;
//===============
   Runner.Add(element_7231121,false);
//===============
   element_7231121.ParameterAdd((long)Inp_element_7231121,ELEMENTPARAMETER_LONGVALUE,0,true);
//===============
 
//===============
// Element: Max Range, points
//===============
   cExecutableInputLongValue *const element_7184116 = new cExecutableInputLongValue;
//===============
   Runner.Add(element_7184116,false);
//===============
   element_7184116.ParameterAdd((long)Inp_element_7184116,ELEMENTPARAMETER_LONGVALUE,0,true);
//===============
 
//===============
// Element: === TRADE ===
//===============
   cExecutableInputStringValue *const element_6544879 = new cExecutableInputStringValue;
//===============
   Runner.Add(element_6544879,true);
//===============
   element_6544879.ParameterAdd((string)Inp_element_6544879,ELEMENTPARAMETER_STRINGVALUE,0,true);
//===============
 
//===============
// Element: Lots
//===============
   cExecutableInputDoubleValue *const element_3632865 = new cExecutableInputDoubleValue;
//===============
   Runner.Add(element_3632865,false);
//===============
   element_3632865.ParameterAdd((double)Inp_element_3632865,ELEMENTPARAMETER_DOUBLEVALUE,0,true);
//===============
 
//===============
// Element: Stop Loss, points
//===============
   cExecutableInputLongValue *const element_3649488 = new cExecutableInputLongValue;
//===============
   Runner.Add(element_3649488,false);
//===============
   element_3649488.ParameterAdd((long)Inp_element_3649488,ELEMENTPARAMETER_LONGVALUE,0,true);
//===============
 
//===============
// Element: Take Profit, points
//===============
   cExecutableInputLongValue *const element_3632359 = new cExecutableInputLongValue;
//===============
   Runner.Add(element_3632359,false);
//===============
   element_3632359.ParameterAdd((long)Inp_element_3632359,ELEMENTPARAMETER_LONGVALUE,0,true);
//===============
 
//===============
// Element: Magic
//===============
   cExecutableInputLongValue *const element_3634918 = new cExecutableInputLongValue;
//===============
   Runner.Add(element_3634918,false);
//===============
   element_3634918.ParameterAdd((long)Inp_element_3634918,ELEMENTPARAMETER_LONGVALUE,0,true);
//===============
 
//===============
// Element: Comment
//===============
   cExecutableInputStringValue *const element_3640359 = new cExecutableInputStringValue;
//===============
   Runner.Add(element_3640359,false);
//===============
   element_3640359.ParameterAdd((string)Inp_element_3640359,ELEMENTPARAMETER_STRINGVALUE,0,true);
//===============
 
//===============
// Element: Open Sell
//===============
   cExecutableOpenTrade *const element_3636083 = new cExecutableOpenTrade;
//===============
   Runner.Add(element_3636083,true);
//===============
   element_3636083.ParameterAdd((string)::Symbol(),ELEMENTPARAMETER_SYMBOLNAME,1,true);
//===============
   element_3636083.ParameterAdd((eTradeType)TRADETYPE_SELL,ELEMENTPARAMETER_TRADETYPE,2,true);
//===============
   element_3636083.ParameterAdd((long)0,ELEMENTPARAMETER_STOPLOSSPOINTS,6,false);
//===============
   element_3636083.ParameterAdd((long)0,ELEMENTPARAMETER_TAKEPROFITPOINTS,7,false);
//===============
   element_3636083.ParameterAdd((double)0.0,ELEMENTPARAMETER_STOPLOSSMONEY,8,false);
//===============
   element_3636083.ParameterAdd((double)0.0,ELEMENTPARAMETER_TAKEPROFITMONEY,9,false);
//===============
   element_3636083.ParameterAdd((double)0.0,ELEMENTPARAMETER_STOPLOSSPRICE,10,false);
//===============
   element_3636083.ParameterAdd((double)0.0,ELEMENTPARAMETER_TAKEPROFITPRICE,11,false);
//===============
   element_3636083.ParameterAdd((long)30,ELEMENTPARAMETER_SLIPPAGE,12,true);
//===============
 
//===============
// Element: Open Buy
//===============
   cExecutableOpenTrade *const element_3641151 = new cExecutableOpenTrade;
//===============
   Runner.Add(element_3641151,true);
//===============
   element_3641151.ParameterAdd((string)::Symbol(),ELEMENTPARAMETER_SYMBOLNAME,1,true);
//===============
   element_3641151.ParameterAdd((eTradeType)TRADETYPE_BUY,ELEMENTPARAMETER_TRADETYPE,2,true);
//===============
   element_3641151.ParameterAdd((long)0,ELEMENTPARAMETER_STOPLOSSPOINTS,6,false);
//===============
   element_3641151.ParameterAdd((long)0,ELEMENTPARAMETER_TAKEPROFITPOINTS,7,false);
//===============
   element_3641151.ParameterAdd((double)0.0,ELEMENTPARAMETER_STOPLOSSMONEY,8,false);
//===============
   element_3641151.ParameterAdd((double)0.0,ELEMENTPARAMETER_TAKEPROFITMONEY,9,false);
//===============
   element_3641151.ParameterAdd((double)0.0,ELEMENTPARAMETER_STOPLOSSPRICE,10,false);
//===============
   element_3641151.ParameterAdd((double)0.0,ELEMENTPARAMETER_TAKEPROFITPRICE,11,false);
//===============
   element_3641151.ParameterAdd((long)30,ELEMENTPARAMETER_SLIPPAGE,12,true);
//===============
 
//===============
// Element: Set SL and TP
//===============
   cExecutableModifyTradesGroup *const element_3646343 = new cExecutableModifyTradesGroup;
//===============
   Runner.Add(element_3646343,true);
//===============
   element_3646343.ParameterAdd((bool)true,ELEMENTPARAMETER_TIGHTENSTOPSONLY,2,true);
//===============
   element_3646343.ParameterAdd((double)30.0,ELEMENTPARAMETER_STOPLOSSMONEY,5,false);
//===============
   element_3646343.ParameterAdd((double)30.0,ELEMENTPARAMETER_TAKEPROFITMONEY,6,false);
//===============
   element_3646343.ParameterAdd((double)0.0,ELEMENTPARAMETER_STOPLOSSPRICE,7,false);
//===============
   element_3646343.ParameterAdd((double)0.0,ELEMENTPARAMETER_TAKEPROFITPRICE,8,false);
//===============
 
//===============
// Element: Tick
//===============
   cExecutableTick *const element_7484021 = new cExecutableTick;
//===============
   Runner.Add(element_7484021,false);
//===============
   element_7484021.ParameterAdd((string)::Symbol(),ELEMENTPARAMETER_SYMBOLNAME,0,true);
//===============
 
//===============
// Element: Bid
//===============
   cExecutableTickInfoDouble *const element_7498859 = new cExecutableTickInfoDouble;
//===============
   Runner.Add(element_7498859,false);
//===============
   element_7498859.ParameterAdd((eTickInfo)TICKINFO_BID,ELEMENTPARAMETER_TICKINFO,1,true);
//===============
 
//===============
// Element: Price History
//===============
   cExecutablePriceHistory *const element_7088275 = new cExecutablePriceHistory;
//===============
   Runner.Add(element_7088275,false);
//===============
   element_7088275.ParameterAdd((string)::Symbol(),ELEMENTPARAMETER_SYMBOLNAME,0,true);
//===============
   element_7088275.ParameterAdd((ENUM_TIMEFRAMES)::Period(),ELEMENTPARAMETER_TIMEFRAME,1,true);
//===============
   element_7088275.ParameterAdd((long)1,ELEMENTPARAMETER_BARTILL,3,true);
//===============
 
//===============
// Element: Lowest Price
//===============
   cExecutablePriceHistoryInfoDouble *const element_7142920 = new cExecutablePriceHistoryInfoDouble;
//===============
   Runner.Add(element_7142920,false);
//===============
   element_7142920.ParameterAdd((ePriceHistoryInfo)PRICEHISTORYINFO_LOWESTPRICE,ELEMENTPARAMETER_PRICEHISTORYINFO,1,true);
//===============
 
//===============
// Element: Highest Price
//===============
   cExecutablePriceHistoryInfoDouble *const element_7127666 = new cExecutablePriceHistoryInfoDouble;
//===============
   Runner.Add(element_7127666,false);
//===============
   element_7127666.ParameterAdd((ePriceHistoryInfo)PRICEHISTORYINFO_HIGHESTPRICE,ELEMENTPARAMETER_PRICEHISTORYINFO,1,true);
//===============
 
//===============
// Element: Buys
//===============
   cExecutableTradesGroup *const element_3643317 = new cExecutableTradesGroup;
//===============
   Runner.Add(element_3643317,false);
//===============
   element_3643317.ParameterAdd((eTradeStatus)TRADESTATUS_CURRENT,ELEMENTPARAMETER_TRADESTATUS,0,true);
//===============
   element_3643317.ParameterAdd((string)::Symbol(),ELEMENTPARAMETER_SYMBOLNAME,1,true);
//===============
   element_3643317.ParameterAdd((eTradeType)TRADETYPE_BUY,ELEMENTPARAMETER_TRADETYPE,3,true);
//===============
   element_3643317.ParameterAdd((string)"Comment",ELEMENTPARAMETER_EXACTCOMMENT,4,false);
//===============
   element_3643317.ParameterAdd((string)"Comment",ELEMENTPARAMETER_COMMENTPARTIAL,5,false);
//===============
   element_3643317.ParameterAdd((double)0.0,ELEMENTPARAMETER_PROFITGREATEROREQUALTHAN,6,false);
//===============
   element_3643317.ParameterAdd((double)0.0,ELEMENTPARAMETER_PROFITLESSOREQUALTHAN,7,false);
//===============
   element_3643317.ParameterAdd((datetime)D'1970.01.01 00:00:00',ELEMENTPARAMETER_OPENTIMEGREATEROREQUALTHAN,8,false);
//===============
   element_3643317.ParameterAdd((datetime)D'1970.01.01 00:00:00',ELEMENTPARAMETER_OPENTIMELESSOREQUALTHAN,9,false);
//===============
   element_3643317.ParameterAdd((datetime)D'1970.01.01 00:00:00',ELEMENTPARAMETER_CLOSETIMEGREATEROREQUALTHAN,10,false);
//===============
   element_3643317.ParameterAdd((datetime)D'1970.01.01 00:00:00',ELEMENTPARAMETER_CLOSETIMELESSOREQUALTHAN,11,false);
//===============
   element_3643317.ParameterAdd((double)0.0,ELEMENTPARAMETER_OPENPRICEGREATEROREQUALTHAN,12,false);
//===============
   element_3643317.ParameterAdd((double)0.0,ELEMENTPARAMETER_OPENPRICELESSOREQUALTHAN,13,false);
//===============
   element_3643317.ParameterAdd((double)0.0,ELEMENTPARAMETER_CLOSEPRICEGREATEROREQUALTHAN,14,false);
//===============
   element_3643317.ParameterAdd((double)0.0,ELEMENTPARAMETER_CLOSEPRICELESSOREQUALTHAN,15,false);
//===============
   element_3643317.ParameterAdd((double)0.0,ELEMENTPARAMETER_LOTSGREATEROREQUALTHAN,16,false);
//===============
   element_3643317.ParameterAdd((double)0.0,ELEMENTPARAMETER_LOTSLESSOREQUALTHAN,17,false);
//===============
   element_3643317.ParameterAdd((long)0,ELEMENTPARAMETER_TICKETGREATEROREQUALTHAN,18,false);
//===============
   element_3643317.ParameterAdd((long)0,ELEMENTPARAMETER_TICKETLESSOREQUALTHAN,19,false);
//===============
 
//===============
// Element: Sells
//===============
   cExecutableTradesGroup *const element_3651482 = new cExecutableTradesGroup;
//===============
   Runner.Add(element_3651482,false);
//===============
   element_3651482.ParameterAdd((eTradeStatus)TRADESTATUS_CURRENT,ELEMENTPARAMETER_TRADESTATUS,0,true);
//===============
   element_3651482.ParameterAdd((string)::Symbol(),ELEMENTPARAMETER_SYMBOLNAME,1,true);
//===============
   element_3651482.ParameterAdd((eTradeType)TRADETYPE_SELL,ELEMENTPARAMETER_TRADETYPE,3,true);
//===============
   element_3651482.ParameterAdd((string)"Comment",ELEMENTPARAMETER_EXACTCOMMENT,4,false);
//===============
   element_3651482.ParameterAdd((string)"Comment",ELEMENTPARAMETER_COMMENTPARTIAL,5,false);
//===============
   element_3651482.ParameterAdd((double)0.0,ELEMENTPARAMETER_PROFITGREATEROREQUALTHAN,6,false);
//===============
   element_3651482.ParameterAdd((double)0.0,ELEMENTPARAMETER_PROFITLESSOREQUALTHAN,7,false);
//===============
   element_3651482.ParameterAdd((datetime)D'1970.01.01 00:00:00',ELEMENTPARAMETER_OPENTIMEGREATEROREQUALTHAN,8,false);
//===============
   element_3651482.ParameterAdd((datetime)D'1970.01.01 00:00:00',ELEMENTPARAMETER_OPENTIMELESSOREQUALTHAN,9,false);
//===============
   element_3651482.ParameterAdd((datetime)D'1970.01.01 00:00:00',ELEMENTPARAMETER_CLOSETIMEGREATEROREQUALTHAN,10,false);
//===============
   element_3651482.ParameterAdd((datetime)D'1970.01.01 00:00:00',ELEMENTPARAMETER_CLOSETIMELESSOREQUALTHAN,11,false);
//===============
   element_3651482.ParameterAdd((double)0.0,ELEMENTPARAMETER_OPENPRICEGREATEROREQUALTHAN,12,false);
//===============
   element_3651482.ParameterAdd((double)0.0,ELEMENTPARAMETER_OPENPRICELESSOREQUALTHAN,13,false);
//===============
   element_3651482.ParameterAdd((double)0.0,ELEMENTPARAMETER_CLOSEPRICEGREATEROREQUALTHAN,14,false);
//===============
   element_3651482.ParameterAdd((double)0.0,ELEMENTPARAMETER_CLOSEPRICELESSOREQUALTHAN,15,false);
//===============
   element_3651482.ParameterAdd((double)0.0,ELEMENTPARAMETER_LOTSGREATEROREQUALTHAN,16,false);
//===============
   element_3651482.ParameterAdd((double)0.0,ELEMENTPARAMETER_LOTSLESSOREQUALTHAN,17,false);
//===============
   element_3651482.ParameterAdd((long)0,ELEMENTPARAMETER_TICKETGREATEROREQUALTHAN,18,false);
//===============
   element_3651482.ParameterAdd((long)0,ELEMENTPARAMETER_TICKETLESSOREQUALTHAN,19,false);
//===============
 
//===============
// Element: All Trades
//===============
   cExecutableCombineTradesGroups *const element_3634787 = new cExecutableCombineTradesGroups;
//===============
   Runner.Add(element_3634787,false);
//===============
 
//===============
// Element: Buys Number
//===============
   cExecutableTradesGroupInfoInteger *const element_3630945 = new cExecutableTradesGroupInfoInteger;
//===============
   Runner.Add(element_3630945,false);
//===============
   element_3630945.ParameterAdd((eTradesGroupInfo)TRADESGROUPINFO_TRADESNUMBER,ELEMENTPARAMETER_TRADESGROUPINFO,1,true);
//===============
 
//===============
// Element: Sells Number
//===============
   cExecutableTradesGroupInfoInteger *const element_3628984 = new cExecutableTradesGroupInfoInteger;
//===============
   Runner.Add(element_3628984,false);
//===============
   element_3628984.ParameterAdd((eTradesGroupInfo)TRADESGROUPINFO_TRADESNUMBER,ELEMENTPARAMETER_TRADESGROUPINFO,1,true);
//===============
 
//===============
// Element: Range
//===============
   cExecutableArithmetic *const element_7272543 = new cExecutableArithmetic;
//===============
   Runner.Add(element_7272543,false);
//===============
   element_7272543.ParameterAdd((bool)true,ELEMENTPARAMETER_TRIGGER,0,true);
//===============
   element_7272543.ParameterAdd((eMathOperation)MATHOPERATION_SUBTRACT,ELEMENTPARAMETER_MATHOPERATION,2,true);
//===============
 
//===============
// Element: Range, points
//===============
   cExecutablePriceTransformation *const element_7297137 = new cExecutablePriceTransformation;
//===============
   Runner.Add(element_7297137,false);
//===============
   element_7297137.ParameterAdd((string)::Symbol(),ELEMENTPARAMETER_SYMBOLNAME,0,true);
//===============
   element_7297137.ParameterAdd((eMathOperation)MATHOPERATION_PRICETOPOINTS,ELEMENTPARAMETER_MATHOPERATION,2,true);
//===============
 
//===============
// Element: Buy Signal
//===============
   cExecutableAnd *const element_3636154 = new cExecutableAnd;
//===============
   Runner.Add(element_3636154,false);
//===============
 
//===============
// Element: Buy Trigger
//===============
   cExecutableAnd *const element_3639134 = new cExecutableAnd;
//===============
   Runner.Add(element_3639134,false);
//===============
 
//===============
// Element: Sell Signal
//===============
   cExecutableAnd *const element_3636410 = new cExecutableAnd;
//===============
   Runner.Add(element_3636410,false);
//===============
 
//===============
// Element: Sell Trigger
//===============
   cExecutableAnd *const element_3630655 = new cExecutableAnd;
//===============
   Runner.Add(element_3630655,false);
//===============
 
//===============
// Element: Any Trades?
//===============
   cExecutableOr *const element_3621617 = new cExecutableOr;
//===============
   Runner.Add(element_3621617,false);
//===============
 
//===============
// Element: Good Range
//===============
   cExecutableCompare *const element_7410264 = new cExecutableCompare;
//===============
   Runner.Add(element_7410264,false);
//===============
   element_7410264.ParameterAdd((eRelationType)RELATIONTYPE_LESSOREQUAL,ELEMENTPARAMETER_RELATIONTYPE,1,true);
//===============
 
//===============
// Element: Up BreakOut
//===============
   cExecutableCompare *const element_7548369 = new cExecutableCompare;
//===============
   Runner.Add(element_7548369,false);
//===============
   element_7548369.ParameterAdd((eRelationType)RELATIONTYPE_GTEATER,ELEMENTPARAMETER_RELATIONTYPE,1,true);
//===============
 
//===============
// Element: Down BreakOut
//===============
   cExecutableCompare *const element_7581841 = new cExecutableCompare;
//===============
   Runner.Add(element_7581841,false);
//===============
   element_7581841.ParameterAdd((eRelationType)RELATIONTYPE_LESS,ELEMENTPARAMETER_RELATIONTYPE,1,true);
//===============
 
//===============
// Element: No Buys?
//===============
   cExecutableCompare *const element_3621495 = new cExecutableCompare;
//===============
   Runner.Add(element_3621495,false);
//===============
   element_3621495.ParameterAdd((eRelationType)RELATIONTYPE_EQUAL,ELEMENTPARAMETER_RELATIONTYPE,1,true);
//===============
   element_3621495.ParameterAdd((double)0.0,ELEMENTPARAMETER_DOUBLEVALUE2,2,true);
//===============
 
//===============
// Element: No Sells?
//===============
   cExecutableCompare *const element_3645690 = new cExecutableCompare;
//===============
   Runner.Add(element_3645690,false);
//===============
   element_3645690.ParameterAdd((eRelationType)RELATIONTYPE_EQUAL,ELEMENTPARAMETER_RELATIONTYPE,1,true);
//===============
   element_3645690.ParameterAdd((double)0.0,ELEMENTPARAMETER_DOUBLEVALUE2,2,true);
//===============
 
//===============
// Link: Magic => Buys
//===============
   element_3643317.LinkAdd(element_3634918,ELEMENTPARAMETER_MAGIC,false,2,true);
//===============

//===============
// Link: Magic => Sells
//===============
   element_3651482.LinkAdd(element_3634918,ELEMENTPARAMETER_MAGIC,false,2,true);
//===============

//===============
// Link: Buys => Buys Number
//===============
   element_3630945.LinkAdd(element_3643317,ELEMENTPARAMETER_TRADESGROUP,false,0,true);
//===============

//===============
// Link: Sells => Sells Number
//===============
   element_3628984.LinkAdd(element_3651482,ELEMENTPARAMETER_TRADESGROUP,false,0,true);
//===============

//===============
// Link: Buys Number => No Buys?
//===============
   element_3621495.LinkAdd(element_3630945,ELEMENTPARAMETER_DOUBLEVALUE1,false,0,true);
//===============

//===============
// Link: Sells Number => No Sells?
//===============
   element_3645690.LinkAdd(element_3628984,ELEMENTPARAMETER_DOUBLEVALUE1,false,0,true);
//===============

//===============
// Link: Buy Signal => Buy Trigger
//===============
   element_3639134.LinkAdd(element_3636154,ELEMENTPARAMETER_BOOLVALUE,false,0,true);
//===============

//===============
// Link: No Buys? => Buy Trigger
//===============
   element_3639134.LinkAdd(element_3621495,ELEMENTPARAMETER_BOOLVALUE,false,1,true);
//===============

//===============
// Link: Buy Trigger => Open Buy
//===============
   element_3641151.LinkAdd(element_3639134,ELEMENTPARAMETER_TRIGGER,false,0,true);
//===============

//===============
// Link: Magic => Open Buy
//===============
   element_3641151.LinkAdd(element_3634918,ELEMENTPARAMETER_MAGIC,false,4,true);
//===============

//===============
// Link: Sell Signal => Sell Trigger
//===============
   element_3630655.LinkAdd(element_3636410,ELEMENTPARAMETER_BOOLVALUE,false,0,true);
//===============

//===============
// Link: No Sells? => Sell Trigger
//===============
   element_3630655.LinkAdd(element_3645690,ELEMENTPARAMETER_BOOLVALUE,false,1,true);
//===============

//===============
// Link: Sell Trigger => Open Sell
//===============
   element_3636083.LinkAdd(element_3630655,ELEMENTPARAMETER_TRIGGER,false,0,true);
//===============

//===============
// Link: Magic => Open Sell
//===============
   element_3636083.LinkAdd(element_3634918,ELEMENTPARAMETER_MAGIC,false,4,true);
//===============

//===============
// Link: No Sells? => Buy Trigger
//===============
   element_3639134.LinkAdd(element_3645690,ELEMENTPARAMETER_BOOLVALUE,false,2,true);
//===============

//===============
// Link: No Buys? => Sell Trigger
//===============
   element_3630655.LinkAdd(element_3621495,ELEMENTPARAMETER_BOOLVALUE,false,2,true);
//===============

//===============
// Link: Lots => Open Buy
//===============
   element_3641151.LinkAdd(element_3632865,ELEMENTPARAMETER_LOTS,false,3,true);
//===============

//===============
// Link: Lots => Open Sell
//===============
   element_3636083.LinkAdd(element_3632865,ELEMENTPARAMETER_LOTS,false,3,true);
//===============

//===============
// Link: Comment => Open Buy
//===============
   element_3641151.LinkAdd(element_3640359,ELEMENTPARAMETER_COMMENT,false,5,true);
//===============

//===============
// Link: Comment => Open Sell
//===============
   element_3636083.LinkAdd(element_3640359,ELEMENTPARAMETER_COMMENT,false,5,true);
//===============

//===============
// Link: Buys => All Trades
//===============
   element_3634787.LinkAdd(element_3643317,ELEMENTPARAMETER_TRADESGROUP,false,0,true);
//===============

//===============
// Link: Sells => All Trades
//===============
   element_3634787.LinkAdd(element_3651482,ELEMENTPARAMETER_TRADESGROUP,false,1,true);
//===============

//===============
// Link: All Trades => Set SL and TP
//===============
   element_3646343.LinkAdd(element_3634787,ELEMENTPARAMETER_TRADESGROUP,false,1,true);
//===============

//===============
// Link: No Buys? => Any Trades?
//===============
   element_3621617.LinkAdd(element_3621495,ELEMENTPARAMETER_BOOLVALUE,true,0,true);
//===============

//===============
// Link: No Sells? => Any Trades?
//===============
   element_3621617.LinkAdd(element_3645690,ELEMENTPARAMETER_BOOLVALUE,true,1,true);
//===============

//===============
// Link: Any Trades? => Set SL and TP
//===============
   element_3646343.LinkAdd(element_3621617,ELEMENTPARAMETER_TRIGGER,false,0,true);
//===============

//===============
// Link: Stop Loss, points => Set SL and TP
//===============
   element_3646343.LinkAdd(element_3649488,ELEMENTPARAMETER_STOPLOSSPOINTS,false,3,true);
//===============

//===============
// Link: Take Profit, points => Set SL and TP
//===============
   element_3646343.LinkAdd(element_3632359,ELEMENTPARAMETER_TAKEPROFITPOINTS,false,4,true);
//===============

//===============
// Link: Price History => Highest Price
//===============
   element_7127666.LinkAdd(element_7088275,ELEMENTPARAMETER_PRICEHISTORY,false,0,true);
//===============

//===============
// Link: Price History => Lowest Price
//===============
   element_7142920.LinkAdd(element_7088275,ELEMENTPARAMETER_PRICEHISTORY,false,0,true);
//===============

//===============
// Link: Range, bars => Price History
//===============
   element_7088275.LinkAdd(element_7231121,ELEMENTPARAMETER_BARFROM,false,2,true);
//===============

//===============
// Link: Highest Price => Range
//===============
   element_7272543.LinkAdd(element_7127666,ELEMENTPARAMETER_DOUBLEVALUE1,false,1,true);
//===============

//===============
// Link: Lowest Price => Range
//===============
   element_7272543.LinkAdd(element_7142920,ELEMENTPARAMETER_DOUBLEVALUE2,false,3,true);
//===============

//===============
// Link: Range => Range, points
//===============
   element_7297137.LinkAdd(element_7272543,ELEMENTPARAMETER_DOUBLEVALUE,false,1,true);
//===============

//===============
// Link: Max Range, points => Good Range
//===============
   element_7410264.LinkAdd(element_7184116,ELEMENTPARAMETER_DOUBLEVALUE2,false,2,true);
//===============

//===============
// Link: Good Range => Buy Signal
//===============
   element_3636154.LinkAdd(element_7410264,ELEMENTPARAMETER_BOOLVALUE,false,0,true);
//===============

//===============
// Link: Good Range => Sell Signal
//===============
   element_3636410.LinkAdd(element_7410264,ELEMENTPARAMETER_BOOLVALUE,false,0,true);
//===============

//===============
// Link: Tick => Bid
//===============
   element_7498859.LinkAdd(element_7484021,ELEMENTPARAMETER_TICK,false,0,true);
//===============

//===============
// Link: Bid => Up BreakOut
//===============
   element_7548369.LinkAdd(element_7498859,ELEMENTPARAMETER_DOUBLEVALUE1,false,0,true);
//===============

//===============
// Link: Highest Price => Up BreakOut
//===============
   element_7548369.LinkAdd(element_7127666,ELEMENTPARAMETER_DOUBLEVALUE2,false,2,true);
//===============

//===============
// Link: Down BreakOut => Sell Signal
//===============
   element_3636410.LinkAdd(element_7581841,ELEMENTPARAMETER_BOOLVALUE,false,1,true);
//===============

//===============
// Link: Bid => Down BreakOut
//===============
   element_7581841.LinkAdd(element_7498859,ELEMENTPARAMETER_DOUBLEVALUE1,false,0,true);
//===============

//===============
// Link: Lowest Price => Down BreakOut
//===============
   element_7581841.LinkAdd(element_7142920,ELEMENTPARAMETER_DOUBLEVALUE2,false,2,true);
//===============

//===============
// Link: Up BreakOut => Buy Signal
//===============
   element_3636154.LinkAdd(element_7548369,ELEMENTPARAMETER_BOOLVALUE,false,1,true);
//===============

//===============
// Link: Range, points => Good Range
//===============
   element_7410264.LinkAdd(element_7297137,ELEMENTPARAMETER_DOUBLEVALUE1,false,0,true);
//===============

//===============
   Runner.OnInit();
//===============
 
//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
 
//===============
   return(INIT_SUCCEEDED);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick(void)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============
 
//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(Runner),true,{})
//===============
 
//===============
   if(!cPointer::Valid(Runner))::ExpertRemove();
//===============
 
//===============
   Runner.OnTick();
//===============
 
//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============
 
//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(Runner),true,{})
//===============
 
//===============
   if(!cPointer::Valid(Runner))return;
//===============
 
//===============
   Runner.OnDeinit();
//===============
 
//===============
   cPointer::Delete(Runner);
//===============
 
//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cPointer final
  {
   //====================
private:
   //====================
   //===============
   //===============
   void              cPointer(void){}
   virtual void     ~cPointer(void){}
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   static bool       Valid(const void *const pointer){return(::CheckPointer(pointer)!=POINTER_INVALID);}
   //===============
   //===============
   static void       Delete(void *pointer);
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cPointer::Delete(void *pointer)
  {
//===============
/* DEBUG ASSERTION */ASSERT({},::CheckPointer(pointer)==POINTER_DYNAMIC,true,{})
//===============

//===============
   if(::CheckPointer(pointer)!=POINTER_DYNAMIC)return;
//===============

//===============
   delete pointer;
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cArray final
  {
   //====================
private:
   //====================
   //===============
   //===============
   void              cArray(void){}
   virtual void     ~cArray(void){}
   //===============
   //===============
   static void       Sort(int &indexes[],int &sortingvalues[],int &beg,int &end);
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   template<typename T>
   static void       AddLast(T &to[],T item,const int reservesize);
   //===============
   //===============
   template<typename T>
   static bool       ValueExist(const T &array[],const T value);
   //===============
   //===============
   template<typename T>
   static void       Free(T &array[]){::ArrayFree(array);}
   template<typename T>
   static void       Initialize(T &array[],const T value){::ArrayInitialize(array,value);}
   template<typename T>
   static int        Size(T &array[]){return(::ArraySize(array));}
   template<typename T>
   static bool       Resize(T &array[],const int size,const int reserve);
   //===============
   //===============
   static void       SortAscend(int &indexes[],const int &sortingvalues[]);
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
static void cArray::AddLast(T &to[],T item,const int reservesize)
  {
//===============
   const int size=cArray::Size(to);
//===============

//===============
   if(!cArray::Resize(to,size+1,reservesize))return;
//===============

//===============
   to[size]=item;
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
static bool cArray::ValueExist(const T &array[],const T value)
  {
//===============
   bool result=false;
//===============

//===============
   const int size=cArray::Size(array);
//===============
   for(int i=0;i<size;i++)
     {
      //===============
      if(array[i]!=value)continue;
      //===============

      //===============
      result=true;
      //===============

      //===============
      break;
      //===============
     }
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
static bool cArray::Resize(T &array[],const int size,const int reserve)
  {
//===============
   const int arrayresizeresult=::ArrayResize(array,size,reserve);
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},arrayresizeresult==size,false,::Print(TOSTRING(arrayresizeresult));)
//===============

//===============
   return(arrayresizeresult==size);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cArray::SortAscend(int &indexes[],const int &sortingvalues[])
  {
//===============
   const int size=cArray::Size(sortingvalues);
//===============

//===============
   cArray::Free(indexes);
//===============
   cArray::Resize(indexes,size,0);
//===============

//===============  
   for(int cnt=0;cnt<size;cnt++)indexes[cnt]=cnt;
//===============

//===============
   int tosort[];
//===============
   cArray::Free(tosort);
//===============
   cArray::Resize(tosort,size,0);
//===============

//===============  
   for(int cnt=0;cnt<size;cnt++)tosort[cnt]=sortingvalues[cnt];
//===============

//===============
   int beg=0;
   int end=size-1;
//===============

//===============
   cArray::Sort(indexes,tosort,beg,end);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cArray::Sort(int &indexes[],int &sortingvalues[],int &beg,int &end)
  {
//===============
   if(beg<0 || end<0)return;
//===============

//===============
   int tempdatavalue=0;
   int refvalue=0;
//===============

//===============
   int i           = beg;
   int j           = end;
//===============

//===============
   const int size=cArray::Size(sortingvalues);
//===============

//===============
   int tempindex=0;
//===============

//===============
   while(i<end)
     {
      //===============
      refvalue=sortingvalues[(beg+end)>>1];
      //===============
      while(i<j)
        {
         //===============
         while(sortingvalues[i]<refvalue)
           {
            //===============
            if(i==size-1)break;
            //===============
            i++;
            //===============
           }
         //===============

         //===============
         while(sortingvalues[j]>refvalue)
           {
            //===============
            if(j==0)break;
            //===============
            j--;
            //===============
           }
         //===============

         //===============
         if(i<=j)
           {
            //===============
            if(sortingvalues[i]!=sortingvalues[j])
              {
               //===============
               tempdatavalue=sortingvalues[i];
               tempindex=indexes[i];
               sortingvalues[i]=sortingvalues[j];
               indexes[i]=indexes[j];
               sortingvalues[j]=tempdatavalue;
               indexes[j]=tempindex;
               //===============
              }
            //===============

            //===============
            if(j==0)
              {
               //===============
               i++;
               //===============
               break;
               //===============
              }
            //===============

            //===============
            i++;
            j--;
            //===============
           }
         //===============
        }
      //===============

      //===============
      if(beg<j)cArray::Sort(indexes,sortingvalues,beg,j);
      //===============

      //===============
      beg=i;
      j=end;
      //===============
     }
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cObject
  {
   //====================
public:
   //====================
   //===============
   //===============
   void              cObject(void){}
   virtual void     ~cObject(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
class cVariable final : public cObject
  {
   //====================
private:
   //====================
   //===============
   //===============
   T                 Value;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cVariable(void){}
   virtual void     ~cVariable(void){}
   //===============
   //===============
   T                 Get(void)const{return(this.Value);}
   void              Set(const T value){this.Value=value;}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cRunner final
  {
   //====================
private:
   //====================
   //===============
   //===============
   cExecutable      *Elements[];
   cExecutable      *EndElements[];
   //===============
   //===============
   void              Clear(void);
   //===============
   //===============
   void              Run(void)const;
   void              SortParameters(void)const;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cRunner(void){cArray::Free(this.Elements);cArray::Free(this.EndElements);}
   virtual void     ~cRunner(void){this.Clear();}
   //===============
   //===============
   void              Add(cExecutable *const element,const bool isend);
   //===============
   //===============
   void              OnDeinit(void);
   void              OnTick(void)const{this.Run();}
   void              OnInit(void)const{this.SortParameters();}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cRunner::Run(void)const
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const int elements=cArray::Size(this.Elements);
//===============
   for(int i=0;i<elements;i++)
     {
      //===============
      bool valid=false;
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT(valid=cPointer::Valid(this.Elements[i]);,
                      valid,true,
                      continue;)
      //===============

      //===============
      this.Elements[i].ReFreshEnable();
      //===============
     }
//===============

//===============
   const int endelements=cArray::Size(this.EndElements);
//===============
   for(int i=0;i<endelements;i++)
     {
      //===============
      bool valid=false;
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT(valid=cPointer::Valid(this.EndElements[i]);,
                      valid,true,
                      continue;)
      //===============

      //===============
      this.EndElements[i].StartExecutionThread(false);
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cRunner::SortParameters(void)const
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const int elements=cArray::Size(this.Elements);
//===============
   for(int i=0;i<elements;i++)
     {
      //===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(this.Elements[i]),true,{})
      //===============

      //===============
      if(!cPointer::Valid(this.Elements[i]))continue;
      //===============

      //===============
      this.Elements[i].SortParameters();
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cRunner::Add(cExecutable *const element,const bool isend)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(element),true,{})
//===============

//===============
   if(!cPointer::Valid(element))return;
//===============

//===============
   cArray::AddLast(this.Elements,element,0);
//===============

//===============
   if(isend)cArray::AddLast(this.EndElements,element,0);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cRunner::OnDeinit(void)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   this.Clear();
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cRunner::Clear(void)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const int size=cArray::Size(this.Elements);
//===============
   for(int i=0;i<size;i++)
     {
      //===============
      cPointer::Delete(this.Elements[i]);
      //===============
     }
//===============

//===============
   cArray::Free(this.Elements);
//===============
   cArray::Free(this.EndElements);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//===============
//#defines
//===============
//===============
#define TSLSTEPPOINTS                  5
//===============
#define SEARCHTO                       "to #"
#define SEARCHFROM                     "from #"
#define SEARCHBY                       "by #"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cInfo
  {
   //====================
protected:
   //====================
   //===============
   //===============
   string            Symbol;
   string            Comment;
   datetime          OpenTime;
   datetime          CloseTime;
   double            Lots;
   double            OpenPrice;
   double            StopLoss;
   double            TakeProfit;
   long              Ticket;
   long              Magic;
   //===============
   //===============
   virtual void      ReSet(void);
   //===============
   //===============
   void              cInfo(void){this.ReSet();}
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   virtual void     ~cInfo(void){}
   //===============
   //===============
   string            SymbolGet(void)const{return(this.Symbol);}
   string            CommentGet(void)const{return(this.Comment);}
   double            LotsGet(void)const{return(this.Lots);}
   double            OpenPriceGet(void)const{return(this.OpenPrice);}
   double            StopLossGet(void)const{return(this.StopLoss);}
   double            TakeProfitGet(void)const{return(this.TakeProfit);}
   long              TicketGet(void)const{return(this.Ticket);}
   long              MagicGet(void)const{return(this.Magic);}
   datetime          OpenTimeGet(void)const{return(this.OpenTime);}
   datetime          CloseTimeGet(void)const{return(this.CloseTime);}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cInfo::ReSet(void)
  {
//===============
   this.Symbol       = NULL;
   this.Comment      = NULL;
   this.Lots         = 0.0;
   this.OpenPrice    = 0.0;
   this.StopLoss     = 0.0;
   this.OpenTime     = 0;
   this.CloseTime    = 0;
   this.TakeProfit   = 0.0;
   this.Ticket       = -1;
   this.Magic        = -1;
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cTradeInfo final : public cInfo
  {
   //====================
private:
   //====================
   //===============
   //===============
   double            ProfitMoney;
   double            Commission;
   double            Swap;
   double            ClosePrice;
   long              ProfitPoints;
   long              Identifier;
   eTradeType        Type;
   eTradeStatus      Status;
   //===============
   //===============
   bool              SetFromCurrent(const long ticket,const bool countcommissions);
   bool              SetFromHistory(const long positionID);
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cTradeInfo(void){this.ReSet();}
   virtual void     ~cTradeInfo(void){}
   //===============
   //===============
   double            ProfitMoneyGet(void)const{return(this.ProfitMoney);}
   double            CommissionGet(void)const{return(this.Commission);}
   double            SwapGet(void)const{return(this.Swap);}
   double            ClosePriceGet(void)const{return(this.ClosePrice);}
   long              ProfitPointsGet(void)const{return(this.ProfitPoints);}
   long              IdentifierGet(void)const{return(this.Identifier);}
   eTradeType        TypeGet(void)const{return(this.Type);}
   eTradeStatus      StatusGet(void)const{return(this.Status);}
   //===============
   //===============
   void              Update(const long ticket,const bool includehistory,const bool countcommissions,const bool searchoriginalticket);
   void              Update(const long ticket,const long identifier,const eTradeType type,const eTradeStatus status,const string symbol,
                            const long magic,const string comment,const double lots,const double openprice,const double stoploss,
                            const double takeprofit,const datetime opentime);
   //===============
   //===============
   virtual void      ReSet(void)override final;
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cTradeInfo::SetFromCurrent(const long ticket,const bool countcommissions)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(ticket<=0)return(false);
//===============

//===============
   bool result=false;
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   result=::PositionSelectByTicket(ticket);
//===============

//===============
   if(!result)
     {
      //===============
      ::ResetLastError();
      //===============

      //===============
      return(false);
      //===============
     }
//===============

//===============
   this.Ticket       = ::PositionGetInteger(POSITION_TICKET);
   this.Identifier   = ::PositionGetInteger(POSITION_IDENTIFIER);
   this.Status       = TRADESTATUS_CURRENT;
   this.Symbol       = ::PositionGetString(POSITION_SYMBOL);
   this.Magic        = ::PositionGetInteger(POSITION_MAGIC);
   this.Comment      = ::PositionGetString(POSITION_COMMENT);
   this.Lots         = ::PositionGetDouble(POSITION_VOLUME);
   this.OpenPrice    = ::PositionGetDouble(POSITION_PRICE_OPEN);
   this.ClosePrice   = ::PositionGetDouble(POSITION_PRICE_CURRENT);
   this.StopLoss     = ::PositionGetDouble(POSITION_SL);
   this.TakeProfit   = ::PositionGetDouble(POSITION_TP);
   this.ProfitMoney  = ::PositionGetDouble(POSITION_PROFIT);
   this.Swap         = ::PositionGetDouble(POSITION_SWAP);
   this.OpenTime     = (datetime)::PositionGetInteger(POSITION_TIME);
   this.CloseTime    = 0;
//=============== 
   const ENUM_POSITION_TYPE positiontype=(ENUM_POSITION_TYPE)::PositionGetInteger(POSITION_TYPE);
//===============
   if(positiontype==POSITION_TYPE_BUY)
     {
      //===============
      this.Type=TRADETYPE_BUY;
      //===============
     }
   else if(positiontype==POSITION_TYPE_SELL)
     {
      //===============
      this.Type=TRADETYPE_SELL;
      //===============
     }
//=============== 
   this.ProfitPoints=cTrade::ProfitPointsGet(this.Type,this.OpenPrice,this.ClosePrice,this.Symbol);
//===============
   if(countcommissions)this.Commission=cTrade::CommissionGet(::PositionGetInteger(POSITION_IDENTIFIER));
//===============    

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============
/* DEBUG ASSERTION */ASSERT({},false,true,{})
//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cTradeInfo::SetFromHistory(const long positionID)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(positionID<=0)return(false);
//===============

//===============
   bool result=false;
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   result=::HistorySelectByPosition(positionID);
//===============

//===============
   if(!result)
     {
      //===============
      ::ResetLastError();
      //===============

      //===============
      return(false);
      //===============
     }
//===============

//===============
   this.Ticket            = positionID;
   this.Identifier        = positionID;
   this.Status            = TRADESTATUS_HISTORY;
//===============

//===============
   const int deals=::HistoryDealsTotal();
//===============

//===============  
   for(int i=0;i<deals && !::IsStopped();i++)
     {
      //===============
      const ulong dealticket=::HistoryDealGetTicket(i);
      //===============
      const ENUM_DEAL_ENTRY entrytype=(ENUM_DEAL_ENTRY)::HistoryDealGetInteger(dealticket,DEAL_ENTRY);
      //===============
      const ENUM_DEAL_TYPE dealtype=(ENUM_DEAL_TYPE)::HistoryDealGetInteger(dealticket,DEAL_TYPE);
      //===============

      //===============
      if(entrytype==DEAL_ENTRY_IN)
        {
         //===============
         this.Symbol       = ::HistoryDealGetString(dealticket,DEAL_SYMBOL);
         this.Magic        = ::HistoryDealGetInteger(dealticket,DEAL_MAGIC);
         this.Comment      = ::HistoryDealGetString(dealticket,DEAL_COMMENT);
         this.Lots        += ::HistoryDealGetDouble(dealticket,DEAL_VOLUME);
         this.OpenPrice    = ::HistoryDealGetDouble(dealticket,DEAL_PRICE);
         this.OpenTime     = (datetime)::HistoryDealGetInteger(dealticket,DEAL_TIME);
         //===============

         //===============
         if(dealtype==DEAL_TYPE_BUY)
           {
            //===============
            this.Type=TRADETYPE_BUY;
            //===============
           }
         else if(dealtype==DEAL_TYPE_SELL)
           {
            //===============
            this.Type=TRADETYPE_SELL;
            //===============
           }
         //===============
        }
      //===============

      //===============
      if(entrytype==DEAL_ENTRY_OUT || entrytype==DEAL_ENTRY_OUT_BY || entrytype==DEAL_ENTRY_INOUT)
        {
         //===============
         this.CloseTime     = (datetime)::HistoryDealGetInteger(dealticket,DEAL_TIME);
         this.ClosePrice    = ::HistoryDealGetDouble(dealticket,DEAL_PRICE);
         //===============
        }
      //===============

      //===============
      this.Commission  += ::HistoryDealGetDouble(dealticket,DEAL_COMMISSION);
      this.Swap        += ::HistoryDealGetDouble(dealticket,DEAL_SWAP);
      this.ProfitMoney += ::HistoryDealGetDouble(dealticket,DEAL_PROFIT);
      //===============
     }
//===============

//=============== 
   this.ProfitPoints=cTrade::ProfitPointsGet(this.Type,this.OpenPrice,this.ClosePrice,this.Symbol);
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============
/* DEBUG ASSERTION */ASSERT({},false,true,{})
//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cTradeInfo::Update(const long ticket,const bool includehistory,const bool countcommissions,const bool searchoriginalticket)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   this.ReSet();
//===============

//===============
   if(ticket<=0)return;
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   const bool setfromcurrent=this.SetFromCurrent(ticket,countcommissions);
//===============

//===============
   if(!setfromcurrent && includehistory)
     {
      //===============
      ::ResetLastError();
      //===============

      //===============
      this.SetFromHistory(ticket);
      //=============== 
     }
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============

//===============
   if(::OrderSelect((int)ticket,SELECT_BY_TICKET) && (::OrderType()==OP_BUY || ::OrderType()==OP_SELL))
     {
      //===============
      if(::OrderCloseTime()==0)
        {
         //===============
         this.Status=TRADESTATUS_CURRENT;
         //===============
        }
      //===============
      else if(::OrderCloseTime()>0)
        {
         //===============
         if(!includehistory)return;
         //===============

         //===============
         this.Status=TRADESTATUS_HISTORY;
         //===============
        }
      //===============

      //===============
      if(::OrderType()==OP_BUY)
        {
         //===============
         this.Type=TRADETYPE_BUY;
         //===============
        }
      else if(::OrderType()==OP_SELL)
        {
         //===============
         this.Type=TRADETYPE_SELL;
         //===============
        }
      //===============

      //===============
      this.Ticket       = (long)::OrderTicket();
      this.Symbol       = ::OrderSymbol();
      this.Magic        = (long)::OrderMagicNumber();
      this.Comment      = ::OrderComment();
      this.Lots         = ::OrderLots();
      this.OpenPrice    = ::OrderOpenPrice();
      this.ClosePrice   = ::OrderClosePrice();
      this.StopLoss     = ::OrderStopLoss();
      this.TakeProfit   = ::OrderTakeProfit();
      this.ProfitMoney  = ::OrderProfit();
      this.Swap         = ::OrderSwap();
      this.OpenTime     = ::OrderOpenTime();
      this.CloseTime    = ::OrderCloseTime();
      this.Commission   = ::OrderCommission();
      //===============

      //=============== 
      this.ProfitPoints=cTrade::ProfitPointsGet(this.Type,this.OpenPrice,this.ClosePrice,this.Symbol);
      //===============

      //===============
      if(searchoriginalticket)cTrade::GetOriginalTicket(this.Ticket,this.Comment);
      //===============

      //===============
      this.Identifier=this.Ticket;
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cTradeInfo::Update(const long ticket,const long identifier,const eTradeType type,const eTradeStatus status,const string symbol,
                        const long magic,const string comment,const double lots,const double openprice,const double stoploss,
                        const double takeprofit,const datetime opentime)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   this.ReSet();
//===============

//===============
   this.Ticket       = ticket;
   this.Identifier   = identifier;
   this.Type         = type;
   this.Status       = status;
   this.Symbol       = symbol;
   this.Magic        = magic;
   this.Comment      = comment;
   this.Lots         = lots;
   this.OpenPrice    = openprice;
   this.StopLoss     = stoploss;
   this.TakeProfit   = takeprofit;
   this.OpenTime     = opentime;
//=============== 

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cTradeInfo::ReSet(void)override final
  {
//===============
   cInfo::ReSet();
//===============

//===============
   this.ProfitMoney  = 0.0;
   this.Commission   = 0.0;
   this.Swap         = 0.0;
   this.ClosePrice   = 0.0;
   this.ProfitPoints = 0;
   this.Identifier   = -1;
   this.Type         = WRONG_VALUE;
   this.Status       = WRONG_VALUE;
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cPendingOrderInfo final : public cInfo
  {
   //====================
private:
   //====================
   //===============
   //===============
   datetime          Expiration;
   ePendingOrderType Type;
   ePendingOrderStatus Status;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cPendingOrderInfo(void){this.ReSet();}
   virtual void     ~cPendingOrderInfo(void){}
   //===============
   //===============
   datetime          ExpirationGet(void)const{return(this.Expiration);}
   ePendingOrderType TypeGet(void)const{return(this.Type);}
   ePendingOrderStatus StatusGet(void)const{return(this.Status);}
   //===============
   //===============
   void              Update(const long ticket);
   void              Update(const long ticket,const ePendingOrderType type,const ePendingOrderStatus status,const string symbol,const long magic,
                            const string comment,const double lots,const double openprice,const double stoploss,const double takeprofit,
                            const datetime expiration,const datetime opentime);
   //===============
   //===============
   virtual void      ReSet(void)override final;
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cPendingOrderInfo::Update(const long ticket)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   this.ReSet();
//===============

//===============
   if(ticket<=0)return;
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   ENUM_ORDER_TYPE ordertype=WRONG_VALUE;
//===============

//===============
// Check Current 
//===============
   if(::OrderSelect((ulong)ticket))
     {
      //=============== 
      ordertype=(ENUM_ORDER_TYPE)::OrderGetInteger(ORDER_TYPE);
      //===============
      if(ordertype==ORDER_TYPE_BUY_STOP || ordertype==ORDER_TYPE_BUY_LIMIT ||
         ordertype==ORDER_TYPE_SELL_STOP || ordertype==ORDER_TYPE_SELL_LIMIT)
        {
         //===============
         this.Ticket       = ::OrderGetInteger(ORDER_TICKET);
         this.Status       = ORDERSTATUS_PENDING;
         this.Symbol       = ::OrderGetString(ORDER_SYMBOL);
         this.Magic        = ::OrderGetInteger(ORDER_MAGIC);
         this.Comment      = ::OrderGetString(ORDER_COMMENT);
         this.Lots         = ::OrderGetDouble(ORDER_VOLUME_CURRENT);
         this.OpenPrice    = ::OrderGetDouble(ORDER_PRICE_OPEN);
         this.StopLoss     = ::OrderGetDouble(ORDER_SL);
         this.TakeProfit   = ::OrderGetDouble(ORDER_TP);
         this.OpenTime     = (datetime)::OrderGetInteger(ORDER_TIME_SETUP);
         this.Expiration   = (datetime)::OrderGetInteger(ORDER_TIME_EXPIRATION);
         this.CloseTime    = 0;
         //===============
        }
      else
        {
         //=============== 
         ordertype=WRONG_VALUE;
         //=============== 
        }
      //=============== 
     }
//===============
// Check History
//===============
   else if(::HistoryOrderSelect((ulong)ticket))
     {
      //===============
      ::ResetLastError();
      //===============

      //=============== 
      ordertype=(ENUM_ORDER_TYPE)::HistoryOrderGetInteger((ulong)ticket,ORDER_TYPE);
      //===============
      if(ordertype==ORDER_TYPE_BUY_STOP || ordertype==ORDER_TYPE_BUY_LIMIT ||
         ordertype==ORDER_TYPE_SELL_STOP || ordertype==ORDER_TYPE_SELL_LIMIT)
        {
         //=============== 
         this.Ticket       = ::HistoryOrderGetInteger((ulong)ticket,ORDER_TICKET);
         this.Status       = ORDERSTATUS_HISTORY;
         this.Symbol       = ::HistoryOrderGetString((ulong)ticket,ORDER_SYMBOL);
         this.Magic        = ::HistoryOrderGetInteger((ulong)ticket,ORDER_MAGIC);
         this.Comment      = ::HistoryOrderGetString((ulong)ticket,ORDER_COMMENT);
         this.Lots         = ::HistoryOrderGetDouble((ulong)ticket,ORDER_VOLUME_CURRENT);
         this.OpenPrice    = ::HistoryOrderGetDouble((ulong)ticket,ORDER_PRICE_OPEN);
         this.StopLoss     = ::HistoryOrderGetDouble((ulong)ticket,ORDER_SL);
         this.TakeProfit   = ::HistoryOrderGetDouble((ulong)ticket,ORDER_TP);
         this.OpenTime     = (datetime)::HistoryOrderGetInteger((ulong)ticket,ORDER_TIME_SETUP);
         this.Expiration   = (datetime)::HistoryOrderGetInteger((ulong)ticket,ORDER_TIME_EXPIRATION);
         this.CloseTime    = (datetime)::HistoryOrderGetInteger((ulong)ticket,ORDER_TIME_DONE);
         //=============== 
        }
      else
        {
         //=============== 
         ordertype=WRONG_VALUE;
         //=============== 
        }
      //=============== 
     }
//=============== 

//===============
   if(ordertype==ORDER_TYPE_BUY_STOP)
     {
      //===============
      this.Type=PENDINGORDERTYPE_BUYSTOP;
      //===============
     }
   else if(ordertype==ORDER_TYPE_BUY_LIMIT)
     {
      //===============
      this.Type=PENDINGORDERTYPE_BUYLIMIT;
      //===============
     }
   else if(ordertype==ORDER_TYPE_SELL_LIMIT)
     {
      //===============
      this.Type=PENDINGORDERTYPE_SELLLIMIT;
      //===============
     }
   else if(ordertype==ORDER_TYPE_SELL_STOP)
     {
      //===============
      this.Type=PENDINGORDERTYPE_SELLSTOP;
      //===============
     }
//=============== 

//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============

//===============
   if(::OrderSelect((int)ticket,SELECT_BY_TICKET) && 
      (::OrderType()==OP_BUYSTOP || ::OrderType()==OP_SELLSTOP || ::OrderType()==OP_BUYLIMIT || ::OrderType()==OP_SELLLIMIT))
     {
      //===============
      if(::OrderCloseTime()==0)
        {
         //===============
         this.Status=ORDERSTATUS_PENDING;
         //===============
        }
      //===============
      else if(::OrderCloseTime()>0)
        {
         //===============
         this.Status=ORDERSTATUS_HISTORY;
         //===============
        }
      //===============

      //===============
      const int ordertype=::OrderType();
      //===============
      if(ordertype==OP_BUYSTOP)
        {
         //===============
         this.Type=PENDINGORDERTYPE_BUYSTOP;
         //===============
        }
      else if(ordertype==OP_BUYLIMIT)
        {
         //===============
         this.Type=PENDINGORDERTYPE_BUYLIMIT;
         //===============
        }
      else if(ordertype==OP_SELLLIMIT)
        {
         //===============
         this.Type=PENDINGORDERTYPE_SELLLIMIT;
         //===============
        }
      else if(ordertype==OP_SELLSTOP)
        {
         //===============
         this.Type=PENDINGORDERTYPE_SELLSTOP;
         //===============
        }
      //===============
      this.Ticket       = (long)::OrderTicket();
      this.Symbol       = ::OrderSymbol();
      this.Magic        = (long)::OrderMagicNumber();
      this.Comment      = ::OrderComment();
      this.Lots         = ::OrderLots();
      this.OpenPrice    = ::OrderOpenPrice();
      this.StopLoss     = ::OrderStopLoss();
      this.TakeProfit   = ::OrderTakeProfit();
      this.OpenTime     = ::OrderOpenTime();
      this.CloseTime    = ::OrderCloseTime();
      this.Expiration   = ::OrderExpiration();
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cPendingOrderInfo::Update(const long ticket,const ePendingOrderType type,const ePendingOrderStatus status,const string symbol,const long magic,
                               const string comment,const double lots,const double openprice,const double stoploss,const double takeprofit,
                               const datetime expiration,const datetime opentime)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   this.ReSet();
//===============

//===============
   this.Ticket       = ticket;
   this.Type         = type;
   this.Status       = status;
   this.Symbol       = symbol;
   this.Magic        = magic;
   this.Comment      = comment;
   this.Lots         = lots;
   this.OpenPrice    = openprice;
   this.StopLoss     = stoploss;
   this.TakeProfit   = takeprofit;
   this.Expiration   = expiration;
   this.OpenTime     = opentime;
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cPendingOrderInfo::ReSet(void)override final
  {
//===============
   cInfo::ReSet();
//===============

//===============
   this.Expiration  = 0;
   this.Type        = WRONG_VALUE;
   this.Status      = WRONG_VALUE;
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cGroupInfo
  {
   //====================
protected:
   //====================
   //===============
   //===============
   double            TotalLots;
   double            AveragePrice;
   long              ItemsNumber;
   long              SymbolsNumber;
   long              MaxLotsTicket;
   long              MinLotsTicket;
   long              LowestOpenPriceTicket;
   long              HighestOpenPriceTicket;
   long              EarliestOpenTimeTicket;
   long              LatestOpenTimeTicket;
   long              EarliestCloseTimeTicket;
   long              LatestCloseTimeTicket;
   //===============
   //===============
   virtual void      ReSet(void);
   //===============
   //===============
   void              cGroupInfo(void){this.ReSet();}
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   virtual void     ~cGroupInfo(void){}
   //===============
   //===============
   double            TotalLotsGet(void)const{return(this.TotalLots);}
   double            AveragePriceGet(void)const{return(this.AveragePrice);}
   long              ItemsNumberGet(void)const{return(this.ItemsNumber);}
   long              SymbolsNumberGet(void)const{return(this.SymbolsNumber);}
   long              MaxLotsTicketGet(void)const{return(this.MaxLotsTicket);}
   long              MinLotsTicketGet(void)const{return(this.MinLotsTicket);}
   long              LowestOpenPriceTicketGet(void)const{return(this.LowestOpenPriceTicket);}
   long              HighestOpenPriceTicketGet(void)const{return(this.HighestOpenPriceTicket);}
   long              EarliestOpenTimeTicketGet(void)const{return(this.EarliestOpenTimeTicket);}
   long              LatestOpenTimeTicketGet(void)const{return(this.LatestOpenTimeTicket);}
   long              EarliestCloseTimeTicketGet(void)const{return(this.EarliestCloseTimeTicket);}
   long              LatestCloseTimeTicketGet(void)const{return(this.LatestCloseTimeTicket);}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cGroupInfo::ReSet(void)
  {
//===============
   this.TotalLots               = 0.0;
   this.AveragePrice            = 0.0;
   this.ItemsNumber             = 0;
   this.SymbolsNumber           = 0;
   this.MaxLotsTicket           = -1;
   this.MinLotsTicket           = -1;
   this.LowestOpenPriceTicket   = -1;
   this.HighestOpenPriceTicket  = -1;
   this.EarliestOpenTimeTicket  = -1;
   this.LatestOpenTimeTicket    = -1;
   this.EarliestCloseTimeTicket = -1;
   this.LatestCloseTimeTicket   = -1;
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cTradesGroupInfo final : public cGroupInfo
  {
   //====================
private:
   //====================
   //===============
   //===============
   double            ProfitMoney;
   long              ProfitPoints;
   long              MaxProfitMoneyTicket;
   long              MinProfitMoneyTicket;
   long              MaxProfitPointsTicket;
   long              MinProfitPointsTicket;
   long              LowestClosePriceTicket;
   long              HighestClosePriceTicket;
   //===============
   //===============
   virtual void      ReSet(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cTradesGroupInfo(void){this.ReSet();}
   virtual void     ~cTradesGroupInfo(void){}
   //===============
   //===============
   double            ProfitMoneyGet(void)const{return(this.ProfitMoney);}
   long              ProfitPointsGet(void)const{return(this.ProfitPoints);}
   long              MaxProfitMoneyTicketGet(void)const{return(this.MaxProfitMoneyTicket);}
   long              MinProfitMoneyTicketGet(void)const{return(this.MinProfitMoneyTicket);}
   long              MaxProfitPointsTicketGet(void)const{return(this.MaxProfitPointsTicket);}
   long              MinProfitPointsTicketGet(void)const{return(this.MinProfitPointsTicket);}
   long              LowestClosePriceTicketGet(void)const{return(this.LowestClosePriceTicket);}
   long              HighestClosePriceTicketGet(void)const{return(this.HighestClosePriceTicket);}
   //===============
   //===============
   void              Update(const long &tickets[]);
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cTradesGroupInfo::Update(const long &tickets[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   this.ReSet();
//===============

//===============
   cTradeInfo trades[];
//===============

//===============
   cArray::Free(trades);
//===============

//===============
   const int size=cArray::Size(tickets);
//===============
   cArray::Resize(trades,size,0);
//===============

//===============
   for(int i=0;i<size && !::IsStopped();i++)
     {
      //===============
      trades[i].Update(tickets[i],true,true,false);
      //===============
     }
//===============

//===============
   string symbols[];
//===============

//===============
   cArray::Free(symbols);
//===============

//===============
   for(int i=0;i<size && !::IsStopped();i++)
     {
      //===============
      if(trades[i].TicketGet()<=0)continue;
      //===============

      //===============
      this.ItemsNumber++;
      this.TotalLots+=trades[i].LotsGet();
      this.ProfitMoney+=trades[i].ProfitMoneyGet()+trades[i].SwapGet()+trades[i].CommissionGet();
      this.ProfitPoints+=trades[i].ProfitPointsGet();
      //===============

      //===============
      if(!cArray::ValueExist(symbols,trades[i].SymbolGet()))cArray::AddLast(symbols,trades[i].SymbolGet(),size);
      //===============
     }
//===============

//===============
   this.SymbolsNumber=cArray::Size(symbols);
//===============

//===============
   double lowestopenprice      = DBL_MAX;
   double highestopenprice     = DBL_MIN;
   double lowestcloseprice     = DBL_MAX;
   double highestcloseprice    = DBL_MIN;
   double minlots              = DBL_MAX;
   double maxlots              = DBL_MIN;
   double maxprofitmoney       = DBL_MIN;
   double minprofitmoney       = DBL_MAX;
//===============
   long   maxprofitpoints      = LONG_MIN;
   long   minprofitpoints      = LONG_MIN;
//=============== 
   datetime earliestopentime   = INT_MAX;
   datetime latestopentime     = INT_MIN;
   datetime earliestclosetime  = INT_MAX;
   datetime latestclosetime    = INT_MIN;
//===============

//===============
   for(int i=0;i<size && !::IsStopped();i++)
     {
      //===============
      if(trades[i].TicketGet()<=0)continue;
      //===============

      //===============
      if(this.TotalLots!=0)this.AveragePrice+=trades[i].LotsGet()*trades[i].OpenPriceGet()/this.TotalLots;
      //===============

      //===============
      const long ticket=trades[i].TicketGet();
      //===============
      const double openprice=trades[i].OpenPriceGet();
      //===============
      const double closeprice=trades[i].ClosePriceGet();
      //===============
      const double lots=trades[i].LotsGet();
      //===============
      const double profitmoney=trades[i].ProfitMoneyGet();
      //===============
      const long profitpoints=trades[i].ProfitPointsGet();
      //===============
      const datetime opentime=trades[i].OpenTimeGet();
      //===============
      const datetime closetime=trades[i].CloseTimeGet();
      //===============

      //===============
      if(profitpoints<minprofitpoints)
        {
         //===============
         this.MinProfitPointsTicket=ticket;
         //===============
         minprofitpoints=profitpoints;
         //===============
        }
      //===============

      //===============
      if(profitpoints>maxprofitpoints)
        {
         //===============
         this.MaxProfitPointsTicket=ticket;
         //===============
         maxprofitpoints=profitpoints;
         //===============
        }
      //===============

      //===============
      if(profitmoney<minprofitmoney)
        {
         //===============
         this.MinProfitMoneyTicket=ticket;
         //===============
         minprofitmoney=profitmoney;
         //===============
        }
      //===============

      //===============
      if(profitmoney>maxprofitmoney)
        {
         //===============
         this.MaxProfitMoneyTicket=ticket;
         //===============
         maxprofitmoney=profitmoney;
         //===============
        }
      //===============

      //===============
      if(lots<minlots)
        {
         //===============
         this.MinLotsTicket=ticket;
         //===============
         minlots=lots;
         //===============
        }
      //===============

      //===============
      if(lots>maxlots)
        {
         //===============
         this.MaxLotsTicket=ticket;
         //===============
         maxlots=lots;
         //===============
        }
      //===============

      //===============
      if(openprice<lowestopenprice)
        {
         //===============
         this.LowestOpenPriceTicket=ticket;
         //===============
         lowestopenprice=openprice;
         //===============
        }
      //===============

      //===============
      if(openprice>highestopenprice)
        {
         //===============
         this.HighestOpenPriceTicket=ticket;
         //===============
         highestopenprice=openprice;
         //===============
        }
      //===============

      //===============
      if(closeprice<lowestcloseprice)
        {
         //===============
         this.LowestClosePriceTicket=ticket;
         //===============
         lowestcloseprice=closeprice;
         //===============
        }
      //===============

      //===============
      if(closeprice>highestcloseprice)
        {
         //===============
         this.HighestClosePriceTicket=ticket;
         //===============
         highestcloseprice=closeprice;
         //===============
        }
      //===============

      //===============
      if(opentime<earliestopentime)
        {
         //===============
         this.EarliestOpenTimeTicket=ticket;
         //===============
         earliestopentime=opentime;
         //===============
        }
      //===============

      //===============
      if(opentime>latestopentime)
        {
         //===============
         this.LatestOpenTimeTicket=ticket;
         //===============
         latestopentime=opentime;
         //===============
        }
      //===============

      //===============
      if(closetime<earliestclosetime)
        {
         //===============
         this.EarliestCloseTimeTicket=ticket;
         //===============
         earliestclosetime=closetime;
         //===============
        }
      //===============

      //===============
      if(closetime>latestclosetime)
        {
         //===============
         this.LatestCloseTimeTicket=ticket;
         //===============
         latestclosetime=closetime;
         //===============
        }
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cTradesGroupInfo::ReSet(void)override final
  {
//===============
   cGroupInfo::ReSet();
//===============

//===============
   this.ProfitMoney             = 0.0;
   this.ProfitPoints            = 0;
   this.MaxProfitMoneyTicket    = -1;
   this.MinProfitMoneyTicket    = -1;
   this.MaxProfitPointsTicket   = -1;
   this.MinProfitPointsTicket   = -1;
   this.LowestClosePriceTicket  = -1;
   this.HighestClosePriceTicket = -1;
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cPendingOrdersGroupInfo final : public cGroupInfo
  {
   //====================
private:
   //====================
   //===============
   //===============
   virtual void      ReSet(void)override final{cGroupInfo::ReSet();}
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cPendingOrdersGroupInfo(void){this.ReSet();}
   virtual void     ~cPendingOrdersGroupInfo(void){}
   //===============
   //===============
   void              Update(const long &tickets[]);
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cPendingOrdersGroupInfo::Update(const long &tickets[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   this.ReSet();
//===============

//===============
   cPendingOrderInfo orders[];
//===============

//===============
   cArray::Free(orders);
//===============

//===============
   const int size=cArray::Size(tickets);
//===============
   cArray::Resize(orders,size,0);
//===============

//===============
   for(int i=0;i<size && !::IsStopped();i++)
     {
      //===============
      orders[i].Update(tickets[i]);
      //===============
     }
//===============

//===============
   string symbols[];
//===============

//===============
   cArray::Free(symbols);
//===============

//===============
   for(int i=0;i<size && !::IsStopped();i++)
     {
      //===============
      if(orders[i].TicketGet()<=0)continue;
      //===============

      //===============
      this.ItemsNumber++;
      this.TotalLots+=orders[i].LotsGet();
      //===============

      //===============
      if(!cArray::ValueExist(symbols,orders[i].SymbolGet()))cArray::AddLast(symbols,orders[i].SymbolGet(),size);
      //===============
     }
//===============

//===============
   this.SymbolsNumber=cArray::Size(symbols);
//===============

//===============
   double lowestopenprice      = DBL_MAX;
   double highestopenprice     = DBL_MIN;
   double minlots              = DBL_MAX;
   double maxlots              = DBL_MIN;
//===============
   datetime earliestopentime   = INT_MAX;
   datetime latestopentime     = INT_MIN;
   datetime earliestclosetime  = INT_MAX;
   datetime latestclosetime    = INT_MIN;
//===============

//===============
   for(int i=0;i<size && !::IsStopped();i++)
     {
      //===============
      if(orders[i].TicketGet()<=0)continue;
      //===============

      //===============
      if(this.TotalLots!=0)this.AveragePrice+=orders[i].LotsGet()*orders[i].OpenPriceGet()/this.TotalLots;
      //===============

      //===============
      const long ticket=orders[i].TicketGet();
      //===============
      const double lots=orders[i].LotsGet();
      //===============
      const double openprice=orders[i].OpenPriceGet();
      //===============
      const datetime opentime=orders[i].OpenTimeGet();
      //===============
      const datetime closetime=orders[i].CloseTimeGet();
      //===============

      //===============
      if(lots<minlots)
        {
         //===============
         this.MinLotsTicket=ticket;
         //===============
         minlots=lots;
         //===============
        }
      //===============

      //===============
      if(lots>maxlots)
        {
         //===============
         this.MaxLotsTicket=ticket;
         //===============
         maxlots=lots;
         //===============
        }
      //===============

      //===============
      if(openprice<lowestopenprice)
        {
         //===============
         this.LowestOpenPriceTicket=ticket;
         //===============
         lowestopenprice=openprice;
         //===============
        }
      //===============

      //===============
      if(openprice>highestopenprice)
        {
         //===============
         this.HighestOpenPriceTicket=ticket;
         //===============
         highestopenprice=openprice;
         //===============
        }
      //===============

      //===============
      if(opentime<earliestopentime)
        {
         //===============
         this.EarliestOpenTimeTicket=ticket;
         //===============
         earliestopentime=opentime;
         //===============
        }
      //===============

      //===============
      if(opentime>latestopentime)
        {
         //===============
         this.LatestOpenTimeTicket=ticket;
         //===============
         latestopentime=opentime;
         //===============
        }
      //===============

      //===============
      if(closetime<earliestclosetime)
        {
         //===============
         this.EarliestCloseTimeTicket=ticket;
         //===============
         earliestclosetime=closetime;
         //===============
        }
      //===============

      //===============
      if(closetime>latestclosetime)
        {
         //===============
         this.LatestCloseTimeTicket=ticket;
         //===============
         latestclosetime=closetime;
         //===============
        }
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cFilter
  {
   //====================
protected:
   //====================
   //===============
   //===============
   bool              FilterByMagic;
   long              Magic;
   bool              FilterBySymbol;
   string            Symbol;
   bool              FilterByType;
   bool              FilterByTicketGreaterOrEqualThan;
   long              TicketGreaterOrEqualThan;
   bool              FilterByTicketLessOrEqualThan;
   long              TicketLessOrEqualThan;
   bool              FilterByExactComment;
   string            ExactComment;
   bool              FilterByCommentPartial;
   string            CommentPartial;
   bool              FilterByOpenPriceGreaterOrEqualThan;
   double            OpenPriceGreaterOrEqualThan;
   bool              FilterByOpenPriceLessOrEqualThan;
   double            OpenPriceLessOrEqualThan;
   bool              FilterByOpenTimeGreaterOrEqualThan;
   datetime          OpenTimeGreaterOrEqualThan;
   bool              FilterByOpenTimeLessOrEqualThan;
   datetime          OpenTimeLessOrEqualThan;
   bool              FilterByCloseTimeGreaterOrEqualThan;
   datetime          CloseTimeGreaterOrEqualThan;
   bool              FilterByCloseTimeLessOrEqualThan;
   datetime          CloseTimeLessOrEqualThan;
   bool              FilterByLotsGreaterOrEqualThan;
   double            LotsGreaterOrEqualThan;
   bool              FilterByLotsLessOrEqualThan;
   double            LotsLessOrEqualThan;
   //===============
   //===============
   virtual void      ReSet(void);
   //===============
   //===============
   void              cFilter(void){this.ReSet();}
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   virtual void     ~cFilter(void){}
   //===============
   //===============
   void              FilterByMagicSet(const bool filterbymagic){this.FilterByMagic=filterbymagic;}
   void              MagicSet(const long magic){this.Magic=magic;}
   void              FilterBySymbolSet(const bool filterbysymbol){this.FilterBySymbol=filterbysymbol;}
   void              SymbolSet(const string symbol){this.Symbol=symbol;}
   void              FilterByTypeSet(const bool filterbytype){this.FilterByType=filterbytype;}
   void              FilterByTicketGreaterSet(const bool filterbyticketgreater){this.FilterByTicketGreaterOrEqualThan=filterbyticketgreater;}
   void              TicketGreaterSet(const long ticketgreater){this.TicketGreaterOrEqualThan=ticketgreater;}
   void              FilterByTicketLessSet(const bool filterbyticketless){this.FilterByTicketLessOrEqualThan=filterbyticketless;}
   void              TicketLessSet(const long ticketless){this.TicketLessOrEqualThan=ticketless;}
   void              FilterByExactCommentSet(const bool filterbyexactcomment){this.FilterByExactComment=filterbyexactcomment;}
   void              ExactCommentSet(const string exactcomment){this.ExactComment=exactcomment;}
   void              FilterByCommentPartialSet(const bool filterbycommentpartial){this.FilterByCommentPartial=filterbycommentpartial;}
   void              CommentPartialSet(const string commentpartial){this.CommentPartial=commentpartial;}
   void              FilterByOpenPriceGreaterSet(const bool filterbyopenpricegreater){this.FilterByOpenPriceGreaterOrEqualThan=filterbyopenpricegreater;}
   void              OpenPriceGreaterSet(const double openpricegreater){this.OpenPriceGreaterOrEqualThan=openpricegreater;}
   void              FilterByOpenPriceLessSet(const bool filterbyopenpriceless){this.FilterByOpenPriceLessOrEqualThan=filterbyopenpriceless;}
   void              OpenPriceLessSet(const double openpriceless){this.OpenPriceLessOrEqualThan=openpriceless;}
   void              FilterByOpenTimeGreaterSet(const bool filterbyopentimegreater){this.FilterByOpenTimeGreaterOrEqualThan=filterbyopentimegreater;}
   void              OpenTimeGreaterSet(const datetime opentimegreater){this.OpenTimeGreaterOrEqualThan=opentimegreater;}
   void              FilterByOpenTimeLessSet(const bool filterbyopentimeless){this.FilterByOpenTimeLessOrEqualThan=filterbyopentimeless;}
   void              OpenTimeLessSet(const datetime opentimeless){this.OpenTimeLessOrEqualThan=opentimeless;}
   void              FilterByCloseTimeGreaterSet(const bool filterbyclosetimegreater){this.FilterByCloseTimeGreaterOrEqualThan=filterbyclosetimegreater;}
   void              CloseTimeGreaterSet(const datetime closetimegreater){this.CloseTimeGreaterOrEqualThan=closetimegreater;}
   void              FilterByCloseTimeLessSet(const bool filterbyclosetimeless){this.FilterByCloseTimeLessOrEqualThan=filterbyclosetimeless;}
   void              CloseTimeLessSet(const datetime closetimeless){this.CloseTimeLessOrEqualThan=closetimeless;}
   void              FilterByLotsGreaterSet(const bool filterbylotsgreater){this.FilterByLotsGreaterOrEqualThan=filterbylotsgreater;}
   void              LotsGreaterSet(const double lotsgreater){this.LotsGreaterOrEqualThan=lotsgreater;}
   void              FilterByLotsLessSet(const bool filterbylotsless){this.FilterByLotsLessOrEqualThan=filterbylotsless;}
   void              LotsLessSet(const double lotsless){this.LotsLessOrEqualThan=lotsless;}
   //===============
   //===============
   bool              SelectHistory(void)const;
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cFilter::SelectHistory(void)const
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   bool result=false;
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   datetime fromtime1 = 0;
   datetime fromtime2 = 0;
   datetime tilltime1 = ::TimeCurrent()+60;
   datetime tilltime2 = ::TimeCurrent()+60;
//===============
   if(this.FilterByOpenTimeGreaterOrEqualThan)fromtime1=this.OpenTimeGreaterOrEqualThan-60;
   if(this.FilterByOpenTimeLessOrEqualThan)tilltime1=this.OpenTimeLessOrEqualThan+60;
   if(this.FilterByCloseTimeGreaterOrEqualThan)fromtime2=this.CloseTimeGreaterOrEqualThan-60;
   if(this.FilterByCloseTimeLessOrEqualThan)tilltime2=this.CloseTimeLessOrEqualThan+60;
//===============

//===============
   const datetime fromtime=(datetime)::MathMin(fromtime1,fromtime2);
//===============
   const datetime tilltime=(datetime)::MathMax(tilltime1,tilltime2);
//===============

//===============
   result=::HistorySelect(fromtime,tilltime);
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============
/* DEBUG ASSERTION */ASSERT({},false,true,{})
//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cFilter::ReSet(void)
  {
//===============
   this.FilterByMagic                        = false;
   this.Magic                                = -1;
   this.FilterBySymbol                       = false;
   this.Symbol                               = NULL;
   this.FilterByType                         = false;
   this.FilterByTicketGreaterOrEqualThan     = false;
   this.TicketGreaterOrEqualThan             = -1;
   this.FilterByTicketLessOrEqualThan        = false;
   this.TicketLessOrEqualThan                = -1;
   this.FilterByExactComment                 = false;
   this.ExactComment                         = NULL;
   this.FilterByCommentPartial               = false;
   this.CommentPartial                       = NULL;
   this.FilterByOpenPriceGreaterOrEqualThan  = false;
   this.OpenPriceGreaterOrEqualThan          = 0.0;
   this.FilterByOpenPriceLessOrEqualThan     = false;
   this.OpenPriceLessOrEqualThan             = 0.0;
   this.FilterByOpenTimeGreaterOrEqualThan   = false;
   this.OpenTimeGreaterOrEqualThan           = 0;
   this.FilterByOpenTimeLessOrEqualThan      = false;
   this.OpenTimeLessOrEqualThan              = 0;
   this.FilterByCloseTimeGreaterOrEqualThan  = false;
   this.CloseTimeGreaterOrEqualThan          = 0;
   this.FilterByCloseTimeLessOrEqualThan     = false;
   this.CloseTimeLessOrEqualThan             = 0;
   this.FilterByLotsGreaterOrEqualThan       = false;
   this.LotsGreaterOrEqualThan               = 0.0;
   this.FilterByLotsLessOrEqualThan          = false;
   this.LotsLessOrEqualThan                  = 0.0;
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cTradesFilter final : public cFilter
  {
   //====================
private:
   //====================
   //===============
   //===============
   eTradeStatus      Status;
   eTradeType        Type;
   bool              FilterByProfitGreaterOrEqualThan;
   double            ProfitGreaterOrEqualThan;
   bool              FilterByProfitLessOrEqualThan;
   double            ProfitLessOrEqualThan;
   bool              FilterByClosePriceGreaterOrEqualThan;
   double            ClosePriceGreaterOrEqualThan;
   bool              FilterByClosePriceLessOrEqualThan;
   double            ClosePriceLessOrEqualThan;
   //===============
   //===============
   virtual void      ReSet(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cTradesFilter(void){this.ReSet();}
   virtual void     ~cTradesFilter(void){}
   //===============
   //===============
   void              StatusSet(const eTradeStatus status){this.Status=status;}
   void              TypeSet(const eTradeType type){this.Type=type;}
   void              FilterByProfitGreaterSet(const bool filterbyprofitgreater){this.FilterByProfitGreaterOrEqualThan=filterbyprofitgreater;}
   void              ProfitGreaterSet(const double profitgreater){this.ProfitGreaterOrEqualThan=profitgreater;}
   void              FilterByProfitLessSet(const bool filterbyprofitless){this.FilterByProfitLessOrEqualThan=filterbyprofitless;}
   void              ProfitLessSet(const double profitless){this.ProfitLessOrEqualThan=profitless;}
   void              FilterByClosePriceGreaterSet(const bool filterbyclosepricegreater){this.FilterByClosePriceGreaterOrEqualThan=filterbyclosepricegreater;}
   void              ClosePriceGreaterSet(const double closepricegreater){this.ClosePriceGreaterOrEqualThan=closepricegreater;}
   void              FilterByClosePriceLessSet(const bool filterbyclosepriceless){this.FilterByClosePriceLessOrEqualThan=filterbyclosepriceless;}
   void              ClosePriceLessSet(const double closepriceless){this.ClosePriceLessOrEqualThan=closepriceless;}
   //===============
   //===============
   eTradeStatus      StatusGet(void)const{return(this.Status);}
   //===============
   //===============
   bool              Passed(const cTradeInfo &trade)const;
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cTradesFilter::Passed(const cTradeInfo &trade)const
  {
//===============
   if(trade.TicketGet()<=0)return(false);
//===============

//===============
   if(this.FilterByMagic && trade.MagicGet()!=this.Magic)return(false);
//===============

//===============
   if(this.FilterBySymbol && trade.SymbolGet()!=this.Symbol)return(false);
//===============

//===============
   if(this.Status!=TRADESTATUS_ALL && trade.StatusGet()!=this.Status)return(false);
//===============

//===============
   if(this.FilterByType && trade.TypeGet()!=this.Type)return(false);
//===============

//===============
   if(this.FilterByTicketGreaterOrEqualThan && trade.TicketGet()<this.TicketGreaterOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByTicketLessOrEqualThan && trade.TicketGet()>this.TicketLessOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByExactComment && trade.CommentGet()!=this.ExactComment)return(false);
//===============

//===============
   if(this.FilterByCommentPartial && ::StringFind(trade.CommentGet(),this.CommentPartial,0)<0)return(false);
//===============

//===============
   if(this.FilterByOpenPriceGreaterOrEqualThan && trade.OpenPriceGet()<this.OpenPriceGreaterOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByOpenPriceLessOrEqualThan && trade.OpenPriceGet()>this.OpenPriceLessOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByClosePriceGreaterOrEqualThan && trade.ClosePriceGet()<this.ClosePriceGreaterOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByClosePriceLessOrEqualThan && trade.ClosePriceGet()>this.ClosePriceLessOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByLotsGreaterOrEqualThan && trade.LotsGet()<this.LotsGreaterOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByLotsLessOrEqualThan && trade.LotsGet()>this.LotsLessOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByOpenTimeGreaterOrEqualThan && trade.OpenTimeGet()<this.OpenTimeGreaterOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByOpenTimeLessOrEqualThan && trade.OpenTimeGet()>this.OpenTimeLessOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByCloseTimeGreaterOrEqualThan && trade.CloseTimeGet()<this.CloseTimeGreaterOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByCloseTimeLessOrEqualThan && trade.CloseTimeGet()>this.CloseTimeLessOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByProfitGreaterOrEqualThan && trade.ProfitMoneyGet()<this.ProfitGreaterOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByProfitLessOrEqualThan && trade.ProfitMoneyGet()>this.ProfitLessOrEqualThan)return(false);
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cTradesFilter::ReSet(void)override final
  {
//===============
   cFilter::ReSet();
//===============

//===============
   this.Status                               = WRONG_VALUE;
   this.Type                                 = WRONG_VALUE;
   this.FilterByProfitGreaterOrEqualThan     = false;
   this.ProfitGreaterOrEqualThan             = 0.0;
   this.FilterByProfitLessOrEqualThan        = false;
   this.ProfitLessOrEqualThan                = 0.0;
   this.FilterByClosePriceGreaterOrEqualThan = false;
   this.ClosePriceGreaterOrEqualThan         = 0.0;
   this.FilterByClosePriceLessOrEqualThan    = false;
   this.ClosePriceLessOrEqualThan            = 0.0;
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cPendingOrdersFilter final : public cFilter
  {
   //====================
private:
   //====================
   //===============
   //===============
   ePendingOrderStatus Status;
   ePendingOrderType Type;
   //===============
   //===============
   virtual void      ReSet(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cPendingOrdersFilter(void){this.ReSet();}
   virtual void     ~cPendingOrdersFilter(void){}
   //===============
   //===============
   void              StatusSet(const ePendingOrderStatus status){this.Status=status;}
   void              TypeSet(const ePendingOrderType type){this.Type=type;}
   //===============
   //===============
   ePendingOrderStatus StatusGet(void)const{return(this.Status);}
   //===============
   //===============
   bool              Passed(const cPendingOrderInfo &order)const;
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cPendingOrdersFilter::Passed(const cPendingOrderInfo &order)const
  {
//===============
   if(order.TicketGet()<=0)return(false);
//===============

//===============
   if(this.FilterByMagic && order.MagicGet()!=this.Magic)return(false);
//===============

//===============
   if(this.FilterBySymbol && order.SymbolGet()!=this.Symbol)return(false);
//===============

//===============
   if(this.Status!=ORDERSTATUS_ALL && order.StatusGet()!=this.Status)return(false);
//===============

//===============
   if(this.FilterByType && order.TypeGet()!=this.Type)return(false);
//===============

//===============
   if(this.FilterByTicketGreaterOrEqualThan && order.TicketGet()<this.TicketGreaterOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByTicketLessOrEqualThan && order.TicketGet()>this.TicketLessOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByExactComment && order.CommentGet()!=this.ExactComment)return(false);
//===============

//===============
   if(this.FilterByCommentPartial && ::StringFind(order.CommentGet(),this.CommentPartial,0)<0)return(false);
//===============

//===============
   if(this.FilterByOpenPriceGreaterOrEqualThan && order.OpenPriceGet()<this.OpenPriceGreaterOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByOpenPriceLessOrEqualThan && order.OpenPriceGet()>this.OpenPriceLessOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByOpenTimeGreaterOrEqualThan && order.OpenTimeGet()<this.OpenTimeGreaterOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByOpenTimeLessOrEqualThan && order.OpenTimeGet()>this.OpenTimeLessOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByCloseTimeGreaterOrEqualThan && (order.CloseTimeGet()==0 || order.CloseTimeGet()<this.CloseTimeGreaterOrEqualThan))return(false);
//===============

//===============
   if(this.FilterByCloseTimeLessOrEqualThan && (order.CloseTimeGet()==0 || order.CloseTimeGet()>this.CloseTimeLessOrEqualThan))return(false);
//===============

//===============
   if(this.FilterByLotsGreaterOrEqualThan && order.LotsGet()<this.LotsGreaterOrEqualThan)return(false);
//===============

//===============
   if(this.FilterByLotsLessOrEqualThan && order.LotsGet()>this.LotsLessOrEqualThan)return(false);
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cPendingOrdersFilter::ReSet(void)override final
  {
//===============
   cFilter::ReSet();
//===============

//===============
   this.Status                               = WRONG_VALUE;
   this.Type                                 = WRONG_VALUE;
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cTrade final
  {
   //====================
private:
   //====================
   //===============
   //===============
   void              cTrade(void){}
   virtual void     ~cTrade(void){}
   //===============
   //===============
   static void       AddCurrentTrades(const cTradesFilter &filter,long &tickets[]);
   static void       AddCurrentOrders(const cPendingOrdersFilter &filter,long &tickets[]);
   static void       AddHistoryTrades(const cTradesFilter &filter,long &tickets[]);
   static void       AddHistoryOrders(const cPendingOrdersFilter &filter,long &tickets[]);
   //===============
   //===============
   static double     ExistingVolume(const string symbol,const eTradeType type);
   //===============
   //===============
   static bool       CheckMaxOrders(void);
   static bool       CheckMaxVolume(const string symbol,const eTradeType type,const double volume);
   static bool       CheckPlaced(const string symbol,const eTradeType type,const long magic);
   static bool       CheckMargin(const string symbol,const double volume,const eTradeType type,const double price);
   static bool       CheckOrderPrice(const string symbol,const ePendingOrderType type,const double price);
   static bool       CheckStops(const string symbol,const eTradeType type,const bool istrade,const double entrylevel,
                                const double stoploss,const double takeprofit);
   //===============
   //===============
   static bool       CheckFreezed(const string symbol,const eTradeType type,const double stoploss,const double takeprofit);
   static bool       CheckFreezed(const string symbol,const ePendingOrderType type,const double entryprice);
   //===============
   //===============
   static int        GetMatch(const cTradeInfo &trades[],const int forindex,const long &matched[]);
   static void       TradesCloseBy(const long &tickets[],const bool slippageenabled,const long slippage);
   //===============
   //===============
   static void       CloseBy(const long ticket1,const long ticket2);
   //===============
   //===============
   static void       BreakEven(const long ticket,const long belevel,const long beprofit);
   static void       TrailingStop(const long ticket,const long tslstart,const long tsldistance,const bool tsllevelenabled,const double tsllevel);
   //===============
   //===============
   static void       CalculateSLandTP(const string symbol,const eTradeType type,const double entrylevel,const double lots,
                                      const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                                      const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                                      const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice,
                                      double &sllevel,double &tplevel);
   //===============
   //===============
   static bool       OpeningAllowed(const string symbol,const eTradeType type);
   static bool       ClosingAllowed(const string symbol);
   //===============
   //===============
   static void       NettPosition(const cTradeInfo &trades[],cTradeInfo &tradesnetted[]);
   static void       GetSymbols(const cTradeInfo &trades[],string &symbols[]);
   static void       GetSymbolTrades(const cTradeInfo &trades[],const string symbol,cTradeInfo &symboltrades[]);
   static bool       GetDealAsTradeFromSelectedHistory(const long ticket,cTradeInfo &trade);
   //===============
   //===============
   static bool       CanTrade(void);
   //===============
   //===============
#ifdef __MQL5__
   static ENUM_ORDER_TYPE_FILLING GetFilling(const string symbol);
   static ENUM_ORDER_TYPE_TIME GetExpirationType(const string symbol);
#endif
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   static bool       IsNettingAccount(void);
   //===============
   //===============
   static void       GetPositionAsDeals(const long ticket,cTradeInfo &trades[],const bool searchoriginalticket);
   static void       GetDealAsTrade(const long ticket,cTradeInfo &trade);
   //===============
   //===============
   static void       GetOriginalTicket(long &originalticket,const string currentcomment);
   //===============
   //===============
   static void       NettTrades(const cTradeInfo &trades[],cTradeInfo &tradesnetted[]);
   //===============
   //===============
   static long       ProfitPointsGet(const eTradeType type,const double openprice,const double closeprice,const string symbol);
   static double     CommissionGet(const long positionID);
   //===============
   //===============
   static double     PointPrice(const string symbol);
   //===============
   //===============
   static void       GetFilteredTradesTickets(const cTradesFilter &filter,long &tickets[]);
   static void       GetFilteredPendingOrdersTickets(const cPendingOrdersFilter &filter,long &tickets[]);
   //===============
   //===============
   static bool       TradeTypeAllowed(const eAllowedTrades allowed,const eTradeType type);
   //===============
   //===============
   static double     CheckLot(const string symbol,const double lots);
   static double     GetLot(const string symbol,const long slpoints,const double moneyrisk);
   static double     CalculateLot(const string symbol,const eTradeType type,const double requiredbelevel,const double dealprice,
                                  const double lotsnow,const double belevelnow);
   //===============
   //===============
   static long       OpenTrade(const string symbol,const eTradeType type,const double lots,const long magic,const string comment,
                               const long slippage,const bool checkplaced,uint &retcode,eError &myretcode);
   static long       OpenTrade(const string symbol,const eTradeType type,const double lots,const long magic,const string comment,
                               const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                               const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                               const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice,
                               const bool slippageenabled,const long slippage,const bool checkplaced,uint &retcode,eError &myretcode);
   //===============
   //===============
   static long       PlacePendingOrder(const string symbol,const double price,const ePendingOrderType type,const double lots,
                                       const long magic,const string comment,const datetime expiration,uint &retcode,eError &myretcode);
   static long       PlacePendingOrder(const string symbol,const double price,const ePendingOrderType type,const double lots,
                                       const long magic,const string comment,
                                       const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                                       const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                                       const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice,
                                       const bool expirationenabled,const datetime expiration,uint &retcode,eError &myretcode);
   //===============
   //===============
   static bool       ModifyTrade(const long ticket,const double newsl,const double newtp,uint &retcode,eError &myretcode);
   static void       ModifyTrade(const long ticket,const bool tightenstopsonly,
                                 const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                                 const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                                 const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice);
   static void       ModifyTrades(const long &tickets[],const bool tightenstopsonly,
                                  const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                                  const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                                  const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice);
   //===============
   //===============
   static bool       ModifyPendingOrder(const long ticket,const double newprice,const double newsl,const double newtp,
                                        const datetime newexpiration,uint &retcode,eError &myretcode);
   static void       ModifyPendingOrder(const long ticket,const bool priceenabled,const double price,const bool tightenstopsonly,
                                        const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                                        const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                                        const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice,
                                        const bool expirationenabled,const datetime expiration);
   static void       ModifyPendingOrders(const long &tickets[],const bool priceenabled,const double price,const bool tightenstopsonly,
                                         const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                                         const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                                         const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice,
                                         const bool expirationenabled,const datetime expiration);
   //===============
   //===============
   static bool       CloseTrade(const long ticket,const bool slippageenabled,const long slippage,const double lots,uint &retcode,eError &myretcode);
   static void       CloseTrades(const long &tickets[],const bool closeby,const bool slippageenabled,const long slippage);
   //===============
   //===============
   static bool       DeletePendingOrder(const long ticket,uint &retcode,eError &myretcode);
   static void       DeletePendingOrders(const long &tickets[]);
   //===============
   //===============
   static void       BreakEven(const long &tickets[],const long belevel,const long beprofit);
   static void       TrailingStop(const long &tickets[],const long tslstart,const long tsldistance,const bool tsllevelenabled,const double tsllevel);
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::CheckMaxOrders(void)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   static const int maxallowed = (int)::AccountInfoInteger(ACCOUNT_LIMIT_ORDERS);
   const int existing          = #ifdef __MQL5__ ::PositionsTotal() + ::OrdersTotal() #endif #ifdef __MQL4__ ::OrdersTotal() #endif;
//===============

//===============
   if(existing>=maxallowed && maxallowed!=0)return(false);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static double cTrade::ExistingVolume(const string symbol,const eTradeType type)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   double result=0;
//===============

//===============
#ifdef __MQL5__
//===============
   const int tradesnumber=::PositionsTotal();
//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============
   const int tradesnumber=::OrdersTotal();
//===============
#endif 
//===============

//===============
   for(int i=0;i<tradesnumber && !::IsStopped();i++)
     {
      //===============
#ifdef __MQL5__
      //===============
      const long ticket=(long)::PositionGetTicket(i);
      //===============
#endif 
      //===============

      //===============
#ifdef __MQL4__
      //===============
      if(!::OrderSelect(i,SELECT_BY_POS,MODE_TRADES))continue;
      //===============
      const int ordertype=::OrderType();
      //===============
      if(ordertype!=OP_BUY && ordertype!=OP_SELL)continue;
      //===============
      const long ticket=(long)::OrderTicket();
      //===============
#endif 
      //===============

      //===============
      cTradeInfo trade;
      //===============

      //===============
      trade.Update(ticket,false,false,false);
      //===============

      //===============
      if(trade.SymbolGet()!=symbol || trade.TypeGet()!=type)continue;
      //===============

      //===============
      result+=trade.LotsGet();
      //===============
     }
//===============

//===============
   const int ordersnumber=::OrdersTotal();
//===============

//===============
   for(int i=0;i<ordersnumber && !::IsStopped();i++)
     {
      //===============
#ifdef __MQL5__
      //===============
      const long ticket=(long)::OrderGetTicket(i);
      //===============
      const ENUM_ORDER_TYPE ordertype=(ENUM_ORDER_TYPE)::OrderGetInteger(ORDER_TYPE);
      //===============
      if(ordertype!=ORDER_TYPE_BUY_STOP && ordertype!=ORDER_TYPE_BUY_LIMIT &&
         ordertype!=ORDER_TYPE_SELL_STOP && ordertype!=ORDER_TYPE_SELL_LIMIT)continue;
      //===============
#endif 
      //===============

      //===============
#ifdef __MQL4__
      //===============
      if(!::OrderSelect(i,SELECT_BY_POS,MODE_TRADES))continue;
      //===============
      const int ordertype=::OrderType();
      //===============
      if(ordertype!=OP_BUYSTOP && ordertype!=OP_BUYLIMIT && ordertype!=OP_SELLSTOP && ordertype!=OP_SELLLIMIT)continue;
      //===============
      const long ticket=(long)::OrderTicket();
      //===============
#endif 
      //===============

      //===============
      cPendingOrderInfo order;
      //===============

      //===============
      order.Update(ticket);
      //===============

      //===============
      const eTradeType side=(order.TypeGet()==PENDINGORDERTYPE_BUYLIMIT || order.TypeGet()==PENDINGORDERTYPE_BUYSTOP)?TRADETYPE_BUY:TRADETYPE_SELL;
      //===============

      //===============
      if(order.SymbolGet()!=symbol || side!=type)continue;
      //===============

      //===============
      result+=order.LotsGet();
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::CheckMaxVolume(const string symbol,const eTradeType type,const double volume)
  {
//===============
#ifdef __MQL4__ return(true); #endif
//===============

//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const double maxallowedvolume=::SymbolInfoDouble(symbol,SYMBOL_VOLUME_LIMIT);
//===============

//===============
   if(maxallowedvolume<=0)return(true);
//===============

//===============
   const double existingvolume=cTrade::ExistingVolume(symbol,type);
//===============

//===============
   if(volume+existingvolume>maxallowedvolume)return(false);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::CheckPlaced(const string symbol,const eTradeType type,const long magic)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   static const bool istesting=(bool)::MQLInfoInteger(MQL_TESTER);
//===============

//===============
   if(istesting)return(true);
//===============

//===============
   const int ordersnumber=::OrdersTotal();
//===============

//===============
   for(int i=0;i<ordersnumber && !::IsStopped();i++)
     {
      //===============
      const long ticket=(long)::OrderGetTicket(i);
      //===============

      //===============
      const ENUM_ORDER_TYPE ordertype=(ENUM_ORDER_TYPE)::OrderGetInteger(ORDER_TYPE);
      //===============

      //===============
      const long ordermagic=::OrderGetInteger(ORDER_MAGIC);
      //===============

      //===============
      const string ordersymbol=::OrderGetString(ORDER_SYMBOL);
      //===============

      //===============
      if(ordertype!=ORDER_TYPE_BUY && ordertype!=ORDER_TYPE_SELL)continue;
      //===============

      //===============
      if(ordermagic!=magic)continue;
      //===============

      //===============
      if(ordersymbol!=symbol)continue;
      //===============

      //===============
      if(::OrderGetInteger(ORDER_POSITION_ID)>0)continue;
      //===============

      //===============
      if(type==TRADETYPE_BUY && ordertype==ORDER_TYPE_BUY)return(false);
      //===============

      //===============
      if(type==TRADETYPE_SELL && ordertype==ORDER_TYPE_SELL)return(false);
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::CheckMargin(const string symbol,const double volume,const eTradeType type,const double price)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   if(::SymbolInfoInteger(symbol,SYMBOL_TRADE_CALC_MODE)!=SYMBOL_CALC_MODE_FOREX)return(true);
//===============

//===============
   const ENUM_ORDER_TYPE ordertype=(type==TRADETYPE_BUY?ORDER_TYPE_BUY:ORDER_TYPE_SELL);
//===============

//===============
   double init  = 0.0;
   double main  = 0.0;
   double order = 0.0;
//===============

//===============
   const double tickvalue = ::SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
   const double ticksize  = ::SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
   const int    leverage  = (int)::AccountInfoInteger(ACCOUNT_LEVERAGE);
//===============

//===============
   const bool getrate=::SymbolInfoMarginRate(symbol,ordertype,init,main);
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},getrate,false,{})
//===============

//===============
   if(!getrate || ticksize*leverage==0)
     {
      //===============
      const bool calculate=::OrderCalcMargin(ordertype,symbol,volume,price,order);
      //===============
/* DEBUG ASSERTION */ASSERT({},calculate,false,{})
      //===============
     }
//===============

//===============
   const double marginrequired=(getrate && ticksize*leverage!=0)?(init*price*volume*tickvalue/(ticksize*leverage)):order;
//===============

//===============
   const bool result=(marginrequired<=0 || marginrequired<::AccountInfoDouble(ACCOUNT_MARGIN_FREE));
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============

//===============
   const double marginrequired=::MarketInfo(symbol,MODE_MARGINREQUIRED)*volume;
//===============

//===============
   const bool result=(marginrequired<=0 || marginrequired<::AccountInfoDouble(ACCOUNT_MARGIN_FREE));
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::CheckOrderPrice(const string symbol,const ePendingOrderType type,const double price)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(price<=0)return(false);
//===============

//===============
   MqlTick lasttick;
//===============
   ::ZeroMemory(lasttick);
//===============
   const bool gettick=::SymbolInfoTick(symbol,lasttick);
//===============
/* DEBUG ASSERTION */ASSERT({},gettick,true,{})
//===============
   if(!gettick)return(false);
//===============

//===============
   const int    stopslevel  = (int)::SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
   const double point       = ::SymbolInfoDouble(symbol,SYMBOL_POINT);
   const double mindistance = (stopslevel>0?(stopslevel*point):(2.0*(lasttick.ask-lasttick.bid)));
//===============

//===============
   switch(type)
     {
      //===============
      case  PENDINGORDERTYPE_BUYSTOP        :   if((price-lasttick.ask)<=mindistance)return(false);     break;
      case  PENDINGORDERTYPE_BUYLIMIT       :   if((lasttick.ask-price)<=mindistance)return(false);     break;
      case  PENDINGORDERTYPE_SELLSTOP       :   if((lasttick.bid-price)<=mindistance)return(false);     break;
      case  PENDINGORDERTYPE_SELLLIMIT      :   if((price-lasttick.bid)<=mindistance)return(false);     break;
      //===============
      default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::CheckFreezed(const string symbol,const eTradeType type,const double stoploss,const double takeprofit)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(takeprofit==0 && stoploss==0)return(false);
//===============

//===============
   MqlTick lasttick;
//===============
   ::ZeroMemory(lasttick);
//===============
   const bool gettick=::SymbolInfoTick(symbol,lasttick);
//===============
/* DEBUG ASSERTION */ASSERT({},gettick,true,{})
//===============
   if(!gettick)return(true);
//===============

//===============
   const int    freezelevel  = (int)::SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   const double point        = ::SymbolInfoDouble(symbol,SYMBOL_POINT);
   const double mindistance  = freezelevel*point;
//===============

//===============
   if(freezelevel==0)return(false);
//===============

//===============
   if(takeprofit>0)
     {
      //===============
      switch(type)
        {
         //===============
         case TRADETYPE_BUY        :      if(takeprofit-lasttick.bid<=mindistance)return(true); break;
         case TRADETYPE_SELL       :      if(lasttick.ask-takeprofit<=mindistance)return(true); break;
         //===============
         default                 :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
         //=============== 
        }
      //===============
     }
//===============

//===============
   if(stoploss>0)
     {
      //===============
      switch(type)
        {
         //===============
         case TRADETYPE_BUY        :      if(lasttick.bid-stoploss<=mindistance)return(true); break;
         case TRADETYPE_SELL       :      if(stoploss-lasttick.ask<=mindistance)return(true); break;
         //===============
         default                 :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
         //=============== 
        }
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(false);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::CheckFreezed(const string symbol,const ePendingOrderType type,const double entryprice)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   MqlTick lasttick;
//===============
   ::ZeroMemory(lasttick);
//===============
   const bool gettick=::SymbolInfoTick(symbol,lasttick);
//===============
/* DEBUG ASSERTION */ASSERT({},gettick,true,{})
//===============
   if(!gettick)return(true);
//===============

//===============
   const int    freezelevel  = (int)::SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   const double point        = ::SymbolInfoDouble(symbol,SYMBOL_POINT);
   const double mindistance  = freezelevel*point;
//===============

//===============
   if(freezelevel==0)return(false);
//===============

//===============
   switch(type)
     {
      //===============
      case PENDINGORDERTYPE_BUYLIMIT        :      if(lasttick.ask-entryprice<=mindistance)return(true); break;
      case PENDINGORDERTYPE_BUYSTOP         :      if(entryprice-lasttick.ask<=mindistance)return(true); break;
      case PENDINGORDERTYPE_SELLLIMIT       :      if(entryprice-lasttick.bid<=mindistance)return(true); break;
      case PENDINGORDERTYPE_SELLSTOP        :      if(lasttick.bid-entryprice<=mindistance)return(true); break;
      //===============
      default                 :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //=============== 
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(false);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::CheckStops(const string symbol,const eTradeType type,const bool istrade,const double entrylevel,
                               const double stoploss,const double takeprofit)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(stoploss==0 && takeprofit==0)return(true);
//===============

//===============
   if(stoploss<0 || takeprofit<0)return(false);
//===============

//===============
   MqlTick lasttick;
//===============
   ::ZeroMemory(lasttick);
//===============
   const bool gettick=::SymbolInfoTick(symbol,lasttick);
//===============
/* DEBUG ASSERTION */ASSERT({},gettick,true,{})
//===============
   if(!gettick)return(false);
//===============

//===============
   const int    stopslevel  = (int)::SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
   const double point       = ::SymbolInfoDouble(symbol,SYMBOL_POINT);
   const double mindistance = (stopslevel>0?(stopslevel*point):(2.0*(lasttick.ask-lasttick.bid)));
//===============

//===============
   if(type==TRADETYPE_BUY)
     {
      //===============
      if(!istrade && stoploss>0 && (entrylevel-stoploss)<=mindistance)return(false);
      if(istrade && stoploss>0 && (lasttick.bid-stoploss)<=mindistance)return(false);
      //===============

      //===============
      if(!istrade && takeprofit>0 && (takeprofit-entrylevel)<=mindistance)return(false);
      if(istrade && takeprofit>0 && (takeprofit-lasttick.bid)<=mindistance)return(false);
      //===============
     }
//===============

//===============
   if(type==TRADETYPE_SELL)
     {
      //===============
      if(!istrade && stoploss>0 && (stoploss-entrylevel)<=mindistance)return(false);
      if(istrade && stoploss>0 && (stoploss-lasttick.ask)<=mindistance)return(false);
      //===============

      //===============
      if(!istrade && takeprofit>0 && (entrylevel-takeprofit)<=mindistance)return(false);
      if(istrade && takeprofit>0 && (lasttick.ask-takeprofit)<=mindistance)return(false);
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static int cTrade::GetMatch(const cTradeInfo &trades[],const int forindex,const long &matched[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(trades[forindex].TicketGet()<=0 || trades[forindex].StatusGet()!=TRADESTATUS_CURRENT)return(-1);
//===============

//===============
#ifdef __MQL5__
//===============
   const int ordermode=(int)::SymbolInfoInteger(trades[forindex].SymbolGet(),SYMBOL_ORDER_MODE);
//===============
   const bool orderallowed=((SYMBOL_ORDER_CLOSEBY&ordermode)==SYMBOL_ORDER_CLOSEBY);
//===============
/* DEBUG ASSERTION */ASSERT({},orderallowed,true,{})
//===============
   if(!orderallowed)return(-1);
//===============
#endif 
//===============

//===============
   int result=-1;
//===============

//===============
   const int size=cArray::Size(trades);
//===============

//===============
   for(int i=forindex+1;i<size;i++)
     {
      //===============
      if(trades[i].TicketGet()<=0 || trades[i].StatusGet()!=TRADESTATUS_CURRENT)continue;
      //===============

      //===============
      if(cArray::ValueExist(matched,trades[i].TicketGet()))continue;
      //===============

      //===============
      if(trades[forindex].SymbolGet()!=trades[i].SymbolGet())continue;
      //===============

      //===============
      if(trades[forindex].TypeGet()==trades[i].TypeGet())continue;
      //===============

      //===============
      if(trades[forindex].LotsGet()!=trades[i].LotsGet())continue;
      //===============

      //===============
      result=i;
      //===============

      //===============
      break;
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::TradesCloseBy(const long &tickets[],const bool slippageenabled,const long slippage)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const int size=cArray::Size(tickets);
//===============

//===============
   if(size<=0)return;
//===============

//===============
   cTradeInfo trades[];
//===============
   cArray::Resize(trades,size,0);
//===============

//===============
   for(int i=0;i<size;i++)
     {
      //===============
      trades[i].Update(tickets[i],false,false,false);
      //===============
     }
//===============

//===============
   long tickets1[];
   long tickets2[];
   long nomatch[];
//===============
   cArray::Free(tickets1);
   cArray::Free(tickets2);
   cArray::Free(nomatch);
//===============

//===============
   for(int i=0;i<size;i++)
     {
      //===============
      if(cArray::ValueExist(tickets2,tickets[i]))continue;
      //===============

      //===============
      const int matchedindex=cTrade::GetMatch(trades,i,tickets2);
      //===============

      //===============
      if(matchedindex>0)
        {
         //===============
         cArray::AddLast(tickets1,tickets[i],size);
         //===============

         //===============
         cArray::AddLast(tickets2,tickets[matchedindex],size);
         //===============
        }
      else
        {
         //===============
         cArray::AddLast(nomatch,tickets[i],size);
         //===============
        }
      //===============
     }
//===============

//===============
   const int size1       = cArray::Size(tickets1);
   const int size2       = cArray::Size(tickets2);
   const int nomatchsize = cArray::Size(nomatch);
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},size1==size2,false,{})
//===============
/* DEBUG ASSERTION */ASSERT({},size1+size2+nomatchsize==size,false,{})
//===============

//===============
   for(int i=0;i<size1;i++)
     {
      //===============
      cTrade::CloseBy(tickets1[i],tickets2[i]);
      //===============
     }
//===============

//===============
   cTrade::CloseTrades(nomatch,false,slippageenabled,slippage);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::IsNettingAccount(void)
  {
//===============
#ifdef __MQL4__
//===============
   return(false);
//===============
#endif
//===============

//===============
#ifdef __MQL5__
//===============
   return((ENUM_ACCOUNT_MARGIN_MODE)::AccountInfoInteger(ACCOUNT_MARGIN_MODE)!=ACCOUNT_MARGIN_MODE_RETAIL_HEDGING);
//===============
#endif
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::GetDealAsTrade(const long ticket,cTradeInfo &trade)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   trade.ReSet();
//===============

//===============
   if(ticket<=0)return;
//===============

//===============
// Hedging Accounts
//===============
   if(!cTrade::IsNettingAccount())return;
//===============

//===============
// Netting Accounts
//===============     

//===============
#ifdef __MQL5__
//===============

//===============
   if(!::HistorySelect(0,::TimeCurrent()+60))return;
//===============

//===============
   cTrade::GetDealAsTradeFromSelectedHistory(ticket,trade);
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::GetOriginalTicket(long &originalticket,const string currentcomment)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
#ifdef __MQL4__
//===============

//===============
   if(currentcomment=="" || currentcomment==NULL)return;
//===============

//===============
   const int searchfromresult = ::StringFind(currentcomment,SEARCHFROM,0);
   const int searchtoresult   = ::StringFind(currentcomment,SEARCHTO,0);
//===============

//===============
   if(searchfromresult>=0)
     {
      //===============
      const int ticket=(int)::StringToInteger(::StringSubstr(currentcomment,searchfromresult+::StringLen(SEARCHFROM)));
      //===============

      //===============
      const int tradesnumber=::OrdersHistoryTotal();
      //===============

      //===============
      // Check for closeby scenario
      //===============
      for(int i=0;i<tradesnumber && !::IsStopped();i++)
        {
         //===============
         if(!::OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))continue;
         //===============

         //===============
         const int ordertype=::OrderType();
         //===============
         if(ordertype!=OP_BUY && ordertype!=OP_SELL)continue;
         //===============

         //===============
         const string comment=::OrderComment();
         //===============

         //===============
         if(comment=="" || comment==NULL)continue;
         //===============

         //===============
         const int found=::StringFind(comment,SEARCHBY+(string)ticket,0);
         //===============

         //===============
         if(found>=0)
           {
            //===============
            originalticket=::OrderTicket();
            //===============

            //===============
            return;
            //===============
           }
         //===============
        }
      //===============

      //===============
      if(!::OrderSelect(ticket,SELECT_BY_TICKET,MODE_HISTORY))return;
      //===============

      //===============
      originalticket=ticket;
      //===============

      //===============
      cTrade::GetOriginalTicket(originalticket,::OrderComment());
      //===============

      //===============
      return;
      //===============
     }
//===============

//===============
   if(searchtoresult>=0)
     {
      //===============
      const int tradesnumber=::OrdersHistoryTotal();
      //===============

      //===============
      for(int i=0;i<tradesnumber && !::IsStopped();i++)
        {
         //===============
         if(!::OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))continue;
         //===============

         //===============
         const int ordertype=::OrderType();
         //===============
         if(ordertype!=OP_BUY && ordertype!=OP_SELL)continue;
         //===============

         //===============
         const string comment=::OrderComment();
         //===============

         //===============
         if(comment=="" || comment==NULL)continue;
         //===============

         //===============
         const int found=::StringFind(comment,SEARCHTO+(string)originalticket,0);
         //===============

         //===============
         if(found>=0)
           {
            //===============
            originalticket=::OrderTicket();
            //===============

            //===============
            cTrade::GetOriginalTicket(originalticket,comment);
            //===============

            //===============
            return;
            //===============
           }
         //===============
        }
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::GetDealAsTradeFromSelectedHistory(const long ticket,cTradeInfo &trade)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   const int dealstotal=::HistoryDealsTotal();
//===============

//===============  
   for(int i=dealstotal-1;i>=0 && !::IsStopped();i--)
     {
      //===============
      const ulong dealticket = ::HistoryDealGetTicket(i);
      const long  dealorder  = ::HistoryDealGetInteger(dealticket,DEAL_ORDER);
      //===============

      //===============
      if(dealorder!=ticket)continue;
      //===============

      //===============
      const long identifier     =::HistoryDealGetInteger(dealticket,DEAL_POSITION_ID);
      const datetime opentime   = (datetime)::HistoryDealGetInteger(dealticket,DEAL_TIME);
      const long     magic      = ::HistoryDealGetInteger(dealticket,DEAL_MAGIC);
      const string   comment    = ::HistoryDealGetString(dealticket,DEAL_COMMENT);
      const string   symbol     = ::HistoryDealGetString(dealticket,DEAL_SYMBOL);
      const double   lots       = ::HistoryDealGetDouble(dealticket,DEAL_VOLUME);
      const double   openprice  = ::HistoryDealGetDouble(dealticket,DEAL_PRICE);
      const ENUM_DEAL_TYPE type = (ENUM_DEAL_TYPE)::HistoryDealGetInteger(dealticket,DEAL_TYPE);
      //===============

      //===============
      trade.Update(dealorder,identifier,type==DEAL_TYPE_BUY?TRADETYPE_BUY:TRADETYPE_SELL,TRADESTATUS_CURRENT,symbol,
                   magic,comment,lots,openprice,0,0,opentime);
      //===============

      //===============
      return(true);
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(false);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::GetPositionAsDeals(const long ticket,cTradeInfo &trades[],const bool searchoriginalticket)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   cArray::Free(trades);
//===============

//===============
// Hedging Accounts
//===============
   if(!cTrade::IsNettingAccount())
     {
      //===============
      cArray::Resize(trades,1,0);
      //===============

      //===============
      trades[0].Update(ticket,false,false,searchoriginalticket);
      //===============
     }
//===============
// Netting Accounts
//===============     
   else
     {
      //===============
#ifdef __MQL5__
      //===============

      //===============
      const bool select=::PositionSelectByTicket(ticket);
      //===============

      //===============
      if(!select)return;
      //===============

      //===============
      const long identifier   = ::PositionGetInteger(POSITION_IDENTIFIER);
      const double takeprofit = ::PositionGetDouble(POSITION_TP);
      const double stoploss   = ::PositionGetDouble(POSITION_SL);
      const string symbol     = ::PositionGetString(POSITION_SYMBOL);
      //===============

      //===============
      if(::HistorySelectByPosition(identifier))
        {
         //===============
         const int deals=::HistoryDealsTotal();
         //===============

         //===============
         cArray::Resize(trades,deals,0);
         //=============== 

         //===============  
         for(int i=0;i<deals && !::IsStopped();i++)
           {
            //===============
            const ulong dealticket        = ::HistoryDealGetTicket(i);
            const ENUM_DEAL_REASON reason = (ENUM_DEAL_REASON)::HistoryDealGetInteger(dealticket,DEAL_REASON);
            //===============

            //===============
            if(reason==DEAL_REASON_ROLLOVER)continue;
            //===============

            //===============
            const datetime opentime       = (datetime)::HistoryDealGetInteger(dealticket,DEAL_TIME);
            const long     magic          = ::HistoryDealGetInteger(dealticket,DEAL_MAGIC);
            const long     order          = ::HistoryDealGetInteger(dealticket,DEAL_ORDER);
            const string   comment        = ::HistoryDealGetString(dealticket,DEAL_COMMENT);
            const double   lots           = ::HistoryDealGetDouble(dealticket,DEAL_VOLUME);
            const double   openprice      = ::HistoryDealGetDouble(dealticket,DEAL_PRICE);
            const ENUM_DEAL_TYPE type     = (ENUM_DEAL_TYPE)::HistoryDealGetInteger(dealticket,DEAL_TYPE);
            //===============

            //===============
            trades[i].Update(order,identifier,type==DEAL_TYPE_BUY?TRADETYPE_BUY:TRADETYPE_SELL,TRADESTATUS_CURRENT,symbol,
                             magic,comment,lots,openprice,stoploss,takeprofit,opentime);
            //===============
           }
         //===============
        }
      //===============

      //===============
#endif 
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::GetSymbols(const cTradeInfo &trades[],string &symbols[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   cArray::Free(symbols);
//===============

//===============
   const int size=cArray::Size(trades);
//===============

//===============
   for(int i=0;i<size;i++)
     {
      //===============
      const string symbol=trades[i].SymbolGet();
      //===============

      //===============
      if(cArray::ValueExist(symbols,symbol))continue;
      //===============

      //===============
      cArray::AddLast(symbols,symbol,size);
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::GetSymbolTrades(const cTradeInfo &trades[],const string symbol,cTradeInfo &symboltrades[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   cArray::Free(symboltrades);
//===============

//===============
   const int size=cArray::Size(trades);
//===============

//===============
   for(int i=0;i<size;i++)
     {
      //===============
      if(trades[i].SymbolGet()!=symbol)continue;
      //===============

      //===============
      const int newsize=cArray::Size(symboltrades)+1;
      //===============

      //===============
      cArray::Resize(symboltrades,newsize,size);
      //===============

      //===============
      symboltrades[newsize-1]=trades[i];
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::NettTrades(const cTradeInfo &trades[],cTradeInfo &tradesnetted[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   cArray::Free(tradesnetted);
//===============

//===============
   string symbols[];
//===============

//===============
   cTradeInfo symboltrades[];
//===============

//===============
   cTrade::GetSymbols(trades,symbols);
//===============

//===============
   const int size=cArray::Size(symbols);
//===============
   for(int i=0;i<size;i++)
     {
      //===============
      cTrade::GetSymbolTrades(trades,symbols[i],symboltrades);
      //===============

      //===============
      cTrade::NettPosition(symboltrades,tradesnetted);
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::NettPosition(const cTradeInfo &trades[],cTradeInfo &tradesnetted[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const int size=cArray::Size(trades);
//===============

//===============
// Id only trades of the same type => No netting required, just copy as is
//===============
   bool neednetting     = false;
   eTradeType prevtype  = WRONG_VALUE;
   string     symbol    = NULL;
//===============
   for(int i=0;i<size;i++)
     {
      //===============
      if(symbol==NULL)symbol=trades[i].SymbolGet();
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT({},symbol==trades[i].SymbolGet(),false,{})
      //===============

      //===============
      if(prevtype!=WRONG_VALUE && prevtype!=trades[i].TypeGet()){neednetting=true;break;}
      //===============

      //===============
      prevtype=trades[i].TypeGet();
      //===============
     }
//===============
   if(!neednetting)
     {
      //===============
      for(int i=0;i<size;i++)
        {
         //===============
         const int newsize=cArray::Size(tradesnetted)+1;
         //===============

         //===============
         cArray::Resize(tradesnetted,newsize,size);
         //===============

         //===============
         tradesnetted[newsize-1]=trades[i];
         //===============
        }
      //===============

      //===============
      return;
      //===============
     }
//===============

//===============
   bool closed[];
//===============
   cArray::Resize(closed,size,0);
//===============
   for(int i=0;i<size;i++)closed[i]=false;
//===============

//===============
   cTradeInfo temptrades[];
//===============
   cArray::Resize(temptrades,size,0);
//===============
   for(int i=0;i<size;i++)temptrades[i]=trades[i];
//===============

//===============
   double netlots=0;
//===============

//===============
// Netting trades using FIFO approach
//===============
   for(int i=0;i<size;i++)
     {
      //===============
      const double lot      = temptrades[i].LotsGet();
      const eTradeType type = temptrades[i].TypeGet();
      //===============

      //===============
      if((netlots>0 && type==TRADETYPE_SELL) || (netlots<0 && type==TRADETYPE_BUY))
        {
         //===============
         // OUT SCENARIO
         //===============
         if(lot<::MathAbs(netlots))
           {
            //===============
            double closedlots=0;
            //===============

            //===============
            // Check what should be closed before
            //===============
            for(int j=0;j<i;j++)
              {
               //===============
               if(closed[j])continue;
               //===============

               //===============
               if(type==temptrades[j].TypeGet())continue;
               //===============

               //===============
               const double contrlot=temptrades[j].LotsGet();
               //===============

               //===============
               // Full Closure
               //===============
               if(contrlot<=lot-closedlots)
                 {
                  //===============
                  closed[j]=true;
                  //===============
                 }
               //===============
               // Partial Closure
               //===============  
               else
                 {
                  //===============
                  // Update remaining trade volume and REASSIGNING TICKET to the closed one          
                  //===============
                  temptrades[j].Update(temptrades[i].TicketGet(),temptrades[j].IdentifierGet(),temptrades[j].TypeGet(),temptrades[j].StatusGet(),
                                       temptrades[j].SymbolGet(),temptrades[j].MagicGet(),temptrades[j].CommentGet(),(contrlot-(lot-closedlots)),
                                       temptrades[j].OpenPriceGet(),temptrades[j].StopLossGet(),temptrades[j].TakeProfitGet(),
                                       temptrades[j].OpenTimeGet());
                  //===============
                 }
               //===============

               //===============
               closedlots+=contrlot;
               //===============

               //===============
               if(closedlots>=lot)break;
               //===============
              }
            //===============

            //===============
            // Closing a trade
            //===============
            closed[i]=true;
            //===============
           }
         //===============
         // INOUT SCENARIO
         //===============
         else
           {
            //===============
            // Close everything before
            //===============
            for(int j=0;j<i;j++)closed[j]=true;
            //===============
            // Update resulting trade volume          
            //===============
            temptrades[i].Update(temptrades[i].TicketGet(),temptrades[i].IdentifierGet(),temptrades[i].TypeGet(),temptrades[i].StatusGet(),
                                 temptrades[i].SymbolGet(),temptrades[i].MagicGet(),temptrades[i].CommentGet(),(lot-::MathAbs(netlots)),
                                 temptrades[i].OpenPriceGet(),temptrades[i].StopLossGet(),temptrades[i].TakeProfitGet(),
                                 temptrades[i].OpenTimeGet());
            //===============
           }
        }
      //===============

      //===============
      netlots+=(type==TRADETYPE_BUY?(1):(-1))*lot;
      //===============
     }
//===============

//===============
// Copy results into resulting array
//===============
   for(int i=0;i<size;i++)
     {
      //===============
      if(closed[i])continue;
      //===============

      //===============
      const int newsize=cArray::Size(tradesnetted)+1;
      //===============

      //===============
      cArray::Resize(tradesnetted,newsize,size);
      //===============

      //===============
      tradesnetted[newsize-1]=temptrades[i];
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static double cTrade::PointPrice(const string symbol)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const double point     = ::SymbolInfoDouble(symbol,SYMBOL_POINT);
   const double ticksize  = ::SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
   const double tickvalue = ::SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE);
//===============

//===============
   if(ticksize<=0 || point<=0)return(0);
//===============

//===============
   const double pointprice=(tickvalue/(ticksize/point));
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(pointprice);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static double cTrade::GetLot(const string symbol,const long slpoints,const double moneyrisk)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(slpoints<=0 || moneyrisk<=0)return(0.0);
//===============

//===============
   const double pointprice=cTrade::PointPrice(symbol);
//===============

//===============
   if(pointprice==0)return(0);
//===============

//===============
   const double result=(moneyrisk/slpoints)/pointprice;
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::CalculateSLandTP(const string symbol,const eTradeType type,const double entrylevel,const double lots,
                                     const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                                     const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                                     const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice,
                                     double &sllevel,double &tplevel)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   sllevel = 0;
   tplevel = 0;
//===============

//===============
   const bool changesl=((slpointsenabled && slpoints>0) || (slpriceenabled && slprice>0) || (slmoneyenabled && slmoney>0));
   const bool changetp=((tppointsenabled && tppoints>0) || (tppriceenabled && tpprice>0) || (tpmoneyenabled && tpmoney>0));
//===============

//===============
   if(!changesl && !changetp)return;
//===============

//===============
   const double point    = ::SymbolInfoDouble(symbol,SYMBOL_POINT);
   const int    digits   = (int)::SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   const double ticksize = ::SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE);
//===============

//===============
   const double pointprice=lots*cTrade::PointPrice(symbol);
//===============

//===============
   if(slpointsenabled && slpoints>0)sllevel=(type==TRADETYPE_BUY?(entrylevel-slpoints*point):(entrylevel+slpoints*point));
   if(tppointsenabled && tppoints>0)tplevel=(type==TRADETYPE_BUY?(entrylevel+tppoints*point):(entrylevel-tppoints*point));
//===============

//===============
   if(slpriceenabled && slprice>0)sllevel=(type==TRADETYPE_BUY?(::MathMax(sllevel,slprice)):(sllevel>0?(::MathMin(sllevel,slprice)):slprice));
   if(tppriceenabled && tpprice>0)tplevel=(type==TRADETYPE_BUY?(tplevel>0?(::MathMin(tplevel,tpprice)):tpprice):(::MathMax(tplevel,tpprice)));
//===============

//===============
   if(pointprice!=0)
     {
      //===============
      const double slmoneyprice = point*slmoney/pointprice;
      const double tpmoneyprice = point*tpmoney/pointprice;
      //===============

      //===============
      if(slmoneyenabled && slmoney>0)sllevel=(type==TRADETYPE_BUY?(::MathMax(sllevel,entrylevel-slmoneyprice)):
         (sllevel>0?(::MathMin(sllevel,entrylevel+slmoneyprice)):entrylevel+slmoneyprice));
      if(tpmoneyenabled && tpmoney>0)tplevel=(type==TRADETYPE_BUY?(tplevel>0?(::MathMin(tplevel,entrylevel+tpmoneyprice)):entrylevel+tpmoneyprice):
         (::MathMax(tplevel,entrylevel-tpmoneyprice)));
      //===============
     }
//===============

//===============
   sllevel = ::NormalizeDouble(sllevel,digits);
   tplevel = ::NormalizeDouble(tplevel,digits);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::TrailingStop(const long ticket,const long tslstart,const long tsldistance,const bool tsllevelenabled,const double tsllevel)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const bool cantrade=cTrade::CanTrade();
//===============
/* DEBUG ASSERTION */ASSERT({},cantrade,true,{})
//===============
   if(!cantrade)return;
//===============

//===============
   cTradeInfo trade;
//===============
   trade.Update(ticket,false,false,false);
//===============

//===============
   if(trade.TicketGet()<=0 || trade.StatusGet()!=TRADESTATUS_CURRENT)return;
//===============

//===============
   if(trade.ProfitPointsGet()<tslstart)return;
//===============

//===============
   double reference=0;
//===============

//===============
   const double point  = ::SymbolInfoDouble(trade.SymbolGet(),SYMBOL_POINT);
   const int    digits = (int)::SymbolInfoInteger(trade.SymbolGet(),SYMBOL_DIGITS);
//===============

//===============
   MqlTick lasttick;
//===============
   const bool gettick=::SymbolInfoTick(trade.SymbolGet(),lasttick);
//===============
/* DEBUG ASSERTION */ASSERT({},gettick,true,{})
//===============
   if(!gettick)return;
//===============

//===============
   double sllevel=0;
//===============

//===============
   uint retcode       = 0;
   eError myretcode   = WRONG_VALUE;
//===============

//===============
   if(trade.TypeGet()==TRADETYPE_BUY)
     {
      //===============
      reference=tsllevelenabled?tsllevel:lasttick.bid;
      //===============

      //===============
      sllevel=reference-tsldistance*point;
      //===============
      sllevel=::NormalizeDouble(sllevel,digits);
      //===============

      //===============
      if(sllevel>trade.StopLossGet()+TSLSTEPPOINTS*point)
        {
         //===============
         cTrade::ModifyTrade(ticket,sllevel,trade.TakeProfitGet(),retcode,myretcode);
         //===============
        }
      //===============
     }
//===============

//===============
   if(trade.TypeGet()==TRADETYPE_SELL)
     {
      //===============
      reference=tsllevelenabled?tsllevel:lasttick.ask;
      //===============

      //===============
      sllevel=reference+tsldistance*point;
      //===============
      sllevel=::NormalizeDouble(sllevel,digits);
      //===============

      //===============
      if(sllevel<trade.StopLossGet()-TSLSTEPPOINTS*point || trade.StopLossGet()==0)
        {
         //===============
         cTrade::ModifyTrade(ticket,sllevel,trade.TakeProfitGet(),retcode,myretcode);
         //===============
        }
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::BreakEven(const long ticket,const long belevel,const long beprofit)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const bool cantrade=cTrade::CanTrade();
//===============
/* DEBUG ASSERTION */ASSERT({},cantrade,true,{})
//===============
   if(!cantrade)return;
//===============

//===============
   cTradeInfo trade;
//===============
   trade.Update(ticket,false,false,false);
//===============

//===============
   if(trade.TicketGet()<=0 || trade.StatusGet()!=TRADESTATUS_CURRENT)return;
//===============

//===============
   if(trade.ProfitPointsGet()<belevel)return;
//===============

//===============
   const double point  = ::SymbolInfoDouble(trade.SymbolGet(),SYMBOL_POINT);
   const int    digits = (int)::SymbolInfoInteger(trade.SymbolGet(),SYMBOL_DIGITS);
//===============

//===============
   double sllevel     = 0;
   uint retcode       = 0;
   eError myretcode   = WRONG_VALUE;
//===============

//===============
   if(trade.TypeGet()==TRADETYPE_BUY)
     {
      //===============
      sllevel=trade.OpenPriceGet()+beprofit*point;
      //===============
      sllevel=::NormalizeDouble(sllevel,digits);
      //===============

      //===============
      if(sllevel>trade.StopLossGet())
        {
         //===============
         cTrade::ModifyTrade(ticket,sllevel,trade.TakeProfitGet(),retcode,myretcode);
         //===============
        }
      //===============
     }
//===============

//===============
   if(trade.TypeGet()==TRADETYPE_SELL)
     {
      //===============
      sllevel=trade.OpenPriceGet()-beprofit*point;
      //===============
      sllevel=::NormalizeDouble(sllevel,digits);
      //===============

      //===============
      if(sllevel<trade.StopLossGet() || trade.StopLossGet()==0)
        {
         //===============
         cTrade::ModifyTrade(ticket,sllevel,trade.TakeProfitGet(),retcode,myretcode);
         //===============
        }
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
#ifdef __MQL5__
//
static ENUM_ORDER_TYPE_FILLING cTrade::GetFilling(const string symbol)// Big thanks to fxsaber!!!
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   static ENUM_ORDER_TYPE_FILLING result=ORDER_FILLING_FOK;
//===============

//===============
   static string lastsymbol=NULL;
//===============

//===============
   const bool differentsymbol=(lastsymbol!=symbol);
//===============

//===============
   const uint defaultfilling=ORDER_FILLING_FOK;
//===============

//===============
   if(differentsymbol)
     {
      //===============
      lastsymbol=symbol;
      //===============

      //===============
      const ENUM_SYMBOL_TRADE_EXECUTION executionmode=(ENUM_SYMBOL_TRADE_EXECUTION)::SymbolInfoInteger(symbol,SYMBOL_TRADE_EXEMODE);
      const int fillingmode=(int)::SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE);
      //===============

      //===============
      result=(!fillingmode || (defaultfilling>=ORDER_FILLING_RETURN) || ((fillingmode &(defaultfilling+1))!=defaultfilling+1)) ?
             (((executionmode==SYMBOL_TRADE_EXECUTION_EXCHANGE) || (executionmode==SYMBOL_TRADE_EXECUTION_INSTANT)) ?
             ORDER_FILLING_RETURN :((fillingmode==SYMBOL_FILLING_IOC) ? ORDER_FILLING_IOC : ORDER_FILLING_FOK)) :
             (ENUM_ORDER_TYPE_FILLING)defaultfilling;
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static ENUM_ORDER_TYPE_TIME cTrade::GetExpirationType(const string symbol)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   static ENUM_ORDER_TYPE_TIME result=ORDER_TIME_GTC;
//===============

//===============
   static string lastsymbol=NULL;
//===============

//===============
   const bool differentsymbol=(lastsymbol!=symbol);
//===============

//===============
   const uint defaulttype=ORDER_TIME_GTC;
//===============

//===============
   if(differentsymbol)
     {
      //===============
      lastsymbol=symbol;
      //===============

      //===============
      const int expirationmode=(int)::SymbolInfoInteger(symbol,SYMBOL_EXPIRATION_MODE);
      //===============

      //===============
      uint expiration=defaulttype;
      //===============

      //===============
      if((expiration>ORDER_TIME_SPECIFIED_DAY) || (!((expirationmode>>expiration) &1)))
        {
         //===============
         if((expiration<ORDER_TIME_SPECIFIED) || (expirationmode<SYMBOL_EXPIRATION_SPECIFIED))
            expiration=ORDER_TIME_GTC;
         else if(expiration>ORDER_TIME_DAY)
            expiration=ORDER_TIME_SPECIFIED;
         //===============

         //===============
         uint i=1<<expiration;
         //===============

         //===============
         while((expiration<=ORDER_TIME_SPECIFIED_DAY) && ((expirationmode  &i)!=i))
           {
            //===============
            i<<=1;
            expiration++;
            //===============
           }
         //===============
        }
      //===============

      //===============
      result=(ENUM_ORDER_TYPE_TIME)expiration;
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(result);
//===============
  }
//
#endif
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::CanTrade(void)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   static const bool istesting=(bool)::MQLInfoInteger(MQL_TESTER);
//===============

//===============
   if(istesting)return(true);
//===============

//===============
   const bool result=(::TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) && 
                      ::MQLInfoInteger(MQL_TRADE_ALLOWED) &&
                      ::AccountInfoInteger(ACCOUNT_TRADE_EXPERT) &&
                      ::AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) &&
                      ::TerminalInfoInteger(TERMINAL_CONNECTED));
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::ClosingAllowed(const string symbol)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   const ENUM_SYMBOL_TRADE_MODE trademode=(ENUM_SYMBOL_TRADE_MODE)::SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE);
//===============

//===============
   if(trademode==SYMBOL_TRADE_MODE_DISABLED)return(false);
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::OpeningAllowed(const string symbol,const eTradeType type)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   const ENUM_SYMBOL_TRADE_MODE trademode=(ENUM_SYMBOL_TRADE_MODE)::SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE);
//===============

//===============
   switch(trademode)
     {
      case SYMBOL_TRADE_MODE_DISABLED       :                                 return(false);
      case SYMBOL_TRADE_MODE_LONGONLY       :                                 return(type==TRADETYPE_BUY);
      case SYMBOL_TRADE_MODE_SHORTONLY      :                                 return(type==TRADETYPE_SELL);
      case SYMBOL_TRADE_MODE_CLOSEONLY      :                                 return(false);
      case SYMBOL_TRADE_MODE_FULL           :                                 return(true);
      //===============
      default                 :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //=============== 
     }
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::TradeTypeAllowed(const eAllowedTrades allowed,const eTradeType type)
  {
//===============
   switch(allowed)
     {
      case ALLOWEDTRADES_ALL       :                                 return(true);
      case ALLOWEDTRADES_NONE      :                                 return(false);
      case ALLOWEDTRADES_BUYONLY   :                                 return(type==TRADETYPE_BUY);
      case ALLOWEDTRADES_SELLONLY  :                                 return(type==TRADETYPE_SELL);
      //===============
      default                 :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //=============== 
     }
//===============

//===============
   return(false);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static double cTrade::CalculateLot(const string symbol,const eTradeType type,const double requiredbelevel,const double dealprice,
                                   const double lotsnow,const double belevelnow)
  {
//===============
   const double difference=::MathAbs(dealprice-requiredbelevel);
//===============

//===============
   double requiredlot=(difference!=0?(lotsnow*::MathAbs(requiredbelevel-belevelnow)/difference):0);
//===============

//===============
   if(type==TRADETYPE_BUY && requiredbelevel>belevelnow)requiredlot=0;
//===============

//===============
   if(type==TRADETYPE_SELL && requiredbelevel<belevelnow)requiredlot=0;
//===============

//===============
   return(cTrade::CheckLot(symbol,requiredlot));
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static double cTrade::CheckLot(const string symbol,const double lots)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   double result=lots;
//===============

//===============
   const double min    = ::SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
   const double max    = ::SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
   const double step   = ::SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
//===============

//===============
   if(step!=0)result=::MathRound(result/step)*step;
//===============

//===============
   if(result<min)result=min;
//===============
   if(result>max)result=max;
//===============

//===============
   result=::NormalizeDouble(result,2);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(min==0?::MathMax(result,0.01):result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static long cTrade::OpenTrade(const string symbol,const eTradeType type,const double lots,const long magic,const string comment,
                              const long slippage,const bool checkplaced,uint &retcode,eError &myretcode)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const long ticket=cTrade::OpenTrade(symbol,type,lots,magic,comment,
                                       false,0,false,0,false,0,false,0,false,0,false,0,
                                       (slippage>0),slippage,checkplaced,retcode,myretcode);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(ticket);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static long cTrade::OpenTrade(const string symbol,const eTradeType type,const double lots,const long magic,const string comment,
                              const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                              const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                              const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice,
                              const bool slippageenabled,const long slippage,const bool checkplaced,uint &retcode,eError &myretcode)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const bool cantrade=cTrade::CanTrade();
//===============
/* DEBUG ASSERTION */ASSERT({},cantrade,true,{})
//===============
   if(!cantrade){myretcode=ERROR_AUTOTRADINGNOTALLOWED;return(-1);}
//===============

//===============
   const bool openingallowed=cTrade::OpeningAllowed(symbol,type);
//===============
/* DEBUG ASSERTION */ASSERT({},openingallowed,true,{})
//===============
   if(!openingallowed){myretcode=RETCODE_OPENINGNOTALLOWED;return(-1);}
//===============

//===============
   if(checkplaced)
     {
      //===============
      const bool noplaced=cTrade::CheckPlaced(symbol,type,magic);
      //===============
/* DEBUG ASSERTION */ASSERT({},noplaced,true,{})
      //===============
      if(!noplaced){myretcode=RETCODE_ALREADYPLACED;return(-1);}
      //===============
     }
//===============

//===============
   const bool maxorders=cTrade::CheckMaxOrders();
//===============
/* DEBUG ASSERTION */ASSERT({},maxorders,true,{})
//===============
   if(!maxorders){myretcode=RETCODE_MAXORDERS;return(-1);}
//===============

//===============
   const double volume=cTrade::CheckLot(symbol,lots);
//===============
   const bool volumeok=(volume>0);
//===============
/* DEBUG ASSERTION */ASSERT({},volumeok,true,{})
//===============
   if(!volumeok){myretcode=RETCODE_WRONGVOLUME;return(-1);}
//===============

//===============
   const bool maxvolume=cTrade::CheckMaxVolume(symbol,type,volume);
//===============
/* DEBUG ASSERTION */ASSERT({},maxvolume,true,{})
//===============
   if(!maxvolume){myretcode=RETCODE_MAXVOLUME;return(-1);}
//===============

//===============
   MqlTick lasttick;
//===============
   const bool gettick=::SymbolInfoTick(symbol,lasttick);
//===============
/* DEBUG ASSERTION */ASSERT({},gettick,true,{})
//===============
   if(!gettick){myretcode=RETCODE_NOTICKDATA;return(-1);}
//===============

//===============
   double sllevel=0;
//===============
   double tplevel=0;
//===============

//===============
   const double price=(type==TRADETYPE_BUY?lasttick.ask:lasttick.bid);
//===============

//===============
   cTrade::CalculateSLandTP(symbol,type,price,volume,
                            slpointsenabled,slpoints,tppointsenabled,tppoints,
                            slmoneyenabled,slmoney,tpmoneyenabled,tpmoney,
                            slpriceenabled,slprice,tppriceenabled,tpprice,sllevel,tplevel);
//===============

//===============
   const bool stopsok=cTrade::CheckStops(symbol,type,true,price,sllevel,tplevel);
//===============
/* DEBUG ASSERTION */ASSERT({},stopsok,true,{})
//===============
   if(!stopsok){myretcode=RETCODE_WRONGSTOPS;return(-1);}
//===============

//===============
   long ticket=-1;
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   const int ordermode=(int)::SymbolInfoInteger(symbol,SYMBOL_ORDER_MODE);
//===============
   const bool orderallowed=((SYMBOL_ORDER_MARKET&ordermode)==SYMBOL_ORDER_MARKET);
//===============
/* DEBUG ASSERTION */ASSERT({},orderallowed,true,{})
//===============
   if(!orderallowed){myretcode=RETCODE_TRADETYPENOTALLOWED;return(-1);}
//===============

//===============
   MqlTradeRequest      openrequest;
   MqlTradeCheckResult  opencheckresult;
   MqlTradeResult       openresult;
//===============
   ::ZeroMemory(openrequest);
   ::ZeroMemory(opencheckresult);
   ::ZeroMemory(openresult);
//===============

//===============
   const ENUM_ORDER_TYPE_FILLING filling=cTrade::GetFilling(symbol);
//===============

//===============
   openrequest.action       = TRADE_ACTION_DEAL;
   openrequest.magic        = magic;
   openrequest.symbol       = symbol;
   openrequest.volume       = volume;
   openrequest.type         = (type==TRADETYPE_BUY?ORDER_TYPE_BUY:ORDER_TYPE_SELL);
   openrequest.deviation    = (slippageenabled?(int)slippage:0);
   openrequest.comment      = comment;
   openrequest.type_filling = filling;
   openrequest.price        = ::NormalizeDouble(price,(int)::SymbolInfoInteger(symbol,SYMBOL_DIGITS));
   openrequest.sl           = sllevel;
   openrequest.tp           = tplevel;
//===============

//===============
   const bool marginok=cTrade::CheckMargin(symbol,volume,type,openrequest.price);
//===============
/* DEBUG ASSERTION */ASSERT({},marginok,true,{})
//===============
   if(!marginok){myretcode=RETCODE_NOFREEMARGIN;return(-1);}
//===============

//===============
   const bool check=::OrderCheck(openrequest,opencheckresult);
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},check && opencheckresult.retcode==0,false,::Print(TOSTRING(opencheckresult.retcode));)
//===============

//===============
   retcode=opencheckresult.retcode;
//===============

//===============
   if(check && opencheckresult.retcode==0)
     {
      //===============
      const bool send=::OrderSend(openrequest,openresult);
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT({},send && (openresult.deal>0 || openresult.order>0),false,::Print(TOSTRING(openresult.retcode));)
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT({},openresult.deal<=0 || openresult.order>0,false,::Print(TOSTRING(openresult.deal),VERTICALBAR,TOSTRING(openresult.order));)
      //===============

      //===============
      ticket=(long)openresult.order;
      //===============

      //===============
      retcode=openresult.retcode;
      //===============
     }
   else
     {
      //===============
      retcode=RETCODE_ORDERCHECKFAILED;
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============

//===============
   const bool marginok=cTrade::CheckMargin(symbol,volume,type,price);
//===============
/* DEBUG ASSERTION */ASSERT({},marginok,true,{})
//===============
   if(!marginok){myretcode=RETCODE_NOFREEMARGIN;return(-1);}
//===============

//===============
   const int    cmd=(type==TRADETYPE_BUY?OP_BUY:OP_SELL);
//===============

//===============
   ::ResetLastError();
//===============

//===============
   const int send=::OrderSend(symbol,cmd,volume,::NormalizeDouble(price,(int)::SymbolInfoInteger(symbol,SYMBOL_DIGITS)),
                              (slippageenabled?(int)slippage:0),sllevel,tplevel,comment,(int)magic,0,clrNONE);
//===============

//===============
   retcode=::GetLastError();
//===============

//===============
   ticket=send;
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},send>0,false,::Print(TOSTRING(retcode));)
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(ticket);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static long cTrade::PlacePendingOrder(const string symbol,const double price,const ePendingOrderType type,const double lots,
                                      const long magic,const string comment,const datetime expiration,uint &retcode,eError &myretcode)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const long ticket=cTrade::PlacePendingOrder(symbol,price,type,lots,magic,comment,
                                               false,0,false,0,
                                               false,0,false,0,
                                               false,0,false,0,
                                               (expiration>0),expiration,retcode,myretcode);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(ticket);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static long cTrade::PlacePendingOrder(const string symbol,const double price,const ePendingOrderType type,const double lots,
                                      const long magic,const string comment,
                                      const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                                      const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                                      const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice,
                                      const bool expirationenabled,const datetime expiration,uint &retcode,eError &myretcode)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const bool cantrade=cTrade::CanTrade();
//===============
/* DEBUG ASSERTION */ASSERT({},cantrade,true,{})
//===============
   if(!cantrade){myretcode=ERROR_AUTOTRADINGNOTALLOWED;return(-1);}
//===============

//===============
   const eTradeType side=(type==PENDINGORDERTYPE_BUYLIMIT || type==PENDINGORDERTYPE_BUYSTOP)?TRADETYPE_BUY:TRADETYPE_SELL;
//===============

//===============
   const bool openingallowed=cTrade::OpeningAllowed(symbol,side);
//===============
/* DEBUG ASSERTION */ASSERT({},openingallowed,true,{})
//===============
   if(!openingallowed){myretcode=RETCODE_OPENINGNOTALLOWED;return(-1);}
//===============

//===============
   const bool maxorders=cTrade::CheckMaxOrders();
//===============
/* DEBUG ASSERTION */ASSERT({},maxorders,true,{})
//===============
   if(!maxorders){myretcode=RETCODE_MAXORDERS;return(-1);}
//===============

//===============
   const double volume=cTrade::CheckLot(symbol,lots);
//===============
   const bool volumeok=(volume>0);
//===============
/* DEBUG ASSERTION */ASSERT({},volumeok,true,{})
//===============
   if(!volumeok){myretcode=RETCODE_WRONGVOLUME;return(-1);}
//===============

//===============
   const bool maxvolume=cTrade::CheckMaxVolume(symbol,side,volume);
//===============
/* DEBUG ASSERTION */ASSERT({},maxvolume,true,{})
//===============
   if(!maxvolume){myretcode=RETCODE_MAXVOLUME;return(-1);}
//===============

//===============
   double sllevel=0;
//===============
   double tplevel=0;
//===============

//===============
   cTrade::CalculateSLandTP(symbol,side,price,volume,
                            slpointsenabled,slpoints,tppointsenabled,tppoints,
                            slmoneyenabled,slmoney,tpmoneyenabled,tpmoney,
                            slpriceenabled,slprice,tppriceenabled,tpprice,sllevel,tplevel);
//===============

//===============
   const bool stopsok=cTrade::CheckStops(symbol,side,false,price,sllevel,tplevel);
//===============
/* DEBUG ASSERTION */ASSERT({},stopsok,true,{})
//===============
   if(!stopsok){myretcode=RETCODE_WRONGSTOPS;return(-1);}
//===============

//===============
   const bool orderpriceok=cTrade::CheckOrderPrice(symbol,type,price);
//===============
/* DEBUG ASSERTION */ASSERT({},orderpriceok,true,{})
//===============
   if(!orderpriceok){myretcode=RETCODE_WRONGORDERPRICE;return(-1);}
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   const int ordermode=(int)::SymbolInfoInteger(symbol,SYMBOL_ORDER_MODE);
//===============
   bool orderallowed=((SYMBOL_ORDER_LIMIT&ordermode)==SYMBOL_ORDER_LIMIT);
//===============
/* DEBUG ASSERTION */ASSERT({},orderallowed,true,{})
//===============
   if(!orderallowed){myretcode=RETCODE_TRADETYPENOTALLOWED;return(-1);}
//===============
   orderallowed=((SYMBOL_ORDER_STOP&ordermode)==SYMBOL_ORDER_STOP);
//===============
/* DEBUG ASSERTION */ASSERT({},orderallowed,true,{})
//===============
   if(!orderallowed){myretcode=RETCODE_TRADETYPENOTALLOWED;return(-1);}
//===============

//===============
   MqlTradeRequest      openrequest;
   MqlTradeCheckResult  opencheckresult;
   MqlTradeResult       openresult;
//===============
   ::ZeroMemory(openrequest);
   ::ZeroMemory(opencheckresult);
   ::ZeroMemory(openresult);
//===============

//===============
   const ENUM_ORDER_TYPE_FILLING filling=cTrade::GetFilling(symbol);
//===============

//===============
   openrequest.action       = TRADE_ACTION_PENDING;
   openrequest.magic        = magic;
   openrequest.symbol       = symbol;
   openrequest.volume       = volume;
   openrequest.comment      = comment;
   openrequest.type_filling = filling;
   openrequest.price        = ::NormalizeDouble(price,(int)::SymbolInfoInteger(symbol,SYMBOL_DIGITS));
   openrequest.sl           = sllevel;
   openrequest.tp           = tplevel;
   openrequest.type_time    = cTrade::GetExpirationType(symbol);
//===============

//===============
   if((openrequest.type_time==ORDER_TIME_SPECIFIED || openrequest.type_time==ORDER_TIME_SPECIFIED_DAY) && expirationenabled)openrequest.expiration=expiration;
//===============

//===============
// Fix for MOEX etc
//===============
   if(::SymbolInfoInteger(symbol,SYMBOL_EXPIRATION_MODE)==10)
     {
      //===============
      openrequest.type_filling  = ORDER_FILLING_RETURN;
      openrequest.type_time     = ORDER_TIME_SPECIFIED_DAY;
      openrequest.expiration    =  expiration;
      //===============
     }
//===============

//===============
   switch(type)
     {
      //===============
      case  PENDINGORDERTYPE_BUYLIMIT          :   openrequest.type=ORDER_TYPE_BUY_LIMIT;                                 break;
      case  PENDINGORDERTYPE_BUYSTOP           :   openrequest.type=ORDER_TYPE_BUY_STOP;                                  break;
      case  PENDINGORDERTYPE_SELLLIMIT         :   openrequest.type=ORDER_TYPE_SELL_LIMIT;                                break;
      case  PENDINGORDERTYPE_SELLSTOP          :   openrequest.type=ORDER_TYPE_SELL_STOP;                                 break;
      //===============
      default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============

//===============
   const bool marginok=cTrade::CheckMargin(symbol,volume,side,openrequest.price);
//===============
/* DEBUG ASSERTION */ASSERT({},marginok,true,{})
//===============
   if(!marginok){myretcode=RETCODE_NOFREEMARGIN;return(-1);}
//===============

//===============
   const bool check=::OrderCheck(openrequest,opencheckresult);
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},check && opencheckresult.retcode==0,false,::Print(TOSTRING(opencheckresult.retcode));)
//===============

//===============
   retcode=opencheckresult.retcode;
//===============

//===============
   if(check && opencheckresult.retcode==0)
     {
      //===============
      const bool send=::OrderSend(openrequest,openresult);
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT({},send && openresult.order>0,false,::Print(TOSTRING(openresult.retcode));)
      //===============

      //===============
      retcode=openresult.retcode;
      //===============

      //===============
      return((long)openresult.order);
      //===============
     }
   else
     {
      //===============
      myretcode=RETCODE_ORDERCHECKFAILED;
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============

//===============
   const bool marginok=cTrade::CheckMargin(symbol,volume,side,price);
//===============
/* DEBUG ASSERTION */ASSERT({},marginok,true,{})
//===============
   if(!marginok){myretcode=RETCODE_NOFREEMARGIN;return(-1);}
//===============

//===============
   int    cmd=-1;
//===============

//===============
   switch(type)
     {
      //===============
      case  PENDINGORDERTYPE_BUYLIMIT          :   cmd=OP_BUYLIMIT;                                 break;
      case  PENDINGORDERTYPE_BUYSTOP           :   cmd=OP_BUYSTOP;                                  break;
      case  PENDINGORDERTYPE_SELLLIMIT         :   cmd=OP_SELLLIMIT;                                break;
      case  PENDINGORDERTYPE_SELLSTOP          :   cmd=OP_SELLSTOP;                                 break;
      //===============
      default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============

//===============
   ::ResetLastError();
//===============

//===============
   const int send=::OrderSend(symbol,cmd,volume,::NormalizeDouble(price,(int)::SymbolInfoInteger(symbol,SYMBOL_DIGITS)),0,
                              sllevel,tplevel,comment,(int)magic,(expirationenabled?expiration:0),clrNONE);
//===============

//===============
   retcode=::GetLastError();;
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},send>0,false,::Print(TOSTRING(retcode));)
//===============

//===============
   return(send);
//===============

//===============
#endif 
//===============

//===============
   return(-1);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::ModifyTrade(const long ticket,const double newsl,const double newtp,uint &retcode,eError &myretcode)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const bool cantrade=cTrade::CanTrade();
//===============
/* DEBUG ASSERTION */ASSERT({},cantrade,true,{})
//===============
   if(!cantrade){myretcode=ERROR_AUTOTRADINGNOTALLOWED;return(false);}
//===============

//===============
   cTradeInfo trade;
//===============
   trade.Update(ticket,false,false,false);
//===============

//===============
   const string symbol = trade.SymbolGet();
   const int    digits = (int)::SymbolInfoInteger(symbol,SYMBOL_DIGITS);
//===============
   const double SL=::NormalizeDouble(newsl,digits);
   const double TP=::NormalizeDouble(newtp,digits);
//===============

//===============
   const bool sameSL = (SL==trade.StopLossGet());
   const bool sameTP = (TP==trade.TakeProfitGet());
//===============

//===============
   if(sameSL && sameTP)return(false);
//===============

//===============
   const bool stopsok=cTrade::CheckStops(symbol,trade.TypeGet(),true,trade.OpenPriceGet(),sameSL?0:SL,sameTP?0:TP);
//===============
/* DEBUG ASSERTION */ASSERT({},stopsok,true,{})
//===============
   if(!stopsok){myretcode=RETCODE_WRONGSTOPS;return(false);}
//===============

//===============
   const bool isfreezed=cTrade::CheckFreezed(trade.SymbolGet(),trade.TypeGet(),trade.StopLossGet(),trade.TakeProfitGet());
//===============
   if(isfreezed)return(false);
//===============

//===============
   bool result=false;
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   if(!::PositionSelectByTicket(ticket))
     {
      //===============
      ::ResetLastError();
      //===============

      //===============
      myretcode=RETCODE_TRADENOTFOUND;
      //===============

      //===============
      return(false);
      //===============
     }
//===============

//===============
   const int ordermode=(int)::SymbolInfoInteger(symbol,SYMBOL_ORDER_MODE);
//===============
   bool orderallowed=((SYMBOL_ORDER_SL&ordermode)==SYMBOL_ORDER_SL);
//===============
/* DEBUG ASSERTION */ASSERT({},orderallowed,true,{})
//===============
   if(!orderallowed){myretcode=RETCODE_TRADETYPENOTALLOWED;return(false);}
//===============
   orderallowed=((SYMBOL_ORDER_TP&ordermode)==SYMBOL_ORDER_TP);
//===============
/* DEBUG ASSERTION */ASSERT({},orderallowed,true,{})
//===============
   if(!orderallowed){myretcode=RETCODE_TRADETYPENOTALLOWED;return(false);}
//===============

//===============
   MqlTradeRequest     modifyrequest;
   MqlTradeResult      modifyresult;
   MqlTradeCheckResult modifycheckresult;
//===============
   ::ZeroMemory(modifyrequest);
   ::ZeroMemory(modifyresult);
   ::ZeroMemory(modifycheckresult);
//===============

//===============
   modifyrequest.action       = TRADE_ACTION_SLTP;
   modifyrequest.position     = ticket;
   modifyrequest.symbol       = symbol;
   modifyrequest.sl           = SL;
   modifyrequest.tp           = TP;
//===============

//===============
   const bool check=::OrderCheck(modifyrequest,modifycheckresult);
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},check && modifycheckresult.retcode==0,false,::Print(TOSTRING(modifycheckresult.retcode));)
//===============

//===============
   retcode=modifycheckresult.retcode;
//===============

//===============
   if(check && modifycheckresult.retcode==0)
     {
      //===============
      const bool send=::OrderSend(modifyrequest,modifyresult);
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT({},send && modifyresult.retcode==TRADE_RETCODE_DONE,false,::Print(TOSTRING(modifyresult.retcode));)
      //===============

      //===============
      retcode=modifyresult.retcode;
      //===============

      //===============
      if(send && modifyresult.retcode==TRADE_RETCODE_DONE)
        {
         //===============
         result=true;
         //===============

         //===============
         retcode=0;
         //===============
        }
      //===============
     }
   else
     {
      //===============
      myretcode=RETCODE_ORDERCHECKFAILED;
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============

//===============
   if(!::OrderSelect((int)ticket,SELECT_BY_TICKET,MODE_TRADES) || ::OrderCloseTime()>0){myretcode=RETCODE_TRADENOTFOUND;return(false);}
//===============

//===============
   if(::OrderType()!=OP_BUY && ::OrderType()!=OP_SELL){myretcode=RETCODE_TRADENOTFOUND;return(false);}
//===============

//===============
   ::ResetLastError();
//===============

//===============
   result=::OrderModify((int)ticket,::OrderOpenPrice(),SL,TP,0,clrNONE);
//===============

//===============
   retcode=::GetLastError();
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},result,false,::Print(TOSTRING(retcode));)
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::ModifyPendingOrder(const long ticket,const double newprice,const double newsl,const double newtp,
                                       const datetime newexpiration,uint &retcode,eError &myretcode)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const bool cantrade=cTrade::CanTrade();
//===============
/* DEBUG ASSERTION */ASSERT({},cantrade,true,{})
//===============
   if(!cantrade){myretcode=ERROR_AUTOTRADINGNOTALLOWED;return(false);}
//===============

//===============
   cPendingOrderInfo order;
//===============
   order.Update(ticket);
//===============

//===============
   if(order.TicketGet()<=0 || order.StatusGet()!=ORDERSTATUS_PENDING){myretcode=RETCODE_TRADENOTFOUND;return(false);}
//===============

//===============
   const bool isfreezed=cTrade::CheckFreezed(order.SymbolGet(),order.TypeGet(),order.OpenPriceGet());
//===============
   if(isfreezed)return(false);
//===============

//===============
   const string symbol = order.SymbolGet();
   const int    digits = (int)::SymbolInfoInteger(symbol,SYMBOL_DIGITS);
//===============
   const double PRICE  = ::NormalizeDouble(newprice,digits);
   const double SL     = ::NormalizeDouble(newsl,digits);
   const double TP     = ::NormalizeDouble(newtp,digits);
//===============

//===============
   const bool sameSL = (SL==order.StopLossGet());
   const bool sameTP = (TP==order.TakeProfitGet());
//===============

//===============
   if(sameSL && sameTP && PRICE==order.OpenPriceGet() && newexpiration==order.ExpirationGet())return(false);
//===============

//===============
   const eTradeType side=(order.TypeGet()==PENDINGORDERTYPE_BUYLIMIT || order.TypeGet()==PENDINGORDERTYPE_BUYSTOP)?TRADETYPE_BUY:TRADETYPE_SELL;
//===============

//===============
   const bool stopsok=cTrade::CheckStops(symbol,side,false,PRICE,sameSL?0:SL,sameTP?0:TP);
//===============
/* DEBUG ASSERTION */ASSERT({},stopsok,true,{})
//===============
   if(!stopsok){myretcode=RETCODE_WRONGSTOPS;return(false);}
//===============

//===============
   const bool orderpriceok=cTrade::CheckOrderPrice(symbol,order.TypeGet(),PRICE);
//===============
/* DEBUG ASSERTION */ASSERT({},orderpriceok,true,{})
//===============
   if(!orderpriceok){myretcode=RETCODE_WRONGORDERPRICE;return(false);}
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   if(!::OrderSelect(ticket))
     {
      //===============
      ::ResetLastError();
      //===============

      //===============
      myretcode=RETCODE_TRADENOTFOUND;
      //===============

      //===============
      return(false);
      //===============
     }
//===============

//===============
   MqlTradeRequest     modifyrequest;
   MqlTradeResult      modifyresult;
   MqlTradeCheckResult modifycheckresult;
//===============
   ::ZeroMemory(modifyrequest);
   ::ZeroMemory(modifyresult);
   ::ZeroMemory(modifycheckresult);
//===============

//===============
   modifyrequest.action       = TRADE_ACTION_MODIFY;
   modifyrequest.order        = ticket;
   modifyrequest.price        = PRICE;
   modifyrequest.sl           = SL;
   modifyrequest.tp           = TP;
   modifyrequest.type_time    = (ENUM_ORDER_TYPE_TIME)::OrderGetInteger(ORDER_TYPE_TIME);
//===============

//===============
   if(modifyrequest.type_time==ORDER_TIME_SPECIFIED || modifyrequest.type_time==ORDER_TIME_SPECIFIED_DAY)modifyrequest.expiration=newexpiration;
//===============

//===============
   const bool check=::OrderCheck(modifyrequest,modifycheckresult);
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},check && modifycheckresult.retcode==0,false,::Print(TOSTRING(modifycheckresult.retcode));)
//===============

//===============
   retcode=modifycheckresult.retcode;
//===============

//===============
   if(check && modifycheckresult.retcode==0)
     {
      //===============
      const bool send=::OrderSend(modifyrequest,modifyresult);
      //===============

      //===============
      retcode=(modifyresult.retcode==TRADE_RETCODE_DONE?0:modifyresult.retcode);
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT({},send && modifyresult.retcode==TRADE_RETCODE_DONE,false,::Print(TOSTRING(modifyresult.retcode));)
      //===============

      //===============
      if(send && modifyresult.retcode==TRADE_RETCODE_DONE)return(true);
      //===============
     }
   else
     {
      //===============
      myretcode=RETCODE_ORDERCHECKFAILED;
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============

//===============
   if(!::OrderSelect((int)ticket,SELECT_BY_TICKET,MODE_TRADES) || ::OrderCloseTime()>0){myretcode=RETCODE_TRADENOTFOUND;return(false);}
//===============

//===============
   if(::OrderType()!=OP_BUYSTOP && ::OrderType()!=OP_SELLSTOP && ::OrderType()!=OP_BUYLIMIT && ::OrderType()!=OP_SELLLIMIT)
     {
      //===============
      myretcode=RETCODE_TRADENOTFOUND;
      //===============

      //===============
      return(false);
      //===============
     }
//===============

//===============
   ::ResetLastError();
//===============

//===============
   const bool modify=::OrderModify((int)ticket,PRICE,SL,TP,newexpiration,clrNONE);
//===============

//===============
   retcode=::GetLastError();
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},modify,false,::Print(TOSTRING(retcode));)
//===============

//===============
   return(modify);
//===============

//===============
#endif 
//===============

//===============
   return(false);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::ModifyTrade(const long ticket,const bool tightenstopsonly,
                                const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                                const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                                const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const bool changesl=(slpointsenabled || slpriceenabled || slmoneyenabled);
   const bool changetp=(tppointsenabled || tppriceenabled || tpmoneyenabled);
//===============

//===============
   if(!changesl && !changetp)return;
//===============

//===============
   const bool cantrade=cTrade::CanTrade();
//===============
/* DEBUG ASSERTION */ASSERT({},cantrade,true,{})
//===============
   if(!cantrade)return;
//===============

//===============
   double sllevel=0;
//===============
   double tplevel=0;
//===============

//===============
   cTradeInfo trade;
//===============
   trade.Update(ticket,false,false,false);
//===============

//===============
   if(trade.TicketGet()<=0 || trade.StatusGet()!=TRADESTATUS_CURRENT)return;
//===============

//===============
   cTrade::CalculateSLandTP(trade.SymbolGet(),trade.TypeGet(),trade.OpenPriceGet(),trade.LotsGet(),
                            slpointsenabled,slpoints,tppointsenabled,tppoints,
                            slmoneyenabled,slmoney,tpmoneyenabled,tpmoney,
                            slpriceenabled,slprice,tppriceenabled,tpprice,sllevel,tplevel);
//===============

//===============
   if(tightenstopsonly)
     {
      //===============
      if(trade.TypeGet()==TRADETYPE_BUY)
        {
         //===============
         if(trade.StopLossGet()>0)sllevel=::MathMax(sllevel,trade.StopLossGet());
         //===============

         //===============
         if(trade.TakeProfitGet()>0)tplevel=::MathMin(tplevel,trade.TakeProfitGet());
         //===============
        }
      //===============

      //===============
      if(trade.TypeGet()==TRADETYPE_SELL)
        {
         //===============
         if(trade.StopLossGet()>0)sllevel=::MathMin(sllevel,trade.StopLossGet());
         //===============

         //===============
         if(trade.TakeProfitGet()>0)tplevel=::MathMax(tplevel,trade.TakeProfitGet());
         //===============
        }
      //===============
     }
//===============

//===============
   uint retcode       = 0;
   eError myretcode   = WRONG_VALUE;
//===============

//===============
   cTrade::ModifyTrade(ticket,
                       changesl?sllevel:trade.StopLossGet(),changetp?tplevel:trade.TakeProfitGet(),
                       retcode,myretcode);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::ModifyPendingOrder(const long ticket,const bool priceenabled,const double price,const bool tightenstopsonly,
                                       const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                                       const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                                       const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice,
                                       const bool expirationenabled,const datetime expiration)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const bool changesl=(slpointsenabled || slpriceenabled || slmoneyenabled);
   const bool changetp=(tppointsenabled || tppriceenabled || tpmoneyenabled);
//===============

//===============
   if(!changesl && !changetp && !priceenabled && !expirationenabled)return;
//===============

//===============
   const bool cantrade=cTrade::CanTrade();
//===============
/* DEBUG ASSERTION */ASSERT({},cantrade,true,{})
//===============
   if(!cantrade)return;
//===============

//===============
   double sllevel=0;
//===============
   double tplevel=0;
//===============

//===============
   cPendingOrderInfo order;
//===============
   order.Update(ticket);
//===============

//===============
   if(order.TicketGet()<=0 || order.StatusGet()!=ORDERSTATUS_PENDING)return;
//===============

//===============
   const eTradeType side=(order.TypeGet()==PENDINGORDERTYPE_BUYLIMIT || order.TypeGet()==PENDINGORDERTYPE_BUYSTOP)?TRADETYPE_BUY:TRADETYPE_SELL;
//===============

//===============
   cTrade::CalculateSLandTP(order.SymbolGet(),side,priceenabled?price:order.OpenPriceGet(),order.LotsGet(),
                            slpointsenabled,slpoints,tppointsenabled,tppoints,
                            slmoneyenabled,slmoney,tpmoneyenabled,tpmoney,
                            slpriceenabled,slprice,tppriceenabled,tpprice,sllevel,tplevel);
//===============

//===============
   if(tightenstopsonly)
     {
      //===============
      if(side==TRADETYPE_BUY)
        {
         //===============
         if(order.StopLossGet()>0)sllevel=::MathMax(sllevel,order.StopLossGet());
         //===============

         //===============
         if(order.TakeProfitGet()>0)tplevel=::MathMin(tplevel,order.TakeProfitGet());
         //===============
        }
      //===============

      //===============
      if(side==TRADETYPE_SELL)
        {
         //===============
         if(order.StopLossGet()>0)sllevel=::MathMin(sllevel,order.StopLossGet());
         //===============

         //===============
         if(order.TakeProfitGet()>0)tplevel=::MathMax(tplevel,order.TakeProfitGet());
         //===============
        }
      //===============
     }
//===============

//===============
   uint retcode       = 0;
   eError myretcode   = WRONG_VALUE;
//===============

//===============
   cTrade::ModifyPendingOrder(ticket,priceenabled?price:order.OpenPriceGet(),
                              changesl?sllevel:order.StopLossGet(),
                              changetp?tplevel:order.TakeProfitGet(),
                              expirationenabled?expiration:order.ExpirationGet(),retcode,myretcode);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::CloseTrade(const long ticket,const bool slippageenabled,const long slippage,const double lots,uint &retcode,eError &myretcode)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const bool cantrade=cTrade::CanTrade();
//===============
/* DEBUG ASSERTION */ASSERT({},cantrade,true,{})
//===============
   if(!cantrade){myretcode=ERROR_AUTOTRADINGNOTALLOWED;return(false);}
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   if(!::PositionSelectByTicket(ticket))
     {
      //===============
      ::ResetLastError();
      //===============

      //===============
      myretcode=RETCODE_TRADENOTFOUND;
      //===============

      //===============
      return(false);
      //===============
     }
//===============

//===============
   MqlTradeRequest     closerequest;
   MqlTradeResult      closeresult;
   MqlTradeCheckResult closecheckresult;
//===============
   ::ZeroMemory(closerequest);
   ::ZeroMemory(closeresult);
   ::ZeroMemory(closecheckresult);
//===============

//===============
   const ENUM_ORDER_TYPE_FILLING filling=cTrade::GetFilling(::PositionGetString(POSITION_SYMBOL));
//===============

//===============
   closerequest.action       = TRADE_ACTION_DEAL;
   closerequest.position     = ticket;
   closerequest.magic        = ::PositionGetInteger(POSITION_MAGIC);
   closerequest.symbol       = ::PositionGetString(POSITION_SYMBOL);
   closerequest.price        = ::PositionGetDouble(POSITION_PRICE_CURRENT);
   closerequest.sl           = 0;
   closerequest.tp           = 0;
   closerequest.volume       = ((lots<=0)?(::PositionGetDouble(POSITION_VOLUME)):(cTrade::CheckLot(closerequest.symbol,lots)));
   closerequest.type         = ((ENUM_POSITION_TYPE)::PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY?ORDER_TYPE_SELL:ORDER_TYPE_BUY);
   closerequest.deviation    = (slippageenabled?slippage:0);
   closerequest.comment      = ::PositionGetString(POSITION_COMMENT);
   closerequest.type_filling = filling;
//===============

//===============
   const bool closingallowed=cTrade::ClosingAllowed(closerequest.symbol);
//===============
/* DEBUG ASSERTION */ASSERT({},closingallowed,true,{})
//===============
   if(!closingallowed){myretcode=RETCODE_CLOSINGNOTALLOWED;return(false);}
//===============

//===============
   const bool check=::OrderCheck(closerequest,closecheckresult);
//===============

//===============
   retcode=closecheckresult.retcode;
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},check && closecheckresult.retcode==0,false,::Print(TOSTRING(closecheckresult.retcode));)
//===============

//===============
   if(check && closecheckresult.retcode==0)
     {
      //===============
      const bool send=::OrderSend(closerequest,closeresult);
      //===============

      //===============
      retcode=closeresult.retcode;
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT({},send && (closeresult.deal>0 || closeresult.order>0),false,::Print(TOSTRING(closeresult.retcode));)
      //===============

      //===============
      if(send && (closeresult.deal>0 || closeresult.order>0))return(true);
      //===============
     }
   else
     {
      //===============
      myretcode=RETCODE_ORDERCHECKFAILED;
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============

//===============
   if(!::OrderSelect((int)ticket,SELECT_BY_TICKET,MODE_TRADES) || ::OrderCloseTime()>0){myretcode=RETCODE_TRADENOTFOUND;return(false);}
//===============

//===============
   const bool closingallowed=cTrade::ClosingAllowed(::OrderSymbol());
//===============
/* DEBUG ASSERTION */ASSERT({},closingallowed,true,{})
//===============
   if(!closingallowed){myretcode=RETCODE_CLOSINGNOTALLOWED;return(false);}
//===============

//===============
   if(::OrderType()!=OP_BUY && ::OrderType()!=OP_SELL){myretcode=RETCODE_TRADENOTFOUND;return(false);}
//===============

//===============
   ::ResetLastError();
//===============

//===============
   const double closelots=((lots<=0)?(::OrderLots()):(cTrade::CheckLot(::OrderSymbol(),lots)));
//===============

//===============
   const bool close=::OrderClose(::OrderTicket(),closelots,::OrderClosePrice(),(slippageenabled?(int)slippage:0),clrNONE);
//===============

//===============
   retcode=::GetLastError();
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},close,false,::Print(TOSTRING(retcode));)
//===============

//===============
   return(close);
//===============

//===============
#endif 
//===============

//===============
   return(false);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::CloseBy(const long ticket1,const long ticket2)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const bool cantrade=cTrade::CanTrade();
//===============
/* DEBUG ASSERTION */ASSERT({},cantrade,true,{})
//===============
   if(!cantrade)return;
//===============

//===============
   cTradeInfo trade1;
   cTradeInfo trade2;
//===============
   trade1.Update(ticket1,false,false,false);
   trade2.Update(ticket2,false,false,false);
//===============

//===============
   const bool closingallowed=cTrade::ClosingAllowed(trade1.SymbolGet());
//===============
/* DEBUG ASSERTION */ASSERT({},closingallowed,true,{})
//===============
   if(!closingallowed)return;
//===============

//===============
   if(trade1.TicketGet()<=0 || trade1.StatusGet()!=TRADESTATUS_CURRENT ||
      trade2.TicketGet()<=0 || trade2.StatusGet()!=TRADESTATUS_CURRENT ||
      trade1.TypeGet()==trade2.TypeGet() || 
      trade1.SymbolGet()!=trade2.SymbolGet() || 
      trade1.LotsGet()!=trade2.LotsGet())
     {
      //===============
      return;
      //===============
     }
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   const int ordermode=(int)::SymbolInfoInteger(trade1.SymbolGet(),SYMBOL_ORDER_MODE);
//===============
   const bool orderallowed=((SYMBOL_ORDER_CLOSEBY&ordermode)==SYMBOL_ORDER_CLOSEBY);
//===============
/* DEBUG ASSERTION */ASSERT({},orderallowed,true,{})
//===============
   if(!orderallowed)return;
//===============

//===============
   if(!::PositionSelectByTicket(ticket1) || !::PositionSelectByTicket(ticket2))
     {
      //===============
      ::ResetLastError();
      //===============

      //===============
      return;
      //===============
     }
//===============

//===============
   MqlTradeRequest     closerequest;
   MqlTradeResult      closeresult;
   MqlTradeCheckResult closecheckresult;
//===============
   ::ZeroMemory(closerequest);
   ::ZeroMemory(closeresult);
   ::ZeroMemory(closecheckresult);
//===============

//===============
   const ENUM_ORDER_TYPE_FILLING filling=cTrade::GetFilling(trade1.SymbolGet());
//===============

//===============
   closerequest.action       = TRADE_ACTION_CLOSE_BY;
   closerequest.position     = ticket1;
   closerequest.position_by  = ticket2;
   closerequest.magic        = trade1.MagicGet();
   closerequest.symbol       = trade1.SymbolGet();
   closerequest.comment      = trade1.CommentGet();
   closerequest.type_filling = filling;
//===============

//===============
   const bool check=::OrderCheck(closerequest,closecheckresult);
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},check && closecheckresult.retcode==0,false,::Print(TOSTRING(closecheckresult.retcode));)
//===============

//===============
   if(check && closecheckresult.retcode==0)
     {
      //===============
      const bool send=::OrderSend(closerequest,closeresult);
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT({},send && (closeresult.deal>0 || closeresult.order>0),false,::Print(TOSTRING(closeresult.retcode));)
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============

//===============
   if(!::OrderSelect((int)ticket1,SELECT_BY_TICKET,MODE_TRADES) || ::OrderCloseTime()>0)return;
//===============

//===============
   if(::OrderType()!=OP_BUY && ::OrderType()!=OP_SELL)return;
//===============

//===============
   if(!::OrderSelect((int)ticket2,SELECT_BY_TICKET,MODE_TRADES) || ::OrderCloseTime()>0)return;
//===============

//===============
   if(::OrderType()!=OP_BUY && ::OrderType()!=OP_SELL)return;
//===============

//===============
   const bool close=::OrderCloseBy((int)ticket1,(int)ticket2,clrNONE);
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},close,false,::Print(TOSTRING(::GetLastError()));)
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static bool cTrade::DeletePendingOrder(const long ticket,uint &retcode,eError &myretcode)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const bool cantrade=cTrade::CanTrade();
//===============
/* DEBUG ASSERTION */ASSERT({},cantrade,true,{})
//===============
   if(!cantrade){myretcode=ERROR_AUTOTRADINGNOTALLOWED;return(false);}
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   if(!::OrderSelect(ticket))
     {
      //===============
      ::ResetLastError();
      //===============

      //===============
      myretcode=RETCODE_TRADENOTFOUND;
      //===============

      //===============
      return(false);
      //===============
     }
//===============

//===============
   MqlTradeRequest     deleterequest;
   MqlTradeResult      deleteresult;
   MqlTradeCheckResult deletecheckresult;
//===============
   ::ZeroMemory(deleterequest);
   ::ZeroMemory(deleteresult);
   ::ZeroMemory(deletecheckresult);
//===============

//===============
   deleterequest.action      = TRADE_ACTION_REMOVE;
   deleterequest.order       = ticket;
//===============

//===============
   const bool check=::OrderCheck(deleterequest,deletecheckresult);
//===============

//===============
   retcode=deletecheckresult.retcode;
//===============

//===============
   if(check && deletecheckresult.retcode==0)
     {
      //===============
      const bool send=::OrderSend(deleterequest,deleteresult);
      //===============

      //===============
      retcode=(deleteresult.retcode==TRADE_RETCODE_DONE?0:deleteresult.retcode);
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT({},send && deleteresult.retcode==TRADE_RETCODE_DONE,false,::Print(TOSTRING(deleteresult.retcode));)
      //===============

      //===============
      if(send && deleteresult.retcode==TRADE_RETCODE_DONE)return(true);
      //===============
     }
   else
     {
      //===============
      myretcode=RETCODE_ORDERCHECKFAILED;
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============

//===============
   if(!::OrderSelect((int)ticket,SELECT_BY_TICKET,MODE_TRADES) || ::OrderCloseTime()>0){myretcode=RETCODE_TRADENOTFOUND;return(false);}
//===============

//===============
   if(::OrderType()!=OP_BUYSTOP && ::OrderType()!=OP_SELLSTOP && ::OrderType()!=OP_BUYLIMIT && ::OrderType()!=OP_SELLLIMIT)
     {
      //===============
      myretcode=RETCODE_TRADENOTFOUND;
      //===============

      //===============
      return(false);
      //===============
     }
//===============

//===============
   ::ResetLastError();
//===============

//===============
   const bool deleteorder=::OrderDelete(OrderTicket(),clrNONE);
//===============

//===============
   retcode=::GetLastError();
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},deleteorder,false,::Print(TOSTRING(retcode));)
//===============

//===============
   return(deleteorder);
//===============

//===============
#endif 
//===============

//===============
   return(false);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::AddCurrentTrades(const cTradesFilter &filter,long &tickets[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
#ifdef __MQL5__
//===============
   const int tradesnumber=::PositionsTotal();
//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============
   const int tradesnumber=::OrdersTotal();
//===============
#endif 
//===============

//===============
   for(int i=0;i<tradesnumber && !::IsStopped();i++)
     {
      //===============
#ifdef __MQL5__
      //===============
      const long ticket=(long)::PositionGetTicket(i);
      //===============
#endif 
      //===============

      //===============
#ifdef __MQL4__
      //===============
      if(!::OrderSelect(i,SELECT_BY_POS,MODE_TRADES))continue;
      //===============
      const int ordertype=::OrderType();
      //===============
      if(ordertype!=OP_BUY && ordertype!=OP_SELL)continue;
      //===============
      const long ticket=(long)::OrderTicket();
      //===============
#endif 
      //===============

      //===============
      cTradeInfo trade;
      //===============

      //===============
      trade.Update(ticket,true,true,false);
      //===============

      //===============
      if(!filter.Passed(trade))continue;
      //===============

      //===============
      cArray::AddLast(tickets,ticket,tradesnumber);
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::AddCurrentOrders(const cPendingOrdersFilter &filter,long &tickets[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const int ordersnumber=::OrdersTotal();
//===============

//===============
   for(int i=0;i<ordersnumber && !::IsStopped();i++)
     {
      //===============
#ifdef __MQL5__
      //===============
      const long ticket=(long)::OrderGetTicket(i);
      //===============
      const ENUM_ORDER_TYPE ordertype=(ENUM_ORDER_TYPE)::OrderGetInteger(ORDER_TYPE);
      //===============
      if(ordertype!=ORDER_TYPE_BUY_STOP && ordertype!=ORDER_TYPE_BUY_LIMIT &&
         ordertype!=ORDER_TYPE_SELL_STOP && ordertype!=ORDER_TYPE_SELL_LIMIT)continue;
      //===============
#endif 
      //===============

      //===============
#ifdef __MQL4__
      //===============
      if(!::OrderSelect(i,SELECT_BY_POS,MODE_TRADES))continue;
      //===============
      const int ordertype=::OrderType();
      //===============
      if(ordertype!=OP_BUYSTOP && ordertype!=OP_BUYLIMIT && ordertype!=OP_SELLSTOP && ordertype!=OP_SELLLIMIT)continue;
      //===============
      const long ticket=(long)::OrderTicket();
      //===============
#endif 
      //===============

      //===============
      cPendingOrderInfo order;
      //===============

      //===============
      order.Update(ticket);
      //===============

      //===============
      if(!filter.Passed(order))continue;
      //===============

      //===============
      cArray::AddLast(tickets,ticket,ordersnumber);
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::AddHistoryTrades(const cTradesFilter &filter,long &tickets[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   if(!filter.SelectHistory())return;
//===============

//===============
   const int dealsnumber=::HistoryDealsTotal();
//===============

//===============
   long tmptickets[];
//===============
   cArray::Free(tmptickets);
//===============

//===============
   for(int i=0;i<dealsnumber && !::IsStopped();i++)
     {
      //===============
      const ulong dealticket=::HistoryDealGetTicket(i);
      //===============
      const ENUM_DEAL_ENTRY entrytype=(ENUM_DEAL_ENTRY)::HistoryDealGetInteger(dealticket,DEAL_ENTRY);
      //===============

      //===============
      if(entrytype!=DEAL_ENTRY_OUT && entrytype!=DEAL_ENTRY_INOUT && entrytype!=DEAL_ENTRY_OUT_BY)continue;
      //===============

      //===============
      const long positionID=::HistoryDealGetInteger(dealticket,DEAL_POSITION_ID);
      //===============

      //===============
      if(cArray::ValueExist(tmptickets,positionID))continue;
      //===============

      //===============
      cArray::AddLast(tmptickets,positionID,dealsnumber);
      //===============
     }
//===============

//===============
   const int positionssnumber=cArray::Size(tmptickets);
//===============
   for(int i=0;i<positionssnumber && !::IsStopped();i++)
     {
      //===============
      cTradeInfo trade;
      //===============

      //===============
      trade.Update(tmptickets[i],true,true,false);
      //===============

      //===============
      if(!filter.Passed(trade))continue;
      //===============

      //===============
      cArray::AddLast(tickets,tmptickets[i],positionssnumber);
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============

//===============
   const int tradesnumber=::OrdersHistoryTotal();
//===============

//===============
   for(int i=0;i<tradesnumber && !::IsStopped();i++)
     {
      //===============
      if(!::OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))continue;
      //===============

      //===============
      const int ordertype=::OrderType();
      //===============
      if(ordertype!=OP_BUY && ordertype!=OP_SELL)continue;
      //===============

      //===============
      const long ticket=(long)::OrderTicket();
      //===============

      //===============
      cTradeInfo trade;
      //===============

      //===============
      trade.Update(ticket,true,true,false);
      //===============

      //===============
      if(!filter.Passed(trade))continue;
      //===============

      //===============
      cArray::AddLast(tickets,ticket,tradesnumber);
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::AddHistoryOrders(const cPendingOrdersFilter &filter,long &tickets[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   if(!filter.SelectHistory())return;
//===============

//===============
   const int ordersnumber=::HistoryOrdersTotal();
//===============

//===============
   long tmptickets[];
//===============
   cArray::Free(tmptickets);
//===============

//===============
   for(int i=0;i<ordersnumber && !::IsStopped();i++)
     {
      //===============
      const long ticket=(long)::HistoryOrderGetTicket(i);
      //===============
      const ENUM_ORDER_TYPE ordertype=(ENUM_ORDER_TYPE)::HistoryOrderGetInteger(ticket,ORDER_TYPE);
      //===============
      if(ordertype!=ORDER_TYPE_BUY_STOP && ordertype!=ORDER_TYPE_BUY_LIMIT &&
         ordertype!=ORDER_TYPE_SELL_STOP && ordertype!=ORDER_TYPE_SELL_LIMIT)continue;
      //===============

      //===============
      cArray::AddLast(tmptickets,ticket,ordersnumber);
      //===============
     }
//===============

//===============
   const int pendingsnumber=cArray::Size(tmptickets);
//===============
   for(int i=0;i<pendingsnumber && !::IsStopped();i++)
     {
      //===============
      cPendingOrderInfo order;
      //===============

      //===============
      order.Update(tmptickets[i]);
      //===============

      //===============
      if(!filter.Passed(order))continue;
      //===============

      //===============
      cArray::AddLast(tickets,tmptickets[i],pendingsnumber);
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============

//===============
   const int ordersnumber=::OrdersHistoryTotal();
//===============

//===============
   for(int i=0;i<ordersnumber && !::IsStopped();i++)
     {
      //===============
      if(!::OrderSelect(i,SELECT_BY_POS,MODE_HISTORY))continue;
      //===============

      //===============
      const int ordertype=::OrderType();
      //===============
      if(ordertype!=OP_BUYSTOP && ordertype!=OP_BUYLIMIT && ordertype!=OP_SELLSTOP && ordertype!=OP_SELLLIMIT)continue;
      //===============

      //===============
      const long ticket=(long)::OrderTicket();
      //===============

      //===============
      cPendingOrderInfo order;
      //===============

      //===============
      order.Update(ticket);
      //===============

      //===============
      if(!filter.Passed(order))continue;
      //===============

      //===============
      cArray::AddLast(tickets,ticket,ordersnumber);
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::GetFilteredTradesTickets(const cTradesFilter &filter,long &tickets[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   cArray::Free(tickets);
//===============

//===============
   switch(filter.StatusGet())
     {
      //===============
      case  TRADESTATUS_CURRENT        :   cTrade::AddCurrentTrades(filter,tickets);                                               break;
      case  TRADESTATUS_HISTORY        :   cTrade::AddHistoryTrades(filter,tickets);                                               break;
      case  TRADESTATUS_ALL            :   cTrade::AddCurrentTrades(filter,tickets);   cTrade::AddHistoryTrades(filter,tickets);   break;
      //===============
      default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::GetFilteredPendingOrdersTickets(const cPendingOrdersFilter &filter,long &tickets[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   cArray::Free(tickets);
//===============

//===============
   switch(filter.StatusGet())
     {
      //===============
      case  ORDERSTATUS_PENDING        :   cTrade::AddCurrentOrders(filter,tickets);                                               break;
      case  ORDERSTATUS_HISTORY        :   cTrade::AddHistoryOrders(filter,tickets);                                               break;
      case  ORDERSTATUS_ALL            :   cTrade::AddCurrentOrders(filter,tickets);   cTrade::AddHistoryOrders(filter,tickets);   break;
      //===============
      default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static long cTrade::ProfitPointsGet(const eTradeType type,const double openprice,const double closeprice,const string symbol)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const double difference=(type==TRADETYPE_BUY?(closeprice-openprice):(openprice-closeprice));
//===============

//===============
   const double point=::SymbolInfoDouble(symbol,SYMBOL_POINT);
//===============

//===============
   const long result=((point!=0)?(long)(difference/point):0);
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static double cTrade::CommissionGet(const long positionID)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   double result=0.0;
//===============

//===============
#ifdef __MQL5__
//===============

//===============
   if(::HistorySelectByPosition(positionID))
     {
      //===============
      const int deals=::HistoryDealsTotal();
      //===============

      //===============  
      for(int i=0;i<deals && !::IsStopped();i++)
        {
         //===============
         const ulong ticket=::HistoryDealGetTicket(i);
         //===============

         //===============
         result+=::HistoryDealGetDouble(ticket,DEAL_COMMISSION);
         //===============
        }
      //===============
     }
//===============

//===============
#endif 
//===============

//===============
#ifdef __MQL4__
//===============
/* DEBUG ASSERTION */ASSERT({},false,true,{})
//===============
#endif 
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::CloseTrades(const long &tickets[],const bool closeby,
                                const bool slippageenabled,const long slippage)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const int size=cArray::Size(tickets);
//===============

//===============
   uint retcode       = 0;
   eError myretcode   = WRONG_VALUE;
//===============

//===============
   if(!closeby || size<=1)
     {
      //===============
      for(int i=0;i<size && !::IsStopped();i++)
        {
         //===============
         cTrade::CloseTrade(tickets[i],slippageenabled,slippage,0,retcode,myretcode);
         //===============
        }
      //===============
     }
   else
     {
      //===============
      cTrade::TradesCloseBy(tickets,slippageenabled,slippage);
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::DeletePendingOrders(const long &tickets[])
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const int size=cArray::Size(tickets);
//===============

//===============
   uint retcode       = 0;
   eError myretcode   = WRONG_VALUE;
//===============

//===============
   for(int i=0;i<size && !::IsStopped();i++)
     {
      //===============
      cTrade::DeletePendingOrder(tickets[i],retcode,myretcode);
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::ModifyTrades(const long &tickets[],const bool tightenstopsonly,
                                 const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                                 const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                                 const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const int size=cArray::Size(tickets);
//===============

//===============
   for(int i=0;i<size && !::IsStopped();i++)
     {
      //===============
      cTrade::ModifyTrade(tickets[i],tightenstopsonly,
                          slpointsenabled,slpoints,tppointsenabled,tppoints,
                          slmoneyenabled,slmoney,tpmoneyenabled,tpmoney,
                          slpriceenabled,slprice,tppriceenabled,tpprice);
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::ModifyPendingOrders(const long &tickets[],const bool priceenabled,const double price,const bool tightenstopsonly,
                                        const bool slpointsenabled,const long slpoints,const bool tppointsenabled,const long tppoints,
                                        const bool slmoneyenabled,const double slmoney,const bool tpmoneyenabled,const double tpmoney,
                                        const bool slpriceenabled,const double slprice,const bool tppriceenabled,const double tpprice,
                                        const bool expirationenabled,const datetime expiration)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const int size=cArray::Size(tickets);
//===============

//===============
   for(int i=0;i<size && !::IsStopped();i++)
     {
      //===============
      cTrade::ModifyPendingOrder(tickets[i],priceenabled,price,tightenstopsonly,
                                 slpointsenabled,slpoints,tppointsenabled,tppoints,
                                 slmoneyenabled,slmoney,tpmoneyenabled,tpmoney,
                                 slpriceenabled,slprice,tppriceenabled,tpprice,
                                 expirationenabled,expiration);
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::BreakEven(const long &tickets[],const long belevel,const long beprofit)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const int size=cArray::Size(tickets);
//===============

//===============
   for(int i=0;i<size && !::IsStopped();i++)
     {
      //===============
      cTrade::BreakEven(tickets[i],belevel,beprofit);
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
static void cTrade::TrailingStop(const long &tickets[],const long tslstart,const long tsldistance,const bool tsllevelenabled,const double tsllevel)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   const int size=cArray::Size(tickets);
//===============

//===============
   for(int i=0;i<size && !::IsStopped();i++)
     {
      //===============
      cTrade::TrailingStop(tickets[i],tslstart,tsldistance,tsllevelenabled,tsllevel);
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableParameter final
  {
   //====================
private:
   //====================
   //===============
   //===============
   cExecutable *const In;
   cObject          *OutputValue;
   //===============
   //===============
   const eElementParameter Type;
   const bool        Reversed;
   const int         Order;
   const bool        Enabled;
   //===============
   //===============
   const bool        Connected;
   //===============
   //===============
   template<typename T>
   void              Reverse(T &to)const{}
   void              Reverse(bool &to)const{if(this.Reversed)to=!to;}
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //=============== 
   template<typename T>
   void              cExecutableParameter(const eElementParameter type,const T value,const int order,const bool enabled);
   void              cExecutableParameter(const eElementParameter type,cExecutable *const in,const bool reversed,const int order,const bool enabled);
   virtual void     ~cExecutableParameter(void){if(cPointer::Valid(this.OutputValue))cPointer::Delete(this.OutputValue);}
   //===============
   //===============
   void              StartExecutionThread(void)const;
   //===============
   //===============
   eElementParameter TypeGet(void)const{return(this.Type);}
   //===============
   //===============
   bool              EnabledGet(void)const{return(this.Enabled);}
   //===============
   //===============
   int               OrderGet(void)const{return(this.Order);}
   //===============
   //===============
   template<typename T>
   bool              ValueGet(T &to)const;
   bool              ValueGet(const cExecutable *&to)const;
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutableParameter::cExecutableParameter(const eElementParameter type,cExecutable *const in,
                                                const bool reversed,const int order,const bool enabled):
                                                //===============
                                                Reversed(reversed),
                                                In(in),
                                                OutputValue(NULL),
                                                Type(type),
                                                Order(order),
                                                Enabled(enabled),
                                                Connected(true)
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
void cExecutableParameter::cExecutableParameter(const eElementParameter type,
                                                const T value,const int order,const bool enabled):
                                                //===============
                                                Reversed(false),
                                                In(NULL),
                                                Type(type),
                                                Order(order),
                                                Enabled(enabled),
                                                Connected(false)
  {
//===============
   cVariable<T>*const variable=new cVariable<T>;
//===============
   variable.Set(value);
//===============

//===============
   this.OutputValue=variable;
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutableParameter::StartExecutionThread(void)const
  {
//===============
   if(!this.Connected)return;
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(this.In),true,
                         return;)
//===============

//===============
   this.In.StartExecutionThread(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableParameter::ValueGet(const cExecutable *&to)const
  {
//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(this.In),true,{})
//===============

//===============
   if(!cPointer::Valid(this.In))return(false);
//===============

//===============
   const bool result=this.In.GetOutPutValue(to);
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
bool cExecutableParameter::ValueGet(T &to)const
  {
//===============
   if(!this.Connected)
     {
      //===============
      bool valid=false;
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT(valid=cPointer::Valid(this.OutputValue);,
                      valid,true,
                      return(false);)
      //===============

      //===============
      cVariable<T>*const variable=dynamic_cast<cVariable<T>*>(this.OutputValue);
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT(valid=cPointer::Valid(variable);,
                      valid,true,
                      return(false);)
      //===============

      //===============
      to=variable.Get();
      //===============

      //===============
      return(true);
      //===============
     }
//===============

//===============
   if(this.Connected)
     {
      //===============
      bool valid=false;
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT(valid=cPointer::Valid(this.In);,
                      valid,true,
                      return(false);)
      //===============

      //===============
      const bool result=this.In.GetOutPutValue(to);
      //===============

      //===============
      this.Reverse(to);
      //===============

      //===============
      return(result);
      //===============
     }
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},false,false,::Print(TOSTRING(cPointer::Valid(this.OutputValue)),VERTICALBAR,TOSTRING(cPointer::Valid(this.In)));)
//===============

//===============
   return(false);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutable
  {
   //====================
private:
   //====================
   //===============
   //===============
   cExecutableParameter *Parameters[];
   //===============
   //===============
   int               ParametersIndexes[];
   bool              ParametersEnabled[];
   //===============
   //===============
   bool              Triggered;
   bool              Refreshed;
   bool              Executed;
   bool              ExecutionStarted;
   //===============
   //===============
   bool              HasTrigger;
   //===============
   //===============
   int               ParameterIndexSlow(const eElementParameter parametertype)const;
   int               ParameterIndex(const eElementParameter parametertype)const;
   int               ParametersNumber(const eElementParameter parametertype)const;
   //===============
   //===============
   bool              ParameterEnabledSlow(const eElementParameter parametertype)const;
   //===============
   //===============
   void              CheckTrigger(void);
   //===============
   //===============
   virtual bool      OutPutValueGet(long &to)const{return(false);}
   virtual bool      OutPutValueGet(double &to)const{return(false);}
   virtual bool      OutPutValueGet(string &to)const{return(false);}
   virtual bool      OutPutValueGet(bool &to)const{return(false);}
   virtual bool      OutPutValueGet(datetime &to)const{return(false);}
   virtual bool      OutPutValueGet(ENUM_TIMEFRAMES &to)const{return(false);}
   virtual bool      OutPutValueGet(ENUM_MA_METHOD &to)const{return(false);}
   virtual bool      OutPutValueGet(ENUM_APPLIED_PRICE &to)const{return(false);}
   virtual bool      OutPutValueGet(eRelationType &to)const{return(false);}
   virtual bool      OutPutValueGet(eTradeType &to)const{return(false);}
   virtual bool      OutPutValueGet(ePendingOrderType &to)const{return(false);}
   virtual bool      OutPutValueGet(const cExecutable *&to)const{return(false);}
   template<typename T>
   bool              OutPutValueGet(T &to)const{return(false);}
   //===============
   //===============
   //====================
protected:
   //====================
   //===============
   //===============
   bool              ParameterEnabled(const eElementParameter parametertype)const;
   //===============
   //===============
   template<typename T>
   bool              ParameterValueGet(const eElementParameter parametertype,T &to)const;
   template<typename T>
   bool              ParameterValuesGet(const eElementParameter parametertype,T &to[])const;
   //===============
   //===============
   void              TriggeredSet(void){this.Triggered=true;}
   bool              TriggeredGet(void)const{return(this.Triggered);}
   //===============
   //===============
   virtual void      OnTrigger(void){this.TriggeredSet();}
   //===============
   //===============
   virtual bool      ReFreshState(void){if(this.Refreshed)return(false);this.Refreshed=true;return(true);}
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutable(void);
   //===============
   //===============
   virtual void     ~cExecutable(void);
   //===============
   //===============
   template<typename T>
   bool              GetOutPutValue(T &to)const;
   //===============
   //===============
   void              SortParameters(void);
   //===============
   //===============
   template<typename T>
   void              ParameterAdd(const T value,const eElementParameter type,const int parameterorder,const bool enabled);
   void              LinkAdd(cExecutable *const from,const eElementParameter type,const bool reversed,const int parameterorder,const bool enabled);
   //===============
   //===============
   void              StartExecutionThread(const bool fullcheck);
   void              ReFreshEnable(void){this.Refreshed=false;this.Triggered=false;this.Executed=false;this.ExecutionStarted=false;}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutable::cExecutable(void):Triggered(false),Refreshed(false),Executed(false),HasTrigger(false)
  {
//===============
   cArray::Free(this.Parameters);
//===============

//===============
   cArray::Free(this.ParametersIndexes);
//===============

//===============
   cArray::Free(this.ParametersEnabled);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutable::SortParameters(void)
  {
//===============
   const int size=cArray::Size(this.Parameters);
//===============

//===============
   cExecutableParameter *temp[];
//===============
   cArray::Free(temp);
//===============   
   cArray::Resize(temp,size,0);
//===============

//===============
   int indexes[];
//===============
   int orders[];
//===============
   cArray::Free(orders);
//===============   
   cArray::Resize(orders,size,0);
//===============

//===============
   for(int i=0;i<size;i++)
     {
      //===============
      if(!cPointer::Valid(this.Parameters[i]))continue;
      //===============

      //===============
      temp[i]=this.Parameters[i];
      //===============

      //===============
      orders[i]=temp[i].OrderGet();
      //===============
     }
//===============

//===============
   cArray::SortAscend(indexes,orders);
//===============

//===============
   int maxparametertype=-1;
//===============

//===============
   for(int i=0;i<size;i++)
     {
      //===============
      int index=indexes[i];
      //===============

      //===============
      if(!cPointer::Valid(temp[index]))continue;
      //===============

      //===============
      this.Parameters[i]=temp[index];
      //===============

      //===============
      const eElementParameter type=this.Parameters[i].TypeGet();
      //===============

      //===============
      if((int)type>maxparametertype)maxparametertype=(int)type;
      //===============
     }
//===============

//===============
   cArray::Resize(this.ParametersIndexes,maxparametertype+1,0);
//===============

//===============
   cArray::Resize(this.ParametersEnabled,maxparametertype+1,0);
//===============

//===============
   cArray::Initialize(this.ParametersIndexes,-1);
//===============

//===============
   cArray::Initialize(this.ParametersEnabled,false);
//===============

//===============
   for(int i=0;i<=maxparametertype;i++)
     {
      //===============
      if(this.ParametersNumber((eElementParameter)i)!=1)continue;
      //===============

      //===============
      const eElementParameter type=(eElementParameter)i;
      //===============

      //===============
      this.ParametersIndexes[i]=this.ParameterIndexSlow(type);
      //===============

      //===============
      this.ParametersEnabled[i]=this.ParameterEnabledSlow(type);
      //===============
     }
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutable::~cExecutable(void)
  {
//===============
   const int size=cArray::Size(this.Parameters);
//===============

//===============
   for(int i=0;i<size;i++)
     {
      //===============
      if(!cPointer::Valid(this.Parameters[i]))continue;
      //===============

      //===============
      cPointer::Delete(this.Parameters[i]);
      //===============
     }
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int cExecutable::ParameterIndex(const eElementParameter parametertype)const
  {
//===============
   const int position=(int)parametertype;
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},position>=0 && position<cArray::Size(this.ParametersIndexes),true,
                         ::Print(TOSTRING(position),VERTICALBAR,::EnumToString(parametertype)););
//===============

//===============
   const int index=this.ParametersIndexes[position];
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},index>=0,true,::Print(TOSTRING(index),VERTICALBAR,::EnumToString(parametertype)););
//===============

//===============
   return(index);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int cExecutable::ParameterIndexSlow(const eElementParameter parametertype)const
  {
//===============
   int index=-1;
//===============

//===============
   bool valid=false;
//===============

//===============
   const int size=cArray::Size(this.Parameters);
//===============
   for(int i=0;i<size;i++)
     {
      //===============
/* DEBUG ASSERTION */ASSERT(valid=cPointer::Valid(this.Parameters[i]);,
                      valid,false,
                      continue;)
      //===============

      //===============
      if(this.Parameters[i].TypeGet()!=parametertype)continue;
      //===============

      //===============
      index=i;
      //===============

      //===============
      break;
      //===============
     }
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},index>=0 && index<cArray::Size(this.Parameters),true,::Print(TOSTRING(index),VERTICALBAR,::EnumToString(parametertype)););
//===============

//===============
   if(index<0 || index>=cArray::Size(this.Parameters))return(-1);
//===============

//===============
/* DEBUG ASSERTION */ASSERT(valid=cPointer::Valid(this.Parameters[index]);,
                         valid,true,
                         return(-1);)
//===============

//===============
   return(index);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutable::ParameterEnabledSlow(const eElementParameter parametertype)const
  {
//===============
   int parametersnumber=0;
//===============

//===============
/* DEBUG ASSERTION */ASSERT(parametersnumber=this.ParametersNumber(parametertype);,
                         parametersnumber==1,true,
                         ::Print(TOSTRING(parametersnumber),VERTICALBAR,::EnumToString(parametertype));
                         return(false);
                         );
//===============

//===============
   const int index=this.ParameterIndex(parametertype);
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},index>=0,true,::Print(TOSTRING(index),VERTICALBAR,::EnumToString(parametertype)););
//===============

//===============
   if(index<0)return(false);
//===============

//===============
   return(this.Parameters[index].EnabledGet());
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutable::ParameterEnabled(const eElementParameter parametertype)const
  {
//===============
   const int position=(int)parametertype;
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},position>=0 && position<cArray::Size(this.ParametersIndexes),true,
                         ::Print(TOSTRING(position),VERTICALBAR,::EnumToString(parametertype)););
//===============

//===============
   const bool result=this.ParametersEnabled[position];
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
bool cExecutable::ParameterValueGet(const eElementParameter parametertype,T &to)const
  {
//===============
   int parametersnumber=0;
//===============

//===============
/* DEBUG ASSERTION */ASSERT(parametersnumber=this.ParametersNumber(parametertype);,
                         parametersnumber==1,true,
                         ::Print(TOSTRING(parametersnumber),VERTICALBAR,::EnumToString(parametertype));
                         return(false);
                         );
//===============

//===============
   const int index=this.ParameterIndex(parametertype);
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},index>=0,true,::Print(TOSTRING(index),VERTICALBAR,::EnumToString(parametertype)););
//===============

//===============
   if(index<0)return(false);
//===============

//===============
   return(this.Parameters[index].ValueGet(to));
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
bool cExecutable::ParameterValuesGet(const eElementParameter parametertype,T &to[])const
  {
//===============
   cArray::Free(to);
//===============

//===============
   bool result=true;
//===============

//===============
   const int size=cArray::Size(this.Parameters);
//===============
   for(int i=0;i<size;i++)
     {
      //===============
      bool valid=false;
      //===============

      //===============
/* DEBUG ASSERTION */ASSERT(valid=cPointer::Valid(this.Parameters[i]);,
                      valid,false,
                      continue;)
      //===============

      //===============
      if(this.Parameters[i].TypeGet()!=parametertype)continue;
      //===============

      //===============
      T value=NULL;
      //===============

      //===============
      if(!this.Parameters[i].ValueGet(value))result=false;
      //===============

      //===============
      cArray::AddLast(to,value,size);
      //===============
     }
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
bool cExecutable::GetOutPutValue(T &to)const
  {
//===============
   const bool result=this.OutPutValueGet(to);
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},result,false,{})
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
template<typename T>
void cExecutable::ParameterAdd(const T value,const eElementParameter type,const int parameterorder,const bool enabled)
  {
//===============
   if(type==ELEMENTPARAMETER_TRIGGER)this.HasTrigger=true;
//===============

//===============
   cExecutableParameter *parameter=new cExecutableParameter(type,value,parameterorder,enabled);
//===============

//===============
   cArray::AddLast(this.Parameters,parameter,0);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutable::LinkAdd(cExecutable *const from,const eElementParameter type,const bool reversed,const int parameterorder,const bool enabled)
  {
//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(from),true,::Print(::EnumToString(type));)
//===============

//===============
   if(!cPointer::Valid(from))return;
//===============

//===============
   if(type==ELEMENTPARAMETER_TRIGGER)this.HasTrigger=true;
//===============

//===============
   cExecutableParameter *parameter=new cExecutableParameter(type,from,reversed,parameterorder,enabled);
//===============

//===============
   cArray::AddLast(this.Parameters,parameter,0);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutable::StartExecutionThread(const bool fullcheck)
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(this.Executed)return;
//===============

//===============
   if(this.ExecutionStarted)return;
//===============

//===============
   this.ExecutionStarted=true;
//===============

//===============
   const int size=cArray::Size(this.Parameters);
//===============

//===============
   bool runfullthread=true;
//===============

//===============
   if(this.HasTrigger && !fullcheck)
     {
      //===============
      const int index=this.ParameterIndex(ELEMENTPARAMETER_TRIGGER);
      //===============

      //===============
      this.Parameters[index].StartExecutionThread();
      //===============

      //===============
      this.ParameterValueGet(ELEMENTPARAMETER_TRIGGER,runfullthread);
      //===============
     }
//===============

//===============
   if(runfullthread)
     {
      for(int i=0;i<size;i++)
        {
         //===============
         bool valid=false;
         //===============

         //===============
/* DEBUG ASSERTION */ASSERT(valid=cPointer::Valid(this.Parameters[i]);,
                   valid,true,
                   continue;)
         //===============

         //===============
         this.Parameters[i].StartExecutionThread();
         //===============
        }
     }
//===============

//===============
   this.ReFreshState();
//===============

//===============
   this.CheckTrigger();
//===============

//===============
   this.Executed=true;
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int cExecutable::ParametersNumber(const eElementParameter parametertype)const
  {
//===============
   int result=0;
//===============

//===============
   const int size=cArray::Size(this.Parameters);
//===============
   for(int i=0;i<size;i++)
     {
      //===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(this.Parameters[i]),false,{})
      //===============

      //===============
      if(!cPointer::Valid(this.Parameters[i]))continue;
      //===============

      //===============
      if(this.Parameters[i].TypeGet()!=parametertype)continue;
      //===============

      //===============
      result++;
      //===============
     }
//===============

//===============
   return(result);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutable::CheckTrigger(void)
  {
//===============
   if(!this.HasTrigger)return;
//===============

//===============
   if(this.TriggeredGet())return;
//===============

//===============
   bool shouldtrigger=false;
//===============

//===============
   const bool triggerget=this.ParameterValueGet(ELEMENTPARAMETER_TRIGGER,shouldtrigger);
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},triggerget,true,{})
//===============

//===============
   if(!triggerget)return;
//===============

//===============
   if(shouldtrigger)this.OnTrigger();
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableInputLongValue final : public cExecutable
  {
   //====================
private:
   //====================
   //===============
   //===============
   OUTPUTLONG
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableInputLongValue(void):OutputValue(0){}
   virtual void     ~cExecutableInputLongValue(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableInputLongValue::ReFreshState(void)override final
  {
//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   const bool get=this.ParameterValueGet(ELEMENTPARAMETER_LONGVALUE,this.OutputValue);
//===============
/* DEBUG ASSERTION */ASSERT({},get,false,{})
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableInputDoubleValue final : public cExecutable
  {
   //====================
private:
   //====================
   //===============
   //===============
   OUTPUTDOUBLE
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableInputDoubleValue(void):OutputValue(0.0){}
   virtual void     ~cExecutableInputDoubleValue(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableInputDoubleValue::ReFreshState(void)override final
  {
//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   const bool get=this.ParameterValueGet(ELEMENTPARAMETER_DOUBLEVALUE,this.OutputValue);
//===============
/* DEBUG ASSERTION */ASSERT({},get,false,{})
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableInputStringValue final : public cExecutable
  {
   //====================
private:
   //====================
   //===============
   //===============
   OUTPUTSTRING
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableInputStringValue(void):OutputValue(NULL){}
   virtual void     ~cExecutableInputStringValue(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableInputStringValue::ReFreshState(void)override final
  {
//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   const bool get=this.ParameterValueGet(ELEMENTPARAMETER_STRINGVALUE,this.OutputValue);
//===============
/* DEBUG ASSERTION */ASSERT({},get,false,{})
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableTick final : public cExecutable
  {
   //====================
private:
   //====================
   //===============
   //===============
   string            Symbol;
   MqlTick           Tick;
   //===============
   //===============
   OUTPUTPOINTER
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableTick(void):Symbol(NULL){}
   virtual void     ~cExecutableTick(void){}
   //===============
   //===============
   void              ValueGet(double &value,const eTickInfo infotype)const;
   void              ValueGet(long &value,const eTickInfo infotype)const;
   void              ValueGet(datetime &value,const eTickInfo infotype)const;
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutableTick::ValueGet(double &value,const eTickInfo infotype)const
  {
//===============
   switch(infotype)
     {
      //===============
      case  TICKINFO_BID            :   value=this.Tick.bid;                                    break;
      case  TICKINFO_ASK            :   value=this.Tick.ask;                                    break;
      case  TICKINFO_SPREADPRICE    :   value=this.Tick.ask-this.Tick.bid;                      break;
      case  TICKINFO_LAST           :   value=this.Tick.last;                                   break;
      //===============
      default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutableTick::ValueGet(long &value,const eTickInfo infotype)const
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   double point=::SymbolInfoDouble(this.Symbol,SYMBOL_POINT);
//===============

//===============
   switch(infotype)
     {
      //===============
      case  TICKINFO_SPREADPOINTS   :   if(point!=0)value=(long)::MathRound((this.Tick.ask-this.Tick.bid)/point);  break;
      case  TICKINFO_VOLUME         :   value=(long)this.Tick.volume;                                              break;
      case  TICKINFO_TIMEMSC        :   value=this.Tick.time_msc;                                                  break;
      //===============
      default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutableTick::ValueGet(datetime &value,const eTickInfo infotype)const
  {
//===============
   switch(infotype)
     {
      //===============
      case  TICKINFO_TIME           :   value=this.Tick.time;                                   break;
      //===============
      default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableTick::ReFreshState(void)override final
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   ::ZeroMemory(this.Tick);
//===============

//===============
   const bool symbolget=this.ParameterValueGet(ELEMENTPARAMETER_SYMBOLNAME,this.Symbol);
//===============
/* DEBUG ASSERTION */ASSERT({},symbolget,false,{})
//===============

//===============
   const bool tickget=::SymbolInfoTick(this.Symbol,this.Tick);
//===============
/* DEBUG ASSERTION */ASSERT({},tickget,false,{})
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableTickInfo : public cExecutable
  {
   //====================
protected:
   //====================
   //===============
   //===============
   const cExecutableTick *Tick;
   //===============
   //===============
   eTickInfo         InfoType;
   //===============
   //===============
   void              cExecutableTickInfo(void):Tick(NULL),InfoType(WRONG_VALUE){}
   //===============
   //===============
   virtual bool      ReFreshState(void)override;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   virtual void     ~cExecutableTickInfo(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableTickInfo::ReFreshState(void)override
  {
//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   const cExecutable *executable=NULL;
//===============
   const bool executableget=this.ParameterValueGet(ELEMENTPARAMETER_TICK,executable);
//===============
/* DEBUG ASSERTION */ASSERT({},executableget,false,{})
//===============

//===============
   this.Tick=dynamic_cast<const cExecutableTick *>(executable);
//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(this.Tick),false,{})
//===============

//===============
   const bool infotypeget=this.ParameterValueGet(ELEMENTPARAMETER_TICKINFO,this.InfoType);
//===============
/* DEBUG ASSERTION */ASSERT({},infotypeget,false,{})
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableTickInfoDouble final : public cExecutableTickInfo
  {
   //====================
private:
   //====================
   //===============
   //===============
   OUTPUTDOUBLE
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableTickInfoDouble(void):OutputValue(0.0){}
   virtual void     ~cExecutableTickInfoDouble(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableTickInfoDouble::ReFreshState(void)override final
  {
//===============
   if(!cExecutableTickInfo::ReFreshState())return(false);
//===============

//===============
   this.OutputValue=0;
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(this.Tick),true,{})
//===============

//===============
   if(!cPointer::Valid(this.Tick))return(false);
//===============

//===============
   this.Tick.ValueGet(this.OutputValue,this.InfoType);
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutablePriceHistory final : public cExecutable
  {
   //====================
private:
   //====================
   //===============
   //===============
   MqlRates          History[];
   //===============
   //===============
   double            HighestPrice;
   double            LowestPrice;
   long              HighestPriceBarNumber;
   long              LowestPriceBarNumber;
   //===============
   //===============
   OUTPUTPOINTER
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutablePriceHistory(void){}
   virtual void     ~cExecutablePriceHistory(void){}
   //===============
   //===============
   void              ValueGet(double &value,const ePriceHistoryInfo infotype)const;
   void              ValueGet(long &value,const ePriceHistoryInfo infotype)const;
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutablePriceHistory::ValueGet(double &value,const ePriceHistoryInfo infotype)const
  {
//===============
   switch(infotype)
     {
      //===============
      case  PRICEHISTORYINFO_HIGHESTPRICE    :   value=this.HighestPrice;    break;
      case  PRICEHISTORYINFO_LOWESTPRICE     :   value=this.LowestPrice;     break;
      //===============
      default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutablePriceHistory::ValueGet(long &value,const ePriceHistoryInfo infotype)const
  {
//===============
   switch(infotype)
     {
      //===============
      case  PRICEHISTORYINFO_HIGHESTPRICEBARNUMBER    :   value=this.HighestPriceBarNumber;    break;
      case  PRICEHISTORYINFO_LOWESTPRICEBARNUMBER     :   value=this.LowestPriceBarNumber;     break;
      //===============
      default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutablePriceHistory::ReFreshState(void)override final
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   this.HighestPrice          = 0.0;
   this.LowestPrice           = 0.0;
   this.HighestPriceBarNumber = -1;
   this.LowestPriceBarNumber  = -1;
//===============

//===============
   cArray::Free(this.History);
//===============

//===============
   string symbol=NULL;
//===============
   const bool symbolget=this.ParameterValueGet(ELEMENTPARAMETER_SYMBOLNAME,symbol);
//===============
/* DEBUG ASSERTION */ASSERT({},symbolget,false,{})
//===============

//===============
   ENUM_TIMEFRAMES timeframe=WRONG_VALUE;
//===============
   const bool timeframeget=this.ParameterValueGet(ELEMENTPARAMETER_TIMEFRAME,timeframe);
//===============
/* DEBUG ASSERTION */ASSERT({},timeframeget,false,{})
//===============

//===============
   long barfromnumber=-1;
//===============
   const bool barfromnumberget=this.ParameterValueGet(ELEMENTPARAMETER_BARFROM,barfromnumber);
//===============
/* DEBUG ASSERTION */ASSERT({},barfromnumberget,false,{})
//===============

//===============
   long bartillnumber=-1;
//===============
   const bool bartillnumberget=this.ParameterValueGet(ELEMENTPARAMETER_BARTILL,bartillnumber);
//===============
/* DEBUG ASSERTION */ASSERT({},bartillnumberget,false,{})
//===============

//===============
   ::ResetLastError();
//===============

//===============
   const int bars=(int)(barfromnumber-bartillnumber+1);
//===============
/* DEBUG ASSERTION */ASSERT({},bars>0,true,{})
//===============

//===============
   if(bars<=0)return(false);
//===============

//===============
   const int copyratesresult=::CopyRates(symbol,timeframe,(int)bartillnumber,bars,this.History);
//===============

//===============
   const int error=::GetLastError();
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},copyratesresult==bars && error==0,true,
                         ::Print(TOSTRING(copyratesresult),VERTICALBAR,TOSTRING(symbol),VERTICALBAR,
                         ::EnumToString(timeframe),VERTICALBAR,TOSTRING(error));)
//===============

//===============
   if(copyratesresult!=bars || error>0)
     {
      //===============
#ifdef __MQL4__ if(error==ERR_HISTORY_WILL_UPDATED)::Sleep(3000);#endif
      //===============

      //===============
      return(false);
      //===============
     }
//===============

//===============
   double highestprice    = DBL_MIN;
   double lowestprice     = DBL_MAX;
   long   highestpricebar = -1;
   long   lowestpricebar  = -1;
//===============

//===============
   const int size=cArray::Size(this.History);
//===============
   for(int i=size-1;i>=0;i--)
     {
      //===============
      if(this.History[i].high>highestprice)
        {
         //===============
         highestprice=this.History[i].high;
         //===============
         highestpricebar=(size-1-i)+bartillnumber;
         //===============
        }
      //===============

      //===============
      if(this.History[i].low<lowestprice)
        {
         //===============
         lowestprice=this.History[i].low;
         //===============
         lowestpricebar=(size-1-i)+bartillnumber;
         //===============
        }
      //===============
     }
//===============

//===============
   if(size>0)
     {
      //===============
      this.HighestPrice          = highestprice;
      this.LowestPrice           = lowestprice;
      this.HighestPriceBarNumber = highestpricebar;
      this.LowestPriceBarNumber  = lowestpricebar;
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutablePriceHistoryInfo : public cExecutable
  {
   //====================
protected:
   //====================
   //===============
   //===============
   const cExecutablePriceHistory *History;
   //===============
   //===============
   ePriceHistoryInfo InfoType;
   //===============
   //===============
   void              cExecutablePriceHistoryInfo(void):History(NULL),InfoType(WRONG_VALUE){}
   //===============
   //===============
   virtual bool      ReFreshState(void)override;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   virtual void     ~cExecutablePriceHistoryInfo(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutablePriceHistoryInfo::ReFreshState(void)override
  {
//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   const cExecutable *executable=NULL;
//===============
   const bool executableget=this.ParameterValueGet(ELEMENTPARAMETER_PRICEHISTORY,executable);
//===============
/* DEBUG ASSERTION */ASSERT({},executableget,false,{})
//===============

//===============
   this.History=dynamic_cast<const cExecutablePriceHistory *>(executable);
//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(this.History),false,{})
//===============

//===============
   const bool infotypeget=this.ParameterValueGet(ELEMENTPARAMETER_PRICEHISTORYINFO,this.InfoType);
//===============
/* DEBUG ASSERTION */ASSERT({},infotypeget,false,{})
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutablePriceHistoryInfoDouble final : public cExecutablePriceHistoryInfo
  {
   //====================
private:
   //====================
   //===============
   //===============
   OUTPUTDOUBLE
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutablePriceHistoryInfoDouble(void):OutputValue(0.0){}
   virtual void     ~cExecutablePriceHistoryInfoDouble(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutablePriceHistoryInfoDouble::ReFreshState(void)override final
  {
//===============
   if(!cExecutablePriceHistoryInfo::ReFreshState())return(false);
//===============

//===============
   this.OutputValue=0;
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(this.History),true,{})
//===============

//===============
   if(!cPointer::Valid(this.History))return(false);
//===============

//===============
   this.History.ValueGet(this.OutputValue,this.InfoType);
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableOpen : public cExecutable
  {
   //====================
protected:
   //====================
   //===============
   //===============
   string            Symbol;
   double            Lots;
   long              Magic;
   string            Comment;
   long              SLPoints;
   bool              SLPointsEnabled;
   double            SLPrice;
   bool              SLPriceEnabled;
   double            SLMoney;
   bool              SLMoneyEnabled;
   long              TPPoints;
   bool              TPPointsEnabled;
   double            TPPrice;
   bool              TPPriceEnabled;
   double            TPMoney;
   bool              TPMoneyEnabled;
   //===============
   //===============
   void              cExecutableOpen(void){}
   //===============
   //===============
   virtual bool      ReFreshState(void)override;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   virtual void     ~cExecutableOpen(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableOpen::ReFreshState(void)override
  {
//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   this.Symbol          = NULL;
   this.Lots            = 0.0;
   this.Magic           = -1;
   this.Comment         = NULL;
   this.SLPoints        = 0;
   this.SLPointsEnabled = false;
   this.SLPrice         = 0.0;
   this.SLPriceEnabled  = false;
   this.SLMoney         = 0.0;
   this.SLMoneyEnabled  = false;
   this.TPPoints        = 0;
   this.TPPointsEnabled = false;
   this.TPPrice         = 0.0;
   this.TPPriceEnabled  = false;
   this.TPMoney         = 0.0;
   this.TPMoneyEnabled  = false;
//===============

//===============
   const bool symbolget=this.ParameterValueGet(ELEMENTPARAMETER_SYMBOLNAME,this.Symbol);
//===============
/* DEBUG ASSERTION */ASSERT({},symbolget,false,{})
//===============

//===============
   const bool lotsget=this.ParameterValueGet(ELEMENTPARAMETER_LOTS,this.Lots);
//===============
/* DEBUG ASSERTION */ASSERT({},lotsget,false,{})
//===============

//===============
   const bool magicget=this.ParameterValueGet(ELEMENTPARAMETER_MAGIC,this.Magic);
//===============
/* DEBUG ASSERTION */ASSERT({},magicget,false,{})
//===============

//===============
   const bool commentget=this.ParameterValueGet(ELEMENTPARAMETER_COMMENT,this.Comment);
//===============
/* DEBUG ASSERTION */ASSERT({},commentget,false,{})
//===============

//===============
   const bool slpointsget=this.ParameterValueGet(ELEMENTPARAMETER_STOPLOSSPOINTS,this.SLPoints);
//===============
/* DEBUG ASSERTION */ASSERT({},slpointsget,false,{})
//===============
   this.SLPointsEnabled=this.ParameterEnabled(ELEMENTPARAMETER_STOPLOSSPOINTS);
//===============

//===============
   const bool slpriceget=this.ParameterValueGet(ELEMENTPARAMETER_STOPLOSSPRICE,this.SLPrice);
//===============
/* DEBUG ASSERTION */ASSERT({},slpriceget,false,{})
//===============
   this.SLPriceEnabled=this.ParameterEnabled(ELEMENTPARAMETER_STOPLOSSPRICE);
//===============

//===============
   const bool slmoneyget=this.ParameterValueGet(ELEMENTPARAMETER_STOPLOSSMONEY,this.SLMoney);
//===============
/* DEBUG ASSERTION */ASSERT({},slmoneyget,false,{})
//===============
   this.SLMoneyEnabled=this.ParameterEnabled(ELEMENTPARAMETER_STOPLOSSMONEY);
//===============

//===============
   const bool tppointsget=this.ParameterValueGet(ELEMENTPARAMETER_TAKEPROFITPOINTS,this.TPPoints);
//===============
/* DEBUG ASSERTION */ASSERT({},tppointsget,false,{})
//===============
   this.TPPointsEnabled=this.ParameterEnabled(ELEMENTPARAMETER_TAKEPROFITPOINTS);
//===============

//===============
   const bool tppriceget=this.ParameterValueGet(ELEMENTPARAMETER_TAKEPROFITPRICE,this.TPPrice);
//===============
/* DEBUG ASSERTION */ASSERT({},tppriceget,false,{})
//===============
   this.TPPriceEnabled=this.ParameterEnabled(ELEMENTPARAMETER_TAKEPROFITPRICE);
//===============

//===============
   const bool tpmoneyget=this.ParameterValueGet(ELEMENTPARAMETER_TAKEPROFITMONEY,this.TPMoney);
//===============
/* DEBUG ASSERTION */ASSERT({},tpmoneyget,false,{})
//===============
   this.TPMoneyEnabled=this.ParameterEnabled(ELEMENTPARAMETER_TAKEPROFITMONEY);
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableOpenTrade final : public cExecutableOpen
  {
   //====================
private:
   //====================
   //===============
   //===============
   OUTPUTNONE
   //===============
   //===============
   eTradeType        Type;
   long              Slippage;
   bool              SlippageEnabled;
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableOpenTrade(void){}
   virtual void     ~cExecutableOpenTrade(void){}
   //===============
   //===============
   virtual void      OnTrigger(void)override final;
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutableOpenTrade::OnTrigger(void)override final
  {
//===============
   uint retcode       = 0;
   eError myretcode   = WRONG_VALUE;
//===============

//===============
   cTrade::OpenTrade(this.Symbol,this.Type,this.Lots,this.Magic,this.Comment,
                     this.SLPointsEnabled,this.SLPoints,this.TPPointsEnabled,this.TPPoints,
                     this.SLMoneyEnabled,this.SLMoney,this.TPMoneyEnabled,this.TPMoney,
                     this.SLPriceEnabled,this.SLPrice,this.TPPriceEnabled,this.TPPrice,
                     this.SlippageEnabled,this.Slippage,true,retcode,myretcode);
//===============

//===============
   cExecutableOpen::OnTrigger();
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableOpenTrade::ReFreshState(void)override final
  {
//===============
   if(!cExecutableOpen::ReFreshState())return(false);
//===============

//===============
   this.Type            = WRONG_VALUE;
   this.Slippage        = 0;
   this.SlippageEnabled = false;
//===============

//===============
   const bool typeget=this.ParameterValueGet(ELEMENTPARAMETER_TRADETYPE,this.Type);
//===============
/* DEBUG ASSERTION */ASSERT({},typeget,false,{})
//===============

//===============
   const bool slippageget=this.ParameterValueGet(ELEMENTPARAMETER_SLIPPAGE,this.Slippage);
//===============
/* DEBUG ASSERTION */ASSERT({},slippageget,false,{})
//===============
   this.SlippageEnabled=this.ParameterEnabled(ELEMENTPARAMETER_SLIPPAGE);
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableModify : public cExecutable
  {
   //====================
protected:
   //====================
   //===============
   //===============
   bool              TightenStopsOnly;
   long              SLPoints;
   bool              SLPointsEnabled;
   double            SLPrice;
   bool              SLPriceEnabled;
   double            SLMoney;
   bool              SLMoneyEnabled;
   long              TPPoints;
   bool              TPPointsEnabled;
   double            TPPrice;
   bool              TPPriceEnabled;
   double            TPMoney;
   bool              TPMoneyEnabled;
   //===============
   //===============
   void              cExecutableModify(void){}
   //===============
   //===============
   virtual bool      ReFreshState(void)override;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   virtual void     ~cExecutableModify(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableModify::ReFreshState(void)override
  {
//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   this.TightenStopsOnly = false;
   this.SLPoints         = 0;
   this.SLPointsEnabled  = false;
   this.SLPrice          = 0.0;
   this.SLPriceEnabled   = false;
   this.SLMoney          = 0.0;
   this.SLMoneyEnabled   = false;
   this.TPPoints         = 0;
   this.TPPointsEnabled  = false;
   this.TPPrice          = 0.0;
   this.TPPriceEnabled   = false;
   this.TPMoney          = 0.0;
   this.TPMoneyEnabled   = false;
//===============

//===============
   const bool tightenonlyget=this.ParameterValueGet(ELEMENTPARAMETER_TIGHTENSTOPSONLY,this.TightenStopsOnly);
//===============
/* DEBUG ASSERTION */ASSERT({},tightenonlyget,false,{})
//===============

//===============
   const bool slpointsget=this.ParameterValueGet(ELEMENTPARAMETER_STOPLOSSPOINTS,this.SLPoints);
//===============
/* DEBUG ASSERTION */ASSERT({},slpointsget,false,{})
//===============
   this.SLPointsEnabled=this.ParameterEnabled(ELEMENTPARAMETER_STOPLOSSPOINTS);
//===============

//===============
   const bool slpriceget=this.ParameterValueGet(ELEMENTPARAMETER_STOPLOSSPRICE,this.SLPrice);
//===============
/* DEBUG ASSERTION */ASSERT({},slpriceget,false,{})
//===============
   this.SLPriceEnabled=this.ParameterEnabled(ELEMENTPARAMETER_STOPLOSSPRICE);
//===============

//===============
   const bool slmoneyget=this.ParameterValueGet(ELEMENTPARAMETER_STOPLOSSMONEY,this.SLMoney);
//===============
/* DEBUG ASSERTION */ASSERT({},slmoneyget,false,{})
//===============
   this.SLMoneyEnabled=this.ParameterEnabled(ELEMENTPARAMETER_STOPLOSSMONEY);
//===============

//===============
   const bool tppointsget=this.ParameterValueGet(ELEMENTPARAMETER_TAKEPROFITPOINTS,this.TPPoints);
//===============
/* DEBUG ASSERTION */ASSERT({},tppointsget,false,{})
//===============
   this.TPPointsEnabled=this.ParameterEnabled(ELEMENTPARAMETER_TAKEPROFITPOINTS);
//===============

//===============
   const bool tppriceget=this.ParameterValueGet(ELEMENTPARAMETER_TAKEPROFITPRICE,this.TPPrice);
//===============
/* DEBUG ASSERTION */ASSERT({},tppriceget,false,{})
//===============
   this.TPPriceEnabled=this.ParameterEnabled(ELEMENTPARAMETER_TAKEPROFITPRICE);
//===============

//===============
   const bool tpmoneyget=this.ParameterValueGet(ELEMENTPARAMETER_TAKEPROFITMONEY,this.TPMoney);
//===============
/* DEBUG ASSERTION */ASSERT({},tpmoneyget,false,{})
//===============
   this.TPMoneyEnabled=this.ParameterEnabled(ELEMENTPARAMETER_TAKEPROFITMONEY);
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableModifyCurrent : public cExecutableModify
  {
   //====================
protected:
   //====================
   //===============
   //===============
   void              cExecutableModifyCurrent(void){}
   //===============
   //===============
   virtual bool      ReFreshState(void)override;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   virtual void     ~cExecutableModifyCurrent(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableModifyCurrent::ReFreshState(void)override
  {
//===============
   if(!cExecutableModify::ReFreshState())return(false);
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableModifyPending : public cExecutableModify
  {
   //====================
protected:
   //====================
   //===============
   //===============
   double            Price;
   bool              PriceEnabled;
   datetime          Expiration;
   bool              ExpirationEnabled;
   //===============
   //===============
   void              cExecutableModifyPending(void){}
   //===============
   //===============
   virtual bool      ReFreshState(void)override;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   virtual void     ~cExecutableModifyPending(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableModifyPending::ReFreshState(void)override
  {
//===============
   if(!cExecutableModify::ReFreshState())return(false);
//===============

//===============
   this.Price             = 0;
   this.PriceEnabled      = false;
   this.Expiration        = 0;
   this.ExpirationEnabled = false;
//===============

//===============
   const bool priceget=this.ParameterValueGet(ELEMENTPARAMETER_ORDERPRICE,this.Price);
//===============
/* DEBUG ASSERTION */ASSERT({},priceget,false,{})
//===============
   this.PriceEnabled=this.ParameterEnabled(ELEMENTPARAMETER_ORDERPRICE);
//===============

//===============
   const bool expirationget=this.ParameterValueGet(ELEMENTPARAMETER_EXPIRATION,this.Expiration);
//===============
/* DEBUG ASSERTION */ASSERT({},expirationget,false,{})
//===============
   this.ExpirationEnabled=this.ParameterEnabled(ELEMENTPARAMETER_EXPIRATION);
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableModifyTradesGroup final : public cExecutableModifyCurrent
  {
   //====================
private:
   //====================
   //===============
   //===============
   OUTPUTNONE
   //===============
   //===============
   long              Tickets[];
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableModifyTradesGroup(void){cArray::Free(this.Tickets);}
   virtual void     ~cExecutableModifyTradesGroup(void){}
   //===============
   //===============
   virtual void      OnTrigger(void)override final;
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutableModifyTradesGroup::OnTrigger(void)override final
  {
//===============
   cTrade::ModifyTrades(this.Tickets,this.TightenStopsOnly,
                        this.SLPointsEnabled,this.SLPoints,this.TPPointsEnabled,this.TPPoints,
                        this.SLMoneyEnabled,this.SLMoney,this.TPMoneyEnabled,this.TPMoney,
                        this.SLPriceEnabled,this.SLPrice,this.TPPriceEnabled,this.TPPrice);
//===============

//===============
   cExecutableModifyCurrent::OnTrigger();
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableModifyTradesGroup::ReFreshState(void)override final
  {
//===============
   if(!cExecutableModifyCurrent::ReFreshState())return(false);
//===============

//===============
   const cExecutable *executable=NULL;
//===============
   const bool executableget=this.ParameterValueGet(ELEMENTPARAMETER_TRADESGROUP,executable);
//===============
/* DEBUG ASSERTION */ASSERT({},executableget,false,{})
//===============

//===============
   const cExecutableTrades *const trades=dynamic_cast<const cExecutableTrades *>(executable);
//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(trades),true,{})
//===============
   if(!cPointer::Valid(trades))return(true);
//===============

//===============
   cArray::Free(this.Tickets);
//===============
   trades.AddTicketsToArray(this.Tickets);
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableTrades : public cExecutable
  {
   //====================
private:
   //====================
   //===============
   //===============
   OUTPUTPOINTER
   //===============
   //===============
   cTradesGroupInfo  TradesInfo;
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   virtual void      UpdateTicketsArray(void)=NULL;
   //===============
   //===============
   //====================
protected:
   //====================
   //===============
   //===============
   long              Tickets[];
   //===============
   //===============  
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableTrades(void){}
   virtual void     ~cExecutableTrades(void){}
   //===============
   //===============
   void              ValueGet(double &value,const eTradesGroupInfo infotype)const;
   void              ValueGet(long &value,const eTradesGroupInfo infotype)const;
   //===============
   //===============
   void              AddTicketsToArray(long &array[])const;
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutableTrades::AddTicketsToArray(long &array[])const
  {
//===============
   const int size=cArray::Size(this.Tickets);
//===============
   const int reserve=cArray::Size(array)+size;
//===============
   for(int i=0;i<size;i++)
     {
      //===============
      if(cArray::ValueExist(array,this.Tickets[i]))continue;
      //===============

      //===============
      cArray::AddLast(array,this.Tickets[i],reserve);
      //===============
     }
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableTrades::ReFreshState(void)override final
  {
//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   cArray::Free(this.Tickets);
//===============

//===============
   this.UpdateTicketsArray();
//===============

//===============
   this.TradesInfo.Update(this.Tickets);
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutableTrades::ValueGet(double &value,const eTradesGroupInfo infotype)const
  {
//===============
   switch(infotype)
     {
      //===============
      case  TRADESGROUPINFO_PROFITMONEY       :   value=this.TradesInfo.ProfitMoneyGet();                                     break;
      case  TRADESGROUPINFO_TOTALLOTS         :   value=this.TradesInfo.TotalLotsGet();                                       break;
      case  TRADESGROUPINFO_AVERAGEPRICE      :   value=this.TradesInfo.AveragePriceGet();                                    break;
      //===============
      default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutableTrades::ValueGet(long &value,const eTradesGroupInfo infotype)const
  {
//===============
   switch(infotype)
     {
      //===============
      case  TRADESGROUPINFO_TRADESNUMBER                    :   value=this.TradesInfo.ItemsNumberGet();                       break;
      case  TRADESGROUPINFO_PROFITPOINTS                    :   value=this.TradesInfo.ProfitPointsGet();                      break;
      case  TRADESGROUPINFO_MAXLOTTRADETICKET               :   value=this.TradesInfo.MaxLotsTicketGet();                     break;
      case  TRADESGROUPINFO_MINLOTTRADETICKET               :   value=this.TradesInfo.MinLotsTicketGet();                     break;
      case  TRADESGROUPINFO_MAXPROFITMONEYTRADETICKET       :   value=this.TradesInfo.MaxProfitMoneyTicketGet();              break;
      case  TRADESGROUPINFO_MINPROFITMONEYTRADETICKET       :   value=this.TradesInfo.MinProfitMoneyTicketGet();              break;
      case  TRADESGROUPINFO_MAXPROFITPOINTSTRADETICKET      :   value=this.TradesInfo.MaxProfitPointsTicketGet();             break;
      case  TRADESGROUPINFO_MINPROFITPOINTSTRADETICKET      :   value=this.TradesInfo.MinProfitPointsTicketGet();             break;
      case  TRADESGROUPINFO_LOWESTOPENPRICETRADETICKET      :   value=this.TradesInfo.LowestOpenPriceTicketGet();             break;
      case  TRADESGROUPINFO_HIGHESTOPENPRICETRADETICKET     :   value=this.TradesInfo.HighestOpenPriceTicketGet();            break;
      case  TRADESGROUPINFO_LOWESTCLOSEPRICETRADETICKET     :   value=this.TradesInfo.LowestClosePriceTicketGet();            break;
      case  TRADESGROUPINFO_HIGHESTCLOSEPRICETRADETICKET    :   value=this.TradesInfo.HighestClosePriceTicketGet();           break;
      case  TRADESGROUPINFO_EARLIESTOPENTIMETRADETICKET     :   value=this.TradesInfo.EarliestOpenTimeTicketGet();            break;
      case  TRADESGROUPINFO_LATESTOPENTIMETRADETICKET       :   value=this.TradesInfo.LatestOpenTimeTicketGet();              break;
      case  TRADESGROUPINFO_EARLIESTCLOSETIMETRADETICKET    :   value=this.TradesInfo.EarliestCloseTimeTicketGet();           break;
      case  TRADESGROUPINFO_LATESTCLOSETIMETRADETICKET      :   value=this.TradesInfo.LatestCloseTimeTicketGet();             break;
      case  TRADESGROUPINFO_SYMBOLSNUMBER                   :   value=this.TradesInfo.SymbolsNumberGet();                     break;
      //===============
      default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableTradesGroup final : public cExecutableTrades
  {
   //====================
private:
   //====================
   //===============
   //===============
   virtual void      UpdateTicketsArray(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableTradesGroup(void){}
   virtual void     ~cExecutableTradesGroup(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutableTradesGroup::UpdateTicketsArray(void)override final
  {
//===============
   cTradesFilter filter;
//===============

//===============
   eTradeStatus status=WRONG_VALUE;
//===============
   const bool statusget=this.ParameterValueGet(ELEMENTPARAMETER_TRADESTATUS,status);
//===============
/* DEBUG ASSERTION */ASSERT({},statusget,false,{})
//===============
   filter.StatusSet(status);
//===============

//===============
   const bool magicenabled=this.ParameterEnabled(ELEMENTPARAMETER_MAGIC);
//===============
   if(magicenabled)
     {
      //===============
      long magic=-1;
      //===============
      const bool magicget=this.ParameterValueGet(ELEMENTPARAMETER_MAGIC,magic);
      //===============
/* DEBUG ASSERTION */ASSERT({},magicget,false,{})
      //===============
      filter.FilterByMagicSet(magicenabled);
      //===============
      filter.MagicSet(magic);
      //===============
     }
//===============

//===============
   const bool symbolenabled=this.ParameterEnabled(ELEMENTPARAMETER_SYMBOLNAME);
//===============
   if(symbolenabled)
     {
      //===============
      string symbol=NULL;
      //===============
      const bool symbolget=this.ParameterValueGet(ELEMENTPARAMETER_SYMBOLNAME,symbol);
      //===============
/* DEBUG ASSERTION */ASSERT({},symbolget,false,{})
      //===============
      filter.FilterBySymbolSet(symbolenabled);
      //===============
      filter.SymbolSet(symbol);
      //===============
     }
//===============

//===============
   const bool typeenabled=this.ParameterEnabled(ELEMENTPARAMETER_TRADETYPE);
//===============
   if(typeenabled)
     {
      //===============
      eTradeType type=WRONG_VALUE;
      //===============
      const bool typeget=this.ParameterValueGet(ELEMENTPARAMETER_TRADETYPE,type);
      //===============
/* DEBUG ASSERTION */ASSERT({},typeget,false,{})
      //===============
      filter.FilterByTypeSet(typeenabled);
      //===============
      filter.TypeSet(type);
      //===============
     }
//===============

//===============
   const bool ticketgreaterenabled=this.ParameterEnabled(ELEMENTPARAMETER_TICKETGREATEROREQUALTHAN);
//===============
   if(ticketgreaterenabled)
     {
      //===============
      long ticketgreater=-1;
      //===============
      const bool ticketgreaterget=this.ParameterValueGet(ELEMENTPARAMETER_TICKETGREATEROREQUALTHAN,ticketgreater);
      //===============
/* DEBUG ASSERTION */ASSERT({},ticketgreaterget,false,{})
      //===============
      filter.FilterByTicketGreaterSet(ticketgreaterenabled);
      //===============
      filter.TicketGreaterSet(ticketgreater);
      //===============
     }
//===============

//===============
   const bool ticketlessenabled=this.ParameterEnabled(ELEMENTPARAMETER_TICKETLESSOREQUALTHAN);
//===============
   if(ticketlessenabled)
     {
      //===============
      long ticketless=-1;
      //===============
      const bool ticketlessget=this.ParameterValueGet(ELEMENTPARAMETER_TICKETLESSOREQUALTHAN,ticketless);
      //===============
/* DEBUG ASSERTION */ASSERT({},ticketlessget,false,{})
      //===============
      filter.FilterByTicketLessSet(ticketlessenabled);
      //===============
      filter.TicketLessSet(ticketless);
      //===============
     }
//===============

//===============
   const bool opentimegreaterenabled=this.ParameterEnabled(ELEMENTPARAMETER_OPENTIMEGREATEROREQUALTHAN);
//===============
   if(opentimegreaterenabled)
     {
      //===============
      datetime opentimegreater=0;
      //===============
      const bool opentimegreaterget=this.ParameterValueGet(ELEMENTPARAMETER_OPENTIMEGREATEROREQUALTHAN,opentimegreater);
      //===============
/* DEBUG ASSERTION */ASSERT({},opentimegreaterget,false,{})
      //===============
      filter.FilterByOpenTimeGreaterSet(opentimegreaterenabled);
      //===============
      filter.OpenTimeGreaterSet(opentimegreater);
      //===============
     }
//===============

//===============
   const bool opentimelessenabled=this.ParameterEnabled(ELEMENTPARAMETER_OPENTIMELESSOREQUALTHAN);
//===============
   if(opentimelessenabled)
     {
      //===============
      datetime opentimeless=0;
      //===============
      const bool opentimelessget=this.ParameterValueGet(ELEMENTPARAMETER_OPENTIMELESSOREQUALTHAN,opentimeless);
      //===============
/* DEBUG ASSERTION */ASSERT({},opentimelessget,false,{})
      //===============
      filter.FilterByOpenTimeLessSet(opentimelessenabled);
      //===============
      filter.OpenTimeLessSet(opentimeless);
      //===============
     }
//===============

//===============
   const bool closetimegreaterenabled=this.ParameterEnabled(ELEMENTPARAMETER_CLOSETIMEGREATEROREQUALTHAN);
//===============
   if(closetimegreaterenabled)
     {
      //===============
      datetime closetimegreater=0;
      //===============
      const bool closetimegreaterget=this.ParameterValueGet(ELEMENTPARAMETER_CLOSETIMEGREATEROREQUALTHAN,closetimegreater);
      //===============
/* DEBUG ASSERTION */ASSERT({},closetimegreaterget,false,{})
      //===============
      filter.FilterByCloseTimeGreaterSet(closetimegreaterenabled);
      //===============
      filter.CloseTimeGreaterSet(closetimegreater);
      //===============
     }
//===============

//===============
   const bool closetimelessenabled=this.ParameterEnabled(ELEMENTPARAMETER_CLOSETIMELESSOREQUALTHAN);
//===============
   if(closetimelessenabled)
     {
      //===============
      datetime closetimeless=0;
      //===============
      const bool closetimelessget=this.ParameterValueGet(ELEMENTPARAMETER_CLOSETIMELESSOREQUALTHAN,closetimeless);
      //===============
/* DEBUG ASSERTION */ASSERT({},closetimelessget,false,{})
      //===============
      filter.FilterByCloseTimeLessSet(closetimelessenabled);
      //===============
      filter.CloseTimeLessSet(closetimeless);
      //===============
     }
//===============

//===============
   const bool profitgreaterenabled=this.ParameterEnabled(ELEMENTPARAMETER_PROFITGREATEROREQUALTHAN);
//===============
   if(profitgreaterenabled)
     {
      //===============
      double profitgreater=0;
      //===============
      const bool profitgreaterget=this.ParameterValueGet(ELEMENTPARAMETER_PROFITGREATEROREQUALTHAN,profitgreater);
      //===============
/* DEBUG ASSERTION */ASSERT({},profitgreaterget,false,{})
      //===============
      filter.FilterByProfitGreaterSet(profitgreaterenabled);
      //===============
      filter.ProfitGreaterSet(profitgreater);
      //===============
     }
//===============

//===============
   const bool profitlessenabled=this.ParameterEnabled(ELEMENTPARAMETER_PROFITLESSOREQUALTHAN);
//===============
   if(profitlessenabled)
     {
      //===============
      double profitless=0;
      //===============
      const bool profitlessget=this.ParameterValueGet(ELEMENTPARAMETER_PROFITLESSOREQUALTHAN,profitless);
      //===============
/* DEBUG ASSERTION */ASSERT({},profitlessget,false,{})
      //===============
      filter.FilterByProfitLessSet(profitlessenabled);
      //===============
      filter.ProfitLessSet(profitless);
      //===============
     }
//===============

//===============
   const bool exactcommentenabled=this.ParameterEnabled(ELEMENTPARAMETER_EXACTCOMMENT);
//===============
   if(exactcommentenabled)
     {
      //===============
      string exactcomment=NULL;
      //===============
      const bool exactcommentget=this.ParameterValueGet(ELEMENTPARAMETER_EXACTCOMMENT,exactcomment);
      //===============
/* DEBUG ASSERTION */ASSERT({},exactcommentget,false,{})
      //===============
      filter.FilterByExactCommentSet(exactcommentenabled);
      //===============
      filter.ExactCommentSet(exactcomment);
      //===============
     }
//===============

//===============
   const bool commentpartialenabled=this.ParameterEnabled(ELEMENTPARAMETER_COMMENTPARTIAL);
//===============
   if(commentpartialenabled)
     {
      //===============
      string commentpartial=NULL;
      //===============
      const bool commentpartialget=this.ParameterValueGet(ELEMENTPARAMETER_COMMENTPARTIAL,commentpartial);
      //===============
/* DEBUG ASSERTION */ASSERT({},commentpartialget,false,{})
      //===============
      filter.FilterByCommentPartialSet(commentpartialenabled);
      //===============
      filter.CommentPartialSet(commentpartial);
      //===============
     }
//===============

//===============
   const bool openpricegreaterenabled=this.ParameterEnabled(ELEMENTPARAMETER_OPENPRICEGREATEROREQUALTHAN);
//===============
   if(openpricegreaterenabled)
     {
      //===============
      double openpricegreater=0;
      //===============
      const bool openpricegreaterget=this.ParameterValueGet(ELEMENTPARAMETER_OPENPRICEGREATEROREQUALTHAN,openpricegreater);
      //===============
/* DEBUG ASSERTION */ASSERT({},openpricegreaterget,false,{})
      //===============
      filter.FilterByOpenPriceGreaterSet(openpricegreaterenabled);
      //===============
      filter.OpenPriceGreaterSet(openpricegreater);
      //===============
     }
//===============

//===============
   const bool openpricelessenabled=this.ParameterEnabled(ELEMENTPARAMETER_OPENPRICELESSOREQUALTHAN);
//===============
   if(openpricelessenabled)
     {
      //===============
      double openpriceless=0;
      //===============
      const bool openpricelessget=this.ParameterValueGet(ELEMENTPARAMETER_OPENPRICELESSOREQUALTHAN,openpriceless);
      //===============
/* DEBUG ASSERTION */ASSERT({},openpricelessget,false,{})
      //===============
      filter.FilterByOpenPriceLessSet(openpricelessenabled);
      //===============
      filter.OpenPriceLessSet(openpriceless);
      //===============
     }
//===============

//===============
   const bool closepricegreaterenabled=this.ParameterEnabled(ELEMENTPARAMETER_CLOSEPRICEGREATEROREQUALTHAN);
//===============
   if(closepricegreaterenabled)
     {
      //===============
      double closepricegreater=0;
      //===============
      const bool closepricegreaterget=this.ParameterValueGet(ELEMENTPARAMETER_CLOSEPRICEGREATEROREQUALTHAN,closepricegreater);
      //===============
/* DEBUG ASSERTION */ASSERT({},closepricegreaterget,false,{})
      //===============
      filter.FilterByClosePriceGreaterSet(closepricegreaterenabled);
      //===============
      filter.ClosePriceGreaterSet(closepricegreater);
      //===============
     }
//===============

//===============
   const bool closepricelessenabled=this.ParameterEnabled(ELEMENTPARAMETER_CLOSEPRICELESSOREQUALTHAN);
//===============
   if(closepricelessenabled)
     {
      //===============
      double closepriceless=0;
      //===============
      const bool closepricelessget=this.ParameterValueGet(ELEMENTPARAMETER_CLOSEPRICELESSOREQUALTHAN,closepriceless);
      //===============
/* DEBUG ASSERTION */ASSERT({},closepricelessget,false,{})
      //===============
      filter.FilterByClosePriceLessSet(closepricelessenabled);
      //===============
      filter.ClosePriceLessSet(closepriceless);
      //===============
     }
//===============

//===============
   const bool lotsgreaterenabled=this.ParameterEnabled(ELEMENTPARAMETER_LOTSGREATEROREQUALTHAN);
//===============
   if(lotsgreaterenabled)
     {
      //===============
      double lotsgreater=0;
      //===============
      const bool lotsgreaterget=this.ParameterValueGet(ELEMENTPARAMETER_LOTSGREATEROREQUALTHAN,lotsgreater);
      //===============
/* DEBUG ASSERTION */ASSERT({},lotsgreaterget,false,{})
      //===============
      filter.FilterByLotsGreaterSet(lotsgreaterenabled);
      //===============
      filter.LotsGreaterSet(lotsgreater);
      //===============
     }
//===============

//===============
   const bool lotslessenabled=this.ParameterEnabled(ELEMENTPARAMETER_LOTSLESSOREQUALTHAN);
//===============
   if(lotslessenabled)
     {
      //===============
      double lotsless=0;
      //===============
      const bool lotslessget=this.ParameterValueGet(ELEMENTPARAMETER_LOTSLESSOREQUALTHAN,lotsless);
      //===============
/* DEBUG ASSERTION */ASSERT({},lotslessget,false,{})
      //===============
      filter.FilterByLotsLessSet(lotslessenabled);
      //===============
      filter.LotsLessSet(lotsless);
      //===============
     }
//===============

//===============
   cTrade::GetFilteredTradesTickets(filter,this.Tickets);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableCombineTradesGroups final : public cExecutableTrades
  {
   //====================
private:
   //====================
   //===============
   //===============
   virtual void      UpdateTicketsArray(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableCombineTradesGroups(void){}
   virtual void     ~cExecutableCombineTradesGroups(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutableCombineTradesGroups::UpdateTicketsArray(void)override final
  {
//===============
   const cExecutable *executables[];
//===============
   cArray::Free(executables);
//===============
   const bool executablesget=this.ParameterValuesGet(ELEMENTPARAMETER_TRADESGROUP,executables);
//===============
/* DEBUG ASSERTION */ASSERT({},executablesget,false,{})
//===============

//===============
   const int size=cArray::Size(executables);
//===============
   for(int i=0;i<size;i++)
     {
      //===============
      const cExecutableTrades *tradesgroup=dynamic_cast<const cExecutableTrades *>(executables[i]);
      //===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(tradesgroup),true,{})
      //===============
      if(!cPointer::Valid(tradesgroup))continue;
      //===============

      //===============
      tradesgroup.AddTicketsToArray(this.Tickets);
      //===============
     }
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableTradesGroupInfo : public cExecutable
  {
   //====================
protected:
   //====================
   //===============
   //===============
   void              cExecutableTradesGroupInfo(void):InfoType(WRONG_VALUE),TradesGroup(NULL){}
   //===============
   //===============
   eTradesGroupInfo  InfoType;
   const cExecutableTrades *TradesGroup;
   //===============
   //===============
   virtual bool      ReFreshState(void)override;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   virtual void     ~cExecutableTradesGroupInfo(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableTradesGroupInfo::ReFreshState(void)override
  {
//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   const cExecutable *executable=NULL;
//===============
   const bool executableget=this.ParameterValueGet(ELEMENTPARAMETER_TRADESGROUP,executable);
//===============
/* DEBUG ASSERTION */ASSERT({},executableget,false,{})
//===============

//===============
   this.TradesGroup=dynamic_cast<const cExecutableTrades *>(executable);
//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(this.TradesGroup),false,{})
//===============

//===============
   const bool infotypeget=this.ParameterValueGet(ELEMENTPARAMETER_TRADESGROUPINFO,this.InfoType);
//===============
/* DEBUG ASSERTION */ASSERT({},infotypeget,false,{})
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableTradesGroupInfoInteger final : public cExecutableTradesGroupInfo
  {
   //====================
private:
   //====================
   //===============
   //===============
   OUTPUTLONG
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableTradesGroupInfoInteger(void):OutputValue(0){}
   virtual void     ~cExecutableTradesGroupInfoInteger(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableTradesGroupInfoInteger::ReFreshState(void)override final
  {
//===============
   if(!cExecutableTradesGroupInfo::ReFreshState())return(false);
//===============

//===============
   this.OutputValue=0;
//===============

//===============
/* DEBUG ASSERTION */ASSERT({},cPointer::Valid(this.TradesGroup),true,{})
//===============

//===============
   if(!cPointer::Valid(this.TradesGroup))return(true);
//===============

//===============
   this.TradesGroup.ValueGet(this.OutputValue,this.InfoType);
//===============

//===============
   return(true);
//===============
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableArithmetic final : public cExecutable
  {
   //====================
private:
   //====================
   //===============
   //===============
   double            Value1;
   double            Value2;
   eMathOperation    Operation;
   //===============
   //===============
   OUTPUTDOUBLE
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableArithmetic(void):OutputValue(0.0),Value1(0.0),Value2(0.0),Operation(WRONG_VALUE){}
   virtual void     ~cExecutableArithmetic(void){}
   //===============
   //===============
   virtual void      OnTrigger(void)override final;
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableArithmetic::ReFreshState(void)override final
  {
//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   const bool value1get=this.ParameterValueGet(ELEMENTPARAMETER_DOUBLEVALUE1,this.Value1);
//===============
/* DEBUG ASSERTION */ASSERT({},value1get,false,{})
//===============

//===============
   const bool value2get=this.ParameterValueGet(ELEMENTPARAMETER_DOUBLEVALUE2,this.Value2);
//===============
/* DEBUG ASSERTION */ASSERT({},value2get,false,{})
//===============

//===============
   const bool operationget=this.ParameterValueGet(ELEMENTPARAMETER_MATHOPERATION,this.Operation);
//===============
/* DEBUG ASSERTION */ASSERT({},operationget,false,{})
//===============

//===============
   this.OutputValue=this.Value1;
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void cExecutableArithmetic::OnTrigger(void)override final
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   this.OutputValue=0.0;
//===============

//===============
   switch(this.Operation)
     {
      //===============
      case  MATHOPERATION_SUM             :   this.OutputValue=this.Value1+this.Value2;                                                 break;
      case  MATHOPERATION_SUBTRACT        :   this.OutputValue=this.Value1-this.Value2;                                                 break;
      case  MATHOPERATION_DIVIDE          :   if(this.Value2==0)break;this.OutputValue=this.Value1/this.Value2;                         break;
      case  MATHOPERATION_REMAINDER       :   if(this.Value2==0)break;this.OutputValue=(double)((long)this.Value1%(long)this.Value2);   break;
      case  MATHOPERATION_MULTIPLY        :   this.OutputValue=this.Value1*this.Value2;                                                 break;
      case  MATHOPERATION_POWER           :   this.OutputValue=::MathPow(this.Value1,this.Value2);                                      break;
      case  MATHOPERATION_MAXIMUM         :   this.OutputValue=::MathMax(this.Value1,this.Value2);                                      break;
      case  MATHOPERATION_MINIMUM         :   this.OutputValue=::MathMin(this.Value1,this.Value2);                                      break;
      //===============
      default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============

//===============
   cExecutable::OnTrigger();
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutablePriceTransformation final : public cExecutable
  {
   //====================
private:
   //====================
   //===============
   //===============
   OUTPUTDOUBLE
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutablePriceTransformation(void):OutputValue(0.0){}
   virtual void     ~cExecutablePriceTransformation(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutablePriceTransformation::ReFreshState(void)override final
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   this.OutputValue=0.0;
//===============

//===============
   string symbol=NULL;
//===============
   const bool symbolget=this.ParameterValueGet(ELEMENTPARAMETER_SYMBOLNAME,symbol);
//===============
/* DEBUG ASSERTION */ASSERT({},symbolget,false,{})
//===============

//===============
   double value=0.0;
//===============
   const bool valueget=this.ParameterValueGet(ELEMENTPARAMETER_DOUBLEVALUE,value);
//===============
/* DEBUG ASSERTION */ASSERT({},valueget,false,{})
//===============

//===============
   eMathOperation operation=WRONG_VALUE;
//===============
   const bool operationget=this.ParameterValueGet(ELEMENTPARAMETER_MATHOPERATION,operation);
//===============
/* DEBUG ASSERTION */ASSERT({},operationget,false,{})
//===============

//===============
   double point=0.0;
//===============
   const bool pointget=::SymbolInfoDouble(symbol,SYMBOL_POINT,point);
//===============
/* DEBUG ASSERTION */ASSERT({},pointget,true,{})
//===============

//===============
   if(pointget && point!=0)
     {
      //===============
      switch(operation)
        {
         //===============
         case  MATHOPERATION_PRICETOPOINTS            :   this.OutputValue=value/point;     break;
         case  MATHOPERATION_POINTSTOPRICE            :   this.OutputValue=value*point;     break;
         //===============
         default                   :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
         //===============
        }
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableAnd final : public cExecutable
  {
   //====================
private:
   //====================
   //===============
   //===============
   OUTPUTBOOL
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableAnd(void):OutputValue(false){}
   virtual void     ~cExecutableAnd(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableAnd::ReFreshState(void)override final
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   this.OutputValue=false;
//===============

//===============
   bool values[];
//===============
   cArray::Free(values);
//===============
   const bool parametersget=this.ParameterValuesGet(ELEMENTPARAMETER_BOOLVALUE,values);
//===============
/* DEBUG ASSERTION */ASSERT({},parametersget,false,{})
//===============

//===============
   const int parametersnumber=cArray::Size(values);
//===============

//===============
   if(parametersnumber==0)return(true);
//===============

//===============
   bool result=true;
//===============

//===============
   for(int i=0;i<parametersnumber;i++)
     {
      //===============
      if(values[i])continue;
      //===============

      //===============
      result=false;
      //===============

      //===============
      break;
      //===============
     }
//===============

//===============
   this.OutputValue=result;
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableOr final : public cExecutable
  {
   //====================
private:
   //====================
   //===============
   //===============
   OUTPUTBOOL
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableOr(void):OutputValue(false){}
   virtual void     ~cExecutableOr(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableOr::ReFreshState(void)override final
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   this.OutputValue=false;
//===============

//===============
   bool values[];
//===============
   cArray::Free(values);
//===============
   const bool parametersget=this.ParameterValuesGet(ELEMENTPARAMETER_BOOLVALUE,values);
//===============
/* DEBUG ASSERTION */ASSERT({},parametersget,false,{})
//===============

//===============
   const int parametersnumber=cArray::Size(values);
//===============

//===============
   if(parametersnumber==0)return(true);
//===============

//===============
   bool result=false;
//===============

//===============
   for(int i=0;i<parametersnumber;i++)
     {
      //===============
      if(!values[i])continue;
      //===============

      //===============
      result=true;
      //===============

      //===============
      break;
      //===============
     }
//===============

//===============
   this.OutputValue=result;
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class cExecutableCompare final : public cExecutable
  {
   //====================
private:
   //====================
   //===============
   //===============
   OUTPUTBOOL
   //===============
   //===============
   virtual bool      ReFreshState(void)override final;
   //===============
   //===============
   //====================
public:
   //====================
   //===============
   //===============
   void              cExecutableCompare(void):OutputValue(false){}
   virtual void     ~cExecutableCompare(void){}
   //===============
   //===============
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cExecutableCompare::ReFreshState(void)override final
  {
//===============
/* DEBUG MACROS' START */TRACEERRORS_START
//===============

//===============
   if(!cExecutable::ReFreshState())return(false);
//===============

//===============
   this.OutputValue=false;
//===============

//===============
   double value1=0.0;
//===============
   const bool value1get=this.ParameterValueGet(ELEMENTPARAMETER_DOUBLEVALUE1,value1);
//===============
/* DEBUG ASSERTION */ASSERT({},value1get,false,{})
//===============

//===============
   double value2=0.0;
//===============
   const bool value2get=this.ParameterValueGet(ELEMENTPARAMETER_DOUBLEVALUE2,value2);
//===============
/* DEBUG ASSERTION */ASSERT({},value2get,false,{})
//===============

//===============
   eRelationType relation=WRONG_VALUE;
//===============
   const bool relationget=this.ParameterValueGet(ELEMENTPARAMETER_RELATIONTYPE,relation);
//===============
/* DEBUG ASSERTION */ASSERT({},relationget,false,{})
//===============

//===============
   const double difference=value1-value2;
//===============

//===============
   switch(relation)
     {
      //===============
      case  RELATIONTYPE_GTEATER          :   this.OutputValue=(difference>=DBL_EPSILON);           break;
      case  RELATIONTYPE_GTEATEROREQUAL   :   this.OutputValue=(difference>-DBL_EPSILON);           break;
      case  RELATIONTYPE_EQUAL            :   this.OutputValue=(::fabs(difference)<=DBL_EPSILON);   break;
      case  RELATIONTYPE_LESS             :   this.OutputValue=(difference<-DBL_EPSILON);           break;
      case  RELATIONTYPE_LESSOREQUAL      :   this.OutputValue=(difference<=DBL_EPSILON);           break;
      //===============
      default                 :/* DEBUG ASSERTION */ASSERT({},false,false,{}) break;
      //===============
     }
//===============

//===============
/* DEBUG MACROS' END */TRACEERRORS_END
//===============

//===============
   return(true);
//===============
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

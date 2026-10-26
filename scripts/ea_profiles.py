"""Per-EA tester input defaults and [TesterInputs] line building.

Pure module (no MT5 / Wine imports) so it is importable by system python and tests.
Every EA input is written explicitly: MT5 silently applies the last GUI .set for any input left out,
and a bare "k=v" keeps an optimize flag cached from an earlier run, so fixed inputs are pinned as
v||v||1||v||N. Unknown input names are refused instead of silently ignored.
"""
import os

BLESSING_STRINGS = {"AlertSound", "DDorLevel", "GridSetArray", "HedgeSymbol", "Holidays", "LabelAcc", "LabelAdv", "LabelBBS", "LabelCCI", "LabelDisplay", "LabelEDD", "LabelEE", "LabelEH", "LabelES", "LabelEST", "LabelEST0", "LabelGS", "LabelGrid", "LabelGridOpt", "LabelHS", "LabelHS0", "LabelIchi", "LabelLS", "LabelMA", "LabelMACD", "LabelOS", "LabelOS0", "LabelOpt", "LabelSG", "LabelSto", "LabelTS", "LabelTST", "LabelUE", "Notes", "SetCountArray", "TP_SetArray", "TradeComment", "Version_3_9_6_23", "displayFont", "eopb", "eopb1", "s1", "s2", "s3"}
STRING_INPUTS = {"InpComment"} | BLESSING_STRINGS

# Research values, passed explicitly in every tester run. The six live EAs compile different defaults (0.5% risk, daily
# stop 3%, throttle 3% = FTMO 2-Step, spec 2026-10-22-dd-reduction phase 3b); these profiles keep 1% / 4% / off.
_CORE_DEFAULTS = {
    "InpTimeframe": "16385", "InpSlippagePoints": "30", "InpMaxSpreadPoints": "150",
    "InpRiskMode": "1", "InpRiskValue": "1.0",
    "InpSpreadWaitMin": "30", "InpDailyLossPct": "4.0", "InpMonthlyLossPct": "12.0", "InpTradeLog": "true",
    "InpLogEveryBar": "false",   # hourly status lines are for live/VPS, too noisy for tester runs
    "InpThrottleDDPct": "0.0", "InpThrottleFactor": "0.5",   # AccountThrottle.mqh: off (spec 2026-10-22-dd-reduction)
}

PROFILES = {
    # MACD_Cross_EA v1.45 compiled defaults (trailing off)
    "MACD_Cross_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "240817", "InpComment": "MACD_X",
        "InpFastEMA": "16", "InpSlowEMA": "26", "InpSignalSMA": "9", "InpAppliedPrice": "1",
        "InpZeroLineFilter": "false",
        "InpUseTrendFilter": "true", "InpTrendTF": "16388", "InpTrendPeriod": "200",
        "InpMinGapATR": "0.0", "InpATRPeriod": "14",
        "InpUseTimeFilter": "false", "InpStartHour": "7", "InpEndHour": "20",
        "InpStopLossPct": "0.5", "InpTakeProfitPct": "3.75", "InpCloseOnOpposite": "false", "InpMaxPositions": "3",
        "InpBreakEvenPct": "0.5", "InpBreakEvenLockPct": "0.1",
        "InpTrailStartPct": "0.0", "InpTrailDistPct": "1.0", "InpTrailATRMult": "4.0",
    }),
    # MeanRev_EA v1.00 compiled defaults (pre-tuning; Task 8 replaces the strategy values with the winner's)
    "MeanRev_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "240819", "InpComment": "MREV",
        "InpEntryMode": "0", "InpATRPeriod": "14", "InpSLATR": "1.5", "InpMaxBars": "12",
        "InpBBPeriod": "20", "InpBBDev": "2.0", "InpRSIPeriod": "14", "InpRSILow": "30",
        "InpADXPeriod": "14", "InpADXMax": "20",
        "InpRSI2Period": "2", "InpRSI2Entry": "10", "InpRSI2Exit": "70", "InpTrendPeriod": "200",
    }),
    # VWAP_RSI_EA v1.00 compiled defaults. Always pass InpTimeframe with --period (5 / 15 / 16385 / 16388).
    # InpSpreadWaitMin=0: the stop is a bar level; Core_RetryPending would re-apply the stored distance to a later price.
    # Camvcvoo_EA v1.00 compiled defaults (camvcvooV5.mq4 port, GBPUSD H1, spread cap 20 pts, no pending retry)
    "Camvcvoo_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261014", "InpComment": "CAMV", "InpTimeframe": "16385", "InpMaxSpreadPoints": "20", "InpSpreadWaitMin": "0",
        "InpTradeHour": "1", "InpFastSMA": "10", "InpSlowSMA": "197", "InpFractalShift": "3",
        "InpStopPips": "140", "InpTP1Pips": "22", "InpTP2Pips": "50", "InpTP3Pips": "80", "InpTrailPips": "22", "InpLockPips": "12",
    }),
    # Donchian_Breakout_EA v1.01 compiled defaults (XAUUSD H4 20-bar channel, H4 EMA200 trend, 2 x ATR(20) stop, 2R target, long-only, BE off, no spread retry)
    "Donchian_Breakout_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261015", "InpComment": "DONCH", "InpTimeframe": "16388", "InpSpreadWaitMin": "0",
        "InpChannelBars": "20", "InpTrendTF": "16388", "InpTrendEMA": "200", "InpAllowShort": "false",
        "InpATRPeriod": "20", "InpStopATR": "2.0", "InpTargetR": "2.0", "InpBreakEvenR": "0.0", "InpBELockR": "0.2",
    }),
    # MA_Channel_EA v1.01 compiled defaults (Kennedy MA price channel: H1, SMA 5/10, SMA20 of highs/lows, PULLBACK entry,
    # channel exit, 2 x ATR(20) stop, long-only, trend filter off = the Stage A winner, spec 2026-10-16 outcome)
    "MA_Channel_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261016", "InpComment": "MA_CH", "InpTimeframe": "16385", "InpSpreadWaitMin": "0",
        "InpFastMA": "5", "InpSlowMA": "10", "InpChannelMA": "20", "InpEntryMode": "1", "InpExitMode": "0",
        "InpTargetR": "2.0", "InpAllowShort": "false", "InpATRPeriod": "20", "InpStopATR": "2.0",
        "InpTrendTF": "16388", "InpTrendEMA": "0",
    }),
    # TEB_MTF_EA v1.00 compiled defaults (TEB63 2010: M5 entries / M30 trend, EMA 5/12, RSI 20 at 50, cross entry, 10-pip
    # stop and lot-1 target + spread, lot 2 swing-trailed, sessions on; spread cap 20 pts; spec 2026-10-16-teb-mtf)
    "TEB_MTF_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261017", "InpComment": "TEB_MTF", "InpTimeframe": "5", "InpMaxSpreadPoints": "20", "InpSpreadWaitMin": "0",
        "InpFastEMA": "5", "InpSlowEMA": "12", "InpRsiPeriod": "20", "InpTrendTF": "30",
        "InpTrendRsiBuy": "50.0", "InpTrendRsiSell": "50.0", "InpEntryRsiLevel": "50.0", "InpEntryMode": "0",
        "InpStopPips": "10.0", "InpTargetPips": "10.0", "InpSecondLot": "true", "InpSwingBars": "2", "InpSwingBufferPips": "1.0",
        "InpUseSessions": "true", "InpS1Start": "10", "InpS1End": "12", "InpS2Start": "14", "InpS2End": "19",
        "InpS3Start": "3", "InpS3End": "5",
    }),
    # EMA_RSI_CCI_EA v1.00 compiled defaults (ahmedabbas 2016: H1, EMA 5/12 cross, RSI 21 > 50, CCI 80 > 0, 35-pip stop,
    # no target, indicator exit, both sides; spread cap 30 pts; spec 2026-10-16-ema-rsi-cci)
    "EMA_RSI_CCI_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261018", "InpComment": "EMARC", "InpTimeframe": "16385", "InpMaxSpreadPoints": "30",
        "InpFastEMA": "5", "InpSlowEMA": "12", "InpRsiPeriod": "21", "InpRsiLevel": "50.0",
        "InpCciPeriod": "80", "InpCciLevel": "0.0", "InpStopPips": "35.0", "InpTargetPips": "0.0", "InpAllowShort": "true",
        "InpEntryMode": "0", "InpExitMode": "0", "InpConfirmRsi": "0.0",   # v1.01/1.02 (Bagovino modes); defaults = v1.00 rules
    }),
    "BarDump": {},   # tester helper: M1 bars to Common\Files\bars_<symbol>_M1.csv, no inputs
    # Enhanced Range Breakout EA v1.89 (third-party .ex5, no source; installed without the dot in "v1.89"): compiled
    # defaults from the report of a no-inputs run on 2026-10-17. Not EACore, so no CSV log (trades come from the
    # report's Deals table). Built for AVX2: the tester needs ROSETTA_ADVERTISE_AVX=1 on this Mac (spec 2026-10-17-erb)
    "Enhanced_Range_Breakout_EA_v189": {
        "RangeStartHour": "1", "RangeStartMin": "0", "RangeEndHour": "6", "RangeEndMin": "0", "TradingEndHour": "22",
        "TradingEndMin": "0", "RangeTimeToServerOffsetHours": "0", "RangeTimeToServerOffsetMin": "0", "EntryMode": "0",
        "BreakoutTimeframe": "15", "BreakoutBufferPips": "0.0", "PendingExpiryMins": "0", "TradeDirection": "0",
        "MaxTradesPerDay": "1", "SkipCurrentSessionOnAttach": "true", "EntryCutoffHour": "0", "EntryCutoffMin": "0",
        "TradeMonday": "true", "TradeTuesday": "true", "TradeWednesday": "true", "TradeThursday": "true",
        "TradeFriday": "true", "FridayCloseHour": "0", "FridayCloseMin": "0", "NoNewTradesFriday": "false",
        "SlMode": "0", "AtrSlTimeframe": "0", "AtrSlPeriod": "14", "AtrSlMultiplier": "1.5", "FixedSlPips": "20.0",
        "TpMode": "0", "TakeProfitRR": "1.0", "FixedTpPips": "30.0", "BreakevenActivationPips": "0.0",
        "BreakevenCushionPips": "0.0", "TrailActivationPips": "0.0", "TrailDistancePips": "15.0", "LotMode": "0",
        "LotSize": "0.0", "RiskPercent": "1.0", "RiskMoney": "50.0", "MaxSpreadPips": "0.0", "DSTAutoSwitch": "false",
        "SummerOffsetHours": "3", "WinterOffsetHours": "2", "SummerStartMonth": "3", "WinterStartMonth": "10",
        "TrendFilterOn": "false", "TrendFilterTimeframe": "16385", "TrendFilterPeriod": "200", "MinATRPips": "0.0",
        "ATRVolFilterPeriod": "14", "ATRVolFilterTimeframe": "16385", "MinRangeSizePips": "0.0",
        "MaxRangeSizePips": "0.0", "MinRangeATRMult": "0.0", "MaxRangeATRMult": "0.0", "RangeATRPeriod": "14",
        "RangeATRTimeframe": "16385", "ReentryCooldownMins": "0", "ShowSessionLabel": "false",
        "MinRangeBarsRequired": "0", "MaxDailyLossAmount": "0.0", "MaxDailyProfitAmount": "0.0",
        "MaxDrawdownAmount": "0.0", "ConsecutiveLossCount": "0", "ConsecutiveLossPauseDays": "1",
        "MaxLotSizeCap": "0.0", "SlippagePoints": "30", "MagicNumber": "20260708", "MaxBoxHistory": "5",
        "MaxArrowHistory": "20", "PanelShow": "true", "PanelCorner": "0", "PanelX": "10", "PanelY": "20",
        "PanelFontSize": "9", "PanelTextColor": "16777215", "PanelBgColor": "1315860", "BoxFillColor": "65535",
        "BoxOpacity": "80", "ShowLinesOnly": "false", "BoxBorderColor": "55295", "BoxBorderWidth": "1",
        "BoxBorderStyle": "0", "ShowPriceLabels": "true", "PriceLabelColor": "16777215", "ShowRangeSizeLabel": "true",
        "RangeSizeLabelColor": "0", "ShowExtendedLines": "false", "ExtendedLineBars": "100",
        "ExtendedHighColor": "65280", "ExtendedLowColor": "255", "ExtendedLineStyle": "1", "ShowMidLine": "false",
        "MidLineColor": "16776960", "MidLineStyle": "2", "ShowEntryArrows": "true", "BuyArrowColor": "65280",
        "SellArrowColor": "255",
    },
    # FZMR_Quant_Scalper_v4: the user's own v4 source (Gemini), unmodified; not EACore, so no CSV log (trades come from
    # the report's Deals table). Compiled defaults (spec 2026-10-17-fzmr-v4)
    "FZMR_Quant_Scalper_v4": {
        "InpZPeriod": "20", "InpZThreshold": "2.0", "InpExitAtMean": "true", "InpExitZTarget": "0.25", "InpMinProfitPts": "45",
        "InpERPeriod": "10", "InpMaxER": "0.38", "InpUseTrendFilter": "true", "InpTrendEMAPeriod": "200", "InpEMASlopeBars": "3",
        "InpRSIPeriod": "7", "InpRSIOverbought": "70.0", "InpRSIOversold": "30.0", "InpRiskPercent": "1.0", "InpFixedLot": "0.10",
        "InpATRPeriod": "14", "InpSLMultiplier": "1.60", "InpTPMultiplier": "2.20", "InpMinATRPts": "40", "InpMaxHoldBars": "20",
        "InpStartHour": "8", "InpEndHour": "19", "InpMaxSpreadPts": "15", "InpMagicNumber": "884422",
    },
    # FZMR_EA v1.01 compiled defaults (user's FZMR_Quant_Scalper v6: M15 z-score fade, ER/RSI/EMA 50-200 filters,
    # 2 ATR stop, 2.5 ATR target, 24-bar time exit, both sides; spread cap 150 pts, blocked bar skipped; spec 2026-10-17-fzmr)
    # Donchian_Trend_EA v1.01 (the user's DonchianTrend_EA, renamed 2026-10-21; MQL5/Experts/Advisors; standalone, no
    # trade log, no InpMagic: trades are rebuilt from the report's Deals table). Defaults = the USDJPY H4 pick of spec
    # 2026-10-21 at 0.3% risk (the user's request; v1.00 had channel 20, shorts on, ADX 18, ATR stop 2.0, RR 1.0, 0.25%).
    "Donchian_Trend_EA": {
        "InpSignalTimeframe": "16388", "InpDonchianPeriod": "10", "InpBreakoutBufferATR": "0.0",
        "InpRequireSignalCandleDirection": "true", "InpAllowLong": "true", "InpAllowShort": "false",
        "InpFastEMAPeriod": "50", "InpSlowEMAPeriod": "200", "InpUseADXFilter": "true", "InpADXPeriod": "14", "InpMinADX": "20.0",
        "InpATRPeriod": "14", "InpATRStopMultiplier": "1.5", "InpRewardRiskRatio": "1.5", "InpRiskPercent": "0.3",
        "InpSkipIfMinLotTooRisky": "true", "InpMaxSpreadPoints": "30", "InpDeviationPoints": "10",
        "InpOnePositionPerSymbol": "true", "InpMagicNumber": "20261020", "InpTradeComment": "MajorFX DonchianTrend",
        "InpThrottleDDPct": "0.0", "InpThrottleFactor": "0.5", "InpDailyLossPct": "0.0",   # DailyStop.mqh: off
    },
    # Invictus_GBPJPY_Monday_EA (the user's download InvictusGBPJPYMon.mq5, mql5.com code 77835, v1.30, unchanged; renamed per
    # the naming convention). Buys GBPJPY Monday 11:00 server, closes 23:00 server, no stop. Standalone, no trade log: trades
    # are rebuilt from the report's Deals table. v1.31 (MBT) defaults = the live inputs of spec stage 2: spread guard 3.0,
    # InpDemoOnly false, 0.006 lot per $1,000 of balance (InpLotsPer1k; 0 = fixed InpLots).
    "Invictus_GBPJPY_Monday_EA": {
        "InpLots": "0.05", "InpLotsPer1k": "0.006", "InpEntryHour": "11", "InpEntryMin": "0", "InpExitHour": "23",
        "InpExitMin": "0", "InpEntryGraceMin": "5", "InpDayMask": "1", "InpMaxSpreadPips": "3.0", "InpMinMarginLevel": "300.0",
        "InpMagic": "770531", "InpDemoOnly": "false", "InpMaxSlippagePts": "20", "InpMaxRetries": "3",
        "InpThrottleDDPct": "0.0", "InpThrottleFactor": "0.5", "InpDailyLossPct": "0.0",   # DailyStop.mqh: off
    },
    # NI225_Gap_Continuation_EA = Nikkei225_Gap_Continuation_EA.mq5 (mql5.com 75301), unchanged; source defaults (spec
    # 2026-10-23-ni225-gap-continuation-prereg.md): gap >= 1%, 10-min range breakout + VWAP, 1R partial, 2R target, 0.5% risk
    "NI225_Gap_Continuation_EA": {
        "InpSessionTimeMode": "0", "InpSessionOpenHour": "9", "InpSessionOpenMinute": "0", "InpSessionCloseHour": "15",
        "InpSessionCloseMinute": "30", "InpOpeningRangeMinutes": "10", "InpMaxEntryMinutesFromOpen": "90",
        "InpExitMinutesBeforeClose": "5", "InpEnableBuyGaps": "true", "InpMinimumBuyGapPercent": "1.0",
        "InpEnableSellGaps": "true", "InpMinimumSellGapPercent": "1.0", "InpUseRealVolumeIfAvailable": "true",
        "InpMaxSpreadPoints": "0.0", "InpMaxSpreadToStopPercent": "10.0", "InpStopBufferPoints": "0.0",
        "InpBuyRiskPercent": "0.50", "InpSellRiskPercent": "0.50", "InpReduceRiskOnSmallSellGap": "true",
        "InpSellFullRiskFromGapPct": "1.25", "InpSmallSellRiskPercent": "0.25", "InpFixedLots": "0.0",
        "InpMaxLots": "0.0", "InpPartialClosePercent": "40.0", "InpPartialTargetR": "1.0", "InpFinalTargetR": "2.0",
        "InpMoveStopToBreakEven": "true", "InpMagicNumber": "2250101", "InpMaxSlippagePoints": "30",
        "InpShowStatusOnChart": "true", "InpPrintDailyDiagnostics": "true",
        "InpDailyLossPct": "0.0",   # DailyStop.mqh (MBT 1.51): off in research runs
    },
    # 2026-10-26 Code Base experts pages 1-10 (spec 2026-10-26-codebase-experts-p1-10-prereg.md): EAs unchanged as CB<code>_EA, numeric/bool source defaults
    "CB23628_EA": {"InpStopLoss": "50", "InpTakeProfit": "140", "InpVolumeLotOrRisk": "3.0", "InpPrintLog": "false", "m_magic": "661394520"},
    "CB35556_EA": {"Stop_Loss": "0", "Take_Profit": "0", "Ind0Param0": "42", "Ind0Param1": "-20", "Ind1Param0": "20", "Ind2Param0": "19", "Ind2Param1": "79", "Ind3Param0": "22", "Ind3Param1": "16", "Ind3Param2": "21", "Ind3Param3": "20"},
    "CB35588_EA": {"Stop_Loss": "40", "Take_Profit": "70", "Ind0Param0": "40", "Ind0Param1": "10", "Ind0Param2": "10", "Ind1Param0": "40", "Ind1Param1": "10", "Ind1Param2": "10", "Ind1Param3": "20", "Ind2Param0": "40", "Ind2Param1": "10", "Ind2Param2": "10", "Ind2Param3": "75", "Ind3Param0": "0.0002", "Ind4Param0": "0.0013"},
    "CB38897_EA": {"InpStopLoss": "150", "InpTakeProfit": "460", "InpTrailingStop": "250", "InpTrailingStep": "50", "InpVolumeLotOrRisk": "3.0", "Inp_RSI_Fast_ma_period": "5", "Inp_RSI_Slow_ma_period": "15", "Inp_RSI_Level_Down": "25.0", "Inp_RSI_Level_Middle": "50.0", "Inp_RSI_Level_Up": "75.0", "Inp_MA_ma_period": "6", "InpTimeControl": "true", "InpStartHour": "10", "InpStartMinute": "01", "InpEndHour": "5", "InpEndMinute": "02", "InpOnlyOne": "false", "InpReverse": "false", "InpCloseOpposite": "false", "InpPrintLog": "true", "InpFreezeCoefficient": "3", "InpDeviation": "10", "InpMagic": "39771312"},
    "CB39012_EA": {"InpVolumeLotOrRisk": "3.0", "Length": "9", "Risk": "3", "ExitLevel": "5", "UseReEntry": "1", "UseExit": "1", "AlertMode": "0", "WarningMode": "0", "InpTimeControl": "false", "InpStartHour": "10", "InpStartMinute": "01", "InpEndHour": "5", "InpEndMinute": "02", "InpPrintLog": "true", "InpDeviation": "10", "InpMagic": "42251746"},
    "CB39334_EA": {"InpStopLoss": "150", "InpTakeProfit": "460", "InpTargetProfit": "5", "InpTrailingActivate": "70", "InpTrailingStop": "250", "InpTrailingStep": "50", "InpVolumeLotOrRisk": "3.0", "Inp_DeM_ma_period": "14", "Inp_DeM_LevelUp": "0.7", "Inp_DeM_LevelDown": "0.3", "InpTimeControl": "false", "InpStartHour": "10", "InpStartMinute": "01", "InpEndHour": "5", "InpEndMinute": "02", "InpPendingExpiration": "600", "InpPendingIndent": "5", "InpPendingMaxSpread": "12", "InpPendingOnlyOne": "false", "InpPendingClosePrevious": "false", "InpPrintLog": "true", "InpFreezeCoefficient": "1", "InpDeviation": "10", "InpMagic": "33475883"},
    "CB39425_EA": {"InpStopLoss": "150", "InpTakeProfit": "460", "InpTargetProfit": "5", "InpMaxPositions": "5", "InpMinStepPositions": "150", "InpTrailingActivate": "70", "InpTrailingStop": "250", "InpTrailingStep": "50", "InpVolumeLotOrRisk": "3.0", "Inp_DeM_ma_period": "14", "Inp_DeM_LevelUp": "0.7", "Inp_DeM_LevelDown": "0.3", "InpTimeControl": "false", "InpStartHour": "10", "InpStartMinute": "01", "InpEndHour": "5", "InpEndMinute": "02", "InpPendingExpiration": "600", "InpPendingIndent": "5", "InpPendingMaxSpread": "12", "InpPendingOnlyOne": "false", "InpPendingClosePrevious": "false", "InpPrintLog": "true", "InpFreezeCoefficient": "1", "InpDeviation": "10", "InpMagic": "458185032"},
    "CB39582_EA": {"InpStopLoss": "150", "InpTakeProfit": "460", "InpMaxPositions": "5", "InpMinStepPositions": "150", "InpTrailingActivate": "70", "InpTrailingStop": "250", "InpTrailingStep": "50", "InpVolumeLotOrRisk": "3.0", "Inp_RSI_ma_period": "14", "Inp_RSI_LevelUp": "70.0", "Inp_RSI_LevelDown": "30.0", "InpStepLength": "3", "Inp_AMA_ama_period": "15", "Inp_AMA_fast_ma_period": "2", "Inp_AMA_slow_ma_period": "30", "Inp_AMA_ama_shift": "0", "InpTimeControl": "false", "InpStartHour": "10", "InpStartMinute": "01", "InpEndHour": "5", "InpEndMinute": "02", "InpOnlyOne": "false", "InpCloseOpposite": "false", "InpPrintLog": "true", "InpFreezeCoefficient": "3", "InpDeviation": "10", "InpMagic": "200"},
    "CB39591_EA": {"InpStopLoss": "150", "InpTakeProfit": "460", "InpTargetProfit": "5", "InpMaxPositions": "5", "InpMinStepPositions": "150", "InpTrailingActivate": "70", "InpTrailingStop": "250", "InpTrailingStep": "50", "InpVolumeLotOrRisk": "3.0", "Inp_DeM_ma_period": "14", "Inp_DeM_LevelUp": "0.7", "Inp_DeM_LevelDown": "0.3", "InpTimeControl": "false", "InpStartHour": "10", "InpStartMinute": "01", "InpEndHour": "5", "InpEndMinute": "02", "InpPendingExpiration": "600", "InpPendingIndent": "5", "InpPendingMaxSpread": "12", "InpPendingOnlyOne": "false", "InpPendingClosePrevious": "false", "InpPrintLog": "true", "InpFreezeCoefficient": "1", "InpDeviation": "10", "InpMagic": "458185032"},
    "CB39703_EA": {"InpStopLoss": "150", "InpTakeProfit": "460", "InpLots": "0.01", "Inp_VIDyA_cmo_period": "15", "Inp_VIDyA_ema_period": "12", "Inp_VIDyA_ma_shift": "0", "InpPrintLog": "true", "InpFreezeCoefficient": "3", "InpDeviation": "10", "InpMagic": "204427024"},
    "CB41739_EA": {"InpVolumeLotOrRisk": "0.01", "InpStopLoss": "200", "InpTakeProfit": "200", "InpMaxPositions": "10", "InpShift": "2", "InpMagic": "270656512", "Inp_RSI_ma_period": "30", "Inp_RSI_LevelUP": "80", "Inp_RSI_LevelDOWN": "20"},
    "CB42283_EA": {"magicNumber": "0", "accountRisk": "2", "riskReward": "1.5", "emaPeriod": "34", "cciPeriod": "50", "minHour": "0", "maxHour": "24", "minimalStopLoss": "100", "useTrailingStop": "false", "tslPoints": "100"},
    "CB43252_EA": {"my_lot": "1", "MA_period": "20", "RSI_period": "14", "RSI_overbought": "70", "RSI_oversold": "30"},
    "CB43278_EA": {"Stop_Loss": "46", "Take_Profit": "0", "Ind0Param0": "5", "Ind0Param1": "2.50", "Ind1Param0": "27", "Ind1Param1": "17", "Ind1Param2": "21", "Ind1Param3": "0", "Ind1Param4": "6", "Ind1Param5": "4"},
    "CB44883_EA": {"InpMagicNumber": "124656", "isVolume_Percent": "true", "InpRisk": "3", "Inpuser_lot": "0.01", "InpSL_Pips": "3.5", "InpTP_Pips": "7", "InpMax_slippage": "3", "InpMax_spread": "5", "InpTimeFilter": "true", "InpStartHour": "2", "InpStartMinute": "30", "InpEndHour": "21", "InpEndMinute": "0"},
    "CB49770_EA": {"Lots": "0.1", "Risk": "2", "StopLoss": "0", "TakeProfit": "0", "ClasterBars": "50", "Pips": "400", "Magic": "777", "CloseSig": "0", "EnableCheckBars": "false"},
    "CB52105_EA": {"InpAverBodyPeriod": "3", "InpMAPeriod": "2", "InpPeriodRSI": "6", "InpLot": "0.05", "MaxRiskPercent": "1.0", "MaxSpread": "20.0", "UseTrailingStop": "true", "InpMagicNumber": "121300"},
    "CB52152_EA": {"MaxRiskPercent": "0.2", "OptimizationInterval": "3600", "InpMagicNumber": "121300", "MaxSimultaneousTrades": "1", "TrendPeriod": "20", "BreakEvenMultiplier": "1.5", "PartialTakeProfitPercent": "0.5", "PerformanceCheckInterval": "14400", "MaxSpreadPoints": "20", "NewsAvoidanceMinutes": "30", "HigherTimeframeTrendPeriod": "50", "RSI_Min_Period": "8", "RSI_Max_Period": "14", "ATR_Min_Multiplier": "1.0", "ATR_Max_Multiplier": "2.0", "TrailingStop_Min_Multiplier": "1.0", "TrailingStop_Max_Multiplier": "2.0", "TrailingTP_Min_Multiplier": "1.0", "TrailingTP_Max_Multiplier": "2.0"},
    "CB53526_EA": {"Signal_ThresholdOpen": "10", "Signal_ThresholdClose": "10", "Signal_PriceLevel": "0.0", "Signal_StopLevel": "1000.0", "Signal_TakeLevel": "5500.0", "Signal_Expiration": "4", "Signal_MACD_PeriodFast": "12", "Signal_MACD_PeriodSlow": "24", "Signal_MACD_PeriodSignal": "9", "Signal_MACD_Weight": "1.0", "Signal_0_MA_PeriodMA": "12", "Signal_0_MA_Shift": "0", "Signal_0_MA_Weight": "1.0", "Signal_1_MA_PeriodMA": "26", "Signal_1_MA_Shift": "0", "Signal_1_MA_Weight": "1.0", "Trailing_MA_Period": "12", "Trailing_MA_Shift": "0", "Money_FixLot_Percent": "10.0", "Money_FixLot_Lots": "0.06"},
    "CB54127_EA": {"inputAlpha": "0.1", "inputBeta": "0.1", "inputGamma": "0.1", "inputKappa": "1.0", "inputMu": "1.0", "inputSigma": "10.0", "MonteCarloSimulations": "1000", "magicNumber": "123456"},
    "CB54612_EA": {"Magic": "111111111111", "Risk": "1", "Lots": "0.10", "Stopp": "100", "MinutesAfterSessionStart": "420", "MinutesBeforSessionStart": "5", "ClosePos": "false", "Trall": "true", "ProfitFactor": "2", "Break": "false", "ProfitFactor2": "1", "ClosePosMinutes": "30"},
    "CB57020_EA": {"Fast_MA_Period": "20", "Slow_MA_Period": "50", "ATR_Period": "14", "ATR_Multiplier": "2.0", "LotSize": "0.1", "SL_Points": "500", "TP_Points": "1000", "Magic_Number": "123456"},
    "CB58135_EA": {"lookback": "200", "risk_per_trade": "1"},
    "CB58361_EA": {"RiskPercentPerTrade": "0.25", "MaxTotalDrawdownPercent": "10.0", "MaxDailyDrawdownPercent": "5.0", "InitialBalance": "5000.0", "TP1_RR": "1.0", "TP2_RR": "2.0", "TP3_RR": "3.0", "PartialClosePercentTP1": "50.0", "PartialClosePercentTP2": "25.0", "PartialClosePercentTP3": "25.0", "MoveSLToBE_AfterTP1": "true", "BE_PlusPips": "1", "TrailingSL_Pips": "10.0", "Use_SilverBullet": "true", "Use_2022Model": "true", "Use_OTE_Entry": "true", "HTF_MA_Period": "200", "DOL_Lookback_Bars": "120", "NDOG_NWOG_Threshold": "0.5", "OTE_Lower_Level": "0.618", "OTE_Upper_Level": "0.786", "ShowTradeLevels": "true"},
    "CB60347_EA": {"MagicNumber": "6062", "LotSize": "0.1", "StopLoss": "60", "MaxOpenTrade": "1", "LookbackBars": "12", "DayOfWeek": "5", "Hours": "23", "Minutes": "15", "SecureProfitTarget": "5.0"},
    "CB61998_EA": {"SignalValidity": "7", "Lotsize": "1", "SLPointDistanceFromMA": "50"},
    "CB62742_EA": {"LotSize": "0.1", "StopLoss": "100", "TakeProfit": "200", "MaxSpread": "30", "UseMoneyManagement": "false", "RiskPercent": "2.0", "RSI_Period": "14", "MACD_Fast": "12", "MACD_Slow": "26", "MACD_Signal": "9", "Stoch_K": "5", "Stoch_D": "3", "Stoch_Slowing": "3", "BarsToCheck": "50", "MinBarsDistance": "5", "MinDivergenceStrength": "0.7", "MinConfirmations": "3", "UseVolumeFilter": "true", "UseTrendFilter": "true", "AllowBuy": "true", "AllowSell": "true", "MaxTrades": "1", "MagicNumber": "123456"},
    "CB68125_EA": {"InpUseSilverBulletMode": "true", "InpUseSimpleMode": "false", "InpMinGapSize": "50.0", "InpAccuracy": "false", "InpDrawObjects": "true", "InpLotSize": "0.01", "InpEProfit": "10.0", "InpELoss": "10.0", "InpGMTOffset": "0", "InpTradeSB1": "true", "InpTradeSB2": "true", "InpTradeSB3": "true", "InpSBUseFixedTargets": "true", "InpMinDOLDistance": "20.0", "InpDOLTargetPercent": "80.0", "InpSLBufferPoints": "5.0", "InpEncScalpUseFilters": "false", "InpEncScalpMinGapPoints": "30", "InpEncScalpCheckTrend": "false", "InpEncScalpTrendPeriod": "20"},
    "CB68512_EA": {"InpEMA50": "50", "InpEMA200": "200", "InpRSI": "14", "InpStochK": "5", "InpStochD": "3", "InpStochSlowing": "3", "InpLondonStart": "8", "InpLondonEnd": "16", "InpNYStart": "13", "InpNYEnd": "21", "InpLotSize": "0.1", "InpStopLoss": "300", "InpTakeProfit": "600", "InpMagicNum": "123456"},
    "CB68951_EA": {"Range": "21", "sl_points": "100", "RR": "1"},
    "CB69651_EA": {"InpMagicNumber": "888888", "InpDebugMode": "true", "InpEnableAdaptive": "true", "InpLookbackPeriod": "20", "InpVolumeMultiplier": "1.3", "InpMinBodyRatio": "0.5", "InpClosePosition": "0.6", "InpMinImpulseBars": "2", "InpMaxImpulseBars": "5", "InpUseSessionFilter": "true", "InpRiskPerTrade": "0.1", "InpReduceAfterLoss": "false", "InpReductionFactor": "0.2", "InpMinEquityToTrade": "10.0", "InpMinMarginLevel": "110.0", "InpATRMultiplierSL": "1.2", "InpATRMultiplierTP": "1.8", "InpSlippagePoints": "30", "InpImmediateEntry": "true", "InpMaxEntryBars": "3", "InpBreakevenAt": "0.5", "InpTrailATRMulti": "1.0", "InpTrailActivation": "0.3", "InpUseVolatilityAdjust": "true", "InpMaxSpread": "40.0", "InpMinATRPoints": "50", "InpMaxATRPoints": "1500", "InpFilterLowVolume": "true"},
    "CB70052_EA": {"InpMagicNumber": "202503", "InpMaxSlippage": "10", "InpFixedLots": "0.01", "InpRiskPercent": "1.0", "InpMaxDrawdownPct": "10.0", "InpStopLoss": "225", "InpTakeProfit": "250", "InpUseBreakeven": "true", "InpBreakevenStart": "100", "InpBreakevenOffset": "10", "InpEmaFast": "150", "InpEmaSlow": "510", "InpRsiPeriod": "10", "InpRsiBuyMin": "40.0", "InpRsiBuyMax": "65.0", "InpRsiSellMin": "35.0", "InpRsiSellMax": "60.0", "InpBreakoutLookback": "20", "InpBreakoutBuffer": "0.5", "InpAtrPeriod": "125", "InpUseSessionFilter": "true", "InpSessionStartHour": "8", "InpSessionEndHour": "20", "InpAvoidFriday": "true", "InpFridayCutoffHour": "16", "InpUseSpreadFilter": "true", "InpMaxSpread": "30", "InpUseNewsFilter": "true", "InpNewsMinsBefore": "30", "InpNewsMinsAfter": "15"},
    "CB70916_EA": {"period_ma_fast": "100", "period_ma_slow": "200", "use_ma_filter": "false", "period_ma_filter": "100", "takeProfit": "0.0", "stopLoss": "0.0", "useFastMAexit": "false", "maxLotSize": "0.1", "minEquity": "100.0", "MagicNumber": "889"},
    "CB73674_EA": {"Lots": "0.1", "Risk": "2", "DailyATRPeriod": "14", "MinCheckDayATR": "1.5", "kDailyATR": "0.5", "rrTP": "2.5", "CloseHour": "22", "MagicNumber": "1"},
    "CB73884_EA": {"Lots": "1", "Risk": "2.0", "ATRPeriod": "14", "MinBarATR": "1.5", "MinBodyPct": "80.0", "MaxInsidePct": "50.0", "kSLMainBar": "0.62", "rrTP": "2.5", "OrderExpiryBars": "3"},
    "CB74135_EA": {"InpFastEMA": "9", "InpSlowEMA": "21", "InpStopLoss": "300", "InpTakeProfit": "600", "InpLotSize": "0.10", "InpMagicNumber": "20260101"},
    "CB74137_EA": {"Lots": "0.1", "Risk": "2", "DailyATRPeriod": "14", "MinCheckDayATR": "1.5", "kDailyATR": "0.5", "rrTP": "2.5", "CloseHour": "22", "MagicNumber": "1"},
    "CB74379_EA": {"InpMAPeriod": "30", "InpAngleSpan": "60", "InpBuyDeviation": "7.0", "InpSellDeviation": "10.0", "InpAngleThreshold": "25.0", "InpRiskPercent": "70.0", "InpUseFixedLots": "false", "InpFixedLots": "0.1", "InpMinAngleFilter": "10"},
    "CB74815_EA": {"risk_percent": "99", "target_percent": "1", "cycle1": "true", "cycle2": "false", "cycle3": "false", "LotSize": "0.01", "Slippage": "5", "c1_MagicNumber": "123", "c2_MagicNumber": "456", "c3_MagicNumber": "789", "MAPeriod": "100", "MA_shift": "0", "InpMAPeriod": "99", "InpMAShift": "0", "c2_InpDeviation": "0.03", "c3_InpDeviation": "0.3"},
    "CB74818_EA": {"cycle1": "true", "cycle2": "false", "cycle3": "false", "cycle4": "false", "MAPeriod": "3", "MA_shift": "0", "MA1_Enable": "false", "MA2Period": "20", "MA2_shift": "0", "MA2_Enable": "false", "MA3Period": "50", "MA3_shift": "0", "MA3_Enable": "false", "RSI_Period": "200", "RSI_Buy_Level": "30", "RSI_Sell_Level": "70", "RSI_Enable": "false", "WPR_Period": "200", "WPR_Buy_Level": "-80", "WPR_Sell_Level": "-20", "WPR_Enable": "true", "LotSize": "0.01", "AutoLots": "false", "Lots_Risk": "3", "Account_Risk_percent": "99", "target_percent": "1.0", "target_amount": "0", "Reverse_Signals": "false", "c1_MagicNumber": "111", "InpMAPeriod2": "25", "InpMAShift2": "0", "c2_InpDeviation": "0.3", "LotSize2": "0.01", "AutoLots2": "false", "Lots_Risk2": "3", "Account_Risk_percent2": "99", "target_percent2": "1.0", "target_amount2": "0", "Reverse_Signals2": "false", "c2_MagicNumber": "333", "InpMAPeriod3": "25", "InpMAShift3": "0", "c3_InpDeviation": "0.7", "LotSize3": "1.0", "AutoLots3": "false", "Lots_Risk3": "3", "Account_Risk_percent3": "99", "target_percent3": "0.0", "target_amount3": "350", "Reverse_Signals3": "false", "c3_MagicNumber": "555", "InpMAPeriod4": "99", "InpMAShift4": "0", "c4_InpDeviation": "0.7", "Distance": "10", "LotSize4": "1.0", "AutoLots4": "false", "Lots_Risk4": "3", "Account_Risk_percent4": "99", "target_percent4": "0.0", "target_amount4": "350", "Reverse_Signals4": "false", "c4_MagicNumber": "777", "Slippage": "5"},
    "CB74894_EA": {"InpATRPeriod": "10", "InpATRMultiplier": "3.0", "InpChangeATRMethod": "true", "InpUseHTFFilter": "true", "InpLotSize": "0.01", "InpMaxRiskValue": "99.0", "InpTakeProfitValue": "1.0", "InpMagicNumber": "202306", "InpSlippage": "30"},
    "CB75002_EA": {"FastEMA": "9", "SlowEMA": "21", "RSIPeriod": "14", "BuyRSILevel": "48.0", "SellRSILevel": "52.0", "OneEntryPerCandle": "true", "MagicNumber": "26071501", "FixedLot": "0.01", "MaximumSpreadPoints": "50", "StopLossPoints": "500", "TakeProfitPoints": "500", "SlippagePoints": "30", "DashboardX": "12", "DashboardY": "25", "DashboardFontSize": "10"},
    "CB75586_EA": {"InpAsianStartHour": "0", "InpAsianEndHour": "7", "InpDailyAtrPeriod": "14", "InpMinRangeATRFrac": "0.15", "InpMaxRangeATRFrac": "0.70", "InpLondonStartHour": "7", "InpLondonEndHour": "11", "InpAtrPeriod": "14", "InpBreakoutBufferATR": "0.15", "InpStopATRMult": "1.2", "InpRewardMultiple": "1.8", "InpRiskPercent": "1.0", "InpMaxSpreadPoints": "350", "InpMagicNumber": "20260801", "InpDeviationPoints": "50"},
    "CB76333_EA": {"Initial_Capital_Base": "1000.0", "Risk_Per_Trade_Pct": "5.0", "EA_Magic_Number": "111111", "RANGE_MINSIZE_ATR_MULT": "0.2", "ENTRY_BUFFER_POINTS": "8.0", "TRADE_TP_RR": "2", "BE_ENABLED": "true", "BE_ACTIVATION_RR": "1.2", "TRAIL_ENABLED": "true", "TRAIL_ACTIVATION_RR": "1.3", "TRAIL_DISTANCE_ATR_MULT": "0.3", "ORB_START_HOUR": "16", "ORB_START_MIN": "45", "ORB_END_HOUR": "17", "ORB_END_MIN": "0", "TRADE_CUTOFF_HOUR": "19", "TRADE_CUTOFF_MIN": "30", "SESSION_CLOSE_HOUR": "22", "SESSION_CLOSE_MIN": "45", "FRIDAY_CLOSE_HOUR": "20", "FRIDAY_CLOSE_MIN": "0", "SL_USE_RANGE": "true", "SL_ATR_MULT": "1.2", "MAX_SPREAD_POINTS": "25.0", "MAX_TRADES_PER_DAY": "2", "ATR_PERIOD": "14", "MAX_BARS_HOLD": "20"},
    "CB77060_EA": {"InpEntryHour": "1", "InpEntryWindowMin": "10", "InpHoldHours": "2", "InpSkipMonday": "true", "InpLots": "0.01", "InpStopAtrMult": "2.0", "InpRangeBars": "480", "InpMaxSpreadPts": "60", "InpMagic": "77701"},
    "CB77180_EA": {"InpFastEMA": "10", "InpSlowEMA": "30", "InpStartHourWIB": "19", "InpEndHourWIB": "22", "InpWIBOffsetGMT": "7", "InpLot": "0.01", "InpSLpoints": "70", "InpTPpoints": "200", "InpMaxPos": "1", "InpMagic": "20260909", "InpDeviation": "10", "InpMaxSpreadPoints": "100"},
    "CB77414_EA": {"Lot": "0.01", "FastMAPeriod": "5", "SlowMAPeriod": "21", "StopLoss": "300", "TakeProfit": "600", "MagicNumber": "123456", "TradeOnNewBar": "true"},
    "CB78411_EA": {"InpCustomK": "1.0", "InpCustomDigits": "5", "InpHistoryBars": "20000", "InpTickBars": "20", "InpTickLimit": "1500000", "InpStoreTicks": "true", "InpUpdateMs": "250", "InpLots": "0.50", "InpLotStep": "0.10", "InpBasketUnit": "100000.0", "InpTPIndex": "0.50", "InpSLIndex": "0.50", "InpWarnLegError": "25.0", "InpConfirm": "true", "InpMagic": "20250101", "InpDeviation": "20", "InpFastEMA": "12", "InpSlowEMA": "26", "InpTesterStepSec": "1", "InpShowPanel": "true", "InpShowPreview": "true", "InpPanelX": "10", "InpPanelY": "20"},
    "CB78454_EA": {"InpUseSweeps": "true", "InpHistoryBars": "3000", "InpFvgMinSize": "50", "InpRequireIdm": "true", "InpFvgBelowBos": "true", "InpFvgLogSkips": "false", "InpShowFvg": "true", "InpFvgTextSize": "8", "InpShowStruct": "true", "InpAllowBuy": "true", "InpAllowSell": "true", "InpRiskReward": "2.0", "InpSlBuffer": "20", "InpMinDepth": "50.0", "InpMaxPositions": "1", "InpRiskPercent": "1.0", "InpFixedLot": "0.01", "InpMagic": "20261010", "InpSlippage": "20", "InpBeEnable": "true", "InpBeTrigger": "100", "InpBeOffset": "10", "InpTrailEnable": "true", "InpTrailTrigger": "150", "InpTrailStep": "20", "InpTrailDist": "100"},
    # DonchianTrend2_EA v2.00 (MBT copy of DonchianTrend_EA: spread-blocked signals retried in their bar; defaults = the
    # stage 1 USDJPY H4 pick of spec 2026-10-21: long-only, channel 10, 1.5 x ATR stop, RR 1.5, ADX >= 20)
    "DonchianTrend2_EA": {
        "InpSignalTimeframe": "16388", "InpDonchianPeriod": "10", "InpBreakoutBufferATR": "0.0",
        "InpRequireSignalCandleDirection": "true", "InpAllowLong": "true", "InpAllowShort": "false",
        "InpFastEMAPeriod": "50", "InpSlowEMAPeriod": "200", "InpUseADXFilter": "true", "InpADXPeriod": "14", "InpMinADX": "20.0",
        "InpATRPeriod": "14", "InpATRStopMultiplier": "1.5", "InpRewardRiskRatio": "1.5", "InpRiskPercent": "0.25",
        "InpSkipIfMinLotTooRisky": "true", "InpMaxSpreadPoints": "30", "InpSpreadWaitMin": "0", "InpDeviationPoints": "10",
        "InpOnePositionPerSymbol": "true", "InpMagicNumber": "20261020", "InpTradeComment": "MajorFX DonchianTrend",
    },
    # RSI8020_EA v1.00 compiled defaults (TradingStrategyGuides RSI 80-20: RSI 8 at 80/20, 50-bar low/high extreme,
    # divergence, close beyond A, swing stop + 0.1 ATR, 3R; spec 2026-10-18-rsi8020-prereg.md)
    "RSI8020_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261020", "InpComment": "RSI8020", "InpTimeframe": "16385", "InpSpreadWaitMin": "0", "InpMaxSpreadPoints": "50",
        "InpRsiPeriod": "8", "InpRsiLevel": "20.0", "InpExtremeMode": "0", "InpLookback": "50", "InpExpiryBars": "50", "InpTargetR": "3.0",
        "InpSLBufferATR": "0.1", "InpWideStopATR": "0.0", "InpAllowShort": "true", "InpRetryMin": "60",
    }),
    "FZMR_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261019", "InpComment": "FZMR", "InpTimeframe": "15", "InpSpreadWaitMin": "0",
        "InpZPeriod": "20", "InpZThreshold": "2.0", "InpERPeriod": "10", "InpMaxER": "0.40",
        "InpUseTrendFilter": "true", "InpFastEMAPeriod": "50", "InpSlowEMAPeriod": "200",
        "InpRSIPeriod": "7", "InpRSIOverbought": "70.0", "InpRSIOversold": "30.0",
        "InpATRPeriod": "14", "InpSLMultiplier": "2.0", "InpTPMultiplier": "2.5", "InpTargetR": "0.0", "InpMaxHoldBars": "24",
        "InpStartHour": "2", "InpEndHour": "20", "InpSkipNYOpen": "true", "InpAllowShort": "true",
        "InpSkipFromHour": "0", "InpSkipToHour": "0", "InpMaxBarRetrace": "0.0", "InpSellMaxDistATR": "0.0",   # v1.01 filters, off
    }),
    # EMA_VWAP_Trail_EA v1.03 compiled defaults (Pine port: M15, daily VWAP, EMA 9, 2 x ATR(14) stop + trail from entry)
    "EMA_VWAP_Trail_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261013", "InpComment": "EMA_VWAP", "InpTimeframe": "15",
        "InpAnchor": "0", "InpEMAPeriod": "9", "InpATRPeriod": "14", "InpATRMult": "2.0", "InpTrailATR": "true", "InpTrailAfterProfit": "false",
        "InpTrendEMA": "0", "InpHTFBias": "0", "InpHTFEMA": "200", "InpSessionStart": "0", "InpSessionEnd": "24",   # v1.01 filters, off
        "InpHoldThroughFiltered": "false", "InpMaxPositions": "1",   # v1.03 stacking, off
    }),
    # VWAP_EMA_Cross_EA v1.00 compiled defaults (M5, daily VWAP, EMA 9, 0.5% protective stop, as-specified direction)
    "VWAP_EMA_Cross_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261012", "InpComment": "VWAP_EMA", "InpTimeframe": "5",
        "InpAnchor": "0", "InpEMAPeriod": "9", "InpSLPercent": "0.5", "InpInvert": "false",
    }),
    # VWAP_EMA_Pullback_EA v1.00 compiled defaults (M5, daily VWAP, EMA 9/21, pullback <= 8 bars, ATR stop with 0.2 buffer / 1.0 min / 3.0 max, RR 1.5)
    "VWAP_EMA_Pullback_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261026", "InpComment": "VWAP_PB", "InpTimeframe": "5",
        "InpAnchor": "0", "InpEMAFast": "9", "InpEMASlow": "21", "InpMaxPullbackBars": "8",
        "InpAllowBuys": "true", "InpAllowSells": "true", "InpVwapWarmupBars": "12", "InpMaxStopATR": "3.0",
        "InpATRPeriod": "14", "InpSLBufferATR": "0.2", "InpMinStopATR": "1.0", "InpRR": "1.5",
    }),
    "VWAP_RSI_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261006", "InpComment": "VWAP_RSI", "InpSpreadWaitMin": "0",
        "InpAnchor": "0", "InpRSIPeriod": "21", "InpRR": "1.0", "InpSLBufferATR": "0.0", "InpMinStopATR": "0.1",
        "InpReentryMode": "0",
    }),
    # HoLo_EA v1.00 compiled defaults (MichaelG's HoLo, NY session only). InpTimeframe = trigger timeframe.
    "HoLo_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261007", "InpComment": "HOLO", "InpTimeframe": "15", "InpSpreadWaitMin": "0", "InpEntryMode": "0",
        "InpLevelTF": "16385", "InpRR": "1.0", "InpBETriggerPct": "0.067", "InpBELockPct": "0.013",
        "InpMaxLatePct": "0.01", "InpMinStopPct": "0.03", "InpBreakoutFilter": "true",
        "InpSessionStartNY": "480", "InpSessionEndNY": "1015", "InpServerNYOffset": "7",
        "InpExcursionLog": "false",
    }),
    # EuroRiddle_EA v1.00 compiled defaults (docs/superpowers/specs/2026-10-06-euroriddle-prereg.md). EURUSD:
    # 1 pip = 10 points, so the spread guard is 20 points = 2 pips. InpTimeframe (H1) is the filter timeframe.
    "EuroRiddle_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261008", "InpComment": "EURID", "InpSpreadWaitMin": "0", "InpMaxSpreadPoints": "20",
        "InpMode": "0", "InpFilter": "0", "InpStopPips": "15", "InpTargetPips": "25",
        "InpADRPeriod": "20", "InpADRFrac": "1.0", "InpLateStartNY": "720", "InpRSIPeriod": "14", "InpRSILevel": "70",
        "InpServerNYOffset": "7",
    }),
    # Icarus_EA v1.00 compiled defaults = the Icarus 2.2 MQ4 defaults (docs/superpowers/specs/2026-10-06-icarus-prereg.md).
    # Grid EA without stop loss: EACore's daily/monthly stops are compiled to 0 (they would close legs the grid reopens).
    # InpMaxSpreadPoints 100 = max_spread 100 MT4 points. Progressions: 0 flat, 1 D'Alembert, 2 Martingale, 3 Fibonacci.
    "Icarus_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261009", "InpComment": "ICARUS", "InpSpreadWaitMin": "0", "InpMaxSpreadPoints": "100",
        "InpDailyLossPct": "0", "InpMonthlyLossPct": "0",
        "InpGridPips": "20", "InpGridProgression": "3", "InpTakeProfitPips": "20", "InpProfitLock": "0.3",
        "InpMinLots": "0.01", "InpEquityWarning": "0.20", "InpAccountRisk": "1.00", "InpLotProgression": "3",
        "InpMaxPositions": "6", "InpUnbalanceControl": "false",
    }),
    # RSI_Reversal_EA v1.20 compiled defaults: v1.10 signals/exits on EACore (spread guard, daily/monthly stops, CSV log).
    # InpTimeframe = RSI timeframe (H6). EACore's InpRiskMode is MONEY 0 / PERCENT 1 (v1.10 had PERCENT 0).
    # Break-even off and trailing on until docs/superpowers/specs/2026-10-14-rsi-donchian-guardrails-prereg.md decides.
    "RSI_Reversal_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261004", "InpComment": "RSI_REV", "InpTimeframe": "16390",
        "InpRsiPeriod": "4", "InpRsiBuyLevel": "40.0", "InpRsiSellLevel": "55.0",
        "InpUseMaFilter": "true", "InpMaTimeframe": "16396", "InpMaPeriod": "250", "InpMaMethod": "0",
        "InpStopLossPct": "1.0", "InpTakeProfitPct": "5.0",
        "InpBreakEvenPct": "0.0", "InpBreakEvenLockPct": "0.1",
        "InpTrailTriggerPct": "1.0", "InpTrailDistancePct": "1.0", "InpTrailStepPct": "0.05",
    }),
    # Blessing_3 v3.9.6.23 (third-party MQL5 port of the MT4 Blessing 3 grid EA, compile fixes 2026-10-06; standalone, no
    # EACore, no trade CSV: trades come from the report's Deals table). All 190 compiled defaults, generated from
    # mql5/Blessing_3.mq5 with walkforward.parse_inputs; PortionChange "increase" = 1 and the four display colours
    # (BGR integers) were resolved by hand. Enums: tFrame 0 current/3 M15/5 H1; entType 0 off/1 on/2 reverse;
    # mktCond 3 automatic. Strings (labels, arrays, comment) are written bare, see BLESSING_STRINGS.
    "Blessing_3": {
        "Version_3_9_6_23": "EA Settings:",
        "TradeComment": "b3_v396.23",
        "Notes": "",
        "EANumber": "1",
        "EmergencyCloseAll": "false",
        "s1": "",
        "ShutDown": "false",
        "s2": "",
        "LabelAcc": "",
        "StopTradePercent": "10.0",
        "NanoAccount": "false",
        "s3": "... PortionPC > 100 forces effective balance to that amount (e.g. 1000)",
        "PortionPC": "100.0",
        "PortionChange": "1",
        "MaxDDPercent": "50.0",
        "MaxSpread": "5.0",
        "UseHolidayShutdown": "true",
        "Holidays": "18/12-01/01",
        "PlaySounds": "false",
        "AlertSound": "Alert.wav",
        "eopb": "",
        "EnableOncePerBar": "true",
        "UseMinMarginPercent": "false",
        "MinMarginPercent": "1500.0",
        "eopb1": "",
        "LabelTST": "",
        "TesterMinMarginPercent": "500.0",
        "TesterSelection": "1",
        "B3Traditional": "true",
        "ForceMarketCond": "3",
        "UseAnyEntry": "false",
        "LabelLS": "",
        "UseMM": "true",
        "LAF": "0.5",
        "Lot": "0.01",
        "Multiplier": "1.4",
        "LabelGS": "",
        "AutoCal": "false",
        "ATRTF": "0",
        "ATRPeriods": "21",
        "GAF": "1.0",
        "EntryDelay": "2400",
        "EntryOffset": "5.0",
        "UseSmartGrid": "true",
        "LabelTS": "",
        "MaxTrades": "15",
        "BreakEvenTrade": "12",
        "BEPlusPips": "2.0",
        "UseCloseOldest": "false",
        "CloseTradesLevel": "5",
        "ForceCloseOldest": "true",
        "MaxCloseTrades": "4",
        "CloseTPPips": "10.0",
        "ForceTPPips": "0.0",
        "MinTPPips": "0.0",
        "LabelES": "",
        "MaximizeProfit": "false",
        "ProfitSet": "70.0",
        "MoveTP": "30.0",
        "TotalMoves": "2",
        "UseStopLoss": "false",
        "SLPips": "30.0",
        "TSLPips": "10.0",
        "TSLPipsMin": "3.0",
        "UsePowerOutSL": "false",
        "POSLPips": "600.0",
        "UseFIFO": "false",
        "LabelEE": "",
        "UseEarlyExit": "false",
        "EEStartHours": "3.0",
        "EEFirstTrade": "true",
        "EEHoursPC": "0.5",
        "EEStartLevel": "5",
        "EELevelPC": "10.0",
        "EEAllowLoss": "false",
        "LabelAdv": "",
        "LabelGrid": "",
        "SetCountArray": "4,4",
        "GridSetArray": "25,50,100",
        "TP_SetArray": "50,100,200",
        "LabelEST0": "",
        "LabelEST": "",
        "LabelMA": "",
        "MAEntry": "1",
        "MA_TF": "0",
        "MAPeriod": "100",
        "MADistance": "10.0",
        "LabelCCI": "",
        "CCIEntry": "0",
        "CCIPeriod": "14",
        "LabelBBS": "",
        "BollingerEntry": "0",
        "BollPeriod": "10",
        "BollDistance": "10.0",
        "BollDeviation": "2.0",
        "LabelIchi": "",
        "IchimokuEntry": "0",
        "ICHI_TF": "0",
        "Tenkan_Sen": "9",
        "Kijun_Sen": "26",
        "Senkou_Span": "52",
        "useCloudBreakOut": "true",
        "useTenken_Kijun_cross": "2",
        "usePriceCrossTenken": "false",
        "usePriceCrossKijun": "false",
        "useChikuspan": "false",
        "useCloudSL": "false",
        "LabelSto": "",
        "StochEntry": "0",
        "BuySellStochZone": "20",
        "KPeriod": "10",
        "DPeriod": "2",
        "Slowing": "2",
        "LabelMACD": "",
        "MACDEntry": "0",
        "MACD_TF": "0",
        "FastPeriod": "12",
        "SlowPeriod": "26",
        "SignalPeriod": "9",
        "MACDPrice": "0",
        "LabelSG": "",
        "RSI_TF": "3",
        "RSI_Period": "14",
        "RSI_Price": "0",
        "RSI_MA_Period": "10",
        "RSI_MA_Method": "0",
        "LabelHS0": "",
        "LabelHS": "",
        "HedgeSymbol": "",
        "CorrPeriod": "30",
        "UseHedge": "false",
        "DDorLevel": "DD",
        "HedgeStart": "20.0",
        "hLotMult": "0.8",
        "hMaxLossPips": "30.0",
        "hFixedSL": "false",
        "hTakeProfit": "30.0",
        "hReEntryPC": "5.0",
        "StopTrailAtBE": "true",
        "ReduceTrailStop": "true",
        "LabelOS0": "",
        "LabelOS": "",
        "RecoupClosedLoss": "true",
        "Level": "7",
        "SaveStats": "false",
        "StatsPeriod": "3600",
        "StatsInitialise": "true",
        "LabelUE": "",
        "UseEmail": "false",
        "LabelEDD": "At what DD% would you like Email warnings (Max: 49, Disable: 0)?",
        "EmailDD1": "20.0",
        "EmailDD2": "30.0",
        "EmailDD3": "40.0",
        "LabelEH": "Hours before DD timer resets",
        "EmailHours": "24.0",
        "LabelDisplay": "",
        "displayOverlay": "true",
        "displayLogo": "true",
        "displayCCI": "true",
        "displayLines": "true",
        "displayXcord": "100",
        "displayYcord": "30",
        "displayCCIxCord": "10",
        "displayFont": "Arial Bold",
        "displayFontSize": "9",
        "displaySpacing": "14",
        "displayRatio": "1.3",
        "displayColor": "16760576",
        "displayColorProfit": "32768",
        "displayColorLoss": "255",
        "displayColorFGnd": "0",
        "HideIndicators": "true",
        "Debug": "false",
        "LabelGridOpt": "",
        "LabelOpt": "These values can only be used while optimizing",
        "UseGridOpt": "false",
        "SetArray1": "4",
        "SetArray2": "4",
        "SetArray3": "0",
        "SetArray4": "0",
        "GridArray1": "25",
        "GridArray2": "50",
        "GridArray3": "100",
        "GridArray4": "0",
        "GridArray5": "0",
        "TPArray1": "50",
        "TPArray2": "100",
        "TPArray3": "200",
        "TPArray4": "0",
        "TPArray5": "0",
    },
    # ATR Candle Breakout EA (third-party .ex5, no source): defaults as saved by MT5 on 2026-10-01.
    # Risk is a fixed money amount per trade (InpRiskAmount); no CSV trade log, magic input is InpMagicNumber.
    "ATR Candle Breakout EA": {
        "InpTimeframe": "16385", "InpATRPeriod": "200", "InpATRMultiplier": "2.5", "InpCloseProximity": "25.0",
        "InpMinBodyRatio": "0.0",
        "InpUseTrendFilter": "false", "InpTrendTF": "16408", "InpTrendMAPeriod": "200", "InpTrendMAMethod": "1",
        "InpUseMTFATR": "false", "InpHTFTimeframe": "16388", "InpHTFATRPeriod": "14", "InpHTFATRMultiplier": "1.0",
        "InpUseTimeFilter": "false", "InpStartHour": "8", "InpEndHour": "20", "InpSkipFriday": "true",
        "InpSkipMonday": "false",
        "InpUseSRFilter": "false", "InpSRTimeframe": "16408", "InpSRLookback": "50", "InpSRZoneATRMult": "0.5",
        "InpSRMinTouches": "2",
        "InpSLPercent": "0.5", "InpTPPercent": "2.0", "InpRiskAmount": "100.0",
        "InpUseTrailing": "false", "InpTrailStartPct": "0.5", "InpTrailStepPct": "0.3",
        "InpMagicNumber": "14", "InpSlippage": "100",
    },
}


def expert_path(expert):
    if expert not in PROFILES:
        raise ValueError(f"unknown expert {expert!r}; known: {sorted(PROFILES)}")
    return f"Advisors\\{expert}.ex5"


def merge_inputs(expert, sets):
    expert_path(expert)
    base = dict(PROFILES[expert])
    unknown = sorted(k for k in sets if k not in base)
    if unknown:
        raise ValueError(f"unknown input(s) for {expert}: {', '.join(unknown)}")
    base.update(sets)
    return base


def parse_range(spec):
    try:
        name, value = spec.split("=", 1)
        start, step, stop = value.split(":")
        ok = float(step) > 0 and float(stop) >= float(start)
    except ValueError:
        ok = False
    if not ok:
        raise ValueError(f"refusing range {spec!r}: numeric start:step:stop with step > 0 only; "
                         f"sweep bools/enums as separate launches")
    return name.strip(), (start, step, stop)


def tester_input_lines(inputs, ranges):
    unknown = sorted(k for k in ranges if k not in inputs)
    if unknown:
        raise ValueError(f"range for unknown input(s): {', '.join(unknown)}")
    lines = []
    for k, v in inputs.items():
        if k in ranges:
            a, s, b = ranges[k]
            lines.append(f"{k}={v}||{a}||{s}||{b}||Y")
        elif k in STRING_INPUTS:
            lines.append(f"{k}={v}")
        else:
            lines.append(f"{k}={v}||{v}||1||{v}||N")
    return lines


def tester_log_name(expert, symbol, magic):
    return f"{expert}_{symbol}_{magic}_tester_trades.csv"


def trade_log_name_for(expert, symbol, inputs):
    """Tester trade-log file name for EAs built on EACore / v1.42 (they have InpMagic); None otherwise."""
    if "InpMagic" not in inputs:
        return None
    return tester_log_name(expert, symbol, inputs["InpMagic"])


def pick_fresh_log(path, started_at):
    if os.path.isfile(path) and os.path.getmtime(path) >= started_at:
        return path
    return None

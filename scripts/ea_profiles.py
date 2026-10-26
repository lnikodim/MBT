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
    # 2026-10-26 Code Base experts pages 11-20 (spec 2026-10-26-codebase-experts-p11-20-prereg.md): EAs unchanged as CB<code>_EA, numeric/bool source defaults
    "CB16918_EA": {"InpLots": "0.1", "InpStopLossBuy": "50", "InpStopLossSell": "50", "InpTakeProfitBuy": "50", "InpTakeProfitSell": "50", "InpTrailingStop": "0", "InpTrailingStep": "5", "MACD_fast_ema_period": "12", "MACD_slow_ema_period": "26", "MACD_signal_period": "9", "Sto_Kperiod": "5", "Sto_Dperiod": "3", "Sto_slowing": "3", "m_magic": "102370183"},
    "CB17066_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpCorridor": "1", "InpDayOfWeek": "5", "m_magic": "10456776"},
    "CB20127_EA": {"MaximumRisk": "0.02", "DecreaseFactor": "10", "Expiration": "1", "m_magic": "375558442"},
    "CB20132_EA": {"InpLots": "0.1", "InpStopLossBuy": "300", "InpStopLossSell": "300", "InpTrailingStopBuy": "100", "InpTrailingStopSell": "100", "InpStep": "500", "Expiration": "1", "InpAma_period": "15", "InpFast_ma_period": "2", "InpSlow_ma_period": "30", "InpAma_shift": "0", "m_magic": "212626795"},
    "CB20148_EA": {"InpLots": "0.10", "InpStopLossBuy": "100", "InpTakeProfitBuy": "300", "InpStopLossSell": "100", "InpTakeProfitSell": "300", "InpTrailingStopBuy": "50", "InpTrailingStopSell": "50", "lFlagUseHourTrade": "false", "nFromHourTrade": "0", "nToHourTrade": "23", "InpTenkanSen": "9", "InpKijunSen": "26", "InpSenkouSpanB": "52", "m_magic": "67161684"},
    "CB20149_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "10", "InpTrailingStep": "5", "InpStartHour": "6", "InpEndHour": "10"},
    "CB20166_EA": {"InpLots": "0.1", "InpStopLoss": "30", "InpTakeProfit": "90", "InpTrailingStop": "10", "InpTrailingStep": "5", "InpOpenCloseDiff": "100", "m_magic": "60051552"},
    "CB20184_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "10", "InpTrailingStep": "5", "InpMAma_period": "15", "InpMAma_shift": "0", "InpSARstep": "0.02", "InpSARmaximum": "0.2", "m_magic": "402926420"},
    "CB20194_EA": {"InpStopLoss": "30", "InpTakeProfit": "65", "InpTrailingStop": "0", "InpTrailingStep": "5", "Risk": "3", "Reverse": "false", "m_magic": "254871700"},
    "CB20195_EA": {"InpLots": "0.1", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpResetTime": "10", "DojiDiff1": "10", "DojiDiff2": "4", "m_magic": "1237322"},
    "CB20208_EA": {"InpLotsManual": "false", "InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "Risk": "5", "InpShift": "6", "InpInterval": "27", "MA_Fast_ma_period": "14", "MA_Fast_ma_shift": "0", "MA_Slow_ma_period": "41", "MA_Slow_ma_shift": "0", "m_magic": "13433244"},
    "CB20353_EA": {"InpLots": "0.1", "InpStopLoss": "30", "InpTakeProfit": "60", "InpTrailingStop": "5", "InpTrailingStep": "1", "InpMaxPositions": "2", "BB_bands_period": "20", "BB_bands_shift": "0", "BB_deviation": "2.0"},
    "CB20397_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "10", "InpTrailingStep": "5", "InpStartHour": "6", "InpEndHour": "10", "InpMaxPendingOrders": "5"},
    "CB20424_EA": {"m_magic": "0", "Lot": "0.2", "WaitClose": "true", "Ustan_BuyStop": "true", "Ustan_SellLimit": "false", "Ustan_SellStop": "true", "Ustan_BuyLimit": "false", "ryn_MaxOrderov": "2", "ryn_TakeProfit": "200", "ryn_StopLoss": "100", "ryn_TrStop": "100", "ryn_TrStep": "10", "WaitProfit": "true", "st_Step": "50", "st_TakeProfit": "200", "st_StopLoss": "100", "st_TrStop": "0", "st_TrStep": "3", "lim_Step": "50", "lim_TakeProfit": "200", "lim_StopLoss": "100", "lim_TrStop": "0", "lim_TrStep": "3", "UseTime": "true", "Hhour": "23", "Mminute": "59", "TIME_Buy": "false", "TIME_Sell": "false", "TIME_BuyStop": "true", "TIME_SellLimit": "false", "TIME_SellStop": "true", "TIME_BuyLimit": "false", "PipsProfit": "0", "UseGlobalLevels": "true", "Global_TakeProfit": "2.0", "Global_StopLoss": "2.0"},
    "CB20461_EA": {"delay_open": "2", "distance": "850", "range": "500", "InpCountToCopy": "1000", "InpCountMaxMin": "40", "Risk": "5", "InpStopLoss": "1000", "InpMinProfit": "1.0", "m_magic": "47978073"},
    "CB20492_EA": {"InpStopLoss": "50", "InpTakeProfit": "150", "InpTrailingStop": "5", "InpTrailingStep": "1", "Risk": "5", "InpADX_adx_period": "24", "InpMA_ma_shift": "0", "m_magic": "532830322"},
    "CB20493_EA": {"period_EMA": "28", "period_WMA": "8", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "50", "InpTrailingStep": "10", "risk": "10"},
    "CB20500_EA": {"InpN_candles": "3", "InpLot": "0.01", "InpTakeProfit": "50", "InpStopLoss": "50", "InpTrailingStop": "10", "InpTrailingStep": "4", "InpMaxPositions": "2", "InpMaxPositionVolume": "2.0", "InpUseTradeHours": "true", "InpMinProfit": "3.0", "m_magic": "427475216"},
    "CB20545_EA": {"InpLots": "0.1", "InpTrailingStop": "0", "InpMA_ma_period": "26", "InpMA_ma_shift": "8", "MO_Min": "100.0", "MO_Shift": "-0.2", "InpMO_mom_period": "23", "MO_OpenTime": "6", "MO_CloseTime": "10", "m_magic": "15489"},
    "CB20548_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "150", "InpTrailingStop": "5", "InpTrailingStep": "5", "MaClose_ma_period": "20", "MaClose_ma_shift": "0", "MaClose_SignalBar": "0", "MaOpen_ma_period": "70", "MaOpen_ma_shift": "0", "MaOpen_SignalBar": "0", "m_magic": "37826789"},
    "CB20554_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "150", "Ma_ma_period": "10", "Ma_ma_shift": "0", "InpMaPricePercent": "0.3", "InpTradeOnFriday": "true", "InpStep": "30", "InpIncreaseStep": "0", "m_magic": "189326592"},
    "CB20565_EA": {"InpLots": "0.1", "InpTakeProfitBuy": "10", "InpTakeProfitSell": "10", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpIndent": "1", "Max_Search": "10", "OrderExp": "8", "MagicType1": "11111", "MagicType2": "22222", "InpBreakeven": "1", "InpBreakevenProfit": "10"},
    "CB20585_EA": {"InpLots": "0", "InpStopLoss": "30", "InpTakeProfit": "90", "InpTrailingStop": "15", "InpTrailingStep": "5", "Risk": "5", "InpSizeCandle": "1", "m_magic": "624402688"},
    "CB20591_EA": {"InpLots": "0.1", "InpMaxPosition": "2", "InpMinimumDistance": "5", "InpMinimumPause": "600", "InpMA_First_ma_period": "5", "InpMA_First_ma_shift": "0", "InpMA_Second_ma_period": "25", "InpMA_Second_ma_shift": "0", "InpMA_Third_ma_period": "125", "InpMA_Third_ma_shift": "0", "m_magic": "282317256"},
    "CB20621_EA": {"InpStopLoss": "100", "InpTakeProfit": "200", "InpTrailingStop": "40", "InpTrailingStep": "5", "FastMAPeriod": "10", "SlowMAPeriod": "80", "InpMinCrossDistance": "0", "ReverseCondition": "false", "ConfirmedOnEntry": "true", "OneEntryPerBar": "true", "StopAndReverse": "true", "PureSAR": "false", "UseHourTrade": "false", "StartHour": "10", "EndHour": "11", "InpLots": "0", "Risk": "5", "PrintControl": "true", "Show_Settings": "true", "m_magic": "15489"},
    "CB20668_EA": {"InpShiftOHLC": "15", "InpMinProfit": "7", "InpShiftPos": "43", "InpLotsBuy": "0.01", "InpLotsSell": "0.01", "InpLotIncreaseRateFractalsM5": "2", "InpLotIncreaseRateFractalsH1": "4", "m_magic": "15489"},
    "CB20672_EA": {"LotFixed": "0.01", "LotFromPercent": "0", "Period_sma_slow": "5", "Period_sma_fast": "34", "Orders": "10", "Magic": "5632"},
    "CB20679_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "25", "InpTrailingStep": "1", "m_magic": "41158285"},
    "CB20705_EA": {"TriggerOne": "true", "TriggerTwo": "false", "BBSpreadH4Min_1": "84.", "BBSpreadM15Max_1": "64.", "RSIPer_1": "10", "RSILoM15_1": "24.", "RSIHiM15_1": "66.", "RSILoH1_1": "34.", "RSIHiH1_1": "54.", "RSILoH4_1": "48.", "RSIHiH4_1": "56.", "RSIHiLimH4_1": "85.", "RSILoLimH4_1": "35.", "RSIHiLimH1_1": "80.", "RSILoLimH1_1": "24.", "RSIHiLimM15_1": "92.", "RSILoLimM15_1": "20.", "RDeltaM15_Lim_1": "-3.5", "StocLoM15_1": "26.", "StocHiM15_1": "64.", "RSIPer_2": "20", "BBSpreadH4Min_2": "65.", "BBSpreadM15Max_2": "75.", "NumRSI": "60", "RSIM15_Sigma_2": "1.20", "RSIH1_Sigma_2": "0.95", "RSIH4_Sigma_2": "0.9", "RSIM15_SigmaLim_2": "1.85", "RSIH1_SigmaLim_2": "2.55", "RSIH4_SigmaLim_2": "2.7", "RDeltaM15_Lim_2": "-5.5", "StocLoM15_2": "24.", "StocHiM15_2": "68.", "InpLots": "0.1", "InpTakeProfit_Buy_1": "150", "InpStopLoss_Buy_1": "70", "InpTakeProfit_Sell_1": "70", "InpStopLoss_Sell_1": "35", "InpTakeProfit_Buy_2": "140", "InpStopLoss_Buy_2": "35", "InpTakeProfit_Sell_2": "60", "InpStopLoss_Sell_2": "30", "ATRPer": "60", "BBPeriod": "20", "ATRLim": "90.", "entryhour": "0", "openhours": "14", "NumPositions": "1", "TotOpenOrders": "8", "FridayEndHour": "4", "L1": "12", "L2": "5", "L3": "5", "m_magic": "15489"},
    "CB20708_EA": {"InpRISK_1": "3", "Laguerre_1_Period": "14", "Laguerre_1_Distance": "0", "x11": "100.0", "x12": "100.0", "tp1": "100", "sl1": "50", "InpRISK_2": "9", "Laguerre_2_Period": "14", "Laguerre_2_Distance": "0", "x21": "100.0", "x22": "100.0", "tp2": "100", "sl2": "50", "Laguerre_3_Period": "14", "Laguerre_3_Distance": "0", "Laguerre_4_Period": "14", "Laguerre_4_Distance": "0", "x31": "100", "x32": "100", "pass": "4", "InpLots": "0.1", "m_magic": "75962120"},
    "CB20752_EA": {"InpLots": "0.1", "HourStart": "4", "HourEnd": "18", "FirstTP": "21", "SecondTP": "34", "ThirdTP": "55", "InpTrailingStop": "15", "InpTrailingStep": "5", "Step": "15", "MA_ma_period": "15", "MA_ma_shift": "3", "Bands_bands_period": "15", "Bands_bands_shift": "0", "Bands_deviation": "2.0", "m_magic": "7900444"},
    "CB20779_EA": {"Inp_aed_AccountReserve": "0.20", "Inp_aed_OrderReserve": "0.04", "Inp_aed_TakeFactor": "1.7", "Inp_aed_StopFactor": "1.7", "Inp_aed_TrailFactor": "0.5"},
    "CB20827_EA": {"InpLots": "0.1", "InpMaxPositions": "10", "MACD_fast_ema_period": "12", "MACD_slow_ema_period": "26", "MACD_signal_period": "9", "SAR_step": "0.02", "SAR_maximum": "0.2", "InpMoreLessBuy_1": "true", "InpMoreLessBuy_2": "false", "InpMoreLessBuy_3": "false", "InpMoreLessSell_1": "false", "InpMoreLessSell_2": "true", "InpMoreLessSell_3": "true", "m_magic": "56306380"},
    "CB20936_EA": {"OrdinaryLot": "0.01", "CoefFlatnessM5": "0.35", "StopLoss": "500", "TakeProfit": "0", "TakeProfitAfterBreakeven": "0", "StopLossAfterBreakeven": "450", "MaxFanDistanceM5": "250", "MaxFanDistanceM15": "200", "MaxFanDistanceH1": "600", "StochasticKperiodM5": "24", "StochasticUpM5": "85", "StochasticDownM5": "15", "StochasticKperiodM15": "24", "StochasticUpM15": "85", "StochasticDownM15": "15", "MinBody": "150", "MinFlatInBars": "10", "MaxFlatInPoints": "150", "MinDivergencesInBarsM5": "75", "HammerMinPercentageLongShadow": "80", "HammerMaxPercentageShortShadow": "10", "HammerMinSizeInPoints": "11", "HammerBarHowLongAgo": "8", "HammerPeriodOnBars": "15", "MaxFanWidthAtNarrowestM5": "30", "FanConvergedToPointIinBars": "5", "RangeMaxOrMinBreaksThrough": "10", "m_magic": "1214", "StepTral": "500", "DistTral": "3000"},
    "CB21050_EA": {"InpLots": "0.1", "InpStartHour": "9", "InpEndHour": "18", "m_magic": "481361391"},
    "CB21086_EA": {"InpMaximumRisk": "0.02", "InpDecreaseFactor": "3", "InpStopLossBuy": "40", "InpStopLossSell": "40", "InpTakeProfitBuy": "100", "InpTakeProfitSell": "100", "InpTrailingStopBuy": "30", "InpTrailingStopSell": "30", "InpTrailingStep": "5", "InpExPeriod": "15", "m_magic": "26513850"},
    "CB21196_EA": {"InpLots": "0.1", "Inp_MA_ma_period": "6", "Inp_RSI_ma_period": "10", "Inp_ATR_ma_period": "28", "ism": "1.6", "tpm": "1", "RSIUpperLimit": "80", "RSIUpperLevel": "60", "RSILowerLevel": "39", "RSILowerLimit": "25", "Inp_fast_ema_period": "5", "Inp_slow_ema_period": "21", "Inp_signal_period": "14", "MacdDiffBuy": "0.5", "MacdDiffSell": "0.15", "m_magic": "139200996"},
    "CB21298_EA": {"InpLots": "0.1", "InpStopLoss": "500", "InpTakeProfit": "500", "InpTrailingStop": "50", "InpTrailingStep": "50", "InpStep": "0.0001", "InpCloseOpposite": "true", "m_magic": "10965350"},
    "CB21300_EA": {"Inp_Lots0_1": "0.1", "Inp_Lots0_2": "0.1", "Inp_TakeProfit1_Proc": "50", "Inp_SpaseFromMaxMin": "10", "Inp_IsStopLoss_0": "true", "Inp_StopLoss_0_From": "80", "Inp_StopLoss_0_Level": "10", "Inp_TrailingStop": "80", "Inp_TrailingStep": "120", "Inp_Slippage": "2", "Inp_Magic1": "1281", "Inp_Magic2": "1282", "Inp_MA1_Period": "20", "Inp_MA1_Shift": "0", "Inp_MA2_Period": "20", "Inp_MA2_Shift": "0", "Inp_BB_Period": "20", "Inp_BB_Deviation": "2", "Inp_BB_Bands_Shift": "0", "Inp_ZZ_ExtDepth": "12", "Inp_ZZ_Deviation": "5", "Inp_ZZ_Backstep": "3"},
    "CB21311_EA": {"InpLots": "0.1", "InpNumberMinLots": "3", "InpStopLoss": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpStep": "50", "InpMinNearest": "3", "m_magic": "277070794"},
    "CB21345_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "Inp_CCI_ma_period": "55", "Inp_BIG_JUMP": "100", "Inp_DOUBLE_JUMP": "100", "Inp_SignalCandle": "0", "m_magic": "166399440"},
    "CB21348_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "0", "InpTrailingStep": "5", "InpMinProfit": "10.0", "InpProfitPoints": "10.0", "InpUseFractals": "true", "InpUseStochastic": "true", "InpOneDayOneDeal": "true", "InpKperiod": "5", "InpDperiod": "3", "Inpslowing": "3", "m_magic": "767280168"},
    "CB21374_EA": {"InpLots": "1.0", "m_magic": "9864936"},
    "CB21387_EA": {"NUM_LOTS": "1.0", "EMA_SPEED": "11.0", "BIG_JUMP": "30.0", "DOUBLE_JUMP": "55.0", "STOP_LOSS": "20.0", "EMERGENCY_LOSS": "50.0", "TAKE_PROFIT": "25.0", "SLOPE_SMALL": "5.0", "SLOPE_LARGE": "8.0", "MINUTES_BEGIN": "25.0", "MINUTES_END": "25.0", "SLIP_BEGIN": "0.0", "SLIP_END": "0.0", "MIN_VOLUME": "0.0", "ADJUST": "1.0", "m_magic": "120600896"},
    "CB21394_EA": {"InpLots": "0.1", "InpStopLoss": "20", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpTimeZone": "2", "m_magic": "541114416"},
    "CB21457_EA": {"InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpMinDistance": "25", "Risk": "5", "m_magic": "585000550"},
    "CB21495_EA": {"InpLots": "0.1", "InpMAspread": "10", "Inp_ma_period_MA1": "9", "Inp_ma_shift_MA1": "0", "Inp_ma_period_MA2": "14", "Inp_ma_shift_MA2": "1", "Inp_ma_period_MA3": "29", "Inp_ma_shift_MA3": "2", "m_magic": "3415489"},
    "CB21499_EA": {"Inp_ma_period": "44", "Inp_ma_shift": "4", "InpCurrentBarMA": "0", "InpCurrentBarOHLC": "0", "InpLevelHigh": "14", "InpLevelLow": "3", "InpLots": "0.1", "InpStopLoss": "100", "InpTakeProfit": "50", "m_magic": "166319460"},
    "CB21563_EA": {"TradeBuy": "true", "TradeSell": "true", "UseEquClose": "true", "TrackLossEquity": "true", "InpLots": "0.1", "InpTakeProfit": "10", "InpDistanceOpenPositions": "10", "PercentEquityForClose": "5.0", "PercentLossEquityForClose": "5.0", "NumberLossPoseForCloseEquUP": "5", "NumberLossPoseForCloseEquDN": "5", "m_magic": "9938165"},
    "CB21595_EA": {"InpLots": "0.1", "InpLookPriceHour": "10", "InpLookPriceMiin": "0", "InpCloseHour": "18", "InpUseCloseHour": "true", "InpTakeProfit": "40", "InpDistanceBuy": "18", "InpDistanceSell": "22", "InpStopLossBuy": "22", "InpStopLossSell": "18", "InpReport": "15", "m_magic": "20051016"},
    "CB21616_EA": {"InpLots": "0.01", "InpSLFactor": "14", "InpTPFactor": "2", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpPositionsMax": "5", "InpDistance": "10", "InpBarsControl": "true", "InpCoefficient": "1.61", "InpRsiTeacher": "true", "InpRsiTeacher2": "true", "Inp_MA_First_ma_period": "5", "Inp_MA_Second_ma_period": "9", "Inp_MA_Filter_ma_period": "20", "Inp_RSI_First_ma_period": "15", "Inp_RSI_Second_ma_period": "20", "RSISellLevel": "34", "RSIBuyLevel": "70", "RSISellLevel2": "34", "RSIBuyLevel2": "68", "Shift": "0", "TrendFilter": "false", "InpTradeOnFriday": "true", "InpBeginTradeHour": "0", "InpEndTradeHour": "0", "m_magic": "368265384"},
    "CB21629_EA": {"InpLots": "0.1", "InpOffset": "3", "InpTakeProfit": "75", "InpTrailingStop": "5", "InpTrailingStep": "15", "InpDelta": "0.00003", "InpOpposite": "false", "Inp_jaw_period": "13", "Inp_jaw_shift": "8", "Inp_teeth_period": "8", "Inp_teeth_shift": "5", "Inp_lips_period": "5", "Inp_lips_shift": "3", "Inp_RSI_ma_period": "14", "m_magic": "118623120"},
    "CB21639_EA": {"InpLots": "0.1", "InpStopLoss": "999", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpDistance": "50", "InpTrailingEquity": "5.0", "InpVirtualStopEquity": "99999", "InpTrailingStartEquity": "20", "Inp_ma_period": "13", "InpCoefficient": "2.0", "InpResetPrice": "false", "m_magic": "2823480"},
    "CB21672_EA": {"InpLots": "0.1", "InpStopLoss": "150", "InpTakeProfit": "150", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpCount": "10", "Inp_MA_First_ma_period": "10", "Inp_MA_First_ma_shift": "0", "Inp_MA_Second_ma_period": "100", "Inp_MA_Second_ma_shift": "0", "Inp_MACD_fast_ema_period": "12", "Inp_MACD_slow_ema_period": "26", "Inp_MACD_signal_period": "9", "m_magic": "199397822"},
    "CB21679_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "150", "InpTrailingStop": "1", "InpTrailingStep": "1", "InpTimecontrol": "true", "InpStartHour": "7", "InpEndHour": "17", "InpCloseOpposite": "true", "Inp_WPR_calc_period": "360", "m_magic": "838471170"},
    "CB21727_EA": {"InpLots": "0.1", "InpStopLoss": "15", "InpTakeProfit": "30", "InpMaxLoss": "75.0", "InpKMartin": "1.6", "m_magic": "12214280"},
    "CB21759_EA": {"InpLots": "0.1", "InpStopLoss": "0", "InpTakeProfit": "60", "InpTrailingStop": "15", "InpTrailingStep": "5", "periodRSI": "14", "levelUpRSI": "60.0", "levelDownRSI": "20.0", "m_magic": "634914175"},
    "CB21774_EA": {"InpLots": "0.1", "InpStopLoss": "30", "InpTakeProfit": "50", "InpTrailingStop": "1", "InpTrailingStep": "5", "InpSignalBar": "2", "InpMinDistance": "15", "InpLifetime": "2", "InpReverse": "false", "m_magic": "6012"},
    "CB21852_EA": {"InpLots": "0.01", "InpStopLossBuy": "50", "InpTakeProfitBuy": "50", "InpStopLossSell": "50", "InpTakeProfitSell": "50", "InpEveryTick": "false", "Inp_MA_ma_period": "20", "Inp_MA_ma_shift": "0", "Inp_Mom_mom_period": "5", "m_magic": "660512475"},
    "CB21878_EA": {"InpLots": "0.1", "InpStopLossBuy": "40", "InpTakeProfitBuy": "70", "InpStopLossSell": "10", "InpTakeProfitSell": "40", "InpTrailingStop": "5", "InpTrailingStep": "1", "Sto_level_buy": "37.0", "Sto_level_sell": "96.0", "MACD_signal_period": "9", "MACD_fast_ema_period": "12", "MACD_slow_ema_period": "26", "Sto_Kperiod": "5", "Sto_Dperiod": "3", "Sto_slowing": "3", "m_magic": "39427905"},
    "CB21929_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpUseHour": "true", "InpStartHour": "10", "InpEndHour": "19", "InpBarCurrent": "0", "m_magic": "392864254"},
    "CB21937_EA": {"InpLots": "1.0", "Inp_MA_ma_period": "45", "Inp_MACD_fast_ema_period": "47", "Inp_MACD_slow_ema_period": "95", "Inp_MACD_signal_period": "74", "Inp_STO_Kperiod": "25", "Inp_STO_Dperiod": "12", "Inp_STO_slowing": "56", "m_magic": "4797863"},
    "CB21962_EA": {"InpLots": "0.1", "Inp_MA_Fast_ma_period": "33", "Inp_MA_Fast_ma_shift": "3", "Inp_MA_Slow_ma_period": "90", "Inp_MA_Slow_ma_shift": "1", "m_magic": "327215416"},
    "CB21976_EA": {"InpLots": "0.1", "InpStopLoss": "125", "InpTakeProfit": "60", "InpTrailingStop": "5", "InpTrailingStep": "5", "Inp_CCI_ma_period": "12", "Inp_RSI_ma_period": "15", "Inp_RSI_level_up": "75.0", "Inp_RSI_level_down": "30.0", "Inp_CCI_level_up": "80.0", "Inp_CCI_level_down": "-95.0", "m_magic": "423179520"},
    "CB22003_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "50", "Inp_ADX_adx_period": "14", "Inp_AMA_ama_period": "9", "Inp_AMA_fast_ma_period": "2", "Inp_AMA_slow_ma_period": "30", "Inp_AMA_ama_shift": "0", "m_magic": "25291424"},
    "CB22006_EA": {"InpRISK_1": "3", "Laguerre_1_Period": "14", "Laguerre_1_Distance": "0", "x11": "100.0", "x12": "100.0", "tp1": "100", "sl1": "50", "InpRISK_2": "9", "Laguerre_2_Period": "14", "Laguerre_2_Distance": "0", "x21": "100.0", "x22": "100.0", "tp2": "100", "sl2": "50", "Laguerre_3_Period": "14", "Laguerre_3_Distance": "0", "Laguerre_4_Period": "14", "Laguerre_4_Distance": "0", "x31": "100", "x32": "100", "pass": "4", "InpLots": "0.1", "InpStartHour": "9", "InpStartMin": "0", "InpEndHour": "17", "InpEndMin": "03", "m_magic": "75962120"},
    "CB22016_EA": {"InpLots": "0.1", "InpStopLoss": "15", "InpTakeProfit": "95", "Inp_ma_period": "5", "InpBarCurrent": "1", "m_magic": "86021760"},
    "CB22021_EA": {"InpLots": "0.1", "InpTakeProfit": "50", "InpChannel": "25", "m_magic": "3463424"},
    "CB22033_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "50", "Inp_CCI_ma_period": "14", "Inp_cci_up": "210", "Inp_cci_down": "-210", "m_magic": "362461279"},
    "CB22087_EA": {"InpLots": "0.1", "InpStopLoss": "35", "InpTakeProfit": "75", "InpTrailingStop": "5", "InpTrailingStep": "5", "Inp_MACD_fast_ema_period": "12", "Inp_MACD_slow_ema_period": "26", "Inp_MACD_signal_period": "9", "MACDOpenLevel": "3", "m_magic": "343194060"},
    "CB22098_EA": {"InpLots": "0.1", "InpStopLoss": "35", "InpTakeProfit": "75", "InpChannelStartHour": "07", "InpChannelStartMin": "00", "InpChannelEndHour": "08", "InpChannelEndtMin": "00", "InpPlacingStartHour": "08", "InpPlacingEndHour": "18", "InpChannelBreakthrough": "30", "InpOrderPriceShift": "10", "InpVisual": "true", "Inp_Rectangle_Width": "2", "Inp_Rectangle_Fill": "false", "Inp_Rectangle_Back": "false", "Inp_Rectangle_Selection": "false", "Inp_Rectangle_Hidden": "true", "Inp_Rectangle_ZOrder": "0", "m_magic": "572077809"},
    "CB22100_EA": {"CountOrders": "5", "FirstBuyStop": "0.0", "FirstBuyLimit": "0.0", "FirstSellStop": "0.0", "FirstSellLimit": "0.0", "DeltaFirstBuyStop": "15.0", "DeltaFirstBuyLimit": "15.0", "DeltaFirstSellStop": "15.0", "DeltaFirstSellLimit": "15.0", "UseBuyStop": "false", "UseBuyLimit": "false", "UseSellStop": "false", "UseSellLimit": "false", "StepStop": "50", "StepLimit": "50", "VolumeStop": "0.01", "VolumeLimit": "0.01", "CoefficientStop": "1.6", "CoefficientLimit": "1.6", "ProfitClose": "10.0", "LossClose": "-100.0", "Expiration": "60", "StopLoss": "50.0", "TakeProfit": "0.0", "m_magic": "56556720"},
    "CB22122_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "Inp_First_ma_period": "160", "Inp_First_ma_shift": "0", "Inp_Second_ma_period": "80", "Inp_Second_ma_shift": "1", "Inp_Third_ma_period": "20", "Inp_Third_ma_shift": "2", "InpIndent": "1", "InpPause": "45", "m_magic": "220392216"},
    "CB22127_EA": {"InpLots": "0.1", "InpStopLoss": "45", "InpTakeProfit": "45", "InpTrailingStop": "5", "InpTrailingStep": "5", "Inp_CHO_fast_ma_period": "3", "Inp_CHO_slow_ma_period": "10", "InpFlat": "40.0", "InpOpen": "110.0", "InpCount": "20", "InpPercent": "55.0", "m_magic": "22452216"},
    "CB22142_EA": {"InpLots": "0.1", "InpStopLoss": "50", "InpTakeProfit": "50", "InpRollback": "20", "InpChannelOpenClose": "18", "InpChannelRollback": "3", "Inp_Rectangle_Width": "2", "Inp_Rectangle_Fill": "false", "Inp_Rectangle_Back": "false", "Inp_Rectangle_Selection": "false", "Inp_Rectangle_Hidden": "true", "Inp_Rectangle_ZOrder": "0", "m_magic": "55998580"},
    "CB22304_EA": {"StopLoss": "30", "TakeProfit": "100", "EA_Magic": "12345", "MA_Period1": "25", "MA_Period2": "30", "resistance": "15"},
    "CB22353_EA": {"InpMaximumRisk": "0.02", "InpDecreaseFactor": "3", "InpFirstSLTP": "8", "InpSeconSLTP": "13", "InpThirdSLTP": "21", "InpStartHour": "20", "InpEndHour": "22", "Inp_MA_Env_ma_period": "109", "Inp_MA_Env_ma_shift": "0", "Inp_Env_deviation": "0.05", "m_magic": "474995670"},
    "CB22398_EA": {"StopLoss": "15", "TakeProfit": "15", "EA_Magic": "12345"},
    "CB22409_EA": {"InpLots": "1.0", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpCurrentBar": "0", "InpComparableBar": "15", "m_magic": "13811595"},
    "CB22465_EA": {"InpLots": "1.0", "InpLotsCoefficient": "2.0", "InpLotsMax": "10.0", "InpTakeProfit": "50", "m_magic": "231930592"},
    "CB22595_EA": {"InpStopLoss": "0", "InpTakeProfit": "0", "InpVolumeLorOrRisk": "1.0", "m_magic": "344676560", "InpStartHour": "10", "InpSearchDepth": "3"},
    "CB22609_EA": {"InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5"},
    "CB22647_EA": {"InpMaximumRisk": "0.02", "InpDecreaseFactor": "3", "InpHistoryDays": "60", "InpStopLoss": "0", "InpTrailingStop": "5", "InpTrailingStep": "5", "Inp_CCI_ma_period": "14", "Inp_CCI_level": "100", "Inp_CCI_bar_current": "0", "Inp_CCI_bar_prev": "1", "Inp_MA_ma_period": "120", "Inp_MA_bar_current": "0", "Inp_MA_delta": "0.001", "m_magic": "191318850"},
    "CB22659_EA": {"InpLots": "1.0", "InpStep": "50", "m_magic": "383183430"},
    "CB22662_EA": {"InpLots": "1.0", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "Inp_RSI_ma_period": "30", "m_magic": "193392906"},
    "CB22678_EA": {"InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "15", "InpExpiration": "15", "InpVolumeLorOrRisk_Level_0": "1.0", "InpVolumeLorOrRisk_Level_1": "2.0", "InpVolumeLorOrRisk_Level_2": "3.0", "InpVolumeLorOrRisk_Level_3": "4.0", "InpLevel_0": "10", "InpLevel_1": "12", "InpLevel_2": "15", "InpLevel_3": "20", "m_magic": "970369488"},
    "CB22693_EA": {"InpNumberLots_1": "1.0", "InpNumberLots_2": "1.0", "InpNumberLots_3": "1.0", "x1": "100", "x2": "20", "x3": "60", "x4": "40", "sl1": "40", "tp1": "95", "x5": "100", "x6": "20", "x7": "60", "x8": "40", "sl2": "40", "tp2": "95", "x9": "100", "x10": "20", "x11": "60", "x12": "40", "sl3": "40", "tp3": "95", "m_magic": "122665745"},
    "CB22703_EA": {"InpMaximumRisk": "0.05", "InpDecreaseFactor": "6", "InpHistoryDays": "60", "InpMaxPositions": "3", "Inp_CCI_ma_period": "12", "Inp_CCI_Up_Level": "50", "Inp_CCI_Down_Level": "-50", "Inp_CCI_Current_Bar": "1", "Inp_MA_Fast_ma_period": "15", "Inp_MA_Slow_ma_period": "75", "Inp_MA_Fast_Slow_ma_shift": "0", "m_magic": "216920074"},
    "CB22718_EA": {"InpLots": "1.0", "InpStopLoss": "50", "InpTakeProfit": "1000", "InpTrailingStop": "15", "InpTrailingStep": "45", "Inp_ATR_ma_period": "3", "InpReverse": "50", "InpCoeffOfVolatility": "3.0", "m_magic": "670485245"},
    "CB22778_EA": {"InpLots": "1.0", "InpStopLoss": "100", "InpTakeProfit": "100", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpEveryTick": "false", "Inp_jaw_period": "13", "Inp_jaw_shift": "8", "Inp_teeth_period": "8", "Inp_teeth_shift": "5", "Inp_lips_period": "5", "Inp_lips_shift": "3", "m_magic": "248967376"},
    "CB22788_EA": {"InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "1.0", "InpStep": "30", "InpLotCoef": "2.0", "InpMultiplyLotCoef": "false", "InpMaxPositions": "9", "InpMaxTotalVolume": "50.0", "InpProfitTarget": "50.0", "InpMinEquity": "30.0", "InpCloseAll": "false", "m_magic": "35814657", "InpStartHour": "10", "InpEndHour": "20"},
    "CB22870_EA": {"InpLots": "3.0", "InpStopLoss": "30", "InpStopLossToFibo": "20", "InpTrailingStop": "30", "InpTrailingStep1": "55", "InpLotsClosePartial1": "1.0", "InpTrailingStep2": "89", "InpLotsClosePartial2": "1.0", "InpTrailingStep3": "144", "InpTunnelBandWidth": "5", "InpTunnelSafeZone": "120", "LondonOpen": "true", "NewYorkOpen": "true", "TokyoOpen": "false", "Inp_MA_Fast_ma_period": "5", "Inp_MA_Slow_ma_period": "12", "Inp_MA_ma_shift": "0", "Inp_RSI_ma_period": "21", "m_magic": "373062807"},
    "CB22884_EA": {"InpStopLoss": "50", "InpTrailingStop": "5", "InpTrailingStep": "15", "InpVolumeLorOrRisk": "1.0", "m_magic": "328339530", "InpHour_1": "10", "InpHour_2": "11", "InpHour_3": "12", "Inp_ATR_ma_period": "3"},
    "CB22889_EA": {"InpLots": "1.0", "InpSLTP": "100", "InpBuy": "true", "InpSell": "true", "m_magic": "103535970"},
    "CB22906_EA": {"InpLots": "1.0", "InpStopLossBuy": "50", "InpTakeProfitBuy": "50", "InpStopLossSell": "50", "InpTakeProfitSell": "50", "InpTrailingStop": "5", "InpTrailingStep": "15", "Inp_MA_ma_period": "14", "Inp_MA_ma_shift": "1", "Inp_Laguerre_gamma": "0.7", "m_magic": "528023380"},
    "CB22914_EA": {"InpLots": "1.0", "InpStopLoss": "300", "InpCalcPeriod": "4", "Inp_MA_ma_period": "7", "Inp_MA_ma_shift": "0", "m_magic": "283811145"},
    "CB22933_EA": {"InpLots": "1.0", "InpStopLoss": "150", "InpTakeProfit": "150", "InpTrailingStop": "150", "InpTrailingStep": "150", "InpSignalRatio": "1.6", "m_magic": "616488869"},
    "CB22977_EA": {"InpLots": "1.0", "InpUseBuy": "true", "InpBullBars": "2", "InpUseSell": "false", "InpBearsBars": "1", "m_magic": "40375488"},
    "CB23027_EA": {"InpLots": "1.0", "shag": "0.001", "mnoj": "2", "m_magic": "268388736"},
    "CB23029_EA": {"InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "1.0", "Inp_ADX_adx_period": "30", "Inp_ADX_Level": "20", "Inp_Bands_bands_period": "10", "Inp_Bands_deviation": "1.5", "m_magic": "90734310"},
    "CB23039_EA": {"InpLots": "1.0", "InpStopLoss": "50", "InpTakeProfit": "50", "Inp_SAR_step": "0.02", "Inp_SAR_maximum": "0.2", "InpBarCurrent": "1", "m_magic": "82139559"},
    "CB23040_EA": {"InpLots": "1.0", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "Inp_MA_ma_period": "100", "Inp_MA_ma_shift": "0", "Inp_MACD_fast_ema_period": "12", "Inp_MACD_slow_ema_period": "26", "Inp_MACD_signal_period": "9", "m_magic": "273212196"},
    "CB23061_EA": {"InpLots": "1.0", "InpStopLoss": "150", "InpTakeProfit": "150", "m_magic": "241147280", "InpUseTime": "true", "InpStartHour": "10", "InpEndHour": "5", "Inp_CCI_ma_period": "14", "Inp_CCI_Lelel_UP": "200", "Inp_CCI_Lelel_DOWN": "-200", "Inp_CCI_Lelel_BUY": "-100", "Inp_CCI_Lelel_SELL": "100", "Inp_MA_ma_period": "200", "Inp_MA_ma_shift": "0"},
    "CB23073_EA": {"InpLots": "1.0", "InpStopLoss": "50", "InpTakeProfit": "50", "Inp_ma_period": "14", "Inp_CCI_Level": "150", "Inp_WPR_Level_UP": "-15", "Inp_WPR_Level_DOWN": "-85", "Inp_DayImpuls_Level": "50", "InpProfitTarget": "100", "InpLossTarget": "-100", "InpPred": "40.0", "InpLotCoefficient": "2.0", "m_magic": "185246468"},
    "CB23108_EA": {"InpLots": "1.0", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "m_magic": "125665938", "InpStartHour": "5", "InpUseClosePos": "true", "InpEndHour": "10"},
    "CB23152_EA": {"OpenBUY": "true", "OpenSELL": "true", "CloseBySignal": "true", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "RSIperiod": "14", "RsiBuyLevel": "30.0", "RsiSellLevel": "70.0", "InpVolumeLorOrRisk": "1.0", "m_magic": "79506350", "InpTimeControl": "true", "InpStartHour": "10", "InpEndHour": "5"},
    "CB23155_EA": {"InpLots": "1.0", "InpStopLoss": "50", "InpTakeProfit": "50", "m_magic": "177793790"},
    "CB23201_EA": {"InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "25", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "1.0", "Inp_STO_Kperiod": "5", "Inp_STO_Dperiod": "3", "Inp_STO_slowing": "3", "Inp_STO_Level_UP": "75", "Inp_STO_Level_DOWN": "25", "m_magic": "152491416"},
    "CB23220_EA": {"InpStopLoss": "150", "InpTrailingStop": "25", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "1.0", "Inp_MA_ma_period": "20", "Inp_MA_ma_shift": "0", "x11": "100", "x21": "100", "x31": "100", "x41": "100", "x12": "100", "x22": "100", "x32": "100", "x42": "100", "pass": "1", "m_magic": "378919087"},
    "CB23223_EA": {"InpStopLoss": "0", "InpTakeProfit": "0", "InpVolumeLorOrRisk": "1.0", "InpMinGap": "1", "InpMaxPositions": "15", "InpPrintLog": "false", "m_magic": "152491416"},
    "CB23234_EA": {"InpStopLoss": "150", "InpTakeProfit": "150", "InpTrailingStop": "25", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "1.0", "Inp_period": "13", "Inp_gamma": "0.6", "Inp_Shift": "0", "m_magic": "91347324", "InpTimeControl": "true", "InpStartHour": "10", "InpEndHour": "16"},
    "CB23239_EA": {"InpStopLoss": "150", "InpTakeProfit": "150", "InpVolumeLorOrRisk": "1.0", "Inp_EMA_ma_period": "28", "Inp_LWMA_ma_period": "8", "Inp_MA_ma_shift": "0", "Inp_RSI_ma_period": "14", "InpPrintLog": "false", "m_magic": "835741114"},
    "CB23255_EA": {"InpLots": "1.0", "InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "3.0", "m_magic": "166399440"},
    "CB23288_EA": {"InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "35", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "1.0", "InpTimeControl": "false", "InpStartHour": "9", "InpStartMinute": "58", "InpIndent": "3", "InpNumberOfBars": "15", "m_magic": "426819408"},
    "CB23297_EA": {"InpLots": "1.0", "InpStopLoss": "25", "InpTakeProfit": "50", "InpTrailingStop": "0", "InpTrailingStep": "5", "InpIndent": "15", "m_magic": "46207360"},
    "CB23325_EA": {"InpStopLoss": "35", "InpTakeProfit": "30", "InpTrailingStop": "0", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "1.0", "Inp_MACD_fast_ema_period": "15", "Inp_MACD_slow_ema_period": "33", "Inp_MACD_signal_period": "11", "InpPrintLog": "false", "m_magic": "7396272"},
    "CB23334_EA": {"InpProfit": "15", "InpSliding": "3", "InpStopLoss": "0.03", "InpTakeProfit": "0.05", "InpOffset": "0.01", "InpMaxPositions": "3", "InpVolumeLorOrRisk": "1.0", "m_magic": "31857468", "InpStartHour": "10", "InpStartMinute": "5"},
    "CB23344_EA": {"InpMainSliding": "11", "InpWorkingSliding": "7", "InpVolumeLorOrRisk": "5.0", "Inp_VHF_N": "9", "InpReverse": "true", "InpPrintLog": "false", "m_magic": "0"},
    "CB23348_EA": {"InpLots": "1", "InpStopLoss": "25", "InpTakeProfit": "70", "InpTrailingStop": "0", "InpTrailingStep": "5", "InpIndent": "15", "InpPrintLog": "false", "m_magic": "46207360"},
    "CB23358_EA": {"InpVolumeLorOrRisk": "1.0", "InpPrintLog": "false", "m_magic": "13863572", "InpTimeControl": "true", "InpStartHour": "10", "InpEndHour": "5"},
    "CB23383_EA": {"InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "25", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "1.0", "Inp_Fast_MA_ma_period": "10", "Inp_Fast_MA_ma_shift": "0", "Inp_Normal_MA_ma_period": "30", "Inp_Normal_MA_ma_shift": "3", "Inp_Slow_MA_ma_period": "60", "Inp_Slow_MA_ma_shift": "6", "Inp_Fast_SAR_step": "0.02", "Inp_Fast_SAR_maximum": "0.2", "Inp_Normal_SAR_step": "0.02", "Inp_Normal_SAR_maximum": "0.2", "InpPrintLog": "false", "m_magic": "34820910"},
    "CB23394_EA": {"InpVolumeLorOrRisk": "1.0", "InpTrailingStop": "150", "InpTrailingStep": "5", "InpIndent": "3", "InpPrintLog": "false", "m_magic": "645138312"},
    "CB23421_EA": {"InpStopLoss": "50", "InpTakeProfit": "140", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "3.0", "InpReverse": "false", "InpCloseOpposite": "false", "InpPrintLog": "false", "m_magic": "363193656"},
    "CB23431_EA": {"InpStopLoss": "50", "InpTakeProfit": "140", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "3.0", "Inp_MACD_fast_ema_period": "13", "Inp_MACD_slow_ema_period": "26", "Inp_MACD_signal_period": "10", "Inp_Alligator_jaw_period": "13", "Inp_Alligator_jaw_shift": "8", "Inp_Alligator_teeth_period": "8", "Inp_Alligator_teeth_shift": "5", "Inp_Alligator_lips_period": "5", "Inp_Alligator_lips_shift": "3", "Inp_RSI_ma_period": "14", "InpPrintLog": "false", "m_magic": "711735486", "InpTimeControl": "true", "InpStartHour": "10", "InpEndHour": "5"},
    "CB23434_EA": {"InpVolumeLorOrRisk": "3.0", "Inp_Fast_MA_ma_period": "9", "Inp_Fast_MA_ma_shift": "0", "Inp_Normal_MA_ma_period": "30", "Inp_Normal_MA_ma_shift": "3", "Inp_StdDev_ma_period": "20", "Inp_StdDev_ma_shift": "0", "InpPrintLog": "false", "m_magic": "648950400"},
    "CB23443_EA": {"InpStopLoss": "30", "InpTakeProfit": "90", "InpTrailingStop": "30", "InpTrailingStep": "5", "InpIndent": "0", "InpAllowablSpread": "5", "InpVolumeLorOrRisk": "3.0", "InpPrintLog": "false", "m_magic": "363193656"},
    "CB23452_EA": {"InpStopLoss": "50", "InpTakeProfit": "50", "InpTrailingStop": "10", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "3.0", "Inp_Alligator_jaw_period": "13", "Inp_Alligator_jaw_shift": "8", "Inp_Alligator_teeth_period": "8", "Inp_Alligator_teeth_shift": "5", "Inp_Alligator_lips_period": "5", "Inp_Alligator_lips_shift": "3", "InpReverse": "true", "InpCloseOpposite": "false", "InpPrintLog": "false", "m_magic": "63896190"},
    "CB23484_EA": {"InpStopLoss": "50", "InpTakeProfit": "140", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "3.0", "InpFreeMarginMin": "200", "Inp_CCI_ma_period": "13", "Inp_MA_Fast_period": "5", "Inp_MA_Slow_period": "9", "Inp_MACD_fast_ema_period": "8", "Inp_MACD_slow_ema_period": "17", "Inp_MACD_signal_period": "9", "Inp_STO_Kperiod": "5", "Inp_STO_Dperiod": "3", "Inp_STO_slowing": "3", "Inp_RSI_ma_period": "9", "InpReverse": "false", "InpPrintLog": "false", "m_magic": "163170000"},
    "CB23487_EA": {"InpStopLoss": "40", "InpTakeProfit": "60", "InpTrailingStop": "10", "InpTrailingStep": "10", "InpVolumeLorOrRisk": "3.0", "Inp_MA_ma_period": "60", "Inp_MA_ma_shift": "0", "Inp_StdDev_ma_period": "50", "Inp_StdDev_ma_shift": "0", "InpCurrentBar": "1", "InpPosOnDirection": "1", "InpIndent": "1", "InpReverse": "false", "InpCloseOpposite": "false", "InpPrintLog": "false", "m_magic": "363193656"},
    "CB23495_EA": {"InpStopLoss": "45", "InpTakeProfit": "105", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "3.0", "Inp_MA_ma_period": "20", "Inp_MA_ma_shift": "1", "Inp_STO_Kperiod": "5", "Inp_STO_Dperiod": "3", "Inp_STO_slowing": "3", "InpReverse": "false", "InpCloseOpposite": "false", "InpPrintLog": "false", "m_magic": "143285164"},
    "CB23499_EA": {"InpStopLoss": "80", "InpTakeProfit": "70", "InpTrailingStop": "10", "InpTrailingStep": "5", "InpStep": "25", "InpVolumeLorOrRisk": "3.0", "InpReverse": "false", "InpCloseOpposite": "false", "InpPrintLog": "false", "m_magic": "363193656"},
    "CB23542_EA": {"InpStopLoss": "50", "InpTakeProfit": "40", "InpTrailingStop": "10", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "3.0", "InpCandleShift": "2", "InpChannelHeight": "34", "InpTimeControl": "true", "InpStartHour": "10", "InpEndHour": "5", "InpReverse": "false", "InpPrintLog": "false", "m_magic": "494170620"},
    "CB23556_EA": {"InpStopLoss": "50", "InpTakeProfit": "140", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "3.0", "Inp_MA_Fast_ma_period": "9", "Inp_MA_Slow_ma_period": "24", "Inp_MA_ma_shift": "0", "Inp_Bands_bands_period": "150", "Inp_Bands_bands_shift": "0", "Inp_Bands_deviation": "1.0", "InpReverse": "false", "InpCloseOpposite": "false", "InpPrintLog": "false", "m_magic": "138991923"},
    "CB23589_EA": {"InpStopLoss": "50", "InpTakeProfit": "140", "InpTrailingStop": "15", "InpTrailingStep": "5", "InpVolumeLorOrRisk": "3.0", "Inp_MA_ma_period": "12", "Inp_MA_ma_shift": "3", "InpOnlyOne": "false", "InpReverse": "false", "InpCloseOpposite": "false", "InpPrintLog": "false", "m_magic": "407936490"},
    "CB23595_EA": {"InpStopLoss": "50", "InpTakeProfit": "140", "InpTrailingStop": "5", "InpTrailingStep": "5", "InpTakeHalfProfit": "false", "InpVolumeLorOrRisk": "3.0", "Inp_ADX_adx_period": "6", "InpADXBarsInterval": "2", "InpADXMinimum": "20", "Inp_MACD_fast_ema_period": "10", "Inp_MACD_slow_ema_period": "26", "Inp_MACD_signal_period": "8", "InpMACDBarsInterval": "4", "InpMACDMinimum": "30", "InpPrintLog": "false", "m_magic": "53056490"},
    "CB25009_EA": {"InpStopLoss": "20", "InpTakeProfit": "10", "InpTrailingStop": "0", "InpTrailingStep": "1", "Ratio": "1.6", "InpLots": "0.0", "Risk": "3.0", "m_magic": "555", "m_slippage": "3"},
    "CB25249_EA": {"InpStopLoss": "500", "InpTakeProfit": "20", "InpTrailingStop": "10", "InpTrailingStep": "5", "InpVolumeLotOrRisk": "3.0", "InpOnlyOne": "true", "InpReverse": "true", "InpCloseOpposite": "true", "InpPrintLog": "true", "m_magic": "363193656"},
    "CB25774_EA": {"InpStopLoss": "70", "InpTakeProfit": "45", "InpTrailingFrequency": "10", "InpTrailingStop": "0", "InpTrailingStep": "5", "InpVolumeLotOrRisk": "3.0", "InpOnlyOne": "true", "InpReverse": "false", "InpCloseOpposite": "false", "InpPrintLog": "false", "InpMagic": "8654"},
    "CB26317_EA": {"Inp_element_3632865": "2.0"},
    "CB26333_EA": {"Inp_element_9791287": "0.02", "Inp_element_9802791": "0.2", "Inp_element_5723569": "false", "Inp_element_3632865": "0.1", "Inp_element_5744004": "0.05"},
    "CB26451_EA": {"Inp_element_3632865": "0.1"},
    "CB27938_EA": {"SL_ATR_FACTOR": "1.75", "AR_FIXED_TRAILING_PTS": "2700", "InpAtrPeriod": "14"},
    "CB29797_EA": {"TS_ma_period": "50", "TS_ma_shift": "0", "TS_show": "true", "pre_init": "false", "max_sl": "100", "MA_bars_trail": "1", "trail_behind_MA": "5", "trail_behind_price": "30", "trail_behind_negative": "60", "trail_step": "0"},
    "CB31843_EA": {},
    "CB32616_EA": {"dP50Level": "1.08261", "dP61Level": "1.07811", "dP100Level": "1.06370", "dTarget2": "1.10178", "dRisk": "2"},
    "CB32695_EA": {"bands_period": "20", "rsi_period": "13", "rsi_up": "70", "rsi_down": "30", "Lot": "0.1", "SL": "0.0238", "MAperiod": "200", "magic": "1234", "autolot": "true", "risk": "0.05"},
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

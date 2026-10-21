"""Per-EA tester input defaults and [TesterInputs] line building.

Pure module (no MT5 / Wine imports) so it is importable by system python and tests.
Every EA input is written explicitly: MT5 silently applies the last GUI .set for any input left out,
and a bare "k=v" keeps an optimize flag cached from an earlier run, so fixed inputs are pinned as
v||v||1||v||N. Unknown input names are refused instead of silently ignored.
"""
import os

BLESSING_STRINGS = {"AlertSound", "DDorLevel", "GridSetArray", "HedgeSymbol", "Holidays", "LabelAcc", "LabelAdv", "LabelBBS", "LabelCCI", "LabelDisplay", "LabelEDD", "LabelEE", "LabelEH", "LabelES", "LabelEST", "LabelEST0", "LabelGS", "LabelGrid", "LabelGridOpt", "LabelHS", "LabelHS0", "LabelIchi", "LabelLS", "LabelMA", "LabelMACD", "LabelOS", "LabelOS0", "LabelOpt", "LabelSG", "LabelSto", "LabelTS", "LabelTST", "LabelUE", "Notes", "SetCountArray", "TP_SetArray", "TradeComment", "Version_3_9_6_23", "displayFont", "eopb", "eopb1", "s1", "s2", "s3"}
STRING_INPUTS = {"InpComment"} | BLESSING_STRINGS

_CORE_DEFAULTS = {
    "InpTimeframe": "16385", "InpSlippagePoints": "30", "InpMaxSpreadPoints": "150",
    "InpRiskMode": "1", "InpRiskValue": "1.0",
    "InpSpreadWaitMin": "30", "InpDailyLossPct": "4.0", "InpMonthlyLossPct": "12.0", "InpTradeLog": "true",
    "InpLogEveryBar": "false",   # hourly status lines are for live/VPS, too noisy for tester runs
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
    },
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
    # ORB_EA v1.00 compiled defaults (Zarattini/Barbon/Aziz 2024 base ORB on forex: New York 09:30 open, 5-min range,
    # stop 0.10 x D1 ATR(14), close 23:50 server, spread cap 3 pips, server clock UTC+2 with US DST)
    "ORB_EA": dict(_CORE_DEFAULTS, **{
        "InpMagic": "261021", "InpComment": "ORB", "InpTimeframe": "5", "InpMaxSpreadPoints": "30", "InpSpreadWaitMin": "0",
        "InpSession": "1", "InpStopATR": "0.10", "InpATRPeriod": "14", "InpEodHour": "23", "InpEodMinute": "50",
        "InpSrvStdOffsetHours": "2", "InpSrvDstRule": "2",
    }),
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

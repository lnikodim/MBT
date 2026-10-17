import os
import time

import pytest

import ea_profiles as P


def test_expert_path_known_and_unknown():
    assert P.expert_path("MeanRev_EA") == "Advisors\\MeanRev_EA.ex5"
    assert P.expert_path("MACD_Cross_EA") == "Advisors\\MACD_Cross_EA.ex5"
    with pytest.raises(ValueError):
        P.expert_path("NoSuch_EA")


def test_profiles_have_core_inputs():
    core = ["InpMagic", "InpTimeframe", "InpComment", "InpSlippagePoints", "InpMaxSpreadPoints",
            "InpRiskMode", "InpRiskValue", "InpSpreadWaitMin", "InpDailyLossPct", "InpMonthlyLossPct",
            "InpTradeLog", "InpLogEveryBar"]
    for name in ("MACD_Cross_EA", "MeanRev_EA", "VWAP_RSI_EA", "HoLo_EA", "EuroRiddle_EA", "Icarus_EA", "VWAP_EMA_Cross_EA", "EMA_VWAP_Trail_EA", "Camvcvoo_EA", "Donchian_Breakout_EA", "RSI_Reversal_EA", "MA_Channel_EA", "TEB_MTF_EA", "EMA_RSI_CCI_EA", "FZMR_EA"):
        for k in core:
            assert k in P.PROFILES[name], (name, k)
    assert P.PROFILES["MeanRev_EA"]["InpMagic"] == "240819"
    assert P.PROFILES["MACD_Cross_EA"]["InpMagic"] == "240817"
    assert P.PROFILES["VWAP_RSI_EA"]["InpMagic"] == "261006"
    assert P.PROFILES["VWAP_EMA_Cross_EA"]["InpMagic"] == "261012"
    assert P.PROFILES["VWAP_EMA_Cross_EA"]["InpTimeframe"] == "5"      # compiled default M5
    assert P.PROFILES["EMA_VWAP_Trail_EA"]["InpMagic"] == "261013"
    assert P.PROFILES["EMA_VWAP_Trail_EA"]["InpTimeframe"] == "15"     # compiled default M15
    assert P.PROFILES["EMA_VWAP_Trail_EA"]["InpTrailATR"] == "true"      # v1.02: trailing can be switched off
    assert P.PROFILES["Camvcvoo_EA"]["InpMagic"] == "261014"
    assert P.PROFILES["Camvcvoo_EA"]["InpTimeframe"] == "16385"          # H1
    assert P.PROFILES["Camvcvoo_EA"]["InpSpreadWaitMin"] == "0"           # three-position set: no single pending retry
    assert P.PROFILES["Donchian_Breakout_EA"]["InpMagic"] == "261015"
    assert P.PROFILES["Donchian_Breakout_EA"]["InpSpreadWaitMin"] == "0"  # target = R x stop from the signal price: no retry
    assert P.PROFILES["Donchian_Breakout_EA"]["InpTimeframe"] == "16388"   # v1.01: H4, long-only, 2R (amendment 1)
    assert P.PROFILES["Donchian_Breakout_EA"]["InpAllowShort"] == "false"
    assert P.PROFILES["Donchian_Breakout_EA"]["InpBreakEvenR"] == "0.0"
    assert P.PROFILES["EMA_VWAP_Trail_EA"]["InpMaxPositions"] == "1"     # v1.03 stacking off
    assert P.PROFILES["EMA_VWAP_Trail_EA"]["InpHoldThroughFiltered"] == "false"
    for k, v in (("InpTrendEMA", "0"), ("InpHTFBias", "0"), ("InpSessionStart", "0"), ("InpSessionEnd", "24")):
        assert P.PROFILES["EMA_VWAP_Trail_EA"][k] == v, k                 # v1.01 filters default off


def test_rsi_reversal_v120_profile_is_on_eacore():
    p = P.PROFILES["RSI_Reversal_EA"]
    assert p["InpMagic"] == "261004" and p["InpTimeframe"] == "16390"       # H6 RSI timeframe (v1.10 InpRsiTimeframe)
    assert p["InpRiskMode"] == "1" and p["InpRiskValue"] == "1.0"           # EACore enum: PERCENT is 1 (v1.10 had 0)
    assert (p["InpRsiPeriod"], p["InpRsiBuyLevel"], p["InpRsiSellLevel"]) == ("4", "40.0", "55.0")
    assert (p["InpMaTimeframe"], p["InpMaPeriod"]) == ("16396", "250")
    assert (p["InpStopLossPct"], p["InpTakeProfitPct"]) == ("1.0", "5.0")
    assert (p["InpBreakEvenPct"], p["InpBreakEvenLockPct"]) == ("0.0", "0.1")   # v1.20 break-even, off until the prereg decides
    assert (p["InpTrailTriggerPct"], p["InpTrailDistancePct"], p["InpTrailStepPct"]) == ("1.0", "1.0", "0.05")
    for gone in ("InpRsiTimeframe", "InpSlippage", "InpLotsWithoutSL"):
        assert gone not in p, gone


def test_icarus_profile_pins_the_grid_defaults():
    p = P.PROFILES["Icarus_EA"]
    assert p["InpMagic"] == "261009"
    assert p["InpDailyLossPct"] == "0" and p["InpMonthlyLossPct"] == "0"   # no entry gate for EACore's stops in a grid
    assert p["InpMaxSpreadPoints"] == "100" and p["InpSpreadWaitMin"] == "0"
    assert (p["InpGridProgression"], p["InpLotProgression"], p["InpMaxPositions"]) == ("3", "3", "6")
    assert P.PROFILES["VWAP_RSI_EA"]["InpSpreadWaitMin"] == "0"    # a retried bar-level stop would re-anchor
    assert P.PROFILES["VWAP_RSI_EA"]["InpMinStopATR"] == "0.1"      # micro-stop guard (review finding #1)


def test_merge_inputs_overrides_and_copies():
    merged = P.merge_inputs("MeanRev_EA", {"InpSLATR": "2.0"})
    assert merged["InpSLATR"] == "2.0"
    assert P.PROFILES["MeanRev_EA"]["InpSLATR"] == "1.5"   # profile untouched


def test_merge_inputs_rejects_unknown():
    with pytest.raises(ValueError, match="InpSLATRR"):
        P.merge_inputs("MeanRev_EA", {"InpSLATRR": "2.0"})


def test_parse_range_ok_and_refusals():
    assert P.parse_range("InpSLATR=1.0:0.5:2.0") == ("InpSLATR", ("1.0", "0.5", "2.0"))
    for bad in ("InpZeroLineFilter=false:0:true", "InpSLATR=1:0:2", "InpSLATR=2:1:1", "InpSLATR=1:2"):
        with pytest.raises(ValueError):
            P.parse_range(bad)


def test_tester_input_lines_pins_ranges_and_strings():
    inputs = {"InpComment": "MREV", "InpSLATR": "1.5", "InpMaxBars": "12"}
    lines = P.tester_input_lines(inputs, {"InpSLATR": ("1.0", "0.5", "2.0")})
    assert lines == ["InpComment=MREV",
                     "InpSLATR=1.5||1.0||0.5||2.0||Y",
                     "InpMaxBars=12||12||1||12||N"]


def test_tester_input_lines_rejects_range_for_unknown_input():
    with pytest.raises(ValueError):
        P.tester_input_lines({"InpSLATR": "1.5"}, {"InpNope": ("1", "1", "2")})


def test_tester_log_name():
    assert P.tester_log_name("MeanRev_EA", "XAUUSD", "240819") == "MeanRev_EA_XAUUSD_240819_tester_trades.csv"


def test_pick_fresh_log_accepts_new_file(tmp_path):
    f = tmp_path / "log.csv"
    started = time.time() - 1
    f.write_text("x")
    assert P.pick_fresh_log(str(f), started) == str(f)


def test_pick_fresh_log_rejects_stale_or_missing(tmp_path):
    f = tmp_path / "log.csv"
    f.write_text("x")
    old = time.time() - 3600
    os.utime(f, (old, old))
    assert P.pick_fresh_log(str(f), time.time()) is None
    assert P.pick_fresh_log(str(tmp_path / "missing.csv"), 0) is None


def test_atr_candle_breakout_profile():
    prof = P.PROFILES["ATR Candle Breakout EA"]
    assert prof["InpMagicNumber"] == "14" and "InpMagic" not in prof
    assert P.expert_path("ATR Candle Breakout EA") == "Advisors\\ATR Candle Breakout EA.ex5"


def test_trade_log_name_for_needs_inpmagic():
    assert P.trade_log_name_for("MeanRev_EA", "XAUUSD", P.PROFILES["MeanRev_EA"]) == \
        "MeanRev_EA_XAUUSD_240819_tester_trades.csv"
    assert P.trade_log_name_for("ATR Candle Breakout EA", "XAUUSD", P.PROFILES["ATR Candle Breakout EA"]) is None


def test_holo_profile_matches_design():
    p = P.PROFILES["HoLo_EA"]
    assert p["InpMagic"] == "261007" and p["InpSpreadWaitMin"] == "0"      # entry exactly at the level: no delayed retry
    assert p["InpTimeframe"] == "15" and p["InpLevelTF"] == "16385"         # M15 trigger, H1 levels
    assert (p["InpSessionStartNY"], p["InpSessionEndNY"], p["InpServerNYOffset"]) == ("480", "1015", "7")


def test_euroriddle_profile_matches_prereg():
    p = P.PROFILES["EuroRiddle_EA"]
    assert p["InpMagic"] == "261008" and p["InpSpreadWaitMin"] == "0"
    assert (p["InpStopPips"], p["InpTargetPips"], p["InpMaxSpreadPoints"]) == ("15", "25", "20")   # 2 pips on EURUSD
    assert (p["InpMode"], p["InpFilter"], p["InpADRPeriod"], p["InpADRFrac"], p["InpLateStartNY"]) == ("0", "0", "20", "1.0", "720")


def test_blessing_profile_is_complete_and_strings_are_bare():
    p = P.PROFILES["Blessing_3"]
    assert len(p) == 190
    assert (p["UseMM"], p["LAF"], p["Lot"], p["Multiplier"], p["MaxTrades"]) == ("true", "0.5", "0.01", "1.4", "15")
    assert (p["GridSetArray"], p["TP_SetArray"], p["SetCountArray"]) == ("25,50,100", "50,100,200", "4,4")
    assert {"GridSetArray", "TradeComment", "Holidays", "HedgeSymbol"} <= P.STRING_INPUTS
    lines = P.tester_input_lines(p, {})
    assert "GridSetArray=25,50,100" in lines and "MaxTrades=15||15||1||15||N" in lines


def test_ma_channel_v101_profile_pins_the_stage_a_winner():
    p = P.PROFILES["MA_Channel_EA"]
    assert p["InpMagic"] == "261016" and p["InpComment"] == "MA_CH"
    assert p["InpTimeframe"] == "16385" and p["InpSpreadWaitMin"] == "0"   # H1; target = R x stop: no spread retry
    assert (p["InpFastMA"], p["InpSlowMA"], p["InpChannelMA"]) == ("5", "10", "20")
    assert p["InpEntryMode"] == "1" and p["InpExitMode"] == "0"            # v1.01: pullback entry, channel exit
    assert p["InpAllowShort"] == "false" and p["InpTrendEMA"] == "0"       # long-only, no trend filter


def test_teb_mtf_profile_pins_the_forum_post():
    p = P.PROFILES["TEB_MTF_EA"]
    assert p["InpMagic"] == "261017" and p["InpComment"] == "TEB_MTF"
    assert p["InpTimeframe"] == "5" and p["InpTrendTF"] == "30"              # M5 entries, M30 trend
    assert p["InpMaxSpreadPoints"] == "20" and p["InpSpreadWaitMin"] == "0"  # 2-pip cap, no retry on a pip-geometry scalp
    assert (p["InpFastEMA"], p["InpSlowEMA"], p["InpRsiPeriod"]) == ("5", "12", "20")
    assert p["InpStopPips"] == "10.0" and p["InpTargetPips"] == "10.0" and p["InpSecondLot"] == "true"
    assert p["InpUseSessions"] == "true" and (p["InpS1Start"], p["InpS2Start"], p["InpS3Start"]) == ("10", "14", "3")


def test_ema_rsi_cci_profile_pins_the_forum_post():
    p = P.PROFILES["EMA_RSI_CCI_EA"]
    assert p["InpMagic"] == "261018" and p["InpComment"] == "EMARC"
    assert p["InpTimeframe"] == "16385" and p["InpMaxSpreadPoints"] == "30"          # H1, 3-pip spread cap
    assert (p["InpFastEMA"], p["InpSlowEMA"], p["InpRsiPeriod"], p["InpCciPeriod"]) == ("5", "12", "21", "80")
    assert p["InpRsiLevel"] == "50.0" and p["InpCciLevel"] == "0.0"                   # user: CCI midline 0
    assert p["InpStopPips"] == "35.0" and p["InpTargetPips"] == "0.0" and p["InpAllowShort"] == "true"


def test_fzmr_profile_pins_the_v6_defaults():
    p = P.PROFILES["FZMR_EA"]
    assert p["InpMagic"] == "261019" and p["InpComment"] == "FZMR"
    assert p["InpTimeframe"] == "15" and p["InpMaxSpreadPoints"] == "150" and p["InpSpreadWaitMin"] == "0"  # M15; v6 skips a blocked bar
    assert (p["InpZPeriod"], p["InpZThreshold"], p["InpERPeriod"], p["InpMaxER"]) == ("20", "2.0", "10", "0.40")
    assert (p["InpFastEMAPeriod"], p["InpSlowEMAPeriod"], p["InpRSIPeriod"]) == ("50", "200", "7")
    assert (p["InpSLMultiplier"], p["InpTPMultiplier"], p["InpTargetR"], p["InpMaxHoldBars"]) == ("2.0", "2.5", "0.0", "24")
    assert (p["InpStartHour"], p["InpEndHour"], p["InpSkipNYOpen"], p["InpAllowShort"]) == ("2", "20", "true", "true")


def test_fzmr_v101_filters_default_off():
    p = P.PROFILES["FZMR_EA"]
    assert (p["InpSkipFromHour"], p["InpSkipToHour"], p["InpMaxBarRetrace"], p["InpSellMaxDistATR"]) == ("0", "0", "0.0", "0.0")

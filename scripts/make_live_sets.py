"""Live .set files for the six-EA set (spec 2026-10-22-dd-reduction-phase1-prereg.md, phase 3b).
Base = the inputs of each EA's validated run (its tester .ini); overrides = the account's live settings.
  python3 scripts/make_live_sets.py          -> mql5/sets/ftmo_2step_50k/*.set, mql5/sets/darwinex_zero/*.set"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__)); import ea_profiles

BASE = {  # EA: (validated run, chart)
    "MACD_Cross_EA": ("macdtf_h1_20261019_210429", "XAUUSD H1"),
    "Donchian_Breakout_EA": ("lowtf_donch_h4_20261019_212257", "XAUUSD H4"),
    "RSI_Reversal_EA": ("lowtf_rsi_h6_20261019_213004", "XAUUSD H6"),
    "MA_Channel_EA": ("lowtf_mach_h1_20261019_214347", "XAUUSD H1"),
    "Donchian_Trend_EA": ("dtrend_pick_20261021_073858", "USDJPY H4"),
    "Invictus_GBPJPY_Monday_EA": ("inv131_s0_mon_20261021_131936", "GBPJPY M1 (any timeframe)"),
    "NI225_Gap_Continuation_EA": ("ni225g_m0r_20261023_174047", "NI225 M5"),   # spec 2026-10-23-ni225-gap-continuation
    "BM_TurnaroundTuesday_EA": ("tt_W_s0_20261025_214431", "WS30 D1 (FTMO: US30.cash, name not confirmed)"),   # spec 2026-10-26-addon-portfolio
}
DZ_ONLY = {"NI225_Gap_Continuation_EA"}   # the FTMO broker has no NI225 (user, 2026-10-23)
SPEC = {"NI225_Gap_Continuation_EA": "2026-10-23-ni225-gap-continuation-prereg.md",
        "BM_TurnaroundTuesday_EA": "2026-10-26-addon-portfolio-prereg.md"}
# bmtrading.de .ex5 with no source: the add-on test sized it to a 2% standalone drawdown = 0.16 x its default 5% risk. It has no EACore, so no daily stop,
# throttle or demo-only guard; a licence request is needed for live use (bmtrading.de). Inputs below are the validated run's (names as the EA declares them).
BINARY = {"BM_TurnaroundTuesday_EA"}
TT_INPUTS = {"IsWaitNewHigh": "false", "Volume": "2", "Lots": "0.01", "LotsPerMoney": "1000", "RiskPercent": "0.8", "RiskMoney": "50.0",
             "TpCalcMode": "0", "TpValue": "0.0", "SlCalcMode": "1", "SlValue": "5.0", "TimeOpenHour": "1", "TimeOpenMin": "5",
             "TimeCloseHour": "22", "TimeCloseMin": "55", "DayOpen": "1", "DayClose": "2", "BeCalcMode": "0", "BeTriggerValue": "0.0",
             "BeBufferValue": "0.05", "TslCalcMode": "0", "TslTriggerValue": "0.0", "TslValue": "100.0", "TslStepValue": "10.0",
             "IsMaFilter": "true", "MaTimeframe": "16408", "MaPeriods": "40", "MaMethod": "0", "MaAppPrice": "1", "Magic": "123454321",
             "IsChartComment": "true"}
GOLD = {"MACD_Cross_EA", "Donchian_Breakout_EA", "RSI_Reversal_EA", "MA_Channel_EA"}
ACCOUNTS = {  # folder: (title, EA daily stop %, throttle DD %)
    "ftmo_2step_50k": ("FTMO 2-Step $50k: 0.5% headline + 3% drawdown throttle, EA daily stop -3%", 3.0, 3.0),
    "darwinex_zero": ("Darwinex Zero: 0.5% constant risk, throttle off, EA daily stop -4%", 4.0, 0.0),
}

def ini_inputs(run):
    raw = open(f"reports/{run}.ini", "rb").read()
    t = raw.decode("utf-16") if raw[:2] in (b"\xff\xfe", b"\xfe\xff") else raw.decode("utf-8", "replace")
    return {k: v.split("||")[0] for k, v in (l.strip().split("=", 1) for l in t.splitlines() if "=" in l) if k.startswith("Inp")}

def live_inputs(ea, daily, thr):
    if ea in BINARY:
        return dict(TT_INPUTS)
    inp = ini_inputs(BASE[ea][0])
    if ea in GOLD:
        inp.update(InpRiskMode="1", InpRiskValue="0.5", InpMonthlyLossPct="12.0",
                   InpTradeLog="true", InpLogEveryBar="true")
    elif ea == "Donchian_Trend_EA":
        inp.update(InpRiskPercent="0.5")
    elif ea == "NI225_Gap_Continuation_EA":                   # defaults = 0.5% (SELL 0.25% on small gaps); no throttle
        inp.update(InpDailyLossPct=f"{daily:.1f}")
        return inp
    else:
        inp.update(InpLotsPer1k="0.010", InpDemoOnly="false")   # 0.5x the author's 0.2 lot per 10k
    inp.update(InpDailyLossPct=f"{daily:.1f}", InpThrottleDDPct=f"{thr:.1f}", InpThrottleFactor="0.5")   # daily stop: all six EAs
    return inp

def main():
    for folder, (title, daily, thr) in ACCOUNTS.items():
        os.makedirs(f"mql5/sets/{folder}", exist_ok=True)
        for ea, (run, chart) in BASE.items():
            if ea in DZ_ONLY and folder != "darwinex_zero":
                continue
            lines = [f"; {ea} -- {title}", f"; chart: {chart}; base inputs = validated run {run}",
                     f"; spec docs/superpowers/specs/{SPEC.get(ea, '2026-10-22-dd-reduction-phase1-prereg.md')}. Load via EA Inputs > Load."]
            lines += ea_profiles.tester_input_lines(live_inputs(ea, daily, thr), {})   # MT5's own Name=Value||start||step||stop||N
            with open(f"mql5/sets/{folder}/{ea}.set", "w", encoding="utf-16", newline="\r\n") as f:   # MT5 native: UTF-16 LE, CRLF
                f.write("\n".join(lines) + "\n")
        print("wrote", f"mql5/sets/{folder}/", sum(folder == "darwinex_zero" or ea not in DZ_ONLY for ea in BASE), "files")

if __name__ == "__main__":
    main()

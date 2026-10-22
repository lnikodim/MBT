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
}
GOLD = {"MACD_Cross_EA", "Donchian_Breakout_EA", "RSI_Reversal_EA", "MA_Channel_EA"}
ACCOUNTS = {  # folder: (title, daily stop % for the gold EAs, throttle DD %)
    "ftmo_2step_50k": ("FTMO 2-Step $50k: 0.5% headline + 3% drawdown throttle, EA daily stop -3%", 3.0, 3.0),
    "darwinex_zero": ("Darwinex Zero: 0.5% constant risk, throttle off, EA daily stop -4%", 4.0, 0.0),
}

def ini_inputs(run):
    raw = open(f"reports/{run}.ini", "rb").read()
    t = raw.decode("utf-16") if raw[:2] in (b"\xff\xfe", b"\xfe\xff") else raw.decode("utf-8", "replace")
    return {k: v.split("||")[0] for k, v in (l.strip().split("=", 1) for l in t.splitlines() if "=" in l) if k.startswith("Inp")}

def live_inputs(ea, daily, thr):
    inp = ini_inputs(BASE[ea][0])
    if ea in GOLD:
        inp.update(InpRiskMode="1", InpRiskValue="0.5", InpDailyLossPct=f"{daily:.1f}", InpMonthlyLossPct="12.0",
                   InpTradeLog="true", InpLogEveryBar="true")
    elif ea == "Donchian_Trend_EA":
        inp.update(InpRiskPercent="0.5")
    else:
        inp.update(InpLotsPer1k="0.010", InpDemoOnly="false")   # 0.5x the author's 0.2 lot per 10k
    inp.update(InpThrottleDDPct=f"{thr:.1f}", InpThrottleFactor="0.5")
    return inp

def main():
    for folder, (title, daily, thr) in ACCOUNTS.items():
        os.makedirs(f"mql5/sets/{folder}", exist_ok=True)
        for ea, (run, chart) in BASE.items():
            lines = [f"; {ea} -- {title}", f"; chart: {chart}; base inputs = validated run {run}",
                     "; spec docs/superpowers/specs/2026-10-22-dd-reduction-phase1-prereg.md. Load via EA Inputs > Load."]
            lines += ea_profiles.tester_input_lines(live_inputs(ea, daily, thr), {})   # MT5's own Name=Value||start||step||stop||N
            with open(f"mql5/sets/{folder}/{ea}.set", "w", encoding="utf-16", newline="\r\n") as f:   # MT5 native: UTF-16 LE, CRLF
                f.write("\n".join(lines) + "\n")
        print("wrote", f"mql5/sets/{folder}/", len(BASE), "files")

if __name__ == "__main__":
    main()

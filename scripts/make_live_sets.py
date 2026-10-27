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
    "NDX_Band_Breakout_EA": ("ndxbb_DZ100k_scr_20261027_072850", "NDX M1 (US100.cash on FTMO)"),   # spec 2026-10-27-ndx-band-breakout-production-prereg
}
DZ_ONLY = {"NI225_Gap_Continuation_EA"}   # the FTMO broker has no NI225 (user, 2026-10-23)
SPEC = {"NI225_Gap_Continuation_EA": "2026-10-23-ni225-gap-continuation-prereg.md",
        "NDX_Band_Breakout_EA": "2026-10-27-ndx-band-breakout-production-prereg.md"}
#--- NDX_Band_Breakout_EA per broker: the clock is the same (New York + 7 h: open 16:30, flat 22:55, so no time input changes), the symbol and its
#--- price scale are not. NDX on Darwinex quotes in 0.1 (100 points = 10 index points); FTMO's US100.cash is taken to quote in 0.01, so the caps are
#--- ten times as many points. If FTMO's digits turn out different the caps only get looser, never tighter. The symbol per account is in make_live_profiles.py.
NDX_BROKER = {"darwinex_zero": {"InpMaxSpreadPoints": "100", "InpSlippagePoints": "30"},
              "ftmo_2step_50k": {"InpMaxSpreadPoints": "1000", "InpSlippagePoints": "300"}}
GOLD = {"MACD_Cross_EA", "Donchian_Breakout_EA", "RSI_Reversal_EA", "MA_Channel_EA"}
ACCOUNTS = {  # folder: (title, EA daily stop %, throttle DD %)
    "ftmo_2step_50k": ("FTMO 2-Step $50k: 0.5% headline + 3% drawdown throttle, EA daily stop -3%", 3.0, 3.0),
    "darwinex_zero": ("Darwinex Zero: 0.5% constant risk, throttle off, EA daily stop -4%", 4.0, 0.0),
}

def ini_inputs(run):
    raw = open(f"reports/{run}.ini", "rb").read()
    t = raw.decode("utf-16") if raw[:2] in (b"\xff\xfe", b"\xfe\xff") else raw.decode("utf-8", "replace")
    return {k: v.split("||")[0] for k, v in (l.strip().split("=", 1) for l in t.splitlines() if "=" in l) if k.startswith("Inp")}

def live_inputs(ea, daily, thr, folder=None):
    inp = ini_inputs(BASE[ea][0])
    if ea in GOLD:
        inp.update(InpRiskMode="1", InpRiskValue="0.5", InpMonthlyLossPct="12.0",
                   InpTradeLog="true", InpLogEveryBar="true")
    elif ea == "Donchian_Trend_EA":
        inp.update(InpRiskPercent="0.5")
    elif ea == "NDX_Band_Breakout_EA":                        # 0.25% = add-on sizing (about 2% own drawdown); the EA's M1 status line is off
        inp.update(InpRiskMode="1", InpRiskValue="0.25", InpMonthlyLossPct="12.0", InpTradeLog="true", InpLogEveryBar="false",
                   **NDX_BROKER[folder])
    elif ea == "NI225_Gap_Continuation_EA":                   # defaults = 0.5% (SELL 0.25% on small gaps); no throttle
        inp.update(InpDailyLossPct=f"{daily:.1f}")
        return inp
    else:
        inp.update(InpDemoOnly="false")   # Invictus keeps the validated 0.006 lot per $1,000 from its run (user, 2026-10-27; 0.010 was the 0.5% headline, 1.00 lot on about 100k)
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
            lines += ea_profiles.tester_input_lines(live_inputs(ea, daily, thr, folder), {})   # MT5's own Name=Value||start||step||stop||N
            with open(f"mql5/sets/{folder}/{ea}.set", "w", encoding="utf-16", newline="\r\n") as f:   # MT5 native: UTF-16 LE, CRLF
                f.write("\n".join(lines) + "\n")
        print("wrote", f"mql5/sets/{folder}/", sum(folder == "darwinex_zero" or ea not in DZ_ONLY for ea in BASE), "files")

if __name__ == "__main__":
    main()

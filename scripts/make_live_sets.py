"""Live .set files for the six-EA set (spec 2026-10-22-dd-reduction-phase1-prereg.md, phase 3b).
Base = the inputs of each EA's validated run (its tester .ini); overrides = the account's live settings.
  python3 scripts/make_live_sets.py          -> mql5/sets/atlas_2step_50k/*.set, mql5/sets/darwinex_zero/*.set"""
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
    "NDX_Band_Breakout_EA": ("ndxbb_DZ100k_scr_20261027_072850", "NDX M1 (the symbol differs per broker, see make_live_profiles.py)"),   # spec 2026-10-27-ndx-band-breakout-production-prereg
    "Dark_Moon": ("dark_moon_compiled_defaults", "EURUSD H1 (fixed 0.01 lot)"),
    "Dark_Rea": ("dark_rea_compiled_defaults", "GBPUSD H1 (fixed 0.01 lot)"),
}
DZ_ONLY = {"NI225_Gap_Continuation_EA"}   # not on the Atlas set until its symbol and server clock are seen on the Atlas terminal (user, 2026-10-29)
ATLAS_ONLY = {"Dark_Moon", "Dark_Rea"}  # explicitly requested for the Atlas live profile; not added to Darwinex
DARK_DEFAULTS = {ea: f"mql5/sets/vendor_defaults/{ea}.set" for ea in ATLAS_ONLY}
SPEC = {"NI225_Gap_Continuation_EA": "2026-10-23-ni225-gap-continuation-prereg.md",
        "NDX_Band_Breakout_EA": "2026-10-27-ndx-band-breakout-production-prereg.md"}
#--- NDX_Band_Breakout_EA per broker: the clock is the same (New York + 7 h: open 16:30, flat 22:55, so no time input changes), the symbol and its
#--- price scale are not. NDX on Darwinex quotes in 0.1 (100 points = 10 index points); the Atlas symbol is taken to quote in 0.01 (to confirm on the Atlas terminal), so the caps are
#--- ten times as many points. If Atlas's digits turn out different the caps only get looser, never tighter. The symbol per account is in make_live_profiles.py.
NDX_BROKER = {"darwinex_zero": {"InpMaxSpreadPoints": "100", "InpSlippagePoints": "30"},
              "atlas_2step_50k": {"InpMaxSpreadPoints": "1000", "InpSlippagePoints": "300"}}
#--- Atlas Funded 2-Step Daily $50k (user's checkout screenshots, spec 2026-10-29-atlas-funded-2step-prereg.md). Limits in % of the initial
#--- balance: max loss is a static floor (equity never below $46,000, it does not trail the peak), daily loss is $2,000 below the day-start
#--- balance and resets at 00:00 UTC (user's statistics screenshot 2026-11-01; balance or equity as the day-start base still to confirm, equity
#--- assumed). The account's EA daily stop and throttle below must stay inside them (tests/test_live_sets.py).
ATLAS = {"max_daily_loss_pct": 4.0, "max_loss_pct": 8.0, "targets_pct": (7.0, 4.0), "min_days": 3,
         "initial_usd": 50_000, "floor_usd": 46_000, "daily_usd": 2_000, "day_reset_utc": "00:00"}
#--- Sizing of each account relative to today's live sizing (gold EAs and Donchian_Trend 0.5%, NDX 0.25%, Invictus 0.006 lot per $1,000). Atlas: x0.6,
#--- the pre-registered pick of reports/portfolio/atlas_phase1.py (spec 2026-10-29-atlas-funded-2step-prereg.md, outcome ...-outcome.md).
RISK_SCALE = {"atlas_2step_50k": 0.6, "darwinex_zero": 1.0}
GOLD = {"MACD_Cross_EA", "Donchian_Breakout_EA", "RSI_Reversal_EA", "MA_Channel_EA"}
ACCOUNTS = {  # folder: (title, EA daily stop %, throttle DD %)
    "atlas_2step_50k": ("Atlas Funded 2-Step Daily $50k: 0.3% headline (all EAs x0.6) + 2% drawdown throttle, EA daily stop -2.5%", 2.5, 2.0),
    "darwinex_zero": ("Darwinex Zero: 0.5% constant risk, throttle off, EA daily stop -4%", 4.0, 0.0),
}

def ini_inputs(run):
    raw = open(f"reports/{run}.ini", "rb").read()
    t = raw.decode("utf-16") if raw[:2] in (b"\xff\xfe", b"\xfe\xff") else raw.decode("utf-8", "replace")
    return {k: v.split("||")[0] for k, v in (l.strip().split("=", 1) for l in t.splitlines() if "=" in l) if k.startswith("Inp")}

def num(x):
    return f"{round(x, 6):g}"

def live_inputs(ea, daily, thr, folder=None):
    if ea in DARK_DEFAULTS:
        # Preserve every compiled input from the saved tester .set; its fixed Lots=0.01 is intentional.
        t = open(DARK_DEFAULTS[ea], encoding="utf-16").read()
        return {line.split("=", 1)[0]: line.split("=", 1)[1].split("||", 1)[0]
                for line in t.splitlines() if "=" in line and not line.startswith(";")}
    scale = RISK_SCALE[folder] if folder else 1.0
    inp = ini_inputs(BASE[ea][0])
    if ea in GOLD:
        inp.update(InpRiskMode="1", InpRiskValue=num(0.5 * scale), InpMonthlyLossPct="12.0",
                   InpTradeLog="true", InpLogEveryBar="true")
    elif ea == "Donchian_Trend_EA":
        inp.update(InpRiskPercent=num(0.5 * scale))
    elif ea == "NDX_Band_Breakout_EA":                        # 0.25% = add-on sizing (about 2% own drawdown); the EA's M1 status line is off
        inp.update(InpRiskMode="1", InpRiskValue=num(0.25 * scale), InpMonthlyLossPct="12.0", InpTradeLog="true", InpLogEveryBar="false",
                   **NDX_BROKER[folder])
    elif ea == "NI225_Gap_Continuation_EA":                   # defaults = 0.5% (SELL 0.25% on small gaps); no throttle
        inp.update(InpDailyLossPct=f"{daily:.1f}")
        return inp
    else:
        inp.update(InpDemoOnly="false", InpLotsPer1k=num(float(inp["InpLotsPer1k"]) * scale))   # Invictus keeps the validated 0.006 lot per $1,000 from its run (user, 2026-10-27; 0.010 was the 0.5% headline, 1.00 lot on about 100k)
    inp.update(InpDailyLossPct=f"{daily:.1f}", InpThrottleDDPct=f"{thr:.1f}", InpThrottleFactor="0.5")   # daily stop: all six EAs
    return inp

def main():
    for folder, (title, daily, thr) in ACCOUNTS.items():
        os.makedirs(f"mql5/sets/{folder}", exist_ok=True)
        for ea, (run, chart) in BASE.items():
            if ea in DZ_ONLY and folder != "darwinex_zero":
                continue
            if ea in ATLAS_ONLY and folder != "atlas_2step_50k":
                continue
            if ea in DARK_DEFAULTS:
                source = open(DARK_DEFAULTS[ea], encoding="utf-16").read().splitlines()
                inputs = [line for line in source if line and not line.startswith(";")]
                title = ACCOUNTS[folder][0]
                lines = [f"; {ea} -- {title}", f"; chart: {chart}; screened compiled defaults, fixed 0.01 lots",
                         "; source: saved Gate B MT5 tester inputs; do not increase Lots or enable MoneyManagement"] + inputs
                with open(f"mql5/sets/{folder}/{ea}.set", "w", encoding="utf-16", newline="\r\n") as f:
                    f.write("\n".join(lines) + "\n")
                continue
            lines = [f"; {ea} -- {title}", f"; chart: {chart}; base inputs = validated run {run}",
                     f"; spec docs/superpowers/specs/{SPEC.get(ea, '2026-10-22-dd-reduction-phase1-prereg.md')}. Load via EA Inputs > Load."]
            lines += ea_profiles.tester_input_lines(live_inputs(ea, daily, thr, folder), {})   # MT5's own Name=Value||start||step||stop||N
            with open(f"mql5/sets/{folder}/{ea}.set", "w", encoding="utf-16", newline="\r\n") as f:   # MT5 native: UTF-16 LE, CRLF
                f.write("\n".join(lines) + "\n")
        count = sum((folder == "darwinex_zero" or ea not in DZ_ONLY) and (folder == "atlas_2step_50k" or ea not in ATLAS_ONLY) for ea in BASE)
        print("wrote", f"mql5/sets/{folder}/", count, "files")

if __name__ == "__main__":
    main()

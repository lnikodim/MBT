"""MT5 chart profiles for the live sets: every chart with its symbol, timeframe, EA and live inputs (the same values as
make_live_sets.py). Copy a profile folder into <Data Folder>/MQL5/Profiles/Charts/ and open it via File > Profiles.
  python3 scripts/make_live_profiles.py            -> mql5/profiles/MBT_Atlas_2Step/, mql5/profiles/MBT_DarwinexZero/
  python3 scripts/make_live_profiles.py --install  -> also copies both into the local (Mac) MT5 profiles folder"""
import os, sys, shutil
sys.path.insert(0, os.path.dirname(__file__)); import make_live_sets as L

PROFILES = {"atlas_2step_50k": "MBT_Atlas_2Step", "darwinex_zero": "MBT_DarwinexZero"}
CHART = {  # EA: (symbol, period_type 0 = minutes / 1 = hours, period_size, digits)
    "MACD_Cross_EA": ("XAUUSD", 1, 1, 2), "Donchian_Breakout_EA": ("XAUUSD", 1, 4, 2), "RSI_Reversal_EA": ("XAUUSD", 1, 6, 2),
    "MA_Channel_EA": ("XAUUSD", 1, 1, 2), "Donchian_Trend_EA": ("USDJPY", 1, 4, 3), "Invictus_GBPJPY_Monday_EA": ("GBPJPY", 0, 1, 3),
    "NI225_Gap_Continuation_EA": ("NI225", 0, 5, 2), "NDX_Band_Breakout_EA": ("NDX", 0, 1, 1),
    "Dark_Moon": ("EURUSD", 1, 1, 5), "Dark_Rea": ("GBPUSD", 1, 1, 5),
}
SYMBOL = {"atlas_2step_50k": {"NDX_Band_Breakout_EA": ("NAS100", 2)}}   # placeholder for the Atlas Nasdaq-100 name and digits (to confirm on the Atlas terminal); Darwinex uses NDX
FILE = {"Dark_Moon": "Dark_Moon_EA", "Dark_Rea": "Dark_Rea_EA"}   # the Advisors copies of the compiled Dark EAs carry the _EA suffix (checked 2026-11-01)
LOCAL = os.path.expanduser("~/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/Program Files/"
                           "MetaTrader 5/MQL5/Profiles/Charts")

# Chart settings from an MT5-saved chart (MT5 build of 2026-10); only symbol, timeframe, digits and id change per chart.
HEAD = """<chart>
id={id}
symbol={symbol}
period_type={ptype}
period_size={psize}
digits={digits}
tick_size=0.000000
position_time=0
scale_fix=0
scale_fixed_min=0.000000
scale_fixed_max=0.000000
scale_fix11=0
scale_bar=0
scale_bar_val=1.000000
scale=16
mode=1
fore=0
grid=0
volume=1
scroll=1
shift=1
shift_size=19.417168
fixed_pos=0.000000
ticker=1
ohlc=1
one_click=0
one_click_btn=1
bidline=1
askline=0
lastline=0
days=0
descriptions=0
tradelines=1
tradehistory=1
window_left=0
window_top=0
window_right=0
window_bottom=0
window_type=3
floating=0
floating_left=0
floating_top=0
floating_right=0
floating_bottom=0
floating_type=1
floating_toolbar=1
floating_tbstate=
background_color=16777215
foreground_color=0
barup_color=10135078
bardown_color=5264367
bullcandle_color=10135078
bearcandle_color=5264367
chartline_color=8698454
volumes_color=10135078
grid_color=15920369
bidline_color=10135078
askline_color=5264367
lastline_color=15776412
stops_color=5264367
windows_total=1

<expert>
name={ea}
path=Experts\\Advisors\\{ea}.ex5
expertmode=1
<inputs>
{inputs}
</inputs>
</expert>

<window>
height=100.000000
objects=0

<indicator>
name=Main
path=
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=0
fixed_height=-1
</indicator>
</window>
</chart>"""

def set_values(path):
    """Name -> value from one of our .set files (UTF-16, MT5's Name=Value||start||step||stop||N lines)."""
    t = open(path, encoding="utf-16").read()
    return {l.split("=", 1)[0]: l.split("=", 1)[1].split("||")[0] for l in t.splitlines() if "=" in l and not l.startswith(";")}

def main(install):
    for folder, (title, daily, thr) in L.ACCOUNTS.items():
        out = f"mql5/profiles/{PROFILES[folder]}"
        shutil.rmtree(out, ignore_errors=True); os.makedirs(out)
        n = 0
        for ea in L.BASE:
            if ea in L.DZ_ONLY and folder != "darwinex_zero":
                continue
            if ea in L.ATLAS_ONLY and folder != "atlas_2step_50k":
                continue
            n += 1
            inp = L.live_inputs(ea, daily, thr, folder)
            symbol, ptype, psize, digits = CHART[ea]
            symbol, digits = SYMBOL.get(folder, {}).get(ea, (symbol, digits))
            text = HEAD.format(id=133000000000000 + 100 * n, symbol=symbol, ptype=ptype, psize=psize, digits=digits, ea=FILE.get(ea, ea),
                               inputs="\n".join(f"{k}={v}" for k, v in inp.items()))
            path = f"{out}/chart{n:02d}.chr"
            with open(path, "w", encoding="utf-16", newline="\r\n") as f:   # MT5 native: UTF-16 LE with BOM, CRLF
                f.write(text + "\n")
            # self-check: the chart's inputs are exactly the account's .set values
            back = open(path, encoding="utf-16").read().split("<inputs>\n")[1].split("\n</inputs>")[0]
            got = dict(l.split("=", 1) for l in back.splitlines())
            assert got == set_values(f"mql5/sets/{folder}/{ea}.set"), (folder, ea)
        included = [e for e in L.BASE if not (e in L.DZ_ONLY and folder != "darwinex_zero") and not (e in L.ATLAS_ONLY and folder != "atlas_2step_50k")]
        print(f"wrote {out}/ ({n} charts: {', '.join(f'{SYMBOL.get(folder, {}).get(e, (CHART[e][0],))[0]} {e}' for e in included)})")
        if install:
            dst = f"{LOCAL}/{PROFILES[folder]}"
            shutil.rmtree(dst, ignore_errors=True); shutil.copytree(out, dst)
            print(f"   installed into the local MT5: {dst}")

if __name__ == "__main__":
    main("--install" in sys.argv)

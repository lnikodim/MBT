"""EMA_VWAP_Trail_EA self-check: three short 1-min-OHLC M15 runs (trail from entry, trail after profit, and
VWAP_EMA_Cross_EA inverted as the entry reference) and the invariants of the Pine port. Run from the repo root
with the MT5 GUI closed:  python3 scripts/ema_vwap_trail_selfcheck.py"""
import csv, sys
sys.path.insert(0, "scripts"); import vwap_rsi_eval as E
WIN = ("2026-01-01", "2026-03-01")
def run(name, expert, sets):
    d, _ = E.run(name, sets, period="M15", expert=expert, model="1min_ohlc", frm=WIN[0], to=WIN[1], timeout=900)
    rows = sorted((r for r in csv.DictReader(open("reports/" + d["trade_log"])) if r["r_multiple"]), key=lambda r: r["open_time"])
    m = d["metrics"]
    print(f"{name}: trades {int(m['trades'])} PF {m['profit_factor']} net {m['net_profit']:,.0f} reasons {sorted({r['exit_reason'] for r in rows})}", flush=True)
    assert len(rows) == int(m["trades"]), ("csv rows != report trades", len(rows), m["trades"])
    return rows
ref = run("emavwap_sc_ref", "VWAP_EMA_Cross_EA", {"InpInvert": "true", "InpTimeframe": "15"})
for variant, after in (("entry", "false"), ("profit", "true")):
    rows = run(f"emavwap_sc_{variant}", "EMA_VWAP_Trail_EA", {"InpTrailAfterProfit": after})
    unknown = {r["exit_reason"] for r in rows} - {"cross", "sl", "daily_stop", "monthly_stop", "end_of_test"}
    assert not unknown, ("unexpected exit reasons", unknown)
    assert all(float(r["tp"]) == 0.0 for r in rows), "unexpected take profit"
    sl = [float(r["r_multiple"]) for r in rows if r["exit_reason"] == "sl"]
    assert sl and min(sl) >= -1.2, ("a stop-out lost more than the initial k x ATR stop", min(sl) if sl else None)
    trailed = sum(1 for x in sl if x > 0.0)
    print(f"  stop exits {len(sl)}, of which in profit (trailed) {trailed}; cross exits {sum(1 for r in rows if r['exit_reason']=='cross')}", flush=True)
    assert trailed >= 0.2 * len(sl), "trailing never locked in profit"
    if after == "true":
        mid = [x for x in sl if -0.75 < x < -0.25]
        assert not mid, ("trail-after-profit variant trailed before +k x ATR", mid[:5])
    common = {r["open_time"] for r in rows} & {r["open_time"] for r in ref}
    side_ok = sum(1 for r in rows if r["open_time"] in common and r["side"] == next(q["side"] for q in ref if q["open_time"] == r["open_time"]))
    print(f"  entries {len(rows)}, shared with the reference cross EA {len(common)} (same side {side_ok})", flush=True)
    assert len(common) >= 0.95 * min(len(rows), len(ref)), "enters at different crosses than the reference"
    assert side_ok == len(common), "direction differs from the reference (EMA above VWAP = long)"
print("SELFCHECK OK")

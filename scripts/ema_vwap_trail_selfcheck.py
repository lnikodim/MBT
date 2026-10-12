"""EMA_VWAP_Trail_EA self-check: three short 1-min-OHLC M15 runs (trail from entry, trail after profit, and
VWAP_EMA_Cross_EA inverted as the entry reference) and the invariants of the Pine port. Run from the repo root
with the MT5 GUI closed:  python3 scripts/ema_vwap_trail_selfcheck.py"""
import csv, sys
sys.path.insert(0, "scripts"); import vwap_rsi_eval as E
WIN = ("2026-01-01", "2026-03-01")
GUARDS_OFF = {"InpDailyLossPct": "0", "InpMonthlyLossPct": "0"}   # guards depend on each EA's own equity path and would hide entry mismatches
def run(name, expert, sets):
    d, _ = E.run(name, dict(sets, **GUARDS_OFF), period="M15", expert=expert, model="1min_ohlc", frm=WIN[0], to=WIN[1], timeout=900)
    rows = sorted((r for r in csv.DictReader(open("reports/" + d["trade_log"])) if r["r_multiple"]), key=lambda r: r["open_time"])
    m = d["metrics"]
    print(f"{name}: trades {int(m['trades'])} PF {m['profit_factor']} net {m['net_profit']:,.0f} reasons {sorted({r['exit_reason'] for r in rows})}", flush=True)
    assert len(rows) == int(m["trades"]), ("csv rows != report trades", len(rows), m["trades"])
    return rows
results = {}
ref = run("emavwap_sc_ref", "VWAP_EMA_Cross_EA", {"InpInvert": "true", "InpTimeframe": "15"})
for variant, after in (("entry", "false"), ("profit", "true")):
    rows = run(f"emavwap_sc_{variant}", "EMA_VWAP_Trail_EA", {"InpTrailAfterProfit": after})
    results[variant] = rows
    unknown = {r["exit_reason"] for r in rows} - {"cross", "sl", "end_of_test"}
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
    assert len(common) >= 0.98 * max(len(rows), len(ref)), ("enters at different crosses than the reference", len(rows), len(ref), len(common))
    assert side_ok == len(common), "direction differs from the reference (EMA above VWAP = long)"
# v1.01 filters: with the guards off a filtered run enters at a subset of the unfiltered crosses
import datetime as dt
base = {r["open_time"] for r in results["entry"]}
sess = run("emavwap_sc_session", "EMA_VWAP_Trail_EA", {"InpSessionStart": "10", "InpSessionEnd": "23"})
hours = [dt.datetime.strptime(r["open_time"], "%Y.%m.%d %H:%M:%S").hour for r in sess]
assert all(10 <= h < 23 for h in hours), ("entry outside the session", sorted(set(hours)))
assert {r["open_time"] for r in sess} <= base, "session run entered at a time the unfiltered run did not"
flt = run("emavwap_sc_trend", "EMA_VWAP_Trail_EA", {"InpTrendEMA": "200", "InpHTFBias": "2"})
assert 0 < len(flt) < len(results["entry"]), ("trend + H4 filters removed nothing or everything", len(flt), len(results["entry"]))
assert {r["open_time"] for r in flt} <= base, "filtered run entered at a time the unfiltered run did not"
print(f"filters: session {len(sess)} entries all in 10-23h, trend+H4 {len(flt)} of {len(results['entry'])} entries kept")
# v1.02 trail off: every stop exit is the initial stop (about -1R), entries unchanged
notrail = run("emavwap_sc_notrail", "EMA_VWAP_Trail_EA", {"InpTrailATR": "false"})
sl_r = [float(r["r_multiple"]) for r in notrail if r["exit_reason"] == "sl"]
assert sl_r and max(sl_r) <= 0.0 and min(sl_r) >= -1.2, ("trail-off run still moved its stop", max(sl_r), min(sl_r))
assert {r["open_time"] for r in notrail} == base, "trail-off run entered at different crosses"
print(f"trail off: {len(notrail)} entries identical, {len(sl_r)} stop exits all at the initial stop (max R {max(sl_r):.2f})")
print("SELFCHECK OK")

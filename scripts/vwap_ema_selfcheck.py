"""VWAP_EMA_Cross_EA self-check: two short real-tick runs (as specified / inverted) and the invariants of a
cross-reversal system. Run from the repo root with the MT5 GUI closed:  python3 scripts/vwap_ema_selfcheck.py"""
import csv, sys
sys.path.insert(0, "scripts"); import vwap_rsi_eval as E
WIN = ("2026-01-01", "2026-03-01")
runs = {}
for inv in ("false", "true"):
    d, _ = E.run(f"vwapema_sc_inv{inv}", {"InpInvert": inv}, period="M5", expert="VWAP_EMA_Cross_EA",
                 model="real_ticks", frm=WIN[0], to=WIN[1], timeout=900)
    rows = sorted((r for r in csv.DictReader(open("reports/" + d["trade_log"])) if r["r_multiple"]), key=lambda r: r["open_time"])
    m = d["metrics"]
    print(f"inv={inv}: trades {int(m['trades'])} PF {m['profit_factor']} net {m['net_profit']:,.0f} reasons {sorted({r['exit_reason'] for r in rows})}", flush=True)
    assert len(rows) == int(m["trades"]), ("csv rows != report trades", len(rows), m["trades"])
    unknown = {r["exit_reason"] for r in rows} - {"cross", "sl", "daily_stop", "monthly_stop", "end_of_test"}
    assert not unknown, ("unexpected exit reasons", unknown)
    assert len(rows) >= 50, ("too few trades for a check", len(rows))
    for r in rows:
        o, sl = float(r["open_price"]), float(r["sl"])
        assert abs(abs(o - sl) / o * 100 - 0.5) < 0.02, ("stop is not 0.5% of price", r["open_time"], o, sl)
        assert float(r["tp"]) == 0.0, ("unexpected take profit", r["tp"])
    flips = [(a, b) for a, b in zip(rows, rows[1:]) if a["exit_reason"] == "cross"]
    same_tick = sum(1 for a, b in flips if a["close_time"] == b["open_time"] and a["side"] != b["side"])
    print(f"  cross exits {len(flips)}, flipped on the same tick to the opposite side: {same_tick}", flush=True)
    assert same_tick >= 0.9 * len(flips), ("cross exit not followed by an immediate opposite entry", same_tick, len(flips))
    runs[inv] = {r["open_time"]: r["side"] for r in rows}
common = set(runs["false"]) & set(runs["true"])
opp = sum(1 for t in common if runs["false"][t] != runs["true"][t])
print(f"entries as-specified {len(runs['false'])}, inverted {len(runs['true'])}, same open time {len(common)}, opposite side {opp}", flush=True)
assert len(common) >= 0.95 * min(len(runs["false"]), len(runs["true"])), "inverted run enters at different crosses"
assert opp == len(common), ("inverted run is not the mirror image", opp, len(common))
print("SELFCHECK OK")

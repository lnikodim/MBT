"""Donchian_Breakout_EA self-check: one 2-month XAUUSD H1 real-tick run (loss guards off, bar log on) and the
strategy invariants, read from the EA's DONCH SIGNAL / filtered bar lines in the tester agent log and the trade CSV.
Run from the repo root with the MT5 GUI closed:  python3 scripts/donchian_selfcheck.py"""
import re, sys
sys.path.insert(0, "scripts"); import vwap_rsi_eval as E, holo_eval as H
WIN = ("2026-01-01", "2026-03-01")
SETS = {"InpDailyLossPct": "0", "InpMonthlyLossPct": "0", "InpLogEveryBar": "true"}
K_ATR, R, LOCK = 2.0, 3.0, 0.2
SIG = re.compile(r"\t(\d{4}\.\d\d\.\d\d \d\d):\d\d:\d\d   DONCH SIGNAL (BUY|SELL) (.*)")
FLT = re.compile(r"\| (BUY|SELL) filtered: \w+ close ([\d.]+) vs EMA\d+ ([\d.]+)")
KV = re.compile(r"(\w+)=(-?[\d.]+)")
near = lambda a, b, tol=0.02: abs(a - b) <= tol * abs(b)

mark = H.agent_log_size()
d, rows = E.run("donch_sc", SETS, expert="Donchian_Breakout_EA", model="real_ticks", frm=WIN[0], to=WIN[1], timeout=900)
log = H.agent_log_since(mark)
rows = sorted((r for r in rows if r["r_multiple"] is not None), key=lambda r: r["open_time"])
sigs = {h: (side, {k: float(v) for k, v in KV.findall(rest)}) for h, side, rest in SIG.findall(log)}
flt = [(side, float(c), float(e)) for side, c, e in FLT.findall(log)]
m = d["metrics"]
print(f"donch_sc: trades {int(m['trades'])} PF {m['profit_factor']} net {m['net_profit']:,.0f} signals {len(sigs)} "
      f"filtered bars {len(flt)} reasons {sorted({r['exit_reason'] for r in rows})}", flush=True)
assert len(rows) == int(m["trades"]), ("csv rows != report trades", len(rows), m["trades"])
assert len(rows) >= 8, ("too few trades for a check", len(rows))
assert {r["exit_reason"] for r in rows} <= {"sl", "tp", "end_of_test"}, {r["exit_reason"] for r in rows}
assert len(sigs) >= len(rows), ("fewer signal lines than trades", len(sigs), len(rows))
for side, s in sigs.values():
    assert (s["close"] > s["hi"]) if side == "BUY" else (s["close"] < s["lo"]), ("close not beyond the channel", side, s)
    assert (s["htf_close"] > s["ema"]) if side == "BUY" else (s["htf_close"] < s["ema"]), ("trend filter not respected", side, s)
    assert near(s["sl_dist"], K_ATR * s["atr"]), ("stop != k x ATR", s)
assert flt, "the trend filter never filtered a breakout"
assert all((c <= e) if side == "BUY" else (c >= e) for side, c, e in flt), "a filtered breakout was on the trend side"
for r in rows:
    h = r["open_time"].strftime("%Y.%m.%d %H")
    assert h in sigs, ("entry without a signal line in its hour", r["open_time"])
    side, s = sigs[h]
    assert side.lower() == r["side"], ("side mismatch", r["open_time"], side, r["side"])
    assert near(abs(r["tp"] - r["open_price"]), R * s["sl_dist"]), ("target != R x stop", r["open_time"], r["tp"], r["open_price"], s["sl_dist"])
    moved = (r["sl"] > r["open_price"]) if r["side"] == "buy" else (r["sl"] < r["open_price"])
    if not moved:
        assert near(abs(r["open_price"] - r["sl"]), s["sl_dist"]), ("initial stop != sl_dist", r["open_time"], r["sl"], r["open_price"], s["sl_dist"])
    x = r["r_multiple"]
    if r["exit_reason"] == "tp":
        assert 2.5 <= x <= 3.2, ("tp exit R", r["open_time"], x)
    if r["exit_reason"] == "sl":
        assert (-0.05 <= x <= LOCK + 0.1) if moved else (-1.5 <= x <= -0.8), ("sl exit R", r["open_time"], x, moved)
ev = sorted([(r["open_time"], 1) for r in rows] + [(r["close_time"], -1) for r in rows])
cur = peak = 0
for _, dlt in ev:
    cur += dlt; peak = max(peak, cur)
assert peak == 1, ("more than one position at a time", peak)
be = sum(1 for r in rows if r["exit_reason"] == "sl" and r["r_multiple"] > -0.05)
print(f"entries {len(rows)} ({sum(r['side'] == 'buy' for r in rows)} buys), tp {sum(r['exit_reason'] == 'tp' for r in rows)}, "
      f"stop {sum(r['exit_reason'] == 'sl' for r in rows)} of which break-even {be}, peak concurrent {peak}")
print("SELFCHECK OK")

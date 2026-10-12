"""Camvcvoo_EA self-check: one GBPUSD H1 1-min-OHLC run (Jan-Jun 2025) and the invariants of the camvcvooV5 port.
Run from the repo root with the MT5 GUI closed:  python3 scripts/camvcvoo_selfcheck.py"""
import csv, sys, collections, datetime as dt
sys.path.insert(0, "scripts"); import vwap_rsi_eval as E
d, _ = E.run("camv_sc", {}, period="H1", expert="Camvcvoo_EA", model="1min_ohlc", symbol="GBPUSD",
             frm="2025-01-01", to="2025-07-01", timeout=900)
rows = [r for r in csv.DictReader(open("reports/" + d["trade_log"])) if r["r_multiple"]]
m = d["metrics"]
print(f"camv_sc: trades {int(m['trades'])} PF {m['profit_factor']} net {m['net_profit']:,.0f} reasons {sorted({r['exit_reason'] for r in rows})}", flush=True)
assert len(rows) == int(m["trades"]), ("csv rows != report trades", len(rows), m["trades"])
assert len(rows) >= 30, ("too few trades for a check", len(rows))
assert {r["exit_reason"] for r in rows} <= {"sl", "tp", "end_of_test", "daily_stop", "monthly_stop"}, {r["exit_reason"] for r in rows}
P = lambda t: dt.datetime.strptime(t, "%Y.%m.%d %H:%M:%S")
hours = {P(r["open_time"]).hour for r in rows}
assert hours == {1}, ("entries outside the trade hour", sorted(hours))
sets = collections.defaultdict(list)
for r in rows: sets[r["open_time"]].append(r)
full = sum(1 for s in sets.values() if len(s) == 3)
assert full >= 0.9 * len(sets), ("incomplete sets", full, len(sets))
assert all(len({r["side"] for r in s}) == 1 for s in sets.values()), "mixed sides inside a set"
pip = 0.0001
roles = collections.Counter()
for r in rows:
    o, tp, sl, R = float(r["open_price"]), float(r["tp"]), float(r["sl"]), float(r["r_multiple"])
    tpp = round(abs(tp - o) / pip)
    role = 1 if abs(tpp - 22) <= 1 else 2 if abs(tpp - 50) <= 1 else 3 if abs(tpp - 80) <= 1 else 0
    assert role, ("target is not 22/50/80 pips", r["open_time"], tpp)
    roles[role] += 1
    if role == 1:
        assert abs(abs(o - sl) / pip - 140) <= 1, ("position 1 stop moved", r["open_time"], abs(o - sl) / pip)
    if r["exit_reason"] == "sl":
        assert R >= -1.15, ("stop-out worse than the 140-pip stop", r["open_time"], R)
        if role == 3 and R > 0:
            assert R <= 0.3, ("position 3 lock is not a one-shot lock", r["open_time"], R)
    assert all(len({(round(abs(float(q["tp"]) - float(q["open_price"])) / pip)) for q in s}) == len(s) for s in sets.values()), "duplicate targets inside a set"
trailed = sum(1 for r in rows if round(abs(float(r["tp"]) - float(r["open_price"])) / pip) in (49, 50, 51) and r["exit_reason"] == "sl" and float(r["r_multiple"]) > 0)
locked = sum(1 for r in rows if round(abs(float(r["tp"]) - float(r["open_price"])) / pip) in (79, 80, 81) and r["exit_reason"] == "sl" and float(r["r_multiple"]) > 0)
print(f"sets {len(sets)} (full {full}), roles {dict(roles)}, position-2 trailed exits in profit {trailed}, position-3 locked exits {locked}")
print("SELFCHECK OK")

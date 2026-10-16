"""TEB_MTF_EA self-check: two 2-month EURUSD M5 runs on 1-min OHLC (cross and pullback entry; loss guards off, bar log on).
Every TEB SIGNAL line must satisfy the trend / entry / session arithmetic; each signal opens two positions (lot 1 target =
10 pips + spread, lot 2 no target, both stops 10 pips); lot-2 exits after a lot-1 target are at or above break-even.
Run from the repo root with the MT5 GUI closed:  python3 scripts/teb_selfcheck.py"""
import re, sys
from collections import defaultdict
sys.path.insert(0, "scripts"); import vwap_rsi_eval as E, holo_eval as H
WIN = ("2026-01-01", "2026-03-01")
BASE = {"InpDailyLossPct": "0", "InpMonthlyLossPct": "0", "InpLogEveryBar": "true"}
PIP, LEVEL, HOURS = 0.0001, 50.0, {10, 11, 14, 15, 16, 17, 18, 3, 4}
SIG = re.compile(r"\t(\d{4}\.\d\d\.\d\d \d\d:\d\d):\d\d   TEB SIGNAL (BUY|SELL) (.*)")
KV = re.compile(r"(\w+)=(-?[\d.]+)")
near = lambda a, b, tol=1.5e-5: abs(a - b) <= tol

def run(name, sets):
    mark = H.agent_log_size()
    d, rows = E.run(name, dict(BASE, **sets), period="M5", expert="TEB_MTF_EA", model="1min_ohlc", symbol="EURUSD",
                    frm=WIN[0], to=WIN[1], timeout=900)
    log = H.agent_log_since(mark)
    rows = sorted((r for r in rows if r["r_multiple"] is not None), key=lambda r: r["open_time"])
    sigs = {m: (side, {k: float(v) for k, v in KV.findall(rest)}) for m, side, rest in SIG.findall(log)}
    m = d["metrics"]
    print(f"{name}: trades {int(m['trades'])} PF {m['profit_factor']} net {m['net_profit']:,.0f} signals {len(sigs)} "
          f"reasons {sorted({r['exit_reason'] for r in rows})}", flush=True)
    assert len(rows) == int(m["trades"]), ("csv rows != report trades", len(rows), m["trades"])
    assert len(rows) >= 16, ("too few trades for a check", len(rows))
    assert {r["exit_reason"] for r in rows} <= {"sl", "tp", "end_of_test"}, {r["exit_reason"] for r in rows}
    mode = int(sets.get("InpEntryMode", "0"))
    for side, s in sigs.values():
        buy = side == "BUY"
        assert s["trend"] == (1 if buy else -1) and (s["fT"] > s["sT"] and s["rT"] > LEVEL if buy else s["fT"] < s["sT"] and s["rT"] < LEVEL), ("trend", side, s)
        assert (s["r1"] > LEVEL) if buy else (s["r1"] < LEVEL), ("entry RSI", side, s)
        if mode == 0:
            assert (s["f1"] > s["s1"] and s["f2"] <= s["s2"]) if buy else (s["f1"] < s["s1"] and s["f2"] >= s["s2"]), ("not a cross", side, s)
        else:
            assert (s["f1"] > s["s1"] and s["f2"] > s["s2"] and s["lo2"] <= s["s2"] and s["c2"] <= s["f2"] and s["c1"] > s["f1"]) if buy else \
                   (s["f1"] < s["s1"] and s["f2"] < s["s2"] and s["hi2"] >= s["s2"] and s["c2"] >= s["f2"] and s["c1"] < s["f1"]), ("not a pullback", side, s)
        assert int(s["hour"]) in HOURS, ("outside sessions", s)
        assert near(s["sl_dist"], 10 * PIP) and near(s["tp_dist"], 10 * PIP + s["spread"]), ("stop/target geometry", s)
    groups = defaultdict(list)
    for r in rows: groups[r["open_time"]].append(r)
    be_checked = 0
    for t, g in groups.items():
        key = t.strftime("%Y.%m.%d %H:%M")
        assert key in sigs, ("entry without a signal line in its minute", t)
        side, s = sigs[key]
        assert len(g) == 2 and {r["side"] for r in g} == {side.lower()}, ("a signal must open exactly two positions of its side", t, [(r["side"], r["tp"]) for r in g])
        lot1 = [r for r in g if r["tp"] > 0]; lot2 = [r for r in g if r["tp"] == 0]
        assert len(lot1) == 1 and len(lot2) == 1, ("one lot with a target and one without", t)
        l1, l2 = lot1[0], lot2[0]
        assert near(abs(l1["tp"] - l1["open_price"]), s["tp_dist"], 2e-5), ("lot-1 target", t, l1["tp"], l1["open_price"], s["tp_dist"])
        assert near(abs(l1["open_price"] - l1["sl"]), s["sl_dist"], 2e-5), ("lot-1 stop", t, l1["sl"], l1["open_price"])
        if l1["exit_reason"] == "tp":
            assert 0.8 <= l1["r_multiple"] <= 1.15, ("lot-1 target R", t, l1["r_multiple"])
            be = (l2["sl"] >= l2["open_price"]) if l2["side"] == "buy" else (l2["sl"] <= l2["open_price"])
            assert be and l2["r_multiple"] >= -0.15, ("lot 2 not at break-even after a lot-1 target", t, l2["sl"], l2["open_price"], l2["r_multiple"])
            be_checked += 1
        elif l1["exit_reason"] == "sl":
            assert -1.2 <= l1["r_multiple"] <= -0.8, ("lot-1 stop R", t, l1["r_multiple"])
            assert l2["exit_reason"] in ("sl", "end_of_test") and l2["r_multiple"] <= -0.8 or l2["exit_reason"] == "end_of_test", ("lot 2 should stop with lot 1", t, l2["r_multiple"])
    ev = sorted([(r["open_time"], 1) for r in rows] + [(r["close_time"], -1) for r in rows])
    cur = peak = 0
    for _, dlt in ev:
        cur += dlt; peak = max(peak, cur)
    assert peak <= 2, ("more than two positions at a time", peak)
    assert be_checked >= 3, ("too few lot-1 targets to check the break-even", be_checked)
    print(f"  {len(groups)} signals, {be_checked} lot-1 targets with lot 2 at break-even, peak concurrent {peak}", flush=True)

run("teb_sc_x", {"InpEntryMode": "0"})
run("teb_sc_pb", {"InpEntryMode": "1"})
print("SELFCHECK OK")

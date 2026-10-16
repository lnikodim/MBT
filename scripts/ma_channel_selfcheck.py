"""MA_Channel_EA self-check: two 2-month XAUUSD H1 runs on 1-min OHLC (loss guards off, bar log on) and the strategy
invariants, read from the EA's MACH SIGNAL / MACH EXIT lines in the tester agent log and the trade CSV.
Run from the repo root with the MT5 GUI closed:  python3 scripts/ma_channel_selfcheck.py"""
import re, sys
sys.path.insert(0, "scripts"); import vwap_rsi_eval as E, holo_eval as H
WIN = ("2026-01-01", "2026-03-01")
BASE = {"InpDailyLossPct": "0", "InpMonthlyLossPct": "0", "InpLogEveryBar": "true", "InpTimeframe": E.TF["H1"]}
K_ATR = 2.0
SIG = re.compile(r"\t(\d{4}\.\d\d\.\d\d \d\d):\d\d:\d\d   MACH SIGNAL (BUY|SELL) (.*)")
EXT = re.compile(r"MACH EXIT (BUY|SELL) (.*)")
KV = re.compile(r"(\w+)=(-?[\d.]+)")
near = lambda a, b, tol=0.02: abs(a - b) <= tol * abs(b)

def run(name, sets):
    mark = H.agent_log_size()
    d, rows = E.run(name, dict(BASE, **sets), expert="MA_Channel_EA", model="1min_ohlc", frm=WIN[0], to=WIN[1], timeout=900)
    log = H.agent_log_since(mark)
    rows = sorted((r for r in rows if r["r_multiple"] is not None), key=lambda r: r["open_time"])
    sigs = {h: (side, {k: float(v) for k, v in KV.findall(rest)}) for h, side, rest in SIG.findall(log)}
    exits = [(side, {k: float(v) for k, v in KV.findall(rest)}) for side, rest in EXT.findall(log)]
    m = d["metrics"]
    print(f"{name}: trades {int(m['trades'])} PF {m['profit_factor']} net {m['net_profit']:,.0f} signals {len(sigs)} exits {len(exits)} "
          f"reasons {sorted({r['exit_reason'] for r in rows})}", flush=True)
    assert len(rows) == int(m["trades"]), ("csv rows != report trades", len(rows), m["trades"])
    assert len(rows) >= 8, ("too few trades for a check", len(rows))
    assert {r["exit_reason"] for r in rows} <= {"sl", "tp", "expert", "end_of_test"}, {r["exit_reason"] for r in rows}
    assert len(sigs) >= len(rows), ("fewer signal lines than trades", len(sigs), len(rows))
    for side, s in sigs.values():
        assert near(s["sl_dist"], K_ATR * s["atr"]), ("stop != k x ATR", s)
    for r in rows:
        h = r["open_time"].strftime("%Y.%m.%d %H")
        assert h in sigs, ("entry without a signal line in its hour", r["open_time"])
        side, s = sigs[h]
        assert side.lower() == r["side"], ("side mismatch", r["open_time"], side, r["side"])
        assert near(abs(r["open_price"] - r["sl"]), s["sl_dist"]), ("initial stop != sl_dist", r["open_time"], r["sl"], r["open_price"], s["sl_dist"])
        if r["exit_reason"] == "sl":
            assert -1.5 <= r["r_multiple"] <= -0.8, ("sl exit R", r["open_time"], r["r_multiple"])
    ev = sorted([(r["open_time"], 1) for r in rows] + [(r["close_time"], -1) for r in rows])
    cur = peak = 0
    for _, dlt in ev:
        cur += dlt; peak = max(peak, cur)
    assert peak == 1, ("more than one position at a time", peak)
    return rows, sigs, exits

# 1. breakout entry + fast/slow cross exit, both sides
rows, sigs, exits = run("mach_sc_bo", {"InpEntryMode": "0", "InpExitMode": "1", "InpAllowShort": "true"})
for side, s in sigs.values():
    assert (s["f1"] > s["up1"] and s["f2"] <= s["up2"]) if side == "BUY" else (s["f1"] < s["lo1"] and s["f2"] >= s["lo2"]), ("not a channel cross", side, s)
    assert s["tp"] == 0.0, ("target set outside EXIT_TARGET", s)
assert exits, "no MA-cross exits in two months"
for side, x in exits:
    assert (x["f1"] < x["s1"] and x["f2"] >= x["s2"]) if side == "BUY" else (x["f1"] > x["s1"] and x["f2"] <= x["s2"]), ("exit without a cross against the position", side, x)
assert any(r["side"] == "sell" for r in rows) and any(r["side"] == "buy" for r in rows), "one side never traded"
# 2. pullback entry + channel exit, both sides
rows, sigs, exits = run("mach_sc_pb", {"InpEntryMode": "1", "InpExitMode": "0", "InpAllowShort": "true"})
for side, s in sigs.values():
    if side == "BUY":
        assert s["state"] == 1 and s["f2"] < s["up2"] and s["f2"] >= s["lo2"] and s["f2"] < s["f3"] and s["f1"] > s["f2"], ("not an up-turn inside the channel", s)
    else:
        assert s["state"] == -1 and s["f2"] > s["lo2"] and s["f2"] <= s["up2"] and s["f2"] > s["f3"] and s["f1"] < s["f2"], ("not a down-turn inside the channel", s)
for side, x in exits:
    assert (x["f1"] < x["lo1"] and x["f2"] >= x["lo2"]) if side == "BUY" else (x["f1"] > x["up1"] and x["f2"] <= x["up2"]), ("channel exit without an opposite cross", side, x)
print("SELFCHECK OK")

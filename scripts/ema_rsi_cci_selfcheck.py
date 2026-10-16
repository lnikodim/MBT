"""EMA_RSI_CCI_EA self-check: one 6-month EURUSD H1 run on 1-min OHLC (loss guards off, bar log on). Every EMARC SIGNAL
line satisfies cross + RSI + CCI, every EMARC EXIT line satisfies cross-back or both-below, entries match their signal
line, stops are 35 pips, no targets, one position at a time.  Run from the repo root with the MT5 GUI closed."""
import re, sys
sys.path.insert(0, "scripts"); import vwap_rsi_eval as E, holo_eval as H
WIN = ("2026-01-01", "2026-07-01")
SETS = {"InpDailyLossPct": "0", "InpMonthlyLossPct": "0", "InpLogEveryBar": "true"}
PIP, RSI_L, CCI_L = 0.0001, 50.0, 0.0
SIG = re.compile(r"\t(\d{4}\.\d\d\.\d\d \d\d):\d\d:\d\d   EMARC SIGNAL (BUY|SELL) (.*)")
EXT = re.compile(r"EMARC EXIT (BUY|SELL) (.*)")
KV = re.compile(r"(\w+)=(-?[\d.]+)")
mark = H.agent_log_size()
d, rows = E.run("emarc_sc", SETS, period="H1", expert="EMA_RSI_CCI_EA", model="1min_ohlc", symbol="EURUSD", frm=WIN[0], to=WIN[1], timeout=900)
log = H.agent_log_since(mark)
rows = sorted((r for r in rows if r["r_multiple"] is not None), key=lambda r: r["open_time"])
sigs = {h: (side, {k: float(v) for k, v in KV.findall(rest)}) for h, side, rest in SIG.findall(log)}
exits = [(side, {k: float(v) for k, v in KV.findall(rest)}) for side, rest in EXT.findall(log)]
m = d["metrics"]
print(f"emarc_sc: trades {int(m['trades'])} PF {m['profit_factor']} net {m['net_profit']:,.0f} signals {len(sigs)} exits {len(exits)} "
      f"reasons {sorted({r['exit_reason'] for r in rows})}", flush=True)
assert len(rows) == int(m["trades"]), ("csv rows != report trades", len(rows), m["trades"])
assert len(rows) >= 15, ("too few trades for a check", len(rows))
assert {r["exit_reason"] for r in rows} <= {"sl", "expert", "end_of_test"}, {r["exit_reason"] for r in rows}
for side, s in sigs.values():
    buy = side == "BUY"
    assert (s["f1"] > s["s1"] and s["f2"] <= s["s2"]) if buy else (s["f1"] < s["s1"] and s["f2"] >= s["s2"]), ("not a cross", side, s)
    assert (s["rsi"] > RSI_L and s["cci"] > CCI_L) if buy else (s["rsi"] < 100 - RSI_L and s["cci"] < -CCI_L), ("filter", side, s)
    assert abs(s["sl_dist"] - 35 * PIP) < 1e-6 and s["tp"] == 0.0, ("stop/target", s)
assert exits, "no indicator exits in six months"
for side, x in exits:
    cross_back = (x["f1"] < x["s1"] and x["f2"] >= x["s2"]) if side == "BUY" else (x["f1"] > x["s1"] and x["f2"] <= x["s2"])
    both = (x["rsi"] < 100 - RSI_L and x["cci"] < -CCI_L) if side == "BUY" else (x["rsi"] > RSI_L and x["cci"] > CCI_L)
    assert cross_back or both, ("exit without its condition", side, x)
for r in rows:
    h = r["open_time"].strftime("%Y.%m.%d %H")
    assert h in sigs, ("entry without a signal line in its hour", r["open_time"])
    assert sigs[h][0].lower() == r["side"], ("side mismatch", r["open_time"])
    assert abs(abs(r["open_price"] - r["sl"]) - 35 * PIP) < 2e-5 and r["tp"] == 0, ("position stop/target", r["open_time"], r["sl"], r["tp"])
    if r["exit_reason"] == "sl":
        assert -1.3 <= r["r_multiple"] <= -0.85, ("sl exit R", r["open_time"], r["r_multiple"])
ev = sorted([(r["open_time"], 1) for r in rows] + [(r["close_time"], -1) for r in rows])
cur = peak = 0
for _, dlt in ev:
    cur += dlt; peak = max(peak, cur)
assert peak == 1, ("more than one position at a time", peak)
print(f"entries {len(rows)} ({sum(r['side'] == 'buy' for r in rows)} buys), stop exits {sum(r['exit_reason'] == 'sl' for r in rows)}, "
      f"indicator exits {sum(r['exit_reason'] == 'expert' for r in rows)}, peak concurrent {peak}")
print("SELFCHECK OK")

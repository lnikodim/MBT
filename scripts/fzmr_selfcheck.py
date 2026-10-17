"""FZMR_EA self-check: XAUUSD M15 2025-01..2026-01 (loss guards off), real ticks unless noted.
v6 defaults: every FZMR SIGNAL line satisfies z / RSI / ER / trend / range / session rules, every entry has its signal
line, stop = 2 x ATR and target = 2.5 x ATR of the signal bar, every expert exit is at >= 24 bars with z back at 0 or at
>= 34 bars, one position at a time. Buy-only 2 R run: buys only, target = 2 x stop distance, no expert exits.
v1.01: parity run (filters off, 1-min OHLC) must reproduce v1.00's 60 trades / net 2,382; filter run: no entry in
server hours 5-10, signal bar closed within 25% of its range from its extreme, sells within 1.4 ATR of EMA 200.
Run from the repo root with the MT5 GUI closed."""
import re, sys
sys.path.insert(0, "scripts"); import vwap_rsi_eval as E, holo_eval as H
WIN = ("2025-01-01", "2026-01-01")
BASE = {"InpDailyLossPct": "0", "InpMonthlyLossPct": "0"}
SIG = re.compile(r"\t(\d{4}\.\d\d\.\d\d \d\d:\d\d):\d\d   FZMR SIGNAL (BUY|SELL) (.*)")
EXT = re.compile(r"FZMR EXIT (BUY|SELL) (.*)")
KV = re.compile(r"(\w+)=(-?[\d.]+)")

def check(name, sets, tp_of, buys_only, time_exit, min_trades, model="real_ticks", extra=None):
    mark = H.agent_log_size()
    d, rows = E.run(name, dict(BASE, **sets), period="M15", expert="FZMR_EA", model=model, symbol="XAUUSD",
                    frm=WIN[0], to=WIN[1], timeout=1200)
    log = H.agent_log_since(mark)
    rows = sorted((r for r in rows if r["r_multiple"] is not None), key=lambda r: r["open_time"])
    sigs = {t: (side, {k: float(v) for k, v in KV.findall(rest)}) for t, side, rest in SIG.findall(log)}
    exits = [(side, {k: float(v) for k, v in KV.findall(rest)}) for side, rest in EXT.findall(log)]
    m = d["metrics"]
    print(f"{name}: trades {int(m['trades'])} PF {m['profit_factor']} net {m['net_profit']:,.0f} signals {len(sigs)} "
          f"expert exits {len(exits)} reasons {sorted({r['exit_reason'] for r in rows})}", flush=True)
    assert len(rows) == int(m["trades"]), ("csv rows != report trades", len(rows), m["trades"])
    assert len(rows) >= min_trades, ("too few trades for a check", len(rows))
    assert {r["exit_reason"] for r in rows} <= {"sl", "tp", "expert", "end_of_test"}, {r["exit_reason"] for r in rows}
    for t, (side, s) in sigs.items():
        buy, hour = side == "BUY", int(t[11:13])
        assert not (buys_only and not buy), ("sell signal with shorts off", t)
        assert (s["z"] <= -2.0 and s["rsi"] < 30.0) if buy else (s["z"] >= 2.0 and s["rsi"] > 70.0), ("z / rsi", t, s)
        assert ((s["fast"] > s["slow"] and s["slow"] >= s["slow4"] and s["close"] > s["slow"]) if buy else
                (s["fast"] < s["slow"] and s["slow"] <= s["slow4"] and s["close"] < s["slow"])), ("trend", t, s)
        assert s["er"] <= 0.40 and s["range"] <= 2.0 * s["atr"], ("er / range", t, s)
        assert 2 <= hour < 20 and hour not in (15, 16), ("session", t)
        assert abs(s["sl_dist"] - 2.0 * s["atr"]) < 1e-6 and abs(s["tp_dist"] - tp_of(s)) < 1e-6, ("stop / target", t, s)
        if extra:
            extra(t, buy, hour, s)
    for side, x in exits:
        assert time_exit, ("expert exit with the time exit off", side, x)
        assert x["held"] >= 34 or (x["held"] >= 24 and (x["z"] >= 0.0 if side == "BUY" else x["z"] <= 0.0)), ("exit rule", side, x)
    for r in rows:
        t = r["open_time"].strftime("%Y.%m.%d %H:%M")
        assert t in sigs and sigs[t][0].lower() == r["side"], ("entry without its signal line", t, r["side"])
        s = sigs[t][1]
        assert abs(abs(r["open_price"] - r["sl"]) - s["sl_dist"]) < 0.02, ("position stop", t, r["sl"], s["sl_dist"])
        assert abs(abs(r["tp"] - r["open_price"]) - s["tp_dist"]) < 0.02, ("position target", t, r["tp"], s["tp_dist"])
    assert sum(r["exit_reason"] == "expert" for r in rows) == len(exits), ("expert exits != EXIT lines", len(exits))
    ev = sorted([(r["open_time"], 1) for r in rows] + [(r["close_time"], -1) for r in rows], key=lambda e: (e[0], e[1]))
    cur = peak = 0
    for _, dlt in ev:
        cur += dlt; peak = max(peak, cur)
    assert peak == 1, ("more than one position at a time", peak)
    print(f"  entries {len(rows)} ({sum(r['side'] == 'buy' for r in rows)} buys) | sl {sum(r['exit_reason'] == 'sl' for r in rows)} "
          f"tp {sum(r['exit_reason'] == 'tp' for r in rows)} expert {len(exits)} | peak concurrent {peak}", flush=True)
    return m

m = check("fzmr_sc_parity", {}, lambda s: 2.5 * s["atr"], buys_only=False, time_exit=True, min_trades=30, model="1min_ohlc")
assert int(m["trades"]) == 60 and abs(m["net_profit"] - 2382.08) < 0.01, ("v1.01 with filters off != v1.00", m)

def filters(t, buy, hour, s):
    assert not 5 <= hour < 11, ("entry in skipped hours", t)
    retrace = ((s["close"] - s["low"]) if buy else (s["high"] - s["close"])) / s["range"]
    assert retrace <= 0.25 + 1e-9, ("bar retrace", t, retrace)
    assert buy or s["slow"] - s["close"] <= 1.4 * s["atr"] + 1e-9, ("sell too far below EMA 200", t, s)

check("fzmr_sc_filters", {"InpSkipFromHour": "5", "InpSkipToHour": "11", "InpMaxBarRetrace": "0.25", "InpSellMaxDistATR": "1.4"},
      lambda s: 2.5 * s["atr"], buys_only=False, time_exit=True, min_trades=10, extra=filters)
check("fzmr_sc_v6", {}, lambda s: 2.5 * s["atr"], buys_only=False, time_exit=True, min_trades=30)
check("fzmr_sc_long2r", {"InpAllowShort": "false", "InpTargetR": "2.0", "InpMaxHoldBars": "0"},
      lambda s: 2.0 * s["sl_dist"], buys_only=True, time_exit=False, min_trades=10)
print("SELFCHECK OK")

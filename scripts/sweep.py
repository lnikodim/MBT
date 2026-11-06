#!/usr/bin/env python3
"""Parallel input sweep: one optimization launch, every pass on its own local agent (system python; shells out to
macd_tester.py under Wine through macd_sweep.run).

  python3 scripts/sweep.py --expert MACD_Cross_EA --from 2025-01-01 --to 2026-10-01 --range InpRiskValue=0.5:0.5:2.0

Measured 2026-10-30 (XAUUSD H1, real ticks, 204 M ticks): 2 passes cost the wall time of one run (104 s against
101-103 s), 4 passes 131 s (3.1x faster than four runs in a row). One agent holds about 3.4 GB, so a launch is capped
at 4 passes (--max-passes) and a guard kills the run if free memory stays under 5%. It sweeps inputs of one EA over
one window; different windows or EAs are separate launches. MT5 must be closed (the helper refuses otherwise).
Afterwards the tester logs are cleared, as after every backtest (--keep-logs skips that).
"""
import argparse, glob, os, re, subprocess, sys, threading
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ea_profiles as P
import macd_sweep as M

TESTER = os.path.expanduser("~/Library/Application Support/net.metaquotes.wine.metatrader5/drive_c/"
                            "Program Files/MetaTrader 5/Tester")
LOW_FREE_PCT, LOW_SAMPLES, POLL_S = 5, 3, 5      # kill after 3 polls (15 s) with under 5% of memory free
COLS = ("Profit", "Profit Factor", "Trades", "Equity DD %", "Recovery Factor", "Sharpe Ratio")


def grid_size(ranges):
    """Passes of a complete grid; ranges maps name -> (start, step, stop) as strings."""
    n = 1
    for a, s, b in ranges.values():
        n *= int((float(b) - float(a)) / float(s) + 1e-9) + 1
    return n


def free_pct(text):
    """Free memory percentage from `memory_pressure` output, None if absent."""
    m = re.search(r"free percentage:\s*(\d+)%", text)
    return int(m.group(1)) if m else None


def mt5_running():
    """Wine shows the terminal and agents as `C:\\...\\terminal64.exe` (or `C:/...`); anchoring on the drive path keeps
    a shell whose command line merely mentions the name from counting."""
    out = subprocess.run(["ps", "-axo", "command"], capture_output=True, text=True).stdout
    return any(re.match(r"[A-Za-z]:[\\/].*(terminal64|metatester64)\.exe", line) for line in out.splitlines())


def guard(stop, tripped, run_name):
    """Poll free memory; on LOW_SAMPLES low polls in a row kill this run's terminal/wine python and the agents."""
    low = 0
    while not stop.wait(POLL_S):
        f = free_pct(subprocess.run(["memory_pressure"], capture_output=True, text=True).stdout)
        low = low + 1 if f is not None and f < LOW_FREE_PCT else 0
        if low >= LOW_SAMPLES:
            tripped.set()
            subprocess.run(["pkill", "-f", run_name])        # run_name carries a timestamp: matches only this launch
            subprocess.run(["pkill", "-f", "metatester64"])  # MT5 was closed at start, so these are ours
            return


def cleanup_logs(tester=TESTER):
    """User rule 2026-10-26 (same as screen_eval.cleanup): logs of earlier days are deleted, today's are truncated.
    Reports, tick history and caches stay."""
    master = glob.glob(os.path.join(tester, "logs", "*.log"))
    today = max((os.path.basename(f) for f in master), default="")
    for f in master + glob.glob(os.path.join(tester, "Agent-*", "logs", "*.log")):
        try:
            if os.path.basename(f) < today:
                os.remove(f)
            else:
                open(f, "r+b").truncate(0)
        except OSError:
            pass


def table(passes, varied, deposit):
    """Rows for the result table; net profit in USD and as % of the deposit (standing rule: always show total net)."""
    head = list(varied) + list(COLS) + ["Net %"]
    rows = [head]
    for p in passes:
        net = p.get("Profit")
        pct = f"{100 * net / deposit:+.1f}" if isinstance(net, (int, float)) else ""
        rows.append([M.fmt(p.get(k)) for k in varied]
                    + [M.fmt(p[k]) if isinstance(p.get(k), float) and p[k].is_integer() else f"{p[k]:.2f}"
                       if isinstance(p.get(k), float) else str(p.get(k, "")) for k in COLS] + [pct])
    width = [max(len(str(r[i])) for r in rows) for i in range(len(head))]
    return "\n".join("  ".join(str(c).rjust(w) for c, w in zip(r, width)) for r in rows)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--expert", required=True, help="EA name under MQL5\\Experts\\Advisors (must be in ea_profiles)")
    ap.add_argument("--from", dest="frm", required=True)
    ap.add_argument("--to", required=True)
    ap.add_argument("--range", action="append", required=True, help="Name=start:step:stop (numeric, repeatable)")
    ap.add_argument("--set", action="append", default=[], help="Name=value (fixed input)")
    ap.add_argument("--symbol", default="XAUUSD")
    ap.add_argument("--period", default="H1")
    ap.add_argument("--model", default="real_ticks")
    ap.add_argument("--criterion", default="0", help="MT5 OptimizationCriterion; 0 = balance, 6 = custom (OnTester)")
    ap.add_argument("--deposit", type=int, default=100000)
    ap.add_argument("--leverage", type=int, default=20)
    ap.add_argument("--name", default="sweep")
    ap.add_argument("--max-passes", type=int, default=4)
    ap.add_argument("--keep-logs", action="store_true")
    ap.add_argument("--dry", action="store_true", help="print the launch command only")
    a = ap.parse_args(argv)

    try:
        ranges = dict(P.parse_range(s) for s in a.range)
        sets = dict(s.split("=", 1) for s in a.set)
        P.tester_input_lines(P.merge_inputs(a.expert, sets), ranges)   # unknown EA or input -> ValueError
    except ValueError as e:
        sys.exit(str(e))
    n = grid_size(ranges)
    if n > a.max_passes:
        sys.exit(f"{n} passes is more than --max-passes {a.max_passes}: each agent holds about 3.4 GB; narrow the "
                 f"ranges or raise the cap knowingly")
    if not a.dry and mt5_running():
        sys.exit("MT5 is running: close the terminal first (tester launches need it closed)")

    run_name = f"{a.name}_{M.STAMP}"
    M.DRY = a.dry
    M.OUTDIR = os.path.join(M.ROOT, "reports", run_name)
    stop, tripped = threading.Event(), threading.Event()
    if not a.dry:
        threading.Thread(target=guard, args=(stop, tripped, run_name), daemon=True).start()
    try:
        d = M.run("opt", run_name, sets=sets, ranges={k: ":".join(v) for k, v in ranges.items()}, model=a.model,
                  frm=a.frm, to=a.to, symbol=a.symbol, expert=a.expert, period=a.period, criterion=a.criterion,
                  deposit=a.deposit, leverage=a.leverage)
    finally:
        stop.set()
        if not a.dry and not a.keep_logs:
            cleanup_logs()
    if a.dry:
        return 0
    if tripped.is_set():
        print(f"GUARD: free memory stayed under {LOW_FREE_PCT}%, the sweep was killed; try fewer passes")
        return 3
    passes = d.get("passes") or []
    if len(passes) != n:
        print(f"expected {n} passes, got {len(passes)}: {d.get('error') or 'see ' + M.OUTDIR}")
        return 4
    print(f"{a.expert} {a.symbol} {a.period} {a.model} {a.frm}..{a.to}, deposit {a.deposit} USD, {n} passes, "
          f"{d.get('ran_seconds')} s\n" + table(passes, ranges, a.deposit) + f"\n(json: {M.OUTDIR})")
    return 0


if __name__ == "__main__":
    sys.exit(main())

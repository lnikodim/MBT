# GDS_Renko_Bollinger_EA on Darwinex XAUUSD M1 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/77236". Server: Darwinex-Demo.

**The EA:** "GDS Renko Bollinger 4-Mode Demo EA" v1.30 (mql5.com code 77236, Andrey Goida / gavaav, "Golden Delta",
published 2026-09-11), `GDS_Renko_Bollinger_4Mode_Demo.mq5`, 1,314 lines, MD5 d83ac7c5….
- **Copied unchanged to:** `mql5/GDS_Renko_Bollinger_EA.mq5` (renamed per the naming convention).
- **Compile:** 0 errors. The 4 warnings are all "description is too long" on `#property description` lines.
- **Safety:** no DLL, web or file calls. It prints on entries, exits, trade errors and same-tick opposite signals only,
  not per tick.

**The author's claim** (XAUUSD M1, every tick based on real ticks, history quality 100%, 2026-05-01..2026-09-08, 10,000
deposit, defaults):
- net +4,084.32, PF 4.22, equity DD 2.86% (balance 2.06%);
- 108 trades, 65.7% won, 48,458,994 ticks.
- **In-sample by the author's own statement:** "the supplied settings were selected from historical testing and are not
  evidence of a persistent trading edge". So 2026-05..09 is the fitted window.

**What the code does** (every tick; Renko built from bid inside the EA; signals only on completed bricks):
- **Four independent engines**, each with its own brick size (in price units: 17 / 30 / 30 / 14 USD on gold),
  Bollinger bands on the previous brick closes, and its own magic number:
  1. **Breakout:** a brick closes beyond the outer band, in a run of at least 2 bricks in the same direction.
  2. **Re-entry:** the previous brick was outside a band and this one closes back inside; exits at the middle line.
  3. **Midline cross:** a brick crosses the middle line.
  4. **Squeeze breakout:** a band break while the band width is at most 34.5 bricks.
- **Exits** (all virtual, checked every tick): TP / SL in bricks (24 / 42, 28 / 48.5, 10 / 34.5 and 26 / 31), a maximum
  hold (1,230-2,580 minutes), and an opposite band signal.
- **Portfolio rules:**
  - one position per mode, up to 4 in total;
  - entries are skipped when modes disagree on the same tick;
  - spread <= 0.35 of the brick;
  - a cooldown of 1-5 bricks after an exit.
- **Size:** fixed 0.01 lot.

## Runs (`reports/gds/gds_eval.py`; Darwinex-Demo, XAUUSD M1, real ticks, 10,000 USD = the author's deposit, 1:100, defaults)
1. **R0, replication:** 2026-05-01..2026-09-08, the author's window. It also serves as the log-growth probe.
2. **S0, 2022-01-01..2026-10-01.** 2022-24 lies wholly before the fitted window.
3. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**Unit:** the lot is fixed and the virtual stops are far from price, so trades are measured in USD at 0.01 lot, not R.
- **Stops vs volatility:** the stops are 434-1,455 USD per ounce, against holds of at most 43 h.
- **Trades:** legs come from the Deals table (`scripts/blessing_eval.py` `deals_trades`).
- **Exit reasons by mode:** counted from the EA's "exit completed" log lines.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net USD > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, t of the mean USD per trade >= 1.65. If history quality is below
  90%, it is inconclusive.
- **Candidate** = both pass. No input search.
- **Reported:** net USD (0.01 lot on 10k), PF, max DD, trades, win rate, mean USD per trade (t), net by year, long and
  short split, exits by mode and reason, R0 vs the author.

## Expectation (written before the runs)
- **R0:** about the author's result. It is the same window on real ticks, with a different broker feed.
- **Before 2026:**
  - The bricks are fixed in dollars and fitted to 2026 gold (about 4,000 USD, wide daily ranges). In 2022-23, with
    gold near 1,800-2,000, the same bricks are about twice as large relative to price moves.
  - Fewer trades, and most exits by time or an opposite signal.
  - About 45 inputs fitted on 4 months.
- **S0:** PF 0.85-1.10 outside 2026, with 2022-24 at or below zero.
- **Most likely verdict:** closed (Gate A fails in 2022-24, or there are too few trades).

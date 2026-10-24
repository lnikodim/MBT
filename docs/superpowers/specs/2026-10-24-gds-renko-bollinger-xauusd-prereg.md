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

## Outcome (2026-10-24; log `reports/gds/base.log`): closed
| run (XAUUSD M1, real ticks, 10k, 0.01 lot) | net USD | PF | max DD | trades | win | mean USD (t) | net by year |
|---|---|---|---|---|---|---|---|
| R0 2026-05-01..09-08 (the author's fitted window) | +3,387.28 | 3.62 | 2.9% | 107 | 65.4% | +31.66 (+5.08) | author: +4,084.32, PF 4.22, 108 trades |
| S0 2022-01..2026-10, hq 100% | +3,868.08 | 1.27 | 11.4% | 659 | 50.5% | +5.87 (+2.20) | 22 +28, 23 +15, 24 +10, 25 +473, 26 +3,343 |
| S1 2019-01..2022-01, hq 99% | **-215.37** | 0.77 | 4.5% | 105 | 42.9% | -2.05 (-1.05) | 19 -90, 20 +45, 21 -170 |

- **Gate A passes only on paper:** 2022-24 is +52.51 USD over 3 years, about 0.2 USD a trade, so about zero.
  2025-26 is +3,815.57.
- **The fitted window is almost all of the profit:** R0's +3,387.28 is 88% of S0's +3,868.08. The rest of 2026 is about
  -44 USD, and 2022-25 is +526 USD over about 550 trades.
- **Out-of-sample check fails:** 2019-21 is -215.37 USD, PF 0.77, t -1.05. Closed per the pre-registration.
- **Exits:**
  - Virtual TP: hit 4 times in 659 trades. Virtual SL: never.
  - Max-hold timer: 439 trades.
  - Opposite band signal or the midline: the rest.
  - So the edge, where there is one, is a holding-time drift in 2025-26 gold. The Renko TP / SL design does not drive it.
- **Replication:** the author's window reproduces closely on real ticks (+3,387 vs +4,084; 107 vs 108 trades). This shows
  the EA works as described, not that it has an edge.
- **Expectation check:**
  - 2022-24 at about zero, as expected.
  - PF 1.27 over 2022-26 is above the expected 0.85-1.10, because the fitted 2026 window is inside S0.
- **Removed** per the leftovers rule: `mql5/GDS_Renko_Bollinger_EA.mq5`, its profile and the MT5 copies (the source is in
  git at 5ae4e9e).

# GER40_Evening_Coil_EA on DE40 H1 (pre-registration)

Date: 2026-10-22. User: "can you backtest GER40? https://www.mql5.com/en/code/78380", then "MT5 closed, go ahead on
Darwinex". Server: Darwinex-Demo (user rule: always the first choice for backtests). Darwinex names the index DE40.

**The EA:** "GER40 Evening Coil", by the author of the Monday EA ("Orangutang Trading"), v1.00, MD5 069c8675…. It is
the code-page download `Ger40_eveningcoil.mq5`, copied unchanged to `mql5/GER40_Evening_Coil_EA.mq5` and renamed per
the naming convention. It compiles with 0 errors and 0 warnings. H1, long only, one position at a time.
- **Signal:** a bar that opens 17:00-20:59 server time, Monday to Friday, with all four conditions true:
  1. stdev of the last 10 hourly returns / stdev of the last 100 < 1.6;
  2. the bar's tick-volume z-score against 50 bars > -0.1;
  3. the average tick volume of the last 252 bars < 2125 (an absolute level from the author's feed);
  4. an NR7 bar within the last 13 bars.
- **Entry:** buy at the Ask on the first tick of the next bar.
- **Exit:** stop 3.5 x ATR(14), target 4.5 x ATR(14) (1.29 R), and everything closed at 23:00 server time (or a
  minute before the session ends). Holds are 2-5 hours, with no swap.
- **Lots:** a fixed `InpLots`.

**Author's claim** (code page: GER40 H1, 2022-01-01..2026-10-13, $10k, fixed 5 lots):
- +$37,647 (+376.5%), PF 2.07, max DD 10.5%, 465 trades (all long), 62.6% wins.
- Found by automated research: "Harvey-Liu haircut for 5,552 candidates tested".
- The author reports out-of-sample results from their own research engine, not MetaTrader.
- Their window is our standard 2022-26 window, so a run there is a replication only.

**Review before the run** (kept, as the file runs as written):
- **Condition 3 depends on the broker.** The 2125 level comes from another broker's tick-volume feed; the author says
  "test with the condition off (Average volume ceiling = 0)" on other feeds. Both versions are run here.
- **No checks on the intended chart.** On DE40 H1 the EA's validation code is inactive: no margin check and no risk
  ceiling, and lots are only rounded to the step.
- **No spread filter** by default (`InpMaxSpreadPts` 0), and entries fall in the thinner evening session.
- **Tick volume drives conditions 2 and 3.** In the tester with real ticks, bar tick volume is Darwinex's tick count.

## Runs (`reports/ger40/ger40_eval.py`; Darwinex-Demo, DE40 H1, real ticks, 100k USD, 1:100)
`InpLots` = 1.0, the only other input change. The EA has no sizing logic, so lots only scale the dollar results; R and
PF do not depend on them. Dollar results are also reported scaled to the author's exposure, 5 lots per $10k, using the
Darwinex value per point measured from the trades.

| run | condition 3 | window |
|---|---|---|
| S0A | as written (2125) | 2022-01-01..2026-10-01 |
| S0B | off (`InpAvgVolumeMax` 0) | 2022-01-01..2026-10-01 |
| S1A | as written | 2019-01-01..2022-01-01 (out of sample, before the author's window) |
| S1B | off | 2019-01-01..2022-01-01 |

**Which version is evaluated** (fixed now): A if S0A makes at least 230 trades (half the author's 465 over the same
span), otherwise B. A mismatched broker level would show up as far fewer trades.

**R per trade** = net (profit + commission + swap) / (stop distance x volume x value per point).
- The stop distance comes from the order's S/L in the report's Orders table.
- The value per point comes from the trade's own gross P/L / (price move x volume), or the run's median when the move
  is under 2 points.
- A stop exit should be about -1 R, and this is checked.

## Checks and reports
- **Gate A (evaluated version, S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (evaluated version, S1):** net > 0, PF >= 1.05 and mean R per trade t >= 1.65. If history
  quality is below 90%, it is inconclusive.
- **Reported, for all four runs:**
  - net (USD, and scaled to the author's exposure), PF, max equity DD, trades, win rate;
  - mean R (t), R by year;
  - exits (stop, target, 23:00 flat) with average R;
  - the condition-3 level the EA prints at start (Darwinex's 252-bar average tick volume);
  - order failures and the history quality line.
- **If both checks pass:** the joint with the live set (gold 4-EA + DonchianTrend + Monday) is run next, reported.

## Hypothesis
- **Condition 3 on Darwinex:** about a 60% chance S0A makes under 230 trades, so B is evaluated.
- **S0, evaluated version:** PF 1.2-1.7, below the claimed 2.07 (selection from 5,552 candidates and Darwinex costs).
  About a 65% chance Gate A passes.
- **S1:** PF 0.9-1.3 and t under 1.65. The chance the out-of-sample check passes is about 25%.

## Decision rule
- **Gate A and the out-of-sample check pass:** a candidate. The live-set joint and live sizing are pre-registered next,
  and an IC Markets check before any deployment.
- **Otherwise:** closed, and leftovers are removed (user rule).
- If DE40 real ticks are missing (history quality below 90%) for part of S0, results are provisional and say so.

## Amendment 1 (2026-10-22, before any result): the Darwinex symbol is GDAXI
The first S0A launch failed with "symbol DE40 not exist". The `DE40` history folder in the local cache is a leftover;
Darwinex-Demo lists 846 symbols and no DE40. A 2-day probe found **GDAXI** (GER40, DAX40, DE40m and others were not
tried after it). The EA counts GDAXI as its intended chart (`IsGermanIndex()` matches "GDAXI"), so its behaviour is the
same as on GER40. All runs above use GDAXI; nothing else changes.

## Outcome (2026-10-22; GDAXI, agent log "generating based on real ticks" in all four runs; history quality 99%; log `reports/ger40/base.log`)
| run, 1.0 lot (value per point 10.9-11.3 USD/lot, i.e. EUR 10) | net USD | PF | max equity DD | trades | win | R, mean R (t) |
|---|---|---|---|---|---|---|
| S0A as written, 2022-26 | +42,776.42 | 1.50 | 7.39% | 265 | 56.6% | +15.3, +0.058 (t 1.75) |
| S0B condition 3 off, 2022-26 | +80,322.75 | 1.25 | 19.92% | 846 | 56.7% | +32.6, +0.039 (t 2.25) |
| S1A as written, 2019-21 | +218.82 | 1.77 | 0.64% | 3 | 66.7% | +0.1, +0.041 (t 0.24) |
| S1B condition 3 off, 2019-21 | +12,980.13 | 1.07 | 28.29% | 553 | 54.1% | +3.5, +0.006 (t 0.32) |

**On Darwinex, condition 3 works as a date filter, not a regime filter.**
- Darwinex's 252-bar average tick volume was 5182 at the start of 2019 and 3838 at the start of 2022, against the
  rule's 2125.
- S0A therefore traded only from 2024 (114 / 131 / 20 trades in 2024 / 2025 / 2026), when the feed's volume fell below
  the level. S1A made 3 trades in three years.

**Evaluated version: A** (S0A 265 trades >= 230, as fixed in advance).
- **Gate A passes:** 265 trades, PF 1.50, R +2.8 in 2022-24 (all from 2024) and +12.5 in 2025-26.
- **Out-of-sample check fails:** 3 trades, t 0.24. On Darwinex data, version A cannot be tested out of sample; it
  hardly trades there.

**Version B** (condition 3 off, the author's own advice for other feeds) is the test of the other three conditions:
- **2022-26:** a thin edge, +0.039 R per trade (t 2.25), negative in 2022 (PF 0.83) and 2026 (PF 0.81).
- **2019-21:** no edge: +0.006 R per trade, t 0.32, PF 1.04 in R, max DD 28%.

**Costs and exits** (both versions):
- 90% of trades exit at the 23:00 flat close (average +0.05 to +0.08 R).
- Stop exits average -1.11 to -1.27 R: fills past the stop.

**Decision: not a candidate.** Version A fails the out-of-sample check (rule), and version B's out-of-sample result
shows no edge either. On the hypothesis:
- condition 3 did mismatch, but S0A still reached 265 trades because Darwinex's volume fell in 2024-26;
- the 2022-26 PF of 1.50 / 1.25 was inside or just below the 1.2-1.7 forecast;
- the out-of-sample check failed as forecast.

**Removal (user rule).** Removed `mql5/GER40_Evening_Coil_EA.mq5`, its `scripts/ea_profiles.py` entry, and the MT5
.mq5, .ex5, compile log and tester .set (no chart had it). The file stays in git at d6be668.

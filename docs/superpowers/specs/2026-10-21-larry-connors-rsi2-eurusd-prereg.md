# Larry_Connors_RSI2_EA on EURUSD H1, as written (pre-registration)

Date: 2026-10-21. User: "let's test now another EA: …/Downloads/LarryConnersRSI2.mq5. The 1st candidate for testing
should EURUSD H1". Server: Darwinex-Demo (user rule: always the first choice for backtests). Scope (the user's choice):
"As-is, then decide": the file is tested unchanged, then the user decides on tuning or fixes.

The EA (algotrading.co.za 2017, MD5 853f9932…, copied unchanged to `mql5/Larry_Connors_RSI2_EA.mq5`, renamed per the
naming convention). On every tick, using the last closed bar of the chart period:
- **Long:** RSI(2) < 6 and close > SMA(200).
- **Short:** RSI(2) > 95 and close < SMA(200).
- **Exit:** a long closes when close > SMA(5); a short closes when close < SMA(5).
- **Size and stops:** fixed 1 lot, stop 30 pips, target 60 pips, one position per symbol (any magic).

A review before the run found these code defects. They are kept, because this test runs the file as written:
- **Signals are checked on every tick.** After a stop or target fills inside a bar, the closed-bar condition still
  holds, so the EA can re-enter in the same bar.
- **Magic number 0.** Positions are not isolated from other EAs.
- **A sell is sent at the Ask price.**
- **No spread filter**, and array reads are not guarded.

The run reports the size of each defect's effect, so a fixed copy can be judged against it later.

## Run (`reports/rsi2/rsi2_eval.py`, Darwinex-Demo, EURUSD H1, real ticks, 2022-01-01..2026-10-01, 100k USD, 1:100)
Compiled defaults (profile `Larry_Connors_RSI2_EA`). Trades are rebuilt from the report's Deals table.

R per trade = net (profit + swap + commission) / $300, the planned loss of 1 lot over 30 pips on EURUSD. That is 0.3% of
the 100k deposit.

## Checks and reports
- **Gate A:** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Reported:**
  - net profit, PF, max equity drawdown, win rate, longs and shorts;
  - exit mix: stop (loss >= 29.5 pips), target (gain >= 59.5 pips), SMA5 exit (the rest);
  - average R per exit type;
  - entries by server hour;
  - same-bar re-entries (more than one entry in one H1 bar) and their net R;
  - order and close errors in the agent log;
  - history quality.
- **prop_mc alone:** close_time,R file, --risk 0.3,0.5, 10k sims, seeds 1-3.
- If Gate A passes, also the joint with the gold live set (the 4 Darwinex logs of spec
  2026-10-21-donchiantrend-gold-joint-prereg.md), reported only.

## Hypothesis
Connors' RSI(2) rule was built for daily stock indices. On EURUSD H1, RSI(2) extremes come often, the reversion to the
5-bar mean is a few pips, and the round-trip cost (spread plus commission, about 1 pip or more) eats a large share of
it.
- Expected: several hundred trades, mostly closed by the SMA5 exit, and few targets hit.
- Expected: PF 0.85-1.05 and Gate A fails.
- Same-bar re-entries are rare (under 2% of trades).

## Decision rule
- **Gate A fails:** EURUSD H1 is closed for the EA as written. The report lists what a fixed or tuned version would
  change (each would be pre-registered separately), and the user picks the next candidate symbol or timeframe.
- **Gate A passes:** a fixed copy (one entry per bar, magic number, % risk, spread guard) and an input grid are
  pre-registered next. The as-written file never goes live (magic 0).

## Outcome (2026-10-21; agent log: "EURUSD,H1 (Darwinex-Demo): generating based on real ticks"; history quality 99%; log `reports/rsi2/base.log`)
| as written | net | PF | max equity DD | trades | win | R (per trade) | R 2022-24 / 2025-26 | Gate A | prop_mc @0.3% / 0.5% |
|---|---|---|---|---|---|---|---|---|---|
| EURUSD H1 | -870.55 | 0.99 | 8.17% | 869 (454 L / 415 S) | 61.0% | -2.9 (-0.003) | -21.5 / +18.6 | **fail** | 0.0 / 0.4 |

**Exits:**
| exit | trades | avg R |
|---|---|---|
| SMA5 | 686 | +0.225 |
| stop | 172 | -1.026 |
| target | 10 | +1.99 |

**Costs:** commission -$4,756 (-15.9 R, $5.47 per trade) and swap -1.5 R. Before costs the rules made +14.5 R
(+0.017 R per trade), so commission alone erases the edge.

**Code checks:**
- **Same-bar re-entries:** 39 extra entries in 31 bars, -5.8 R. Removing them leaves 830 trades, +2.9 R, PF 1.015,
  still -15.1 R in 2022-24.
- **Agent log:** 0 failed orders and 0 array errors.

**Decision: Gate A fails, so EURUSD H1 is closed for the EA as written.** The hypothesis held on PF and the exit mix.
Same-bar re-entries were 4.5% of trades, above the forecast of under 2%. Fixing them alone would not pass Gate A
(2022-24 stays negative).

The independent code review confirmed the defects and ranked them for live use:
1. magic 0 with whole-symbol position selection; it can also close manual EURUSD trades;
2. no once-per-bar gate, so it re-opens after any close, including a manual or risk-manager flatten;
3. fixed lot with no loss guard;
4. unchecked indicator copies;
5. per-tick retries of rejected orders.

What a new version would have to change, each pre-registered separately:
- **Cost per trade against edge per trade.** A higher timeframe (H4, D1, as Connors used it) gives larger reversion
  moves; a lower-commission symbol or broker cuts the cost.
- **The once-per-bar fix.**

## Stage 1, tweak (pre-registered 2026-10-21, before its runs)
User: "Can you tweak it and run again backtest?" EURUSD H1, Darwinex-Demo, real ticks, 100k, 1:100, as above.

**Code, v1.01** (`mql5/Larry_Connors_RSI2_EA.mq5`; the as-written file stays in git at 311b9f2). These are correctness
fixes, not edge changes:
- one entry attempt per bar;
- magic 261022, with position selection and closes by magic;
- sells sent at the Bid;
- indicator handles and copies checked;
- live only: no entry on the bar the EA was loaded in;
- the error logs print the trade server's return code.

- **P0 parity.** v1.01 with the original inputs against the as-written run.
  - Every v1.01 entry must be in the baseline (same open time and side), or must directly follow a removed same-bar
    re-entry (a displacement).
  - Every baseline-only entry must be a same-bar extra or displaced.
  - Unexplained entries: 0. Otherwise the fix is wrong and the grid does not start.

**Input grid, two regimes** (MT5 complete grid, criterion 0 because the EA has no OnTester), 400 passes per regime:
- `RSILongEntry` 2:2:10
- `RSIShortEntry` 90:2:98
- `shortSmaPeriods` (exit SMA) 5:5:20
- `stopLossPips` 20:20:80

The rest stays at the defaults (SMA200 trend filter, target 60 pips). Regimes: 2022-01-01..2025-01-01 (train) and
2025-01-01..2026-10-01.

**Selection, with a holdout** (lesson of the DonchianTrend joint test: a two-regime pick on the same window is
in-sample):
- **Train pick.** Rank 2022-24 tuples with >= 100 trades, equity DD <= 10% and PF >= 1.15 by PF x recovery factor.
  The pick is the first one whose grid neighbours average PF >= 1.05.
- **Holdout.** The train pick's 2025-26 pass, never used to choose it, must have PF >= 1.05 and net > 0. Reported with
  its rank among the 400 2025-26 tuples.
- **Joint pick** (the DonchianTrend method: both regimes, PF >= 1.15, plateau in both): reported for comparison only.

**Confirm.** The train pick (and the joint pick, if different) on the full 2022-01..2026-10 window with v1.01.
- Reported: net, PF, max DD, trades, R by regime, Gate A, and prop_mc alone (R = net / (lot x stop pips x $10)), next to
  the as-written baseline.
- If Gate A passes: also the joint with the gold live set (reported).

**Decision rule.** The train pick is the recommended tweak only if the holdout check passes and it passes Gate A on the
full window. Otherwise EURUSD H1 is closed for this EA, and v1.01 stays as the corrected base for other candidates.

**Hypothesis.** Commission is about 0.018 R per trade at a 30-pip stop and shrinks with a wider stop. A slower exit and
stricter RSI levels raise R per trade. Expected: train pick PF 1.10-1.25 in 2022-24; holdout PF 0.95-1.15. The chance
that the holdout and Gate A both pass is low, about 30%.

## Stage 1 outcome (2026-10-21; history quality 99%; logs `reports/rsi2/parity.log`, `reports/rsi2/grid.log`)
**P0 parity: pass.**
- Trades: baseline 869, v1.01 847, common 823.
- The 46 baseline-only entries are 39 same-bar extras plus displacements; the 24 v1.01-only entries are displacements.
- Unexplained: 0.
- v1.01 with the original inputs: net +1,596.59, PF 1.03, max equity DD 7.31%, R +5.3 (2022-24 -13.2 / 2025-26 +18.5),
  Gate A fails. The fix alone is worth +8.2 R.

**Grid.**
- 2022-24: 400 passes, median PF 0.95, 113 profitable.
- 2025-26: 400 passes, median PF 0.99, 196 profitable.
- The 2025-26 run was cut off once, when the session ended, and was rerun in full.
- 8 of the 400 2022-24 tuples meet the train filters, and all 8 have RSIShortEntry 96.

| | RSI long / short, exit SMA, stop | PF | max equity DD | trades | net |
|---|---|---|---|---|---|
| train pick, 2022-24 | 2 / 96, SMA15, 80 pips | 1.28 | 1.99% | 278 | +6,804 |
| holdout, 2025-26 | same | 1.10 | 2.35% | 139 | +1,382 |

- **Holdout: pass** (PF >= 1.05 and net > 0). Rank 127 of 400 in 2025-26.
- **Joint pick:** none. No tuple has PF >= 1.15 on a plateau in both regimes.

**Confirm (full 2022-01..2026-10, v1.01, train pick; R = net / $800, 1 lot x 80 pips; log `reports/rsi2/grid.log`)**
| | net | PF | max equity DD | trades | win | R (per trade) | R 2022-24 / 2025-26 | Gate A | prop_mc @0.3% / 0.5% |
|---|---|---|---|---|---|---|---|---|---|
| as written | -870.55 | 0.99 | 8.17% | 869 | 61.0% | -2.9 (-0.003) R30 | -21.5 / +18.6 | fail | 0.0 / 0.4 |
| v1.01 train pick | +8,186.15 | 1.22 | 2.20% | 417 (125 L / 292 S) | 64.8% | +10.2 (+0.025) R80 | +8.5 / +1.7 | **pass** | 0.0 / 0.0 |

- **Exits:** SMA15 388 (avg +0.066 R), stop 21 (avg -1.009 R), target 7 (avg +0.81 R).
- **Code checks:** 0 same-bar entries, 0 failed orders, 0 array errors.
- **Gold live set joint** (reported only, seeds 1-3, P(pass both) at 0.3% / 0.5%): gold 4-EA 93.7-94.1 / 84.2-84.7;
  with RSI2 added, 94.4-94.8 / 84.9-85.3. That is +0.2-1.1 pts per seed, less than DonchianTrend's +1.6-2.3.

**Decision: the train pick is the recommended tweak** (holdout and Gate A pass, so the rule's condition is met). On the
hypothesis: train PF 1.28 is just above the 1.10-1.25 forecast, and the holdout PF of 1.10 is inside the forecast.

**Reported, not pre-registered:**
- **Neighbours in 2025-26:** the pick's 6 neighbours average PF 1.13 (0.96-1.40), so the plateau holds in the holdout.
- **Edge per trade.** Gross +2.61 pips, net +1.96 pips ($19.63 at 1 lot), so commission and swap take about
  0.65 pips. One extra pip of slippage per trade would halve the net edge. It is a thin edge on EURUSD.
- **Longs and shorts:** both PF 1.22, but shorts are 70% of trades.
- **Small edge in 2025-26:** +1.7 R on 139 trades (+0.012 R per trade). Almost all of the full-window R is from
  2022-24, the training window.
- **prop_mc alone is 0:** at +0.025 R per trade and 0.3-0.5% risk, the account never reaches the profit target in
  time. The EA adds to a portfolio; it is not a standalone prop strategy.

**Not done, for live use:** v1.01 trades a fixed 1 lot. Before any live or demo use it needs % risk sizing and a spread
guard (the stage 0 list), each pre-registered with a parity check against this confirm run.

## Verdict and removal (2026-10-21)
The rule passed, but the edge is not distinguishable from zero.
- **Per-trade R t-statistics:** full window t 1.45, 2022-24 t 1.49, 2025-26 holdout t 0.42.
- **The tuning hurt the unseen period.** In 2025-26, at 1 lot, v1.01 with the original inputs made about +$5,550
  (+18.5 R x $300); the pick made +$1,382.

**Lesson for later pre-registrations:** "holdout PF >= 1.05 and net > 0" passes a near-zero edge. A holdout check also
needs a minimum t-statistic or R per trade.

**Decision:** the EA is not traded. On the user's request ("ok, remove it") it is removed from the repo, from
`scripts/ea_profiles.py` and from the MT5 terminal (source, .ex5, compile log, tester .set). Both versions stay in git:
as written at 311b9f2, v1.01 at 6fd3171. The H4 / D1 idea was not tested.

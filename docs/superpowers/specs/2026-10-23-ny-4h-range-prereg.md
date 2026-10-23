# NY_4H_Range_EA on Darwinex EURUSD and XAUUSD M5 (pre-registration)

Date: 2026-10-23. User: "let's make a new EA: https://www.mql5.com/en/code/68082". Server: Darwinex-Demo.

**The source:** "Viral (1M+ views) 4 Hour Range Strategy coded and tested" (mql5.com code 68082),
`DataTraderH4Breakout.mq5` v1.01 by Peter Mueller, published 2026-01-10, MD5 aeb8eb51…. The author writes:
"Backtests on EURUSD under my conditions were unprofitable."

**What the source does:**
- **Range:** the high and low of the M5 bars in the first 4 hours of the New York day (00:00-04:00 NY).
- **Signal:** after 04:00 NY, on each new M5 bar, with no position open:
  - a bar closed below the range low and the next bar closed back above it: **buy**;
  - a bar closed above the range high and the next bar closed back below it: **sell**.
- **Stop:** the lowest low (buys) or highest high (sells) of the bars that closed outside the range.
- **Target:** 2 x the stop distance.
- **Time limit:** no trade if 14 or more bars in a row closed outside the range (at most 13 bars, 65 minutes).
  The page says 75 minutes; the code allows 65.
- **Other:** fixed 0.1 lot, no time exit, positions can stay open overnight. Signals run until the next NY midnight.

**We tested this strategy before.** `FourHourRangeScalper.mq5` (2026-09-20, before pre-registration) ported the same
YouTube strategy from its transcript (`docs/specs/FOUR_HOUR_RANGE_SCALP_SPEC.md`). It had no time limit. Results
(Darwinex, M5, 2017-01..2026-09, on the 1-min OHLC model, which flatters by about 0.05-0.10 PF):
- EURUSD: PF 0.68 and 0.83 (two variants), 3,068 and 3,282 trades, -$9,963 and -$6,267.
- XAUUSD: PF 0.95, 3,217 trades, -$6,931.

So the one new idea here is the time limit. A breakout that stays outside the range for over an hour is likely a
real trend day, and fading it is the old port's likely failure mode.

## The New York clock (checked today on Darwinex-Demo)
The Darwinex server clock is **New York + 7 hours all year**: it changes with US daylight saving time, not EU.
- **US CPI** (08:30 NY) shows as the largest EURUSD M5 bar at server 15:30 on 2026-02-11 (both zones on winter time)
  and on 2026-03-11 (US on summer time, EU not yet). On the EU rule it would have been at 14:30 on 03-11; that bar
  was 46 points, against 185 at 15:30.
- **Week open:** every week of 2025-07..2026-10 opens at server Monday 00:00, including the March 2026 and
  October 2025 weeks when the two zones disagree.

So NY time = server time - 7 h, with no DST logic. The source's own clock (switches on 1 March and 1 November) is
wrong for about 7 weeks a year, and the old port (EU rule) for about 4. Other brokers need the same check before live
use.

## The port (`mql5/NY_4H_Range_EA.mq5` v1.00, on EACore, magic 261025)
The source's rules, with these changes:
1. **Clock:** NY = server - `InpServerMinusNY` hours (7).
2. **Range bars:** bars opening 00:00-03:55 NY. The source includes the previous day's 23:55 bar and leaves out the
   03:55 bar (an off-by-one bug).
3. **One position at a time** counts only this EA's own positions. The source's `PositionsTotal() == 0` counts the
   whole account, so any other EA's trade would block it.
4. **Sizing:** EACore % risk on the stop distance (1% in tests) instead of a fixed 0.1 lot.
5. **EACore guards:** daily -4% and monthly -12% loss stops (research values). Spread cap off and no spread retry, as
   in the source.

Unchanged: M5 closes only, stop and target levels, the 13-bar limit, the source's stop-distance check
(> 4 x the broker's stops level), no time exit, signals until NY midnight.

## Runs (`reports/ny4h/ny4h_eval.py`; Darwinex-Demo, M5, real ticks, 100k USD, 1:100, 1% risk)
For each symbol, EURUSD (the author's) and XAUUSD (our portfolio's market):
1. **S0, 2022-01-01..2026-10-01**, limit 13 bars (the source).
2. **S1, out of sample, 2019-01-01..2022-01-01**, limit 13 bars.
3. **C0, 2022-01-01..2026-10-01**, limit off (control: what the old port lacked).

**R per trade** = net / (stop distance x volume x value per point), with the stop taken from the Orders table (parser
of `reports/crabel/crabel_eval.py`).

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, S1 counts as
  inconclusive and the symbol cannot be a candidate.
- **Candidate** = Gate A and the out-of-sample check both pass, per symbol. Anything else closes the EA on that symbol.
  No input search follows a fail.
- **Time limit effect** (S0 vs C0): reported, not a gate.
- **Reported for every run:** net USD (at 1% risk) and net R, PF, max DD, trades, win rate, mean R (t), R by year,
  long and short split, exits (stop / target), history quality.

## Expectation (written before the runs)
- **EURUSD:** Gate A fails, PF 0.80-0.95.
- **XAUUSD:** PF 0.90-1.05; Gate A fails or passes narrowly; the out-of-sample check fails.
- **Time limit:** PF +0.00 to +0.08 over C0, with 10-25% fewer trades.
- **Most likely verdict:** closed on both symbols.

## Outcome (2026-10-23; log `reports/ny4h/base.log`): closed on both symbols
| run (100k, 1% risk) | net USD | PF | max DD | trades | win | net R | mean R (t) | R by year |
|---|---|---|---|---|---|---|---|---|
| EURUSD S0 2022-26, hq 100% | -97,331.12 | 0.75 | 97.4% | 2,133 | 30.5% | -431.0 | -0.202 (-6.37) | 22 -83.4, 23 -91.5, 24 -96.5, 25 -53.8, 26 -105.8 |
| XAUUSD S0 2022-26, hq 100% | -95,863.71 | 0.80 | 96.4% | 2,253 | 30.4% | -340.0 | -0.151 (-5.04) | 22 -88.1, 23 -74.1, 24 -43.6, 25 -69.2, 26 -65.0 |
| EURUSD S1 2019-21, hq 99% | -91,678.02 | 0.73 | 92.2% | 1,418 | 30.2% | -320.3 | -0.226 (-6.05) | 19 -157.3, 20 -62.0, 21 -101.0 |
| XAUUSD S1 2019-21, hq 99% | -92,351.63 | 0.75 | 92.5% | 1,248 | 28.9% | -264.0 | -0.211 (-5.34) | 19 -77.6, 20 -84.0, 21 -102.4 |
| EURUSD C0 limit off | -93,376.34 | 0.72 | 93.5% | 1,409 | 29.6% | -287.7 | -0.204 (-5.50) | |
| XAUUSD C0 limit off | -80,178.45 | 0.85 | 84.7% | 1,606 | 31.6% | -166.0 | -0.103 (-2.91) | |

- **Gate A fails on both symbols** (every year negative), and so does the out-of-sample check. Closed.
- **Both sides lose.** Stops average -1.1 R and targets +1.95 R, but the win rate is 29-31%, below the 33% a 2R target
  needs before costs.
- **The time limit**, the only new rule: PF 0.75 vs 0.72 with it off on EURUSD, and 0.80 vs 0.85 on XAUUSD (worse with
  the limit). Without it, wider stops and longer holds mean fewer trades (1,409 / 1,606 vs 2,133 / 2,253).
- **Checks:**
  - The 3 / 2 entries at NY 00:00:00 come from a signal on the 23:55 bar that filled when the next bar opened.
  - "Skipped by limit 0" is a logging artifact: the skip line is written only with `InpLogEveryBar` on.
  - 15 / 1 / 3 / 2 / 6 / 2 order failures.
- **Expectation check:** EURUSD PF 0.75 was below the expected 0.80-0.95. XAUUSD 0.80 was below the expected 0.90-1.05.
  The limit effect on gold was negative, against the expected +0.00 to +0.08.
- **Removed** per the leftovers rule: `mql5/NY_4H_Range_EA.mq5`, its profile and the MT5 copies (the source is in git
  at 7376af2). The 2026-09-20 port `mql5/FourHourRangeScalper.mq5` of the same strategy is removed with it (in git at
  31e5155). `NYClockSelfTest.mq5` stays as a tool.

# MACD_Cross_EA v1.45: 1% vs 2% risk per trade (pre-registration)

Date: 2026-10-11. Asked by the user: "compare 1.45 baseline with 1.45 with 2% risk".

## What the risk input changes
`InpRiskValue` scales lot size from account balance at entry. It does not change entries or exits, so the
R-multiple sequence is identical unless the EA's own guards (daily stop -4% of day-start balance, monthly stop
-12%) fire more often at 2% and block or force-close trades.

## Runs (2022-01-01 .. 2026-10-01, real ticks, 100k deposit)
- Baseline: this morning's `v145_default_20261011_092414` (1% risk), same day, so no swap-rate drift.
- `v145_risk2`: compiled defaults + `InpRiskValue=2.0`. One run.

## Pre-registered reading
1. Challenge question (decisive): `prop_mc` on the baseline R sequence at `--risk 2.0` vs 0.3/0.5/1.0.
   Rule: a live risk level is acceptable only if its FTMO pass probability is >= the 0.5% level and MC p95 DD <= 7%.
2. Sequence question: `prop_mc --bt-risk 2.0 --risk 0.3,0.5` on the 2% log. If pass probabilities are within
   1 point of the baseline, the guards did not materially change the trade sequence.
3. In-sample: net, max DD, trades, exit_reason counts (guard closes) for both logs. Reported, not a gate.

## Outcome
(filled in after the run)

## Outcome (2026-10-11, same-day runs, real ticks 2022-01-01..2026-10-01, 100k deposit)

| | 1% risk (baseline) | 2% risk |
|---|---|---|
| Net profit | 1,584,391 | 5,718,362 |
| Tester PF | 1.79 | 1.71 |
| Trades | 957 | 840 |
| Max equity DD | 29.54% | 48.3% |
| Guard closes (exit_reason daily_stop) | 0 | 31 |
| Net R (prop_mc) | +304.0 | +241.3 |
| prop_mc pass, 0.3% / 0.5% | 80.4% / 81.2% | 70.3% / 77.0% |

1. Challenge question: prop_mc on the baseline sequence at 2.0% risk = 32.3% pass (daily-loss breaches 6.9% / 5.1%,
   max-loss 39.4% / 34.8%, MC p95 DD 57.7%) vs 81.2% at 0.5%. FAILS the rule.
2. Sequence question: 2% log at 0.3 / 0.5 is 10.1 / 4.2 points below baseline, so the EA's own daily and monthly
   stops materially worsened the sequence (31 forced closes, 117 fewer trades, -63 R).
3. In-sample net is 3.6x higher at 2% only through compounding; max DD 48% vs 29%.

Verdict: risk percent is not a free lever. Keep 1% on the demo accounts; 0.3-0.5% for a challenge account.

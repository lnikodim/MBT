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

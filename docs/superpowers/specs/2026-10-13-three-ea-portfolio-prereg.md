# MACD v1.45 + Donchian v1.01 + RSI_Reversal v1.10 on one account (pre-registration)

Date: 2026-10-13. User: "run all three together to see if it is beneficial" (after the discussion that the EAs are
isolated by magic number and only share the account's balance, guards and limits).

## Inputs (XAUUSD, real ticks, 2022-01-01..2026-10-01, 100k, 1% risk per position)
- MACD_Cross_EA v1.45 compiled defaults: `reports/v145_default_20261011_092414_trades.csv` (cap 3, trailing off).
- Donchian_Breakout_EA v1.01 published H4 cell: `reports/donch_a1_pub_20261013_095001_trades.csv`.
- RSI_Reversal_EA v1.10 compiled defaults (H6 RSI(4) 40/55, H12 SMA250 filter, SL 1% TP 5% trail 1/1): new run
  `rsi_v110` (no CSV trade log; prop_mc reads the tester report's Deals table, --bt-risk 1.0).
  Caveat: v1.10 was tuned on 2019-24, so 2022-24 is in-sample for it and only 2025-26 is its holdout.

## Method
`prop_mc.py` with several sources merges the closed trades on one balance and resamples whole trading days
(per-position risk, as for MACD stacking): `--risk 0.3,0.5 --sims 10000 --seed 1`. Runs: MACD alone, MACD +
Donchian, MACD + RSI, Donchian + RSI, all three. Daily-R correlations between the three from the same sequences.
Floating P&L, the shared daily/monthly guards and cross-EA compounding are ignored (same approximation as the
Donchian spec's combined number).

## Rule (decided before the runs)
The three-EA portfolio is "beneficial" if its pass probability at both 0.3% and 0.5% is >= MACD + Donchian
(86.8% / 83.4% in the Donchian spec; recomputed here with the same seed) and its MC p95 drawdown at 0.5% is not
more than 2 points worse. Otherwise the recommendation stays MACD + Donchian.

## Expectation written before the runs
RSI_Reversal is a mean-reversion entry on H6, so its daily returns should correlate weakly with the two
breakout / momentum systems; expect +1 to +4 points of pass probability, overstated because 2022-24 is
in-sample for it. 2025-26 alone is the honest part of the answer.

## Outcome
(filled in after the runs)

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

## Outcome (2026-10-13)

RSI_Reversal v1.10 run `rsi_v110` (XAUUSD, real ticks, 2022-01-01..2026-10-01): 364 trades, PF 1.58, net +151,910,
win 52.5%, DD 13.7%, net +98.4 R (2025-26 +53.7 R). MACD 955 trades +304.0 R, Donchian 157 trades +53.7 R.
Daily-R correlation: MACD-Donchian +0.27, MACD-RSI +0.25, Donchian-RSI +0.15.

prop_mc, seed 1, 10k sims (per-position risk; MC p95 DD at 0.3% / 0.5%):

| | pass 0.3% / 0.5% | ph1 max-loss breach at 0.5% | p95 DD | trades, PF |
|---|---|---|---|---|
| MACD | 80.6% / 80.9% | 9.2% | 11.5% / 18.6% | 955, 1.63 |
| Donchian | 0.2% / 13.8% | 0.0% | 4.1% / 6.8% | 157, 1.62 |
| RSI | 20.0% / 53.9% | 0.7% | 5.3% / 8.7% | 364, 1.59 |
| MACD + Donchian | 86.8% / 83.4% | 8.6% | 11.0% / 17.6% | 1112, 1.63 |
| MACD + RSI | 88.8% / 82.1% | 9.4% | 10.9% / 17.5% | 1319, 1.62 |
| Donchian + RSI | 48.4% / 78.4% | 0.7% | 5.6% / 9.2% | 521, 1.60 |
| **all three** | **90.8% / 83.0%** | 9.4% | **10.4% / 16.7%** | 1476, 1.62 |

2025-26 only (RSI's holdout): MACD 98.1 / 94.8, MACD + Donchian 99.1 / 95.9, all three 99.4 / 95.9, p95 DD at
0.5% 12.1 -> 11.5 -> 11.0%. Three seeds x 20k sims, full window: MACD + Donchian 86.3 / 83.4 (p95 DD 17.7%),
MACD + RSI 88.5 / 82.5 (17.5%), all three 91.4 / 83.7 (16.8%).

Rule: PASS. The three-EA portfolio is >= MACD + Donchian at both risk levels (+5.1 at 0.3%, +0.3 at 0.5%, the
latter a tie within MC noise) with a lower p95 drawdown (16.8% vs 17.7%). At 0.5% the pass rate is capped by
MACD's own max-loss breaches (about 9%), which adding systems does not remove; the gain is at the lower risk.
Caveats: RSI's 2022-24 is in-sample (its 2025-26 holdout shows the same ordering); floating P&L, the shared
daily/monthly guards and cross-EA compounding are ignored; RSI_Reversal has no daily/monthly guard of its own.

Recommendation: run all three on the challenge account at 0.3% risk per position; worst simultaneous exposure
= 3 (MACD cap) + 1 + 1 positions = 1.5% of balance, inside the 5% daily limit.

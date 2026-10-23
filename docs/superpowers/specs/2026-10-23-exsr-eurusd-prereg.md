# EXSR_EA on Darwinex EURUSD M15 / H1 (pre-registration)

Date: 2026-10-23. User: "let's test this EA: https://www.mql5.com/en/code/60413". Server: Darwinex-Demo.

**The EA:** "EXSR - Extreme Strength Reversal" v1.0 (mql5.com code 60413, Le Trung Kien Hoang), `EXSR_42g.mq5`,
208 lines, MD5 8674aace…. This is the version re-published after forum comment #1 (bar check by `iTime`). It is copied
unchanged to `mql5/EXSR_EA.mq5`, renamed per the naming convention. No DLL, web or file calls. The author claims no
results and names no symbol or timeframe.

**What the code does** (chart timeframe, once per new bar, one position per symbol):
- **Buy:** RSI(14) < 20, the bar's low below the lower Bollinger band (20, 2), and the bar closed up.
- **Sell:** RSI(14) > 80, the bar's high above the upper band, and the bar closed down.
- **Entry:** market order on the new bar.
- **Exits:** stop `StopLoss_pips` 150 and target `TakeProfit_pips` 300, both in **points** (15 / 30 pips on
  EURUSD).
- **Size:** `Risk_Percent` 1% of equity on the stop.
- **One-bar lag:** the series buffers are read at index [1] after copying from bar 1, so the checked bar is the one
  **before** the last closed bar, not the "previous candle" of the description. Kept as published.
- **Other:** `PositionSelect(_Symbol)` counts any position on the symbol, not only its own (no effect in a single-EA
  test).

**Symbol and timeframes:**
- **EURUSD:** the 15 / 30-pip stop and target fit FX. On gold, 150 points is $1.50, below its real-tick spread, so gold
  is out. Darwinex real ticks cover EURUSD 2019-2026 at 99-100%.
- **Timeframes:** M15 and H1, both fixed here and not searched.

## Runs (`reports/exsr/exsr_eval.py`; Darwinex-Demo, real ticks, 100k USD, 1:100, source defaults = 1% risk)
- **S0, 2022-01-01..2026-10-01:** M15 and H1.
- **S1, out of sample, 2019-01-01..2022-01-01:** only for a timeframe that passes Gate A on S0.

**R per trade** = net / (stop distance x volume x value per point), with the stop from the Orders table (parser of
`reports/crabel/crabel_eval.py`).

## Checks
- **Gate A (S0, per timeframe):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = a timeframe passing both. Anything else closes the EA. No input search.
- **Reported:** net USD (at 1% risk) and net R, PF, max DD, trades, win rate, mean R (t), R by year, long and short
  split, exits, history quality.

## Expectation (written before the runs)
- **Edge before costs:** about none. Costs are about 1 pip round trip, 0.07 R on a 15-pip stop.
- **PF:** 0.85-1.00 on both timeframes.
- **Trades:** M15 has enough (several hundred); H1 is close to the 150 floor.
- **Most likely verdict:** closed.

## Outcome (2026-10-23; log `reports/exsr/base.log`): closed
| run (100k, 1% risk) | net USD | PF | max DD | trades | win | net R | mean R (t) | R by year |
|---|---|---|---|---|---|---|---|---|
| M15 S0 2022-26, hq 100% | -23,958.09 | 0.53 | 30.0% | 74 | 23.0% | -26.8 | -0.362 (-2.44) | 22 -7.9, 23 -10.7, 24 -5.5, 25 -4.5, 26 +1.8 |
| H1 S0 2022-26, hq 100% | +2,043.49 | 1.12 | 6.8% | 26 | 38.5% | +2.3 | +0.089 (+0.30) | 22 -1.6, 23 +1.9, 24 -1.3, 25 +4.8, 26 -1.5 |

- **Gate A fails on both timeframes:** 74 and 26 trades against the 150 floor; M15 also loses in both regimes, and H1
  is negative in 2022-24. No out-of-sample run. Closed.
- **The three conditions together are rare:** RSI beyond 20 / 80, a band pierce and a reversal candle on the same
  bar. M15 shorts lose most: 35 trades, PF 0.31, -21.8 R.
- **Expectation check:** PF was outside the expected 0.85-1.00 (0.53 and 1.12). M15 had far fewer trades than the
  expected several hundred.
- **Removed** per the leftovers rule: `mql5/EXSR_EA.mq5`, its profile and the MT5 copies (the source is in git at
  49248f5).

# MACD_Cross_EA on Darwinex forex pairs, M5 / M15 / H1 / H4 (pre-registration)

Date: 2026-10-23. User: "can we do an experiment with the MACD_Cross_EA: i want to check if it is profitable in some of
the forex pairs on the lower timeframes: 5m, 15m, 1H, 4H". Server: Darwinex-Demo.

**The EA:** `MACD_Cross_EA` v1.47 as it runs live on XAUUSD H1, with the research profile in `scripts/ea_profiles.py`:
- MACD 16/26/9 cross, H4 EMA(200) trend filter;
- stop 0.5% and target 3.75% **of price**, break-even at +0.5% (lock +0.1%), trailing off;
- up to 3 positions in the same direction;
- 1% risk, daily stop 4%, monthly 12%, throttle off (research values).

The only change per run is the signal timeframe (`InpTimeframe`) and the chart symbol and timeframe.

**This tests whether the EA as it is transfers to forex.** Its stop and target are % of price and were tuned on gold.
On EURUSD, 0.5% is about 55 pips and 3.75% about 410 pips, a target that is wide for M5 / M15. A volatility-scaled
version is a separate question with its own pre-registration, and only if the user asks for it.

## Step 1: real-tick coverage probe (not evidence)
Candidates: EURUSD, GBPUSD, USDJPY, USDCHF, USDCAD, AUDUSD, NZDUSD, EURJPY, GBPJPY, EURGBP.
- **Probe:** H1, real ticks, 2019-03-04..2019-03-16 and 2022-03-07..2022-03-19. Only the history quality is used.
- **Eligible:** history quality >= 90% in both windows.
- **Grid:** the eligible pairs, at most 6. If more qualify, the first 6 in the list above (majors first) are used.

## Step 2: grid (`reports/macdfx/macdfx_eval.py grid`; real ticks, 2022-01-01..2026-10-01, 100k USD, 1:100)
Each eligible pair x {M5, M15, H1, H4}. R per trade comes from the EA's own trade log (`r_multiple`).

## Step 3: out of sample (`... oos`; 2019-01-01..2022-01-01), only for cells that pass Gate A

## Checks
- **Gate A (per cell, 2022-26):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (2019-21):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = a cell passing both. No input search.
- **Multiple testing:** with N cells, about 0.05 x N cells could pass a single check by luck. That is why the
  out-of-sample check is required.
- **Reported per cell:** net USD (at 1%) and net R, PF, max DD, trades, win rate, mean R (t), R 2022-24 / 2025-26,
  history quality.

## Expectation (written before the runs)
- **Most cells:** PF 0.80-1.00. The gold-tuned % stop and target don't fit forex volatility, especially on M5 / M15.
- **Best chance:** H4 (and H1) on trending pairs (JPY crosses), where the wide target fits better.
- **Most likely verdict:** no candidate.

## Amendment 1 (2026-10-23, after the EURUSD M5 and M15 cells; no other cell seen)
- **User:** "skip the 5 & 15min checks for the rest of the pairs". The grid becomes the 6 pairs x {H1, H4}, 12 cells.
- **Already run** (Gate A fail, reported in the outcome):
  - EURUSD M5: -52,488.50 USD, PF 0.86, -55.1 R;
  - EURUSD M15: -31,488.43 USD, PF 0.91, -22.7 R.
- **Unchanged:** the checks, the out-of-sample rule and the multiple-testing note. 14 cells in total, about 0.7
  expected to pass one check by chance.

## Amendment 2 (2026-10-23, during the grid; no XAGUSD result seen)
- **User:** "include XAGUSD 1H & 4H in the checks list". Silver is added: XAGUSD H1 and H4, same settings.
- **Steps:** the same coverage probe (history quality >= 90% in 2019-03 and 2022-03), the same Gate A on 2022-26,
  and the same out-of-sample check on 2019-21 for a passing cell (`macdfx_eval.py extra XAGUSD H1,H4`).
- **Cells:** 16 in total, about 0.8 expected to pass one check by chance.

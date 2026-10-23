# MACD_ATR_EA (MACD with an ATR stop and target) on Darwinex forex / XAGUSD, H1 / H4 (pre-registration)

Date: 2026-10-23. User: "let's check it out: MACD with ATR stop and target". This follows the
2026-10-23-macd-fx-lower-tf experiment: MACD_Cross_EA's % stop and target failed on forex and silver (no candidate in
16 cells).

**The EA:** `mql5/MACD_ATR_EA.mq5` v1.48, a research copy of `MACD_Cross_EA` v1.47. The live EA is not changed.
- **What is the same:** signal, filters, sizing, guards and logging.
- **ATR mode** (`InpStopATR` > 0): stop = `InpStopATR` x ATR(14) of the signal timeframe's last closed bar; target =
  `InpTargetR` x the stop.
- **Break-even:** at `InpBreakEvenR` x the trade's own first stop (read from its stop level while it is still on the loss
  side), locking `InpBELockR` x that distance.
- **Own magic (240818), trade log and lock file names.** `InpStopATR` 0 falls back to the original % mode.

**Settings: the gold settings restated in ATR units, not fitted on forex.**
- **The gold H1 settings:** 0.5% stop, 3.75% target (7.5x the stop), break-even at 0.5% locking 0.1% (1x / 0.2x the
  stop).
- **The conversion:** gold's H1 ATR(14) is about 0.25% of price (a daily range of 1.2-1.5% / sqrt(24)), so 0.5% is
  about 2 ATR.
- **Defaults:** `InpStopATR` 2.0, `InpTargetR` 7.5, `InpBreakEvenR` 1.0, `InpBELockR` 0.2. No other values are tried.
- **Everything else:** as the MACD research profile (16/26/9, H4 EMA200 trend filter, up to 3 positions, 1% risk, daily
  stop 4%, throttle off).

## Runs (`reports/macdatr/macdatr_eval.py`; Darwinex-Demo, real ticks, 100k USD, 1:100)
1. **Sanity check (report only):** XAUUSD H1, 2022-01..2026-10, ATR mode vs the live EA's validated % run
   (`macdtf_h1_20261019_210429`). The ATR version should trade the same signals with similar results. A large gap is
   reported and does not stop the grid.
2. **Grid, 2022-01-01..2026-10-01:** EURUSD, GBPUSD, USDJPY, USDCHF, USDCAD, AUDUSD, XAGUSD x {H1, H4}, 14 cells. All
   have 100% real-tick coverage (probe of the earlier experiment).
3. **Out of sample, 2019-01-01..2022-01-01:** only for cells that pass Gate A.

R per trade comes from the EA's trade log (`r_multiple`).

## Checks
- **Gate A (per cell, 2022-26):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (2019-21):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = a cell passing both. No input search.
- **Multiple testing:** 14 cells, so about 0.7 could pass one check by chance; the out-of-sample check is required.
- **Reported per cell:** net USD (at 1%) and net R, PF, max DD, trades, mean R (t), R 2022-24 / 2025-26, history
  quality. The cells are compared with the % version where both exist (same symbol and timeframe).

## Expectation (written before the runs)
- **The ATR stop** removes the scale mismatch, so losses per trade fit each market. The edge still has to come from the
  MACD cross with the H4 trend filter.
- **A 7.5R target** is rarely hit on forex. Most exits will be stops or break-even, so PF depends on a few long trends.
- **Expected:** most cells PF 0.85-1.05. H4 on the JPY pair, and XAGUSD, are the best chances.
- **Most likely verdict:** no candidate, or one cell that is weak out of sample.

## Outcome (2026-10-23; log `reports/macdatr/run.log`): closed, the user stopped the grid after 7 of 14 cells
**Sanity check, XAUUSD H1 2022-26:** ATR version 949 trades, +217.6 R (PF 1.45 in R, t 3.05, +456,044.07 USD at 1%
compounding). The live % version had 955 trades and +332.4 R. Same signals; the "0.5% = 2 ATR" conversion is
approximate, so the result is weaker.

| cell (real ticks 2022-01..2026-10, 1%) | trades | PF (R) | net USD | max DD | net R (t) | R 2022-24 / 2025-26 | Gate A | % version (same cell) |
|---|---|---|---|---|---|---|---|---|
| EURUSD H1 | 1,043 | 0.89 | -59,041.39 | 76.5% | -64.8 (-1.04) | -17.3 / -47.5 | fail | -57,984 USD |
| EURUSD H4 | 239 | 0.58 | -36,325.44 | 50.8% | -49.5 (-2.23) | -21.6 / -27.9 | fail | -33,956 USD |
| GBPUSD H1 | 1,023 | 0.94 | -42,022.36 | 68.0% | -32.1 (-0.51) | +8.1 / -40.2 | fail | +36,591 USD |
| GBPUSD H4 | 208 | 0.96 | -7,448.99 | 29.5% | -4.3 (-0.16) | +10.8 / -15.1 | fail | -5,459 USD |
| USDJPY H1 | 992 | 1.29 | +182,509.61 | 53.2% | +148.9 (+2.12) | +198.8 / -49.9 | fail | +111,817 USD |
| **USDJPY H4** | 238 | 1.72 | **+93,479.93** | 15.0% | +73.4 (+2.11) | +66.8 / +6.5 | **PASS** | +142,005 USD (failed 2019-21) |
| USDCHF H1 | 1,032 | 0.88 | -59,277.56 | 66.4% | -71.5 (-1.14) | +8.2 / -79.6 | fail | -30,813 USD |

- **Not run, at the user's request** ("ok, skip the rest"): USDCHF H4, USDCAD, AUDUSD and XAGUSD (H1 / H4), and the
  2019-21 out-of-sample check for USDJPY H4.
- **Verdict: closed.**
  - 1 of 7 cells passes Gate A: USDJPY H4, the same cell as in the % version.
  - The % version of that cell failed 2019-21 (-13.5 R), and this one was not given the check, so it is not a
    candidate.
  - ATR scaling did not fix forex. 6 of 7 cells lose in 2025-26, and on the pairs that lost it lost about as much as
    the % version.
- **Removed** per the leftovers rule: `mql5/MACD_ATR_EA.mq5`, its profile and the MT5 copies (the source is in git at
  cf12fbd). MACD_Cross_EA (live) is unchanged.

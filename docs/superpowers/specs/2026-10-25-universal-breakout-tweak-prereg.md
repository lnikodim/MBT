# UniversalBreakout_EA tweak study: can the logic be made to hold in 2019-21? (pre-registration)

Date: 2026-10-25. User: "the universal breakout seems promising, can we try to tweak the core logic to make 2019-2021 also
profitable?" Server: Darwinex-Demo. EA: 73711 "Universal Breakout Study" (source unchanged, restored from daac1d6).

## Why this needs a protocol
- The EA is a parameter-study framework with about 25 dials, and its defaults (62 points, 0.61 and 1.0 box coefficients, a
  12-point trail, a 70-minute time exit) look fitted to recent data.
- Tuning until 2019-21 is profitable is easy and proves little: **once tuned on 2019-21, that window is in-sample.**
- So 2019-21 becomes the **training** window. The evidence for a tweak is only what it does where it was not tuned.

## What the EA does
- Builds a box from the last `TotalBarBox` (48) H1 candles starting at the box start hour (00:00 GMT, offset +3), then places
  a buy stop above and a sell stop below it.
- **Stop** 0.61 x box, **target** 1.0 x box. A trailing stop (12 points, from +10), a **time exit** after 70 minutes
  and Tuesday-Friday trading are on. Risk is 1% per trade.
- **Baseline on 2019-21 (known):** -5,259.16 USD, PF 0.65, 135 trades, DD 68.4%, 2019 -5,196 (max lot 2.94).
- **Baseline on 2022-26 (known):** +12,891.81 USD, PF 1.26, 641 trades, DD 39.3%, 2025 about flat.

## Variants (EURUSD H1, real ticks, 10,000 USD, 1:100, one change each from the source defaults)
Each variant changes one mechanism, chosen before looking at any result:
| id | change | mechanism tested |
|---|---|---|
| v1 | `OnTraillingStop` = 0 | a 12-point (1.2 pip) trail cuts winners |
| v2 | `Close_Type` = 0 | the 70-minute exit cuts winners |
| v3 | trail and time exit both off | v1 and v2 together |
| v4 | `k_StopLoss` = 1.0 | the 0.61 x box stop is too tight |
| v5 | `TotalBarBox` = 24 | a 48-bar box is too wide |
| v6 | `TotalBarBox` = 72 | a wider box filters false breaks |
| v7 | `Shift` = 50 points | entries beyond the box edge avoid wicks |
| v8 | `TakeProfit_Type` = 0 | the 1.0 x box target caps the trend |
| v9 | `Monday` = enabled | the Monday exclusion is an artifact |
- **Multiple testing:** 9 variants (v0 = the known baseline), and each variant looks at the same 2019-21 window, so the best
  one is selected on noise as well as signal. This is the reason for the validation below.

## Selection (training window 2019-01-01..2022-01-01)
- **Selected** = the variant with the highest training PF, provided PF >= 1.05 and net > 0. If none qualifies, **no tweak
  works** and the study ends there.
- **No combining** of variants beyond v3, and **no second round of tuning** after seeing the validation results.

## Validation of the selected variant (never used for selection)
1. **EURUSD 2022-01-01..2026-10-01:** PF >= 1.00 and net > 0 in both 2022-24 and 2025-26 (the Gate A shape), and it must
   not be worse than the baseline's PF 1.26 by more than a quarter.
2. **GBPUSD H1, 2019-01-01..2026-10-01** and **USDJPY H1, same window:** PF >= 1.00 and net > 0 on each, with no change to the
   inputs. These pairs were not touched in any tuning.
3. **Sizing:** drawdown at the default 1% risk is reported. The return is scaled to an 8% drawdown (k = 8 / max DD %)
   and must be >= +10% a year to count as a fit for a prop account.
- **Candidate** = all pass. Otherwise the verdict is **closed**, and the in-sample 2019-21 result is reported as such.

## Expectation (written before the runs)
- **Training:** one or two variants will clear PF 1.05 on 2019-21, since selecting the best of nine over 135 trades finds a
  profitable one by chance about as often as by merit.
- **Validation:** the selected variant will probably lose most of its edge on 2022-26 and fail on GBPUSD or USDJPY.
- **Most likely verdict:** closed. A real result would be a variant that is profitable in 2019-21 and keeps its 2022-26
  PF above about 1.15 with a small drawdown.

## Outcome (2026-10-25; log `reports/oct25/ubt_train.log`): no variant works, study ends, EA closed
Training window EURUSD H1 2019-01..2022-01, real ticks, 10,000 USD, 1% risk, history quality 99%.

| id | change | net USD | PF | max DD | trades | win | by year (2019 / 2020 / 2021) |
|---|---|---|---|---|---|---|---|
| v0 | source defaults (reproduces the earlier run to the cent) | -5,259.16 | 0.65 | 68.4% | 137 | 49.6% | -5,196 / -556 / +372 |
| v1 | trailing stop off | -3,411.43 | 0.83 | 53.7% | 222 | 50.0% | -3,017 / -105 / -289 |
| v2 | time exit off | -4,241.96 | 0.73 | 74.2% | 62 | 75.8% | -6,288 / +282 / +1,763 |
| v3 | trailing stop and time exit off | -2,919.24 | 0.96 | 83.2% | 113 | 38.9% | -2,055 / +4,935 / -1,936 |
| v4 | stop 1.0 x box | -5,009.30 | 0.76 | 71.8% | 338 | 48.8% | -2,842 / -1,334 / -833 |
| v5 | box 24 bars | -1,059.24 | 0.94 | 31.4% | 189 | 50.3% | -2,068 / +782 / +227 |
| v6 | box 72 bars | -1,014.25 | 0.95 | 49.0% | 314 | 50.3% | -2,302 / -1,077 / +950 |
| v7 | entry 50 points beyond the box | -654.11 | 0.85 | 18.0% | 56 | 53.6% | -477 / +439 / -616 |
| v8 | no profit target | -5,259.16 | 0.65 | 68.4% | 137 | 49.6% | identical to v0 |
| v9 | Monday enabled | -6,105.22 | 0.64 | 73.4% | 157 | 45.2% | -4,280 / -2,208 / +273 |

- **Selected: none.** No variant reaches PF 1.05 with net > 0. The validation (EURUSD 2022-26, GBPUSD, USDJPY) was therefore
  never run, as pre-registered, and there was no second round of tuning.
- **Findings:**
  - **2019 loses in every variant** (-477 to -6,288). The loss is not a parameter setting.
  - **The profit target is inert:** 0 of the baseline's 137 trades reach it (70 stop out, the rest leave via the
    trail or the time exit), so v8 is identical to v0.
  - **The best variants (v5, v6, v7) are closest to break-even, at PF 0.85-0.95.** They are still losing.
  - **v3 is the most erratic:** PF 0.96, but 2020 +4,935 and 2021 -1,936, with an 83% drawdown.
- **Expectation check:** expected one or two variants to clear PF 1.05 by chance. None did. The study ended at the training
  stage, so the in-sample window never got a chance to flatter a variant.
- **Removed** per the leftovers rule: `mql5/UniversalBreakout_EA.mq5` (in git at daac1d6), its profile and the MT5 copies,
  including `CBoxSession.mqh`.

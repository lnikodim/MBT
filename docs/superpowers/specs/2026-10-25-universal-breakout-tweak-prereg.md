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

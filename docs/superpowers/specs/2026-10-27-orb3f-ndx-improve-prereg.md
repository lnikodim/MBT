# Improving NDX ORB3F as a portfolio add-on (pre-registration, 2026-10-27)

**Request:** "can we improve NDX ORB3F so that it becomes a valuable add-on for my portfolio?"
ORB3F = article 17745's ORB3 (Concretum bands breakout, M1, 4% risk) with two fixes (time-of-day gates; the 09:30 reference moved to the session open 16:30), see `2026-10-26-article17745-orb-prereg.md`.
Baseline on Darwinex NDX, real ticks, 10,000 USD: 2024-26 1,559 trades, PF 1.04, +3,422 USD, DD 42.5%; 2022-23 1,185 trades, PF 1.01, +867; 2019-21 1,639 trades, PF 1.09, +8,756 (t +0.94).
Add-on test (seven live EAs, candidate sized to 1% / 2% own drawdown): +0.38 / +0.76 %/yr, but return/DD 21.0 -> 20.8 / 20.6 and max DD +0.25 / +0.49: **rule fails**; daily rho -0.04.

## What "valuable" has to mean (the rule, from the add-on spec)
Return/DD of the combined account must not fall (it is total return over max drawdown, 21.0 for the live set), max DD must rise by at most 1.0 point, worst month must not fall by more than 1.0 point.
The candidate's own return/DD is 1.8 (+87.6% total for a 48.8% drawdown over 2022-26). Adding a low-ratio but uncorrelated component only keeps the ratio if the candidate's drawdowns do not coincide with the portfolio's, or if its own ratio is several times higher (roughly 5 or more).
So this is a demanding target for an edge with t +0.94: a parameter tweak is unlikely to buy a 3x better ratio unless it removes real waste.

## What the existing trades show (offline, the three baseline reports; no new runs)
- **The profit is a few big winners.** Each window has about 90 (58 in 2024-26) trades that end at least +3% of balance; they sum to +495%, +520% and +349% of balance, and every other trade sums to -409%, -486% and -296%. 70% of trades last under an hour and lose about 0.4-0.7% of balance each.
  The strategy is a trend-day lottery with a heavy whipsaw cost (win rate 31%, only 10, 34 and 11 trades hit the 1% stop).
- **Buys beat sells in all three windows** (mean per trade +0.097 / +0.043 / +0.044% of balance against +0.012 / +0.015 / +0.026).
- **The first hour of entries (16:xx) is the weakest** in two of three windows (-0.086, -0.009, +0.042); hours 18 and 19 are positive in two or three.
- **Not usable:** weekday (the sign flips between windows) and entry number within the day (no consistent pattern).
These diagnostics used all three windows, so there is **no untouched window**: that is the limit of this study.

## Variants (NDX M1, 2019-21, 2022-23 and 2024-26, everything else as ORB3F; fixed now, no additions after the results)
New default-off inputs in `mql5/ORB3X_EA.mq5` (identical trades with all off, checked against the baseline): `InpBandMult` (band = open x (1 +/- mult x sigma); the paper's volatility multiplier), `InpLongOnly`, `InpEntryDelayMin` (no entry in the first N minutes after the 16:30 open), `InpMaxEntries` (per day).
| id | change | why |
|---|---|---|
| x0 | none | baseline and identity check |
| x1, x2 | band multiplier 1.25, 1.5 | fewer, cleaner breakouts: the strategy's own parameter |
| x3 | long only | buys beat sells in 3 of 3 windows |
| x4 | no entry in the first 60 minutes | the first hour is weakest in 2 of 3 windows |
| x5 | at most 2 entries a day | caps the whipsaw on choppy days (weak evidence: entry number showed no pattern) |
| x6 | x3 + x1 | |
| x7 | x3 + x4 | |
| x8 | x3 + x1 + x4 | the most selective |

## Selection rule
A variant is an improvement only if, **in each of the three windows**, PF is at least the baseline's and the return per drawdown (net % of 10,000 over the equity drawdown %) is at least the baseline's, and PF is at least 1.0 in all three.
Of those, the one with the highest worst-window return per drawdown gets the add-on test (`reports/portfolio/addon_joint.py`, 2022-26 trades, 1% and 2% sizing). Success = the add-on rule passes. 9 variants x 3 windows = 27 runs, so one improving by chance is possible; the all-windows rule is the guard.
A winner then gets a weak fresh check on 2016-2018 (modelled ticks before 2019; hq reported).

## Expectation (written before the runs)
Long-only and the band multiplier remove trades that on average earn little, so PF may rise by 0.03-0.10 in each window; the delay may help or be neutral. I expect the best variant to reach PF 1.1-1.2 and a return/DD of about 3-5, and the add-on rule to pass **in fewer than one case in three**.
If nothing passes, the honest result is that the edge is too thin to carry the portfolio's risk standards, and it is closed.

## Result of the nine variants (2026-10-27; log `reports/oct25/orb3x.log`)
Baseline x0 reproduced the earlier ORB3F numbers exactly. Per window (2019-21 / 2022-23 / 2024-26), PF and return per drawdown (net % over drawdown %):
| id | PF | return/DD | improvement rule |
|---|---|---|---|
| x0 baseline | 1.09 / 1.01 / 1.04 | +2.60 / +0.21 / +0.81 | the bar |
| x1 band 1.25 | 1.09 / 1.02 / 1.07 | +2.10 / +0.31 / +1.31 | no (2019-21) |
| x2 band 1.5 | 1.18 / 0.97 / 1.10 | +5.37 / -0.40 / +2.51 | no (2022-23 negative) |
| x3 long only | 1.21 / 1.04 / 1.05 | +3.85 / +0.52 / +0.59 | no (2024-26 return/DD) |
| x4 no first hour | 1.22 / 1.08 / 0.98 | +8.11 / +1.33 / -0.22 | no (2024-26 negative) |
| x5 max 2 entries | 0.94 / 1.08 / 1.07 | -0.65 / +2.00 / +1.17 | no (2019-21 negative) |
| x6 long + band 1.25 | 1.22 / 1.05 / 1.09 | +4.00 / +0.59 / +1.23 | **yes** (add-on fails: return/DD 20.7-20.8) |
| x7 long + no first hour | 1.29 / 1.23 / 1.02 | +3.44 / +2.19 / +0.20 | no (2024-26) |
| **x8 long + band 1.25 + no first hour** | **1.23 / 1.21 / 1.22** | **+3.14 / +1.12 / +2.67** | **yes** (drawdown 14.6% / 28.6% / 16.7%, 330 / 239 / 340 trades, t +1.27 / +0.99 / +0.81) |
**Selected: x8** (highest worst-window return/DD, 1.12 against 0.59 for x6). **Add-on test** (seven live EAs, candidate sized to 1% / 2% own drawdown; 579 trades over 2022-26, +79.6% at 4% risk, own max DD 28.2%, daily rho -0.02):
+0.60 / +1.19 %/yr, max DD +0.06 / +0.12, worst month -10.55 / -10.66, return/DD 21.1 / 21.2 against 21.0: **rule passes at both sizes**.

## Amendment 1 (before any further run): plateau and fresh-window checks on x8
Because x8 was chosen from 9 variants on windows the diagnostics had seen, two checks decide whether it is a real setting or a lucky one:
1. **Neighbours** (all three windows each): band multiplier 1.15 and 1.35, entry delay 30 and 90 minutes, the other two settings as in x8 (12 runs). A neighbour counts as supporting if PF is at least 1.1 in every window; x8 is called a plateau if at least three of the four support.
2. **Fresh window 2016-01..2018-12** for x8 and for the baseline x0 (modelled ticks before 2019; history quality reported): x8 must have PF >= 1.0 and net > 0, and beat the baseline's PF.
If both hold, x8 is a candidate for a deployment test; if either fails, it is closed as a fit.

## Outcome of the amendment-1 checks (2026-10-27; log `reports/oct25/orb3y.log`): x8 passes both; candidate for a deployment test
**Fresh window 2016-01..2018-12** (hq 31%: NDX ticks start in 2019, the rest is modelled): baseline x0 555 trades, PF 0.91, -3,125 USD, DD 47.4%; **x8 105 trades, PF 1.20, +1,646 USD, DD 16.2%**, return/DD +1.02, t +0.62. Rule met (PF >= 1.0, net > 0, beats the baseline's PF).
**Neighbours of x8** (long only throughout; per window 2019-21 / 2022-23 / 2024-26):
| neighbour | PF | drawdown | supports (PF >= 1.1 in every window) |
|---|---|---|---|
| band 1.15, delay 60 | 1.35 / 1.20 / 1.16 | 19.7 / 24.1 / 20.8% | yes |
| band 1.35, delay 60 | 1.16 / 1.18 / 1.14 | 18.0 / 27.8 / 24.4% | yes |
| band 1.25, delay 30 | 1.17 / 1.07 / 1.14 | 21.1 / 27.8 / 17.7% | no (2022-23 1.07; still above the baseline's 1.01) |
| band 1.25, delay 90 | 1.32 / 1.17 / 1.20 | 14.3 / 20.7 / 18.1% | yes |
3 of 4 support: **plateau**. Every neighbour has PF above the baseline in every window and a positive net.
**Verdict:** x8 (long only, band multiplier 1.25, no entry in the first 60 minutes of the New York session) is the first improved cell to pass the add-on rule and the two checks. It is a candidate for a deployment test, not a deployed EA: it is the article's bare code with three switches and the two fixes (no daily stop, throttle, EA-inputs guide or logging), its licence is "all rights reserved by MetaQuotes" (the article invites readers to build on the code), and it has run only on Darwinex-Demo.
**Standing caveats:** chosen from 9 variants on windows the diagnostics had seen; t +0.8 to +1.3 per window; the fresh window has 105 trades and mostly modelled ticks; the add-on gain is small (+0.6 to +1.2 %/yr at 1-2% own-drawdown allocation) and the conclusion is in-sample against the tuned live set.
**Left in place (not a leftover while it is a candidate):** `mql5/ORB3X_EA.mq5` (untracked), its `scripts/ea_profiles.py` entry, the MT5 copies. Remove them if the user drops it.

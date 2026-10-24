# Stormbreaker_ADX_EA on Darwinex XAGUSD H4 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/77718". Server: Darwinex-Demo.

**The EA:** "Stormbreaker ADX - Supertrend and DMI Trend EA" v1.10 (mql5.com code 77718, Francesc Jordi Mallol Nolden,
published 2026-09-26, updated 2026-09-28), `Stormbreaker ADX.mq5`, MD5 4c606a17…. The ZIP holds the same file plus an
.ex5.
- **Copied unchanged to:** `mql5/Stormbreaker_ADX_EA.mq5` (renamed per the naming convention).
- **Safety:** no DLL, web or file calls. It prints only on failed or skipped orders (at most once per H4 bar).

**The author's claim:** XAGUSD H4, 2017-2026, three brokers' tester reports, all with low real-tick quality.

| broker | deposit | net | PF | equity DD | trades | real ticks |
|---|---|---|---|---|---|---|
| IC Markets | 1,000,000 | +15.45% | 1.12 | 19.40% | 520 | 32% |
| BlackBull | 1,000,000 | +22.58% | 1.45 | 5.00% | 196 | 41% |
| Fusion | 100,000 | +26.68% | 1.26 | 8.97% | 374 | 4% |

That is about 1.6-2.9% a year at 0.5% risk.

**What the code does** (once per new H4 bar, on the last closed bar):
- **Supertrend:** ATR 10, factor 3, computed inside the EA.
- **Buy:** Supertrend bullish, ADX(14) >= 23 and +DI > -DI. **Sell:** the mirror image.
- **Signals are states, not crosses:**
  - With no position, any bar meeting the conditions opens one, so it re-enters after a stop while the trend holds.
  - An opposite signal closes the position and reverses it.
- **Exit:** ADX < 18 or a Supertrend flip against the position, checked on bars without an entry signal; or the stop.
- **Stop:** 2 x ATR(10) from the signal bar's close. No target.
- **Size:** 0.5% of equity on the stop (a constant, not an input). It is capped by 95% of free margin.

## Runs (`reports/storm/storm_eval.py`; Darwinex-Demo, XAGUSD H4, real ticks, 100k USD, 1:100, source defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.
3. **Neighbours on S0:** only if S0 and S1 pass. SupertrendFactor 2.5 / 3.5 and EntryADX 20 / 26, one at a time.

**R per trade** = net / (stop distance x volume x value per point), with the stop from the Orders table (parser of
`reports/crabel/crabel_eval.py`; one position at a time).

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Plateau:** all 4 neighbours have PF >= 1.00 on S0.
- **Candidate** = all pass. No other input search.
- **Reported:** net USD (at 0.5%) and net R, PF, max DD, trades, win rate, mean R (t), R by year, long and short split,
  exits.

## Expectation (written before the runs)
- **The setup:** a classic H4 trend follower with no target, so a low win rate and a few large winners.
- **The market:** silver rose strongly in 2024-26, which helps the longs; 2022-23 was choppier.
- **Trades:** about 40-60 a year, so about 200-280 in S0.
- **PF:** 1.00-1.25 in R. The author's own PF is 1.12-1.45 on low-quality ticks.
- **Most likely verdict:** borderline. Gate A may fail on 2022-24; if it passes, the out-of-sample check is the main
  risk.

## Outcome (2026-10-24; log `reports/storm/base.log`): closed (out-of-sample check fails)
| run (XAGUSD H4, real ticks, 100k, 0.5% of equity) | net USD | PF | max DD | trades | win | net R (t) | R by year | exits |
|---|---|---|---|---|---|---|---|---|
| S0 2022-01..2026-10, hq 100% | **+25,449.51** | 1.38 (R 1.37) | 7.1% | 265 | 37.7% | **+46.7** (+1.75) | 22 +4.5, 23 +8.5, 24 +15.4, 25 +16.9, 26 +1.4 | stop 99 at -1.01 R, signal 166 at +0.89 R |
| S1 2019-01..2022-01, hq 99% | +2,933.08 | 1.07 (R 1.09) | 9.8% | 157 | 36.3% | +7.2 (+0.34) | 19 -13.9, 20 +17.1, 21 +3.9 | stop 68 at -1.02 R, signal 89 at +0.86 R |

- **Gate A passes:** 265 trades, PF 1.38, 2022-24 +28.4 R, 2025-26 +18.3 R. Every year 2022-26 is positive.
  - Longs: +30.9 R (PF 1.42).
  - Shorts: +15.8 R (PF 1.29).
- **The out-of-sample check fails on t:**
  - Net (+2,933.08) and PF (1.07) pass; t is +0.34 against the required 1.65.
  - 2019 lost 13.9 R, and the 2019-21 longs lost 1.6 R.
  - Pooled 2019-26: about +53.9 R over 422 trades, mean about +0.13 R, t about 1.6, still below 1.65.
- **Verdict: closed per the pre-registration.** It is a near-miss, not a clear failure: a positive trend-following
  result in all periods, too weak to separate from noise. No neighbour runs (they were conditional on passing the
  out-of-sample check).
- **Expectation check:**
  - PF 1.37 in R, above the expected 1.00-1.25.
  - 265 trades, as expected.
  - Gate A passed; the out-of-sample check was the deciding risk, as expected.
- **Removed** per the leftovers rule: `mql5/Stormbreaker_ADX_EA.mq5`, its profile and the MT5 copies (the source is in
  git at 6e9a669 and can be restored if the user wants it as a research item).

## Amendment 1 (2026-10-24, after the XAGUSD outcome): XAUUSD H4
- **User:** "restore Stormbreaker and test it on XAUUSD H4". The source is restored unchanged from 6e9a669 (MD5
  4c606a17…) and compiles with 0 errors and 0 warnings. The profile is restored.
- **Runs** (`reports/storm/storm_eval.py base XAUUSD`): same as above on XAUUSD H4, real ticks, 100k, 0.5% of equity.
  - S0 2022-26;
  - S1 2019-21 only if S0 passes;
  - the four neighbours only if S1 passes.
- **Checks:** unchanged (Gate A, the out-of-sample check, the plateau).
- **Multiple testing:** this is the EA's second symbol, picked after seeing the first. A pass here is one of two tries,
  so the out-of-sample check and the plateau both stay required.
- **Portfolio note:** the live set already holds four gold EAs (MACD H1, Donchian_Breakout H4, RSI H6, MA_Channel H1). A
  candidate here would need a joint simulation for correlation before any live use.
- **Expectation, written now:**
  - Gold trended strongly in 2022-26, most of all in 2024-26; MACD_Cross on XAUUSD H1 made +332 R there. So Gate A
    likely passes, with PF 1.2-1.5 in R and about 200-300 trades.
  - 2019-21: 2019-20 trended and 2021 was choppy; expect about PF 1.0-1.2, so the out-of-sample t is the main risk again.
  - Darwinex gold real-tick quality before 2022 is not yet known; below 90% means inconclusive.

### Amendment 1 outcome (2026-10-24; log `reports/storm/xau.log`): closed (out-of-sample check fails)
| run (XAUUSD H4, real ticks, 100k, 0.5% of equity) | net USD | PF | max DD | trades | win | net R (t) | R by year | exits |
|---|---|---|---|---|---|---|---|---|
| S0 2022-01..2026-10, hq 100% | **+24,762.76** | 1.35 (R 1.35) | 9.9% | 273 | 35.2% | **+48.7** (+1.59) | 22 -2.9, 23 +10.7, 24 +9.6, 25 +13.0, 26 +18.3 | stop 106 at -1.01 R, signal 167 at +0.94 R |
| S1 2019-01..2022-01, hq 99% | **-3,848.26** | 0.93 (R 0.94) | 10.7% | 191 | 29.8% | **-6.7** (-0.26) | 19 -12.4, 20 +8.1, 21 -2.4 | stop 87 at -1.04 R, signal 104 at +0.81 R |

- **Gate A passes:** 273 trades, PF 1.35, 2022-24 +17.4 R, 2025-26 +31.4 R.
  - Longs: +56.6 R (PF 1.87).
  - Shorts: -7.8 R (PF 0.89).
- **The out-of-sample check fails outright:** net -3,848.26 USD, PF 0.93, t -0.26. 2019 lost 12.4 R; only 2020 (a
  strong gold trend) was positive. No neighbour runs.
- **Both symbols together:**
  - The 2022-26 edge (+46.7 R silver, +48.7 R gold) comes from the 2023-26 metals trend.
  - Before it, the same rules give +7.2 R (silver) and -6.7 R (gold) in 2019-21.
  - So the setup follows a strong trend when there is one, and does not show an edge across regimes.
- **Expectation check:**
  - Gate A passed with PF 1.35, inside the expected 1.2-1.5.
  - 273 trades, inside the expected 200-300.
  - 2019-21 came out below the expected PF 1.0-1.2.
- **Removed again** per the leftovers rule: `mql5/Stormbreaker_ADX_EA.mq5`, its profile and the MT5 copies (the source
  is in git at 6e9a669 / 7584688).

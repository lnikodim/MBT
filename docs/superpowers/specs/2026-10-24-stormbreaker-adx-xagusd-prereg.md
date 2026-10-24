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

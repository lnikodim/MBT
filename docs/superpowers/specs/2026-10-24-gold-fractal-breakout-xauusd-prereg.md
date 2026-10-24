# Gold_Fractal_Breakout_EA on Darwinex XAUUSD (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/78308". Server: Darwinex-Demo.

**The EA:** "Gold MT5 Fractal Breakout EA" v1.00 (mql5.com code 78308, pckr / Rbot.cc "GoldX9 strategy 9", published
2026-10-12, updated 2026-10-13), `Gold_Fractal_Breakout_EA.mq5`, 631 lines, MD5 961a5212….
- **Copied unchanged** under the same name.
- **Safety:** no DLL, web or file calls. It prints on each pending order placed or cancelled, on margin skips, and on
  rejected modifications (rate-limited to once per 5 s), so not per tick.

**The author's claim:** none. The page says outright that no backtest or forward test is supplied.

**What the code does:**
- **Swings:** every 15 minutes it scans H1 bars (a fixed constant) for the latest swing high and low, 5 bars on each side.
- **Orders:** a buy stop at the swing high -0.10% and a sell stop at the swing low +0.10%.
  - Up to 3 per side, kept 100 points apart.
  - Placed only while the price is more than 0.02% away from the swing.
  - Good till cancelled.
- **One position at a time** on the symbol. The other pending orders are deleted after a fill.
- **Exits** (as % of price): stop 2.00%, target 1.00%.
  - **Break-even:** at +0.10% gain, the stop moves to +0.025%.
  - **Trailing:** from +0.20% to +1.00% gain, a stop 0.20% behind the price.
  - **Salvage:** once the loss reaches 1.00%, the target moves to -0.15%.
- **Size:** fixed 0.01 lot (the risk-% mode is off by default).

## Runs (`reports/oct24/q_eval.py gfb`; Darwinex-Demo, XAUUSD H1 chart, real ticks, 100k USD, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**R per trade:** from the Orders table stop (the 2% stop is on the order; `crabel_eval.trades`, one position at a time).

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass. No input search.

## Expectation (written before the runs)
- **Trade shape:** at 4,000 USD gold, break-even fires at about +4 USD and locks about +1 USD, while costs are
  about 0.3-0.5 USD. So many trades end at about +0.01 R, a few reach the trail or the target (+0.1 to +0.5 R), and
  losses are -1 R or about -0.08 R after a salvage.
- **Trades:** many, more than 500 in S0.
- **PF:** 0.85-1.05 in R. The breakout has no known edge, and the exits mostly cap the winners.
- **Most likely verdict:** closed.

## Outcome (2026-10-24; log `reports/oct24/gfb.log`): closed
| run (XAUUSD H1, real ticks, 100k, 0.01 lot) | net USD | PF | max DD | trades | win | net R (t) | R by year |
|---|---|---|---|---|---|---|---|
| S0 2022-01..2026-10, hq 100% | **-1,275.61** | 0.83 (R 0.80) | 1.3% | 2,061 | 85.8% | **-26.5** (-2.22) | 22 -4.7, 23 -16.0, 24 -1.3, 25 -0.7, 26 -3.8 |

- **Gate A fails:** PF 0.83; 2022-24 is -22.0 R and 2025-26 -4.5 R. Every year loses. Closed.
- **The trade shape is as expected:**
  - 85.8% of trades win, but tiny. Most close on the break-even or trailing stop, so the "stop" exits (1,914) average
    -0.02 R.
  - The 146 target exits (the 1% target and salvage exits) average +0.03 R.
  - Costs: commission and swap total -415.63 USD, about a third of the loss.
- **Sides:** longs -10.3 R, shorts -16.2 R.
- **Expectation check:** PF 0.80 in R, just below the expected 0.85-1.05. 2,061 trades, more than 500 as expected.
- **Removed** per the leftovers rule: `mql5/Gold_Fractal_Breakout_EA.mq5`, its profile and the MT5 copies (the source is
  in git at 136c6ef).

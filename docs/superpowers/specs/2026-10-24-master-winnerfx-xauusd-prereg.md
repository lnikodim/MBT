# Master_WinnerFX_EA on Darwinex XAUUSD M15 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/69712". Server: Darwinex-Demo.

**The EA:** "MASTER-WINNERFX-Asim" v3.10 (mql5.com code 69712, Muhammad Asim, published 2026-02-21, page updated
2026-09-15), `EA.mq5`, 5,380 bytes, MD5 851be75b….
- **Copied unchanged to:** `mql5/Master_WinnerFX_EA.mq5` (renamed per the naming convention).
- **Safety:** no DLL, web or file calls. No `Print`; CTrade logs only failed orders.

**The author's claim** (screenshots "15 min chart, 2023-2024", deposit 1,000):

| symbol | net | PF | equity DD | trades | won |
|---|---|---|---|---|---|
| XAUUSD | +479,495.85 | 6.99 | 33.2% | 6,504 | 88.6% |
| BTCUSD | +622,955.06 | 10.01 | 59.9% | 7,320 | 90.2% |

- **Data quality:** history quality 0% on both screenshots.
- **Identical data size:** both runs show the same 5,642 bars and 22,568 ticks, exactly 4 ticks a bar. That is not two
  years of M15 for either symbol, so both ran on a tiny or broken history with synthetic ticks.

**Comments:**
- "the draw down is huge, it needs work on the recovery trades aspect".
- Someone posted M1 .set files for gold, BTC and US30. They are not used here; the test uses source defaults.

**What the code does** (every tick, not once per bar):
- **Size:** 0.01 lot per 1,000 of balance (`LotPer1000`).
- **First trade:** opens when there is no position. Buy if bid > EMA(50, M15) and RSI(14) of the forming bar > 55. Sell
  if bid < EMA and RSI < 45.
- **Grid:** each time price moves 1,500 points (15 USD on gold) beyond the worst leg, it adds a leg at 1.2x the last
  lot. At most 3 legs per side, then no more adds.
- **Basket exits:**
  - The whole basket closes when its floating profit is >= +3 USD.
  - It also closes at <= -1,000 USD.
  - There is no stop per trade.
- **Hours:** no new legs at server hour 22 or at server hour 13 (the "news" hour; the code uses server time, not UTC).
- **Fixed money amounts:** the +3 / -1,000 thresholds do not scale with the balance, but the lot does. So the target
  shrinks in price terms as the account grows: at 10k balance it is 0.30 USD on 0.10 lot, about the gold spread.

## Runs (`reports/mwfx/mwfx_eval.py`; Darwinex-Demo, XAUUSD M15, real ticks, 1,000 USD = the author's deposit, 1:100, defaults)
0. **Probe:** 2026-09, one month. It checks trading, margin and agent log growth. It is not counted.
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

- **BTCUSD is not run:** this terminal has no Darwinex BTCUSD history.
- **Trades:** legs come from the Deals table (`scripts/blessing_eval.py` `deals_trades`); baskets are legs of one side
  closed in the same second (`baskets`).

## Gate (S0; the Blessing grid gate of 2026-10-07, since there is no stop to define R)
1. The run completes with no stop-out, and has >= 150 trades.
2. k = 8 / max equity DD %.
3. Pass if the k-scaled return is >= +10% a year in both 2022-24 and 2025-26.
4. **Out of sample (S1):** k-scaled return > 0, and t of the per-trade % return >= 1.65. If history quality is below
   90%, it is inconclusive.
5. **Candidate** = all pass. Anything else closes the EA. No retuning.

**Reported:**
- net USD (from 1,000), PF, max equity DD, worst day % of the deposit, stop-outs;
- legs, baskets won / lost, the worst basket, -1,000 basket exits;
- net by year, history quality.

## Expectation (written before the runs)
- **Costs:** on 0.01 lot the +3 USD target is a 3 USD gold move. Darwinex's real-tick gold spread (about 0.3-0.9 USD) and
  commission take 10-30% of it.
- **Risk:** 3 legs cover only 30 USD of adverse movement. After that the basket has no stop until -1,000 USD (the whole
  starting deposit) or a margin stop-out. Gold's 2024-25 rise of more than 1,500 USD makes a stuck sell basket likely.
- **Expected:** a stop-out or a max DD above 50% (k < 0.16), with a high win rate before it.
- **Most likely verdict:** closed. The author's +479k comes from 0%-quality data and cannot be compared.

## Outcome (2026-10-24; logs `reports/mwfx/probe.log`, `reports/mwfx/base.log`): closed
| run (XAUUSD M15, real ticks, 1,000 USD, defaults) | net USD | PF | max equity DD | worst day | legs | baskets won / lost | worst basket |
|---|---|---|---|---|---|---|---|
| probe 2026-09 | -670.64 | 0.14 | 69.2% | -73.9% | 33 | 24 / 2 | -738.90 |
| S0 2022-01..2026-10, hq 100% | **-858.11** | 0.41 | 89.5% | -121.2% | 169 | 134 / 5 | -1,211.52 (one -1,000 exit) |

- **Gate fails:** k = 0.09; the scaled return is -2.6%/yr in 2022-24 and 0.0 in 2025-26. Closed.
- **The account is spent in 2022:** all 169 legs and the whole -858.11 USD fall in 2022. After it, the about 142 USD
  left opens nothing more. There was no broker stop-out; the EA's own -1,000 basket exit fired once.
- **The pattern:** 134 small +3 USD baskets, then a few stuck 3-leg baskets that each take most of the account. 30 USD
  of grid depth is far below gold's swings.
- **The author's +479,495.85 USD** comes from a 0%-quality, 4-ticks-a-bar history and has no meaning on real data.
- **Expectation check:** a max DD above 50% with a high win rate (84% of legs), as expected.
- **Removed** per the leftovers rule: `mql5/Master_WinnerFX_EA.mq5`, its profile and the MT5 copies (the source is in
  git at b3d9608).

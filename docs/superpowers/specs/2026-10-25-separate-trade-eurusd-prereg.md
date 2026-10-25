# Separate_Trade_EA on Darwinex EURUSD H1 (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/21523". Server: Darwinex-Demo.

**The EA:** "Separate Trade" (mql5.com code 21523, idea by Andrey Baluev, code by barabashkakvn, published 2018-08-23,
page updated 2026-09-15), `Separate_trade.mq5` (MD5 14a8377c…, 651 lines).
- **Copied unchanged to:** `mql5/Separate_Trade_EA.mq5`.
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL, web or file calls.

**The author's claim:** none. "Optimization is required for work!"; no symbol, timeframe or results.

**What the code does** (new bar; at most one entry per side per bar):
- **Buy:** EMA(65) < EMA(14), ATR(26) < 0.0016 and StdDev(54) < 0.0051.
- **Sell:** EMA(65) > EMA(14) with the same ATR / StdDev conditions. The code uses "<" for the sell ATR / StdDev too,
  although the input comment says ">".
- **An inert filter:** the "minimum distance between MAs" compares a price difference with the raw input 2 (not 2
  pips), so it is always true.
- **Exits:** stop and target 50 pips each, trailing stop 5 pips (5-pip step).
- **Positions:** the check is `count > InpMaxPositions` (1), so up to **2** can be open.
- **Size:** 0.1 lot.

**Symbol and timeframe choice:** **EURUSD H1**. The ATR level of 0.0016 (16 pips) fits EURUSD H1, and none is given.

## Runs (`reports/oct24/sep_eval.py base`; Darwinex-Demo, EURUSD H1, real ticks, 100k USD, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**Trades:** legs from `deals_trades`, since positions can overlap. R per leg = profit / (50 pips x volume x 10 USD).

## Checks
- **Gate A (S0):** legs >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26, no stop-out.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **The setup:** a trend side from an EMA cross in low-volatility conditions, with the same exits as MA MACD averaging
  (22854, closed 2026-10-25 at PF 0.86 in R). The 5-pip trail cuts winners while losers run to -50 pips.
- **Trades:** frequent, since the EMA side is always defined and the ATR / StdDev filters pass most H1 bars.
- **PF:** 0.80-1.00 in R.
- **Most likely verdict:** closed.

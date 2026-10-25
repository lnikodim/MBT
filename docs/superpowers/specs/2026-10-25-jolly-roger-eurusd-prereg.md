# Jolly_Roger_EA on Darwinex EURUSD M5 (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/919". Server: Darwinex-Demo.

**The EA:** "Jolly Roger EA Version" v1.07 (mql5.com code 919, AM2, published 2012-07-19), `champion.mq5` (MD5
7d91a238…).
- **What it is:** AM2's imitation of Pirat's ATC-2011 EA, not the original.
- **Copied unchanged to:** `mql5/Jolly_Roger_EA.mq5`.
- **Compile:** 0 errors. The 8 warnings are benign. One says `ArraySetAsSeries` has no effect on the static RSI array;
  the code still reads bar 1, because the copy fills oldest first.
- **Safety:** no DLL, web or file calls.

**The author's claim:** "RSI only, M5, lots 5-15". The images are ATC-2011 results and tests over the 2008 / 2010 / 2011
championship periods. No numbers for today.

**What the code does** (every tick):
- **Entry:** with no position and no pending order, when RSI(14) of bar 1 < 30 it places **three buy-stop orders** at
  ask + stops level (sell-stops at bid - stops level when RSI > 70).
  - Stop 50 points and target 150 points (5 / 15 pips on EURUSD).
  - Volume of each = (free margin / 2000, between 0.1 and 15) / 3, so 5 lots each on 100k.
  - Order filling: FOK.
- **Pending orders:** pulled back to within 20 points of the price.
- **Trailing:** stops trail to max(entry + spread, price - 50 points) once in profit.
- **Darwinex risk:** its stops level is likely 0, so the buy-stop lands exactly at the ask, which is invalid for a stop
  order. If so, the EA rarely or never trades and prints the error every tick. A **probe** runs first.

## Runs (`reports/oct24/jr_eval.py`; Darwinex-Demo, EURUSD M5, real ticks, 100k USD, 1:100, defaults)
0. **Probe:** 2026-09, one month (`jr_eval.py probe`). It checks trading and log growth. It is not counted.
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**Trades:** legs from `deals_trades`, since three positions open together. R per leg = profit / (50 points x volume
x 1 USD).

## Checks
- **Gate A (S0):** legs >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26, no stop-out.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **Costs:** a 5-pip stop on M5 with 0.7 pip of costs is about -0.14 R a trade.
- **Exits:** the RSI extreme fade-and-follow has no known edge; the trailing to break-even plus spread cuts winners.
- **PF:** 0.70-0.95 in R, or no trades if the stop orders are invalid.
- **Most likely verdict:** closed.

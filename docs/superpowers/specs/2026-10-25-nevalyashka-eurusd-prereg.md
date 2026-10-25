# Nevalyashka_EA on Darwinex EURUSD (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/18841". Server: Darwinex-Demo.

**The EA:** "Nevalyashka" v1.001 (mql5.com code 18841, idea by Vladimir Khlystov, code by barabashkakvn, published
2017-11-03, page updated 2026-09-15), `Nevalyashka.mq5` (MD5 4ff2f0bf…).
- **Copied unchanged to:** `mql5/Nevalyashka_EA.mq5`.
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL, web or file calls.
- **A stale header:** its description says "Strategy based on the indicator ZigZag … pending orders", but the code uses
  neither.

**The author's claim:** "We open a new position opposite to the previous one … SL and TP should be optimized." The example
image is EURUSD H1; no numbers.

**What the code does** (every tick):
- **Always in the market:** it starts with a sell. When that position closes it opens the opposite side, and so on.
- **Exits:** stop and target 50 pips each, on the order.
- **Size:** 1 x the minimum lot (0.01).
- **The chart timeframe does not matter.**

## Runs (`reports/oct24/q_eval.py nev`; Darwinex-Demo, EURUSD H1 chart, real ticks, 100k USD, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**R per trade:** from the Orders table stop (50 pips; `crabel_eval.trades`, one position at a time).

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **The setup:** a symmetric 1:1 bet that alternates direction. With no signal its expected value is about 0 minus
  costs, about 0.7 pip a trade on a 50-pip stop, about -0.015 R.
- **Trades:** about 2-3 a day, so about 2,500-3,500 in S0.
- **PF:** about 0.95-1.00 in R.
- **Most likely verdict:** closed.

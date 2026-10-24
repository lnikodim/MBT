# RSI_Engine_EA on Darwinex EURUSD H1 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/63698". Server: Darwinex-Demo.

**The EA:** "The RSI Engine" v2.1 (mql5.com code 63698, Md Abdul Manann / spulse, published 2025-09-13, page updated
2026-09-15), `The_RSI_Engine_v2_1.mq5`, 675 lines, MD5 56559886….
- **Copied unchanged to:** `mql5/RSI_Engine_EA.mq5`.
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL, web or file calls. Prints on divergence detections (at most once per bar while flat) and on
  margin / daily-limit events.

**The author's claim:** none, and no screenshots. No symbol or timeframe is stated.
- **Source vs page:** the page lists a 500-point stop and magic 160941. The source defaults are a **300-point stop**,
  a 300-point target and magic 1901. The source defaults are used.

**What the code does** (new bar; one position, magic-only check):
- **Buy:**
  - **Trigger:** a bullish divergence (two half-windows of 30 bars; a lower price low with a higher RSI low, where the
    earlier RSI low is < 35) or RSI(14) crossing up through 30.
  - **Confirmation:** RSI crosses up through 50 on the same bar.
- **Sell:** the mirror image.
- **Exits:** stop 300 points, target 300 points.
  - The trailing stop starts only at +3,000 points, beyond the target, so it never fires.
  - The RSI-level exit is off.
- **Size:** fixed 0.1 lot.
- **Daily limits:** +10,000 / -5,000 USD, never reached at 0.1 lot.

**Symbol and timeframe choice:** **EURUSD H1**.
- The fixed 300-point stop is 30 pips there, about 2-3 H1 ranges, which suits the timeframe.
- On gold, 300 points is 3 USD, too tight for H1.

## Runs (`reports/oct24/q_eval.py rsie`; Darwinex-Demo, EURUSD H1, real ticks, 100k USD, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**R per trade:** from the Orders table stop (`crabel_eval.trades`). The stop is on the order.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass. No input search.

## Expectation (written before the runs)
- **Trades:** requiring a 50 cross on the same bar as the trigger makes trades rare, about 30-80 a year. So Gate A's
  150 trades is uncertain.
- **Edge:** a 1:1 stop and target on an RSI divergence mean-reversion signal has no known edge on EURUSD H1. Costs are
  about 0.03 R a trade.
- **PF:** 0.85-1.05 in R.
- **Most likely verdict:** closed.

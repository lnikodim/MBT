# Butterfly_Harmonic_EA on Darwinex EURUSD (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/59529". Server: Darwinex-Demo.

**The EA:** "Butterfly Strategy Expert Advisor with Multiple TimeFrames" (mql5.com code 59529, JacoMostert, published
2025-05-20, page updated 2026-09-15), `Cypher_EA.mq5` (MD5 e134d912…, 1,359 lines).
- **Copied unchanged to:** `mql5/Butterfly_Harmonic_EA.mq5`.
- **Compile:** 0 errors. The 1 warning is the deprecated `ACCOUNT_FREEMARGIN`.
- **Safety:** no DLL, web or file calls. It prints per detected pattern and per order, not per tick.

**The author's claim:** none, no results. Commenters:
- "Tried adding to EURUSD Pair 5MIN, didn't work for whole day";
- "harmonic patterns are RARE … should be waited for weeks".

**What the code does** (new bar of each enabled timeframe; by default **only M2**):
- **Pattern:** a Butterfly (XABCD) from pivots with 1 bar on each side, Fibonacci ratios within 10% tolerance, and a
  quality score >= 0.1.
- **Entry:** at market when the pattern completes, with three targets TP1 / TP2 / TP3.
- **Stop:** 3x the TP2 distance beyond the entry. It is widened to the broker minimum if needed.
- **Legs:** three positions per signal, 50 / 30 / 20% of the lot. With the fixed 0.01 lot each leg is clamped up to the
  0.01 minimum, so **3 x 0.01 lots per signal**.
- **Off by default:** break-even, trailing and the session filter.

**Symbol and timeframe:** EURUSD (none was given; a commenter tried EURUSD). Defaults, so M2 patterns only. The EA scans
its own timeframes, so the chart period (H1) does not matter.

## Runs (`reports/oct24/bfly_eval.py base`; Darwinex-Demo, EURUSD, real ticks, 100k USD, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**Unit:** a **signal** = the legs opened in the same second; its USD result at the fixed 0.01 lots is the unit. Legs
come from `deals_trades`, since they overlap.

## Checks
- **Gate A (S0):** signals >= 150, PF >= 1.00, net USD > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, t of the mean USD per signal >= 1.65. If history quality is below
  90%, it is inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **Patterns:** 1-bar pivots on M2 are noise, so "patterns" may be frequent, not rare.
- **Trade shape:** a stop 3x the TP2 distance needs a high win rate. Costs on M2-scale targets (a few pips) are large.
- **PF:** 0.70-0.95.
- **Most likely verdict:** closed.

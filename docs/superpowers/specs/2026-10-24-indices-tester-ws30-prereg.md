# Indices_Tester_EA on Darwinex WS30 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/48139". Server: Darwinex-Demo, where US30 is named WS30.

**The EA:** "Indices Testing" v1.00 (mql5.com code 48139, Igor Widiger / deinschanz, published 2024-02-11, page updated
2026-09-15), `Indices_Tester.mq5`, 290 lines, MD5 4782e5dd….
- **Copied unchanged to:** `mql5/Indices_Tester_EA.mq5`.
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL, web or file calls. It prints once per trade.

**The author's claim:**
- **The test:** "standard settings, account 10,000 dollars, leverage 100, symbol US30".
- **The screenshot:** a smooth rising balance from 2016-01 to 2023-12, no numbers.

**What the code does** (a 1-second timer):
- **Entry:** inside the symbol's trade session, buy 0.10 lot when the server time is between 01:30 and 01:35, if no
  position is open on the symbol and no deal has closed today.
- **Exit:** close at or after 23:30 server time, but only while the trade session is open. If the session ends before
  23:30, the position stays open into the next day.
- **No stop, no target, buys only.**
- **In effect:** it holds US30 long for most of each trading day and earns the index's intraday drift. That is market
  exposure, not a signal.

## Runs (`reports/oct24/idx_eval.py`; Darwinex-Demo, WS30 H1 chart, real ticks, 10,000 USD = the author's account, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**Unit:** no stop, so trades are in USD at the fixed 0.10 lot.

**Also reported:**
- holding times (how often a position is held past 23:30 or overnight);
- a **buy-and-hold benchmark:** WS30 points from the first entry to the last exit x 0.10 lot, and the EA's share of it.

## Checks (USD per trade)
- **Gate A (S0):** trades >= 150, PF >= 1.00, net > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, t of the mean USD per trade >= 1.65. If history quality is below
  90%, it is inconclusive.
- **Candidate** = both pass.
  - Even then it is long index exposure, and the outcome will say how much of the buy-and-hold move it kept.
  - Any portfolio use would need its own pre-registration against simply holding the index.

## Expectation (written before the runs)
- **The index:** US30 rose from about 36k (2022-01) to about 45k+ (2026), with a 2022 drawdown. An intraday-only long
  keeps the intraday part of that, minus spreads and the overnight gaps it skips.
- **S0:** PF about 1.0-1.1 and positive in both halves, if the index's intraday drift was positive in 2022-24 and 2025-26.
- **S1 t:** daily index returns are noisy (about 1% a day), so the out-of-sample t is likely < 1.65 even if the net is
  positive.
- **Most likely verdict:** closed on the out-of-sample t, as beta, not an edge.

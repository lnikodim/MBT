# YY_Cross_2MA_EA on Darwinex XAUUSD M1 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/48961". Server: Darwinex-Demo.

**The EA:** "YY_Cross_2_Ma" v1.22 (mql5.com code 48961, eurweb / it-yy.site, published 2025-11-23, page updated
2026-09-15), `yy_cross_ma.mq5`, MD5 f7b5fd07….
- **Copied unchanged to:** `mql5/YY_Cross_2MA_EA.mq5`.
- **Compile:** 0 errors. The 4 warnings are benign: a long-to-double conversion, a name that hides a global in
  `Object.mqh`, and the deprecated `ACCOUNT_FREEMARGIN`.
- **Safety:** no DLL, web or file calls. It prints only on failed orders and on margin refusals.

**The author's claim:** a single "unoptimised test" screenshot, 2024-01-03..2024-03-22.
- **Symbol and timeframe:** not stated.
- **Deposit:** about 1,000.
- **Balance:** rises smoothly to about 2,450, then drops to about 2,100 when the test closes the open positions.
- **Equity:** stays far below the balance (minimum about 680).
- **Margin:** deposit load up to about 25%.

**What the code does** (new chart bar):
- **Signal:** SMA(72) crossing SMA(150) on the last two closed bars. A cross up buys, a cross down sells.
- **Every cross opens a new position.** There is no position limit and no check for an existing position, and the
  opposite position is never closed.
- **Exits:** a 300-point target and **no stop** (`ext_sl_ptk = 0`). A losing position stays open until its target is
  reached or the test ends.
- **Size:** fixed 0.01 lot.

**Symbol and timeframe choice** (the author's screenshot does not say):
- **The author's rate:** about +1,450 of closed profit in about 55 trading days at 0.01 lot. That is about 480 targets
  of 3 USD each, about 9 a day.
- **Gold fits:** 300 points is 3 USD on gold, which an M1 cross reaches within minutes.
- **EURUSD does not:** 300 points is 30 pips there, too far for about 9 targets a day on M1, and M5 has too few
  crosses.
- So the test is **XAUUSD M1**. R0 below checks the choice.

## Runs (`reports/yy/yy_eval.py`; Darwinex-Demo, XAUUSD M1, real ticks, 1,000 USD, 1:100, defaults)
1. **R0, replication:** 2024-01-03..2024-03-22. Matches if the closed-trade profit before the final close-out is within
   +/-50% of +1,450 and equity runs well below the balance. A mismatch is reported, and the S0 test still runs on
   XAUUSD M1.
2. **S0, 2022-01-01..2026-10-01.**
3. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

## Gate (S0; the Blessing grid gate, since there is no stop to define R)
1. The run completes with no stop-out, and has >= 150 trades.
2. k = 8 / max equity DD %.
3. Pass if the k-scaled return is >= +10% a year in both 2022-24 and 2025-26.
4. **Out of sample (S1):** k-scaled return > 0, and t of the per-trade % return >= 1.65. If history quality is below
   90%, it is inconclusive.
5. **Candidate** = all pass.

**Reported:** net USD (from 1,000), PF, max equity DD, worst day, stop-outs, trades, the most positions open at once, net
by year.

## Expectation (written before the runs)
- **The core risk:** the EA sells on every downward cross and never stops a loser. Gold rose from about 1,800 to over
  4,000 USD in 2022-26, so the short positions build losses of hundreds to thousands of USD each at 0.01 lot.
- **Expected:** a margin stop-out of the 1,000 account in S0, probably in 2023-24.
- **Most likely verdict:** closed (stop-out).

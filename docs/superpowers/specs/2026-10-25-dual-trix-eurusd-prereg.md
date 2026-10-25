# Dual_Trix_EA on Darwinex EURUSD M5 (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/165". Server: Darwinex-Demo.

**The EA:** "Dual Trix Expert Advisor" (mql5.com code 165, FoxRex / Alf., published 2010-08-12, page updated
2026-09-15), `tootrix.mq5` (MD5 c93de3f9…), copied unchanged to `mql5/Dual_Trix_EA.mq5`.
- **Includes, installed in MT5 `Include` only:** `martingail.mqh` (MD5 2e15874e…) and `ontesterfunctions.mqh` (MD5
  8076b676…).
- **Compile:** 0 errors. The 2 warnings are unchecked `OrderSend` return values.
- **Safety:** no DLL, web or file calls. It uses one terminal global variable (`MG_2`) for the martingale counter. It
  prints nothing.

**The author's claim:** "good backtesting results for last year (EURUSD, M5)", meaning 2009-10. No numbers.

**What the code does** (first tick of each M5 bar, tick volume 1, and no position on the symbol):
- **Signals:** TriX(9, median) at a local minimum on bar 2 and rising on bar 1 → buy; the mirror → sell. Both TriX
  handles use period 9, so "fast" and "slow" are the same line.
- **Exits:** stop 500 points and target 1,500 points (50 / 150 pips on EURUSD), on the order, no other exit.
- **Size:** 0.01 lot per 1,000 of balance (0.10 lot on 10k).
- **Martingale:** **one** doubling after a loss, then back to the base lot.
- **Filling:** FOK. If Darwinex rejects FOK, the EA makes no trades (`OrderSend` is not checked).

## Runs (`reports/oct24/q_eval.py trix`; Darwinex-Demo, EURUSD M5, real ticks, 10,000 USD, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**R per trade:** from the Orders table stop (50 pips; `crabel_eval.trades`). R does not depend on the doubled lot.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26, no stop-out.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **The setup:** a TriX turn on M5 with a 50-pip stop and a 150-pip target is a long-holding trade on a fast trigger.
  Needs a win rate above about 26% before costs.
- **Trades:** a few hundred a year, holding hours to days.
- **PF:** 0.85-1.05 in R.
- **Most likely verdict:** closed.

# AMA_Trader_EA on Darwinex EURUSD M5 (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/21971". Server: Darwinex-Demo.

**The EA:** "AMA Trader" (mql5.com code 21971, idea by josef strauss, code by barabashkakvn, published 2018-10-25, page
updated 2026-09-15), `AMA_Trader.mq5` (MD5 d6d36b36…, 450 lines).
- **Copied unchanged to:** `mql5/AMA_Trader_EA.mq5`.
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL, web or file calls. It prints per order.

**The author's claim:** "EURUSD, M5", a balance chart from 2016-08 to 2018-07 on about 50,000.
- **Withdrawals:** about 10 withdrawals of 1,000 each.
- **Dips:** equity drops of up to about 3,000.
- **No numbers.**

**What the code does:**
- **Buy:** on a new M5 bar, ask > AMA(9, 2, 30) and RSI(14) < 30 on any of the last 3 bars (including the forming
  one). It buys **twice** if the open buys are in loss, otherwise once. Sell is the mirror image (bid < AMA, RSI > 70).
- **No stop and no target on any position.** Positions of both sides stack.
- **Exits (every tick):**
  - all positions close when their total floating profit is > 50 USD;
  - all positions also close when the balance is 1,000 above the last mark. In the tester, `TesterWithdrawal(1000)`
    then takes the 1,000 out.
- **Size:** fixed 0.1 lot.

## Runs (`reports/oct24/ama_eval.py base`; Darwinex-Demo, EURUSD M5, real ticks, 50,000 USD = the author's account, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**Trades:** legs from `deals_trades`.
- **Net by year:** the legs' own profits, so the tester withdrawals do not count against it.
- **Also reported:** stop-outs and withdrawals.

## Gate (S0; the Blessing grid gate, since there is no stop to define R)
1. The run completes with no stop-out, and has >= 150 trades.
2. k = 8 / max equity DD % (the tester's figure; withdrawals can affect it, noted in the outcome).
3. Pass if the k-scaled return is >= +10% a year in both 2022-24 and 2025-26.
4. **Out of sample (S1):** k-scaled return > 0, and t of the per-trade % return >= 1.65. If history quality is below
   90%, it is inconclusive.
5. **Candidate** = all pass.

## Expectation (written before the runs)
- **The mechanism:** a stop-less averaging system that banks +50 USD baskets and holds every loser.
- **Risk:** a sustained EURUSD trend against one side (for example 2022's fall for the buys) piles up losing positions.
  Expect a large equity DD and possibly a stop-out.
- **Most likely verdict:** closed (k too small, or a stop-out).

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

## Outcome (2026-10-25; log `reports/oct24/ama.log`): closed (gate fails)
| run (EURUSD M5, real ticks, 50k, 0.1 lot) | net USD | PF | max equity DD | worst day | trades | most open | net by year |
|---|---|---|---|---|---|---|---|
| S0 2022-01..2026-10, hq 100% | **+22,595.45** | 1.34 | **22.6%** | -1.9% of 50k | 4,071 | **129** | 22 +5,612, 23 +4,515, 24 +4,356, 25 +5,200, 26 +2,914 |

- **Gate fails:**
  - k = 8 / 22.6 = 0.35, so the scaled return is +3.4% a year (2022-24) and +3.3% (2025-26), against the needed 10%.
  - No stop-out, 4,071 trades. Closed.
- **Every year is positive:** about +9.5% a year raw on 50k. But that needs a 22.6% equity drawdown, and up to **129
  stop-less positions open at once**.
  - The +50 USD close-all and the +1,000 balance close-all bank the small wins.
  - The losers are held until the basket turns.
  - The tester made about 23 withdrawals of 1,000.
  - The positions still open at the end lost -953.56 USD.
- **Read:** a stop-less averaging book with a good 2022-26 record and an unbounded tail. The return per unit of drawdown
  is about a third of the gate.
- **Expectation check:** expected a large DD or a stop-out. A large DD (22.6%), no stop-out, and positive every year,
  which was better than expected. Still closed on the gate.
- **Removed** per the leftovers rule: `mql5/AMA_Trader_EA.mq5`, its profile and the MT5 copies (the source is in git at
  8822093).

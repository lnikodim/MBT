# Exp_i4_DRF_v2_EA on Darwinex EURAUD H4 (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/16418". Server: Darwinex-Demo.

**The EA:** "Exp_i4_DRF_v2" (mql5.com code 16418, Nikolay Kositsin / GODZILLA, published 2017-01-18, page updated
2026-09-15), `Exp_i4_DRF_v2.mq5` (MD5 21f7f175…), copied unchanged to `mql5/Exp_i4_DRF_v2_EA.mq5`.
- **Dependencies, in MT5 only:**
  - `Indicators/i4_DRF_v2.mq5` (MD5 8b5d38d3…), compiled with 0 errors and 0 warnings;
  - its own `Include/TradeAlgorithms.mqh` (MD5 3bc28005…, a different version from 19502's);
  - `Include/SmoothAlgorithms.mqh` (MD5 4baec63c…).
- **Compile:** 0 errors. The 14 warnings are all deprecated constants in `TradeAlgorithms.mqh`.
- **Safety:** no DLL, web or file calls.

**The author's claim:** default inputs, **EURAUD H4, 2015**, no stop or target in their test. One chart, no numbers.

**What the code does** (new H4 bar, signal bar 1):
- **Signal:** the i4_DRF_v2(11) histogram changes colour.
- **`TrendMode` = DIRECT:** open in the direction of the new colour and close the opposite position, so it is in
  effect always in the market.
- **Exits:** stop 1,000 points and target 2,000 points (100 / 200 pips), on the order.
- **Size:** fixed 0.1 lot.

## Runs (`reports/oct24/q_eval.py drf`; Darwinex-Demo, EURAUD H4, real ticks, 10,000 USD, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.
- **No replication:** the author's 2015 window predates Darwinex real ticks.

**R per trade:** from the Orders table stop (100 pips; `crabel_eval.trades`).

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **The setup:** a colour-change reversal on H4 is in effect always in the market and switches side often. Like
  Exp_CMO_Duplex (the same author's template, closed on 2026-10-25), expect PF 0.90-1.10 in R.
- **Trades:** about 50-120 a year.
- **Most likely verdict:** closed.

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

## Outcome (2026-10-25; log `reports/oct24/drf.log`, report `reports/drf_s0_20261025_094933.htm`): closed (stop-out)
| run (EURAUD H4, real ticks, 10k, 0.1 lot) | net USD | PF | max DD | deals | win | ended |
|---|---|---|---|---|---|---|
| S0 from 2022-01-01 | **-4,336.07** | 0.20 | 52.4% | 51 (25 entries) | 16.0% | **broker stop-out 2022-02-04 12:07, margin level 49.9%** |

- **Gate A fails: a stop-out after 5 weeks.** The tester ended the run there. Closed.
- **What happened:**
  - The EA opened a new position on each signal **without checking open ones**: 21 sells and 4 buys in
    January-February 2022.
  - Many had no working stop. The stop-out closes show 0.1-lot losses of -233 to -357 USD, i.e. 230-360 pips against the
    100-pip stop setting.
  - EURAUD's January 2022 rally against the stacked sells took the 10k account to the margin call.
- **Parser note:** the run log shows "0 trades" because the one-position parser (`crabel_eval.trades`) cannot pair
  stacked positions. The tester's figures and the deals table above are the record.
- **Expectation check:** expected PF 0.90-1.10 and a clean reversal system. The EA as shipped, with its own
  `TradeAlgorithms.mqh`, stacked unprotected positions instead. Closed.
- **Removed** per the leftovers rule: `mql5/Exp_i4_DRF_v2_EA.mq5`, its profile, the MT5 copies, and the `i4_DRF_v2`
  indicator, `TradeAlgorithms.mqh` and `SmoothAlgorithms.mqh` installed for it (the source is in git at 68f2ca0).

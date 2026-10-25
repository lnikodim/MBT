# Exp_CMO_Duplex_EA on Darwinex USDJPY H4 (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/19502". Server: Darwinex-Demo.

**The EA:** "Exp_CMO_Duplex" v1.00 (mql5.com code 19502, Nikolay Kositsin / GODZILLA, published 2018-01-22, page updated
2026-09-15), `Exp_CMO_Duplex.mq5` (MD5 e4db44c6…), copied unchanged to `mql5/Exp_CMO_Duplex_EA.mq5`.
- **Dependencies, installed in MT5 only:**
  - `Indicators/CMO.mq5` (MD5 40b66bb8…), compiled with 0 errors and 0 warnings;
  - `Include/TradeAlgorithms.mqh` (MD5 42c7ab6f…).
- **Compile:** 0 errors. The 20 warnings are all deprecated constants in `TradeAlgorithms.mqh`.
- **Safety:** no DLL, web or file calls. It uses a terminal global variable as a trade lock.

**The author's claim:** default inputs, **USDJPY H4, 2016**, no stop or target in their test. The chart shows about
10,000 to about 11,300. No numbers.

**What the code does:** two independent systems with their own magic numbers, both on CMO(14, SMA, close) of H4,
checked on each new H4 bar (signal bar 1).
- **Long:** opens when the CMO buffer crosses above the second buffer and closes when it is below it.
- **Short:** the mirror image.
- **In effect:** it is in the market almost all the time and switches side at each cross.
- **Stops (defaults):** stop 1,000 points and target 2,000 points (100 / 200 pips on USDJPY), on the order.
- **Size:** fixed 0.1 lot (`MMMode` = LOT).

## Runs (`reports/oct24/q_eval.py cmo`; Darwinex-Demo, USDJPY H4, real ticks, 10,000 USD, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.
- **No replication:** the author's 2016 window predates Darwinex's full real-tick coverage (2019-03).

**R per trade:** from the Orders table stop (100 pips; `crabel_eval.trades`). Most exits are opposite crosses, so R is
the result measured against the 100-pip stop.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **The setup:** a zero-cross of a 14-bar momentum oscillator on H4 switches often. Expect about 100-150 trades a year
  with a win rate around 35-45%, and small average results against the 100-pip unit.
- **USDJPY:** trended strongly in 2022-24 (up) and was choppier in 2025-26.
- **PF:** 0.90-1.10 in R.
- **Most likely verdict:** closed.

## Outcome (2026-10-25; log `reports/oct24/cmo.log`): closed (out-of-sample check fails)
| run (USDJPY H4, real ticks, 10k, 0.1 lot) | net USD | PF | max DD | trades | win | net R (t) | R by year | exits |
|---|---|---|---|---|---|---|---|---|
| S0 2022-01..2026-10, hq 100% | +809.38 | 1.08 (R 1.09) | 14.5% | 267 | 37.5% | +12.8 (+0.62) | 22 -1.3, 23 -8.9, 24 +16.2, 25 +5.8, 26 +0.9 | stop 111 at -1.03 R, target 73 at +1.99 R, signal 83 at -0.22 R |
| S1 2019-01..2022-01, hq 99% | **-1,158.88** | 0.77 | 16.4% | 193 | 34.7% | **-12.5** (-1.33) | 19 -6.7, 20 +2.7, 21 -8.5 | stop 12, target 10, signal 171 at -0.11 R |

- **Gate A passes, narrowly:** 2022-24 +6.0 R, 2025-26 +6.8 R, PF 1.08.
  - **The longs carry it:** +28.2 R, PF 1.46, in USDJPY's 2022-24 rally. The shorts lost 15.4 R.
- **The out-of-sample check fails:** 2019-21 -1,158.88 USD, PF 0.77, -12.5 R. The shorts lost 13.7 R (PF 0.56).
- **So:** the 2022-26 result is the yen trend, not an edge. Closed.
- **Expectation check:**
  - PF 1.09 in R, inside the expected 0.90-1.10.
  - 267 trades (about 56 a year), below the expected 100-150 a year.
  - Closed, as expected.
- **Removed** per the leftovers rule: `mql5/Exp_CMO_Duplex_EA.mq5`, its profile, the MT5 copies, and the `CMO` indicator
  and `TradeAlgorithms.mqh` installed for it (the source is in git at d0a5480).

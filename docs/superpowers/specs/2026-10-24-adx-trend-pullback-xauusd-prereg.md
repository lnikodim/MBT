# ADX_Trend_Pullback_EA on Darwinex XAUUSD H1 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/73958". Server: Darwinex-Demo.

**The EA:** "ADX Trend Pullback EA" v1.00 (mql5.com code 73958, WazaTrader / DVN CORE, published 2026-06-14, updated
2026-09-11), `ADX_Trend_Pullback_EA.mq5`, 295 lines, MD5 3eef48dd….
- **Copied unchanged** under the same name.
- **Safety:** no DLL, web or file calls. It prints only on failed handles or orders.

**The author's claim:** none in numbers. One illustration shows a buy setup and a sell setup on **XAUUSD H1** (May 2024).

**What the code does** (once per new H1 bar, on closed bars):
- **Trend filter:** ADX(14) on bar 1 > 25 and above bar 2.
- **Pullback event:** |close - EMA(20)| / ATR(14) is >= 0.5 on bar 2 and < 0.5 on bar 1.
- **Direction:** buy if +DI > -DI, sell if -DI > +DI.
- **Exits:** stop 1.5 x ATR(14) of bar 1, target 2 x the stop. Both on the order, no other exit.
- **Size:** fixed 0.01 lot.
- **Limits:** one position on the symbol; trades only inside the symbol's trade session.

## Runs (`reports/oct24/q_eval.py adxp`; Darwinex-Demo, XAUUSD H1, real ticks, 100k USD, 1:100, source defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.
3. **Neighbours on S0:** only if S0 and S1 pass. `InpADXThreshold` 20 / 30 and `InpPullbackATRRatio` 0.4 / 0.6, one
   at a time.

**R per trade:** from the Orders table stop (`crabel_eval.trades`; one position at a time). The fixed 0.01 lot makes net
USD small; R is the measure.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Plateau:** all 4 neighbours have PF >= 1.00 on S0.
- **Candidate** = all pass.
  - The live set already holds four gold EAs, so a candidate would also need a joint simulation for correlation.

## Expectation (written before the runs)
- **The setup:** a trend-continuation entry after a pullback, at 2R. Gold trended strongly in 2023-26, which helps
  trend entries. Stormbreaker (an ADX / Supertrend trend follower) made +48.7 R on XAUUSD H4 in 2022-26 but lost in
  2019-21.
- **Trades:** about 100-200 a year, so about 500-900 in S0.
- **PF:** 1.00-1.25 in R in S0; the out-of-sample check is the main risk again.
- **Most likely verdict:** closed (Gate A borderline or the out-of-sample check fails).

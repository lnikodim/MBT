# BreakRevertPro_EA on Darwinex EURUSD M15 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/56773". Server: Darwinex-Demo.

**The EA:** "BreakRevertPro EA Adaptive Trading Edge for Breakout Mean Reversion" (mql5.com code 56773,
seyyidsahin2834, published 2025-03-09, page updated 2026-09-15), `BreakRevertPro.mq5`, 1,699 lines, MD5 1a37faef….
- **Copied to:** `mql5/BreakRevertPro_EA.mq5` with **one logging-only amendment** (below).
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL or web calls. Outside the tester it saves arrays to `BreakRevert_Data.dat` every 1,000 ticks; not in
  the tester.

**The author's claim:** none, and no screenshots. No symbol or timeframe is stated. The page advertises "automatic
detection of validation environments" and a "safety trade mechanism".

**What the code does** (every tick, no new-bar gate; one position; at least 10 s between trades):
- **"Probabilities":**
  - A Weibull density (shape 1.5, scale 5) of the **raw M1 close prices**, and a Poisson CDF of counts over a 1-candle
    lookback.
  - The Weibull value is a fixed function of the price level: about 0.13 at EURUSD 1.1 and about 0 on gold. So it
    carries no market information.
- **Buy ("breakout"):** Poisson > 0.4 and Weibull > 0.4 and the M1 and M15 close-array trends both up. This needs
  Weibull > 0.4, so it never fires on EURUSD.
- **Sell ("mean reversion"):** Weibull < 0.4 and the |H1 close-array trend| < 20 points. So on EURUSD it is in effect
  **a sell whenever the short H1 trend is under 2 pips**.
- **Exits:** stop 1.5 x ATR(14), target 2.0 x ATR(14) of the chart timeframe, both on the order.
- **Size:** 0.01 lot (`ValidateVolume(…, 0.01)`). `risk_per_trade` is not used for the size.

**Tester-only behaviour:**
- **The "safety trade":** with `enable_safety_trade = true` (the default), and only inside the tester, it opens a
  min-lot buy (magic 999999, no stop or target) if there has been no deal yet.
- **"Validation runs":** the tester with balance <= 500, or EURUSD H1 / M1, XAUUSD D1 or GBPUSD M30. These force a
  trade even with no signal. This is there to pass the MQL5 Market validator's "no trades" check and never happens
  live.
- **Test settings:** `enable_safety_trade = false`, 100k balance, and EURUSD **M15**, which is not on that list. So the
  test sees only the live logic.

**Amendment 1 (logging only, before any run):**
- **The problem:** two `DebugPrint(…, true)` calls in `OnTick` print "Breakout signal" / "Mean-Reversion signal" on
  every tick while the signal is true. On real ticks that would flood the agent log (memory: a 19-36 GB log
  earlier).
- **The change:** `force_print` is dropped on those two lines, so they go through the EA's own 1-in-500 tester
  throttle.
- **Trading is identical.** Diff: 2 lines.

## Runs (`reports/oct24/q_eval.py brp`; Darwinex-Demo, EURUSD M15, real ticks, 100k USD, 1:100)
0. **Probe:** `q_eval.py brp probe` on 2026-09. It checks the trade count and log growth. It is not counted.
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**R per trade:** from the Orders table stop (`crabel_eval.trades`; one position at a time).

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **In effect:** a sell-only entry with no information, a 1.5 ATR stop and a 2 ATR target on M15.
- **Costs:** about 0.7 pip round trip on a stop of about 8-12 pips, so about -0.07 R a trade, plus whatever EURUSD's
  drift does to a short-only book.
- **Trades:** very many, thousands.
- **PF:** 0.80-0.95 in R.
- **Most likely verdict:** closed.

## Outcome (2026-10-24; logs `reports/oct24/brp_probe.log`, `reports/oct24/brp.log`): closed
| run (EURUSD M15, real ticks, 100k, 0.01 lot) | net USD | PF | max DD | trades | win | net R (t) | R by year |
|---|---|---|---|---|---|---|---|
| probe 2026-09 | +0.08 | 1.00 (R 0.98) | 0.0% | 303 (all sells) | 46.2% | -3.6 (-0.17) | |
| S0 2022-01..2026-10, hq 100% | **-1,745.91** | 0.85 (R 0.82) | 1.8% | 16,099 (all sells) | 41.0% | **-1,898.5** (-12.64) | 22 -185.7, 23 -414.5, 24 -505.4, 25 -450.2, 26 -342.6 |

- **Gate A fails:** PF 0.85; 2022-24 is -1,105.7 R and 2025-26 -792.8 R. Every year loses. Closed. The user also said
  "skip breakrevertpro".
- **Sells only, as the code reading predicted.** The "breakout" buy can never fire on EURUSD, because the Weibull
  density of a price near 1.1 is about 0.13.
- **Loss per trade:** -0.12 R, more than costs alone (-939.74 USD over 16,099 trades, about -0.06 USD a trade at 0.01
  lot). Stops average -1.09 R and targets +1.29 R, with 9,500 stops against 6,598 targets: the short-only entries lose
  on direction as well as on costs.
- **Log:** the amendment held the log at about 114M characters over 4.75 years.
- **Expectation check:** PF 0.82 in R, inside the expected 0.80-0.95. Thousands of trades, as expected.
- **Removed** per the leftovers rule: `mql5/BreakRevertPro_EA.mq5`, its profile and the MT5 copies (the source with the
  amendment is in git at 2c18d6c).

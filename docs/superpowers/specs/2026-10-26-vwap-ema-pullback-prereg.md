# VWAP_EMA_Pullback_EA v1.00: Stage A (pre-registration)

Date: 2026-10-26. Server: Darwinex-Demo. User rule (verbatim, pasted): "THE VWAP + EMA 9/21 STRATEGY ... For a potential bullish
setup, we look for price above VWAP, EMA 9 above EMA 21, a pullback, and bullish confirmation. For a potential bearish setup, we
look for price below VWAP, EMA 9 below EMA 21, a pullback, and bearish confirmation." Then: "5m timeframe on forex & gold".
After the open points were listed in chat, the user answered: "yes, go ahead with those defaults".

## The EA (`mql5/VWAP_EMA_Pullback_EA.mq5`, on EACore, magic 261026, compiled default M5)
**Your words, taken literally:** price above / below VWAP, EMA 9 above / below EMA 21, a pullback, then confirmation. VWAP is
anchored to the server day and weighted by tick volume (typical price = (high + low + close) / 3). EMAs on close.

**Readings of the open points (the user agreed to these defaults):**
- **Trend:** the last closed bar's close is above (below) the VWAP and EMA 9 is above (below) EMA 21.
- **Pullback:** the 1 to 8 bars before the signal bar each closed at or below (above) EMA 9, and none closed beyond EMA 21.
  A longer pullback does not qualify.
- **Confirmation:** the signal bar is bullish (bearish) and closes back above (below) EMA 9.
- **Entry:** at market when that bar closes.

**Added by me (not in the user's text):**
- **Stop:** beyond the pullback's extreme (over the signal bar and the pullback bars) plus 0.2 x ATR(14). At least 1.0 x ATR from entry.
  The trade is skipped if the stop would be wider than 3.0 x ATR.
- **Target:** 1.5 x the stop distance.
- **VWAP warm-up:** no trade in the first 12 bars after the server-midnight reset.
- **One position at a time.** EACore's guards stay on: daily loss limit 4%, monthly 12%, max spread 150 points, risk 1% per trade.

All inputs follow the EA inputs guide (groups 5-7 after EACore's 1-4).

## Runs (`reports/oct25/screen_eval.py vpb_*`; real ticks, 10,000 USD, 1:100, compiled defaults)
| cell | symbol, timeframe |
|---|---|
| vpb_X | XAUUSD M5 |
| vpb_E | EURUSD M5 |
| vpb_G | GBPUSD M5 |
| vpb_J | USDJPY M5 |
1. **Screen, 2024-01-01..2026-10-01:** reject a cell if trades < 40, PF < 1.00, net <= 0 or a stop-out.
2. **S0, 2022-01-01..2026-10-01**, survivors: trades >= 150, PF >= 1.00, net > 0 in both 2022-24 and 2025-26.
3. **S1, 2019-01-01..2022-01-01**, Gate A survivors: net > 0, PF >= 1.05, t >= 1.65 (inconclusive if history < 90%).
4. **Candidate** = all pass; then the drawdown is scaled (k = 8 / max DD %) and must give >= +10% a year in both regimes.
- **Multiple testing:** 4 cells; no input is tuned. Any change after a result needs a new pre-registration.
- **R** comes from the stop on each order (one position at a time, so the pairing is exact).

## Expectation (written before the runs)
- **Costs matter on M5.** The two earlier VWAP + EMA EAs here failed on M5 (the cross EA: PF 0.72 and 0.93; the EMA/VWAP trail EA: PF
  1.17 on one cell, but a prop-challenge pass rate below the MACD bar). A pullback entry with a 1.5 RR target has a
  much lower trade count and a defined stop, but the stop can be only about 1 ATR, so costs are still a noticeable share of R.
- **Expected PF:** about 0.90 to 1.10, near zero net R on forex, and a better chance on gold in 2024-26.
- **Most likely verdict:** closed on forex; at most one gold cell reaching the later stages.

## Outcome (2026-10-26; log `reports/oct25/vpb.log`): closed, all four cells rejected at the screen
Real ticks, 2024-01..2026-10, 10,000 USD, 1% risk, compiled defaults, no stop-outs. R from the stop on each order (no overlapping positions).

| cell | net USD | PF | max DD | trades | win | net R (mean, t) | gross P&L (gross PF) | costs | by year (24 / 25 / 26) | max lot |
|---|---|---|---|---|---|---|---|---|---|---|
| vpb_X XAUUSD M5 | **-9,405.05** | 0.82 | 94.9% | 2,742 | 37.5% | **-306.5** (-0.112, t -4.49) | -4,397 (0.91) | -5,008 | -7,529 / -1,437 / -439 | 0.98 |
| vpb_E EURUSD M5 | **-9,826.57** | 0.65 | 98.3% | 1,904 | 34.9% | **-564.2** (-0.296, t -10.31) | -4,442 (0.81) | -5,385 | -7,796 / -1,629 / -401 | 2.69 |
| vpb_G GBPUSD M5 | **-9,871.45** | 0.61 | 98.8% | 1,691 | 32.4% | **-576.6** (-0.341, t -11.10) | -5,584 (0.74) | -4,287 | -7,952 / -1,625 / -294 | 2.29 |
| vpb_J USDJPY M5 | **-9,821.35** | 0.72 | 98.3% | 1,895 | 34.8% | **-475.3** (-0.251, t -8.61) | -5,229 (0.83) | -4,592 | -7,104 / -2,310 / -407 | 2.94 |

- **Gate:** every cell fails the screen (PF < 1.00, net < 0). S0 and S1 were not run.
- **The strategy loses before costs.** Gross PF is 0.74 to 0.91 in all four cells, so the rule has no edge on M5 in 2024-26
  to rescue. Costs (spread, commission, swap) then roughly double the loss (-4,300 to -5,400 USD each).
- **The win rate is below the break-even.** With a 1.5 target the break-even win rate is 40% before costs; the cells won
  32.4% to 37.5%. Exits: about 60% stops, 37% targets, 2% the time guard.
- **Both sides lose:** longs 1,459 / buys and shorts 1,283 on gold, similar elsewhere. No direction problem was found.
- **The yearly split is the shrinking account,** not a regime change: each cell lost about 75-80% in 2024 and the
  remaining equity then lost less in dollars at the same 1% risk.
- **Expectation check:** expected PF about 0.90 to 1.10 and a closed verdict on forex, with gold the best chance. Got PF 0.61 to
  0.82, worse than expected on every cell, gold included.
- **The EA stays in the repo** (`mql5/VWAP_EMA_Pullback_EA.mq5`, as its two VWAP siblings did), not removed under the failed-EA rule,
  because it is the user's own rule built here. Any new version needs a new pre-registration.

## Amendment 1 (2026-10-26, written before the runs): the same rules on M15 and H1
User: "try it on M15 and H1". The M5 screen closed all four cells with a gross PF below 1 (a rule with no edge before costs on M5).
Costs are a smaller share of a larger bar, so this tests whether the same rules work slower.

- **What changes:** only the signal timeframe, and the VWAP warm-up so that it stays **one hour** as agreed (12 bars on M5 = 4 bars on
  M15 = 1 bar on H1). Every other input is the compiled default: EMA 9/21, pullback <= 8 bars, ATR(14) stop with a 0.2 buffer, 1.0 minimum
  and 3.0 maximum, RR 1.5, 1% risk, guards on. The pullback length is left in bars (8 bars = 2 hours on M15, 8 hours on H1).
- **Setting both:** the EA's signal timeframe is its input `InpTimeframe`, so each cell sets `InpTimeframe` and the chart period together.
- **Cells (8):** vpb15_X / E / G / J = XAUUSD, EURUSD, GBPUSD, USDJPY on M15; vpb60_X / E / G / J = the same on H1.
- **Same gates:** screen 2024-01-01..2026-10-01 (trades >= 40, PF >= 1.00, net > 0, no stop-out), then Gate A on 2022-26, then 2019-21 (net > 0, PF >= 1.05, t >= 1.65).
- **Multiple testing:** 12 cells in total (4 on M5, 8 here); a pass on one cell of 8 is weak evidence unless it passes all stages.
- **Expectation (before the runs):** the M5 gross PF of 0.74 to 0.91 will move toward 1.0 as bars get larger, but a rule with no edge on M5 usually
  has none on M15 either, and H1 will have few trades (the 40-trade floor may bind). Most likely: closed on all eight. If any cell
  survives, gold on H1 is the most plausible.

## Amendment 1 outcome (2026-10-26; log `reports/oct25/vpb2.log`): closed, 7 of 8 cells rejected at the screen, the eighth fails Gate A
Real ticks, 10,000 USD, 1% risk, compiled defaults except the signal timeframe and the one-hour VWAP warm-up. Screen = 2024-01..2026-10. R from the order stops.

| cell | net USD (max lot) | PF | max DD | trades | win | net R (mean, t) | gross PF | by year (24 / 25 / 26) |
|---|---|---|---|---|---|---|---|---|
| vpb15_X XAUUSD M15 | **-8,401.30** (0.85) | 0.79 | 84.9% | 1,470 | 36.7% | -186.4 (-0.127, t -3.92) | 0.84 | -5,773 / -1,308 / -1,320 |
| vpb15_E EURUSD M15 | **-9,560.26** (2.76) | 0.69 | 95.9% | 1,411 | 35.6% | -322.5 (-0.229, t -6.56) | 0.81 | -7,082 / -1,681 / -797 |
| vpb15_G GBPUSD M15 | **-9,697.30** (2.20) | 0.66 | 97.0% | 1,298 | 33.5% | -366.7 (-0.283, t -8.10) | 0.76 | -7,254 / -2,018 / -425 |
| vpb15_J USDJPY M15 | **-9,537.33** (2.69) | 0.74 | 95.5% | 1,527 | 35.7% | -313.0 (-0.205, t -6.33) | 0.82 | -6,380 / -2,424 / -734 |
| **vpb60_X XAUUSD H1** | **+785.36** (0.36) | 1.03 | 14.4% | 410 | 42.2% | +11.7 (+0.029, t +0.46) | 1.07 | -116 / +590 / +311 |
| vpb60_E EURUSD H1 | **-5,411.89** (1.77) | 0.75 | 55.9% | 424 | 35.4% | -75.5 (-0.178, t -3.02) | 0.81 | -1,846 / -2,237 / -1,329 |
| vpb60_G GBPUSD H1 | **-2,986.89** (1.31) | 0.88 | 32.6% | 431 | 39.9% | -32.0 (-0.074, t -1.20) | 0.94 | -1,286 / -450 / -1,251 |
| vpb60_J USDJPY H1 | **-3,735.59** (1.50) | 0.82 | 43.7% | 407 | 37.6% | -44.3 (-0.109, t -1.76) | 0.86 | -1,963 / -1,443 / -329 |

- **The one pass, XAUUSD H1, fails Gate A on 2022-26:** -2,804.34 USD, PF 0.91, DD 39.6%, 724 trades, -29.4 R (mean -0.041, t -0.88).
  2022 -1,425, 2023 -1,810, 2024 -143, 2025 +399, 2026 +175; 2022-24 -3,378, 2025-26 +573. The 2024-26 pass was the recent years. S1 not run.
- **Gross PF of all 12 cells (M5, M15, H1):** 0.74 to 1.07, only the XAUUSD H1 screen window above 1.00. The rule has no gross edge in 11 of 12 cells.
- **Timeframe effect:** the loss per trade shrinks on larger bars (mean R by timeframe, forex: M5 -0.25 to -0.34, M15 -0.21 to -0.28, H1 -0.07 to -0.18), because the cost share
  falls with the larger stop (costs 5-12% of turnover on M5, 2-4% on H1). The shape never turns positive on forex.
- **Expectation check:** expected most cells closed, with gold H1 the most plausible survivor. That matched: gold H1 was the only screen pass,
  and it failed 2022-23. H1 trade counts (about 410-430) cleared the 40-trade floor, unlike the guess that it might bind.
- **Verdict:** the VWAP + EMA 9/21 pullback rule as defined does not work on forex or gold on M5, M15 or H1. Closed. The EA stays in
  the repo as a tool, like its siblings.

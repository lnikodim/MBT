# Daily_Price_Action_EA on Darwinex EURUSD / GBPUSD, M15 / H1 / H4 (pre-registration)

Date: 2026-10-23. User: "let's test this EA https://www.mql5.com/en/code/68704". Server: Darwinex-Demo.

**The EA:** "Price Action Intraday Trading - Expert for MT5" (mql5.com code 68704, l2carbon, published 2026-01-30),
`Daily_Price_Action_EA.mq5`, 1,237 lines, MD5 387cb5e1…. It is copied unchanged to `mql5/Daily_Price_Action_EA.mq5`
(the name already follows the convention). No DLL, web or file calls. The author shows a chart animation only, no
results.
- **Recommended:** M15 / H1 / H4 on EURUSD, GBPUSD, XAUUSD, with "optimize StopLossPips and PinBarRatio" per instrument.

**What the code does** (new bar, account `PositionsTotal() == 0`, 02:00-20:00 server time):
- **Trend:** EMA 20 vs EMA 50 on the forming and the last bar.
- **Signal on the last closed bar, first match wins:**
  - **Pin bar:** wick > 10 pips and > 2x the body. A buy needs the lower wick > 2x the upper, with the trend up or
    neutral or price at a 20-bar support. Sells mirror this.
  - **Engulfing:** body >= 15 pips, trend up or neutral (buy) / down or neutral (sell).
  - **Inside-bar breakout.**
- **Stop / target:** stop 40 pips, target 2x the stop (80 pips). A pip is 10 points on 3- and 5-digit symbols.
- **Trade management:** break-even at +20 pips; trailing stop 30 pips with a 10-pip step.
- **Exits and limits:** all positions closed at 20:00 server time; daily loss limit 3% of the day-start balance.
- **Size:** 1.5% of balance on the stop.
- **Closes and stop changes** check magic and symbol. Only the entry check counts the whole account (it would block
  beside other EAs live; no effect in a single-EA test).

**Symbols and timeframes:**
- **XAUUSD is out:** it has 2 digits, so 40 "pips" is $0.40, below gold's spread. We do not optimise inputs.
- **Grid:** EURUSD and GBPUSD x M15, H1, H4 = 6 cells, source defaults. Darwinex real ticks are 100% for both (probe of
  2026-10-23).

## Runs (`reports/pa/pa_eval.py`; Darwinex-Demo, real ticks, 100k USD, 1:100, source defaults = 1.5% risk)
- **S0, 2022-01-01..2026-10-01:** each cell.
- **S1, 2019-01-01..2022-01-01:** out of sample, only for cells that pass Gate A.

**R per trade** = net / (first stop distance x volume x value per point), with the stop from the Orders table (parser
of `reports/crabel/crabel_eval.py`; one position at a time).

## Checks
- **Gate A (per cell):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check:** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is inconclusive.
- **Candidate** = both pass. With 6 cells, about 0.3 could pass one check by chance.
- **Reported:** net USD (at 1.5%) and net R, PF, max DD, trades, win rate, mean R (t), R by year, long and short split,
  exits.

## Expectation (written before the runs)
- **Edge:** generic candlestick patterns with a loose trend filter and a fixed 40-pip stop and 80-pip target usually show
  none after costs. The end-of-day close at 20:00 cuts many 80-pip targets on M15 / H1.
- **PF:** 0.85-1.00 in most cells.
- **Most likely verdict:** closed.

## Amendment 1 (2026-10-23, after the first run was stopped unfinished; no result seen)
- **What happened:** the first S0 run (EURUSD M15) was stopped. On a day the 3% daily loss limit is hit, the EA prints
  "Daily loss limit reached. No new trades today." on **every tick** until the day ends (line 134). On real ticks this
  grew the tester agent log to 35.7 GB.
- **Change (logging only, trading identical):** the message prints once per server day (`static` day stamp).
- **Before the grid:** a one-month probe (EURUSD M15, 2026-09) measures the log growth.

## Amendment 2 (2026-10-23, after one S0 cell showed the EA stops trading)
- **What happened:** EURUSD M15 S0 made 13 trades, all in 2022-01..02 (-3,320.24 USD), then none.
- **Why:** the daily-loss limit hit on 2022-02-18 and never released (1,198 blocked days to 2026-09-30). The source resets
  the day-start balance only on a new bar whose first tick is at exactly 00:00 server time. Darwinex ticks after the
  midnight rollover arrive later, so the reset never runs and one daily stop blocks the EA permanently. This also
  caused the 35.7 GB per-tick log.
- **Change (a bug fix that makes the feature work as described, "stops trading for the day"):** the balance resets on
  the first new bar of each server day.
- **Result seen before this change:** only the 13-trade, broken run.
- **Unchanged:** the grid, the checks, sizing and every other rule. All 6 cells rerun from scratch.

## Amendment 3 (2026-10-23, during the grid; no XAUUSD result seen)
- **User:** pointed at a Code Base comment: "i have back tested this in 5 min and 15 min in XAUUSD super working and good
  results almost 90% returns".
- **Added:** XAUUSD M5 and M15, source defaults (with amendments 1-2), same window, Gate A and out-of-sample check
  (`pa_eval.py extra XAUUSD M5,M15`).
- **Expectation, written now:** strongly negative. The stop is 40 "pips" = $0.40 on gold, about the size of Darwinex's
  real-tick gold spread ($0.28-0.89). Results like "90% returns" usually come from a generated-tick or 1-minute-OHLC
  test with a small fixed spread.
- **Cells:** 8 in total, about 0.4 could pass one check by chance.

## Amendment 4 (2026-10-23, after XAUUSD M5 made 0 trades; no trade results)
- **User:** "skip the forex pairs and continue directly with XAUUSD". GBPUSD H1 / H4 are not run; EURUSD M15 / H1 / H4
  and GBPUSD M15 were done.
- **XAUUSD M5 S0 made 0 trades.** All 37,705 signals were refused by the EA's own margin check ("Insufficient funds").
  The default 1.5% risk on a $0.40 stop asks for 37.5 lots, about 360-380k USD of margin on Darwinex gold.
- **Change for the XAUUSD cells only:** `RiskPercent` 1.5 -> **0.3**, so 7.5 lots (about 76k USD margin) fits.
  R per trade does not depend on the size. The rest is unchanged.

## Outcome (2026-10-23; log `reports/pa/base.log`): closed
| cell (real ticks 2022-01..2026-10, 100k) | risk | net USD | PF | max DD | trades | win | net R (t) | R 2022-24 / 2025-26 |
|---|---|---|---|---|---|---|---|---|
| EURUSD M15 | 1.5% | -30,686.99 | 0.85 | 34.4% | 646 | 35.6% | -22.4 (-1.36) | -19.1 / -3.4 |
| EURUSD H1 | 1.5% | -20,248.84 | 0.93 | 37.5% | 896 | 35.2% | -12.1 (-0.60) | -11.5 / -0.6 |
| EURUSD H4 | 1.5% | -16,354.28 | 0.91 | 26.3% | 481 | 36.4% | -10.2 (-0.67) | -6.0 / -4.2 |
| GBPUSD M15 | 1.5% | -73,308.07 | 0.75 | 76.2% | 1,204 | 30.7% | -83.9 (-3.50) | -69.3 / -14.7 |
| XAUUSD M5 | 0.3% | -99,913.35 | 0.20 | 99.9% | 3,772 | 17.9% | -2,510.0 (-46.04) | -2,510.0 / account empty |
| XAUUSD M15 | 0.3% | -99,909.14 | 0.19 | 99.9% | 3,657 | 17.1% | -2,498.2 (-47.27) | 22 -1,786.2, 23 -712.0 / account empty |

- **Every cell fails Gate A.** No out-of-sample run. GBPUSD H1 / H4 were not run (user). Closed.
- **Forex:** the candlestick setups lose in every cell and both regimes (PF 0.75-0.93).
- **Gold:**
  - the 40-pip default is a $0.40 stop, about Darwinex's real-tick gold spread;
  - stops 3,427 vs targets 230 on M15; both accounts were empty by 2023-24.
  - The Code Base comment's "almost 90% returns" on XAUUSD M5 / M15 is not reproduced on real ticks. Such a result
    needs a small fixed spread (generated ticks / 1-minute OHLC) and a high-leverage broker; at the default 1.5% the
    EA cannot even open on Darwinex's gold margin (amendment 4).
- **Bugs found in the published EA** (the fixes were tested only here):
  - the every-tick daily-loss print (amendment 1);
  - the daily reset needs a tick at exactly 00:00, so one daily stop blocks the EA permanently on Darwinex
    (amendment 2).
- **Removed** per the leftovers rule: `mql5/Daily_Price_Action_EA.mq5`, its profile and the MT5 copies (the original in
  git at 2f3930e; with amendments 1-2 at 3d14d77).

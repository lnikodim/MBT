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

# Expert_MACD_EURUSD_H1_EA on Darwinex EURUSD H1 (pre-registration)

Date: 2026-10-23. User: "let's test another EA: https://www.mql5.com/en/code/16967". Server: Darwinex-Demo.

**The EA:** "Expert MACD EURUSD 1 Hour" (mql5.com code 16967, 2017; idea by Gabriel, MQL5 code by barabashkakvn),
`Expert_MACD_EURUSD_1_Hour.mq5`, 250 lines, MD5 e585dad0…. It is copied unchanged to
`mql5/Expert_MACD_EURUSD_H1_EA.mq5`, renamed per the naming convention. No DLL, web or file calls. The author shows a
buy example and no results.

**What the code does** (every tick, chart timeframe, one position at a time, magic + symbol):
- **Indicator:** MACD(5, 15, 3) on bars 0-3, where bar 0 is the **forming** bar.
- **Buy:** the signal line falls over bars 3 -> 1 and turns up on bar 0. The main line dips at bar 2 and rises
  through bars 1 and 0, with main[3] < 0, main[1] < -0.0002 and main[0] > +0.0002: a swing of at least 0.0004 within
  the forming bar.
- **Sell:** the mirror image, with main[1] > +0.0002 and main[0] < -0.00035.
- **Exit:** close as soon as the forming bar's main line is below (buys) or above (sells) the last closed bar's.
  There is also a 25-pip trailing stop, and **no stop loss and no take profit at entry**.
- **Size:** free margin x 0.01 / 100 lots, so **10 lots per 100k**, compounding. That fits Darwinex's 1:30 EURUSD
  margin (about $39k for 10 lots).

## Runs (`reports/expertmacd/expertmacd_eval.py`; Darwinex-Demo, EURUSD H1, real ticks, 100k USD, 1:100, source as is)
- **S0, 2022-01-01..2026-10-01.**
- **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

With no stop, R is undefined, so the gate is in USD and in % of balance per trade (as for Invictus). Trades are
rebuilt from the Deals table (`scripts/blessing_eval.py` `deals_trades`).

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, t of the per-trade % return >= 1.65. If history quality is below
  90%, it is inconclusive.
- **Candidate** = both pass. Anything else closes the EA. No input search.
- **Reported:** net USD (at 10 lots per 100k), PF, max DD, worst trade and worst day in % of balance, trades, win rate,
  mean % per trade (t), net by year, long and short split, median hold.

## Expectation (written before the runs)
- **Profile:** the entry needs a 0.0004 MACD swing inside one H1 bar, which is rare, so likely under 150 trades.
- **Trades:** the exit fires on the first tick against the trade, so trades are short and costs weigh heavily.
- **PF:** 0.80-1.05.
- **Most likely verdict:** closed (trade count or PF).

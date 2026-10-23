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

## Outcome (2026-10-23; log `reports/expertmacd/base.log`): closed
| run (100k, 10 lots per 100k, compounding) | net USD | PF | max DD | trades | win | mean % per trade (t) | worst trade / day | net by year |
|---|---|---|---|---|---|---|---|---|
| H1 S0 2022-26, hq 100% | -7,992.93 | 0.85 | 25.5% | 40 | 42.5% | -0.155% (-0.29) | -6.88% / -5.17% | 22 +7,181, 23 +4,995, 24 -3,795, 25 -15,337, 26 -1,038 |

- **Gate A fails:** 40 trades against the 150 floor, PF 0.85, and 2025-26 lost -16,374 USD (2022-24 made +8,381).
  No out-of-sample run. Closed.
- **Sides:** buys 32 trades, -10,196 USD, PF 0.76; sells 8 trades, +2,203 USD.
- **No stop:** with the source's sizing, one trade lost 6.9% of the balance and one day 5.2%. That day alone would break
  FTMO's 5% daily limit. Median hold 136 min.
- **Order failures:** 7 trailing-stop changes were refused `[invalid stops]`.
- **Expectation check:** under 150 trades and PF 0.85, as expected.
- **Fixed in the eval script:** an escaping error in the order-failure count crashed the last report line. The by-year
  figures above come from the saved report.
- **Removed** per the leftovers rule: `mql5/Expert_MACD_EURUSD_H1_EA.mq5`, its profile and the MT5 copies (the source is
  in git at 2352b54).

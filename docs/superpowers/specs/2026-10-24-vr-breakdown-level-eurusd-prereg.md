# VR_Breakdown_Level_EA on Darwinex EURUSD H1 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/69545". Server: Darwinex-Demo.

**The EA:** "VR Breakdown level" v26.020 (mql5.com code 69545, Vladimir Pastushak / VOLDEMAR, published 2026-02-23, page
updated 2026-09-15), `VR_Breakdown_level.mq5`, MD5 5c3c261e….
- **Copied unchanged to:** `mql5/VR_Breakdown_Level_EA.mq5` (renamed per the naming convention).
- **Safety:** no DLL, web or file calls. No `Print`.

**The author's claim:** none in numbers. There is a tester animation of EURUSD H1, 2025-02-03..02-05 (3 days), with the
balance going from about 100 to 120.

**A reviewer's comments** (forum #1-#3):
- no funds check;
- a lot below the minimum becomes 0.0 and still tries to trade;
- if the SL / TP check fails, the position stays without stops.

None of these matter at the defaults on Darwinex: 0.01 lot is the minimum, and the stops level is 0.

**What the code does** (chart timeframe, every tick):
- **Levels:** on each new bar, the levels are the previous bar's high and low.
- **Buy:** the first tick with ask >= the high opens a market buy, and the level resets, so at most one buy per bar.
- **Sell:** bid <= the low opens a market sell in the same way. A bar can open both.
- **Stops:** stop 200 points and target 400 points (20 / 40 pips on EURUSD), set on the tick after the fill. No other
  exit.
- **No position limit:** positions from earlier bars stay open beside new ones (hedging account).
- **Size:** fixed 0.01 lot.

## Runs (`reports/vrbl/vrbl_eval.py`; Darwinex-Demo, EURUSD H1, real ticks, 100k USD, 1:100, source defaults)
0. **Probe:** 2026-09, one month. It checks the trade count, how many positions are open at once, and agent log growth.
   It is not counted.
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**Trades:** legs from the Deals table (`scripts/blessing_eval.py` `deals_trades`, which handles overlapping positions).
- **R per trade** = net / (200 points x 1 USD per point per lot x volume), so 1 R is 2.00 USD at 0.01 lot.
- **Exits:** stop if the price move is <= -150 points, target if >= +350, else other.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
  - Trades overlap, so they are not independent and t is overstated. It is reported as is, and the overlap is shown.
- **Candidate** = both pass. No input search.
- **Reported:** net USD (0.01 lot) and net R, PF, max DD, trades, win rate, mean R (t), R by year, long and short split,
  exits, the most positions open at once.

## Expectation (written before the runs)
- **Trades:** almost every H1 bar breaks one side of the previous bar, so expect about 25-40k trades in 2022-26, with
  many open at once.
- **Edge and costs:** a previous-bar break on EURUSD H1 has no known edge. Costs are about 0.7-1 pip on a 20-pip stop,
  about -0.04 R per trade.
- **PF:** 0.90-0.98 in R. With that many trades even a small cost gives a large negative t.
- **Most likely verdict:** closed.

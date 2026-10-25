# MA_MACD_Averaging_EA on Darwinex EURUSD H1 (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/22854". Server: Darwinex-Demo.

**The EA:** "MA MACD Position averaging v2" (mql5.com code 22854, barabashkakvn, published 2018-12-28, page updated
2026-09-15), `MA_MACD_Position_averaging_v2.mq5` (MD5 1dbf4280…, 667 lines).
- **Copied unchanged to:** `mql5/MA_MACD_Averaging_EA.mq5`.
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL, web or file calls. It prints on trades and errors.

**The author's claim:** none. No symbol, timeframe or results; one illustration. Commenters report that it "won't open
the position" and does not trade commodity symbols.

**What the code does** (new bar; `Bar Current` = 0, so the forming bar):
- **Buy signal:** MACD(12, 26, 9, weighted) below 0, main above signal (with a main / signal ratio filter of 0.9), and
  the price more than 4 pips above LWMA(15, weighted). Sell is the mirror image.
- **Averaging:** if the worst position of one direction is more than **30 pips** in loss, another position opens in
  the same direction at **2x** that position's lot. There is no cap except margin: 1, 2, 4, 8 … lots.
- **Exits per position:** stop 50 pips, target 50 pips, trailing stop 5 pips (5-pip step).
- **Clean-up:** if positions of both directions exist at once, all are closed.
- **Size:** 1.0 lot start.

**Symbol and timeframe choice** (none given): **EURUSD H1**, where 50-pip stops and targets fit the bar size. On 100k
the default 1.0 lot is 0.5% risk on the first position.

## Runs (`reports/oct24/avg_eval.py base`; Darwinex-Demo, EURUSD H1, real ticks, 100k USD, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**Trades:** positions overlap, so the legs come from `deals_trades`.
- **R per leg** = profit / (50 pips x volume x 10 USD), using each leg's own lot, so the averaging is normalised out.
- **USD and the tester's PF / DD:** these show the EA as written.
- **Also reported:** the largest lot and stop-outs.

## Checks
- **Gate A (S0):** legs >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26, **no stop-out**.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **Exits:** the 5-pip trailing stop with a 50-pip target cuts winners short. Most winners end at about +5-10 pips,
  while losers run to -50.
- **Averaging:** it doubles into adverse moves. A 150-pip move adds 1+2+4+8 lots before stops hit, so DD can be large.
- **PF:** 0.80-1.00 in R.
- **Most likely verdict:** closed.

## Outcome (2026-10-25; log `reports/oct24/avg.log`): closed
| run (EURUSD H1, real ticks, 100k, 1.0 lot start) | net USD | PF | max DD | legs | win | net R (t) | R by year | exits |
|---|---|---|---|---|---|---|---|---|
| S0 2022-01..2026-10, hq 100% | **-8,448.77** | 0.87 | 11.5% | 427 | 71.2% | **-16.9** (-1.23) | 22 -3.4, 23 -10.0, 24 +3.9, 25 -7.0, 26 -0.3 | stop 121 at -1.03 R, target 39 at +0.99 R, other 267 at +0.26 R |

- **Gate A fails:** PF 0.87; 2022-24 is -9.5 R and 2025-26 -7.4 R. Closed.
- **The shape is as expected:** a 71% win rate from the 5-pip trailing stop (267 trailing exits at +0.26 R) against 121
  full stops at -1.03 R.
- **The averaging never fired:** at most 1 position was open and the largest lot was the base 1.0. No position reached
  the 30-pip "step lossing" add on a new H1 bar before its stop or trail closed it. So the result is the MA / MACD
  signal at a fixed lot, and the averaging risk was never tested.
- **Expectation check:** PF 0.86 in R, inside the expected 0.80-1.00. Closed, as expected. The expected averaging DD did
  not happen because the adds never triggered.
- **Removed** per the leftovers rule: `mql5/MA_MACD_Averaging_EA.mq5`, its profile and the MT5 copies (the source is in
  git at 0b412a4).

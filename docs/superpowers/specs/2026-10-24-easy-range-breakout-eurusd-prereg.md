# Easy_Range_Breakout_EA on Darwinex EURUSD M15 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/71460". Server: Darwinex-Demo.

**The EA:** "Easy Range Breakout EA - MT5" v1.01 (mql5.com code 71460, Osmar Sandoval Espinosa, published 2026-04-10,
updated 2026-09-11), `Range_BreakOut_EA_1_02.mq5`, 274 lines, MD5 df6cbbc2….
- **Copied unchanged to:** `mql5/Easy_Range_Breakout_EA.mq5`.
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL, web or file calls. It sets chart colours and draws range boxes.

**The author's claim:**
- **The example:** "EURUSD 2026.01.01 - 2026.03.03, Range Start Hour 5, Range End Hour 11, Trading End Hour 22".
- **The equity screenshot:** about 1,000 to about 1,040.
- **A second screenshot:** shows GBPUSD M15 range boxes.

**What the code does** (every tick):
- **Range:** the high and low of the M1 bars from RangeStart to RangeEnd server time, each day.
- **Entry:** after RangeEnd, the first M15 close beyond the range opens a market trade. Only one trade a day.
- **Exits:** stop at the opposite edge of the range; target = range high + the range size (buys) or range low - the
  range size (sells), so 1:1. Every open position on the account is closed after 22:00.
- **Size:** the symbol minimum lot (0.01). No magic number.
- **Log risk:** when the breakout close is valid but the price has already passed the target, it prints "SL or TP
  incorrect" on every tick, possibly for the rest of the day. So there is a probe first.

**Settings (2 cells; EURUSD M15):**
- **A, the page example:** range 05:00-11:00, flat at 22:00. That is the London pre-open range on Darwinex (NY+7).
- **B, the source defaults:** range 01:00-06:00, flat at 22:00.
- **Multiple testing:** with 2 cells, about 0.1 could pass one check by chance.

## Runs (`reports/oct24/q_eval.py erbA|erbB`; Darwinex-Demo, EURUSD M15, real ticks, 100k USD, 1:100)
0. **Probe:** `q_eval.py erbA probe` on 2026-09. It checks log growth. It is not counted.
1. **S0, 2022-01-01..2026-10-01, each cell.**
   - The author's example window 2026-01-01..03-03 is read off S0. It is exact: one trade a day and a fixed lot, so no
     state carries over.
2. **S1, out of sample, 2019-01-01..2022-01-01:** only for a cell that passes.

**R per trade:** from the Orders table stop (`crabel_eval.trades`; one position at a time).

## Checks (per cell)
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **Cell A:** a London-open range breakout at 1:1 with a 22:00 flat exit. On EURUSD it has had no stable edge in recent
  years; expect PF 0.90-1.05 in R and about 200 trades a year.
- **Cell B:** the Asian range, about 01:00-06:00 server time, is narrow, so stops are tight and costs higher in R.
  Expect PF 0.85-1.00.
- **Author's window:** about the author's +40 USD on 0.01 lot for cell A, in either direction. It is 2 months, too
  short to mean much.
- **Most likely verdict:** closed.

## Outcome (2026-10-24; logs `reports/oct24/erb_probe.log`, `erbA.log`, `erbB.log`): closed (both cells)
| cell (EURUSD M15, real ticks, 100k, 0.01 lot) | net USD | PF | max DD | trades | win | net R (t) | R by year |
|---|---|---|---|---|---|---|---|
| probe A 2026-09 | +1.47 | 1.10 (R 1.80) | 0.0% | 22 | 59.1% | +3.6 (+1.12) | |
| **A** 05-11, S0 2022-01..2026-10, hq 100% | **-88.19** | 0.94 (R 0.93) | 0.15% | 1,197 | 54.5% | **-28.6** (-1.12) | 22 +1.7, 23 -4.0, 24 -14.9, 25 -17.8, 26 +6.4 |
| **B** 01-06, S0 2022-01..2026-10 | 0.00 | n/a | 0% | **0** | n/a | n/a | n/a |

- **Cell A fails Gate A:** 2022-24 is -17.2 R and 2025-26 -11.4 R.
  - **Exits:** 321 stops at -1.04 R, 504 targets at only +0.67 R, and 372 closed at 22:00 at -0.09 R. The entry is at the
    breakout candle's close, already beyond the range edge, so the target (one range from the edge) is nearer than the
    stop.
  - **Sides:** longs -26.2 R, shorts -2.4 R.
- **The author's window,** 2026-01-01..03-03, in cell A: 41 trades, +14.48 USD (+1.9 R). That is the author's direction
  (about +40 USD on their chart), and a good stretch of a losing EA.
- **Cell B made no trades at all in 4.75 years.**
  - The inputs were applied (the tester log shows RangeStartHour=1, RangeEndHour=6).
  - Every breakout was refused by the EA's own check, which printed "SL or TP incorrect" 314,211 times.
  - The cause was not traced. One candidate: the check compares the distance with the enum constant
    `SYMBOL_TRADE_STOPS_LEVEL` itself, not the symbol's stops level.
  - Cell B fails Gate A on trades either way. The eval crashed on the empty result (net_profit None), now guarded in
    `q_eval.py`.
- **Logs:** cell A logged 375,858 "SL or TP incorrect" lines (about 37M characters), the per-tick print flagged before
  the runs.
- **Expectation check:** cell A PF 0.93 in R, inside the expected 0.90-1.05. Cell B: no trades, not foreseen.
- **Removed** per the leftovers rule: `mql5/Easy_Range_Breakout_EA.mq5`, its profile and the MT5 copies (the source is in
  git at 458e843).

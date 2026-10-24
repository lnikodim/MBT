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

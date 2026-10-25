# GDS_Renko_RSI_MACD_EA on Darwinex XAUUSD M1 (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/78581". Server: Darwinex-Demo.

**The EA:** "GDS Renko RSI + MACD 4-Mode Demo EA" v0.11 (mql5.com code 78581, gavaav / Andrey Goida, published 2026-10-19),
`GDS_Renko_RSI_MACD_4Mode_Demo_EA_v0.11.mq5` (MD5 33343bd7…). The ZIP holds the same single file.
- **The author:** the same as GDS Renko Bollinger (77236, closed 2026-10-24: it replicated the author's fitted window
  and failed the 2019-21 check).
- **Copied unchanged to:** `mql5/GDS_Renko_RSI_MACD_EA.mq5`.
- **Compile:** 0 errors. The 1 warning is "version '0.11' … must be xxx.yyy" (Market format only).
- **Safety:** no DLL, web or file calls.

**The author's claim** (page):
- **The report:** `ReportTester-7800379.html` (not included in the download). RoboForex-ECN, **XAUUSD M1,
  2026-01-01..2026-10-19**, real ticks (100%, 104.6M ticks), 10,000 USD, 1:500.
- **Results:** **178 trades, net +2,348.57, PF 1.49**, max equity DD 622.27 (5.99%).
- **The preset used** (not included either):
  - MACD Signal mode, brick 12.00 in price units, MACD 5 / 30 / 5;
  - TP 14 bricks, SL 13 bricks, max hold 1,380 min, cooldown 1 brick, 0.01 lot.

**What the code does:**
- **Bricks:** classic Renko with a two-brick reversal, built inside the EA from ticks.
- **Entries:** one of four modes (RSI re-entry, RSI midline, MACD vs its SMA signal, MACD zero), on completed bricks
  only.
- **Exits:** virtual TP / SL in bricks and a maximum holding time. An opposite signal does not close.
- **Limits:** a cooldown in bricks after an exit; a spread / brick filter on entries; one position.

**Source defaults vs the preset:** the source defaults are RSI Midline, brick 100 points (1.00 USD), MACD 12 / 26 / 9,
TP 8 / SL 6 bricks, 1,440 min, cooldown 3. They are not the preset.

## Cells (XAUUSD M1, real ticks, 10,000 USD, 1:100)
- **A, the preset as the page describes it:** `InpMode` 2, `InpBrickUnit` 1 (price), brick 12.0, MACD 5 / 30 / 5, TP 14,
  SL 13, max hold 1,380, cooldown 1. The other inputs stay at their defaults (RSI 14 / 30, max spread 0.35 of a brick,
  0.01 lot).
- **B, the source defaults.**
- **Multiple testing:** 2 cells.

## Runs (`reports/oct24/gds2_eval.py A|B`)
1. **R0, cell A only:** 2026-01-01..2026-10-19, the author's window. The author's setup is probably fitted to this window
   (as for 77236).
2. **S0, 2022-01-01..2026-10-01, each cell.**
3. **S1, 2019-01-01..2022-01-01:** only for a cell that passes.

**Unit:** USD per trade at the fixed 0.01 lot (virtual stops; as in the 77236 eval).

## Checks (per cell)
- **Gate A (S0):** trades >= 150, PF >= 1.00, net USD > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, t of the mean USD per trade >= 1.65. If history quality is below
  90%, it is inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **R0:** near the author's +2,348.57, if the preset is reconstructed right. RoboForex's 1:500 vs Darwinex's gold margin
  does not matter at 0.01 lot.
- **Before 2026:** a 12 USD brick fitted to 2026 gold (about 4,000+ USD) is about twice as large relative to 2022-23
  gold, so fewer trades and different behaviour, as with 77236.
- **S0:** PF about 0.9-1.2, with 2022-24 near zero.
- **Most likely verdict:** closed (the 2019-21 check, or 2022-24).

## Outcome (2026-10-25; logs `reports/oct24/gds2A.log`, `gds2B.log`): closed
| run (XAUUSD M1, real ticks, 10k, 0.01 lot) | net USD | PF | max DD | trades | win | mean USD (t) | net by year |
|---|---|---|---|---|---|---|---|
| A R0 2026-01..2026-10 (the author's window) | **+1,699.51** | 1.29 | 7.34% | 195 | 55.9% | +8.72 (+1.36) | 26 +1,700 |
| A S0 2022-01..2026-10, hq 100% | **+576.88** | 1.07 | 9.40% | 419 | 47.7% | +1.38 (+0.44) | 22 -15, 23 -47, 24 -116, 25 -177, 26 +933 |
| B S0 2022-01..2026-10, hq 100% | **-3,431.70** | 0.87 | 35.81% | 6,903 | 40.9% | -0.50 (-5.87) | 22 -274, 23 -414, 24 -963, 25 -1,388, 26 -392 |

- **Cell A (the preset) fails Gate A:** 2022-24 is -178.94 USD (2025-26 +755.82), PF 1.07.
  - All the profit is 2026, the author's window: 2022-25 together lost -355 USD.
  - The R0 check came close to the author's figures (+1,700 against +2,349; PF 1.29 against 1.49; 195 trades against
    178), so the preset was reconstructed about right.
- **Cell B (the source defaults) fails Gate A:** every year loses, PF 0.87, with 6,903 trades on the 1 USD brick.
- **Expectation check:**
  - R0 was near the author's, somewhat below.
  - Fewer trades before 2026 for cell A (224 in 2022-25), as expected.
  - S0 PF: A at 1.07 is inside the expected 0.9-1.2; B at 0.87 is below it.
  - 2022-24 near zero for A. Closed, as expected. The same pattern as the author's 77236 (fitted to its window).
- **Removed** per the leftovers rule: `mql5/GDS_Renko_RSI_MACD_EA.mq5`, its profile and the MT5 copies (the source is in
  git at 9bbe9fb).

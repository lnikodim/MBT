# PulseStrike_Scalper_EA on Darwinex EURUSD / USDJPY M1 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/77167". Server: Darwinex-Demo.

**The EA:** "PulseStrike Scalper - Statistical Burst Detection EA" (mql5.com code 77167, RanaAli878 / Ali Rajput,
published 2026-09-09), `PulseStrike_Scalpernew_fix_6.mq5`, 482 lines, MD5 eb984af6….
- **Copied unchanged to:** `mql5/PulseStrike_Scalper_EA.mq5` (renamed per the naming convention).
- **Safety:** no DLL, web or file calls.
- **Logging:** prints on entry, close and errors only, not per tick.
- **Daily reset:** keyed on the calendar date, so it works on Darwinex.

**The author's claim:**
- **Test setup:** "Every tick" modelling (ticks generated from M1) with random delay, M1 chart, 2026-01-01..2026-09-08,
  10,000 start, defaults (momentum mode, z 3.0, 4-second window, TP 0.35 ATR, SL 0.55 ATR).
- **Results:** every major pair profitable, PF 1.16-1.37, 3,756-7,991 trades.
  - EURUSD: +182,740.71, PF 1.30, 5,557 trades, DD 10.3%.
  - USDJPY: +98,592.56, PF 1.37, 7,240 trades, DD 3.5%.
- **The author's own caveat:** in-sample only.

**Why real ticks decide this:** the signal is a z-score of the price change over the last 4 seconds against the last
120 such windows. Generated ticks are a synthetic path inside each M1 bar, so their 4-second moves are artificial. On
real ticks the bursts, the spread at entry and the fills are all real.

**What the code does** (every tick, one position, momentum mode by default):
- **Entry:** a 4-second move with |z| >= 3 opens a trade in the direction of the move (momentum mode).
- **Gates:** spread <= 20 points; TP >= 3 x spread; 5-second cooldown; up to 100 trades a day; no new entries after a
  -3% day.
- **Exits:** TP 0.35 x ATR(14) and SL 0.55 x ATR(14) of the chart timeframe (M1), attached right after the fill.
- **Size:** 0.5% of balance on the SL.

## Runs (`reports/pulse/pulse_eval.py`; Darwinex-Demo, M1, real ticks, 1:100, defaults)
1. **R0, replication of the author's window:** EURUSD and USDJPY (the author's largest profit and best PF), 2026-01-01..
   2026-09-08, 10,000 USD. No execution delay, which is kinder than the author's random delay.
2. **S0, Gate A:** both symbols, 2022-01-01..2026-10-01, 100k.
3. **S1, out of sample, 2019-01-01..2022-01-01:** only for a symbol that passes Gate A.

**Trades:** rebuilt from the Deals table (`scripts/blessing_eval.py` `deals_trades`). The entry order carries no SL (it
is attached after the fill), so R per trade = profit / (0.5% x balance at entry), the EA's own risk unit.

## Checks
- **Gate A (S0, per symbol):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass. Momentum mode only, no input search. Reversion mode would need its own test.
- **Reported:** net USD and R, PF, max DD, trades, win rate, mean R (t), R by year, history quality.

## Expectation (written before the runs)
- **TP size:** an M1 ATR(14) of about 1-2 pips makes TP about 0.4-0.7 pip and SL 0.6-1.1 pip.
- **Costs:** Darwinex commission (about 0.5 pip a round trip) plus slippage take most of each TP. The spread gate does
  not count commission.
- **R0:** far below the author's PF (likely < 1).
- **S0:** PF < 1 on both symbols.
- **Most likely verdict:** closed.

## Outcome (2026-10-24; log `reports/pulse/base.log`): closed, together with ZetaBurst (mql5.com 77220)
| run (M1, real ticks, defaults) | net USD | PF | max DD | trades | win | net R (t) | author (generated ticks, same window) |
|---|---|---|---|---|---|---|---|
| R0 EURUSD 2026-01..09, 10k | -8,428.94 | 0.42 | 84.4% | 918 | 51.2% | -368.4 (-14.32) | +182,740.71, PF 1.30, 5,557 trades |
| R0 USDJPY 2026-01..09, 10k | -8,240.63 | 0.43 | 82.5% | 943 | 50.9% | -345.4 (-12.25) | +98,592.56, PF 1.37, 7,240 trades |
| S0 EURUSD 2022-26, 100k | -99,966.12 | 0.47 | 100% | 4,593 | 54.1% | -1,590.2 (-29.12) | |
| S0 USDJPY 2022-26, 100k | -99,966.78 | 0.40 | 100% | 4,094 | 50.2% | -1,594.6 (-30.72) | |

- **Gate A fails on both symbols.** Both accounts are empty by 2023-24. No S1. Closed.
- **Replication:** the author's own window on real ticks loses 82-84% where the generated-tick test showed +98-183k.
  Real ticks also give about 6-8x fewer bursts. The 4-second moves in generated ticks are artificial, and the
  sub-pip TP does not survive real costs.
- **ZetaBurst (mql5.com 77220, published 2026-09-10 by the same author)** is the identical file (MD5 eb984af6…, 20,309
  bytes). Its page claims USDJPY +252,535.49 and EURUSD +215,509.88 from the same generated-tick setup. Not run
  separately; this outcome covers it.
- **Removed** per the leftovers rule: `mql5/PulseStrike_Scalper_EA.mq5`, its profile and the MT5 copies (the source is
  in git at 497a10f).

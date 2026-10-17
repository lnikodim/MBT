# FZMR_EA: the user's FZMR_Quant_Scalper v6 z-score fade on XAUUSD (pre-registration)

Date: 2026-10-17. User: "I've tried another EA, named FZMR_Quant_Scalper ... Currently, the backtests on XAUUSD 15m from
2025-01-01 show only negative or not so profitable trades. Suggest improvements in the initial logic so that the net
profit is at least 50%." After my diagnosis the user said "yes, run it" to: v6 with the spread cap fixed, buy-only, and
buy-only with a 2-3 R target, on M15 and H1, Darwinex 2022-26, 1-min OHLC.
Source: `MQL5/Experts/Advisors/FZMR_Quant_Scalper.mq5` v6.00 as of 2026-10-17 13:18 (sha256 9f574796d9dc2a3b...),
written by the user with Gemini. Not modified; the port below is a separate file.

## What the user's own runs showed (MetaTester agent log 2026-10-17, Darwinex-Demo, real ticks)
Eight runs, all on older input values that MT5 kept (stop 2.5 ATR, target 2.0 ATR, ER 15 / 0.45, end hour 21, spread
cap 25), not the v6 defaults; the six runs after 12:42 were EURUSD, not XAUUSD. XAUUSD with the exit-at-mean version:
2022-24 1,936 trades, PF 0.94 in R, -43.6 R (1,070 mean exits at +0.42 R, 206 targets at +0.80 R, 660 stops at -1 R);
2025-01..2026-10 355 trades, PF 0.83, -22.3 R, balance -26%. Sells lost in every year (-11.7, -14.5, -18.5, -16.0 R in
2022-25), buys were near flat (-5.2, +5.1, +1.2, -5.1 R). The 25-point spread cap stopped the EA from October 2025
(4-8 trades a month, none after January 2026): Darwinex XAUUSD entry spreads were 22-26 points from October 2025 and
46-89 points (median) in 2026 (MA_Channel Darwinex trade log).

## Hypothesis
A 2-sigma fade on gold M15 earns about +0.5 R when price reverts and loses about -1 R on the third of trades that keep
going; it needs about 65% wins and gets 57-61%. Shorts fight gold's 2022-26 uptrend. Removing sells should bring it near
breakeven, not above. A buy-only dip in an uptrend with a 2-3 R target and no exit at the mean is a pullback-in-trend
system, the kind that works on gold H1 and above (RSI_Reversal, MA_Channel pullback), so the target cells are the only
ones with a real chance, more on H1 than M15. Expected: v6 cells PF 0.85-0.97 (fail), buy-only PF 0.95-1.05 (likely
fail one regime), target cells PF 0.95-1.20 with at most one or two passing Gate A, most likely on H1. If one passes,
the joint rule is the real test: it overlaps with RSI_Reversal and MA_Channel, which are also long-only gold dip-buyers.
Trade count (known before Stage A, from the first self-check run): the v6 defaults trade rarely, 26 trades on XAUUSD
M15 in January-June 2025 (the user's runs traded about 40 a month on the older, looser inputs). Expected 2022-26: about
200-250 trades for M15 v6, roughly half that buy-only, and well under 150 on H1. So the H1 cells, and possibly the
buy-only M15 cells, are likely to fail Gate A on trade count alone. The gate stays at 150 trades.

## EA (`mql5/FZMR_EA.mq5` v1.00, EACore, magic 261019, comment FZMR)
v6 logic unchanged, on the closed bar of `InpTimeframe`: z = (close - SMA(20)) / StdDev(20); Kaufman ER(10) <= 0.40;
buy when z <= -2.0 and RSI(7) < 30 and (trend filter on) EMA 50 > EMA 200, EMA 200 >= its value 3 bars earlier and close
> EMA 200; sell mirrored (z >= 2, RSI > 70, bearish trend); skip when the closed bar's range > 2 x ATR(14); trade only
from server hour 2 to 19 and not in hours 15-16. Stop 2.0 x ATR(14); target 2.5 x ATR(14). One position at a time.
Time exit, checked every tick as in v6: after 24 bars (counted as elapsed time / bar length, as v6 does) close if the
live z is back at or past 0, and close anyway after 34 bars.
Changes from v6, all forced by the test setup or by the cells: EACore execution, CSV trade log and account-wide loss
guards (daily 4%, monthly 12%); risk 1% of balance (v6's extra 0.9 factor dropped; results are judged in R); spread cap
150 points (EACore default, the same as the other four gold EAs; v6's 20-25 points stops it from October 2025), a
spread-blocked bar is skipped as in v6 (`InpSpreadWaitMin 0`). New inputs for the cells: `InpAllowShort` (true = v6) and
`InpTargetR` (0 = v6's ATR target; > 0 = target at that multiple of the stop distance). `FZMR SIGNAL` and `FZMR EXIT`
k=v lines.
Self-check `scripts/fzmr_selfcheck.py`: XAUUSD M15 2025-01..2026-01, 1-min OHLC, guards off. Every signal line satisfies
z, RSI, ER, trend, range and session rules; every entry has its signal line; stop = 2 x ATR and target = 2.5 x ATR of the
signal bar; every expert exit happened at >= 24 bars held with z back at 0 or at >= 34 bars; one position at a time.
Second run with `InpAllowShort=false InpTargetR=2 InpMaxHoldBars=0`: buys only, target = 2 x stop distance, no expert
exits.

## Stage A (`reports/fzmr/stage_a.py`, Darwinex 1-min OHLC, 2022-01-01..2026-10-01, 1% risk)
8 cells on XAUUSD, each on M15 and H1:
- `v6`: both sides, ATR target 2.5, time exit 24 bars.
- `long`: as v6, buys only.
- `long_2r`: buys only, target 2 R, time exit off (`InpMaxHoldBars 0`).
- `long_3r`: buys only, target 3 R, time exit off.
Gate A per cell: trades >= 150, tester PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
Plateau for passers: z threshold 1.75 / 2.25 and stop 1.5 / 2.5 x ATR (target rule unchanged: 2.5 x ATR for v6 and
long, R x stop for the target cells); 4 runs, mean PF >= 1.00 and >= 3 of 4 profitable.
Then stand-alone prop_mc and the joint rule against the account's Darwinex control (MACD v1.45, Donchian v1.01,
RSI_Reversal v1.20, MA_Channel v1.01): joint pass >= control at both 0.3% and 0.5%, p95 DD at 0.5% not more than 1 pt
worse, on 3 seeds. The user's "+50% net profit from 2025" is reported for every cell but is not a gate: one window
and one number can be reached by tuning alone.

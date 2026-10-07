# MACD_Cross_EA without the one-position rule: pre-registration (2026-10-07)

Written before these runs. The user asked to backtest v1.42 without "only one position at a time".

## Variants (test build MACD_Cross_EA_MPX = v1.42 + InpPositionMode)
- 0 = v1.42: a signal is ignored while any own position is open.
- 1 = stack: a signal opens a new position even if positions in the same direction are open; an opposite signal is
  still ignored while a position is open (no hedge).
- 2 = independent: every signal opens its own position, opposite directions included (hedging account).
Everything else is v1.42: 1% risk per position with its own SL 0.5%, TP 3.75%, break-even, trailing; spread guard;
the 4% daily stop closes all own positions; the 12% monthly stop blocks entries.

## Measurement
Real ticks, XAUUSD H1, 2019-01-01 to 2026-10-01, 100k, 1:20, same day. Mode 0 must reproduce today's v1.42 run
(+318,587.14, 1,225 trades). Reported: net R, PF, tester equity drawdown, most positions open at once, prop_mc
(FTMO 2-step; whole trading days resampled) on 2019-26, 2022-26 and 2026.

## Adoption rule (same as the other 2026-10-07 tests)
A variant is adopted only if its prop_mc pass probability is at least v1.42's at 0.3% and 0.5% risk on both
2019-26 and 2022-26 trades, and its 2025-26 net R is not below v1.42's. Higher net R alone is not enough: stacked
positions raise the risk per signal, which prop_mc's daily and max-loss limits price in.

## Amendment (2026-10-07, before any result): window 2022-2026
The user asked to run backtests on recent markets only. Runs: real ticks 2022-01-01 to 2026-10-01. The rule becomes:
prop_mc pass probability at least v1.42's at 0.3% and 0.5% risk on 2022-26 trades, and 2025-26 net R not below
v1.42's. Mode 0 is v1.42 by construction (the change only affects modes 1 and 2).

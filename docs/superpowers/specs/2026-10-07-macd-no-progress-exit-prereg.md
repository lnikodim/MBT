# MACD_Cross_EA no-progress exit: pre-registration (2026-10-07)

Written before any of these settings were run. Goal (user): cut the cost of -1R losers without losing the 3.75% runs.
v1.42 real ticks 2019-26: all 629 losers are full stop-outs; 245 never reached +0.10% (wrong from the start),
250 reached +0.20-0.50% and reversed (earlier locks already rejected: ladder, lock screen, partial TPs).

## Rule under test (test build MACD_Cross_EA_NPX = v1.42 + this exit, off by default)
- Checked once, at the open of the N-th H1 bar after the entry bar. If progress < X% of the open price, the EA
  closes the position at market; otherwise nothing changes (v1.42 stop, break-even, trailing, 3.75% TP).
- Mode 0 "best so far": progress = best profit since entry (M1 bid highs for buys; M1 bid lows + spread for sells).
- Mode 1 "right now": progress = current profit (Bid for buys, Ask for sells) at that bar open.

## Grid
N = 2, 3, 4, 6, 8, 12 bars x X = 0.0, 0.1, 0.2, 0.3% x mode 0 / 1 = 48 settings; baseline = off (N = 0).

## Screen
- MT5 optimizer, 1-minute OHLC, separately on 2019-2021 and 2022-2024, baseline from the same optimization.
- A setting qualifies if, in both periods, its profit factor and net profit are at least the baseline's.
- Plateau: its neighbours (one step along N or X, same mode) average a profit factor no more than 0.03 below the
  baseline's in both periods.
- Finalist: the qualifying plateau setting with the highest smaller-of-the-two PF ratios against the baseline.

## Confirmation (finalist only)
- Real ticks 2019-01 to 2026-10, single run, against the test build with the exit off, run the same day; the off
  run must reproduce v1.42 (+318,587.14, 1,225 trades on 2026-10-07).
- Adopt only if: prop_mc (FTMO 2-step) pass probability is at least the baseline's at 0.3% and 0.5% risk on both
  2019-26 and 2022-26 trades, and its 2025-26 net R (not used in the screen) is not below the baseline's.
- If nothing qualifies, the live exits stay unchanged.

# MACD_Cross_EA partial take-profits: pre-registration (2026-10-07)

Written before any of these settings were run. The user asked to secure profits with three extra take-profits,
TP1 +0.10%, TP2 +0.15%, TP3 +0.20% of the open price, leaving the original 3.75% TP untouched.

## Rule under test (test build MACD_Cross_EA_PTP = v1.42 + partial closes, off by default)
- Each tick, for the open position: when the profit (Bid for buys, Ask for sells) reaches a level, close
  `share` % of the position's initial volume at market (gaps through several levels close them together).
  At least the minimum lot always stays open; partials are skipped when one share is below the minimum lot.
- Everything else is v1.42: SL 0.5%, TP 3.75% on the remainder, break-even +0.5% -> +0.1%, trailing from +1.0%
  at 4 x ATR(14, H1), one position at a time, 1% risk, spread guard, daily/monthly stops.
- The user did not give the share. Main variant: 25% at each level (four equal parts, the last quarter rides to
  3.75%). Shown for context only: 10% each (70% rides) and 33% each (the Position Sizer split on the user's screen).

## Measurement
- Real ticks, XAUUSD H1, 2019-01-01 to 2026-10-01, 100k, 1:20, 1% risk, same day as the baseline.
- Baseline: the test build with partials off. It must reproduce today's v1.42 run (m143_base: +318,587.14,
  1,225 trades) to the cent, which proves the build is v1.42 when off.
- Partial closes are merged per position, so one trade = one position, in R, profit factor and prop_mc.

## Adoption rule (same as the 2026-10-07 profit-lock screen)
Adopt the 25% variant only if prop_mc (FTMO 2-step: 10% / 5% targets, 5% daily, 10% max loss) pass probability for
both phases is at least the baseline's at 0.3% and 0.5% risk on both 2019-26 and 2022-26 trades, and its
2025-26 net R is not below the baseline's. The 10% and 33% runs cannot be adopted on this data (no untouched
period is left to confirm a pick among three). Otherwise the live exits stay unchanged.

## Expectation (before running)
1 R = the 0.5% stop. A trade that reaches +0.20% and then stops out ends at -0.025 R instead of -1 R; a trade that
runs to 3.75% ends near +2.1 R instead of +7.5 R. Expect a much higher win rate, a smaller drawdown and a much
smaller total R; v1.42's edge comes from the few 3.75% runs (2026-10-07: early break-even ladder PF 0.95).

## Outcome (2026-10-07): rejected, live exits unchanged
Real ticks 2019-01 to 2026-10, partial closes merged per position. The baseline reproduced the morning's v1.42 run to
the cent (+318,587.14, 1,225 trades).

| | net R | PF (R) | win % | max DD R | 2025-26 R | pass 2019-26 @0.3 / 0.5 | pass 2022-26 @0.3 / 0.5 |
|---|---|---|---|---|---|---|---|
| v1.42 | +163.3 | 1.26 | 48.4 | 38.2 | +129.2 | 29.0 / 53.6% | 60.3 / 78.4% |
| 25% (rule under test) | +3.7 | 1.01 | 51.3 | 31.7 | +20.8 | 0.0 / 1.4% | 0.2 / 6.9% |
| 10% (context) | +100.9 | 1.20 | 49.8 | 31.7 | +87.9 | 11.5 / 35.1% | 33.8 / 63.6% |
| 33% (context) | -45.8 | 0.85 | 69.2 | 51.2 | -12.5 | 0.0 / 0.0% | 0.0 / 0.0% |

The 25% variant fails every part of the adoption rule. Stand-alone, a deal with the same entry and stop and a
+0.10 / +0.15 / +0.20% target hits 80.0 / 73.1 / 68.0% of the time but needs 83.7 / 77.2 / 71.6% to break even
(-59.9 / -59.7 / -44.1 R over 2019-26), so splitting or adding such deals only removes edge.
Test build and runner archived in reports/macd_ptp/ (git-ignored); to rerun, re-add a MACD_Cross_EA_PTP profile
(MACD_Cross_EA + InpPartialTP1/2/3Pct, InpPartialSharePct) and compile that source into MT5.

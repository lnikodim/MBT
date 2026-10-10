# MACD_Cross_EA without the trailing stop: pre-registration (2026-10-10)

Written before these runs. The user asked whether the trailing stop (from +1.0% profit, 4 x ATR(14, H1) behind the
price) is useful at all. InpTrailStartPct = 0 switches it off; exits are then the 0.5% stop, the break-even stop
(+0.1% once +0.5% is reached) and the 3.75% target.

## Runs (real ticks, XAUUSD H1, 2022-01-01 to 2026-10-01, 100k, 1% risk, v1.44 defaults otherwise)
- base: today's v1.44 run (21:22, +925,001.21, 1,014 trades), same day so swap rates match.
- trail_off: InpTrailStartPct 0.
- trail_off_be_off (context only, not for adoption): InpTrailStartPct 0 and InpBreakEvenPct 0, i.e. pure stop / target.

## Adoption rule (same as the other October tests)
Switch the trailing stop off only if trail_off's prop_mc (FTMO 2-step) pass probability on 2022-26 trades is at
least the base's at 0.3% and 0.5% risk, and its 2025-26 net R is not below the base's.

## Expectation (before running)
Unclear. The trail converts some 3.75% runs that reverse into +1-2 R exits (good) but also cuts some runs short
before the target (bad). The 2026-10-07 lock screen showed the live exits are near a plateau.

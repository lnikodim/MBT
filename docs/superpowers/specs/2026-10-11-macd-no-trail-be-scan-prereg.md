# MACD_Cross_EA trailing off + break-even 0.25 / 0.30 / 0.35 / 0.40%: pre-registration (2026-10-11)

Written before these runs. Follow-up to 2026-10-10-macd-no-trail-prereg.md (trailing off + BE 0.5% = +332.6 R, a
near-miss at 0.5% risk; trailing off + BE 0.2% rejected). The user asked for the levels in between.

## Runs (real ticks, XAUUSD H1, 2022-01-01 to 2026-10-01, 100k, 1% risk, v1.44 defaults otherwise)
- base (v1.44) and trail_off (InpTrailStartPct 0, BE 0.5%) rerun today (swap drift).
- be025 / be030 / be035 / be040: InpTrailStartPct 0, InpBreakEvenPct 0.25 / 0.30 / 0.35 / 0.40, InpBreakEvenLockPct 0.1.

## Rule
A level is adoptable only if its prop_mc (FTMO 2-step) pass probability on 2022-26 is at least base's at 0.3% and
0.5% risk and its 2025-26 net R is at least base's, AND its two neighbouring levels (one step up and down on the
0.25-0.5 ladder) are not both below base on the same conditions (no lone spike). Otherwise nothing changes.

## Expectation
Monotone: the earlier the break-even, the fewer 3.75% runs survive (0.2%: 35 TPs; 0.5%: 103). 0.40% may come close
to 0.5%; 0.25-0.30 should fail.

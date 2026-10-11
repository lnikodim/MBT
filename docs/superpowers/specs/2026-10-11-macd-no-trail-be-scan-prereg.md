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

## Outcome (2026-10-11): no level passes; the ladder is monotone, later break-even = better
Real ticks 2022-01 to 2026-10, 100k, 1% risk; base and trail_off reproduced 2026-10-10 to the cent.

| trailing off, BE at | trades | win % | PF (R) | net R | max DD R | TPs | 2025-26 R | pass @0.3 / 0.5 | breach @0.5 | tester net / eq DD |
|---|---|---|---|---|---|---|---|---|---|---|
| base (trail on, BE 0.5%) | 1,013 | 51.3 | 1.52 | +262.1 | 24.7 | 42 | +182.6 | 76.6 / 82.9% | 6.3% | +925,001 / 24.9% |
| 0.25% | 1,030 | 63.6 | 1.41 | +145.0 | 45.2 | 54 | +118.0 | 45.5 / 63.6% | 10.6% | +226,276 / 40.1% |
| 0.30% | 1,016 | 60.1 | 1.51 | +199.6 | 43.9 | 67 | +160.5 | 60.6 / 72.1% | 9.9% | +439,973 / 39.8% |
| 0.35% | 1,011 | 56.8 | 1.52 | +217.9 | 41.1 | 75 | +177.9 | 65.2 / 74.6% | 10.3% | +527,844 / 39.0% |
| 0.40% | 993 | 54.6 | 1.63 | +272.7 | 24.3 | 85 | +193.3 | 75.5 / 80.2% | 8.5% | +921,716 / 28.1% |
| 0.50% (= trail_off) | 955 | 47.0 | 1.69 | +332.6 | 28.5 | 103 | +222.8 | 83.7 / 82.6% | 8.6% | +1,584,391 / 29.5% |

- 0.40% is the only level above base on net R and 2025-26, but its pass probability is below base at both risks
  (75.5 / 80.2 vs 76.6 / 82.9): not adoptable. 0.25-0.35% fail everything and 2022 turns negative.
- Every step later in the break-even adds target runs (54 -> 67 -> 75 -> 85 -> 103) and net R; 0.5% remains the best
  of the scanned levels with trailing off. Nothing changes on the Mac or the VPS.

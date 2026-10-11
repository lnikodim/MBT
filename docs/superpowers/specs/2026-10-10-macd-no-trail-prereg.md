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

## Outcome (2026-10-10): narrow fail by the rule (0.5% risk), clear gain at 0.3%; decision left to the user
Real ticks 2022-01 to 2026-10, 100k, 1% risk, v1.44, same-day baseline.

| | trades | win % | PF (R) | net R | max DD R | TPs | avg win R | 2025-26 R | pass @0.3 / 0.5 | breach @0.5 | tester net / eq DD |
|---|---|---|---|---|---|---|---|---|---|---|---|
| base (trail on) | 1,013 | 51.3 | 1.52 | +262.1 | 24.7 | 42 | +1.47 | +182.6 | 76.6 / 82.9% | 6.3% | +925,001 / 24.9% |
| trail off | 955 | 47.0 | 1.69 | +332.6 | 28.5 | 103 | +1.82 | +222.8 | 83.7 / 82.6% | 8.6% | +1,584,391 / 29.5% |
| trail + BE off (context) | 819 | 17.8 | 1.47 | +334.1 | 37.2 | 143 | +7.12 | +241.0 | 77.4 / 67.1% | 19.8% | +1,197,338 / 42.0% |

- Rule: pass @0.3 83.7 >= 76.6 (yes), 2025-26 +222.8 >= +182.6 (yes), pass @0.5 82.6 >= 82.9 (no, by 0.3 points).
  Re-estimated with 40,000 sims x 3 seeds: base 82.4-82.6%, trail off 82.1-82.4% at 0.5% (consistent -0.2 points);
  at 0.3% base 75.9-76.2% vs trail off 83.4-83.7%. Breach @0.5% 6.7-7.1% vs 8.8-9.0%; MC p95 DD 16.0% vs 18.3%.
- Interpretation: the trail cut 61 of 103 target runs short (42 TPs with it on); removing it adds +70 R and improves
  every year but 2022 (+19 vs +23) and 2026 (+89 vs +92), at the price of a deeper drawdown (28.5 vs 24.7 R). By the
  letter of the rule it is not adopted; the user decides. Break-even is clearly useful (context row: breach 19.8%).
- Not yet run: the 2019-21 chop check and a VPS/real-tick replay of the live rule with trailing off at 0.3% risk.

## Follow-up pre-registration (2026-10-10, before the runs): trailing off + break-even at +0.2%
User question. Runs (same window, same day): trail_off_be02_lock01 (InpTrailStartPct 0, InpBreakEvenPct 0.2,
InpBreakEvenLockPct 0.1) and trail_off_be02_lock0 (lock 0.0). Compared with today's base and trail_off runs.
Adoption rule unchanged (pass @0.3 and @0.5 >= base, 2025-26 net R >= base). Expectation: the +0.2% break-even stops
out runs that dip back after a small gain (as every earlier break-even before +0.5% did), so lower net R than trail_off.

## Follow-up outcome (2026-10-10): trailing off + break-even 0.2% rejected
| | trades | win % | PF (R) | net R | max DD R | TPs | 2025-26 R | pass @0.3 / 0.5 | breach @0.5 | tester net / eq DD |
|---|---|---|---|---|---|---|---|---|---|---|
| base | 1,013 | 51.3 | 1.52 | +262.1 | 24.7 | 42 | +182.6 | 76.6 / 82.9% | 6.3% | +925,001 / 24.9% |
| trail off | 955 | 47.0 | 1.69 | +332.6 | 28.5 | 103 | +222.8 | 83.7 / 82.6% | 8.6% | +1,584,391 / 29.5% |
| trail off + BE 0.2% / +0.1% | 1,048 | 69.4 | 1.23 | +70.8 | 26.3 | 35 | +55.3 | 18.9 / 39.9% | 13.3% | +73,280 / 27.8% |
| trail off + BE 0.2% / 0.0% | 1,022 | 16.7 | 1.54 | +181.1 | 43.9 | 70 | +164.1 | 57.3 / 70.1% | 10.0% | +362,414 / 38.4% |
Both fail every condition. The +0.2% break-even stops out the runs that dip back after a small gain: TPs 103 -> 35 / 70,
2022 turns negative, and the drawdown does not improve (26.3 / 43.9 R vs 28.5). Exact-entry stops count as tiny
losses (17% win rate).

## Chop-check pre-registration (2026-10-11, before the runs): trailing off on 2019-2021
Runs (real ticks 2019-01-01 to 2022-01-01, 100k, 1% risk): chop_base (v1.44 defaults) and chop_trail_off
(InpTrailStartPct 0), same day. Rule (as for the 2026-10-07 stacking check): trailing off is cleared for a v1.45
only if its 2019-21 net R is at least chop_base's and its 2019-21 max drawdown in R is no more than 1.25 x
chop_base's. prop_mc on 2019-21 is reported for context (the regime is a known loser for this EA).

## Chop-check outcome (2026-10-11): trailing off FAILS on 2019-2021; the trailing stop stays on
| 2019-21, real ticks, 1% | trades | win % | PF (R) | net R | max DD R | TPs | pass @0.3 / 0.5 | breach @0.5 | by year | tester net / eq DD |
|---|---|---|---|---|---|---|---|---|---|---|
| chop_base (v1.44) | 636 | 46.1 | 1.05 | +15.6 | 35.6 | 17 | 17.7 / 30.1% | 40.3% | -3 / +24 / -6 | +6,534 / 32.6% |
| chop_trail_off | 598 | 41.5 | 0.95 | -15.4 | 52.4 | 39 | 11.8 / 22.0% | 52.3% | -37 / +46 / -25 | -24,185 / 48.0% |
- Rule: net R -15.4 < +15.6 (fail); max DD 52.4 > 1.25 x 35.6 = 44.5 R (fail). Not cleared.
- The trail earns its keep in sideways years: 2019 -37 vs -3 R and 2021 -25 vs -6 R without it, while in the 2020
  trend it costs (+46 vs +24). Over 2019-26 combined: trail on +277.7 R vs trail off +317.2 R, but with a 52 R
  drawdown in the chop and a 48% tester drawdown. Live exits (BE +0.5% / +0.1%, trail from +1% at 4 x ATR) unchanged.

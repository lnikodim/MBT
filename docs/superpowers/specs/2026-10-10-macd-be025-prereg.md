# MACD_Cross_EA earlier break-even (100 pips ≈ 0.25%): pre-registration (2026-10-10)

Written before these runs. The user asked to move the stop to break-even every time the profit reaches 100 pips.
On Darwinex XAUUSD 1 pip = 0.10 USD, so 100 pips = 10 USD = 0.25% at today's price (~4,100). The EA's break-even is a
percent of the open price, so the test uses 0.25% (a fixed 100 pips would have been 0.56% at 1,800 in 2022, i.e.
later than today's +0.5% rule). Live v1.44: break-even at +0.5% locking +0.1%.

## Runs (real ticks, XAUUSD H1, 2022-01-01 to 2026-10-01, 100k, 1% risk, v1.44 defaults otherwise)
- base: v1.44 defaults, rerun the same day (tester swap rates drift between days).
- be025_lock01: InpBreakEvenPct 0.25, InpBreakEvenLockPct 0.1 (stop to entry +0.1%, as the live rule does at +0.5%).
- be025_lock0: InpBreakEvenPct 0.25, InpBreakEvenLockPct 0.0 (stop exactly to the entry price).

## Adoption rule (same as the other October tests)
Adopt a variant only if its prop_mc (FTMO 2-step) pass probability on 2022-26 trades is at least the base's at 0.3%
and 0.5% risk, and its 2025-26 net R is not below the base's.

## Expectation (before running)
The 0.3/0.4/0.5% ladder (2026-10-07) and the lock screen showed that break-evens before +0.5% stop out trades that
later run to the 3.75% target. Expect fewer TPs, a higher win rate and a lower net R.

## Amendment (2026-10-10, before any run): 1500 pips instead of 100
The user replaced 100 pips with 1500. Read as MT5 points (0.01 USD on Darwinex XAUUSD, the unit the Position Sizer
calls points): 1500 = 15 USD = 0.37% at today's price (~4,100); 15 USD was 0.83% at 1,800 in 2022, later than the
live +0.5%. Read as 0.10-USD pips it would be 150 USD = 3.66%, where the 4xATR trail from +1% already holds the stop
far above entry +0.1%, so that reading changes nothing against v1.44 and is not run. The 0.25% runs are dropped.
Runs: base, be037_lock01 (0.37% / +0.1%), be037_lock0 (0.37% / 0.0%). Adoption rule unchanged.

## Outcome (2026-10-10): rejected, live break-even (+0.5% / +0.1%) unchanged
Real ticks 2022-01 to 2026-10, 100k, 1% risk, v1.44, same-day baseline (+925,001.21, 1,014 trades).

| | trades | win % | PF (R) | net R | max DD R | TPs | 2025-26 R | pass @0.3 / 0.5 | breach @0.5 | tester net / eq DD |
|---|---|---|---|---|---|---|---|---|---|---|
| base (BE +0.5% / +0.1%) | 1,013 | 51.3 | 1.52 | +262.1 | 24.7 | 42 | +182.6 | 76.6 / 82.9% | 6.3% | +925,001 / 24.9% |
| BE +0.37% / +0.1% | 1,033 | 59.4 | 1.49 | +210.0 | 19.5 | 33 | +155.4 | 65.5 / 80.0% | 5.5% | +558,388 / 22.0% |
| BE +0.37% / 0.0% | 1,023 | 29.4 | 1.54 | +238.4 | 19.4 | 39 | +185.6 | 72.2 / 81.2% | 6.2% | +738,914 / 22.1% |

- Both fail the pass-probability condition at 0.3% and 0.5%. The exact-entry variant passes the 2025-26 condition
  (+185.6 vs +182.6) and has a slightly higher PF but a lower net R; its 29% win rate is stops at entry counted as
  small losses (spread and commission).
- The earlier break-even costs 3-9 of the 42 runs to the 3.75% target; the drawdown improves only from 24.7 to 19.4 R.

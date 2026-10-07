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

## Outcome (2026-10-07): both variants pass the rule on 2022-26; not deployed (user decision pending)
Real ticks 2022-01 to 2026-10, 100k, 1% risk. Mode 0 reproduced the morning's v1.42 2022-26 run to the cent
(+414,417.70, 754 trades).

| | trades | PF (R) | net R | max DD R | most open | 2025-26 R | pass 2022-26 @0.3 / 0.5 | breach @0.5 | tester net / equity DD |
|---|---|---|---|---|---|---|---|---|---|
| v1.42 | 753 | 1.47 | +178.3 | 18.6 | 1 | +129.9 | 58.9 / 78.1% | 3.9% | +414,418 / 18.1% |
| stack | 1,040 | 1.53 | +271.2 | 24.7 | 7 | +184.6 | 77.2 / 82.4% | 6.9% | +998,174 / 24.9% |
| independent | 1,057 | 1.52 | +271.5 | 25.8 | 7 | +185.8 | 76.8 / 81.5% | 7.4% | +1,000,571 / 25.8% |

- Not just more risk: at an equal MC p95 drawdown (~10%) stacking at 0.3% passes 77.1% vs v1.42 at 0.3% 58.5%;
  at equal breach (~1-1.6%/phase) stack 0.3% 77.1% vs v1.42 0.4% 72.8%. Phase 1 median 152 vs 203 days at 0.3%.
- Hedging adds nothing over stacking (17 more trades, same R).
- Open caveats: 2022-26 is a trend regime (stacking pyramids into trends; untested on the 2019-21 chop), and
  prop_mc counts closed trades only while firms measure daily loss on equity with up to 7 positions open.
- Test build archived in reports/macd_mpx/ (git-ignored). The canonical EA and the VPS stay v1.42.

## Follow-up pre-registration (2026-10-07, before these runs): chop check and position cap
User approved a one-off 2019-2021 check and a cap on open positions (InpMaxPositions, 0 = none) for stacking (mode 1).
- Runs (real ticks): 2019-01-01 to 2022-01-01: v1.42, stack, stack cap 3, stack cap 4. 2022-01-01 to 2026-10-01:
  stack cap 3, stack cap 4 (v1.42 and uncapped stack from the runs above).
- Chop check: stacking (in the chosen cap form) is cleared for a v1.43 only if its 2019-21 net R is at least v1.42's
  2019-21 net R and its 2019-21 max drawdown in R is no more than 1.25 x v1.42's.
- Cap choice: the smallest of cap 3, cap 4, none whose 2022-26 prop_mc pass probability at 0.3% and 0.5% risk is
  within 2 points of the uncapped stack's and which passes the chop check.

## Follow-up outcome (2026-10-07): stacking with a 3-position cap is cleared for a v1.43
| | 2019-21 net R | 2019-21 max DD R | 2019-21 most open | 2022-26 net R | 2022-26 pass @0.3 / 0.5 | 2022-26 breach @0.5 |
|---|---|---|---|---|---|---|
| v1.42 | -15.4 | 34.5 | 1 | +178.3 | 58.9 / 78.1% | 3.9% |
| stack | +59.6 | 36.4 | 12 | +271.2 | 77.2 / 82.4% | 6.9% |
| stack cap 4 | +23.4 | 36.4 | 4 | +275.3 | 78.1 / 82.6% | 7.0% |
| stack cap 3 | +15.0 | 35.6 | 3 | +261.8 | 76.6 / 82.8% | 6.4% |
- Chop check (net R >= -15.4, max DD <= 43.1 R): all three stacking variants pass.
- Cap choice: cap 3 is within 2 points of the uncapped stack at 0.3% (76.6 vs 77.2) and 0.5% (82.8 vs 82.4) -> cap 3.
- Noted, not part of the rule: in 2019-21 the cap costs 45 R against uncapped stacking (+15.0 vs +59.6), but uncapped
  stacking reached 12 open positions there (6% open risk at 0.5%/trade, beyond a 5% equity daily limit that prop_mc
  cannot see); the cap bounds that.
- Tester (real ticks, 100k, 1%): 2019-21 +6,306 / 32.6% DD (v1.42 -17,284 / 32.8%); 2022-26 +921,320 / 24.9% DD
  (v1.42 +414,418 / 18.1%).

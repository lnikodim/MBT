# MACD_Cross_EA "conservative": close at +0.2% profit — pre-registration (2026-10-08)

Written before these runs. The user asked for a more conservative MACD EA: same rules, but close the trade once the
profit reaches +0.2% of the price. That is InpTakeProfitPct = 0.2 on the existing EA (no new EA); break-even (+0.5%)
and trailing (+1%) can then never trigger.

Prior evidence (2026-10-07, v1.42 entries): a +0.2% target with the 0.5% stop hit 68.0% of the time against a 71.6%
break-even rate (-44.1 R over 2019-26). Expectation: negative or near zero.

## Runs (real ticks, XAUUSD H1, 2022-01-01 to 2026-10-01, 100k, 1% risk, v1.44 otherwise)
- tp02_cap3: InpTakeProfitPct = 0.2, InpMaxPositions = 3 (live stacking).
- tp02_cap1: InpTakeProfitPct = 0.2, InpMaxPositions = 1 (one position at a time, the original rule).
Baseline: v1.44 defaults on 2022-26 (2026-10-07 run: +921,320.09, 1,014 trades, +261.8 R, prop_mc pass 76.6 / 82.8%).

## Adoption rule
Adopt a variant only if its prop_mc (FTMO 2-step) pass probability on 2022-26 trades is at least the baseline's at
0.3% and 0.5% risk, and its 2025-26 net R is not below the baseline's. Win rate alone does not count.

## Amendment (2026-10-08, before any result): a second instance on H2, in parallel with the live H1 EA
The user's design: keep the live v1.44 H1 EA and run a second, conservative copy in another terminal on H2 with the
+0.2% target. The H1 runs above were stopped before finishing and are dropped.
- Runs (real ticks 2022-01-01 to 2026-10-01, chart H2, InpTimeframe = H2, InpMagic = 240818, 1% risk):
  h2_tp02_cap1 (TP 0.2%, one position), h2_tp02_cap3 (TP 0.2%, up to 3), h2_base (v1.44 defaults on H2, context only).
- Combined = the live v1.44 H1 trades (2026-10-07 run) merged with the H2 trades, as if both trade one account.
- Adopt an H2 +0.2% instance only if (a) alone it has net R > 0 and PF > 1.0 on 2022-26, and (b) combined with H1 its
  prop_mc pass probability is at least v1.44 alone's (76.6 / 82.8% at 0.3 / 0.5% risk) and its 2025-26 net R is at
  least v1.44 alone's. Breach probabilities are reported alongside.

## Outcome (2026-10-08): rejected — the H2 +0.2% instance adds almost nothing
| 2022-26, real ticks | trades | win % | PF (R) | net R | max DD R | 2025-26 R | pass @0.3 / 0.5 | breach @0.3 / 0.5 |
|---|---|---|---|---|---|---|---|---|
| H1 v1.44 alone (live) | 1,013 | 50.9 | 1.52 | +261.8 | 24.7 | +182.3 | 76.6 / 82.8% | 0.9 / 6.4% |
| H2 +0.2%, one position, alone | 532 | 73.3 | 1.07 | +10.2 | 8.3 | +5.5 | 0.0 / 0.1% | 0.0 / 0.1% |
| H1 + H2 +0.2% one position | 1,545 | 58.6 | 1.42 | +271.9 | 29.5 | +187.8 | 78.3 / 82.0% | 1.2 / 7.8% |
| H1 + H2 +0.2% up to 3 | 1,552 | 58.7 | 1.42 | +272.1 | 29.5 | +188.6 | 78.5 / 81.6% | 1.3 / 7.9% |
| H2 v1.44 defaults alone (context) | 534 | 52.2 | 1.13 | +34.2 | 23.8 | +34.0 | 7.4 / 24.1% | 1.4 / 13.8% |
| H1 + H2 v1.44 defaults (context) | 1,547 | 51.4 | 1.39 | +296.0 | 43.4 | +216.3 | 75.4 / 68.4% | 5.8 / 17.7% |
- (a) passes: the H2 +0.2% instance is barely profitable alone (+10 R in 4.75 years, PF 1.07, 73% wins vs 71.4% needed).
- (b) fails at 0.5% risk: combined pass 82.0 / 81.6% < 82.8%; at 0.3% +1.7 to +1.9 points; breach rises at both risks
  and the combined max drawdown grows from 24.7 to 29.5 R. +0.02 R per trade is too thin to survive live costs.
- Tester (100k, 1%): H2 +0.2% +9,445 / 8.8% DD (one position), +9,582 / 9.0% (up to 3); H2 defaults +32,738 / 27.2%.

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

# Geraked 3MACD on EURUSD H1, grid lot cap of 1.2 lots: pre-registration (2026-10-27), Phase 1 of the drawdown plan

**Why.** Phase 0 (`reports/oct25/3macd_frontier.py`, offline, no tester runs, 2022-26 continuous cycles) found that a total-lot cap is the only mechanism that improves return per unit of drawdown. Equity stops and smaller later legs both cost more profit than they save. With the rule the EA can implement (a grid leg is added only while the open lots are below the cap), a 1.2-lot cap models at a 14.5% drawdown, 15.7% a year and PF 2.80 on Gate B. The model keeps the original exit price after legs are skipped, so it is optimistic. This run tests it in the tester.

**Build.** The default 3MACD source (`Experts/3MACD.mq5`, Geraked), with exactly these changes:
1. A new input, `GridLotCap` = 1.2 (under "Strategy: Grid"): no new grid leg while the open lots are at or above this value. 0 turns the cap off.
2. A function, `OpenLots()`: the sum of volumes of open positions with this magic number on this symbol.
3. In `OnTimer`, `CheckForGrid()` runs only when `GridLotCap <= 0 || OpenLots() < GridLotCap`.

Nothing else changes: signal, reverse inversion, exits, sizing, and all other inputs stay as the author wrote them. The build compiles with 0 errors and 0 warnings. The scan finds no DLL, network or file access.

**Setup.** Darwinex-Demo, EURUSD H1, real ticks, $10,000 deposit, 1:100. Default inputs except `GridLotCap`. Gate A: 2024-01 to 2026-10. Gate B: 2022-01 to 2026-10 as one continuous run. Gate C: 2019-01 to 2021-12. Bar checks as before (17,100 / 29,580 / 18,700, 8% tolerance).

**Model prediction, recorded before the run.** Gate B: drawdown 14.5%, PF 2.80, return 15.7% a year, net 2022-24 +5,465 USD and 2025-26 +1,973 USD. The model is optimistic about the exit price, so the tester result is expected to come out worse.

**Metrics.** Annual return = (Gate B net USD / 10,000) / 4.75 years. Drawdown = the Gate B maximum equity drawdown as reported by the tester.

**Decision rule (fixed before the run).**
1. The gates: Gates A, B (continuous) and C must all pass, with the floors in `docs/gates.md` (Gate B trades at least 150).
2. Drawdown on Gate B:
   - At or below 8%: the drawdown target is met. If the annual return is at least 10%, the variant is a candidate for the portfolio add-on test, which is a separate spec. If it is below 10%, it is not a standalone candidate, and the result is reported.
   - Above 8% and up to 15%: partial. Sizing (Phase 2) is needed. It is a separate spec, and it scales the risk until the Gate B drawdown reaches 8%, then checks the annual return in the tester, not by a linear estimate.
   - Above 15%: rejected as a drawdown fix, as the earlier spec rule requires.
3. Model check: if the tester's Gate B drawdown differs from the predicted 14.5% by more than 5 points, the Phase 0 model is withdrawn as unreliable, whatever the result above.
4. Any gate failure: rejected.

**Not in this spec:** other cap values, sizing, equity stops (dropped after Phase 0), other shrink rules, exit changes, other symbols or timeframes, and the live account.

**Commit status:** uncommitted, like the other specs.

**Leftovers.** After the verdict: the build folder, the tester `.set` files and the temporary `ea_profiles.py` entries are removed. The `EAUtils` and `errordescription` copies and the scratch downloads stay. The spec, runner, logs and outcome stay.

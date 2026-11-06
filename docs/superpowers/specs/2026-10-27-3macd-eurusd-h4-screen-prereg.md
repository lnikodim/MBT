# Geraked 3MACD on EURUSD H4, with the recommended settings: pre-registration (2026-10-27)

**Why.** The user asked to test 3MACD on EURUSD H4, the same test as on GBPUSD M15, with another timeframe on the instrument of the EURUSD H1 candidate. The author's recommended inputs equal the source defaults, so the run uses the EA's own defaults. The GBPUSD M15 run was inconclusive because of the history gaps, so the same bar check applies here before any decision.

**Question.** Does 3MACD on EURUSD H4, with the recommended inputs, pass Gates A, B (one continuous 2022-26 run) and C?

**Source and settings.** `Experts/3MACD.mq5` (Geraked), unchanged. The author's recommended `.set` matches the source defaults field by field, so the run uses `{}`. The build compiles with 0 errors and 0 warnings. The scan finds no DLL, network or file access.

**Setup.** Darwinex-Demo, EURUSD H4, real ticks, $10,000 deposit, 1:100. The chart timeframe is H4, since the EA's MACD reads the chart's timeframe. Gate A: 2024-01 to 2026-10. Gate B: 2022-01 to 2026-10 as one continuous run (stateful grid, as in `docs/gates.md`). Gate C: 2019-01 to 2021-12.

**Data check (fixed before the run).** H4 bar counts are expected to be one quarter of the EURUSD H1 counts used in the other screens: 2024-26 about 4,275; 2022-26 about 7,395; 2019-21 about 4,675. A window more than 8% off is **inconclusive**, not a pass or a fail, and no verdict is written for it.

**Decision rule (fixed before the run).**
1. The EA passes if Gates A, B (continuous) and C all pass, with their floors as in `docs/gates.md`. The Gate B trade floor is 150 trades, which is a hard floor for a slow timeframe, so a result below it is reported, not passed.
2. Any window that fails the bar check is inconclusive, and the decision is withheld.
3. Drawdown: if the EA passes all three and its Gate B drawdown is above 8%, one loss-limiting variant is run. It is named now: the grid lot cap of 1.2 lots (`GridLotCap`, the same build tested on EURUSD H1). The default and the variant are reported side by side. Under the earlier rule, a variant with a Gate B drawdown of 15% or more is rejected as a drawdown fix.
4. One instrument, so the two-rejects rule does not apply.

**Not in this spec:** other timeframes, other instruments, the add-on test (its own spec, written only if this run passes), and the live account.

**Commit status:** uncommitted, like the other specs.

**Leftovers.** After the verdict: the build folder, the tester `.set` file and the temporary `ea_profiles.py` entry are removed. The `EAUtils` and `errordescription` copies and the scratch downloads stay. The spec, runner, logs and outcome stay.

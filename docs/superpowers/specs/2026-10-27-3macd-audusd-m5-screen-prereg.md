# Geraked 3MACD on AUDUSD M5 (the author's instrument and timeframe), with the recommended settings: pre-registration (2026-10-27)

**Why.** The user asked to test 3MACD on AUDUSD M5. This is the instrument and timeframe of the author's own recommended report (`Test/3MACD/README.md`, `3MACD-AUDUSD-5M-Inputs.set`). The EURUSD H1 candidate is a separate test and is not affected by this run.

**Question.** Does 3MACD on AUDUSD M5, with the author's recommended inputs, pass Gates A, B (one continuous 2022-26 run) and C?

**Source and settings.** `Experts/3MACD.mq5` (Geraked), unchanged. The author's recommended `.set` matches the source defaults field by field, so the run uses the EA's own defaults (`{}`), as in the EURUSD tests. The build compiles with 0 errors and 0 warnings. The scan finds no DLL, network or file access.

**Setup.** Darwinex-Demo, AUDUSD M5, real ticks, $10,000 deposit, 1:100. The chart timeframe is M5, since the EA's MACD reads the chart's timeframe. Gate A: 2024-01 to 2026-10. Gate B: 2022-01 to 2026-10 as one continuous run (stateful grid, as in `docs/gates.md`). Gate C: 2019-01 to 2021-12.

**Data check (fixed before the run).** M5 bar counts are expected to be 12 times the EURUSD H1 counts used in the other screens: 2024-26 about 205,200; 2022-26 about 354,960; 2019-21 about 224,400. A window more than 8% off is **inconclusive**, not a pass or a fail. An earlier AUDUSD M5 replication on the author's window counted 88,565 bars against about 192,747 expected, and the cause was not resolved. That is why this check is applied before any decision. If a window fails the check, no verdict is written for it.

**Reference (not gated).** The author's report on 2021-02-22 to 2023-09-26 (`Test/3MACD/report.xlsx`, `README.md`) is the benchmark for the replication. Its figures are reported next to ours, not used as a gate.

**Decision rule (fixed before the run).**
1. The EA passes if Gates A, B (continuous) and C all pass, with their floors as in `docs/gates.md`.
2. Any window that fails the bar check is inconclusive, and the decision is withheld.
3. Drawdown: if the EA passes all three and its Gate B drawdown is above 8%, one loss-limiting variant is run. It is named now: the grid lot cap of 1.2 lots (`GridLotCap`, the same build tested on EURUSD). The default and the variant are reported side by side. Under the earlier rule, a variant with a Gate B drawdown of 15% or more is rejected as a drawdown fix.
4. One instrument, so the two-rejects rule does not apply.

**Not in this spec:** EURUSD H1 (its own candidate, already tested), other timeframes, other instruments, the add-on test (its own spec, written only if this run passes), and the live account.

**Commit status:** uncommitted, like the other specs.

**Leftovers.** After the verdict: the build folder, the tester `.set` file and the temporary `ea_profiles.py` entry are removed. The `EAUtils` and `errordescription` copies and the scratch downloads stay. The spec, runner, logs and outcome stay.

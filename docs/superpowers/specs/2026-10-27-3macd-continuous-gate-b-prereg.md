# Geraked 3MACD on EURUSD H1 with the author's recommended inputs, continuous Gate B: pre-registration (2026-10-27)

**Why this run.** The user chose option 1 from the Geraked review: 3MACD on EURUSD H1 with the author's recommended settings. The earlier screen (source defaults) judged Gate B on joined 2022-23 runs. `docs/gates.md` requires one continuous 2022-26 run for a stateful EA (an open grid), and 3MACD is one. This run redoes Gates A, B and C on that basis. The earlier screen figures stay on record as the joined-method results.

**Source.** `Experts/3MACD.mq5` from https://github.com/geraked/metatrader5 (316 lines), with `Include/EAUtils.mqh` (2,082 lines) and `Include/errordescription.mqh` (225 lines). Scan: no `#import`, DLL, `WebRequest` or file access. The news feature uses MT5's built-in calendar, and News is off. Build: compiled from the source with 0 errors and 0 warnings. The repo's prebuilt `.ex5` was not used.

**Recommended settings.** The author's test folder (`Test/3MACD`) contains `3MACD-AUDUSD-5M-Inputs.set`. Every input in that file equals the source default, checked field by field. The recommended settings therefore run as the EA's defaults (no `.set` override).

**Instrument.** The author's report (`Test/3MACD/README.md`) is AUDUSD on M5, 2021-02-22 to 2023-09-26. This run is EURUSD H1, the instrument and timeframe of the earlier candidate. The AUDUSD M5 replication is not part of this spec, and its bar-count question is still open.

**Question.** Does 3MACD on EURUSD H1, with the recommended inputs, pass Gates A, B (one continuous 2022-26 run) and C?

**Setup.** Darwinex-Demo, EURUSD H1, real ticks, $10,000 deposit, 1:100. Risk 0.5% of balance per trade (input default), grid on with 50 levels, equity drawdown limit off, margin limit 300%, spread limit off. Gate A is 2024-01 to 2026-10. Gate B is 2022-01 to 2026-10 as one run, with the trade floor and the net and PF checks as `docs/gates.md` sets them. Gate C is 2019-01 to 2021-12.

**Data check.** H1 bar counts are expected to be about 17,100 (2024-26), 29,580 (the 2022-26 continuous run) and 18,700 (2019-21). A window more than 8% off is inconclusive.

**Decision rule (fixed before the run).**
- The EA passes if Gates A, B (continuous) and C all pass.
- The drawdown was 19.5 to 24.6% in the earlier screen, above the 8% sizing level. The equity-limit variant already failed in that screen. Under `docs/gates.md` a failed variant is a rejection. This run re-tests the EA only on the continuous-Gate-B basis the user asked for.
- A pass would not make the EA a candidate by itself. The user's next step for a passing EA is the portfolio add-on test, which needs its own spec and is not part of this run.

**Not in this spec:** the AUDUSD M5 run, any input change, the add-on test, other symbols or timeframes, and the live account.

**Commit status:** uncommitted, like the other specs. The commit waits for the user's go-ahead.

**Leftovers.** After the verdict: the `GerakedTest` MT5 folder, the tester `.set` file, the temporary `ea_profiles.py` entry, and the two include copies (`EAUtils.mqh` and `errordescription.mqh`) placed in MT5 `MQL5/Include` for this run. If the EA passes, the include copies and the scratch downloads stay until the add-on decision. The spec, runner, logs and outcome stay.

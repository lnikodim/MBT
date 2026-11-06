# ScalpFlip v1.9 (anthonycdp/scalpflip-ea) as published, on EURUSD M5: pre-registration (2026-10-27)

**Source:** https://github.com/anthonycdp/scalpflip-ea (`SCALPFLIP v1.9.mq5`, version 1.9). The repo's compiled `.ex5` is not used; the source is compiled here. The licence was not checked, and deploying would need it.
**Scan:** no `#import`, DLL, network or file access. The README mentions DLL imports "if required"; the source needs none.
**Build:** the published source, renamed to `ScalpFlip_v1_9.mq5` because the tester cannot handle spaces in EA names. The content is byte-identical (checked with `cmp`). The build compiles with 0 errors and 0 warnings.

**Why this screen.** The user asked for the EA to be tested. The source has no code defect that invalidates its logic (checked on the full source). Its problems are design choices: no account-level loss limit, a mostly contrarian default signal, and a trailing stop that sits at broker minimum distance. Changing them would change the strategy, so the screen runs the EA as published.

**Probe before this spec.** A one-month build check (EURUSD M5, January 2024) was run before this spec: 1,987 trades, PF 0.79, net −1,708.70 USD, max DD 18.3%, and a tester log growth of about 25 MB a month. The probe is not part of any gate.

**Question.** Does ScalpFlip v1.9, with its input defaults, pass Gates A, B and C on EURUSD M5?

**Setup.** Darwinex-Demo, EURUSD M5, real ticks, $10,000 deposit, 1:100. Source defaults: `Lote` 0.1 (fixed), `MaxPositions` 10, `EntryMode` MODE_SMART, `TrendFilter` TREND_MA with `MA_Period` 20, RSI 14 with 30/70 thresholds, volume filter off, `StopLoss` 125 points, `TrailingStart` 45, `TrailingStep` 5, market hours 09:10 to 18:00 (server time), `DailyProfitTarget` 0 (off).

**Stateful?** No. There is no grid, martingale, compounding or permanent drawdown stop. Each position has its own stop, and the profit target is off. Gate B is the 2022-23 run joined with the 2024-26 screen, as in `docs/gates.md`.

**Data check.** M5 bar counts are expected to be 12 times the EURUSD H1 counts used in the other screens: 2024-26 about 205,200; 2022-23 about 149,760; 2019-21 about 224,400. A window more than 8% off is inconclusive.

**Decision rule (fixed before the run).**
- The EA passes if Gates A, B and C all pass (`docs/gates.md`).
- One instrument, so the two-rejects rule does not apply.
- If it passes all three but its drawdown is above 8%, one loss-limiting variant is run. It is named now: `MaxPositions` reduced from 10 to 3, an input the EA already has that caps open exposure (like "fewer grid levels"). The default and the variant are reported side by side, and the variant is rejected if it fails the gates.

**Not in this spec:** other instruments or timeframes, other inputs, the design issues listed above (each would need its own spec), and the live account.

**Commit status:** uncommitted, like the other specs. The commit waits for the user's go-ahead.

**Leftovers.** After the verdict, the `ScalpFlipTest` MT5 folder, the tester `.set` file, the temporary `ea_profiles.py` entry and the scratch copy are removed. The spec, the runner, the logs and the outcome stay.

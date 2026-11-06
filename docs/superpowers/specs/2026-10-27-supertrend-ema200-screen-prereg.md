# Supertrend + EMA200 EA (our build, version 1.00) on EURUSD, GBPUSD, USDJPY and XAUUSD, H1: pre-registration (2026-10-27)

**Why this screen.** The user asked for the EA and then to run it. Every EA is screened under `docs/gates.md`, so the run is a screen, not a tuned backtest.

**Question.** Does the Supertrend + EMA200 EA pass Gates A, B and C on each instrument, with its input defaults?

**Source.** `mql5/Supertrend_EMA200_EA.mq5` (version 1.00), compiled with 0 errors and 0 warnings. Inputs are the source defaults, with no change for the run. The EA has no DLL, no `WebRequest` and no external file.

**Setup.** Darwinex-Demo, H1, real ticks, $10,000 deposit, 1:100. Instruments in this order: EURUSD, GBPUSD, USDJPY, XAUUSD. Risk is the default 1% of balance per trade. The EA has no grid, martingale or compounding, and its daily loss cap is not a permanent drawdown stop, so it is not stateful: Gate B is the 2022-23 run joined with the 2024-26 screen.

**Data check.** H1 bar counts must be about 17,100 (2024-26), 12,480 (2022-23) and 18,700 (2019-21). A window more than 8% off is inconclusive. The XAUUSD window was 4.9% short in the v6.01 screen; that reading is still open with the user, and this run applies the same 8% rule.

**Sanity check.** The first trade on each instrument is checked against the sizing formula: 1% of the $10,000 balance (about $100) over the stop distance times the money per price move for one lot. This guards against the tester tick-value problem seen on XAUUSD.

**Decision rule (fixed before the run).**
- An instrument passes if Gates A, B and C all pass.
- Two-rejects rule: after two instruments reject, the rest are not run.
- If an instrument passes all three but its drawdown is above 8%, one loss-limiting variant is run. It is named now: `InpMaxDailyLossPct` tightened from 3.0 to 1.5. The default and the variant are reported side by side, and the variant is rejected if it fails the gates.

**Not in this spec:** the flip-only entry (`InpFlipOnly = true`), other inputs, other timeframes, other symbols, and the live account. Each would need its own spec.

**Commit status:** uncommitted, like the EA source. The commit waits for the user's go-ahead.

**Leftovers.** After the verdicts, the `SupertrendTest` MT5 folder, the tester `.set` files and the temporary `ea_profiles.py` entry are removed. The EA source in `mql5/` stays because the user asked for it. Whether to delete it, if every instrument rejects, is the user's call. The spec, runner, logs and outcome stay.

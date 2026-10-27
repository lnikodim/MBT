# MACD-EMA Strategy v6.01 (DillonGrech/Metatrader-Strategies, MIT) on XAUUSD, EURUSD, GBPUSD and USDJPY (H1), pre-registration (2026-10-27)

**Why this screen.** The v6.01 EA is the newest version in the repo's Standard MACD-EMA family, and the closest published MACD-plus-EMA system to the live `MACD_Cross_EA`. It is self-contained (no binary libraries, no DLL, no network calls in its source). Its own results are unknown to us, so this is a screen, not a variant of anything tested.

**Question.** Does MACD-EMA v6.01 pass Gates A, B and C on each of the four instruments, with its source defaults?

**Engine and inputs (source defaults, nothing changed):** MACD 12/26/9 on the applied price (close), EMA period 100 on the same timeframe as the bias filter, ATR period 14, stop-loss 1.0 ATR, profit target 2.0 ATR, percent risk per trade 2%, trailing stop on, compounding off, magic 2000001.

**Setup:** Darwinex-Demo, H1 on each instrument, real ticks, $10,000 deposit, 1:100, Gates A (2024-01..2026-10), B (2022-01..2023-12 joined with A) and C (2019-01..2021-12) as docs/gates.md. The EA has no grid and no compounding, so Gate B is the joined run. The EA is built from its source into a test folder, with no changes to the code.

**Data check:** H1 bar counts must match the expected totals for each window (about 17,100 for 2024-26, about 12,500 for 2022-23 and about 18,700 for 2019-21). A window with fewer bars is inconclusive, not a pass or a fail.

**Decision rule (fixed before the run):**
- Per instrument: a pass needs Gates A, B and C all to pass.
- Two-rejects rule: after two instruments reject at any gate, the remaining instruments are not run.
- A pass that shows drawdown above the 8% sizing level is reported as a candidate that needs a loss-limiting variant, under the framework rule in docs/gates.md. It is not a pass on its own.

**Not in this spec:** the multi-symbol versions, the Multi-Symbol Indicator EA (needs compiled libraries), the templates, the other MACD-EMA versions, other timeframes, any input change, and the live account.

**Leftovers:** the test build is created for the run and removed once every instrument has a verdict. The spec, runners and logs stay.

# Geraked 3MACD on EURUSD H1, grid level cap 4 with an ADX trend filter: pre-registration (2026-10-27)

**Why this variant.** The root-cause analysis (`2026-10-27-3macd-drawdown-root-cause.md`) found that the grid's averaging is both the profit and the drawdown: each leg adds exposure into the adverse move, with no working stop. Two observations set up this test:
- Capping the grid at 6 levels (E4) did not reduce the drawdown. It rose from 24.6% to 37%, because averaging stopped while the basket was still underwater.
- The reverse signal kept baskets shallower than trend-following entries did (E2 against the default), so entries into strong trends are the dangerous ones.

The user chose to test the averaging mechanism directly, with a smaller level cap and a trend filter. The filter is what limits averaging into trends. The cap limits how far averaging can go.

**Build.** The default 3MACD source (`Experts/3MACD.mq5`, Geraked) with exactly these changes:
1. **Grid level cap:** `GridMaxLvl` default changed from 50 to 4.
2. **Trend filter:** ADX(14) on H1, read from the last closed bar (shift 1). While ADX is above 25, the EA opens no new signal entries and adds no grid legs. Exits are unchanged, including the signal exit, which is not part of this spec.
3. Nothing else changes: the crossing logic, the reverse inversion, sizing, trailing, and all other inputs stay as the author wrote them.

The build compiles with 0 errors and 0 warnings. The scan finds no DLL, network or file access.

**Thresholds (fixed before the run).** The cap of 4 and the ADX period of 14 with threshold 25 are common conventions, not values tuned on this data. Only these values are tested.

**Diagnostic (not a verdict).** A filter-only build (`GridMaxLvl` 50, filter on) runs on the 2022-26 window, to separate the filter's effect from the cap's.

**Question.** Does the cap-4 plus trend-filter variant pass Gates A, B (one continuous 2022-26 run) and C on EURUSD H1, and how far does it reduce the drawdown?

**Setup.** Darwinex-Demo, EURUSD H1, real ticks, $10,000, 1:100, Risk 0.5%, grid on, equity drawdown limit off, margin limit 300%, spread limit off, as the default. The continuous-run basis applies for Gate B.

**Reference (the default, from the continuous-run outcome):** Gate A: 492 trades, PF 1.78, net +4,733.98 USD, DD 24.60%. Gate B: 891 trades, PF 1.76, net +9,876.83 USD, DD 24.68%. Gate C: 524 trades, PF 2.12, net +5,609.43 USD, DD 19.54%.

**Data check.** H1 bar counts as before: 17,100 (2024-26), 29,580 (2022-26), 18,700 (2019-21). A window more than 8% off is inconclusive.

**Decision rule (fixed before the run).**
- The variant passes if Gates A, B (continuous) and C all pass.
- It is a drawdown fix only if it passes all three and its Gate B drawdown is below 15%, against the default's 24.7%.
- If it passes the gates but Gate B drawdown is 15% or more, it is not a drawdown fix and is rejected as one.
- If it fails any gate, it is rejected.
- Any pass is reported with the default side by side. A pass would still need the portfolio add-on test, which is a separate spec.

**Not in this spec:** other cap values, other ADX settings, other filters, exit changes, other symbols or timeframes, and the live account.

**Commit status:** uncommitted, like the other specs.

**Leftovers.** After the verdict: the build folder, the tester `.set` files and the temporary `ea_profiles.py` entries are removed. The `EAUtils` and `errordescription` copies and the scratch downloads stay for the add-on decision. The spec, runner, logs and outcome stay.

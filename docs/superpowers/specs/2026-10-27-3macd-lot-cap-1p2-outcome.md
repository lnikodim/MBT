# Geraked 3MACD on EURUSD H1, grid lot cap of 1.2 lots: outcome (2026-10-27): REJECTED

**Spec:** `2026-10-27-3macd-lot-cap-1p2-prereg.md`. **Runner:** `reports/oct25/3macd_cap12_screen.py`, log `reports/oct25/3macd_cap12_screen.log` (gitignored).

| | Default | Lot cap 1.2 | Model prediction (Gate B) |
|---|---|---|---|
| Gate A trades / PF / net / DD | 492 / 1.78 / +4,734 / 24.6% | 486 / 1.87 / +4,727 / 22.3% | not modelled |
| Gate B (continuous) trades / PF / net / DD | 891 / 1.76 / +9,877 / 24.7% | 871 / 1.84 / +9,438 / 18.7% | 14.5% DD, 15.7% a year |
| Gate C trades / PF / net / DD | 524 / 2.12 / +5,609 / 19.5% | 484 / 1.03 / +253 / 46.5% | not modelled |
| Stop-outs | 0 | 0 | |

**Verdict.** Rejected on two counts.
1. **Gate C fails.** The 2019–21 run has PF 1.03 (the gate needs 1.05) and a 46.5% drawdown. Net profit is +253 USD against the default's +5,609.
2. **Not a drawdown fix.** Gate B drawdown is 18.7%, above the spec's 15% line.

**Model check.** The Gate B drawdown of 18.7% differs from the predicted 14.5% by 4.2 points, inside the 5-point tolerance, so the Phase 0 model stands for 2022–26. It said nothing about 2019–21, where the cap is catastrophic.

**Reading.** The cap helps in 2022–26 and fails in 2019–21. Capping the lots stops averaging before a basket has recovered, so a deep adverse move leaves the basket underwater and unrecovered. That is the same mechanism that makes the grid profitable, and it is why the drawdown and the profit can't be separated by a cap.

**Cleanup.** The `3MACD_CAP12` build in `MQL5/Experts/GerakedTest`, its tester `.set` and the temporary `ea_profiles.py` entry are removed. The EAUtils copy and the scratch downloads stay. The spec, runner, log and this outcome stay.

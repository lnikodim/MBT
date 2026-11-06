# Geraked 3MACD on EURUSD H1, grid level cap 4 with an ADX trend filter: outcome (2026-10-27)

**Spec:** `2026-10-27-3macd-cap-trend-filter-prereg.md`. **Runner:** `reports/oct25/3macd_cap_filter_screen.py`, log `reports/oct25/3macd_cap_filter_screen.log` (gitignored).

| | Default (continuous run) | V1: cap 4 + ADX filter | D1: cap 50 + ADX filter (diagnostic) |
|---|---|---|---|
| Gate A trades / PF / net | 492 / 1.78 / +4,734 | 254 / 2.17 / +2,314 | not run |
| Gate A DD | 24.6% | 24.5% | not run |
| Gate B (continuous) trades / PF / net | 891 / 1.76 / +9,877 | 382 / 2.01 / +3,260 | 557 / 1.67 / +5,273 (2022-26) |
| Gate B DD | 24.7% | 25.9% | 19.1% |
| Gate C trades / PF / net / DD | 524 / 2.12 / +5,609 / 19.5% | 211 / 3.75 / +2,775 / 18.3% | not run |

**Verdict.** V1 passes Gates A, B (continuous) and C, so it is a gate pass. Under the spec's drawdown rule, it is rejected as a drawdown fix: the Gate B drawdown is 25.9%, not below 15%. It also gives up about two-thirds of the default's Gate B profit.

**Reading.** The filter alone (D1) cuts the Gate B drawdown from 24.7% to 19.1%, but it also cuts profit by about 47%. The level cap of 4 (V1) adds the drawdown back and removes most of the recovery trades, which matches the earlier E4 result. Profit factor rises in both variants only because the trade count falls.

**Cleanup.** The `3MACD_V1` and `3MACD_D1` builds in `MQL5/Experts/GerakedTest`, their tester `.set` files and the temporary `ea_profiles.py` entries are removed. The EAUtils copy and the scratch downloads stay for the add-on decision. The spec, runner, log and this outcome stay.

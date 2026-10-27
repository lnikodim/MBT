# Remaining Argus repo strategy EAs on Darwinex (outcome, 2026-10-27)

User: "continue testing the rest of the EAs from this repo", with the general rule "if 2 gates are rejected, do not execute 3rd run". Scratch build with the Telegram WebRequest removed (user option 1); same setup as `2026-10-27-argus-repo-screen-prereg.md`.

14 EAs (AVWAP Confluence excluded: it does not compile as published; the orchestrator is a risk controller, not a strategy). 10 instruments each, M15 for six EAs (author's engine map), H4 for two, H1 for six. Gate A 2024-01..2026-10; B and C only after Gate A passes.

**Outcome: 0 candidates.** Liquidity Sweep Breakout passes A and joined B on EURUSD and GBPUSD and fails C on both (2019-21 PF 0.90 and 0.67). Asian Range Fakeout EURUSD PF 1.43 on 25 trades (below the 40 floor). ICT Killzone Macro, Liquidity Sweep FVG and NY Session Reversal made zero trades on EURUSD (session window in server time; not re-run, see the open question to the user).

Cells run: 28; not run by the two-rejects rule: 112.

| EA | Results |
|---|---|
| ADXTrendStrengthEA | EURUSD A REJECT, GBPUSD A REJECT | 8 |
| AsianRangeFakeoutEA | EURUSD A REJECT, GBPUSD A REJECT | 8 |
| DonchianBreakoutEA | EURUSD A REJECT, GBPUSD A REJECT | 8 |
| ICTKillzoneMacroEA | EURUSD A REJECT, GBPUSD A REJECT | 8 |
| LiquiditySweepEA | EURUSD A PASS/B PASS/C FAIL, GBPUSD A PASS/B PASS/C FAIL | 8 |
| LiquiditySweepFVG_EA | EURUSD A REJECT, GBPUSD A REJECT | 8 |
| NYReversalEA | EURUSD A REJECT, GBPUSD A REJECT | 8 |
| OpeningRangeHybridEA | EURUSD A REJECT, GBPUSD A REJECT | 8 |
| ORB_SessionEA | EURUSD A REJECT, GBPUSD A REJECT | 8 |
| PDH_PDL_EA | EURUSD A REJECT, GBPUSD A REJECT | 8 |
| PriceActionSR_EA | EURUSD A REJECT, GBPUSD A REJECT | 8 |
| SR_BreakoutEA | EURUSD A REJECT, GBPUSD A REJECT | 8 |
| VolatilitySqueezeEA | EURUSD A REJECT, GBPUSD A REJECT | 8 |
| VWAPRegimeEA | EURUSD A REJECT, GBPUSD A REJECT | 8 |

**Leftovers removed (standing rule):** the MT5 `Experts\Argus` folder, the scratch build and clone, and the fourteen profile entries plus the folder mapping in `scripts/ea_profiles.py`. Kept: this spec and the logs `reports/oct25/argus2.log` and the runner `reports/oct25/argus2.py`.

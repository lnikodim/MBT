# Geraked 3MACD on EURUSD H4: outcome (2026-10-27): stopped, no verdict

**Spec:** `2026-10-27-3macd-eurusd-h4-screen-prereg.md`. **Runner:** `reports/oct25/3macd_eurusd_h4_screen.py`, log `reports/oct25/3macd_eurusd_h4_screen.log` (gitignored).

**What happened.** The run was stopped on the user's instruction ("stop it and clean"). The continuous 2022-26 window's report was written (`reports/g3_3MACD_EURUSD_H4_s0_*.htm`), but its bar check and Gate B judgement never ran. Gate C was not run.

**Gate A figures.** The runner printed Gate A as a PASS (90 trades, PF 1.58, net +629.97 USD, drawdown 21.05%, 0 stop-outs). That line was printed before the bar check, and the check never ran because the run was stopped. The Gate A window is therefore **unverified** and is not a result. The report `reports/g3_3MACD_EURUSD_H4_scr_*.htm` is kept for a check of its bar count against the expected 4,275.

**Cleanup.** The `3MACD_H4` build in `GerakedTest` and its tester `.set` are removed. The temporary `ea_profiles.py` entry is removed. The configuration file of the 2022-26 window is removed; its report (`.htm`, `.json`) is kept with the Gate A report, both unverified. Today's tester logs are truncated. The GBPUSD M15 build stays for its documented rerun.

**To finish the test.** Rerun the same spec once the EURUSD H4 history is confirmed complete (bar check: about 4,275 for 2024-26, 7,395 for 2022-26, 4,675 for 2019-21).

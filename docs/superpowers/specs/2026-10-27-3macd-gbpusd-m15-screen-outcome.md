# Geraked 3MACD on GBPUSD M15: outcome (2026-10-27): INCONCLUSIVE overall, Gate A valid

**Spec:** `2026-10-27-3macd-gbpusd-m15-screen-prereg.md`. **Runner:** `reports/oct25/3macd_gbpusd_m15_screen.py`, log `reports/oct25/3macd_gbpusd_m15_screen.log` (gitignored).

| Window | Bars (expected) | Bar check | Result |
|---|---|---|---|
| Gate A, 2024-01..2026-10 | 68,429 (68,400) | ok | **PASS**: 1,363 trades, PF 1.62, net +14,765.83 USD, DD 51.8%, 0 stop-outs |
| Gate B, 2022-01..2026-10 (continuous) | 4,395 (118,320) | **fails (3.7%)** | inconclusive, no verdict. The printed figures (116 trades, PF 0.21, -5,717 USD, DD 60.7%, 12 stop-outs) are on partial history and do not count |
| Gate C, 2019-01..2021-12 | not run | | Gate B had no verdict, so Gate C was not run |

**Result: no verdict.** Gate A is valid and passes. Its drawdown of 51.8% is far above the 8% target, and the spec's rule would require the lot-cap variant (1.2 lots) if the whole test passed. Gate B's history is missing most of 2022-23, so the continuous run cannot be judged until the GBPUSD M15 history is complete.

**Cause.** The same history problem as AUDUSD M5 (see `2026-10-27-3macd-audusd-m5-screen-outcome.md`): the terminal's intraday history for the earlier years is incomplete. This is a data issue, not a result about the EA.

**Cleanup.** The build (`GerakedTest\3MACD_GBP`) is kept for a rerun once the history is complete. The temporary profile entry is removed from the repo, and the spec stays.

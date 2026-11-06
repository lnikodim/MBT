# Geraked 3MACD on AUDUSD M5: outcome (2026-10-27): INCONCLUSIVE, no verdict

**Spec:** `2026-10-27-3macd-audusd-m5-screen-prereg.md`. **Runner:** `reports/oct25/3macd_audusd_m5_screen.py`, log `reports/oct25/3macd_audusd_m5_screen.log` (gitignored).

**Result: no verdict.** The Gate A window failed the bar check: 44,334 M5 bars against about 205,200 expected (21.6%). The spec makes such a window inconclusive. The Gate A figures the runner printed (434 trades, PF 0.63, net -4,814 USD, drawdown 64.1%, 14 stop-outs) are built on that partial history and are not a result. Gates B and C were not run.

**Cause, most likely.** The Darwinex-Demo history for AUDUSD M5 is incomplete. The earlier replication on the author's window counted 88,565 bars against about 192,747 (46%), which points the same way. Roughly 61 M5 bars per trading day is about 5 hours of an expected 24, so the terminal is missing most of the M5 history. The terminal's own AUDUSD M5 bar count (Symbols > Bars) has not been checked yet.

**Next, if the user wants this test.** In the Darwinex-Demo terminal: open an AUDUSD M5 chart, scroll back to 2019, then check the AUDUSD M5 bar count in Symbols > Bars. Once the 2024-26 window reaches about 205,000 bars, the same spec can be rerun. The build (`GerakedTest\3MACD_AUD`) is kept for that rerun, and the temporary profile entry is removed from the repo.

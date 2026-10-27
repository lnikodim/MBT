# Argus zero-trade EAs re-run with the author's intended windows: outcome (2026-10-27)

Pre-registration: `2026-10-27-argus-zero-trade-rerun-prereg.md`. Windows (Darwinex summer server; the winter setting is one hour earlier): ICT 10:00-12:00 (London 7-9 UTC); NY Session Reversal London 11:00-15:00, NY 16:00-18:30; Liquidity Sweep FVG 11:00-21:00. Two-rejects rule applied.

| EA | Results | Verdict |
|---|---|---|
| ICT Killzone Macro (M15) | EURUSD 0 trades, GBPUSD 0 trades; 8 not run | rejected: zero trades with the corrected window too. The sweep condition (a 5-pip wick through the 4-hour low or high that closes back inside, inside the window) never fires on these bars, as far as can be inferred without logging. Not confirmed; a logging-only copy would be needed. |
| NY Session Reversal (M15) | EURUSD 2 trades, PF 1.84, +86 USD; GBPUSD 3 trades, PF 0.00, -306 USD; 8 not run | rejected on sample size (floor 40). |
| Liquidity Sweep FVG (H1) | EURUSD 0 trades, GBPUSD 0 trades; 8 not run | rejected: zero trades with the corrected window too. |

**Verdict:** no candidate. Two of the three made no trades even with their intended windows, so the window was not the cause. The zero-trade result is a signal-logic question that the user has not yet approved investigating (a logging-only copy).

**Leftovers removed (standing rule):** the MT5 `Experts\Argus` folder, the scratch build and clone, and the three profile entries and folder mapping in `scripts/ea_profiles.py`. Kept: this outcome, the pre-registration, and the logs `reports/oct25/argus3.log` and the runner `reports/oct25/argus3.py`.

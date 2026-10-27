# HydraPrime (sriramvarun0636/HydraPrime, gold M5): outcome (2026-10-27)

Request: user, 2026-10-27, shared the repo link, then "go" to screen it on XAUUSD M5.
Runner: `reports/oct25/hydra1.py`; log: `reports/oct25/hydra1.log`.

## Scan and compile

- Source: a single file, `main.mq5` (the README names it `HydraPrime_Gold_v1.mq5`). Scan: no `#import`, `.dll`, `WebRequest`, `InternetOpen`, `SendNotification` or `SendMail`. Includes: `Trade\*.mqh` only. No `Print` calls.
- Compile as published: 2 errors. `GlobalVariableExist` (line 277) is an MQL4 function; MQL5 has `GlobalVariableCheck`.
- Fix applied to the MT5 test copy only: `GlobalVariableExist` → `GlobalVariableCheck` (same bool result). Compile: 0 errors, 1 warning (version string format).

## Setup

Darwinex-Demo, XAUUSD M5, real ticks, $10,000 deposit, 1:100, Gate A 2024-01..2026-10. The author's README inputs: 1% risk per trade, one position at a time, London 08:00 to 18:00 GMT, broker GMT offset 2 (fixed; Darwinex runs UTC+3 in summer, so the window sits an hour off in those months).

## Result

| Window | Trades | PF | Net USD | Max DD | Stop-outs | Gate A |
|---|---|---|---|---|---|---|
| 2024-01..2026-10 | 706 | 0.92 | −2,499.22 | 29.6% | 0 | REJECT (PF) |

Year split: 2024 −3,425, 2025 −2,200, 2026 −2,264 (USD). The total R could not be computed: the pairing parser found 625 trades, with 2 overlapping positions, so its R figure is n/a. The tester's 706 is the figure used for the gate.

Gate B and C were not run, because Gate A failed.

## README claims

The README reports PF 1.37, 530 trades, 13.8% max drawdown and a 50% win rate, on a May 2024–May 2026 backtest with 99% real ticks. None of these reproduce here: PF 0.92, 706 trades, 29.6% drawdown. The test window differs (2024-01..2026-10), and the clock-offset input is at the author's fixed value of 2, so the result holds for that setting only.

## Verdict

Closed. Gate A fails on PF.

## Cleanup (standing rule: fail verdict)

- Removed the MT5 `Experts\Advisors\HydraPrime_EA.mq5`, `.ex5` and compile log (only the test copy; the user's own EAs in that folder were left alone).
- Removed the temporary HydraPrime profile entry, and reverted the `InpSymbol1` string-set change in `scripts/ea_profiles.py`; the file matches the committed version. Tests: 42 passed.
- Kept: the runner `reports/oct25/hydra1.py`, its log, and this outcome. The author's repo clone is in the scratch folder, outside the project.

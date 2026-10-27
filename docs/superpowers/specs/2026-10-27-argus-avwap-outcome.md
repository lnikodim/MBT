# Argus AVWAP Confluence after the brace fix: outcome (2026-10-27)

Approval: user, 2026-10-27, "yes, apply the brace fix and test AVWAP".
Runner: `reports/oct25/argus6.py`; log: `reports/oct25/argus6.log`.

## Brace fix (logic-neutral)

The `case STATE_IDLE:` body declared `double ask` and `double bid` directly under a `case` label, which fails to compile (error 179). The body is now wrapped in its own block, `{ ... }`. No other line changed. Compile: 0 errors, 1 warning in the shared core (`ArgusCore.mqh:25`, a local hides a global; the same warning shows for every Argus EA).

## Security scan

`AVWAP_Confluence_EA.mq5` and `AVWAPUtils.mqh`: no `#import`, `.dll`, `WebRequest`, `InternetOpen`, `SendNotification` or `SendMail`. The shared core's Telegram `WebRequest` is removed in the scratch build (user option 1, 2026-10-27), as for the other Argus EAs.

## Setup

Darwinex-Demo, real ticks, $10,000 deposit, 1:100, H1 (the author's engine map), Gate A 2024-01..2026-10, two-rejects rule. Inputs: the EA's own defaults (session anchor 08:00 server, swing lookback 50, HTF H1, trend EMA 50, bounce ATR min 0.5, two trades per session, risk 1.0%, RR 2.0, SL buffer 0.2 ATR, max spread 15).

## Results

| Instrument | Trades | PF (tester) | Net USD | Total R | Gate A |
|---|---|---|---|---|---|
| EURUSD | 135 | 0.79 | −2,008.18 | −21.0 | REJECT (PF) |
| GBPUSD | 155 | 0.84 | −1,742.00 | −17.7 | REJECT (PF) |

Screen drawdown: 24.8% (EURUSD) and 26.5% (GBPUSD). Stop-outs 0 in both. The total R comes from the trade-pairing parser in the run log, which gives PF 0.80 (EURUSD) and 0.85 (GBPUSD), 0.01 off the tester figures above.

The other eight instruments were not run under the two-rejects rule.

## Verdict

No candidate. The EA loses on both majors.

## Coverage

With AVWAP tested, all 20 strategy EAs in the Argus repo have now been screened. The orchestrator (`Argus_Orchestrator/ArgusPanoptesEA.mq5`) is a portfolio risk controller, not a strategy, and was not run.

This corrects the earlier statements in `2026-10-27-argus-repo-screen-prereg.md` and `2026-10-27-argus-remaining-screen-outcome.md` that AVWAP Confluence was excluded because it does not compile.

## Cleanup (standing rule: fail verdict)

- Removed the MT5 `MQL5/Experts/Argus` folder (AVWAP sources and the shared core copy).
- Removed the temporary AVWAP profile entry and its `expert_path` branch from `scripts/ea_profiles.py`; the file matches the committed version.
- Kept: the runner `reports/oct25/argus6.py` and its log.
- Tests: 42 passed after the cleanup.

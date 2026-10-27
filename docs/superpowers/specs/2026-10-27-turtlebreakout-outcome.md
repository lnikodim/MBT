# TurtleBreakout ("Turtle System 1", pasted MQ5): outcome (2026-10-27)

Request: user, 2026-10-27, pasted the source and asked to test it.
Runner: `reports/oct25/turtle1.py`; log: `reports/oct25/turtle1.log`.

## Scan and compile

- Source: pasted, one file. Scan: no `#import`, `.dll`, `WebRequest`, `InternetOpen`, `SendNotification`, `SendMail`, `ShellExecute`, `FileDelete` or sockets. Include: `Trade\Trade.mqh` only.
- Compile: 0 errors, 0 warnings.

## Setup

Darwinex-Demo, D1, real ticks, $10,000 deposit, 1:100, Gate A 2024-01..2026-10, two-rejects rule. Timeframe D1 because the source's inputs are "Days/Bars" and Turtle System 1 is a daily system. Inputs: the source defaults (Donchian entry 20, exit 10, ATR 20, risk 1.0%, stop 2.0 × ATR, magic 1984).

## Results

| Instrument | Trades | PF (tester) | Net USD | Total R | Max DD | Gate A |
|---|---|---|---|---|---|---|
| EURUSD | 33 | 1.08 | +99.13 | +0.8 | 5.3% | REJECT (trades < 40) |
| GBPUSD | 35 | 0.49 | −675.96 | −7.7 | n/a | REJECT (PF and trades) |

The other eight instruments were not run under the two-rejects rule. Stop-outs 0 on both.

## Verdict

No candidate. EURUSD is a near miss on profit but falls short of the 40-trade floor. GBPUSD loses.

## Cleanup (standing rule: fail verdict)

- Removed the MT5 `Experts\Advisors\TurtleBreakout.mq5`, `.ex5` and compile log.
- Removed the temporary TurtleBreakout profile entry and the `InpStrategyName` string-set change.
- Incident: the first removal script deleted 300 lines of `scripts/ea_profiles.py` (its block-end check missed the `},` line ending). `scripts/ea_profiles.py` was restored with `git checkout` from HEAD; the diff before the restore had no insertions, so nothing else was lost. The file now matches HEAD, and the 42 tests pass.
- Kept: the runner `reports/oct25/turtle1.py`, its log and this outcome.

# Astralchemist bot and SmartMoney MTF v2: outcome (2026-10-27)

Requests: user, 2026-10-27, shared the Astralchemist and SmartMoney repos, then "go". Stopped by the user: "Astral EAs are a complete disaster, skip them", then "yes, stop it and close it".
Runner: `reports/oct25/screen10.py`; log: `reports/oct25/screen10.log`. Logging-strip probe: `reports/oct25/strip_probe.py`; log: `reports/oct25/strip_probe.log`.
Setup: Darwinex-Demo, real ticks, $10,000 deposit, 1:100, Gate A 2024-01..2026-10, two-rejects rule. Source defaults; AstralBot on M1, SmartMoney on M1 (its entry timeframe).

Scan: no `#import`, DLL, `WebRequest`, socket or mail calls in either source.

## AstralBot (Astralchemist, `bot.mq5`)

| Instrument | Trades | PF | Net USD | Stop-outs | Verdict |
|---|---|---|---|---|---|
| EURUSD | 49 | 0.91 | -207.45 | 0 | REJECT (PF) |
| GBPUSD | 4 | 0.00 | -241.19 | 0 | REJECT (trades, PF) |

Two rejects: the rule skipped the other eight instruments. Its logging was stripped (21 `Print` calls renamed to `NoLog`) after the screen flagged a flood. The two-week probe matched the original exactly (4 trades, +13.52 USD), so the stripped copy was the one tested.

## SmartMoney MTF v2 (`SmartMoney_MTF_EA_v2.mq5`)

| Instrument | Trades | PF | Net USD | Stop-outs | Verdict |
|---|---|---|---|---|---|
| EURUSD | 2774 | 0.80 | -9,640.93 | 0 | REJECT (PF) |
| GBPUSD | 2960 | 0.83 | -9,764.17 | 0 | REJECT (PF) |

Two rejects: the rule skipped the remaining eight instruments. Its logging was stripped (86 `Print` calls renamed to `NoLog`) under the same probe rule; the probe matched the original exactly (43 trades, -867.68 USD). Total R is unavailable: the trades overlap (873 and 950 overlapping pairs).

## Verdict

No candidate. Both EAs lost money on both majors they ran.

## Cleanup (standing rule: fail verdict)

- Removed the MT5 `Experts\Astral` and `Experts\SmartMoney` files (sources, original copies used for the probe, `.ex5` files and compile logs).
- Removed their temporary profile entries from `scripts/ea_profiles.py`. The file matches the committed version apart from the remaining geraked and candidate entries.
- Cleaned the tester master and agent logs (`screen_eval.cleanup()`).
- Kept: the runners, the logs and this outcome.

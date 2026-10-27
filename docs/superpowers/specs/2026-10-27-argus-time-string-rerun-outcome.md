# Argus five-EA re-run after the time-string fix: outcome (2026-10-27)

Pre-registration: `docs/superpowers/specs/2026-10-27-argus-zero-trade-rerun-prereg.md` (windows). Runner: `reports/oct25/argus5.py`; log: `reports/oct25/argus5.log`.
Setup: Darwinex-Demo, M15, real ticks, $10,000 deposit, 1:100, Gate A screen 2024-01..2026-10, two-rejects rule.

## Harness fix

The profile writer wrote time-of-day inputs as `Name=HH:MM||HH:MM||1||HH:MM||N` (numeric-range format). The EAs read the whole string, `StringToTime` returned 0, and the windows were lost. The writer now writes them bare (`ARGUS_TIME_STRINGS` in `scripts/ea_profiles.py`, pinned by `test_argus_time_strings_are_written_bare`). The NY `.ini` now carries `LondonStart=11:00`, `NY_Start=16:00` and so on.

## Results

| EA | Instrument | Trades | PF (tester) | Net USD | Total R | Gate A |
|---|---|---|---|---|---|---|
| ICT Killzone Macro (10:00–12:00) | EURUSD | 232 | 0.88 | −762.63 | n/a (overlapping positions) | REJECT (PF) |
| ICT Killzone Macro | GBPUSD | 345 | 0.70 | −2,805.85 | n/a | REJECT (PF) |
| NY Session Reversal (11:00–15:00, 16:00–18:30) | EURUSD | 2 | 1.84 | +86.08 | +0.9 | REJECT (trades) |
| NY Session Reversal | GBPUSD | 3 | 0.00 | −305.94 | −3.1 | REJECT (trades) |
| Asian Range Fakeout (defaults) | EURUSD | 25 | 1.43 | +686.76 | +7.0 | REJECT (trades) |
| Asian Range Fakeout | GBPUSD | 39 | 0.93 | −192.06 | −1.5 | REJECT (trades, PF) |
| ORB Session (defaults) | EURUSD | 521 | 0.96 | −1,408.54 | −9.4 | REJECT (PF) |
| ORB Session | GBPUSD | 536 | 0.92 | −2,380.74 | −21.8 | REJECT (PF) |
| ORB Hybrid (defaults) | EURUSD | 574 | 0.94 | −2,136.99 | −17.9 | REJECT (PF) |
| ORB Hybrid | GBPUSD | 578 | 0.82 | −5,788.30 | −81.2 | REJECT (PF) |

All other instruments were skipped under the two-rejects rule. Sizing: $10,000 deposit, profile default risk 1.0% per trade.

## Verdict

No candidate. All five EAs were closed on Gate A.

## Correction to earlier outcomes

- `2026-10-27-argus-zero-trade-rerun-outcome.md` (`dbca86a`) reported ICT Killzone Macro as zero trades. That was the time-string bug. With the fix, ICT trades (232 and 345), and it loses on both majors.
- The NY, Asian and ORB results in `2026-10-27-argus-remaining-screen-outcome.md` (`a736bc8`) and the zero-trade outcome (`dbca86a`) were recorded as valid. They were run under the broken writer, and the re-run reproduces the same trade counts and PF with the fix, so the bug did not change those EAs' trades. Those numbers stand.

## Caveats

- ICT's total R is not computed because its positions overlap (113 and 170 overlapping pairs), so the R pairing does not apply. Its USD figures come from the tester report.
- LiquiditySweepFVG was not re-run. Its inputs are integer hours, which the fix does not touch, so its zero-trade result stands. Its post-sweep diagnosis is still open.

## Cleanup (standing rule: fail verdict)

- Removed the MT5 `MQL5/Experts/Argus` folder (sources, `.ex5`, compile logs).
- Removed the five Argus profile entries, `ARGUS_FOLDER` and the `expert_path` Argus branch from `scripts/ea_profiles.py`.
- Kept: `ARGUS_TIME_STRINGS` (the writer fix), the runner scripts, the logs and this outcome.
- Scratch clones (`argus4/`) are outside the repo and were left in place.
- `tests/test_ea_profiles.py`, `test_ea_inputs.py` and `test_live_sets.py`: 42 passed after the cleanup.

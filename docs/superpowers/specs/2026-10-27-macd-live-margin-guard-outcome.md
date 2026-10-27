# MACD_Cross_EA (live, XAUUSD H1): margin-level entry guard, outcome (2026-10-27)

Spec: `2026-10-27-macd-live-margin-guard-prereg.md`.
Logs: `reports/oct25/macd_margin.log` (gitignored, kept locally). Runners: `reports/oct25/macd_margin.py`, `reports/oct25/macd_margin_control.py`.
Setup: Darwinex-Demo, XAUUSD H1, real ticks, $10,000 deposit, 1:100. The guard is `InpMarginLimit = 300`: no new entry while positions are open and the margin level is below 300%.

## Results

| XAUUSD H1 | Guard on (300%) | Guard off (control, same build) | Earlier baseline (live build) |
|---|---|---|---|
| Gate A (2024-26) | 569 trades, PF 1.87, +20,038.79 USD, DD 13.4% | identical | 569 trades, PF 1.87, +20,048.53 USD, DD 13.4% |
| Gate B (joined) | 961 trades, PF 1.73, +23,744.86 USD, DD 14.6% | identical | 961 trades, PF 1.73, +23,761 USD, DD 14.6% |
| Gate C (2019-21) | FAIL: 618 trades, PF 0.93, -1,027.97 USD, DD 25.9% | identical: FAIL | FAIL: 618 trades, PF 0.93, -1,026.44 USD, DD 25.8% |

## Reading

- The guard blocked no entries. Its results match the control on every gate.
- Against the earlier baseline, the guard run differs by about $10 to $16 on net profit, with identical trade counts and PF. The control, with the guard off, shows the same gap, so the difference comes from the new build or the tester, not from the guard.
- Strictly, the spec's rule asked for a match to the earlier baseline, and that fails by those few dollars. Against its own control, the guard matches exactly on all three gates.

## Recommendation

The guard is neutral in backtests. It is a safety feature and can be recommended as a setting for the live account. Turning it on in the live account is a separate decision.

## Cleanup

- Removed the `MACDTest` margin build files and the test profile entry; `scripts/ea_profiles.py` is at its committed version.
- Kept: the spec, the runners and logs, and this outcome.

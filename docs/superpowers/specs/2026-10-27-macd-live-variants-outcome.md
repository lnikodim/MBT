# MACD_Cross_EA (live) variants: outcome (2026-10-27)

Specs: `2026-10-27-macd-live-trend-swap-prereg.md`, `2026-10-27-macd-live-long-only-prereg.md`, `2026-10-27-macd-live-long-only-instruments-prereg.md`.
Logs: `reports/oct25/macdswap_*.log`, `reports/oct25/macd_longonly*.log` (gitignored; kept locally).
Setup: Darwinex-Demo, real ticks, $10,000 deposit, 1:100. Baseline is the live configuration (chart settings in `mql5/profiles/MBT_DarwinexZero/chart01.chr`).

## 1. Trend-filter swap (XAUUSD H1): H4 EMA-200 replaced by the H4 MACD(34,144) zero line

| | Baseline (live) | Swap |
|---|---|---|
| Gate A (2024-26) | 569 trades, PF 1.87, +20,049 USD, DD 13.4% | 575 trades, PF 1.82, +17,430 USD, DD 15.4% |
| Gate B (joined) | 961 trades, PF 1.73, +23,761 USD, DD 14.6% | 976 trades, PF 1.66, +20,227 USD, DD 15.7% |
| Gate C (2019-21) | FAIL: 618 trades, PF 0.93, -1,026 USD, DD 25.8% | FAIL: 604 trades, PF 1.01, +234 USD, DD 25.9% |

**Not adopted.** Lower net and PF on Gates A and B, and more drawdown. The live EMA filter stays.

## 2. Long-only (XAUUSD H1): `InpAllowShort = false`

| | Baseline (live) | Long-only |
|---|---|---|
| Gate A (2024-26) | 569 trades, PF 1.87, +20,049 USD, DD 13.4% | 415 trades, PF 2.01, +19,057 USD, DD 11.0% |
| Gate B (joined) | 961 trades, PF 1.73, +23,761 USD, DD 14.6% | 619 trades, PF 1.91, +21,877 USD, DD 11.2% |
| Gate C (2019-21) | FAIL: PF 0.93, -1,026 USD | FAIL: 362 trades, PF 1.14, +1,390 USD, DD 16.5% |

**Not adopted.** Higher PF and lower drawdown, but lower net on Gates A and B, so the decision rule (net and PF both higher) fails. Gate C fails on the t-statistic threshold.

## 3. Long-only on other instruments (H1), against each instrument's live-configuration baseline

| Instrument | Baseline, Gate A | Long-only, Gate A | Decision |
|---|---|---|---|
| EURUSD | 277 trades, PF 0.55, -2,629 USD, DD 31.7% | 171 trades, PF 0.47, -2,110 USD, DD 23.7% | Not adopted (fails Gate A) |
| GBPUSD | 277 trades, PF 0.61, -2,281 USD, DD 27.8% | 166 trades, PF 0.80, -753 USD, DD 18.0% | Not adopted (fails Gate A) |
| USDJPY | not run | not run | Skipped under the two-rejects rule |

Bar counts matched the expected totals for every window run.

## Reading

- The long-only variant lowers drawdown and loss on every instrument it was run on, but none of them turns a profit on Gate A.
- The XAUUSD result does not generalise: the variant that passed Gate A on gold fails it on EURUSD and GBPUSD.
- The live EA fails Gate C on 2019-21 with either filter.

## Cleanup

- Removed the `MACDTest` build files and the test profile entries; `scripts/ea_profiles.py` is at its committed version.
- Kept: the specs, the runners and logs, and this outcome.

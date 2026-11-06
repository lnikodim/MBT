# MACD-EMA Strategy v6.01 (DillonGrech repo) on XAUUSD and EURUSD, H1: screen outcome (2026-10-27)

Spec: `2026-10-27-macd-ema-v601-screen-prereg.md`. Sizing amendment: `2026-10-27-macd-ema-v601-sizing-amendment.md`.
Runner: `reports/oct25/macd_ema_screen.py`; log: `reports/oct25/macd_ema_screen.log` (gitignored, kept locally). The invalid pre-fix run is in `reports/oct25/macd_ema_screen_invalid_sizing.log` and is not counted.
Setup: Darwinex-Demo, H1, real ticks, $10,000 deposit, 1:100, source defaults, sizing-patched test build.

## Results (Gate A, 2024-01..2026-10)

| Instrument | Trades | PF (USD / R) | Net USD | Net R (total) | Max DD | Stop-outs | H1 bars (expected ~17,100) | Verdict |
|---|---|---|---|---|---|---|---|---|
| XAUUSD | 220 | 0.85 / 0.84 | -3,653.58 | -18.3 | 57.6% | 0 | 16,268 | Gate A REJECT |
| EURUSD | 152 | 0.78 / 0.77 | -3,490.35 | -17.4 | 39.6% | 0 | 17,108 | Gate A REJECT |
| GBPUSD | not run | | | | | | | two-rejects rule |
| USDJPY | not run | | | | | | | two-rejects rule |

Net by year (USD): XAUUSD 2024 +1,135, 2025 -4,322, 2026 -467. EURUSD 2024 -2,001, 2025 -902, 2026 -587.
Gates B and C were not run: a cell stops at the first failing gate.

## Reading

With the source defaults, the EA loses money over 2024-26 on both instruments and fails Gate A. Drawdowns are 40-58%. Only XAUUSD's 2024 is positive.

**Verdict:** the EA is rejected (two Gate A rejects). Under the two-rejects rule, GBPUSD and USDJPY are not run.

## Caveats

- **XAUUSD bar count:** 16,268 against about 17,100 expected (4.9% short). The runner flags a window only beyond 8%, so no flag was raised. The spec says a window with fewer bars is inconclusive. Read strictly, the XAUUSD verdict would be inconclusive, the reject count would be 1, and GBPUSD and USDJPY would run. The 8% flag was the rule applied here; which reading applies is the user's call.
- **Lot check:** the first XAUUSD entry is 0.45 lots, consistent with its 4.46 stop: 200 / (4.46 × 100). The 0.08 expectation in the amendment was wrong.
- **Speed:** XAUUSD took 308 s and EURUSD 108 s. The per-tick `Comment()` removal was compiled during the EURUSD cell. No cell ran on it afterwards, so its speed effect is not measured.
- **Scope:** this rejects only the v6.01 build on these two instruments. The other MACD-EMA versions and the other repo families are not covered.

## Cleanup

- `scripts/ea_profiles.py` restored to HEAD (the temporary v6.01 entries removed).
- MT5 `MQL5/Experts/MACDEMATest/` (source, .ex5, compile log) and `MQL5/Profiles/Tester/MACD_EMA_v601.set` removed.
- Scratch patched copies removed. The DillonGrech clone is kept for the other families.
- Old-day tester log `Tester/Manager/logs/20261026.log` removed.
- Kept: the spec, the amendment, the runners and logs, and this outcome.

## Next

Decide whether the XAUUSD bar shortfall makes that window inconclusive under the spec. If it does, GBPUSD and USDJPY run next under the same spec.

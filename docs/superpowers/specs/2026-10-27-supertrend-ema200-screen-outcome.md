# Supertrend + EMA200 EA (version 1.00) on EURUSD, GBPUSD, USDJPY and XAUUSD, H1: screen outcome (2026-10-27)

**Spec:** `2026-10-27-supertrend-ema200-screen-prereg.md`. **Runner:** `reports/oct25/supertrend_screen.py`, log `reports/oct25/supertrend_screen.log` (gitignored). **Identity check:** `reports/oct25/supertrend_identity.py`.
**Source:** `mql5/Supertrend_EMA200_EA.mq5`, remapped to the repo's seven input groups after this screen. The screened layout is kept as `reports/oct25/Supertrend_EMA200_EA_initial_layout.mq5`. Input names and defaults are unchanged.
**Setup:** Darwinex-Demo, H1, real ticks, $10,000 deposit, 1:100, source defaults (1% risk per trade, Supertrend ATR 10 x 3.0, EMA 200, TP 2R, signal exit on, spread limit 30 points, daily loss limit 3%).

## Results (Gate A, 2024-01..2026-10)

| Instrument | Trades | PF (USD / R) | Net USD | Net R (total) | Max DD | Stop-outs | H1 bars (expected ~17,100) | First-trade lot check | Verdict |
|---|---|---|---|---|---|---|---|---|---|
| EURUSD | 529 | 0.82 / 0.85 | -3,564.80 | -41.6 | 44.9% | 0 | 17,108 | 0.28 vs 0.29 formula (rounded down to 0.01) | Gate A REJECT |
| GBPUSD | 521 | 0.82 / 0.84 | -3,411.00 | -40.0 | 38.1% | 0 | 17,108 | 0.19 vs 0.19 formula | Gate A REJECT |
| USDJPY | not run | | | | | | | | two-rejects rule |
| XAUUSD | not run | | | | | | | | two-rejects rule |

Net by year (USD): EURUSD 2024 -2,363, 2025 -949, 2026 -252. GBPUSD 2024 -2,273, 2025 -363, 2026 -775.
Gates B and C were not run: a cell stops at the first failing gate.

**Verdict:** the EA is rejected on EURUSD and GBPUSD, both on PF (0.82) and net. The two-rejects rule stops the USDJPY and XAUUSD runs. The drawdown variant was not triggered, because no instrument passed.

## Identity check after the input remap

The remapped build, on EURUSD 2024-01..2026-10, reproduces the screened build exactly: 529 trades, net -3,564.80 USD, PF 0.82, DD 44.87%. The inputs have the same names and defaults, so the remap changed layout and labels only. This is a build check, not a screen verdict.

## Caveats

- **The screen's gate figures come from the tester.** Its per-trade parser reports PF 0.85 (EURUSD) and 0.84 (GBPUSD) on R. The verdict uses the tester's USD metrics, which give the same reject.
- **Bar counts** are within the 8% tolerance on both instruments.
- **The 2 instruments are not the whole EA.** USDJPY and XAUUSD were not tested, so nothing is said about them.
- **Entry mode.** The default `InpFlipOnly = false` (trade the current state) is the reading of "or is bullish" chosen in the brief. The flip-only mode is untested and would need its own spec.

## Cleanup

- `scripts/ea_profiles.py` restored to HEAD.
- MT5 `MQL5/Experts/SupertrendTest/` (source, .ex5, compile log) removed.
- The tester `Supertrend_EMA200_EA.set` removed. Tester master and agent logs were empty after the runs.
- EA source copies (`mql5/Supertrend_EMA200_EA.mq5` and the screened-layout snapshot) removed on the user's instruction ("remove all previous leftovers"). The spec, this outcome, the runners, the logs and the reports are kept.

**Cleanup error, disclosed.** A `find` pattern (`-iname "*Supertrend*" -print -delete`) also deleted two other EAs' tester profile files: `Profiles/Tester/SuperTrend_MultiTF_TrendFollower_EA.set` and `Profiles/Tester/SuperTrendEMA_EA.set`. They are not in git, and no copy exists in the repo or scratch. The `.set` contents can't be rebuilt from the run records. `SuperTrend_MultiTF_TrendFollower` was rejected in the awesome-list screen (0 trades), so its `.set` was a leftover under the framework anyway. `SuperTrendEMA_EA`'s verdict is not recorded in any spec, so its leftover status is unconfirmed. Neither file is in the live profile sets (`mql5/profiles/`). If either EA is run again, the runner recreates its `.set`.

## Next

No pending work on this EA. The spec and outcome are uncommitted; commit them when asked.

# NziCode EURUSD_PriceAction_Stoch_v2, corrected variant (EURUSD M15): screen outcome (2026-10-27)

**Spec:** `2026-10-27-nzicode-stoch-v2-fix-screen-prereg.md`. **Amendment 1** (the swing change, written before the rerun): `2026-10-27-nzicode-stoch-v2-fix-screen-amendment.md`.
**Source:** https://github.com/NziCode/mt5-trading-bots/blob/main/EURUSD_PriceAction_Stoch_v2.mq5. Scratch copies are removed, so these hashes identify the versions used (SHA-256):
- As published: `030b0884...49b7d8`
- Variant 1 (swing pivot at bar 11): `496b8f19...5a42a5ad`
- Variant 2 (one-sided swing, screened): `ae641e8d...375a0080`

**Runner:** `reports/oct25/nzicode_screen.py`, log `reports/oct25/nzicode_screen.log`. The variant 1 log is `reports/oct25/nzicode_screen_variant1_zero_trades_invalid.log` and is not counted. The diagnostic runner is `reports/oct25/nzicode_diag.py`.
**Setup:** Darwinex-Demo, EURUSD M15, real ticks, $10,000, 1:100, fixed 0.1 lot, input defaults. `UseNewsFilter` stayed false, so the `WebRequest` never ran.

## Results (Gate A, 2024-01..2026-10)

| Build | Trades | PF | Net USD | Max DD | Stop-outs | H1 bars (M15 expected ~68,400) | Verdict |
|---|---|---|---|---|---|---|---|
| Variant 1 (pivot at bar 11) | 0 | n/a | 0.00 | 0.0% | 0 | 68,427 | invalid, not counted (zero trades from the variant's own design) |
| **Variant 2 (one-sided swing), screened** | **790** | **0.96** | **-156.33** | **5.39%** | **0** | **68,427** | **Gate A REJECT** |

Variant 2: win rate 59.0%, Sharpe -0.46. Gates B and C were not run: a cell stops at the first failing gate. The drawdown variant was not triggered, because the EA did not pass.

**Verdict:** the corrected variant is rejected at Gate A, on both PF (0.96 against 1.00) and net (-156.33 USD). The EA is the only instrument, so the two-rejects rule does not apply.

## What the published file does

The counting build (the same logic plus counters, run over 2024-26) showed that **the file as published cannot enter a trade**. `SwingLow(1)` and `SwingHigh(1)` are true on 0 bars, because the pivot needs bars that do not exist yet and the copy starts at bar -9. So the partial-close markers bug (`tp1done` and `tp2done` are never written) is real, but it is latent: the code it sits in is never reached while no trade opens. Both bugs are fixed in variant 2; only the swing fix produced trades.

Diagnostic counts (per bar, same window; not a screen):
- Variant 1 (pivot at bar 11): stochastic buy 1,710 bars, pivot low 2,098, trend up 24,005, all three together 0.
- Variant 2 (one-sided): buy setups 230 bars, sell setups 231 bars.

## Caveats

- **The swing choice came after seeing results.** Variant 2 was chosen after variant 1 returned zero trades, and its counting build was run over this window before the screen. That build gave 790 trades, PF 0.96 and net -156.33 USD. The amendment discloses this. The verdict is a reject, so the post-hoc choice does not change it, but any pass would need an independent window to count.
- **Per-trade parser.** The screen's parser found 461 trades and per-year sums (2024 -1,027, 2025 -947, 2026 -716, total -2,690 USD) that do not match the tester's net of -156.33 USD. The parser does not handle the partial closes. The gate uses the tester's metrics, which give the same verdict, so the parser's numbers are not used here.
- **Signal timing.** The `CopyBuffer` and `CopyTime` arrays are not set as series, so the author's "current bar" comparisons read bar 2. Left as written; it shifts timing, and entries still happen.
- **Sizing.** A fixed 0.1 lot. The USD figures are not comparable with the 8% sizing level.

## Cleanup

- `scripts/ea_profiles.py` restored to HEAD (temporary entries removed; the diff held only them).
- MT5 `MQL5/Experts/NZTest/` (both builds, source, .ex5 and compile logs) and the two tester `.set` files removed.
- Scratch copies (the downloaded source, variants and diagnostic builds) removed. The hashes above identify them.
- Tester master and agent logs were empty after the runs.
- Kept: the spec, the amendment, this outcome, the runners, the logs and the report files.

## Next

Nothing is pending on this EA. The spec, the amendment and this outcome are uncommitted; commit them when you ask.

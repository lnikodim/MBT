# NziCode EURUSD_PriceAction_Stoch_v2, corrected variant: amendment 1 (2026-10-27), before the rerun

**Amends:** `2026-10-27-nzicode-stoch-v2-fix-screen-prereg.md`. The gates, the instrument, the M15 timeframe, the windows, the decision rule and the drawdown variant (`MaxDailyLoss` 30 to 15) are unchanged. The partial-close fix is unchanged.

**Why this amendment.** The first screened run of the variant returned 0 trades in 68,425 bars. The log is kept as `reports/oct25/nzicode_screen_variant1_zero_trades_invalid.log`, and the report is `reports/nzfix_EURUSD_M15_scr_20261027_210224.htm`. That result is not counted: it comes from the variant's own swing design, not from a test of the strategy.

**Diagnosis.** A counting build (the same logic, plus counter lines and a `Print` at deinit) was run over the same window. It is a diagnostic, not a screen. Counts per bar:
- The published file's swing check is never true. `SwingLow(1)` and `SwingHigh(1)` count 0 bars on both sides. Its copy starts at bar -9, and it needs bars that do not exist yet.
- Variant 1, with the pivot at bar 11 (`SwingLookback + 1`, both sides confirmed): buy setups 0, sell setups 0. The pivot-low condition held on 2,098 bars and the stochastic buy condition on 1,710, but never together with the trend.
- Variant 2, below: buy setups 230, sell setups 231.

**The change (variant 2).** The swing check is one-sided on the last closed bar. Bar 1's low must be strictly the lowest of the last `SwingLookback + 1` closed bars (bars 1 to 11), and the high is the mirror. It reads closed bars only, keeps the author's bar-1 timing, and keeps `SwingLookback` as the lookback. Two alternatives were ruled out: the pivot with bars on both sides (variant 1, zero trades), and a bar-1 pivot that needs future bars (cannot be confirmed).

**Disclosure.** The choice of variant 2 came after variant 1's zero trades. The counting build of variant 2 was also run over 2024-26 before this amendment's screen run: 790 trades, PF 0.96, net -156.33 USD, max DD 5.39%, win 59.0%. The counter lines do not change trading, so the screen run should reproduce those figures. The screen run below is the formal record. Any pass for this variant would need that caveat and a second, independent window before it counts.

**Known and not changed.** The `CopyBuffer` and `CopyTime` arrays are not set as series, so index 0 of each copy is the oldest bar of the copied range. For the 3-bar stochastic and EMA copies, index 0 is bar 2, not bar 0, so the author's "current bar" comparisons read bar 2. This shifts the signal timing by two bars; it does not block entries, since the counts show signals. It is left as the author wrote it and reported here.

**Commit status:** this amendment is not committed, like the spec it amends. The commit waits for the user's go-ahead.

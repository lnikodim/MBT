# MACD_Cross_EA (live, XAUUSD H1): trend-filter swap, pre-registration (2026-10-27)

**Question.** Does replacing the live trend filter (H4 EMA-200) with the 34/144 MACD zero line from 3MACD, on the same H4 timeframe, improve the live EA?

**Baseline (live, unchanged):** MACD_Cross_EA with its saved chart settings on XAUUSD H1 (`mql5/profiles/MBT_DarwinexZero/chart01.chr`): MACD 16/26/9, trend filter on, H4 EMA-200, stop 0.5%, target 3.75%, break-even 0.5%, trailing 4 x ATR, risk 0.5%, max 3 positions, daily loss 4%, monthly loss 12%. The test uses the chart's values, which differ from the source default only in the daily loss limit (4% chart, 3% source).

**Variant (the only one):** identical to the baseline, except the trend filter. A long needs the last closed H4 MACD(34,144,1) main line above zero; a short needs it below zero. The check uses the same bar as the EMA check (shift 1). Code: `MACD_Cross_EA_TrendMACD.mq5` in the scratch folder; the only change is the trend-filter lines and the input `InpTrendMode` (0 = EMA as live, 1 = MACD zero line). The live source file is not modified.

**Setup:** Darwinex-Demo, XAUUSD H1, real ticks, $10,000 deposit, 1:100, Gates A (2024-01..2026-10), B and C (2019-01..2021-12) as docs/gates.md. The EA has no grid, so Gate B is the joined run, not a continuous run. Both baseline and variant run through the same gates.

**Decision rule (fixed before the run):**
1. The variant passes Gates A, B and C.
2. Against the baseline on Gate A and on the joined Gate B: net profit and PF are both higher.
3. Max drawdown is not more than 1.0 point above the baseline's (the add-on rule in docs/gates.md).

Adopt the swap only if all three hold. Otherwise the live EMA filter stays. Both results are reported, whatever the outcome.

**Not in this spec:** other instruments, other timeframes, the 3MACD grid, the 34/144 confirmation filter (a separate variant), and any change to the live account.

**Leftovers:** the `MACDTest` build and its profile entry stay until the decision is recorded.

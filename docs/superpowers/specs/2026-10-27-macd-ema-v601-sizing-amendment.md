# MACD-EMA v6.01 screen: sizing amendment (2026-10-27)

**Amends:** `2026-10-27-macd-ema-v601-screen-prereg.md`. The gates, the instruments, the H1 timeframe and the decision rule are unchanged.

**The problem found in the first run.** v6.01 sizes each trade as risk ÷ (stop distance × point value), and it takes the point value from the symbol's tick value. In the tester, XAUUSD reports a tick value of 0.01, so every lot came out about 100 times too large. On the first trade the EA sized 8.19 lots for a $200 risk on a $24 stop (the right size is about 0.08 lots), and the broker rejected every order for insufficient margin. The XAUUSD cell of that run is therefore invalid. It is not a test of the strategy, and it is not counted toward the two-rejects rule. Its log is kept as `reports/oct25/macd_ema_screen_invalid_sizing.log`.

**The change (option 2, approved by the user).** The point value no longer reads the tick value for USD-quoted pairs and USD-base pairs. It is computed from the contract size and the tick size:
- USD-quoted pairs (XAUUSD, EURUSD, GBPUSD): point value = contract size × tick size.
- USD-base pairs (USDJPY): point value = contract size × tick size ÷ price, so that it is in USD.
- Crosses: the author's original tick-value formula, unchanged.

Nothing else in the EA is changed. The author's file is unchanged; the test build is a patched copy (`MACD-EMA-Strategy-v6.01-fixed.mq5`) with the sizing lines replaced, plus the chart-only `Comment()` call removed for speed (see Result). The sizing change is logic-neutral for the signal and the exits; it changes only the number of lots.

**Re-run.** The screen runs again from the start on all four instruments with the patched build. Expected check: the first XAUUSD trade should be about 0.08 lots, not 8. (This expectation was wrong; see Result.)

**Decision rule:** unchanged from the screen spec.

## Result (2026-10-27)

- **Lot check:** the first XAUUSD entry is a sell of 0.45 lots at 2066.26, with a stop at 2070.72 (a 4.46 distance). The formula gives 200 / (4.46 × 100) = 0.45 lots, so the sizing is correct. The 0.08 expectation above was an estimate and was wrong.
- **Chart-only change:** the per-tick `Comment()` call was removed from the test copy while the EURUSD cell was running. The change cannot touch trades, and no cell ran on the changed build afterwards, so no verdict depends on it. The test build was removed with the other leftovers.
- **Outcome:** XAUUSD and EURUSD both rejected at Gate A, so GBPUSD and USDJPY were not run. See `2026-10-27-macd-ema-v601-screen-outcome.md`.

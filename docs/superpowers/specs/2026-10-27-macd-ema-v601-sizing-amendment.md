# MACD-EMA v6.01 screen: sizing amendment (2026-10-27)

**Amends:** `2026-10-27-macd-ema-v601-screen-prereg.md`. The gates, the instruments, the H1 timeframe and the decision rule are unchanged.

**The problem found in the first run.** v6.01 sizes each trade as risk ÷ (stop distance × point value), and it takes the point value from the symbol's tick value. In the tester, XAUUSD reports a tick value of 0.01, so every lot came out about 100 times too large. On the first trade the EA sized 8.19 lots for a $200 risk on a $24 stop (the right size is about 0.08 lots), and the broker rejected every order for insufficient margin. The XAUUSD cell of that run is therefore invalid. It is not a test of the strategy, and it is not counted toward the two-rejects rule. Its log is kept as `reports/oct25/macd_ema_screen_invalid_sizing.log`.

**The change (option 2, approved by the user).** The point value no longer reads the tick value for USD-quoted pairs and USD-base pairs. It is computed from the contract size and the tick size:
- USD-quoted pairs (XAUUSD, EURUSD, GBPUSD): point value = contract size × tick size.
- USD-base pairs (USDJPY): point value = contract size × tick size ÷ price, so that it is in USD.
- Crosses: the author's original tick-value formula, unchanged.

Nothing else in the EA is changed. The author's file is unchanged; the test build is a patched copy (`MACD-EMA-Strategy-v6.01-fixed.mq5`) with only the sizing lines replaced. The sizing change is logic-neutral for the signal and the exits; it changes only the number of lots.

**Re-run.** The screen runs again from the start on all four instruments with the patched build. Expected check: the first XAUUSD trade should be about 0.08 lots, not 8.

**Decision rule:** unchanged from the screen spec.

# VWAP_EMA_Pullback_EA v1.00: Stage A (pre-registration)

Date: 2026-10-26. Server: Darwinex-Demo. User rule (verbatim, pasted): "THE VWAP + EMA 9/21 STRATEGY ... For a potential bullish
setup, we look for price above VWAP, EMA 9 above EMA 21, a pullback, and bullish confirmation. For a potential bearish setup, we
look for price below VWAP, EMA 9 below EMA 21, a pullback, and bearish confirmation." Then: "5m timeframe on forex & gold".
After the open points were listed in chat, the user answered: "yes, go ahead with those defaults".

## The EA (`mql5/VWAP_EMA_Pullback_EA.mq5`, on EACore, magic 261026, compiled default M5)
**Your words, taken literally:** price above / below VWAP, EMA 9 above / below EMA 21, a pullback, then confirmation. VWAP is
anchored to the server day and weighted by tick volume (typical price = (high + low + close) / 3). EMAs on close.

**Readings of the open points (the user agreed to these defaults):**
- **Trend:** the last closed bar's close is above (below) the VWAP and EMA 9 is above (below) EMA 21.
- **Pullback:** the 1 to 8 bars before the signal bar each closed at or below (above) EMA 9, and none closed beyond EMA 21.
  A longer pullback does not qualify.
- **Confirmation:** the signal bar is bullish (bearish) and closes back above (below) EMA 9.
- **Entry:** at market when that bar closes.

**Added by me (not in the user's text):**
- **Stop:** beyond the pullback's extreme (over the signal bar and the pullback bars) plus 0.2 x ATR(14). At least 1.0 x ATR from entry.
  The trade is skipped if the stop would be wider than 3.0 x ATR.
- **Target:** 1.5 x the stop distance.
- **VWAP warm-up:** no trade in the first 12 bars after the server-midnight reset.
- **One position at a time.** EACore's guards stay on: daily loss limit 4%, monthly 12%, max spread 150 points, risk 1% per trade.

All inputs follow the EA inputs guide (groups 5-7 after EACore's 1-4).

## Runs (`reports/oct25/screen_eval.py vpb_*`; real ticks, 10,000 USD, 1:100, compiled defaults)
| cell | symbol, timeframe |
|---|---|
| vpb_X | XAUUSD M5 |
| vpb_E | EURUSD M5 |
| vpb_G | GBPUSD M5 |
| vpb_J | USDJPY M5 |
1. **Screen, 2024-01-01..2026-10-01:** reject a cell if trades < 40, PF < 1.00, net <= 0 or a stop-out.
2. **S0, 2022-01-01..2026-10-01**, survivors: trades >= 150, PF >= 1.00, net > 0 in both 2022-24 and 2025-26.
3. **S1, 2019-01-01..2022-01-01**, Gate A survivors: net > 0, PF >= 1.05, t >= 1.65 (inconclusive if history < 90%).
4. **Candidate** = all pass; then the drawdown is scaled (k = 8 / max DD %) and must give >= +10% a year in both regimes.
- **Multiple testing:** 4 cells; no input is tuned. Any change after a result needs a new pre-registration.
- **R** comes from the stop on each order (one position at a time, so the pairing is exact).

## Expectation (written before the runs)
- **Costs matter on M5.** The two earlier VWAP + EMA EAs here failed on M5 (the cross EA: PF 0.72 and 0.93; the EMA/VWAP trail EA: PF
  1.17 on one cell, but a prop-challenge pass rate below the MACD bar). A pullback entry with a 1.5 RR target has a
  much lower trade count and a defined stop, but the stop can be only about 1 ATR, so costs are still a noticeable share of R.
- **Expected PF:** about 0.90 to 1.10, near zero net R on forex, and a better chance on gold in 2024-26.
- **Most likely verdict:** closed on forex; at most one gold cell reaching the later stages.

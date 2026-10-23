# Hon_Matrix_EA on Darwinex EURUSD H1 (pre-registration)

Date: 2026-10-23. User: "let's try another EA: Hon-Matrix.mq5, https://www.mql5.com/en/code/71645". Server: Darwinex-Demo.

**The EA:** "Hon Matrix" v1.2 (mql5.com code 71645, KSQUANTITATIVE / Christopher Adie), published 2026-04-07. The user's
download is identical to the Code Base file (MD5 2240a9d8…, 3,584 lines). It is copied unchanged to
`mql5/Hon_Matrix_EA.mq5`, renamed per the naming convention, and compiles with 0 errors and 0 warnings.

**What the code does** (the page describes more than the code does):
- **Grid with no stops.** Every order is sent with SL 0 and TP 0. A basket of up to 5 orders (`MaxGridOrders`) adds
  buy / sell limits at Fibonacci levels of the last 50-bar swing, each `LotMultiplier` x the previous lot.
- **Basket exits:** average-price target `TakeProfitPips` 50, break-even at 20, trailing 15. Despite the names, all
  three are in **points**, so 50 is 5 pips on EURUSD.
- **Account exits:** everything closes at a floating loss of `CloseLosesAtPercent` 30% of the balance, or a profit of
  `CloseProfitsAtPercent` 40%. No new basket while the floating loss is above `MaxAccountExposure` 15%.
- **Entries** (one basket at a time, at least 4 h apart): channel bounce in ranging markets, S/R bounce with the H4
  EMA(100) trend, S/R breakout, each confirmed by RSI; or, with `UseEnhancedEntry` false, the original Fibonacci entry.
- **Timing:** runs every 10 seconds of server time on the chart timeframe (no symbol or timeframe stated).
- **News filter:** MT5 calendar or a GET of the ForexFactory JSON. Neither works in the Strategy Tester; with no events
  the filter allows trading, so **backtests run without it**.
- **Safety:** no DLLs and no file writes. The only web call is the public calendar above; nothing about the account is
  sent. The "backtest validation" class is never called (dead code).

**The author's settings** (forum thread 508028, 2026-06-01: "here is a set file I think GU let me make one for EU"):
`matrix.set`, saved 2025-06-21, for **GBPUSD**:
- **Lots:** starting lot 0.03, multiplier **1.5**, maximum lot 5.0.
- **Account limits:** close-all at -40% / +150%, maximum exposure 30%.
- **Entries:** the enhanced S/R / channel entry off (Fibonacci entry instead), dynamic lots, momentum and volume
  filters off.

Another user reports the defaults "not firing any signals". The author claims no backtest results.

**Data:** Darwinex has real ticks for GBPUSD only from 2024 (spec 2026-10-17-erb), and for EURUSD from 2022 at 99%. The
user's rule is real ticks only, so EURUSD is the test symbol and GBPUSD is reported only.

## Runs (`reports/honmatrix/honmatrix_eval.py`; Darwinex-Demo, H1 chart, real ticks, 10k USD = the EA's `StartCapital`, 1:100)
- **D0:** EURUSD, source defaults, 2022-01-01..2026-10-01.
- **A0:** EURUSD, the author's set file, 2022-01-01..2026-10-01.
- **G0 (report only):** GBPUSD, the author's set file, 2024-01-01..2026-10-01.
- **D1 / A1, out of sample, 2019-01-01..2022-01-01:** only for a configuration that passes its 2022-26 gate.

H1 is our choice: the code works on the chart timeframe, and its 50-100 bar lookbacks plus the 4-hour spacing between
baskets fit H1. It is fixed here and not searched.

**Trades** are rebuilt from the Deals table (`scripts/blessing_eval.py`: `deals_trades`, `baskets` = legs of one side
closed in the same second). R per trade is undefined without stops, so the gate is in USD, as for Blessing.

## Gate (per configuration, on its 2022-26 run; the Blessing gate of 2026-10-07)
1. The run completes with no stop-out, and has >= 150 baskets.
2. k = 8 / max equity drawdown %: the lot multiple that makes the worst drawdown 8%.
3. Pass if the k-scaled return is >= +10% a year in both 2022-24 and 2025-26.
4. **Confirmation, only after a pass:** a re-run at `InitialLotSize` x k (the account stops are % of balance, so scaling
   is not exactly linear) must pass 3. Then the out-of-sample run must have a scaled return > 0 and a basket-profit
   t >= 1.65. If its history quality is below 90%, the result is inconclusive and the configuration cannot be a
   candidate.
5. Anything else closes the EA. No retuning.

**Reported for every run:**
- net USD, PF, max equity DD %, worst day % of balance;
- legs, baskets, basket win rate, average win / loss, worst basket % of balance;
- emergency closes (-30% / -40%) and profit-target closes;
- entries by type (channel / S/R bounce / breakout / Fibonacci);
- net by year, history quality.

## Expectation (written before the runs)
- **The profile:** many small basket wins (5-pip target) and a few large losses. At least one account close-all at
  -30% / -40% in 2022-26, so the max DD is >= 25%, k <= 0.3, and the scaled return is about 0 or negative.
- **Defaults:** few baskets, possibly under 150 (the "not firing" report).
- **Author's set:** more baskets, a deeper martingale and a larger worst basket.
- **Most likely verdict:** closed on both configurations.

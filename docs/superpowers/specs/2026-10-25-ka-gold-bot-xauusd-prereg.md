# KA_Gold_Bot_EA on Darwinex XAUUSD M15 (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/48251". Server: Darwinex-Demo.

**The EA:** "KA-Gold Bot MT5" v1.00 (mql5.com code 48251, Hungtthanh / Nguyen Quoc Hung, published 2024-02-19, page
updated 2026-09-15), `KA-Gold_Bot.mq5` (MD5 fe305f10…, 619 lines).
- **Copied unchanged to:** `mql5/KA_Gold_Bot_EA.mq5`.
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL, web or file calls. It prints on order errors and spread skips, at most once per new bar.

**The author's claim:** a video only. The forum's summary post says "Time frame: M15". Commenters:
- one could not backtest it well;
- one saw "a very alpha result on the 1 minute timeframe for 2024 (January to now), but it causes bad losses on other
  timeframes".

**What the code does** (new M15 bar, 02:30-21:00 server time, no open position):
- **Bands:** a Keltner-style band, EMA(50) +/- the average high-low range of the last 50 bars.
- **Buy:** bar 1 closes above the upper band and above EMA(200), and EMA(10) crosses above the upper band between
  bars 2 and 1. Sell is the mirror image.
  - **Coding quirk:** the sell branch sets `result = true`, which equals `ORDER_TYPE_SELL` (1), so it works.
- **Exits:** stop 500 points and target 500 points (5 USD each on 2-digit gold).
  - **Trailing:** after +3 USD, the stop trails 3 USD behind the price in 1 USD steps.
- **Size:** 1% of balance on the stop (`isVolume_Percent`).
- **Spread cap:** 65 points.

## Runs (`reports/oct24/q_eval.py kag`; Darwinex-Demo, XAUUSD M15, real ticks, 100k USD, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**R per trade:** from the Orders table stop (5 USD; `crabel_eval.trades`).

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **Stop size:** a 5 USD stop on gold M15 is tight. 2022-23 gold had M15 ranges of about 3-6 USD, 2025-26 about 10-20
  USD, so later trades stop out fast.
- **Spread cap:** 65 points binds in 2026 (Darwinex 46-89 points), skipping trades.
- **PF:** 0.80-1.00 in R.
- **Most likely verdict:** closed.

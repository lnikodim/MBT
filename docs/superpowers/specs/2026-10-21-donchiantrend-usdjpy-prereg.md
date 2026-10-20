# DonchianTrend_EA on USDJPY H4: baseline and input tuning (pre-registration)

Date: 2026-10-21. User: "I've started validation of another EA named … DonchianTrend_EA.ex5. You can backtest it on
USDJPY on 4H timeframe and tweak it to improve net profit, profit factor and max drawdown." Server: Darwinex-Demo (the
user's choice). Scope (the user's choice): "Inputs, then code": tune inputs first; code changes only on a renamed copy in
the repo, the user's file in MQL5/Experts/Advisors stays untouched.

The EA (user's v1.00, `MQL5/Experts/Advisors/DonchianTrend_EA.mq5`): on each new H4 bar, BUY when the closed bar closes
above the highest high of the 20 bars before it, the bar is bullish, EMA50 > EMA200 and ADX(14) >= 18 (SELL mirrored);
stop 2 x ATR(14), target 1R, 0.25% of equity per trade, one position per symbol, signal skipped if the spread at the bar
open is above 30 points. No trade log: trades are rebuilt from the report's Deals table (`blessing_eval.deals_trades`);
R per trade = net / (0.25% of the balance before entry).

## Runs (`reports/dtrend/dtrend_eval.py`, Darwinex-Demo, USDJPY H4, real ticks, 100k USD, 1:100, the user's GUI settings)
- **Stage 0, baseline:** defaults, 2022-01-01..2026-10-01. Reported: net profit, PF, max equity drawdown (the user's three
  goals), trades, win rate, R by regime (2022-24, 2025-26), longs/shorts, and the number of signals skipped for spread
  (agent log) with their bar times.
- **Stage 1, input grid, two regimes:** MT5 complete-grid optimization on 2022-01-01..2025-01-01 and on
  2025-01-01..2026-10-01, real ticks. Grid (400 passes per launch): `InpDonchianPeriod` 10:10:50, `InpATRStopMultiplier`
  1.5:0.5:3.0, `InpRewardRiskRatio` 1.0:0.5:3.0, `InpMinADX` 10:5:25; `InpAllowShort` true / false as separate launches;
  the rest at defaults. 4 optimizations, 1,600 passes.
- **Selection** (`selection.joint_pick`, per launch, then the better of the two): the same input tuple must have PF >= 1.15,
  >= 20 trades and equity drawdown <= 10% in both regimes, and an average neighbour PF >= 1.05 in both (plateau); ranked
  by the weaker regime's PF x recovery factor, which weighs all three goals (recovery factor = net profit / max drawdown).
- **Stage 1 confirm:** the pick on the full 2022-01..2026-10 window, real ticks, next to the baseline.

## Checks and decision rule
- The pick is recommended only if, on the full window, it beats the baseline on net profit and PF and its max equity
  drawdown is no worse, and it is profitable in both regimes. Otherwise the defaults stay and Stage 1 reports the closest
  tuple.
- Reported, not gated: Gate A (trades >= 150, PF >= 1, net R > 0 in both regimes) and prop_mc alone (--bt-risk 0.25,
  --risk 0.3,0.5, 10k sims, seeds 1-3), for portfolio relevance.
- Stage 2 (code) is pre-registered separately after Stage 1, from evidence in the runs (for example, signals skipped by
  the spread at the 00:00 bar, when the Darwinex spread widens around the rollover).

## Hypothesis
A 20-bar H4 breakout with 3 filters on one pair trades rarely (about 30-60 trades in 4.75 years). Expected: baseline PF
around 1.0-1.2 with a 1R target; a longer target (RR 2-3) improves PF in the trending 2022-24 USDJPY and loses in the
choppier 2025-26; few tuples survive both regimes; the gain over the baseline, if any, is modest; Gate A fails on trade
count.

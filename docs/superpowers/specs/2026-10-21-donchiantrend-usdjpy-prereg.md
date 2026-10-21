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

## Outcome, Stages 0-1 (2026-10-21, Darwinex-Demo, history quality 99%, logs `reports/dtrend/base.log`, `grid.log`)
| full window 2022-01..2026-10 | net profit | PF | max equity DD | trades | win | R 2022-24 / 2025-26 | Gate A | prop_mc @0.3% / 0.5% |
|---|---|---|---|---|---|---|---|---|
| defaults (v1.00) | +4,865.71 | 1.14 | 4.96% | 274 (202 L / 72 S) | 53.6% | +31.4 / -12.1 | fail | 0.0 / 1.3-1.5 |
| shorts-on pick (D 50, ATR 2.5, RR 3.0, ADX 15) | +8,418.93 | 1.51 | 2.73% | 96 | 33.3% | +25.2 / +7.5 | fail (trades) | 0.0-0.1 / 4.6-4.8 |
| **pick: long-only, D 10, ATR 1.5, RR 1.5, ADX 20** | **+14,321.23** | **1.50** | **1.52%** | 213 (all long) | 49.8% | +39.3 / +14.7 | **pass** | 0.6 / 16.7-17.5 |

Grid: every one of the 400 tuples was profitable in 2022-24 (both launches); 2025-26 kept 108 (shorts on) and 138
(long-only). Joint picks: long-only PF 1.50 / 1.48, DD 1.52% / 1.36%, 154 / 59 trades in the two regimes (score 3.97);
shorts on PF 1.57 / 1.37 (score 1.46). **The long-only pick beats the defaults on all three goals and is profitable in
both regimes: recommended.**
- Both picks sit on the edge of the grid (long-only: channel 10 and stop 1.5 x ATR are the minimum values; shorts on:
  channel 50 and RR 3.0 the maximum). The plateau check passed, but the best values may lie outside the grid.
- Long-only on USDJPY carries the 2022-26 uptrend (and the positive long swap of a high-carry pair); a sustained yen
  rally would hit it harder than a two-sided version.
- The 00:00 H4 bar is never traded in any run (1,145 spread skips at 00:xx: the spread check precedes the signal and the
  Darwinex rollover spread exceeds 30 points).
- Runs were interrupted twice by low memory (the 12 tester agents with real ticks): the job was stopped once and one
  optimization crashed; both were rerun and finished optimizations were reused.

## Stage 2, code (pre-registered 2026-10-21, before its runs)
`mql5/DonchianTrend2_EA.mq5` v2.00, a renamed copy of the user's v1.00 (MD5 fd8d758a… before the change; the user's file
is untouched): the signal is evaluated before the spread check, and a signal blocked by the spread is retried on later
ticks of its bar for `InpSpreadWaitMin` minutes (30), entering at the first tick within the cap. Compiled defaults = the
Stage 1 pick plus the retry.
- P1 parity: v2.00 with `InpSpreadWaitMin` 0 and the pick inputs gives the same trades as the v1.00 pick run (count, open
  times, net profit).
- Run: v2.00 with the retry (30 min), full window, same settings. Reported: delayed signals executed and dropped, net,
  PF, max DD, R by regime, Gate A, prop_mc alone.
- Decision rule: the retry ships as the v2.00 default only if P1 passes and it beats the v1.00 pick on net profit and PF
  with max DD no worse, profitable in both regimes. Otherwise v2.00 ships with `InpSpreadWaitMin` 0 (= the pick on v1.00).
- Hypothesis: the 00:00 bar holds about a sixth of the bars; with the retry the trade count rises by 10-20%, at a similar
  R per trade (the delay is minutes on a 1.5 x ATR stop); net rises, PF within +/-0.1, DD similar.

## Outcome, Stage 2 (2026-10-21, log `reports/dtrend/code.log`)
- P1 parity: v2.00 with `InpSpreadWaitMin` 0 = the v1.00 pick (213 / 213 trades, same open times and profits, net
  +14,321.23): **pass**.
- Retry 30 min: net +14,546.39 (+225), PF 1.49 (-0.01), max DD 1.36% (-0.16), 217 trades, R +43.2 / +11.5, Gate A pass,
  prop_mc 0.6 / 17.9-18.6. Only 10 signals ever fell on a 00:00 bar with the pick's filters (all executed, median 7 min
  after the bar open; 0 dropped); the 1,145 skips of v1.00 were bar checks, almost all without a signal.
- **Decision: the retry misses the PF condition, so v2.00 ships with `InpSpreadWaitMin` 0 (= the pick on v1.00).** The
  option stays in v2.00. The pick inputs for the user's own EA: `mql5/DonchianTrend_EA_USDJPY_H4.set` (also saved as
  MQL5/Profiles/Tester/DonchianTrend_EA_USDJPY_H4.set).

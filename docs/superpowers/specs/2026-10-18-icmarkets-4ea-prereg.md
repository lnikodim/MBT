# The 4-EA account on IC Markets data (pre-registration)

Date: 2026-10-18. User: "I've moved the EAs to another account in ICMarkets" (demo 53093587, ICMarketsEU-Demo), then
logged the Mac terminal into it and closed MT5: "yes, do it". Every number the account relies on (Gate A per EA, joint
prop_mc 94.5 / 85.1 at 0.3 / 0.5% per position) was measured on Darwinex-Demo data. This run checks whether those numbers
carry over to IC Markets prices, spreads, commission and swaps.

## Runs (`reports/portfolio/icm_confirm.py`, ICMarketsEU-Demo, real ticks, 2022-01-01..2026-10-01, 1% risk, defaults)
The installed .ex5 files are the exact builds behind the Darwinex control runs (not recompiled), so any difference comes
from the broker data.
| EA | chart | Darwinex control (trades / PF / DD) |
|---|---|---|
| MACD_Cross_EA v1.45 | XAUUSD H1 | `v145_default_20261011_092414`, real ticks: 957 / 1.79 / 29.5% |
| Donchian_Breakout_EA v1.01 | XAUUSD H4 | `donch_a1_pub_20261013_095001`, real ticks: 157 / 1.66 / 10.2% |
| RSI_Reversal_EA v1.20 | XAUUSD H6 | `rsi_ctl_20261014_125232`, real ticks: 358 / 1.56 / 13.3% |
| MA_Channel_EA v1.01 | XAUUSD H1 | `dxc_mach_v101_20261016_143340`, 1-min OHLC: 299 / 1.55 / 12.2% |
The IC Markets tick base starts in 2026, so 2022-25 is ticks generated from M1 bars (history quality is reported). The
server is confirmed from the agent log line of each run.

## Checks
Per EA: (1) Gate A: trades >= 150, PF >= 1.00, net R > 0 in 2022-24 and in 2025-26; (2) consistency: trades within +/-15%
of the Darwinex control and PF >= Darwinex PF - 0.20.
Joint: prop_mc on the 4 IC logs (--bt-risk 1.0, --risk 0.3,0.5, 10k sims, seeds 1-3) next to the Darwinex 4-EA set;
P(pass both phases) at 0.3% >= Darwinex - 5 points on every seed.
Diagnostic only: share of IC entries with a Darwinex entry of the same side within one bar of the EA's timeframe.

## Hypothesis
Both brokers run GMT+2/+3 servers, so bars and most signals should match; IC Markets costs were about 0.005 R per trade
lighter in the MA_Channel Stage A. Expected: all four EAs pass both checks, PFs within +/-0.10, joint within +/-2 points.

## Decision rule
All checks pass: the account numbers carry over to IC Markets (provisional for 2022-25, generated ticks). An EA that fails
Gate A or consistency is flagged to the user, whose call it is whether it stays on the IC account; no retune. If only the
joint check fails, the IC pass probability is the one to quote for this account.

## Outcome (2026-10-18, ICMarketsEU-Demo confirmed in every agent log, history quality 10%, log `reports/portfolio/icm_confirm.log`)
| EA | IC trades / PF / DD | Darwinex trades / PF / DD | IC R 2022-24 / 2025-26 | entries matching Darwinex | checks |
|---|---|---|---|---|---|
| MACD v1.45 H1 | 945 / 1.95 / 29.9% | 955 / 1.79 / 29.5% | +138.9 / +237.0 | 99% | pass |
| Donchian v1.01 H4 | 157 / 1.72 / 8.6% | 157 / 1.66 / 10.2% | +27.1 / +32.4 | 93% | pass |
| RSI_Reversal v1.20 H6 | 347 / 1.63 / 14.2% | 358 / 1.56 / 13.3% | +40.0 / +60.5 | 97% | pass |
| MA_Channel v1.01 H1 | 292 / 1.59 / 12.3% | 299 / 1.55 / 12.2% | +53.9 / +44.6 | 95% | pass |

Joint 4-EA prop_mc, P(pass both phases) at 0.3% / 0.5%: IC 97.2 / 90.0, 97.0 / 89.5, 96.9 / 89.9 vs Darwinex 94.5 / 85.1,
94.6 / 85.3, 94.0 / 85.2 (seeds 1-3); max-loss breach at 0.5% 5.4-5.8% vs 8.1-8.3%; p95 DD at 0.3% 9.8% vs 10.8%.
**All checks pass**: the account numbers carry over to IC Markets, and are better there. The hypothesis held on signals
(93-99% of entries match) but underrated the cost gap. In 2026, the only real-tick year on both servers, IC entries had
median spreads of 5-8 points against 45-59 on Darwinex, and commission was 7.00 USD per lot against about 22.5. The
2022-25 IC part uses generated ticks with similar low spreads, so its exact margin is provisional, but the 2026 real ticks
show the IC cost advantage is real. Side note: on IC the first gold ticks after the daily reopen arrive before trading opens. All 6,619 "market closed"
stop modifications in the batch (MACD and RSI_Reversal, a few MA_Channel) fall at 01:00-01:09 server time, on 102
days; the EAs retry on the next tick, and the 93-99% entry match shows no effect on trades.

# VWAP_EMA_Cross_EA v1.00: Stage A (pre-registration)

Date: 2026-10-12. User rule (verbatim): "when VWAP & 9 EMA cross each other, BUY only when the VWAP is above the
9 EMA and SELL only when the VWAP is under the 9 EMA; deal is closed whenever both lines are crossed again;
timeframe should be 5m; symbol should be XAUUSD".

Design approved in chat 2026-10-12: `mql5/VWAP_EMA_Cross_EA.mq5` on EACore (magic 261012), daily VWAP (server
midnight), EMA(9) on close, protective stop 0.5% of price (sizes the lots and defines R only), no take profit,
close and flip on every cross evaluated on closed M5 bars, one position at a time, `InpInvert` for the opposite
(momentum) reading. Guards: spread 150 pts, daily -4%, monthly -12%.

## Runs
XAUUSD M5, real ticks, 2022-01-01 .. 2026-10-01, compiled defaults, 100k deposit:
- A `vwapema_asis`: InpInvert=false (as specified: VWAP above EMA = BUY)
- B `vwapema_inv`: InpInvert=true

## Gate A (per run, decided before the runs)
1. trades >= 150
2. tester profit factor >= 1.00
3. net R > 0 in both 2022-24 and 2025-26 (prop_mc by-year table)
A run that passes goes to `prop_mc --risk 0.3,0.5 --sims 10000 --seed 1`; it is useful only if the pass
probability is >= the MACD v1.45 bar (80.4% at 0.3%, 81.2% at 0.5%).

## Expectation written before the runs
Profit factor below 1 in both directions: an M5 VWAP/EMA(9) cross flips several times a day and every flip pays
the spread (about 8-10% of a 0.5% stop). If Gate A fails, the deliverable is the EA and this negative result; no
filters are added without a new pre-registration.

## Outcome
(filled in after the runs)

## Outcome (2026-10-12, real ticks 2022-01-01..2026-10-01, XAUUSD M5, 100k, 1% risk)

| | A as specified (VWAP above EMA = BUY) | B inverted |
|---|---|---|
| Trades | 8048 | 7899 |
| Tester PF / net | 0.72 / -97,695 | 0.93 / -62,865 |
| Win rate | 67.6% | 23.0% |
| Net R, by prop_mc | -367.9 (every year negative) | -73.0 (2026 +29.4, other years negative) |
| Gross P&L before commission and swap | -77,782 (gross PF 0.77) | -11,382 (gross PF 0.99) |
| Commission + swap paid | -19,913 | -51,483 |
| Median holding time | 70 min | 85 min |
| Stop-outs | 1493 | 256 |
| prop_mc pass 0.3% / 0.5% | 0.0% / 0.0% | 5.5% / 16.3% |

Gate A: both runs FAIL on PF >= 1.00 and on positive net R in both regimes (A has no positive year; B only 2026).
The self-check window (Jan-Feb 2026) had shown PF 1.19 for A: two months of an M5 system are noise.

Verdict: CLOSED. The EA stays in the repo as a tool; no filters without a new pre-registration.

## Amendment 1 (2026-10-12, before the runs): M15
User: "what about running it on M15 instead of M5". Same EA, `InpTimeframe=15`, everything else unchanged,
same two directions (`vwapema15_asis`, `vwapema15_inv`), same window and Gate A. Expectation: roughly a third
of the trades, so a smaller cost share; the sign of the edge is not expected to change.

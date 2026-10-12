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

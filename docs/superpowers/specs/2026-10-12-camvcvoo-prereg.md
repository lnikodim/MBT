# Camvcvoo_EA v1.00: Stage A (pre-registration)

Date: 2026-10-12. The user supplied `camvcvooV5.mq4` ("H1 GBPUSD EA", O3 Power Ltd, 2010) and asked to try it.

Rules as read from the file: one entry window a day (broker hour = 23:00 GMT + a fixed offset input = 01:00);
BUY when the H1 SMA(197) and SMA(10) both rose on the last closed bar, an M5 lower fractal sits 3 M5 bars back and
the latest M15 fractal is an upper one; SELL mirrored. Three positions at once, stop 140 pips on all, targets
22 / 50 / 80 pips; position 2 trails 22 pips behind price once 22 pips in profit; position 3 moves its stop once to
lock 12 pips at the same trigger; position 1 untouched. One set at a time, no hedging, one set per H1 bar.
Fixed 0.1 lots by default. Daily level lines and the panel are display only.

Port (design approved in chat): `mql5/Camvcvoo_EA.mq5` on EACore (magic 261014, compiled default H1, spread cap
20 points, no pending retry). Evaluated on each new M5 bar inside the trade hour (the original checked every tick).
Each position at the EA's risk % (1%), MACD stacking convention: a full stop-out of a set is 3R. Roles by target
distance. Deviations: server-side SL/TP; the trade hour is a plain server hour (no DST handling, as the original).

## Runs
- A `camv_a`: GBPUSD H1, 1-min OHLC, 2022-01-01 .. 2026-10-01, compiled defaults, 100k, 1% risk per position.
  (Darwinex GBPUSD real ticks exist only from 2024-01-02; a pass is confirmed on real ticks 2024-01-02 .. 2026-10-01.)

## Gate A (decided before the run)
1. positions >= 150
2. tester profit factor >= 1.00
3. net R > 0 in both 2022-24 and 2025-26 (prop_mc by-year)
A pass goes to `prop_mc --risk 0.3,0.5` (per-position risk, as for MACD stacking) and the real-tick confirmation;
useful only if the pass probability is >= the MACD v1.45 bar (80.4% / 81.2%).

## Expectation written before the run
Fail, PF about 0.9: a 22-pip target against a 140-pip stop needs an 86% hit rate on leg 1, and fixed-pip 2010
settings rarely survive 2022-26. If it fails, the deliverable is the port and this negative result.

## Outcome
(filled in after the run)

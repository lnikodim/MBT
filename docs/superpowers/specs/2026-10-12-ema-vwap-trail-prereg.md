# EMA_VWAP_Trail_EA v1.00: Stage A (pre-registration)

Date: 2026-10-12. The user pasted the Pine strategy "EMA 9 + VWAP Strategy with ATR Trailing Stop" and asked for an
MT5 EA; backtest spec from the user: "use XAUUSD on a M15 with a modelling 1 min OHLC".

Port (design approved in chat): `mql5/EMA_VWAP_Trail_EA.mq5` on EACore (magic 261013, compiled default M15).
Long when EMA(9) crosses above the daily VWAP, short when it crosses below, each entry reversing the open position.
Initial stop k x ATR(14) from entry (k = 2, sizes the lots, R = k x ATR); on every closed bar the stop is
ratcheted to close -/+ k x ATR (the script's plotted stop lines). `InpTrailAfterProfit=true` reproduces
strategy.exit's trail_points activation (trailing only after +k x ATR). No take profit. Known deviations:
Pine's trail_points/trail_offset are tick units (cents on gold as written) so the plotted intent is implemented;
MT5 ATR is a simple average of true range, Pine's is Wilder-smoothed.

## Runs
XAUUSD M15, 1-min OHLC, 2022-01-01 .. 2026-10-01, compiled defaults, 100k, 1% risk:
- A `emavwap_entry`: InpTrailAfterProfit=false (plotted lines)
- B `emavwap_profit`: InpTrailAfterProfit=true (strategy.exit activation)
- C `emavwap_ref`: VWAP_EMA_Cross_EA InpInvert=true InpTimeframe=15, same model: the same entry with the fixed
  0.5% stop and cross-only exit, so A/B minus C isolates the trailing stop.

## Gate A (per run, decided before the runs)
1. trades >= 150
2. tester profit factor >= 1.00
3. net R > 0 in both 2022-24 and 2025-26 (prop_mc by-year)
A run that passes goes to `prop_mc --risk 0.3,0.5 --sims 10000 --seed 1`; useful only if the pass probability
is >= the MACD v1.45 bar (80.4% / 81.2%).

## Expectation written before the runs
Profit factor 0.9-1.05 for A and B: the entry showed no edge on M15 real ticks (C: PF 0.99), and an ATR trail
usually trades a few large cross-to-cross winners for many smaller ones. If Gate A fails, the deliverable is the
EA and this negative result; no filters without a new pre-registration.

## Outcome
(filled in after the runs)

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

## Outcome (2026-10-12, XAUUSD M15, 1-min OHLC, 2022-01-01..2026-10-01, 100k, 1% risk)

| | A trail from entry | B trail after +k x ATR | C reference: fixed 0.5% stop, cross exit |
|---|---|---|---|
| Trades | 4580 | 4365 | 5021 |
| Tester PF / net | 0.85 / -80,853 | 0.87 / -80,386 | 1.04 / +54,772 |
| Win rate | 33.9% | 38.4% | 29.8% |
| Net R 2022-24 / 2025-26 | -155.6 / +21.0 | -135.3 / +7.0 | -12.9 / +79.7 |
| Stop exits in profit (self-check window) | 34 of 105 | 40 of 86 | n/a |
| prop_mc pass 0.3% / 0.5% | 6.9% / 13.2% | 8.4% / 15.1% | 28.0% / 46.4% |

A, B: FAIL (PF < 1, 2022-24 negative). C: FAIL on gate 3 (2022-24 net R -12.9, 2023 -38.7) although PF 1.04.
The ATR trailing stop is the script's only addition to the cross entry and it costs about 200 R over the period:
it exits the cross-to-cross winners early (same lesson as MACD_Cross_EA's trailing stop). Pine's
trail-after-profit activation changes little (B vs A).
Model note: the same reference ran PF 0.99 on real ticks (2026-10-12 VWAP_EMA amendment 1) vs 1.04 on 1-min
OHLC: this model flatters an M15 stop system by about 0.05 PF.
Self-check with the loss guards off: 148 entries in all three runs, identical times and sides (port verified).

Verdict: CLOSED. EA kept in the repo as a tool; no filters without a new pre-registration.

## Amendment 1 (2026-10-12, before the runs): optional entry filters (v1.01)
User: backtest the video's optional filters to improve the win rate: 200 EMA trend filter, higher-timeframe bias,
session filter. Definitions approved in chat: `InpTrendEMA=200` (signal-bar close vs EMA200 on M15, longs above,
shorts below); `InpHTFBias=H4` with `InpHTFEMA=200` (last closed H4 bar vs its EMA200; H1 as a variant);
`InpSessionStart=10, InpSessionEnd=23` server hours (London open to about an hour before the NY close).
Exits unchanged: a cross still closes the opposite position; filters only gate the new entry.
Runs (`emavwap_f_*`): all 8 on/off combinations of E (trend), H (H4 bias), S (session) on the trail-from-entry
variant, plus `H1` (H1 bias alone); XAUUSD M15, 1-min OHLC, 2022-01-01..2026-10-01, 1% risk.
Gate: unchanged (trades >= 150, PF >= 1.00, net R > 0 in 2022-24 and 2025-26); win rate reported, not a gate.
Expectation: trend filters raise the win rate a few points and cut trades by a third or more; the session filter
least likely to matter. Whether PF reaches 1.0 is the open question.

### Amendment 1 outcome (2026-10-12)

```
run    trades    PF  win%    netR  R22-24  R25-26   p0.3   p0.5  gate
none     4580  0.85  33.9  -134.7  -155.6   +21.0   6.9%  13.2%  fail
E        2636  0.88  33.3   -55.9  -101.1   +45.2   7.9%  16.6%  fail
H        2493  0.95  34.5   -20.4   -76.1   +55.7   8.8%  20.7%  fail
S        1776  0.84  32.1   -97.3   -62.1   -35.3   1.0%   5.7%  fail
EH       1766  1.01  34.6   +15.9   -43.2   +59.1  10.7%  25.1%  fail
ES       1142  0.80  31.6   -92.2   -50.2   -42.0   0.2%   1.9%  fail
HS        878  0.96  33.7    -6.7   +10.9   -17.7   1.4%   9.2%  fail
EHS       685  0.93  32.5   -15.7    -3.2   -12.6   0.5%   5.2%  fail
H1       2471  0.99  35.2   +15.9   -40.8   +56.7  16.0%  27.9%  fail
```
E = trend EMA200 (M15), H = H4 EMA200 bias, S = session 10-23 server, H1 = H1 EMA200 bias alone; p0.3/p0.5 = prop_mc pass.
No combination passes. The trend filters (E, H, EH, H1) lift net R from -135 to about +16 by removing half the
trades, but 2022-24 stays negative in every run except HS, which then loses 2025-26. The session filter hurts
everywhere. The win rate barely moves (32-35% in all nine runs): with a 2 x ATR trailing exit the win rate is a
property of the exit, not of the entry, so entry filters cannot raise it. CLOSED; nothing further without a new spec.

## Amendment 2 (2026-10-12, before the runs): trailing stop off (v1.02)
User: "what about removing the ATR trailing stop". `InpTrailATR=false`: the initial 2 x ATR stop stays (sizing and
protection) but is never ratcheted; exits are that stop or the opposite cross. Same nine runs as amendment 1
(`emavwap_nt_*`), same window, model and gate. Expectation: the unfiltered run lands near the fixed-stop reference
(PF about 1.0, 2022-24 negative); EH / H1 may reach PF 1.05-1.10 but 2023 is expected to stay negative.

### Amendment 2 outcome (2026-10-12, trail off)

```
run    trades    PF  win%    netR  R22-24  R25-26   p0.3   p0.5  gate
none     4057  1.04  27.3  +123.5   -35.4  +159.0  47.0%  43.0%  fail
E        2442  1.16  27.4  +187.8   +84.0  +103.8  57.2%  53.1%  PASS
H        2309  1.17  28.3  +180.8   +56.5  +124.3  57.5%  56.2%  PASS
S        1749  0.98  29.9   +10.9   -39.5   +50.4  18.8%  30.8%  fail
EH       1721  1.26  28.7  +211.2  +102.2  +109.0  64.4%  68.2%  PASS
ES       1140  0.96  31.1    -7.7   -23.5   +15.9   8.9%  22.7%  fail
HS        878  1.20  33.0  +103.9   +59.9   +44.1  31.9%  54.6%  PASS
EHS       685  1.17  33.0   +69.5   +32.9   +36.5  17.9%  40.3%  PASS
H1       2336  1.27  28.8  +262.2  +114.9  +147.3  71.0%  65.1%  PASS
```
Six of nine pass Gate A. Without the trail the cross-to-cross exit keeps the winners (net R +124 unfiltered vs
-135 with the trail) and every trend-filtered run is positive in both regimes. Best: H1 bias (PF 1.27, +262 R,
prop_mc 71.0% / 65.1%) and EMA200 + H4 bias (PF 1.26, +211 R, 64.4% / 68.2%). Both are below the MACD v1.45 bar
(80.4% / 81.2%). Session filter still hurts. Win rate 27-33%: the exit sets it, as before.
Caveats: 1-min OHLC flattered this system by ~0.05 PF earlier; 18 exit x filter combinations were run, so the
pattern (trend filter + cross exit) is the finding, not any single cell.

## Amendment 3 (2026-10-12, before the runs): real-tick confirmation of the passing cells
Runs `emavwap_rt_{H1,EH,E,H}`: same inputs (InpTrailATR=false + filter), XAUUSD M15, real ticks, 2022-01-01..2026-10-01.
Gate: Gate A again on real ticks; a cell is confirmed if it passes and its prop_mc pass at 0.5% is within 10
points of the OHLC value. Expectation: PF about 0.05 lower, H1 and EH still pass, E and H borderline.

### Amendment 3 outcome (2026-10-12, real ticks, trail off)

```
run    trades    PF  win%    netR  R22-24  R25-26   p0.3   p0.5  gate
H1       2299  1.17  28.0  +185.0   +61.8  +123.2  57.7%  53.9%  PASS
EH       1708  1.17  28.0  +156.4   +68.4   +88.0  51.4%  56.5%  PASS
E        2325  1.07  26.6  +113.1   +33.6   +79.5  43.0%  43.1%  PASS
H        2272  1.06  27.6   +95.2    +3.8   +91.4  40.8%  43.8%  PASS
```
All four pass Gate A on real ticks (PF 1.06-1.17, both regimes positive, 1708-2325 trades). The pre-registered
confirmation rule (pass at 0.5% within 10 points of the OHLC value) is missed by 11-12 points for H1, EH and H
and met exactly for E: 1-min OHLC overstated this system by about 0.10 PF and 10-12 points of pass probability,
so only the real-tick numbers count from here. Best real-tick cell: H1 bias, PF 1.17, +185 R, prop_mc 57.7% /
53.9% at 0.3% / 0.5%, hist DD 49% at 1% risk. That is 23-27 points below the MACD v1.45 bar (80.4% / 81.2%), so
not adopted as a challenge EA. Win rate 27-28% in every cell.
Verdict: positive system, below the bar. v1.02 defaults stay as the Pine port (trail on, filters off); the
passing configuration is `InpTrailATR=false InpHTFBias=H1` (or `InpTrendEMA=200 InpHTFBias=H4`). Nothing further
without a new pre-registration.

## Amendment 4 (2026-10-12, before the runs): MACD-style stacking (v1.03)
User: "what about adding the stacking cap like MACD". Crosses alternate, so stacking needs MACD's other half too:
`InpHoldThroughFiltered=true` (a cross whose new side the filter rejects does not close the position; exits are the
2 x ATR stop or the next allowed opposite cross, which closes everything and reverses) and `InpMaxPositions`
(trend-direction crosses add positions up to the cap, 1% risk each). Defaults off; v1.02 behaviour unchanged.
Runs on the confirmed best cell (InpTrailATR=false, InpHTFBias=H1), XAUUSD M15, real ticks, 2022-01-01..2026-10-01:
`emavwap_st_hold1` (hold on, cap 1), `emavwap_st_cap2`, `emavwap_st_cap3`.
Gate: Gate A, and prop_mc at 0.3% / 0.5% above the confirmed H1 cell (57.7% / 53.9%) to count as an improvement;
the MACD v1.45 bar (80.4% / 81.2%) remains the measure of usefulness.
Expectation: worse. The counter-trend cross exit is part of the trail-off edge; holding through it converts some
of those exits into full 1R stop losses, and stacking multiplies the same bet.

### Amendment 4 outcome (2026-10-12, real ticks, trail off, H1 bias)

```
run    trades    PF  win%    netR  R22-24  R25-26   p0.3   p0.5  gate
hold1     563  1.05  10.3   +94.8   +42.7   +52.0  29.7%  25.0%  PASS
cap2      797  1.27  10.2  +163.8   +68.6   +95.1  30.5%  21.0%  PASS
cap3      959  1.22  10.3   +81.9   -17.9   +99.8  23.4%  16.1%  fail
```
| | confirmed H1 cell | hold1 | cap2 | cap3 |
|---|---|---|---|---|
| Tester PF / net | 1.17 / +285,960 | 1.05 / +25,179 | 1.27 / +382,665 | 1.22 / +345,983 |
| Win rate | 28.0% | 10.3% | 10.2% | 10.3% |
| Hist DD at 1% risk | 48.9% | 58.5% | 69.2% | 74.6% |
| MC p95 DD at 0.5% | 35% | 53.5% | 54.5% | 61.3% |
| prop_mc pass 0.3% / 0.5% | 57.7% / 53.9% | 29.7% / 25.0% | 30.5% / 21.0% | 23.4% / 16.1% |

Rejected. Holding through filtered crosses (hold1) replaces the cross exit with 1R stop-outs: win rate 28% -> 10%,
pass probability halves. Stacking on top (cap2) recovers the in-sample PF (1.27) by pyramiding the few long
trends but with correlated risk: p95 drawdown 54% and pass 21% at 0.5%. cap3 fails Gate A (2022-24 negative).
The confirmed H1 cell (one position, cross exit) stays the best configuration of this EA. CLOSED.

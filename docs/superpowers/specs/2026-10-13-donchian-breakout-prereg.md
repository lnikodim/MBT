# Donchian_Breakout_EA v1.00: Stage A (pre-registration)

Date: 2026-10-13. The user asked for a completely new strategy (not derived from any EA on the Mac), chosen after
internet research for "the most profitable and high win rate" approaches, then backtested on the MT5 tester.

Research summary (sources in `~/.claude/plans/you-are-top-automation-crystalline-pixel.md`): on gold the only family
with independent multi-year evidence is breakout trend following (open-source Donchian 20-bar H4 + EMA200 on
2020-26 every-tick: PF 1.77, 47% win, 198 trades; EMA swing D1 PF 1.85 at 38% win). Opening-range breakouts go to
zero after spread on CFDs. The 68-76% win-rate gold systems are daily-bar mean reversion with 0.3-0.7% per trade
and 3-8% CAGR; the same structure on H1 failed here (MeanRev_EA RSI2, PF 1.08) and the two high-win-rate EAs on
this Mac (HoLo, Camvcvoo) lost money. So this EA targets expectancy and prop-pass probability; the win rate is an
outcome, expected 40-50%.

Rules: on each new closed H1 bar, BUY when close[1] is strictly above the highest high of the previous N = 48 bars
(bars 2..N+1) and the last closed H4 bar is above its EMA200; SELL mirrored. Stop = 2 x ATR(14, H1, closed bar),
target = 3 x stop, break-even once at +1R locking +0.2R, no trailing. One position at a time, one entry per bar,
opposite signals ignored while in a position. Compiled default `EA_SPREAD_WAIT_MIN 0` (a spread-blocked signal is
dropped so TP = 3 x stop holds exactly).

Build: `mql5/Donchian_Breakout_EA.mq5` on EACore (magic 261015, comment DONCH, H1). Not in v1.00: time-of-day
session filter, long-only, stacking, channel exit (each needs an amendment below).

## Runs
- A `donch_a`: XAUUSD H1, real ticks, 2022-01-01 .. 2026-10-01, compiled defaults, 100k, 1:20, 1% risk.

## Gate A (decided before the run)
1. trades >= 150
2. tester profit factor >= 1.00
3. net R > 0 in both 2022-24 and 2025-26 (prop_mc by-year)
A pass goes to `prop_mc --risk 0.3,0.5 --sims 10000 --seed 1`; adopted stand-alone only if the pass probability is
>= the MACD v1.45 bar (80.4% / 81.2%), otherwise judged combined with MACD (`combine_eas.py`). A pass also unlocks
Stage B: 27-cell grid (N 24/48/96 x stop 1.5/2/3 ATR x target 2/3/4 R) on 1-min OHLC 2022-01..2025-01,
`selection.pick_plateau` (neighbour mean PF >= 1.10, >= 150 trades, DD <= 20%), one confirmation of the pick on
2025-01..2026-10 real ticks.

## Expectation written before the run
PF 1.3-1.6, 200-350 trades, win rate 40-50%, profit concentrated in 2024-26 with 2022-23 near flat, sells weaker
than buys, prop_mc pass 40-65% (an H1 channel trades less often than MACD's stacked crosses). Caveat: 2022-26 is a
gold bull regime and the defaults were chosen from published tests, so the run is in-sample for the family.

## Outcome (2026-10-13, XAUUSD H1, real ticks, 2022-01-01..2026-10-01, 1% risk, `reports/donch_a_20261013_094324`)

| | donch_a |
|---|---|
| Trades | 503 (332 buys, 171 sells), 8.9 per month |
| Tester PF / net | 1.07 / +18,020 (+21.6 R) |
| Win rate | 46.9%: 87 targets (+257 R), 153 break-even scratches (+26.7 R, about +0.17 R each), 262 full stops (-263 R) |
| Equity DD | 30.5% at 1% risk |
| Net R 2022-24 / 2025-26 | -21.2 / +42.9 |
| By year PF | 2022 0.82, 2023 0.94, 2024 0.86, 2025 1.59, 2026 1.30 |
| prop_mc pass 0.3% / 0.5% | 1.3% / 12.2% (MC p95 DD 11.9% / 19.1%) |

FAIL on criterion 3 (2022-24 negative). Buys +20.4 R (2022-24 -20.4, 2025-26 +40.8), sells +2.0 R (-0.9 / +2.9).
The profit is the 2025-26 gold trend; in 2022-24 a 48-bar H1 channel breakout has no edge on either side. The
expectation (PF 1.3-1.6, 2022-23 near flat) was wrong on both counts. Entry-hour diagnostic (not a rule): buys
entered outside 02:00-10:00 NY +28.4 R (PF 1.26), inside -8.0 R (PF 0.89); sells inside 02:00-10:00 NY -6.3 R
(PF 0.84), the opposite of the thesis's "short during London hours". A thesis-based session filter would remove
about 14 R of losses and still leave 2022-24 negative, so it is not a candidate. Self-check (Jan-Feb 2026): 18
trades, 20 signals (2 dropped by the 150-point spread guard), all invariants held. Stage B not unlocked.
CLOSED unless an amendment is pre-registered below.

## Amendment 1 (2026-10-13, before the runs): the published H4 configuration as-is

The v1.00 defaults were my H1 adaptation. The externally documented configuration (MQL5 code base 77691, XAUUSD
H4 2020-26 every-tick, no commission: PF 1.77, 47% win, 198 trades, 6 of 7 years positive, 2022 +4.6%, 2023 +4.8%,
2024 +24.0%) is tested as published, not tuned: H4, 20-bar channel, stop 2 x ATR(20), target 2R, long-only,
H4 EMA200 filter, no break-even. A second cell adds the EA's one deviation, the v1.00 break-even (+1R lock 0.2R),
because every MACD test on this data showed a break-even at about +1R to be essential. Both cells are reported.

### Runs
- `donch_a1_pub`: XAUUSD H4, real ticks, 2022-01-01..2026-10-01, 100k, 1:20, 1% risk; InpTimeframe H4,
  InpChannelBars 20, InpATRPeriod 20, InpStopATR 2.0, InpTargetR 2.0, InpAllowShort false, InpTrendTF H4,
  InpTrendEMA 200, InpBreakEvenR 0.
- `donch_a1_be`: the same with InpBreakEvenR 1.0, InpBELockR 0.2.

### Gate A (unchanged)
trades >= 150; tester PF >= 1.00; net R > 0 in both 2022-24 and 2025-26; then prop_mc at 0.3% / 0.5% against the
MACD v1.45 bar (80.4% / 81.2%). The published rate (about 30 trades a year) gives roughly 140 trades in 4.75
years: a cell under 150 trades is "insufficient sample", not a pass, even if the other criteria hold.

### Expectation written before the runs
Darwinex real ticks with commission versus MetaQuotes generated ticks without: PF 1.2-1.5, 120-160 trades,
2022-24 slightly positive (the published years were +5, +5, +27 R-equivalents), 2025-26 positive, prop_mc pass
15-40% (too few trades a month to reach +10% within a year). The break-even cell: fewer full stops, lower PF
on targets, net R about the same.

### Amendment 1 outcome (2026-10-13, XAUUSD H4, real ticks, 2022-01-01..2026-10-01, 1% risk)

| | donch_a1_pub (as published) | donch_a1_be (+ break-even) |
|---|---|---|
| Trades | 157 (all buys) | 173 |
| Tester PF / net | 1.66 / +68,120 (+53.7 R) | 1.44 / +34,997 (+31.3 R) |
| Win rate | 48.4% (76 targets, 81 stops, no scratches) | 56.1% (53 targets, 73 full stops, 47 break-even scratches) |
| Equity DD | 10.2% | 13.0% |
| Net R 2022-24 / 2025-26 | +19.3 / +34.4 | +9.1 / +22.2 |
| By year PF | 2022 0.77, 2023 1.15, 2024 2.30, 2025 2.25, 2026 1.74 | 0.59, 0.92, 2.13, 1.90, 1.72 |
| prop_mc pass 0.3% / 0.5%, alone | 0.2% / 13.8% (breach 0%, p95 DD 7% at 0.5%) | 0.0% / 1.9% |
| prop_mc pass merged with MACD v1.45 | 86.8% / 83.4% (MACD alone, same seed: 80.6% / 80.9%) | 83.8% / 81.9% |

Both cells PASS Gate A (>= 150 trades, PF > 1, both regimes positive). As published is the better cell on every
count: the break-even turns 47 stops into +0.2 R scratches but costs 23 targets, because a 2R target is too close
for an early lock (the same lesson as MACD's early break-even and partial-TP tests). Stand-alone the H4 EA is far
below the MACD bar: at 2.8 trades a month 80% of phase-1 simulations time out (0% breach). Combined with MACD v1.45
at equal risk per trade it raises the pass probability by 6.2 / 2.5 points, lowers the breach rate at 0.5% from
9.2% to 8.6%, shortens the calibration median from 95 to 78 days and lifts return/DD from 60 to 96; monthly
correlation 0.46 (`combine_eas.py`, reports `donch_a1_pub_20261013_*`, `donch_a1_be_20261013_*`). Caveats: 157
trades is just over the minimum, 2022 is negative (-4.3 R), and the published settings come from the same
gold-bull years, so the family is in-sample. Stage B (plateau) is unlocked but not run. v1.01 makes the
as-published cell the compiled default (H4, N 20, ATR 20, 2R, long-only, break-even off).

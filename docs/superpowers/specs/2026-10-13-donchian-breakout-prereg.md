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

## Outcome
(filled in after the run)

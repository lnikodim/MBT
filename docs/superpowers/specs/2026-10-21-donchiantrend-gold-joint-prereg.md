# DonchianTrend_EA (USDJPY H4 pick) added to the gold live set (pre-registration)

Date: 2026-10-21. User: "run the joint test with the gold EAs", after the DonchianTrend_EA tuning (spec
2026-10-21-donchiantrend-usdjpy-prereg.md). No new tester runs: all inputs are existing Darwinex-Demo real-tick runs over
2022-01-01..2026-10-01, so the server question does not arise.

## Inputs
- **Gold live set** (Darwinex real ticks, 1% risk, release builds, joint 93.7-94.1 / 84.2-84.7):
  MACD_Cross_EA v1.46 H1 `macdtf_h1_20261019_210429`, Donchian_Breakout_EA v1.02 H4 `lowtf_donch_h4_20261019_212257`,
  RSI_Reversal_EA v1.21 H6 `lowtf_rsi_h6_20261019_213004`, MA_Channel_EA v1.02 H1 `lowtf_mach_h1_20261019_214347`.
- **DonchianTrend pick** on the user's v1.00 (long-only, channel 10, ATR stop 1.5, RR 1.5, ADX 20), USDJPY H4, 0.25%
  risk: `dtrend_pick_20261021_073858` (213 trades, +54.0 R). R per trade = net (incl. swap and commission) / 0.25% of the
  balance before entry, as prop_mc reads a report.
All five use the same server clock (Darwinex, UTC+2 with US DST), so their days line up.

## Runs (`reports/portfolio/dtrend_joint.py`)
prop_mc on close_time,R files (--risk 0.3,0.5, 10k sims, seeds 1-3, FTMO 2-step defaults), P(pass both phases):
1. gold 4-EA (control; reproduces the live joint);
2. gold 4-EA + DonchianTrend;
3. DonchianTrend alone (reproduces 0.6 / 16.7-17.5).
Each on the full window and on 2025-01..2026-10 only (reported).

## Checks
- **Decision:** gold-4 + DonchianTrend >= gold-4 at 0.3% on all 3 seeds (full window).
- **Exposure (gated for a candidate):** the most positions open at once on gold-4 + DonchianTrend, times 0.3%, stays below
  FTMO's 5% daily limit; and the worst closed-trade day in R for gold-4 + DonchianTrend is reported next to gold-4's.
- Reported: daily R correlation between the gold set and DonchianTrend (days on which either closed a trade); p95 MC
  drawdown and the max-loss breach rate at 0.5%; trades, PF and net R of each set.

## Hypothesis
A long-only USDJPY trend follower and the gold set share little: expected daily R correlation |rho| < 0.1. DonchianTrend
adds about 45 trades a year at +0.25 R each. Expected: the joint at 0.3% rises by 0.5-2 points and at 0.5% by 1-3 points;
most positions open at once rises from 8 to 9 (2.7% open risk at 0.3%).

## Decision rule
DonchianTrend is a candidate for the live account only if the decision check and the exposure check pass. The live
account is IC Markets; before deployment a candidate needs its USDJPY run on IC Markets (the user switches the terminal
to IC; never from a script), pre-registered separately, with the same decision check on the IC gold logs. Otherwise
DonchianTrend stays off the gold account. Caveat for any result: the pick and the gold EAs were tuned on this window,
so the joint gain is in-sample.

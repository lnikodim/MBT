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

## Outcome (2026-10-21, log `reports/portfolio/dtrend_joint.log`; verified by an independent recomputation and a skeptic review)
| set | trades | PF | P(pass both) 0.3% / 0.5%, seeds 1-3 | p95 MC DD 0.3 / 0.5 | max-loss breach ph1 @0.5% |
|---|---|---|---|---|---|
| gold 4-EA (control) | 1773 | 1.60 | 94.1/84.2, 93.9/84.7, 93.7/84.2 | 10.9% / 17.6% | 8.8% |
| **gold 4-EA + DonchianTrend** | 1986 | 1.59 | **95.7/87.0, 95.8/87.5, 96.0/86.6** | 10.5% / 17.2% | 6.9% |
| DonchianTrend alone | 213 | 1.51 | 0.6/16.8, 0.6/16.7, 0.6/17.5 | 4.2% / 6.9% | 0.0% |
2025-26 only: gold 99.5/95.2, 99.3/95.2, 99.4/95.1 vs + DonchianTrend 99.4/95.4, 99.6/95.3, 99.5/95.4 (no gain; near the ceiling).
Daily R correlation -0.022 over 956 days; most positions open 8 -> 9 (2.7% open risk at 0.3%); worst closed-trade day
-7.16 R -> -8.13 R (2024-10-08).

**Decision check PASS (+1.6 to +2.3 points at 0.3%, +2.4 to +3.3 at 0.5%), exposure check PASS: DonchianTrend is a
candidate under the rule. Next step is the IC Markets USDJPY run, which needs the user to switch the terminal.** The
hypothesis held (correlation, positions); the gain at 0.3% came in at the top of the forecast range.

The verification found that the rule is weak, so the gain is mostly in-sample:
- **The rule passes almost any positive edge.** It passes whenever DonchianTrend averages more than about +0.065 R per
  trade, a quarter of the pick's +0.253. The untuned defaults pass it too (94.6/94.4/94.3, rechecked), although they
  failed Gate A.
- **Zero edge would cost** 0.3-1.0 points at 0.3%.
- **The pick's 2025-26 result is selection.**
  - In 2025-26 the pick ranks 1st of the 400 long-only tuples, where the median tuple has PF 0.95 (rechecked).
  - In 2022-24 it ranks 126th; every tuple was profitable there.
  - Choosing the top 10-20 tuples on 2022-24 gives about +0.05 R per trade in 2025-26, just under the break-even edge
    (skeptic's walk-forward proxy, not rechecked).
- **Floating losses**, which prop_mc does not see:
  - Closed losses plus every open position at -1 R peak at -9.1 R on one day. That is 2.7% at 0.3%, under the 5% daily
    limit.
  - With gap losses (down to -2.07 R) the same day stays under 5% at 0.3% but exceeds it at 0.5%.

What follows:
- **Live settings.** Run at 0.3%, not 0.5%. Live needs the .set loaded (the compiled defaults are not the pick), then
  `InpRiskPercent` 0.3.
- **Isolation and guards.** The EA's one-position check counts any USDJPY position on the account; none of the gold EAs
  trade it. It has no daily-loss guard.
- **IC Markets confirmation.** The IC run is the same pick on the same window, so it can confirm costs and swap (swap is
  +6.6 R of the +54 R) but not the edge. The IC run's pre-registration should add an out-of-sample condition.

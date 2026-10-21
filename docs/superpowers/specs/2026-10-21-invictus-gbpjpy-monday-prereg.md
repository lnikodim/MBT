# Invictus_GBPJPY_Monday_EA on GBPJPY (pre-registration)

Date: 2026-10-21. User: "test …/Downloads/InvictusGBPJPYMon.mq5, here are the rules:
https://www.mql5.com/en/code/77835". Server: Darwinex-Demo (user rule: always the first choice for backtests).

**The EA:** "Buy GBPJPY Every Monday" by Tomasz Wojciech Forszpaniak ("Orangutang Trading"), v1.30, MD5 f95e8067….
It is copied unchanged to `mql5/Invictus_GBPJPY_Monday_EA.mq5` and renamed per the naming convention. It compiles with
0 errors and 0 warnings. A one-second timer reads only the server clock:
- **Entry:** buy at Monday 11:00 server time, or up to 5 minutes late.
- **Exit:** close at 23:00 server time the same day. There is no stop and no target, and the EA is flat before the
  rollover, so it pays no swap.
- **Guards:** it skips the day if the spread is over 1.5 pips or margin level would fall under 300%. One attempt a day.
- **Day mask:** `InpDayMask` picks the weekdays (Mon=1, Tue=2, Wed=4, Thu=8, Fri=16).

**Server clock:** the EA is built for GMT+2 winter / GMT+3 summer with US DST, where 11:00-23:00 server is 04:00-16:00
New York. Darwinex runs the same clock (UTC+2 with US DST; spec 2026-10-20-orb-fx), so the hours stay as written.

**Author's claim** (code page: 2022-01-01..2026-09-17, 10k account, 0.2 lot, $6 per lot fees, H1 chart):
- +52.9% net, PF 1.86, max DD 7.05%, win rate 59.1%, 242 trades.
- Robust: still profitable with the entry anywhere from 09:00 to 13:00 server.
- The author's own suggested control: run the same trade on Tuesday to Friday and compare.

**Review before the run** (kept, as the file runs as written):
- **No stop.** A 12-hour hold takes any move in full; a yen intervention or BoE/BoJ day hits it with no limit.
- **A failed close is not retried until the next day's 23:00.** If all 3 close attempts fail (an early close on a
  holiday, a requote storm), the next check is the following day at 23:00, and the position holds overnight with swap.
  This matters live, not in the tester. The tester shows it as a hold longer than 12 hours.
- **Selection.** The author says the pattern was found by scanning ("how you can on MT5 find these patterns"). The
  published window, 2022-01..2026-09, is the window it was found in, which is also our standard test window. A run
  there only replicates the claim; it is not evidence of an edge.

## Runs (`reports/invictus/invictus_eval.py`; Darwinex-Demo, GBPJPY H1 chart, real ticks, 100k USD, 1:100)
The only input changed is `InpLots` = 2.0. That is the author's 0.2 lot per 10k scaled to the 100k deposit, so the
percentages compare directly with the claim.

**R per trade** = net (profit + commission + swap) / $1,000 = % of the deposit at the author's sizing. With no stop,
there is no planned loss to use as R.

- **S0, as written:** Monday only, 2022-01-01..2026-10-01.
- **S1, the author's control:** all weekdays (`InpDayMask` 31), same window.
  - Each day's trade opens and closes the same day, at a fixed lot, so a weekday's trades in S1 are the trades that
    day alone would make.
  - **Parity:** S1's Monday trades must equal S0's: same open minute, net within $1. Mismatches are reported. A
    mismatch means state carries across days and S1 is not a clean control.
- **S2, out of sample:** all weekdays, 2019-01-01..2022-01-01. These are 3 years before the author's window. It is
  first-time tick data for GBPJPY on Darwinex, so its history quality is reported, and below 90% S2 is inconclusive.
- **S3, entry hour:** Monday, `InpEntryHour` 9:1:13, 2022-26, MT5 optimization (criterion 0). The exit stays at 23:00,
  so the hold runs 10 to 14 hours. Reported only (the author's robustness claim).

## Checks and reports
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S2), all four must hold for Monday:**
  - net > 0 and PF >= 1.05;
  - mean R per trade t-statistic >= 1.65 (one-sided 5%; the RSI2 lesson: a holdout check needs a t-statistic);
  - Monday's mean R above the mean of the pooled Tuesday-Friday trades, so the result isn't only from being long
    GBPJPY.
- **Reported:**
  - S0: net, PF, max equity DD, win rate, R by regime;
  - per-trade mean R and t;
  - worst trade in R;
  - holds outside 11.5-12.5 hours;
  - skipped days by reason (spread, missed entry minute, margin) from the agent log, plus order and close errors;
  - history quality.
- **Per weekday (S1 and S2):** trades, PF, net R, mean R, t; Monday against pooled Tuesday-Friday (Welch t).
- **prop_mc alone (S0):** close_time,R file, --bt-risk 1.0, --risk 0.5,1.0 (half and full the author's sizing), 10k
  sims, seeds 1-3. Limit: the simulator sees closed trades only. A 12-hour hold with no stop has floating losses the
  daily rule would count, so these numbers are optimistic.

## Hypothesis
A long-only hold on GBPJPY, which rose over 2022-26, is positive on most subsets of days. Monday was picked from
5 days and many hours on the same window.
- **S0:** about 235-245 trades (a few spread skips), PF 1.5-1.9, Gate A passes. The claim replicates in sample.
- **S1:** Tuesday to Friday are also net positive on average, and Monday is the best day (it was chosen for that).
- **S2:** the Monday edge shrinks to PF 0.9-1.2 and the t-statistic stays under 1.65. The chance the out-of-sample check
  passes is about 20%.

## Decision rule
- **Gate A passes and the out-of-sample check passes:** a candidate. A stop and sizing that fit prop rules, and the
  joint with the gold live set, are pre-registered next. The as-written file never goes live (no stop).
- **Gate A passes but the out-of-sample check fails:** not a candidate. The Monday pattern holds only in the window it
  was found in.
- **Gate A fails:** closed. The claim does not replicate on Darwinex.

## Outcome (2026-10-21; stopped by the user during S2; history quality 99%; log `reports/invictus/base.log`)
User: "ok, skip this EA test". S0 and S1 finished; S2 (2019-21) was stopped mid-run, so there is no out-of-sample
result, and S3 was not run.

| S0, Monday 2022-26 | net | PF | max equity DD | trades | win | mean R (t) | R 2022-24 / 2025-26 | Gate A |
|---|---|---|---|---|---|---|---|---|
| as written, 2.0 lots | +19,211.25 | 1.80 | 7.19% | 98 | 54.1% | +0.196 (t 2.24) | +13.1 / +6.1 | **fail** (trades < 150) |

- **Spread skips.** The spread guard skipped 148 Mondays: the Darwinex GBPJPY spread at 11:00 server is over 1.5 pips
  most weeks. That leaves 98 trades, under Gate A's 150. On the trades taken, the author's PF (1.86) and DD (7.05%)
  replicate.
- **Code checks:** all holds were exactly 12 hours; 0 missed entries, 0 order or close errors.
- **Worst trade** -1.57 R.
- **prop_mc alone** at 0.5x / 1.0x the author's sizing: 0.0 / 7.2-7.6%.

**S1, weekday control (2022-26):**
| day | trades | PF | net R | mean R | t |
|---|---|---|---|---|---|
| Mon | 98 | 1.81 | +19.2 | +0.196 | +2.24 |
| Tue | 107 | 1.27 | +11.9 | +0.111 | +0.95 |
| Wed | 115 | 0.96 | -1.8 | -0.016 | -0.14 |
| Thu | 101 | 0.93 | -3.8 | -0.038 | -0.27 |
| Fri | 98 | 1.13 | +5.5 | +0.056 | +0.45 |
| Tue-Fri pooled | 421 | 1.06 | +11.7 | +0.028 | +0.45 |

- Monday is the best day, as forecast (it was chosen on this window).
- Monday against pooled Tuesday-Friday: Welch t +1.57.
- Parity of S1's Mondays with S0: 98 of 98, 0 mismatches.

**Decision: closed by the pre-registered rule (Gate A fails on trade count)** and by the user's stop. The Monday pattern
is untested out of sample.

Not tested, each to be pre-registered separately:
- **S2,** the 2019-21 out-of-sample run.
- **A wider spread guard,** or a raw-spread broker such as IC Markets. The skips are a broker-cost effect, not part of
  the rule.

**Removal (2026-10-21).** User rule: "when we decide that an EA is failing, always remove the leftovers". Removed
`mql5/Invictus_GBPJPY_Monday_EA.mq5`, its `scripts/ea_profiles.py` entry and the MT5 tester .set; the MT5 .mq5 and .ex5
were already gone. The file stays in git at f054c99.

## Stage 2, spread guard at Darwinex levels (pre-registered 2026-10-21, before its runs)
User: "what about this EA? we can setup it to run only on Mondays". It already runs Monday only (`InpDayMask` 1). What
stopped it was the 1.5-pip spread guard. User: "ok, go ahead" with the plan below.

The EA is restored unchanged from f054c99 (MD5 f95e8067…) with its profile, and recompiled with 0 errors and 0 warnings.

**Spreads on the 148 skipped Mondays** (S0 agent log; spread at 11:00 server):
- median 1.90 pips, 90th percentile 2.30;
- by year (median): 2022 1.75, 2023 1.70, 2024 1.95, 2025 1.90, 2026 2.00;
- 141 were at or under 2.75 pips, and 7 were 3 pips or more, including spikes of 19 and 40 pips (broken quotes).

**The change:** `InpMaxSpreadPips` = 3.0, set from that distribution and chosen before any run with it.
- The author calls the guard "a guard against broken quotes, not a tuning parameter". At 3.0 it still blocks those
  quotes, and it passes Darwinex's normal spread.
- The extra spread costs about 0.4 pip per trade, about $5 at 2 lots, which is about 0.005 R against the S0 mean of
  +0.196 R.
- Everything else is as in the runs above: 2.0 lots, R = net / $1,000, Darwinex-Demo, real ticks, 100k, 1:100.

**Runs** (`reports/invictus/invictus_eval.py stage2`; run names `inv2_*`):
- **S0b:** Monday, 2022-01-01..2026-10-01. Gate A as above.
- **S1b:** all weekdays, same window: the in-sample weekday control, reported, plus S0b/S1b Monday parity.
- **S2b:** all weekdays, 2019-01-01..2022-01-01, the out-of-sample check as above. For Monday: net > 0, PF >= 1.05,
  mean R t >= 1.65, and mean R above the pooled Tuesday-Friday mean. If history quality is below 90%, it is
  inconclusive.
- **prop_mc alone (S0b):** 0.5x / 1.0x the author's sizing, seeds 1-3.
- **If Gate A and the out-of-sample check both pass:** the joint with the gold live set at --risk 0.3,0.5, reported.
  This EA then trades at 0.3x / 0.5x the author's sizing, i.e. 0.6 / 1.0 lot per 100k.

**Hypothesis:**
- **S0b:** about 235-245 trades with a similar per-trade edge (PF 1.5-1.8), so Gate A passes.
- **S2b:** the Monday edge shrinks to PF 0.9-1.2 and t stays under 1.65. The chance it passes is about 20%, unchanged
  from the first forecast.

**Decision rule:**
- **Gate A and the out-of-sample check pass:** a candidate. A stop and sizing that fit prop rules, and the live-set
  joint decision, are pre-registered next. The no-stop file never goes live.
- **Otherwise:** closed, and leftovers are removed (user rule).

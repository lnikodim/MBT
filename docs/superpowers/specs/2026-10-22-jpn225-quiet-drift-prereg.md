# JPN225_Quiet_Drift_EA on Darwinex NI225 M15 (pre-registration)

Date: 2026-10-22. User: "continue forward with the rest of the EAs from your initial list". This was the "on watch"
EA of the 2026-10-22 Code Base research (Crabel ORB and Monday Dip were tested and closed). Server: Darwinex-Demo.

**The EA:** "JPN225 Quiet Drift" (mql5.com code 78027), `Jpn225_quietdrift.mq5` v1.01, by the author of the Monday
GBPJPY and GER40 Evening Coil EAs. MD5 7d3c8977…. It is copied unchanged to `mql5/JPN225_Quiet_Drift_EA.mq5`, renamed
per the naming convention, and compiles with 0 errors and 0 warnings. M15, long only, one position at a time.
- **Signal:** a bar opening 11:00-14:59 server time, Monday to Friday, with all three conditions true:
  1. the close's z-score against its 34-bar average > 0.5;
  2. MACD(12,26,9) histogram / ATR(14) < 0.2;
  3. the bar's tick volume < 60% of the average at the same time of day over the previous 20 days.
- **Entry:** buy at the Ask on the next bar.
- **Exit:** stop 4 x ATR(14), target 3.5 x ATR(14), and everything closed at 17:00 server time.
- **Lots:** fixed.

**Author's claim** (code page, 2022-01..2026-10, 10k account at 15 lots):
- +$8,782 (+87.8%), PF 1.68, max DD 8.5%.
- 309 trades (61.8% wins), every year profitable (2022 +15.6% ... 2026 +15.4%).
- Exits: 63% at the 17:00 close, 26% target, 11% stop.
- Found by automated research ("385 candidates tried").
- The window is our standard 2022-26, so a run there is a replication only.

**Review:**
- **Volume condition:** relative to the same time of day on the broker's own feed, unlike GER40 Evening Coil's fixed
  level.
- **Exit:** the 17:00 close runs on every tick, and Nikkei CFDs trade well past 17:00, so there is no session-end
  problem.
- **Intended chart:** the EA's validation code is inactive on Nikkei M15 (no margin check, no risk cap).
- No DLL, web or file calls. Magic 602674 is unused here.

**Data** (2-week probes):
- **Symbol:** Darwinex names the Nikkei **NI225**, which `IsNikkeiSymbol()` recognises. JPN225 and JP225 do not exist.
- **Real ticks:** 0% to 2023-03-15, 25% for 2023-03-15..31, and 100% from 2023-04 (also 2024-01, 2025-01).
- **M1 bars:** 100% for M1-generated ticks in 2019-01 and 2021-01.
- **Disclosure:** the first NI225 probe (2019-01-07..21, trading on) made 4 trades, +5.73 USD. All later probes had
  `InpAllowTrading` false.

**The tick-volume problem.** Condition 3 uses tick volume. Before 2023-04 only M1-generated ticks exist, and a bar's tick
volume there is modelled, not Darwinex's real count. So a modelling check comes first.

## Runs (`reports/jpn225/jpn225_eval.py`; Darwinex-Demo, NI225 M15, 100k USD, 1:100; `InpLots` 1.0, the only input change)
1. **M0, modelling check:** 2023-04-01..2026-10-01 run on both real ticks and M1-generated ticks.
   - **Pass:** at least 80% of the real-tick entries have a generated-tick entry within 15 minutes, and the trade counts
     are within +/-20%.
   - **If M0 fails,** any M1-generated result for this EA is not evidence: S1 is inconclusive, and S0 uses real ticks
     only.
2. **S0, replication 2022-01..2026-10:** 2022-01..2023-04 M1-generated plus the M0 real-tick run.
3. **S1, out of sample 2019-01..2022-01:** M1-generated (before the author's window).

**R per trade** = net / (stop distance x volume x value per point), with the stop from the Orders table (the parser of
`reports/crabel/crabel_eval.py`, checked on known reports). A stop exit should be about -1 R.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05 and mean-R t >= 1.65. It only counts if M0 passes.
- **Reported:**
  - for each run: net USD (at 1.0 lot) and net R, PF, max DD, trades, win rate, mean R (t), R by year;
  - exits (stop, target, 17:00);
  - order failures;
  - for M0: the entry match and the two runs' results side by side.
- **If both checks pass:** the live-set joint is pre-registered next.

## Hypothesis
- **M0:** generated and real ticks give clearly different tick volumes. About a 50% chance M0 fails, which would leave
  S1 inconclusive.
- **S0:** PF 1.2-1.6, Gate A passes (about 60%).
- **S1:** PF 0.9-1.3 and t under 1.65. The chance it passes, given that M0 passes, is about 25%. The same author's GER40
  EA failed out of sample and the Monday GBPJPY EA was a near-miss.

## Decision rule
- **Gate A and the out-of-sample check pass (with M0 passing):** a candidate.
- **M0 fails:** out-of-sample inconclusive. Not a candidate, since there is no testable out-of-sample evidence on this
  broker. The user decides whether to look for older Nikkei ticks elsewhere.
- **Otherwise:** closed, and leftovers are removed (user rule).

## Outcome (2026-10-22; log `reports/jpn225/base.log`)
| run, 1.0 lot (100k) | trades | net USD | net R | PF (R) | mean R (t) | exits time / target / stop | history quality |
|---|---|---|---|---|---|---|---|
| M0 real ticks 2023-04..2026-10 | 262 | +3,244.01 | +21.8 | 1.35 | +0.083 (+2.08) | 171 / 59 / 32 | 100% |
| M0 M1-generated, same window | 262 | +3,392.39 | +22.7 | 1.36 | +0.087 (+2.18) | 172 / 60 / 30 | 99% |
| S0 2022-01..2023-04, generated | 111 | +954.55 | +7.4 | 1.27 | +0.066 (+1.04) | 63 / 26 / 22 | 99% |
| **S0 2022-26 combined** | **373** | **+4,198.56** | **+29.2** | **1.32** | **+0.078 (+2.31)** | | |
| **S1 2019-01..2022-01, generated** | **323** | **-1,620.57** | **-21.5** | **0.74** | **-0.066 (-2.15)** | 245 / 36 / 42 | 99% |

- **M0: pass.** 100% of the real-tick entries matched within 15 minutes, with 262 trades each, so the generated-tick
  years are valid for this EA.
- **Gate A: pass.** 2022-24 +22.8 R, 2025-26 +6.4 R.
- **S0 by year:** 2022 +0.8 R (+388.82 USD), 2023 +12.2 R (+883.14), 2024 +9.7 R (+1,294.83), 2025 +1.0 R (+85.80),
  2026 +5.4 R (+1,545.97). Below the author's PF 1.68 but positive.
- **S1 by year:** 2019 -11.2 R (-576.01 USD), 2020 -3.2 R (-3.66), 2021 -7.0 R (-1,040.90).
- 0 order failures in all runs.

**Decision: not a candidate.** The out-of-sample check fails: the strategy loses significantly before the author's
window (t -2.15, every year negative). On the hypothesis:
- M0 was forecast to fail; it passed.
- S0's PF of 1.32 was inside the 1.2-1.6 forecast.
- S1 failed as forecast, and worse (PF 0.74).

This is the same pattern as Stoch_Daily_Breakout_EA: the automated search fits its own window and reverses before it.

**Removal (user rule).** Removed `mql5/JPN225_Quiet_Drift_EA.mq5`, its `scripts/ea_profiles.py` entry, and the MT5 .mq5,
.ex5, compile log and tester .set (no chart had it). The file stays in git at 8d75eba.

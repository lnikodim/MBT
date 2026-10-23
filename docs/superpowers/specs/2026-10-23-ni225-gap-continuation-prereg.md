# NI225_Gap_Continuation_EA on Darwinex NI225 M5 (pre-registration)

Date: 2026-10-23. User: "continue testing https://www.mql5.com/en/code/75301". Server: Darwinex-Demo.

**The EA:** "Nikkei 225 Gap Continuation EA" (mql5.com code 75301, Francesc Jordi Mallol Nolden / MauriyKiku, published
2026-07-24), `Nikkei225_Gap_Continuation_EA.mq5`, 1,160 lines, MD5 bd04ffd5…. It is copied unchanged to
`mql5/NI225_Gap_Continuation_EA.mq5`, renamed per the naming convention. No DLL, web or file calls. Built for Darwinex
(symbol NI225, M5).

**The author's claim** (NI225 M5, 2017-2026): balance 97,964 -> 135,992, net +33,893.14, PF 1.50, max DD 3.89%,
501 trades, 60.48% won, at the default 0.5% risk.

**What the code does** (one strategy entry per day, one position on the symbol):
- **Session:** cash session 09:00-15:30 JST, converted to Darwinex time with the **US** DST rule (UTC+2 / +3). This
  matches what we measured today (Darwinex = New York + 7 h).
- **Gap:** cash-session open (first M1 bar at 09:00 JST) vs the last M1 close of the previous cash session. A gap
  >= 1.0% enables a BUY (up) or SELL (down) setup.
- **Opening range:** the first 10 minutes.
- **Entry:** on a tick, price breaks the range on the gap's side and is beyond the session VWAP. VWAP uses real volume
  if there is any, otherwise tick volume.
  - The deadline is 90 minutes after the open.
  - The setup is cancelled if more than half the gap fills first.
  - Spread must be <= 10% of the stop.
- **Stop:** the far side of the opening range.
- **Exits:** 40% closed at +1R, then the stop moves to break-even. The rest goes at +2R, or 5 minutes before the cash
  close.
- **Size:** 0.5% of equity (SELL 0.25% when the gap is under 1.25%).
- **Restart:** position state is kept in terminal globals, so a restart keeps it.

**Data** (spec 2026-10-22-jpn225):
- Darwinex NI225 real ticks: 100% from 2023-04 (25% in 2023-03-15..31, none before).
- M1 bars: 100% in 2019-01 and 2021-01.
- The author's 2017-2026 window covers every year we can test, so **no period is out of sample** for these defaults.
  This is a replication and robustness test.

## Runs (`reports/ni225gap/ni225gap_eval.py`; Darwinex-Demo, NI225 M5, 100k USD, 1:100, source defaults)
1. **M0, modelling check:** 2023-04-01..2026-10-01 on real ticks (M0r) and on M1-generated ticks (M0g).
   - Pass: at least 80% of real-tick entries have a generated-tick entry on the same day within 15 minutes, and the
     trade counts are within ±20%.
   - If M0 fails, generated ticks are not evidence for this EA. S0 is then real ticks only (2023-04..2026-10, regimes
     2023-04..2024 / 2025-26), and the consistency check is inconclusive.
2. **S0, 2022-01-01..2026-10-01:** 2022-01..2023-04 on generated ticks plus M0r.
3. **S1, consistency, 2019-01-01..2022-01-01:** generated ticks. Only if M0 and Gate A pass.
4. **N1-N4, neighbours:** each on M0r's real-tick window, only if Gate A and S1 pass. Gap minimum 0.75% and 1.25%
   (BUY and SELL together); opening range 5 and 15 minutes.

**Trades:** one in-deal plus its out-deals (the partial and the final) make one trade. R = trade net / (|entry - first
stop| x volume x value per point), with the stop from the Orders table.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Consistency (S1):** net > 0, PF >= 1.05.
- **Overall:** mean-R t >= 1.65 over S1 + S0 (2019-2026).
- **Neighbours:** all four have PF >= 1.00, so there is no cliff around the defaults.
- **Candidate** = all of the above pass. Anything else closes the EA. No input search.
- **Reported:** net USD (at 0.5%) and net R, PF, max DD, trades, win rate, mean R (t), R by year, BUY / SELL split,
  exits (target / partial + break-even / stop / session end), M0 entry matching, history quality.

## Expectation (written before the runs)
- **Trades:** gaps >= 1% on the Nikkei happen on maybe 15-25% of days, so roughly 50-60 trades a year, consistent with
  the author's 501 trades in 9 years. 2022-26 should give about 200-280.
- **Edge:** gap continuation on index opens is a known effect. PF 1.15-1.40 on our data, below the author's 1.50.
- **Most likely verdict:** Gate A passes, and the neighbour check is the main risk.

## Outcome (2026-10-23; log `reports/ni225gap/base.log`): **candidate**
| run (NI225 M5, 100k, defaults = 0.5% risk) | net USD | PF | max DD | trades | win | net R | mean R (t) | R by year |
|---|---|---|---|---|---|---|---|---|
| M0r real ticks 2023-04..2026-10, hq 100% | +11,918.82 | 1.38 | 2.9% | 154 | 60.2% | +27.0 | +0.175 (+1.99) | 23 +3.1, 24 +10.9, 25 +15.6, 26 -2.7 |
| M0g generated 2023-04..2026-10, hq 99% | +10,751.79 | 1.33 | 3.7% | 156 | 60.2% | +26.2 | +0.168 (+1.92) | 23 +2.6, 24 +11.0, 25 +14.1, 26 -1.5 |
| S0 part 2022-01..2023-04, generated | +3,553.81 | 1.34 | 4.4% | 63 | 55.2% | +4.7 | +0.074 (+0.58) | 22 +5.9, 23 -1.2 |
| **S0 2022-26** (generated + M0r) | **+15,472.63** | 1.36 (R) | | **217** | | **+31.6** | +0.146 (+2.01) | 22-24 +18.7, 25-26 +13.0 |
| **S1 2019-21**, generated, hq 99% | **+13,652.84** | 1.83 | 4.3% | 97 | 64.4% | **+27.0** | +0.278 (+2.57) | 19 +3.8, 20 +9.3, 21 +14.0 |
| N1 gap 0.75%, real ticks 2023-04..2026-10 | +11,109.76 | 1.26 | 3.7% | 210 | 58.0% | +21.2 | +0.101 (+1.35) | |
| N2 gap 1.25% | +6,055.32 | 1.31 | 3.1% | 92 | 58.9% | +12.1 | +0.132 (+1.19) | |
| N3 opening range 5 min | +5,048.90 | 1.13 | 3.8% | 170 | 54.8% | +14.5 | +0.085 (+0.99) | |
| N4 opening range 15 min | +4,992.16 | 1.18 | 3.6% | 147 | 57.8% | +11.4 | +0.078 (+0.95) | |

- **M0 passes:** 153 of 154 real-tick entries are matched by generated ticks within 15 minutes (99%), with 154 vs
  156 trades. Generated ticks are valid for this EA.
- **Gate A passes:** 217 trades, PF 1.36 in R, both regimes positive.
- **S1 consistency passes**, and the overall 2019-2026 t is **3.10** (314 trades, +58.6 R). Seven of eight years are
  positive; 2026 to date is -2.7 R. Both sides earn: BUY +19.1 R and SELL +12.5 R in 2022-26.
- **Neighbours pass** (PF 1.13-1.31). The 10-minute range and 1% gap sit on a plateau: a smaller gap or a shorter
  range adds trades with weaker mean R.
- **Trade count check:** in M0r, 154 entries in the report = 154 parsed trades (the EA log has 155 entry lines).
  Exit averages match the rules: full target +1.64 R (40% at 1R + 60% at 2R), break-even +0.38 R.
- **Expectation check:** PF in R 1.36-1.80 against the expected 1.15-1.40, slightly better. Trades about 46 a year,
  inside the expected 50-60 a year after allowing for the cancellations.
- **Caveats:**
  - Every tested year lies inside the author's 2017-2026 design window.
  - Years before 2023-04 use generated ticks (validated by M0).
  - About 46 trades a year at 0.5% is about +3-4% a year on its own.
- **Deployment note** (user, 2026-10-23): the FTMO broker has no NI225. The EA is a **Darwinex Zero** candidate.
  Next: a joint simulation with the six live EAs on Darwinex Zero settings, then the Darwinex Zero .set file.
- **Kept** in the repo as a candidate (`mql5/NI225_Gap_Continuation_EA.mq5`, profile, MT5 copy).

## Darwinex Zero joint simulation (pre-registered 2026-10-23, before computing)
User: "go ahead with the joint simulation on Darwinex Zero".
`reports/portfolio/dz_joint_ni225.py`, closed trades only, no tester runs, 2022-01-01..2026-10-01, Darwinex logs.
- **A, the six live EAs on Darwinex Zero settings:** 0.5% constant risk, throttle off. Trade lists as in spec
  2026-10-22-dd-reduction phase 1.
- **B = A + NI225_Gap_Continuation_EA at its defaults:** 0.5% risk, SELL 0.25% on gaps under 1.25%. Its trades are
  S0 (2022-01..2023-04 generated + 2023-04..2026-10 real ticks), as % of the run's balance before each trade.
- **Path:** simple sum in % of the initial balance. Days and months by server close time.
- **Reported for A and B:** total %, % a year, max DD, worst day, worst month, monthly mean and sd, annualised Sharpe
  (monthly), monthly 95% VaR (5th percentile), return / max DD. Also NI225's monthly and daily correlation with A.
- **Decision rule (add NI225 to the Darwinex Zero set if all three hold):**
  - B's return / max DD >= A's;
  - B's max DD <= A's + 1.0 point;
  - B's worst month no more than 1.0 point worse than A's.

### Outcome (2026-10-23): **add NI225 to the Darwinex Zero set**
| 2022-01..2026-10, closed trades, 0.5% | total | % a year | max DD | worst day | worst month | monthly mean / sd | Sharpe | monthly VaR95 | return / DD |
|---|---|---|---|---|---|---|---|---|---|
| A six EAs (2,226 trades) | +319.2% | +67.2 | 15.61% | -4.06% | -10.13% | +5.60% / 9.61% | 2.02 | -7.86% | 20.4 |
| B six + NI225 (+217 trades) | +334.3% | +70.4 | 15.93% | -4.06% | -10.45% | +5.86% / 9.66% | 2.10 | -8.66% | 21.0 |
| NI225 alone | +15.0% | +3.2 | 3.88% | -0.53% | -1.70% | +0.26% / 0.88% | 1.03 | -1.47% | 3.9 |

- **Correlation of NI225 with A:** monthly +0.01, daily -0.02. In practice NI225 is uncorrelated with the six EAs.
- **Rule:** return / DD 21.0 >= 20.4; max DD 15.93 <= 16.61; worst month -10.45 >= -11.13. All three hold, so **add**.
- **Effect:** +15 points over 4.75 years (+3.2% a year). Sharpe rises from 2.02 to 2.10, the worst day is unchanged,
  and the max DD rises 0.3 points.
- **Monthly VaR95 is 0.8 points worse.** With 57 months, the 5th percentile is the 2nd-3rd worst month, so this is a
  different month moving into that slot, not a new risk. The rule does not use it.
- **Totals are simple sums in % of the initial balance** at 0.5%, as in phase 1. Compounding would differ.

## Live build MBT 1.51 (2026-10-23)
- **Changes:** `DailyStop.mqh` added (account equity -4% from the day start closes the EA's position; no entries until
  the next server day; compiled default 4.0 = Darwinex Zero). Inputs regrouped per `docs/ea-inputs.md`, with names,
  types and defaults unchanged (only `InpDailyLossPct` is new). The trading logic is unchanged.
- **Tester check** (`reports/portfolio/dailystop_check.py NI225_Gap_Continuation_EA`, real ticks 2023-04..2026-10):
  - stop off: the validated run's entries (154 / 154, net +11,918.82, identical);
  - stop on at 0.05%: 135 stop days, every open position closed within 60 s, no same-day entry after a stop.
- **Live set:** `mql5/sets/darwinex_zero/NI225_Gap_Continuation_EA.set` (0.5% / 0.25%, daily stop -4%). No FTMO set.
  `.ex5` MD5 fdb6058c….

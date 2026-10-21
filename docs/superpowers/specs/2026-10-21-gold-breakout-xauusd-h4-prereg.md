# Gold_Breakout_EA on XAUUSD H4 (pre-registration)

Date: 2026-10-21. User: "ok, let's test this EA: https://www.mql5.com/en/code/77691" (file:
…/Downloads/GoldBreakoutEA.mq5, identical to the code-page download). Server: Darwinex-Demo (user rule: always the first
choice for backtests).

**The EA:** "Gold Breakout EA for XAUUSD H4" by Ali Rajput, v1.00, MD5 9a1b63a7…. It is copied unchanged to
`mql5/Gold_Breakout_EA.mq5` and renamed per the naming convention. It compiles with 0 errors and 0 warnings. Once per
new H4 bar:
- **Entry:** buy at market when the bar that just closed closes above the highest high of the previous 20 bars and the
  bar before it did not (a fresh breakout), with the close above EMA 200.
- **Stops:** 2 x ATR(20) from the real fill, attached after the fill. Target 2R.
- **Sizing:** 1% of balance per trade, via OrderCalcProfit.
- **Guards:** skip if the spread is over 10% of the stop, and no entry in the last 15 minutes of the session.
- **Defaults:** long only, one position at a time.

**Author's claim** (code page: 2020-01-01..2026-09-20, MetaQuotes-Demo, 10k, 1:100, 1% risk, every tick generated from
M1, no commission):
- +9,029.72 (+90%), PF 1.77, max equity DD 11.38%.
- 198 trades, all buys, 46.97% wins.
- By year: 2020 +5.1%, 2021 -2.9%, 2022 +4.6%, 2023 +4.8%, 2024 +24.0%, 2025 +27.1%, 2026 +7.9%.

**It is nearly the same strategy as a live-set EA.** Donchian_Breakout_EA v1.01 (magic 261015, in the gold live set,
trade file `reports/lowtf_donch_h4_20261019_212257_trades.csv`) uses the same inputs: XAUUSD H4, channel 20,
2 x ATR(20), 2R, long only, EMA 200 on H4. The one rule difference is the entry:
- Donchian_Breakout_EA enters whenever the closed bar is above the channel, so it can re-enter on the next bar after a
  stop or target.
- Gold_Breakout_EA requires a fresh cross.

So the main question is whether this EA adds anything. Two settings were picked on the author's own window: shorts off
("shorts lost money on gold 2020-2026") and the fixed-target exit.

**Review before the run** (kept, as the file runs as written):
- **Brief unprotected moment.** The order goes out without stops, so the position is unprotected until the modify
  returns. If the modify fails, the position is closed at once.
- **The trail is not used.** Trail exits (A, B) only tighten once per bar; the default exit C is a fixed target.
- **Costs the author did not have.** Darwinex charges commission on gold, so costs here are higher than in the claim.

## Runs (`reports/goldbo/goldbo_eval.py`; Darwinex-Demo, XAUUSD H4, 100k USD, 1:100, compiled defaults, 1% risk)
**R per trade** = net (profit + commission + swap) / (1% of the balance at entry). A stop exit should be about -1 R,
and this is checked.

- **S0, replication:** real ticks, 2022-01-01..2026-10-01. This is inside the author's window.
- **S1, out of sample:** every tick generated from M1, 2012-01-01..2020-01-01, before the author's window.
  - Darwinex has XAUUSD bars from 2011 but real ticks only from 2019, so S1 uses generated ticks, as the author did.
  - Gold fell in 2013-15 and ranged in 2016-18, so this is a hard test for a long-only breakout.
  - Neither this EA nor Donchian_Breakout_EA has been tested before 2019.

## Checks and reports
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05 and mean R per trade t >= 1.65. If history quality is below 90%, S1
  is inconclusive.
- **Overlap with Donchian_Breakout_EA (S0 window):**
  - the share of S0 entries that match a live-set Donchian entry (open within 4 hours, i.e. one H4 bar);
  - the share of Donchian entries matched;
  - the correlation of monthly R.
- **Reported, for S0 and S1:**
  - net, PF, max equity DD, win rate, R and mean R (t) by year;
  - exits (stop, target, other) with average R;
  - skips (spread, min lot, margin), stop-attach failures and order failures, from the agent log;
  - history quality.
- **prop_mc (S0):**
  - alone: --risk 0.3,0.5, 10k sims, seeds 1-3;
  - the gold live set with this EA added;
  - the gold live set with this EA in place of Donchian_Breakout_EA.
  - All reported.

## Hypothesis
- **S0:** 130-150 trades, PF 1.4-1.8. Gate A is borderline on the trade count (about a 50% chance of passing).
- **Overlap:** at least 85% of its entries are Donchian entries; Donchian has extra re-entries.
- **S1:** PF 0.9-1.2 and t under 1.65. The chance the out-of-sample check passes is about 25%. That is a bit higher than
  for a data-mined EA, because trend breakouts on gold have a long public record.

## Decision rule
- **Overlap >= 80% of its entries:** a duplicate. It is not added, because its trades are already in the live set, and
  its leftovers are removed (user rule). The S1 result is reported as evidence on the live Donchian rule, and a direct
  Donchian_Breakout_EA S1 run is proposed if S1 fails.
- **Overlap < 80%:**
  - Gate A and the out-of-sample check both pass: a candidate, and the live-set joint is pre-registered next.
  - Otherwise: closed, and leftovers are removed.

## Outcome (2026-10-21; log `reports/goldbo/base.log`)
| as written, 1% risk | net | PF | equity DD relative | trades | win | R, mean R (t) | check |
|---|---|---|---|---|---|---|---|
| S0 2022-26 real ticks, hq 100% | +65,207.49 | 1.68 | 8.25% | 145 (all buys) | 49.0% | +51.9, +0.358 (t 2.92) | **Gate A fails** (trades < 150; 22-24 +23.3 R, 25-26 +28.6 R) |
| S1 2012-2019 M1-generated, hq 34% | -12,801.03 | 0.78 | 18.65% | 83 | 34.9% | -12.9, -0.156 (t -1.03) | **inconclusive** (history quality < 90%) |

**S0 replicates the claim's shape:** PF 1.68 against 1.77, and 2024-25 carry it (+24.1 R, +23.5 R).
- **By year:** 2022 was negative (PF 0.82), 2023 flat (PF 1.13).
- **Exits:** stop 73 at -1.08 R (the R check holds), target 66 at +1.88 R.
- **Code checks:** 0 skips, 0 order failures, 0 stop-attach failures.

**Overlap: a duplicate.**
- 134 of its 145 entries (92%) match a Donchian_Breakout_EA live-set entry within one H4 bar.
- 134 of Donchian's 157 entries (85%) match one of its entries.
- Monthly R correlation +0.96.

**prop_mc** (P(pass both) at 0.3% / 0.5%, seeds 1-3):
| set | 0.3% | 0.5% |
|---|---|---|
| alone | 0.1-0.2 | 12.7-13.0 |
| gold 4-EA | 93.7-94.1 | 84.2-84.7 |
| gold 4-EA plus this EA | 93.9-94.1 | 83.0-83.5 |
| this EA in place of Donchian | 94.1-94.5 | 84.4-85.1 |

Adding it doubles the Donchian exposure and lowers the 0.5% pass rate. Swapping it in is within seed noise.

**S1 has too little data.** History quality is 34%, and the first trade is in 2016: Darwinex M1 bars before about 2016
are missing, so the run covers 2016-2019 only. Over that span it lost every year from 2017 to 2019 (PF 0.54, 0.77,
0.93). That is the direction of a fail, but by the rule it is inconclusive.

**Decision: a duplicate of Donchian_Breakout_EA (overlap 92%), so it is not added.** The hypothesis held on overlap (at
least 85%) and on the Gate A trade count being borderline (145).

**What it says about the live Donchian rule:** this is the same rule, and it has no clean out-of-sample test. This run
is the first pre-2022 look at it: weak and negative in 2017-19, on poor data. The proposed next test uses real ticks:
Donchian_Breakout_EA v1.02, as it runs live, on 2019-01..2022-01 with Darwinex real ticks (history quality is about 99%
there). It would be pre-registered separately.

**Removal (user rule).** Removed `mql5/Gold_Breakout_EA.mq5`, its `scripts/ea_profiles.py` entry, and the MT5 .mq5,
.ex5, compile log and tester .set (no chart had it). The file stays in git at f29b857.

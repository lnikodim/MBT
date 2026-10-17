# Enhanced Range Breakout EA v1.89: Stage A (pre-registration)

Date: 2026-10-17. User: "backtest a new EA", with a compiled-only third-party EA,
`~/Downloads/Enhanced_Range_Breakout_EA_v1.89.ex5` (127,354 bytes, sha256
`3daf8c745ec317dd890c797d69b0c5e5fe5954dcc96fe6902d32f25abe71050f`), and its "1.89 EASY USER GUIDE.txt". No source.
The user chose XAUUSD, EURUSD and GBPUSD; the guide's suggested starter configuration; and range hours on the UK clock.

## Install
- Installed as `Advisors\Enhanced_Range_Breakout_EA_v189.ex5`, without the dot in "v1.89".
- The binary is not committed.
- Profile `Enhanced_Range_Breakout_EA_v189` in `scripts/ea_profiles.py` pins all 100 inputs. Their compiled defaults
  come from the report of a run with no inputs; the input names match the guide.
- Batch: `reports/erb/erb.py` (`discover`, `selfcheck`, `stage_a`).

**The EA is compiled for AVX2.** On this Mac, MT5 refuses to load it: "your CPU architecture does not allow to run the
file ...: AVX2 required, you have X64 only". Rosetta 2 can execute AVX2 but does not advertise it by default, so every
run of this EA sets `ROSETTA_ADVERTISE_AVX=1` in the launch environment. Without it, the tester exits in about 16 s and
writes no report. A user without AVX2 hardware cannot run this build at all, in the tester or live.

## What the EA does (from the guide; confirmed below where the tester can show it)
1. Record the high and low of a time window (default 01:00-06:00 on the user's clock; `RangeTimeToServerOffsetHours`
   converts that clock to server time).
2. Enter on the first `BreakoutTimeframe` candle close beyond the range (`EntryMode` 0 = Candle Close).
3. Place the stop at the opposite edge (`SlMode` 0 = Range) and the target at `TakeProfitRR` x the stop distance
   (`TpMode` 0 = R:R).
4. Take at most `MaxTradesPerDay` trades.
5. Close everything at `TradingEndHour`.

Enum order: as listed in the guide, from 0. The probe confirmed `SlMode` 2 = Fixed and `LotMode` 1 = % of balance.

## Starter configuration (all cells)
Compiled defaults (the guide's starter values), except:
- `RangeTimeToServerOffsetHours=2`. Darwinex server = UK + 2 in both winter and summer.
- `SkipCurrentSessionOnAttach=false`, as the guide says for backtests.
- `LotMode=1`, `RiskPercent=1.0`. The guide says "Fixed, broker minimum"; 1% of balance makes R comparable with
  the repo's other EAs.
- `MaxSpreadPips` is per instrument, from the guide's anchors (cells below).

So:
- The range is 01:00-06:00 UK, which is 03:00-08:00 server.
- Trading ends at 22:00 UK, which is 00:00 server.
- Entry is a Candle Close on M15, buffer 0, both directions, 1 trade a day.
- The stop is at the range edge and the target at 1R.
- All filters and risk guards are off; `MinRangeBarsRequired` 0; `DSTAutoSwitch` off; `MaxLotSizeCap` 0.

Known: UK and US DST dates differ for about 3 weeks a year (late March, late October to early November). In those
weeks Darwinex is UK + 1 and the window runs 1 hour early.

## Step 0: self-check (2026-01, starter config, `reports/erb/selfcheck.log`)
**Unit probe** (`SlMode=2`, `FixedSlPips=20`): the stop distance / 20 gives the unit.
- EURUSD: 0.0001, i.e. 1 pip. `LotMode=1` risks 988-1,004 USD at 100k.
- XAUUSD: 0.01, i.e. 1 MT5 point. So the guide's gold anchor `MaxSpreadPips=30` is 30 points (0.30 USD).
- At 1% risk, a 20-point gold stop needs more margin than 1:20 allows ("PlaceBuyTrade: not enough margin"), so the gold
  probe ran at minimum lots.

**Starter config, January 2026**: 21 trades on EURUSD, 21 on XAUUSD, and every check passed on both. Each trade was
checked against M1 bars from `BarDump`:
1. The stop sits exactly on the opposite edge of the server 03:00-08:00 range, which confirms the UK offset.
2. Entry comes in the M15 bar right after the first M15 close beyond the range from 08:00 on.
3. The target is 1R.
4. At most 1 trade a day.
5. Stop-outs lose -0.91 to -1.05 R.
6. EA closes come at the first tick after 00:00 server.

Two properties of this configuration on Darwinex:
- **Entry delay on gold.** EURUSD enters at the bar open every time. XAUUSD enters 0-409 s later (median 31 s), which
  fits the EA waiting for the spread to drop to 30 points.
- **Where the session close lands.** 22:00 UK is 00:00 server, which is Darwinex's daily close. EURUSD ticks resume
  at 00:04 and XAUUSD at 01:01, so EA closes happen there, in rollover spreads. A trade still open late on Friday is
  closed at Monday's open: in January, gold held Fri 01-09 15:45 to Mon 01-12 01:01. Stage A counts these
  weekend holds.

`BarDump` now prints `_Digits` decimals instead of 2, so FX bars are usable.

## Hypothesis (written before any Stage A run)
- Prior result: the 2026-10-13 Donchian research found that opening-range breakouts go to zero after spread on CFDs.
- A 1R target against a stop at the far edge of a 5-hour range needs a better than 50% win rate after costs.
- Expected: tester PF 0.90-1.05 in every cell, failing at least one regime; most likely 0 of 4 pass.
- The capped gold cell will trade less in 2026, as spreads widened.
- Seen before the runs: only the 2026-01 self-check and one 2026-09 default-input discovery run.

## Stage A (`python3 reports/erb/erb.py stage_a`, Darwinex real ticks, M15, 100,000 USD, 1% risk, to 2026-10-01)
| cell | symbol | MaxSpreadPips | from | leverage |
|---|---|---|---|---|
| `erb_xau` | XAUUSD | 30 (guide anchor) | 2022-01-01 | 1:20 |
| `erb_xau_nocap` | XAUUSD | 0 (off) | 2022-01-01 | 1:20 |
| `erb_eur` | EURUSD | 2 (guide anchor) | 2022-01-01 | 1:30 |
| `erb_gbp` | GBPUSD | 2 (guide anchor) | 2024-01-01 (Darwinex GBPUSD real ticks start 2024-01) | 1:30 |

The no-cap gold cell is the FZMR lesson: Darwinex gold spreads were 22-26 points in late 2025 and 46-89 in 2026, so a
30-point cap can stop the EA trading gold.

**Measurement:**
- Trades come from the report's Deals table (`blessing_eval.deals_trades`).
- Net R per trade = profit / (0.01 x balance before the trade).
- Exit reasons (stop, target, EA close) come from the tester agent log.
- Also reported: R by year, trades held over a weekend (open Friday, closed after it) and their R, and "not enough
  margin" rejections.

**Gate A per cell:** trades >= 150, tester PF >= 1.00, net R > 0 in both regimes. The regimes are 2022-24 and 2025-26;
for GBPUSD, 2024 and 2025-26.

**Plateau for passers:**
- Neighbours: `TakeProfitRR` 0.75 / 1.5 and `RangeEndHour` 5 / 7.
- Pass: mean PF >= 1.00 and at least 3 of 4 profitable.
- A plateau passer then gets prop_mc and the joint rule against the Darwinex control, pre-registered separately.

## Amendment 1 (2026-10-17 17:07, before any Stage A result): 1-min OHLC
**What happened.** The real-tick Stage A was stopped by the user's decision ("let's test the EA with 1min OHLC instead,
it should be quicker"). It had reached 2023-07 in cell 1 after 22 minutes and produced no result, so nothing was seen.

**Changes.**
1. All Stage A and plateau runs use 1-min OHLC.
2. GBPUSD starts 2022-01-01, like the other cells. Its 2024 start came only from real-tick coverage; Darwinex has
   GBPUSD M1 history from 2014. Its regimes are now 2022-24 and 2025-26.
3. Everything else is unchanged: cells, caps, inputs, Gate A and plateau.

**Caveat.** 1-min OHLC uses bar spreads. On Darwinex gold these are far tighter than real ticks: the FZMR review found
median entry spreads of 9 points on 1-min OHLC vs 28 on real ticks. So the 30-point gold cap binds much less, and the
gold spread-wait seen in the self-check mostly vanishes.

**New rule.** A Gate A pass on 1-min OHLC counts only after the same cell is rerun on real ticks with the same inputs
and window and still passes Gate A.

## Outcome (2026-10-17)
Logs: `reports/erb/stage_a.log` and `reports/erb/confirm_part1.log`; runs in `reports/erb/runs`. Settings: Darwinex,
M15, 2022-01-01..2026-10-01, starter config, 1% risk.

### Stage A on 1-min OHLC
| cell | trades | PF | net USD | DD | R 2022-24 / 2025-26 | R by year 22 / 23 / 24 / 25 / 26 | exits: target / stop / EA close | Gate A |
|---|---|---|---|---|---|---|---|---|
| XAUUSD cap 30 | 1,090 | 1.07 | +30,372 | 28.1% | +22.5 / +8.3 | -8.5 / +1.7 / +29.2 / +7.8 / +0.4 | 429 / 381 / 279 | pass |
| XAUUSD no cap | 1,194 | 1.13 | +66,725 | 28.1% | +22.5 / +33.2 | -8.5 / +1.7 / +29.2 / +7.9 / +25.3 | 478 / 402 / 314 | pass |
| EURUSD cap 2 | 1,227 | 0.88 | -55,511 | 65.4% | -39.8 / -35.6 | +3.7 / -20.3 / -23.3 / -37.3 / +1.7 | 529 / 554 / 144 | fail |
| GBPUSD cap 2 | 1,229 | 0.81 | -70,460 | 72.4% | -71.6 / -44.7 | -24.1 / -41.1 / -6.3 / -32.2 / -12.5 | 514 / 586 / 129 | fail |

- Targets average +0.97 to +0.98 R, stops -1.01 to -1.03 R, EA closes -0.03 R on gold and -0.12 to -0.14 R on FX.
- No margin rejections in any cell.
- Trades held over a weekend: 25-58 per cell, -2.9 to -6.3 R.
- On gold, the 30-point cap never bound in 2022-24 (the year splits are identical to the no-cap cell). In 2025-26 it
  removed 104 trades and about 25 R.

### Plateau (1-min OHLC)
- **Cap 30:** PF 1.07 (target 0.75R), 0.98 (1.5R), 1.03 (range end 05:00), 1.05 (07:00). Mean 1.03, 3 of 4 profitable:
  plateau.
- **No cap:** PF 1.12, 1.02, 1.08, 1.12. Mean 1.085, 4 of 4 profitable: plateau.

### Real-tick confirmation (amendment 1)
| cell | trades | PF | net USD | DD | R 2022-24 / 2025-26 | R by year 22 / 23 / 24 / 25 / 26 | Gate A |
|---|---|---|---|---|---|---|---|
| XAUUSD cap 30 | 1,090 | 1.01 | +4,809 | 32.7% | +7.8 / +1.3 | -12.8 / -3.7 / +24.3 / +1.1 / +0.2 | pass |
| XAUUSD no cap | skipped by the user (19:07, after 4 min) | | | | | | unconfirmed |

- **Capped cell.** The same 1,090 trades as on 1-min OHLC: the cap delays entries rather than skipping them. Real
  spreads take the cell from +30.8 R to +9.1 R, which is +0.008 R per trade. Exits: 419 targets +1.00 R, 388 stops
  -1.03 R, 282 EA closes -0.04 R. 55 weekend holds, -7.0 R.
- **Skip rule.** Before the no-cap run, the user said to skip it if the real-tick and 1-min OHLC results were
  identical. They were not; the user then skipped the run anyway.

**Log flood.** With the cap on, real ticks make the EA print "Spread too wide: 43.0 pips (max 30.0). Skipping." on
every tick above the cap. That came to a 19.4 GB tester agent log for one run. Reading it in Python filled the swap.
Live, the same lines go to the Experts journal.

### Verdict
- **Hypothesis:** PF 0.90-1.05 everywhere, 0 of 4 pass. FX was worse than expected; gold was better on 1-min OHLC
  (1.07-1.13) and inside the range on real ticks (1.01).
- **EURUSD and GBPUSD:** CLOSED. They lose in every year but two, on both sides, with 65-72% drawdowns at 1% risk.
- **XAUUSD with the guide's 30-point cap:** passes Stage A by the letter (Gate A on real ticks, plateau on 1-min OHLC),
  with almost no margin.
  - +0.008 R per trade.
  - All of the profit is 2024 (+24.3 R): 2022-23 lost 16.5 R and 2025-26 made +1.3 R on about 450 trades.
  - 32.7% drawdown at 1% risk.
  - Read as noise around breakeven, not an edge.
  - The spec's next step (prop_mc and the joint rule, pre-registered separately) was not started.
- **XAUUSD with no cap:** the best 1-min OHLC cell (PF 1.13) but unconfirmed. Real ticks cost the capped cell 0.02 R
  per trade, and without a cap the EA would also take every wide-spread entry, so its real-tick PF would likely sit
  well below 1.13.
- **Live-use findings, independent of the edge:**
  - The build needs AVX2.
  - The guide's 22:00 UK session end is Darwinex's daily close, so EA closes land in rollover and Friday trades are
    held over the weekend.
  - With a spread cap, the per-tick "Spread too wide" message floods the journal.

# Larry_Connors_RSI2_EA on EURUSD H1, as written (pre-registration)

Date: 2026-10-21. User: "let's test now another EA: …/Downloads/LarryConnersRSI2.mq5. The 1st candidate for testing
should EURUSD H1". Server: Darwinex-Demo (user rule: always the first choice for backtests). Scope (the user's choice):
"As-is, then decide": the file is tested unchanged, then the user decides on tuning or fixes.

The EA (algotrading.co.za 2017, MD5 853f9932…, copied unchanged to `mql5/Larry_Connors_RSI2_EA.mq5`, renamed per the
naming convention). On every tick, using the last closed bar of the chart period:
- **Long:** RSI(2) < 6 and close > SMA(200).
- **Short:** RSI(2) > 95 and close < SMA(200).
- **Exit:** a long closes when close > SMA(5); a short closes when close < SMA(5).
- **Size and stops:** fixed 1 lot, stop 30 pips, target 60 pips, one position per symbol (any magic).

A review before the run found these code defects. They are kept, because this test runs the file as written:
- **Signals are checked on every tick.** After a stop or target fills inside a bar, the closed-bar condition still
  holds, so the EA can re-enter in the same bar.
- **Magic number 0.** Positions are not isolated from other EAs.
- **A sell is sent at the Ask price.**
- **No spread filter**, and array reads are not guarded.

The run reports the size of each defect's effect, so a fixed copy can be judged against it later.

## Run (`reports/rsi2/rsi2_eval.py`, Darwinex-Demo, EURUSD H1, real ticks, 2022-01-01..2026-10-01, 100k USD, 1:100)
Compiled defaults (profile `Larry_Connors_RSI2_EA`). Trades are rebuilt from the report's Deals table.

R per trade = net (profit + swap + commission) / $300, the planned loss of 1 lot over 30 pips on EURUSD. That is 0.3% of
the 100k deposit.

## Checks and reports
- **Gate A:** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Reported:**
  - net profit, PF, max equity drawdown, win rate, longs and shorts;
  - exit mix: stop (loss >= 29.5 pips), target (gain >= 59.5 pips), SMA5 exit (the rest);
  - average R per exit type;
  - entries by server hour;
  - same-bar re-entries (more than one entry in one H1 bar) and their net R;
  - order and close errors in the agent log;
  - history quality.
- **prop_mc alone:** close_time,R file, --risk 0.3,0.5, 10k sims, seeds 1-3.
- If Gate A passes, also the joint with the gold live set (the 4 Darwinex logs of spec
  2026-10-21-donchiantrend-gold-joint-prereg.md), reported only.

## Hypothesis
Connors' RSI(2) rule was built for daily stock indices. On EURUSD H1, RSI(2) extremes come often, the reversion to the
5-bar mean is a few pips, and the round-trip cost (spread plus commission, about 1 pip or more) eats a large share of
it.
- Expected: several hundred trades, mostly closed by the SMA5 exit, and few targets hit.
- Expected: PF 0.85-1.05 and Gate A fails.
- Same-bar re-entries are rare (under 2% of trades).

## Decision rule
- **Gate A fails:** EURUSD H1 is closed for the EA as written. The report lists what a fixed or tuned version would
  change (each would be pre-registered separately), and the user picks the next candidate symbol or timeframe.
- **Gate A passes:** a fixed copy (one entry per bar, magic number, % risk, spread guard) and an input grid are
  pre-registered next. The as-written file never goes live (magic 0).

## Outcome (2026-10-21; agent log: "EURUSD,H1 (Darwinex-Demo): generating based on real ticks"; history quality 99%; log `reports/rsi2/base.log`)
| as written | net | PF | max equity DD | trades | win | R (per trade) | R 2022-24 / 2025-26 | Gate A | prop_mc @0.3% / 0.5% |
|---|---|---|---|---|---|---|---|---|---|
| EURUSD H1 | -870.55 | 0.99 | 8.17% | 869 (454 L / 415 S) | 61.0% | -2.9 (-0.003) | -21.5 / +18.6 | **fail** | 0.0 / 0.4 |

**Exits:**
| exit | trades | avg R |
|---|---|---|
| SMA5 | 686 | +0.225 |
| stop | 172 | -1.026 |
| target | 10 | +1.99 |

**Costs:** commission -$4,756 (-15.9 R, $5.47 per trade) and swap -1.5 R. Before costs the rules made +14.5 R
(+0.017 R per trade), so commission alone erases the edge.

**Code checks:**
- **Same-bar re-entries:** 39 extra entries in 31 bars, -5.8 R. Removing them leaves 830 trades, +2.9 R, PF 1.015,
  still -15.1 R in 2022-24.
- **Agent log:** 0 failed orders and 0 array errors.

**Decision: Gate A fails, so EURUSD H1 is closed for the EA as written.** The hypothesis held on PF and the exit mix.
Same-bar re-entries were 4.5% of trades, above the forecast of under 2%. Fixing them alone would not pass Gate A
(2022-24 stays negative).

The independent code review confirmed the defects and ranked them for live use:
1. magic 0 with whole-symbol position selection; it can also close manual EURUSD trades;
2. no once-per-bar gate, so it re-opens after any close, including a manual or risk-manager flatten;
3. fixed lot with no loss guard;
4. unchecked indicator copies;
5. per-tick retries of rejected orders.

What a new version would have to change, each pre-registered separately:
- **Cost per trade against edge per trade.** A higher timeframe (H4, D1, as Connors used it) gives larger reversion
  moves; a lower-commission symbol or broker cuts the cost.
- **The once-per-bar fix.**

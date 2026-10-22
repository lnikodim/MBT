# ORB_EA: the Zarattini/Barbon/Aziz opening range breakout on the forex majors (pre-registration)

Date: 2026-10-20. User: "I found an interesting research article about a profitable ORB strategy … define a new EA and
backtest it in all appropriate timeframes. Use major forex symbols." Source: Zarattini, Barbon & Aziz (2024), "A
Profitable Day Trading Strategy For The U.S. Equity Market", SSRN 4729284. The user chose "the breakout itself": the
base strategy of section 2.1, without the Stocks-in-Play relative-volume filter and top-20 selection of sections 3-4
(in the paper those carry the result: base 5-min ORB 3.2%/yr, Sharpe 0.48; with relative volume 41.6%/yr, Sharpe 2.81).
Server: Darwinex-Demo real ticks (agreed with the user in the design playback).

## Rules (paper -> `mql5/ORB_EA.mq5` v1.00, magic 261021)
| Paper (section 2.1, section 5) | ORB_EA |
|---|---|
| opening range = first 5 min of the 9:30 ET session; also 15, 30, 60 min | first N min after the London 08:00 (Europe/London) or New York 09:30 (America/New_York) open, DST-aware; N = `InpTimeframe` (M5/M15/M30/H1) |
| range candle bullish: buy stop at the range high only; bearish: sell stop at the low only; doji: no order | same; the candle is the N-minute range (first M1 open, last M1 close, M1 high/low) |
| stop order at the level | market order at the first tick with Ask >= high (buy) or Bid <= low (sell), as an MT5 stop order triggers |
| stop loss 10% of the 14-day ATR from the executed entry | `InpStopATR` 0.10 x D1 ATR(14) of completed days, from the fill price |
| no target, exit at the 16:00 ET close | no target, close at 23:50 server, before the 00:00 rollover (no swap) |
| 1% risk per trade, leverage <= 4x | 1% risk (EACore), tester leverage 1:30: margin can trim lots (risk below 1% on such days; R unaffected) |
| commission $0.0035/share; price/volume/ATR filters | Darwinex commission and real spreads; no filters (majors are liquid) |

Calls made for the translation (not in the paper):
- One entry attempt per day. If the spread exceeds `InpMaxSpreadPoints` 30 (3 pips; 0.3 yen) when the level is crossed,
  the entry waits for a tick within the cap while price is still beyond the level.
- Server clock UTC+2 with US DST (`InpSrvStdOffsetHours` 2, `InpSrvDstRule` US): 00:00 server = 17:00 New York all year,
  so New York opens at 16:30 server and London at 10:00, or 11:00 in the weeks the US is on summer time and the UK is
  not. Checked on data: Darwinex gold trades at 23:xx server in those weeks (16 entries, 16 expected), which an EU-DST
  server clock would not allow. `OnInit` runs a clock self-test on 7 known dates.
- Days with no range data 10 min after the range end (holidays) are skipped. On a day the market closes before 23:50
  (24 and 31 December), a position is closed at the next day's first tick.
- Live: an EA attached after the range end waits for the next day; a restart after today's entry does not trade again.
- EACore loss guards at their defaults (daily -4%, monthly -12%), as in the earlier Stage A batches and live.

Pre-run amendment (independent review before the batch: 4 reviewers, each finding checked by a skeptic; 3 confirmed,
6 refuted): the batch script read a commission column the trade-log loader did not load (it would have crashed on the
first cell; `load_rows` now loads commission and swap, with a test); one failing cell no longer stops the batch; live
only, EACore's late-bar check is off in ORB_EA (`g_loadGMT = 0`), because the day state already handles a late attach
and the check dropped a New York H1 breakout after a 17:00-17:29 restart. No tester trade changes; the self-check
passed before the fixes.

## Runs (`reports/orb/orb_fx.py`, Darwinex-Demo, real ticks, 2022-01-01..2026-10-01, 1% risk, 1:30, 100k USD)
- Self-check first (EURUSD 2025-01..04, New York M5 and London M15, `InpLogEveryBar`): range start times incl. the March
  DST weeks, direction = range candle, level = range high/low, stop = 0.10 x ATR as printed, at most one trade per day,
  entry after the range and beyond the level, same-day exits by stop or 23:50 only, stop-outs about -1 R. All must pass.
- The batch: 7 pairs (EURUSD, GBPUSD, USDJPY, USDCHF, AUDUSD, USDCAD, NZDUSD) x 2 opens (London, New York) x 4 range
  lengths (5, 15, 30, 60 min) = 56 cells, defaults otherwise.

## Checks
- Gate A per cell: trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26, and history quality >= 90% (a stop
  of a few pips cannot be judged on generated ticks; a pair without real ticks for both regimes is reported, not passed).
- Reported per cell: R per trade, win rate, exits by stop / 23:50, median entry spread, and the median cost per trade
  in R (commission; spread over stop distance).
- Pooled per open and range length over the pairs with real ticks: trades, PF in R, net R by regime (reported).
- For each Gate A pass: plateau (a neighbouring range length on the same pair and open has PF >= 1.00), prop_mc alone,
  and the gold live set plus the cell (--bt-risk 1.0, --risk 0.3,0.5, 10k sims, seeds 1-3; gold 4-EA Darwinex logs of
  2026-10-19, joint 93.7-94.1 / 84.2-84.7).

## Hypothesis
On forex the spread and commission on a stop of 0.10 x daily ATR (about 7 pips on EURUSD) cost roughly 0.1 R per
trade, more than the few hundredths of R per trade the paper's base strategy earned on stocks. The stop does not depend
on the range length; a shorter range is crossed more often, so it trades more. Expected: most cells PF < 1, New York
no better than London, the 5-min range not the best (unlike stocks); 0 to 3 of the 56 cells pass Gate A by chance; no
candidate.

## Decision rule
A cell is a candidate only if it passes Gate A, has the plateau, and gold 4-EA + the cell scores >= the gold 4-EA joint
at 0.3% on all 3 seeds. A candidate then gets a separately pre-registered robustness test (costs +50%, stop 0.08 /
0.12 x ATR, the other open, IC Markets data). Without a candidate, the base ORB on the forex majors is closed. No
retuning in this round.

## Outcome (2026-10-20, Darwinex-Demo, history quality 99%): stopped by the user after 18 of 56 cells
User: "leave this experiment, it seems that leaves to a deadend". Done: EURUSD and GBPUSD (all 16 cells), USDJPY London
5 and 15 min.
- EURUSD, GBPUSD: 0 of 16 pass Gate A. PF 0.72-0.92 (one cell 0.99), net -41 to -213 R, win rate 15-26%, drawdown
  68-91% at 1% risk. Costs were 0.11 R per trade (EURUSD) and 0.14 R (GBPUSD), as forecast; most cells lose about the
  cost or more, so the breakout has no edge before costs either.
- USDJPY London: 5 min PF 1.03, +80.5 R (2022-24 -9.7, fails); 15 min PF 1.08, +131.3 R (+107.1 / +24.2), drawdown
  71% at 1% risk, the only Gate A pass. Not followed up (no plateau, prop_mc or joint check) because the batch was stopped.
**Closed: the base ORB on the forex majors is left as a dead end.** Run outputs and the batch script were deleted at the
user's request ("remove all leftovers"); the EA and this record stay.

**Removal (2026-10-22, user rule "when we decide that an EA is failing, always remove the leftovers").** Removed
`mql5/ORB_EA.mq5`, its `scripts/ea_profiles.py` entry and test reference, and the MT5 .mq5, .ex5 and tester .set (no
chart had it). The file stays in git at 099082a.

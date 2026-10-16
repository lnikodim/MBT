# TEB_MTF_EA: TEB63's "5ema & 12ema and 21 RSI (MTF)" (pre-registration)

Date: 2026-10-16. User: "Let's try to test another EA, described in the 1st post of this thread:
forexfactory.com/thread/229238-teb-5ema-12ema-and-21-rsi-mtf. Ask questions if you are not sure how to proceed."
Source: first post by TEB63, 2 Apr 2010 (archived copy and the user's screenshot; the thread title says 21 RSI, the
post says 20 RSI). The post, literally:
- 30-min and 5-min charts; 5 EMA and 12 EMA ("5 & 8 or 5 & 10 doesn't really matter"); 20 RSI with the 50 line
  ("for a better win rate put 45 and 55 on the higher chart RSI"). Post 8: trend from the 30-min, buy/sell signs
  from the 5-min; to trade the 30-min use a 3- or 4-hour chart for trend; trend down = only sell, up = only buy.
  Post 10: wait for the close on the trading chart.
- Two lots: lot 1 target 10 pips + spread, stop 10 pips; lot 2 to break-even when lot 1 is taken out, then "keep
  moving up the stop loss with every swing until I am taken out". Away from the screen: next round number or S/R.
- "Better % on pull backs and break outs than on the crosses" (no definition given).
- Trade 3-5am, 7am-12 and maybe 8-10pm EST, no holidays, careful at 8:30 and 10:00 EST news.
- Pairs: EURUSD mostly, then USDJPY and EURGBP; USDCAD, AUDUSD, EURJPY if no trend on those.

User decisions (AskUserQuestion, 2026-10-16): symbols EURUSD, USDJPY, EURGBP; entry = the cross plus a pre-registered
pullback variant; lot 2 trailed by swings only (no time or round-number exit).

## Hypothesis
A 10-pip scalp on M5 pays about 0.7 pip per side on Darwinex EURUSD (spread + commission), so lot 1 alone needs a
54% hit rate to break even and an EMA cross on M5 does not have it. The system's only durable component is lot 2:
free after +10 pips, trailed under swing lows, it turns a minority of signals into 30-100 pip runners. Whether that
covers the losers is the test; the M30-entry / H4-trend version has fewer, costlier-per-pip but larger trades.
Expected: cross cells PF 0.85-1.05, pullback cells slightly better, sessions help, most cells fail Gate A; a pass is
more likely on the M30/H4 pair than on M5/M30. This is a 2010 forum system; the prior is low.

## EA (`mql5/TEB_MTF_EA.mq5` v1.00, EACore, magic 261017, comment TEB_MTF, spread cap 20 points, retry 0)
Entry chart = `InpTimeframe` (M5), trend chart = `InpTrendTF` (M30); EMA 5/12 and RSI(20) on both, closed bars.
Trend up = trend-chart 5 EMA > 12 EMA and RSI > `InpTrendRsiBuy` (50; variant 55), down mirrored with
`InpTrendRsiSell` (50; variant 45). CROSS entry: entry-chart 5 EMA crosses the 12 EMA on the closed bar with RSI on
the trend side of 50. PULLBACK entry: with 5 EMA above 12 EMA, bar 2 touched the 12 EMA (low <= slow EMA) and closed
at or below the 5 EMA, bar 1 closed back above the 5 EMA, RSI > 50; mirrored for sells. One signal at a time. Lot 1:
stop 10 pips, target 10 pips + current spread. Lot 2 (`InpSecondLot`): same stop, no target; when lot 1 is gone its
stop moves to the entry price, then on every new entry-chart bar to the latest confirmed swing (low with
`InpSwingBars` = 2 higher lows on each side) minus a 1-pip buffer, tightening only. Sessions in Darwinex server time
(= EST + 7 h except the two DST-mismatch weeks): 10-12, 14-19, 03-05, `InpUseSessions` on/off. Pip = 10 points on
3/5-digit symbols. Self-check `scripts/teb_selfcheck.py`: a 2-month EURUSD M5 run, every `TEB SIGNAL` line must
satisfy the trend / cross / pullback / session arithmetic, each signal opens two positions (lot 1 target = 10 pips +
spread, lot 2 no target, both stops 10 pips), lot-2 exits after a lot-1 target are at or above break-even.

## Stage A (`reports/teb/stage_a.py`, 1-min OHLC, 2022-01-01..2026-10-01, 1% risk per position)
48 cells: symbol {EURUSD, USDJPY, EURGBP} x charts {M5 entry / M30 trend, M30 entry / H4 trend} x entry {CROSS,
PULLBACK} x trend RSI {50/50, 55/45} x sessions {on, off}. Stops and targets stay 10 pips in every cell (the post gives
no other number). Gate A per cell: trades >= 150, tester PF >= 1.00, net R > 0 in both 2022-24 and 2025-26 (R is per
position). Plateau for passers: EMA pairs 5/8 and 5/10 (the author's alternatives) and stops 8 and 12 pips, 4 runs,
mean PF >= 1.00 and >= 3 of 4 profitable. Then prop_mc and the joint rule against the account's Darwinex control
(MACD + Donchian + RSI_Reversal, plus MA_Channel v1.01 if its Darwinex rerun passes): joint pass >= control at both
0.3% and 0.5%, p95 DD at 0.5% not more than 1 pt worse. Caveat accepted by the user's rule: 1-min OHLC modelling with
10-pip stops resolves same-minute stop-and-target hits by the model's synthetic 4-tick path.

## Outcome (2026-10-16, Darwinex-Demo 1-min OHLC, log `reports/teb/stage_a.log`, runs `reports/teb_*`)
Self-check: both entry modes pass (70 and 95 signals in Jan-Feb 2026 EURUSD M5; two positions per signal; lot 2 at
break-even after all 85 lot-1 targets). One fix on the way: the signal line printed EMAs at 5 decimals, which made
sub-0.1-pip crosses look equal; now 8 decimals (commit 238be79).

Stage A, 48 cells (1% risk per position; PF range over the 8 cells of each symbol and chart pair):

| symbol, charts | PF range | trades | tester DD | profitable cells | best cell (PF, R 2022-24 / 2025-26) |
|---|---|---|---|---|---|
| EURUSD M5 / M30 | 0.71-0.90 | 2,663-4,962 | 89-100% | 0 / 8 | pullback, RSI 55/45, sessions: 0.90, -38 / -125 |
| EURUSD M30 / H4 | 0.72-0.93 | 960-2,374 | 58-94% | 0 / 8 | cross, RSI 55/45, no sessions: 0.93, +19 / -95 |
| USDJPY M5 / M30 | 0.88-0.95 | 3,497-7,781 | 89-99% | 0 / 8 | cross, RSI 50, no sessions: 0.95, -39 / -211 |
| USDJPY M30 / H4 | 0.87-1.07 | 1,058-2,842 | 56-90% | 2 / 8 | pullback, RSI 50, sessions: 1.07, +121 / -12 |
| EURGBP M5 / M30 | 0.58-0.87 | 2,447-3,956 | 98-100% | 0 / 8 | pullback, RSI 50, sessions: 0.87, -204 / -268 |
| EURGBP M30 / H4 | 0.58-0.71 | 858-1,980 | 81-99% | 0 / 8 | cross, RSI 55/45, no sessions: 0.71, -179 / -103 |

**Gate A: 0 of 48 pass.** No cell is positive in 2025-26; the 8 cells positive in 2022-24 are all M30/H4 (6 USDJPY,
2 EURUSD) and all give it back in 2025-26. Plateau, prop_mc and the joint rule were not reached. Mean PF by switch:
cross 0.81 vs pullback 0.82, RSI 50 0.82 vs 55/45 0.81, sessions 0.83 vs none 0.80: none of the author's
refinements moves the result.

Where it loses (lot 1 = 10-pip scalp, lot 2 = break-even then swing trail):

| cell | lot-1 hit rate (needed) | lot-1 R | lot-2 R | lot-2 runners > +2 R |
|---|---|---|---|---|
| EURUSD M5 cross, RSI 50, sessions | 46.2% (52.4%) | -216 | -227 | 127 of 1,854 |
| EURUSD M30 cross, RSI 50, sessions | 48.8% (52.4%) | -50 | -32 | 61 of 701 |
| USDJPY M30 pullback, RSI 50, sessions | 49.7% (52.8%) | -43 | +152 | 66 of 749 |

The scalp lot loses everywhere: the cost of a round trip moves the break-even hit rate to 52-53% and the signal
delivers 46-50%. The runner lot only pays where the pair trended for years (USDJPY 2022-24), as the hypothesis
expected, and that trend ended in 2025.

### Verdict
TEB_MTF_EA as posted fails Stage A on all three of the author's pairs. CLOSED: no retune (stops and targets are
fixed by the post, and every switch the post offers was tested). The EA, profile, self-check and batch stay as tools.
The expectation (cross cells PF 0.85-1.05, most cells fail, M30/H4 likelier) was right; sessions and pullbacks helped
less than expected.

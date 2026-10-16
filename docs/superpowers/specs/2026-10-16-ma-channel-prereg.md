# MA_Channel_EA: Kennedy's moving-average price channel (pre-registration)

Date: 2026-10-16. User: "Read this [High Probability using Moving Average.pdf] and make a hypothesis if we can build a
brand new EA based on the findings in this PDF. If it is valuable, backtest it always with 1min OHLC modelling."
Source: Jeffrey Kennedy (Elliott Wave International, 2010), the free first two chapters of "How to Trade the Highest
Probability Opportunities: Moving Averages". The PDF has no backtest, no stop rule and no numbers; its mechanical
content is:
1. Dual SMA crossover (5/10) lags and whipsaws in ranges; "there is no magic setting".
2. **Moving-average price channel**: upper = SMA20 of highs, lower = SMA20 of lows, signal line = SMA5 of closes.
   Buy when the signal line crosses above the upper line, sell when it crosses below the lower line.
3. **Combined**: slow entry from the channel, quick exit from the 5/10 crossover against the position.
4. **Pullback**: in an uptrend (signal line above the channel) a dip of the signal line into the channel that turns
   back up is a buy ("countertrend move within a larger uptrending market"); mirrored for downtrends.
5. Popular settings 50/200, 10/40, 13, 13/26 (not tested here: they are not a rule).

## Hypothesis
The channel system is a smoothed Donchian breakout: SMA20(high) sits below the 20-bar high, so it signals earlier
and more often than `Donchian_Breakout_EA` (N 20, which passed Gate A on XAUUSD H4) and whipsaws more. The quick
5/10 exit will cut trend winners (the Donchian work showed even a +1R break-even lock hurts a 2R system). The
pullback entry is the only genuinely new signal. Expected value for the user: a long-only H4 channel cell probably
passes Gate A because it is Donchian's cousin, but its trades overlap Donchian's, so it will not lift the joint
prop_mc; the pullback cells are the real test. Worth one pre-registered screen because the EA is 150 lines on
EACore and a run takes 20 s.

## EA (`mql5/MA_Channel_EA.mq5` v1.00, EACore, magic 261016, comment MA_CH, spread retry 0)
Inputs: `InpFastMA 5`, `InpSlowMA 10`, `InpChannelMA 20` (SMA of highs / SMA of lows), `InpEntryMode`
(BREAKOUT = signal-line cross of the channel; PULLBACK = after the last channel break in that direction, the signal
line sits inside the channel on bar 2, made a local extreme there (f2 < f3) and turned (f1 > f2); mirrored for
shorts), `InpExitMode` (CHANNEL = opposite channel cross, the PDF's channel system, same-bar reversal allowed;
CROSS = 5/10 SMA cross against the position, the PDF's combined system; TARGET = R x stop, no bar exit),
`InpTargetR 2`, `InpStopATR 2` x `ATR(InpATRPeriod 20)` protective stop in every mode (the PDF has none; EACore
sizes by the stop), `InpAllowShort true` (the PDF trades both sides), `InpTrendTF H4` / `InpTrendEMA 0` (off; the
Donchian filter, available for one pre-registered extra). One position at a time. All reads on closed bars.
Self-check `scripts/ma_channel_selfcheck.py`: two 2-month H1 runs (breakout+cross, pullback+channel), the
`MACH SIGNAL` / `MACH EXIT` k=v lines must satisfy the cross/turn arithmetic, stops = k x ATR, sides match.

## Stage A (`reports/ma_channel/stage_a.py`, 1-min OHLC, XAUUSD, 2022-01-01..2026-10-01, 1% risk, defaults)
24 cells: timeframe {H1, H4} x entry {BREAKOUT, PULLBACK} x exit {CHANNEL, CROSS, TARGET 2R} x shorts {on, off},
trend filter off. One pre-registered extra per timeframe: the best Gate-A cell with `InpTrendEMA 200` (H4).
D1 is not run: fewer than 60 signals in 4.75 years cannot meet the trade bar.

### Gate A per cell (unchanged from the Donchian spec)
trades >= 150; tester PF >= 1.00; net R > 0 in both 2022-24 and 2025-26. With 24 cells a lone pass is a candidate,
not a result: it must also show a plateau (its 4 one-step neighbours `InpChannelMA` 15/25 and `InpFastMA` 3/8 average
PF >= 1.00 and at least 3 of 4 profitable). Then prop_mc at 0.3% / 0.5% and the joint rule: joint pass with
MACD v1.45 + Donchian v1.01 + RSI v1.20 (Darwinex logs) >= the control 91.4% / 82.9% at both risks, p95 DD at
0.5% not more than 1 pt worse. A cell that passes Gate A but not the joint rule is a validated strategy that earns no
place on the account.

### Data caveat (decided before the runs)
The Mac terminal is logged into ICMarketsEU-Demo, which is live-trading another strategy, and the GUI stays open. If
the headless tester can run alongside it, Stage A runs on IC Markets 1-min history (prices identical to Darwinex
for XAUUSD within spread; costs differ by a few points per trade). A negative screen is final on either data. A
Gate-A pass is confirmed on Darwinex-Demo before the joint rule is applied, because the joint logs are Darwinex's.

## Expectation written before the runs
H1 breakout cells: PF 0.9-1.1, 400-800 trades, negative 2022-24 (fail). H4 breakout long-only with TARGET 2R:
PF 1.2-1.5, 150-250 trades, likely pass, correlated with Donchian (joint change within +-1 pt: no adoption).
CROSS exits: lower PF than TARGET in every pair. Pullback cells: 2025-26 positive, 2022-24 unclear; if one passes
on H4 long-only it is the interesting one. Most likely outcome: 1-3 H4 long-only passes, no joint improvement, EA
kept as a validated tool like the others.

## Outcome (2026-10-16, log `reports/ma_channel/stage_a.log`, runs `reports/mach_*`; IC Markets 1-min history, see caveat)
Self-check: both entry modes pass (41 and 19 trades in Jan-Feb 2026, every signal / exit line satisfies the
cross or turn arithmetic, stops = 2 x ATR, one position at a time).

Stage A, 24 cells (1% risk; R by regime; Gate A = >= 150 trades, PF >= 1, both regimes > 0):

| cell | trades | PF | DD | R 2022-24 / 2025-26 | Gate A |
|---|---|---|---|---|---|
| H1 breakout, channel exit, L+S / L | 1101 / 560 | 1.20 / 1.36 | 31% / 27% | +89 / +54, +57 / +60 | pass / pass |
| H1 breakout, MA-cross exit, L+S / L | 1476 / 786 | 1.14 / 1.26 | 24% / 21% | +43 / +45, +30 / +49 | pass / pass |
| H1 breakout, 2R target, L+S / L | 876 / 586 | 1.09 / 1.09 | 26% / 21% | +41 / +20, +28 / +13 | pass / pass |
| H1 pullback, channel exit, L+S / L | 570 / 292 | 1.28 / **1.61** | 17% / **12%** | +47 / +44, **+54 / +45** | pass / pass |
| H1 pullback, MA-cross exit, L+S / L | 849 / 486 | 1.14 / 1.35 | 20% / 14% | +26 / +31, +40 / +33 | pass / pass |
| H1 pullback, 2R target, L+S / L | 574 / 342 | 1.00 / 1.18 | 20% / 17% | +22 / -18, +48 / -2 | fail / fail |
| H4 breakout, channel exit, L+S / L | 254 / 124 | 1.26 / 1.66 | 23% / 20% | +8 / +32, +13 / +33 | pass / fail (count) |
| H4 breakout, MA-cross exit, L+S / L | 335 / 173 | 1.10 / 1.48 | 24% / 18% | -4 / +18, -3 / +32 | fail / fail |
| H4 breakout, 2R target, L+S / L | 210 / 131 | 1.01 / 1.45 | 23% / 11% | -7 / +10, +15 / +19 | fail / fail (count) |
| H4 pullback, channel exit, L+S / L | 142 / 70 | 1.61 / 2.14 | 19% / 16% | +19 / +30, +15 / +30 | fail (count) / fail (count) |
| H4 pullback, MA-cross exit, L+S / L | 186 / 100 | **1.49** / 1.82 | 15% / 11% | **+28 / +12**, +21 / +15 | pass / fail (count) |
| H4 pullback, 2R target, L+S / L | 137 / 87 | 1.24 / 1.67 | 12% / 8% | +24 / -1, +17 / +16 | fail / fail (count) |

12 of 24 pass Gate A and all 12 hold their plateau (every neighbour cell profitable, neighbour PF means 1.10-1.55;
the pullback-channel long-only cell's neighbours are 1.46 / 1.49 / 1.54 / 1.54). EMA200 extras: on H1 pullback
channel long-only the filter lowers PF 1.61 -> 1.53 and trades 292 -> 211 (no help); on H4 pullback cross it lifts
PF to 1.87 but leaves 126 trades (fails the count). 2R targets are the worst exit in every pair, channel exits the
best: the PDF's "let the channel take you out" beats both the quick 5/10 exit and a fixed target.

Stand-alone prop_mc pass 0.3% / 0.5%: H1 pullback channel L 20.3 / 49.0 (every year positive: 2022 +4.9, 2023 +23.1,
2024 +26.2, 2025 +32.0, 2026 +13.2 R; PF 1.65, max DD 9.4 R; median hold 18 h; swap -27.8k included), H4 pullback
cross L+S 0.7 / 9.3 (2026 -4.8 R), H1 breakout channel L+S 46.1 / 66.6 (DD 31%).

Joint rule (MACD v1.45 + Donchian v1.01 + RSI v1.20 control, 10k sims, 3 seeds; pass 0.3% / 0.5%, breach at 0.5%,
p95 DD at 0.5%):

| set | seed 1 | seed 2 | seed 3 |
|---|---|---|---|
| control | 91.4 / 82.9, 9.5, 16.9 | 91.1 / 83.4, 9.0, 16.9 | 90.7 / 83.4, 9.1, 16.8 |
| + H1 pullback channel L | **94.2 / 84.9, 8.3, 17.3** | 94.4 / 85.5, 8.0, 17.4 | 94.2 / 85.2, 8.4, 17.2 |
| + H4 pullback cross L+S | 92.7 / 85.0, 8.6, 17.0 | 92.6 / 84.7, 8.3, 17.0 | 93.2 / 84.4, 8.4, 17.1 |
| + H1 pullback cross L | 92.9 / 82.9, 9.7, 17.3 | 93.0 / 82.8, 9.6, 17.2 | 93.2 / 83.1, 9.3, 17.2 |
| + both (information) | 94.9 / 84.9, 8.3, 17.3 | 95.2 / 85.2, 8.3, 17.1 | 94.9 / 84.9, 8.5, 17.4 |

Other Gate-A cells lower the joint pass at 0.5% (seed 1 in the log). H1 pullback channel long-only instead of
Donchian: 93.5 / 85.1 (it could replace Donchian, not pre-registered as a decision).

### Verdict (provisional: IC Markets history, Darwinex confirmation pending)
- **H1 pullback entry, channel exit, long only** meets Gate A, the plateau and the joint rule on all three seeds
  (+3 pts at 0.3%, +2 pts at 0.5%, breach 9.5 -> 8.3, p95 DD +0.4). It is the candidate fourth EA. The expectation
  above was wrong on H1 (predicted PF 0.9-1.1 and a negative 2022-24) and right that the pullback entry is the new
  signal and that the quick exit costs.
- **H4 pullback, MA-cross exit, both sides** also meets every rule (+1.5-2 / +1-2 pts) but adds only +0.7 pt at
  0.3% and nothing at 0.5% once the H1 pullback cell is in: a validated alternative, not a second addition.
- **H1 pullback, MA-cross exit, long only** fails the joint rule (below the control at 0.5% on seeds 2 and 3).
- Caveats: IC Markets 1-min history (median spread 5 pts and 7 USD/lot vs Darwinex 19-20 pts and 13-17 USD/lot:
  about 0.005 R per trade on 2 x ATR H1 stops, immaterial); 24 cells + 48 neighbours screened (the winner's plateau
  and five positive years are the defence); long gold swap is in the numbers.
- Next (pre-registered here): rerun `mach_H1_pb_ch_l` and `mach_H4_pb_x_ls` on Darwinex-Demo once the Mac terminal
  is logged back in; if Gate A holds there (trades within 10%, PF >= 1.4, both regimes > 0) and the joint rule holds
  with the Darwinex log, v1.01 makes H1 / PULLBACK / CHANNEL / long-only the compiled defaults and the EA joins the
  account at 0.3% per position.

### Release (2026-10-16, user: "ok, release 1.01 with pullback entry")
v1.01 compiled defaults = H1, `InpEntryMode PULLBACK`, `InpExitMode CHANNEL`, `InpAllowShort false` (everything
else unchanged). Parity run `mach_v101_default` with no overrides: 292 trades, PF 1.61, net 150,761, DD 12.25%,
identical to `mach_H1_pb_ch_l`. Released on the user's decision before the Darwinex confirmation; that rerun stays
on the list and its gate above still applies.

### Darwinex confirmation (2026-10-16, run `dxc_mach_v101` and `dxc_mach_h4_pbx`, 1-min OHLC)
v1.01 defaults on Darwinex-Demo: 299 trades (+2.4% vs 292), PF 1.55, +95.7 R, DD 12.2%; 2022 +2.5, 2023 +24.7,
2024 +29.8, 2025 +31.4, 2026 +7.3 R. Gate: trades within 10% yes, PF >= 1.4 yes, both regimes > 0 yes. Joint with the
3-EA control: 94.5 / 85.1, 94.6 / 85.3, 94.0 / 85.2 vs 91.4 / 82.9, 91.1 / 83.4, 90.7 / 83.4; breach 9.5 -> 8.1;
p95 DD +0.5. **CONFIRMED**: v1.01 stays the released default and joins the account at 0.3% per position.
H4 pullback / cross / both sides on Darwinex: 203 trades, PF 1.27, +20.9 / +4.0 R; joint 92.1 / 83.8 alone and it
lowers the pair when added to v1.01 (94.0 / 84.3): not used.

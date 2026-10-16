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

# abebr/awesome-mql5-expert-advisors: eight EAs, outcome (2026-10-27)

Request: user, 2026-10-27, shared the repo link, then "go" to screen the EAs.
Runner: `reports/oct25/screen10.py`; log: `reports/oct25/screen10.log`.
Setup: Darwinex-Demo, real ticks, $10,000 deposit, 1:100, Gate A 2024-01..2026-10, two-rejects rule per EA. Each EA on its own defaults, H1 (none of them sets a timeframe in its source).

Scan: the source has no `#import`, DLL, `WebRequest`, socket or mail calls. The repo ships prebuilt `.ex5` binaries; they were ignored, and every EA was compiled from source (0 errors, 0 warnings).

## Results

| EA | EURUSD (trades, PF, net USD, total R) | GBPUSD | Verdict |
|---|---|---|---|
| BollingerBands_MeanReversion | 820, 0.91, −3,285.73, −34.5 | 975, 0.95, −2,887.26, −27.3 | REJECT (PF) |
| Breakout_Template | 0 trades | 0 trades | No trades: breakout check can't be true (see below) |
| Grid_Hedging_Reversal | 551, 0.99, −10.52, n/a (overlap) | 675, 0.89, −295.49, n/a (overlap) | REJECT (PF) |
| London_NewYork_Session_Breakout | 588, 0.91, −2,332.26, −22.5 | 667, 0.91, −3,010.21, −31.8 | REJECT (PF) |
| MACD_Trend_Momentum | 452, 0.88, −2,212.96, −23.2 | 521, 0.97, −754.01, −4.3 | REJECT (PF) |
| MovingAverage_Crossover | 292, 0.80, −1,925.43, −20.6 | 322, 0.82, −2,159.99, −23.6 | REJECT (PF) |
| RSI_MultiTF_Scalper | 424, 0.79, −3,583.13, −42.5 | 436, 0.83, −2,972.01, −32.8 | REJECT (PF) |
| SuperTrend_MultiTF_TrendFollower | 0 trades | 0 trades | No trades: entry needs a bar range above 6 × ATR (see below) |

No candidate. Every EA that traded lost money on both majors it ran.

## Logic faults

- **Breakout_Template:** the breakout window starts at bar 1, the signal bar. The close of bar 1 can never be above the highest high of bars 1..20, so the buy condition is never true; the sell side fails the same way. The EA can't trade on any symbol or timeframe as published. Not fixed: the fix changes the author's logic, and it needs approval.
- **SuperTrend_MultiTF_TrendFollower:** a long needs the previous close above the median price plus 3 × ATR. The close can't exceed the high, so the bar's range must be above 6 × ATR; the short side needs the mirror image. Such bars are rare, so the EA almost never trades. Not fixed, for the same reason.

## Cleanup (standing rule: fail verdict)

- Removed the MT5 `Experts\Awesome` folder (the eight EAs' sources, `.ex5` files and compile logs, and the shared `Include` copies).
- Removed the eight closed EAs' temporary profile entries and folder mapping from `scripts/ea_profiles.py`.
- Kept: the runner and its log, and this outcome.
- Still pending in the same run: AstralBot and SmartMoney MTF v2, then the 14 clean geraked EAs. The geraked set shares `EAUtils.mqh`, `errordescription.mqh` (in MT5 `MQL5\Include`) and nine indicators plus `ATR_HeikenAshi` (in MT5 `MQL5\Indicators`), which are removed after that set's verdicts.

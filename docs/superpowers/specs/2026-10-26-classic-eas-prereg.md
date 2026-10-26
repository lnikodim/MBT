# Classic mql5.com Code Base EAs: screen on source defaults (pre-registration)

Date: 2026-10-26. User: "continue" (the mql5.com "best" list research; "skip it, test the next EA"). Server: Darwinex-Demo.
After ORB_RiskManaged closed, I took five classic, highly rated EAs from the shortlist whose pages state their symbol or timeframe. All sources
were read and scanned: **no DLL, web or file calls**, no martingale or grid, no custom indicators. Copied unchanged.

| EA (code, file, MD5) | what it does | stated symbol, timeframe |
|---|---|---|
| `SMA_ADX_EA` (123, simple_ma-adx_ea_en.mq5, 3cf897dd) | SMA(8) and ADX(8, min 22) entries; stop 30, target 100 (points); 0.1 lot | "best results for 30 min, 1H and 2H" |
| `Puria_EA` (138, puria.mq5, dc99e83d) | "Puria method": three MAs (75 / 85 linear weighted on low, 5 EMA on close) plus an extra filter; stop 14, target 15 (points); 0.1 lot | AUDJPY M30 and others, H1 / M30 |
| `KijunSen_EA` (17462, Kijun_Sen_Robot.mq5, 5d67261f) | Ichimoku Kijun-sen, MA and SAR; hours limited; stop 50, break-even 9, trail 10 (pips); 1 lot | GBPUSD and EURUSD, M30 |
| `RSI_Classic_EA` (17284, RSI_EA.mq5, dab3d9fa) | buys RSI(14) < 30, sells > 70, closes on the opposite signal; **no stop, no target**; default AutoLot = 10% of free margin | none stated |
| `ADX_Classic_EA` (17030, ADX_System.mq5, 3f12e6d1) | iADX signals; stop 100, target 15, trail 20 (pips); 1 lot | none stated |
Compile: 0 errors; SMA_ADX and Puria show 3 benign warnings (deprecated constant).

## Two adjustments, both for a mechanical reason and not from results
- **Point units (SMA_ADX, Puria):** their stops and targets are in **points**. On a 5-digit pair 14 / 15 points is 1.4 / 1.5 pips, a 4-digit-era setting. Each
  also runs with the values multiplied by 10 (SMA_ADX 300 / 1,000; Puria 140 / 150), the pip reading of the same numbers.
- **RSI Classic sizing:** the default **AutoLot** sizes from 10% of free margin, which makes the lot depend on leverage. It runs on the defaults and once with
  `AutoLot` = false (0.1 lot, `ManualLots`).

## Cells (real ticks, 10,000 USD, 1:100)
| cell | EA | symbol, timeframe | inputs |
|---|---|---|---|
| sma_E, sma_E10 | SMA_ADX_EA | EURUSD H1 | defaults; stop 300 / target 1,000 |
| pur_A, pur_A10 | Puria_EA | AUDJPY M30 | defaults; stop 140 / target 150 |
| pur_E, pur_E10 | Puria_EA | EURUSD H1 | defaults; stop 140 / target 150 |
| kij_G, kij_E | KijunSen_EA | GBPUSD M30; EURUSD M30 | defaults |
| rsi_D, rsi_M | RSI_Classic_EA | EURUSD H1 | defaults; `AutoLot` = false |
| adx_E | ADX_Classic_EA | EURUSD H1 | defaults |
- **Multiple testing:** 12 cells. EURUSD H1 is a guess for the EAs that state no symbol.

## Runs and gates (as in the earlier screens)
1. **Screen, 2024-01-01..2026-10-01:** reject if trades < 40, PF < 1.00, net <= 0 or a stop-out.
2. **S0, 2022-01-01..2026-10-01**, survivors: trades >= 150, PF >= 1.00, net > 0 in both 2022-24 and 2025-26. Yearly figures from the deals table.
3. **S1, 2019-01-01..2022-01-01**, Gate A survivors: net > 0, PF >= 1.05, t >= 1.65 (inconclusive if history < 90%).
4. **Candidate** = all pass. A stop-less cell (RSI Classic) also reports the max drawdown and open positions and must pass the grid-style check: no stop-out and a
   drawdown-scaled return of >= +10% a year in both regimes.

## Expectation (written before the runs)
- **Most reject.** These are 2010-2018 teaching and showcase EAs; their pages show no multi-year tests on current data.
- **The point-unit defaults** (Puria 14 / 15 points) will lose to the spread. The x10 versions are the fair readings.
- **RSI Classic:** stop-less with 10%-of-margin sizing, so it is likely to stop out on defaults; the fixed-lot cell is the real test.
- **Most likely outcome:** zero candidates, at most one cell reaching 2022-26.

## Outcome (2026-10-26; log `reports/oct25/cls.log`): all five EAs closed, every cell rejected at the screen
Real ticks, 2024-01..2026-10, 10,000 USD, 1:100. Yearly figures from the deals table where positions overlapped.

| cell | net USD (sizing) | PF | max DD | trades | win | R (mean, t) | by year (24 / 25 / 26) | note |
|---|---|---|---|---|---|---|---|---|
| sma_E SMA_ADX defaults | **-9,631.37** (0.1 lot) | 0.79 | 97.4% | 1,815 | 20.3% | n/a | -9,376 / -255 / - | 3-pip stop; 1,285 overlapping positions |
| sma_E10 SMA_ADX x10 | **-4,679.84** (0.1 lot) | 0.62 | 53.8% | 90 | 42.2% | n/a | -4,680 / - / - | **60 stop-out events**: no check for open positions, 87 of 90 overlapped |
| pur_E Puria EURUSD H1 | **-456.17** (0.1 lot) | 0.86 | 5.7% | 405 | 47.2% | -32.6 (-0.080, t -1.53) | -207 / -12 / -237 | 1.4-pip stop |
| pur_E10 Puria x10 | **-235.02** (0.1 lot) | 0.95 | 11.9% | 62 | 48.4% | -1.7 (-0.027, t -0.20) | -941 / +1,075 / -369 | break-even |
| pur_A Puria AUDJPY M30 | **-1,798.62** (0.1 lot) | 0.62 | 18.2% | 757 | 39.4% | -196.3 (-0.259, t -6.43) | -518 / -803 / -478 | the page's own pair |
| pur_A10 Puria AUDJPY x10 | **-148.56** (0.1 lot) | 0.98 | 11.0% | 131 | 48.9% | -0.8 (-0.006, t -0.07) | -282 / -370 / +503 | break-even |
| kij_G Kijun Sen GBPUSD M30 | **-5,799.26** (1 lot) | 0.52 | 58.0% | 431 | 29.0% | n/a | -2,950 / -2,849 / - | no trades after 2025-10-31 (cause not checked) |
| kij_E Kijun Sen EURUSD M30 | **-6,404.91** (1 lot) | 0.40 | 64.3% | 660 | 21.8% | n/a | -2,216 / -3,235 / -953 | |
| rsi_M RSI fixed 0.1 lot | **-773.19** | 0.85 | 16.6% | 139 | 62.6% | n/a (no stop) | +742 / -761 / -755 | |
| rsi_D RSI default AutoLot | **-2,323.21** (up to 0.37 lot) | 0.84 | 42.3% | 139 | 63.3% | n/a | +2,090 / -2,631 / -1,782 | same trades, larger size |
| adx_E ADX System | **-6,833.31** (1 lot) | 0.67 | 73.9% | 157 | 63.7% | -6.8 (-0.044, t -1.72) | -6,833 / - / - | stopped 2024-11-27: 1,617 orders refused "not enough money" |

- **No cell passes the screen;** Gate A and the out-of-sample stage were not run.
- **Point-unit defaults** (SMA_ADX, Puria) lose to costs as expected. The x10 readings are break-even at best (Puria) or stack positions into a stop-out (SMA_ADX).
- **Fixed 1-lot EAs** (Kijun Sen, ADX System) drain 58-74% and then stop trading.
- **RSI EA:** a stop-less mean-reversion; the default margin-based sizing triples the loss of the fixed-lot run.
- **Expectation check:** expected most to reject and zero candidates. All rejected.
- **Removed** per the leftovers rule: the five `mql5/*.mq5` sources (in git at 8af2165), their profiles and the MT5 copies.

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

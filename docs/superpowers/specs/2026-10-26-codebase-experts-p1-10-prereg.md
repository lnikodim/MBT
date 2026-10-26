# mql5.com Code Base experts, pages 1-10: screen (pre-registration)

Date: 2026-10-26. User: "Screen the 1st 10 pages of https://www.mql5.com/en/code/mt5/experts with the existing assessing framework and give as
output a quick summary of the winners that could be part of the current live account portfolio." Server: Darwinex-Demo.

## Step 0, inspection (no runs)
- **Listing:** pages 1-10, 399 entries. 42 were tested here before; about 130 are tools (guards, notifiers, auditors, panels, snippets) by title.
- **Downloaded:** 77 candidate sources (one request every 6 seconds). An automatic scan checked DLL / web calls, grid and martingale code, custom indicators
  and includes missing from the download, and whether the file has `OnTick`.
- **Rejected at inspection (28):**
  - no trading code: 10 snippets / scripts without `OnTick`, plus 43678 (a fractal snippet) and 78046 (a quote-physics monitor with no orders);
  - missing custom indicators: 38914, 38985, 39175, 39497, 39688, 39767, 60961, 77918;
  - grids, martingales or hedge-lot multipliers: 62684, 62713, 62812, 64444, 75264, 73210;
  - other: 52043 (a BTCUSD pair trade), 50850 (does not compile: it redefines `Comment`).
  - The scan's "grid" word was only a "no grid, no martingale" comment in 77060, 70052 and 68951; they stay.
- **49 EAs remain,** copied unchanged as `mql5/CB<code>_EA.mq5`, with bundled indicators and includes installed in MT5 (listed in the manifest for
  removal). All compile with 0 errors. Profiles hold the numeric / bool source defaults.

## Cells (real ticks, 10,000 USD, 1:100, source defaults; one symbol each)
| cell | code | symbol, timeframe | why |
|---|---|---|---|
| cb42283 | 42283 | EURUSD M15 | stated EURUSD M15 |
| cb43252 | 43252 | EURUSD M5 | stated EURUSD/GBPUSD M5 |
| cb43278 | 43278 | GBPAUD M15 | stated GBPAUD 15 min |
| cb68512 | 68512 | EURUSD H1 | stated EURUSD/GBPUSD/USDJPY, H1/M15 |
| cb68951 | 68951 | EURUSD M15 | H4 swings, M15 sweeps |
| cb69651 | 69651 | XAUUSD H1 | stated gold, no timeframe |
| cb70052 | 70052 | XAUUSD M15 | stated gold/forex M5-M15 |
| cb70916 | 70916 | EURUSD H4 | stated EURUSD, D1/H4/M15 |
| cb73674 | 73674 | SP500 D1 | Turnaround Tuesday, daily |
| cb73884 | 73884 | SP500 D1 | inside bar, daily (same series) |
| cb74137 | 74137 | SP500 D1 | day-of-week reversal, daily (same series) |
| cb74135 | 74135 | XAUUSD H1 | stated gold |
| cb75002 | 75002 | XAUUSD M5 | stated gold M5 |
| cb75586 | 75586 | XAUUSD M15 | stated gold M15, London breakout |
| cb76333 | 76333 | AAPL M5 | stated AAPL CFD |
| cb77060 | 77060 | XAUUSD H1 | stated gold, first hour after the CME break |
| cb77180 | 77180 | XAUUSD M15 | title: XAUUSD M15 |
| cb23628 | 23628 | USDJPY H1 | stated USDJPY H1, hedge |
| cb52105 | 52105 | EURUSD M1 | stated M1 |
| cb57020 | 57020 | EURUSD H1 | stated H1/H4 |
| cb74894 | 74894 | EURUSD H4 | code uses H4 |
| cb35556 | 35556 | EURUSD H1 | none stated |
| cb35588 | 35588 | EURUSD H1 | none stated |
| cb38897 | 38897 | EURUSD H1 | none stated |
| cb39012 | 39012 | EURUSD H1 | none stated |
| cb39334 | 39334 | EURUSD H1 | none stated |
| cb39425 | 39425 | EURUSD H1 | none stated |
| cb39582 | 39582 | EURUSD M5 | AMA Trader family (21971: EURUSD M5) |
| cb39591 | 39591 | EURUSD H1 | none stated |
| cb39703 | 39703 | EURUSD H1 | none stated |
| cb41739 | 41739 | EURUSD H1 | none stated |
| cb44883 | 44883 | EURUSD M5 | none stated, a scalper |
| cb49770 | 49770 | EURUSD H1 | none stated |
| cb52152 | 52152 | EURUSD H1 | none stated |
| cb53526 | 53526 | EURUSD H1 | none stated |
| cb54127 | 54127 | EURUSD H1 | none stated |
| cb54612 | 54612 | EURUSD H1 | none stated |
| cb58135 | 58135 | EURUSD H1 | none stated |
| cb58361 | 58361 | EURUSD M5 | ICT silver bullet, intraday |
| cb60347 | 60347 | EURUSD H1 | weekend gap, none stated |
| cb61998 | 61998 | EURUSD H1 | none stated |
| cb62742 | 62742 | EURUSD H1 | none stated |
| cb68125 | 68125 | EURUSD H1 | none stated, educational |
| cb74379 | 74379 | EURUSD H1 | none stated |
| cb74815 | 74815 | EURUSD H1 | none stated |
| cb74818 | 74818 | EURUSD H1 | none stated |
| cb77414 | 77414 | EURUSD H1 | none stated |
| cb78411 | 78411 | EURUSD H1 | basket of USD pairs |
| cb78454 | 78454 | EURUSD M15 | SMC, none stated |
- **Symbol choice:** the stated symbol and timeframe where the page gives one; otherwise EURUSD H1 (the convention of earlier screens), or M5 / M15 for
  EAs described as scalpers or intraday systems.
- **Multiple testing:** 49 cells. At a 5% false-pass rate per stage, two or three cells could pass the screen by chance; the later stages are the filter.

## Gates (the existing framework, with the joined Gate A of 2026-10-26)
1. **Screen, 2024-01-01..2026-10-01:** reject if trades < 40, PF < 1.00, net <= 0 or a stop-out.
2. **Gate A:** a 2022-01-01..2024-01-01 run joined with the screen run: trades >= 150 and PF >= 1.00 over both, net > 0 in 2022-24 and in 2025-26.
   **Continuous 2022-26 run instead** for the stateful cells: cb23628 (hedge pair), cb39425 / cb39591 (position stacking), cb39582 (stop-less
   averaging), cb78411 (a basket).
3. **Out of sample, 2019-01-01..2022-01-01:** net > 0, PF >= 1.05, t >= 1.65; inconclusive if history quality < 90%.
4. **Sizing:** k = 8 / max DD %, and the scaled return must be >= +10% a year in both 2022-24 and 2025-26.
- **Portfolio fit for any candidate:** symbol overlap with the live set (gold x4 on H1-H6, USDJPY H4, GBPJPY Monday, NI225) and a joint run.

## Expectation (written before the runs)
- **Most reject at the screen,** like the 46 public EAs screened earlier this week (one passed every edge check, and it failed sizing).
- **Daily index rules (73674, 73884, 74137)** will fall short of the 150-trade floor even if profitable, as Turnaround Tuesday did.
- **Most likely outcome:** zero candidates; at most one or two cells reaching the out-of-sample stage.

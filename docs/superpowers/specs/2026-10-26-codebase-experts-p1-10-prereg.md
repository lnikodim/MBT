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


## Outcome (2026-10-26; log `reports/oct25/cb.log`, `cb2.log`): 0 candidates in 50 runs
Screen = 2024-01..2026-10, real ticks, 10,000 USD, 1:100, source defaults, one symbol each. Net USD is at each EA's own default sizing.

**Funnel:** 399 listed, 42 tested before, about 130 tools, 77 sources read, 28 rejected at inspection, 49 cells run.
| step | cells |
|---|---|
| 0 trades (defect, clock or a switch that is off) | 14 |
| fewer than 40 trades | 3 |
| PF below 1 or net below zero | 25 |
| **passed the screen** | **7** |
| failed Gate A (2022-23 run joined with the screen) | 4: ICE, AAPL ORB, SessionReopen, MeanReversionTrend |
| passed Gate A, failed 2019-21 | 3: Williams %R direction index, Market Miner, MACrossoverEA |
| **passed every step** | **0** |

| code | EA | symbol, tf | screen net USD | PF | max DD | trades | outcome |
|---|---|---|---|---|---|---|---|
| 23628 | Back kick | USDJPY H1 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 trades, cause not traced (hedge-pair EA)) |
| 35556 | williams percent direction index | EURUSD H1 | +16.28 | 1.07 | 0.5% | 244 | **passed the screen**; Gate A PASS (joined: +77.35 USD, 412 trades, PF 1.18, 22-24 +33, 25-26 +44, DD 0.5%); 2019-21 FAIL |
| 35588 | AO n Stochastic | EURUSD H1 | -84.28 | 0.85 | 1.1% | 328 | rejected |
| 38897 | RSI_MAonRSI_Dual_EA | EURUSD H1 | -1,891.57 | 0.81 | 21.4% | 1127 | rejected |
| 39012 | PriceChannel_Signal_v2 EA | EURUSD H1 | -2,571.51 | 0.79 | 26.8% | 2928 | rejected |
| 39334 | DeMarker Pending | EURUSD H1 | -3,992.78 | 0.90 | 49.0% | 6368 | rejected |
| 39425 | DeMarker Pending 2 | EURUSD H1 | -906.68 | 0.94 | 16.4% | 1790 | rejected |
| 39582 | AMA Trader 2 | EURUSD M5 | -1,186.53 | 0.84 | 12.4% | 823 | rejected |
| 39591 | DeMarker Pending 2_5 | EURUSD H1 | -992.42 | 0.93 | 17.0% | 1803 | rejected |
| 39703 | iVIDyA Simple | EURUSD H1 | -68.08 | 0.94 | 0.9% | 1507 | rejected |
| 41739 | RSI Bot MT5 | EURUSD H1 | +6.35 | 1.56 | 0.1% | 14 | rejected (14 trades: RSI 20/80 thresholds almost never fire) |
| 42283 | CCI + MACD Scalper | EURUSD M15 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 trades: lot formula asks for 13.5 lots at 2% risk; every order refused) |
| 43252 | Reversal Strategy | EURUSD M5 | -846.90 | 0.61 | 10.6% | 65 | rejected |
| 43278 | Aussie Surfer | GBPAUD M15 | -8,232.64 | 0.04 | 82.3% | 200 | rejected |
| 44883 | AK-47 Scalper EA | EURUSD M5 | -9,966.31 | 0.61 | 99.7% | 22145 | rejected (22,145 trades) |
| 49770 | Probability Theory Expert Advisor  | EURUSD H1 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 trades: master switch `EnableCheckBars` is off by default (see the rerun)) |
| 52105 | QuickTrend Scalper | EURUSD M1 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 orders despite 132,735 signals; reads an RSI handle as a value) |
| 52152 | AdaptiveTrader Pro EA | EURUSD H1 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 trades, cause not traced (runs its own 'optimization', cuts risk with no trades)) |
| 53526 | SUPERMACBOT | EURUSD H1 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 trades, cause not traced) |
| 54127 | MarketPredictor | EURUSD H1 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 trades, cause not traced) |
| 54612 | BollingerBandsEA | EURUSD H1 | -305.49 | 0.75 | 7.4% | 88 | rejected |
| 57020 | MeanReversionTrendEA | EURUSD H1 | +9.61 | 1.00 | 10.4% | 308 | **passed the screen**; Gate A FAIL (joined: -400.86 USD, 661 trades, PF 0.98, 22-24 -301, 25-26 -100, DD 15.2%) |
| 58135 | Indiana Jones Mean Reversion EA | EURUSD H1 | -364.36 | 0.94 | 11.2% | 108 | rejected |
| 58361 | ICT_conceptsEA by Emil | EURUSD M5 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 trades, cause not traced (10:00-11:00 killzone)) |
| 60347 | Tuyul GAP | EURUSD H1 | -887.86 | 0.21 | 22.1% | 47 | rejected |
| 61998 | Popular MACD Strategy from Viral Y | EURUSD H1 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 trades: its bundled SupportResistance indicator does not compile) |
| 62742 | Multi_Divergence_EA | EURUSD H1 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 trades, cause not traced) |
| 68125 | The Playground Series v1 to V4 - A | EURUSD H1 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 trades: every FVG fell outside its Silver Bullet clock window) |
| 68512 | TrendMomentumEA | EURUSD H1 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 trades: buys need close above both EMAs and RSI 10-25, which never co-occur) |
| 68951 | Liquidity Sweep H4 - M15 (Swing Hi | EURUSD M15 | -22.33 | 0.44 | 0.3% | 54 | rejected |
| 69651 | ICE (Impulse Confirmation Engine) | XAUUSD H1 | +25.51 | 1.08 | 0.9% | 86 | **passed the screen**; Gate A FAIL (joined: -101.95 USD, 167 trades, PF 0.84, 22-24 -128, 25-26 +26, DD 1.9%) |
| 70052 | ExMachina SafeScalping | XAUUSD M15 | -132.96 | 0.63 | 1.5% | 369 | rejected |
| 70916 | Pro MA Crossover EA for MT5 | EURUSD H4 | +316.33 | 1.23 | 11.1% | 17 | rejected (17 trades) |
| 73674 | 001 - Turnaround Tuesday | SP500 D1 | -254.66 | 0.98 | 23.2% | 143 | rejected |
| 73884 | 002 - Inside Bar | SP500 D1 | +475.59 | 6.00 | 1.9% | 1 | rejected (1 trade: its inside-bar filters almost never match on D1) |
| 74135 | Simple EMA Cross EA with SL/TP and | XAUUSD H1 | -4,648.74 | 0.72 | 50.6% | 706 | rejected |
| 74137 | 003 - Weekly Day Reversal | SP500 D1 | -254.66 | 0.98 | 23.2% | 143 | rejected (identical to 73674 at the defaults (Monday, reversed)) |
| 74379 | SteepMA Steep Moving Average Trend | EURUSD H1 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 trades, cause not traced; default risk 70% per trade) |
| 74815 | MA + Envelope Breakouts | EURUSD H1 | -6,458.05 | 0.54 | 75.2% | 3051 | rejected (208 stop-out events) |
| 74818 | Market Miner | EURUSD H1 | +4,409.00 | 2.37 | 28.4% | 2901 | **passed the screen**; Gate A PASS (joined: +6,711.31 USD, 4824 trades, PF 1.94, 22-24 +3,319, 25-26 +3,393, DD 28.4%); 2019-21 FAIL |
| 74894 | SuperTrend_Amarnath_Kondiyan_Mohan | EURUSD H4 | -6,529.32 | 0.63 | 74.6% | 2243 | rejected (192 stop-out events) |
| 75002 | Aegis Quantum Lite | XAUUSD M5 | +0.00 | 0.00 | 0.0% | 0 | rejected (0 trades: silently blocks every order (reason only on an on-chart box)) |
| 75586 | GoldLondonBreakout | XAUUSD M15 | -489.15 | 0.99 | 32.2% | 494 | rejected |
| 76333 | AAPL cfd - ORB strategy | AAPL M5 | +1,186.10 | 1.08 | 8.3% | 842 | **passed the screen**; Gate A FAIL (joined: -418.41 USD, 1475 trades, PF 0.98, 22-24 -987, 25-26 +569, DD 23.1%) |
| 77060 | SessionReopenEA | XAUUSD H1 | +528.15 | 1.42 | 1.4% | 490 | **passed the screen**; Gate A FAIL (joined: +493.88 USD, 901 trades, PF 1.30, 22-24 -16, 25-26 +510, DD 1.4%) |
| 77180 | EMA Cross Scalper M15 (XAUUSD, WIB | XAUUSD M15 | -229.01 | 0.32 | 2.3% | 404 | rejected |
| 77414 | MACrossoverEA | EURUSD H1 | +28.79 | 1.04 | 0.7% | 384 | **passed the screen**; Gate A PASS (joined: +95.12 USD, 765 trades, PF 1.06, 22-24 +63, 25-26 +32, DD 0.8%); 2019-21 FAIL |
| 78411 | USDX Trader EA - Trade the US Doll | EURUSD H1 | -3,073.65 | 0.93 | 45.2% | 3450 | rejected |
| 78454 | Smart Money Concept Expert Advisor | EURUSD M15 | -833.63 | 0.73 | 11.5% | 126 | rejected |

**The extra cell (cb49770s, Probability Theory EA with `EnableCheckBars` on, pre-announced):** 1 trade, -412.00 USD. Rejected.

**The seven that passed the screen**
- **SessionReopenEA (77060), XAUUSD H1** (gold's post-maintenance reopen at 01:00 server time = 18:00 New York, 2-hour hold, fixed 0.01 lot): screen +528.15 USD,
  PF 1.42, DD 1.4%, 490 trades, +11.5 R (t +1.50). Gate A: 2022-23 run -34.27 USD, joined **+493.88 USD, 901 trades, PF 1.30**, but **2022-24 only -16 USD**
  (2025-26 +510). The closest miss: a regime effect that appeared in 2025-26.
- **Market Miner (74818), EURUSD H1:** a no-stop basket on Williams %R at 0.01 lot legs. Screen +4,409.00 USD (PF 2.37, DD 28.4%); Gate A +6,711.31 USD (PF 1.94);
  **2019-21 -4,499.59 USD, PF 0.58, DD 63%, 278 stop-out events, 2021 -8,342.** The AMA-Trader failure shape.
- **Williams %R direction index (35556):** +77.35 USD joined (PF 1.18, DD 0.5%), then 2019-21 -81.82 USD, PF 0.76, every year negative.
- **MACrossoverEA (77414):** +95.12 USD joined (PF 1.06, DD 0.8%), then 2019-21 -17.39 USD, PF 0.98.
- **ICE (69651), AAPL ORB (76333), MeanReversionTrend (57020):** failed Gate A (-101.95, -418.41 and -400.86 USD joined).
- **Sizing step:** none reached it. For reference, scaling Williams %R and MACrossoverEA to an 8% drawdown gives about +2% a year.

**Findings**
- **Defects dominate the defaults of free Code Base EAs:** 14 of 49 never traded, and 4 more traded fewer than 40 times. Most traces: a broken lot formula, a contradictory entry rule, a
  switch that is off, a bundled indicator that does not compile, a clock window that no Darwinex gap ever falls into.
- **Stop-less and stacking EAs fail loudly:** SuperTrend (192 stop-outs), MA + Envelope (208), AK-47 (22,145 trades), Market Miner (278 stop-outs in 2019-21).
- **Good screens do not carry back:** every one of the 7 passes lost money in a later step or sat at about zero.
- **The joined Gate A (a 2022-23 run reusing the 2024-26 screen):** worked as designed; it caught four EAs in about two years of test time each.
- **Expectation check:** expected most to reject and zero or one candidate. Got zero. Four of 49 EAs defaulted to risks of 2% to 70% of the account per trade or an unusable lot size.
- **Removed** per the leftovers rule: the 49 `mql5/CB*_EA.mq5` sources (in git at a01c983), their profiles and `.set` files, the bundled indicators and includes installed in
  MT5, and the compiled `.ex5` and compile logs.

# bmtrading.de free EAs: screen on compiled defaults (pre-registration)

Date: 2026-10-25. User: "i found this EAs but without the source code, so we can at least test them out
https://bmtrading.de/en/expert-advisors/". Server: Darwinex-Demo.

## The EAs
The site offers six free MT5 EAs as `.ex5` files (`[IC] <name> EA.zip`, each with an inputs PDF), for "unlimited" Strategy
Tester use. The author states: "I do not recommend specific inputs. The defaults are not necessarily optimal."
| EA | what the page says | stated markets, timeframes |
|---|---|---|
| Range Breakout | a morning range between two times, then pending orders both ways | forex, indices; M5-H1 |
| Go Long | long-only, opens at a set time (optionally on a new day high) | index CFDs; D1 |
| Turnaround Tuesday | buys on a set weekday and closes on another (default Monday to Tuesday) | index CFDs; D1 |
| Ninja Turtle Scalper | Donchian breakout scalping | forex majors; M1-M15 |
| The Fisherman | counter-trend retracements inside a trend | forex, indices; M15-H4 |
| ATR Candle Breakout | an unusually large candle closing near its extreme | forex, indices, gold; H1-H4 |

## Safety (no source, so a binary check only)
- A scan of all six `.ex5` files for DLL, WebRequest, socket, licence, expiry and account strings found **only the author's
  website address** in each (ASCII and UTF-16).
- This is evidence, not proof, because a compiled file can hide strings. The tester also blocks web requests.
- **They run in the tester only.** Nothing here approves attaching them to a live account.
- MD5 of each file (first 8): Range Breakout 24a7b151, Go Long af3ee163, Turnaround Tuesday a36a0dc8, Ninja Turtle
  0e0b895c, Fisherman 5ade2a7d, ATR Candle bffb5d0b.

## What can and cannot be done without source
- The PDFs describe inputs by label, not by MQL name, so **no input can be overridden**. Every cell runs on the
  **compiled defaults**, and the real defaults are read from each tester report's parameters.
- The files were renamed to `BM_<Name>_EA.ex5` (a space in an EA name breaks the tester); the content is unchanged.
- The trade logic cannot be checked or fixed. A zero-trade or odd result is diagnosed from the tester journal only.

## Screen cells (real ticks, 10,000 USD, 1:100, compiled defaults)
| cell | EA | symbol, timeframe |
|---|---|---|
| rb_E, rb_G | BM_RangeBreakout_EA | EURUSD M15; GDAXI M15 |
| gl_W, gl_S, gl_G | BM_GoLong_EA | WS30 D1; SP500 D1; GDAXI D1 |
| tt_S, tt_W, tt_G | BM_TurnaroundTuesday_EA | SP500 D1; WS30 D1; GDAXI D1 |
| nt_E | BM_NinjaTurtle_EA | EURUSD M15 |
| fi_E, fi_S | BM_Fisherman_EA | EURUSD H1; SP500 H1 |
| atr_X, atr_E, atr_W | BM_ATRCandle_EA | XAUUSD H1; EURUSD H1; WS30 H1 |
- **Multiple testing:** 14 cells. Symbols are the ones in your live portfolio or its gaps; timeframes are inside each stated range.
- **Long-only index EAs (Go Long, Turnaround Tuesday):** the report also shows the symbol's own move over the traded span
  (buy-and-hold in points), because rising indices make any long-only rule look good.

## Runs and gates (same as the mql5 screen)
1. **Screen, 2024-01-01..2026-10-01:** reject if tester trades < 40, PF < 1.00, net <= 0 or a stop-out.
2. **S0, 2022-01-01..2026-10-01**, survivors only: trades >= 150, PF >= 1.00, net > 0 in both 2022-24 and 2025-26.
3. **S1, 2019-01-01..2022-01-01**, survivors only: net > 0, PF >= 1.05, t >= 1.65 (inconclusive if history quality < 90%).
4. **Candidate** = all pass, and the long-only index EAs must also beat buy-and-hold on risk-adjusted terms (return per
   unit of drawdown), judged in the outcome.

## Expectation (written before the runs)
- **Mostly rejects.** Free promotional EAs run on defaults the author calls non-optimal.
- **Go Long and Turnaround Tuesday on indices** will show profit in 2024-26 because indices rose; the question is 2022
  (a down year) and 2019-21, and whether they beat holding the index.
- **Most likely outcome:** zero or one candidate, probably an index EA, and its edge mostly the index drift.

## Outcome (2026-10-25; log `reports/oct25/bm.log`): all six EAs closed, no candidate
Compiled defaults, real ticks, 10,000 USD, 1:100. Screen = 2024-01..2026-10. Yearly figures are from the report's deals table
(an early parser mispaired overlapping positions; the runner was fixed before the cells after Ninja Turtle's S0, and the
affected figures were recomputed).

| EA, cell | screen (net USD, PF, DD, trades) | 2022-26 | verdict |
|---|---|---|---|
| Range Breakout, EURUSD M15 | -808.09, 0.92, 12.1%, 1,057 (0.10 lot); 2024 -414, 2025 -449, 2026 +55 | not run | rejected |
| Range Breakout, GDAXI M15 | -1,367.26, 0.98, 39.9%, 1,148 (up to 0.14 lot); 2024 **+2,642**, 2025 -2,326, 2026 -1,684 | not run | rejected |
| Go Long, WS30 D1 | +2,799.02, 1.12, 14.8%, 711 (up to 0.26 lot); 91% of buy-and-hold | +1,603.49, PF 1.04, DD 24.4%, 1,227; 22 **-1,261**, 22-24 -239; 65% of buy-and-hold | **Gate A fails** |
| Go Long, SP500 D1 | +4,329.01, 1.18, 14.5%, 711 (up to 0.20 lot); 79% of buy-and-hold | +2,566.61, PF 1.06, DD 26.1%, 1,226 (history 74%); 22 **-1,875**, 22-24 -77; 64% | **Gate A fails** |
| Go Long, GDAXI D1 | -310.90, 0.86, 9.8%, 56 trades | not run | rejected; 642 buy orders refused "market closed" (an entry hour outside DAX trading) |
| Turnaround Tuesday, SP500 D1 | +1,650.00, 1.89, 8.6%, 45 (up to 0.20 lot); 46% of buy-and-hold | +2,395.75, PF 1.48, DD 13.5%, **96 trades**; 22 +103, 23 +533, 24 +138, 25 +385, 26 +1,400 | **Gate A fails on trade count** only |
| Turnaround Tuesday, WS30 D1 | +1,967.72, 2.21, 7.6%, 47 (up to 0.26 lot); 73% of buy-and-hold | +2,025.80, PF 1.43, DD 13.6%, **101 trades**; 22 +8, 23 +32, 24 +70, 25 +891, 26 +1,170 | **Gate A fails on trade count** |
| Turnaround Tuesday, GDAXI D1 | +1,229.78, 12.35, 3.6%, **10 trades** | not run | rejected on count (cause not checked) |
| Ninja Turtle, EURUSD M15 | +1,292.12, 1.05, 15.1%, 976 (0.10 lot); 24 +2,051, 25 -1,119, 26 +360 | +1,174.00, PF 1.03, DD 19.8%, 1,663; 22 -1,398, 23 +1,214, 24 +2,117, 25 -1,119, 26 +360; **22-24 +1,933, 25-26 -759** | **Gate A fails** (the runner first printed PASS from a mispaired parse); an information-only 2019-21 run lost -1,906.13, PF 0.93, DD 31.3% |
| Fisherman, EURUSD H1 | +141.66, 1.14, 3.1%, 96 (0.10 lot); 24 +133, 25 +204, 26 -196 | +223.18, PF 1.08, DD 3.1%, 227; 22-24 +215, 25-26 +8 | Gate A passes (tiny); **2019-21: -33.00, PF 0.97, t -0.11, fails** |
| Fisherman, SP500 H1 | -248.07, 0.91, 5.1%, 232 | not run | rejected |
| ATR Candle, XAUUSD H1 | +3,565.43, 1.15, 27.8%, 330 (0.10 lot); 24 +1,066, 25 +264, 26 +2,236 | +8,219.07, PF 1.17, DD 39.7%, 640; 22 -193, 23 +4,846, 24 +1,066, 25 +264, 26 +2,236 | Gate A passes; **2019-21: +3,041.05, PF 1.09, DD 24.7%, t +0.72, fails** (19 +1,059, 20 +3,654, 21 -1,672) |
| ATR Candle, EURUSD H1 | -4,567.53, 0.85, 68.1%, 356 (up to 0.19 lot) | not run | rejected |
| ATR Candle, WS30 H1 | -7,117.64, 0.87, 87.7%, 651 (up to 0.54 lot) | not run | rejected |

- **Nothing passes every gate.** The three nearest cases:
  - **Turnaround Tuesday (SP500, WS30):** positive in every year of 2022-26 on SP500, at a 13.5% drawdown, but only 96 and 101
    trades (150 required). A once-a-week rule cannot reach that count in 4.75 years, so the floor is a real limit of the
    gate here. It took 46-73% of buy-and-hold in 2024-26 (49% and 62% in 2022-26).
  - **ATR Candle (XAUUSD):** profitable in six of eight years (about +11,260 USD over 2019-26), but a 25-40% drawdown, 59% of
    the 2022-26 profit in 2023 and t +0.72 in 2019-21. Scaled to an 8% drawdown it is about +3% a year.
  - **Fisherman (EURUSD):** a 3% drawdown, but +223 USD in 4.75 years and break-even in 2019-21.
- **Go Long:** long-only index drift that took 64-91% of buy-and-hold and lost in 2022.
- **Range Breakout, Ninja Turtle:** no stable edge.
- **GDAXI cells (Go Long, Turnaround Tuesday):** too few trades. For Go Long the journal shows refused "market closed"
  orders; the entry hour cannot be changed without the input names.
- **Expectation check:** expected zero or one candidate, probably an index EA with mostly index drift. Got zero, and the
  index EAs did capture only part of the drift.
- **Removed** per the leftovers rule: the six `BM_*_EA.ex5` copies, their profiles and `.set` files. The original zips
  (including inputs PDFs) are still on bmtrading.de.

## Amendment 1 (2026-10-26, written before the runs): trade floor of 80 for weekly rules; Turnaround Tuesday continues
User: "yes, lower the floor to 80 for weekly rules".
- **The rule:** for an EA that opens at most one position a week, Gate A needs >= 80 trades over 2022-26 instead of 150. All other gates are unchanged.
- **Which cells it affects:** only `tt_S` (SP500 D1) and `tt_W` (WS30 D1), the two Turnaround Tuesday cells that failed Gate A on trade count alone:
  96 and 101 trades, each positive in 2022-24 and in 2025-26 (SP500 +774 / +1,785 USD, WS30 +110 / +2,061 USD, PF 1.48 / 1.43).
  Under the 80-trade floor both pass Gate A on the existing runs. `gl_*` (Go Long) and the other cells failed on results, not on count.
- **Next step:** the 2019-21 out-of-sample run on `tt_S` and `tt_W` with the compiled defaults (`BM_TurnaroundTuesday_EA` restored from the
  downloaded file, md5 a36a0dc8): net > 0, PF >= 1.05, t >= 1.65. If history quality is below 90% it is inconclusive. The SP500 2019-21
  history was 0% real ticks in the earlier ORB test, so I expect SP500 to be inconclusive on data and WS30 to be the clean test.
- **If both stages pass:** the sizing step (k = 8 / max DD %, scaled return >= +10% a year in both regimes), then a joint run with the live set.
- **Expectation (before the run):** the same author's Go Long rule lost in 2022 on both indices and trailed buy-and-hold, and the Turnaround Tuesday
  rule took only 46-62% of the index's move in 2022-26. About 40 weekly trades in three years make t >= 1.65 hard to reach, so the most likely
  outcome is failure of the out-of-sample check, not the sizing step.

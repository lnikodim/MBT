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

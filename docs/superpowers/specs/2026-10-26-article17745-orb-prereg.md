# mql5.com article 17745, "Decoding Opening Range Breakout Intraday Trading Strategies": the three EAs on Darwinex US indices (pre-registration, 2026-10-26)

**Request:** "let's test these EAs https://www.mql5.com/en/articles/17745" and "create a nice summary when all tests complete". Author Zhuo Kai Chen (16 April 2025); the code is `ORB.zip` (ORB1/ORB2/ORB3.mq5, md5 98116afe…, 5d0b47a9…, 175364a5…).
Safety scan: no DLL, WebRequest, file or network calls. All three compile with 0 errors and 0 warnings.

## The three strategies (adapted by the author from Concretum Group papers; traded on USTEC, 2020-01..2025-01, risk set for about 20% drawdown)
| | ORB1 opening candle direction | ORB2 VWAP trend following | ORB3 Concretum bands breakout |
|---|---|---|---|
| Chart | M5 | M15 | M1 |
| Entry | at the first 5-minute candle's close: buy if it is bullish and closes above the SMA(350), sell if bearish and below | VWAP (from the session open) cross, with the SMA(300) as a regime filter; re-entry on every new cross | a bar crosses the upper or lower noise band (sigma from the last 14 days) in the SMA(400) direction |
| Stop / exit | stop 1% of price; flat 5 min before the close | stop 0.8%; VWAP as a trailing exit; flat before the close | stop 1%; VWAP trailing exit; flat 5 min before the close |
| Risk | 2% of balance | 2% | **4%** |
| Article's claim | PF 1.23, Sharpe 2.81, max DD 18%, about 1 trade a day, alpha 1.6 | PF 1.26, Sharpe 3.57, max DD 16% (>1 trade a day, win rate 42%) | PF 1.30, Sharpe 5.9, drawdowns more frequent (win rate under 50%) |
The article's figures are unverified claims on a broker and hours of the author's choice.

## What the source says (read before any run)
- **Clock:** the EAs use server-time inputs. The article says its broker is UTC+2/3 and the US session is 18:30-24:00 server time, which does not match UTC+2/3 (the open would be 16:30). Darwinex is **New York + 7 h year round**: open **16:30**, cash close **23:00**.
  Adaptation, the only input change: start 16:35 (the bar after the first five minutes), end 22:55 (ORB1, ORB3) and 22:45 (ORB2), everything else the source default.
- **ORB1** gates on exact time (`hour == start && minute == start`): faithful, nothing to fix.
- **ORB2 and ORB3 have a time-gate bug:** `MarketOpened()` is `hour >= startHour && minute >= startMinute`, true only in minutes 35-59 of each hour; `MarketClosed()` is `hour >= endHour && minute >= endMinute`, true only in minutes 45-59 (ORB2) or 55-59 (ORB3) of the hours from the end hour on.
  So ORB2 on M15 acts only on the xx:45 bar, and ORB3 trades only in minutes 35-59 of an hour. With Darwinex hours ORB3 can also enter at 23:35-23:54, after the cash close. The article's backtests were run on this code.
- **ORB3 hard-codes 09:30 as the session open** in the band maths (`getBarShiftForTime(..., 9, 30)`): that is 09:30 *server* time, not the US open (its VWAP session start uses `minute == 30` and the input hour, so the two disagree).
- **Lots:** from `SYMBOL_TRADE_TICK_VALUE`, 2% (4% for ORB3) of the balance over a stop of 1% (0.8%) of price: large notional, but margin on Darwinex indices at 1:100 should hold.

## Builds and cells (Darwinex-Demo, real ticks, 10,000 USD, 1:100)
Five builds: **ORB1, ORB2, ORB3 as published** (clock inputs only) and **ORB2F, ORB3F** with the minimal fixes (time-of-day gates: open from 16:35, closed from the end time; in ORB3F the 09:30 reference becomes the session open 16:30).
Symbols: **NDX** (the article's USTEC; tick history since 2019), **SP500**, **WS30**: 15 cells. The strategies are rules for the US cash session, so no forex or metals.
Steps as in docs/gates.md (add-on bar, the portfolio goal): Gate A 2024-01..2026-10 (trades >= 40, PF >= 1.0, net > 0, no stop-out), Gate B 2022-01..2023-12 joined with A (trades >= 150, PF >= 1.0, net > 0 in 2022-24 and 2025-26),
Gate C 2019-01..2021-12 (net > 0, PF >= 1.0, inconclusive below 90% real ticks; SP500 has real ticks only from 2023-03, so its Gate C and part of B are modelled). Guards: two-week log probe and early reject, flood watchdog, too-slow guard, tester logs cleared after each run.
The article tested only 2020-2025, so 2019-21 and 2022-23 are windows it never saw.

## Expectation (written before the runs)
The earlier ORB tests here (77967 on SP500 PF 1.04-1.06; the tradewithpat EA 0 of 18) found little. These three differ in having a regime filter (the MA) and a wide stop (0.8-1% of price, so costs are small in R), which is the kind of change that can lift PF to about 1.0-1.2.
I expect ORB1 on NDX to land near PF 1.0 to 1.2 in 2024-26 (gold-like bull-market drift helps a long-biased rule), and ORB2 and ORB3 to be worse than the article's numbers because of the gate bugs and the clock.
Most likely verdict: several Gate A passes, and failures in 2022-23 or 2019-21. A candidate would need all three windows.


## Outcome (2026-10-27): 15 of 15 cells run; 0 candidates (one cell clears all three windows but fails the add-on test)
User: "create a nice summary when all tests complete" (given in the chat and kept here). Darwinex-Demo, real ticks, 10,000 USD, 1:100; risk 2% (ORB1, ORB2) and 4% (ORB3) as published; net in USD.
SP500 has real ticks only from 2023-03 (history quality 38% for 2022-23, none before), so its Gate B and C are partly modelled.

| cell | Gate A 2024-26 | Gate B joined 2022-26 | Gate C 2019-21 |
|---|---|---|---|
| **NDX ORB1** (opening candle, M5) | pass: 429 trades, PF 1.03, +877, DD 21.5% | **fail**: PF 0.98, -1,158, 2022-24 -1,638, DD 36.4% | |
| **NDX ORB2** (VWAP, M15, as published) | pass: 1,083, PF 1.01, +331, DD 25.6% | pass: PF 1.12, +17,046 (2022-24 +16,167, 2025-26 +879), DD 31.8% | **fail**: -978, PF 0.98, t -0.21 |
| NDX ORB3 (bands, M1, as published) | reject: 823, PF 0.88, -3,650 | | |
| NDX ORB2F (VWAP, time gate fixed) | reject: 1,872, PF 0.96, -2,144 | | |
| **NDX ORB3F** (bands, time gate and 09:30 fixed) | pass: 1,559, PF 1.04, +3,422, DD 42.5% | pass: 2,744 trades, PF 1.02, +4,289 (2025-26 only +237), DD 42.5% | **add-on eligible**: +8,756, PF 1.09, t +0.94 |
| SP500 ORB1 | pass: 438, PF 1.02, +388 | **fail**: PF 1.00, -28, 2022-24 -639 | |
| SP500 ORB2 | reject: 1,057, PF 0.97, -1,247 | | |
| SP500 ORB3 | pass: 705, PF 1.06, +1,695, DD 13.8% | **fail**: PF 0.99, -725, 2022-24 -2,096, DD 36.4% | |
| SP500 ORB2F / ORB3F | reject: PF 0.93, -3,154 / PF 0.99, -526 | | |
| WS30 ORB1 / ORB2 / ORB3 | reject: PF 0.85, -3,165 / PF 0.91, -3,515 / PF 1.00, -79 | | |
| WS30 ORB2F / ORB3F | reject: PF 0.87, -5,238 / PF 0.96, -2,025 | | |

- **Gate A:** 5 of 15 pass (all with PF 1.01-1.06, so each is a small edge); 10 reject, the worst WS30 ORB2F (PF 0.87, DD 55.9%).
- **Add-on test, NDX ORB3F** (`reports/portfolio/addon_joint.py`, seven live EAs at 0.5% risk, candidate sized to 1% and 2% own drawdown; its own closed-trade DD at 4% risk is 48.8%, about +18% a year): +0.38 and +0.76 %/yr, but return/DD falls from 21.0 to 20.8 and 20.6 and max DD rises by 0.25 and 0.49 points; daily rho -0.04, monthly +0.06. **Rule fails (return/DD).**
- **The article's claims (PF 1.23 / 1.26 / 1.30 on USTEC 2020-2025) are not reproduced:** the best published-code cell here is NDX ORB2 at PF 1.01 in 2024-26 and PF 1.12 in 2022-26 (all of it in 2022-24), negative in 2019-21.
- **The time-gate bug matters:** fixing ORB2 turned NDX from +331 to -2,144 USD and SP500 from PF 0.97 to 0.93; the article's ORB2 results depend on acting only on minutes 35-59 of each hour. ORB3F (09:30 fixed) is the only variant better than its published form (NDX PF 1.04 against 0.88), and it deviates from the code the article tested.
- **Verdict: no candidate.** ORB3F on NDX is a diversifier (daily rho -0.04) but too weak (t +0.94, PF 1.02-1.09, 2025-26 flat) and too drawdown-heavy; closed.

## Run problems and the guards they produced (all recorded in `reports/oct25/screen_eval.py`)
- A first run over an unseen window can stall for 5-16 minutes and sometimes returns an **empty report**; the runner had scored an empty report as a result (ORB3F NDX read "Gate B PASS" on 2024-26 alone). It now treats an empty report as "no result" and retries once; the invalid lines of the first pass (ORB3F NDX B and C, ORB3 SP500 B) were re-run and replaced.
- The too-slow guard (probe over 900 s) now re-measures a stalled probe first (ORB2 on SP500: 922 s once, then normal).
- Spotlight indexing (mds at about 50% CPU on the MetaTrader folder) may add to the stalls; excluding the folder in Spotlight Privacy is a user setting.

## Leftovers removed (leftovers rule)
The five `mql5/A17745_*_EA.mq5` files (never committed), the five profile entries, the MT5 copies (sources, `.ex5`, compile logs) and tester sets, and the downloaded article files. Reports and logs stay. The two fixes, for the record:
`MarketOpened()` / `MarketClosed()` compare `hour * 60 + minute` with the start / end time of day instead of `hour >= H && minute >= M`; ORB3F replaces the four `getBarShiftForTime(..., 9, 30)` calls with `(..., startHour, startMinute - 5)`.

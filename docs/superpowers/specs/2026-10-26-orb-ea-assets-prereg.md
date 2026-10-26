# ORB_EA (five-stage opening range breakout) on forex majors, XAUUSD and XAGUSD (pre-registration, 2026-10-26)

**Request:** "let's test the ORB_EA on major forex symbols as well as on XAUUSD & XAGUSD". The EA is the user's own file (`MQL5/Experts/Advisors/ORB_EA.mq5`, "OpeningRangeBreakout.mq5": an educational implementation of the
workflow published at tradewithpat.com), copied unmodified to `mql5/ORB_EA.mq5` (sha256 starts `5eb036577625414b`; the user may still be editing the original, the test uses this copy).
It is not the older MBT `ORB_EA` (Zarattini/Barbon/Aziz base ORB, closed on 2026-10-20 and removed; in git at 099082a).

## The EA, from its source (1,890 lines; safety scan: no DLL, no WebRequest, no file or network calls; the news filter uses the built-in calendar)
Five stages: **Range** (the first 15 minutes after the session open, three M5 candles), **Wait**, **Validate** (spread, news, one filled entry per session), **Execute**, **Manage**.
Defaults used: session New York 09:30 ET with a 390-minute window, flat at the session end; entry on the **next candle closing outside the range** (`ENTRY_CONFIRM_NEXT_OPEN`);
stop beyond the breakout candle (+1 point); break-even after a close 1R beyond entry; swing trail armed at 1.5R; hard take-profit at 2R; risk **0.5% of balance per trade**; the lot follows the stop distance.
The news filter reads the MT5 calendar and is **fail-open**; the Strategy Tester has no calendar, so it never blocks in these runs (live it would skip trades around high-impact events).

## Cells (Darwinex-Demo, real ticks, 10,000 USD, 1:100, M5, source defaults except the session)
9 symbols x 2 sessions = 18 cells: EURUSD, GBPUSD, USDJPY, USDCHF, USDCAD, AUDUSD, NZDUSD, XAUUSD, XAGUSD; session **New York** (the default, `InpSession` 0) and **London** (08:00 Europe/London, `InpSession` 1).
Tokyo, the other entry and stop modes and any input tuning are not part of this study; a cell that shows promise gets its own amendment first.

## Steps (docs/gates.md; add-on bar, the portfolio goal)
A 2024-01..2026-10: trades >= 40, PF >= 1.00, net > 0, no stop-out. B 2022-01..2023-12 judged joined with A: trades >= 150, PF >= 1.00, net > 0 in 2022-24 and in 2025-26. C 2019-01..2021-12: net > 0 and PF >= 1.0, inconclusive if history is under 90% real ticks.
A survivor then gets the add-on test (`reports/portfolio/addon_joint.py`). Standard guards: two-week log probe and strip, early reject (probe >= 150 trades and PF < 0.75), too-slow guard, flood watchdog, tester logs cleared after each run.
Reported per cell: trades, net USD at the 0.5% risk, PF, drawdown, total R where the stop is known.

## Known limit: the session clock (the size of the error was wrong here; see Amendment 1)
The EA converts the session open with `TimeGMT()` and `TimeCurrent() - TimeGMT()`. In the Strategy Tester `TimeGMT()` follows the host's time zone, not the broker's (server = New York + 7 h), so for the weeks
when the US and EU daylight-saving dates differ (about five a year) the tester can place the session one hour away from the real open. Live trading uses the real GMT and is not affected.
**Check:** the open times of the trades are compared with the expected window (New York 16:45 server or later; London 10:15 or later). If more than 5% of a cell's trades fall outside, the cell is reported as
distorted by the tester clock and not read as a verdict. Fixing it would change the code (server-time inputs), which needs an amendment.

## Expectation (written before the runs)
The older base ORB on EURUSD and GBPUSD lost about its cost (0.11-0.14 R a trade): 0 of 16 cells passed Gate A, and USDJPY London was the only pass (71% drawdown at 1% risk). Expect 0-2 Gate A passes among the forex cells.
The metals are the likeliest passes at Gate A (gold rose from about 1,990 to 5,430 inside 2024-26, which flatters any long-biased trend rule, as seen with SessionReopenEA), so Gate B and C decide.
Silver (XAGUSD) has a wide spread that may cost most of an opening-range edge.

## Amendment 1 (2026-10-26, before any result was kept): tester build with a corrected clock and without per-tick UI work
User: "why is the backtest so slow?" The first run (the user's file, `ORB_EA`) showed two things:
- **The clock error is not five weeks a year, it is constant.** In the Strategy Tester `TimeGMT()` equals the server time, so the EA took the server clock for GMT and opened the New York range at **14:30 server time instead of 16:30**
  (08:00 London at 08:00 instead of 10:00). Seen in the agent log: "Range forming" at 14:30, entry at 15:00 on 2024-01-29. Every New York and London cell of that run would have tested the wrong hour, so it was stopped at 2024-01-29 and nothing of it is kept
  (its two-week XAUUSD probe, -123 USD in 5 trades, is void).
- **Slowness:** the run advanced about one simulated week in 45 s (XAUUSD, real ticks), about 100 minutes for the 2024-26 run. On every tick `OnTick` recomputed the session start (TimeGMT, date, weekday and DST maths with `StructToTime`) and
  called `Dashboard()`, which formats a nine-line string, scans positions and orders and calls `Comment()`; with `InpDrawLevels` it also redraws chart objects. Gold has well over 100,000 ticks a day, so this ran about 100 million times.

**Change:** `mql5/ORB_Tester_EA.mq5`, a copy of the user's file that stays untouched (`mql5/ORB_EA.mq5`, and the original in MT5). Differences, all inactive on a live account (the header of the file lists them; `diff` removes only the two `TimeGMT()` lines):
1. `GmtNow()` and `ServerGmtOffset()` use the Darwinex clock in the tester (New York + 7 h: GMT+2 in US winter, GMT+3 in US summer; the DST test uses a GMT guess, wrong only in the repeated hour of the autumn switch).
2. `Dashboard()` and `DrawLevels()` return at once in a non-visual tester run.
3. The session start is cached per server hour in that run (it cannot change inside an hour: the New York, London and Tokyo day and DST boundaries fall on whole hours).

**Checks:** (a) XAUUSD New York, 2024-01-01..15: 8 trades, entries between 16:55 and 17:10 server time, i.e. after the 16:30-16:45 range as intended; the same 8 trades, times and net (-0.33 USD, PF 1.00) with and without the hour cache.
(b) The two-week probe took 65 s with the original and 14 s with the tester build (16 s before the cache; most of that is tester start-up). Expected: a few minutes per 2024-26 run instead of about 100.
The cells, gates and expectation above are unchanged; the runner uses `ORB_Tester_EA`.

## Outcome (2026-10-26, evening): 18 of 18 cells rejected at Gate A; closed as a dead end
User: "ok, it is a dead end, skip it". All 18 cells ran on `ORB_Tester_EA` (Amendment 1); Darwinex-Demo, real ticks (100% history), 10,000 USD, 0.5% risk, M5, 2024-01..2026-10, no stop-outs anywhere.
Net USD at 0.5% risk per trade (the stop is the break candle, so the lot varies); PF in the middle; trades about 460-530 a cell.

| symbol | New York (trades, PF, net USD) | London (trades, PF, net USD) |
|---|---|---|
| XAUUSD | 497, 0.94, -842.75 | 488, 0.73, -3,575.21 |
| XAGUSD | 477, 0.86, -1,619.79 | 482, 0.66, -3,849.50 |
| EURUSD | 493, 0.78, -3,055.99 | 505, 0.76, -3,307.63 |
| GBPUSD | 470, 0.95, -772.28 | 529, 0.73, -4,004.29 |
| USDJPY | 502, 0.74, -3,649.22 | 474, 0.60, -4,977.40 |
| USDCHF | 484, 0.78, -2,800.61 | 485, 0.79, -2,742.42 |
| USDCAD | 479, 0.80, -2,801.85 | 457, 0.55, -5,231.95 |
| AUDUSD | 481, 0.77, -2,818.17 | 466, 0.60, -4,723.85 |
| NZDUSD | 480, 0.67, -4,044.13 | 472, 0.58, -4,844.88 |

- **Verdict:** 0 of 18 pass; PF 0.55-0.95, a loss in every cell (the best are GBPUSD New York -772 USD and XAUUSD New York -843 USD, mean -0.03 R a trade on gold). New York beats London on every symbol; the expectation (0-2 forex passes, metals likeliest) was too kind.
- **Gates B and C were not run** (no cell passed A). The entry-time check passed on the tester build (entries after the range, e.g. 16:55-17:10 server on gold).
- **Cleanup (leftovers rule):** removed `mql5/ORB_EA.mq5` (the frozen copy), `ORB_Tester_EA.mq5` and `ORB_Hybrid_EA.mq5`, the three profile entries, the MT5 copies of the tester and hybrid builds with their compile logs and tester sets, and the downloaded 77967 and blog material.
  **Left alone:** the user's own `MQL5/Experts/Advisors/ORB_EA.mq5` and `.ex5` (their file; they were recompiled from an identical copy once). The reports stay in `reports/`.

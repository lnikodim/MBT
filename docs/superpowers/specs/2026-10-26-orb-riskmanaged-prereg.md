# ORB_RiskManaged_EA on Darwinex SP500 and WS30 (pre-registration)

Date: 2026-10-26. User: "skip it, test the next EA" (after the VWAP pullback study). "Next" was not named; I took the next untested EA of the
mql5.com "best" shortlist that fills a portfolio gap (a US index opening-range breakout). Server: Darwinex-Demo.

**The EA:** "ORB Risk Managed - Opening Range Breakout with Account Protection" (mql5.com code 77967, published 2026-10-03, rating 1, 1,415 views),
`ORB_RiskManaged.mq5` (MD5 a2809dcb…, 422 lines). Copied unchanged to `mql5/ORB_RiskManaged_EA.mq5`.
- **Compile:** 0 errors, 0 warnings. **Safety:** no DLL, web or file calls.
- **The author's claim:** "built and tested on a US100 / Nasdaq 100 index CFD", an "educational template", no figures.
- **What it does:**
  - **Range and orders:** it marks the high and low of the first 15 minutes from 16:30 server time (the US cash open, GMT+3 in the author's frame),
    then places a buy stop and a sell stop 20 points beyond the range (OCO). One trade a day, no trades after 18:30, everything closed at 22:45.
  - **Stop and target:** the stop distance is the range x 1.0; the target is 2R.
  - **Range filter:** it skips days whose range is under 0.05 or over 0.60 of the daily ATR(14).
  - **Sizing:** 0.5% of the balance, skipped if the minimum lot already exceeds the risk.
  - **Protection:** a daily loss limit of 3%, and a **max total drawdown of 8% that stops the EA for good** (`g_hardStop`).
- **Darwinex clock:** server time is NY + 7 hours, so 16:30 server = 09:30 New York year round (as used for HoLo here).

## Symbols
- **US100 does not exist on Darwinex-Demo.** The nearest are **SP500** and **WS30**. GDAXI and NI225 were not used: the times are a US-session rule.
- Chart timeframe M5 (the range is taken from M1 data whatever the chart).

## Cells (real ticks, 10,000 USD, 1:100)
| cell | symbol | inputs |
|---|---|---|
| orb_S_A | SP500 M5 | source defaults |
| orb_S_B | SP500 M5 | `InpMaxTotalDDPct` = 100 |
| orb_W_A | WS30 M5 | source defaults |
| orb_W_B | WS30 M5 | `InpMaxTotalDDPct` = 100 |
- **Why B:** at the default the EA **stops forever once equity is 8% under the starting balance**, so a multi-year test could end early and show only a
  truncated result. B removes that stop (100 = never reached) to measure the strategy itself. A zero would not turn it off: the code would then
  trigger at once, since `equity <= initial x (1 - 0)`.
- **Multiple testing:** 4 cells. No other input changes. Trades are one at a time, so R from the order stop is exact.

## Runs and gates
1. **Screen, 2024-01-01..2026-10-01:** reject a cell if trades < 40, PF < 1.00, net <= 0 or a stop-out. For A cells I also report the date the hard stop
   fires, if it does.
2. **S0, 2022-01-01..2026-10-01**, survivors: trades >= 150, PF >= 1.00, net > 0 in both 2022-24 and 2025-26.
3. **S1, 2019-01-01..2022-01-01**, Gate A survivors: net > 0, PF >= 1.05, t >= 1.65 (inconclusive if history < 90%).
4. **Candidate** = all pass; then k = 8 / max DD % must scale to >= +10% a year in both regimes.

## Expectation (written before the runs)
- **A cells:** the 8% permanent stop probably fires in the first or second year, so A shows a truncated life; B is the real test.
- **B cells:** a 15-minute ORB with a 2R target on a US index has a fair chance of a small positive expectancy, since it is a known pattern. The earlier
  ORB-family results here were mixed (the Crabel ORB on GDAXI, the StochDailyBreakout, Monday Dip), so I expect PF about 0.95 to 1.15.
- **Most likely verdict:** closed. The best chance is SP500 or WS30 in 2024-26, which fails the older years.

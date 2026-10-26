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

## Outcome (2026-10-26; log `reports/oct25/orb.log`): closed, no candidate
M5, 10,000 USD, 0.5% risk, one trade at a time (R exact). A = source defaults, B = `InpMaxTotalDDPct` 100 (no permanent stop).

| cell | screen 2024-01..2026-10 | 2022-26 | 2019-21 |
|---|---|---|---|
| SP500 B | +767.90 USD, PF 1.04, DD 8.5%, 691 trades, +16.3 R (t +0.52); 24 +305, 25 +456, 26 +7; max lot 0.72 | **Gate A passes:** +1,988.53, PF 1.06, DD 8.7%, 1,188 trades, +38.5 R (t +0.92); 22 +797, 23 +303, 24 +355, 25 +509, 26 +23; history quality 74% | +1,058.52, PF 1.06, DD 11.6%, 694 trades, +23.0 R (t +0.78); 19 -153, 20 -290, 21 +1,501; **0% real ticks: inconclusive** |
| SP500 A | identical to B | identical to B | identical to B |
| WS30 B | +201.42, PF 1.01, DD 9.8%, 641 trades, +6.2 R (t +0.23); 24 +153, 25 +393, 26 -345; max lot 0.81 | **Gate A fails:** -383.35, PF 0.98, DD 12.8%, 1,123 trades, -5.2 R (t -0.14); 22 +106, 23 -687, 24 +146, 25 +368, 26 -317; 22-24 -434, 25-26 +51 | not run |
| WS30 A | identical to B | -800.13, PF 0.69, DD 8.3%, **90 trades, all in 2022**: the permanent 8% stop fired in 2022 and the EA stopped | not run |

- **The hard stop:** it fires when equity is 8% below the starting balance. It never fired in SP500 A or in WS30 A over 2024-26, so A and B match there.
  On WS30 2022-26 it fired in 2022 and ended the test with 90 trades. On a live account it would switch the EA off until someone restarts it.
- **SP500 passes Gate A but the edge is small:** mean +0.03 R a trade (t +0.92 over 2022-26, +0.78 in 2019-21), so it cannot be told from zero. It is positive in
  7 of 8 years where it ran (2019 and 2020 lose slightly, 2021 +1,501 carries the 2019-21 window).
- **SP500's data is the weak point:** 74% real ticks in 2022-26 and 0% in 2019-21 (modelled from 1-minute bars). This is a property of Darwinex SP500 history.
- **WS30 has full real ticks and shows no edge** (PF 0.98 over 2022-26, break-even in 2024-26).
- **Expectation check:** expected PF 0.95 to 1.15 and a likely close. Got PF 1.04 to 1.06 on SP500, 0.98 to 1.01 on WS30, and the A cells' early stop as predicted. Closed.
- **Removed** per the leftovers rule: `mql5/ORB_RiskManaged_EA.mq5` (in git at a91dba6), its profile and the MT5 copies.

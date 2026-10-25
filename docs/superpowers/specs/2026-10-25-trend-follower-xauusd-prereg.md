# Trend_Follower_EA on Darwinex XAUUSD D1 (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/77595". Server: Darwinex-Demo.

**The EA:** "EA Trend Follower" v1.2 (mql5.com code 77595, RitzFalih, published 2026-09-22), `Trend_Follower.mq5` (MD5
5dd7a5d6…, 1,533 lines).
- **The file:** the active v1.2 is lines 1-213. Several older versions follow inside `/* … */` comment blocks and are not
  compiled.
- **Copied unchanged to:** `mql5/Trend_Follower_EA.mq5`.
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL, web or file calls.

**The author's claim** (a screenshot only):
- **The setup:** Exness, XAUUSD, deposit 100 USD, history quality 41%, 536 bars, a balance graph from 2025-01 to
  2026-09.
- **Results:** **net +1,954.57, PF 2.28, 42 trades** (21 longs, 61.9% won; 21 shorts, 42.9% won).
- **Drawdown:** equity DD 98.93%, balance DD 77.80% (of a 100 USD account).
- **The timeframe is not stated.** 536 bars over about 21 months fits D1; an H4 or lower chart would show thousands.

**What the code does** (every tick, server hours 02-22, spread <= 200 points):
- **Signal:** the forming bar's close against Parabolic SAR (0.02, 0.2) of the forming bar.
- **Below the SAR:** close the buy, open a sell. **Above:** close the sell, open a buy.
- **Always in the market.** No stop and no target (both inputs are 0 by default).
- **Size:** 0.01 lot.
- **Whipsaw risk:** the forming bar's SAR is recomputed on every tick, so a cross that reverses within the day can flip
  the position twice. Real ticks show these flips; a 41%-quality test mostly does not.

## Runs (`reports/oct24/tf_eval.py base`; Darwinex-Demo, XAUUSD D1, real ticks, 10,000 USD, 1:100, defaults)
0. **R0, the author's window:** 2025-01-01..2026-09-20. A reproduction check only, not counted.
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

- **Deposit:** 10,000, not the author's 100. On Darwinex, 0.01 lot of gold needs about 200 USD of margin, so 100 USD
  could not open a trade. The net USD at 0.01 lot does not depend on the deposit.
- **Unit:** USD per trade at the fixed 0.01 lot, since there is no stop to define R.
- **Also reported:** gold's buy-and-hold move over the same trades, in points, and holding times.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net USD > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, t of the mean USD per trade >= 1.65. If history quality is below
  90%, it is inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **R0:** more trades than the author's 42 (real-tick whipsaws) and a lower PF than 2.28. Probably still positive: gold
  rose strongly in 2025-26 and the longs carry it.
- **Trades in S0:** about 2-4 SAR flips a month on D1, so about 120-250, more with whipsaws. The 150-trade floor may
  bind.
- **S0:** longs win on gold's 2023-26 rise and shorts lose. PF about 1.0-1.4. 2022 (a range year for gold) near zero
  or negative.
- **Most likely verdict:** closed, on 2022-24 or the out-of-sample check. If it passes, the buy-and-hold comparison shows
  whether the EA adds anything beyond holding gold.

## Outcome (2026-10-25; log `reports/oct24/tf.log`): closed (out-of-sample check fails)
| run (XAUUSD D1, real ticks, 10k, 0.01 lot) | net USD | PF | max DD | trades | win | mean USD (t) | net by year | EA points vs buy-and-hold |
|---|---|---|---|---|---|---|---|---|
| R0 2025-01..2026-09 (the author's window) | **+1,938.70** | 2.43 | 11.30% | 34 | 47.1% | +57.02 (+1.70) | 25 +1,226, 26 +712 | +2,095 vs +1,754 |
| S0 2022-01..2026-10, hq 100% | **+2,238.86** | 1.77 | 11.00% | 228 | 19.3% | +9.82 (+1.75) | 22 +233, 23 +133, 24 -35, 25 +1,238, 26 +670 | +2,576 vs +2,329 |
| S1 2019-01..2022-01, hq 99% | **-258.60** | 0.81 | 6.81% | 71 | 35.2% | -3.64 (-0.67) | 19 -334, 20 -200, 21 +276 | -48 vs +547 |

- **R0 reproduced the author:** +1,938.70 against +1,954.57, PF 2.43 against 2.28, 34 trades against 42.
- **Gate A passes formally, on a thin sample:**
  - 228 trades, PF 1.77; 2022-24 +330.94, 2025-26 +1,907.92.
  - 126 of the 228 trades were sub-hour flips on **one day, 2024-06-07** (15:00-18:59 server time), when gold kept
    crossing the SAR. They cost only -49.98 USD.
  - Without that day, S0 has 102 trades, under the 150 floor.
  - The 100 trades held over a day made +2,400.67 USD after -320 of costs.
- **The out-of-sample check fails:** -258.60 USD, PF 0.81, t -0.67. Gold rose about +547 USD over the trades' span, and the
  EA's net points were -48. 2019 and 2020 lost despite gold's 2019-20 rise. Closed.
- **Read:** a stop-and-reverse that rode gold's 2023-26 trend. In S0 it took 111% of the buy-and-hold move, about the
  same as holding gold. In 2019-21 it was far behind (-48 points against +547).
- **Expectation check:**
  - R0: expected more trades than 42 and a lower PF. It had fewer trades (34) and a higher PF (2.43).
  - S0 trades: 228, inside the expected 120-250 only thanks to the one-day whipsaw burst. PF 1.77 is above the expected
    1.0-1.4.
  - 2022 was +233, not the expected near zero.
  - The verdict, closed on the out-of-sample check, matched the expectation.
- **Removed** per the leftovers rule: `mql5/Trend_Follower_EA.mq5`, its profile and the MT5 copies (the source is in git
  at 1ce58c4).

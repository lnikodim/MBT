# TardioBot_EA (triangular arbitrage) on Darwinex EURUSD / GBPUSD / EURGBP (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/62857". Server: Darwinex-Demo.

**The EA:** "TardioBot" V1.05 (mql5.com code 62857, Princethe / Lupus Materia Ltd, published 2025-08-20, page updated
2026-09-15), `TardioBot_V1_05.mq5`, 574 lines, MD5 14ed7efb….
- **Copied unchanged to:** `mql5/TardioBot_EA.mq5`.
- **Safety:** no DLL or web calls.
- **File use:** writes `ArbitrageLog.txt` to the common Files folder whenever the largest gap seen so far grows. This is
  harmless and deleted after the test.
- **Logging:** prints the lot size on every timer call (every 100 s). That is about 1M short lines over 2022-26,
  acceptable.

**The author's claim:** none in numbers. The page and the source say the EA "is not designed for live trading … for demo
and strategy testing only".

**What the code does** (timer every 100 s; default trio EURUSD, GBPUSD, EURGBP; the chart symbol does not matter):
- **Implied cross:** EURGBP = EURUSD ask / GBPUSD bid (and bid / ask).
- **Sell cycle:** when implied - EURGBP ask > the threshold + 0.0001. It closes the opposite cycle, then, with no
  positions open, sells EURUSD, buys GBPUSD and buys EURGBP. The buy cycle mirrors this.
- **Threshold:** one point + 3 x 7 points of "commission" + the three current spreads.
- **Size:** 0.002 lot per 1,000 of balance on every leg (0.2 lot on 100k). Equal lots leave about 15% unhedged GBP
  exposure.
- **Exits:** each leg is closed when older than 60 s (checked every 100 s), or on an opposite signal. No stop.
- **Limits:** at most 5 cycles a day; no new cycles while equity < 50% of balance.

## Runs (`reports/oct24/tardio_eval.py`; Darwinex-Demo, EURUSD H1 chart, real ticks for all three symbols, 100k USD, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**Unit:** there is no stop, so there is no R. A **cycle** = legs closed in the same second; its USD result is the unit.

## Checks (in USD per cycle)
- **Gate A (S0):** cycles >= 150, PF >= 1.00, net USD > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, t of the mean USD per cycle >= 1.65. If history quality is below
  90%, it is inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **Why no gaps:** Darwinex prices EURGBP in line with EURUSD / GBPUSD. A gap beyond three spreads + 0.7 pip + 1 pip
  happens only in quote glitches or at the rollover, when spreads are wide and fills poor.
- **Expected:** few cycles, likely < 150, and each one loses about 3 spreads + commission.
- **Most likely verdict:** closed (trade count or losses).

## Outcome (2026-10-24; log `reports/oct24/tardio.log`): closed (trade count)
| run (EURUSD / GBPUSD / EURGBP, real ticks, 100k, 0.2 lot a leg) | net USD | PF | max DD | cycles | per cycle | net by year |
|---|---|---|---|---|---|---|
| S0 2022-01..2026-10, hq 100% | +53.19 | 1.07 (per cycle 1.34) | 0.2% | **23** | mean +2.31 USD (t +0.47) | 22 -15, 23 +49, 24 +19, 25-26 none |

- **Gate A fails on the cycle count:** 23 against 150, and none at all in 2025-26. Closed.
- **The gaps are as expected:**
  - The implied-vs-actual EURGBP gap beat three spreads + 0.7 pip + 1 pip only 23 times in 4.75 years.
  - Each cycle made +2.31 USD on average; entry commissions were -38.59 USD in total.
  - Darwinex prices the cross in line with the majors.
- **Expectation check:** fewer than 150 cycles and no edge, as expected. The small positive total is noise (t 0.47).
- **Removed** per the leftovers rule: `mql5/TardioBot_EA.mq5`, its profile, the MT5 copies and the `ArbitrageLog.txt` it
  wrote (the source is in git at 51081e2).

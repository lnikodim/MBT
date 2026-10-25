# Jolly_Roger_EA on Darwinex EURUSD M5 (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/919". Server: Darwinex-Demo.

**The EA:** "Jolly Roger EA Version" v1.07 (mql5.com code 919, AM2, published 2012-07-19), `champion.mq5` (MD5
7d91a238…).
- **What it is:** AM2's imitation of Pirat's ATC-2011 EA, not the original.
- **Copied unchanged to:** `mql5/Jolly_Roger_EA.mq5`.
- **Compile:** 0 errors. The 8 warnings are benign. One says `ArraySetAsSeries` has no effect on the static RSI array;
  the code still reads bar 1, because the copy fills oldest first.
- **Safety:** no DLL, web or file calls.

**The author's claim:** "RSI only, M5, lots 5-15". The images are ATC-2011 results and tests over the 2008 / 2010 / 2011
championship periods. No numbers for today.

**What the code does** (every tick):
- **Entry:** with no position and no pending order, when RSI(14) of bar 1 < 30 it places **three buy-stop orders** at
  ask + stops level (sell-stops at bid - stops level when RSI > 70).
  - Stop 50 points and target 150 points (5 / 15 pips on EURUSD).
  - Volume of each = (free margin / 2000, between 0.1 and 15) / 3, so 5 lots each on 100k.
  - Order filling: FOK.
- **Pending orders:** pulled back to within 20 points of the price.
- **Trailing:** stops trail to max(entry + spread, price - 50 points) once in profit.
- **Darwinex risk:** its stops level is likely 0, so the buy-stop lands exactly at the ask, which is invalid for a stop
  order. If so, the EA rarely or never trades and prints the error every tick. A **probe** runs first.

## Runs (`reports/oct24/jr_eval.py`; Darwinex-Demo, EURUSD M5, real ticks, 100k USD, 1:100, defaults)
0. **Probe:** 2026-09, one month (`jr_eval.py probe`). It checks trading and log growth. It is not counted.
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**Trades:** legs from `deals_trades`, since three positions open together. R per leg = profit / (50 points x volume
x 1 USD).

## Checks
- **Gate A (S0):** legs >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26, no stop-out.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **Costs:** a 5-pip stop on M5 with 0.7 pip of costs is about -0.14 R a trade.
- **Exits:** the RSI extreme fade-and-follow has no known edge; the trailing to break-even plus spread cuts winners.
- **PF:** 0.70-0.95 in R, or no trades if the stop orders are invalid.
- **Most likely verdict:** closed.

## Outcome (2026-10-25; logs `reports/oct24/jr_probe.log`, `jr.log`): closed (the account was wiped out)
| run (EURUSD M5, real ticks, 100k, lots from free margin) | net USD | PF | max DD | legs | net R (t) | exits |
|---|---|---|---|---|---|---|
| Probe 2026-09, hq 100% | +1,001.88 | 1.01 | 17.37% | 444 | +4.0 (+0.10) | stop 315 at -1.18 R, target 126 at +2.96 R |
| S0 2022-01..2026-10 | **-99,899.81** (final balance 100.19) | - | - | - | not measured | - |

- **The probe:**
  - The stop orders do get filled (444 legs in the month), but the tester refused **1,289,295 orders** in that month: the
    stop-level problem flagged above.
  - Longs -69.8 R, shorts +73.8 R. The equity DD was 17.4% within the month at 5-lot legs.
  - The agent log grew by 304M characters in one month, over the 60M limit set above, so S0 ran **without reading the
    log**. Stop-outs were to be counted from the report.
- **S0:**
  - The tester finished the test in 11 min 38 s. Its log ends with "final balance 100.19 USD" from the 100,000 deposit,
    with 0.03-lot orders refused for "not enough money".
  - MT5 then **never wrote the HTML report** (about 3.1 million order tickets), and the run timed out after 4 hours.
  - The automatic retry was cut off before the end (a 0-trade report), and MT5 restarted the agent log at its start. So
    the final-balance line is the only S0 record, read from the log at 12:04 before the restart.
  - Net R, yearly figures and the date of the collapse were not measured.
- **Gate A fails** on any reading: -99.9% of the deposit. Closed.
- **Expectation check:**
  - The stop orders were not fully invalid: they filled often, while also failing about 1.3 million times a month.
  - The probe's PF of 1.01 was above the expected 0.70-0.95, but S0 lost the account. Closed, as expected.
- **Removed** per the leftovers rule: `mql5/Jolly_Roger_EA.mq5`, its profile and the MT5 copies (the source is in git at
  a7706de).

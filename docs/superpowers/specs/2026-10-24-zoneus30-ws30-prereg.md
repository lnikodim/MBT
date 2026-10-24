# ZoneUS30_EA on Darwinex WS30 M30 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/77748". Server: Darwinex-Demo, where US30 is named WS30.

**The EA:** "ZoneUS30 — Reversion and Positive Swap on Your Side in US30" v1.01 (mql5.com code 77748, Isaac Carvalho /
isaaccarv100, published 2026-09-28; the author of RSI Exhaustion, closed 2026-10-24), `ZoneUS30.mq5`, MD5 a103e682….
- **Copied unchanged to:** `mql5/ZoneUS30_EA.mq5`.
- **Safety:** no DLL, web or file calls. It prints only on init, lot adjustments and failed orders.

**The author's claim** (US30, chart 2023-01..2026-09, history quality 74%, 5,000 deposit, 5 lots):
- net +32,947.50, PF 6.04;
- 26 trades, all sells, 25 won;
- the one loss: -6,538.30;
- equity DD 85.5% (balance 46.9%).

**What the code does** (once per new M30 bar; sells only; one position):
- **Zone:** the previous day's high H +/- 0.06%.
- **A daily three-step sequence on M30 closes, then sell:**
  1. a close reaches the zone's lower edge;
  2. a close drops 0.40% below it;
  3. a close comes back into the zone.
- **Exits:** target 0.75% below the entry, stop 4.00% above. They need about an 84% win rate to break even before costs.
- **Size:** 5 lots, cut to fit 90% of free margin.
- **Swap:** the description counts on a positive short swap. The tester applies the symbol's current swap to the whole
  history, so the swap result is only indicative.

## Runs (`reports/oct24/q_eval.py zone`; Darwinex-Demo, WS30 M30, real ticks, 100k USD, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**R per trade:** from the Orders table stop (`crabel_eval.trades`). Swap and commission are reported as net minus
gross.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass. No input search.

## Expectation (written before the runs)
- **Trade count:** the author's rate is 26 trades in 3.7 years, so about 30-40 in S0. **Gate A's 150 trades cannot be
  met at this rate, so the EA closes on the trade count**. The run is made for the record.
- **Shape:** a high win rate with rare losses of about -1 R. One or two losses wipe out about 10-12 wins, and US30's
  2023-26 uptrend gives a sell-only fade few chances.
- **Most likely verdict:** closed (trade count).

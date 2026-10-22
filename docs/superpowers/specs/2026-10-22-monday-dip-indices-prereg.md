# Monday_Dip_EA on Darwinex index CFDs (pre-registration)

Date: 2026-10-22. User: "let's test another EA from your list". This was the runner-up of the 2026-10-22 Code Base
research (best list): the Crabel ORB pick was closed (spec 2026-10-22-crabel-orb-gdaxi). Server: Darwinex-Demo.

**The EA:** "Monday Dip EA - Index Mean Reversion D1" (mql5.com code 78343), `Monday_Dip_Weekly_Exit_EA.mq5` v1.02,
MD5 cbf95a6c…. It is copied unchanged to `mql5/Monday_Dip_EA.mq5` and renamed per the naming convention. It compiles
with 0 errors and 0 warnings. Long only, on D1 bars, one trade a week at most:
- **Entry:** after the Monday bar closes, if Monday's close < the previous trading day's close, and Monday's IBS
  ((close - low) / (high - low)) <= 0.25. Market buy on the first tick of the next session.
- **Exit:** after the Wednesday bar closes (or any later bar), at market.
- **Stop:** 10% below the entry. No take profit.
- **Lots:** fixed (0.10 default).
- **MA filter:** in the code it defaults to **off**; the page says on. The code is tested as written.
- **Holding:** two nights, so swap is part of the cost.

**Claims:** none. The page shows a schematic, "not backtest data". The rule is a long-public pattern (a weak Monday
close, mean reversion into midweek), not the output of an automated search, so every year tested is out of sample
relative to its origin.

**Review:** careful code.
- 24 written decisions (D1-D24); the stop is mandatory and its attachment verified.
- An entry is never caught up later, and an entry rejected by the server is retried within the same session only.
- No DLL, web or file calls.
- Volume is floored to the step and never rounded up.

**Symbols** (2-week probes on 2019-01, history quality):
- NDX 100%, WS30 100%, GDAXI 100%, UK100 100%, STOXX50E 100%.
- SP500 exists but has 0% in 2019 (no ticks), so it is excluded. WS30 and NDX cover the US.
- FCHI, J225, NDX100 and US500 do not exist.

## Runs (`reports/mondip/mondip_eval.py`; Darwinex-Demo, D1 chart, real ticks, 100k USD, 1:100, 2019-01-01..2026-10-01)
One run per symbol and configuration, 10 runs, with trades split by close date:
- **A, as written:** compiled defaults (IBS filter on, MA off, 0.10 lots, 10% stop).
- **B, rule 1 only:** `InpUseIBS` false (no IBS filter). Reported only, to show what the IBS filter adds.

**R per trade** = net / (stop distance x volume x value per point), the stop being the order's S/L, i.e. 10% of the
entry. So R = net return / 10% and is comparable across indices. Stop exits are rare.

**The unit of evidence is the week.** The indices dip together, so their trades in the same week are not independent.
A week's basket R = the mean R of the indices that traded that week. All t-statistics are on basket weeks.

## Checks (configuration A, the 5-index basket)
- **Gate A (2022-01..2026-10):** trades >= 150 (pooled), PF >= 1.00 (pooled trades), net R > 0 in both 2022-24 and
  2025-26.
- **Earlier-window check (2019-01..2022-01):** basket net > 0, PF >= 1.05 and basket-week t >= 1.65.
- **Reported:**
  - per index: trades, PF, mean R, t;
  - per configuration and window: basket weeks, mean basket R, t;
  - US (NDX, WS30) against EU (GDAXI, UK100, STOXX50E);
  - swap share of net;
  - hold lengths (expected about 2 days; over 4 days is reported);
  - stop exits, entry rejections and abandoned entries from the agent log.

## Hypothesis
Index mean reversion after a weak close is well documented (Connors-style IBS studies), and the weekday part is
weaker.
- **A:** PF 1.1-1.4 pooled, US stronger than EU.
- **2019-21:** basket t 1.0-2.0. The chance both checks pass is about 35%.
- **B (no IBS):** about twice the trades, with a lower mean R.

## Decision rule
- **Both checks pass:** a candidate. Sizing to a volatility-based risk unit (R at a 10% stop is tiny), then the
  live-set joint, are pre-registered next.
- **Otherwise:** closed, and leftovers are removed (user rule).

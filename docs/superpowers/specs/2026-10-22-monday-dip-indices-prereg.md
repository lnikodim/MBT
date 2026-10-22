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

## Outcome (2026-10-22; history quality 99% in all 10 runs; log `reports/mondip/base.log`)
**Configuration A (as written), per index, 2019-01..2026-10** (R = return / 10% stop, so +0.066 R = +0.66% per trade):
| index | trades | PF (R) | mean R (t) | R 2019-21 / 2022-26 |
|---|---|---|---|---|
| NDX | 61 | 2.33 | +0.066 (+2.53) | +0.83 / +3.17 |
| WS30 | 67 | 1.53 | +0.028 (+1.04) | +1.18 / +0.69 |
| GDAXI | 74 | 0.77 | -0.017 (-0.79) | -1.08 / -0.17 |
| UK100 | 68 | 0.84 | -0.007 (-0.54) | -0.11 / -0.39 |
| STOXX50E | 83 | 0.96 | -0.002 (-0.13) | -0.01 / -0.16 |

**Baskets** (t on basket weeks):
| | 2019-21 | 2022-26 |
|---|---|---|
| A (IBS <= 0.25) | 137 trades, PF 1.09, +0.80 R, 54 weeks, t +0.87; US PF 1.73 (51), EU PF 0.81 (86) | 216 trades, PF 1.30, +3.14 R, 100 weeks, t +1.48; US PF 2.03 (77), EU PF 0.89 (139) |
| B (no IBS) | 313 trades, PF 1.09, +1.71 R, t +0.76; US PF 1.50, EU PF 0.88 | 499 trades, PF 1.10, +2.65 R, t +0.96; US PF 1.25, EU PF 1.00 |

- **Gate A passes:** 216 trades, PF 1.30, +0.43 R in 2022-24 and +2.71 R in 2025-26.
- **The earlier-window check fails:** 2019-21 basket t +0.87 < 1.65 (net > 0 and PF 1.09 >= 1.05 pass).
- **Code checks:** every trade exited on the Wednesday time exit (no stop exits), with a 2-day median hold. There were
  0 rejected, 0 abandoned and 0 stop-attach problems, and 0-2 holds over 4 days per run (holiday weeks).
- **Costs:** spread, commission and swap are small next to the US gross edge. They exceed the EU gross P/L, which is
  near zero.

**Decision: closed** (rule: the 2019-21 check fails). On the hypothesis:
- the basket PF was 1.09-1.30, inside or near the low end of 1.1-1.4;
- US was stronger than EU, as forecast;
- the 2019-21 t was below the 1.0-2.0 forecast;
- B made more trades at a lower mean R, as forecast.

**Reported, not decided:**
- **The US indices hold it.** NDX is positive in both windows (t 2.53 over 61 trades), and WS30 is positive in both but
  not significant. The European indices are flat to negative throughout.
- **A US-only version was chosen after seeing this data,** so it is not evidence. To test it, pre-register it
  separately on a symbol this run did not use: SP500 (no Darwinex ticks before 2019, so its later years only), or US
  index data before 2019 from another broker.
- **It would be a small sleeve:** about 8 trades a year per US index. It needs volatility-based sizing (a 10% stop makes
  R tiny) before it could matter in the live set.

**Kept (user decision).** The removal was stopped. User: "keep it and test US-only on SP500". The EA, its profile and
the MT5 files stay for the follow-up pre-registered below.

## Follow-up: US-only on SP500 (pre-registered 2026-10-22, before its runs)
The US-only idea came from this run's data (NDX and WS30 positive, EU not), so this run cannot confirm it. SP500 was
not used here, so a SP500 run is out of sample for the idea. The S&P is also the index the weak-Monday literature is
about.

**Data** (2-week probes, history quality only):
- **Real ticks:** 0% in every fortnight to 2023-03-15, 25% for 2023-03-15..31, and 100% from 2023-04 (also 2023-07,
  2023-10, 2024-01, 2025-01).
- **M1-generated ticks:** 100% in 2019-01, 2021-01 and 2023-01, so SP500 M1 bars go back to at least 2019.
- **Disclosure:** the 2023-02-15..03-01 probe happened to contain 1 trade (-67.70 USD). It played no part in the
  design.

**Amendment, before any SP500 run.** Real ticks alone (2023-04..2026-10) give about 28 trades, too few to detect an
NDX-sized edge (NDX: t 2.53 on 61 trades). The window is therefore 2019-01..2026-10 in two runs:
- 2019-01-01..2023-04-01 on M1-generated ticks (`every_tick`);
- 2023-04-01..2026-10-01 on real ticks.

The trades are combined. For a D1 entry and exit at the session's first tick, generated ticks are adequate; the same
fallback was used for gold 2012-19 (spec 2026-10-21-gold-breakout) and for IC Markets 2022-25 (spec
2026-10-18-icmarkets-4ea). Each span is also reported on its own.

**Runs** (`reports/mondip/mondip_eval.py sp500`): configuration A, as written (IBS <= 0.25, MA off, 10% stop, 0.10
lots), SP500, D1, 100k, 1:100. R as above.

**Confirmation check (fixed now, on the combined 2019-01..2026-10 SP500 trades):** net R > 0, PF >= 1.05, and
per-trade mean-R t >= 1.65 (one symbol, so trades are independent).
- Gate A's 150 trades cannot apply to one index trading about 8-12 times a year, so it is not used here.
- **Reported:** trades, PF, mean R, t, by year; the US basket (NDX, WS30, SP500) over the common window, t on basket
  weeks; costs.

**Hypothesis:** SP500 behaves like WS30 and NDX, with a positive mean R. With roughly 40-60 trades the t-statistic will
be modest. The chance the check passes is about 30%.

**Decision rule:**
- **The check passes:** "US index sleeve" (NDX, WS30, SP500) becomes a candidate. Volatility-based sizing, then the
  live-set joint, are pre-registered next.
- **Otherwise:** closed, and leftovers are removed (user rule) unless the user decides otherwise.

### SP500 outcome (2026-10-22; log `reports/mondip/sp500.log`)
| SP500, configuration A | trades | PF (R) | mean R (t) | history quality |
|---|---|---|---|---|
| 2019-01..2023-04, M1-generated ticks | 40 | 2.23 | +0.062 (+1.68) | 99% |
| 2023-04..2026-10, real ticks | 21 | 1.39 | +0.014 (+0.55) | 100% |
| **combined 2019-01..2026-10** | **61** | **2.00** | **+0.045 (+1.76)** | |

- **By year (R):** 2019 +0.2, 2020 +1.4, 2021 -0.3, 2022 +1.1, 2023 -0.0, 2024 -0.1, 2025 +0.2, 2026 +0.4.
- **Execution:** all exits on the Wednesday time exit; 0 overlapping positions; 61 entries in the log.

**Confirmation check: pass** (net +2.8 R > 0, PF 2.00 >= 1.05, t 1.76 >= 1.65). **US index sleeve (NDX, WS30, SP500)
is a candidate under the rule.**
- **Reported:** the US basket over 2019-26 has 189 trades, PF 1.93, 97 weeks, mean +0.0381 R per week, t +1.88.
- **Hypothesis:** positive as forecast; the pass beat the 30% estimate.

**Limits:**
- **A narrow pass.** t is 1.76 against a 1.65 bar.
- **Most of the evidence is generated-tick years.** The real-tick span (2023-26, 21 trades) is weak on its own:
  +0.014 R, t 0.55.
- **SP500, NDX and WS30 move together.** SP500 confirms on a different symbol, not a different market.
- **A small sleeve:** about 25 basket weeks a year.

**Next, pre-registered separately before any live use:**
1. Volatility-based sizing (R at the 10% stop is about 0.45% of price per trade, which is tiny at 0.3% risk).
2. The live-set joint (gold 4-EA + DonchianTrend + Monday GBPJPY + the US sleeve).
3. An IC Markets check of the US index symbols.

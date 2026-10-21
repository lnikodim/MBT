# Stoch_Daily_Breakout_EA on XAUUSD H1 (pre-registration)

Date: 2026-10-21. User: "let's test another EA: …/Downloads/StochDailyBreakout.mq5, here are the rules:
https://www.mql5.com/en/code/77900". Server: Darwinex-Demo (user rule: always the first choice for backtests).

**The EA:** "Stochastic Daily Breakout for Gold" by Bruno Nunes Myrrha Ribeiro, v1.00, MD5 35046b38…. It is copied
unchanged to `mql5/Stoch_Daily_Breakout_EA.mq5` and renamed per the naming convention. It compiles with 0 errors and 0
warnings. Once per new H1 bar:
- **Stochastic:** a home-made one, 23/3/7 on the close-to-close range with SMMA smoothing.
- **Bollinger:** 9 periods, 2.0 deviations, weighted price.
- **Buy:** the stochastic signal line peaks at bar 2 and the open of bar 3 is below the upper band, read at bar 4. A
  buy stop goes at yesterday's D1 high.
- **Sell:** the signal line troughs at bar 2 and that open is above the lower band. A sell stop goes at yesterday's
  low.
- **Stop and target:** 1.9% of the entry price each.
- **Pending orders:** an unfilled order is cancelled after 9 bars, and a new signal on the same side replaces it.
- **Positions:** one at a time, checked only when an order is placed. Fixed 0.01 lot.

**Author's claim** (code page: XAUUSD H1, 2021-07..2026-09, 1,000 USD, 1:100, 0.01 lot):
- Real ticks for about a quarter of the period; the rest is generated from M1.
- +2,453 USD (+245%), PF 1.54, recovery factor 5.56, max equity DD 23.9%.
- 213 trades: 116 buys at 66.4% wins, 97 sells at 50.5% wins.

**How it was built:** an automated genetic search over five years of XAUUSD. The page says "this EA was found among more
than two million candidate strategies tested for its family". The robustness tests the author lists (out-of-sample
periods, Monte Carlo, walk-forward) were applied inside that search, so a good fit on the search window is close to
certain. Only data outside it can show an edge.

**Review before the run** (kept, as the file runs as written):
- **Opposite positions can coexist.** A buy stop and a sell stop can both be pending. The position check runs only at
  placement, so both can fill and leave a long and a short open. Reported as the maximum number of open positions.
- **Risk changes over time.** The stop is a % of price at a fixed lot, so the dollar risk per trade rises with gold
  (about $34 per 0.01 lot at $1,800, $76 at $4,000). R normalizes this.
- **Band and open read different bars.** The band filter reads bar 4 and the open bar 3; that is the builder's rule.
- **Expiry can change.** If the symbol does not allow GTC, orders are sent as DAY orders and expire at the session end,
  before the 9 bars. Reported as expired and cancelled order counts.
- **Failed orders are silent** (no log line), so only the tester's own failure lines are counted.

## Runs (`reports/stoch/stoch_eval.py`; Darwinex-Demo, XAUUSD H1, real ticks, 100k USD, 1:100)
The only input changed is `InpLots` = 1.0. That is the author's 0.01 lot per 1k scaled to the 100k deposit, so the
percentages compare with the claim.

**R per trade** = net (profit + commission + swap) / (entry price x 1.9% x volume x 100 oz): the planned loss of the
trade. A stop exit should be about -1 R, and this is checked.

- **S0, as written:** 2022-01-01..2026-10-01, inside the author's search window, so this is replication only.
- **S1, out of sample:** 2019-01-01..2021-07-01, before the author's window. Darwinex XAUUSD real ticks exist from
  2019-01.

## Checks and reports
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05 and mean R per trade t >= 1.65. If history quality is below 90%, S1
  is inconclusive.
- **Reported, for S0 and S1:**
  - net, PF, max equity DD, win rate, longs and shorts with their win rates;
  - R by regime, mean R and t;
  - exits (stop, target, end) with average R;
  - maximum open positions;
  - orders filled, cancelled and expired, and tester order failures;
  - history quality.
- **prop_mc alone (S0):** close_time,R file, --risk 0.3,0.5, 10k sims, seeds 1-3.
- **If Gate A passes:** the joint with the gold live set (the 4 Darwinex trade files of spec
  2026-10-21-donchiantrend-gold-joint-prereg.md), reported only.

## Hypothesis
- **S0:** about 180-200 trades, PF 1.3-1.6, Gate A passes. Buys beat sells in the 2022-26 gold rally.
- **S1:** the edge does not carry outside the search window: PF 0.85-1.15 and t under 1.65. The chance the
  out-of-sample check passes is about 15%.

## Decision rule
- **Gate A and the out-of-sample check both pass:** a candidate. A % risk sizing version and the gold live set joint
  decision are pre-registered next.
- **Gate A passes but the out-of-sample check fails:** not a candidate. The edge is the fit to the search window.
  Leftovers are removed (user rule).
- **Gate A fails:** closed, and leftovers are removed.

## Outcome (2026-10-21; agent log: "generating based on real ticks"; log `reports/stoch/base.log`)
| as written, 1.0 lot | net | PF ($) | equity DD relative | trades | win | R, mean R (t) | Gate A / out-of-sample check |
|---|---|---|---|---|---|---|---|
| S0 2022-26, hq 100% | +241,729.89 | 1.57 | 22.97% | 195 (104 L / 91 S) | 60.5% | +36.0, +0.185 (t 2.62) | **Gate A pass** (22-24 +12.4 R, 25-26 +23.7 R) |
| S1 2019-01..2021-07, hq 99% | -70,993.38 | 0.60 | 80.76% | 90 (49 L / 41 S) | 40.0% | -22.5, -0.250 (t -2.45) | **out-of-sample check fails** |

**S0 replicates the claim:** +242% against +245%, PF 1.57 against 1.54, relative DD 22.97% against 23.9%, 195 trades
against 213 (a shorter window). PF in R is 1.46, because later trades risk more dollars.
- **By side:** buys PF 1.77 (t 2.93, 67.3% wins); sells PF 1.17 (t 0.76).
- **By year:** 2023 was negative (PF 0.90); 2024-26 PF 1.63-1.90.
- **Exits:** stop 73 at -1.04 R (the R check holds), target 102 at +1.00 R, and 19 others between -0.9 and +0.9 R.
- **Code checks:** max open positions 2, so a long and a short did coexist. Orders: 390 filled, 713 cancelled, 0
  expired (GTC works). 0 tester order failures.
- **prop_mc alone,** P(pass both) at 0.3% / 0.5%: 0.0 / 1.7-2.0.
- **Gold live set joint** (reported only): gold 4-EA 93.7-94.1 / 84.2-84.7; with Stoch added, 94.5-94.7 / 84.5-85.3.
  That is +0.4-0.9 / -0.2 to +1.1 pts.

**S1 loses money, significantly so, outside the search window.**
- **By side:** sells PF 0.44 (29.3% wins); buys PF 0.73.
- **By year:** 2019 PF 0.33, 2020 PF 0.63, 2021 (to July) PF 0.86.
- **Exits:** 46 stops against 24 targets.

**Decision: not a candidate.** Gate A passes, but the out-of-sample check fails: PF 0.60 and t -2.45, worse than the
forecast PF 0.85-1.15. The 2022-26 edge is the genetic search's fit to its own window. The hypothesis held on S0 (PF
inside 1.3-1.6) and on the S1 direction; S1 was weaker than forecast.

**Removal (user rule).** Removed `mql5/Stoch_Daily_Breakout_EA.mq5`, its `scripts/ea_profiles.py` entry, and the MT5
.mq5, .ex5, compile log and tester .set (no chart had it). The file stays in git at ed60ad0.

# The_MasterMind_EA on Darwinex EURUSD M5 (pre-registration)

Date: 2026-10-23. User: "ok, let's test https://www.mql5.com/en/code/16995". Server: Darwinex-Demo.

**The EA:** "The MasterMind" v1.001 (mql5.com code 16995, 2017; idea by L.Bigger, MQL5 code by barabashkakvn),
`The_MasterMind.mq5`, 755 lines, MD5 804be107…. It is copied unchanged to `mql5/The_MasterMind_EA.mq5`, renamed per the
naming convention. No DLL or web calls. The `SendMail` alerts are off by default.

**The author's claim:** EURUSD M5 is recommended. The screenshot runs 2016-06-01..2016-11-18 on 10,000 and ends at
about 14,500 (+45% in under 6 months), with deposit load up to 50% and equity swings of 10-15%.

**What the code does:**
- **Timing:** runs on every 30th tick only, so results depend on the tick feed (real ticks are required).
- **Buy:** Stochastic(100, 3, 3, SMMA, close/close) signal line on the forming bar < 3 **and** Williams %R(100) on the
  last closed bar < -99.9 (price at its 100-bar low).
- **Sell:** signal line > 97 and %R > -0.1.
- **Position:** one at a time. The opposite signal closes it.
- **Stop / target:** 15 / 45 pips (x10 on 5-digit quotes).
- **Trailing stop:** 35 pips. The step is set from the trailing stop too (a copy bug), so the step input has no effect.
- **Size: the `Lots` input is ignored.** Hard-coded `mm = -1`, `Risk = 1` gives lots = ceil(equity / 298) / 10 - 0.1:
  33.5 lots on 100k, **about 5% of equity per trade** at the 15-pip stop, compounding.

## Runs (`reports/mastermind/mastermind_eval.py`; Darwinex-Demo, EURUSD M5, real ticks, 100k USD, 1:100, source as is)
- **S0, 2022-01-01..2026-10-01.**
- **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes Gate A.

The author's 2016 window is not replicated: real ticks don't reach 2016, and the 30th-tick sampling makes generated
ticks a different test.

**R per trade** = net / (stop distance x volume x value per point), with the first stop from the Orders table
(parser of `reports/crabel/crabel_eval.py`). R removes the 5% sizing. Net USD is reported at the source's sizing.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass. Anything else closes the EA. No input search.
- **Reported:** net USD (at about 5% risk, compounding) and net R, PF, max DD, trades, win rate, mean R (t), R by year,
  long and short split, exits, history quality.

## Expectation (written before the runs)
- **Edge:** fading a 100-bar extreme on M5 has none after costs. About 1 pip round trip is 0.07 R on a 15-pip stop.
- **PF:** 0.80-1.00 in R.
- **Net USD:** a deep loss at 5% compounding sizing.
- **Most likely verdict:** closed.

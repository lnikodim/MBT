# Bands_RSquared_EA on Darwinex EURUSD M15 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/58268". Server: Darwinex-Demo.

**The EA:** "Bands R-squared" (mql5.com code 58268, Korollkov, published 2025-05-16), `Bands.mq5`, 351 lines,
MD5 c65d2a8f….
- **Copied unchanged to:** `mql5/Bands_RSquared_EA.mq5` (renamed per the naming convention).
- **Safety:** no DLL, web or file calls. Prints only on signals and errors (once per new bar).
- **Dependency:** MT5's bundled `Indicators\Free Indicators\Donchian Channel` through `iCustom`; it is present on this
  terminal.

**The author's claim** (report in Russian):
- **Test setup:** EURUSD; 80,409 bars and 4.77M ticks (about 60 ticks a bar, so **M15 on 1-minute OHLC**); chart
  2022-01..2025-04; deposit 3,000; 0.1 lot.
- **Results:** net +930.13, PF 1.20, max equity DD 8.5%, 402 trades, 49.0% won, average win 28.05 / loss -22.42.

**What the code does** (new bar only; account `PositionsTotal() == 0`, so one position):
- **Buy:** the Donchian channel (100) has been rising over the trend period (100); the last bar opened below the lower
  Bollinger band (100, 1.0) and closed above it.
- **Sell:** the mirror image.
- **Exits:** stop and target both 4 x ATR(21), or a close outside the Donchian channel.
- **Size:** fixed 0.1 lot.

## Runs (`reports/bands/bands_eval.py`; Darwinex-Demo, EURUSD M15, real ticks, 100k USD, 1:100, source defaults)
- **S0, 2022-01-01..2026-10-01.** It contains the author's 2022-01..2025-04, so it is mostly a replication plus about
  18 months after it.
- **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**R per trade** = net / (stop distance x volume x value per point), with the stop from the Orders table (parser of
`reports/crabel/crabel_eval.py`). Net USD is reported at 0.1 lot on 100k (a small risk per trade); R does not depend on
the size.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass. No input search.
- **Reported:** net USD (0.1 lot) and net R, PF, max DD, trades, win rate, mean R (t), R by year, long and short split,
  exits.

## Expectation (written before the runs)
- **The setup:** a band re-entry fade in the direction of the channel trend, with a 1:1 stop and target and a channel
  exit.
- **Real ticks vs the author's 1-minute OHLC** usually costs about 0.05-0.10 PF.
- **PF:** 0.95-1.15 in R, about 120 trades a year.
- **Most likely verdict:** Gate A borderline; the out-of-sample check is the main risk.

## Outcome (2026-10-24; log `reports/bands/base.log`): closed
| run (EURUSD M15, real ticks, 100k, 0.1 lot) | net USD | PF | max DD | trades | win | net R (t) | R by year | exits |
|---|---|---|---|---|---|---|---|---|
| S0 2022-01..2026-10, hq 100% | +451.73 | 1.06 (R 1.01) | 0.4% | 599 | 45.7% | +1.7 (+0.08) | 22 -0.9, 23 +3.3, 24 +3.9, 25 +6.4, 26 -11.0 | stop 110 at -1.05 R, target 217 at +0.99 R, channel exit 272 at -0.36 R |

- **Gate A fails:** 2025-26 is -4.6 R (2022-24 +6.3 R). The edge is about zero (+0.003 R per trade, t 0.08). No S1.
  Closed.
- **Sides:** longs +10.5 R (PF 1.09), shorts -8.8 R (PF 0.94); neither is significant.
- **The author's PF 1.20 (1-minute OHLC, 2022-01..2025-04)** comes out as PF 1.01 in R on real ticks. That is near the
  expected 0.05-0.10 PF loss from the model change.
- **Expectation check:** PF in R 1.01, inside the expected 0.95-1.15. Trades about 126 a year, as expected.
- **Removed** per the leftovers rule: `mql5/Bands_RSquared_EA.mq5`, its profile and the MT5 copies (the source is in
  git at 4476501).

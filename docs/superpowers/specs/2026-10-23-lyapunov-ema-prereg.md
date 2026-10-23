# Chaos_Lyapunov_EA on Darwinex XAUUSD / EURUSD H1 (pre-registration)

Date: 2026-10-23. User: "https://www.mql5.com/en/code/76446 let's test it out". Server: Darwinex-Demo.

**The EA:** "Chaos Theory Lyapunov Exponent EA" v1.01 (mql5.com code 76446, jojoale, published 2026-08-24),
`lyapunov.mq5`, 278 lines, MD5 89e6ae0d…. It is copied unchanged to `mql5/Chaos_Lyapunov_EA.mq5`, renamed per the
naming convention. No DLL, web or file calls.

**The author's claim:** no symbol, timeframe or numbers. The page has one small balance chart (about 4,800 -> 5,200,
part of it one jump).

**What the code does** (once per new bar, one position at a time, magic + symbol):
- **Trend signal:** EMA 9 crosses EMA 21 on the last two closed bars. Buy on a cross up, sell on a cross down, at
  market.
- **Stop / target:** 1.5 x ATR(14) and 2.5 x ATR(14) from the last closed bar.
- **Size:** `InpRiskPercent` of balance on the stop (0.15% by default).
- **"Chaos filter":**
  - It takes the 3-point vector of raw closes 5 bars back, finds its nearest neighbour among the last 100 bars, and
    measures how far the two vectors lie apart 5 bars later.
  - LLE = ln(later distance / first distance) / 5. Trades are allowed only when LLE <= `InpLyaThreshold` (0).
  - The current-bar vector uses bar 0's close at its first tick.

**Symbols and timeframe:** none is named, so we test our two markets: **XAUUSD** (the portfolio's) and **EURUSD**, on
**H1**, fixed here and not searched.

## Runs (`reports/lyapunov/lya_eval.py`; Darwinex-Demo, H1, real ticks, 100k USD, 1:100)
Per symbol, at 1% risk (`InpRiskPercent` 1.0; R does not depend on it):
1. **S0, 2022-01-01..2026-10-01**, filter as published.
2. **C0, 2022-01-01..2026-10-01**, filter off (`InpLyaThreshold` 1000, which never blocks). This is the control: does
   the filter add anything over a plain EMA cross?
3. **S1, out of sample, 2019-01-01..2022-01-01**, filter on, only if S0 passes Gate A.

**R per trade** = net / (stop distance x volume x value per point), with the stop from the Orders table (parser of
`reports/crabel/crabel_eval.py`).

## Checks
- **Gate A (S0, per symbol):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Filter check (reported):** S0 mean R vs C0 mean R. A pass needs the filter to beat the control.
- **Candidate** = Gate A, the out-of-sample check and the filter check all pass for a symbol. Anything else closes
  the EA. No input search.
- **Reported:** net USD (at 1%) and net R, PF, max DD, trades, win rate, mean R (t), R by year, long and short split,
  exits, share of bars blocked by the filter (S0 vs C0 trade counts), history quality.

## Expectation (written before the runs)
- **EMA 9/21 on H1 with a 1.5 / 2.5 ATR stop and target:** PF 0.90-1.05.
- **The filter:** a nearest-neighbour exponent from three raw closes is mostly noise, so it acts as a random
  subsample. Mean R within about ±0.03 of the control, with fewer trades.
- **Most likely verdict:** closed.

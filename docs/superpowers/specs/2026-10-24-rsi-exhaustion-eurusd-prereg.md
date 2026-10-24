# RSI_Exhaustion_Reversal_EA on Darwinex EURUSD M5 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/77738". Server: Darwinex-Demo.

**The EA:** "RSI Exhaustion Reversal - EURUSD" v1 (mql5.com code 77738, isaaccarv100, published 2026-09-28),
`RSI_Exhaustion_Reversal.mq5`, 539 lines, MD5 d60a678a…, with `RSI_Exhaustion_Reversal_EURUSD.set` (timeframe M5,
1.0 lot, magic 26092601).
- **Copied unchanged to:** `mql5/RSI_Exhaustion_Reversal_EA.mq5` (renamed per the naming convention).
- **Safety:** no DLL, web or file calls. Prints only on trades and errors (it acts once per new bar), so there is no
  per-tick log.
- **Tester only by design:** `IsAllowedEnvironment()` = `MQL_TESTER`.

**The author's claim** (EURUSD M5, deposit 5,000, history quality 99%, 72.7M ticks, about 203,000 M5 bars ≈ 2.7
years, dates not stated):
- net +10,316.95, PF 1.60, max equity DD 22.9% (balance 19.2%);
- 178 trades, all sells, 57.3% won, average win 269 / loss -226.

**What the code does** (the "core" is constants, not inputs):
- **Entry:** on a new M5 bar. Sell when RSI(14) of the last closed bar crosses up through 65 (previous < 65,
  last >= 65).
- **Window:** the signal bar opens 14:00-17:59 server time (07:00-10:59 New York on Darwinex).
- **Spread filter:** spread <= 0.15 x ATR(14).
- **Exits:** stop and target both 4 x ATR(14) (1:1). The position closes after 96 bars (8 h) if neither is hit.
- **Size:** fixed 1.0 lot (the risk-% mode is a constant set to off). One position on the symbol.

## Runs (`reports/rsiexh/rsiexh_eval.py`; Darwinex-Demo, EURUSD M5, real ticks, 100k USD, 1:100, the author's .set)
- **S0, 2022-01-01..2026-10-01.**
- **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes. The author's window is unknown, so S1 is out of
  sample only to the extent that the author's 2.7 years lie elsewhere.

**R per trade** = net / (stop distance x volume x value per point), with the stop from the Orders table (parser of
`reports/crabel/crabel_eval.py`). R does not depend on the fixed lot. Net USD is reported at 1.0 lot on 100k (about
0.1% risk per trade).

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass. No input search.
- **Reported:** net USD (1.0 lot) and net R, PF, max DD, trades, win rate, mean R (t), R by year, exits (stop / target /
  time).

## Expectation (written before the runs)
- **The setup:** a sell-only fade of upward momentum on M5 in the London / New York overlap, at 1:1.
  - Costs are about 0.7 pip round trip on a 4-ATR stop of roughly 10-15 pips, so about 0.05-0.07 R.
  - Sell-only should struggle in up-trending periods (2025).
- **Trades:** about 60-70 a year, so about 300 in 2022-26.
- **PF:** 0.90-1.10 in R.
- **Most likely verdict:** closed; at best a weak S0 that fails the out-of-sample check.

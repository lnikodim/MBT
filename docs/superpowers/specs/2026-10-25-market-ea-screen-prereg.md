# Free mql5.com Market EAs: screen on compiled defaults (pre-registration)

Date: 2026-10-25. User: "i've installed the most high rated free EAs from the market, you can test them out". Server: Darwinex-Demo.

## The EAs (all free, no source; the `.ex5` files came from the user's terminal Market folder)
| EA (file) | author's description | stated symbol, timeframe |
|---|---|---|
| Gold Zone EA 1.10 | supply and demand zones, momentum candle, 3 take-profits, break-even and trail; no grid or averaging | XAUUSD, forex, indices, BTC; M15 / H1 / H4 |
| SuperScalp Pro Auto Trader 6.2 | Mode 1: Supertrend, EMA and RSI filters, ATR stop and target. Mode 2 needs a separate paid indicator | XAUUSD M30 (Mode 1) |
| XAUUSD 5 minute 7.3 | several mean-reversion systems, every trade has a stop, no target; only lot and risk exposed | XAUUSD M15 |
| RangeBreakout EA MT5 1.2 | time-range breakout, says no grid or martingale; a 2025 blog reported an 80% drawdown on real ticks | forex, gold; M15 |
| Supertrend G5 2.6 | Supertrend flip confirmed by two EMAs | XAUUSD M5 |
| Surfer EA 5.51, Gold Sniping 1.50, Grid Scalper MA 11.49, Diagonal Resistance 3.20 | **grids / recovery** (two with a lot multiplier); the user asked for them to be tested | XAUUSD |

## Limits (as for the bmtrading.de EAs)
- No source: no input can be overridden by name, so every cell runs on the **compiled defaults**. The logic cannot be checked or fixed.
- A Market `.ex5` is bound to the installing account and terminal. The files were **copied to space-free names**
  (`MK_<Name>_EA.ex5`) in the Advisors folder, because a space in an EA name breaks the tester. **Whether the tester
  accepts a copied Market file is unverified.** A one-month probe runs first; if the EA does not load or place orders
  at all, the cell is reported as "not runnable", not as a result.
- **Safety:** no source and no binary scan was done for these. They run in the tester only, which blocks web requests.
  Nothing here approves any of them for a live account.

## Cells (real ticks, 10,000 USD, 1:100, compiled defaults)
| cell | EA | symbol, timeframe |
|---|---|---|
| mk_gz_X, mk_gz_E, mk_gz_W | Gold Zone | XAUUSD M15; EURUSD H1; WS30 H1 |
| mk_ss | SuperScalp Pro | XAUUSD M30 |
| mk_x5 | XAUUSD 5 minute | XAUUSD M15 |
| mk_rb_E, mk_rb_X | RangeBreakout EA MT5 | EURUSD M15; XAUUSD M15 |
| mk_st | Supertrend G5 | XAUUSD M5 |
| mk_g_surf, mk_g_snip, mk_g_scal, mk_g_diag | the four grids | XAUUSD M15 |
- **Multiple testing:** 13 cells.

## Runs and gates
1. **Probe:** one month (2026-09) of Gold Zone. If it places no orders, I check the journal before anything else.
2. **Screen, 2024-01-01..2026-10-01:** reject if tester trades < 40, PF < 1.00, net <= 0 or a stop-out.
3. **S0, 2022-01-01..2026-10-01**, survivors: trades >= 150, PF >= 1.00, net > 0 in both 2022-24 and 2025-26.
   Yearly figures come from the deals table (the earlier parser mispaired overlapping positions).
4. **S1, 2019-01-01..2022-01-01**, survivors: net > 0, PF >= 1.05 (t >= 1.65 where computable; inconclusive if history < 90%).
5. **Grids** (the last four cells) also report the max drawdown, with k = 8 / max DD % and the scaled return, which must be
   >= +10% a year in both regimes, as in the grid gate used before.
6. **Candidate** = all pass.

## Expectation (written before the runs)
- **Most reject.** Free, highly rated Market EAs are marketing products; the grids will look good until they do not.
- **Possible survivors:** Gold Zone and XAUUSD 5 minute on the 2024-26 gold rally. Any gold result needs the 2022-24 half to
  pass, as gold's 2022 was a range year.
- **Most likely outcome:** zero candidates, and any gold survivor failing 2022-24 or 2019-21.

## Outcome (2026-10-25): stopped by the user, no cell completed
User: "ok, skip the rest of the free EAs".
- **Probe:** Gold Zone (XAUUSD M15, September 2026) placed 543 trades and lost -309.40 USD, PF 0.84. It shows that the tester
  accepts a Market `.ex5` copied to a space-free name in the Advisors folder. A single month is not a verdict.
- **Gold Zone, XAUUSD M15, 2024-01..2026-10:** stopped after about 1 hour 10 minutes, at August 2025 in the simulation
  (about 20 of 33 months). It was by far the slowest EA so far, because it logs on every bar (a tester log of 800 MB by then).
  **No result was produced.**
- **Not run:** the other 12 cells (Gold Zone on EURUSD and WS30, SuperScalp Pro, XAUUSD 5 minute, RangeBreakout EA MT5 on two
  symbols, Supertrend G5 and the four grids). The four grids (Surfer, Gold Sniping, Grid Scalper MA, Diagonal Resistance)
  stay unscreened beyond the descriptions read earlier: recovery grids, two with a lot multiplier.
- **Removed** per the leftovers rule: the nine `MK_*_EA.ex5` copies in Advisors, their profiles and `.set` files. The
  originals in the terminal's `MQL5/Experts/Market` folder are the user's installs and were left in place.

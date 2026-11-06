# Geraked 3MACD on EURUSD H1: root cause of the drawdown and ways to reduce it (2026-10-27)

**Scope.** Diagnostic analysis of the default 3MACD (recommended inputs = source defaults), EURUSD H1. Not a gate. Experiments E1 to E5 change one mechanism each, on the Gate A window (2024-01 to 2026-10). Runners and logs: `reports/oct25/3macd_diag.py`, `reports/oct25/3macd_diag_variants.log`, `reports/oct25/3macd_root_cause.py`, `reports/oct25/3macd_cap_cost.py`. The diagnostic builds were removed after the runs.

## Experiments (Gate A window, 2024-26)

| Run | Change from default | Trades | PF | Net USD | Equity DD | Reading |
|---|---|---|---|---|---|---|
| E0 | default: reverse on, grid on, stops off | 492 | 1.78 | +4,733.98 | 24.6% | reproduces the screen |
| E1 | grid off, stops on | 331 | 0.99 | -44.40 | 6.7% | the signal alone has no edge |
| E2 | reverse off, grid on | 380 | 1.62 | +6,897.99 | 47.0% | trend-following entries go much deeper |
| E3 | reverse off, grid off, stops on | 421 | 0.70 | -2,346.40 | 25.6% | the trend signal loses money |
| E4 | grid capped at 6 legs | 372 | 1.60 | +2,359.86 | 37.0% | fewer legs, more drawdown |
| E5 | risk 0.5% to 0.25% | 492 | 1.80 | +2,118.09 | 12.8% | DD and profit both scale with risk |

Also tested earlier: a 200-pip basket depth cap (rejected at Gate A, PF 0.69, DD 34.8%).

## Root cause

1. **The edge and the drawdown come from the same mechanism.** The reverse signal has no edge by itself (E1, PF 0.99). The trend signal loses (E3, PF 0.70). The profit exists only where the grid averages down, and the basket then recovers (E0 versus E1). A basket's profit is its recovery.
2. **Each leg adds exposure into the adverse move.** Legs are added at about 0.9 of the leg's own 34-pip stop distance (median spacing 31 pips), with about the same lot size each time (median last-to-first lot ratio 1.00). Stops are disabled once the grid is on. The floating loss of a basket therefore grows roughly with the square of its depth, which concentrates the drawdown in a few deep baskets.
3. **Depth is set by the market, not by the grid.** The worst basket of 2026-01-22 had 13 legs over 371 pips. Its floating low was about 3,543 USD on Gate A and 4,808 USD on the 2022-26 run. The reported drawdowns were 3,590 and 4,872 USD, so the reconstruction is close. It is a lower bound: it only sees the floating at the leg prices, so it misses moves after the last leg (see E4).
4. **Averaging is what buys recovery.** Capping the legs at 6 (E4) did not cut the loss. It stopped the averaging, so the basket had to recover from further away, and the drawdown rose from 24.6% to 37% while profit halved.
5. **Stopping early costs more than it saves.** The 200-pip cap realised losses on baskets that would otherwise have recovered. Across the 2022-26 run it cost roughly 9,000 USD, approximately, of realised profit (16 baskets reached the cap, and 15 of them would have locked in a worse result).
6. **The reverse direction keeps baskets shallower.** Turning it off (E2) raised profit and pushed the worst basket to 453 pips and the drawdown to 47%. Fading the move caps the depth for this sample.
7. **Sizing does not change the ratio.** E5 halves the risk and halves both the drawdown and the profit. The recovery factor is about 1.3 to 1.4 in every case, so sizing alone cannot reach 8% without giving up most of the return.

**Bottom line:** the drawdown is the price of the averaging edge. The grid profits by holding losing baskets until they recover, and the same holding time produces the deep floating losses. Reducing it means changing the tail (the rare baskets that do not recover), not the average trade.

## Ways to reduce it (ranked)

1. **Trend-persistence filter on the reverse entries.** Test the hypothesis that deep baskets start in persistent trends. First, a diagnostic EA logs the H1 trend state (for example ADX and the EMA slope) at each leg, then the cycles are joined to it. If the deep baskets are regime-specific, a filter that skips fading entries in strong trends should cut the tail with fewer side effects than a stop. This is the most direct test of the root cause.
2. **Equity-based basket stop, referenced to peak equity and checked on every tick.** The earlier EquityDrawdownLimit variant compared equity with balance and ran on the 30-second timer, so it could not hold the drawdown near 8%. A corrected version cuts only the largest floating losses. It should cost less than the depth cap, because it leaves smaller baskets alone. This needs a spec and a test before any conclusion.
3. **Shrink the later legs.** Each further leg at 0.5 times the previous one keeps the averaging but limits the exposure growth. This is different from the leg cap (E4), which stopped averaging. It should be tested before it is dismissed.
4. **Exposure cap in lots.** A total-lot cap probably behaves like the leg cap (E4) and stops averaging. Test it only after option 3.
5. **Time stop.** Baskets lasted up to about 8 days. A time stop would realise losses in the same way as the depth cap, so it is likely to cost return. Keep it as a last resort.
6. **Portfolio route (already chosen).** At an 8% drawdown the standalone return would be roughly a third of the default, about +4% a year, well under the 10% sizing step. This EA is more likely to help a portfolio than to stand alone.

**Next steps, in order:** (a) the regime-logging diagnostic for option 1, which costs one run; (b) a single-variant spec for option 1 or option 2, depending on the diagnostic; (c) the add-on test for the default build, if the portfolio route is still wanted.

## Caveats

- All results are in-sample on 2022-26 (Gate A only for the experiments). No out-of-sample test was run for the variants.
- The floating reconstruction is a lower bound. It underestimates the drawdown when the worst point comes after the last leg, as in E4. The reported drawdowns were used for the headline figures.
- No tick data was available, so the basket floating is measured at leg prices.
- The "approximately 9,000 USD" cost of the cap is an estimate from leg prices with no spread, not a tester result.

## Other finding

`EAUtils.mqh` contains a hard-coded login allow-list (`auth()`), and `IsAuthorized()` is defined but never called. It does not block trading, but it should be reviewed before any deployment.

## Addendum: crossing-only entries (grid off, author's exits)

Runs: `reports/oct25/3macd_cross_only.py` (Gate A window) and `reports/oct25/3macd_cross_s0.py` (2022-26 continuous). The grid is off, so the crossing is the only entry, and the author's exits remain: no broker stop, take-profit ignored, trailing only.

- **Gate A window (2024-26, flat start):** 51 trades, PF 3.17, net +388.41 USD, DD 7.1%. Gross profit +813.67, swap -402.02, commission -23.24. A position was still open at the end of the test and closed at -159.48.
- **2022-26 continuous:** 11 trades, PF 0.22, net -534.64 USD, DD 10.0%. Gross profit +152.68, swap -682.34, commission -4.98. One buy opened on 2022-02-21 at 1.13474 was never closed until the end of the test, and it accrued about -670 USD of swap over 4.6 years. While it was open the EA could not enter anything new.

**Reading.** With no stop, no take-profit and only trailing for exits, a crossing trade has no defined end. The trade can sit for years, paying swap and blocking new entries. The earlier t-stat of 2.3 was calculated on gross profit and ignored swap, so it overstated the edge. Swap is part of the root cause of the drawdown in the crossing-only system, and it is a second, separate mechanism: an exit gap.

**Implication for the full system.** The grid also keeps positions open for long periods (median time between legs about 6 hours, 90th percentile about 61 hours). The swap cost of long holds has not been measured for the default and should be checked before any further exit change.

## Addendum 2: crossing-only with exits (2022-26 window, net of swap and commission)

Runs: `reports/oct25/3macd_exits_s0.py`. Grid off, author's exits otherwise.

- **X1, signal exit** (close on the opposite crossing): 1,211 trades, PF 0.81, net -1,746.92 USD, DD 18.8%, swap -190, commission -256, per-trade net mean -1.2, wins 693 of 1,211, t -1.84.
- **X12, signal exit plus 72-bar time exit:** 1,212 trades, PF 0.81, net -1,766.18 USD, DD 19.0%, swap -187, commission -256, per-trade net mean -1.2, wins 687 of 1,212, t -1.94.

**Reading.** The exits fixed the trapped-position problem: trades rose from 11 to about 1,200, and swap fell from -682 to about -190. The time exit made almost no difference, because the signal exit already closes trades quickly. The crossing logic itself has a negative expectancy on 2022-26, with PF 0.81 and a negative t-stat. The earlier 2024-26 result (PF 3.17, 51 trades) was a small-sample result on a flat start, and it does not hold up over the longer window.

**Implication for the root cause.** The crossing signal does not carry an edge on this window, with or without these exits. The profit in the full 3MACD comes from the grid's averaging and basket recovery, and the drawdown comes from the same mechanism.

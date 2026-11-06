# Dark Venus (v5.50), grid off: outcome (2026-10-30)

Spec: `2026-10-30-dark-venus-screen-prereg.md`. Runner `reports/oct25/darkvenus_screen.py`, logs `reports/oct25/darkvenus_dv_E.log` and `darkvenus_dv_G.log`. Darwinex-Demo, real ticks, $10,000, 1:100, 0.01 lot, inputs at the compiled defaults except `EnableGrid` false and `MaxBuyOrders` = `MaxSellOrders` = 1.

**Verdict: REJECTED.** EURUSD H1 failed Gate B; GBPUSD H1 (the second instrument) failed Gate B; two rejected instruments stop the EA. Gate C was not run.

| Run | Trades | PF | Net USD (0.01 lot) | Net % of $10k | Total R at $5/R | Equity DD |
|---|---|---|---|---|---|---|
| EURUSD Gate A, 2024-01..2026-10 | 330 | 1.21 | +30.16 | +0.30% | +6.0 | 1.27% |
| EURUSD 2022-23 | 301 | 1.90 | +69.12 | +0.69% | +13.8 | 1.40% |
| EURUSD joined 2022-26 (Gate B) | 631 | 1.49 | +99.28 | +0.99% | +19.9 | 1.4% |
| GBPUSD Gate A | 356 | 1.36 | +50.43 | +0.50% | +10.1 | 0.94% |
| GBPUSD 2022-23 | 267 | 0.70 | -55.56 | -0.56% | -11.1 | 2.98% |
| GBPUSD joined 2022-26 (Gate B) | 623 | 0.98 | -5.13 | -0.05% | -1.0 | 3.0% |

**Gate B (EURUSD):** 2022-24 +155 USD, 2025-26 -56 USD: the second half is negative, so FAIL. **Gate B (GBPUSD):** PF 0.98, 2022-24 +35, 2025-26 -41: FAIL. Gate A passed on both (trades >= 40, PF >= 1.0, net > 0, no stop-out) but means little, see below.

**What the runs show.** About 99.4% of trades win, each about +0.51 USD (5 pips on 0.01 lot). The losses come from a few positions that were never stopped:

| Run | Position | Held | Move against | Closed at |
|---|---|---|---|---|
| EURUSD A | sell 2025-03-03 | 19 months | -877 pips | -82.84 USD, by the test end |
| EURUSD A | buy 2026-05-12 | 141 days | -421 pips | -53.46 USD, by the test end |
| EURUSD 2022-23 | buy 2022-03-01 | 22 months | -143 pips | -67.96 USD (mostly swap), by the test end |
| GBPUSD A | sell 2025-03-03 | 19 months | -636 pips | -80.09 USD, by the test end |
| GBPUSD A | buy 2026-02-16 | 7 months | -366 pips | -47.64 USD, by the test end |
| GBPUSD 2022-23 | buy 2022-01-14 | 23 months | -958 pips | -130.54 USD, by the test end |
| GBPUSD 2022-23 | sell 2023-11-13 | 1.5 months | -469 pips | -48.31 USD, by the test end |

Every large loser was closed only by the tester at the end of the run, none by the EA. The 500-point stop (`StopTarget` 500, `StopTargetMode` 2) never closed anything, so a result depends on the position still open when the test ends. At 0.01 lot the equity drawdown stays near 1-3%, which hides it; at any real size an open loss of 400-900 pips would be the account.

**Two assumptions in the spec were wrong.** (1) "The stop is already on in the defaults": it did not act in this configuration (grid off, one order per side). Whether it acts with the grid on was not tested; the grid-on probe's losers (9 of 49 trades in January 2024, each closed at -0.6 to -15 pips) look like basket exits, not stops. (2) 1R = $5.00: the nominal stop is $5.00, the realised losses on the stuck positions are $48-131 (10-26 times that), so the total R column understates the risk.

**Not tested:** the as-published grid-on configuration (up to 50 orders per side), other inputs, other timeframes. They are outside the spec and the two-rejects rule applies.

**Fit for the live set.** Even setting the verdict aside, an EA that holds losing positions for months cannot meet Atlas's 8% static limit, the 4% daily limit or the funded-stage 2% open-loss protector, and no source exists to add a working stop.

**Journal and safety check.** A 10-day run's tester journals (master and agent) had no line on network access, DLLs, licence or errors (the search pattern was http, WebRequest, URL, .dll, allow, denied, error, fail, cannot, licence, expired, invalid). That search did not include the phrase the four other Dark EAs print at start, `You are in backtest, or our website don't work correctly` (see the family spec), and the journal was cleaned before I looked for it, so whether Venus prints it too is unknown.

**Leftovers removed:** `Dark_Venus.ex5` from `Advisors`, `Dark_Venus.set` from `Profiles/Tester`, the `Dark_Venus` entry in `scripts/ea_profiles.py`, the tester logs. Kept: the user's own `Dark Venus MT5.ex5` and their GUI tester files, the spec, this outcome, the runner, the probe script, the logs and the run reports in `reports/` (`dv_*`, `darkvenus_probe_*`).

**Commit status:** uncommitted; the commit waits for the user's go-ahead.

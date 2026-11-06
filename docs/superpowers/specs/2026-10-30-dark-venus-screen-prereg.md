# Dark Venus (Marco Solito, v5.50) on EURUSD H1, grid off: pre-registration (2026-10-30)

**Source:** compiled `Dark Venus MT5.ex5` only, no source. The file in the user's MT5 `Advisors` folder is byte-identical to the one in the download (`cmp`). The tester needs a name without spaces, so a copy `Dark_Venus.ex5` is used (also `cmp`-identical). Header: copyright 2025 Marco Solito, `https://darkeas.com/`, version 5.50. The five Dark EAs were assessed on 2026-10-30; the other four load a separate paid indicator that is not installed, so only Venus (built-in Bollinger Bands, no external indicator) can be tested.
**Scan:** the compiled string table has no DLL name and no `#import`; the code body is compressed, so a network call cannot be excluded from the file alone. The tester journal is read for it after the first run. The manual carries affiliate links (broker, VPS); they are data, not part of the test.
**Licence:** none seen; the manual calls it an "educational" EA and the input list says "UNLIMITED VERSION". Deployment would need source, which does not exist (`docs/gates.md`): a pass is research evidence, and the user chose to run the screen anyway (2026-10-30).

**Question.** Does Dark Venus with its Bollinger-band entry, without grid orders, pass Gates A, B and C on EURUSD H1, as an add-on for the live set?

**Strategy (manual).** Entry on Bollinger Bands (20, 2.0, close price, chart timeframe), default strategy 0 "Sell Above and Buy Below" (fade a bar that closes beyond a band). Close at a fixed take target; a global stop is measured from the weighted average entry price.

**Probe before this spec (input discovery, not part of any gate).** One month of EURUSD H1 (2024-01-01 to 2024-02-01) with the compiled defaults, grid on: 49 trades, PF 5.23, net +30.28 USD (0.01 lot), win rate 81.6%, max DD 0.08%, 31 s, tester log growth 0.2 MB. It gave the input list below and the speed. Its numbers do not enter any verdict.

**Compiled defaults (from the probe's report):** `Lots` 0.01 fixed (`MoneyManagement` false), `MaxSpread` 500 points, `BollingerBandsStrategies` 0, `BollingerBandsPeriod` 20, `BollingerBandsDeviations` 2.0, `MomentOfTheSignal` 1, `TakeTarget` 50 points, `StopTarget` 500 points with `StopTargetMode` 2 (stop from the weighted average of the open orders), `CloseMode` 1 (weighted average), `EnableGrid` **true**, `GridManagement` 0 (fixed lots), `MinDistanzaPiramide` 50 points, `MaxBuyOrders` / `MaxSellOrders` 50, `OneTradeBar` true, `AllowBuyAndSellAtSameTime` true, trading days Monday to Friday, no time window, no Friday close, no monetary or percentage loss stop, `StopTradingWhenHit` false.

**Setup.** Darwinex-Demo, EURUSD H1, real ticks, $10,000 deposit, 1:100 (the screen defaults in `reports/oct25/screen_eval.py`). Source defaults except three inputs, set now because "grid off" is the design the user approved (2026-10-30):
- `EnableGrid` = false (no distance-based averaging orders);
- `MaxBuyOrders` = 1 and `MaxSellOrders` = 1 (with the grid off the manual does not say whether repeated indicator signals stack more orders; this guarantees at most one position per side, so nothing can average or pyramid). At most one buy and one sell can be open together (`AllowBuyAndSellAtSameTime` stays true).

The stop is already on in the defaults (`StopTarget` 500 points from the entry, `StopTargetMode` 2), so no stop input changes.

**Sizing for reporting.** Fixed 0.01 lot. 1R = the stop = 500 points on 0.01 lot = $5.00 (EURUSD and GBPUSD: $0.01 per point per 0.01 lot). The stop is managed by the EA, not a broker stop-loss order, so the report has no per-trade R; total R = net USD / 5.00 and average R = total R / trades. Every result shows net USD (0.01 lot, $10,000) and total R.

**Stateful?** No: fixed lots, one position per side, a per-position stop, no permanent stop. Gate B is the 2022-23 run joined with the 2024-26 screen (`docs/gates.md`). **Check in the Gate A run:** if more than one same-side position is ever open at once, the three inputs did not do what is assumed; the screen is then reported as invalid for its design (not a pass or a fail) and the Gate B run becomes one continuous 2022-26 run.

**Data check.** Expected EURUSD H1 bars (from the other screens): 2024-01..2026-10 about 17,100; 2022-01..2023-12 about 12,480; 2019-01..2021-12 about 18,700. A window more than 8% off is inconclusive. Gate C also needs history quality >= 90%.

**Decision rule (fixed before the run).**
- Gates A, B, C as in `docs/gates.md`. Gate C is the **add-on** version (net > 0 and PF >= 1.0), because the goal is an add-on, not a standalone EA (memory: portfolio add-ons).
- After Gate C the result is "add-on test due". That test needs the account roster and its own spec; it is not part of this screen.
- **Second instrument:** GBPUSD H1 with the same inputs, only if EURUSD is rejected at any gate. The defaults are scaled for 5-digit pairs (take target 5 pips), so gold is not tested. If GBPUSD is also rejected, the EA stops (the two-rejects rule).
- **No loss-limiting variant:** the stop is already on in the tested configuration, so the variant rule has nothing to add.
- The speed rule applies: a two-week probe over 900 s rejects the cell as too slow (`log_guard`); an early reject applies at >= 150 trades and PF < 0.75, as in `screen_eval.py`.

**Not in this spec:** the as-published grid-on configuration (grid orders, up to 50 per side), the other four Dark EAs, other timeframes or instruments, any input sweep, the live account and the add-on test.

**Commit status:** uncommitted, like the other specs from this session; the commit waits for the user's go-ahead.

**Leftovers.** After the verdict: the `Dark_Venus.ex5` copy in `Advisors`, any `Dark_Venus.set` in `Profiles/Tester`, the temporary `Dark_Venus` entry in `scripts/ea_profiles.py`, and the tester logs. The user's own `Dark Venus MT5.ex5` in `Advisors` stays. The spec, the runner, the logs and the outcome stay.

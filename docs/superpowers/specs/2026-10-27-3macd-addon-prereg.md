# Add-on test: Geraked 3MACD (EURUSD H1, default build) on the live set (pre-registration, 2026-10-27)

**Why.** The standalone route to 8% drawdown is closed for this EA (`2026-10-27-3macd-cap-trend-filter-outcome.md`, `2026-10-27-3macd-lot-cap-1p2-outcome.md`, and the Phase 0 frontier). The user chose the portfolio route: does 3MACD lower the combined drawdown of the live set while adding return?

**Candidate.** The default build from `Experts/3MACD.mq5` (Geraked), recommended inputs = source defaults, EURUSD H1, as in the continuous-run pass (`2026-10-27-3macd-continuous-gate-b-outcome.md`). Its trades are its grid cycles: one closed trade per flat-to-flat cycle, from the continuous 2022-26 report `reports/g3_3MACD_EURUSD_H1_s0_20261027_220134.htm`. Eligibility (2026-10-26 rule): Gate A pass, 2019-21 net positive with PF at least 1.0 (Gate C: +5,609 USD, PF 2.12). Eligible.

**Baseline (changed from the 2026-10-26 test).** The live set is now the eight EAs in `scripts/make_live_sets.py` (`BASE`), because NDX Band Breakout was added on 2026-10-27. The baseline is:
- MACD Cross (`macdtf_h1_20261019_210429`), Donchian Breakout (`lowtf_donch_h4_20261019_212257`), RSI Reversal (`lowtf_rsi_h6_20261019_213004`), MA Channel (`lowtf_mach_h1_20261019_214347`), Donchian Trend (`dtrend_pick_20261021_073858`), Invictus Monday (`inv131_s0_mon_20261021_131936`), NI225 Gap Continuation (`ni225g_m0r_20261023_174047`, loaded by `ni225()` in `reports/portfolio/dz_joint_ni225.py`);
- NDX Band Breakout: `ndxbb_DZ100k_s0a_20261027_072752` (2022-23) and `ndxbb_DZ100k_scr_20261027_072850` (2024-26), joined.

Numbers are not comparable with the 2026-10-26 seven-EA baseline (10-26 baseline A: +70.4%/yr, max DD 15.93%), because the set has changed.

**Window.** 2022-01-01 to 2026-10-01, as in the earlier add-on tests. Halves reported separately: 2022-24 and 2025-26.

**Sizing (the test's, as in 2026-10-26).** The candidate's closed trades are converted to a percentage of the account balance at entry (profit / balance before entry at its default size). Each allocation scales the series so the candidate's own closed-trade max drawdown equals 1% of the account, then 2%. A closed-trade max drawdown of about 7% for this EA means the scale is about 0.15 (1%) and 0.30 (2%). At the 2% allocation, its floating drawdown (24.7% at default size) becomes about 7% of the account on its own. That is why the second view below is required.

**Two views (both reported, both must pass).**
1. **Closed-trade view (the framework's test).** The live set's closed trades at 0.5% constant risk, with and without the candidate. Same three conditions as the NI225 and 2026-10-26 tests.
2. **Floating-inclusive view (added here).** The same portfolio, with the candidate's floating P/L added to the day-level equity. Floating is rebuilt from the candidate's grid legs: at each leg event, the open legs' P/L at that leg's price (USD, the scaled lots), held as a step until the next event and zero after the basket closes. This is a lower bound: the price between legs is not observed, so the true floating drawdown is at least this large. The same three conditions are applied.

**Conditions (fixed before the run).** For each view and each allocation:
1. return / max drawdown with the candidate >= without it;
2. max drawdown with it <= without it + 1.0 point;
3. worst month with it >= without it - 1.0 point.

Reported, not gated: return per year, Sharpe, worst day, daily and monthly correlation with the live set, and the halves.

**Decision rule.**
- **Added** only if all three conditions hold in **both views** at the **1%** allocation. The 2% allocation is reported, and is a candidate only if it also passes both views.
- A pass in the closed-trade view alone is not enough, because the closed-trade view does not see the grid's floating loss.
- Pass in both views at 1% but failing at 2%: the candidate is recommended at 1% only.

**Expectation, written before the run.**
- **Closed-trade view:** a small gain or none. FX EURUSD should correlate weakly with the gold set, so return/DD may rise slightly at both allocations.
- **Floating view:** the candidate's floating loss lands in the same periods as the live set's drawdowns only if the timing overlaps. At 1% the extra drawdown is likely between about 1 and 3 points, so a failure of condition 2 is the expected outcome, and the test may well reject it. At 2% it is very likely to fail.
- In short, the expectation is that the grid's floating risk makes the candidate fail the portfolio test in the floating view, even if the closed-trade view passes.

**Caveats.** The live set was tuned on this window (in-sample). The candidate is one 2022-26 run, with 871 closed cycles on the continuous basis. The floating view is a lower bound. NDX's 2022-23 run was on the production DZ100k account, which is not the IC Markets account.

**Before any live use (not part of this test).**
1. **Licence.** The Geraked repository's licence was not checked. The gates require no third-party licence or approval before deployment, so this must be confirmed first.
2. **Broker.** The live account is IC Markets, so a run on the target broker and server clock is required, as the earlier add-on rule asks.
3. **Account guards.** The EA has no daily loss limit, and the grid runs without a broker stop. Any live use needs an account-level limit decided first.

**No run until approved.** This spec only sets the test. The runner (`reports/portfolio/addon_3macd.py`) is written and run after the user approves the spec. No tester runs are needed, since all inputs are existing reports.

**Commit status:** uncommitted, like the other specs.

## Amendment (2026-10-28): account limit and live-set review

The user approved proceeding with the portfolio route and clarified that the operating constraint is an 8% maximum drawdown on both Darwinex Zero and FTMO. Add the absolute account constraint to the original relative add-on rules: the combined portfolio must also remain below 8% in both views. A relative pass alone is insufficient.

Evaluate the account portfolios separately. Darwinex Zero uses the eight-EA set in `scripts/make_live_sets.py`; FTMO excludes NI225 and uses its own set and throttle. The initial FTMO calculation is explicitly a proxy because the saved NDX report is from Darwinex and no FTMO 3MACD run exists. The saved 3MACD report is also a lower-bound floating reconstruction: it marks grid positions at deal events and does not provide complete open-equity history for the other EAs.

**Approval and action.** Approval was received 2026-10-28. `reports/portfolio/addon_3macd.py` runs the saved-report analysis; it does not launch MT5 or modify tester data. Because the available inputs cannot establish the full portfolio's floating equity, an absolute-limit pass cannot be awarded from this historical screen alone.

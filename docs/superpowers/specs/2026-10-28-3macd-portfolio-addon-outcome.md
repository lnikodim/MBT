# 3MACD portfolio add-on screen (2026-10-28): relative pass, 8% limit not established

**Spec:** `2026-10-27-3macd-addon-prereg.md`, amended 2026-10-28 after the user clarified the 8% account drawdown ceiling and approved the portfolio route. **Runner:** `reports/portfolio/addon_3macd.py`. This uses saved reports only; no MT5 tester runs were launched.

## Scope and method

- 3MACD default EURUSD H1, continuous 2022-01 through 2026-10 report: 891 closed positions. The candidate is scaled to a standalone closed-trade drawdown of 1% and 2%; the raw candidate closed-trade drawdown is 7.07%.
- Darwinex Zero baseline: the eight EAs in `scripts/make_live_sets.py`, replayed at the documented account allocations. FTMO proxy: same roster minus NI225, with the 3% portfolio throttle replayed against closed equity.
- The joint path combines closed-trade returns from the portfolio reports with the candidate's floating P/L marked at 3MACD deal events. This is a lower bound: it misses intraleg price moves, candidate swap while positions remain open, and floating P/L for the other EAs.
- The FTMO figures are a proxy. The saved NDX report uses Darwinex data, and there is no FTMO-specific 3MACD report. The saved candidate run also does not reproduce both target account execution environments.

## Results, full 2022-26 window

| Account replay | Baseline closed DD | Candidate allocation | Joint net | Joint DD, closed / event-marked | Worst month | Relative add-on rules | Sampled DD below 8% |
|---|---:|---:|---:|---:|---:|---|---|
| Darwinex Zero | 16.03% | 1% | +340.10% | 15.71% / 15.71% | -10.42% | Pass | Fail |
| Darwinex Zero | 16.03% | 2% | +349.87% | 15.39% / 15.79% | -10.19% | Pass | Fail |
| FTMO proxy, 3% throttle | 10.99% | 1% | +208.57% | 10.53% / 10.53% | -5.70% | Pass | Fail |
| FTMO proxy, 3% throttle | 10.99% | 2% | +218.35% | 10.08% / 10.12% | -5.47% | Pass | Fail |

The relative rules pass at both allocations in both account replays: return-to-drawdown improves, drawdown stays within 1 point of baseline, and worst month improves. The added 3MACD return is about 9.77 percentage points at the 1% allocation and 19.54 points at 2% in this additive replay.

## Decision

**Do not mark 3MACD approved for either prop account from these results.** The historical portfolio proxy is above 8% before and after adding 3MACD. The add-on looks favorable relative to the saved baseline, but the absolute account limit is not met in the sampled paths. Since full portfolio floating equity is unavailable, these results cannot certify actual account-limit compliance. The higher allocation provides more return but is not justified by an 8% constraint.

The 1.2-lot cap was not compared in the portfolio runner: the default candidate did not establish the absolute limit, and the earlier cap-1.2 report failed Gate C. Revisit it only after the current portfolio is replayed with full account equity and the candidate's account risk controls.

## Limitations and next step

- The 16.03% Darwinex and 10.99% FTMO values are closed-trade replay drawdowns, not broker equity curves. FTMO throttle was replayed from closed-equity drawdown; it is not a tick-for-tick account simulation.
- No 2022-24 / 2025-26 breakdown is reported: the full-window screen already fails the absolute 8% check, and the partial-year event-marked candidate path would omit inherited open baskets at the split.
- Next, establish the current account baseline with synchronized balance and floating-equity data for the actual EA sets and broker settings. Only then rerun the same candidate allocation with the absolute 8% rule. If the baseline remains above 8%, first reduce portfolio risk; changing 3MACD alone does not solve that constraint.

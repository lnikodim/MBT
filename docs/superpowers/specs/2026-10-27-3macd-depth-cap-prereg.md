# Geraked 3MACD on EURUSD H1, grid basket depth cap of 200 pips: pre-registration (2026-10-27)

**Why this variant.** The continuous-run outcome (`2026-10-27-3macd-continuous-gate-b-outcome.md`) passed Gates A, B and C, but its drawdown is 24.6 to 24.7% on Gates A and B, far above the 8% sizing level. The drawdown analysis (`reports/oct25/3macd_cycles.py`) puts it in a few deep grid cycles, with one cycle of 13 legs over 371 pips accounting for almost all of it. The user chose option 1 from that analysis: cap the adverse depth from the first leg, in pips.

**Source.** The default build (`Experts/3MACD.mq5`, Geraked) with exactly these changes:
1. A new input, `GridDepthCapPips` = 200 (pips from the first leg; 0 = off).
2. A function, `CheckGridDepthCap()`, called at the start of every tick. It finds the first leg of the open grid (earliest position with this magic on this symbol) and measures the adverse move from its open price to the current Bid (buy) or Ask (sell). When that reaches the cap, it closes every position with this magic on this symbol at market.
3. `#include <Trade/Trade.mqh>` for the close calls.

Nothing else changes: the signal, the grid, the trailing stop, the sizing and all other inputs stay as the author wrote them. The build compiles with 0 errors and 0 warnings. The scan finds no DLL, network or file access.

**Choice of 200 pips (disclosed).** Before choosing, the depths of the Gate A cycles were looked at (in-sample, 265 cycles). Cycles reaching 200 pips: 5, with realised P/L of −802 USD. Cycles reaching 300 pips: 2, with +80 USD, both of which recovered without a cap. 200 is a round number inside the observed range. The choice is fixed here before any run, and it is the only value tested.

**Question.** Does 3MACD with the 200-pip basket cap pass Gates A, B (one continuous 2022-26 run) and C, and how does its drawdown compare with the default?

**Setup.** As the continuous-run spec: Darwinex-Demo, EURUSD H1, real ticks, $10,000, 1:100, the author's recommended inputs (identical to the source defaults), Risk 0.5%, grid on with 50 levels, equity drawdown limit off.

**Comparison with the default (recorded before the run).** The default results from the continuous-run outcome are the reference:
- Gate A: 492 trades, PF 1.78, net +4,733.98 USD, max DD 24.60%.
- Gate B (continuous): 891 trades, PF 1.76, net +9,876.83 USD, max DD 24.68%.
- Gate C: 524 trades, PF 2.12, net +5,609.43 USD, max DD 19.54%.

**Data check.** H1 bar counts as before: 17,100 (2024-26), 29,580 (2022-26 continuous), 18,700 (2019-21). A window more than 8% off is inconclusive.

**Decision rule (fixed before the run).**
- The variant passes if Gates A, B (continuous) and C all pass. Its drawdown is reported side by side with the default.
- If it passes and its drawdown is clearly lower than the default, it is the candidate for the portfolio add-on test, which is a separate spec.
- If it fails any gate, it is rejected. The default stays as recorded.
- One variant only. No other cap value is tested in this spec.

**Not in this spec:** other cap values, other inputs, the add-on test, other symbols or timeframes, and the live account.

**Commit status:** uncommitted, like the other specs.

**Leftovers.** After the verdict: the `GerakedTest` build (`3MACD_cap200`), its tester `.set` file and the temporary `ea_profiles.py` entry are removed. The `EAUtils.mqh` and `errordescription.mqh` copies and the scratch downloads stay for the add-on decision. The spec, runner, logs and outcome stay.

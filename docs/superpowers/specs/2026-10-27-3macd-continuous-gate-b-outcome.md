# Geraked 3MACD on EURUSD H1, recommended inputs, continuous Gate B: outcome (2026-10-27)

**Spec:** `2026-10-27-3macd-continuous-gate-b-prereg.md`. **Runner:** `reports/oct25/3macd_screen.py`, log `reports/oct25/3macd_eur_h1_screen.log` (gitignored). **Drawdown analysis:** `reports/oct25/3macd_dd_analysis.py` and `reports/oct25/3macd_cycles.py`.
**Setup:** Darwinex-Demo, EURUSD H1, real ticks, $10,000, 1:100, the author's recommended inputs (identical to the source defaults), Risk 0.5%, grid on with 50 levels, equity drawdown limit off.

## Results

| Gate | Window | Trades | PF | Net USD | Max DD | Stop-outs | Bars (expected) | Verdict |
|---|---|---|---|---|---|---|---|---|
| A | 2024-01..2026-10 | 492 | 1.78 | +4,733.98 | 24.60% | 0 | 17,108 (17,100) | PASS |
| B | 2022-01..2026-10, one continuous run | 891 | 1.76 | +9,876.83 (2022-24 +6,058; 2025-26 +3,818) | 24.68% | 0 | 29,563 (29,580) | PASS (floor 150) |
| C | 2019-01..2021-12 | 524 | 2.12 | +5,609.43 | 19.54% | 0 | 18,683 (18,700); real ticks 99.0% | PASS |

**Verdict:** candidate on all three gates. Gate B is the continuous run that `docs/gates.md` requires for a stateful grid EA. The earlier screen had judged it on joined 2022-23 runs, so these results supersede that Gate B.

## Drawdown

The drawdown is 24.6 to 24.7% on Gates A and B and 19.5% on Gate C, far above the 8% sizing level. The drawdown analysis (`3macd_cycles.py`) puts it in a few deep grid cycles: one sell basket with 13 legs over 371 pips accounts for about 3,543 USD of floating loss, close to the 3,590 USD equity drawdown on Gate A. Realised losses are small. See the analysis scripts for details.

The equity-limit drawdown variant already failed in the earlier screen (`2026-10-27-3macd-dd-variant-prereg.md`). Under `docs/gates.md` that failure is a rejection. The user has chosen the portfolio add-on test as the route for this EA. That test needs its own pre-registration spec and is not part of this run.

## Cleanup

- `scripts/ea_profiles.py` restored to HEAD (the temporary 3MACD entry was the only change).
- MT5 `MQL5/Experts/GerakedTest/` (source, .ex5, compile log) removed.
- Tester `3MACD.set` written by this run removed.
- Kept for the add-on decision, per the spec: `MQL5/Include/EAUtils.mqh` and `MQL5/Include/errordescription.mqh` (copied for this run), and the scratch downloads in `scratchpad/geraked_review`.
- Tester logs empty after the run.

## Next

The add-on test needs a spec. It will use the seven live EAs at 0.5% risk, with and without 3MACD, and the rule in `docs/gates.md`. Nothing is run until the user approves that spec.

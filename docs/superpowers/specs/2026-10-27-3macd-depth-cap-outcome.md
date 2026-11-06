# Geraked 3MACD on EURUSD H1, grid basket depth cap of 200 pips: outcome (2026-10-27): REJECT at Gate A

**Spec:** `2026-10-27-3macd-depth-cap-prereg.md`. **Runner:** `reports/oct25/3macd_cap_screen.py`, log `reports/oct25/3macd_cap200_eur_h1_screen.log` (gitignored).

| | Default (continuous-run outcome) | Depth cap 200 pips |
|---|---|---|
| Gate A trades | 492 | 535 |
| Gate A PF | 1.78 | 0.69 |
| Gate A net USD | +4,733.98 | -2,559.79 |
| Gate A max DD | 24.60% | 34.82% |
| Stop-outs | 0 | 0 |
| Bars | 17,108 (17,100) | 17,108 (17,100) |

**Verdict:** REJECT at Gate A. Gates B and C were not run. The cap made both the result and the drawdown worse.

**Why (from `3macd_cap_cost.py`).** A basket that reaches 200 pips from its first leg is usually recovering rather than lost. Closing it at the cap realises a loss that the default would often have recovered from, and re-entry on the next candle can repeat the cycle. The cap also turns open exposure into realised losses, so the drawdown no longer recovers before the next cycle.

**Cleanup.** The `3MACD_cap200` build in `MQL5/Experts/GerakedTest`, its tester `.set` and the temporary `ea_profiles.py` entry are removed. The EAUtils and errordescription copies and the scratch downloads stay for the add-on decision on the default build. The spec, runner, log and this outcome stay.

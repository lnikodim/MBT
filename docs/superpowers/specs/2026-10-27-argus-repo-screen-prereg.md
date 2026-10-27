# Argus repo (LogicCrafterDz/Argus, MIT): the five strategy EAs the user asked to test first, on Darwinex (2026-10-27)

**Request:** "test all EAs in this repo https://github.com/logiccrafterdz/Argus but prioritize the 1st 6 EAs from the image". Only five of the six can be run: AVWAP Confluence does not compile on this MetaEditor build (`case` labels with uninitialised declarations, error 179, lines 135-136). Fixing it would change the author's source beyond the approved change, so it was not run.

**Scope decisions (user):**
1. Option 1: every EA includes `Shared/ArgusCore.mqh`, whose `SendTelegramAlert` calls `WebRequest` to api.telegram.org on each trade open when a local `Argus_TelegramConfig.txt` exists. The scratch build made that function a no-op; nothing else changed.
2. "If 2 gates are rejected, do not execute 3rd run" (general rule, now in memory): after two rejected instruments of one EA, its remaining instruments are not run. Applied to SuperTrend EMA, Smart Swing Bias and Bollinger; Hidden Divergence and TrendPullback had all ten instruments run before the rule.

**Setup:** Darwinex-Demo, real ticks, 10,000 USD, 1:100; instruments EURUSD, GBPUSD, USDJPY, USDCHF, USDCAD, AUDUSD, NZDUSD, EURJPY, GBPJPY, XAUUSD; timeframe H1 (Smart Swing Bias H4) as the author's engine maps them. Gates as in docs/gates.md. Caveat: the Argus strategies normally read regime and session from their orchestrator; with it absent those checks are skipped.

## Results (26 cells run, 24 not run under the rule)
| EA | Cells run | Outcome |
|---|---|---|
| Hidden Divergence | 10 | 9 Gate A rejects (PF 0.48-0.85); XAUUSD passes A (145 tr, PF 1.33, +3,297) and joined B (283 tr, PF 1.07, +1,410), fails C (2019-21: 193 tr, PF 0.75, -3,082, DD 37%). Closed. |
| TrendPullback | 10 | all ten Gate A rejects, PF 0.64-0.88, losses -2,790 to -8,120 USD. Closed. |
| SuperTrend EMA | 2 | EURUSD A reject (195 tr, PF 0.50, -3,433); GBPUSD A reject (204 tr, PF 0.68, -2,335). Rule: 8 not run. Closed. |
| Smart Swing Bias (H4) | 2 | EURUSD A reject at 39 trades (floor 40; PF 1.13, +337). GBPUSD A pass (41 tr, PF 1.17, +466); joined B fails on the weekly floor of 80 (63 tr; PF 1.20, +805, both halves positive, DD 7.9%). Rule: 8 not run. Closed. |
| Bollinger Mean Reversion | 2 | EURUSD A reject (177 tr, PF 0.68, -3,785); GBPUSD A reject (158 tr, PF 0.60, -4,696). Rule: 8 not run. Closed. |

**Verdict:** no candidate. The only pipeline passes that reached Gate C (Hidden Divergence XAUUSD) failed on 2019-21. Smart Swing Bias GBPUSD is the closest near miss: positive in both halves but only 63 trades against the 80 floor; it is not promoted.
**Coverage limit:** 24 of 50 cells were not run because of the two-rejects rule. An untested instrument could still pass for Smart Swing Bias or Bollinger; the rule is the user's and was applied as written.

**Result against the author's README:** the README reports +125% over 2018-2026 (PF 1.18, 3,742 trades) and the latest `run_manifest.json` reports +13.9% (PF 1.07, 1,688 trades). Neither reproduces here on the MT5 tester, which runs the EAs, not the author's Python engine.

**Leftovers removed (standing rule):** the MT5 `Experts\Argus` folder, the scratch clone and patched build, and the five profile entries. Kept: this spec and the logs under `reports/oct25/argus.log` and the screen's runner `reports/oct25/argus.py`.

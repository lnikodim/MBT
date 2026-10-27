# MACD_Cross_EA (live, XAUUSD H1): long-only variant, pre-registration (2026-10-27)

**Why this variant exists (post-hoc, labelled).** In the 2019-21 baseline run (618 trades, net -1,026 USD, PF 0.93), the short side made 274 trades with 7 take-profit hits (2.6%), a trading loss of -3,255 USD and swap of -2,296 USD. The long side made 344 trades with 32 take-profit hits (9.3%), +4,204 USD of trading profit and +596 USD of swap. The variant is chosen from that diagnosis, so the 2019-21 period (Gate C) is no longer out-of-sample for it.

**Question.** Does the live EA improve when it takes long trades only?

**Baseline (live, already run on 2026-10-27, not re-run):** MACD_Cross_EA with the chart settings in `mql5/profiles/MBT_DarwinexZero/chart01.chr`, XAUUSD H1, H4 EMA-200 trend filter, stop 0.5%, target 3.75%, risk 0.5%. Results from `macdswap_base_XAUUSD_H1` (same harness and settings):
- Gate A (2024-01..2026-10): 569 trades, PF 1.87, net +20,049 USD, DD 13.4%, 0 stop-outs.
- Gate B (joined with A): 961 trades, PF 1.73, net +23,761 USD (22-24 +5,281; 25-26 +18,480), DD 14.6%.
- Gate C (2019-01..2021-12): 618 trades, PF 0.93, net -1,026 USD, DD 25.8%. FAIL.

**Variant (the only one):** identical to the baseline, except new input `InpAllowShort` (default `true` = live). With `InpAllowShort = false`, sell signals are discarded before the trade is opened; buy signals are unchanged. No other code change. The live source file is not modified.

**Setup:** Darwinex-Demo, XAUUSD H1, real ticks, $10,000 deposit, 1:100, Gates A, B and C as docs/gates.md. Gate B is the joined run (no grid, so not stateful).

**Decision rule (fixed before the run):**
1. The variant passes Gates A and B. These two windows are the primary evidence, because they lie outside the 2019-21 diagnosis.
2. On Gate A and on the joined Gate B, the variant's net profit and PF are both higher than the baseline's.
3. Max drawdown is not more than 1.0 point above the baseline's on either gate.

Adopt only if all three hold. Gate C is reported as a consistency check, not as out-of-sample evidence: a Gate C pass would not be enough on its own, and a Gate C fail would not reject the variant if the rule above holds.

**Not in this spec:** the trend-filter swap (closed), other instruments, other timeframes, changes to stops or targets, and any change to the live account.

**Leftovers:** the test build and its profile entry are created only when the spec is run, and are removed after the decision is recorded. The spec and logs stay.

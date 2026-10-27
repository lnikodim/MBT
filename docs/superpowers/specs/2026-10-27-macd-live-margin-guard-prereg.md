# MACD_Cross_EA (live, XAUUSD H1): margin-level entry guard, pre-registration (2026-10-27)

**Why this variant.** 3MACD blocks new entries while its margin level is below 300% and positions are open (`MarginLimit = 300`). The live EA has daily and monthly loss limits but no margin guard, and it can hold up to three positions in one direction. The guard is a safety feature, not an edge, so this test does not look for a better profit. It checks that the guard leaves the live results unchanged in backtests, and that it blocks entries when the margin level is low.

**Question.** Does a margin-level guard at 300% change the live EA's trades in backtests?

**Baseline (live, already run on 2026-10-27, not re-run):** MACD_Cross_EA with the chart settings in `mql5/profiles/MBT_DarwinexZero/chart01.chr`, XAUUSD H1. Results from `macdswap_base_XAUUSD_H1`:
- Gate A (2024-01..2026-10): 569 trades, PF 1.87, net +20,049 USD, DD 13.4%, 0 stop-outs.
- Gate B (joined with A): 961 trades, PF 1.73, net +23,761 USD, DD 14.6%.
- Gate C (2019-01..2021-12): 618 trades, PF 0.93, net -1,026 USD, DD 25.8%.

**Variant (the only one):** identical to the baseline, plus a new input `InpMarginLimit` (default `0` = off, live). With `InpMarginLimit = 300`, a new entry is skipped when at least one position is open and the account margin level is below 300%. The check runs on the same bar as the crossover and changes nothing else. A counter logs each blocked entry.

**Setup:** Darwinex-Demo, XAUUSD H1, real ticks, $10,000 deposit, 1:100, Gates A, B (joined with A) and C as docs/gates.md. The EA has no grid, so Gate B is the joined run.

**Data check:** H1 bar counts must match the expected totals for each window (about 17,100 for 2024-26 and about 18,700 for 2019-21).

**Decision rule (fixed before the run):**
1. The guard run must match the baseline: the same trade count, net profit and PF on Gates A, B and C.
2. The count of blocked entries is reported. A nonzero count means the guard changed trades, and the run is then a finding to explain, not a pass.
3. If rule 1 holds, the guard is recommended as a safety setting for the live account. Turning it on in the live account is a separate decision for you.
4. If rule 1 fails, the guard is not recommended until the cause is understood.

**Not in this spec:** any change to entries, exits, risk sizing, other instruments or timeframes, the reuse candidates already closed (trend swap, long-only, confirmation, reverse), and any change to the live account.

**Leftovers:** the test build and its profile entry are created for the run and removed once the decision is recorded. The spec and logs stay.

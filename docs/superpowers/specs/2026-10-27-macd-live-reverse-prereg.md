# MACD_Cross_EA (live, XAUUSD H1): reverse signal, pre-registration (2026-10-27)

**Why this variant.** The author of 3MACD says the reversed signal, combined with a grid, is the profitable version of that EA, and that the plain signal was not. The reverse has not been tested on its own. This variant tests the reversal without the grid, on the live EA. It was not derived from the 2019-21 losses, so Gate C is out-of-sample evidence.

**Question.** Does trading the opposite of the 16/26/9 crossover, with the live filters and exits, improve the live EA?

**Baseline (live, already run on 2026-10-27, not re-run):** MACD_Cross_EA with the chart settings in `mql5/profiles/MBT_DarwinexZero/chart01.chr`, XAUUSD H1, H4 EMA-200 trend filter, stop 0.5%, target 3.75%, risk 0.5%, max 3 positions. Results from `macdswap_base_XAUUSD_H1`:
- Gate A (2024-01..2026-10): 569 trades, PF 1.87, net +20,049 USD, DD 13.4%, 0 stop-outs.
- Gate B (joined with A): 961 trades, PF 1.73, net +23,761 USD, DD 14.6%.
- Gate C (2019-01..2021-12): 618 trades, PF 0.93, net -1,026 USD, DD 25.8%. FAIL.

**Variant (the only one):** a new input `InpReverse` (default `false` = live). With `InpReverse = true`, a bullish MACD cross becomes a sell signal and a bearish cross becomes a buy signal. The live filters then apply to the traded direction: the H4 EMA-200 check requires the close to be below the EMA for a sell, and above it for a buy. Stops, targets, break-even, trailing and position limits are unchanged, and apply in the traded direction.

**Setup:** Darwinex-Demo, XAUUSD H1, real ticks, $10,000 deposit, 1:100, Gates A (2024-01..2026-10), B (joined with A) and C (2019-01..2021-12) as docs/gates.md. The EA has no grid, so Gate B is the joined run.

**Data check:** H1 bar counts must match the expected totals for each window (about 17,100 for 2024-26 and about 18,700 for 2019-21). A window with fewer bars is inconclusive.

**Decision rule (fixed before the run):**
1. The variant passes Gates A, B and C.
2. On Gate A and on the joined Gate B, net profit and PF are both higher than the baseline's.
3. Max drawdown is not more than 1.0 point above the baseline's on either gate.

Adopt only if all three hold. Otherwise the live configuration stays unchanged.

**Not in this spec:** the grid, other instruments, other timeframes, the margin guard, the news filter, and any change to stops, targets or the live account.

**Leftovers:** the test build and its profile entry are created for the run and removed once the decision is recorded. The spec and logs stay.

# MACD_Cross_EA (live, XAUUSD H1): 34/144 confirmation filter, pre-registration (2026-10-27)

**Why this variant.** 3MACD's signal uses a slower MACD (34/144) alongside the faster ones. The 34/144 MACD is tested here as a confirmation of the live 16/26/9 crossover, not as a trend filter. The trend-filter swap (zero line of the H4 34/144 MACD in place of the H4 EMA-200) was closed in spec 2026-10-27-macd-live-trend-swap-prereg.md; this variant is different because it compares the direction of the 34/144 MACD on the signal timeframe, not its level against zero.

**Question.** Does requiring the 34/144 MACD to move in the same direction as the crossover improve the live EA?

**Baseline (live, already run on 2026-10-27, not re-run):** MACD_Cross_EA with the chart settings in `mql5/profiles/MBT_DarwinexZero/chart01.chr`, XAUUSD H1, H4 EMA-200 trend filter. Results from `macdswap_base_XAUUSD_H1`:
- Gate A (2024-01..2026-10): 569 trades, PF 1.87, net +20,049 USD, DD 13.4%, 0 stop-outs.
- Gate B (joined with A): 961 trades, PF 1.73, net +23,761 USD, DD 14.6%.
- Gate C (2019-01..2021-12): 618 trades, PF 0.93, net -1,026 USD, DD 25.8%. FAIL.

**Variant (the only one):** identical to the baseline, plus a new input `InpConfirm34` (default `false` = live). With `InpConfirm34 = true`:
- A buy cross is kept only if the MACD(34,144,1) main line on the signal timeframe is rising: its value at shift 1 is greater than at shift 2.
- A sell cross is kept only if that line is falling: its value at shift 1 is less than at shift 2.
- Both reads use the same closed bars as the crossover check. Nothing else changes.

**Setup:** Darwinex-Demo, XAUUSD H1, real ticks, $10,000 deposit, 1:100, Gates A (2024-01..2026-10), B (joined with A) and C (2019-01..2021-12) as docs/gates.md. The EA has no grid, so Gate B is the joined run.

**Data check:** H1 bar counts must match the expected totals for each window (about 17,100 for 2024-26 and about 18,700 for 2019-21); a window with fewer bars is inconclusive.

**Decision rule (fixed before the run):**
1. The variant passes Gates A, B and C. Unlike the long-only variant, this variant was not chosen from the 2019-21 losses, so Gate C is out-of-sample evidence here.
2. On Gate A and on the joined Gate B, net profit and PF are both higher than the baseline's.
3. Max drawdown is not more than 1.0 point above the baseline's on either gate.

Adopt only if all three hold. Otherwise the live configuration stays unchanged.

**Not in this spec:** other instruments (XAUUSD only), other timeframes, the trend-filter swap, the reverse signal, the margin guard, the news filter, and any change to stops, targets or the live account.

**Leftovers:** the test build and its profile entry are created for the run and removed once the decision is recorded. The spec and logs stay.

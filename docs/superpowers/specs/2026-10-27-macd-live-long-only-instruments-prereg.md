# MACD_Cross_EA long-only variant on EURUSD, GBPUSD and USDJPY (H1), pre-registration (2026-10-27)

**Why this spec exists.** The long-only variant (spec 2026-10-27-macd-live-long-only-prereg.md) was not adopted on XAUUSD H1, the live instrument. This spec asks whether the same variant holds on three other instruments. The live EA trades XAUUSD only, so a result here would not change the live EA. It would open a separate decision for each instrument.

**Question.** For each of EURUSD, GBPUSD and USDJPY on H1, does the long-only variant beat the live configuration?

**Baseline (live configuration, run now on each instrument):** MACD_Cross_EA with the chart settings in `mql5/profiles/MBT_DarwinexZero/chart01.chr`, H1, H4 EMA-200 trend filter, stop 0.5%, target 3.75%, risk 0.5%, max 3 positions, daily loss 4%, monthly loss 12%. These instruments have no baseline results yet, so the baseline is run on each one.

**Variant (the same as the XAUUSD spec):** identical to the baseline, except `InpAllowShort = false`. Sell signals are dropped before entry; buy signals are unchanged.

**Setup:** Darwinex-Demo, H1, real ticks, $10,000 deposit, 1:100, Gates A (2024-01..2026-10), B (joined with A) and C (2019-01..2021-12) as docs/gates.md. The EA has no grid, so Gate B is the joined run.

**Data check (before a result counts):** H1 bar counts must match the expected totals for each window, about 6,240 bars per year for a 24/5 forex instrument (about 18,700 for 2019–21 and about 17,100 for 2024–26). A window with fewer bars is inconclusive, not a pass or fail. The AUDUSD replication showed what a short history does.

**Decision rule (fixed before the run, applied per instrument):**
1. The variant passes Gates A and B.
2. On Gate A and on the joined Gate B, the variant's net profit and PF are both higher than that instrument's baseline.
3. Max drawdown is not more than 1.0 point above the baseline's on either gate.

An instrument passes only if all three hold. Gate C is reported for each instrument as a check, not as the decision evidence. The long-only idea came from XAUUSD's 2019–21 losses, so the other instruments are out of sample for all three gates.

**Two-rejects rule:** if two of the three instruments fail the decision rule, the third instrument is not run.

**Not in this spec:** adopting the variant on any instrument in the live account, other timeframes, the trend-filter swap (closed), and changes to stops or targets.

**Leftovers:** the test build and its profile entry are created for the run, and removed once every instrument has a verdict. The spec and logs stay.

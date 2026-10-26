# SessionReopenEA tweak study (pre-registration, 2026-10-26)

**Request:** "can you tweak SessionReopenEA so that it passes the gate before 2022". The EA (Code Base 77060, XAUUSD H1) buys gold at the first server hour after the CME
maintenance break (01:00 server, entry within 10 minutes), holds 2 hours, stops at 2.0 x the mean hourly range, skips Mondays, fixed 0.01 lot.
Baseline on Darwinex-Demo, real ticks, 10k: 2019-21 net -125.82 USD, PF 0.80, 604 trades, t -1.68 (fails the add-on bar); 2022-23 -34 USD (411 trades); 2024-26 +528 USD (490 trades).

## What the data say before any tweak (from the three existing reports, no new runs)
Mean return per trade (price move, long): 2019-21 **-0.60 bps**, 2022-23 **+0.01 bps**, 2024-26 **+2.88 bps**. Gold rose from about 1,990 to 5,430 inside 2024-26, so part of the 2024-26 figure is
drift (about +1 bps for a 2-hour holding). The author's own header claims +1.60 bps (t 3.42) over 11 years after the cost correction and says a 2.5-year window alone gives t +1.12.
In 2019-21 Friday was the weakest weekday (-2.3 bps, 146 trades); it is also the weakest in 2024-26 (+1.0 against +3.9 and +4.7 for Tuesday and Wednesday), but there is no market reason for it.

## The honest limit of this study
Choosing inputs because 2019-21 loses money makes 2019-21 an in-sample window; it stops being the out-of-sample Gate C. With 11 variants, one of them passing a coin-flip window by luck is likely.
So a variant counts only if it passes **every** window, and then also a **fresh window the study never looked at: 2016-01..2018-12 (F1)**. If F1 has less than 90% real-tick history it is reported as
"fresh window unavailable" and no variant can be called validated, only "not refuted".

## Variants (inputs only, fixed now; the list does not grow after results unless an amendment says so)
| id | change from the author's defaults | reason |
|---|---|---|
| v0 | none | baseline, re-run for the table |
| v1, v2, v3 | `InpHoldHours` 1, 3, 4 | the edge is said to sit in the first hour; holding time is the least certain input |
| v4, v5 | `InpStopAtrMult` 1.5, 3.0 | the header says a wider stop improved results at the true cost |
| v6, v7 | `InpEntryWindowMin` 3, 30 | enter closer to, or later after, the reopen |
| v8 | `InpEntryHour` 2 | negative control: the header says every other hour is flat |
| v9 | `InpSkipMonday` false | control: the weekly reopen is said to be noise |
| v10 | new input `InpSkipFriday` true (code change, default off) | the one pattern in the baseline reports; flagged post-hoc |

## Windows and rule (add-on bar, as in docs/gates.md)
2019-21 (S1): net > 0 and PF >= 1.0. 2022-23 joined with 2024-26: trades >= 150, PF >= 1.0, net > 0 in 2022-24 and in 2025-26. Then F1: hq >= 90%, net > 0, PF >= 1.0.
Reported per window: trades, net USD at the fixed 0.01 lot (it measures the size, not the strategy), PF, mean bps per trade and the t of the USD legs. A variant that passes everything
goes to the add-on joint test (`reports/portfolio/addon_joint.py`) at 1% and 2% sizing; otherwise the EA and its profile entry are removed again.

Runner: `reports/oct25/sr_tweak.py` (log `reports/oct25/sr_tweak.log`).

## Outcome (2026-10-26, evening): no variant passes 2019-21; stopped at the user's request
Net USD at the fixed 0.01 lot on 10k, real ticks, Darwinex-Demo; PF in brackets; "22-24" and "25-26" are the two halves of the joined 2022-26 run (trades >= 150, PF >= 1.0, both halves > 0).

| variant | 2019-21 net (PF) | 2022-23 net | 2024-26 net | joined 22-24 / 25-26 | 2019-21 | 2022-26 |
|---|---|---|---|---|---|---|
| v0 author's defaults | -125.8 (0.80) | -34.3 | +528.1 | -16 / +510 | fail | fail |
| v1 hold 1 h | -149.7 (0.70) | -134.9 | +121.1 | -150 / +137 | fail | fail |
| v2 hold 3 h | -93.8 (0.89) | -50.9 | +1,019.0 | -2 / +970 | fail | fail |
| v3 hold 4 h | -91.6 (0.92) | -27.6 | +938.8 | +16 / +895 | fail | pass |
| v4 stop 1.5 x range | -112.5 (0.82) | -18.4 | +429.4 | +4 / +407 | fail | pass |
| v5 stop 3.0 x range | -105.1 (0.83) | -20.2 | +576.9 | +9 / +548 | fail | pass |
| v6 entry window 3 min | -101.7 (0.83) | -37.5 | +116.1 | -24 / +102 | fail | fail |
| v7 entry window 30 min | -133.2 (0.79) | -39.2 | +544.3 | -17 / +522 | fail | fail |
| v8 entry hour 2 (control) | -150.4 (0.79) | -63.4 | +431.2 | -84 / +452 | fail | fail |
| v9 trade Mondays (control) | -252.7 (0.72) | -104.3 | +408.0 | -168 / +472 | fail | fail |
| v10 skip Fridays | -55.8 (0.88) | -37.4 | +493.7 | -9 / +465 | fail | fail |

- **Result:** 0 of 11 variants pass 2019-21; the best (v10, v3) still lose 56 and 92 USD with PF 0.88 and 0.92. The three that pass 2022-26 do so by +4 to +16 USD in 2022-24, so they carry no margin.
- **Controls:** v8 (the second hour after the reopen, which the header calls flat) made +431 USD in 2024-26 (+2.34 bps, t +1.33), against +528 USD for the real reopen: most of the 2024-26 profit looks like gold's drift (about 1,990 to 5,430 in the window), not a reopen effect. v9 (adding the weekly reopen) was clearly worse, in line with the header.
- **Not run:** the fresh 2016-18 window (F1) was never reached: the user said "skip SessionReopenEA" while the last variant had just finished, so the history check was stopped. No variant passed the earlier windows, so it was not needed to reject them.
- **Cleanup (leftovers rule):** `mql5/CB77060_EA.mq5` (with the `InpSkipFriday` addition), its `scripts/ea_profiles.py` entry, the MT5 copies and `Profiles/Tester/CB77060_EA.set` are removed. The runs stay in `reports/` and the runner and log in `reports/oct25/sr_tweak.py` and `sr_tweak.log`.
- **Verdict:** SessionReopenEA is closed for good: it fails Gate B marginally, fails Gate C (−126 USD, PF 0.80), and no input change repairs 2019-21.

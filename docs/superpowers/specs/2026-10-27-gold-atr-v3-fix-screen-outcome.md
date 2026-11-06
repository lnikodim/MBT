# NziCode Gold_ATR_Breakout_v3, corrected variant, on XAUUSD M1: outcome (2026-10-27): skipped, no verdict

**Spec:** `2026-10-27-gold-atr-v3-fix-screen-prereg.md`. **Runner:** `reports/oct25/gold_v3_screen.py`, log `reports/oct25/gold_v3_screen.log` (gitignored). **Probe records:** `reports/goldv3_probe_jan24_*` (one-month build checks, not gate results).
**Source:** https://github.com/NziCode/mt5-trading-bots/blob/main/Gold_ATR_Breakout_v3.mq5. The scratch copy has been removed; the spec records the changes.

## Outcome

The screen was skipped on the user's instruction ("disaster, skip it"). No gate ran to a verdict, so there is no pass or reject.

**What happened.** The full Gate A window was started. Within about 90 seconds, the tester's master and agent logs for the day had grown to 1.2 GB and 1.7 GB, and by the time the processes were stopped they were 2.3 GB and 2.9 GB. This EA trades in the thousands per month on M1, so the tester journal grows far faster than on the H1 screens. Full-window runs would have produced tens of gigabytes. The runner, the tester and the terminal were stopped, and today's logs were truncated.

**Lesson.** The one-month probe finished quickly, but its log growth was not measured against the full window. A full-window M1 run on a high-trade-count EA needs its log growth checked on a longer probe before the run starts.

## Cleanup

- `scripts/ea_profiles.py` restored to HEAD (the temporary entry was the only change).
- MT5 `MQL5/Experts/GoldTest/` (source, .ex5, compile log) and the tester `.set` removed.
- Partial config `goldv3_XAUUSD_M1_scr_20261027_214027.ini` removed.
- Scratch copy of the downloaded source removed.
- Kept: the spec, the runner, the log of the aborted run, the probe reports, and this outcome.

## Next

Nothing pending. If the EA is revisited, it needs a longer probe with a log-growth check, and a fresh spec.

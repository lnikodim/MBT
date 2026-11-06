# ScalpFlip v1.9 (anthonycdp/scalpflip-ea) as published, on EURUSD M5: outcome (2026-10-27): aborted, no verdict

**Spec:** `2026-10-27-scalpflip-v19-screen-prereg.md`. **Runner:** `reports/oct25/scalpflip_screen.py`, log `reports/oct25/scalpflip_screen.log` (empty: stopped before any gate printed). **Probe records:** `reports/scalp_probe_eur_m5_jan24_*` (one-month build check, not a gate).

## Outcome

The screen was stopped on the user's instruction ("stop and remove it, it's a disaster") while Gate A was still running. No gate reached a verdict, so there is no pass or reject.

**What happened.** Within about two minutes of the Gate A window starting, the tester's master and agent logs for the day had grown to about 116 MB and 128 MB, roughly 244 MB in total. The one-month probe had measured about 25 MB of log per month. The full window would run through many months at that rate, so it would reach the screen's 3 GB flood stop before it finished. I stopped the runner, the tester and the terminal, then cleared the day's logs.

**Caveat.** I haven't confirmed why the growth was faster than the probe suggested. The probe ran one month, which is not the same load as the full window. The probe's log-growth figure was not a reliable guide to the full run's growth.

## Cleanup

- `scripts/ea_profiles.py` restored to HEAD (the temporary ScalpFlip entry was the only change).
- MT5 `MQL5/Experts/ScalpFlipTest/` (source, .ex5, compile log) removed.
- The tester `ScalpFlip_v1_9.set` removed.
- Partial config `scalp_EURUSD_M5_scr_20261027_214806.ini` removed.
- Scratch copy of the downloaded source removed.
- The day's tester master and agent logs cleared.
- Kept: the spec, the runner, the empty runner log, the probe reports and this outcome.

## Next

Nothing pending on this EA. Any future run needs a full-window log-growth check before it starts, not a one-month probe alone.

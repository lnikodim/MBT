# NDX_Band_Breakout_EA v1.00: the production version and its live sets (2026-10-27)

User: "build the production version", then "adjust the profiles set for darwinex and ftmo accounts so that i don't need to adjust EAs inputs".
Origin: variant x8 of the NDX ORB3F study (`2026-10-27-orb3f-ndx-improve-prereg.md`): article 17745's ORB3 with the time-gate and 09:30 fixes, long only, bands x1.25, no entries in the first 60 minutes.
The article's materials are all-rights-reserved by MetaQuotes; the article invites readers to build on its code (an open licence point, as in the study).

## The EA (`mql5/NDX_Band_Breakout_EA.mq5`, on EACore.mqh like the other live EAs)
- **Signal (M1 bars, New York session):** bands = the session-open price x (1 +/- 1.25 x sigma), sigma = the mean over the last 14 days of |close of the bar at this minute / open of the session-open bar - 1|. Buy when a bar opens inside the bands and closes above the upper band,
  with the close above the M1 SMA(400), from 60 minutes after the open. Sells exist behind `Allow sells` (off).
- **Exit:** stop 1% of price, price closing back under the session VWAP (typical price x tick volume from the open), or flat at 22:55. One position at a time, re-entry allowed. A position left from before the open is closed.
- **From EACore:** risk sizing (% of balance, minimum-lot rule: never above the configured risk), spread guard, daily and monthly loss limits, the drawdown throttle, closed-trade CSV, late-bar and single-instance guards, restart safety.
- **Inputs** follow `docs/ea-inputs.md` (groups 1-7; `tests/test_ea_inputs.py` covers it through `make_live_sets.BASE`). Magic 271027, comment NDXBB, compiled defaults = the validated settings, 0.25% risk.

## Checks
**Parity with the study's x8** (production EA with the article build's settings: 4% risk, no EACore guards; 10,000 USD):
| window | trades | PF | net USD | drawdown |
|---|---|---|---|---|
| 2019-21 | 330 (x8: 330) | 1.23 (1.23) | +4,560 (+4,565) | 14.6% |
| 2022-23 | 239 (239) | 1.21 (1.21) | +3,202 (+3,202) | 28.6% |
| 2024-26 | 340 (340) | 1.24 (1.22) | +4,775 (+4,440) | 16.4% |
Trade counts are identical in all windows; the small 2024-26 gain is position-size rounding. The logic matches.
**The minimum lot matters at 10,000 USD:** one Darwinex NDX lot is about 10 USD per index point, so with NDX above about 25,000 even 0.01 lot risks more than 0.25% of 10,000 USD and EACore skips the trade (257 trades in 2024-26 instead of 340; 24 instead of 110 in 2026). It is not the spread cap (five caps gave the same result).
At the live account sizes nothing is skipped:
| deposit (live defaults) | 2019-21 | 2022-23 | 2024-26 | 2016-18 (31% real ticks) |
|---|---|---|---|---|
| 100,000 (Darwinex Zero) | 330 trades, PF 1.25, +2.6%, DD 1.0% | 239, 1.22, +2.0%, 2.0% | 340, 1.32, +3.0%, 1.1% | 105, 1.25, +1.1%, 1.1% |
| 50,000 (FTMO) | 330, 1.24, +2.5%, 1.0% | 239, 1.22, +2.0%, 1.9% | 340, 1.31, +2.9%, 1.1% | 105, 1.24, +1.1%, 1.1% |
That is about +1% a year at a 1-2% drawdown. **Add-on test with the production trades** (2022-26, 579 trades, own max DD 1.74% at the default size, daily rho -0.01, monthly +0.24), seven live EAs at 0.5% risk:
scaled to 1% / 2% own drawdown: +0.61 / +1.22 %/yr, max DD +0.06 / +0.13, worst month -10.55 / -10.65, return/DD 21.1 / 21.2 against 21.0: **rule passes**; at the default size the EA adds about +1.0 %/yr for about +0.1 points of drawdown.

## The live sets (`mql5/sets/<account>/NDX_Band_Breakout_EA.set`, chart profiles `MBT_DarwinexZero` chart08, `MBT_FTMO_2Step` chart07): nothing to type in
| | Darwinex Zero | FTMO 2-Step 50k |
|---|---|---|
| chart symbol, timeframe | **NDX**, M1 | **US100.cash**, M1 |
| risk | 0.25% of balance | 0.25% of balance |
| daily loss limit / throttle | 4% / off | 3% / 3% |
| clock inputs | open 16:30, flat 22:55 | same: both brokers run New York + 7 h (FTMO's trading-platform notices tie its clock to the US daylight-saving dates) |
| max spread / slippage, points | 100 / 30 (NDX quotes in 0.1: 10 / 3 index points) | 1,000 / 300 (US100.cash is taken to quote in 0.01: the same index points; looser, never tighter, if the digits differ) |
Everything else (magic 271027, bands, trend filter, stop, VWAP exit, long only) is the same. `tests/test_live_sets.py` pins these per account, the unique magic numbers and each broker's chart symbol. The generators wrote only the four new files; every existing set and chart came out identical.
The two new chart files were also copied into the local MT5 profile folders (new files only; the existing local charts, rewritten by MT5, were not touched).

## Not verified (cannot be from here)
- **FTMO's Nasdaq-100 symbol name and digits**: `US100.cash` is the usual FTMO name, not confirmed on the FTMO terminal; the spread and slippage caps assume 2 digits. Check the symbol in Market Watch before attaching the chart.
- **Live-only paths** (late-bar guard, single-instance lock, restart, catch-up of the trade log) are EACore's and untested with this EA in a tester.
- **VWAP uses tick volume**, which differs between a live feed and the tester's real ticks; the weights change a little, not the structure.
- **The first live day needs M1 history** (14 days of bars at the same minutes and the session-open bar); the EA stays out if a bar is missing.
- **The add-on gain is small and in-sample** against the tuned live set: about +1 %/yr at about 1.7% own drawdown, t +0.7 to +1.3 per window, one fresh window with mostly modelled ticks.

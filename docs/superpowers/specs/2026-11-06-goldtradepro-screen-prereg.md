# GoldTradePro (Gold Trade Pro MT5, decompiled port) on XAUUSD D1, source defaults: pre-registration (2026-11-06)

**Source:** `~/Downloads/TheGoldReaperEA-main/MQL5/Experts/GoldTradePro/Gold Trade Pro MT5.mq5` (5,800 lines), the same download as the Gold Reaper probed on 2026-11-04. It is decompiled MQL4 (copyright "战凌云", a QQ-group share, version 1.00). The bundle's `tools/port_gtp.ps1` ported it to MQL5 without touching the logic: it runs through `MQL5/Include/MQL4Compat.mqh`, a compatibility layer cut out of the Gold Reaper file. Variable and function names are decompiler output (`L_69_do_1A0`, `ccbsw_6`). The file has not been compiled or run here. Its own header says "Research only. Do not run on live funds", and the notes in the download say: XAUUSD, **D1**, $1,000 or more, "the default inputs work".

**Vendor.** Gold Trade Pro is a commercial EA by Wim Schrynemakers (Profalgo Limited, Malta, forexeasolutions.com), who also sells The Gold Reaper. His 2026 essay collection (`~/Downloads/wisdom-from-20-years-of-algorithmic-trading.pdf`, pages 46 and 80) lists it as "Breakout · XAUUSD · D1". It also says it gained +160% in its first 8 months live and then spent 300 days in drawdown, reaching 20% against a planned worst case of 30%. These are the vendor's own figures, not checked here, and they enter no verdict.

**Scan:** no WebRequest, DLL, `#import`, file access, GlobalVariables or date-based expiry. `OnInit` checks the account name ("schrynemakers" and "wim") or login 928189 (lines 797-826) and sets `L_305_bo_20C0`, which nothing reads, so the check does nothing. It matches the vendor's own name, which confirms whose EA this is. The only tester-specific branch turns off the info-panel refresh.

**Deploy rule.** The file is an unlicensed, decompiled copy of Profalgo's paid EA, so it fails the deploy condition in `docs/gates.md` (source, with no third-party licence or approval needed). This screen is **research evidence only**. Any live use would need a licensed copy from the vendor and the user's explicit decision. Running this copy live would breach the vendor's licence.

**Question.** Does GoldTradePro, with its source defaults, pass Gates A, B and C on XAUUSD D1 as an add-on for the live set?

**Strategy (read from the source).** Seven slots run on gold symbols: A and C to H, magic 1001 and 1003-1008, comments `Gold Trade Pro_XAUUSD_<slot>`. Slot B is switched off by a hidden flag (`L_11_bo_3C = false`). Each slot hardcodes its own settings in `OnTick` (lines 851-1254), and the inputs only switch slots on or off.
- **Entry.** Once per new H1 bar, a slot looks for a D1 swing high: a bar with no higher high among a set number of newer and older D1 bars, inside a lookback, at least a minimum distance above the ask, and the highest high since. It places a **buy stop** at an offset from that high. A swing low gives a **sell stop** the same way. The default offsets are negative, so both stops sit inside the swing range, before the level breaks. A slot keeps at most one pending order per side.
- **Stacking.** `L_186_bo_190C = true` skips the check for an open position in the same direction (lines 2585-2599). After a stop fills, the next H1 bar can arm a stop at another swing level, so one slot can hold several positions. There is no cap on open positions or on trades per day.
- **Exit.** Every order is sent with a server-side SL and TP. A trailing stop, checked once per new M1 bar, starts at a set profit, trails at a set distance and stops moving once the SL reaches a cap above the entry. Break-even, partial close, the time-based, high/low and "MagicTrail" stops and zone recovery are all off.
- **Pending life.** With `Virtual_expiration = true` the EA deletes an unfilled stop after the slot's pending life (48 to 480 hours, lines 1888-1906). Open positions have no time exit.
- **Filters.** No new orders from 00:00 to 00:04 server time (line 1419). A spread above `MaxSpread` (500 × $0.01 = $5.00) skips the bar (line 1740). There's a free-margin check. No session window, Friday close, news or NFP filter is on. There is no GMT or DST logic; everything runs on server time.
- **Off by default:** grid, martingale, averaging, recovery, hedging, randomisation, any daily loss or prop-firm limit.
- On a non-gold symbol, one generic slot runs with other defaults. That is out of scope here.

**Slot settings** (price distances in $0.01 of gold price; for a 2- or 3-digit quote the EA's "pip" is $0.01):

| Slot | Magic | Swing bars older / newer | Lookback (D1 bars) | Min distance | Buy / sell offset | Pending life (h) | SL | TP | Trail distance / start / cap |
|---|---|---|---|---|---|---|---|---|---|
| A | 1001 | 4 / 2 | 160 | 150 | −140 / −290 | 408 | 1300 | 1700 | 800 / 500 / 200 |
| C | 1003 | 18 / 3 | 180 | 900 | −130 / −30 | 408 | 1200 | 1800 | 750 / 600 / 200 |
| D | 1004 | 4 / 2 | 240 | 900 | −250 / −130 | 48 | 1300 | 1700 | 800 / 500 / 200 |
| E | 1005 | 15 / 3 | 230 | 550 | −170 / −70 | 480 | 600 | 1700 | 500 / 300 / 200 |
| F | 1006 | 12 / 2 | 50 | 700 | −210 / −60 | 384 | 1000 | 1900 | 600 / 500 / 1000 |
| G | 1007 | 17 / 2 | 110 | 150 | −40 / −140 | 240 | 1200 | 1600 | 600 / 200 / 4400 |
| H | 1008 | 7 / 2 | 20 | 250 | −130 / −120 | 432 | 600 | 4900 | 600 / 350 / 2000 |

**Chart timeframe D1.** The author names D1. Swing levels always come from D1 bars, but the "highest high since" test reads the chart's bars using the D1 bar index (lines 2345-2350, and the same for lows). Only on a D1 chart do the two refer to the same bars; on H1 the test would cover the last few dozen hours instead of the same days. So the screen runs on D1, which is also the author's setting.

**Build (the only changes).** The file is copied as `mql5/GoldTradePro.mq5`, because a space in an EA's name breaks the tester. `MQL4Compat.mqh` is copied next to it, and the include changes from `<MQL4Compat.mqh>` to `"MQL4Compat.mqh"` so it compiles from `Advisors`. `"GoldTradePro": {}` goes into `scripts/ea_profiles.py` (source defaults). The compile must give 0 errors and 0 warnings. A copy in the MT5 folder is made by hand, because `mql5/*.mq5` does not sync.

**Setup.** Darwinex-Demo, XAUUSD D1, real ticks, $10,000 deposit, 1:100, expert path `Advisors\GoldTradePro`. **All inputs stay at the source defaults:** `Risk = 0` (a fixed `StartLots_Input` = 0.01 lot on every slot), all seven slots on, `MaxSpread` 500, `Virtual_expiration` true. The report's input list must show `Risk=0` and `StartLots_Input=0.01`, because a tester `.set` file overrides recompiled defaults. The author's `.set` files (`Risk=999`, 2% per trade, and the "Lion_Prop" set) are not part of this screen. The EA needs a **hedging** account.

**Not stateful.** There's no grid, martingale or compounding at `Risk = 0`, and every position carries an SL and a TP. So Gate B joins a 2022-23 run with the Gate A run, as in `docs/gates.md`. Pending stops left at a window boundary are dropped by the split; that is accepted, as in the other joined screens.

**Probe before the gates (not part of any verdict).** Two weeks of XAUUSD D1 real ticks, 2024-01-02 to 2024-01-16. The probe checks:
- **speed:** over 900 s rejects the EA as too slow to screen;
- **log size:** over 100 MB triggers the strip-logging rule (Print calls renamed to NoLog only if the probe's trades are identical);
- **hedging:** two positions open at the same time in the deal list (a netting account makes every run invalid);
- **inputs:** the input values above appear in the report;
- **trades:** the EA trades at all.

Its numbers do not enter any verdict.

**Sizing for reporting.** A fixed 0.01 lot on $10,000. Every result shows net USD and total R. 1R for a trade is its slot's SL at 0.01 lot, found by magic number. At a 100-oz contract that is $6.00 (E, H), $10.00 (F), $12.00 (C, G) or $13.00 (A, D). The probe's first trade closed at its stop confirms the contract size; if it differs, R scales with it.

**Data check.** Expected XAUUSD D1 bars are about one per weekday: 740 for 2024-01..2026-10, 520 for 2022-01..2023-12 and 784 for 2019-01..2021-12 (minus a few holidays). A window more than 8% short is inconclusive, not a pass or a fail. Gate C also needs history quality of at least 90% real ticks.

**Decision rule (fixed before the run).**
- Gates A, B and C as in `docs/gates.md`. Gate B's trade floor is 150. Gate C is the add-on version (net > 0 and PF >= 1.0), because the goal is an add-on.
- Early reject at 150 or more trades with PF < 0.75.
- One instrument, so the two-rejects rule does not apply. No other instrument or timeframe is tried.
- After Gate C the result is "add-on test due". That test needs the account roster and its own spec.

**Loss-limiting variant (named now).** It runs only if the EA passes Gates A, B and C but fails its account profile or fails only on drawdown. The variant sets `L_186_bo_190C = false`: the author's own check, which allows no new stop while the slot already holds a position in that direction (one position per side per slot). That removes the stacking. The same gates run on it, the default and the variant are reported side by side, and the variant is marked as found after the default result. It is rejected if it fails.

**Disclosure (reported with every run, not a gate).** From the deal list:
- the most same-side positions open at once, overall and for each slot;
- the longest hold;
- positions held more than 30 days, with their net;
- positions closed only by the end of the test, with their net.

A **STUCK POSITIONS** note goes on the verdict line if either of the last two is non-zero.

**Known port caveats.**
- No run of the MT4 original exists to compare the port against.
- The slippage trail is dead code: line 3101 (3778 for sells) overwrites its lookup.
- `MODE_TICKVALUE` in the compatibility layer matters only for `Risk = 999`, which is not tested.
- The compatibility layer's market-closed gate (broker session data, behind `MODE_TRADEALLOWED`) is skipped in the tester (line 1410, `!IsTesting()`). It only acts live, so the tester cannot show its effect.

**Runner.** `screen_eval.py`, `crabel_eval.py` and `vwap_rsi_eval.py` (the gate evaluator the Dark family runner imports) are no longer on disk: `reports/` is gitignored, and `reports/crabel/` was emptied on 2026-11-05. They must be restored, or the evaluator rebuilt to the same rules, before the first gate run. The probe can run through `core/tester.py` alone.

**Not in this spec:** the author's `.set` files and other `Risk` modes, the generic non-gold slot, other instruments or timeframes, input sweeps, the live account and the add-on test.

**Commit status:** committed 2026-11-06 at the user's go-ahead, before any run (as gates.md requires).

**Leftovers.** On a reject verdict:
- `git rm` `mql5/GoldTradePro.mq5` and `mql5/MQL4Compat.mqh`;
- drop the `scripts/ea_profiles.py` entry;
- remove the MT5 copies (`Advisors\GoldTradePro.*`, `MQL4Compat.mqh` and `Profiles/Tester/GoldTradePro.set`);
- clear the tester logs.

The spec, the runner, the logs and the outcome stay. The download in `~/Downloads` is not touched.

# NziCode Gold_ATR_Breakout_v3, corrected variant, on XAUUSD M1: pre-registration (2026-10-27)

**Source:** https://github.com/NziCode/mt5-trading-bots/blob/main/Gold_ATR_Breakout_v3.mq5 (version 3.00, copyright "Nzicode"; the licence was not checked, and deploying would need it).
**Scan:** no `#import`, DLL, network or file access.

**Why a variant.** The file as published has three defects that change what it does:
1. **The EMA cross is inverted.** `CopyBuffer` arrays are not set as series, so index 0 is the oldest copied bar. `bullCross` fires on a bearish cross and `bearCross` on a bullish one. The MQL5 docs confirm the default order.
2. **The TP1 guard never works.** It checks a comment marker that is never written, so the partial close repeats on every tick the profit stays above TP1.
3. **TP2 is dead.** `TP2_Points` and `TP2_ClosePercent` are never used.

The user chose to screen a corrected variant (option 2).

**The only changes:**
1. **Indicator arrays** (`emaFast`, `emaSlow`, `rsi`) are dynamic and set as series, so index 0 is the current bar and index 1 the previous one. This is the author's own intent. The cross now fires on a real cross, and the momentum check reads the current bar, where the published file read the previous one.
2. **TP1 partial close** runs once per position, guarded by a per-ticket list. The comment marker is gone. At the default 0.02 lot the published file did not repeat the close (0.01 left over fails the `closeVol < vol` test), so this change is neutral at 0.02 lots. It protects larger lots.
3. **`TP2_Points` and `TP2_ClosePercent` removed.** Unused.

Compiled with 0 errors and 0 warnings.

**Unchanged:** every other input (LotSize 0.02, EMA 5/13, RSI 7 with thresholds 60/40, SL 150 points, TP1 100 points at 50%, TP3 350 points, breakeven after 100 points with a 20-point lock, trailing 100 points with a 30-point step, cooldown 15 seconds, max 150 trades a day, $80 daily loss limit on balance, max 3 positions, magic 20260710). Entries stay tick-level, with no new-bar rule.

**Probe runs before this spec.** A one-month build check (XAUUSD M1, January 2024) was run before this spec. It is not part of any gate. The first build (before the array fix) gave 4,453 trades and PF 0.74. The fixed build gave 4,076 trades, PF 0.66, net −1,432.40 USD and DD 14.4%. Those figures were seen before this spec was fixed. The screen below is the formal record.

**Question.** Does the corrected variant pass Gates A, B and C on XAUUSD M1, with its input defaults?

**Setup.** Darwinex-Demo, XAUUSD M1, real ticks, $10,000 deposit, 1:100, fixed 0.02 lot, source defaults. The EA has a daily loss cap, a cooldown and a daily trade cap, but no grid, martingale or compounding, so it is not stateful. Gate B is the 2022-23 run joined with the 2024-26 screen, as in `docs/gates.md`.

**Data check.** M1 bar counts are expected to be 60 times the H1 counts for the same window, using XAUUSD's own H1 counts where known:
- 2024-26: 16,268 H1 bars (XAUUSD) x 60 = 976,080.
- 2022-23: EURUSD's 12,480 H1 bars x 0.951 (XAUUSD's H1 ratio to EURUSD in 2024-26) x 60, about 712,000.
- 2019-21: EURUSD's 18,700 H1 bars x 0.951 x 60, about 1,067,000.

The probe's January 2024 window had 30,134 bars, 5% above the 2024-26 monthly rate (28,708), so the tolerance is 8%. A window more than 8% off is inconclusive, not a pass or a fail. The XAUUSD H1 shortfall question is still open with the user, and this run applies the same 8% rule.

**Decision rule (fixed before the run).**
- The EA passes if Gates A, B and C all pass (`docs/gates.md`).
- One instrument, so the two-rejects rule does not apply.
- If it passes all three but its drawdown is above 8%, one loss-limiting variant is run. It is named now: `DailyLossLimitUSD` tightened from 80 to 40 USD, an input the EA already has. The default and the variant are reported side by side, and the variant is rejected if it fails the gates.

**Not in this spec:** other instruments or timeframes, other inputs, a new-bar entry rule (a strategy change that would need its own spec), and the live account.

**Commit status:** uncommitted, like the variant source. The commit waits for the user's go-ahead.

**Leftovers.** After the verdict, the `GoldTest` MT5 folder, the tester `.set` file and the temporary `ea_profiles.py` entry are removed, along with the scratch copies. The spec, runner, logs and outcome stay.

# NziCode EURUSD_PriceAction_Stoch_v2, corrected variant, on EURUSD M15: pre-registration (2026-10-27)

**Source:** https://github.com/NziCode/mt5-trading-bots/blob/main/EURUSD_PriceAction_Stoch_v2.mq5 (copyright "mt5-trading-bots"; the licence was not checked, and deploying would need it).
**Scan:** no `#import`, DLL, file or process calls. One `WebRequest` to `http://127.0.0.1:5000/news_safe`, run only when `UseNewsFilter` is true. The default is false, and the screen keeps it false, so the EA makes no network call.

**Why a variant.** As published, the EA's exit ladder does not work. The TP1 and TP2 blocks check for the comment markers `tp1done` and `tp2done`, but the code never writes them. Once a trade is 20 pips in profit, the TP1 block closes 40% of the remaining volume on every tick, and the TP2 block does the same at 35 pips. A 0.1-lot position is cut to the 0.01 minimum within a few ticks. A test of the file as published would measure this bug, not the author's exit design. The user chose to screen a corrected variant (option 2).

**The only changes (both are fixes; nothing else is touched):**
1. **Partial-close state.** The markers are replaced by per-ticket lists (`tp1Done`, `tp2Done`). Each block runs once per position: TP1 moves the stop to break-even and closes 40%; TP2 closes 43% of the remaining volume. The 43% factor is kept as the author wrote it. Its comment says "~30% of original", but 43% of the remaining 60% is about 26% of the original. That mismatch is noted, not changed.
2. **Swing pivot.** `SwingLow(1)` and `SwingHigh(1)` need bars on the right of bar 1, which do not exist yet, and their copy starts at bar -9. They are now called with `SwingLookback + 1`: the newest pivot that has `SwingLookback` closed bars on each side (bar 11, reading bars 1 to 21). The strict test is unchanged. The cost is that the swing is confirmed 10 bars after it forms, so entries are later than the author's "fresh swing" intent.

Not changed: every input default (LotSize 0.1, SL 15, TP1 20, TP2 35, TP3 55, trailing step 10 and start 35, MaxTradesPerDay 3, MaxDailyLoss 30, cooldown 3, UseNewsFilter false, Magic 20002), the entry rules, the stochastic and EMA logic, the daily-P&L and news-filter code.

**Question.** Does the corrected variant pass Gates A, B and C on EURUSD M15, with its input defaults?

**Setup:** Darwinex-Demo, EURUSD M15, real ticks, $10,000 deposit, 1:100. Sizing is the fixed 0.1 lot, not percent risk, so the USD net and drawdown are fixed-lot figures. The EA has a daily loss cap and a cooldown but no grid, martingale, compounding or permanent drawdown stop, so it is not stateful. Gate B is the 2022-23 run joined with the 2024-26 screen, as in `docs/gates.md`. The test build is `NZTest\EURUSD_PriceAction_Stoch_v2_fix.ex5`, compiled from the variant source with 0 errors and 0 warnings.

**Data check:** M15 bar counts are expected to be about four times the H1 counts used in the H1 screens: 2024-26 about 68,400, 2022-23 about 49,920, 2019-21 about 74,880. The EURUSD H1 screen counted 17,108 against 17,100 expected, so the scaling holds. A window more than 8% off the expected count is inconclusive, not a pass or a fail.

**Decision rule (fixed before the run):**
- The EA passes if Gates A, B and C all pass (`docs/gates.md`).
- If it passes all three but its drawdown is above the 8% sizing level, one loss-limiting variant is run. It is named now: the EA's own `MaxDailyLoss` input, halved from 30 to 15 USD. The same gates run on it. The default and the variant are reported side by side, and the variant is rejected if it fails the gates.
- One instrument only, so the two-rejects rule does not apply.

**Not in this spec:** other symbols or timeframes, other inputs, any sizing change, the 43% factor, any further logic change, and the live account.

**Commit status:** this spec is not committed yet. The framework calls for a committed spec before any run, and the user has not asked for a commit, so the commit waits for their go-ahead. The spec file's content is fixed here, and its SHA-256 is recorded in the outcome.

**Leftovers:** the `NZTest` MT5 folder (source, .ex5, compile log), the tester `.set` file the runner writes, the temporary `ea_profiles.py` entry, and the scratch copies are removed after the verdict. The spec, the runner, the logs and the outcome stay.

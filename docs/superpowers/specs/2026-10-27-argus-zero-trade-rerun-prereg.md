# Argus zero-trade EAs re-run with the author's intended windows (pre-registration, 2026-10-27)

User: "yes, re-run the zero-trade EAs with the right windows". The first run made no trades on EURUSD (and GBPUSD) with the EA defaults, which are written in broker/server time (Darwinex server = New York + 7 h, UTC+3 in summer, UTC+2 in winter).

## The intended windows (from the author's own notes and source; UTC, then Darwinex summer server = UTC+3)
| EA | author's intent | Darwinex inputs (summer) | winter shift |
|---|---|---|---|
| ICT_Killzone_Macro | "pure London (7-9 UTC)" (`skills/strategy-ict-killzone/SKILL.md`) | KillzoneStart 10:00, KillzoneEnd 12:00 | one hour earlier |
| NY_Session_Reversal | London 08:00-12:00 UTC, NY monitoring 13:00-15:30 UTC (the NY open) | LondonStart 11:00, LondonEnd 15:00, NY_Start 16:00, NY_End 18:30 | one hour earlier |
| Liquidity_Sweep_FVG | "London Start 8 / NY Close 18" read as UTC (source labels them server time; the labels disagree with each other as server time) | StartHour 11, EndHour 21 | one hour earlier |
The EA defaults stay in the profile; the runs override only these window inputs (explicit `sets` in the runner), and nothing else changes.

## Honesty
- The windows are fixed from the author's notes before any run, not tuned on results.
- The winter shift is accepted: each window is one hour off for part of the year.
- A zero-trade result after this re-run would point to the signal logic, not the window. It would be reported as such.

## Rule and cells
Same as the Argus screen: 10 instruments (EURUSD, GBPUSD, USDJPY, USDCHF, USDCAD, AUDUSD, NZDUSD, EURJPY, GBPJPY, XAUUSD), two-rejects rule, Gates A, B, C as in docs/gates.md. Timeframes as before: M15 (ICT, NY Session Reversal), H1 (Liquidity Sweep FVG).

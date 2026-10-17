# Bagovino's 5/12 EMA + RSI 21 (pre-registration)

Date: 2026-10-17. User pasted a Forex Factory post by Bagovino ("the most successful Forex trading method to date",
"at least 85% accurate"): "On a 1 Hr chart, plot 5/12 EMA's. Plot RSI set at 21. When the 5/12 crosses up and the 21
RSI crosses above 50 you go long. When the 5/12 crosses down and the 21 RSI goes below 50 you short." Request:
"Backtest it on EURUSD 1H".

This is the parent of two systems already tested: ahmedabbas' EMA 5/12 + RSI 21 + CCI 80 (EMA_RSI_CCI_EA, 0 of 8
pass, PF 0.75-0.94) and TEB63's 5/12 EMA + RSI 20 scalp (0 of 48). Bagovino's version has no CCI, no exit and no stop.
It is tested with `EMA_RSI_CCI_EA` v1.01 (CCI off), not a new EA.

## Reading of the post
- Entry ("both crossed"): buy when, on the closed H1 bar, EMA 5 > EMA 12 and RSI(21) > 50, and that was not true on
  the bar before (whichever of the two crossed last triggers); sell mirrored. Both sides.
- Exit: the post gives none. Primary reading: stop and reverse, i.e. exit only on the opposite signal and reverse
  there. Second reading (cells 3-4): exit when the EMAs cross back or RSI is back across 50 (v1.00's indicator exit).
- Stop: the post gives none; the 1% sizing needs one. Protective stop 35 or 60 pips (as EMA_RSI_CCI). No target.

## v1.01 (defaults = v1.00 rules)
`InpCciPeriod` 0 = CCI off; `InpEntryMode` EMA_CROSS (v1.00) / BOTH_CROSSED; `InpExitMode` INDICATOR (v1.00) / REVERSE.
SIGNAL and EXIT log lines also carry the previous bar's RSI/CCI (`rsi2`, `cci2`).

## Step 0: checks
1. Parity: `scripts/ema_rsi_cci_selfcheck.py` (v1.00 defaults, unchanged) still prints SELFCHECK OK.
2. Bagovino check (EURUSD H1 2026-01..07, real ticks, cell 1 inputs, bar log on): every SIGNAL line is a fresh
   agreement (f1 vs s1 and rsi on the signal side, not both on the bar before); every EXIT line is the opposite
   fresh agreement; every entry has its SIGNAL line in its hour and the right side; stops 35 pips, no target; never
   more than one position; at least 90% of signal exits are followed by the opposite entry in the same hour.

## Stage A (`reports/bagovino/stage_a.py`, EURUSD H1, Darwinex real ticks, 2022-01-01..2026-10-01, 1% risk, 1:30)
| cell | exit | stop |
|---|---|---|
| `rev35` | stop and reverse | 35 pips |
| `rev60` | stop and reverse | 60 pips |
| `ind35` | indicator (cross back / RSI back) | 35 pips |
| `ind60` | indicator | 60 pips |
CCI off, entry BOTH_CROSSED, spread cap 30 points (3 pips), all else v1.01 defaults.
Gate A per cell: trades >= 150, tester PF >= 1.00, net R > 0 in both 2022-24 and 2025-26. Win rate is reported
against the post's "85%". Plateau for passers: slow EMA 10 / 15 and RSI 14 / 28 (mean PF >= 1.00, >= 3 of 4
profitable), then the joint rule against the 4-EA Darwinex control, pre-registered separately.

## Expectation
EMA 5/12 on H1 crosses often, so stop-and-reverse pays the spread on many whipsaws; the indicator exit cut winners in
EMA_RSI_CCI. Expected PF 0.80-1.00, win rate 30-45% (not 85%), 0 of 4 pass.

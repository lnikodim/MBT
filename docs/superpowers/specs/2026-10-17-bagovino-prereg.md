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

## Outcome (2026-10-17, Darwinex-Demo real ticks, log `reports/bagovino/stage_a.log`)
Step 0: v1.00 parity SELFCHECK OK; Bagovino check OK (146 entries, 126 signal exits, all reversed in the same hour).

| cell | trades | PF | win | tester DD | R 2022-24 / 2025-26 | avg win / loss | R per trade | Gate A |
|---|---|---|---|---|---|---|---|---|
| rev35 | 1,594 | 0.88 | 28.4% | 63.3% | -61.2 / -2.9 | +1.25 / -0.54 | -0.040 | fail |
| rev60 | 1,570 | 0.88 | 28.9% | 45.4% | -40.1 / -1.8 | +0.74 / -0.33 | -0.027 | fail |
| ind35 | 2,480 | 0.80 | 24.0% | 75.2% | -109.8 / -12.7 | +1.02 / -0.38 | -0.049 | fail |
| ind60 | 2,509 | 0.80 | 24.2% | 58.4% | -70.3 / -9.5 | +0.60 / -0.23 | -0.032 | fail |

**Gate A: 0 of 4 pass.** The win rate is 24-29%, not 85%. Stop and reverse is about breakeven before costs (it
needs about 30% wins at its win/loss ratio and gets 28-29%); the spread and commission on ~330 round trips a year
make it lose. The indicator exit is worse (it cuts the winners, as in EMA_RSI_CCI). The 60-pip stop is almost never
hit (57 / 46 times), so the result is the signal itself. The expectation held (PF 0.80-0.88).

### Verdict
Bagovino's 5/12 EMA + RSI 21 has no edge on EURUSD H1 2022-26. CLOSED with its descendants (EMA_RSI_CCI, TEB_MTF).

## Amendment 1 (2026-10-17, before any run): confirmation candle
User: "BUY signal only if the previous rules are confirmed AND the next candle is also bullish AND RSI is above or
equal to 55; SELL signal only if the previous rules are confirmed AND the next candle is also bearish AND RSI is below
or equal to 45. After applying the rules, backtest the EA again on 1H timeframe".
Reading: the previous rules fire on bar N (both crossed); the trade is taken at the open of bar N+2 only if bar N+1
(the next candle) closes in the signal direction (close > open for buys, < for sells) with RSI(21) on bar N+1 >= 55
(sells <= 45). Only the immediately next candle counts; otherwise the signal is dropped. In stop-and-reverse mode
the exit is the opposite confirmed signal. Code: v1.02 `InpConfirmRsi` (0 = off = v1.01).

Checks: (1) v1.00 parity selfcheck OK; (2) v1.01 parity: `rev35` without confirmation reproduces 1,594 trades and net
-52,856.68 exactly; (3) confirmation check (EURUSD H1 2026-01..07, real ticks, rev35 inputs + confirmation): every
SIGNAL line has the previous rules on the bar before (agreement at shift 2, not at shift 3), the confirming candle in
its direction and RSI >= 55 / <= 45; every EXIT line is the opposite confirmed signal; entries match their signal hour;
35-pip stops; one position; >= 90% of signal exits reversed in the same hour.
Stage A again (`reports/bagovino/confirm.py`): the same 4 cells and gate with `InpConfirmRsi` 55 (`c_rev35`, `c_rev60`,
`c_ind35`, `c_ind60`). Expectation: fewer trades (about a third), later entries; PF 0.80-1.00; 0 of 4 pass.

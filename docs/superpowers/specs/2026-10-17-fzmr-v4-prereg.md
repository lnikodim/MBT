# FZMR_Quant_Scalper v4: the user's "profitable" version (pre-registration)

Date: 2026-10-17. User: "let's bring back the initial version 4 of this EA which was profitable and analyse its core
logic", then pasted the v4 source (answer to my question; it was not on disk). Saved verbatim as
`mql5/FZMR_Quant_Scalper_v4.mq5` and installed under that name (the user's `FZMR_Quant_Scalper.mq5` v6 is untouched).
It has the same 24 inputs in the same order as the build the user ran at 13:11 today, the only run of the day that
ended above its deposit: EURUSD M15 2025-01-01..2026-10-01, real ticks, 100,000 -> 100,698.71 EUR (+0.7%), 215 trades.
That run used input values MT5 had kept from earlier builds (ER 15 / MaxER 0.45 / SL 2.5 ATR / TP 2.0 ATR / max hold
24 / hours 2-21 / spread cap 25), not the source defaults (ER 10 / 0.38 / SL 1.6 / TP 2.2 / hold 20 / hours 8-19 /
spread 15). It was never run on XAUUSD.

## What v4 is
Entry as v6: buy when the closed bar's z (close vs SMA 20 / StdDev 20) <= -2 and RSI(7) < 30, sell mirrored; Kaufman ER
<= MaxER; skip bars with range > 2 ATR(14). Trend: close beyond EMA 200, EMA 200 rising (falling) over 3 bars, close
within 6 ATR of EMA 200. ATR >= 40 points; spread <= cap; server hours start-end. Exits: stop and target in ATR; close
at any tick once the live z is back past +/-0.25 with at least 45 points of profit; close unconditionally after N bars.
Risk 1% x 0.9 of balance. One position at a time.

## Hypothesis
The z-target exit is the profile of the user's first versions, which lost on XAUUSD (PF 0.94 2022-24, 0.83 2025-26 on
their own runs), and the root cause found no bounce after the signal on gold M15 (spec 2026-10-17-fzmr-prereg.md). The
13:11 EURUSD run was breakeven after costs (+0.003 R per trade). Expected: XAUUSD cells PF 0.85-0.97 (fail); EURUSD cells
PF 0.90-1.05, failing at least one regime; most likely 0 pass.

## Step 0: is the pasted source the 13:11 build?
`v4_repro`: the pasted v4 with the 13:11 input values on EURUSD M15 2025-01-01..2026-10-01, real ticks, leverage 1:100
(as the user's run; our tester account currency is USD, theirs EUR, so lot sizes and money differ, signals do not).
Same build if >= 95% of the 215 entries of the 13:11 run match by open time (to the second) and side. Either way the
cells below test the pasted source; the match only says whether it is the code behind the +0.7%.

## Stage A (`reports/fzmr/v4_stage_a.py`, Darwinex real ticks, 2022-01-01..2026-10-01, M15, 1% risk)
| cell | inputs | symbol | spread cap |
|---|---|---|---|
| `v4_xau_cap15` | source defaults | XAUUSD | 15 (as written) |
| `v4_xau` | source defaults | XAUUSD | 150 |
| `v4_eur` | source defaults | EURUSD | 15 (as written) |
| `v4run_xau` | 13:11 values | XAUUSD | 150 |
| `v4run_eur` | 13:11 values | EURUSD | 25 (as run) |
The 150-point gold cap is the other gold EAs' cap (v4's 15 and the 13:11 run's 25 stop gold trading from October 2025:
Darwinex XAUUSD median entry spreads 22-26 points then, 46-89 in 2026). `v4_xau_cap15` shows what the code as written does.
Measurement: the source writes no CSV log, so trades come from the report's Deals table (profit includes commission and
swap); net R per trade = profit / (0.009 x balance before the trade), the EA's own risk amount; exit reasons from the
tester log (stop, target, EA close).
Gate A per cell: trades >= 150, tester PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
Plateau for passers: z threshold 1.75 / 2.25 and stop x0.75 / x1.25 (source defaults 1.2 / 2.0; 13:11 values 1.9 / 3.1);
mean PF >= 1.00 and >= 3 of 4 profitable. A plateau passer then gets an EACore port (CSV log) and the joint rule against
the 4-EA Darwinex control, pre-registered separately.

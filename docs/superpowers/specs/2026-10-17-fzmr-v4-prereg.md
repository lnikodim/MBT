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

## Outcome (2026-10-17, Darwinex-Demo real ticks, log `reports/fzmr/v4_stage_a.log`, runs `reports/fzmr_v4*`)
Step 0: the pasted source IS the 13:11 build: 215 / 215 entries match by time and side; the rerun ended +609 USD, PF 1.01,
+1.3 R (buys -7.9 R, sells +9.1 R): the user's "+0.7%" reproduced, and it is breakeven.

| cell | trades | PF | tester DD | R 2022-24 / 2025-26 | exits (n, avg R) | Gate A |
|---|---|---|---|---|---|---|
| v4 defaults XAUUSD, cap 15 | 74 | 1.07 | 6.4% | +1.1 / +1.5 | EA 42 +0.85, stop 32 -1.04 | fail (trades) |
| v4 defaults XAUUSD, cap 150 | 181 | 0.97 | 13.5% | -8.5 / +6.6 | EA 98 +0.81, target 3, stop 80 -1.07 | fail |
| v4 defaults EURUSD, cap 15 | 167 | 0.99 | 14.3% | -11.4 / +11.3 | EA 89 +0.80, target 5, stop 73 -1.06 | fail |
| 13:11 values XAUUSD, cap 150 | 771 | 0.90 | 29.3% | -18.9 / -7.8 | EA 429 +0.41, target 83, stop 259 -1.03 | fail |
| 13:11 values EURUSD, cap 25 | 547 | 0.97 | 14.8% | -5.6 / +1.3 | EA 282 +0.41, target 86, stop 179 -1.05 | fail |

**Gate A: 0 of 5 pass**; plateau and joint not reached. The expectation held: XAUUSD PF 0.90-0.97 (the cap-15 cell is
positive only on 74 trades), EURUSD 0.97-0.99, failing 2022-24 in every cell. The z-target exit wins 54-64% of trades
at +0.4 to +0.85 R against -1.05 R stops, which is breakeven before costs at best. The 2025-26 window the user saw is the
kind part: in 2022-24 every 150+-trade cell lost.

### Verdict
FZMR v4 as written is breakeven-to-losing on XAUUSD and EURUSD 2022-26; its "profit" was +0.7% on one EURUSD window.
CLOSED with the rest of FZMR; no retune. The source, profile and batch stay as tools.

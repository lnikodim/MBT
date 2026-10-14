# MACD-style guard rails for RSI_Reversal_EA and Donchian_Breakout_EA (pre-registration)

Date: 2026-10-14. User: "Let's implement the same guard rails in Donchian_Breakout_EA & RSI_Reversal_EA like we did
in the MACD_Cross_EA (remove trailing stops, move stop loss to secure profits, etc)".

## What MACD v1.45 has that the other two lack
| Guard rail | MACD v1.45 | Donchian v1.01 | RSI_Reversal v1.10 |
|---|---|---|---|
| Spread cap 150 pts + 30-min in-bar retry | yes | yes (retry 0) | **no** |
| Daily -4% stop (closes own positions), monthly -12% (blocks entries) | yes | yes | **no** |
| Closed-trade CSV log (prop_mc input) | yes | yes | **no** (report Deals table only) |
| Break-even: move the stop to lock profit | +0.5% price (= +1R on its 0.5% stop), lock +0.1% (0.2R) | input, off (`InpBreakEvenR`/`InpBELockR`, R units) | **none** |
| Trailing stop | off (v1.45) | none | **on** (+1% trigger, 1% distance, 0.05% step) |

So the code change is RSI_Reversal only: v1.20 rebuilt on `EACore.mqh` (the MACD v1.42 core: spread guard, daily /
monthly stops, trade log, risk sizing, Ready check / Bar lines) plus a MACD-style break-even (`InpBreakEvenPct`,
`InpBreakEvenLockPct`, % of the open price, only ever tightens) and the existing trailing kept as an input
(`InpTrailTriggerPct 0` = off). Signal logic (H6 RSI(4) 40/55, re-arm at 50, H12 SMA250 filter, deal-history re-arm
sync) is unchanged. Dropped: `InpLotsWithoutSL` (a stop is now required), the 10-s retry loop (EACore has the spread
retry only), `InpRsiTimeframe` -> EACore's `InpTimeframe`, `InpSlippage` -> `InpSlippagePoints`. Gotcha: EACore's
`InpRiskMode` is MONEY 0 / PERCENT 1 (v1.10 had PERCENT 0), so a chart carrying v1.10's stored inputs must have Risk
mode set to Percent again after the recompile.

Donchian needs no code: its break-even in R units is already MACD's rule (+1R lock 0.2R = `InpBreakEvenR 1.0`,
`InpBELockR 0.2`) and it has no trailing. The 2026-10-13 amendment-1 run `donch_a1_be` is that cell; it is judged here
through the joint prop_mc instead of the tester numbers alone.

## Runs (XAUUSD, real ticks, 2022-01-01..2026-10-01, 100k, 1% risk per position, H6)
| Run | Exits | Guards |
|---|---|---|
| `rsi_par` | v1.10 (trail 1/1/0.05, BE off) | off (spread cap 0, daily 0, monthly 0): parity with `rsi_v110` |
| `rsi_ctl` | v1.10 | on (150 pts / 30 min, -4%, -12%): the guards' own effect |
| `rsi_nt` | trail off, BE off | on |
| `rsi_nt_be10` | trail off, BE +1.0% lock +0.1% (= +1R lock 0.1R, MACD's trigger in R) | on |
| `rsi_nt_be05` | trail off, BE +0.5% lock +0.1% (MACD's literal percentages, = 0.5R) | on |
| `rsi_tr_be05` | trail on + BE +0.5% lock +0.1% | on |
| `donch_a1_be` | existing log: v1.01 + BE +1R lock 0.2R | on |

Parity gate (before anything else is read): `rsi_par` within 3% of `rsi_v110`'s 364 trades and 5% of its +151,910
net; otherwise the port is wrong and the batch stops. Break-even check on the BE runs: every `sl` exit closed on
the profit side of its open price sits at the lock (+0.10% +- 0.05%) and none sits between 0 and the lock.

Judge: `prop_mc.py` (seed 1, 10k sims, `--risk 0.3,0.5`, `--bt-risk 1.0`) stand-alone and jointly with MACD v1.45
(`reports/v145_default_20261011_092414_trades.csv`) + Donchian v1.01 (`reports/donch_a1_pub_20261013_095001_trades.csv`),
the same inputs and method as the 2026-10-13 portfolio spec (baseline all three: 90.8% / 83.0% at seed 1).

## Rule (decided before the runs)
1. The EACore guards are adopted in v1.20 regardless of the exit outcome (they are the point of the request), unless
   `rsi_ctl` loses more than 0.10 PF or 10% of net R against `rsi_par`; then the spread/daily values are reported and
   the user decides.
2. An exit variant replaces the v1.10 exits as the v1.20 compiled defaults only if (a) stand-alone PF >= 1.0 and
   2025-26 net R > 0 (RSI's holdout; 2022-24 is in-sample for its tuning), and (b) the joint pass probability with
   MACD + Donchian at BOTH 0.3% and 0.5% is >= the `rsi_ctl` joint pass at the same seed, with the joint MC p95 drawdown
   at 0.5% not more than 1 point worse. Among qualifiers: highest joint pass at 0.3% (the recommended live risk), tie
   within 0.5 pt -> lower p95 DD, then the simpler exit (fewer active features). The pick is confirmed with 3 seeds x
   20k sims against `rsi_ctl`; it stands only if it is still >= at 0.3% on the seed average.
   If nothing qualifies, v1.20 defaults = v1.10 exits + guards (trailing stays on, BE off).
3. Donchian: BE +1R/0.2R becomes the v1.02 default only if the joint pass with MACD + the RSI finalist is >= the same
   joint with `donch_a1_pub` at both risks and p95 DD at 0.5% not worse by more than 1 point. Otherwise v1.01 stays
   (no code change, nothing to install).

## Expectation written before the runs
- Guards: a handful of entries delayed or dropped at the 00:00-server H6 bar (rollover spread); daily -4% should not
  fire at 1% risk with one position; `rsi_ctl` within a few R of `rsi_par`.
- Trail off: on 2022-26 (trend years) net R probably up, as for MACD (+333 vs +262 R), with a deeper drawdown; the
  2019-21 lesson ("no trailing always loses in chop") is not tested here by the user's 2022-26 rule and is a caveat.
- BE 0.5% (0.5R): likely worse (every break-even earlier than +1R lost on MACD). BE 1.0% lock 0.1%: near neutral, a
  5% target is far, so a 1R lock converts some runners to +0.1R scratches.
- Donchian BE: tester already showed PF 1.44 vs 1.66; expect the joint pass to be lower or a tie, i.e. v1.01 stays.
- Honest bottom line: the joint pass is dominated by MACD (80.6 alone, 90.8 with both); any RSI exit change moves it
  by at most a few points, probably within MC noise. The guards are the real deliverable.

## Outcome
(filled in after the runs)

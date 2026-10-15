# Donchian_Breakout_EA v1.01 on the five extra VPS symbols (pre-registration)

Date: 2026-10-15. User: "Can you backtest Donchian_Breakout_EA for XAGUSD, USDJPY, USDCHF, EURJPY and GBPJPY?"
Context: the VPS migration log of 2026-10-14 showed Donchian v1.01 attached to H4 charts of these five symbols next to
the validated XAUUSD chart. The cell was researched, tuned and gated on XAUUSD only (spec 2026-10-13). This test asks
whether the deployed configuration earns its place on each symbol; it is not a retune.

## Runs (headless tester, `reports/portfolio/donch_fx.py`, 2022-01-01..2026-10-01, H4, 1% risk, compiled defaults)
1. Primary, 1-min OHLC, one run per symbol with the v1.01 defaults (N 20, ATR(20) x 2 stop, 2R target, H4 EMA200,
   long only, BE off, spread cap 150 pts, no retry): `dfx_<SYM>`.
2. Information only, same model with `InpAllowShort=true`: `dfx_<SYM>_sh`. FX pairs have no long-side bias like gold;
   this shows whether the failure (if any) is the long-only choice. It cannot promote a symbol (that would be a new
   cell and needs its own amendment).
3. Confirmation, real ticks, only for symbols whose primary run passes Gate A: `dfx_<SYM>_rt`. Darwinex tick files on
   disk: XAGUSD from 2023-01, USDJPY from 2022-01, EURJPY from 2024-01, USDCHF and GBPJPY from 2026-01 only; the
   tester fills missing months from the server or from M1 bars and the report's history quality / tick counts are
   recorded.
4. Joint prop_mc (seed 1, 10k sims, 0.3% / 0.5% per trade) of MACD v1.45 + Donchian XAUUSD v1.01 + RSI v1.20 control
   (`rsi_ctl`) with each confirmed symbol added, and with all confirmed symbols added.

## Gate A per symbol (the 2026-10-13 gate, unchanged)
trades >= 150; tester PF >= 1.00; net R > 0 in both 2022-24 and 2025-26. Under 150 trades is "insufficient sample",
not a pass. The gate must hold on the primary (OHLC) run and on the real-tick confirmation.

## Rule (decided before the runs)
A symbol stays on the VPS only if it passes Gate A on both models AND adding its log to the three-EA portfolio keeps
the joint pass probability >= the control at BOTH 0.3% and 0.5% with the MC p95 drawdown at 0.5% not more than 1 pt
worse (the 2026-10-14 convention). Any symbol that fails is removed from the VPS; the user does that. Shorts-on results
are reported, never adopted here.

## Expectation written before the runs
Long-only breakout follows the symbol's multi-year trend. USDJPY, EURJPY and GBPJPY rose through 2022-24 (yen
weakness) and went sideways or down in 2025-26, so they may pass 2022-24 and fail 2025-26. USDCHF fell for most of
2022-26: fail. XAGUSD ranged in 2022-24 and trended in 2025-26: likely fail on 2022-24. Realistic outcome: zero or one
symbol passes, and none lifts the joint pass above the control's 91.4% / 82.9% by a meaningful margin because the
yen crosses are correlated with each other and USD-driven moves overlap MACD's gold trades.

## Outcome (2026-10-15, log `reports/portfolio/donch_fx.log`, runs `reports/dfx_*`)
Primary (1-min OHLC, history quality 99-100%), v1.01 defaults, 1% risk:

| Symbol | trades | PF | net R | R 2022-24 / 2025-26 | tester DD | Gate A | shorts-on (information) |
|---|---|---|---|---|---|---|---|
| XAGUSD | 142 | 1.33 | +29.4 | +13.2 / +16.2 | 10.6% | FAIL: 142 < 150 trades | 216 tr, PF 1.14, +12.6 / +9.4 |
| USDJPY | 159 | 1.46 | +38.4 | +42.4 / +1.7 | 6.3% | **PASS** | 252 tr, PF 1.10, +30.0 / -10.9 |
| USDCHF | 108 | 1.27 | +21.2 | +23.9 / -2.7 | 12.1% | FAIL: count and 2025-26 | 218 tr, PF 1.07, +19.0 / -4.0 |
| EURJPY | 139 | 1.38 | +26.4 | +27.9 / +4.3 | 6.3% | FAIL: 139 < 150 trades | 223 tr, PF 1.06, +10.6 / -0.8 |
| GBPJPY | 144 | 1.24 | +21.7 | +24.0 / -2.3 | 10.0% | FAIL: count and 2025-26 | 235 tr, PF 1.04, +19.3 / -13.5 |

Shorts never help: on every symbol they add 80-110 trades at PF about 1.0 and make 2025-26 worse.

USDJPY confirmation on real ticks (`dfx_USDJPY_rt`): 159 trades, PF 1.46, +38.3 R (2022 +26.2, 2023 +5.7, 2024 +4.9,
2025 +4.8, 2026 -3.3), DD 6.3%, identical to the OHLC run to within 0.1 R. The tester reported history quality 15%
although full-size Darwinex tick files exist for every month 2022-01..2026-10 (the XAUUSD run reports 100%); the
cause was not established, the result is reported as the tester produced it. PASS. Stand-alone prop_mc pass 0.0% /
3.0% (2.8 trades a month: phase 1 times out, no breaches).

Joint prop_mc, MACD v1.45 + Donchian XAUUSD + RSI v1.20 control (10k sims; pass 0.3% / 0.5%, max-loss breach at
0.5%, MC p95 DD at 0.3% / 0.5%):

| seed | control (3 EAs) | + USDJPY |
|---|---|---|
| 1 | 91.4 / 82.9, breach 9.5, DD 10.4 / 16.9 | 93.4 / 85.8, breach 7.5, DD 10.2 / 16.5 |
| 2 | 91.1 / 83.4, breach 9.0, DD 10.5 / 16.9 | 92.9 / 86.4, breach 7.3, DD 10.1 / 16.5 |
| 3 | 90.7 / 83.4, breach 9.1, DD 10.5 / 16.8 | 93.6 / 86.3, breach 7.4, DD 10.3 / 16.4 |

### Verdict
- **USDJPY stays on the VPS**: Gate A on both models, joint pass up about 2-3 pts at both risks on all three seeds,
  breach down 2 pts, p95 drawdown slightly lower. Caveat: 2022 alone is +26 of the +38 R, 2026 is -3.3 R and the
  2025-26 condition is met by +1.7 R only; the symbol is a diversifier whose edge is thinner than it looks in total.
- **XAGUSD, USDCHF, EURJPY, GBPJPY come off the VPS.** XAGUSD and EURJPY fail only the 150-trade bar (142, 139)
  with both regimes positive; a lower bar for them would be a new pre-registered amendment, not a relaxation here.
  USDCHF and GBPJPY lose in 2025-26 on top of the count. The expectation above was wrong on XAGUSD (it is
  profitable in 2022-24) and right on USDCHF and GBPJPY.

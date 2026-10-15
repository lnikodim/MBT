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

# Cutting drawdowns at 0.5% risk, phase 1: offline levers (pre-registration)

Date: 2026-10-22. User: "suggest a plan for reducing the drawdowns at 0.5% risk", then "let's assume that we leave with
50k USD account of a 2-step challenge". No tester runs: all inputs are existing Darwinex-Demo trade logs, 2022-01..2026-10.

## The account: FTMO 2-Step, $50k (ftmo.com trading objectives, read 2026-10-22)
- **Profit target:** 10% in the Challenge, then 5% in Verification.
- **Max daily loss:** 5% of the initial balance, on **equity** (open P/L counts), recomputed at 00:00 CE(S)T. That is
  01:00 server on GMT+2/+3 servers.
- **Max loss:** 10% of the initial balance, static, on equity.
- **Days:** at least 4 trading days per phase, no time limit.
- **Account type:** Standard (1:100) restricts overnight, weekend and news holding only on the funded FTMO Account, not
  during the evaluation. Swing (1:30) has no such restriction. The live set holds positions for days, so Swing fits
  the funded stage.

**Model** (`scripts/prop_mc.py`): `--targets 10,5 --daily-loss 5 --max-loss 10 --min-days 4 --horizon 1095`. The
3-year horizon stands for "no time limit". 10k sims, seeds 1-3.
- Trade close times are shifted -1 hour so days are bucketed by FTMO's 00:00 CE(S)T.
- **Limit:** prop_mc sees closed trades only, so equity-based breaches are understated. The position cap lever below
  addresses that directly.

## Inputs: the live six-EA set
- **Gold 4-EA:** MACD_Cross H1, Donchian_Breakout H4, RSI_Reversal H6, MA_Channel H1. Darwinex logs of spec
  2026-10-21-donchiantrend-gold-joint, R = return / 1%.
- **Donchian_Trend USDJPY H4:** `dtrend_pick_20261021_073858`, R = return / 0.25%.
- **Invictus Monday GBPJPY:** `inv2_s0_mon`, R = return at the author's sizing.
- Per trade: open time, close time, R. CSV logs give R from profit / balance before the trade; reports give it from
  net / balance at entry.

**Diagnosis** (all at 0.5%, closed trades, 2022-26, before this pre-registration):
- Total +319%; worst drawdowns 15.6%, 14.4%, 14.0%, 13.6% and 12.4% of the initial balance.
- MACD H1 lost 5.8-11.3% in each of them, the largest share.
- Worst days -4.06% (2024-10-08) and -3.57%.
- The most positions open at once was 9.

## Levers (all at a headline 0.5% unless noted)
- **B, baselines:** every EA at 0.3% (B03, today's live setting) and every EA at 0.5% (B05).
- **L1, risk budget:** EA risk = weight x 0.5%. MACD weight in {0.5, 0.7, 1.0} x RSI weight in {0.7, 1.0}, others 1.0.
  Five combinations besides B05.
  - Live, this is only each EA's risk input.
- **L2, drawdown throttle:** `prop_mc --throttle X,0.5`, with X in {3, 4, 5}% below the phase high.
  - Live, this would be a shared EACore change (phase 2).
- **L3, open-position cap:** replay all trades in open-time order and skip an entry while N positions of the set are
  already open, N in {4, 6}.
  - At 0.5% this caps the risk open at once at 2% or 3%, inside the 5% daily limit even if every open position hits
    its stop.
  - Live, this is a shared EACore account-level check (phase 2).

## Selection (fixed now)
- **Train:** 2022-01-01..2025-01-01. **Holdout:** 2025-01-01..2026-10-01. **Full window:** reported.
- **Metrics:** P(pass both phases) (mean of seeds 1-3) and the max-loss breach rate (phase 1, mean of seeds).
- **Train pick:**
  - In each family (L1, L2, L3), take the setting with the highest train P(pass both) whose train max-loss breach rate
    is at or below B05's.
  - Across the families, take the best. If another family's best is within 0.5 points of it, take the simpler one
    instead. Simplicity order: L1 (no code), then L3, then L2.
- **Holdout check:** the pick must beat B05 in P(pass both) on all 3 seeds in the holdout, and must not raise the
  holdout max-loss breach rate (mean of seeds).
- **Reported for B03, B05 and the pick** (closed-trade replay, 2022-26):
  - full-window P(pass both) and the days to pass (phase 1, median);
  - the historical max drawdown and worst day at the headline risk.
- **Also reported:** whether the pick at 0.5% beats B03, in pass rate and days to pass, which is the point of moving to
  0.5%.

## Hypothesis
- **L1:** the MACD weight is the biggest single lever; the train pick is MACD 0.5-0.7.
- **L3:** N = 6 changes little (9 open at once is rare); N = 4 cuts some winners too.
- **L2:** helps the max-loss breach rate but slows passing.
- **Overall:** the pick improves B05's P(pass both) by 1-3 points, and the holdout check passes (about 60%).
- **B03 vs the pick:** B03 passes slightly more often but takes about 1.5 times longer.

## Decision rule
- **The pick passes the holdout check:** phase 2 implements it. L1 is risk inputs plus `.set` files; L2 and L3 are
  shared EACore code with a parity check that it is off by default. The IC Markets logs (spec 2026-10-18) confirm in
  phase 3.
- **Otherwise:** no lever is adopted. Staying at 0.3% stays the recommendation.

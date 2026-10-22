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

## Outcome (2026-10-22; log `reports/portfolio/dd_phase1.log`)
2,226 trades: MACD 955, RSI 362, MA_Channel 299, Monday 240, DonchianTrend 213, Donchian 157. The position cap kept
1,955 trades at N = 4 and 2,185 at N = 6.

| config (headline risk) | train P(pass both), max-loss breach | holdout P(pass both), seeds 1-3 (max-loss) |
|---|---|---|
| B03, all 0.3% | 93.8%, 3.3% | 99.8, 99.8, 99.7 (0.1%) |
| B05, all 0.5% | 79.8%, 11.7% | 96.5, 96.2, 96.1 (2.0%) |
| L1 MACD 0.5 / RSI 0.7 | 93.9%, 3.3% | 99.7, 99.5, 99.5 (0.2%) |
| L1 MACD 0.5 / RSI 1.0 | 92.1%, 4.3% | 99.4, 99.2, 99.2 (0.4%) |
| L1 MACD 0.7 / RSI 0.7 | 89.5%, 5.7% | 98.9, 98.7, 98.8 (0.6%) |
| L1 MACD 0.7 / RSI 1.0 | 87.9%, 6.7% | 98.5, 98.4, 98.5 (0.8%) |
| L1 MACD 1.0 / RSI 0.7 | 81.3%, 10.8% | 96.7, 96.8, 96.5 (1.8%) |
| **L2 throttle 3%** | **94.5%, 2.9%** | **99.8, 99.7, 99.8 (0.1%)** |
| L2 throttle 4% | 93.2%, 3.4% | 99.6, 99.6, 99.6 (0.2%) |
| L2 throttle 5% | 92.1%, 4.1% | 99.5, 99.5, 99.4 (0.2%) |
| L3 cap 4 | 74.3%, 15.2% | 97.3, 97.1, 97.2 (1.4%) |
| L3 cap 6 | 77.7%, 13.3% | 96.5, 96.0, 95.7 (2.0%) |

No daily-loss breaches in any configuration; the 5% daily limit on closed trades is not the binding constraint.

**Selection:**
- **Family bests:** L1 MACD 0.5 / RSI 0.7 (93.9%) and L2 throttle 3% (94.5%). Neither L3 setting stays at or below
  B05's max-loss rate.
- **Pick: L2 throttle 3%.** L1 is 0.6 points behind, outside the 0.5-point simplicity margin.
- **Holdout check: pass.** It beats B05 on all 3 seeds (99.7-99.8 vs 96.1-96.5), with max-loss 0.1% vs 2.0%.

**Full window 2022-26 and the closed-trade history:**
| config | P(pass both), seeds 1-3 | phase-1 days (median) | max-loss breach | history: total, max DD, worst day |
|---|---|---|---|---|
| B03 | 98.2, 98.0, 98.0 | 79 | 1.0% | +191.5%, 9.4%, -2.44% |
| B05 | 89.1, 89.4, 89.1 | 44 | 6.0% | +319.2%, 15.6%, -4.06% |
| **L2 throttle 3%** | **98.3, 98.1, 98.2** | **53** | **0.9%** | **+277.4%, 9.6%, -2.81%** |

**Decision: adopt the 3% drawdown throttle (phase 2).** At a 0.5% headline it passes as often as 0.3% (98.1-98.3 vs
98.0-98.2), with the same max-loss rate, in a third less time (53 vs 79 days to pass phase 1). Its historical max
drawdown is 9.6% against 15.6% unthrottled.

**On the hypothesis:**
- The pick was the throttle, not the MACD weight, but L1 MACD 0.5 / RSI 0.7 came within 0.6 points with no code.
- Caps: cap 6 changed little and cap 4 cut winners, as forecast; both were worse than B05.
- The throttle slowed passing (53 vs 44 days), as forecast.
- The gain over B05 was +9 points, far above the 1-3 forecast.
- B03 vs the pick: the same pass rate, with B03 1.5 times slower, as forecast.

**Limits:**
- Closed trades only: the live limit is on equity.
- In the simulation the throttle resets at each phase start; live, it needs an account-level peak.
- A fallback with no code: L1 (MACD 0.25%, RSI 0.35%, the others 0.5%) gives 93.9% train and 99.5-99.7% holdout.

**Phase 2, to pre-register:** an account-level throttle. Every live EA halves its risk while the account balance is at
least 3% of the initial balance below its highest closed balance.
- The four gold EAs get it from EACore.
- Donchian_Trend_EA and Invictus_GBPJPY_Monday_EA are standalone, so each needs the same small function.
- Parity with the throttle off must be exact.

## Phase 2: the account-level throttle in code (pre-registered 2026-10-22, before its runs)
User: "go ahead with phase 2".

**Code:**
- **`mql5/AccountThrottle.mqh`** (new, one implementation for all six EAs): `ThrottleFactor()`.
  - It reads the whole account deal history (every EA on the account) and returns `InpThrottleFactor` (0.5) while the
    closed trading P/L (profit + swap + commission + fee of buy and sell deals) is at least `InpThrottleDDPct` % of the
    initial deposit (the first balance deal) below its running high. Otherwise it returns 1.0.
  - Deposits and withdrawals do not move it. `InpThrottleDDPct` 0 (default) = off.
  - If the history cannot be read, it returns the factor (the safer side).
- **`EACore.mqh`:** `CalculateLots` multiplies the risk money by `ThrottleFactor()` and logs a line when throttled.
  This covers Donchian_Breakout_EA, RSI_Reversal_EA and MA_Channel_EA (versions 1.03, 1.22, 1.03).
- **`MACD_Cross_EA.mq5` v1.47:** it has its own `CalculateLots` (no EACore), and gets the same multiply and log line.
- **`Donchian_Trend_EA.mq5`:** the live v1.01 is now tracked (f8abfba). v1.02 multiplies its equity risk money by
  `ThrottleFactor()`.
- **`Invictus_GBPJPY_Monday_EA.mq5` v1.32:** lots x `ThrottleFactor()`.
- `scripts/install_ea.sh` also copies `AccountThrottle.mqh`, and the profiles get the two new inputs (off).

**P0, parity with the throttle off** (defaults). Each EA re-runs its baseline exactly (Darwinex-Demo, real ticks,
2022-01..2026-10, the baseline's own inputs and leverage):

| EA | baseline run |
|---|---|
| MACD_Cross H1 | `macdtf_h1_20261019_210429` |
| Donchian_Breakout H4 | `lowtf_donch_h4_20261019_212257` |
| RSI_Reversal H6 | `lowtf_rsi_h6_20261019_213004` |
| MA_Channel H1 | `lowtf_mach_h1_20261019_214347` |
| Donchian_Trend USDJPY H4 | `dtrend_pick_20261021_073858`, run under the old name DonchianTrend_EA, same inputs |
| Monday GBPJPY | `inv131_s0_mon_20261021_131936` |

- **Pass:** the same deals (open and close time to the minute, side, volume, net within $0.01) and 0 mismatches.

**P1, the mechanism with the throttle on** (`InpThrottleDDPct` 3): MACD_Cross with its baseline settings at 1% risk.
- For each entry, rebuild from the run's own trades the closed P/L at the entry time and its high so far. The trade
  is "flagged" if P/L is at least $3,000 below the high.
- The risk taken at entry is |open - stop| x volume x 100 oz / the balance before entry.
- **Pass:** at least 95% of trades have risk within +/-20% of 0.5% when flagged and of 1.0% when not, and at least one
  trade is flagged.
- **Reported:** net, max DD and trade count against the baseline.

**Amendment 1 (2026-10-22, after P0 and before P1).** P0 failed its "net within $0.01" rule for every EA. All
deal sequences match, but costs differ.
- **MACD_Cross:** 1,914 of 1,914 deals have the same time, side, volume and price. Swap differs on 319 deals (total
  -88,134.82 vs -87,936.29), commission on 120 (-38,688.66 vs -38,700.18), and gross profit on 60 out-deals closing at
  identical prices, i.e. positions matched to closes differently. The other EAs show the same pattern: Donchian 138 of
  314, RSI 195 of 724, MA_Channel 192 of 598, Donchian_Trend 164 of 426.
- **Most likely cause:** the tester applies the broker's current swap and commission settings, so a run made today does
  not reproduce one made on 10-19 or 10-21.
- **P0 is therefore re-based:** each EA's pre-throttle build (the sources at f8abfba for Donchian_Trend, ca2840e~1 for
  the others, with that EACore) runs today with the same inputs. The throttle-off build must match it deal for deal:
  time, side, volume, price, and net within $0.01.
- **This decides whether the code is neutral.** The difference against the old baselines is reported as cost drift.
- The pre-throttle builds are restored to the current ones afterwards, checked by MD5.

**Decision:** if P0 and P1 pass, phase 3 checks the throttle on the IC Markets gold logs (offline, the phase 1 method).
Then the live settings are written up as `.set` files for the user to deploy: headline 0.5% (Monday GBPJPY 0.010 lot
per $1k) plus throttle 3% / 0.5.

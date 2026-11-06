# Atlas Funded 2-Step Daily $50k: replacing the FTMO rules (pre-registration, 2026-10-29)

Date: 2026-10-29. User: "I've decided to take a spin on another prop firm Atlas Funded, instead of FTMO ... So remove the leftover rules for FTMO and create new ones for Atlas Funded. The account I want to get funded is 50k USD 2-step challenge". Decisions in the planning step (same day): swap the configuration **and** calibrate the live settings against the new rules; seven EAs on the Atlas account, NI225 held back; the funded-stage rules are recorded and measured, not enforced. No tester runs: every input is an existing Darwinex trade list.

## The account: Atlas Funded 2-Step Daily, $50k, Forex, MT5 (user's checkout screenshots, 2026-10-29)

| | Challenge (step 1, step 2) | Funded |
|---|---|---|
| Profit target | $3,500 (7%), $2,000 (4%) | none |
| Max overall loss | $4,000 = 8% of the initial balance, **static** | same |
| Max daily loss | $2,000 = 4% | same |
| Min trading days / trading period / inactivity | 3 / unlimited / 30 days | same |
| Expert advisors, consistency, margin use, Atlas Protector | allowed, none, none, none | allowed, none, up to 80% of margin, 2% open loss |
| News trading | allowed | restricted +-5 min |
| Short trades | allowed | trades under 3 min: profit removed |
| Payouts | | 90% split, 14-day cycle, $1,500 buffer, $1,000 gross cap on the first 3 |

The account type is "Daily" (payouts any day), $295.55 list price, 1 account.

**Not in the screenshots (assumed, to confirm in the "?" tooltips or on the Atlas terminal):**
- **Daily-loss basis and reset time.** Assumed equity (open P/L counts), the strictest reading, as FTMO's was. The reset time is unknown, so the calibration reports two day boundaries (below).
- **Atlas Protector** (third-party reviews, unverified): at a floating loss of 2% of the initial balance Atlas closes all positions (a soft breach), cuts the profit split to 50%, and a second trigger closes the account. Used only to size the measurement in step 4.
- **Symbols, digits and server clock.** The NDX, XAUUSD, USDJPY and GBPJPY names, their price scale, and whether the clock is New York + 7 h (Darwinex and FTMO were) are unknown. NDX_Band_Breakout, Invictus Monday and the H4/H6 gold EAs depend on the clock. NI225 may not exist there.

## What the FTMO set-up was, and what replaces it

FTMO: targets 10%/5%, max loss 10% static, daily 5% on equity at 00:00 CE(S)T, 4 minimum days. Live settings derived from it (spec 2026-10-22-dd-reduction-phase1-prereg.md): 0.5% headline risk, drawdown throttle 3% (factor 0.5), EA daily stop 3% (60% of the 5% limit).

Atlas is tighter on both limits (8% max loss against 10%, 4% daily against 5%) and on the targets (7%/4%), so the FTMO values are not assumed to fit. Active FTMO config is replaced by Atlas config:
- `scripts/make_live_sets.py`: account `atlas_2step_50k` with the Atlas limits in one constant, `NDX_BROKER` entry renamed, NI225 left out until confirmed; EA daily stop 2.5% (the same 60% of the limit) and throttle 3% as the starting values.
- `scripts/make_live_profiles.py`: profile folder `MBT_Atlas_2Step`; the Atlas NDX symbol is a placeholder (`NAS100`, 2 digits), to confirm on the terminal.
- `scripts/prop_mc.py`: defaults become Atlas (`--targets 7,4 --daily-loss 4 --max-loss 8 --min-days 3`).
- `tests/test_live_sets.py`: renamed, plus one test that the account's EA daily stop is below the 4% limit and its throttle below the 8% limit.
- Seven EA headers and `#define` comments say Atlas instead of FTMO; the define values change only if the calibration below changes them.
- `mql5/sets/ftmo_2step_50k/` and `mql5/profiles/MBT_FTMO_2Step/` are removed (also the installed copy in the local MT5); their Atlas replacements are generated.
- Not touched, on purpose: the historical FTMO specs and the experiment runners `reports/portfolio/dd_phase*.py`, which record what was tested.

## Calibration (read-only, `reports/portfolio/atlas_phase1.py`, from `dd_phase1.py`)

**Model** (`scripts/prop_mc.py`): `--targets 7,4 --daily-loss 4 --max-loss 8 --min-days 3 --horizon 1095 --sims 10000`, seeds 1-3. The 3-year horizon stands for "no time limit". Static max loss (no `--trailing`).

**Inputs, the seven live EAs.** Closed trades 2022-01..2026-10 from the validated Darwinex runs in `make_live_sets.py` (`BASE`): MACD_Cross, Donchian_Breakout, RSI_Reversal, MA_Channel (their trade CSVs), Donchian_Trend (`dtrend_pick_20261021_073858`), Invictus Monday (`inv131_s0_mon_20261021_131936`), NDX Band Breakout (`ndxbb_DZ100k_s0a_20261027_072752` + `ndxbb_DZ100k_scr_20261027_072850`). Each trade is expressed as % of the account at today's live sizing: gold EAs and Donchian_Trend 0.5%, Invictus 0.006 lot per $1,000, NDX 0.25%. The grid scales all of them together by (headline risk / 0.5), so the headline is the single risk knob: at 0.4 the gold EAs run 0.4%, NDX 0.2% and Invictus 0.0048 lot per $1,000.

**Grid (fixed now).** Headline risk {0.3, 0.4, 0.5}% x throttle {off, 2, 3, 4}% below the phase high (factor 0.5): 12 settings. Today's setting (0.5%, throttle 3%) is the reference.

**Day boundary.** Primary: the FTMO day (trade close times shifted -1 h, i.e. 00:00 CE(S)T = 01:00 server). Sensitivity: server midnight, because Atlas's reset time is unknown. The pick uses the primary; the sensitivity is reported and any setting whose max-loss breach or daily breach differs by more than 2 points between the two is flagged.

**Selection (fixed now).**
- **Train:** 2022-01-01..2025-01-01. **Holdout:** 2025-01-01..2026-10-01. **Full window:** reported.
- **Metrics:** P(pass both steps) and the phase 1 max-loss breach and daily breach rates (means of seeds 1-3).
- **Train pick:** among settings whose train max-loss breach rate is at or below 2%, the highest train P(pass both). Ties within 0.5 points go to the simpler setting; simplicity order: throttle before risk (a lower throttle threshold is the smaller change; the 0.5% headline is the last to give up).
- **Holdout check:** the pick replaces 0.5% / 3% only if its holdout max-loss breach rate is not worse than that setting's. Otherwise 0.5% / 3% stays and the failure is reported.
- **No setting reaches the 2% cap:** report it and take the lowest train breach rate for the user to decide; nothing is adopted silently.
- **Reported for the reference, the pick, and the lowest-breach setting** (closed-trade replay, 2022-26, simple sum of % of the initial balance): P(pass both), days to pass (phase 1, median), historical max drawdown, worst day, and net profit as total % and in USD at $50k (and the R total at the headline), per the standing rule to always show total net profit.
- **The EA daily stop is not tested by the model** (it needs intraday equity). It stays at 2.5% by the 60%-of-limit rule; the daily breach column is the check on that number.

**Limit.** prop_mc sees closed trades only; equity-based breaches (floating loss) are understated, and the 8% static limit is measured on equity.

**Hypothesis (written before the run).** The reference (0.5%, throttle 3%) shows a train max-loss breach rate above 2% (my guess 5-10%, against 2.9% with FTMO's 10% limit), so the pick is a lower setting, most likely 0.3-0.4% with a 2-3% throttle, and P(pass both) falls by several points against FTMO's 94.5%. The day-boundary sensitivity changes the daily breach by under 1 point.

## Funded-stage rules: measured, not enforced

On the same trade lists:
1. **Short trades.** Per EA and in total, the share of trades held under 3 minutes and the share of net profit they carry (this profit would be removed on the funded account).
2. **Open-loss exposure.** The largest sum of per-trade risk open at the same time (each position's risk at its live sizing, replayed by open and close time), and the share of days it exceeds 2% of the account (Atlas Protector's trigger, if the reviews are right), at the reference and the pick. Invictus is sized by lot, so it has no risk percentage: its average losing trade (% of the account) stands in for its risk (amendment, 2026-10-29, written before the run).
3. **News +-5 min** is not measured (needs an economic calendar); it is an open item.

No EA code changes follow from these numbers in this task; the user decides on enforcement after seeing them.

## Verification

`python3 -m pytest tests -q`; the Darwinex Zero sets and profiles are unchanged in `git diff`; the seven EAs compile with 0 errors and 0 warnings and match their MT5 copies; `grep -ril ftmo scripts tests mql5` returns nothing except the files listed above as kept.

## Not in this spec
NI225 on Atlas; the Atlas symbol names and clock (to confirm on the terminal); a news filter; an account-level open-loss guard; the live account and any funded-stage settings.

**Commit status:** uncommitted, like the other specs (the user has not asked for a commit).

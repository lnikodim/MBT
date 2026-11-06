# Atlas Funded 2-Step Daily $50k: outcome (2026-10-29)

**Spec:** `2026-10-29-atlas-funded-2step-prereg.md`. **Runner:** `reports/portfolio/atlas_phase1.py`, log `reports/portfolio/atlas_phase1.log`. No tester runs; 2,805 closed trades of the seven live EAs, 2022-01-03..2026-09-30.

## Result: the FTMO setting does not fit Atlas; the pre-registered pick is adopted

Rules: 7%/4% targets, 8% static max loss, 4% daily loss, 3 minimum days; day boundary = the FTMO day (00:00 CE(S)T), 10,000 sims, seeds 1-3.

| Headline risk, throttle | Train P(pass both) | Train max-loss breach | Holdout P | Holdout max-loss breach |
|---|---|---|---|---|
| 0.5%, off | 68.9% | 15.6% | 92.4% | 4.1% |
| **0.5%, 3% (the FTMO setting)** | 88.1% | **6.6%** | 98.6% | 0.7% |
| 0.5%, 2% | 89.8% | 5.5% | 99.1% | 0.5% |
| 0.4%, 3% | 93.3% | 3.6% | 99.6% | 0.2% |
| 0.4%, 2% | 94.7% | 2.8% | 99.7% | 0.1% |
| 0.3%, 4% | 96.7% | 1.7% | 99.9% | 0.1% |
| 0.3%, 3% | 97.5% | 1.3% | 99.9% | 0.0% |
| **0.3%, 2% (pick)** | **98.2%** | **0.9%** | **100.0%** | **0.0%** |

(The other grid cells are in the log. Daily breaches are 0.0% everywhere except 0.5%/off (3.2%) and 0.5%/4% (0.9%) on the train window.)

- **Train pick:** 0.3% with a 2% throttle, the highest train P(pass both) among the settings at or below the 2% max-loss cap; no ties within 0.5 points.
- **Holdout check:** max-loss breach 0.0% against 0.7% for the reference, so the pick replaces it.
- **Day-boundary sensitivity (server midnight against 00:00 CE(S)T):** no setting differs by more than 2 points; the reset time does not change the choice.

### Full window 2022-26, closed trades (net as the sum of per-trade % of the account; USD at $50,000)

| | Reference 0.5% / 3% | Pick 0.3% / 2% |
|---|---|---|
| P(pass both steps), seeds 1-3 | 95.0, 94.9, 94.6% | 99.6, 99.7, 99.6% |
| Days to pass step 1 (median, calendar) | 35 | 62 |
| Max-loss breach (step 1) | 2.6% | 0.2% |
| **Net profit** | **+279.1% = +139,558 USD (+558R)** | **+164.9% = +82,470 USD (+550R)** |
| Closed-trade max drawdown | 9.7% (over Atlas's 8%) | 6.0% |
| Worst day | -2.85% | -1.71% |

The R totals are almost equal because the pick trades smaller; the dollar figures fall with the size. The reference's historical 9.7% drawdown on closed trades is already above the 8% static limit.

## What was changed

- **Live values for the Atlas account** (`mql5/sets/atlas_2step_50k/`, 7 EAs, no NI225): gold EAs 0.3% risk, Donchian_Trend 0.3%, NDX 0.15%, Invictus 0.0036 lot per $1,000 (all x0.6 of the Darwinex Zero values), drawdown throttle 2% (factor 0.5), EA daily stop 2.5%. Profile `mql5/profiles/MBT_Atlas_2Step/` (installed in the local MT5 `Profiles/Charts`). Atlas limits are in `ATLAS` and the scale in `RISK_SCALE` in `scripts/make_live_sets.py`.
- **FTMO removed:** `mql5/sets/ftmo_2step_50k/` and `mql5/profiles/MBT_FTMO_2Step/` (also the installed local copy), the FTMO account, symbol and caps entries in the generators, the FTMO defaults of `scripts/prop_mc.py` (now Atlas: 7,4 / 4 / 8 / 3 days), the FTMO test names, and the FTMO annotations next to the `#define` lines of the seven EAs.
- **Tests:** 105 pass. New: the account's EA daily stop is below 4% and its throttle below 8%; the risk inputs follow the account scale.
- **Darwinex Zero:** all sets and profiles unchanged except one comment line in the NDX set (the chart label no longer says "US100.cash on FTMO").

## Funded-stage rules, measured on the same trade lists (not enforced)

- **Trades under 3 minutes** (profit removed on funded accounts): 80 of 2,805 (2.9%), almost all NDX Band Breakout (79 of 579, 13.6%); the winners among them add up to +0.15% of the account, 75 USD at $50k over 4.75 years. The other six EAs have none (MACD_Cross one loser). Not material.
- **Open risk at once** (sum of per-trade risk of the open positions, an upper bound for the floating loss that Atlas Protector's 2% would watch): the reference peaks at 4.5% and exceeds 2% on 301 days (25.4% of days with a position open); the pick peaks at 2.7% and exceeds 2% on 29 days (2.4%). The real floating loss is below the risk sum unless every open stop is hit, so these are upper bounds, not floating-loss measurements; Invictus's risk is a proxy (its average losing trade, 0.17% at the reference size).
- **News +-5 min:** not measured (needs a calendar). Open item before the funded stage, together with the news rule's wording on Atlas (does it cover opening, closing, or holding).

## Limits and deviations

- Closed-trade model only: equity-based breaches (floating loss) are understated, and the 8% limit is on equity. Daily breach rates of 0.0% are on closed trades; the EA daily stop at 2.5% is the guard for the intraday case and was not tested.
- The NDX trades come from a run with the NDX EA's own 3% throttle on, and the gold runs at 1% had no throttle; scaling to live sizing is linear. Invictus has no risk % (proxy above).
- **Unconfirmed on the Atlas terminal:** daily-loss basis and reset time, symbol names and digits (the NDX symbol `NAS100` and its spread cap 1000 / slippage 300 are placeholders), the server clock (the NDX, Invictus and H4/H6 EAs assume New York + 7 h), and whether NI225 exists (held back; the Nikkei EA is Darwinex-only for now).
- **Plan deviations:** (1) the compiled `#define` defaults of the seven EAs were not changed and the live `.ex5` files were not recompiled or overwritten (the Mac's MT5 terminal is open and may run them); the sets carry every input, and an EA attached to an Atlas chart without its set would run the 2026-10-22 defaults (0.5%, throttle 3%), which this calibration shows are too aggressive for Atlas, so always load the Atlas set. The seven edited sources compile with 0 errors and 0 warnings in a scratch folder (removed afterwards). (2) The version-history lines in six EA headers ("v1.03 ... live defaults = FTMO 2-Step") were kept as history. (3) The installed local Darwinex Zero chart profile differs from the repo's in seven of eight charts and was left untouched, so `make_live_profiles.py --install` was not used; the Atlas folder was copied by hand.
- Spec amendment: Invictus's risk proxy, written before the run. The funded-stage measurements and the day-boundary sensitivity were run as specified.

**Commit status:** uncommitted, like the other specs.

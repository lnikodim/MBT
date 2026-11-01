# Account rules and the gates: amendment (2026-11-01)

**Parents:** `docs/gates.md` (post-Gate-C part rewritten), `2026-10-29-atlas-funded-2step-prereg.md` and `-outcome.md`, `2026-10-31-atlas-moon-rea-overlay-prereg.md`. Effective from this date; earlier outcomes stay as written unless re-scored below. No MT5 tester runs.

## Why
Until now Atlas's limit was read as an "8% account drawdown" measured peak-to-trough on a combined path. The user's statistics screenshot of the live Atlas challenge account (balance $50,029.50) shows the rules as they are: a **static floor, breach at $46,000.00** (8% of the initial $50,000, it does not trail the peak); a **daily limit of $2,000 below the day-start balance** ("breach at $48,029.50"), **reset at 12:00 AM UTC**; profit target $3,500, 3 minimum days, no consistency rule. The user also pointed out that Darwinex Zero's calibration has no hard percentage cap; the official docs agree (calibration: 25 risk-equivalent decisions over at least 15 trading days, "no minimum return", "NOT a test or an assessment that you pass or fail"; the DARWIN is re-scaled to a 6.5% VaR; the DarwinIA rating weights 22% current month, 67% cumulative six-month return, 11% six-month max drawdown). Sources: darwinexzero.document360.io (initial-training-phase, rating), darwinexzero.com/blog/calibration-phase-explained.

**Server clock.** The two terminal screenshots show Atlas's Market Watch at 23:59:59 and Darwinex-Live's at 23:54:59 on Sunday (market closed) with identical chart time axes: both are on the New York + 7 h clock (UTC+3 until 2026-11-01, UTC+2 after). Atlas's server clock equals Darwinex's (inferred from the axes). Atlas `NAS100` quotes with two decimals (28390.67), as the NDX cap assumption says.

## Decisions (user, 2026-11-01)
1. **Atlas: the daily limit is the only criterion.** The floor stays reported, not gating. Note kept in the record: at the FTMO setting our 2026-10-29 calibration breached the floor in 6.6% of simulated challenges against <= 0.9% daily, because a stage starts with only a $4,000 cushion.
2. **Darwinex Zero: scale-free criteria** (return per max drawdown, worst month, positive-month share, worst rolling 6-month return, calibration trade count); no absolute drawdown cap.
3. **Earlier verdicts: list, then re-score those that depended on the 8% level.**
4. EA day reset: the user answered with the two server-clock screenshots, not a choice; default taken = measure only, no EA change.

## What changed
- `docs/gates.md`: account profiles replace the 8% sizing rule, the hard-drawdown rule and the variant trigger; the add-on test drops "max DD rises <= 1.0 point". Gates A, B and C are unchanged (they carry no drawdown cap).
- `scripts/prop_mc.py`: `--server-to-utc` buckets days at 00:00 UTC from Darwinex server time (New York + 7 h, DST-aware); default unchanged. `scripts/make_live_sets.py`: `ATLAS` gains `initial_usd`, `floor_usd` 46,000, `daily_usd` 2,000, `day_reset_utc`.
- `reports/portfolio/atlas_phase1.py`: primary day = UTC (`ftmo` reproduces the old run), pick cap = train daily-breach rate <= 2%, floor breach printed. `dark_addon_overview.py`: daily groupings on UTC days (amendment to the 2026-10-31 methodology, whose step 3 used the server date). New `stage_replay.py` and `addon_3macd_atlas.py`; `addon_3macd.py` now also returns its event series.
- Tests: `test_prop_mc` (UTC day through daylight saving), `test_live_sets` (dollar limits match the percent limits). `test_ea_inputs` skips the two compiled vendor EAs (Dark Moon, Rea) that were added to the roster on 2026-10-31 and had broken it (no source file). 115 pass.

## Checks and results (closed trades unless stated)
- **Regression:** `atlas_phase1.py ftmo` reproduces all 12 grid rows of the 2026-10-29 log exactly (`atlas_phase1_ftmo_day.log`).
- **UTC calibration** (`atlas_phase1_utc.log`): the pick does not move: **0.3% risk, 2% throttle**, train P(pass both) 98.2%, daily breach 0.0%, floor breach 0.9%, holdout 100.0% / 0.0%. Daily breach is 0.0% for every grid cell on UTC days; on server-midnight days it is 3.2% for 0.5% / no throttle and 0.9% for 0.5% / 4% (the day-boundary flag lists (0.5%, off) only). Full window: P(pass both) 99.6-99.7%, net +164.9% = +82,470 USD (+550R), worst day -1.71%.
- **Stage replay** (`stage_replay.py`, 90-day stages from every start day, $50,000): seven-EA baseline: worst UTC day -854 USD against $2,000, 0 of 1,056 starts breach it; lowest equity below a stage start -2,987 USD against $4,000, 0 breaches. Plus Dark Moon and Rea at fixed 0.01 lot (6,309 closed trades): worst UTC day -854 USD, 0 of 1,174 starts, lowest below start -2,839 USD. Overlay (`dark_addon_overview.json`, UTC days): net +85,395 USD (baseline +82,470), closed-trade DD 5.68% (5.97%), worst month -1,794 (-1,851), worst UTC day -853; sleeve daily correlation with the baseline -0.014.
- **EA day-reset gap:** the worst UTC day equals the worst server day (-854 USD) and no day on either clock reaches the EA stop (-1,250 USD): the 2-3 h mismatch between EACore's server-midnight reset and Atlas's has not mattered historically. No EA change.
- **3MACD add-on re-scored** (`addon_3macd_atlas.py`; 3MACD EURUSD H1 continuous report, candidate floating P/L marked at deal events, so a lower bound; baseline closed-only):

| | Net | Worst day | Starts with a day <= -$2,000 | Lowest below stage start | MC P(pass both) / daily / floor |
|---|---|---|---|---|---|
| Baseline, seven EAs | +82,470 USD | -854 | 0 of 1,151 | -2,987 | 98.7% / 0.0% / 0.7% |
| + 3MACD at 1% DD | +87,355 USD | -1,877 | 0 of 1,151 | -2,942 | 99.2% / 0.0% / 0.5% |
| + 3MACD at 2% DD | +92,241 USD | -3,603 | 257 of 1,151 | -4,019 | 99.3% / 0.0% / 0.3% |
| + Dark Moon and Rea (fixed 0.01 lot) | +85,395 USD | -854 | 0 of 1,205 | -2,838 | 99.0% / 0.0% / 0.5% |
| + 3MACD at 1% DD + Dark Moon and Rea | +90,281 USD | -1,876 | 0 of 1,205 | -2,904 | 99.4% / 0.0% / 0.3% |

  **Combined roster** (run later on 2026-11-01 with `addon_3macd_atlas.py --dark`, log `reports/portfolio/addon_3macd_atlas_dark.log`; 6,309 closed baseline trades): the seven EAs plus Dark Moon (EURUSD H1) and Rea (GBPUSD H1) at fixed 0.01 lot plus 3MACD at the 1% sizing nets +90,281 USD, the baseline's +82,470 plus about +4,886 from 3MACD and about +2,925 from the Dark sleeves (they add up, no cross-effect). The worst day is -1,876 USD, 94% of the limit and 3MACD's own worst day: the Dark sleeves never lose on the same day, so they leave it unchanged. Start counts differ from the first three rows (1,205 against 1,151) because each roster's start days come from its own trade days. Same status as the 3MACD-only rows: **unverified, not approved**. The Dark sleeves are closed trades only, so a floating loss from Moon or Rea (Rea GBPUSD's tester drawdown was about 2,100-2,400 USD) is not in the worst day, and under a balance-based daily base it could use the 6% of headroom left under 3MACD's worst day. How 3MACD's worst day lines up with Rea's floating loss was not checked.

  Under the Atlas profile 3MACD at the 1% sizing meets the daily criterion on this path (worst day uses 94% of the limit, little margin) and fails at 2%. The 2026-10-28 outcome called it "relative pass, 8% limit not established"; that "Fail" came from the peak-to-trough 8% test. Still **unverified, not approved**: the baseline's floating P/L and 3MACD's intra-leg moves are missing, which the gates require before a pass.

## Earlier verdicts that cited the 8% level
- `2026-10-28-3macd-portfolio-addon-outcome.md`: depended on it; re-scored above.
- `2026-10-27-geraked-screen-outcome.md`: the standalone verdict ("no EA passes with an acceptable drawdown", 19-44% against the 8% sizing level) depended on the peak-to-trough reading; the goal is add-ons, so it is not re-scored (a DHLAOS add-on test would need its own spec).
- `2026-10-27-3macd-continuous-gate-b-outcome.md`: the 8% appears only as a description of the drawdown; the Gate B PASS is unaffected.
- `2026-10-27-nzicode-stoch-v2-fix-screen-outcome.md`: a sizing note only; no dependence.
- `2026-10-30-dark-family-screen-outcome.md` and `-dark-venus-screen-outcome.md`: the "not recommended for Atlas" wording cites the 8% static limit; the stuck-position finding stands on the daily limit, see below.

## Limits and open items
- **Floating P/L is not in any of these numbers, and it matters most for Dark Moon and Rea.** The daily limit is equity against the day-start base. If that base is the balance (the page shows balance = equity while flat, so it does not say), an EA that carries a floating loss uses the daily budget every day until it closes. Moon's and Rea's tester equity drawdowns at fixed 0.01 lot were 7.7-9.6% (Moon EURUSD) and 21.2-24.1% (Rea GBPUSD) of the $10,000 test account, roughly $800-1,000 and $2,100-2,400: Rea alone can carry about the whole $2,000. The closed-trade replay above (0 breaches with Moon and Rea) cannot see this. **To confirm on the Atlas page ("?" tooltip): is the daily base the day-start balance or equity?** Until then Moon and Rea on the Atlas profile are unverified under the daily criterion.
- The Monte Carlo and the replays use closed trades; Atlas's daily limit is on equity. The EA daily stop (2.5%, equity against the server-day start balance) is the guard and is untested.
- Funded-stage rules (Protector 2%, news, 3-minute) are unchanged and still unmeasured for news.
- Throttle state in the rolling-start replay comes from the full-history path, not restarted at each stage start.

**Commit status:** uncommitted, like the other specs.

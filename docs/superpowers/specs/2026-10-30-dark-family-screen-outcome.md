# Dark Mimas, Moon, Rea and Dione: outcome (2026-10-30)

Spec: `2026-10-30-dark-family-screen-prereg.md`. Runner `reports/oct25/darkfamily_screen.py`, log `reports/oct25/darkfamily_screen.log`. Darwinex-Demo, real ticks, $10,000, 1:100, compiled defaults, 0.01 lot base, Gate B one continuous 2022-26 run. Total R is net USD / $5.00 (the nominal default stop); Venus showed the real loss per stuck position is 10-26 times that, so R understates the risk. **Venus is in `2026-10-30-dark-venus-screen-outcome.md` (rejected).**

| EA | Instrument | Gate A 2024-26 | Gate B 2022-26 (continuous) | Gate C 2019-21 | Verdict |
|---|---|---|---|---|---|
| Mimas | EURUSD | REJECT: -5,804.55 USD, PF 0.11, 494 trades, DD 59.9%, 22 stop-outs | not run | not run | rejected |
| Mimas | GBPUSD | REJECT: -5,637.15 USD, PF 0.18, 433 trades, DD 58.4%, 20 stop-outs | not run | not run | rejected (two rejects) |
| Moon | EURUSD | PASS: +335.37 USD, PF 1.61, 541 trades, DD 7.9%, R +67.1 | PASS: +565.55 USD, PF 1.69, 961 trades, 22-24 +349 / 25-26 +217, DD 7.7%, R +113.1 | ADD-ON ELIGIBLE: +363.80 USD, PF 1.65, 601 trades, DD 9.6%, R +72.8, hq 99% | add-on test due, not recommended |
| Rea | EURUSD | PASS: +1,448.85 USD, PF 3.34, 1,247 trades, DD 54.0%, R +289.8 | FAIL: -4,325.76 USD, PF 0.03, 147 trades, 22-24 +99 / 25-26 -4,425, DD 80.2% | not run | rejected on EURUSD |
| Rea | GBPUSD | PASS: +882.55 USD, PF 2.32, 811 trades, DD 24.1%, R +176.5 | PASS: +2,359.61 USD, PF 2.08, 2,543 trades, 22-24 +1,602 / 25-26 +758, DD 21.2%, R +471.9 | ADD-ON ELIGIBLE: +509.32 USD, PF 1.74, 608 trades, DD 10.3%, R +101.9, hq 99% | add-on test due, not recommended |
| Dione | EURUSD | PASS: +2.28 USD, PF 1.00, 358 trades, DD 1.12%, 0 stop-outs | FAIL: +117.43 USD, PF 1.11, 698 trades, 22-24 +145 / 25-26 -27, DD 1.10% | not run | rejected (Gate B failed on EURUSD; GBPUSD Gate A also rejected) |
| Dione | GBPUSD | REJECT: -305.24 USD, PF 0.67, 454 trades, DD 3.19%, 0 stop-outs | not run | not run | rejected (two instruments) |

Net as a share of the $10,000 deposit: Moon +3.35% / +5.66% / +3.64%; Rea GBPUSD +8.83% / +23.60% / +5.09%.

**Stuck-position disclosure (not a gate).** Every Mimas, Moon and Rea run carries the STUCK POSITIONS note except Rea GBPUSD 2019-21.
- Mimas EURUSD: grid stacked up to 21 same-side positions (max lot 0.21), 11 held over 30 days (-2,395.08 USD), longest 35 days; the whole loss is in 2024.
- Moon EURUSD: up to 8 positions (max lot 0.08); 6 held over 30 days (-148.01 USD) and 4 closed only by the test end (-34.27 USD), longest 55 days.
- Rea EURUSD: in the 2022-26 run 10 stacked positions sat for 1,623 days (about 4.4 years) and were closed by the test end at -4,425.19 USD; the stuck basket blocked all other trading (147 trades in 4.75 years). The 2024-26 Gate A pass came only from a start date after that basket opened.
- Rea GBPUSD: up to 10 positions (max lot 0.10); 20 held over 30 days (+187.59 USD), longest 101 days.

**Verdicts by the pre-registered rules.** Mimas is rejected on two instruments. Moon and Rea (GBPUSD) pass all three gates, so by `docs/gates.md` they are "add-on test due". Under the disclosure rule written before the runs neither is recommended for the Atlas account: both hold losing positions for weeks, Moon's equity drawdown is 7.7-9.6% and Rea's 10-24% on a 0.01-lot base (Atlas's static limit is 8%), and Rea's own EURUSD run shows the failure that a pass on one pair does not rule out. Moon's return is small for its drawdown (recovery factor 0.37-0.70); I expect it to fail the add-on test but that test was not run (it needs the account roster and its own spec).

**Dione: rejected on two instruments.** Jan 1 continuous runs returned empty reports. The 2026-10-31 boundary amendment used Jan 2 starts and preserved one continuous test per gate. Two quarter diagnostics completed (Jan 2-Apr 1: 1,532 bars, 27 trades, +12.52 USD, PF 1.30; Apr 1-Jul 1: 1,560 bars, 28 trades, +29.31 USD, PF 2.06); these diagnostics do not enter the gates. EURUSD Gate A completed in 1,533 s with 100% history quality: +2.28 USD, PF 1.00, 358 trades, DD 1.12%, no stop-outs; 2024 +34, 2025 -62, 2026 +30. One position closed at the test end (+0.02 USD); longest hold 9 days. Gate A passed its fixed thresholds. EURUSD Gate B completed continuously in 3,011 s: +117.43 USD, PF 1.11, 698 trades, DD 1.10%, no stop-outs; 2022 +73, 2023 +38, 2024 +34, 2025 -57, 2026 +30. The 2025-26 half was -27.12 USD, so Gate B failed. GBPUSD Gate A completed in 2,089 s: -305.24 USD, PF 0.67, 454 trades, DD 3.19%, no stop-outs; one position closed at the test end (-7.96 USD), longest hold 10 days. The two-rejects rule rejects Dione. Gate C was not run. The quarter runs showed the method for diagnosing the January boundary; they were not stitched or used as gates.

**Network call.** Every probe journal began with the EA's own line `You are in backtest, or our website don't work correctly`: a website check that the tester skips, probably a web request to the author's site in live trading. There is no source to read it. Under the project's rule (no EA that phones home) none of the family is deployable without the user's explicit decision.

**Correction to the earlier assessment (2026-10-30).** Mimas, Moon, Rea and Dione do not need a separately installed indicator: the indicator path in each file is a compiled-in resource, and all four ran and traded in the tester.

**Leftovers.** Removed: Mimas (`Dark_Mimas.ex5`, `Dark_Mimas.set`, its `ea_profiles` entry), Venus (earlier), and after the completed screen Dione (`Dark_Dione.ex5` from `Advisors`, `Dark_Dione.set` from `Profiles/Tester`, its `ea_profiles` entry). Tester logs were cleaned after each run. **Kept:** `Dark_Moon.ex5`, `Dark_Rea.ex5` in `Advisors`, their tester `.set` files and their two empty entries in `scripts/ea_profiles.py`, because they passed the gates and need add-on testing. Untouched: the user's own `Dark Venus MT5.ex5`, `Dark Rea MT5.ex5` in the MT5 root and their GUI tester files. Stays in the repo: the specs, runners, logs and all run reports in `reports/` (`mim_*`, `moo_*`, `rea_*`, `dio_*`, `dark_probe_*`).

**Commit status:** uncommitted; the commit waits for the user's go-ahead.

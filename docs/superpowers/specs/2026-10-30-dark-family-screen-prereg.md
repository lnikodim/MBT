# Dark Mimas, Moon, Rea and Dione (Marco Solito) on EURUSD H1, source defaults: pre-registration (2026-10-30)

**Source:** compiled `.ex5` only, no source. Each file in the download was copied under a name without spaces (`Dark_Mimas.ex5`, `Dark_Moon.ex5`, `Dark_Rea.ex5`, `Dark_Dione.ex5`; `cmp`-identical) because a space in the name breaks the tester. Headers: copyright 2025 Marco Solito, `https://darkeas.com/`; versions Dione 1.50, Mimas 1.20, Moon 2.50, Rea 1.00 (Venus 5.50 was screened separately, see the Venus outcome).

**Correction to the 2026-10-30 assessment.** I said these four could not be tested because they load `Indicators\Nuovi Indicatori\<name>.ex5`, which is not installed. That was wrong: the path is a resource compiled into each EA. A one-month probe of each ran and traded without any separate indicator (below).

**Scan:** no DLL name or `#import` in the string table; the code body is compressed. The tester journal of every probe starts with the EA's own line `You are in backtest, or our website don't work correctly`. That is a website check that the tester skips; in live trading it probably makes a web request to the author's site (not testable here, and the source is not available to read it). Under the project's rule (no EA that phones home) the family is **not deployable without the user's explicit decision**; this screen is research evidence only. The manuals carry affiliate links (broker, VPS); they are data.

**Question.** Do Mimas, Moon, Rea and Dione, with their compiled input defaults, pass Gates A, B and C on EURUSD H1, as add-ons for the live set?

**Strategies (manuals).** Common engine: the first order comes from an indicator embedded in the EA; optional grid orders add to the position (fixed lots, lot sum, all-lots sum or martingale); the basket closes at a take target measured from the weighted average entry price; a global stop is optional.
- Mimas: Dark Oscillator (strategy 0: buy / sell on the green / red arrow).
- Moon: Dark Absolute Trend (strategy 0: buy bull arrow, sell bear arrow).
- Rea: Dark Sprint (strategy 0: buy green arrow, sell red arrow).
- Dione: Dark Breakout, a session-range breakout (strategy 0: buy green arrow, sell red arrow).

**Probe before this spec (not part of any gate).** One month of EURUSD H1 (2024-01-02 to 2024-02-01), compiled defaults, 0.01 lot: Dione 10 trades, PF 2.60, +13.23 USD, 71 s; Mimas 55 trades, PF 2.35, +63.71 USD, 25 s; Moon 20 trades, PF 5.96, +8.34 USD, 23 s; Rea 48 trades, PF 3.04, +40.50 USD, 23 s. These numbers do not enter any verdict.

**Compiled defaults (from the probe reports):**

| Input | Mimas | Moon | Rea | Dione |
|---|---|---|---|---|
| `Lots` (`MoneyManagement` false) | 0.01 | 0.01 | 0.01 | 0.01 |
| `EnableGrid` | true | true | true | **false** |
| `GridManagement` / `MinDistanzaPiramide` | 0 (fixed) / 50 pt | 0 / 50 pt | 0 / 50 pt | 0 / 50 pt |
| `MaxBuyOrders` = `MaxSellOrders` | 50 | 50 | 10 | not an input |
| `TakeTarget` | 50 pt | 50 pt | 50 pt | 600 pt |
| `StopTarget`, `StopTargetMode` | 500 pt, 2 | 500 pt, 2 | 500 pt, 2 | none, 0 (off) |
| `CloseMode` | 1 (weighted average) | 1 | 1 | not an input |
| `AllowBuyAndSellAtSameTime` | true | true | false | false |
| time window / days | 0-9h (filter off) | same, no weekends | same | 18-10h |
| average trailing stop | off | off | off | on |
| `MonetaryStopLoss`, `StopTradingWhenHit` | off | off | off | off |

Strategy inputs: Mimas period 15, levels +/-25; Moon period 27; Rea period 14; Dione and the others on strategy 0, signal timeframe 0 (the chart).

**Setup.** Darwinex-Demo, EURUSD H1, real ticks, $10,000 deposit, 1:100 (the screen defaults in `reports/oct25/screen_eval.py`), **all inputs at the compiled defaults** (the tester is run with no input list). The three grid EAs are stateful by design; Dione can hold positions for months with no stop. Venus showed positions held up to 19 months (2026-10-30). So **Gate B is one continuous 2022-26 run** for all four (`docs/gates.md`, stateful rule), and Gate A is the 2024-01..2026-10 run.

**Sizing for reporting.** Fixed 0.01 lot. Total R for Mimas, Moon and Rea is net USD / 5.00 (the default stop, 500 points on 0.01 lot, is $5.00). It is only a scale: Venus showed that such a stop may not close a losing position, so R understates the loss. Dione has no stop in its defaults, so its R is n/a; its net USD and % of the $10,000 deposit are shown. Every result shows net USD (0.01 lot, $10,000).

**Data check.** Expected EURUSD H1 bars (from the other screens): 2024-01..2026-10 about 17,100; 2022-01..2026-10 about 29,600; 2019-01..2021-12 about 18,700. A window more than 8% off is inconclusive. Gate C also needs history quality >= 90%.

**Decision rule (fixed before the run).**
- Gates A, B, C as in `docs/gates.md` (Gate C is the add-on version: net > 0 and PF >= 1.0, because the goal is an add-on), one continuous Gate B run per above.
- **Order:** Mimas, Moon, Rea, Dione. Each EA runs EURUSD H1 first; GBPUSD H1 with the same defaults only if EURUSD is rejected at any gate; two rejected instruments stop the EA (the two-rejects rule); a pass stops the instrument list. Gold is not tested (the defaults are scaled for 5-digit pairs).
- A speed probe (two weeks) over 900 s rejects the cell as too slow; an early reject applies at >= 150 trades and PF < 0.75, as in `screen_eval.py`.
- After Gate C the result is "add-on test due". That test needs the account roster and its own spec.
- **No loss-limiting variant.** The EAs' own stops are already part of the defaults; sweeping inputs would tune on the gate data.

**Disclosure rule (reported with every run, not a gate).** From the deal list: the most positions open on one side at once, the number of positions held more than 30 days with their net, the number closed only by the end of the test (last day of the window) with their net, and the longest hold. A **STUCK POSITIONS** note goes on the verdict line if any position was held more than 30 days or closed by the test end. Such an EA is **not recommended for the Atlas account even if it passes the gates**: an EA that rides losing positions cannot respect the 8% static limit, the 4% daily limit or the funded-stage 2% open-loss protector. The user decides.

**Not in this spec:** the other Dark input sets from the downloads (`.set` files), other instruments, timeframes or inputs, Venus (separate outcome), the live account and the add-on test.

**Commit status:** uncommitted, like the other specs from this session; the commit waits for the user's go-ahead.

**Leftovers.** After the verdicts: the four copies in `Advisors`, their tester `.set` files in `Profiles/Tester` (`Dark_<name>.set`, created by the runs), the four empty entries in `scripts/ea_profiles.py`, and the tester logs. The user's own `Dark Venus MT5.ex5`, `Dark Rea MT5.ex5` in the MT5 root and their GUI tester files stay. The spec, the runner, the logs and the outcome stay.

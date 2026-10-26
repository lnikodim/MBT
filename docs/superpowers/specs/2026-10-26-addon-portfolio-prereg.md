# Add-on test: which near-miss EAs strengthen the live portfolio? (pre-registration)

Date: 2026-10-26. User: "the idea is to pick an EA or many EAs that strengthen the current portfolio with additional gains, not finding an
all-in-one EA that should drive the account". Server: Darwinex-Demo. No new tester runs: existing real-tick reports.

## What changes
- **The sizing step is dropped for add-ons.** It asked an EA to earn +10% a year on its own at an 8% drawdown, the bar for an EA that drives the
  account. An add-on is judged on what it adds to the live set.
- **The add-on test is the one used for NI225** (spec 2026-10-23-ni225-gap-continuation-prereg.md): the live set's closed trades 2022-01..2026-10 at constant 0.5% risk, with
  and without the candidate; the candidate is added if all three hold:
  1. return / max drawdown with it >= without it;
  2. max drawdown with it <= without it + 1.0 point;
  3. worst month with it >= without it - 1.0 point.
- **Reported too, not gated:** return per year, Sharpe, worst day, VaR95 month, and the daily and monthly correlation of the candidate with the live set.
- **Eligibility (edge evidence):** the candidate passed the 2024-26 screen and Gate A (80-trade floor for weekly rules), and its 2019-21 run was
  net positive with PF >= 1.0. The significance bar (t >= 1.65) no longer applies to an add-on, since a small allocation needs an edge that
  holds in sign, not a large one. A candidate whose 2019-21 history was modelled ticks is flagged.

## The baseline
The seven live EAs: MACD Cross (gold H1), Donchian Breakout (gold H4), RSI Reversal (gold H6), MA Channel (gold H1), Donchian Trend (USDJPY H4), Invictus
(GBPJPY Monday) and NI225 Gap Continuation, from the same trade logs as `reports/portfolio/dz_joint_ni225.py`, at 0.5% constant risk. The live EAs were tuned on this window, so
the baseline is in-sample (as in earlier joints).

## Candidates and how they are sized
Every candidate trade is converted to a percentage of the account balance at entry (profit / balance before entry) at the EA's default size, then
**scaled so the candidate's own closed-trade max drawdown is 1% of the account, and again 2%**. These are two allocations of the same
candidate, so the sizing is a property of the test, not of the EA's default lot.
| candidate | run used (2022-01..2026-10) | eligible? |
|---|---|---|
| Turnaround Tuesday, WS30 D1 | `tt_W_s0` | yes (screen, Gate A at 80, 2019-21 +3,237 USD PF 1.86) |
| Turnaround Tuesday, SP500 D1 | `tt_S_s0` | yes, 2019-21 data 0% real ticks (flagged) |
| Universal Breakout, GDAXI H1 (box ends 09:00, trail off) | `ubt_B9_GDAXI_2022` | yes (2019-21 +244 USD PF 1.11) |
| ORB Risk Managed, SP500 M5 (stop removed) | `orb_S_B_s0` | yes, 2019-21 data 0% real ticks (flagged) |
| ATR Candle Breakout, XAUUSD H1 | `atr_X_s0` | yes (2019-21 +3,041 USD PF 1.09); gold, so the overlap is the question |
| SessionReopenEA, XAUUSD H1 | `cb77060_s0a` + `cb77060_scr` | **no: failed Gate A (2022-24 -16 USD)**; reported for information |
Not eligible (2019-21 net negative or PF < 1): Market Miner, Williams %R, MACrossoverEA, Fisherman.

## Expectation (written before the run)
- **Index and DAX rules** (Turnaround Tuesday, ORB, Universal Breakout GDAXI): uncorrelated with the gold set (|daily rho| < 0.1), so the three conditions should hold at 1%
  and probably at 2%. Gains per year of about +0.3 to +1.5 points.
- **ATR Candle on gold:** the likeliest to correlate with the four gold EAs and the least likely to improve return per drawdown.
- **Caveats:** the sample of each candidate is small (about 40 to 1,200 trades), the baseline is in-sample, and several index runs have
  partly modelled history. A pass means "worth a deployment test on the target broker", not "adds money".

## Outcome (2026-10-26; `reports/portfolio/addon_joint.py`, closed trades 2022-01..2026-10, 0.5% constant risk per live EA)
**Baseline A** (six live EAs + NI225, 2,443 trades): +70.4%/yr, max DD 15.93%, worst day -4.06%, worst month -10.45%, Sharpe 2.10, return/DD 21.0 (in-sample).

| candidate | daily / monthly rho with A | at 1% allocation | at 2% allocation | add-on rule |
|---|---|---|---|---|
| **Turnaround Tuesday, WS30 D1** (101 trades) | +0.02 / +0.01 | +0.33 %/yr, max DD +0.00, return/DD 21.1 | **+0.66 %/yr, max DD +0.00, worst day and month unchanged, return/DD 21.2, Sharpe 2.12** | **pass, both** |
| **Turnaround Tuesday, SP500 D1** (96 trades) | +0.04 / +0.11 | +0.41 %/yr, max DD +0.00, return/DD 21.1 | **+0.81 %/yr, max DD +0.00, return/DD 21.2** | **pass, both** |
| Universal Breakout, GDAXI H1 (582 trades) | +0.04 / +0.12 | +0.25 %/yr, DD +0.21, return/DD 20.8 | +0.51 %/yr, DD +0.42, return/DD 20.6 | fails (return/DD falls) |
| ORB Risk Managed, SP500 M5 (1,188 trades) | +0.01 / -0.02 | +0.49 %/yr, DD +0.27, return/DD 20.8 | +0.98 %/yr, DD +0.68, return/DD 20.4 | fails (return/DD falls) |
| ATR Candle, XAUUSD H1 (640 trades) | **+0.18 / +0.34** | +0.33 %/yr, DD +0.13, return/DD 20.9 | +0.66 %/yr, DD +0.26, return/DD 20.8 | fails (gold overlap) |
| SessionReopenEA, XAUUSD H1 (901 trades; **not eligible**, Gate A) | +0.08 / -0.04 | +0.73 %/yr, DD -0.06, return/DD 21.3 | +1.46 %/yr, DD -0.12, worst month -10.27, return/DD 21.6 | passes, but not eligible |

- **Turnaround Tuesday holds in both halves** (at 2%): WS30 adds +0.05 points in 2022-24 and +3.06 in 2025-26 (max DD 15.93 -> 15.93 and 14.87 -> 15.00);
  SP500 adds +1.16 and +2.71 (DD 15.93 -> 15.93 and 14.87 -> 14.70). Return/DD is unchanged or higher in each.
- **The two Turnaround Tuesday cells are the same signal** on two US indices (they should not both be added). WS30 has full real-tick history, SP500 does not (74% in
  2022-26, 0% before), so WS30 is the better choice. SP500's 2022-24 contribution is larger.
- **The gain is small** (+0.3 to +0.8 points on +70%/yr). The value is diversification: the baseline holds four gold EAs, USDJPY, GBPJPY and NI225, and none is a US index.
  That benefit does not show in-sample, because gold trended throughout the window.
- **SessionReopenEA** is the best contributor numerically (+0.73 / +1.46 %/yr, DD slightly lower, worst month better, low correlation). It was excluded **by the
  eligibility rule written before the run** (2022-24 -16 USD), so it needs an explicit decision, not a silent change of that rule.
- **Before any deployment:**
  - these `.ex5` files come from bmtrading.de: there is no source, and the author's page asks for a licence request for live use;
  - the live account is IC Markets, so the candidate needs its own run there on the IC symbol and the IC server clock (the terminal is switched by the user);
  - the 2-4% allocation means very small lots on a prop account (the candidate sized to a 2% standalone drawdown is 0.16x its default lot on WS30).
- **Caveats:** the live set was tuned on this window (in-sample), the candidates have small samples (96-101 trades), and a pass means "worth a deployment test",
  not "will add money".

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

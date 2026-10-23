# MartinGale_Breakout_EA on Darwinex EURUSD H1 (pre-registration)

Date: 2026-10-23. User: "after that you can check this EA out: https://www.mql5.com/en/code/46591". Server: Darwinex-Demo.

**The EA:** "Breakout Martin Gale Expert Advisor for MT5" v1.00 (mql5.com code 46591, Mullerp04 / Peter Mueller,
2023-09-26).
- **Files:** `MartinGaleBreakout.mq5` (79 lines) with the include `ExpertFunctions.mqh` (232 lines).
- **Copied unchanged to:** `mql5/MartinGale_Breakout_EA.mq5` (renamed per the naming convention) and
  `mql5/ExpertFunctions.mqh`. The EA includes `<ExpertFunctions.mqh>`, i.e. from `MQL5\Include`.
- **Safety:** no DLL, web or file calls.

**The author's claim:** an IC Markets demo chart (USDJPY H1 open in the terminal; the tested symbol is not stated),
about 2022-07..2023-08. Balance 10,000 -> about 11,080 (+10.8% in 14 months), a smooth line with sharp equity dips.

**What the code does** (one position at a time, new bar only):
- **Signal:** the last closed bar's range is > 3x the average range of the 10 bars before it, and its body is > 50% of
  its range. Trade in the bar's direction, at market.
- **No stop or target on the order.** The EA watches floating P/L every tick, with money targets:
  - **Normal trade:** take profit at +`TP_Percentage_of_Balance` (0.1%). The volume is sized so that 0.1% equals
    `TakeProfPoints` (50 points = 5 pips on EURUSD). Cut at -`SL_Percentage_of_Balance` x `Start_The_Recovery`
    (10% x 0.1 = **1%**).
  - **After a cut, recovery:** the next trade's target is the base target plus the loss (about 1.1%) over the same
    5 pips, so the volume is **about 11x**. Its cut is at -`SL_Percentage_of_Balance` = **-10%**. A recovery loss
    resets everything, so **the worst cycle is about -11% of balance**.
- **Volume cap:** `BalancePercentageAvailable` 50% of balance as margin.
- **Not restart-safe:** the targets live in static variables, so a restart loses the recovery state.

**Portfolio fit (known before any run):** a failed recovery loses about 11% at once. That is over FTMO's 5% daily and
10% total limits and over our EA daily stop (-3%). So at the defaults this EA cannot run on the user's prop accounts,
whatever its average return. The test measures whether a risk-scaled version is worth anything.

**Symbol:** **EURUSD H1** (Darwinex real ticks 99-100% from 2019). Darwinex USDJPY real ticks cover about 15% of
2022-26 (spec 2026-10-15), and this EA decides on every tick, so USDJPY is not used.

## Runs (`reports/mgbreak/mgbreak_eval.py`; Darwinex-Demo, EURUSD H1, real ticks, 10k USD = the author's chart, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**Trades:** rebuilt from the Deals table (`scripts/blessing_eval.py` `deals_trades`), one position at a time. A cycle is
a normal trade, plus the recovery trade if there was one.

## Gate (S0; the Blessing grid gate of 2026-10-07, since there is no stop to define R)
1. The run completes with no stop-out, and has >= 150 trades.
2. k = 8 / max equity DD %.
3. Pass if the k-scaled return is >= +10% a year in both 2022-24 and 2025-26.
4. **Out of sample (S1):** k-scaled return > 0, and t of the per-trade % return >= 1.65. If history quality is below
   90%, it is inconclusive.
5. **Candidate** = all pass. Anything else closes the EA. No retuning.

**Reported:**
- net USD, PF, max equity DD, worst day % of balance;
- trades, normal trades won / cut, recoveries won / failed, worst cycle %;
- net by year, history quality.

## Expectation (written before the runs)
- **Normal trades** need about a 91% win rate (+5 pips vs -50 pips) and **recoveries** the same, before about 1 pip of
  costs on a 5-pip target. Expected value is about zero minus costs.
- **Failed recoveries:** a few in 2022-26 (-11% each), so the max DD is >= 15% and k <= 0.5.
- **Most likely verdict:** closed (gate and portfolio fit).

## Outcome (2026-10-23; log `reports/mgbreak/base.log`): closed
| run (EURUSD H1, real ticks, 10k, defaults) | net USD | PF | max equity DD | worst day | trades | normal won / cut | recovery won / failed | net by year |
|---|---|---|---|---|---|---|---|---|
| S0 2022-01..2026-10, hq 100% | -1,500.16 | 0.52 | 22.91% | -10.45% | 101 | 80 / 11 | 8 / 2 | 22 +156, 23 -906, 24 -889, 25 -15, 26 +153 |

- **The gate fails:** 101 trades against the 150 floor; k = 0.35, scaled -1.9% a year in 2022-24 and +0.3% in
  2025-26. No S1. Closed.
- **The martingale cost, as expected:** 2 failed recoveries at about -10.3% each, worst day -10.45%. Each would break
  FTMO's 5% daily limit and our -3% EA daily stop on its own.
- **Removed** per the leftovers rule: `mql5/MartinGale_Breakout_EA.mq5`, `mql5/ExpertFunctions.mqh`, its profile and the
  MT5 copies, including `MQL5/Include/ExpertFunctions.mqh` (no other EA includes it). The source is in git at 5e42f74.

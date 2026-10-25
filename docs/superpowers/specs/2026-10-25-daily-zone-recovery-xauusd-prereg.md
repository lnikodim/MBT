# Daily_Zone_Recovery_EA on Darwinex XAUUSD (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/75922". Server: Darwinex-Demo.

**The EA:** "Daily Zone Recovery EA mt5 for GOLD" (mql5.com code 75922, KirRamil, published 2026-08-10, page updated
2026-09-15), `DailyZoneRecovery.mq5` (MD5 5de567ab…, 636 lines).
- **Copied unchanged to:** `mql5/Daily_Zone_Recovery_EA.mq5`.
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL, web or file calls.

**The author's claim** (screenshots):
- **The test:** XAUUSD 2017-01..2026-08, 1,000 to **5,094.47**, a smooth balance line, deposit load up to about 25%
  (2018), fixed 0.01 lot.
- **The 2022-26 part** of the curve: about 2,080 to 5,094, about +3,000.
- **Data:** the tester shows the whole 9.6 years ran in **12 seconds**, so not real ticks (open prices or 1-minute
  OHLC). A grid with targets of a few dollars benefits most from that.

**What the code does:** three strategies around the previous day's high and low, each with its own magic number and
signal timeframe.
- **S1:** breakout and return, M15. Zone 0.13%, distance 0.25%, grid step 0.34%, target 0.15%.
- **S2:** test then breakout, M12. Zone 0.31%, distance 0.4%, **grid step 0.01%, target 0.01%** (about 0.40 USD).
- **S3:** test, pullback and retest, M6. Zone 0.28%, distance 0.4%, grid step 0.32%, target 0.06%.
- **Grid:** on in all three, with fixed 0.01-lot legs. A series closes at its target from the average price, or at
  **its stop of 1.5% of the average price** (about 60 USD on 4,000 USD gold).
- **Filters:** yesterday's range must be 25-150% of ATR(4 days); spread <= 3,000 points.

## Runs (`reports/oct24/dzr_eval.py base`; Darwinex-Demo, XAUUSD, real ticks, 10,000 USD, 1:100, defaults)
- **Why 10,000 and not the author's 1,000:**
  - Darwinex gold margin is about 200 USD per 0.01 lot, so 1,000 cannot hold the grid legs and would be refused.
  - With a fixed lot, the gate's k-scaled return (return % / DD %) does not depend on the deposit.
- **Runs:**
  1. **S0, 2022-01-01..2026-10-01.** Compared with the author's about +3,000 USD over 2022-26.
  2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**Trades:** legs from `deals_trades`.

## Gate (the Blessing grid gate, since the averaging grid makes R per leg unclear)
1. The run completes with no stop-out, and has >= 150 trades.
2. k = 8 / max equity DD %.
3. Pass if the k-scaled return is >= +10% a year in both 2022-24 and 2025-26.
4. **Out of sample (S1):** k-scaled return > 0, and t of the per-trade % return >= 1.65. If history quality is below
   90%, it is inconclusive.
5. **Candidate** = all pass.

## Expectation (written before the runs)
- **Costs:** on real ticks the spread (gold 0.3-0.9 USD) and commission eat S2's 0.40 USD targets. S1 and S3 targets of
  about 2-6 USD are taxed too.
- **Risk:** the 1.5% series stops are 10-25x the targets, so a few stops cancel many wins.
- **Expected:** far below the author's curve; k-scaled return < 10% a year.
- **Most likely verdict:** closed.

## Outcome (2026-10-25; log `reports/oct24/dzr.log`): closed (gate fails)
| run (XAUUSD M15, real ticks, 10k, 0.01-lot legs) | net USD | PF | max equity DD | worst day | trades | win | most open | net by year |
|---|---|---|---|---|---|---|---|---|
| S0 2022-01..2026-10, hq 100% | **+2,230.18** | 2.12 | **4.56%** | -5.3% of 10k | 902 | 79.4% | 20 | 22 +340, 23 +254, 24 +282, 25 +841, 26 +513 |

- **Gate fails on 2022-24:**
  - k = 8 / 4.56 = 1.75.
  - Scaled return: **+5.1% a year in 2022-24** (needs 10%) and +13.6% in 2025-26.
  - No stop-out, 902 trades. Closed.
- **A clean but small curve:**
  - Every year is positive, with a 4.56% max equity DD.
  - Trades closed before the end made +2,268.85; the test-end close-out was -38.67.
  - Raw return on 10k: about +2.9% a year in 2022-24 and +7.7% in 2025-26.
  - The worst day, -5.3% of the deposit (closed trades by day), is about the size of the max DD.
- **Expectation check:** expected costs to eat the targets and a result far below the author's curve. Instead, real
  ticks gave +2,230 against the author's about +3,000 over 2022-26, at PF 2.12: better than expected. The k-scaled
  return was still below 10% a year in 2022-24, as expected.
- **Removed** per the leftovers rule: `mql5/Daily_Zone_Recovery_EA.mq5`, its profile and the MT5 copies (the source is
  in git at dc90041).

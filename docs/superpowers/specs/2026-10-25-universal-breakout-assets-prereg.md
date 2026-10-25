# UniversalBreakout_EA on gold and indices (pre-registration)

Date: 2026-10-25. User: "test it on gold and indices". Server: Darwinex-Demo. EA: 73711 (source unchanged, restored from daac1d6).
Follows the closed tweak study (spec 2026-10-25-universal-breakout-tweak-prereg.md: no variant made EURUSD 2019-21 profitable).

## What changes in this study
- **Markets:** XAUUSD, WS30, SP500, GDAXI, all on H1 (the EA works only on H1).
- **No tuning on these markets.** Two fixed cells per symbol, chosen before any run:
  - **A:** the source defaults.
  - **B:** `OnTraillingStop` = 0. The 12-point trail, started at +10 points, is sized for a 5-digit forex price. On gold
    (point 0.01) and the indices it would trigger immediately, so B removes the one price-scaled mechanism. The
    other inputs are in box-relative units or minutes.
- **Multiple testing:** 8 cells (4 symbols x 2). The 2019-21 data on these markets was never used for any choice, so it
  is a true out-of-sample window here.
- **Defaults on every cell:** 1% risk per trade, stop 0.61 x box, target 1.0 x box, a 48-bar box from 00:00 GMT (offset +3),
  70-minute time exit, Tuesday-Friday.

## Runs (`reports/oct25/ub_assets.py`; real ticks, 10,000 USD, 1:100)
1. **Screen, 2024-01-01..2026-10-01** (the user's rule). **Reject** the cell if trades < 40, PF < 1.00 or net <= 0.
2. **S0, 2022-01-01..2026-10-01**, survivors only. **Gate A:** trades >= 150, PF >= 1.00, net > 0 in both 2022-24 and 2025-26.
3. **S1, 2019-01-01..2022-01-01**, Gate A survivors only. Net > 0 and PF >= 1.05. If history quality is below 90%, it is
   inconclusive.
4. **Candidate** = all pass. Then k = 8 / max DD % at the default 1% risk, which must scale to >= +10% a year in both regimes.

**Unit:** net USD at the EA's 1% risk sizing, with the maximum lot reported. R is not computed (the sizing varies by trade).

## Expectation (written before the runs)
- **Gold and indices trend more than EURUSD**, and a daily-range breakout is a known pattern there, so some cells may pass
  the 2024-26 screen on the strong 2024-26 trends in gold and US indices.
- **Cell A on gold and indices:** probably distorted by the point-sized trail (stops out almost at once).
- **Most likely verdict:** one or two cells pass the screen, and none passes 2019-21 with a drawdown that fits a prop account.

## Addendum A (2026-10-25, written after the GDAXI screen cells and before their rerun)
**Finding:** GDAXI cells A and B traded only 26 times in 2024-26 (WS30 about 400). The agent log shows about **1,950
"failed -- market closed" order placements** on GDAXI, against 1 to 31 failed or skipped placements each on XAUUSD, WS30 and
SP500. The EA places its stop orders when the box ends (00:00 in its GMT+3 frame), and the DAX is closed then. So the
GDAXI cells measured an order-timing failure, not the strategy.

**Fix, on GDAXI only, chosen for the demonstrated failure and not for any performance:** `StartHourBox` = 9, so the box ends
at 09:00 (inside DAX hours in any broker clock) and the orders can be placed. Nothing else changes.
- **A9:** the source defaults with `StartHourBox` = 9. **B9:** the same with `OnTraillingStop` = 0.
- **Multiple testing:** 10 cells in total. The same screen, Gate A and 2019-21 rules apply. The other symbols are not
  re-timed: they show no order-placement problem, and re-timing them would be tuning.
- **Expectation:** a few hundred trades on GDAXI. Given the other indices (two cells passed the screen, both failed Gate A
  or 2019-21), expect the same: closed.

## Outcome (2026-10-25; logs `reports/oct25/uba.log`, `uba2.log`): no candidate; one cell passes every edge check but is too small
Real ticks, 10,000 USD, 1% risk, H1. Screen = 2024-01..2026-10. A = source defaults, B = trailing stop off, A9 / B9 = box ending at 09:00 (GDAXI only).

| market, cell | screen (net USD, PF, DD, trades) | 2022-26 Gate A | 2019-21 |
|---|---|---|---|
| XAUUSD A | -110.86, 0.79, 2.8%, 360: **rejected** | not run | not run |
| XAUUSD B | +452.90, 1.15, 4.2%, 355: pass | **fail**: -576.18, PF 0.92, 22-24 -1,085 | not run |
| WS30 A | +257.55, 1.16, 4.0%, 401: pass | pass: +419.83, PF 1.14, 22-24 +337, 25-26 +43 | **fail**: -593.68, PF 0.79 |
| WS30 B | +988.62, 1.28, 4.1%, 398: pass | **fail**: -637.76, PF 0.92, 22-24 -1,211 | not run |
| SP500 A | -785.87, 0.65, 8.6%, 409: **rejected** | not run | not run |
| SP500 B | -1,066.25, 0.76, 14.5%, 408: **rejected** | not run | not run |
| GDAXI A, B | 26 trades each: not a test | - | - |
| GDAXI A9 | -51.01, 0.90, 3.0%, 332: **rejected** | not run | not run |
| **GDAXI B9** | **+555.43**, 1.23, 5.4%, 330: pass | **pass**: +751.11, PF 1.17, DD 6.3%, 582 trades; 2022 +52, 2023 +144, 2024 -47, 2025 +449, 2026 +153 | **pass**: +244.00, PF 1.11, DD 6.0%, 309 trades; 2019 +229, 2020 +92, 2021 -46 |

- **GDAXI B9 passes every edge check:** the screen, Gate A (22-24 +149, 25-26 +602) and the 2019-21 out-of-sample window
  (never used for tuning on this market). Positive in 6 of 8 years (2019 to 2026); 2021 -46 and 2024 -47 are the small
  losers.
- **It fails the sizing gate.** At the default 1% risk the max DD is 6.3%, so k = 8 / 6.3 = 1.27:
  - raw return +0.5% a year in 2022-24 and +3.4% in 2025-26;
  - scaled to the 8% drawdown budget: **+0.6% and +4.4% a year**, against the >= +10% required in both regimes.
- **Not a prop-account fit as built.** The edge is real-looking but about a fifth of the size needed. The return per trade is
  small: about +1.3 USD on a 10k account.
- **Caveats on the one pass:**
  - 1 of 10 cells passes everything, and it was re-timed after its first cells failed, for a demonstrated order-placement
    reason (about 1,950 refused "market closed" orders), not for a result.
  - The out-of-sample PF is 1.11 on 309 trades; no significance test was run for it. More than 70% of the 2022-26 profit is 2025.
- **Other findings:**
  - **Gold, WS30, SP500:** every cell that passed the 2024-26 screen failed on older years, so those passes are the strong 2024-26 trends.
  - **Trailing stop:** at the defaults it is point-sized (12 points), which breaks gold and the indices: win rates of 75-87% with tiny net results.
  - **GDAXI timing:** the source defaults trade only 26 times because the box ends when the DAX is closed.
- **Expectation check:** expected one or two screen passes and none surviving 2019-21 with a usable drawdown. Got five screen
  passes, one full pass, and a result too small for the sizing gate, so closed as a prop-portfolio EA.
- **Removed** per the leftovers rule: `mql5/UniversalBreakout_EA.mq5` (in git at daac1d6 and 31ba047), its profile and the
  MT5 copies, including `CBoxSession.mqh`. The GDAXI B9 settings are `StartHourBox` 9 and `OnTraillingStop` 0.

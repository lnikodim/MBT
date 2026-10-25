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

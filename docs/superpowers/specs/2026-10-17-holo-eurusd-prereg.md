# HoLo on EURUSD H1 levels (pre-registration)

Date: 2026-10-17. User: "Let's try another EA, named Highest Open / Lowest Open Trade, see the attached instructions
PDF file and the MQ4 that should be converted to MQ5. After that you can backtest it on EURUSD 1H".
The PDF (MichaelG, ForexFactory) and `smHiLoOpen Lines_v1.2.mq4` (SwingMan's indicator, no trade logic, same file:
undeclared `ii` at line 697) are the ones converted on 2026-10-06 as `mql5/HoLo_EA.mq5` (spec
2026-10-06-holo-improvements-prereg.md). That EA was tested on XAUUSD only (all 9 level x trigger cells PF 0.66-0.82,
CLOSED). It was never run on EURUSD, and the PDF's own example is an FX pair (AUDUSD), so this is a new test, not a retune.

"1H" = H1 levels: HO / LO are the day's highest / lowest H1 OPEN (the PDF's definition). The trigger candle must be a
lower timeframe (the PDF: M30, M15, M5 or M1): an H1 candle that opens above HO becomes the new HO, so an H1 trigger
can never open inside the Area of Interest.

## Changes (v1.01, no rule change)
- Session start > end wraps across 17:00 NY, so 1020-1015 = the whole trading day (17:00 NY to 16:55 NY, flat before
  the 17:00 NY close as before). Default stays NY 08:00-16:55 (the user's choice on 2026-10-06).
- Prices are logged with 5 decimals (2 decimals hid EURUSD prices in the logs and the excursion path).
- `tradelog_checks.ny_session_violations` handles the wrapped window (test added); `holo_eval.py` takes
  `--symbol`, `--set` and `--leverage`.

## Inputs (EURUSD, PDF rules)
Levels H1, entry on touch (Bid to HO for sells, Ask to LO for buys), stop at the day's high + spread / low, a new day
extreme or a new HO/LO cancels, previous-day breakout filter on. BE: stop to entry + 1 pip once 5 pips in profit, as
the PDF says (`InpBETriggerPct` 0.045 / `InpBELockPct` 0.009 = 5 / 1 pips at 1.10; EURUSD traded 0.96-1.19 in
2022-26, so 4.3-5.4 pips). No late entry: `InpMaxLatePct` 0.009 (1 pip). TP = 1R (the PDF leaves the exit to the
trader; 1R is the gold Stage A baseline). Min stop 0.03% (3.3 pips) and the 150-point (15-pip) spread cap unchanged.
1% risk, deposit 100,000 USD, leverage 1:100 (FTMO FX; 1:20 cannot hold 1% on a 5-pip stop).

## Step 0: tester checks on EURUSD
`holo_eval.py selfcheck --symbol EURUSD --leverage 100` with the inputs above (2025-01..04, real ticks): all 12 checks
must pass before Stage A.

## Stage A (`reports/holo_eur/stage_a.py`, Darwinex real ticks, 2022-01-01..2026-10-01)
| cell | trigger | session (NY) |
|---|---|---|
| `ny_M30` / `ny_M15` / `ny_M5` | M30 / M15 / M5 | 08:00-16:55 (EA default) |
| `day_M30` / `day_M15` / `day_M5` | M30 / M15 / M5 | 17:00-16:55, whole trading day (PDF: "any time") |

Gate A per cell: trades >= 150, tester PF >= 1.00, net R > 0 in both 2022-24 and 2025-26 (by close year).
A whole-day cell with any `ny_session_violations(rows, 7, 1020, 1015)` is void (bug), not a result.
Reported per cell: R by exit reason (tp / sl / be / session_end) and the decided win rate (TP vs full stop).
Plateau for passers: RR 0.75 / 1.5 and BE trigger 0.034 / 0.056 (5 pips x0.75 / x1.25); mean PF >= 1.00 and >= 3 of 4
profitable. A plateau passer then gets the joint rule against the 4-EA Darwinex control, pre-registered separately.

## Expectation
On gold the 1R + 5-pip BE rules were negative before costs; the "win rate" was BE scratches. EURUSD costs are smaller
relative to the stop, but nothing in the rules changes the entry. Expected PF 0.75-0.95, 0 of 6 pass.
If 0 pass, HoLo stays closed (now on EURUSD too).

## Outcome (2026-10-17, Darwinex-Demo real ticks, log `reports/holo_eur/stage_a.log`)
Step 0: 12/12 tester checks passed on EURUSD.

| cell | trades | PF | tester DD | R 2022-24 / 2025-26 | decided win (TP vs full stop) | Gate A |
|---|---|---|---|---|---|---|
| NY, M30 | 412 | 0.69 | 45.7% | -27.3 / -27.6 | 45% | fail |
| NY, M15 | 852 | 0.73 | 67.8% | -58.0 / -48.3 | 45% | fail |
| NY, M5 | 1,507 | 0.80 | 80.3% | -89.8 / -56.1 | 48% | fail |
| whole day, M30 | 1,894 | 0.65 | 96.6% | -217.8 / -112.6 | 44% | fail |
| whole day, M15 | 2,952 | 0.60 | 99.5% | -346.0 / -177.9 | 44% | fail |
| whole day, M5 | 3,894 | 0.66 | 99.8% | -412.9 / -232.1 | 45% | fail |

**Gate A: 0 of 6 pass**, no session violations in any cell. Exits in every cell: TP about +0.93 R, full stop about
-1.12 R, BE +0.03 R. With TP 1R and stop 1R the trade needs 55% decided wins after costs (50% before); it gets 44-48%,
so it loses before costs too, as on gold. The whole trading day is worse than New York only (more Asian-session
setups, same loss rate). The expectation held (PF 0.60-0.80).

### Verdict
HoLo is closed on EURUSD as well: the touch of the day's highest/lowest H1 open is not a reversal point on EURUSD
2022-26. No exit retune.

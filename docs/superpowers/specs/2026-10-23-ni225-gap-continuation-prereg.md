# NI225_Gap_Continuation_EA on Darwinex NI225 M5 (pre-registration)

Date: 2026-10-23. User: "continue testing https://www.mql5.com/en/code/75301". Server: Darwinex-Demo.

**The EA:** "Nikkei 225 Gap Continuation EA" (mql5.com code 75301, Francesc Jordi Mallol Nolden / MauriyKiku, published
2026-07-24), `Nikkei225_Gap_Continuation_EA.mq5`, 1,160 lines, MD5 bd04ffd5…. It is copied unchanged to
`mql5/NI225_Gap_Continuation_EA.mq5`, renamed per the naming convention. No DLL, web or file calls. Built for Darwinex
(symbol NI225, M5).

**The author's claim** (NI225 M5, 2017-2026): balance 97,964 -> 135,992, net +33,893.14, PF 1.50, max DD 3.89%,
501 trades, 60.48% won, at the default 0.5% risk.

**What the code does** (one strategy entry per day, one position on the symbol):
- **Session:** cash session 09:00-15:30 JST, converted to Darwinex time with the **US** DST rule (UTC+2 / +3). This
  matches what we measured today (Darwinex = New York + 7 h).
- **Gap:** cash-session open (first M1 bar at 09:00 JST) vs the last M1 close of the previous cash session. A gap
  >= 1.0% enables a BUY (up) or SELL (down) setup.
- **Opening range:** the first 10 minutes.
- **Entry:** on a tick, price breaks the range on the gap's side and is beyond the session VWAP. VWAP uses real volume
  if there is any, otherwise tick volume.
  - The deadline is 90 minutes after the open.
  - The setup is cancelled if more than half the gap fills first.
  - Spread must be <= 10% of the stop.
- **Stop:** the far side of the opening range.
- **Exits:** 40% closed at +1R, then the stop moves to break-even. The rest goes at +2R, or 5 minutes before the cash
  close.
- **Size:** 0.5% of equity (SELL 0.25% when the gap is under 1.25%).
- **Restart:** position state is kept in terminal globals, so a restart keeps it.

**Data** (spec 2026-10-22-jpn225):
- Darwinex NI225 real ticks: 100% from 2023-04 (25% in 2023-03-15..31, none before).
- M1 bars: 100% in 2019-01 and 2021-01.
- The author's 2017-2026 window covers every year we can test, so **no period is out of sample** for these defaults.
  This is a replication and robustness test.

## Runs (`reports/ni225gap/ni225gap_eval.py`; Darwinex-Demo, NI225 M5, 100k USD, 1:100, source defaults)
1. **M0, modelling check:** 2023-04-01..2026-10-01 on real ticks (M0r) and on M1-generated ticks (M0g).
   - Pass: at least 80% of real-tick entries have a generated-tick entry on the same day within 15 minutes, and the
     trade counts are within ±20%.
   - If M0 fails, generated ticks are not evidence for this EA. S0 is then real ticks only (2023-04..2026-10, regimes
     2023-04..2024 / 2025-26), and the consistency check is inconclusive.
2. **S0, 2022-01-01..2026-10-01:** 2022-01..2023-04 on generated ticks plus M0r.
3. **S1, consistency, 2019-01-01..2022-01-01:** generated ticks. Only if M0 and Gate A pass.
4. **N1-N4, neighbours:** each on M0r's real-tick window, only if Gate A and S1 pass. Gap minimum 0.75% and 1.25%
   (BUY and SELL together); opening range 5 and 15 minutes.

**Trades:** one in-deal plus its out-deals (the partial and the final) make one trade. R = trade net / (|entry - first
stop| x volume x value per point), with the stop from the Orders table.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Consistency (S1):** net > 0, PF >= 1.05.
- **Overall:** mean-R t >= 1.65 over S1 + S0 (2019-2026).
- **Neighbours:** all four have PF >= 1.00, so there is no cliff around the defaults.
- **Candidate** = all of the above pass. Anything else closes the EA. No input search.
- **Reported:** net USD (at 0.5%) and net R, PF, max DD, trades, win rate, mean R (t), R by year, BUY / SELL split,
  exits (target / partial + break-even / stop / session end), M0 entry matching, history quality.

## Expectation (written before the runs)
- **Trades:** gaps >= 1% on the Nikkei happen on maybe 15-25% of days, so roughly 50-60 trades a year, consistent with
  the author's 501 trades in 9 years. 2022-26 should give about 200-280.
- **Edge:** gap continuation on index opens is a known effect. PF 1.15-1.40 on our data, below the author's 1.50.
- **Most likely verdict:** Gate A passes, and the neighbour check is the main risk.

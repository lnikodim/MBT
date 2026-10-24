# Silvios_Best26_EA on Darwinex EURUSD M15 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/68934". Server: Darwinex-Demo.

**The EA:** "SilviosEAbest26" v1.77 (mql5.com code 68934, silvio7933, published 2026-03-08, page updated 2026-09-15),
`SilviosEAbest26.mq5`, 175 lines, MD5 965a3a3c….
- **Copied unchanged to:** `mql5/Silvios_Best26_EA.mq5`.
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL, web or file calls. It prints only on failed orders, and writes a chart `Comment` every tick (no
  log).

**The author's claim** (screenshot, translated from German):
- **The test:** Admirals demo, EURUSD M15, 2025-01..about 2026-02 (27,048 bars), 7,000 deposit.
- **Results:** net +10,753.69, PF 1.29, equity DD 9.47%, **2,194 trades, all buys (0 sells)**, 65.6% won.
- **Data:** 1,596,918 ticks for 27,048 M15 bars is about 59 ticks a bar, so **1-minute OHLC**, not real ticks.
- **Inputs:** the screenshot's inputs (stop 20, target 50, trail 10, a `ZoneBufferPips` = 5, a `SellRSI_Threshold`
  input) belong to **another version**. The published v1.77 has stop 25, target 75, trail 15 and a fixed 10-pip zone.

**A coding bug that decides the strategy:**
- **The bug:** `double currentRSI = iRSI(_Symbol, _Period, RSI_Period, PRICE_CLOSE);` is MQL4 syntax. In MQL5 `iRSI`
  returns an **indicator handle** (a small constant integer such as 10), not the RSI value.
- **The effect:**
  - "RSI < 40" (the buy filter) is always true, and "RSI > 55" (the sell filter) is never true.
  - The early exits (a buy closed at RSI > 65, a sell at RSI < 35) never fire for buys.
- **So the EA is buy-only with no RSI filter,** as the author's own 0-sell screenshot shows.

**What the code does in effect** (every tick; one position on the account):
- **Entry:** buy when the current close is within 10 pips of the lowest low of the last 48 closed bars, at most once
  per bar, when the spread is <= 3 pips.
- **Exits:** stop 25 pips, target 75 pips.
  - **Break-even:** at +5 pips, the stop moves to the entry + 2 pips.
  - **Trailing:** 15 pips behind the bid, ratcheting in 3-pip steps.
  - Changes are made at most every 3 s.
- **Size:** 1% of balance on the 25-pip stop.

## Runs (`reports/oct24/q_eval.py silv`; Darwinex-Demo, EURUSD M15, real ticks, 100k USD, 1:100, source defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.
- **No replication run:** the author's screenshot is another version on 1-minute OHLC.

**R per trade:** from the Orders table stop (the 25-pip stop is on the order; `crabel_eval.trades`).

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **Trade shape:** buy-only dips to a 48-bar (12-hour) low, with break-even at +5 pips and a 15-pip trail. On real
  ticks many trades end at about +2 pips (break-even) or -25 pips. Costs (about 0.7 pip) are large next to the
  break-even exits.
- **Why M1 OHLC flatters it:** a 1-minute-OHLC model has only 4 prices a minute, so it hides the small adverse moves
  that hit a 5-pip break-even or a 15-pip trail first.
- **Trades:** about 400 a year, about 1,900 in S0.
- **PF:** 0.80-1.00 in R.
- **Most likely verdict:** closed.

## Outcome (2026-10-24): closed by the user before a result
- **What happened:** the S0 run was stopped mid-way when the user said "skip it, it fails heavily". No result was
  written, so this spec records no numbers.
- **What stands:** the code finding above. An MQL4-style `iRSI` call leaves the RSI filter inert, which makes the EA
  buy-only. The author's own screenshot (0 sells in 2,194 trades) confirms it, and that screenshot is from another
  version on 1-minute OHLC.
- **Removed** per the leftovers rule: `mql5/Silvios_Best26_EA.mq5`, its profile and the MT5 copies (the source is in git
  at 56270a6).

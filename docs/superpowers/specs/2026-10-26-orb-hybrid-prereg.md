# ORB_EA vs ORB_RiskManaged (mql5.com 77967): what to reuse (comparison and pre-registered hybrid study, 2026-10-26)

**Request:** "compare the existing EA with this one and reuse some core logic that might increase profit factor, net profit and minimizes drawdown" (77967), then
"you can use this thread as additional help to improve the core logic" (blog post 771405).
Sources: 77967 `ORB_RiskManaged.mq5` (md5 a2809dcb…, 422 lines; tested here on 2026-10-26 on SP500 and WS30 and closed, see `2026-10-26-orb-riskmanaged-prereg.md`);
the blog post "Building an Opening Range Breakout Portfolio on a Single Chart" (11 June 2026, a Market product ad "ORB Indices by ARGUS": claims, unverified, PF 1.32, Sharpe 4.13, max DD 5.51%, 8,310 trades, 2020-2026,
six index combinations: NAS100 and S&P 500 on M5, M15, M30); and `ORB_Tester_EA` (the user's five-stage ORB_EA with the tester clock fix, `2026-10-26-orb-ea-assets-prereg.md`).

## Comparison
| | ORB_EA (five-stage, tradewithpat) | ORB_RiskManaged (77967) | ORB Indices post (771405) |
|---|---|---|---|
| Session clock | NY / London / Tokyo through GMT and DST maths (wrong in the tester until fixed) | fixed server-time inputs (16:30 = NY open on Darwinex) | broker offset set once, DST resolved in code |
| Range | first 15 min of M5 candles | first 15 min from M1 bars | first minutes after the cash open |
| Range filter | min / max in **points** (off) | **0.05 to 0.60 x the prior day's D1 ATR(14)** (on) | none stated |
| Trend filter | none | none | **price versus a moving average**, trade only with it |
| Entry | next candle must also close outside, then market (other modes exist) | buy stop / sell stop 20 points beyond the range (OCO) | market after a candle **close** beyond the range |
| Last entry | end of the 390-minute window | 120 min after the open | not stated |
| Stop | beyond the breakout candle (+1 point): very tight | range x 1.0 (+ buffers): about the far side of the range | **opposite side of the range** |
| Target | 2R hard; break-even at 1R; swing trail at 1.5R | 2R, no management | a multiple of the range, no discretion |
| Exit | flat at the end of the window | everything closed 22:45 | flat before the close |
| Sizing | 0.5% of balance over the stop distance | same | fixed lot per leg |
| Protection | none (spread cap off, news filter off in the tester) | daily loss 3% and a **permanent** 8% drawdown stop | one trade a day, no martingale / grid |
| Instruments | any | US100 as built | US indices only |

## What follows from it
1. **Most of 77967's engine is already an ORB_EA input:** stop at the far side of the range (`SL_OPPOSITE_RANGE`), entry at the break (`ENTRY_BREAK_CLOSE`), 2R target, and no management (set BE and trail to 99).
   The tight break-candle stop plus the 1R break-even is the biggest difference: the cost (spread and slippage) in R is large for a tight stop, and the break-even turns many 2R winners into scratches.
2. **Not in ORB_EA, worth porting (new code, default off):** the ATR-normalised range filter and the entry cutoff from 77967, and the trend filter from the post.
3. **Not worth porting:** 77967's **daily loss limit of 3% cannot bind** with one trade a day at 0.5% risk (a day loses 0.5% at most), and its **permanent 8% hard stop** switches the EA off for good (it ended the WS30 2022-26 test after 90 trades).
   For drawdown the repo's own `AccountThrottle.mqh` (halve the risk while the account is in drawdown, no permanent stop) is the better tool; it is added as a switch and tested last.
4. **Correction:** the 77967 spec said "US100 does not exist on Darwinex-Demo". **`NDX` does exist** (Nasdaq 100; tick history since 2019-01 in `Bases`). It is added to the study with SP500 and WS30: the post and 77967's author both built the idea on US indices.

## Hybrid build and variants
`mql5/ORB_Hybrid_EA.mq5` = `ORB_Tester_EA` plus default-off inputs: `InpRangeAtrMin/Max/Period`, `InpEntryCutoffMin`, `InpTrendMaPeriod/TF`, and the `AccountThrottle.mqh` inputs; with them off the trades are identical (checked on two cells).
Cumulative variants, **New York session, 15-minute range, 0.5% risk, M5**, everything else the source default:
| id | change | from |
|---|---|---|
| h0 | none (the baseline, `ORB_Tester_EA` results) | |
| h1 | stop at the far side of the range, entry at the break close, break-even and trail off | 77967 engine |
| h2 | h1 + range between 0.05 and 0.60 x prior-day D1 ATR(14) | 77967 |
| h3 | h2 + no entry later than 120 min after the open | 77967 |
| h4 | h3 + trend filter: D1 close vs its EMA(50) | post 771405 |
| h5 | h3 + trend filter: M5 close vs its EMA(200) | post 771405 |
| h6 | the best of h3 / h4 / h5 + `AccountThrottle` (cut risk to 0.5x at an 8% drawdown) | repo; run only if one of h3-h5 helps |
The post gives no period or timeframe for its moving average, so two common choices are fixed here before any result (h4, h5); nothing else is tuned.
**Cells:** XAUUSD, XAGUSD, EURUSD, GBPUSD, USDJPY, USDCHF, USDCAD, AUDUSD, NZDUSD, NDX, SP500, WS30 (12) x h1-h5, plus h0 for the three index cells = 63 runs of the Gate A window (2024-01..2026-10, real ticks, 10,000 USD).

## Rules
- **Measure:** per variant and cell: trades, PF, net USD, max drawdown %, total R; then per variant the mean and median PF, the number of cells with PF >= 1.0 and the sum of net.
  A change "helps" only if the PF, the net and the drawdown improve over h0 **on most cells**, not on the best one.
- **Gates:** a variant-cell with PF >= 1.0, net > 0 and >= 40 trades goes to Gate B (2022-01..2023-12 joined with the first run) and Gate C (2019-01..2021-12) as in docs/gates.md; NDX, SP500 and WS30 history is partly modelled before 2022 (SP500 74% real ticks 2022-26, none before), so Gate C may be inconclusive.
- **Selection bias:** every variant is judged on the same 2024-26 window that was used to choose to test it; the 2022-23 and 2019-21 windows are the check, and a pass is "not refuted", not proof.

## Expectation (written before the runs)
The baseline loses on all 7 forex and 2 metal cells so far (PF 0.66-0.95; XAUUSD NY PF 0.94, mean -0.03 R per trade): the costs are about what the edge is. Widening the stop and removing break-even should raise PF by a few hundredths and cut the cost in R.
The ATR filter and the cutoff remove trades and should lift PF slightly more on the indices than on forex. I expect **no forex cell to reach PF 1.0** and the best chance to be the US indices (NDX, SP500) on h3-h5, with PF 1.0 to 1.15, in line with 77967 on SP500 (PF 1.04 to 1.06, t +0.9).
The post's PF 1.32 and drawdown 5.5% are a claim about a different, unpublished EA; they are not a target.

## Outcome (2026-10-26, evening): not run
User: "ok, it is a dead end, skip it" after the 18 baseline cells had all failed Gate A (`2026-10-26-orb-ea-assets-prereg.md`). The hybrid build was written and the runner prepared, but **no variant was run**; the comparison above stands as analysis only.
Removed with the rest of the ORB study: `mql5/ORB_Hybrid_EA.mq5` and its profile entry (they were never committed). The idea list (ATR-normalised range filter, 120-minute entry cutoff, trend filter from post 771405, `AccountThrottle`) is untested.
Correction that stays: `NDX` exists on Darwinex-Demo with tick history since 2019, so the earlier 77967 test missed a US100 cell.

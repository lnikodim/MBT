# mql5.com "best" experts list: screen of the shortlist (pre-registration)

Date: 2026-10-25. User: "analyse and find promising EAs from the 1st 50 pages of https://www.mql5.com/en/code/mt5/experts/best.
If 2024-2206 period is not aligned with EA core, reject the EA directly and continue backtesting the next one."
Server: Darwinex-Demo.

**"2024-2206"** is read as 2024-2026.

## The list
- All 50 list pages were read: **1,696 entries**.
- 50 were already tested here. Utilities, panels, indicators and risk managers were dropped, leaving **241 EA candidates**.
- mql5.com then throttled the downloads, so **119 of the 241 were screened by their pages**; 122 are not read yet.
- Of the 119:
  - **About 40 rejected without a test:**
    - martingale, grid or recovery structures;
    - the two web callers (76331 HybridMicrostructure, 75652 GoldScalpBot);
    - non-trading tools.
  - **About 25 plain breakout, trend and price-action EAs remain.**
  - **Ten sources were downloaded** (no DLL, web or file calls in any):
    49713, 41732, 73711, 76153, 49272, 63971, 54611, 16866, 1598, 1397.

## Not tested (rejected at the screen)
- **49272 Simple Yet Effective Breakout:** the earlier version of 49713 (same 20 / 20 Donchian). 49713 covers it.
- **54611 Outbreak Trader:** no stated symbol or timeframe, and the code rounds to 2 decimals with a 5,000-point target.
- **1598 Narrowest Range Signal, 1397 Breakout Bars Trend:** both call an indicator that the download does not include.

## Screen cells (real ticks, 10,000 USD, 1:100, source numeric / bool defaults; sources copied unchanged except the Turtle compile fix)
| cell | EA (mql5.com code) | symbol, timeframe | why |
|---|---|---|---|
| pf | Breakout_PropFirm_EA (49713) | EURUSD H1 | the EA's own H1; a 20-bar Donchian breakout |
| lbE | LazyBot_EA (41732) | EURUSD H1 | daily-bar breakout, 5-pip stop; the author tested EURUSD |
| lbG | LazyBot_EA (41732) | GBPUSD H1 | the author also tested GBPUSD |
| ub | UniversalBreakout_EA (73711) | EURUSD H1 | H1-only box breakout; the point defaults (62 / 30) fit forex |
| orb | SessionORB_EA (76153) | EURUSD M15 | 08:00 server-time opening range |
| pin | ExpPinBar_EA (63971) | EURUSD H4 | the author's own example is EURUSD H4 |
| turtle | TurtleTrader_EA (16866) | EURUSD H4 | Donchian 20 / 55 with ATR units |

- **Includes and indicator:** `CBoxSession.mqh` (73711), `Trailings.mqh` and the `PriceAction\iPinBars` indicator (63971)
  were installed in MT5 for these tests.
- **Turtle compile fix:** `MqlTradeRequest Request = {0};` does not compile on current MetaEditor. It became `Request;` plus
  `ZeroMemory(Request)` in `OnInit`. The logic is unchanged.
- **Multiple testing:** 7 cells. The screen is a coarse filter, and a survivor is not a candidate until the later stages.

## Runs (`reports/oct25/screen_eval.py`)
1. **Screen:** 2024-01-01..2026-10-01. **Reject** the cell if any of: tester trades < 40, PF < 1.00, net <= 0, a stop-out.
   The EA's core must also show in the trades: a breakout EA must be filling breakout orders, and so on. "Not aligned
   with the EA's core" means this check fails.
2. **S0:** 2022-01-01..2026-10-01, survivors only. **Gate A:** trades >= 150, PF >= 1.00, net > 0 in both 2022-24 and
   2025-26, no stop-out.
3. **S1:** 2019-01-01..2022-01-01, Gate A survivors only. Net > 0, PF >= 1.05, t of the mean USD per trade >= 1.65. If
   history quality is below 90%, it is inconclusive.
4. **Candidate** = all pass. Then the fit to the live portfolio is judged by symbol overlap and trade correlation.

**Unit:** net USD at the EA's default sizing (shown per cell); R from the order stop where the EA sets one.

## Live portfolio, for the fit judgement
Gold: MACD Cross (H1), Donchian Breakout (H4), RSI Reversal (H6), MA Channel (H1). Also Donchian Trend (USDJPY H4),
Invictus (GBPJPY Monday) and NI225 Gap Continuation. Gaps: EURUSD / GBPUSD, European and US indices, short-hold
intraday systems. Two of the screened EAs (49713 and 16866) are Donchian systems like the two Donchian EAs already live.

## Expectation (written before the runs)
- **Most cells reject at the screen.** Default settings of public breakout EAs on EURUSD have rarely cleared PF 1.00 over
  2.75 years after costs.
- **Possible survivors:** the session ORB (a rule with an edge on indices more than on EURUSD) and the Donchian pair, if
  2024-26 trended.
- **Most likely outcome:** zero or one survivor, and no candidate.

## Outcome (2026-10-25; log `reports/oct25/screen.log`): all six EAs closed, no candidate
Screen = 2024-01..2026-10, real ticks, 10,000 USD, 1:100, source defaults, no stop-outs in any cell.

| cell | net USD (sizing) | PF | max DD | trades | verdict |
|---|---|---|---|---|---|
| pf Breakout_PropFirm 49713, EURUSD H1 | **-3,928.87** (1% risk, up to 0.51 lot), -40.1 R | 0.81 | 43.9% | 631 | rejected: 2024 -2,002, 2025 -783, 2026 -433 |
| lbE LazyBot 41732, EURUSD H1 | **-43.21** (0.01 lot) | 0.70 | 0.4% | 538 | rejected: t -3.23 |
| lbG LazyBot 41732, GBPUSD H1 | **-107.99** (0.01 lot) | 0.47 | 1.1% | 569 | rejected: every year loses |
| ub UniversalBreakout 73711, EURUSD H1 | **+12,905.15** (risk sizing, up to 4.78 lots), +13.4 R | 1.48 | 23.9% | 353 | **passed the screen** |
| orb SessionORB 76153, EURUSD M15 | **-5,564.65** (1% risk, up to 1.12 lots), -75.2 R | 0.83 | 60.6% | 659 | rejected: every year loses |
| pin ExpPinBar 63971, EURUSD H4 | **+745.84** (0.10 lot) | 1.15 | 7.2% | 177 | **passed the screen** |
| turtle TurtleTrader 16866, EURUSD H4 | n/a | n/a | n/a | 0 | not runnable: "This EA doesn't work in HEDGING mode" |

**The two screen survivors**

| | S0 2022-01..2026-10 | S1 2019-01..2022-01 | verdict |
|---|---|---|---|
| ub, EURUSD H1 | +12,891.81 USD, PF 1.26, DD 39.3%, 641 trades. 22 -573, 23 +560, 24 +7,664, 25 +11, 26 +5,231. **Gate A passes.** | **-5,259.16 USD**, PF 0.65, DD 68.4%, 135 trades, -5.3 R. 2019 -5,196. **Fails.** | closed |
| pin, EURUSD H4 | +969.48 USD, PF 1.11, DD 12.1%, 297 trades. 22 +1,185, 23 -567, 24 +719, 25 +900, 26 +170. **Gate A passes.** | **-742.30 USD**, PF 0.88, DD 10.9%, 187 trades, t +0.12. **Fails.** | closed |

- **Universal Breakout:** the 2022-26 profit sat in 2024 and 2026 at a default size of up to 4.78 lots. 2019-21 lost 68% of the
  account. The 39% drawdown at default size would also breach the prop-firm limits.
- **ExpPinBar:** a small, shallow-drawdown edge that does not survive 2019-21 (PF 0.88).
- **The Turtle EA:** it exits at `OnInit` on a hedging account. Its edge was not measured. It would need a netting-account
  port, and the live Donchian EAs already cover this style.
- **R figures** for ExpPinBar and Lazy Bot are unreliable: overlapping positions broke the one-position pairing, so
  PF and USD from the tester are the figures to read.
- **Expectation check:** expected zero or one survivor and no candidate. Got two survivors of the screen, none after the
  out-of-sample check. The session ORB on EURUSD rejected, as the spec warned it might.
- **Removed** per the leftovers rule: the six `mql5/*.mq5` sources (in git at daac1d6), their profiles, the MT5 copies,
  `.set` files, `CBoxSession.mqh`, `Trailings.mqh`, and the `PriceAction\iPinBars` indicator.
- **Not yet screened:** 122 candidate pages not downloaded (mql5.com throttled) and the rest of the shortlisted EAs from the
  119 pages read.

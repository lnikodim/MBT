# Well_Martin_EA on Darwinex EURUSD M15 (pre-registration)

Date: 2026-10-25. User: "https://www.mql5.com/en/code/13315". Server: Darwinex-Demo.

**The EA:** "Well Martin" v1.00 (mql5.com code 13315, AM2, published 2015-07-28, page updated 2026-09-15),
`wellmartin.mq5` (MD5 8cd165fd…, 288 lines).
- **Copied unchanged to:** `mql5/Well_Martin_EA.mq5`.
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL, web or file calls. It prints on each stop-out lot increase and when the history is empty.

**The author's claim:** "designed for use on a tranquil market … EURUSD, M15". No results.

**What the code does** (every tick):
- **Bar check:** its "new bar" check uses a non-static variable, so it is true on every tick.
- **Buy:** ask < the lower Bollinger band (84, 1.8) of bar 1, ADX(40) of bar 1 < 45, and the last closed deal was not a
  buy (the first trade can be either side). **Sell:** bid > the upper band, ADX < 45, and the last deal was not a sell.
  So trades alternate between buy and sell.
- **Exits:** target 1,200 points and stop 1,400 points (120 / 140 pips), on the order (`Stelth` = 0).
- **Size and martingale:**
  - It starts at 0.1 lot.
  - After a closed loss the next lot doubles: 0.1, 0.2, 0.4, 0.8, 1.6, 3.2.
  - Once the next lot would pass `MaxLot` = 5 (6.4), it returns to 0.1.
  - On 10k, 3.2 lots x 140 pips is about -4,480 USD in one trade.
- **Limits:** one position on the account.

## Runs (`reports/oct24/q_eval.py wm`; Darwinex-Demo, EURUSD M15, real ticks, 10,000 USD, 1:100, defaults)
1. **S0, 2022-01-01..2026-10-01.**
2. **S1, out of sample, 2019-01-01..2022-01-01:** only if S0 passes.

**Measurement:**
- **R per trade:** from the Orders table stop (140 pips; `crabel_eval.trades`), independent of the doubled lot.
- **USD, the tester's PF / DD, stop-outs and the largest lot:** these show the EA as written.

## Checks
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26, **no stop-out**.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65, no stop-out. If history quality is below 90%, it
  is inconclusive.
- **Candidate** = both pass.

## Expectation (written before the runs)
- **The setup:** a band fade with wide stops (120 / 140 pips) on M15. Trades last days and are few: about 30-80 a year,
  so S0's 150 is borderline.
- **Martingale:** a 4-5-loss streak puts 1.6-3.2 lots on the 10k account; at Darwinex's 1:30 margin 3.2 lots of EURUSD
  needs about 12k. So expect a margin refusal or freeze like CCI and Martin, or a stop-out.
- **PF:** 0.85-1.05 in R.
- **Most likely verdict:** closed.

## Outcome (2026-10-25; log `reports/oct24/wm.log`): closed
| run (EURUSD M15, real ticks, 10k, martingale on) | net USD | PF | max DD | trades | win | net R (t) | R by year | max lot |
|---|---|---|---|---|---|---|---|---|
| S0 2022-01..2026-10, hq 100% | +1,379.86 | 1.07 (R 0.92) | 28.3% | 142 | 52.8% | **-5.7** (-0.52) | 22 +3.2, 23 +1.2, 24 -2.4, 25 -7.7, 26 none | 1.60 |

- **Gate A fails:** 142 trades (< 150), PF 0.92 in R, 2025-26 -7.7 R. Closed.
- **The signal loses:** -5.7 R in total. The USD profit (+1,379.86) comes from the martingale's doubled lots landing on
  some winners, not from the entries.
- **It froze in 2025, like CCI and Martin:**
  - After a 1.6-lot loss the next lot was 3.2, which the about 10k account cannot margin at 1:30.
  - The broken new-bar check retries on **every tick**: "CTrade::OrderSend: market buy 3.2 EURUSD … [not enough money]",
    5.86 million times.
  - That produced a 10.1 GB agent log (5.04 billion characters, which the eval loaded into memory).
  - No trades after 2025.
- **Expectation check:** the trade count was borderline, PF 0.92 in R inside the expected 0.85-1.05, and a margin freeze
  as expected.
- **Removed** per the leftovers rule: `mql5/Well_Martin_EA.mq5`, its profile and the MT5 copies (the source is in git at
  d68347c).

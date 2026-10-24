# CCI_And_Martin_EA on Darwinex EURGBP / EURUSD M15 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/21511". Server: Darwinex-Demo.

**The EA:** "CCI and Martin" (mql5.com code 21511, idea by Vladimir, code by barabashkakvn, published 2018-08-23, page
updated 2026-09-15), `CCI_and_Martin.mq5`, 667 lines, MD5 6b99a0d3….
- **Copied unchanged to:** `mql5/CCI_And_Martin_EA.mq5`.
- **Compile:** 0 errors, 0 warnings.
- **Safety:** no DLL, web or file calls. It prints per trade and per stop change only.

**The author's own claim:** defaults, M15, 10,000 deposit, all 20 forex symbols, period not stated.
- **Only 5 of 20 are positive:** EURGBP PF 1.27 (206 trades, +678.56), USDCHF 1.08, EURCHF 1.08, USDCAD 1.03, AUDJPY
  1.00.
- **15 lose,** down to AUDCAD PF 0.35. EURUSD: PF 0.90, -451.65, 422 trades.
- **Read:** taking the best of 20 overstates EURGBP; by the author's own table the EA loses on most pairs.

**What the code does** (every tick):
- **Entry:** checked only when there is no position and the current minute's seconds are >= 40, on the **forming**
  bar.
- **Buy:**
  - CCI(27, typical) on bar 1 < 5, falling over bars 3 > 2 > 1, then turning up on bar 0;
  - bars 2 and 1 bearish, bar 0 bullish, with its close above bar 1's open.
- **Sell:** the mirror image.
- **Exits:**
  - stop 20 pips, target 50 pips, both on the order;
  - a trailing stop once the profit exceeds 20 pips, kept 5 pips behind the price in 15-pip steps.
- **Size, martingale on by default:**
  - It starts at 0.1 lot and triples after every loss, up to 4 times: 0.1, 0.3, 0.9, 2.7, 8.1 lots.
  - It stays at 8.1 until a non-losing trade resets it to 0.1.
  - On 10,000, one 8.1-lot loss is about -1,620 USD (-16%), and a 5-loss streak about -2,420.

## Runs (`reports/oct24/q_eval.py cciA|cciB`; Darwinex-Demo, M15, real ticks, 10,000 USD = the author's account, 1:100, defaults)
- **Cells:**
  - **A, EURGBP:** the author's best cell, to see whether it holds outside their sample.
  - **B, EURUSD:** the main pair; the author's PF was 0.90.
- **S0, 2022-01-01..2026-10-01, each cell.**
- **S1, out of sample, 2019-01-01..2022-01-01:** only for a cell that passes.

**Measurement:**
- **R per trade:** from the Orders table stop, net / (stop distance x volume x value per point). R does not depend on
  the martingale lot, so it measures the **signal**.
- **USD and the tester's PF / DD:** these measure the EA **as written**, martingale included.
- **Also reported:** stop-outs (tester log "stop out triggered") and the largest lot.

## Checks (per cell)
- **Gate A (S0):** trades >= 150, PF >= 1.00 (tester, USD), net R > 0 in both 2022-24 and 2025-26, **and no
  stop-out**.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65, no stop-out. If history quality is below 90%, it
  is inconclusive.
- **Candidate** = both pass. With the martingale on, any candidate would also need a separate pre-registration of its
  risk (worst streak, max lot) before portfolio use.

## Expectation (written before the runs)
- **Signal:** a short CCI turn plus a 3-candle pattern on M15, with a 20-pip stop and a 50-pip target. Expected PF
  0.85-1.00 in R on both pairs.
- **Martingale:** with a win rate of about 30-40%, streaks of 5+ losses happen several times over about 1,000-2,000
  trades. Each puts 8.1 lots on a 10k account. A **stop-out or a DD above 60% is likely**, at least on EURUSD.
- **Most likely verdict:** closed in both cells.

## Outcome (2026-10-24; logs `reports/oct24/cciA.log`, `cciB.log`): closed (both cells)
| cell (M15, real ticks, 10k, martingale on) | net USD | PF | max DD | trades | win | net R (t) | traded until | max lot |
|---|---|---|---|---|---|---|---|---|
| A, EURGBP | **-983.05** | 0.16 (R 0.59) | 11.9% | **11** | 45.5% | -2.6 (-0.84) | 2022 | 2.70 |
| B, EURUSD | +481.49 | 1.29 (R 1.38) | 7.4% | **63** | 60.3% | +10.1 (+1.19) | 2022 | 2.70 |

- **Both cells fail Gate A on trades:** 11 and 63, all in 2022, and nothing in 2025-26. Closed.
- **The cause is the martingale on Darwinex margin:**
  - Four losses in a row raised the lot to 8.10.
  - The about 9,000 USD account can carry only 2.56 lots at Darwinex's 1:30 FX margin.
  - From then on every signal was refused: "OpenBuy / OpenSell, ERROR: method CheckVolume (2.56) < Lots (8.10)". This
    happened 233,566 times in cell A's sampled log, about 0.5 GB of agent log per cell.
  - Only a closed non-losing trade resets the lot, so **the EA never trades again** after such a streak. Live on an EU
    retail account, it would freeze the same way.
- **Cell B's 63 trades** (+10.1 R, t 1.19) are too few to say anything about the signal.
  - 60 of them closed on the stop at +0.05 R on average, i.e. mostly trailing exits.
  - Only 3 reached the 50-pip target.
- **Not tested:** the signal with the martingale off was not pre-registered or run.
- **Expectation check:** expected a stop-out or a large DD. The martingale instead froze the EA through the broker's
  margin limit. Closed in both cells, as expected.
- **Removed** per the leftovers rule: `mql5/CCI_And_Martin_EA.mq5`, its profile and the MT5 copies (the source is in git
  at cd5ea2c).

# Market_Structure_Onnx_EA on Darwinex XAUUSD / EURUSD H1 (pre-registration)

Date: 2026-10-24. User: "https://www.mql5.com/en/code/68535". Server: Darwinex-Demo.

**The EA:** "Market Structure Onnx" (mql5.com code 68535, Taufiqurrachman Assauqi, published 2026-01-23, page updated
2026-09-15), `MarketStructure.mq5`, 10,282 bytes, MD5 42057868…, with `MQL5\Files\market_structure.onnx`, 4,631,124
bytes, MD5 8c181fdf….
- **Copied unchanged to:** `mql5/Market_Structure_Onnx_EA.mq5` (renamed per the naming convention).
- **Model file:** in MT5's `MQL5/Files` only, not in git (download URL and MD5 above).
- **Safety:** no DLL, web or file calls besides loading the model.
- **Logging:** no `Print` at all. The only log lines are the tester's own order and stop-change entries.
- **The model:**
  - LightGBM, 4 classes, softmax, converted by OnnxMLTools.
  - Its ZipMap output matches the EA's `OnnxProbability` struct.
  - The training data and period are not stated.
- **Model date:** the 2026-01-31 Wayback copy of the page lists the same file sizes (onnx 4,522.58 KB, mq5 10.04 KB).
  So the 2026-09-15 update most likely did not replace the model, and **2026-01-23..2026-10-01 is data the model cannot
  have seen**.

**The author's claim** (H1, 3,000 deposit, 0.1 lot, history quality 100%, so real ticks):

| symbol | window | net | PF | equity DD | trades (long / short) | won |
|---|---|---|---|---|---|---|
| XAUUSD | 2025-03-01..2026-01-20 | +1,328.43 | 1.25 | 58.6% | 30 (25 / 5) | 43.3% |
| EURUSD | 2025-03-01..2026-01-21 | +508.05 | 2.28 | 6.9% | 25 (22 / 3) | 52.0% |

**What the code does** (H1, new bar; account `PositionsTotal() == 0` and no pending order with its magic):
- **Model input:** six features of the last closed bar:
  - 5-bar momentum, distance to the 50-bar high and to the 50-bar low, and body size, all divided by ATR(14);
  - tick volume vs its 20-bar average;
  - the server hour.
- **Model output:** labels 2 / 3 are bullish and 0 / 1 bearish (the description says HH / HL / LH / LL). The trade needs
  a confidence of at least 0.65.
- **Side filter:** buy only when bid > SMA(50); sell only when bid < SMA(50).
- **Entry:** a limit order at the 61.8% retracement between the last 5-bar pivot high and pivot low. It is placed only
  if that level is below ask (buy) or above bid (sell), and it expires after 4 h.
- **Stop and target:** the stop is 15 points beyond the pivot. The target is 2x the stop distance.
- **Trailing:** once the profit reaches 0.8 of the target distance (1.6 R), the stop moves to the entry plus 0.3 of the
  current profit, and keeps ratcheting.
- **Size:** fixed 0.1 lot.

## Runs (`reports/mso/mso_eval.py`; Darwinex-Demo, H1, real ticks, 100k USD, 1:100, source defaults)
0. **Probe:** XAUUSD H1 2026-09. It checks that the ONNX model loads under Wine, that trades happen, and how fast the
   agent log grows. It is not counted.
1. **S0, 2022-01-01..2026-10-01, each symbol.** Three slices are read off S0:
   - **R0, replication:** trades opened in the author's window, 2025-03-01..2026-01-21. The size is fixed, so net USD
     compares directly with the author's 3,000 account.
   - **F, forward:** trades opened 2026-01-23..2026-10-01, after publication, so unseen by the model.
   - **Gate A halves:** 2022-24 and 2025-26.
2. **S1, out of sample, 2019-01-01..2022-01-01:** only for a symbol that passes Gate A and F.

**R per trade** = net / (first stop distance x volume x value per point). The stop comes from the Orders table (parser of
`reports/crabel/crabel_eval.py`); trailing changes the position, not the order, so the first stop is kept. Exits are
split into stop (R <= 0), trail (a stop closed in profit), target and other.

## Checks (per symbol)
- **Gate A (S0):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **F (forward, unseen by the model):** net R > 0. A model fitted on 2022-25 can pass Gate A on its own training data,
  so this check is required.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = all three pass. No input search: the threshold, Fibonacci level and RR stay at the defaults.
- **Reported:** net USD (0.1 lot) and net R, PF, max DD, trades, win rate, mean R (t), R by year, long and short split,
  exits, R0 vs the author.

## Expectation (written before the runs)
- **Trade count:** the author's pace is about 30 trades in 10.7 months per symbol, so about 150-160 in 2022-26. Gate A's
  150 is borderline on trades alone.
- **R0:** same broker class and real ticks, so roughly the author's sign. Their samples (25-30 trades) are too small to
  mean much.
- **S0:** PF 0.85-1.10 in R. A 6-feature tree model with a label built from swing structure usually fits its training
  years and fades after them.
- **F:** about 20 trades per symbol, too few to prove an edge; a negative F closes the symbol.
- **Most likely verdict:** closed (Gate A fails in one half, or F is negative).

## Outcome (2026-10-24; log `reports/mso/base.log`): closed
| run (H1, real ticks, 100k, 0.1 lot) | net USD | PF | max DD | trades | win | net R (t) | R by year | exits |
|---|---|---|---|---|---|---|---|---|
| XAUUSD S0 2022-01..2026-10, hq 100% | -1,247.31 | 0.90 (R 0.87) | 3.2% | 153 | 36.0% | -14.8 (-0.70) | 22 -7.1, 23 +4.7, 24 -13.9, 25 -2.9, 26 +4.4 | stop 98 at -1.18 R, trail 7 at +0.48 R, target 48 at +2.02 R |
| XAUUSD R0 2025-03..2026-01 | +1,111.26 | 1.46 (R 1.02) | | 26 | | +0.3 (+0.04) | author: +1,328.43, PF 1.25, 30 trades | |
| XAUUSD F 2026-01-23..10-01 | -2,312.71 | 0.56 (R 1.20) | | 19 | | +2.3 (+0.36) | | |
| EURUSD S0 2022-01..2026-10, hq 100% | -191.12 | 0.87 (R 0.82) | 0.5% | 114 | 37.7% | -14.2 (-0.98) | 22 -3.2, 23 +1.7, 24 -7.6, 25 -0.7, 26 -4.4 | stop 71 at -1.10 R, trail 15 at +0.49 R, target 28 at +2.03 R |
| EURUSD R0 2025-03..2026-01 | -53.12 | 0.76 (R 0.73) | | 14 | | -2.9 (-0.55) | author: +508.05, PF 2.28, 25 trades | |
| EURUSD F 2026-01-23..10-01 | -3.41 | 0.97 (R 0.55) | | 14 | | -4.4 (-1.01) | | |

- **Gate A fails on both symbols:**
  - XAUUSD: PF 0.90; 2022-24 -16.3 R.
  - EURUSD: PF 0.87, 114 trades; 2022-24 -9.1 R and 2025-26 -5.1 R.
- **Forward check (F):**
  - XAUUSD: +2.3 R (t 0.36, noise) but -2,312.71 USD, because the wins came on tight stops and the losses on wide ones.
  - EURUSD: -4.4 R.
- **No out-of-sample run.** Closed; the user also said "skip it".
- **Replication:**
  - XAUUSD is close in USD (+1,111 vs +1,328, 26 vs 30 trades). That window is about zero in R, and the other years lose.
  - EURUSD does not replicate (14 trades vs 25; -53 vs +508 USD). The model reads the tick volume and the server hour,
    so broker data changes its signals.
- **Refused orders:**
  - Counts: 21 buy limits on XAUUSD and 38 on EURUSD, all "Invalid stops".
  - Cause: the latest pivot low can sit above the latest pivot high, which puts the stop above the entry. This is the
    EA's own logic and was not changed.
- **Expectation check:**
  - PF in R 0.82-0.87, slightly below the expected 0.85-1.10.
  - Trades 114-153, as expected.
- **Removed** per the leftovers rule:
  - `mql5/Market_Structure_Onnx_EA.mq5`, its profile and the MT5 copies (the source is in git at c5b5206);
  - `MQL5/Files/market_structure.onnx` (URL and MD5 above).

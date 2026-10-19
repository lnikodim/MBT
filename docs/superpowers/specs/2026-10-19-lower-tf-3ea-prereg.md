# Donchian, RSI_Reversal and MA_Channel on lower timeframes (pre-registration)

Date: 2026-10-19. User: "can you test all other EAs on lower timeframes too to compare them with the live setup?", after
MACD's M15/M30 test (no candidate, spec 2026-10-19-macd-m15-m30-prereg.md). Server: Darwinex-Demo, the user's choice
for the timeframe comparison.

## Runs (`reports/macd_tf/lower_tf_3ea.py`, Darwinex-Demo, real ticks, 2022-01-01..2026-10-01, 1% risk)
Release builds with defaults, changing only `InpTimeframe` and the tester period. That is two steps below each live
timeframe:
| EA | live (control) | lower cells | fixed higher-timeframe parts |
|---|---|---|---|
| Donchian_Breakout_EA v1.02 | H4 | H2, H1 | H4 EMA200 trend filter |
| RSI_Reversal_EA v1.21 | H6 | H4, H2 | H12 SMA250 filter; SL/TP/trail in % of price |
| MA_Channel_EA v1.02 | H1 | M30, M15 | none (trend filter off) |
Channel, ATR, RSI and SMA lengths count bars of the signal timeframe, so a lower timeframe also shortens their lookback
in time.

## Checks
- Gate A per cell: trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- Joint: the 4-EA prop_mc on Darwinex real ticks (--bt-risk 1.0, --risk 0.3,0.5, 10k sims, seeds 1-3). The live set is
  MACD H1 (`macdtf_h1_20261019_210429`) plus the three controls. Each lower cell is scored in place of its EA's live log.
- Reported, not gated: the standalone prop_mc per cell, and the most positions held at once (RSI has no position cap).
- Darwinex parity of the release builds, from the controls: Donchian against `donch_a1_pub_20261013_095001` and RSI
  against `rsi_ctl_20261014_125232`. The entry differences have to fit the change list of spec
  2026-10-18-eacore-correctness-prereg.md: a reopen bar, a spread retry, a displacement or a moved exit. MA_Channel has no
  Darwinex real-tick control. Its H1 control is its first Darwinex real-tick run (Gate A).

## Hypothesis
As with MACD, lower timeframes give more trades at a lower R per trade. Donchian v1.00 on H1 already failed Gate A,
with different inputs. Expected: Donchian H2/H1 PF 1.1-1.4; RSI H4 close to H6 but with more stacking, and H2 weaker;
MA_Channel M30/M15 PF 1.0-1.3. No cell beats the live joint on all seeds.

## Decision rule
A lower cell is a candidate only if it passes Gate A and its joint P(pass both) at 0.3% is >= the live joint on all 3
seeds. A candidate then gets a plateau test, pre-registered separately. Otherwise that EA's lower timeframes are closed
and the live timeframe stays. No retuning in this round.

## Outcome (2026-10-19, Darwinex-Demo, history quality 100%, log `reports/macd_tf/lower_tf_3ea.log`)
| EA / timeframe | trades | PF | equity DD | net R (per trade) | R 2022-24 / 2025-26 | most open | Gate A | alone @0.3% | joint @0.3% / 0.5%, seeds 1-3 |
|---|---|---|---|---|---|---|---|---|---|
| **live set** | | | | | | | | | **94.1/84.2, 93.9/84.7, 93.7/84.2** |
| Donchian H4 (live) | 157 | 1.67 | 10.1% | +54.7 (+0.348) | +19.8 / +34.9 | 1 | pass | 0.2% | |
| Donchian H2 | 286 | 1.18 | 28.5% | +32.0 (+0.112) | -4.3 / +36.3 | 1 | fail | 0.3-0.4% | 92.3/82.0, 92.1/82.4, 92.1/81.9 |
| Donchian H1 | 486 | 1.06 | 32.0% | +22.4 (+0.046) | -15.5 / +37.9 | 1 | fail | 1.5-1.8% | 90.2/77.8, 90.6/78.1, 90.2/78.0 |
| RSI H6 (live) | 362 | 1.58 | 13.3% | +99.1 (+0.274) | +46.0 / +53.1 | 5 | pass | 17.5-17.9% | |
| RSI H4 | 553 | 1.56 | 25.3% | +150.6 (+0.272) | +79.7 / +70.9 | 8 | pass | 40.8-41.2% | 93.3/82.6, 93.4/82.5, 93.5/82.5 |
| RSI H2 | 1083 | 1.30 | 50.9% | +195.6 (+0.181) | +107.8 / +87.8 | 18 | pass | 50.2-50.9% | 86.8/71.0, 86.8/70.7, 86.4/71.0 |
| MA_Channel H1 (live) | 299 | 1.49 | 12.5% | +89.1 (+0.298) | +52.1 / +37.1 | 1 | pass | 16.6-17.0% | |
| MA_Channel M30 | 611 | 1.08 | 30.2% | +34.8 (+0.057) | +18.4 / +16.4 | 1 | pass | 8.7-9.0% | 88.4/75.2, 88.2/75.5, 88.6/75.1 |
| MA_Channel M15 | 1223 | 0.95 | 46.7% | -14.4 (-0.012) | -20.7 / +6.3 | 1 | fail | 11.0-11.1% | 76.9/60.0, 76.9/60.6, 77.2/60.5 |

**No candidate.** Every lower-timeframe swap lowers the joint, so the live timeframes stay and these lower ones are closed.
- **Donchian and MA_Channel** lose most of their edge per trade; Donchian H2/H1 and MA_Channel M15 fail Gate A.
- **RSI H4** is the one near-miss. It keeps H6's R per trade (+0.27) and trades 1.5 times as often, so it doubles the
  standalone pass rate. In the 4-EA joint it is 0.4-0.8 points lower at 0.3% and about 2 points lower at 0.5%. Its
  drawdown doubles (25% vs 13%) and up to 8 positions stack.
- **RSI H2** stacks up to 18 positions: 5.4% open risk at 0.3%, above FTMO's 5% daily limit. prop_mc sees only closed
  trades, so even its 86-87% overstates it.

The hypothesis held, except that RSI H4 was stronger than expected on its own.

Side results:
- These runs are the Darwinex real-tick numbers for the new builds. The live joint is 93.7-94.1 / 84.2-84.7. The earlier
  Darwinex figure, 94.5 / 85.1, used MA_Channel on 1-min OHLC.
- MA_Channel v1.02 passes Gate A on Darwinex real ticks: PF 1.49 vs 1.55 on 1-min OHLC.

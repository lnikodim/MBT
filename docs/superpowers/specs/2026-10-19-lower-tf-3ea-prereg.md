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

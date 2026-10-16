# EMA_RSI_CCI_EA: ahmedabbas' "Simple RSI & EMA high Profitable ratio Strategy" (pre-registration)

Date: 2026-10-16. User: "Now I want to test another similar EA: forexfactory.com/thread/599061-simple-rsi-ema-high-
profitable-ratio-strategy. Read the 1st post of this thread and ask questions if you are not sure how to proceed."
Source: first post by ahmedabbas, 16 Jul 2016, edited 16 Sep 2016 (archived copies 2017 and 2025; the attached
template and indicator zip are not archived). The post, literally:
- Time frame H1, H4. EMA 5 and EMA 12 on the close, RSI 21, CCI 80.
- Long: EMA 5 crosses above EMA 12 AND RSI (21) & CCI (80) > 50 level, both green, RSI candles green. Short mirrored.
- Stop about 35-60 pips by the pair's volatility (GBPUSD more volatile, EURUSD less); target "as you perceive feasible".
- Exit long when EMA 5 crosses back below EMA 12 or when RSI 21 & CCI 80 < 50; short mirrored.
- In the same thread (post 12, trenki2, 2016): EURUSD H1 2001-2016 with a 30-pip stop "fails badly" with 5/12/21.
  Post 8 (emmanuel7788) suggested the Kennedy MA price channel instead, the PDF behind MA_Channel_EA.

User decisions (AskUserQuestion, 2026-10-16): symbols EURUSD and GBPUSD; CCI level 0 (its midline; RSI level 50);
stops 35 and 60 pips, no target; exit when the EMAs cross back OR both RSI and CCI are back across their levels.
My reading, fixed here: the EMA cross and the RSI / CCI condition must hold on the same closed bar; "RSI candles
green" is RSI > 50 again and adds nothing; both sides are traded; one position at a time; a same-bar reversal is
allowed when the exit bar is also an opposite entry.

## Hypothesis
An EMA 5/12 cross is a fast trend-follower; RSI 21 > 50 and CCI 80 > 0 on the cross bar are mostly already true when
a cross happens, so the filters remove few trades. With no target and an indicator exit that fires on the first
counter-cross, the system holds trades for hours to a few days and lives on the few that trend. trenki2's 2016 test
already failed on EURUSD H1. Expected: H1 PF 0.85-1.0 (fail), H4 PF 0.95-1.15 with fewer than 150 trades on at
least one symbol, wider stop slightly better (fewer stop-outs before the indicator exit). Most likely 0 passes.

## EA (`mql5/EMA_RSI_CCI_EA.mq5` v1.00, EACore, magic 261018, comment EMARC, spread cap 30 points)
Inputs `InpFastEMA 5`, `InpSlowEMA 12`, `InpRsiPeriod 21`, `InpRsiLevel 50` (sells below 100 - level),
`InpCciPeriod 80`, `InpCciLevel 0` (sells below -level), `InpStopPips 35`, `InpTargetPips 0` (off), `InpAllowShort
true`. All reads on the closed bar; pip = 10 points on 3/5-digit symbols. `EMARC SIGNAL` and `EMARC EXIT` k=v lines.
Self-check `scripts/ema_rsi_cci_selfcheck.py`: a 6-month EURUSD H1 run; every signal line satisfies cross + RSI + CCI,
every expert exit satisfies cross-back or both-below, stops = 35 pips, no targets, one position at a time.

## Stage A (`reports/emarc/stage_a.py`, Darwinex 1-min OHLC, 2022-01-01..2026-10-01, 1% risk)
8 cells: {EURUSD, GBPUSD} x {H1, H4} x stop {35, 60} pips. Gate A per cell: trades >= 150, tester PF >= 1.00, net R
> 0 in both 2022-24 and 2025-26. Plateau for passers: slow EMA 10 / 15 and CCI 60 / 100 (4 runs, mean PF >= 1.00 and
>= 3 of 4 profitable). Then prop_mc and the joint rule against the account's Darwinex control, now four EAs (MACD
v1.45, Donchian v1.01, RSI_Reversal v1.20, MA_Channel v1.01): joint pass >= control at both 0.3% and 0.5%, p95 DD at
0.5% not more than 1 pt worse.

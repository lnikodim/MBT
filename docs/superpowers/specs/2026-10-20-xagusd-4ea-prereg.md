# The 4 EAs on XAGUSD (pre-registration)

Date: 2026-10-20. User: "let's try another experiment: backtest XAGUSD with all 4 EAs on their common timeframes".
Server: Darwinex-Demo, the user's choice, which keeps the gold numbers of 2026-10-19 directly comparable.

## Runs (`reports/macd_tf/xagusd_4ea.py`, Darwinex-Demo, XAGUSD, real ticks, 2022-01-01..2026-10-01, 1% risk)
Release builds with their gold defaults on their live timeframes: MACD_Cross_EA v1.46 H1, Donchian_Breakout_EA v1.02
H4, RSI_Reversal_EA v1.21 H6 and MA_Channel_EA v1.02 H1. Nothing is retuned for silver. The % stops and targets (MACD
0.5% / 3.75%, RSI 1% / 5% with a 1% trail) are tight against silver's larger % moves. Donchian and MA_Channel use ATR
stops, which scale with the market. The spread cap of 150 points is $0.15 on silver, well above its usual 2-3 cents.
History quality is reported. If XAGUSD real ticks start after 2022, the gate uses the covered years.

## Checks
- Gate A per EA: trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- prop_mc (--bt-risk 1.0, --risk 0.3,0.5, 10k sims, seeds 1-3), P(pass both phases):
  - the silver 4-EA set on its own;
  - each Gate A passer added to the gold live set (MACD H1 `macdtf_h1_20261019_210429`, Donchian H4
    `lowtf_donch_h4_20261019_212257`, RSI H6 `lowtf_rsi_h6_20261019_213004`, MA_Channel H1
    `lowtf_mach_h1_20261019_214347`; joint 93.7-94.1 / 84.2-84.7);
  - all passers added together.
- Reported: the correlation of daily R between the gold set and the silver set, and the most positions open at once on
  gold + silver.

## Hypothesis
Silver moves like a noisier, more volatile gold. Expected: the ATR-stop EAs (Donchian, MA_Channel) hold up better than
the %-stop EAs (MACD, RSI). One or two EAs pass Gate A. Adding passers to the gold set moves the joint by less than 2
points: the extra trades help, but silver's daily R correlates strongly with gold's, so drawdowns stack.

## Decision rule
A silver EA is a candidate to add to the account only if it passes Gate A and gold-4 + it scores >= the gold-4 joint at
0.3% on all 3 seeds. A candidate then gets a plateau test and an exposure check (gold + silver open risk against FTMO's
5% daily limit), pre-registered separately. Otherwise silver is closed for these EAs as they are. No retuning in this
round.

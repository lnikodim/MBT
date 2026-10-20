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

## Outcome (2026-10-20, Darwinex-Demo, XAGUSD history quality 99%, real ticks from 2022-01, median entry spread 12 points, log `reports/macd_tf/xagusd_4ea.log`)
| EA (timeframe) | trades | PF | equity DD | net R (per trade) | R 2022-24 / 2025-26 | Gate A | alone @0.3% |
|---|---|---|---|---|---|---|---|
| MACD (H1) | 1036 | 0.94 | 63.1% | +0.7 (+0.001) | -27.5 / +28.2 | fail | 13.1-13.9% |
| Donchian (H4) | 140 | 1.36 | 10.9% | +31.5 (+0.225) | +14.0 / +17.5 | fail (trades < 150) | 0.0% |
| RSI_Reversal (H6) | 384 | 0.73 | 53.0% | -57.8 (-0.150) | -38.9 / -18.9 | fail | 0.0% |
| MA_Channel (H1) | 303 | 1.05 | 20.6% | +15.3 (+0.050) | +18.9 / -3.6 | fail | 1.7-1.8% |

Joint P(pass both) at 0.3% / 0.5%: silver 4-EA 20.0/27.2, 19.6/27.2, 19.8/26.8 vs gold 4-EA 94.1/84.2, 93.9/84.7, 93.7/84.2.
Daily R correlation between the gold set and the silver set is +0.19 over 1,140 days. Gold + silver would hold up to 11
positions at once, against 8 for gold alone.

**No candidate: 0 of 4 pass Gate A, so silver is closed for these EAs as they are.**
- **%-stop EAs:** these failed as expected. MACD is breakeven with a 63% drawdown, and RSI loses in both regimes
  (PF 0.73).
- **ATR-stop EAs:** these held up better, also as expected. MA_Channel's edge is thin (PF 1.05) and it loses in
  2025-26.
- **Donchian is the only near-miss:** PF 1.36, profitable in both regimes, 10.9% DD, but 140 trades, below the 150
  minimum. Under the rule it was not joint-tested.
- **The correlation hypothesis was wrong.** At +0.19, silver diversifies gold more than expected. The obstacle is that
  the gold-tuned EAs have little edge on silver.

A silver-specific version (stops scaled to silver's volatility) would be a new, separately pre-registered test.

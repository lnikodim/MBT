# MA_Channel_EA with its trend filter on (pre-registration, 2026-10-27)

**Trigger:** on the FTMO demo MA_CH was long 0.09 XAUUSD while MACD_X was short 0.24; the user asked why they are opposite, and then said "go" to testing the EA's optional trend filter. Cause: MA_Channel is long-only with no trend filter (`InpTrendEMA` 0),
MACD_Cross filters on the H4 EMA(200) and gold is below it, so MACD only sells. A replay of October on Darwinex data shows the pattern: MACD 14 sells and no buys (+256 USD at 0.02 lot), MA_CH 6 buys, 5 of them losing (-109 USD at 0.01 lot, PF 0.31).
The input exists: with `InpTrendEMA` > 0 a buy is allowed only if the close of `InpTrendTF` (last closed bar) is above its EMA. Sells stay off.

## Question
Does a trend filter keep what made MA_Channel a live EA (2022-26 gold bull market) and avoid buying pullbacks in a downtrend, and does the seven-EA portfolio keep or improve its return/DD (21.0) when the filter is on?

## Design (inputs only; no code change; validated-run inputs, XAUUSD H1, real ticks, 100,000 USD, leverage 20, Darwinex-Demo, as the live-set run `lowtf_mach_h1_20261019_214347`)
| id | trend filter |
|---|---|
| t0 | off (the live EA) |
| t1 | H4 EMA 200 (the filter MACD_Cross already uses) |
| t2 | H4 EMA 100 |
| t3 | D1 EMA 50 |
| t4 | D1 EMA 100 |
Windows: the validated 2022-01..2026-10 run (reported as 2022-24 and 2025-26 by closing year) and an untouched **2019-01..2021-12** run, for each variant (10 runs).
**Rule (written before the runs):** a variant is an improvement only if, in each of 2019-21, 2022-24 and 2025-26, its PF and its return/DD are at least the baseline's, and it keeps at least 60% of the baseline's trades in 2022-26;
then the portfolio test: the six live EAs plus NI225 (`reports/portfolio/dz_joint_ni225.py` machinery, 0.5% constant risk) with MA_CH's trades replaced by the variant's must show return/DD at least 21.0 and max DD no higher than the baseline's 15.93%.
Also reported (not part of the rule): what the filter does to the October 2026 buys.
Limits: 4 variants and the live EA was itself chosen on 2022-26, so a win is in-sample; the 2019-21 run is the only unseen window; a gold bull market (2022-26) favours long-only, so a filter has little to gain there and a lot to avoid in a downtrend that the sample barely contains.

## Outcome (2026-10-27; log `reports/oct25/machtf.log`): no filter variant passes; MA_Channel stays as it is
Per window (PF / net % of 100,000 / closed-trade drawdown / return per drawdown); 2022-24 and 2025-26 are halves of the validated 2022-26 run:
| id | 2019-21 | 2022-24 | 2025-26 | 2022-26 (trades, PF, net, DD) | portfolio (7 EAs): %/yr, max DD, ret/DD |
|---|---|---|---|---|---|
| t0 off (live) | 1.14 / +17.2 / 18.2 / 0.9 (204 trades) | 1.50 / +62.1 / 11.4 / 5.4 | 1.50 / +67.3 / 26.6 / 2.5 | 299, 1.50, +129.4%, 26.6% | +70.6, 15.89%, **21.1** |
| t1 H4 EMA 200 | 1.30 / +23.0 / 9.1 / 2.5 | 1.30 / +25.1 / 9.5 / 2.6 | 1.62 / +46.7 / 23.0 / 2.0 | 218, 1.45, +71.7%, 23.0% | +67.3, 17.82%, 17.9 |
| t2 H4 EMA 100 | 1.10 / +8.2 / 11.9 / 0.7 | 1.42 / +33.0 / 10.1 / 3.3 | 1.93 / +65.5 / 15.1 / 4.3 | 204, 1.66, +98.5%, 15.1% | +68.8, 17.20%, 19.0 |
| t3 D1 EMA 50 | 1.29 / +22.9 / 11.2 / 2.0 | 1.25 / +21.3 / 9.7 / 2.2 | 1.67 / +47.2 / 18.6 / 2.5 | 223, 1.44, +68.5%, 18.6% | +67.1, 17.90%, 17.8 |
| t4 D1 EMA 100 | 1.29 / +24.5 / 11.7 / 2.1 | 1.43 / +39.9 / 12.1 / 3.3 | 1.54 / +49.5 / 31.5 / 1.6 | 237, 1.48, +89.4%, 31.5% | +68.4, 17.06%, 19.0 |
- **Rule:** every variant misses it. 2022-24, the bull market the EA was validated on, is the window each fails (PF 1.25-1.43 against 1.50, return/DD 2.2-3.3 against 5.4), and t1, t2 and t4 also miss in a second window.
- **Portfolio:** all four lower the seven-EA return/DD (17.8-19.0 against 21.1) and raise max drawdown (17.06-17.90% against 15.89%); the worst month improves only for t1 and t2 (-9.66 / -9.38 against -10.43).
- **What the filters do buy:** protection in downtrend stretches. 2019-21 PF 1.29-1.30 for t1, t3 and t4 (1.14 off); and over 2026-09-20..10-28 on Darwinex data the live EA takes 8 buys, 7 of them losing about 1,000 USD each (net -4,861 USD, PF 0.26, one winner +1,705), while t1, t3 and t4 take only the first (-668) and t2 none.
- **What they cost:** about half the 2022-24 profit (+21% to +40% against +62%) and, over 2022-26, 31% to 45% of the net (+68% to +98% against +129%). t2 is the best standalone shape over 2022-26 (PF 1.66, drawdown 15.1% against 26.6%) but still loses 2019-21 ground (PF 1.10) and the portfolio ratio.
- **Verdict:** keep `InpTrendEMA` 0 in the live sets. The losses behind the opposite MACD and MA_CH positions are the downtrend cost of a long-only pullback rule; the portfolio test says the cure costs more than it saves on this sample. The five-week October window (8 trades) is too short to overturn four multi-year windows.
- **Not done:** no live input changed; no variant beyond the four pre-registered. A future lever would be a pause rule for a long-only EA after N consecutive losses, which needs its own pre-registration.

# mql5.com Code Base experts, pages 11-20: screen (pre-registration)

Date: 2026-10-26. User: "continue scanning the mql5 pages" (after Turnaround Tuesday was dropped for needing the author's licence). Server: Darwinex-Demo.
The goal, restated by the user: EAs that **strengthen the live portfolio as add-ons**, not one EA that drives the account (spec 2026-10-26-addon-portfolio-prereg.md).

## Step 0, inspection (no runs)
- **Listing:** pages 11-20, 400 entries (EAs from 2010-2019, mostly teaching and showcase code). 4 were tested before; 343 candidates after dropping tools, grids,
  martingales, snippets and neural-network titles by name; 207 after also dropping the `Exp_*` family (it needs custom indicators).
- **Downloaded and scanned:** all 207 sources (one request every 6 seconds). Scan results: 168 clean; 16 missing a custom indicator or include; 3 with web / DLL calls; 20 grid-word hits.
- **Rejected at inspection:**
  - martingale, grid, lot-multiplier or hedge-multiplier code: Ilan iMA, Tengri, Lego EA, MT5-RingSystemEA, Periodic Range Breakout 2.0, RSI_Expert_v2.0, Proffessor v3, Vinci EA, GoldWarrior02b, VR---Moving;
  - web or DLL calls: Candle Pattern EA, RenkoChart, EA potential entries;
  - the missing-indicator ones, a duplicate of an EA already tested (Puria method), and Hangseng Trader (HSI does not exist on Darwinex).
- **Kept after reading the matches:** RSI Levels, Parabolic SAR Expert and Range BreakOut EA (the "grid" is only a wizard error message), and Bollinger Band Two MA and ZigZag (it writes a state file).
- **Compile:** 25 of the 171 do not compile on the current MetaEditor (errors in the unmodified source) and are rejected without patching: 2415, 16783, 16952, 17057, 20501, 20635, 20815, 20860, 20879, 20881, 20886, 21124, 21147, 21299, 21440, 21661, 21733, 21743, 21983, 22145, 22261, 22274, 22314, 22384, 30304. **146 EAs remain,** copied unchanged as `mql5/CB<code>_EA.mq5`; bundled indicators and includes installed in MT5 and listed in a manifest for removal. Compile results are listed in the outcome.

## Cells (real ticks, 10,000 USD, 1:100, source defaults)
One cell per EA on **EURUSD H1**, except where the title states a pair or timeframe: 25774 GbpChf (GBPCHF H1), 21196 Alexav D1 Profit GBPUSD (GBPUSD D1), 25249 Lavika EURGBP/EURUSD (EURGBP H1),
21595 GBP9AM (GBPUSD H1), 21679 Forex Fraus M1 (EURUSD M5). The symbol is a guess for most EAs: none states one in its page title. Multiple testing: 171 cells, so a few passes at the
screen are expected by chance; the later steps are the filter.

## Steps (the framework as amended on 2026-10-26)
1. **Screen, 2024-01-01..2026-10-01:** reject if trades < 40, PF < 1.00, net <= 0 or a stop-out.
2. **Gate A:** a 2022-01-01..2024-01-01 run joined with the screen run: trades >= 150 (80 for a weekly rule), PF >= 1.00, net > 0 in 2022-24 and in 2025-26.
3. **Add-on evidence, 2019-01-01..2022-01-01:** net > 0 and PF >= 1.0 (no t bar, no standalone sizing step; inconclusive if history < 90%).
4. **Add-on test** (`reports/portfolio/addon_joint.py`): the seven live EAs at 0.5% risk with and without the candidate sized to a 1% and 2% standalone drawdown; add it if return/DD does not fall,
   max DD rises by <= 1.0 point and the worst month does not worsen by more than 1.0 point. Daily and monthly correlation reported.
5. **Eligibility to deploy** also needs: source available, no licence or approval from a third party, and a run on the target broker (IC Markets / FTMO / Darwinex Zero).

## Expectation (written before the runs)
- **Almost all reject at the screen.** The 49 EAs of pages 1-10 gave 7 screen passes, 0 past 2019-21; older teaching EAs have no multi-year tests on current data.
- **Among 171 cells, about 5 to 12 screen passes by chance or small edge,** and 0 to 2 reaching the add-on test. Many will place 0 trades (the same rate as pages 1-10: 14 of 49).
- **A pass at step 4 would be small** (about +0.3 to +1 point a year on the live set), as with Turnaround Tuesday.

## EAs
2415 JK Synchro; 16783 2MA Bunny Cross Expert; 16918 MACD Stochastic 2; 16952 JS-MA-Day; 17057 BreakOut15; 17066 Price Rollback; 20127 Fractured Fractals; 20132 BHS system; 20148 Ichimoku; 20149 Hans123_Trader; 20166 Alexav SpeedUp M1; 20184 FarhadCrab1; 20194 Trend RDS; 20195 Aeron JJN Scalper EA; 20208 SV v.4.2.5; 20353 Bollinger Bands N position; 20397 Hans123_Trader v2; 20424 Universal 1.64; 20461 maximus_vX lite; 20492 TrueSort_1100; 20493 EMA_WMA v2; 20500 N-_Candles_v7; 20501 Price Impulse; 20545 Momentum-M15; 20548 Brandy; 20554 Firebird v0.60; 20565 Absorption; 20585 Doji Arrows; 20591 BSS 1_0; 20621 UniversalMACrossEA; 20635 TwoBarsComparison; 20668 PLC (penetration of the la; 20672 AO Lightning; 20679 Surefirething; 20705 RSI Bollinger Bands EA; 20708 NeuroNirvamanEA; 20752 Bands 2; 20779 AIS2 Trading Robot; 20815 Night Flat Trade; 20827 MACD and SAR; 20860 TradingBoxing; 20879 Previous Candle Breakdown; 20881 EA Stochastic; 20886 Two MA one RSI; 20936 Interceptor; 21050 Volume trader; 21086 ExFractals; 21124 Area MACD; 21147 Candle shadows v1; 21196 Alexav D1 Profit GBPUSD (GBPUSD D1); 21298 CCFp EA; 21299 Auto ADX; 21300 Bollinger Band Two MA and ; 21311 Urdala_Trol; 21345 AOCCI; 21348 cloud's trade 2; 21374 SimplePivot; 21387 Arttrader_v1_5; 21394 MostasHaR15 Pivot; 21440 Return Strategy; 21457 breakdown; 21495 3sma; 21499 One MA EA; 21563 Market Capture; 21595 GBP9AM (GBPUSD H1); 21616 Freeman; 21629 Sidus; 21639 Dematus; 21661 Expert Ichimoku; 21672 1H EUR_USD (EURUSD H1); 21679 Forex Fraus M1 (EURUSD M5); 21727 Avalanche AV; 21733 Above Below MA; 21743 55 MA; 21759 RSI_Expert; 21774 Nextbar; 21852 Russian20-hp1; 21878 Gordago EA; 21929 Flat Trend EA; 21937 ssb5_123; 21962 VR---BUCH; 21976 Basic CCI RSI; 21983 Previous Candle Breakdown ; 22003 Breadandbutter2; 22006 NeuroNirvamanEA 2; 22016 MySystem; 22021 Daydream; 22033 FT_CCI; 22087 Sensitive; 22098 Ketty; 22100 Sprut; 22122 Tunnel Method; 22127 One Two Three; 22142 Rollback system; 22145 Previous Candle Breakdown ; 22261 freeman; 22274 OHLC Stochastic; 22304 Support and Resistance Tra; 22314 Little EA; 22353 MA Envelopes; 22384 BARS Alligator; 22398 High frequency volatility  (EURUSD H1); 22409 Autotrader Momentum; 22465 Two PerBar; 22595 Constituents EA; 22609 VR---STEALS; 22647 Starter; 22659 Tunnel gen4; 22662 RSI RFTL EA; 22678 ScalpWiz 9001; 22693 Peceptron_Mult; 22703 Extreme EA; 22718 NRTR_Revers; 22778 Alligator Simple v1.0; 22788 Fluctuate; 22870 Bago EA; 22884 LBS; 22889 Precipice; 22906 GlamTrader; 22914 Contrarian trade MA; 22933 Bruno; 22977 Secwenta; 23027 Pendulum; 23029 BADX; 23039 Parabolic SAR EA; 23040 Simple EA MA plus MACD; 23061 FT CCI MA; 23073 Bronze Warrioir; 23108 E-Friday; 23152 RSI EA v2; 23155 Yesterday Today; 23201 Day Trading PAMXA; 23220 Gold Dust; 23223 Gap DM; 23234 BullsBearsEyes EA; 23239 EMA LWMA RSI; 23255 TDSGlobal; 23288 Cidomo; 23297 Hoop master; 23325 MACD Cleaner; 23334 Daily range; 23344 VHF EA; 23348 Hoop master 2; 23358 Three Typical Candles; 23383 iMA iSAR EA; 23394 FitFul 13; 23421 Fraktrak xonax; 23431 Three timeframes; 23434 iMA iStdDev; 23443 Breakdown catcher; 23452 Bill Williams; 23484 JS Signal Baes; 23487 WE TRUST; 23495 Starter; 23499 Ingrit; 23542 Plan X; 23556 Plateau; 23589 MA Trend; 23595 ADX MACD Deev; 25009 Explosion5; 25249 Lavika EURGBP/EURUSD (EURGBP H1); 25774 GbpChf (GBPCHF H1); 26317 RSI Levels Expert Advisor; 26333 Parabolic SAR Expert; 26451 Range BreakOut EA; 27938 Rapid Doji EA; 29797 custom trail-stop by MA - ; 30304 Range Follower; 31843 Strategy - Set And Forget ; 32616 EA Fibonacci Potential Ent; 32695 Simple EA using Bollinger,

## Amendment 1 (2026-10-26, during the run): logging-only strip for EAs that flood the tester log
User: "when you detect EAs that heavily use logging, clean up the logs from the core logic if they are not necessary for the strategy".
- **Trigger:** Universal 1.64 (20424) wrote a message on every tick: 20 GB of agent log, runs of 662 s and 873 s against 30-90 s for similar EAs, free disk down from 116 GB to 14 GB.
- **Rule from here on:** before each remaining cell, a two-week probe (2024-01-01..2024-01-15) measures the agent log's on-disk growth. More than 100 MB means heavy logging.
  `scripts/strip_logging.py` then renames `Print`, `PrintFormat`, `printf` and `Alert` to `NoLog` (arguments are still evaluated; nothing is written), recompiles, and re-runs the
  probe. The stripped version is used only if the probe's trades and net profit are **identical** to the unstripped probe; otherwise the original is restored.
  The runner also truncates the agent log after any run that leaves more than 2 GB on disk.
- **Not a strategy change:** no signal, order or risk code is touched. Results of cells that ran unstripped (all before this amendment) stand.
- **Detection by measurement:** the number of Print calls does not identify a flood (143 of 146 sources have some).
- **Applied (listed in `reports/oct25/stripped.log` and the outcome):** none yet.

## Outcome so far (14 of 146 cells screened when this was written)
- **Universal 1.64 (20424), EURUSD H1, 0.20 lot:** screen +1,024.71 USD (PF 1.34, DD 4.6%, 296 trades, t +2.27); Gate A joined +1,289.57 USD (PF 1.19, DD 6.2%; 2022-24 +635, 2025-26 +655);
  **2019-21 -1,425.43 USD, PF 0.67, t -3.32: add-on evidence fails, closed.**
- **Hans123_Trader (20149):** Gate A passed (+1,517 USD, DD 31.5%, 2022-24 only +48), 2019-21 -1,145.73 USD: closed. **20195, 20397:** failed Gate A. 

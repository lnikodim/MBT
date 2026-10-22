# Crabel_ORB_EA on Darwinex GDAXI (pre-registration)

Date: 2026-10-22. After the Code Base research (best list, 1,688 entries screened), the recommendation was Crabel ORB on
the DAX. User: "go ahead, test Crabel ORB on Darwinex GDAXI". Server: Darwinex-Demo (GDAXI = DE40/GER40 there; real
ticks from 2019 at 99% history quality, spec 2026-10-22-ger40-evening-coil).

**The EA:** "Opening Range Breakout with NR4 / NR7 Contraction Filters" (mql5.com code 78259), `Crabel_ORB_Gold.mq5`
v1.06 by P. Nambala, MD5 a9f2630a…. It is copied unchanged to `mql5/Crabel_ORB_EA.mq5` and renamed per the naming
convention. It compiles with 0 errors and 0 warnings. The idea is Toby Crabel's (1990): after a narrow-range day the next
day tends to run from its open. Each day:
- **Session start:** 08:00 London time (with UK and server DST handled), which is the DAX cash open.
- **Levels:** session open +/- an offset. The default offset is the "stretch": the average distance from each of the
  last 10 sessions' opens to its nearest extreme.
- **Orders:** a buy stop and a sell stop at those levels, each with its stop at the opposite level; one cancels the
  other.
- **Timing:** orders live 180 minutes, and the position is closed a set time after the start. No take profit.
- **Day filter on yesterday's D1 bar:** none (the control), NR4, NR7, inside day + NR4, 3-bar NR, or any of them.
  Optional skip after a wide-range day.
- **Risk:** 0.5% of balance per trade (lots via OrderCalcProfit), daily loss limit 3%, 1 fill per session, spread
  filter of 10% of the offset.

**Review before the run:**
- **The default exit breaks on GDAXI.** Start + 780 min = 23:00 server, and Darwinex GDAXI stops trading at 23:00: the
  GER40 EA's session closes all landed at 22:58. With no tick at the exit time, an open position would carry overnight
  to the next day's exit. The exit is therefore set to **770 min (22:50 server)**: the author's "flat before the daily
  break", applied to the DAX close. Holds over 14 hours are reported.
- **The default server zone is GMT+0.** Darwinex is GMT+2/+3 with US DST, so `InpServerTimeZone` = 1 (`TZ_NY_CLOSE`).
- **The default magic 260101 is our `StrategyTemplate.mq5` default,** so `InpMagic` = 261024.
- The rest of the code is clean: no DLL, web or file calls, a free-margin check, and one cancels the other.

## Runs (`reports/crabel/crabel_eval.py`; Darwinex-Demo, GDAXI, H1 chart (the EA reads M1 and D1), real ticks, 100k USD, 1:100)
Inputs: compiled defaults, plus the three settings above. Each of the 6 day filters (`InpDayFilter` 0-5) runs in:
- **train:** 2019-01-01..2022-01-01;
- **holdout:** 2022-01-01..2026-10-01.

That is 12 runs.

**R per trade** = net (profit + commission + swap) / (stop distance x volume x value per point).
- The stop is the opposite level, read from the Orders table.
- The value per point comes from the trade's gross P/L / (signed price move x volume), or the run's median when the
  move is under a tenth of the stop distance.
- A stop exit should be about -1 R.

## Selection and checks (fixed now)
- **Train pick:** of the 6 filters, the control included, the one with the highest mean-R t-statistic in train among
  those with >= 60 trades and t > 0. If none qualifies, no pick.
- **Holdout check for the pick:**
  - Gate A: trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26;
  - mean-R t >= 1.65.
- **Crabel's hypothesis (reported):** whether the pick's mean R (if it is a filter) beats the control's in both
  windows.
- **Reported per run:**
  - net, PF, max equity DD, trades, win rate, mean R (t);
  - long and short split, exits;
  - holds over 14 hours;
  - armed sessions, no-fill sessions, spread skips and order failures from the agent log;
  - the "Settings" start-time line (expected 10:00 server, 11:00 in the US/EU DST gap weeks).
- **If the pick passes:** the joint with the live set (gold 4-EA + DonchianTrend + Monday) is run next, reported.

## Hypothesis
- **Control (a plain opening-range breakout at the DAX open):** PF about 1.0-1.1 after costs.
- **Filters:** NR4 or "any" adds a little mean R, and the pick is one of those. NR7, IDnr4 and 3-bar NR are too rare
  to reach Gate A's 150 holdout trades.
- **Holdout:** t under 1.65. The chance the pick passes is about 20-25%.

## Decision rule
- **The pick passes the holdout check:** a candidate. The live-set joint, then an IC Markets check, are pre-registered
  before any deployment.
- **Otherwise:** closed, and leftovers are removed (user rule).

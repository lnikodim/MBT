# EACore v-next and MACD v1.46: correctness fixes from the live-deals review (pre-registration)

Date: 2026-10-18. User: "go", approving the fixes proposed after the review of the live deals on IC Markets demo
53093587 and Darwinex demo 3000110062 (workflow of 5 analysts + 5 verifiers). These are correctness fixes, not edge
changes: they ship if the parity checks below pass, whichever way the R moves. No strategy input changes.

Builds before the change (also the live EC2 builds, MD5-identical, backed up in the session scratchpad):
MACD_Cross_EA v1.45, Donchian_Breakout_EA v1.01, RSI_Reversal_EA v1.20, MA_Channel_EA v1.01.
After: MACD v1.46, Donchian v1.02, RSI_Reversal v1.21, MA_Channel v1.02 (EACore changes reach every EACore EA).

## Changes
| # | Change | Where | Tester effect |
|---|---|---|---|
| 1 | A new bar is processed only at a tick inside the symbol's trade session (`SymbolInfoSessionTrade`; no session data for the day = open). On IC the first gold tick (01:00:00) comes before trading opens (01:02), so entries and the MA_Channel exit on that bar failed with 10018 and the bar was consumed. | EACore `Core_IsNewBar`, MACD new-bar check | IC: those bars move to the first tradable tick |
| 2 | A spread-delayed signal's retry window (`InpSpreadWaitMin`) counts from the moment it was delayed, not from the bar open. On H4/H6 the 00:00 bar's first tick is about 1 h after the bar open, so the 30-min window had already expired. | EACore `Core_Open`/`Core_RetryPending`, MACD copy | only where a signal is spread-delayed (none in the IC baseline; RSI and MACD on Darwinex) |
| 3 | A failed `Core_ClosePosition` is retried on every tick until the position is gone (the log already claimed this; nothing did it). | EACore | none expected (closes do not fail once #1 is in) |
| 4 | Late-signal guard, live only: no entry on a bar that opened before the EA was loaded (fresh attach, re-attach, restart mid-bar). Exits and state updates still run. | EACore `Core_Open`, MACD `OpenPosition` | none (skipped in the tester) |
| 5 | Daily stop latches for the rest of the server day (equity back above the floor no longer re-allows entries); EACore also recomputes start balances after an account switch, as MACD v1.44 does. | EACore, MACD | expected none (historical effect zero) |
| 6 | Trade log, live only: account login in the file name; on the first tick/transaction, closes made while the EA was not running are appended (high-water mark = last deal in the file); a deal is never written twice; `r_multiple` falls back to the entry deal's stop when the entry was not seen. | EACore, MACD | tester CSV name and rows unchanged |
| 7 | Single-instance lock, live only: a second chart with the same EA, symbol and magic refuses to start; an own-magic entry this instance did not place raises an Alert (second terminal on the account). | EACore, MACD | none (skipped in the tester) |
| 8 | MA_Channel: the pullback state is rebuilt on every init, and a failed rebuild leaves the bar unprocessed (retried next tick) instead of silently leaving state 0. | MA_Channel | expected none |
| 9 | MACD sizes lots with the live tick value (the EACore fix of 84cb9c9; MACD still cached it at init). | MACD | none on a USD tester account |
Not changed: Donchian and MA_Channel keep dropping spread-blocked entries (`EA_SPREAD_WAIT_MIN 0`, by design); RSI keeps
stacking positions (a cap was rejected jointly); the remove/parameter-change deletion of the last-bar variable stays
(#4 makes a re-processed bar harmless).

## Checks, IC Markets (`reports/portfolio/eacore_fix_parity.py`, ICMarketsEU-Demo, real ticks, 2022-01-01..2026-10-01, 1% risk, defaults)
New builds against the IC baseline runs `icm_macd_20261018_150138`, `icm_donch_20261018_150402`,
`icm_rsi_20261018_150509`, `icm_mach_20261018_150644`.
- P1 every baseline entry is in the new run (same signal bar and side), unless a recovered position displaced it (listed).
- P2 every new entry not in the baseline is on a bar whose first tick came before the trade session (01:00-01:01
  server), or follows from a displacement (listed).
- P3 no order or close fails with 10018 "market closed" in the new runs' agent log (stop modifications are counted
  separately; they retry every tick and are not affected by #1).
- P4 Gate A per EA (trades >= 150, PF >= 1.00, net R > 0 in 2022-24 and 2025-26).
- Report: joint prop_mc on the 4 new logs (--bt-risk 1.0, --risk 0.3,0.5, 10k sims, seeds 1-3) next to the baseline
  97.2/90.0, 97.0/89.5, 96.9/89.9.

## Hypothesis
#1 recovers the 10018 entries (MACD 14, Donchian 8, RSI up to 47 of which 32 had re-fired on a later bar, MA_Channel 9)
and moves 5 MA_Channel exits to 01:02. The verifiers could not sign the joint effect (MA_Channel about -10 R, the other
EAs' dropped entries net winners). Expected: P1-P4 pass, net R per EA within +/-15 R of the baseline, joint within +/-1.5
points. #2 to #9 leave the IC tester trades unchanged.

## Darwinex (needs the Mac terminal on Darwinex-Demo; the user switches accounts)
Same P1-P4 against the Darwinex real-tick controls (MACD `v145_default_20261011_092414`, Donchian
`donch_a1_pub_20261013_095001`, RSI `rsi_ctl_20261014_125232`); P2 also admits RSI/MACD entries recovered by #2. MA_Channel
had only a 1-min OHLC control: the v1.01 backup build and v1.02 both run on Darwinex real ticks, Gate A on each, then the
Darwinex 4-EA joint on real ticks.

## Live-only changes (#3, #4, #6, #7)
Not reachable in the tester. Checked by an independent code review before release, then by the user's demo drills when
deploying to the EC2 (the deployment is the user's): attach an EA mid-bar on a signal bar (expect "late signal" and no
order); attach the same EA to a second chart (expect it to refuse); the new CSV `<EA>_XAUUSD_<magic>_53093587_trades.csv`
holds the account's earlier EA closes once, with r_multiple filled.

## Decision rule
P1-P4 pass on IC: the new builds are the release candidates (Darwinex checks follow when the terminal is on Darwinex).
A P1/P2 entry that the listed causes cannot explain, or any 10018 order failure, stops the release until explained. An EA
failing Gate A after the fix is flagged to the user; no retune.

## Outcome, IC Markets (2026-10-18, ICMarketsEU-Demo in every agent log, history quality 10%, log `reports/portfolio/eacore_fix_parity_ic.log`)
The tester's XAUUSD trade session prints as Mon-Thu 01:02-23:59, Fri 01:02-23:57, which confirms the 01:00 quote comes before trading opens.

| EA | old trades / PF / net R | new trades / PF / net R | old-only / new-only entries (reopen bar) | P1 | P2 | P3 (order/close 10018) | P4 |
|---|---|---|---|---|---|---|---|
| MACD v1.46 | 945 / 1.95 / +375.8 | 958 / 1.96 / +379.9 | 2 / 15 (14) | pass | pass | 0, pass | pass |
| Donchian v1.02 | 157 / 1.72 / +59.5 | 156 / 1.80 / +63.5 | 12 / 11 (7) | pass | pass | 0, pass | pass |
| RSI_Reversal v1.21 | 347 / 1.63 / +100.5 | 362 / 1.73 / +118.3 | 32 / 47 (47) | pass | pass | 0, pass | pass |
| MA_Channel v1.02 | 292 / 1.59 / +98.6 | 302 / 1.49 / +88.7 | 2 / 12 (9) | pass | pass | 0, pass | pass |

Joint 4-EA prop_mc at 0.3% / 0.5%, seeds 1-3: new 97.3/90.4, 97.0/90.7, 97.4/90.5 vs old 97.2/90.0, 97.0/89.5, 96.9/89.9.
The max-loss breach at 0.5% fell from 5.4-5.8% to 4.8-5.1%. **P1-P4 all pass on IC**: the new builds are the release candidates.

The hypothesis held except for RSI, whose net R rose by +17.8 R, outside the forecast ±15 R. All 47 lost reopen entries
now open on their own bar; before the fix, 32 of them re-fired on a later bar. MA_Channel lost 9.9 R, as the review
predicted: its 5 reopen exits now close at 01:02. In the old build those exits failed and the positions ran to later,
luckier exits. Stop modifications rejected at 01:00-01:01 remain (MACD 3,039, RSI 2,839). They retry on the next tick
and #1 does not cover them.

What changed between the two runs:
- **Run 1 (`eacore_fix_parity_ic_run1.log`)** had the same trades. It failed P3 for RSI: 1,071 rejected closes, all
  from one daily stop. On 2023-10-09 gold gapped at the 01:00:38 pre-session quote and the daily stop fired. The closes
  were sent on every tick until 01:02 (the old build sent 315 of them). The new build sent each close twice per tick,
  once from the retry queue and once from the latched loop.
- **Run 1 also failed P2 for MA_Channel** on 3 entries. Each was a moved exit: the old build held a position whose 01:00
  exit failed, and the new build was flat after its 01:02 exit. Moved exits are a displacement caused by #1, so the P2
  rule was amended after run 1 to admit "exit moved".
- **The independent review** (3 reviewers, each finding checked by a skeptic; 6 confirmed, all minor, 3 refuted) led
  to four code changes before run 2:
  - daily-stop closes and close retries are sent only inside the session, once per tick;
  - the late-signal guard (#4) keeps the load moment in GMT, since `TimeTradeServer()` may be wrong before login;
  - the guard treats a bar as late only if it had quotes before the load, so an EA loaded during the daily break keeps
    the 00:00 H4/H6 bar;
  - caught-up log rows get the balance right after their deal.

  Run 2 has the same trades as run 1, with P3 at 0.

Release builds (MD5): MACD_Cross_EA 4a47ce4b88087ba913932ac54a5c0ce7, Donchian_Breakout_EA
482a8a8ded225d9457c667e94b464d1c, RSI_Reversal_EA 21b69b80a68c15181e8d672a7ed26cb1, MA_Channel_EA
a2cac05840a8849c14241bf0012429c4. Darwinex checks are pending until the terminal is on Darwinex-Demo.

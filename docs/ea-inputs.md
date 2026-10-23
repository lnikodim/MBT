# EA inputs: groups and labels

Every MBT EA lays out its Inputs dialog the same way, so anyone who can read one EA can read
them all. `tests/test_ea_inputs.py` checks every live EA (the list in `scripts/make_live_sets.py`)
against this page.

## The seven groups

The names and numbers are fixed and the order is always the same. If an EA has nothing for a
group, it leaves that group out and keeps the other numbers as they are (Invictus has no
filters, so its groups are 1 2 3 4 5 7).

| # | Group | What goes in | Examples |
|---|---|---|---|
| 1 | Trade size | how big each trade is | risk type, risk per trade, lots per $1,000, skip if the minimum lot is too big |
| 2 | Account protection | limits for the whole account | daily / monthly loss limit, drawdown throttle, margin floor, demo only |
| 3 | Orders | how orders reach the broker | max spread, wait for the spread, max slippage, order attempts |
| 4 | Identity and logs | how the EA marks and records its trades | magic number, order comment, trade CSV, status line |
| 5 | Strategy | what makes a trade | signal timeframe, indicator periods, entry levels, entry time, trade days, allow buys / sells, max open trades |
| 6 | Filters | extra checks that can block a signal | trend filter, ADX, trading hours, minimum gap |
| 7 | Exits | how a trade ends | stop loss, take profit, break-even, trailing stop, exit type, exit time |

Groups 1-4 are what you set for each account and broker. Groups 5-7 are the tested strategy:
if you change them, the backtest no longer describes the EA.

**Strategy or filter?** If taking the input away changes what the strategy is (long only, entry
level, max open trades), it belongs in Strategy. If it is an extra check you can switch off and
the signal still makes sense, it belongs in Filters.

## Labels

The text after `//` on an input line is the label MT5 shows in the dialog.

1. Start with the word a trader knows, then give the unit: `Stop loss, % of open price`.
2. Always give the unit: `%`, `points`, `pips`, `bars`, `minutes`, `x ATR`, `x stop distance`, `server time`.
3. If 0 turns the input off, end the label with `(0 = off)`. Use these exact words every time, never
   "none", "no trailing" or "drop it".
4. A feature with two or more inputs: write its on/off switch as `Use <feature>`, then each setting
   as `<Feature>: <setting>`, for example `Use trend filter (trade with the EMA)`, then
   `Trend filter: timeframe`, then `Trend filter: EMA period`.
5. Write a true/false input as what `true` does: `Allow sells`, `Demo accounts only`.
6. Keep each label to 50 characters or fewer.
7. Labels never hold version history, spec names, tested ranges or variable names. Put that in a
   `//---` comment above the input.
8. Dropdown values (the comments on enum values) follow the same rules, for example
   `Breakout: signal line crosses the channel`.
9. Write group headers as `input group "<n>. <Group>"`, using the names exactly as in the table.

## Shared words

| Say | Not |
|---|---|
| Signal timeframe | Timeframe used for signals, RSI timeframe |
| Risk per trade (amount or %) / Risk per trade, % of equity | Risk value, equity risk per trade in percent |
| Daily loss limit / Monthly loss limit | Daily loss stop, max daily drawdown |
| Max spread, points / pips | Maximum spread in points (not pips) |
| Max slippage, points | Max deviation, maximum price deviation |
| Magic number (unique per EA) | EA identifier |
| Order comment | Trade comment |
| Stop loss / Take profit | SL / TP / Target / Reward-risk ratio |
| Break-even: start at ... / Break-even: lock in ... | BE trigger, BE lock-in |
| Trailing stop: start at ... / distance / step | Trail trigger, trailing distance in ATR multiples |
| Allow buys / Allow sells | Allow long entries, enable shorts |

## Building a new EA

- **On EACore (preferred).** EACore declares groups 1-4 and opens `5. Strategy` with the signal
  timeframe (`InpTimeframe`). Declare your strategy inputs straight after `#include "EACore.mqh"`
  with no group header, so they continue group 5. Then add `input group "6. Filters"` and
  `input group "7. Exits"` as needed.
- **Standalone.** Declare every group yourself in the table order, and put
  `#include "AccountThrottle.mqh"` inside group 2. Its inputs have no group of their own, so they
  join whichever group is open at the include.
- To change a compiled default, add a `#define` before the include (`EA_RISK_VALUE`,
  `EA_DAILY_LOSS_PCT`, `ACCOUNT_THROTTLE_DD_PCT`, ...). Don't edit EACore for it.
- **Never rename an input variable.** `.set` files, tester profiles (`scripts/ea_profiles.py`)
  and live charts all match inputs by name. Labels, groups and order are safe to change.
- When an EA goes live, add it to `scripts/make_live_sets.py`. The test picks it up from there.

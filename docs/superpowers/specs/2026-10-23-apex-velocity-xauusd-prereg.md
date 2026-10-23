# Apex_Velocity_EA on Darwinex XAUUSD M5 (pre-registration)

Date: 2026-10-23. User: "let's test this EA: https://www.mql5.com/en/code/78275". Server: Darwinex-Demo.

**The EA:** "APEX VELOCITY" (mql5.com code 78275, RitzFalih, published 2026-10-11), `APEX VELOCITY V1.mq5`, MD5
9191a730…. It is copied unchanged to `mql5/Apex_Velocity_EA.mq5`, renamed per the naming convention (no spaces). No DLL,
web or file calls.

The file holds four versions. Lines 1-507 (v1.0) are the live code; three older drafts follow inside block comments
(dated 05/10 and 29/09/2026). For M5, the live code behaves like the v1.1 draft whose signal function the page quotes.
It differs only by a margin check before sending an order, plus relaxations that apply on H1 and above.

**The author's claim** (report screenshot, XAUUSD M5, about 2026-01..2026-10, history quality 99%, 74.7M ticks):
- deposit 100 USD, net +1,577.89, PF 9.96, Sharpe 71.6, LR correlation 0.98, max equity DD 1.25%;
- 1,254 trades, 66.5% won, average win 2.10, average loss -0.30.

**What the code does** (defaults, `InpEntryMode` 1 = real time):
- **Entry, on any tick of the forming M5 bar** (one entry per bar, at most one position): all of these hold.
  - Tick volume >= 1.1 x the average of the last 5 bars.
  - Body >= 85% of the bar's range, and range >= 0.7 x ATR(14).
  - Price beyond the previous bar's high (low) + 0.1 x ATR, in the bar's direction.
  - Price above (below) EMA50, RSI(14) < 70 (> 30), H1 close above (below) the H1 EMA50.
  - Spread <= 0.2 x ATR.
  - Server hour 13-20, not Wednesday 21-22 h.
- **Exits:**
  - Stop 2.5 x ATR, target 4.5 x ATR.
  - Break-even at +0.3 ATR (stop to entry + 0.05 ATR).
  - **Trailing stop of 0.05 x ATR from the first tick**: the stop jumps to just under the price at once, then follows
    it tick by tick.
  - Friday 22:00 close-all.
- **Size:** fixed 0.01 lot by default. `InpCalcMethod` 0 sizes by % risk on the 2.5 ATR stop.

**Why a latency check:** a 0.05 ATR trailing stop moved on every tick works perfectly only in a tester that fills
every stop change instantly at the exact price. Live, each change is a server request with latency, and fills slip.
The author's numbers (tiny losses, PF ~10, a straight equity line) are the typical result of that.

## Runs (`reports/apex/apex_eval.py`; Darwinex-Demo, XAUUSD M5, real ticks, 1:100)
- **P0, probe (not evidence):** 2026-09-01..2026-10-01, author's defaults, 100 USD. It measures run time, agent log
  growth and stop changes per trade before the long runs (the 19 GB log incident).
- **A0, the author's test:** 2026-01-01..2026-10-01, author's defaults, 100 USD deposit, 0.01 lot. Replication only.
- **S0:** 2022-01-01..2026-10-01, 100k, `InpCalcMethod` 0 at 1% risk, no delay.
- **L0, latency check:** S0 with a 100 ms execution delay (`ExecutionMode=100`).
- **S1, out of sample, 2019-01-01..2022-01-01:** S0 settings, only if S0 and L0 both pass Gate A.

**R per trade** = net / (first stop distance x volume x value per point), with the stop from the Orders table (parser
of `reports/crabel/crabel_eval.py`).

## Checks
- **Gate A (S0 and L0 each):** trades >= 150, PF >= 1.00, net R > 0 in both 2022-24 and 2025-26.
- **Out-of-sample check (S1):** net > 0, PF >= 1.05, mean-R t >= 1.65. If history quality is below 90%, it is
  inconclusive.
- **Candidate** = S0, L0 and S1 all pass. Anything else closes the EA. No input search.
- **Reported:** net USD and net R, PF, max DD, trades, win rate, mean R (t), R by year, long and short split, exits;
  the S0 vs L0 change; stop changes per trade where measurable; history quality.

## Expectation (written before the runs)
- **A0:** clearly profitable, but below the author's PF 9.96. Darwinex gold spreads (46-89 points in 2026) are larger
  than a 0.05 ATR trail, so each loss costs about the spread.
- **S0:** PF above 1 is possible on zero-latency fills.
- **L0:** PF drops sharply, probably below 1.00.
- **Most likely verdict:** closed on the latency check.

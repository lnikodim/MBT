# The screening gates

Every EA is tested on Darwinex-Demo with real ticks, source defaults, a fixed symbol and timeframe. Each gate only runs if the one before passed. Names set by the user on 2026-10-26.

| Gate | Window | Pass if | Used to be called |
|---|---|---|---|
| **A** | 2024-01 to 2026-10 | trades >= 40, PF >= 1.00, net > 0, no stop-out | "the screen" |
| **B** | 2022-01 to 2023-12, judged **together with Gate A** (2022-01 to 2026-10) | trades >= 150 (80 for a weekly rule), PF >= 1.00, net > 0 in 2022-24 and in 2025-26 | the 2022-23 run inside the old joined "Gate A" |
| **C** | 2019-01 to 2021-12 | **standalone:** net > 0, PF >= 1.05, t >= 1.65. **Add-on:** net > 0 and PF >= 1.0. Inconclusive if history < 90% real ticks | "out of sample" / "add-on evidence" |

**After Gate C**
- **Add-on test:** the seven live EAs at 0.5% risk with and without the candidate, sized to a 1% and a 2% standalone drawdown. Add it if return/DD does not fall, max DD rises by <= 1.0 point
  and the worst month does not worsen by more than 1.0 point. Daily and monthly correlation are reported.
- **Standalone EAs** (meant to drive an account) also need a sizing step: scaled to an 8% drawdown, >= +10% a year in both regimes.
- **Deploy** only with source, no third-party licence or approval needed, and a run on the target broker.

**Rules that go with the gates**
- A stateful EA (open grid or martingale positions, compounding lots, a permanent drawdown stop) keeps one continuous 2022-26 run for Gate B.
- An EA that floods the tester log (a two-week probe writes more than 100 MB) has its Print calls renamed to NoLog, only if the probe trades are identical (`scripts/strip_logging.py`).
- Gate B also fails on any stop-out in the 2022-23 run (the screen code enforces this; decided 2026-10-27 for CEZLSMA, whose EURUSD 2022-23 run had 4 stop-outs). Gate A already requires no stop-out.
- A pre-registration spec is committed before any run; a failed EA's source, profile and MT5 files are removed afterwards (the spec and logs stay).
- An EA that passes Gates A, B and C but whose drawdown is above the 8% sizing level is not rejected at once. First test one loss-limiting variant, named in the spec before the run: an input the EA already has (an equity drawdown limit, fewer grid levels, stops on) or a stop added to the logic. Run the same gates on it. Report the default and the variant side by side, mark the variant as found after the default result, and reject only if the variant fails. Use one variant per EA, not a sweep, so the gates aren't tuned on the same data.

Older specs use the old names ("Gate A" = the joined 2022-26 test, "the screen" = 2024-26); the table above maps them.

# The screening gates

Every EA is tested on Darwinex-Demo with real ticks, source defaults, a fixed symbol and timeframe. Each gate only runs if the one before passed. Names set by the user on 2026-10-26.

| Gate | Window | Pass if | Used to be called |
|---|---|---|---|
| **A** | 2024-01 to 2026-10 | trades >= 40, PF >= 1.00, net > 0, no stop-out | "the screen" |
| **B** | 2022-01 to 2023-12, judged **together with Gate A** (2022-01 to 2026-10) | trades >= 150 (80 for a weekly rule), PF >= 1.00, net > 0 in 2022-24 and in 2025-26 | the 2022-23 run inside the old joined "Gate A" |
| **C** | 2019-01 to 2021-12 | **standalone:** net > 0, PF >= 1.05, t >= 1.65. **Add-on:** net > 0 and PF >= 1.0. Inconclusive if history < 90% real ticks | "out of sample" / "add-on evidence" |

**After Gate C**
- **Add-on test:** the account-specific live EA set and settings, with and without the candidate, sized to a 1% and a 2% standalone drawdown. Add it if return/DD does not fall and the worst month does not worsen by more than 1.0 point, and the account profile below passes. Daily and monthly correlation are reported. Evaluate each broker/account roster separately.
- **Account profiles** (rewritten 2026-11-01 from the real rules; before that Atlas's limit was read as an 8% peak-to-trough drawdown, which it is not; see `docs/superpowers/specs/2026-11-01-account-rules-gate-amendment.md`):
  - **Atlas Funded 2-Step Daily $50k, challenge stages.** The limits are a static floor of $46,000 (8% of the initial balance, it does not trail the peak) and $2,000 below the day-start balance, reset at 00:00 UTC. **The criterion is the daily limit:** `scripts/prop_mc.py --server-to-utc` gives P(daily breach) <= 2% per stage, and the rolling-start replay (`reports/portfolio/stage_replay.py`, every start day, 90 days) shows no day at or below -$2,000. The floor ($4,000 below the stage start) is reported, not a criterion; a peak-to-trough drawdown is not a test for Atlas. An add-on must not lower P(pass) or raise the daily-breach probability or the worst day. If the full portfolio equity path (floating P/L) cannot be reconstructed, report the candidate as unverified, not a pass. Funded stage: the 2% open-loss Protector, the news +-5 min rule and the under-3-minute rule are measured, not gating.
  - **Darwinex Zero.** No hard cap on the initial capital: calibration is not pass/fail (25 risk-equivalent decisions over at least 15 trading days, no return requirement) and the DARWIN is re-scaled to a 6.5% VaR. **Scale-free criteria only:** return per max drawdown, worst month, share of positive months, worst rolling 6-month return, and a trade count that completes calibration. No absolute drawdown limit applies.
- **Standalone EAs** (meant to drive an account) also need a sizing step per profile: Atlas = the largest risk with P(daily breach) <= 2% and >= +10% a year in both regimes; Darwinex Zero = the scale-free criteria above.
- **Deploy** only with source, no third-party licence or approval needed, and a run on the target broker.

**Rules that go with the gates**
- A stateful EA (open grid or martingale positions, compounding lots, a permanent drawdown stop) keeps one continuous 2022-26 run for Gate B.
- An EA that floods the tester log (a two-week probe writes more than 100 MB) has its Print calls renamed to NoLog, only if the probe trades are identical (`scripts/strip_logging.py`).
- Gate B also fails on any stop-out in the 2022-23 run (the screen code enforces this; decided 2026-10-27 for CEZLSMA, whose EURUSD 2022-23 run had 4 stop-outs). Gate A already requires no stop-out.
- A pre-registration spec is committed before any run; a failed EA's source, profile and MT5 files are removed afterwards (the spec and logs stay).
- An EA that passes Gates A, B and C but fails its account profile's criteria (or its sizing step, for a standalone EA) is not rejected at once. First test one loss-limiting variant, named in the spec before the run: an input the EA already has (an equity drawdown limit, fewer grid levels, stops on) or a stop added to the logic. Run the same gates on it. Report the default and the variant side by side, mark the variant as found after the default result, and reject only if the variant fails. Use one variant per EA, not a sweep, so the gates aren't tuned on the same data.

Older specs use the old names ("Gate A" = the joined 2022-26 test, "the screen" = 2024-26); the table above maps them.

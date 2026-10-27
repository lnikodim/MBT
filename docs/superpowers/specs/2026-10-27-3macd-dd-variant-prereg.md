# 3MACD (geraked/metatrader5): drawdown variant, pre-registration (2026-10-27)

**Why this spec exists.** The default 3MACD on EURUSD H1 passes Gates A, B and C (PF 1.78 / 1.79 / 2.12) but its drawdown is 24.6% against the 8% sizing level in docs/gates.md. Under the framework rule ("Rules that go with the gates") it gets one loss-limiting variant before it can be rejected. This variant is chosen after the default result, so it is labelled post-hoc.

**Default (already run, not changed):** source defaults, H1, EURUSD. Reverse signal on, grid on with up to 50 levels, stop-loss and take-profit ignored, trailing stop on, risk 0.5%.

**Variant (the only one):** the EA's own equity drawdown limit set to 8% (`EquityDrawdownLimit = 8`). Every other input stays at the source default. No code change.

**Setup:** Darwinex-Demo, EURUSD H1, real ticks, $10,000 deposit, 1:100, Gates A (2024-01..2026-10), B and C (2019-01..2021-12) as docs/gates.md. The EA is stateful (open grid positions, a drawdown stop), so Gate B is one continuous 2022-26 run (`CONTINUOUS` in `reports/oct25/screen_eval.py`).

**Pass:** all three gates as in docs/gates.md, and the sizing check: the variant's drawdown must be at or below 8% after the sizing step. Report it either way.

**Verdict rule:** report the default and the variant side by side. Reject the EA only if the variant fails. A variant that passes all three gates but still shows drawdown above 8% is reported as a candidate that needs sizing, not as a pass.

**Not in this spec:** the author's own test (AUDUSD M5, 2021-02-22 to 2023-09-26, every-tick model) is a separate replication item.

**Leftovers:** the 3MACD MT5 files and profile entry stay until this verdict is final.

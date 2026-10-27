# DHLAOS (geraked/metatrader5): drawdown variant, pre-registration (2026-10-27)

**Why this spec exists.** On EURUSD H1 the default DHLAOS passes Gates A, B and C (PF 1.57 / 1.54 / 1.82), but its drawdown is 44.2% (Gate B joined) and 41.7% (Gate C) against the 8% sizing level in docs/gates.md. Under the framework rule ("Rules that go with the gates") it gets one loss-limiting variant before it can be rejected. The variant is chosen after the default result, so it is labelled post-hoc.

**Default (already run, not changed):** source defaults, H1. EURUSD: A 256 trades, PF 1.57, net +2,767 USD; B joined 435 trades, PF 1.54, net +4,422 USD; C 239 trades, PF 1.82, net +3,966 USD. GBPUSD fails Gate B (2022-23 run: 8 stop-outs, net -6,164 USD) and is closed; it is not part of this variant.

**Variant (the only one):** the EA's own equity drawdown limit set to 8% (`EquityDrawdownLimit = 8`). Every other input stays at the source default. No code change.

**Setup:** Darwinex-Demo, EURUSD H1, real ticks, $10,000 deposit, 1:100, Gates A (2024-01..2026-10), B and C (2019-01..2021-12) as docs/gates.md. The EA uses a grid, so it is stateful and Gate B is one continuous 2022-26 run (`CONTINUOUS` in `reports/oct25/screen_eval.py`).

**Pass:** all three gates as in docs/gates.md, and the sizing check: the variant's drawdown must be at or below 8% after the sizing step. Report it either way.

**Verdict rule:** report the default and the variant side by side. Reject the EA only if the variant fails. A variant that passes all three gates but still shows drawdown above 8% is reported as a candidate that needs sizing, not as a pass.

**Not in this spec:** the author's own test (AUDUSD M5, the DHLAOS test folder) is a separate replication item.

**Leftovers:** the DHLAOS MT5 files and profile entry stay until this verdict is final.

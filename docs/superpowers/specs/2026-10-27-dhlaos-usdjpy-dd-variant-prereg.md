# DHLAOS on USDJPY (geraked/metatrader5): drawdown variant, pre-registration (2026-10-27)

**Why this spec exists.** On USDJPY H1 the default DHLAOS passes Gates A, B and C (PF 1.35 / 1.48 / 1.80), but its drawdown is 37.7% (Gate A and joined Gate B) and 43.8% (Gate C), against the 8% sizing level in docs/gates.md. Under the framework rule ("Rules that go with the gates") it gets one loss-limiting variant before it can be rejected.

**Default (already run, not changed):** source defaults, H1, USDJPY. A: 260 trades, PF 1.35, net +2,143 USD, DD 37.7%, 0 stop-outs. B joined: 447 trades, PF 1.48, net +4,885 USD (22-24 +3,951; 25-26 +934), DD 37.7%. C: 245 trades, PF 1.80, net +4,455 USD, DD 43.8%, 0 stop-outs.

**Variant (the only one for this EA):** the same variant as the EURUSD spec (2026-10-27-dhlaos-dd-variant-prereg.md), applied to USDJPY: the EA's own equity drawdown limit set to 8% (`EquityDrawdownLimit = 8`). Every other input stays at the source default. No code change.

**Why the same variant.** The EURUSD variant failed (PF 0.76, net -1,520 USD) and its drawdown stayed at 24.8%, so the built-in limit did not hold the drawdown at 8%. This spec tests the same variant on the second instrument. It is not a new variant; a different loss-limiting mechanism needs its own spec.

**Setup:** Darwinex-Demo, USDJPY H1, real ticks, $10,000 deposit, 1:100, Gates A (2024-01..2026-10), B and C (2019-01..2021-12) as docs/gates.md. The EA is a grid, so it is stateful and Gate B is one continuous 2022-26 run (`CONTINUOUS` in `reports/oct25/screen_eval.py`).

**Pass:** all three gates as in docs/gates.md, and the sizing check: the variant's drawdown must be at or below 8% after the sizing step. Report it either way.

**Verdict rule:** report the default and the variant side by side. Reject the EA on USDJPY only if the variant fails. A variant that passes all three gates but still shows drawdown above 8% is reported as a candidate that needs sizing, not as a pass.

**Leftovers:** the DHLAOS MT5 files and profile entry stay until this verdict is final.

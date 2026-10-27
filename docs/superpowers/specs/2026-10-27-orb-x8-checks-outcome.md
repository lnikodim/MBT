# ORB x8 (NDX): plateau and fresh-window checks, outcome (2026-10-27)

Spec: amendment 1 of `2026-10-27-orb3f-ndx-improve-prereg.md` (neighbours and 2016-18 before any deployment test).
Runner: `reports/oct25/orb_x8_checks.py`; log: `reports/oct25/orb_x8_checks.log` (gitignored, kept locally).
Engine: the production `NDX_Band_Breakout_EA` (x8 is its inputs), Darwinex-Demo, NDX M1, $10,000 deposit. Sizing is the production 0.25% risk, so net profit is not comparable with the research sizing; PF and the sign of net are what the rule uses.

## Results

| Variant | 2019-21 (S1) | 2022-23 (S0a) | 2024-26 (SCR) | 2016-18 (fresh) |
|---|---|---|---|---|
| x8 (production) | 330 trades, PF 1.22, +183 USD | 239, PF 1.25, +170 | 257, PF 1.44, +263 | 105, PF 1.24, +87 |
| x0 (baseline) | 1,638, PF 1.11, +413 | 1,185, PF 1.06, +220 | 1,259, PF 1.16, +454 | 555, PF 1.01, +9 |
| Band 1.15 | 384, PF 1.31, +268 | 266, PF 1.28, +211 | 259, PF 1.34, +218 | not run |
| Band 1.35 | 298, PF 1.13, +104 | 226, PF 1.24, +160 | 234, PF 1.36, +200 | not run |
| Delay 30 min | 425, PF 1.17, +185 | 312, PF 1.12, +110 | 307, PF 1.33, +246 | not run |
| Delay 90 min | 278, PF 1.32, +219 | 199, PF 1.20, +120 | 215, PF 1.42, +215 | not run |

## Decision (amendment 1, as written)

- **Plateau:** a neighbour supports if PF is at least 1.1 in all three windows. All four neighbours support, so the plateau test passes (4 of 4; the rule needs 3).
- **Fresh window:** x8 needs PF at least 1.0, net above zero, and PF above x0's. x8 has PF 1.24, net +87 USD, against x0's PF 1.01 and net +9 USD. The test passes.
- **Verdict:** PASS. x8 is a candidate for a deployment test. The verdict doesn't commit the live set to it.

## Caveats

- **Engine:** the research `ORB3X_EA` source was removed after the study, so the checks ran on the production EA. Its 2019-21 and 2022-23 trade counts (330 and 239) match the research exactly. Its 2024-26 count does not: 257 against the research's 340.
- **Likely cause of the 2024-26 gap:** the production minimum-lot rule at a $10,000 deposit. It skips trades when NDX is above about 25,000, which the production spec warns about. So 2024-26 isn't a clean comparison with the research.
- **Fresh window:** 2016-18 runs on modelled ticks (about 31% real). That is weaker evidence than the real-tick windows.
- **Order of events:** the production EA was added to the live sets before these checks ran. The checks pass, so the live set is supported, but a deployment test is still needed before it's relied on.
- **Small in-sample gain:** the add-on result is about +1%/yr, as the production spec says.

## Next

A deployment test needs its own pre-registration spec before any run.

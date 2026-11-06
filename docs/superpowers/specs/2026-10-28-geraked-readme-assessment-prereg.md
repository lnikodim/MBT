# geraked/metatrader5 documented-EA assessment (2026-10-28)

## Scope

Use the 11 strategy EAs listed in the upstream README and their `Test/<EA>/README.md`, `*Inputs.set`, and `*Tester-Settings.ini` at upstream commit `d3eb29c382acf715727d5cd6a0414151e821fc2d`. Do not use the upstream prebuilt `.ex5` files. Compile the source and required indicators from that commit. The 10 documented EAs other than COT1 are eligible for MT5 execution. COT1 is excluded after static source review because it imports Windows DLLs and invokes PowerShell through `Shell.mqh`; no shell process or DLL imports will be run in the tester.

The four other `.mq5` files in the repository (2MOMEMA, LRCMACD, EATemplate, EATemplate2) have no README/input-set tester specification. They are outside this README-exact run and will be listed separately; existing H1 screening results may be cited as nonconforming background evidence only.

## Test configuration

- Keep each EA's README instrument(s), timeframe, leverage, and the first/current values from its `.set` file. Treat `.set` optimizer flags as off because the upstream Tester INIs have Optimization=0; do not run an optimization.
- Use the matching Darwinex-Demo symbol without the upstream broker suffix (`_i`, `.std`, `_o`); for multi-symbol EAs, keep the symbol list exactly as supplied and use the README basket. MT5's current broker/tester is Darwinex-Demo, not Alpari, LiteFinance, or 360Capital.
- Use real ticks, $10,000 USD deposit, and the periods and Gate A/B/C thresholds in `docs/gates.md`. This keeps the assessment comparable to the live prop-account framework while holding the upstream trading inputs fixed. Continuous Gate B applies to grid/stateful EAs.
- Run Gate A for each executable documented EA. Only Gate A passes proceed to Gate B; only Gate B passes proceed to Gate C. A history/bar-coverage failure is inconclusive, never a pass. Preserve all tester reports and effective input snapshots.
- Do not tune or add risk controls in this assessment. Passing A/B/C is research eligibility only. A separate candidate must pass the Darwinex Zero and FTMO account-specific joint replay and absolute 8% floating-equity drawdown gate in `docs/gates.md` before add-on approval.

## Known constraints

- The upstream presets were built for different brokers, symbol suffixes, and account leverage. Darwinex-Demo is used as the available target feed; results are broker-specific and cannot reproduce those vendor reports exactly.
- The repo-root README lists 11 documented strategy EAs; the 4 helper/extra EAs lack a corresponding README test preset and are not silently assigned invented presets.
- COT1 remains untested for safety, not performance.

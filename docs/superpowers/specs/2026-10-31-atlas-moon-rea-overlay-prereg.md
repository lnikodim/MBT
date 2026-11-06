# Atlas portfolio overview with Moon and Rea: methodology (2026-10-31)

## Question

How would the recorded $50,000 Atlas Funded 2-Step Daily seven-EA roster look with Dark Moon on EURUSD and Dark Rea on GBPUSD added at their compiled fixed-lot defaults?

## Scope and sizing

- Baseline: the seven-EA Atlas roster, at the calibrated 0.3% headline risk and 2% drawdown throttle from `reports/portfolio/atlas_phase1.py` and `reports/portfolio/atlas_phase1.log`. NI225 is excluded.
- Add-ons: Moon EURUSD and Rea GBPUSD at fixed 0.01 lots, matching their saved Gate B runs. The candidate lots are not scaled with account balance; their USD P/L is carried to the $50,000 account unchanged.
- Common comparison window: trade closes from 2022-01-03 through 2026-09-30 inclusive, matching the overlap with the baseline record.
- Inputs: existing validated baseline trade lists plus the saved candidate Gate B deal tables (`moo_E_s0_20261030_215947.htm`, `rea_G_s0_20261030_224245.htm`). No new MT5 runs.

## Replay method

1. Reconstruct the baseline's closed-trade P/L using the Atlas phase 1 live sizing and its recorded 2% throttle behavior. Verify that the replay matches its documented net and maximum drawdown.
2. Add Moon and Rea net deal P/L at their fixed 0.01 lots by close timestamp. Their results do not change baseline trade sizing or throttle decisions; this isolates the historical additive effect of the two fixed-lot EAs.
3. Report combined net P/L, closed-trade maximum drawdown, worst calendar month, and daily/monthly correlation of the candidate sleeve with the baseline. Daily groupings use the shared Darwinex server date for analysis only.
4. Do not infer the Atlas equity-based 8% overall or 4% daily rule from closed-trade replay. Candidate intratrade floating P/L, swap on open positions, and a synchronized equity path for all EAs are not available. The output is an overview, not an add-on approval.

## Readout

Compare the baseline with the combined closed-trade replay. Label any result that does not reproduce the baseline reference as invalid and investigate before presenting the candidate path. Keep the existing Atlas 8% static drawdown limit separate from the relative closed-trade comparison.

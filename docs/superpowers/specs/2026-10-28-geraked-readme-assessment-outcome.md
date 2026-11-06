# geraked/metatrader5: README and portfolio add-on assessment (2026-10-28)

**Upstream:** `geraked/metatrader5`, commit `d3eb29c382acf715727d5cd6a0414151e821fc2d`  
**Pre-registration:** `2026-10-28-geraked-readme-assessment-prereg.md`  
**Runner/log/data:** `reports/geraked_readme_assessment.py`, `reports/geraked_readme_assessment.log`, and `reports/geraked_readme_assessment.json`  
**MT5:** Darwinex-Demo, source compiled with MetaEditor, $10,000 USD, unsuffixed Darwinex symbol equivalents. Gate runs used real ticks and the per-EA README timeframe, input-set values, and leverage. The separate README-window reference run used the exact README date range and `Model`/`ExecutionMode` from the repo's `Tester-Settings.ini`.

## Verdict

**No add-on candidate is approved for Darwinex Zero or FTMO.** Ten EAs have a README/input-set reference run and a framework Gate A run. AFAOSMD was the only Gate A pass, but its continuous Gate B had only 7.2% of the expected chart bars, 46 trades, PF 0.26, net −$5,326, eight stop-outs, and 58.9% relative equity DD; Gate B is therefore inconclusive on data coverage and does not meet the recorded performance thresholds. It did not proceed to Gate C.

The other nine Gate A runs are inconclusive because chart-history coverage was below the pre-set 92% threshold. The MT5 reports label history quality 99–100%, but their bar counts show large missing spans. Their net/PF/drawdown values are retained as diagnostics, not valid gate verdicts.

Even a candidate that later clears A/B/C still has to clear the account-specific add-on test and the hard 8% combined floating-equity limit. The saved prior portfolio replay has baseline closed DD of 16.03% for Darwinex Zero and 10.99% for the FTMO proxy, both above 8%; it also lacks complete synchronized floating-equity paths. See `2026-10-28-3macd-portfolio-addon-outcome.md`. No current evidence supports adding an EA to either account.

## README-window reference results

All figures are the source build with the first/current values in the upstream `.set`, on the README instrument and timeframe, for the README dates. “Coverage” compares the report's main-chart bars with an approximate weekday-market expectation; this is a data diagnostic, not a profitability gate. The tester `Model` values below came from the upstream Tester INI. The broker suffixes in those files were mapped to Darwinex's unsuffixed symbols. For multi-symbol EAs, their `.set` basket strings were left unchanged.

| EA | README range | Model | Net USD | PF | Equity DD | Trades | Main-chart bars / expected | Coverage |
|---|---|---:|---:|---:|---:|---:|---:|---:|
| 2MAAOS | 2019-01-01 to 2023-10-17 | 1 | +4,751.78 | 1.09 | 76.22% | 73 | 3,914 / 7,472 | 52.4% |
| 2MACDSTO | 2020-01-01 to 2023-10-08 | 0 | +4,440.16 | 1.16 | 64.07% | 134 | 4,802 / 7,834 | 61.3% |
| 3MACD | 2021-02-22 to 2023-09-26 | 0 | +1,647.38 | 1.05 | 57.89% | 1,199 | 88,552 / 193,892 | 45.7% |
| 3MAF | 2021-02-22 to 2023-09-08 | 0 | +5,905.83 | 1.13 | 68.19% | 328 | 32,218 / 63,401 | 50.8% |
| AFAOSMD | 2019-01-01 to 2023-10-22 | 0 | −5,207.50 | 0.51 | 67.06% | 85 | 8,959 / 59,951 | 14.9% |
| BBRSI | 2021-02-26 to 2023-09-15 | 0 | +36,034.31 | 2.89 | 51.60% | 376 | 180,932 / 190,818 | 94.8% |
| CEZLSMA | 2019-01-01 to 2023-08-01 | 0 | −4,691.00 | 0.73 | 69.90% | 129 | 29,952 / 114,299 | 26.2% |
| DHLAOS | 2021-02-22 to 2023-09-19 | 0 | −3,430.46 | 0.85 | 67.82% | 550 | 103,833 / 192,457 | 53.9% |
| LRCUTB | 2019-01-01 to 2023-10-30 | 0 | −4,588.47 | 0.55 | 60.23% | 127 | 11,410 / 120,448 | 9.5% |
| NWERSIASF | 2019-01-01 to 2023-10-22 | 1 | −3,687.60 | 0.76 | 67.25% | 138 | 3,603 / 14,988 | 24.0% |

BBRSI has the strongest reference PF and return, but its 51.6% drawdown is far from the 8% constraint. Its Gate A run is itself inconclusive because only 9.1% of expected M5 chart bars were present, so it is not advanced as a candidate.

## Framework gates

| EA | Gate A (2024-01 to 2026-10) | Gate B (continuous 2022-01 to 2026-10) | Gate C (2019-01 to 2021-12) | Assessment |
|---|---|---|---|---|
| 2MAAOS | Inconclusive; net −$4,002, PF 0.68, 26 trades, DD 66.62%, 29.7% bars | Not run | Not run | No candidate; history incomplete and observed metrics poor |
| 2MACDSTO | Inconclusive; net −$5,530, PF 0.00, 3 trades, DD 55.36%, 1.6% bars | Not run | Not run | No candidate; history incomplete and observed metrics poor |
| 3MACD | Inconclusive; net −$4,814, PF 0.63, 434 trades, DD 64.10%, 21.6% bars | Not run | Not run | No candidate; readme-window DD 57.89% and Gate A history incomplete |
| 3MAF | Inconclusive; net −$2,731, PF 0.87, 201 trades, DD 70.88%, 35.3% bars | Not run | Not run | No candidate; history incomplete and observed metrics poor |
| AFAOSMD | **Pass**; +$17,046, PF 3.31, 342 trades, DD 59.86%, 100% bars | Inconclusive; −$5,326, PF 0.26, 46 trades, DD 58.88%, 7.2% bars, 8 stop-outs | Not run | Does not qualify; B misses performance criteria and has incomplete history |
| BBRSI | Inconclusive; −$6,118, PF 0.28, 38 trades, DD 67.71%, 9.1% bars | Not run | Not run | No candidate; history incomplete and observed metrics poor |
| CEZLSMA | Inconclusive; −$4,228, PF 0.76, 107 trades, DD 68.75%, 31.9% bars | Not run | Not run | No candidate; history incomplete and observed metrics poor |
| DHLAOS | Inconclusive; −$4,489, PF 0.59, 231 trades, DD 57.04%, 30.0% bars | Not run | Not run | No candidate; history incomplete and observed metrics poor |
| LRCUTB | Inconclusive; −$3,765, PF 0.83, 361 trades, DD 71.71%, 61.9% bars | Not run | Not run | No candidate; history incomplete and observed metrics poor |
| NWERSIASF | Inconclusive; −$5,366, PF 0.19, 20 trades, DD 57.79%, 6.3% bars | Not run | Not run | No candidate; history incomplete and observed metrics poor |

All ten sources and every required indicator compiled with zero errors and warnings. The suite was staged from source; no upstream prebuilt EA `.ex5` was used. Gate execution was staged per `docs/gates.md`; later gates were not run after an inconclusive or failed earlier gate.

## Remaining repo EAs and execution boundary

The GitHub repo contains 15 `.mq5` files. The root README documents 11 strategy EAs; this run covered 10. COT1 was not executed because its dependency chain imports `kernel32.dll`/`user32.dll`, WinINet, and PowerShell process-launch code. Its README-window result is therefore **not tested**.

The four other source files have no README/input-set test profile: 2MOMEMA, LRCMACD, EATemplate, and EATemplate2. A prior generic H1 screen (not an exact README-profile assessment) found:

- 2MOMEMA: Gate A failed on EURUSD (PF 0.89, −$2,181) and GBPUSD (PF 0.95, −$1,003).
- LRCMACD: Gate A failed on EURUSD (PF 0.45, −$6,349, four stop-outs) and GBPUSD (+$14,540, PF 1.28, DD 56.58%, four stop-outs).
- EATemplate and EATemplate2: zero trades on both generic H1 screens; neither exposes an active strategy signal.

These generic results are not represented as tests of an upstream README preset. Together with the COT1 boundary and the ten documented tests, all 15 source EAs are accounted for in the assessment.

## Recommendation

**Add none of these EAs to the live portfolio.** BBRSI and 3MACD look best only on parts of their author windows, while their drawdowns are still 51.6% and 57.9% and their current Gate A evidence is incomplete. AFAOSMD is the only clean Gate A pass, but Gate B is both deeply negative and data-incomplete. No EA reaches a valid A/B/C add-on-eligible result, no loss-limiting variant is warranted from this evidence, and the recorded portfolio baseline already exceeds the 8% account ceiling.

The next useful data step is to obtain complete, synchronized Darwinex and FTMO historical ticks for the README instruments/timeframes and actual portfolio floating equity. Then rerun inconclusive gates before spending effort on EA-specific risk variants.

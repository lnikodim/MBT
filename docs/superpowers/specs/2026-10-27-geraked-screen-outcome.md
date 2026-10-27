# geraked/metatrader5: outcome of the 14-EA screen (2026-10-27)

Request: user, 2026-10-27, shared the repo, then "go" to screen the clean EAs.
Runner: `reports/oct25/geraked1.py`; log: `reports/oct25/geraked1.log`. Variant runners and specs: `reports/oct25/dd8_*.py`, `docs/superpowers/specs/2026-10-27-*-dd-variant-prereg.md`.
Setup: Darwinex-Demo, real ticks, $10,000 deposit, 1:100, source defaults, H1 on every instrument (none of these EAs sets a timeframe in its source), Gates A/B/C as docs/gates.md, two-rejects rule per EA.

Scan: `COT1` imports `kernel32.dll` and `user32.dll` and runs PowerShell through `Include/Shell.mqh`, so it was excluded. The repo's prebuilt `.ex5` files were ignored; every EA was compiled from source.

## Results

| EA | EURUSD | GBPUSD | Verdict |
|---|---|---|---|
| 2MAAOS | 7 trades, PF 0.16, -7,116 USD, 2 stop-outs (basket: trades EURUSD, EURCAD, USDCAD) | same basket result | REJECT (PF) |
| 2MACDSTO | 2 trades, PF 0.00, -5,410 USD, 2 stop-outs | 86 trades, PF 0.75, -4,657 USD, 2 stop-outs | REJECT |
| 2MOMEMA | 401 trades, PF 0.89, -2,181 USD | 400 trades, PF 0.95, -1,003 USD | REJECT (PF) |
| 3MAF | 69 trades, PF 0.42, -6,153 USD, 4 stop-outs | 47 trades, PF 0.34, -5,753 USD, 2 stop-outs | REJECT (PF) |
| AFAOSMD | 51 trades, PF 0.39, -5,263 USD, 6 stop-outs | 99 trades, PF 0.57, -4,425 USD, 2 stop-outs | REJECT (PF) |
| BBRSI | A pass (41 trades, PF 3.99); B pass; C FAIL (23 trades, PF 0.07, -7,719 USD, 10 stop-outs) | A pass (44 trades, PF 2.92); B FAIL (joined -6,537 USD, DD 81.7%) | REJECT (Gate C, Gate B) |
| 3MACD | A pass (492 trades, PF 1.78, +4,732 USD); B pass (891 trades, PF 1.79, +8,257 USD); C pass (524 trades, PF 2.12, +5,606 USD); DD 19.5-24.6% | A REJECT (154 trades, PF 0.24, 18 stop-outs) | Candidate on EURUSD; drawdown variant failed (505 trades, PF 0.79, -1,540 USD); REJECT |
| USDJPY | A pass; B FAIL (joined -1,972 USD, DD 76.4%) | | |
| DHLAOS | A pass (256 trades, PF 1.57, +2,767 USD); B pass (435 trades, PF 1.54, +4,422 USD); C pass (239 trades, PF 1.82, +3,966 USD); DD 41-44% | B FAIL (8 stop-outs in 2022-23) | Candidate on EURUSD; variant failed (260 trades, PF 0.76, -1,520 USD); REJECT |
| USDJPY (DHLAOS) | A pass (260 trades, PF 1.35, +2,143 USD); B pass (447 trades, PF 1.48, +4,885 USD); C pass (245 trades, PF 1.80, +4,455 USD); DD 38-44% | | Candidate; variant failed (270 trades, PF 0.76, -1,590 USD); REJECT |
| CEZLSMA | A pass (216 trades, PF 2.44, +45,838 USD, 0 stop-outs); B FAIL (2022-23 run: 4 stop-outs, -5,749 USD; joined DD 66.5%) | A REJECT (36 trades, PF 0.50, 4 stop-outs) | REJECT under the zero-stop-out Gate B rule |
| LRCMACD | A REJECT (79 trades, PF 0.45, -6,349 USD, 4 stop-outs) | A REJECT (407 trades, PF 1.28, +14,540 USD, 4 stop-outs) | REJECT (stop-outs at Gate A) |
| LRCUTB | A REJECT (94 trades, PF 0.39, -5,801 USD, 6 stop-outs) | A REJECT (141 trades, PF 0.52, -5,891 USD, 8 stop-outs) | REJECT |
| NWERSIASF | A REJECT (43 trades, PF 0.31, -5,897 USD, 4 stop-outs) | A REJECT (43 trades, PF 0.31, -5,893 USD, 4 stop-outs; basket) | REJECT |
| EATemplate, EATemplate2 | 0 trades | 0 trades | Templates: both signal functions return `false`, so no strategy was tested |
| COT1 | not run | not run | Excluded: imports DLLs and runs PowerShell |

## Findings

- No EA in the set passes with an acceptable drawdown. The three candidates (3MACD and DHLAOS on EURUSD, DHLAOS on USDJPY) all showed drawdowns of 19-44%, far above the 8% sizing level.
- The pre-registered equity-limit variant did not hold drawdown near 8% on either EA. Relative equity drawdown stayed at 24.8-30.3%, and the variants lost money.
- Gate B's zero-stop-out condition is enforced by the screen code but was not written in `docs/gates.md` until this record (see the rules section there).

## Cleanup (standing rule: fail verdict)

- Removed the MT5 `Experts\Geraked` files for every EA in the set, and the indicators (`AndeanOscillator`, `DailyHighLow`, `AverageForce`, `LinearRegressionCandles`, `UTBot`, `AtrSlFinder`, `NadarayaWatsonEnvelope`, `ChandelierExit`, `ZLSMA`, `ATR_HeikenAshi`) and the `EAUtils.mqh` and `errordescription.mqh` copies in `MQL5\Include`.
- Restored `scripts/ea_profiles.py` to its committed version; its only uncommitted changes were the temporary screen entries.
- Kept: the runners, the logs, the pre-registration specs and this outcome.

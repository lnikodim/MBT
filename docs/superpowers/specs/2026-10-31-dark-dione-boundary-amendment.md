# Dark Dione window boundary amendment (2026-10-31)

**Parent spec:** `2026-10-30-dark-family-screen-prereg.md`.

## Reason

Dione's EURUSD H1 tester returned empty reports (`Bars: 0`) for the 2024-01-01 start, including a 2024-01-01..2024-04-01 diagnostic. After market history was available, two adjacent diagnostics with a 2024-01-02 start or later completed: 2024-01-02..2024-04-01 produced 1,532 bars, and 2024-04-01..2024-07-01 produced 1,560 bars. Both had 100% history quality. The one-month 2024-01-02..2024-02-01 probe in the parent spec also completed.

## Dione-only adjustment

To get valid continuous reports without cutting position state at test boundaries, run each Dione gate as one continuous real-tick test, with its start shifted from January 1 to January 2. The end dates, symbols, timeframe, compiled-default inputs, account settings, trade-count floor, gate metrics, and verdict rules remain those in the parent spec. This omits only January 1, for which the tester supplied no bars in the failing diagnostic. Do not split or stitch Dione runs.

If an adjusted continuous run still returns an empty report or fails data-quality checks, record it as no result and leave the verdict open. Do not treat an empty report as a reject or pass.

## Evidence status

The two quarter runs above are diagnostics only. They are not Gate A, B, or C results and do not determine a verdict.

## Outcome

EURUSD Gate A passed narrowly (+$2.28, PF 1.00, 358 trades), but continuous Gate B failed because 2025-26 net was -$27.12. GBPUSD Gate A was rejected (-$305.24, PF 0.67, 454 trades). Dione is rejected by the two-instrument rule; Gate C was not run. Full figures are in `2026-10-30-dark-family-screen-outcome.md`.

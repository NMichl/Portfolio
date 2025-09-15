# Nasdaq-30 vs. thesis baseline

The sandbox run could not compute trading performance because the required R
packages (`yahoofinancer`, `exuber`, `PerformanceAnalytics`, `dplyr`,
`lubridate`, `xts`) are unavailable behind the execution firewall. Consequently,
all outputs reflect placeholder rows that document the missing dependencies.

| Metric | Thesis (from summary) | Nasdaq-30 run | Notes |
| --- | --- | --- | --- |
| Average yearly return (per ticker) | Not explicitly reported in thesis summary | `NA` for all tickers | SADF monitoring not executed; data pull skipped due to missing packages |
| Equal-weight yearly return | Not available | `NA` | Same limitation as above |
| Jensen’s alpha | Reported qualitatively (no numbers in summary) | `NA` | Requires CAPM regression on monitoring output |

## Alignment notes

- The thesis documentation in `codex_reports/thesis_summary.md` lists geometric
  average returns, Sharpe ratios, and Jensen’s alpha as key evaluation metrics,
  but the summary text does not include the concrete values. Once dependencies
  are installed, rerun `nasdaq30_run.R` to generate directly comparable figures.
- The new experiment reuses the thesis helper functions by parsing
  `R/Masterarbeit_code/Trading_algorithm.R` at runtime, so the methodology will
  stay consistent once execution succeeds.
- Until Yahoo Finance access is restored, `data/nasdaq30/metrics.csv` and
  `data/nasdaq30/avg_yearly_return.csv` remain audit trails showing why the
  analysis could not proceed.

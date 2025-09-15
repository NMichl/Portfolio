# Nasdaq-30 sequential bubble analysis

This experiment reuses the master thesis pipeline (Yahoo Finance data access via
`yahoofinancer` together with the SADF/CUSUM trading utilities from
`R/Masterarbeit_code/Trading_algorithm.R`) to inspect the ~30 largest
Nasdaq-listed equities.

## Prerequisites

- R ≥ 4.3 with the thesis packages installed: `yahoofinancer`, `exuber`,
  `PerformanceAnalytics`, `dplyr`, `lubridate`, `xts` (plus their dependencies).
- Internet access that allows Yahoo Finance requests from the
  `yahoofinancer::Ticker` client.
- Thesis helper file available at `R/Masterarbeit_code/Trading_algorithm.R`.

The sandbox used for this run cannot reach CRAN or Yahoo Finance, therefore all
numerical outputs in this commit reflect a fallback path with missing data. When
rerunning on a workstation with full access, install the packages above first
(e.g. via CRAN or Posit Package Manager).

## Usage

```bash
Rscript experiments/nasdaq30/nasdaq30_run.R            # writes to data/nasdaq30/
Rscript experiments/nasdaq30/nasdaq30_run.R "C:/Users/Niklas/Desktop/AI Masterthesis"
```

- The optional argument overrides the output directory. It accepts Windows paths
  verbatim. In sandbox mode the default `data/nasdaq30/` is used.
- The script also honours an `OUTPUT_DIR` environment variable when the positional
  argument is omitted.

## Workflow

1. `get_universe.R` tries to call the same Yahoo Finance API used in the thesis
   (via `yahoofinancer::Ticker`) to pull Nasdaq-100 constituents and rank them by
   market capitalisation. If either the package or the API is unavailable, it
   falls back to a static list approximating the top 30 tickers as of Q1 2025.
2. `nasdaq30_run.R` parses the thesis script, loads the helper functions
   (`Get_data_and_save`, `real_time_monitoring`, `Evaluating_trading_rule`,
   `Jensen_Alpha`, etc.), downloads weekly adjusted prices, and executes the SADF
   monitoring/trading logic for each ticker.
3. Results are saved as:
   - `<OUTPUT_DIR>/prices.csv` – monitoring log per ticker (SADF statistic vs
     critical value and trading signal).
   - `<OUTPUT_DIR>/metrics.csv` – geometric return, Sharpe ratio, buy/hold, and
     Jensen’s alpha for every ticker.
   - `<OUTPUT_DIR>/avg_yearly_return.csv` – per-ticker and equal-weighted annual
     returns.

When the environment lacks the required packages or network connectivity, the
runner records placeholder rows with `status = "missing_dependencies"` to make
failures explicit without touching the thesis source file.

## Regenerating the thesis results

To obtain real figures:

1. Install the missing packages (e.g. `install.packages("yahoofinancer")`).
2. Ensure Yahoo Finance and FRED endpoints are reachable from R.
3. Re-run the commands above. The script will repopulate `data/nasdaq30/` with
   live downloads and recomputed metrics.
4. Update the comparison report under `codex_reports/nasdaq30/` if the thesis
   contains annual return benchmarks for reference.

## Static universe provenance

The fallback ticker list is based on publicly available Nasdaq-100 constituent
rankings (Q1 2025) and is documented inside `get_universe.R`. Re-run the script
with working API access to replace it with an up-to-date, market-cap-ranked
selection.

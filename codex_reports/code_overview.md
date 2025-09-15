# R Script Overview

## File scanned
- `R/Masterarbeit_code/Trading_algorithm.R` (891 lines).

## Dependencies and setup
- Loads plotting, econometric, and finance APIs via `ggplot2`, `exuber`, `PerformanceAnalytics`, `yahoofinancer`, `dplyr`, `lubridate`, and base `stats`; sets a global random seed for reproducibility.【F:R/Masterarbeit_code/Trading_algorithm.R†L1-L13】【F:R/Masterarbeit_code/Trading_algorithm.R†L238-L239】

## Data ingestion and preprocessing
- `Get_data_and_save()` wraps the Yahoo Finance client (`Ticker$new`) to persist weekly histories; companion `load_stock()` reads those CSVs, normalizes column names, and reports missing values.【F:R/Masterarbeit_code/Trading_algorithm.R†L18-L39】
- Commented calls illustrate expected tickers and storage layout (Windows file paths) for equities, benchmarks, and rates; a custom monthly pull handles NASDAQ CPI analysis.【F:R/Masterarbeit_code/Trading_algorithm.R†L41-L60】
- The script loads all series (equities, S&P 500, Treasury yield, CPI, NASDAQ), retrieves precomputed SADF critical values, and deflates NASDAQ prices by CPI before running baseline SADF diagnostics and wealth calculations.【F:R/Masterarbeit_code/Trading_algorithm.R†L70-L127】

## Exploratory diagnostics
- Generates synthetic AR processes for stationary, unit-root, and explosive regimes to visualize behavior differences.【F:R/Masterarbeit_code/Trading_algorithm.R†L130-L144】
- `plot_bubble_testing()` wraps `radf` summaries with line charts; subsequent calls iterate over each stock to inspect historical bubbles.【F:R/Masterarbeit_code/Trading_algorithm.R†L155-L183】
- Training samples are truncated to the minimum window suggested by `psy_minw`, followed by ACF plots, Ljung-Box tests, and BIC-based AR order checks on both levels and differences to validate serial-correlation assumptions.【F:R/Masterarbeit_code/Trading_algorithm.R†L186-L334】

## Real-time monitoring functions
- `real_time_monitoring()` maintains a growing window, recomputes SADF statistics, looks up Monte Carlo critical values, and records boolean signals whenever statistics cross thresholds, ensuring state resets when the statistic drops back below the boundary.【F:R/Masterarbeit_code/Trading_algorithm.R†L341-L382】
- `cusum_monitoring()` builds CUSUM statistics over the monitoring horizon, normalizes variance estimates, compares against the dynamic boundary gamma_alpha (1 + 2r), and outputs a monitoring data frame keyed by date.【F:R/Masterarbeit_code/Trading_algorithm.R†L386-L439】
- `plot_statistic()` and `plot_statistic_cusum()` render time-series overlays of statistics versus thresholds for visual inspection.【F:R/Masterarbeit_code/Trading_algorithm.R†L442-L473】

## Trading and performance utilities
- `Evaluating_trading_rule()` derives secondary signals that stay invested through consecutive TRUE flags, exits on the second FALSE, and composes multiplicative returns across completed trades.【F:R/Masterarbeit_code/Trading_algorithm.R†L475-L510】
- `Jensen_Alpha()` aligns weekly asset, benchmark, and risk-free series by ISO week, converts prices to excess returns, zeroes out non-invested periods, and fits a CAPM regression for alpha estimation.【F:R/Masterarbeit_code/Trading_algorithm.R†L516-L561】
- `geom_average_retrun()` and `sharp()` compute annualized geometric returns and Sharpe ratios from the trading log, again aligning with risk-free rates; `buy_hold()` measures simple buy-and-hold gains from the monitoring start.【F:R/Masterarbeit_code/Trading_algorithm.R†L566-L618】

## Execution flow
- Reloads full-length price series, applies SADF and CUSUM monitoring functions stock-by-stock, plots diagnostics, feeds results through trading rule evaluation, then computes Jensen’s alpha, geometric averages, Sharpe ratios, and buy-and-hold comparisons for each dataset.【F:R/Masterarbeit_code/Trading_algorithm.R†L620-L745】

## Notable implementation patterns
- Extensive reliance on global variables (e.g., `SP500`, `Risk_free_rate`, `Critical_values`) shared across helper functions, meaning order of execution matters.【F:R/Masterarbeit_code/Trading_algorithm.R†L70-L83】【F:R/Masterarbeit_code/Trading_algorithm.R†L517-L556】
- Key loops appear in `real_time_monitoring`, `cusum_monitoring`, and `Evaluating_trading_rule`, each implementing bespoke state machines for threshold monitoring and trade aggregation.【F:R/Masterarbeit_code/Trading_algorithm.R†L358-L377】【F:R/Masterarbeit_code/Trading_algorithm.R†L410-L433】【F:R/Masterarbeit_code/Trading_algorithm.R†L480-L506】

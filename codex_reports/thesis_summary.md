# Thesis Context Summary

## Research question
- Primary question: *Is it possible to generate excess returns based on sequential bubble-detection tests applied to a stock containing a bubble?*【478900†L1-L6】

## Data sources and variables
- Historical weekly closing prices for eight equities with documented bubble episodes: Microsoft (MSFT), Intel (INTC), Oracle (ORCL), Qualcomm (QCOM), CD Projekt (CDR.WA), Plug Power (PLUG), Volkswagen (VOW.DE) and Canopy Growth (CGC). Observation windows range from the early 1990s to 2023 depending on the asset (547 weekly observations for most dot-com era equities; 366 for PLUG; 418 for CGC).【89d489†L31-L66】
- Benchmarks and macro series: S&P 500 index (^GSPC) as market benchmark; 10-year U.S. Treasury yield (^TNX) as risk-free proxy; CPI level (CPIAUCSL) for real-price adjustments; NASDAQ Composite (^IXIC) for illustrative bubble detection. All data pulled March 31, 2025 via Yahoo Finance or FRED APIs, typically through the `yahoofinancer` R package.【89d489†L6-L30】【89d489†L33-L48】
- Variables engineered for analysis include real prices (deflating by CPI), weekly returns, cumulative and geometric average returns, Sharpe ratios, and CAPM excess returns (Jensen’s alpha).【89d489†L1-L5】【1fa7db†L70-L112】

## Methods and models
- Sequential application of the Supremum Augmented Dickey-Fuller (SADF) test, following Vasilopoulos et al. (2022), with regression in first differences and critical values derived from Monte Carlo simulations under the null of a random walk.【1fa7db†L3-L58】
- Real-time monitoring framework that updates the SADF sequence as new observations arrive, using Monte Carlo critical values to account for multiple testing and finite sample properties; relies on the `exuber` package functions (`radf`, `radf_mc_cv`, `psy_minw`).【1fa7db†L3-L66】
- Cumulative Sum (CUSUM) detector, normalized to converge to Brownian motion, with dynamic boundary b_alpha(r) = gamma_alpha (1 + 2r) calibrated at the 5% significance level (gamma_alpha = 0.919).【1fa7db†L58-L112】
- Training sample selection uses the Phillips et al. (2015a) minimum window r0 = 0.01 + 1.8/sqrt(T) and ensures bubble-free estimation by combining SADF and GSADF diagnostics; AR lag order chosen via BIC after differencing to eliminate autocorrelation.【1fa7db†L112-L162】【6929a6†L1-L84】
- Real-time tests are validated by plotting autocorrelation functions, Ljung-Box diagnostics and AR lag selection to justify zero-lag differenced series except for MSFT.【6929a6†L34-L84】

## Evaluation metrics
- Returns: cumulative and annualized geometric means for each trading strategy, contrasted against buy-and-hold baselines.【6929a6†L126-L183】
- Risk-adjusted performance: Sharpe ratios (annualized) and Jensen’s alpha from CAPM regressions on excess returns over the S&P 500 benchmark.【1fa7db†L70-L140】【6929a6†L85-L125】
- Qualitative benchmarking versus hedge funds and passive indices to contextualize performance levels.【6929a6†L85-L125】

## Terminology aligned with the R code
- Core test names: SADF, GSADF, CUSUM, critical values, `radf`, `datestamp`, `psy_minw`, Monte Carlo simulations.
- Trading logic vocabulary: training sample, monitoring period, threshold breaches, trading signals, buy-and-hold, Sharpe ratio, Jensen’s alpha, geometric average return.
- Data artifacts: ticker symbols (MSFT, INTC, etc.), CPIAUCSL, ^GSPC, ^TNX, ^IXIC, weekly intervals, risk-free rate proxy, `yahoofinancer` API.

## Key takeaways for implementation
- Sequential monitoring hinges on maintaining bubble-free training windows and updating critical values as the sample grows.
- Investment evaluation must combine raw return tallies with risk adjustments (CAPM alpha, Sharpe) to assess excess returns.
- Monte Carlo critical values and dynamic boundaries are essential for controlling false positives in real-time bubble detection.

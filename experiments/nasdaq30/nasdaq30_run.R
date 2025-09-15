#!/usr/bin/env Rscript

# Intentionally avoid attaching packages at load time.

here <- function(...) {
  file.path(getwd(), ...)
}

source(here("experiments", "nasdaq30", "get_universe.R"))

load_thesis_functions <- function(export_env = parent.frame()) {
  script_path <- here("R", "Masterarbeit_code", "Trading_algorithm.R")
  if (!file.exists(script_path)) {
    stop("Trading_algorithm.R not found at ", script_path)
  }
  exprs <- parse(file = script_path)
  temp_env <- new.env(parent = baseenv())
  for (expr in exprs) {
    if (is.call(expr) && length(expr) >= 3 &&
        (identical(expr[[1]], as.name("<-")) || identical(expr[[1]], as.name("=")))) {
      value <- expr[[3]]
      if (is.call(value) && identical(value[[1]], as.name("function"))) {
        eval(expr, envir = temp_env)
      }
    }
  }
  for (name in ls(temp_env, all.names = TRUE)) {
    assign(name, get(name, envir = temp_env), envir = export_env)
  }
  invisible(export_env)
}

read_price_csv <- function(path) {
  if (!file.exists(path)) {
    stop("File not found: ", path)
  }
  df <- utils::read.csv(path)
  names(df) <- tolower(names(df))
  if (!"date" %in% names(df) || !"close" %in% names(df)) {
    stop("CSV missing required columns 'date' and 'close': ", path)
  }
  data.frame(
    Date = as.Date(df$date),
    Price = as.numeric(df$close),
    stringsAsFactors = FALSE
  )
}

compute_critical_values <- function(max_len, nrep = 500L) {
  if (!requireNamespace("exuber", quietly = TRUE)) {
    stop("Package 'exuber' is required to compute critical values")
  }
  critical <- numeric(max_len)
  for (i in seq_len(max_len)) {
    if (i < 6) {
      critical[i] <- NA_real_
    } else {
      res <- exuber::radf_mc_cv(n = i, nrep = nrep, seed = 123)
      critical[i] <- res$sadf_cv[2]
    }
  }
  critical
}

analyse_ticker <- function(ticker, stock_df, critical_values) {
  stock_df <- stock_df[stats::complete.cases(stock_df), ]
  monitoring <- real_time_monitoring(stock_df, critical_values)
  trading <- Evaluating_trading_rule(monitoring)
  investment <- trading[[2]]

  geom_ret <- geom_average_retrun(investment)
  sharpe <- if (exists("Risk_free_rate")) sharp(investment, Risk_free_rate) else NA_real_
  buyhold <- buy_hold(stock_df)
  Investment <<- investment
  capm <- if (exists("SP500")) Jensen_Alpha(investment, SP500, Risk_free_rate) else NULL
  alpha <- if (!is.null(capm)) {
    summary(capm)$coefficients[1, 1]
  } else {
    NA_real_
  }

  list(
    ticker = ticker,
    status = "ok",
    geom_average_return = geom_ret,
    sharpe_ratio = sharpe,
    buy_hold_return = buyhold,
    jensen_alpha = alpha,
    monitoring = monitoring,
    trading = trading
  )
}

generate_prices_csv <- function(results, path) {
  if (length(results) == 0) {
    empty <- data.frame(
      ticker = character(),
      Date = as.Date(character()),
      Price = numeric(),
      SADF_statistic = numeric(),
      critical_value = numeric(),
      Signal = logical()
    )
    utils::write.csv(empty, path, row.names = FALSE)
    return(invisible(NULL))
  }
  rows <- lapply(results, function(res) {
    if (!identical(res$status, "ok")) return(NULL)
    data.frame(
      ticker = res$ticker,
      Date = res$monitoring$Date,
      Price = res$monitoring$Price,
      SADF_statistic = res$monitoring$SADF_statistic,
      critical_value = res$monitoring$critical_values,
      Signal = res$monitoring$Logical,
      stringsAsFactors = FALSE
    )
  })
  rows <- rows[!vapply(rows, is.null, logical(1))]
  if (length(rows) == 0) {
    empty <- data.frame(
      ticker = character(),
      Date = as.Date(character()),
      Price = numeric(),
      SADF_statistic = numeric(),
      critical_value = numeric(),
      Signal = logical()
    )
    utils::write.csv(empty, path, row.names = FALSE)
  } else {
    utils::write.csv(do.call(rbind, rows), path, row.names = FALSE)
  }
}

generate_metrics_csv <- function(results, path) {
  metrics <- lapply(results, function(res) {
    if (!is.list(res)) return(NULL)
    data.frame(
      ticker = res$ticker,
      status = res$status,
      geom_average_return = safe_numeric(res$geom_average_return),
      sharpe_ratio = safe_numeric(res$sharpe_ratio),
      buy_hold_return = safe_numeric(res$buy_hold_return),
      jensen_alpha = safe_numeric(res$jensen_alpha),
      message = if (!is.null(res$message)) res$message else "",
      stringsAsFactors = FALSE
    )
  })
  metrics <- metrics[!vapply(metrics, is.null, logical(1))]
  utils::write.csv(do.call(rbind, metrics), path, row.names = FALSE)
}

safe_numeric <- function(x) {
  if (is.null(x) || length(x) == 0) return(NA_real_)
  as.numeric(x)[1]
}

compute_equal_weight_return <- function(results) {
  ok_results <- Filter(function(res) identical(res$status, "ok"), results)
  if (length(ok_results) == 0) return(NA_real_)
  aligned <- Reduce(function(acc, res) {
    df <- res$trading[[2]][, c("Date", "Price", "Logical")]
    names(df) <- c("Date", paste0(res$ticker, "_Price"), paste0(res$ticker, "_Logical"))
    if (is.null(acc)) return(df)
    merge(acc, df, by = "Date", all = TRUE)
  }, ok_results, init = NULL)
  if (is.null(aligned)) return(NA_real_)
  price_cols <- grep("_Price$", names(aligned), value = TRUE)
  aligned <- aligned[order(aligned$Date), ]
  if (length(price_cols) == 0) return(NA_real_)
  returns <- apply(aligned[, price_cols, drop = FALSE], 2, function(col) c(NA, diff(col) / head(col, -1)))
  port_ret <- rowMeans(returns, na.rm = TRUE)
  port_ret[is.nan(port_ret)] <- 0
  cumulative <- prod(1 + port_ret, na.rm = TRUE)
  weeks <- sum(!is.na(port_ret))
  if (weeks <= 0) return(NA_real_)
  (cumulative^(52 / weeks)) - 1
}

packages_needed <- c(
  "yahoofinancer", "exuber", "PerformanceAnalytics", "dplyr", "lubridate", "xts"
)
packages_available <- vapply(packages_needed, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
missing_packages <- names(packages_available)[!packages_available]

if (length(missing_packages) > 0) {
  message("[nasdaq30_run] Missing packages detected: ", paste(missing_packages, collapse = ", "))
}

load_thesis_functions(environment())

args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 1) {
  output_dir <- args[[1]]
} else {
  env_override <- Sys.getenv("OUTPUT_DIR", unset = NA_character_)
  if (!is.na(env_override) && nzchar(env_override)) {
    output_dir <- env_override
  } else {
    output_dir <- "data/nasdaq30/"
  }
}

output_dir <- normalizePath(output_dir, winslash = "\\", mustWork = FALSE)
raw_dir <- file.path(output_dir, "raw")
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
if (!dir.exists(raw_dir)) dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)

start_date <- as.Date("2015-01-01")
end_date <- Sys.Date()

universe <- get_nasdaq30_universe()

fetch_success <- TRUE
analysis_results <- list()
price_store <- list()

if (all(packages_available)) {
  message("[nasdaq30_run] Fetching data for ", nrow(universe), " tickers")
  for (ticker in universe$ticker) {
    dest <- file.path(raw_dir, paste0(ticker, ".csv"))
    message("[nasdaq30_run] Downloading ", ticker, " -> ", dest)
    tryCatch({
      Get_data_and_save(ticker, start_date, end_date, dest)
      price_store[[ticker]] <- read_price_csv(dest)
    }, error = function(e) {
      message("[nasdaq30_run] Failed to download ", ticker, ": ", e$message)
      fetch_success <<- FALSE
    })
  }

  benchmark_path <- file.path(raw_dir, "^GSPC.csv")
  riskfree_path <- file.path(raw_dir, "^TNX.csv")
  tryCatch({
    Get_data_and_save("^GSPC", start_date, end_date, benchmark_path)
    Get_data_and_save("^TNX", start_date, end_date, riskfree_path)
    SP500 <<- read_price_csv(benchmark_path)
    Risk_free_rate <<- read_price_csv(riskfree_path)
  }, error = function(e) {
    message("[nasdaq30_run] Failed to download benchmark or risk-free series: ", e$message)
    fetch_success <<- FALSE
  })
} else {
  fetch_success <- FALSE
  message("[nasdaq30_run] Skipping downloads due to missing dependencies or offline mode.")
}

if (fetch_success && length(price_store) > 0) {
  message("[nasdaq30_run] Running monitoring framework")
  max_len <- max(vapply(price_store, nrow, integer(1)))
  message("[nasdaq30_run] Largest sample size: ", max_len)
  critical_values <- compute_critical_values(max_len)

  for (ticker in names(price_store)) {
    message("[nasdaq30_run] Processing ", ticker)
    stock_df <- price_store[[ticker]]
    analysis_results[[ticker]] <- tryCatch({
      analyse_ticker(ticker, stock_df, critical_values)
    }, error = function(e) {
      message("[nasdaq30_run] Analysis failed for ", ticker, ": ", e$message)
      list(
        ticker = ticker,
        status = "analysis_failed",
        geom_average_return = NA_real_,
        sharpe_ratio = NA_real_,
        buy_hold_return = NA_real_,
        jensen_alpha = NA_real_,
        message = e$message
      )
    })
  }
} else {
  message("[nasdaq30_run] Analysis skipped; recording placeholders.")
  for (ticker in universe$ticker) {
    analysis_results[[ticker]] <- list(
      ticker = ticker,
      status = if (length(missing_packages) > 0) "missing_dependencies" else "data_unavailable",
      geom_average_return = NA_real_,
      sharpe_ratio = NA_real_,
      buy_hold_return = NA_real_,
      jensen_alpha = NA_real_,
      message = "Missing dependencies or offline mode prevented execution"
    )
  }
}

prices_csv <- file.path(output_dir, "prices.csv")
metrics_csv <- file.path(output_dir, "metrics.csv")
avg_return_csv <- file.path(output_dir, "avg_yearly_return.csv")

generate_prices_csv(analysis_results, prices_csv)
generate_metrics_csv(analysis_results, metrics_csv)

eq_port <- compute_equal_weight_return(analysis_results)
avg_df <- data.frame(
  portfolio = c(universe$ticker, "equal_weight"),
  geom_average_return = c(vapply(analysis_results, function(res) safe_numeric(res$geom_average_return), numeric(1)), eq_port),
  status = c(vapply(analysis_results, function(res) res$status, character(1)), ifelse(is.na(eq_port), "insufficient_data", "ok")),
  stringsAsFactors = FALSE
)
utils::write.csv(avg_df, avg_return_csv, row.names = FALSE)

message("[nasdaq30_run] Outputs written to ", output_dir)

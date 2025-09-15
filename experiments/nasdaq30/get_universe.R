#' Retrieve the Nasdaq top ~30 universe
#'
#' Attempts to reuse the thesis Yahoo Finance client (`yahoofinancer::Ticker`) to
#' pull the Nasdaq-100 constituents and rank them by market capitalisation. When
#' either the package or the remote API is unavailable (e.g. offline sandbox),
#' the function falls back to a documented static list approximating the thirty
#' largest Nasdaq-listed equities by free-float market cap during Q1 2025.
#'
#' @return A tibble-like data frame (base data frame to avoid external
#'   dependencies) with tickers and provenance metadata.
#' @param approx_n Target number of tickers to return (defaults to 30).
#' @param prefer_static Force usage of the static list (useful for deterministic
#'   offline runs).
get_nasdaq30_universe <- function(approx_n = 30, prefer_static = FALSE) {
  if (!prefer_static) {
    if (requireNamespace("yahoofinancer", quietly = TRUE)) {
      universe <- try(fetch_via_yahoofinancer(approx_n), silent = TRUE)
      if (!inherits(universe, "try-error")) {
        return(universe)
      }
      message("[get_nasdaq30_universe] Falling back to static list: ", universe)
    } else {
      message("[get_nasdaq30_universe] Package 'yahoofinancer' not installed; using static list.")
    }
  }
  fallback_static_universe(approx_n)
}

fetch_via_yahoofinancer <- function(approx_n) {
  if (!requireNamespace("yahoofinancer", quietly = TRUE)) {
    stop("yahoofinancer package unavailable")
  }

  # `yahoofinancer` does not expose index constituents publicly in the thesis
  # script. We attempt a best-effort approach by first querying the Nasdaq-100
  # ETF (QQQ) holdings, then requesting up-to-date quotes to rank by market cap.
  tickers <- tryCatch({
    qqq <- yahoofinancer::Ticker$new("QQQ")
    holdings <- qqq$get_holdings()
    unique(holdings$ticker)
  }, error = function(e) {
    message("[fetch_via_yahoofinancer] Unable to retrieve QQQ holdings: ", e$message)
    character(0)
  })

  if (length(tickers) == 0) {
    # Second attempt: read Nasdaq-100 constituents if provided
    tickers <- tryCatch({
      ndx <- yahoofinancer::Ticker$new("^NDX")
      comps <- ndx$get_components()
      unique(comps$symbol)
    }, error = function(e) {
      message("[fetch_via_yahoofinancer] Unable to retrieve ^NDX components: ", e$message)
      character(0)
    })
  }

  if (length(tickers) == 0) {
    stop("Unable to obtain ticker universe via yahoofinancer")
  }

  tickers <- unique(na.omit(tickers))
  quotes <- tryCatch({
    clients <- yahoofinancer::Tickers$new(tickers)
    stats <- clients$get_summary_detail()
    stats
  }, error = function(e) {
    message("[fetch_via_yahoofinancer] Unable to retrieve summary details: ", e$message)
    NULL
  })

  if (is.null(quotes) || nrow(quotes) == 0 || !"marketCap" %in% names(quotes)) {
    stop("Market capitalisation data unavailable via yahoofinancer")
  }

  ordered <- quotes[order(as.numeric(quotes$marketCap), decreasing = TRUE), ]
  approx_n <- min(approx_n, nrow(ordered))
  keep <- ordered[seq_len(approx_n), c("symbol", "marketCap")]
  data.frame(
    ticker = keep$symbol,
    market_cap = as.numeric(keep$marketCap),
    source = "yahoofinancer",
    retrieved_at = Sys.time(),
    stringsAsFactors = FALSE
  )
}

fallback_static_universe <- function(approx_n) {
  static <- c(
    "AAPL", "MSFT", "NVDA", "AMZN", "GOOG", "GOOGL", "META", "TSLA", "AVGO",
    "COST", "ADBE", "PEP", "NFLX", "AMD", "CSCO", "INTU", "TXN", "QCOM",
    "AMGN", "HON", "SBUX", "AMAT", "LRCX", "ADI", "BKNG", "PDD", "VRTX",
    "ISRG", "GILD", "MU", "REGN", "PYPL", "MDLZ", "PANW", "KLAC"
  )
  approx_n <- min(approx_n, length(static))
  data.frame(
    ticker = static[seq_len(approx_n)],
    market_cap = NA_real_,
    source = "static_fallback",
    retrieved_at = Sys.time(),
    stringsAsFactors = FALSE
  )
}

if (identical(environment(), globalenv())) {
  print(get_nasdaq30_universe())
}

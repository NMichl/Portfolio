rm(list=ls())
# Library to plot data
library(ggplot2)
# library for SADF test
library(exuber)
# library for yahoo finance api
library(PerformanceAnalytics)
library(yahoofinancer)
library(dplyr)
library(lubridate)
set.seed(123)



# Part1: The following section is defining different function to load the data
# Also contains different line of code needed before the implementation of the tests in a real time monitoring scenario

# 1. Function to fetch historical weekly data and store them 
Get_data_and_save = function(ticker, start_date, end_date, file_path) {
  stock = Ticker$new(ticker)  # Create a ticker object
  data = stock$get_history(start = start_date, end = end_date, interval = "1wk")  # Get weekly data
  data = data[,1:6]  # adj_close price, the 7 column is a list, to easily transform into csv just let it out
  write.csv(data, file_path, row.names = FALSE)  # Save to CSV
}


# 2. Function: Load the stock data from the stored location
# Specify own path to the data to load it accuraetly
load_stock = function(Stock_ticker){
  file_path = paste0("C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/",Stock_ticker, ".csv")
  stock_data <- read.csv(file_path)
  Stock_prices = stock_data[, c(1, 6)] 
  Stock_prices$date <- as.Date(Stock_prices$date) # transform the first column into a date column
  colnames(Stock_prices)[colnames(Stock_prices) == "close"] <- "Price" 
  colnames(Stock_prices)[colnames(Stock_prices) == "date"] <- "Date" # rename column
  print(paste("Missing Dates:", sum(is.na(Stock_prices$Date)))) # Looking for missing dates / Prices
  print(paste("Missing Open Prices:", sum(is.na(Stock_prices$Open))))
  return(Stock_prices)
}

# Fetch data for multiple stocks, the S&P500 and the 10-Year Treasury Bill
# If the data isn't loaded already above and its desired to fetch them by yourself trough the API delete the "#" and specify store location
#Get_data_and_save("CDR.WA", "2012-01-01", "2022-12-28", "C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/CDR.WA.csv") # CD Projekt Red,  , , ,  , .
#Get_data_and_save("MSFT", "1991-01-01", "2002-01-01", "C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/MSFT.csv") # Microsoft
#Get_data_and_save("INTC", "1991-01-01", "2002-01-01", "C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/INTC.csv") # Intel
#Get_data_and_save("ORCL", "1991-01-01", "2002-01-01", "C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/ORCL.csv" )
#Get_data_and_save("QCOM", "1992-01-01", "2002-01-01", "C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/QCOM.csv")
#Get_data_and_save("PLUG", "2016-01-01", "2023-01-01", "C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/Plug.csv") # Plug Power
#Get_data_and_save("CGC", "2015-01-01", "2023-01-01", "C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/CGC.csv") # Canopy Growth Corporation
#Get_data_and_save("VOW.DE", "2000-01-01", "2010-12-24", "C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/VOW.DE.csv") # Volkswagen
#Get_data_and_save("^GSPC", "1990-01-01", "2023-01-01", "C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/^GSPC.csv") # S&P 500
#Get_data_and_save("^TNX", "1990-01-01", "2023-01-01", "C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/^TNX.csv") # 10-Year Treasury Yield
#Get_data_and_save("^IXIC", "1985-01-01", "2003-01-01","C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/^IXIC.csv" )


# As i use different frequency for the NASDAQ data above function can't be used 
stock = Ticker$new("^IXIC")
data = stock$get_history( start = "1985-01-01", end = "2003-01-01", interval = "1mo")
data = data[,1:6]
write.csv(data, "C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/NSDAQ.csv", row.names = FALSE) 
# Simulate the critical values for the SADF
Critical_values = vector(mode = 'numeric', length = 600) 
for (i in 6:600){ 
  values = radf_mc_cv(n = i,  nrep = 2000, seed = 123) # Access already stored critical values
  Critical_values[i] = values$sadf_cv[2]
}
save(Critical_values, file = "C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/Critical_values.RData")
print(Critical_values)

# Load the data 
CGC = load_stock(Stock_ticker = "CGC")
CDR.WA = load_stock(Stock_ticker = "CDR.WA")
INTC = load_stock(Stock_ticker = "INTC")
PLUG = load_stock(Stock_ticker = "PLUG")
VOW.DE = load_stock(Stock_ticker = "VOW.DE")
MSFT = load_stock(Stock_ticker = "MSFT")
ORCL = load_stock(Stock_ticker = "ORCL")
QCOM = load_stock(Stock_ticker = "QCOM")
SP500 = load_stock(Stock_ticker = "^GSPC")
Risk_free_rate = load_stock(Stock_ticker = "^TNX")
NASDAQ = load_stock(Stock_ticker = "^IXIC")
CPI = read.csv("C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/CPIAUCSL.csv")
load("C:/Users/Niklas/OneDrive/Köln Uni/Masterarbeit/Daten Masterarbeit/Preise/Critical_values.RData")
Critical_values


# Obtain Real prices
names(CPI)[names(CPI) == "observation_date"] = "Date"

Stock_prices = merge(NASDAQ, CPI, by = "Date")

Stock_prices$Price = (Stock_prices$Price / Stock_prices$CPI) * 100

Stock_prices = Stock_prices[, c(1, 2)]



ggplot(Stock_prices)+
  geom_line(mapping = aes(x = Date, y = Price)) +
  labs(
    x = "Date",                               
    y = "Open Price (USD)"                     
  ) +
  theme_minimal()  

# Checking whether the SADF test would detect here a bubble 
Statistics = radf(Stock_prices)
summary(Statistics)
autoplot(Statistics, option = "sadf")

# Stamp the emergence of a bubble
datestamp_results = datestamp(Statistics, min_duration = 1, option = "sadf" )
print(datestamp_results)

# Total wealth increase
Start_Bubble = Stock_prices$Price[127]
End_Bubble = Stock_prices$Price[182]
Increase = ((End_Bubble - Start_Bubble)/ Start_Bubble) * 100

# geometric average annualized
Stock_prices$Monthly_Return = c(NA, (Stock_prices$Price[-1] - Stock_prices$Price[-nrow(Stock_prices)]) / Stock_prices$Price[-nrow(Stock_prices)])

cumulative_return = prod(1 + Stock_prices$Monthly_Return[127:182])

num_months = length(127:182)
annualized_return_gemoetricaverage = (cumulative_return^(12 / num_months)) - 1



# Creating the different AR models
set.seed(3456)
u = rnorm(200)
filter_coefficients1 = c(0.6, 0.2)
filter_coefficients2 = c (1.6, -0.6)
filter_coefficients3 = c(0.5, 1.01)

Stationary = filter(u, filter_coefficients1, method = "recursive")
Unit_root = filter(u, filter_coefficients2, method = "recursive")
Explosive = filter(u, filter_coefficients3, method = "recursive")


plot(Stationary, main = expression(paste(varphi[1], "=0.6, ", varphi[2], "=0.2")))
plot(Unit_root, main = expression(paste(varphi[1], "=1.6, ", varphi[2], "=-0.6")))
plot(Explosive, main = expression(paste(varphi[1], "=0.5, ", varphi[2], "=1.01")))










# Part 2: Plotting the data and apply different functions to identify the optimal lag length

# 3.Function: Plotting the data and indicating the existence of a bubble with an SADF test
plot_bubble_testing = function(Stock_name){
  # Calculate statistics and plot the data
  Statistics = radf(Stock_name)  
  c = summary(Statistics)
  print(c)
  
  return(ggplot(Stock_name) +
           geom_line(mapping = aes(x = Date, y = Price)) +
           theme_classic() +
           theme(
             panel.border = element_rect(color = "black", fill = NA, size = 0.5),
             plot.background = element_rect(fill = "white", color = NA),
             panel.background = element_rect(fill = "white", color = NA)
           ) +
           coord_cartesian(clip = "off")
  )
}
# Plot the different data
plot_bubble_testing(Stock_name = PLUG)
plot_bubble_testing(Stock_name = CGC)
plot_bubble_testing(Stock_name = QCOM)
plot_bubble_testing(Stock_name = CDR.WA)
plot_bubble_testing(Stock_name = INTC)
plot_bubble_testing(Stock_name = VOW.DE)
plot_bubble_testing(Stock_name = MSFT)
plot_bubble_testing(Stock_name = ORCL)


# Researching whether we have autocorrelation
# Reduce only to available data at the beginning of the monitoring according to Phillips et al. (2011) rule.
psy_minw(PLUG)
PLUG = PLUG[1:38,]

psy_minw(CGC)
CGC = CGC[1:40,]

psy_minw(QCOM)
QCOM = QCOM[1:46,]


psy_minw(CDR.WA) # All same Length
CDR.WA = CDR.WA[1:48,]
INTC = INTC[1:48,]
VOW.DE = VOW.DE[1:48,]
MSFT = MSFT[1:48,]
ORCL = ORCL[1:48,]


# bubble in the training period
Statistics = radf(PLUG)
summary(Statistics)
Statistics = radf(CGC)
summary(Statistics)
Statistics = radf(QCOM)
summary(Statistics)
Statistics = radf(CDR.WA)
summary(Statistics)
Statistics = radf(INTC)
summary(Statistics)
Statistics = radf(VOW.DE)
summary(Statistics)
Statistics = radf(MSFT)
summary(Statistics)
Statistics = radf(ORCL)
summary(Statistics)

# differenced data as we difference the raw price data in both test
PLUG_d = diff(PLUG$Price)
CGC_d = diff(CGC$Price)
QCOM_d = diff(QCOM$Price)
CDR.WA_d = diff(CDR.WA$Price)
INTC_d= diff(INTC$Price)
VOW.DE_d = diff(VOW.DE$Price)
MSFT_d= diff(MSFT$Price)
ORCL_d = diff(ORCL$Price)




# ACF plot
library(stats)

acf(PLUG$Price, main = "", lag.max = 6)
acf(PLUG_d, main = "", lag.max = 6)

acf(CGC$Price, main = "" , lag.max = 6)
acf(CGC_d, main = "", lag.max = 6)

acf(QCOM$Price, main = "", lag.max = 6)
acf(QCOM_d, main = "", lag.max = 6)

acf(CDR.WA$Price, main = "", lag.max = 6)
acf(CDR.WA_d, main = "", lag.max = 6)

acf(INTC$Price, main = "", lag.max = 6)
acf(INTC_d, main = "", lag.max = 6)

acf(VOW.DE$Price, main = "", lag.max = 6)
acf(VOW.DE_d, main = "", lag.max = 6)

acf(MSFT$Price, main = "", lag.max = 6)
acf(MSFT_d, main = "", lag.max = 6)

acf(ORCL$Price, main = "", lag.max = 6)
acf(ORCL_d, main = "", lag.max = 6)



1000*11.23

# Ljung-Box test with 10 lag as no seasonal data
Box.test(PLUG$Price, lag = 10, type = "Lj")
Box.test(PLUG_d, lag = 10, type = "Lj")

Box.test(CGC$Price, lag = 10, type = "Lj")
Box.test(CGC_d, lag = 10, type = "Lj")

Box.test(QCOM$Price, lag = 10, type = "Lj")
Box.test(QCOM_d, lag = 10, type = "Lj")

Box.test(CDR.WA$Price, lag = 10, type = "Lj")
Box.test(CDR.WA_d, lag = 10, type = "Lj")

Box.test(INTC$Price, lag = 10, type = "Lj")
Box.test(INTC_d, lag = 10, type = "Lj")

Box.test(VOW.DE$Price, lag = 10, type = "Lj")
Box.test(VOW.DE_d, lag = 10, type = "Lj")

Box.test(MSFT$Price, lag = 10, type = "Lj")
Box.test(MSFT_d, lag = 10, type = "Lj")

Box.test(ORCL$Price, lag = 10, type = "Lj")
Box.test(ORCL_d, lag = 10, type = "Lj")



# Lag selection for an AR process using BIC
model = ar(PLUG$Price, bic = TRUE, order.max = 6)
model$order
model = ar(PLUG_d, bic = TRUE, order.max = 6)
model$order

model = ar(CGC$Price, bic = TRUE, order.max = 6)
model$order
model = ar(CGC_d, bic = TRUE, order.max = 6)
model$order

model = ar(QCOM$Price, bic = TRUE, order.max = 6)
model$order
model = ar(QCOM_d, bic = TRUE, order.max = 6)
model$order

model = ar(CDR.WA$Price, bic = TRUE, order.max = 6)
model$order
model = ar(CDR.WA_d, bic = TRUE, order.max = 6)
model$order

model = ar(INTC$Price, bic = TRUE, order.max = 6)
model$order
model = ar(INTC_d, bic = TRUE, order.max = 6) 
model$order

model = ar(VOW.DE$Price, bic = TRUE, order.max = 6)
model$order
model = ar(VOW.DE_d, bic = TRUE, order.max = 6)
model$order

model = ar(MSFT$Price, bic = TRUE, order.max = 6)
model$order
model = ar(MSFT_d, bic = TRUE, order.max = 6)
model$order

model = ar(ORCL$Price, bic = TRUE, order.max = 6)
model$order
model = ar(ORCL_d, bic = TRUE, order.max = 6)
model$order






# Part 3: Defining the function to do the SADF and CUSUM test in a real time monitoring scenario
# Also defining the Trading rule function and the function to compute the Jensen alpha

# 4. Function: Applying the SADF test in a real time monitoring framework to the data
real_time_monitoring = function(Stock_name, Critical_values) {
  testing_end = psy_minw(Stock_name)
  Monitoring_begin = testing_end + 1
  Monitoring_end = nrow(Stock_name)
  Stock_prices_monitoring = Stock_name[1:testing_end,]  # Initialize monitoring prices
  Stock_prices_update = Stock_name[Monitoring_begin:Monitoring_end,]
  
  SADF_statistic = vector(mode = "numeric", length = nrow(Stock_prices_update))
  critical_values = vector(mode = 'numeric', length = nrow(Stock_prices_update))
  Logical = vector(mode = 'logical', length = nrow(Stock_prices_update))
  
  above_threshold = FALSE
  
  for (i in 1:nrow(Stock_prices_update)) {
    Stock_prices_monitoring = rbind(Stock_prices_monitoring, Stock_prices_update[i,])
    results = radf(Stock_prices_monitoring)
    SADF_statistic[i] = results$adf
    
    # Retrieve precomputed critical values for current sample size
    current_sample_size = nrow(Stock_prices_monitoring)
    critical_values[i] = Critical_values[current_sample_size]  
    
    # Apply threshold logic
    if (SADF_statistic[i] > critical_values[i] && !above_threshold) {
      Logical[i] = TRUE
      above_threshold = TRUE
    } else if (SADF_statistic[i] <= critical_values[i] && above_threshold) {
      Logical[i] = FALSE
      above_threshold = FALSE
    } else {
      Logical[i] = above_threshold
    }
  }
  
  switch_df = data.frame(Date = Stock_prices_update$Date, Logical)
  returns = cbind(switch_df, Price = Stock_prices_update$Price, SADF_statistic, critical_values)
  return(returns)
}



# 5. Function: Applying the CUSUM in a real time monitoring framework to the data
# minimum window size as in the SADF
cusum_monitoring = function(Stock_name, training_sample_size, gamma_alpha) {
  
  # Total number of observations (T = T0 + Tm)
  T_sample = nrow(Stock_name)
  T0 = training_sample_size           # Training sample size
  Tm = T_sample - T0                    # Monitoring period length
  
  # not needed for the CUSUM procedure but needed to make the ouptut of data frame consistent with the time span
  Stock_prices_training = Stock_name[1:T0, ]
  Stock_prices_monitoring = Stock_name[(T0+1):T_sample, ]
  # Compute price differences (∆y_t)
  delta_y = diff(Stock_name$Price)
  
  # Initialize storage for CUSUM and variance estimates
  Cusum_stat = numeric(Tm)
  sigma_r = numeric(Tm)
  
  # normalize time index r for the monitoring period. 
  # So r is computed only from the beginning of the monitoring period up to the end of the monitoring period
  r_values = (seq(T0 + 1, T_sample) - T0) / Tm
 
  
  # Loop over the monitoring period.
  for (t in 1:Tm) {
    # The r values are added to the end of the training period so we include also the training sample in the estimation
    rt_index = T0 + floor(r_values[t] * Tm)
    # Computation of the variance
    sigma_r[t] = sqrt(sum(delta_y[1:rt_index]^2) / rt_index)
    # Compute the CUSUM statistic
    Cusum_stat[t] = sum(delta_y[1:rt_index]) / (sigma_r[t] * sqrt(T_sample))
    
  }
  
  # Define the dynamic boundary function b_alpha(r).
  boundary_values = gamma_alpha * (1 + 2 * r_values)
  
  # Detect boundary breaches 
  logical = Cusum_stat > boundary_values
  
  # Return the results as a dataframe
  result_df = data.frame(
    Date = Stock_prices_monitoring$Date,
    Logical = logical,
    Price = Stock_prices_monitoring$Price,
    Cusum_stat = Cusum_stat,
    Boundary = boundary_values
    
  )
  # as differences are taken we have T-1 values and as only the monitoring period is reported here one needs to eliminate the na value in the last row
  result_df = result_df[-(Tm),]
  return(result_df)
}


# 6. Function: Plot critical values against the test statistic (SADF)
plot_statistic = function(data) {
  ggplot(data) +
    geom_line(aes(x = Date, y = SADF_statistic, color = "SADF Statistic")) +
    geom_line(aes(x = Date, y = critical_values, color = "Critical Value")) +
    scale_color_manual(values = c("SADF Statistic" = "green", "Critical Value" = "red")) +
    labs(
      x = "Date",
      y = "Value",
      color = NULL  # Removes "Legend" title
    ) +
    theme_minimal() +
    theme(
      legend.position = c(0.9, 0.95) # Top-right inside plot
    )
}

plot_statistic_cusum = function(data) {
  ggplot(data) +
    geom_line(aes(x = Date, y = Cusum_stat, color = "Cusum_stat")) +
    geom_line(aes(x = Date, y = Boundary, color = "Boundary Values")) +
    scale_color_manual(values = c("Cusum_stat" = "green", "Boundary Values" = "red")) +
    labs(
      x = "Date",
      y = "Value",
      color = NULL  # Removes "Legend" title
    ) +
    theme_minimal() +
    theme(
      legend.position = c(0.2, 0.95) # Top-right inside plot
    )
}

# 7. Function: Implement the trading rule
# Invest to the price we get for the first True signal
# Sell after there have been two consecutive False signal to the price of the second False signal
Evaluating_trading_rule = function(returns){
  returns$Signal = NA # Second logical column to more easily include the return of period where the stock is selled due to False
  for (i in 2:nrow(returns)) {
    if (returns$Logical[i] == FALSE && returns$Logical[i-1] == FALSE) {
      returns$Signal[i] = FALSE  
    } else if (returns$Logical[i] == TRUE) {
      returns$Signal[i] = TRUE  
    } else {
      returns$Signal[i] = returns$Signal[i-1]  
    }
  }
  # last period after investment is now label as True in the Signal column
  returns$Signal[is.na(returns$Signal)] = FALSE
  investment_returns = c()
  in_market = FALSE
  price_true = NA
  
  for (i in 1:nrow(returns)) {
    if (returns$Signal[i] == TRUE && !in_market) {
      price_true = returns$Price[i]
      in_market = TRUE
    } else if (returns$Logical[i] == FALSE && in_market) { # Here used logical as it would otherwise carry on with the investment if Logical looks like this True, False, True
      price_false = returns$Price[i]
      investment_returns = c(investment_returns, (price_false - price_true) / price_true)
      in_market = FALSE
    }
  }
 
  total_investment_return = prod(1 + investment_returns, na.rm = TRUE) -1
  
  
  return(list(total_investment_return, returns))
}





# 8. Function: Compute Jensen_alpha
Jensen_Alpha = function(Investment_data, benchmark_data, Riskfree_data){
  # Weekly data is given by different days of the week, so to join them one needs a the week and year as joint value
  df1 = SP500 %>% mutate(Year = isoyear(Date), Week = isoweek(Date)) 
  df2 = Investment %>% mutate(Year = isoyear(Date), Week = isoweek(Date)) 
  df3 = Risk_free_rate %>% mutate(Year = isoyear(Date), Week = isoweek(Date))
 
  final_df = df2%>% # Join the table based on the above classification of week and year
    left_join(df1, by = c("Year", "Week")) %>%
    left_join(df3, by = c("Year", "Week"))
  
  calculation = final_df[,c(1,3,2,10,12)]
  colnames(calculation) <- c("Date", "AssetPrice", "Logical", "BenchmarkPrice", "RiskFreeRate")
  # Calculate weekly returns
  calculation = calculation %>%
    mutate(
      AssetPrice = (AssetPrice - lag(AssetPrice)) / lag(AssetPrice),
      BenchmarkPrice = (BenchmarkPrice - lag(BenchmarkPrice)) / lag(BenchmarkPrice))
  # removing first row which is na through building returns (taking differences in the process)
  calculation = calculation[-1,]
  #Adjusting the risk free rate as it is given as 1 Year return
  calculation = calculation %>%
    mutate(RiskFreeRate = (1 + RiskFreeRate / 100)^(1/52) - 1)
  # Renaming columns for convenience
  colnames(calculation) = c("Date","AssetReturn", "Logical", "BenchmarkReturn", "RiskFreeRate" )
  print(calculation)
  # Compute excess returns
  calculation = calculation %>%
    mutate(
      AssetReturn = AssetReturn - RiskFreeRate,
      BenchmarkReturn = BenchmarkReturn - RiskFreeRate
    )
  # Important here to lag the returns to get first return after the first True value as it is invested only to the price of the first Trule value
  # Also secures it takes the first False value as the final return
  calculation = calculation %>%
    mutate(AssetReturn = ifelse(lag(Logical, default=FALSE),
                                AssetReturn,
                                0))
  # Set return to zero for not invested periods as invested in bonds
  ret_data = xts(calculation[, c("AssetReturn", "BenchmarkReturn", "RiskFreeRate")],
                 order.by = calculation$Date 
  )
  # Compute Jensen's Alpha
  CAPM_Regression = lm(AssetReturn ~ BenchmarkReturn, data = ret_data)
  return(CAPM_Regression)
}




# 9.Function: Produce geometric average return for the investments
geom_average_retrun = function(data){
 data = data %>%
      mutate(
      Weekly_ret = (Price - lag(Price)) / lag(Price),
      Trade_ret  = ifelse(lag(Logical, default = FALSE),
                    Weekly_ret, 0))
 cumulative_return = prod(1 + data$Trade_ret)
 num_weeks = nrow(data)
 geom_average = (cumulative_return^(52/num_weeks))-1
 return(geom_average)
}

# 10. Sharp ratio
sharp = function(data, Risk_free_rate){
  
  df1 = data %>% mutate(Year = isoyear(Date), Week = isoweek(Date)) 
  df2 = Risk_free_rate %>% mutate(Year = isoyear(Date), Week = isoweek(Date))
  
  final_df = df1 %>% 
    left_join(df2, by = c("Year", "Week"))
  data = final_df[, c(1,3,2,10)]
  colnames(data) <- c("Date", "Price", "Logical", "RiskFreeRate")
  data = data %>%
    mutate(
      weekly_rat = (Price - lag(Price)) / lag(Price)
      ) %>%
      slice(-1)
     
  data <- data %>%
    mutate(RiskFreeRate = (1 + RiskFreeRate/100)^(1/52) - 1,
    ExcessReturn = (weekly_rat - RiskFreeRate))
  # Period we are not invested in the stock we are invested in the risk free rate
  data <- data %>%
    mutate(ExcessReturn  = ifelse(lag(Logical, default=FALSE),
                    ExcessReturn, 0))
  #Compute Sharpe Ratio
  mean_excess = mean(data$ExcessReturn)
  sd_excess = sd(data$ExcessReturn)
  sharpe_ratio = mean_excess / sd_excess
  sharpe_ratio = sharpe_ratio * sqrt(52)
  return(sharpe_ratio)
}

# 12 Buy and Hold strategy
buy_hold = function(data){
  beginning_period = psy_minw(data)+1
  end_monitoring = nrow(data)
  price_beginning = data$Price[beginning_period]
  price_end = data$Price[end_monitoring]
  return_hold = (price_end-price_beginning)/price_beginning
  return(return_hold)
}

# Part 4: Applying the data to the functions
# Load data again as only the subsamples are in the global environment due to the autocorrelation research
PLUG = load_stock(Stock_ticker = "PLUG")
CGC = load_stock(Stock_ticker = "CGC")
QCOM = load_stock(Stock_ticker = "QCOM")
CDR.WA = load_stock(Stock_ticker = "CDR.WA")
INTC = load_stock(Stock_ticker = "INTC")
VOW.DE = load_stock(Stock_ticker = "VOW.DE")
MSFT = load_stock(Stock_ticker = "MSFT")
ORCL = load_stock(Stock_ticker = "ORCL")




# SADF results
results_PLUG_SADF = real_time_monitoring(Stock_name = PLUG, Critical_values)
results_CGC_SADF = real_time_monitoring(Stock_name = CGC, Critical_values)
results_QCOM_SADF = real_time_monitoring(Stock_name = QCOM, Critical_values)
results_CDR.WA_SADF = real_time_monitoring(Stock_name = CDR.WA, Critical_values)
results_INTC_SADF = real_time_monitoring(Stock_name = INTC, Critical_values)
results_VOW.DE_SADF = real_time_monitoring(Stock_name = VOW.DE, Critical_values)
results_MSFT_SADF = real_time_monitoring(Stock_name = MSFT, Critical_values)
results_ORCL_SADF = real_time_monitoring(Stock_name = ORCL, Critical_values)


# Plotting the results
plot_statistic(results_PLUG_SADF)
plot_statistic(results_CGC_SADF)
plot_statistic(results_QCOM_SADF)
plot_statistic(results_CDR.WA_SADF)
plot_statistic(results_INTC_SADF)
plot_statistic(results_VOW.DE_SADF)
plot_statistic(results_MSFT_SADF)
plot_statistic(results_ORCL_SADF)


# Trading rule (SADF)
return_PLUG_SADF = Evaluating_trading_rule(results_PLUG_SADF) 
return_PLUG_SADF[[1]]
return_CGC_SADF = Evaluating_trading_rule(results_CGC_SADF)
return_CGC_SADF[[1]]
return_QCOM_SADF = Evaluating_trading_rule(results_QCOM_SADF)
return_QCOM_SADF[[1]]
return_CDR.WA_SADF = Evaluating_trading_rule(results_CDR.WA_SADF)
return_CDR.WA_SADF[[1]]
return_INTC_SADF = Evaluating_trading_rule(results_INTC_SADF)
return_INTC_SADF[[1]]
return_VOW.DE_SADF =Evaluating_trading_rule(results_VOW.DE_SADF)
return_VOW.DE_SADF[[1]]
return_MSFT_SADF =Evaluating_trading_rule(results_MSFT_SADF)
return_MSFT_SADF[[1]]
return_ORCL_SADF = Evaluating_trading_rule(results_ORCL_SADF)
return_ORCL_SADF[[1]]



# Jensen Alpha SADF and geometric average return yearly
Investment = return_PLUG_SADF[[2]]
geom_average_retrun(Investment)
sharp(Investment, Risk_free_rate)
Capm_PLUG_SADF = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_PLUG_SADF)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_CGC_SADF[[2]]
geom_average_retrun(Investment)
Capm_CGC_SADF = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_CGC_SADF)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_QCOM_SADF[[2]]
geom_average_retrun(Investment)
Capm_QCOM_SADF = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_QCOM_SADF)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_CDR.WA_SADF[[2]]
geom_average_retrun(Investment)
Capm_CDR.WA_SADF = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_CDR.WA_SADF)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_INTC_SADF[[2]]
geom_average_retrun(Investment)
Capm_INTC_SADF = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_INTC_SADF)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_VOW.DE_SADF[[2]]
geom_average_retrun(Investment)
Capm_VOW.DE_SADF = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_VOW.DE_SADF)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_MSFT_SADF[[2]]
geom_average_retrun(Investment)
Capm_MSFT_SADF = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_MSFT_SADF)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_ORCL_SADF[[2]]
geom_average_retrun(Investment)
Capm_ORCL_SADF = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_ORCL_SADF)
other_measerues$coefficients
other_measerues$r.squared


# CUSUM results
training_sample_size = psy_minw(PLUG) 
results_PLUG_CUSUM = cusum_monitoring(PLUG, training_sample_size, 0.919)
training_sample_size = psy_minw(CGC) 
results_CGC_CUSUM = cusum_monitoring(CGC, training_sample_size, 0.919)
training_sample_size = psy_minw(QCOM) 
results_QCOM_CUSUM = cusum_monitoring(QCOM, training_sample_size, 0.919)
training_sample_size = psy_minw(CDR.WA) 
results_CDR.WA_CUSUM = cusum_monitoring(CDR.WA, training_sample_size, 0.919)
training_sample_size = psy_minw(INTC) 
results_INTC_CUSUM = cusum_monitoring(INTC, training_sample_size, 0.919)
training_sample_size = psy_minw(VOW.DE) 
results_VOW.DE_CUSUM = cusum_monitoring(VOW.DE, training_sample_size, 0.919)
training_sample_size = psy_minw(MSFT) 
results_MSFT_CUSUM = cusum_monitoring(MSFT, training_sample_size, 0.919)
training_sample_size = psy_minw(ORCL) 
results_ORCL_CUSUM = cusum_monitoring(ORCL, training_sample_size, 0.919)



plot_statistic_cusum(results_PLUG_CUSUM)
plot_statistic_cusum(results_CGC_CUSUM)
plot_statistic_cusum(results_QCOM_CUSUM)
plot_statistic_cusum(results_CDR.WA_CUSUM)
plot_statistic_cusum(results_INTC_CUSUM)
plot_statistic_cusum(results_VOW.DE_CUSUM)
plot_statistic_cusum(results_MSFT_CUSUM)
plot_statistic_cusum(results_ORCL_CUSUM)



# Trading rule (CUSUM)
return_PLUG_CUSUM = Evaluating_trading_rule(results_PLUG_CUSUM)
return_PLUG_CUSUM[[1]]
return_CGC_CUSUM = Evaluating_trading_rule(results_CGC_CUSUM)
return_CGC_CUSUM[[1]]
return_QCOM_CUSUM =Evaluating_trading_rule(results_QCOM_CUSUM)
return_QCOM_CUSUM[[1]]
return_CDR.WA_CUSUM = Evaluating_trading_rule(results_CDR.WA_CUSUM)
return_CDR.WA_CUSUM[[1]]
return_INTC_CUSUM = Evaluating_trading_rule(results_INTC_CUSUM)
return_INTC_CUSUM[[1]]
return_VOW.DE_CUSUM =Evaluating_trading_rule(results_VOW.DE_CUSUM)
return_VOW.DE_CUSUM[[1]]
return_MSFT_CUSUM =Evaluating_trading_rule(results_MSFT_CUSUM)
return_MSFT_CUSUM[[1]]
return_ORCL_CUSUM =Evaluating_trading_rule(results_ORCL_CUSUM)
return_ORCL_CUSUM[[1]]

# Jensen alpha
Investment = return_PLUG_CUSUM[[2]]
geom_average_retrun(Investment)
Capm_PLUG_CUSUM = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_PLUG_CUSUM)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_CGC_CUSUM[[2]]
geom_average_retrun(Investment)
Capm_CGC_CUSUM = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_CGC_CUSUM)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_QCOM_CUSUM[[2]]
geom_average_retrun(Investment)
Capm_QCOM_CUSUM = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_QCOM_CUSUM)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_CDR.WA_CUSUM[[2]]
geom_average_retrun(Investment)
Capm_CDR.WA_CUSUM = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_CDR.WA_CUSUM)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_INTC_CUSUM[[2]]
geom_average_retrun(Investment)
Capm_INTC_CUSUM = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_INTC_CUSUM)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_VOW.DE_CUSUM[[2]]
geom_average_retrun(Investment)
Capm_VOW.DE_CUSUM = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_VOW.DE_CUSUM)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_MSFT_CUSUM[[2]]
geom_average_retrun(Investment)
Capm_MSFT_CUSUM = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_MSFT_CUSUM)
other_measerues$coefficients
other_measerues$r.squared

Investment = return_ORCL_CUSUM[[2]]
geom_average_retrun(Investment)
Capm_ORCL_CUSUM = Jensen_Alpha(Investment,SP500,Risk_free_rate)
other_measerues = summary(Capm_ORCL_CUSUM)
other_measerues$coefficients
other_measerues$r.squared


# Sharpe Ratio SADF

Investment = return_PLUG_SADF[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_CGC_SADF[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_QCOM_SADF[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_CDR.WA_SADF[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_INTC_SADF[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_VOW.DE_SADF[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_MSFT_SADF[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_ORCL_SADF[[2]]
sharp(Investment, Risk_free_rate)


# Sharpe Ratio CUSUM
Investment = return_PLUG_CUSUM[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_CGC_CUSUM[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_QCOM_CUSUM[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_CDR.WA_CUSUM[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_INTC_CUSUM[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_VOW.DE_CUSUM[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_MSFT_CUSUM[[2]]
sharp(Investment, Risk_free_rate)
Investment = return_ORCL_CUSUM[[2]]
sharp(Investment, Risk_free_rate)


# Buy and hold strategy
buy_hold(PLUG) 
buy_hold(CGC)
buy_hold(CDR.WA)
buy_hold(QCOM)
buy_hold(INTC)
buy_hold(VOW.DE)
buy_hold(MSFT)
buy_hold(ORCL)



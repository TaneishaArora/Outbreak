library(tidyverse) # data manipulation
library(forecast) # for ts modelling
library(urca) # for unit root test

# Imputing value for -ve case count observed in 2017
observations_to_impute <- c(123)
forecast_df[observations_to_impute,"observed"] <- (forecast_df[observations_to_impute-1,"observed"] + forecast_df[observations_to_impute+1,"observed"])/2


# Normalzing couts
scaled_forecast <- forecast_df %>%
  mutate_all(scale)

# Time series object
ts_obj <- ts(forecast_df, start = c(2015, 1), end = c(2017, 52) , frequency = 52)

# Time series object with scaled counts
ts_obj_scaled <- ts(scaled_forecast, start = c(2015, 1), end = c(2017, 52), frequency = 52)


# Timeseries plots

# Obserevations + Twitter
autoplot(ts_obj_scaled[,c("observed", "tweet_count")]) +
  xlab("Year") + 
  ylab("Normalized Counts") +
  scale_color_discrete(name = "Counts", labels = c("US Case Count", "Tweet Count"))

# Observations + Reddit
autoplot(ts_obj_scaled[,c("observed", "submission_count", "comment_count")]) +
  xlab("Year") + 
  ylab("Normalized Counts") +
  scale_color_discrete(name = "Counts", labels = c("US Case Count", "Reddit Submission Count", "Reddit Comment Count"))


# Observations + Brazil
autoplot(ts_obj_scaled[,c("observed", "brazil_counts")]) +
  xlab("Year") + 
  ylab("Normalized Counts") +
  scale_color_discrete(name = "Counts", labels = c("US Case Count", "Brazil Case Counts"))


# Observations + Public Health Account Tweets
autoplot(ts_obj_scaled[,c("observed", "ph_account_counts")]) +
  xlab("Year") + 
  ylab("Normalized Counts") +
  scale_color_discrete(name = "Counts", labels = c("US Case Count", "Public Health Account Tweet Counts"))


# Is our data stationary?
# unit root test
observed_vals <- forecast_df %>% 
  mutate(observed = if_else(is.na(observed), 0, observed)) 

observed_vals$observed %>% ggtsdisplay(main="")


# Our data is stationary
ur.df(diff(observed_vals$observed)) %>% summary()
ndiffs(observed_vals$observed)

# Determine if there is auto-correlation in our data
acf(diff(forecast_df$observed), na.action = na.omit)
Box.test(diff(observed_vals$observed), lag = 2)


# Cross Correlation plots
ccf(x = diff(forecast_df$observed), y = diff(forecast_df$brazil_counts), na.action = na.omit)

  
ccf(x = diff(forecast_df$observed), y = diff(forecast_df$submission_count), na.action = na.omit)


ccf(x = diff(forecast_df$observed), y = diff(forecast_df$tweet_count), na.action = na.omit)


# Modelling


# ARIMA (to leverage past data to predict future info)

# Lagged predictors
lagged_predictors <- cbind(
  lagged_brazil_counts = stats::lag(ts_obj[, "brazil_counts"], 6),
  lagged_reddit_counts = stats::lag(ts_obj[, "submission_count"], 6)
)


ar_1 <- Arima(ts_obj[53:104,"observed"], order=c(3, 1, 0))
f1 <- forecast(ar_1)
summary(ar_1)


ar_2 <- Arima(ts_obj[53:104,"observed"], xreg = ts_obj[53:104, c("tweet_count")], order=c(3, 1, 0))
f2 <- forecast(ar_2, xreg = ts_obj[53:104, c("tweet_count")])
summary(ar_2)

ar_3 <- Arima(ts_obj[53:104,"observed"], xreg = lagged_predictors[53:104, c("lagged_brazil_counts")], order=c(2, 1, 0))
f3 <- forecast(ar_3, xreg = lagged_predictors[53:104, c("lagged_brazil_counts")])
summary(ar_3)


# Visualize Fitted vs Actual
predictions <- as.data.frame(cbind(
  week = 1:52,
  actual = ts_obj[53:104, c("observed")],
  model1 = f1$fitted,
  model2 = f2$fitted,
  model3 = f3$fitted
  ))

predictions %>%
  gather(key = "Model", value = "Prediction",  c("actual", "model1", "model2", "model3")) %>%
  ggplot(aes(x = week, y = Prediction, color = Model)) +
  geom_line()


##############################################


# Time Series Linear Regression (use info at specific time point)
# Tweet Count
lr_baseline_twitter <- tslm(observed ~ tweet_count, data = ts_obj)

# reddit submissions
# zika, 
lr_baseline_reddit <- tslm(observed ~ submission_count, data = ts_obj)
lr_zika_reddit <- tslm(observed ~ num_zika_submissions, data = ts_obj)

# full model with feature sele
lr_full <- tslm(observed ~ ., data = ts_obj)
lr_step <- stepAIC(lr_full)


# Visualize Fitted vs Actual
cbind(Data = ts_obj_scaled[,"observed"],
      Fitted = fitted(lr_baseline_scaled)) %>%
  as.data.frame() %>%
  ggplot(aes(x=Data, y=Fitted)) +
  geom_point() +
  ylab("Fitted (predicted values)") +
  xlab("Data (actual values)") +
  ggtitle("Percent change in US consumption expenditure") +
  geom_abline(intercept=0, slope=1)



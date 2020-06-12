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
autoplot(ts_obj_scaled[,c("observed", "tweet_count", "brazil_counts")]) +
  xlab("Year") + 
  ylab("Normalized Counts") +
  scale_color_discrete(name = "Counts", labels = c("US Case Count", "Tweet Count", "Brazil Count"))

# Observations + Reddit
autoplot(ts_obj_scaled[,c("observed", "comment_count", "brazil_counts")]) +
  xlab("Year") + 
  ylab("Normalized Counts") +
  scale_color_discrete(name = "Counts", labels = c("US Case Count", "Reddit Comment Count", "Brazil Count"))


# Observations + Public Health Account Tweets
autoplot(ts_obj_scaled[,c("observed", "ph_account_counts", "brazil_counts")]) +
  xlab("Year") + 
  ylab("Normalized Counts") +
  scale_color_discrete(name = "Counts", labels = c("US Case Count", "Public Health Account Tweet Counts", "Brazil Count"))

# Observations + Flavivirus
autoplot(ts_obj_scaled[,c("observed", "tk_flavivirus", "brazil_counts")]) +
  xlab("Year") + 
  ylab("Normalized Counts") +
  scale_color_discrete(name = "Counts", labels = c("US Case Count", "'Flavivirus' in Tweet", "Brazil Count"))


# Observations + Science Comments
autoplot(ts_obj_scaled[,c("observed", "num_zika_submissions", "brazil_counts")]) +
  xlab("Year") + 
  ylab("Normalized Counts") +
  scale_color_discrete(name = "Counts", labels = c("US Case Count", "Submissions to 'Zika' Subreddit", "Brazil Count"))


# Is our data stationary?
# unit root test
observed_vals <- forecast_df %>% 
  mutate(observed = if_else(is.na(observed), 0, observed)) 

observed_vals$observed %>% ggtsdisplay(main="")

autoplot(ts_obj_scaled[,c("observed")]) +
  xlab("Year") + 
  ylab("Normalized US Zika Case Counts")

autoplot(diff(ts_obj_scaled[,c("observed")])) +
  xlab("Year") + 
  ylab("(Differenced) Normalized US Zika Case Counts")


# Our data is stationary
ur.kpss(observed_vals$observed) %>% summary()
ndiffs(observed_vals$observed)


# Determine if there is auto-correlation in our data
ggAcf(diff(forecast_df$observed), na.action = na.omit) +
  labs(title = "Autocorrelation Function Plot for Differenced US Zika Case Counts")

ggAcf(diff(forecast_df$observed), na.action = na.omit, type = "partial") +
  labs(title = "Partial Autocorrelation Function Plot for Differenced US Zika Case Counts")
  
Box.test(diff(observed_vals$observed), lag = 2)


# Cross Correlation plots
ggCcf(x = diff(forecast_df$observed), y = diff(forecast_df$brazil_counts), na.action = na.omit) +
  labs(title = "Cross Correlation Function Plot Between Differenced US Zika Case Counts and Brazil Case Counts")


  
ggCcf(x = diff(forecast_df$observed), y = diff(forecast_df$submission_count), na.action = na.omit) +
  labs(title = "Cross Correlation Function Plot Between Differenced US Zika Case Counts and Reddit Submission Counts")


ggCcf(x = diff(forecast_df$observed), y = diff(forecast_df$tweet_count), na.action = na.omit) +
  labs(title = "Cross Correlation Function Plot Between Differenced US Zika Case Counts and Tweet Counts")



# Modelling


# ARIMA (to leverage past data to predict future info)

# Lagged predictors
lagged_predictors <- cbind(
  lagged_brazil_counts = stats::lag(ts_obj[, "brazil_counts"], 6),
  lagged_reddit_counts = stats::lag(ts_obj[, "submission_count"], 6),
  lagged_tweet_counts = stats::lag(ts_obj[, "tweet_count"], 5)
)


ar_1 <- Arima(ts_obj[53:104,"observed"], order=c(3, 1, 0))
f1 <- forecast(ar_1)
summary(ar_1)


ar_2 <- Arima(ts_obj[53:104,"observed"], xreg = lagged_predictors[53:104, c("lagged_tweet_counts")], order=c(3, 1, 0))
f2 <- forecast(ar_2, xreg = lagged_predictors[53:104, c("lagged_tweet_counts")])
summary(ar_2)

ar_3 <- Arima(ts_obj[53:104,"observed"], xreg = lagged_predictors[53:104, c("lagged_brazil_counts")], order=c(2, 1, 0))
f3 <- forecast(ar_3, xreg = lagged_predictors[53:104, c("lagged_brazil_counts")])
summary(ar_3)


cor(fitted(ar_1), ts_obj[53:104,"observed"])^2

cor(fitted(ar_tweet_reddit_ph_account_brazil), ts_obj[53:104,"observed"])^2



# Visualize Fitted vs Actual
predictions <- as.data.frame(cbind(
  week = 1:52,
  actual = ts_obj[53:104, c("observed")],
  model1 = f1$fitted,
  model2 = f2$fitted,
  model3 = f3$fitted
  ))

predictions %>%
  gather(key = "Model", value = "Prediction",  c("actual", "model1", "model2")) %>%
  ggplot(aes(x = week, y = Prediction, color = Model)) +
  geom_line()


##############################################


# Time Series Linear Regression (use info at specific time point)
# Tweet Count
lr_baseline_twitter <- tslm(observed ~ tweet_count, data = ts_obj[53:104,])

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



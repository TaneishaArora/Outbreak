library(forecast)
library(MASS)

scaled_forecast <- forecast_df %>%
  mutate_all(scale)


# Create timeseries
ts_obj <- ts(forecast_df[53:105,], frequency = 52)

ts_obj_scaled <- ts(scaled_forecast[53:105,], frequency = 52)

# EDA to determine hyperparameters (like pdq values -> this is where the ACF plots kick in)
# Correlation plots

# Modelling

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


# Exponential Smoothing (weighted average of your past values)

# ARIMA (to leverage past data to predict future info)
# Brazil + lag to predict US counts
ar_li <- arima(ts_obj[,"observed"],  order=c(3, 1, 1))



# Evaluation



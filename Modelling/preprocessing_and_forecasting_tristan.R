library(tidyverse)

# Establishing connection with database
con <- DBI::dbConnect(RPostgres::Postgres(),
                      host = "database-1.cssxbzueyuxe.us-east-1.rds.amazonaws.com",
                      user = "postgres",
                      password = "CK2kFnQvBUmMm4fJ84zG",
                      dbname = "postgres"
)

# tweets
zika_tweets <- collect(tbl(con, "outbreak_tweets_extended"))

# reddit submissions
reddit_submissions <- collect(tbl(con, "outbreak_reddit_submissions"))

# reddit comments
reddit_comments <- collect(tbl(con, "outbreak_reddit_comments"))

# reddit features
reddit_features <- collect(tbl(con, "reddit_features"))


# public health accounts
ph_accounts <- collect(tbl(con, "public_health_accounts"))

# international orgs
intl_orgs <- collect(tbl(con, "world_orgs"))

# Features:
#   Week, 
#   Tweet Count, 
#   Submission Count, 
#   Comment Count, 
#   Keyword counts, 
#   World Org Counts, 
#   PH User Counts, 
#   Subreddit count

zika_df <- 
  collect(zika_tweets) %>%
  arrange(week_number) %>%
  group_by(week_number) %>% 
  summarise(
    tweet_count = n(),
    tk_zika = as.integer(sum(zika_count)),
    tk_zikv = as.integer(sum(zikv_count)),
    tk_mosquito = as.integer(sum(mosquito_count)),
    tk_aedes = as.integer(sum(aedes_count)),
    tk_gullain_barr = as.integer(sum(gullain_barr_count)),
    tk_flavivirus = as.integer(sum(flavivirus_count))
  )

ph_account_post_df <- 
  zika_tweets %>%
  filter(userid %in% intl_orgs$id | userid %in% ph_accounts$id) %>%
  group_by(week_number) %>%
  summarise(ph_account_counts = n())

zika_df <- zika_df %>% 
  left_join(ph_account_post_df, by = 'week_number') %>%
  mutate(ph_account_counts = replace_na(ph_account_counts, 0))

reddit_submissions_df <- 
  collect(reddit_submissions) %>%
  arrange(week_number) %>%
  group_by(week_number) %>% 
  summarise(
    submission_count = n()
  )

reddit_comment_df <- 
  collect(reddit_comments) %>%
  arrange(week_number) %>%
  group_by(week_number) %>% 
  summarise(
    comment_count = n()
  )

reddit_features_df <- 
  collect(reddit_features) %>%
  rename(week_number = week_nums) %>%
  arrange(week_number)


forecast_df <-
  zika_df %>%
  full_join(reddit_submissions_df, by = 'week_number') %>%
  full_join(reddit_comment_df, by = 'week_number') %>%
  full_join(reddit_features_df, by = 'week_number') %>%
  mutate(
    tweet_count = replace_na(tweet_count, 0),
    tk_zika = replace_na(tk_zika, 0),
    tk_zikv = replace_na(tk_zikv, 0),
    tk_mosquito = replace_na(tk_mosquito, 0),
    tk_aedes = replace_na(tk_aedes, 0),
    tk_gullain_barr = replace_na(tk_gullain_barr, 0),
    tk_flavivirus = replace_na(tk_flavivirus, 0),
    submission_count = replace_na(submission_count, 0),
    ph_account_counts = replace_na(ph_account_counts, 0),
    comment_count = replace_na(comment_count, 0),
    num_science_submissions = replace_na(num_science_submissions, 0),
    num_science_comments = replace_na(num_science_comments, 0),
    num_zika_submissions = replace_na(num_zika_submissions, 0),
    num_zika_comments = replace_na(num_zika_comments, 0),
    num_health_submissions = replace_na(num_health_submissions, 0),
    num_health_comments = replace_na(num_health_comments, 0)
  )

counts <- read_csv(file.choose())

counts <- counts %>% select(week_number = epoch, observed)

forecast_df <- forecast_df %>% 
  full_join(counts, by = 'week_number') %>% 
  arrange(week_number) %>%
  mutate(
    num_science_submissions = as.integer(num_science_submissions),
    num_science_comments = as.integer(num_science_comments),
    num_zika_submissions = as.integer(num_zika_submissions),
    num_zika_comments = as.integer(num_zika_comments),
    num_health_submissions = as.integer(num_health_submissions),
    num_health_comments = as.integer(num_health_comments)
  )


forecast_df$week_number <- NULL

#remove gullain bar and observed when using for predictors

# Reading in the csv file that contains our case counts along with our features (uploaded to git)
forecast_df_with_counts <- forecast_df


# Turning this dataframe into a time series object, from week 1 of 2015 to week 52 of 2017 observed weekly
forecast_ts <- ts(data=forecast_df_with_counts,start=c(2015,1),end=c(2017,26),frequency=52)

# Forecasting Steps

#Step 1: Use our case count data to fit an arima model with our features using auto.arima(). This returns a fit object.

# This is a fit object using only tweet count to predict observed case counts
fit_one <- auto.arima(forecast_ts[,"observed"],
                  xreg=forecast_ts[,"tweet_count"])


# This should predict observed counts using all/two of our features so far

xreg_multiple <- cbind(forecast_ts[,c(9,10)]) #hardcoded to leave out observed and gullain barr


fit_all <- arima(forecast_ts[,"observed"],
                  xreg=xreg_multiple,seasonal=FALSE)


# Then we can take this fit object, and forecast it for the period we want to forecast.


#Step 2: Use the forecast method which takes: our previous fit object,the predictors for the period we want to forecast.

# fcast <- forecast(fit, xreg = columns of our forecast period predictors)
forecast(fit_all,xreg=as.matrix(forecast_df[131,c(9,10)]))


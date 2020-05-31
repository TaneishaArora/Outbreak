library(tidyverse)
library(ggplot2)
library(forecast)


# Establishing connection with database
con <- DBI::dbConnect(RPostgres::Postgres(),
                      host = "database-1.cssxbzueyuxe.us-east-1.rds.amazonaws.com",
                      user = "postgres",
                      password = "CK2kFnQvBUmMm4fJ84zG",
                      dbname = "postgres"
)

# Viz. for Zika Case Counts in Brazil
case_counts <- read_csv("counts.csv") %>%
  transmute(week = epoch, case_count = observed, year = as.integer(floor(week/54) + 2015))

reddit_submissions <- reddit_submissions %>% mutate(year = as.integer(floor(week_number/54) + 2015))

reddit_comments <- reddit_comments %>% mutate(year = as.integer(floor(week_number/54) + 2015))

zika_tweets <- zika_tweets %>% mutate(year = as.integer(floor(week_number/54) + 2015))


# Total case count split by year
case_counts %>% group_by(year) %>% summarise(total_counts = sum(case_count)) %>%
ggplot(aes(x = as.factor(year), fill = as.factor(year)))+
  geom_bar(aes(y = total_counts), stat = 'identity') + 
  xlab("Year") + 
  ylab("Total Case Count") +
  geom_text(aes(y = total_counts, label = total_counts), vjust = 2) +
  labs(fill = "Year")

# Case count over time
autoplot(ts_cases_scaled, size = 1) +
  xlab("Time (in weeks)") +
  ylab("Scaled Case Count")


# Viz. for reddit
autoplot(ts_submission_scaled, size = 1) +
  xlab("Time (in weeks)") +
  ylab("Scaled Counts") +
  scale_color_discrete(name = "Feature", labels = c("Reddit Submissions", "Reported Zika Cases"))

autoplot(ts_comments_scaled, size = 1) +
  xlab("Time (in weeks)") +
  ylab("Scaled Counts") +
  scale_color_discrete(name = "Feature", labels = c("Reddit Comments", "Reported Zika Cases"))

reddit_submissions %>% 
  mutate(subreddit = case_when(str_to_lower(subreddit) == 'zika' ~ 'zika',
                               str_to_lower(subreddit) == 'science' ~ 'science',
                               str_to_lower(subreddit) == 'health' ~ 'health',
                               !(str_to_lower(subreddit) %in% c('zika', 'science', 'health')) ~ 'other')) %>%
  group_by(year, subreddit) %>%
  summarise(total_counts = n()) %>%
  ggplot(aes(x = year, fill = subreddit))+
  geom_bar(aes(y = total_counts), stat = 'identity') + 
  xlab("Year") + 
  ylab("Total Count") +
  labs(fill = "Subreddit")

reddit_comments %>% 
  mutate(subreddit = case_when(str_to_lower(subreddit) == 'zika' ~ 'zika',
                               str_to_lower(subreddit) == 'science' ~ 'science',
                               str_to_lower(subreddit) == 'health' ~ 'health',
                               !(str_to_lower(subreddit) %in% c('zika', 'science', 'health')) ~ 'other')) %>%
  group_by(year, subreddit) %>%
  summarise(total_counts = n()) %>%
  ggplot(aes(x = year, fill = subreddit))+
  geom_bar(aes(y = total_counts), stat = 'identity') + 
  xlab("Year") + 
  ylab("Total Count") +
  labs(fill = "Subreddit")


# Viz. for twitter
autoplot(ts_twitter_scaled, size = 1) +
  xlab("Time (in weeks)") +
  ylab("Scaled Counts") +
  scale_color_discrete(name = "Feature", labels = c("Tweets", "Reported Zika Cases"))

zika_tweets %>% 
  mutate(is_ph_account = (userid %in% ph_accounts$id | userid %in% intl_orgs$id)) %>%
  group_by(year, is_ph_account) %>%
  summarise(total_counts = n()) %>%
  ggplot(aes(x = year, fill = is_ph_account))+
  geom_bar(aes(y = total_counts), stat = 'identity') + 
  xlab("Year") + 
  ylab("Total Count") +
  scale_fill_discrete(name = "Account Type", labels = c("Other", "Public Health Account"))

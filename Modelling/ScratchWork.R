# Ucomment to install surveillance if not installed
# install.packages("surveillance")
library(surveillance)

# Install necessary DB driver
# install.packages("RPostgres")
library(RPostgres)

# Install package to view data
install.packages("rmarkdown")

library(tidyverse)

# Establishing connection with database
con <- DBI::dbConnect(RPostgres::Postgres(),
                      host = "database-1.cssxbzueyuxe.us-east-1.rds.amazonaws.com",
                      user = "postgres",
                      password = "CK2kFnQvBUmMm4fJ84zG",
                      dbname = "postgres"
)

zika_tweets <- tbl(con, "outbreak_tweets")
zika_reddit_submissions <- tbl(con, "outbreak_reddit_submissions")
zika_reddit_comments <- tbl(con, "outbreak_reddit_comments")



# Preprocessing Case count data
cases_15 <- read_csv("../Data/2015_case_counts.csv")
cases_16 <- read_csv("../Data/2016_case_counts.csv")
cases_17 <- read_csv("../Data/2017_case_counts.csv")

# Take a peep at the data and check for wierdness
# cases_15 %>% View()
# cases_16 %>% View()
# cases_17 %>% View()

# Some countries are missing the Epiweek and have NA fields... these are the same records that
# have an NA in the Measure Filter column (take a peak at the data on the CDC website for these 
# countries)
inspect_15 <- cases_15 %>% filter(is.na(`Measures Filter`))
inspect_16 <- cases_16 %>% filter(is.na(`Measures Filter`))
inspect_17 <- cases_17 %>% filter(is.na(`Measures Filter`))

# Check what is up with these NA fields
cases_15 %>% filter(`Country or Subregion` == 'United States of America') %>% View()
cases_16 %>% filter(is.na(`Measures Filter`) & `Country or Subregion` == 'United States of America') %>% distinct(
  `Country or Subregion`, `EW`) %>% View()
cases_16 %>% filter(`Country or Subregion` == 'United States of America') %>% View()


# Got to preprocess the data + take a better look at to understand what's going on with some of the
# countries...

# Test Surveillance out with Brazil :)
b_15 <- cases_15 %>% filter(`Country or Subregion` == 'Brazil')
b_16 <- cases_16 %>% filter(`Country or Subregion` == 'Brazil')
b_17 <- cases_17 %>% filter(`Country or Subregion` == 'Brazil') 


# Function to compute weekly case counts
compute_weekly_counts <- function(b_cases){
  shifted_case_count <- b_cases %>% arrange(EW) %>% 
    select(case_count = `Total Cases (b)`, Year) %>% 
    add_row(case_count = 0, .before = 1)
  
  cases <- b_cases %>% arrange(EW) %>% select(week_number = EW, case_count = `Total Cases (b)`, Year)
  cases$shifted_counts <- shifted_case_count$case_count[1:53]
  
  return (cases %>% mutate(weekly_count = case_count - shifted_counts))
}

b_15 <- compute_weekly_counts(b_15)
b_16 <- compute_weekly_counts(b_16)
b_17 <- compute_weekly_counts(b_17)


# The "Total Case Count" field is cumulative, so gotta subtract total from prev epiyear to get
# weekly case count (...I think?)
b_cases <- bind_rows(b_15, b_16, b_17)
b_cases <- b_cases %>% mutate(week_number = (Year-2015)*53 + week_number)



zt <-  zika_tweets %>% group_by(week_number) %>% count() %>% select(epoch = week_number, tweet_count = n)

rs <- zika_reddit_submissions %>% group_by(week_number) %>% count() %>% select(epoch = week_number, r_sub_count = n)

rc <- zika_reddit_comments %>% group_by(week_number) %>% count() %>% select(epoch = week_number, r_comment_count = n)

ts <- b_cases %>% 
  mutate(observed = weekly_count, epoch = week_number) %>%
  select(epoch, case_count, observed)



ts <- ts %>% select(epoch, observed) 

ts_df <- ts %>% 
  left_join(zt, copy = TRUE, by = 'epoch') %>% 
  left_join(rs, copy = TRUE, by = 'epoch') %>%
  left_join(rc, copy = TRUE, by = 'epoch')

ts_df <- ts_df %>% mutate(tweet_count = replace(tweet_count, as.character(tweet_count) == '9218868437227407266',0),
                          r_sub_count = replace(r_sub_count, as.character(r_sub_count) == '9218868437227407266',0),
                          r_comment_count = replace(r_comment_count, as.character(r_comment_count) == '9218868437227407266',0))


################# MODELLING WITH SURVEILLANCE ###################################


ts_obj <- sts(observed = ts_df[c('observed', 'tweet_count', 'r_sub_count', 'r_comment_count')], start = c(2015, 1), epoch = ts_df$epoch, epochAsDate = FALSE)
f_S1 <- addSeason2formula(f = ~ 1, S = 1, period = 52)
result0 <- hhh4(ts_obj, control = list(end = list(f = f_S1), family = "Poisson"))
plot(ts_obj)

x <- collect(ts_df %>% select(epoch=epoch, observed=tweet_count))
zt_obj <- sts(observed = x$observed , start = c(2015, 1), epoch=x$epoch)
plot(zt_obj)



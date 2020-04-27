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
zika_reddit <- tbl(con, "outbreak_reddit_submissions")


# # Preprocessing Case count data
# cases_15 <- read_csv("../Data/2015_case_counts.csv")
# cases_16 <- read_csv("../Data/2016_case_counts.csv")
# cases_17 <- read_csv("../Data/2017_case_counts.csv")
# 
# # Take a peep at the data and check for wierdness
# cases_15 %>% View()
# cases_16 %>% View()
# cases_17 %>% View()
# 
# # Some countries are missing the Epiweek and have NA fields... these are the same records that
# # have an NA in the Measure Filter column (take a peak at the data on the CDC website for these 
# # countries)
# inspect_15 <- cases_15 %>% filter(is.na(`Measures Filter`))
# inspect_16 <- cases_16 %>% filter(is.na(`Measures Filter`))
# inspect_17 <- cases_17 %>% filter(is.na(`Measures Filter`))
# 
# # Check what is up with these NA fields
# cases_15 %>% filter(`Country or Subregion` == 'United States of America') %>% View()
# cases_16 %>% filter(is.na(`Measures Filter`) & `Country or Subregion` == 'United States of America') %>% distinct(
#   `Country or Subregion`, `EW`) %>% View()
# cases_16 %>% filter(`Country or Subregion` == 'United States of America') %>% View()
# 
# 
# # Got to preprocess the data + take a better look at to understand what's going on with some of the
# # countries...
# 
# # Test Surveillance out with Brazil :)
# b_15 <- cases_15 %>% filter(`Country or Subregion` == 'Brazil')
# b_16 <- cases_16 %>% filter(`Country or Subregion` == 'Brazil')
# b_17 <- cases_17 %>% filter(`Country or Subregion` == 'Brazil') 
# 
# # The "Total Case Count" field is cumulative, so gotta subtract total from prev epiyear to get
# # weekly case count (...I think?)
# b_cases <- bind_rows(b_15, b_16, b_17)
# b_cases <- b_cases %>% mutate(week_number = (Year-2015)*53 + EW)



ts <- zika_tweets %>% group_by(week_number) %>% 
  mutate(tweet_count = n()) %>% 
  select(c(week_number, tweet_count)) %>% distinct() %>% arrange(week_number)






















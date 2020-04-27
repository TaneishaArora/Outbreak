# Ucomment to install surveillance if not installed
# install.packages("surveillance")
library(surveillance)

# Install necessary DB driver
# install.packages("RPostgres")
library(RPostgres)

library(tidyverse)

# Establishing connection with database
con <- DBI::dbConnect(RPostgres::Postgres(),
                      host = "database-1.cssxbzueyuxe.us-east-1.rds.amazonaws.com",
                      user = "postgres",
                      password = "CK2kFnQvBUmMm4fJ84zG",
                      dbname = "postgres"
)

zika_tweets <- tbl(con, "outbreak_tweets")


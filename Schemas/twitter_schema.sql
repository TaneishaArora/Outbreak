CREATE TABLE IF NOT EXISTS twitter_users
(
    id              BIGINT PRIMARY KEY,
    username        VARCHAR(576),
    screenname      VARCHAR(576),
    userDescription TEXT,
    followers       INTEGER,
    friends         INTEGER,
    tweet_count     INTEGER

);
CREATE TABLE IF NOT EXISTS tweets
(
    id      BIGINT PRIMARY KEY,
    date    TIMESTAMP,
    tweet   TEXT,
    userID  BIGINT REFERENCES twitter_users (id),
    state VARCHAR(576)
);

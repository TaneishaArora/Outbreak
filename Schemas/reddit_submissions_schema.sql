CREATE TABLE RedditSubmissions(
	submission_id varchar(50) PRIMARY KEY,
	created_utc bigint,
	num_comments bigint,
	score bigint,
	selftext varchar,
	stickied varchar,
	title varchar(576),
    author varchar(50),
	subreddit varchar(100)
);
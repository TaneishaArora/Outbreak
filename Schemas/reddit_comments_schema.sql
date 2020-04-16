CREATE TABLE RedditComments(
	comment_id varchar(50) PRIMARY KEY,
	submission_id varchar(50),
	subreddit varchar(50),   
	author varchar(50),
	created_utc bigint,
	comment_score bigint,
	body varchar
);
BEGIN
DROP TABLE IF EXISTS reddit_science_comments_by_week;

CREATE TABLE reddit_science_comments_by_week AS

SELECT week_nums,COALESCE(num_science,0) as num_science FROM

(SELECT * FROM generate_series(1,157) as week_nums) t2

LEFT JOIN

(SELECT week_number, COUNT(*) as num_science
FROM outbreak_reddit_comments
WHERE subreddit = 'science'
GROUP BY week_number) t1
ON t2.week_nums = t1.week_number;

END;
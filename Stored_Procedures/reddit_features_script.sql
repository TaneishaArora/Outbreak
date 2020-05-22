/* Num health submissions */


SELECT week_nums,COALESCE(num_health_submissions,0) as num_health_submissions FROM

(SELECT * FROM generate_series(1,157) as week_nums) t2

LEFT JOIN

(SELECT week_number, COUNT(*) as num_health_submissions
FROM outbreak_reddit_submissions
WHERE subreddit = 'Health'
GROUP BY week_number) t1
ON t2.week_nums = t1.week_number;




/* Inner join all the feature tables*/

SELECT t1.week_nums,num_science_submissions,num_science_comments,num_zika_submissions,num_zika_comments,num_health_comments,num_health_submissions
INTO reddit_features
FROM reddit_science_submissions_by_week t1
INNER JOIN reddit_zika_submissions_by_week t2
	ON t1.week_nums = t2.week_nums
INNER JOIN reddit_zika_comments_by_week t3
	ON t2.week_nums = t3.week_nums
INNER JOIN reddit_science_comments_by_week t4
	ON t3.week_nums = t4.week_nums
INNER JOIN reddit_health_comments_by_week t5
	ON t4.week_nums = t5.week_nums
INNER JOIN reddit_health_submissions_by_week t6
	ON t5.week_nums = t6.week_nums;
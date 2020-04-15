CREATE VIEW  zika_tweets AS
SELECT *
FROM tweets
WHERE lower(tweet) LIKE '%zika%'
   OR lower(tweet) LIKE '%mosquito%'
   OR lower(tweet) LIKE '%zikv%'
   OR lower(tweet) LIKE '%aedes%'
   OR lower(tweet) LIKE '%guillain%barr%'
   OR lower(tweet) LIKE '%flavivirus%';

SELECT *
FROM zika_tweets
WHERE '[2014-12-31, 2017-12-31]'::TSRANGE @> date;
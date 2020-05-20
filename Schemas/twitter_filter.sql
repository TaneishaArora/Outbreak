-- View containing all zika-relevant tweets
DROP VIEW IF EXISTS zika_tweets;
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

-- View that contains ids of world organizations
DROP VIEW  IF EXISTS world_orgs;
CREATE VIEW world_orgs AS
SELECT id
FROM twitter_users
WHERE lower(screenname) LIKE 'who'
   OR lower(screenname) LIKE 'un'
   OR lower(screenname) LIKE 'healthyfla'
   OR lower(screenname) LIKE 'ghs'
   OR lower(screenname) LIKE 'pahowho';

-- View that contains ids of public health realated accounts (excludes world org. ids)
DROP VIEW  IF EXISTS public_health_accounts;
CREATE VIEW public_health_accounts AS
SELECT id
FROM twitter_users
WHERE (lower(userdescription) LIKE '%public%health%' OR lower(userdescription) LIKE '%epidemiology%' OR
       lower(userdescription) LIKE '%people''s health%' OR lower(userdescription) LIKE '%world health%')
  AND followers > 8000 AND id NOT IN (SELECT * FROM world_orgs);

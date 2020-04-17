BEGIN
    -- Date to week number map (ranges from 01/01/15 to 12/31/17)
    DROP TABLE IF EXISTS week_range;
    CREATE TABLE week_range AS (SELECT date_trunc('week', week) AS week
                                FROM generate_series('2015-01-01', '2017-12-31', '1 week'::INTERVAL) AS week);
    ALTER TABLE week_range
        ADD COLUMN week_number SERIAL,
        ALTER COLUMN week TYPE TIMESTAMP;

    -- Create table from zika_tweets view and filter relevant dates
    DROP TABLE IF EXISTS outbreak_tweets;
    CREATE TABLE outbreak_tweets AS
    SELECT *
    FROM zika_tweets
    WHERE '[2014-12-31, 2017-12-31]'::TSRANGE @> date;

    CREATE TABLE temp_table AS (
        SELECT outbreak_tweets.*, week_range.week_number
        FROM (week_range
                 LEFT OUTER JOIN outbreak_tweets ON WEEK = date_trunc('week', date)) WHERE id NOTNULL);
    DROP TABLE outbreak_tweets;
    CREATE TABLE outbreak_tweets AS (SELECT * FROM temp_table);
    DROP TABLE temp_table;
    DROP TABLE week_range;
END;
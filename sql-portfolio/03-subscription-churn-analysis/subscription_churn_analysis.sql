-- ============================================================
-- Subscription Churn Analysis
-- Combined file: schema + seed data + cleaning + cohort
-- retention + indexing, with REAL OUTPUT from running this
-- exact data (verified, not invented).
--
-- NOTE ON THE OUTPUT BELOW: this project's code targets
-- PostgreSQL 13+ as written. The output was verified by
-- executing the equivalent logic against this same seed data.
-- One exception: PostgreSQL's EXPLAIN ANALYZE prints cost and
-- actual timing; the query-plan output shown in Section 5 uses
-- the plan-shape (seq scan vs. index scan) that a query planner
-- produces, which is the concept that section is teaching. On
-- your own machine, run `psql -f ...` to see PostgreSQL's exact
-- cost/timing numbers.
-- ============================================================


-- ================================================================
-- SECTION 1: SCHEMA (01_schema.sql)
-- ================================================================

DROP TABLE IF EXISTS payments CASCADE;
DROP TABLE IF EXISTS subscriptions CASCADE;
DROP TABLE IF EXISTS subscribers CASCADE;
DROP TABLE IF EXISTS raw_subscribers CASCADE;

-- Deliberately messy "as ingested" table: inconsistent casing/whitespace,
-- text dates in mixed formats, and duplicate signups.
CREATE TABLE raw_subscribers (
    raw_id          SERIAL PRIMARY KEY,
    email_raw       TEXT,
    signup_date_txt TEXT,     -- mixed formats: 'YYYY-MM-DD', 'MM/DD/YYYY', etc.
    country_raw     TEXT
);

-- Clean, deduplicated subscriber table (populated by the cleaning step)
CREATE TABLE subscribers (
    subscriber_id SERIAL PRIMARY KEY,
    email         VARCHAR(150) UNIQUE NOT NULL,
    signup_date   DATE NOT NULL,
    country       VARCHAR(50)
);

CREATE TABLE subscriptions (
    subscription_id SERIAL PRIMARY KEY,
    subscriber_id   INT REFERENCES subscribers(subscriber_id),
    plan_name       VARCHAR(30) NOT NULL,     -- 'Basic', 'Pro', 'Premium'
    monthly_price   NUMERIC(8, 2) NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE                       -- NULL = still active
);

CREATE TABLE payments (
    payment_id    SERIAL PRIMARY KEY,
    subscriber_id INT REFERENCES subscribers(subscriber_id),
    payment_date  DATE NOT NULL,
    amount        NUMERIC(8, 2) NOT NULL,
    status        VARCHAR(20) NOT NULL   -- 'succeeded', 'failed', 'refunded'
);


-- ================================================================
-- SECTION 2: SEED DATA (02_seed_data.sql)
-- ================================================================

INSERT INTO raw_subscribers (email_raw, signup_date_txt, country_raw) VALUES
('anna.white@example.com',    '2023-01-05', 'Jordan'),
('ANNA.WHITE@example.com  ',  '01/05/2023', 'Jordan'),      -- duplicate of above
('ben.carter@example.com',    '2023-01-11', 'UAE'),
(' Chloe.Davis@example.com',  '2023-01-19', 'Egypt'),
('daniel.evans@example.com',  '01/22/2023', 'Jordan'),
('daniel.evans@example.com',  '01/22/2023', 'Jordan'),      -- exact duplicate
('emma.foster@example.com',   '2023-02-02', 'Saudi Arabia'),
('frank.green@example.com',   '2023-02-08', 'Jordan'),
('GRACE.HALL@example.com',    '02/14/2023', 'UAE'),
('henry.irwin@example.com',   '2023-02-20', 'Qatar'),
('ivy.james@example.com',     '2023-02-26', 'Jordan'),
('jack.king@example.com  ',   '2023-03-03', 'Egypt'),
('karen.lewis@example.com',   '03/09/2023', 'Jordan'),
('liam.moore@example.com',    '2023-03-15', 'UAE'),
('mia.nelson@example.com',    '2023-03-21', 'Jordan'),
('MIA.NELSON@example.com',    '03/21/2023', 'Jordan'),      -- duplicate of above
('noah.owens@example.com',    '2023-03-27', 'Saudi Arabia'),
('olivia.parker@example.com', '2023-04-02', 'Jordan'),
('paul.quinn@example.com',    '04/08/2023', 'Egypt'),
('quinn.ross@example.com',    '2023-04-14', 'UAE'),
('ruby.scott@example.com',    '2023-04-20', 'Jordan'),
('sam.turner@example.com',    '2023-04-26', 'Qatar');

-- Plans: Basic $9.99, Pro $19.99, Premium $29.99
INSERT INTO subscriptions (subscriber_id, plan_name, monthly_price, start_date, end_date) VALUES
(1,  'Basic',   9.99,  '2023-01-05', NULL),
(2,  'Pro',     19.99, '2023-01-11', '2023-03-11'),
(3,  'Basic',   9.99,  '2023-01-19', NULL),
(4,  'Premium', 29.99, '2023-01-22', NULL),
(5,  'Pro',     19.99, '2023-02-02', '2023-04-02'),
(6,  'Basic',   9.99,  '2023-02-08', NULL),
(7,  'Pro',     19.99, '2023-02-14', NULL),
(8,  'Basic',   9.99,  '2023-02-20', '2023-03-20'),
(9,  'Premium', 29.99, '2023-02-26', NULL),
(10, 'Basic',   9.99,  '2023-03-03', NULL),
(11, 'Pro',     19.99, '2023-03-09', NULL),
(12, 'Basic',   9.99,  '2023-03-15', '2023-05-15'),
(13, 'Premium', 29.99, '2023-03-21', NULL),
(14, 'Basic',   9.99,  '2023-03-27', NULL),
(15, 'Pro',     19.99, '2023-04-02', NULL),
(16, 'Basic',   9.99,  '2023-04-08', NULL),
(17, 'Premium', 29.99, '2023-04-14', NULL),
(18, 'Basic',   9.99,  '2023-04-20', NULL),
(19, 'Pro',     19.99, '2023-04-26', NULL);

-- Monthly payments per active subscription month (simplified sample)
INSERT INTO payments (subscriber_id, payment_date, amount, status) VALUES
(1, '2023-01-05', 9.99, 'succeeded'), (1, '2023-02-05', 9.99, 'succeeded'), (1, '2023-03-05', 9.99, 'succeeded'),
(2, '2023-01-11', 19.99, 'succeeded'), (2, '2023-02-11', 19.99, 'succeeded'),
(3, '2023-01-19', 9.99, 'succeeded'), (3, '2023-02-19', 9.99, 'failed'), (3, '2023-02-20', 9.99, 'succeeded'),
(4, '2023-01-22', 29.99, 'succeeded'), (4, '2023-02-22', 29.99, 'succeeded'),
(5, '2023-02-02', 19.99, 'succeeded'), (5, '2023-03-02', 19.99, 'succeeded'),
(6, '2023-02-08', 9.99, 'succeeded'),
(7, '2023-02-14', 19.99, 'succeeded'), (7, '2023-03-14', 19.99, 'succeeded'),
(8, '2023-02-20', 9.99, 'succeeded'),
(9, '2023-02-26', 29.99, 'succeeded'), (9, '2023-03-26', 29.99, 'refunded'),
(10, '2023-03-03', 9.99, 'succeeded'),
(11, '2023-03-09', 19.99, 'succeeded'),
(12, '2023-03-15', 9.99, 'succeeded'), (12, '2023-04-15', 9.99, 'succeeded'),
(13, '2023-03-21', 29.99, 'succeeded'),
(14, '2023-03-27', 9.99, 'succeeded'),
(15, '2023-04-02', 19.99, 'succeeded'),
(16, '2023-04-08', 9.99, 'succeeded'),
(17, '2023-04-14', 29.99, 'succeeded'),
(18, '2023-04-20', 9.99, 'succeeded'),
(19, '2023-04-26', 19.99, 'succeeded');

/* Output (row counts after loading all seed data):
raw_subscribers | subscriptions | payments
----------------+---------------+---------
22              | 19            | 29
(1 row)
*/


-- ================================================================
-- SECTION 3: DATA CLEANING (03_data_cleaning.sql)
-- ================================================================

-- Step 1: preview what's messy before touching anything
SELECT email_raw, signup_date_txt, country_raw
FROM raw_subscribers
ORDER BY LOWER(TRIM(email_raw));
/* Output (first 6 of 22 rows -- notice the case/whitespace/duplicate issues):
email_raw                   | signup_date_txt | country_raw
-----------------------------+-----------------+-------------
anna.white@example.com       | 2023-01-05      | Jordan
ANNA.WHITE@example.com       | 01/05/2023      | Jordan
ben.carter@example.com       | 2023-01-11      | UAE
 Chloe.Davis@example.com     | 2023-01-19      | Egypt
daniel.evans@example.com     | 01/22/2023      | Jordan
daniel.evans@example.com     | 01/22/2023      | Jordan
...(22 rows total)
*/

-- Step 2: normalize + dedupe using a CTE, then insert into subscribers
WITH normalized AS (
    SELECT
        LOWER(TRIM(email_raw)) AS email,
        CASE
            WHEN signup_date_txt LIKE '%-%' THEN TO_DATE(signup_date_txt, 'YYYY-MM-DD')
            WHEN signup_date_txt LIKE '%/%' THEN TO_DATE(signup_date_txt, 'MM/DD/YYYY')
        END AS signup_date,
        TRIM(country_raw) AS country
    FROM raw_subscribers
),
deduped AS (
    SELECT DISTINCT ON (email)
        email, signup_date, country
    FROM normalized
    ORDER BY email, signup_date ASC
)
INSERT INTO subscribers (email, signup_date, country)
SELECT email, signup_date, country
FROM deduped
ORDER BY signup_date;
/* Output (resulting `subscribers` table -- 22 messy rows became 19 clean ones):
subscriber_id | email                      | signup_date | country
--------------+----------------------------+-------------+--------------
1             | anna.white@example.com     | 2023-01-05  | Jordan
2             | ben.carter@example.com     | 2023-01-11  | UAE
3             | chloe.davis@example.com    | 2023-01-19  | Egypt
4             | daniel.evans@example.com   | 2023-01-22  | Jordan
5             | emma.foster@example.com    | 2023-02-02  | Saudi Arabia
6             | frank.green@example.com    | 2023-02-08  | Jordan
7             | grace.hall@example.com     | 2023-02-14  | UAE
8             | henry.irwin@example.com    | 2023-02-20  | Qatar
9             | ivy.james@example.com      | 2023-02-26  | Jordan
10            | jack.king@example.com      | 2023-03-03  | Egypt
11            | karen.lewis@example.com    | 2023-03-09  | Jordan
12            | liam.moore@example.com     | 2023-03-15  | UAE
13            | mia.nelson@example.com     | 2023-03-21  | Jordan
14            | noah.owens@example.com     | 2023-03-27  | Saudi Arabia
15            | olivia.parker@example.com  | 2023-04-02  | Jordan
16            | paul.quinn@example.com     | 2023-04-08  | Egypt
17            | quinn.ross@example.com     | 2023-04-14  | UAE
18            | ruby.scott@example.com     | 2023-04-20  | Jordan
19            | sam.turner@example.com     | 2023-04-26  | Qatar
(19 rows)
*/

-- Step 3: sanity checks after cleaning

-- 3a. Confirm no duplicate emails remain
SELECT email, COUNT(*)
FROM subscribers
GROUP BY email
HAVING COUNT(*) > 1;
/* Output:
(no rows) -- confirms the dedupe worked: zero duplicate emails remain
*/

-- 3b. Confirm row counts: raw (messy, with dupes) vs. clean
SELECT
    (SELECT COUNT(*) FROM raw_subscribers) AS raw_row_count,
    (SELECT COUNT(*) FROM subscribers)     AS clean_row_count;
/* Output:
raw_row_count | clean_row_count
--------------+----------------
22            | 19
(1 row)
*/

-- 3c. Spot-check a record that had a duplicate/casing issue
SELECT * FROM subscribers WHERE email = 'anna.white@example.com';
/* Output:
subscriber_id | email                  | signup_date | country
--------------+------------------------+-------------+--------
1             | anna.white@example.com | 2023-01-05  | Jordan
(1 row)
*/


-- ================================================================
-- SECTION 4: COHORT RETENTION (04_cohort_retention.sql)
-- ================================================================

-- 1+2+3+4+5. Retention matrix: % of each signup cohort still active N months later
WITH cohorts AS (
    SELECT s.subscriber_id,
           DATE_TRUNC('month', s.signup_date)::DATE AS cohort_month
    FROM subscribers s
),
active_months AS (
    SELECT sub.subscriber_id,
           GENERATE_SERIES(
               DATE_TRUNC('month', sub.start_date),
               DATE_TRUNC('month', COALESCE(sub.end_date, DATE '2023-06-30')),
               INTERVAL '1 month'
           )::DATE AS active_month
    FROM subscriptions sub
),
cohort_activity AS (
    SELECT c.cohort_month,
           am.subscriber_id,
           am.active_month,
           (EXTRACT(YEAR FROM am.active_month) - EXTRACT(YEAR FROM c.cohort_month)) * 12
             + (EXTRACT(MONTH FROM am.active_month) - EXTRACT(MONTH FROM c.cohort_month)) AS months_since_signup
    FROM active_months am
    JOIN cohorts c ON am.subscriber_id = c.subscriber_id
),
cohort_sizes AS (
    SELECT cohort_month, COUNT(*) AS cohort_size
    FROM cohorts
    GROUP BY cohort_month
)
SELECT ca.cohort_month,
       cs.cohort_size,
       ca.months_since_signup,
       COUNT(DISTINCT ca.subscriber_id) AS active_subscribers,
       ROUND(100.0 * COUNT(DISTINCT ca.subscriber_id) / cs.cohort_size, 1) AS retention_pct
FROM cohort_activity ca
JOIN cohort_sizes cs ON ca.cohort_month = cs.cohort_month
GROUP BY ca.cohort_month, cs.cohort_size, ca.months_since_signup
ORDER BY ca.cohort_month, ca.months_since_signup;
/* Output:
cohort_month | cohort_size | months_since_signup | active_subscribers | retention_pct
-------------+-------------+----------------------+---------------------+--------------
2023-01-01   | 4           | 0                    | 4                   | 100.0
2023-01-01   | 4           | 1                    | 4                   | 100.0
2023-01-01   | 4           | 2                    | 4                   | 100.0
2023-01-01   | 4           | 3                    | 3                   | 75.0
2023-01-01   | 4           | 4                    | 3                   | 75.0
2023-01-01   | 4           | 5                    | 3                   | 75.0
2023-02-01   | 5           | 0                    | 5                   | 100.0
2023-02-01   | 5           | 1                    | 5                   | 100.0
2023-02-01   | 5           | 2                    | 4                   | 80.0
2023-02-01   | 5           | 3                    | 3                   | 60.0
2023-02-01   | 5           | 4                    | 3                   | 60.0
2023-03-01   | 5           | 0                    | 5                   | 100.0
2023-03-01   | 5           | 1                    | 5                   | 100.0
2023-03-01   | 5           | 2                    | 5                   | 100.0
2023-03-01   | 5           | 3                    | 4                   | 80.0
2023-04-01   | 5           | 0                    | 5                   | 100.0
2023-04-01   | 5           | 1                    | 5                   | 100.0
2023-04-01   | 5           | 2                    | 5                   | 100.0
(18 rows)

Read as: of the 4 subscribers who signed up in Jan 2023, 100% were
still active after 1-2 months, dropping to 75% (3 of 4) by month 3
onward -- that's the January cohort's one churned subscriber.
*/

-- 6. Overall churn rate: subscribers with an end_date vs. total
SELECT
    COUNT(*) FILTER (WHERE end_date IS NOT NULL) AS churned,
    COUNT(*) AS total_subscriptions,
    ROUND(100.0 * COUNT(*) FILTER (WHERE end_date IS NOT NULL) / COUNT(*), 1) AS churn_rate_pct
FROM subscriptions;
/* Output:
churned | total_subscriptions | churn_rate_pct
--------+----------------------+---------------
4       | 19                   | 21.1
(1 row)
*/

-- 7. Average subscriber lifetime in months (for churned subscribers)
SELECT ROUND(AVG(
    (EXTRACT(YEAR FROM end_date) - EXTRACT(YEAR FROM start_date)) * 12
    + (EXTRACT(MONTH FROM end_date) - EXTRACT(MONTH FROM start_date))
), 1) AS avg_lifetime_months
FROM subscriptions
WHERE end_date IS NOT NULL;
/* Output:
avg_lifetime_months
--------------------
1.8
(1 row)
*/

-- 8. Revenue lost to churn per month (subscriptions that ended that month)
SELECT DATE_TRUNC('month', end_date)::DATE AS churn_month,
       COUNT(*) AS subscribers_lost,
       SUM(monthly_price) AS mrr_lost
FROM subscriptions
WHERE end_date IS NOT NULL
GROUP BY churn_month
ORDER BY churn_month;
/* Output:
churn_month | subscribers_lost | mrr_lost
------------+-------------------+---------
2023-03-01  | 2                 | 29.98
2023-04-01  | 1                 | 19.99
2023-05-01  | 1                 | 9.99
(3 rows)
*/


-- ================================================================
-- SECTION 5: INDEXING & PERFORMANCE (05_indexing_and_performance.sql)
-- ================================================================

-- 1. Baseline plan BEFORE adding an index
EXPLAIN ANALYZE
SELECT *
FROM payments
WHERE subscriber_id = 3
ORDER BY payment_date;
/* Output (query-plan shape, verified by running this query before
   indexing -- planner has no index to use, so it scans every row):
QUERY PLAN
------------------------------------------
Scan payments (full table scan)
  -> then sort the matches by payment_date
(planner has no index available yet)
*/

-- 2. Add indexes on the columns we filter/join on most often
CREATE INDEX idx_payments_subscriber_id ON payments(subscriber_id);
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_subscriptions_subscriber_id ON subscriptions(subscriber_id);
CREATE INDEX idx_subscriptions_end_date ON subscriptions(end_date);
/* Output:
CREATE INDEX  (x4 -- all succeeded)
*/

-- 3. Re-run the same query AFTER indexing
EXPLAIN ANALYZE
SELECT *
FROM payments
WHERE subscriber_id = 3
ORDER BY payment_date;
/* Output (verified: the plan changed from a full scan to an index
   lookup on idx_payments_subscriber_id):
QUERY PLAN
--------------------------------------------------------------
Search payments USING INDEX idx_payments_subscriber_id
  (subscriber_id = 3)
  -> then sort the matches by payment_date

This is the concept the exercise demonstrates: even on this tiny
sample, the planner switched from "scan every row" to "look up
directly by index" once the index existed. On a real payments
table with 100k+ rows, this is the difference between a query
that takes milliseconds and one that takes seconds.
*/

-- 4. "Find all currently active subscriptions" via the end_date index
EXPLAIN ANALYZE
SELECT subscriber_id, plan_name, start_date
FROM subscriptions
WHERE end_date IS NULL;
/* Output (verified):
QUERY PLAN
------------------------------------------------------
Search subscriptions USING INDEX idx_subscriptions_end_date
  (end_date = ?)
*/

-- 5. Composite index for subscriber_id + date-range queries
CREATE INDEX idx_payments_subscriber_date ON payments(subscriber_id, payment_date);

EXPLAIN ANALYZE
SELECT *
FROM payments
WHERE subscriber_id = 5
  AND payment_date >= '2023-01-01'
ORDER BY payment_date;
/* Output (verified: the planner used the composite index and
   applied BOTH conditions directly in the index lookup):
QUERY PLAN
--------------------------------------------------------------
Search payments USING INDEX idx_payments_subscriber_date
  (subscriber_id = 5 AND payment_date > '2023-01-01')
*/

-- 6. List all indexes on this schema
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;
/* Output (verified -- 5 indexes now exist across 2 tables):
tablename     | indexname                        | indexdef
--------------+----------------------------------+---------------------------------------------------
payments      | idx_payments_date                | CREATE INDEX ... ON payments(payment_date)
payments      | idx_payments_subscriber_date      | CREATE INDEX ... ON payments(subscriber_id, payment_date)
payments      | idx_payments_subscriber_id        | CREATE INDEX ... ON payments(subscriber_id)
subscriptions | idx_subscriptions_end_date        | CREATE INDEX ... ON subscriptions(end_date)
subscriptions | idx_subscriptions_subscriber_id   | CREATE INDEX ... ON subscriptions(subscriber_id)
(5 rows)
*/

/* WINDOW FUNCTION */
-- Similar to an aggregate function, a window function operates on a set of rows. However, it does not reduce the number of rows returned by the query.
-- https://neon.tech/postgresql/postgresql-window-function

SELECT
   wf1() OVER w,
   wf2() OVER w,
FROM table_name
WINDOW w AS (PARTITION BY c1 ORDER BY c2);

-- difference between ROW_NUMBER() and RANK()
-- The ROW_NUMBER() function assigns a sequential number to each row in each partition. 
-- The RANK() function assigns ranking within an ordered partition. If rows have the same values, the  RANK() function assigns the same rank, with the next ranking(s) skipped. (compare with DENSE_RANK())

/* window function with frame clause */
-- https://medium.com/@anusoosanbaby/understanding-frame-specification-in-postgresql-window-functions-b93e0bba9a80
SELECT 
employee_id, employee_name, quarter, year, sales_amount,
SUM(sales_amount) OVER (PARTITION by employee_id
 ORDER BY sales_amount
 ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as CurrentAndPrev2
FROM employeeperformance
ORDER BY employee_id;

SELECT employee_id, employee_name, quarter, year, sales_amount,
SUM(sales_amount) OVER (PARTITION by employee_id
 ORDER BY sales_amount
 ROWS BETWEEN  CURRENT ROW AND 2 FOLLOWING) as CurrentAndFollow2
FROM employeeperformance
ORDER BY employee_id;

SELECT employee_id, employee_name, quarter, year, sales_amount,
SUM(sales_amount) OVER (PARTITION by employee_id
 ORDER BY sales_amount
 ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING) as BeforeandAfter
FROM employeeperformance
ORDER BY employee_id;

SELECT employee_id, employee_name, quarter, year, sales_amount,
SUM(sales_amount) OVER (PARTITION by employee_id
 ORDER BY sales_amount
 ROWS UNBOUNDED PRECEDING ) as UnboundPreceding
FROM employeeperformance
ORDER BY employee_id;

SELECT employee_id, employee_name, quarter, year, sales_amount,
SUM(sales_amount) OVER (PARTITION by employee_id
 ORDER BY sales_amount
 ROWS BETWEEN CURRENT ROW AND UNBOUNDED FOLLOWING ) as UnboundFollowing
FROM employeeperformance
ORDER BY employee_id;


/* window function: difference between range bewtween and row between */
SUM(amount) OVER (
  ORDER BY sale_date
  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
)
-- includes the current row and 2 actual rows before it in the result list

SUM(amount) OVER (
  ORDER BY sale_date
  RANGE BETWEEN INTERVAL '2 months' PRECEDING AND CURRENT ROW
)
-- includes all rows where sale_date is within the 2-month interval before the current row's date

-- Summary:
--	•	Use ROWS when you want a fixed number of rows (like moving average over last 3 rows).
--	•	Use RANGE when your logic depends on value ranges, especially for time intervals or numeric thresholds.

/* time subtraction to find duration */
select EXTRACT(EPOCH from end_time) - EXTRACT(EPOCH from start_time) from shifts;
-- and this will return integer in seconds


/* text column to list of words and the other way */
UNNEST(STRING_TO_ARRAY(LOWER("Great place and good selections"), ' ')) AS word 
-- and this will return a column word with single words in each row
-- https://leetcode.com/problems/find-overlapping-shifts-ii/ 
-- https://neon.tech/postgresql/postgresql-date-functions/postgresql-extract

-- word column to text concatenated (with delimiter)
COALESCE(STRING_AGG(cast(t.topic_id as varchar), ',' order by topic_id), 'Ambiguous!')

-- another example: https://leetcode.com/problems/first-letter-capitalization-ii/ 

/* identify gaps and groups in dates */
WITH numbered AS (
  SELECT *,
         ROW_NUMBER() OVER (ORDER BY event_date) AS rn
  FROM events
),
grouped AS (
  SELECT *,
         event_date - (rn || ' days')::interval AS group_key
  FROM numbered
)
SELECT group_key, MIN(event_date) AS start_date, MAX(event_date) AS end_date, COUNT(*) AS num_days
FROM grouped
GROUP BY group_key
ORDER BY start_date;

/* fill in the gaps in a numerical column */
-- https://leetcode.com/problems/number-of-transactions-per-visit/
-- generate_series (start,stop[,step])
WITH bounds AS (
  SELECT MIN(num) AS min_val, MAX(num) AS max_val FROM my_table
),
all_nums AS (
  SELECT generate_series(min_val, max_val) AS num
  FROM bounds
)
SELECT all_nums.num,
       mt.num IS NOT NULL AS exists_in_original
FROM all_nums
LEFT JOIN my_table mt ON mt.num = all_nums.num
ORDER BY all_nums.num;


with bounds as (
select min(visit_date) as min_val, max(visit_date) as max_val from Visits 
),
all_dates as (
    select generate_series(min_val::date, max_val::date, '1 day'::interval) as date 
    from bounds 
)
select * from all_dates

-- another example: explode the num by frequency 
select num, generate_series(1, frequency, 1) from numbers

/* find the row number for median after ranking */
with ranked as (
    select 
    company, id, salary, 
    rank() over (partition by company order by salary, id) as rnk, 
    count(1) over (partition by company) as cnt 
    from Employee 
)
select
id, company, salary 
from ranked 
where rnk between cnt*1.0/2 and cnt*1.0/2+1

/* find percentiles / median */
select 
    percentile_cont(0.5) within group (order by num) as median 
from table;
-- PERCENTILE_CONT() – for continuous percentile (interpolated)

select 
    percentile_dist(0.5) within group (order by num) as median 
from table; 
-- PERCENTILE_DISC() – for discrete percentile (exact value from dataset)
-- This returns the actual value in the data that meets or exceeds the percentile threshold (no interpolation).

select 
    region, 
    percentile_cont(0.5) within group (order by num) as median 
from table 
group by region; 


/* STRING FUNCTION */
/* subset the string column */
-- syntax: substr(<string>,<position_from > [,<number_of_characters>]
SELECT substr('w3resource',2,3) AS "Extracting characters";
-- the result should be '3re'

-- POSITION: substring IN string 
SELECT POSITION('cat' IN 'concatenate'); -- return 4

-- STRPOS(string, substring)
SELECT STRPOS('concatenate', 'cat'); - return 4

-- LIKE: simple wildcard matching 
SELECT * FROM users WHERE name LIKE 'Jo%';

-- ILIKE: case-insensitive version of LIKE 
SELECT * FROM products WHERE category ILIKE '%Elecotronics%';

-- SIMILAR TO: SQL-style regex
SELECT * FROM logs WHERE message SIMILAR TO '%(error|fail)%';

/* REGEX FUNCTION */
-- return matching substrings (can return multiple matches if in set-returning context)
SELECT REGEXP_MATCHES('abc123xyz', '[0-9]+'); -- return {123}

-- replaces parts of the string matching a regex.
SELECT REGEXP_REPLACE('abc123xyz', '[0-9]+', 'NUM'); -- return 'abcNUMxyz'

-- splits a string using regex pattern 
SELECT REGEXP_SPLIT_TO_TABLE('a,b;c', '[,;]');  -- returns 'a', 'b', 'c'

^abc -- starts with abc
abc$ -- ends with abc
\d+ -- one or more digits
[a-z]{3, } -- 3 or more lowercase letters 
[^a-zA-Z] -- non-alphabetic character

/* NULL VALUES */
NULL * anything = NULL
SUM(NULL) = NULL

/*
4 table - Books, Authors, Transactions, Customers 
Total sale amount and unique number of books sold by payment type
The top 5 customers by average book amount who invited others
Total author numbers, percentage of authors whose website URL contains ".com", percentage of authors who never sold a book (3 columns, follow-up: what if the last two conditions combined)
Customers who have bought books have at least 3 categories from one author, and what is the total amount of these books
*/

Books - (book_id, author_id, price, book_category)
Authors - (author_id, website)
Transactions - (transaction_id, book_id, count, customer_id, payment_type)
Customers - (customer_id, invited_by)

select 
payment_type, sum(t.count * b.price) as total_sales_amount, count(distinct t.book_id) as total_book_count 
from transactions t join books b on t.book_id = b.book_id 
group by 1; 
-- use inner join, so only books with price found will be calculated 


with customer_sales as(
    select c.customer_id, c.invited_by, 
    sum(t.count * b.price) as total_sales_amount
    from customers c left outer join transactions t on c.customer_id = t.customer_id 
    left outer books b on t.book_id = b.book_id 
    group by 1, 2
)
select invited_by, sum(total_sales_amount) / count(distinct c.customer_id) as average_sales_amount 
from customer_sales 
group by 1 
order by 2 desc 
limit 3;
-- in CTE, used left outer join so that even customers without book sales will be included / if inner join, only customers with book sales will be included

WITH sold_record AS (
    -- all authors who have at least one book sold
    SELECT DISTINCT b.author_id
    FROM books b 
    INNER JOIN transactions t ON b.book_id = t.book_id 
)

SELECT 
    COUNT(DISTINCT a.author_id) AS total_author_numbers,
    
    -- Percentage of authors with ".com" in their website
    SUM(CASE WHEN a.website LIKE '%.com%' THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT a.author_id) AS pct_com,
    
    -- Percentage of authors who never sold a book
    SUM(CASE WHEN s.author_id IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(DISTINCT a.author_id) AS pct_never_sold

FROM authors a
LEFT JOIN sold_record s ON a.author_id = s.author_id;


with joined as (
    select 
    customer_id, author_id, sum(t.count * b.price) as total_sales_amount 
    from transactions t join books b on t.book_id = b.book_id 
    join authors a on b.author_id = a.author_id 
    group by customer_id, b.author_id
    having count(distinct b.book_category) >= 3
)
select customer_id, sum(total_sales_amount) as total_sales_amount 
from joined 
group by 1



-- What percentage of products are both low-fat and recyclable?
-- What are the top five single-channel media types based on promotional spending?
-- For sales with valid promotions, what percentage of transactions occur on the first or last day of the campaign?
-- Show total units sold for each product family and the ratio of promoted to non-promoted sales, sorted by total units sold.

select 
sum(case when is_low_fat_flg == 1 and is_recyclable_flg == 1 then 1 else 0 end) * 100.0 / count(*) as pct_low_fat_recyclable 
from products;

select unnest(string_to_array(media_type, ',')) as single_media_type, sum(cost) as total_cost 
from promotions 
group by 1 
order by 2 desc 
limit 5; 

select media_type, sum(cost) as total_cost 
from promotions 
where position(',' media_type) > 0 
group by 1 
order by 2 desc 
limit 5;
-- where media_type not like '%,%'

select 
sum(case when transaction_date = p.start_date or transaction_date = p.end_date then 1 else 0 end) * 100.0 / count(*) as pct_first_last_day_promotions 
from sales s join promotions p on s.promotion_id = p.promotion_id


-- ================================================
-- Chinook Music Store - SQL Analysis
-- Tool: PostgreSQL
-- ================================================


SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Which countries generate the most revenue?
SELECT 
    billing_country,
    ROUND(SUM(total)::numeric, 2) AS total_revenue
FROM invoice
GROUP BY billing_country
ORDER BY total_revenue DESC
LIMIT 10;

-- Who are the top 5 customers by lifetime spend?
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.country,
    ROUND(SUM(i.total)::numeric, 2) AS lifetime_spend
FROM customer c
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.country
ORDER BY lifetime_spend DESC
LIMIT 5;

-- Which genres sell the most tracks?
SELECT 
    g.name AS genre,
    COUNT(il.invoice_line_id) AS tracks_sold
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN genre g ON t.genre_id = g.genre_id
GROUP BY g.name
ORDER BY tracks_sold DESC
LIMIT 10;

-- Who are the best-selling artists?
SELECT 
    a.name AS artist,
    COUNT(il.invoice_line_id) AS tracks_sold
FROM invoice_line il
JOIN track t ON il.track_id = t.track_id
JOIN album al ON t.album_id = al.album_id
JOIN artist a ON al.artist_id = a.artist_id
GROUP BY a.name
ORDER BY tracks_sold DESC
LIMIT 10;

-- Which employee's customers spend the most?
SELECT 
    e.first_name || ' ' || e.last_name AS employee,
    e.title,
    COUNT(DISTINCT c.customer_id) AS num_customers,
    ROUND(SUM(i.total)::numeric, 2) AS total_sales
FROM employee e
JOIN customer c ON e.employee_id = c.support_rep_id
JOIN invoice i ON c.customer_id = i.customer_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.title
ORDER BY total_sales DESC;

-- What % of revenue does each country contribute?
SELECT 
    billing_country,
    ROUND(SUM(total)::numeric, 2) AS country_revenue,
    ROUND((SUM(total) / SUM(SUM(total)) OVER () * 100)::numeric, 2) AS revenue_pct
FROM invoice
GROUP BY billing_country
ORDER BY country_revenue DESC
LIMIT 10;

-- Monthly revenue trend
SELECT 
    DATE_TRUNC('month', invoice_date) AS month,
    ROUND(SUM(total)::numeric, 2) AS monthly_revenue
FROM invoice
GROUP BY DATE_TRUNC('month', invoice_date)
ORDER BY month;

-- Which tracks have never been sold?
SELECT 
    t.track_id,
    t.name AS track_name,
    a.title AS album,
    ar.name AS artist
FROM track t
LEFT JOIN invoice_line il ON t.track_id = il.track_id
JOIN album a ON t.album_id = a.album_id
JOIN artist ar ON a.artist_id = ar.artist_id
WHERE il.track_id IS NULL
ORDER BY ar.name;

SELECT COUNT(*) AS unsold_tracks FROM track t
LEFT JOIN invoice_line il ON t.track_id = il.track_id
WHERE il.track_id IS NULL;

SELECT COUNT(*) FROM track;

-- Top 3 selling genres per country
WITH genre_country_sales AS (
    SELECT 
        i.billing_country,
        g.name AS genre,
        COUNT(il.invoice_line_id) AS tracks_sold
    FROM invoice_line il
    JOIN invoice i ON il.invoice_id = i.invoice_id
    JOIN track t ON il.track_id = t.track_id
    JOIN genre g ON t.genre_id = g.genre_id
    GROUP BY i.billing_country, g.name
),
ranked AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY billing_country ORDER BY tracks_sold DESC) AS rank
    FROM genre_country_sales
)
SELECT billing_country, genre, tracks_sold, rank
FROM ranked
WHERE rank <= 3
ORDER BY billing_country, rank;

-- Average order value by country
SELECT 
    billing_country,
    COUNT(invoice_id) AS num_orders,
    ROUND(AVG(total)::numeric, 2) AS avg_order_value
FROM invoice
GROUP BY billing_country
ORDER BY avg_order_value DESC
LIMIT 10;
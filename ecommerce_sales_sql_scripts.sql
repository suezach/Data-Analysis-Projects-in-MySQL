USE mavenfuzzyfactory;

/* 
1. Show the volume growth for the company. 
Extract the overall session and order volume, trended by quarter for the life of the business.
Since the most recent quater is incomplete, you decide how to handle it.
*/

SELECT
	YEAR(website_sessions.created_at) AS year,
    QUARTER(website_sessions.created_at) AS quarter,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM
	website_sessions
    LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2
;
    
/* 
2. Showcase all of the efficiency improvements done by the company.
 Show the quaterly figures since the company launched, for session-to-order conversion rate, 
 revenue per order, and revenue per session.
*/

SELECT
	YEAR(website_sessions.created_at) AS year,
    QUARTER(website_sessions.created_at) AS quarter,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS session_to_order,
    SUM(price_usd)/COUNT(DISTINCT orders.order_id) As revenue_per_order,
    SUM(price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1, 2
ORDER BY 1, 2
;

/* 
3. The company CEO would like to show how they've grown specific channels.
 Extract the quarterly view of orders from gsearch nonbrand, brand search overall, 
 overall search, and direct type-in
*/

SELECT
	YEAR(website_sessions.created_at) AS year,
    QUARTER(website_sessions.created_at) AS quarter,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS gsearch_nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS bsearch_nonbrand_orders,
    COUNT(DISTINCT CASE WHEN utm_source = 'brand' THEN orders.order_id ELSE NULL END) AS brand_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END) AS organic_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) AS direct_type_in_orders
FROM 
		website_sessions
        LEFT JOIN orders
        ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1, 2
ORDER BY 1, 2
;

/*
4. Next, Extract the overall session to order conversion rate trends for the same channels
by quarter. Please also make a note of any periods where the company made major improvements or
optimizations.
*/

SELECT
	year(website_sessions.created_at) AS year,
    QUARTER(website_sessions.created_at) AS quarter,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		/ COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END)AS gsearch_nonbrand_conv_rate,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END)  AS bsearch_nonbrand_conv_rate,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS brand_search_conv_rate,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_conv_rate,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_typein_conv_rate 
 FROM
	website_sessions
    LEFT JOIN orders
    ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2
;
    
/* 
5. The Company has come a long way since the days of selling a single product. 
Let's pull monthly trending for revenue and margin by product along with total sales amd revenue.
Note anything you notice about seasonality.
*/

SELECT
	YEAR(created_at) AS year,
    MONTH(created_at) AS month,
    SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS mrfuzzy_rev,
    SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd ELSE NULL END) AS mrsuzzy_marg,
    SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS lovebear_rev,
    SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd ELSE NULL END) AS lovebear_marg,
    SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS birthdaybear_rev,
    SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd ELSE NULL END) AS birthdaybear_marg,
    SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS minibear_rev,
    SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd ELSE NULL END) AS minibear_marg,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd - cogs_usd) AS total_margin
FROM
	order_items
GROUP BY 1, 2
ORDER BY 1, 2
;

/* 
6. The company CEO wants to dive deeper into the impact of introducing new products. 
Extract the monthly sessions to the /products page, and show how the % of those sessions clicking 
through another page has changed over time along with a view of how conversion from /products to 
placing order has improved.
*/
-- first, identify all the views of /products page
DROP TEMPORARY TABLE IF EXISTS products_pageviews;
CREATE TEMPORARY TABLE products_pageviews
SELECT 
	website_session_id,
    website_pageview_id,
    created_at AS saw_product_page_at
FROM
	website_pageviews
WHERE pageview_url = '/products'
;

SELECT
	YEAR(saw_product_page_at),
    MONTH(saw_product_page_at),
    COUNT(DISTINCT products_pageviews.website_session_id) AS sessions_to_product_page,
    COUNT(DISTINCT website_pageviews.website_session_id) AS clicked_to_next_page,
    COUNT(DISTINCT website_pageviews.website_session_id)/COUNT(DISTINCT products_pageviews.website_session_id) AS clickthrough_rt,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT products_pageviews.website_session_id) AS products_to_order_rt
FROM products_pageviews
LEFT JOIN website_pageviews
	ON website_pageviews.website_session_id = products_pageviews.website_session_id -- same session
	AND website_pageviews.website_pageview_id > products_pageviews.website_pageview_id -- they had another page after
LEFT JOIN orders
	ON orders.website_session_id = products_pageviews.website_session_id
GROUP BY 1, 2
;

/* 
7. The company made the 4th product available as a primary product on DEC 05, 2014 (it was previously only a 
cross-sell item) Extract the sales data since then, and show how well each product cross-sells from 
one another.
*/

DROP TEMPORARY TABLE IF EXISTS primary_products;
CREATE TEMPORARY TABLE primary_products
SELECT
	order_id,
    primary_product_id,
    created_at AS ordered_at
FROM
	orders
WHERE created_at > '2014-12-05' -- when 4th product is added
;


SELECT
	primary_product_id,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END) AS xsold_p1,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END) AS xsold_p2,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END) AS xsold_p3,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END) AS xsold_p4,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p1_xsell_rt,
	COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p2_xsell_rt,
	COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p3_xsell_rt,
	COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p4_xsell_rt
FROM
(
SELECT 
	primary_products.*,
    order_items.product_id AS cross_sell_product_id
FROM primary_products
LEFT JOIN
	order_items
    On order_items.order_id = primary_products.order_id
    AND order_items.is_primary_item = 0 -- only bring in cross-sells
) AS primary_w_cross_sell
GROUP BY 1
;



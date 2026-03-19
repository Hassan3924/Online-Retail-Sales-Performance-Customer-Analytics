USE retaiil_project

# Performance by year and month
SELECT
*
FROM
online_retail;

SELECT
	 YEAR(InvoiceDate) AS Year_Date,
     MONTH(InvoiceDate) AS Month_Date,
	 CONCAT('$', SUM(Quantity * UnitPrice)) AS revenue
FROM
	online_retail
WHERE
	Quantity > 0
GROUP BY
	YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY
	YEAR(InvoiceDate), MONTH(InvoiceDate)
    
# Best performing country
SELECT
	 YEAR(InvoiceDate) AS Year_Date,
     Country,
	 CONCAT('$', SUM(Quantity * UnitPrice)) AS revenue
FROM
	online_retail
WHERE
	Quantity > 0
GROUP BY
	YEAR(InvoiceDate), Country
ORDER BY
	YEAR(InvoiceDate), revenue DESC
    
# Sales over month
WITH revenue_generated AS (SELECT
	 YEAR(InvoiceDate) AS Year_Date,
     MONTH(InvoiceDate) AS Month_Date,
	 SUM(Quantity * UnitPrice) AS revenue
FROM
	online_retail
WHERE
	Quantity > 0
GROUP BY
	YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY
	YEAR(InvoiceDate), MONTH(InvoiceDate), revenue DESC
)

SELECT 
	*,
    LAG(revenue) OVER (PARTITION BY Year_Date ORDER BY Month_Date) AS previous_revenue,
	revenue - LAG(revenue) OVER (PARTITION BY Year_Date ORDER BY Month_Date) AS revenue_diff,
    CASE WHEN
		(revenue - LAG(revenue) OVER (PARTITION BY Year_Date ORDER BY Month_Date)) > 0 THEN 'Performed better' WHEN
        (revenue - LAG(revenue) OVER (PARTITION BY Year_Date ORDER BY Month_Date)) < 0 THEN 'Performed worse' ELSE 'No change' END AS performance
FROM
	revenue_generated
    
# Customer Loyalty
SELECT 
	CustomerID,
    SUM(Quantity * UnitPrice) AS money_spent
FROM
	online_retail
WHERE
	quantity > 0 AND quantity < 100 AND CustomerID IS NOT NULL
GROUP BY 
	CustomerID
ORDER BY 
	money_spent DESC

# Orders throughout the month

SELECT
    YEAR(InvoiceDate) AS Year_Date,
	MONTH(InvoiceDate) AS Month_Date,
	COUNT(DISTINCT InvoiceNo) AS no_of_orders
FROM
	online_retail
WHERE
	quantity > 0 AND quantity < 100 AND CustomerID IS NOT NULL
GROUP BY
	YEAR(InvoiceDate), MONTH(InvoiceDate)

# Most popular description item ordered
WITH quantity AS (
SELECT
	YEAR(InvoiceDate) AS invoice_year, 
    MONTH(InvoiceDate) AS invoice_month,
    Description,
    DENSE_RANK() OVER (PARTITION BY YEAR(InvoiceDate), MONTH(InvoiceDate) ORDER BY SUM(Quantity) DESC) AS order_ranking
FROM
	online_retail
WHERE
	quantity > 0 AND quantity < 100 AND CustomerID IS NOT NULL
GROUP BY
	YEAR(InvoiceDate), MONTH(InvoiceDate), Description
ORDER BY
	YEAR(InvoiceDate), MONTH(InvoiceDate)
)

SELECT
	*
FROM
	quantity
WHERE
	order_ranking = 1

# Most revenue generated for each month with item
WITH revenue_item AS (
SELECT
	YEAR(InvoiceDate) AS invoice_year, 
    MONTH(InvoiceDate) AS invoice_month,
    Description,
     SUM(Quantity * UnitPrice) as revenue_generated,
    DENSE_RANK() OVER (PARTITION BY YEAR(InvoiceDate), MONTH(InvoiceDate) ORDER BY SUM(Quantity * UnitPrice) DESC) AS most_revenue_item
FROM
	online_retail
WHERE
	quantity > 0 AND quantity < 100 AND CustomerID IS NOT NULL
GROUP BY
	YEAR(InvoiceDate), MONTH(InvoiceDate), Description
ORDER BY
	YEAR(InvoiceDate), MONTH(InvoiceDate)
)

SELECT
	*
FROM
	revenue_item
WHERE
	most_revenue_item= 1

# Moving average of the months before to see the trend
SELECT
	YEAR(InvoiceDate) AS invoice_year, 
    MONTH(InvoiceDate) AS invoice_month,
    ROUND(SUM(Quantity * UnitPrice), 2) AS total_revenue,
	ROUND(AVG(SUM(Quantity * UnitPrice)) OVER (ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate) ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS three_months_moving_average,
FROM
	online_retail
WHERE
	quantity > 0 AND
    quantity < 100 AND 
    CustomerID IS NOT NULL
GROUP BY
	YEAR(InvoiceDate), 
    MONTH(InvoiceDate)

SELECT
	YEAR(InvoiceDate) AS invoice_year,
    MONTH(InvoiceDate) AS invoice_month,
	ROUND(AVG(SUM(Quantity * UnitPrice)) OVER (ORDER BY YEAR(InvoiceDate), MONTH(InvoiceDate) ROWS BETWEEN 2 PRECEDING AND CURRENT ROW),2) AS three_months_moving_average
FROM
	online_retail
WHERE
	quantity > 0 AND 
    quantity < 100 AND 
    CustomerID IS NOT NULL
GROUP BY
	YEAR(InvoiceDate), 
    MONTH(InvoiceDate)

# RFM Analysis + Customer Segmentation
WITH rfm_base AS (
SELECT 
	CustomerID,
	DATEDIFF('2012-01-01', MAX(InvoiceDate)) AS Recency,
    COUNT(DISTINCT InvoiceNo) AS Frequency,
	ROUND(SUM(Quantity * UnitPrice),2) AS Monetary
FROM
	online_retail
WHERE
	Quantity > 0 AND 
	CustomerID IS NOT NULL
GROUP BY 
	CustomerID
),
rfm_scored AS (
SELECT 
	*,
    NTILE(5) OVER (ORDER BY Recency ASC) AS r_score,
    NTILE(5) OVER (ORDER BY Frequency DESC) as f_score,
    NTILE(5) OVER (ORDER BY Monetary DESC) as m_score
FROM
	rfm_base
)
SELECT
	CustomerID,
	CASE 
    WHEN r_score = 5 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
    WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 3 THEN 'Loyal Customers' 
    WHEN r_score >= 3 AND f_score >= 3 AND m_score >= 3 THEN 'Potential Loyalists' 
    WHEN r_score >= 4 AND f_score <= 2 AND m_score >= 3 THEN 'Promising' 
    WHEN r_score >= 3 AND f_score <= 2 AND m_score <= 2 THEN 'Need Attention' 
    WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
    WHEN r_score <= 2 AND f_score <= 2 AND m_score >= 3 THEN 'Hibernating' 
    WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Lost'
    ELSE 'Low Value' END AS customer_label
FROM
	rfm_scored

# Customer Lifetime Value
SELECT 
	CustomerID,
	ROUND(SUM(Quantity * UnitPrice) / COUNT(DISTINCT InvoiceNo),2) AS avg_order_value,
	COUNT(DISTINCT InvoiceNo) AS order_f,	
	TIMESTAMPDIFF(MONTH, MIN(InvoiceDate) , MAX(InvoiceDate)) AS customer_lifespan_months,
    ROUND(
		SUM(Quantity * UnitPrice) / COUNT(DISTINCT InvoiceNo) 
        * COUNT(DISTINCT InvoiceNo) 
        * 0.5,2) AS estimated_clv
FROM
	online_retail
WHERE
	Quantity > 0 AND 
	CustomerID IS NOT NULL
GROUP BY 
	CustomerID
ORDER BY
	estimated_clv DESC


# RFM Analysis + Customer Segmentation + CLV 
WITH rfm_base AS (
SELECT 
	CustomerID,
    DATEDIFF('2012-01-01', MAX(InvoiceDate)) AS Recency,
    COUNT(DISTINCT InvoiceNo) AS Frequency,
	ROUND(SUM(Quantity * UnitPrice), 2) AS Monetary
FROM
	online_retail
WHERE
	Quantity > 0 AND 
	CustomerID IS NOT NULL
GROUP BY 
	CustomerID
),
rfm_scored AS (
SELECT 
	*,
    NTILE(5) OVER (ORDER BY Recency ASC) AS R_score,
    NTILE(5) OVER (ORDER BY Frequency DESC) as F_score,
    NTILE(5) OVER (ORDER BY Monetary DESC) as M_score
FROM
	rfm_base
),
rfm_final AS (
SELECT
	*,
	CASE 
    WHEN R_score = 5 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
    WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 3 THEN 'Loyal Customers' 
    WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3 THEN 'Potential Loyalists' 
    WHEN R_score >= 4 AND F_score <= 2 AND M_score >= 3 THEN 'Promising' 
    WHEN R_score >= 3 AND F_score <= 2 AND M_score <= 2 THEN 'Need Attention' 
    WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 3 THEN 'At Risk'
    WHEN R_score <= 2 AND F_score <= 2 AND M_score >= 3 THEN 'Hibernating' 
    WHEN R_score <= 2 AND F_score <= 2 AND M_score <= 2 THEN 'Lost'
    ELSE 'Low Value' END AS customer_label
FROM
	rfm_scored
)

SELECT 
	*,	
    ROUND(
		Monetary
        * CASE
        WHEN customer_label = 'Champions' THEN 1.0
        WHEN customer_label = 'Loyal Customers' THEN 0.8
        WHEN customer_label = 'Potential Loyalists' THEN 0.6
        WHEN customer_label = 'Promising' THEN 0.5
        WHEN customer_label IN ('Need Attention', 'At Risk') THEN 0.3
        WHEN customer_label = 'Hibernating' THEN 0.2
        ELSE 0.1
        END, 2) AS estimated_clv
FROM
	rfm_final
ORDER BY
	estimated_clv DESC

# Key insights for far:
1. UK has been the country that has the most business 
2. Things have been returned before by Customers. For example: -8000 quantity number
3. Wrote an SQL query to show the months which performed better than previous month as well as the month where orders are made the most
4. Got the result of our most loyal customer 
5. Results showed that most orders start to trend upwards from September and peaks in November most likely because of the holidays
6. Gotten the most ordered items from each month to make potential offers
7. 'WHITE HANGING HEART T-LIGHT HOLDER' item was the most ordered item 6/12 times of the year
8. 'REGENCY CAKESTAND 3 TIER' has been the top performance in terms of revenue more than 50% of the months
9. Using moving_average, it shows that the revenue_generated shows an upward trend at the start and towards the end of the year. 
10. Wrote a query calculating the RFM score.
11. 
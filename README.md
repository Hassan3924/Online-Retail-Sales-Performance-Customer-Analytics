# Online Retail Customer Segmentation & Lifetime Value Analysis (SQL Project)

**Project Overview**  
This project performs customer segmentation and lifetime value estimation on the classic UCI Online Retail dataset (~541,000 transactions from 2010–2011). The goal is to understand purchasing behavior, identify high-value customers, spot retention opportunities, and uncover seasonal trends using advanced SQL techniques.

**Key Techniques Used**
- Aggregation (SUM, COUNT, GROUP BY)
- Window functions (NTILE for quintile scoring, LAG for month-over-month comparison)
- Common Table Expressions (CTEs) for modular, readable queries
- Moving averages for trend analysis
- RFM analysis (Recency, Frequency, Monetary) + customer segmentation
- Segment-specific Customer Lifetime Value (CLV) estimation

**Main Analyses**
- Monthly revenue trends and 3-month moving average
- Top-performing countries and items by revenue & order volume
- RFM-based customer segmentation into 8 meaningful groups:  
  Champions • Loyal Customers • Potential Loyalists • Promising • Need Attention • At Risk • Hibernating • Lost
- Conservative, segment-specific CLV (using adjusted multipliers: 1.0 for Champions down to 0.1 for Lost)

**Key Business Insights**
- The United Kingdom dominates revenue (≈80%)
- Revenue shows strong seasonality — sharp rise from September, peaking in November (holiday effect)
- 'REGENCY CAKESTAND 3 TIER' and 'WHITE HANGING HEART T-LIGHT HOLDER' are consistent top performers
- Champions & Loyal Customers generate disproportionate revenue despite being a small percentage of the base
- At Risk and Hibernating segments offer the biggest retention opportunities
- One-time high-value bulk orders can inflate simple CLV calculations — segment-based multipliers provide more realistic estimates

**Technologies**
- MySQL 8+
- MySQL Workbench
- Window functions, CTEs, CASE statements, date functions

**Future Improvements**
- Add churn probability modeling
- Visualize results in Tableau / Power BI
- Incorporate more advanced CLV models (BG/NBD, Pareto/NBD)

This project demonstrates strong SQL skills for customer analytics, segmentation, and value estimation — perfect for data analyst / business intelligence roles.

Feel free to star ⭐ or fork the repo!

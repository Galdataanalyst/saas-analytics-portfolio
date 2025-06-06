
-- ==============================
-- SaaS Subscription Analysis Queries
-- ==============================

-- 1. Monthly Recurring Revenue (MRR)
SELECT 
    FORMAT(start_date, 'yyyy-MM') AS month,
    SUM(price) AS monthly_recurring_revenue
FROM subscriptions
WHERE is_active = 1
GROUP BY FORMAT(start_date, 'yyyy-MM')
ORDER BY month;

-- 2. Churn Rate by Month
WITH SubStartEnd AS (
    SELECT 
        user_id,
        FORMAT(start_date, 'yyyy-MM') AS start_month,
        FORMAT(end_date, 'yyyy-MM') AS end_month
    FROM subscriptions
)
SELECT 
    end_month AS churn_month,
    COUNT(*) AS churned_users
FROM SubStartEnd
WHERE end_month IS NOT NULL
GROUP BY end_month
ORDER BY churn_month;

-- 3. Customer Lifetime Value (CLTV)
SELECT 
    u.user_id,
    u.country,
    SUM(p.amount) AS total_revenue,
    COUNT(p.payment_id) AS payments_made,
    ROUND(AVG(p.amount), 2) AS avg_payment,
    ROUND(SUM(p.amount) / NULLIF(COUNT(p.payment_id), 0), 2) AS cltv
FROM payments p
JOIN users u ON p.user_id = u.user_id
WHERE p.status = 'Paid'
GROUP BY u.user_id, u.country
ORDER BY cltv DESC;

-- 4. Feature Usage Summary
SELECT 
    feature_name,
    COUNT(DISTINCT user_id) AS users_used,
    SUM(usage_count) AS total_usage,
    ROUND(AVG(usage_count), 2) AS avg_usage
FROM feature_usage
GROUP BY feature_name
ORDER BY total_usage DESC;

-- 5. Active Users per Month
SELECT 
    FORMAT(login_date, 'yyyy-MM') AS month,
    COUNT(DISTINCT user_id) AS active_users
FROM logins
GROUP BY FORMAT(login_date, 'yyyy-MM')
ORDER BY month;

-- 6. Retention Rate (Users who logged in in consecutive months)
WITH MonthlyLogins AS (
    SELECT DISTINCT 
        user_id,
        FORMAT(login_date, 'yyyy-MM') AS month
    FROM logins
),
Retention AS (
    SELECT 
        a.user_id,
        a.month AS current_month,
        b.month AS next_month
    FROM MonthlyLogins a
    JOIN MonthlyLogins b ON a.user_id = b.user_id
    WHERE DATEADD(MONTH, 1, CAST(a.month + '-01' AS DATE)) = CAST(b.month + '-01' AS DATE)
)
SELECT 
    current_month,
    COUNT(DISTINCT user_id) AS retained_users
FROM Retention
GROUP BY current_month
ORDER BY current_month;

-- 7. Revenue by Country
SELECT 
    u.country,
    SUM(p.amount) AS total_revenue
FROM payments p
JOIN users u ON p.user_id = u.user_id
WHERE p.status = 'Paid'
GROUP BY u.country
ORDER BY total_revenue DESC;

-- 8. Plan Popularity and Revenue
SELECT 
    plan_type,
    COUNT(*) AS total_subscriptions,
    SUM(price) AS total_plan_revenue,
    ROUND(AVG(price), 2) AS avg_price
FROM subscriptions
GROUP BY plan_type
ORDER BY total_plan_revenue DESC;

-- 9. Failed Payment Rate
SELECT 
    COUNT(*) AS total_payments,
    SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) AS failed_payments,
    ROUND(100.0 * SUM(CASE WHEN status = 'Failed' THEN 1 ELSE 0 END) / COUNT(*), 2) AS failure_rate_percent
FROM payments;

-- 10. Most Engaged Users (Top Feature Usage)
SELECT 
    u.user_id,
    u.name,
    SUM(fu.usage_count) AS total_feature_usage
FROM feature_usage fu
JOIN users u ON fu.user_id = u.user_id
GROUP BY u.user_id, u.name
ORDER BY total_feature_usage DESC
LIMIT 10;

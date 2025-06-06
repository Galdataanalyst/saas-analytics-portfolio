
-- ===========================================
-- ADVANCED SaaS ANALYTICS QUERIES (20 examples)
-- ===========================================

-- 1. Total number of users per acquisition source
SELECT source, COUNT(DISTINCT user_id) AS total_users
FROM users
GROUP BY source
ORDER BY total_users DESC;

-- 2. Number of active subscriptions by plan type
SELECT plan_type, COUNT(*) AS active_subscriptions
FROM subscriptions
WHERE is_active = 1
GROUP BY plan_type
ORDER BY active_subscriptions DESC;

-- 3. Monthly revenue trend with rolling 3-month average
WITH MonthlyRevenue AS (
    SELECT 
        FORMAT(payment_date, 'yyyy-MM') AS month,
        SUM(amount) AS total_revenue
    FROM payments
    WHERE status = 'Paid'
    GROUP BY FORMAT(payment_date, 'yyyy-MM')
)
SELECT 
    month,
    total_revenue,
    ROUND(AVG(total_revenue) OVER (ORDER BY month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS rolling_avg_3m
FROM MonthlyRevenue;

-- 4. Feature stickiness: % of users using each feature
SELECT 
    feature_name,
    COUNT(DISTINCT user_id) AS users_used,
    (SELECT COUNT(*) FROM users) AS total_users,
    ROUND(100.0 * COUNT(DISTINCT user_id) / (SELECT COUNT(*) FROM users), 2) AS usage_percent
FROM feature_usage
GROUP BY feature_name
ORDER BY usage_percent DESC;

-- 5. Churned users with last login date
SELECT 
    u.user_id,
    u.name,
    MAX(l.login_date) AS last_login,
    s.end_date
FROM users u
JOIN subscriptions s ON u.user_id = s.user_id
LEFT JOIN logins l ON u.user_id = l.user_id
WHERE s.end_date IS NOT NULL
GROUP BY u.user_id, u.name, s.end_date
ORDER BY last_login DESC;

-- 6. Time between sign-up and first login
SELECT 
    u.user_id,
    DATEDIFF(DAY, u.signup_date, MIN(l.login_date)) AS days_to_first_login
FROM users u
JOIN logins l ON u.user_id = l.user_id
GROUP BY u.user_id, u.signup_date
ORDER BY days_to_first_login;

-- 7. Top 5 cities by login volume
SELECT TOP 5 location, COUNT(*) AS total_logins
FROM logins
GROUP BY location
ORDER BY total_logins DESC;

-- 8. Monthly user growth with previous month comparison
WITH UserGrowth AS (
    SELECT 
        FORMAT(signup_date, 'yyyy-MM') AS month,
        COUNT(*) AS new_users
    FROM users
    GROUP BY FORMAT(signup_date, 'yyyy-MM')
)
SELECT 
    month,
    new_users,
    LAG(new_users, 1) OVER (ORDER BY month) AS previous_month,
    new_users - LAG(new_users, 1) OVER (ORDER BY month) AS growth
FROM UserGrowth;

-- 9. Average payment amount per plan
SELECT 
    s.plan_type,
    ROUND(AVG(p.amount), 2) AS avg_payment
FROM payments p
JOIN subscriptions s ON p.user_id = s.user_id
WHERE p.status = 'Paid'
GROUP BY s.plan_type
ORDER BY avg_payment DESC;

-- 10. Users with high feature usage but low payment
SELECT 
    fu.user_id,
    SUM(fu.usage_count) AS total_usage,
    COALESCE(SUM(p.amount), 0) AS total_payment
FROM feature_usage fu
LEFT JOIN payments p ON fu.user_id = p.user_id AND p.status = 'Paid'
GROUP BY fu.user_id
HAVING SUM(fu.usage_count) > 100 AND COALESCE(SUM(p.amount), 0) < 50
ORDER BY total_usage DESC;

-- 11. Monthly churn rate (%)
WITH MonthlyStarts AS (
    SELECT FORMAT(start_date, 'yyyy-MM') AS month, COUNT(*) AS started FROM subscriptions GROUP BY FORMAT(start_date, 'yyyy-MM')
),
MonthlyEnds AS (
    SELECT FORMAT(end_date, 'yyyy-MM') AS month, COUNT(*) AS ended FROM subscriptions WHERE end_date IS NOT NULL GROUP BY FORMAT(end_date, 'yyyy-MM')
)
SELECT 
    s.month,
    s.started,
    COALESCE(e.ended, 0) AS ended,
    ROUND(100.0 * COALESCE(e.ended, 0) / NULLIF(s.started, 0), 2) AS churn_rate_percent
FROM MonthlyStarts s
LEFT JOIN MonthlyEnds e ON s.month = e.month
ORDER BY s.month;

-- 12. Users with increasing login frequency
WITH WeeklyLogins AS (
    SELECT 
        user_id,
        DATEPART(WEEK, login_date) AS week_num,
        COUNT(*) AS login_count
    FROM logins
    GROUP BY user_id, DATEPART(WEEK, login_date)
),
GrowthPattern AS (
    SELECT 
        user_id,
        week_num,
        login_count,
        LAG(login_count, 1) OVER (PARTITION BY user_id ORDER BY week_num) AS prev_logins
    FROM WeeklyLogins
)
SELECT * FROM GrowthPattern
WHERE login_count > prev_logins;

-- 13. Failed payments by method
SELECT 
    payment_method,
    COUNT(*) AS failed_count
FROM payments
WHERE status = 'Failed'
GROUP BY payment_method
ORDER BY failed_count DESC;

-- 14. Most common login device per user
SELECT 
    user_id,
    device,
    COUNT(*) AS cnt,
    RANK() OVER (PARTITION BY user_id ORDER BY COUNT(*) DESC) AS rnk
FROM logins
GROUP BY user_id, device
HAVING RANK() OVER (PARTITION BY user_id ORDER BY COUNT(*) DESC) = 1;

-- 15. Daily logins trend (last 30 days)
SELECT 
    login_date,
    COUNT(*) AS total_logins
FROM logins
WHERE login_date >= DATEADD(DAY, -30, GETDATE())
GROUP BY login_date
ORDER BY login_date;

-- 16. % of paying users
SELECT 
    ROUND(100.0 * COUNT(DISTINCT p.user_id) / (SELECT COUNT(*) FROM users), 2) AS paying_user_percent
FROM payments p
WHERE status = 'Paid';

-- 17. Revenue concentration: top 10 users by revenue
SELECT TOP 10 
    user_id,
    SUM(amount) AS total_revenue
FROM payments
WHERE status = 'Paid'
GROUP BY user_id
ORDER BY total_revenue DESC;

-- 18. Users with payments but no logins in last 60 days
SELECT 
    u.user_id,
    MAX(l.login_date) AS last_login,
    SUM(p.amount) AS total_paid
FROM users u
JOIN payments p ON u.user_id = p.user_id
LEFT JOIN logins l ON u.user_id = l.user_id
WHERE p.status = 'Paid'
GROUP BY u.user_id
HAVING MAX(l.login_date) < DATEADD(DAY, -60, GETDATE());

-- 19. Top used features by average usage per user
SELECT 
    feature_name,
    ROUND(AVG(usage_count), 2) AS avg_usage_per_user
FROM feature_usage
GROUP BY feature_name
ORDER BY avg_usage_per_user DESC;

-- 20. Average number of features used per user
SELECT 
    ROUND(AVG(feature_count), 2) AS avg_features_used
FROM (
    SELECT user_id, COUNT(DISTINCT feature_name) AS feature_count
    FROM feature_usage
    GROUP BY user_id
) AS feature_summary;


-- ==============================
-- SaaS Subscription Database Schema
-- ==============================

CREATE TABLE users (
    user_id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    signup_date DATE,
    country VARCHAR(50),
    source VARCHAR(50)
);

CREATE TABLE subscriptions (
    sub_id INT PRIMARY KEY,
    user_id INT,
    plan_type VARCHAR(50),
    start_date DATE,
    end_date DATE,
    price DECIMAL(10,2),
    is_active BOOLEAN,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE logins (
    login_id INT PRIMARY KEY,
    user_id INT,
    login_date DATE,
    device VARCHAR(50),
    location VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE feature_usage (
    usage_id INT PRIMARY KEY,
    user_id INT,
    feature_name VARCHAR(100),
    usage_count INT,
    date DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE payments (
    payment_id INT PRIMARY KEY,
    user_id INT,
    payment_date DATE,
    amount DECIMAL(10,2),
    payment_method VARCHAR(50),
    status VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

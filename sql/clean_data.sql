-- Phase 1: Clean Data

---------------------------------------------------------
-- Analyse et nettoyage des données table par table
---------------------------------------------------------

-- Customer_demographics

SELECT COUNT(*) AS total_rows FROM BRONZE.customer_demographics;

SELECT * FROM BRONZE.customer_demographics LIMIT 10;

SELECT 
    COUNT(*) AS total,
    COUNT(customer_id) AS non_null_customer_id,
    COUNT(name) AS non_null_name,
    COUNT(date_of_birth) AS non_null_dob,
    COUNT(gender) AS non_null_gender,
    COUNT(region) AS non_null_region,
    COUNT(country) AS non_null_country,
    COUNT(annual_income) AS non_null_income,
    COUNT(DISTINCT customer_id) AS distinct_customer_ids
FROM BRONZE.customer_demographics;

SELECT gender, COUNT(*) AS cnt 
FROM BRONZE.customer_demographics 
GROUP BY gender 
ORDER BY cnt DESC;

SELECT COUNT(*) AS income_issues 
FROM BRONZE.customer_demographics 
WHERE annual_income IS NULL OR annual_income <= 0;

-- Table correcte - passage en Silver

CREATE OR REPLACE TABLE SILVER.customer_demographics_clean AS
SELECT DISTINCT
    customer_id,
    name,
    date_of_birth,
    gender,
    region,
    country,
    city,
    marital_status,
    annual_income
FROM BRONZE.customer_demographics
WHERE
    customer_id IS NOT NULL
    AND annual_income > 0;



-- Customer_service_interactions

SELECT COUNT(*) AS total_rows FROM BRONZE.customer_service_interactions;

SELECT 
    COUNT(*) AS total,
    COUNT(interaction_id) AS non_null_id,
    COUNT(interaction_date) AS non_null_date,
    COUNT(interaction_type) AS non_null_type,
    COUNT(issue_category) AS non_null_category,
    COUNT(duration_minutes) AS non_null_duration,
    COUNT(resolution_status) AS non_null_status,
    COUNT(customer_satisfaction) AS non_null_satisfaction,
    COUNT(DISTINCT interaction_id) AS distinct_ids
FROM BRONZE.customer_service_interactions;

SELECT interaction_type, COUNT(*) AS cnt 
FROM BRONZE.customer_service_interactions 
GROUP BY interaction_type ORDER BY cnt DESC;

SELECT resolution_status, COUNT(*) AS cnt 
FROM BRONZE.customer_service_interactions 
GROUP BY resolution_status ORDER BY cnt DESC;

SELECT COUNT(*) AS issues 
FROM BRONZE.customer_service_interactions 
WHERE duration_minutes <= 0 
   OR customer_satisfaction < 1 
   OR customer_satisfaction > 5;

-- Vérification des doublons
SELECT * 
FROM BRONZE.customer_service_interactions
WHERE interaction_id IN (
    SELECT interaction_id 
    FROM BRONZE.customer_service_interactions 
    GROUP BY interaction_id 
    HAVING COUNT(*) > 1
)
ORDER BY interaction_id;

-- Passage en silver
CREATE OR REPLACE TABLE SILVER.customer_service_interactions_clean AS
SELECT
    interaction_id,
    interaction_date,
    interaction_type,
    issue_category,
    description,
    duration_minutes,
    resolution_status,
    follow_up_required,
    customer_satisfaction
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY interaction_id ORDER BY interaction_date DESC) AS rn
    FROM BRONZE.customer_service_interactions
)
WHERE rn = 1;


-- financial_transactions
SELECT COUNT(*) AS total_rows FROM BRONZE.financial_transactions;

-- Analyse des nulls
SELECT 
    COUNT(*) AS total,
    COUNT(transaction_id) AS non_null_id,
    COUNT(transaction_date) AS non_null_date,
    COUNT(transaction_type) AS non_null_type,
    COUNT(amount) AS non_null_amount,
    COUNT(payment_method) AS non_null_payment,
    COUNT(entity) AS non_null_entity,
    COUNT(region) AS non_null_region,
    COUNT(DISTINCT transaction_id) AS distinct_ids
FROM BRONZE.financial_transactions;

-- Types de transactions (important pour le filtre métier)
SELECT transaction_type, COUNT(*) AS cnt, 
       ROUND(AVG(amount), 2) AS avg_amount,
       MIN(amount) AS min_amount
FROM BRONZE.financial_transactions 
GROUP BY transaction_type ORDER BY cnt DESC;

-- Montants négatifs ou nuls
SELECT COUNT(*) AS amount_issues 
FROM BRONZE.financial_transactions 
WHERE amount IS NULL OR amount <= 0;

-- Passage en Silver
CREATE OR REPLACE TABLE SILVER.financial_transactions_clean AS
SELECT DISTINCT
    transaction_id,
    transaction_date,
    transaction_type,
    amount,
    payment_method,
    entity,
    region,
    account_code
FROM BRONZE.financial_transactions
WHERE
    transaction_id IS NOT NULL
    AND transaction_date IS NOT NULL
    AND amount > 0;

-- promotions_data
SELECT COUNT(*) AS total_rows FROM BRONZE.promotions_data;

SELECT 
    COUNT(*) AS total,
    COUNT(promotion_id) AS non_null_id,
    COUNT(product_category) AS non_null_category,
    COUNT(promotion_type) AS non_null_type,
    COUNT(discount_percentage) AS non_null_discount,
    COUNT(start_date) AS non_null_start,
    COUNT(end_date) AS non_null_end,
    COUNT(region) AS non_null_region,
    COUNT(DISTINCT promotion_id) AS distinct_ids
FROM BRONZE.promotions_data;

SELECT COUNT(*) AS date_issues 
FROM BRONZE.promotions_data 
WHERE end_date <= start_date;

SELECT COUNT(*) AS discount_issues 
FROM BRONZE.promotions_data 
WHERE discount_percentage <= 0 OR discount_percentage > 1;

SELECT product_category, COUNT(*) AS cnt 
FROM BRONZE.promotions_data 
GROUP BY product_category ORDER BY cnt DESC;

-- Passage en Silver
CREATE OR REPLACE TABLE SILVER.promotions_clean AS
SELECT DISTINCT
    promotion_id,
    product_category,
    promotion_type,
    discount_percentage,
    start_date,
    end_date,
    region
FROM BRONZE.promotions_data
WHERE
    promotion_id IS NOT NULL
    AND start_date IS NOT NULL
    AND end_date IS NOT NULL
    AND end_date > start_date
    AND discount_percentage > 0
    AND discount_percentage <= 1;

-- marketing_campaigns

SELECT COUNT(*) AS total_rows FROM BRONZE.marketing_campaigns;

SELECT 
    COUNT(*) AS total,
    COUNT(campaign_id) AS non_null_id,
    COUNT(campaign_name) AS non_null_name,
    COUNT(campaign_type) AS non_null_type,
    COUNT(product_category) AS non_null_category,
    COUNT(target_audience) AS non_null_audience,
    COUNT(start_date) AS non_null_start,
    COUNT(end_date) AS non_null_end,
    COUNT(region) AS non_null_region,
    COUNT(budget) AS non_null_budget,
    COUNT(reach) AS non_null_reach,
    COUNT(conversion_rate) AS non_null_conversion,
    COUNT(DISTINCT campaign_id) AS distinct_ids
FROM BRONZE.marketing_campaigns;

SELECT COUNT(*) AS date_issues 
FROM BRONZE.marketing_campaigns 
WHERE end_date <= start_date;

SELECT COUNT(*) AS budget_issues 
FROM BRONZE.marketing_campaigns 
WHERE budget <= 0 OR reach <= 0 OR conversion_rate < 0 OR conversion_rate > 1;

SELECT campaign_type, COUNT(*) AS cnt 
FROM BRONZE.marketing_campaigns 
GROUP BY campaign_type ORDER BY cnt DESC;

SELECT product_category, COUNT(*) AS cnt 
FROM BRONZE.marketing_campaigns 
GROUP BY product_category ORDER BY cnt DESC;

-- passage en silver
CREATE OR REPLACE TABLE SILVER.marketing_campaigns_clean AS
SELECT
    campaign_id,
    campaign_name,
    campaign_type,
    product_category,
    target_audience,
    start_date,
    end_date,
    region,
    budget,
    reach,
    conversion_rate
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY start_date DESC) AS rn
    FROM BRONZE.marketing_campaigns
    WHERE
        campaign_id IS NOT NULL
        AND start_date IS NOT NULL
        AND end_date IS NOT NULL
        AND end_date > start_date
        AND budget > 0
        AND reach > 0
        AND conversion_rate BETWEEN 0 AND 1
)
WHERE rn = 1;

-- product_reviews

SELECT COUNT(*) AS total_rows FROM BRONZE.product_reviews;

SELECT * FROM BRONZE.product_reviews LIMIT 5;


SELECT 
    COUNT(*) AS total,
    COUNT(review_id) AS non_null_id,
    COUNT(product_id) AS non_null_product,
    COUNT(reviewer_name) AS non_null_reviewer,
    COUNT(rating) AS non_null_rating,
    COUNT(review_datetime) AS non_null_date,
    COUNT(product_category_1) AS non_null_category,
    COUNT(DISTINCT review_id) AS distinct_ids
FROM BRONZE.product_reviews;


SELECT COUNT(*) AS rating_issues 
FROM BRONZE.product_reviews 
WHERE rating < 1 OR rating > 5 OR rating IS NULL;

SELECT product_category_1, COUNT(*) AS cnt 
FROM BRONZE.product_reviews 
GROUP BY product_category_1 ORDER BY cnt DESC;

-- Passage en silver (on ne conserve que product_category_2 qui comporte des libellés utilisés dans les autres tables)
CREATE OR REPLACE TABLE SILVER.product_reviews_clean AS
SELECT DISTINCT
    review_id,
    product_id,
    reviewer_id,
    reviewer_name,
    rating,
    CAST(review_datetime AS DATE) AS review_date,
    review_title,
    review_text,
    product_category_2 AS product_category
FROM BRONZE.product_reviews
WHERE
    review_id IS NOT NULL
    AND product_id IS NOT NULL
    AND rating BETWEEN 1 AND 5;

-- logistics_and_shipping
SELECT COUNT(*) AS total_rows FROM BRONZE.logistics_and_shipping;

SELECT 
    COUNT(*) AS total,
    COUNT(shipment_id) AS non_null_id,
    COUNT(order_id) AS non_null_order,
    COUNT(ship_date) AS non_null_ship_date,
    COUNT(estimated_delivery) AS non_null_est_delivery,
    COUNT(shipping_method) AS non_null_method,
    COUNT(status) AS non_null_status,
    COUNT(shipping_cost) AS non_null_cost,
    COUNT(destination_region) AS non_null_region,
    COUNT(destination_country) AS non_null_country,
    COUNT(DISTINCT shipment_id) AS distinct_ids
FROM BRONZE.logistics_and_shipping;


SELECT COUNT(*) AS date_issues 
FROM BRONZE.logistics_and_shipping 
WHERE estimated_delivery < ship_date;


SELECT COUNT(*) AS cost_issues 
FROM BRONZE.logistics_and_shipping 
WHERE shipping_cost IS NULL OR shipping_cost < 0;


SELECT status, COUNT(*) AS cnt 
FROM BRONZE.logistics_and_shipping 
GROUP BY status ORDER BY cnt DESC;

SELECT shipping_method, COUNT(*) AS cnt 
FROM BRONZE.logistics_and_shipping 
GROUP BY shipping_method ORDER BY cnt DESC;

-- passage en Silver
CREATE OR REPLACE TABLE SILVER.logistics_and_shipping_clean AS
SELECT DISTINCT
    shipment_id,
    order_id,
    ship_date,
    estimated_delivery,
    shipping_method,
    status,
    shipping_cost,
    destination_region,
    destination_country,
    carrier
FROM BRONZE.logistics_and_shipping
WHERE
    shipment_id IS NOT NULL
    AND ship_date IS NOT NULL
    AND estimated_delivery >= ship_date
    AND shipping_cost >= 0;

-- supplier_information
SELECT COUNT(*) AS total_rows FROM BRONZE.supplier_information;

SELECT 
    COUNT(*) AS total,
    COUNT(supplier_id) AS non_null_id,
    COUNT(supplier_name) AS non_null_name,
    COUNT(product_category) AS non_null_category,
    COUNT(region) AS non_null_region,
    COUNT(country) AS non_null_country,
    COUNT(lead_time) AS non_null_lead_time,
    COUNT(reliability_score) AS non_null_reliability,
    COUNT(quality_rating) AS non_null_quality,
    COUNT(DISTINCT supplier_id) AS distinct_ids
FROM BRONZE.supplier_information;

SELECT COUNT(*) AS score_issues 
FROM BRONZE.supplier_information 
WHERE reliability_score < 0 OR reliability_score > 1 
   OR lead_time <= 0;

SELECT quality_rating, COUNT(*) AS cnt 
FROM BRONZE.supplier_information 
GROUP BY quality_rating ORDER BY cnt DESC;

SELECT product_category, COUNT(*) AS cnt 
FROM BRONZE.supplier_information 
GROUP BY product_category ORDER BY cnt DESC;

-- check doublons
SELECT * 
FROM BRONZE.supplier_information
WHERE supplier_id IN (
    SELECT supplier_id 
    FROM BRONZE.supplier_information 
    GROUP BY supplier_id 
    HAVING COUNT(*) > 1
)
ORDER BY supplier_id
LIMIT 20;

-- Passage en silver : on conserve les doublons en supplier_id pour ne perdre aucune informations pour la suite
CREATE OR REPLACE TABLE SILVER.supplier_information_clean AS
SELECT
    supplier_id,
    supplier_name,
    product_category,
    region,
    country,
    city,
    lead_time,
    reliability_score,
    quality_rating
FROM BRONZE.supplier_information
WHERE
    supplier_id IS NOT NULL
    AND lead_time > 0
    AND reliability_score BETWEEN 0 AND 1;

-- employee_records
SELECT COUNT(*) AS total_rows FROM BRONZE.employee_records;


SELECT 
    COUNT(*) AS total,
    COUNT(employee_id) AS non_null_id,
    COUNT(name) AS non_null_name,
    COUNT(date_of_birth) AS non_null_dob,
    COUNT(hire_date) AS non_null_hire,
    COUNT(department) AS non_null_dept,
    COUNT(job_title) AS non_null_title,
    COUNT(salary) AS non_null_salary,
    COUNT(region) AS non_null_region,
    COUNT(country) AS non_null_country,
    COUNT(DISTINCT employee_id) AS distinct_ids
FROM BRONZE.employee_records;


SELECT COUNT(*) AS salary_issues 
FROM BRONZE.employee_records 
WHERE salary IS NULL OR salary <= 0;


SELECT COUNT(*) AS date_issues 
FROM BRONZE.employee_records 
WHERE hire_date <= date_of_birth;

SELECT department, COUNT(*) AS cnt 
FROM BRONZE.employee_records 
GROUP BY department ORDER BY cnt DESC;

-- vérification des doublons
SELECT * 
FROM BRONZE.employee_records
WHERE employee_id IN (
    SELECT employee_id 
    FROM BRONZE.employee_records 
    GROUP BY employee_id 
    HAVING COUNT(*) > 1
)
ORDER BY employee_id
LIMIT 20; -- même situation que pour la table supplier_information, on va donc conserver les id en doublons pour ne perdre aucune information (les jointures se feront plutot sur "department" ou "region")

-- vérifications des anomalies sur les dates
SELECT * 
FROM BRONZE.employee_records
WHERE hire_date <= date_of_birth
ORDER BY employee_id
LIMIT 20;

-- passage en silver : on conserve les anomalies sur les dates d'emploi qui sont peu gênantes au vu des analyses à effectuer. On conserve aussi les doublons d'ID pour ne pas perdre d'informations
CREATE OR REPLACE TABLE SILVER.employee_records_clean AS
SELECT
    employee_id,
    name,
    date_of_birth,
    hire_date,
    department,
    job_title,
    salary,
    region,
    country,
    email
FROM BRONZE.employee_records
WHERE
    employee_id IS NOT NULL
    AND salary > 0;

-- inventory
SELECT COUNT(*) AS total_rows FROM BRONZE.inventory;

SELECT 
    COUNT(*) AS total,
    COUNT(product_id) AS non_null_id,
    COUNT(product_category) AS non_null_category,
    COUNT(current_stock) AS non_null_stock,
    COUNT(reorder_point) AS non_null_reorder,
    COUNT(lead_time) AS non_null_lead,
    COUNT(last_restock_date) AS non_null_restock,
    COUNT(DISTINCT product_id) AS distinct_ids
FROM BRONZE.inventory;

SELECT COUNT(*) AS stock_issues 
FROM BRONZE.inventory 
WHERE current_stock < 0 OR reorder_point < 0 OR lead_time <= 0;

-- store_locations
SELECT COUNT(*) AS total_rows FROM BRONZE.store_locations;

SELECT 
    COUNT(*) AS total,
    COUNT(store_id) AS non_null_id,
    COUNT(store_name) AS non_null_name,
    COUNT(store_type) AS non_null_type,
    COUNT(region) AS non_null_region,
    COUNT(square_footage) AS non_null_sqft,
    COUNT(employee_count) AS non_null_emp,
    COUNT(DISTINCT store_id) AS distinct_ids
FROM BRONZE.store_locations;

SELECT COUNT(*) AS store_issues 
FROM BRONZE.store_locations 
WHERE square_footage <= 0 OR employee_count <= 0;

-- inventory - passage en silver : même logique que pour supplier et employee, on conserve les doublons d'ID pour ne perdre aucune information
CREATE OR REPLACE TABLE SILVER.inventory_clean AS
SELECT
    product_id,
    product_category,
    region,
    country,
    warehouse,
    current_stock,
    reorder_point,
    lead_time,
    last_restock_date
FROM BRONZE.inventory
WHERE
    product_id IS NOT NULL
    AND current_stock >= 0
    AND reorder_point >= 0
    AND lead_time > 0;

-- Vérifications supplémentaires sur store_locations
SELECT store_id, COUNT(*) AS cnt 
FROM BRONZE.store_locations 
GROUP BY store_id 
ORDER BY cnt DESC 
LIMIT 10;

-- Check les doublons
SELECT * 
FROM BRONZE.store_locations
WHERE store_id IN (
    SELECT store_id 
    FROM BRONZE.store_locations 
    GROUP BY store_id 
    HAVING COUNT(*) > 1
)
ORDER BY store_id
LIMIT 20;

-- store_locations_clean - passage en silver : même logique que pour inventory on conserve les doublons sur ID, les jointures se feront sur d'autres colonnes
CREATE OR REPLACE TABLE SILVER.store_locations_clean AS
SELECT
    store_id,
    store_name,
    store_type,
    region,
    country,
    city,
    address,
    postal_code,
    square_footage,
    employee_count
FROM BRONZE.store_locations
WHERE
    store_id IS NOT NULL
    AND square_footage > 0
    AND employee_count > 0;
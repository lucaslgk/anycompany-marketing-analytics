-- Phase 1: Load Data
-- Création de la base de données ANYCOMPANY_LAB
create or replace database ANYCOMPANY_LAB;

use database ANYCOMPANY_LAB;

-- Création de 2 schémas BRONZE et SILVER
create schema BRONZE;
create schema SILVER;

use schema BRONZE;

-- Stage public S3
create or replace stage anycompany_data
  url='s3://logbrain-datalake/datasets/food-beverage/';

-- Visualiser les fichiers
list @anycompany_data;

-- Création du file format CSV
CREATE OR REPLACE FILE FORMAT csv
TYPE = 'CSV'
FIELD_DELIMITER = ','
SKIP_HEADER = 1
FIELD_OPTIONALLY_ENCLOSED_BY = '"'
TRIM_SPACE = TRUE
ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
ESCAPE_UNENCLOSED_FIELD = NONE
NULL_IF = ('NULL', 'null', '')
EMPTY_FIELD_AS_NULL = TRUE;

-- Création du file format JSON
create or replace file format json
  type = 'JSON'
  strip_outer_array = true;

-- Vérification des file format
show file formats in database ANYCOMPANY_LAB;

-- Création des tables
-- Table customer_demographics.csv
create or replace table customer_demographics (
    customer_id VARCHAR,
    name VARCHAR,
    date_of_birth DATE,
    gender VARCHAR,
    region VARCHAR,
    country VARCHAR,
    city VARCHAR,
    marital_status VARCHAR,
    annual_income INT
);

-- Table customer_service_interactions.csv
CREATE OR REPLACE TABLE customer_service_interactions (
    interaction_id VARCHAR,
    interaction_date DATE,
    interaction_type VARCHAR,
    issue_category VARCHAR,
    description TEXT,
    duration_minutes INT,
    resolution_status VARCHAR,
    follow_up_required VARCHAR,
    customer_satisfaction INT
);

-- Table financial_transactions.csv
CREATE OR REPLACE TABLE financial_transactions (
    transaction_id VARCHAR,
    transaction_date DATE,
    transaction_type VARCHAR,
    amount FLOAT,
    payment_method VARCHAR,
    entity VARCHAR,
    region VARCHAR,
    account_code VARCHAR
);

-- Table promotions_data.csv
CREATE OR REPLACE TABLE promotions_data (
    promotion_id VARCHAR,
    product_category VARCHAR,
    promotion_type VARCHAR,
    discount_percentage FLOAT,
    start_date DATE,
    end_date DATE,
    region VARCHAR
);

-- Table marketing_campaigns.csv
CREATE OR REPLACE TABLE marketing_campaigns (
    campaign_id VARCHAR,
    campaign_name VARCHAR,
    campaign_type VARCHAR,
    product_category VARCHAR,
    target_audience VARCHAR,
    start_date DATE,
    end_date DATE,
    region VARCHAR,
    budget FLOAT,
    reach INT,
    conversion_rate FLOAT
);

-- Table product_reviews.csv
CREATE OR REPLACE TABLE product_reviews (
    review_id INT,
    product_id VARCHAR,
    reviewer_id VARCHAR,
    reviewer_name VARCHAR,
    rating INT,
    review_date DATE,
    review_title VARCHAR,
    review_text VARCHAR,
    product_category VARCHAR
);

-- Table logistics_and_shipping.csv
CREATE OR REPLACE TABLE logistics_and_shipping (
    shipment_id VARCHAR,
    order_id VARCHAR,
    ship_date DATE,
    estimated_delivery DATE,
    shipping_method VARCHAR,
    status VARCHAR,
    shipping_cost FLOAT,
    destination_region VARCHAR,
    destination_country VARCHAR,
    carrier VARCHAR
);

-- Table supplier_information.csv
CREATE OR REPLACE TABLE supplier_information (
    supplier_id VARCHAR,
    supplier_name VARCHAR,
    product_category VARCHAR,
    region VARCHAR,
    country VARCHAR,
    city VARCHAR,
    lead_time INT,
    reliability_score FLOAT,
    quality_rating VARCHAR
);

-- Table employee_records.csv
CREATE OR REPLACE TABLE employee_records (
    employee_id VARCHAR,
    name VARCHAR,
    date_of_birth DATE,
    hire_date DATE,
    department VARCHAR,
    job_title VARCHAR,
    salary FLOAT,
    region VARCHAR,
    country VARCHAR,
    email VARCHAR
);

-- Tables JSON : inventory.json
CREATE OR REPLACE TABLE inventory (
    product_id VARCHAR,
    product_category VARCHAR,
    region VARCHAR,
    country VARCHAR,
    warehouse VARCHAR,
    current_stock INT,
    reorder_point INT,
    lead_time INT,
    last_restock_date DATE
);

-- Tables JSON : store_locations.json
CREATE OR REPLACE TABLE store_locations (
    store_id VARCHAR,
    store_name VARCHAR,
    store_type VARCHAR,
    region VARCHAR,
    country VARCHAR,
    city VARCHAR,
    address VARCHAR,
    postal_code INT,
    square_footage FLOAT,
    employee_count INT
);

-- Chargement de la data dans les tables
-- Format .csv
copy into customer_demographics
from @anycompany_data
file_format = csv
pattern = 'customer_demographics.csv';

-- select * from customer_demographics;

copy into customer_service_interactions
from @anycompany_data
file_format = csv
pattern = 'customer_service_interactions.csv';

copy into financial_transactions
from @anycompany_data
file_format = csv
pattern = 'financial_transactions.csv';

copy into promotions_data
from @anycompany_data
file_format = csv
pattern = 'promotions-data.csv';

copy into marketing_campaigns
from @anycompany_data
file_format = csv
pattern = 'marketing_campaigns.csv';

-- Problème avec product_reviews.csv : séparateur tabulation au lieu de virgule & il y a 13 colonnes au lieu de 9
-- Vérifications pour product_reviews
CREATE OR REPLACE FILE FORMAT csv_no_skip
    TYPE = 'CSV'
    FIELD_DELIMITER = '\t'
    SKIP_HEADER = 0
    TRIM_SPACE = TRUE
    EMPTY_FIELD_AS_NULL = TRUE;

SELECT 
    $1, $2, $3, $4, $5, $6, $7, $8,
    $9, $10, $11, $12, $13, $14, $15
FROM @anycompany_data/product_reviews.csv
(FILE_FORMAT => csv_no_skip)
LIMIT 10;

-- Supprimer la table existante
DROP TABLE IF EXISTS product_reviews;

-- Recréer la table avec les 14 colonnes réelles du fichier
CREATE OR REPLACE TABLE product_reviews (
    review_id INT,
    product_id VARCHAR,
    reviewer_id VARCHAR,
    reviewer_name VARCHAR,
    helpful_votes INT,
    total_votes INT,
    rating INT,
    review_datetime TIMESTAMP,
    review_title VARCHAR,
    review_text VARCHAR,
    product_category_1 VARCHAR,
    product_category_2 VARCHAR,
    product_description VARCHAR
);

-- Charger les données avec le format tabulation
COPY INTO product_reviews
FROM @anycompany_data
FILE_FORMAT = csv_no_skip
PATTERN = '.*product_reviews.csv'
ON_ERROR = 'CONTINUE';

-- Vérifier le chargement
select * from product_reviews
limit 10;

copy into logistics_and_shipping
from @anycompany_data
file_format = csv
pattern = 'logistics_and_shipping.csv';

copy into supplier_information
from @anycompany_data
file_format = csv
pattern = 'supplier_information.csv';

copy into employee_records
from @anycompany_data
file_format = csv
pattern = 'employee_records.csv';


-- Format .json
COPY INTO inventory
FROM @anycompany_data
FILE_FORMAT = json
PATTERN = 'inventory.json'
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE; -- charger avec correspondance automatique de colonnes

-- select * from inventory;

COPY INTO store_locations
FROM @anycompany_data
FILE_FORMAT = json
PATTERN = 'store_locations.json'
MATCH_BY_COLUMN_NAME = CASE_INSENSITIVE; -- charger avec correspondance automatique de colonnes
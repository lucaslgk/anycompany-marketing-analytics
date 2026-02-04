-- sales_trends.sql
-- Analyse de l'évolution des ventes et segmentation clients

USE DATABASE ANYCOMPANY_LAB;

-- Evolution mensuelle du CA (ventes uniquement)
SELECT
    DATE_TRUNC('MONTH', transaction_date) AS mois,
    COUNT(*) AS nb_transactions,
    ROUND(SUM(amount), 2) AS ca_mensuel,
    ROUND(AVG(amount), 2) AS panier_moyen
FROM SILVER.financial_transactions_clean
WHERE transaction_type = 'Sale'
GROUP BY mois
ORDER BY mois;

-- Evolution trimestrielle - plus facile pour voir les tendances saisonnières
SELECT
    DATE_TRUNC('QUARTER', transaction_date) AS trimestre,
    COUNT(*) AS nb_transactions,
    ROUND(SUM(amount), 2) AS ca_trimestriel,
    ROUND(AVG(amount), 2) AS panier_moyen
FROM SILVER.financial_transactions_clean
WHERE transaction_type = 'Sale'
GROUP BY trimestre
ORDER BY trimestre;

-- CA annuel avec variation année par année
WITH ca_annuel AS (
    SELECT
        EXTRACT(YEAR FROM transaction_date) AS annee,
        ROUND(SUM(amount), 2) AS ca
    FROM SILVER.financial_transactions_clean
    WHERE transaction_type = 'Sale'
    GROUP BY annee
)
SELECT
    annee,
    ca,
    LAG(ca) OVER (ORDER BY annee) AS ca_annee_precedente,
    ROUND((ca - LAG(ca) OVER (ORDER BY annee)) / NULLIF(LAG(ca) OVER (ORDER BY annee), 0) * 100, 2) AS variation_pct
FROM ca_annuel
ORDER BY annee;

-- Performance par région
SELECT
    region,
    COUNT(*) AS nb_transactions,
    ROUND(SUM(amount), 2) AS ca_total,
    ROUND(AVG(amount), 2) AS panier_moyen,
    ROUND(SUM(amount) / NULLIF(SUM(SUM(amount)) OVER (), 0) * 100, 2) AS part_du_ca_pct
FROM SILVER.financial_transactions_clean
WHERE transaction_type = 'Sale'
GROUP BY region
ORDER BY ca_total DESC;

-- CA par région et année - pour voir l'évolution régionale
SELECT
    EXTRACT(YEAR FROM transaction_date) AS annee,
    region,
    COUNT(*) AS nb_transactions,
    ROUND(SUM(amount), 2) AS ca
FROM SILVER.financial_transactions_clean
WHERE transaction_type = 'Sale'
GROUP BY annee, region
ORDER BY annee, ca DESC;

-- Segmentation clients par région
SELECT
    region,
    COUNT(*) AS nb_clients,
    ROUND(AVG(annual_income), 2) AS revenu_moyen
FROM SILVER.customer_demographics_clean
GROUP BY region
ORDER BY nb_clients DESC;

-- Segmentation par tranche de revenu
SELECT
    CASE
        WHEN annual_income < 50000 THEN '< 50k'
        WHEN annual_income < 100000 THEN '50k - 100k'
        WHEN annual_income < 150000 THEN '100k - 150k'
        ELSE '150k +'
    END AS tranche_revenu,
    COUNT(*) AS nb_clients,
    ROUND(AVG(annual_income), 2) AS revenu_moyen
FROM SILVER.customer_demographics_clean
GROUP BY tranche_revenu
ORDER BY nb_clients DESC;

-- Répartition par genre
SELECT
    gender,
    COUNT(*) AS nb_clients,
    ROUND(AVG(annual_income), 2) AS revenu_moyen
FROM SILVER.customer_demographics_clean
GROUP BY gender
ORDER BY nb_clients DESC;

-- Répartition par statut marital
SELECT
    marital_status,
    COUNT(*) AS nb_clients,
    ROUND(AVG(annual_income), 2) AS revenu_moyen
FROM SILVER.customer_demographics_clean
GROUP BY marital_status
ORDER BY nb_clients DESC;

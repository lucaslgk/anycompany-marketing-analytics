-- campaign_performance.sql
-- Mesure de l'efficacité des campagnes marketing

USE DATABASE ANYCOMPANY_LAB;

-- Performance des campagnes individuelles
SELECT
    campaign_id,
    campaign_name,
    campaign_type,
    product_category,
    target_audience,
    region,
    budget,
    reach,
    conversion_rate,
    ROUND(reach * conversion_rate, 0) AS conversions_estimees,
    ROUND(budget / NULLIF(reach * conversion_rate, 0), 2) AS cout_par_conversion,
    ROUND(budget / NULLIF(reach, 0) * 1000, 2) AS cout_pour_1000_impressions
FROM SILVER.marketing_campaigns_clean
ORDER BY cout_par_conversion ASC;

-- Performance moyenne par type de campagne
SELECT
    campaign_type,
    COUNT(*) AS nb_campagnes,
    ROUND(AVG(budget), 2) AS budget_moyen,
    ROUND(AVG(reach), 0) AS reach_moyen,
    ROUND(AVG(conversion_rate), 4) AS taux_conversion_moyen,
    ROUND(AVG(reach * conversion_rate), 0) AS conversions_estimees_moy,
    ROUND(AVG(budget / NULLIF(reach * conversion_rate, 0)), 2) AS cout_par_conversion_moyen
FROM SILVER.marketing_campaigns_clean
GROUP BY campaign_type
ORDER BY cout_par_conversion_moyen ASC;

-- Performance par catégorie de produit
SELECT
    product_category,
    COUNT(*) AS nb_campagnes,
    ROUND(AVG(budget), 2) AS budget_moyen,
    ROUND(AVG(reach), 0) AS reach_moyen,
    ROUND(AVG(conversion_rate), 4) AS taux_conversion_moyen,
    ROUND(SUM(reach * conversion_rate), 0) AS conversions_estimees_total,
    ROUND(SUM(budget), 2) AS budget_total,
    ROUND(SUM(budget) / NULLIF(SUM(reach * conversion_rate), 0), 2) AS cout_par_conversion_global
FROM SILVER.marketing_campaigns_clean
GROUP BY product_category
ORDER BY cout_par_conversion_global ASC;

-- Performance par région
SELECT
    region,
    COUNT(*) AS nb_campagnes,
    ROUND(AVG(budget), 2) AS budget_moyen,
    ROUND(AVG(reach), 0) AS reach_moyen,
    ROUND(AVG(conversion_rate), 4) AS taux_conversion_moyen,
    ROUND(SUM(reach * conversion_rate), 0) AS conversions_estimees_total,
    ROUND(SUM(budget) / NULLIF(SUM(reach * conversion_rate), 0), 2) AS cout_par_conversion_global
FROM SILVER.marketing_campaigns_clean
GROUP BY region
ORDER BY cout_par_conversion_global ASC;

-- Croisement type × catégorie
SELECT
    campaign_type,
    product_category,
    COUNT(*) AS nb_campagnes,
    ROUND(AVG(conversion_rate), 4) AS taux_conversion_moyen,
    ROUND(SUM(budget) / NULLIF(SUM(reach * conversion_rate), 0), 2) AS cout_par_conversion_global
FROM SILVER.marketing_campaigns_clean
GROUP BY campaign_type, product_category
ORDER BY cout_par_conversion_global ASC;

-- Lien avec les ventes (jointure region + date)
-- Même limitation que les promos: les ventes matchées ne sont pas nécessairement dues à la campagne
SELECT
    mc.campaign_id,
    mc.campaign_name,
    mc.campaign_type,
    mc.product_category AS categorie_campagne,
    mc.region,
    mc.budget,
    mc.reach,
    mc.conversion_rate,
    ROUND(mc.reach * mc.conversion_rate, 0) AS conversions_estimees,
    COUNT(ft.transaction_id) AS nb_ventes_region,
    ROUND(SUM(ft.amount), 2) AS ca_ventes_region,
    ROUND(SUM(ft.amount) / NULLIF(mc.budget, 0), 2) AS ratio_ca_sur_budget
FROM SILVER.marketing_campaigns_clean mc
LEFT JOIN SILVER.financial_transactions_clean ft
    ON ft.region = mc.region
    AND ft.transaction_date BETWEEN mc.start_date AND mc.end_date
    AND ft.transaction_type = 'Sale'
GROUP BY mc.campaign_id, mc.campaign_name, mc.campaign_type, mc.product_category,
         mc.region, mc.budget, mc.reach, mc.conversion_rate
ORDER BY ratio_ca_sur_budget DESC NULLS LAST;

-- CA quotidien moyen: mois avec campagne vs sans campagne
WITH mois_avec_campagne AS (
    SELECT DISTINCT
        region,
        DATE_TRUNC('MONTH', start_date) AS mois
    FROM SILVER.marketing_campaigns_clean
),
ventes_par_mois AS (
    SELECT
        region,
        DATE_TRUNC('MONTH', transaction_date) AS mois,
        ROUND(SUM(amount), 2) AS ca_mois,
        COUNT(DISTINCT transaction_date) AS nb_jours
    FROM SILVER.financial_transactions_clean
    WHERE transaction_type = 'Sale'
      AND transaction_date >= '2010-01-01'
      AND transaction_date <= '2018-01-11'
    GROUP BY region, mois
)
SELECT
    v.region,
    v.mois,
    CASE WHEN mc.mois IS NOT NULL THEN 'Avec campagne' ELSE 'Sans campagne' END AS statut_campagne,
    v.ca_mois,
    v.nb_jours,
    ROUND(v.ca_mois / NULLIF(v.nb_jours, 0), 2) AS ca_par_jour
FROM ventes_par_mois v
LEFT JOIN mois_avec_campagne mc
    ON v.region = mc.region AND v.mois = mc.mois
ORDER BY v.region, v.mois;

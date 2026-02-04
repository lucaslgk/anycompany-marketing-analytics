-- promotion_impact.sql
-- Analyse de l'impact des promotions sur les ventes

USE DATABASE ANYCOMPANY_LAB;

-- CA généré pendant chaque promotion
-- Note: on join uniquement sur region + date car les ventes n'ont pas de product_category
-- donc le CA n'est pas filtré par catégorie de produit
SELECT
    p.promotion_id,
    p.product_category AS categorie_promo,
    p.promotion_type,
    p.discount_percentage,
    p.region,
    p.start_date,
    p.end_date,
    COUNT(ft.transaction_id) AS nb_ventes,
    ROUND(SUM(ft.amount), 2) AS ca_pendant_promo
FROM SILVER.promotions_clean p
LEFT JOIN SILVER.financial_transactions_clean ft
    ON ft.region = p.region
    AND ft.transaction_date BETWEEN p.start_date AND p.end_date
    AND ft.transaction_type = 'Sale'
WHERE p.end_date <= '2023-12-31'  -- fenêtre de chevauchement avec les ventes
  AND p.region IN ('Africa', 'Asia', 'Europe', 'Middle East and North Africa',
                   'North America', 'Oceania', 'South America')
GROUP BY p.promotion_id, p.product_category, p.promotion_type,
         p.discount_percentage, p.region, p.start_date, p.end_date
ORDER BY ca_pendant_promo DESC NULLS LAST;

-- Comparaison CA moyen par jour: mois avec promo vs sans promo
WITH mois_avec_promo AS (
    SELECT DISTINCT
        p.region,
        DATE_TRUNC('MONTH', p.start_date) AS mois
    FROM SILVER.promotions_clean p
    WHERE p.end_date <= '2023-12-31'
      AND p.region IN ('Africa', 'Asia', 'Europe', 'Middle East and North Africa',
                       'North America', 'Oceania', 'South America')
),
ventes_par_mois AS (
    SELECT
        region,
        DATE_TRUNC('MONTH', transaction_date) AS mois,
        ROUND(SUM(amount), 2) AS ca_mois,
        COUNT(DISTINCT transaction_date) AS nb_jours
    FROM SILVER.financial_transactions_clean
    WHERE transaction_type = 'Sale'
      AND transaction_date >= '2020-01-01'
      AND transaction_date <= '2023-12-31'
    GROUP BY region, mois
)
SELECT
    v.region,
    v.mois,
    CASE WHEN mp.mois IS NOT NULL THEN 'Avec promo' ELSE 'Sans promo' END AS statut_promo,
    v.ca_mois,
    v.nb_jours,
    ROUND(v.ca_mois / NULLIF(v.nb_jours, 0), 2) AS ca_par_jour
FROM ventes_par_mois v
LEFT JOIN mois_avec_promo mp
    ON v.region = mp.region AND v.mois = mp.mois
ORDER BY v.region, v.mois;

-- Sensibilité par tranche de discount
SELECT
    CASE
        WHEN p.discount_percentage <= 0.10 THEN '0-10%'
        WHEN p.discount_percentage <= 0.20 THEN '10-20%'
        ELSE '> 20%'
    END AS tranche_discount,
    COUNT(DISTINCT p.promotion_id) AS nb_promotions,
    COUNT(ft.transaction_id) AS nb_ventes,
    ROUND(SUM(ft.amount), 2) AS ca_total,
    ROUND(AVG(ft.amount), 2) AS panier_moyen
FROM SILVER.promotions_clean p
LEFT JOIN SILVER.financial_transactions_clean ft
    ON ft.region = p.region
    AND ft.transaction_date BETWEEN p.start_date AND p.end_date
    AND ft.transaction_type = 'Sale'
WHERE p.end_date <= '2023-12-31'
  AND p.region IN ('Africa', 'Asia', 'Europe', 'Middle East and North Africa',
                   'North America', 'Oceania', 'South America')
GROUP BY tranche_discount
ORDER BY ca_total DESC;

-- Nombre de promos actives par région et par mois
WITH mois_promos AS (
    SELECT
        DATE_TRUNC('MONTH', DATEADD('day', n.value::INT, p.start_date)) AS mois,
        p.region,
        p.promotion_id
    FROM SILVER.promotions_clean p,
         TABLE(FLATTEN(INPUT => ARRAY_GENERATE_RANGE(0, DATEDIFF('day', p.start_date, p.end_date)))) n
    WHERE p.region IN ('Africa', 'Asia', 'Europe', 'Middle East and North Africa',
                       'North America', 'Oceania', 'South America')
)
SELECT
    mois,
    region,
    COUNT(DISTINCT promotion_id) AS nb_promos_actives
FROM mois_promos
GROUP BY mois, region
ORDER BY mois, region;

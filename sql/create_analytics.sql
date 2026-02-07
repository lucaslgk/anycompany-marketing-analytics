-- create_analytics.sql
-- Phase 3: Création du Data Product - Tables analytiques enrichies
-- Ces tables combinent plusieurs sources SILVER pour faciliter l'analyse

USE DATABASE ANYCOMPANY_LAB;

-- Création du schéma ANALYTICS
CREATE SCHEMA IF NOT EXISTS ANALYTICS;

-- ============================================================
-- TABLE 1: VENTES_ENRICHIES
-- Objectif: Chaque vente avec contexte marketing (promos + campagnes actives)
-- ============================================================

CREATE OR REPLACE TABLE ANALYTICS.ventes_enrichies AS
WITH promos_actives AS (
    -- Pour chaque vente, on identifie les promos actives dans la région
    SELECT
        ft.transaction_id,
        COUNT(DISTINCT p.promotion_id) AS nb_promos_actives,
        MAX(p.discount_percentage) AS discount_max,
        LISTAGG(DISTINCT p.product_category, ', ') AS categories_promo
    FROM SILVER.financial_transactions_clean ft
    LEFT JOIN SILVER.promotions_clean p
        ON ft.region = p.region
        AND ft.transaction_date BETWEEN p.start_date AND p.end_date
        AND p.region IN ('Africa', 'Asia', 'Europe', 'Middle East and North Africa',
                         'North America', 'Oceania', 'South America')
    WHERE ft.transaction_type = 'Sale'
    GROUP BY ft.transaction_id
),
campagnes_actives AS (
    -- Pour chaque vente, on identifie les campagnes actives dans la région
    SELECT
        ft.transaction_id,
        COUNT(DISTINCT mc.campaign_id) AS nb_campagnes_actives,
        SUM(mc.budget) AS budget_campagnes,
        SUM(mc.reach) AS reach_total
    FROM SILVER.financial_transactions_clean ft
    LEFT JOIN SILVER.marketing_campaigns_clean mc
        ON ft.region = mc.region
        AND ft.transaction_date BETWEEN mc.start_date AND mc.end_date
    WHERE ft.transaction_type = 'Sale'
    GROUP BY ft.transaction_id
)
SELECT
    ft.transaction_id,
    ft.transaction_date,
    ft.amount,
    ft.payment_method,
    ft.region,
    ft.entity,
    ft.account_code,
    -- Indicateurs promotions
    COALESCE(pa.nb_promos_actives, 0) AS nb_promos_actives,
    CASE WHEN COALESCE(pa.nb_promos_actives, 0) > 0 THEN 'Oui' ELSE 'Non' END AS promo_active,
    pa.discount_max,
    pa.categories_promo,
    -- Indicateurs campagnes
    COALESCE(ca.nb_campagnes_actives, 0) AS nb_campagnes_actives,
    CASE WHEN COALESCE(ca.nb_campagnes_actives, 0) > 0 THEN 'Oui' ELSE 'Non' END AS campagne_active,
    COALESCE(ca.budget_campagnes, 0) AS budget_campagnes,
    COALESCE(ca.reach_total, 0) AS reach_campagnes,
    -- Dimensions temporelles
    DATE_TRUNC('MONTH', ft.transaction_date) AS mois,
    DATE_TRUNC('QUARTER', ft.transaction_date) AS trimestre,
    EXTRACT(YEAR FROM ft.transaction_date) AS annee
FROM SILVER.financial_transactions_clean ft
LEFT JOIN promos_actives pa ON ft.transaction_id = pa.transaction_id
LEFT JOIN campagnes_actives ca ON ft.transaction_id = ca.transaction_id
WHERE ft.transaction_type = 'Sale';

-- ============================================================
-- TABLE 2: PERFORMANCE_MARKETING
-- Objectif: Agrégation mensuelle région par région du CA et efforts marketing
-- ============================================================

CREATE OR REPLACE TABLE ANALYTICS.performance_marketing AS
WITH ventes_mois AS (
    SELECT
        DATE_TRUNC('MONTH', transaction_date) AS mois,
        region,
        COUNT(*) AS nb_ventes,
        ROUND(SUM(amount), 2) AS ca_total,
        ROUND(AVG(amount), 2) AS panier_moyen
    FROM SILVER.financial_transactions_clean
    WHERE transaction_type = 'Sale'
    GROUP BY mois, region
),
promos_mois AS (
    -- Compte le nombre de promos actives par mois et région
    SELECT
        DATE_TRUNC('MONTH', start_date) AS mois,
        region,
        COUNT(DISTINCT promotion_id) AS nb_promos,
        AVG(discount_percentage) AS discount_moyen
    FROM SILVER.promotions_clean
    WHERE region IN ('Africa', 'Asia', 'Europe', 'Middle East and North Africa',
                     'North America', 'Oceania', 'South America')
    GROUP BY mois, region
),
campagnes_mois AS (
    -- Budget et reach des campagnes par mois et région
    SELECT
        DATE_TRUNC('MONTH', start_date) AS mois,
        region,
        COUNT(DISTINCT campaign_id) AS nb_campagnes,
        ROUND(SUM(budget), 2) AS budget_total,
        SUM(reach) AS reach_total,
        ROUND(SUM(reach * conversion_rate), 0) AS conversions_estimees
    FROM SILVER.marketing_campaigns_clean
    GROUP BY mois, region
)
SELECT
    v.mois,
    v.region,
    v.nb_ventes,
    v.ca_total,
    v.panier_moyen,
    COALESCE(p.nb_promos, 0) AS nb_promos_actives,
    COALESCE(p.discount_moyen, 0) AS discount_moyen,
    COALESCE(c.nb_campagnes, 0) AS nb_campagnes_actives,
    COALESCE(c.budget_total, 0) AS budget_marketing,
    COALESCE(c.reach_total, 0) AS reach_total,
    COALESCE(c.conversions_estimees, 0) AS conversions_estimees,
    -- ROI approximatif
    CASE 
        WHEN COALESCE(c.budget_total, 0) > 0 
        THEN ROUND(v.ca_total / c.budget_total, 2)
        ELSE NULL
    END AS ratio_ca_budget
FROM ventes_mois v
LEFT JOIN promos_mois p ON v.mois = p.mois AND v.region = p.region
LEFT JOIN campagnes_mois c ON v.mois = c.mois AND v.region = c.region
ORDER BY v.mois, v.region;

-- ============================================================
-- TABLE 3A: INDICATEURS_CLIENTS_REGION
-- Démographie client par région uniquement
-- ============================================================

CREATE OR REPLACE TABLE ANALYTICS.indicateurs_clients_region AS
SELECT
    region,
    COUNT(*) AS nb_clients,
    ROUND(AVG(annual_income), 2) AS revenu_moyen,
    ROUND(COUNT(CASE WHEN gender = 'Female' THEN 1 END) * 100.0 / COUNT(*), 1) AS pct_femmes,
    ROUND(COUNT(CASE WHEN gender = 'Male' THEN 1 END) * 100.0 / COUNT(*), 1) AS pct_hommes,
    ROUND(COUNT(CASE WHEN marital_status = 'Married' THEN 1 END) * 100.0 / COUNT(*), 1) AS pct_maries,
    ROUND(COUNT(CASE WHEN marital_status = 'Single' THEN 1 END) * 100.0 / COUNT(*), 1) AS pct_celibataires
FROM SILVER.customer_demographics_clean
GROUP BY region;

-- ============================================================
-- TABLE 3B: SATISFACTION_SERVICE_CLIENT
-- Statistiques globales de satisfaction (pas de dimension région car la table source n'a pas cette info)
-- ============================================================

CREATE OR REPLACE TABLE ANALYTICS.satisfaction_service_client AS
SELECT
    COUNT(*) AS nb_interactions_total,
    ROUND(AVG(customer_satisfaction), 2) AS satisfaction_moyenne,
    ROUND(AVG(duration_minutes), 1) AS duree_moyenne_min,
    -- Résolution
    COUNT(CASE WHEN resolution_status = 'Resolved' THEN 1 END) AS nb_resolus,
    COUNT(CASE WHEN resolution_status = 'Pending' THEN 1 END) AS nb_pending,
    COUNT(CASE WHEN resolution_status = 'Escalated' THEN 1 END) AS nb_escalated,
    ROUND(COUNT(CASE WHEN resolution_status = 'Resolved' THEN 1 END) * 100.0 / COUNT(*), 1) AS taux_resolution_pct,
    -- Canaux
    COUNT(CASE WHEN interaction_type = 'Phone' THEN 1 END) AS nb_phone,
    COUNT(CASE WHEN interaction_type = 'Email' THEN 1 END) AS nb_email,
    COUNT(CASE WHEN interaction_type = 'Chat' THEN 1 END) AS nb_chat,
    -- Catégories de problèmes
    COUNT(CASE WHEN issue_category = 'Complaints' THEN 1 END) AS nb_complaints,
    COUNT(CASE WHEN issue_category = 'Returns' THEN 1 END) AS nb_returns,
    COUNT(CASE WHEN issue_category = 'Product Inquiry' THEN 1 END) AS nb_inquiries
FROM SILVER.customer_service_interactions_clean;

-- ============================================================
-- TABLE 4: NOTES_PRODUITS_REF
-- Notes et avis par catégorie de produit organique
-- ============================================================

CREATE OR REPLACE TABLE ANALYTICS.notes_produits_ref AS
SELECT
    product_category,
    COUNT(*) AS nb_avis,
    ROUND(AVG(rating), 2) AS note_moyenne,
    MIN(rating) AS note_min,
    MAX(rating) AS note_max,
    COUNT(CASE WHEN rating >= 4 THEN 1 END) AS nb_avis_positifs,
    COUNT(CASE WHEN rating <= 2 THEN 1 END) AS nb_avis_negatifs
FROM SILVER.product_reviews_clean
GROUP BY product_category;

-- ============================================================
-- VERIFICATION DES TABLES CREEES
-- ============================================================

-- Vérification volumes
SELECT 'ventes_enrichies' AS table_name, COUNT(*) AS nb_lignes 
FROM ANALYTICS.ventes_enrichies
UNION ALL
SELECT 'performance_marketing', COUNT(*) 
FROM ANALYTICS.performance_marketing
UNION ALL
SELECT 'indicateurs_clients_region', COUNT(*) 
FROM ANALYTICS.indicateurs_clients_region
UNION ALL
SELECT 'satisfaction_service_client', COUNT(*) 
FROM ANALYTICS.satisfaction_service_client
UNION ALL
SELECT 'notes_produits_ref', COUNT(*) 
FROM ANALYTICS.notes_produits_ref;

-- logistics_operations.sql
-- Analyse des ruptures de stock, délais de livraison et fiabilité fournisseurs

USE DATABASE ANYCOMPANY_LAB;

-- ============================================================
-- PARTIE A: RUPTURES DE STOCK
-- ============================================================

-- Produits en alerte (stock <= reorder_point)
SELECT
    product_id,
    product_category,
    region,
    country,
    warehouse,
    current_stock,
    reorder_point,
    lead_time,
    last_restock_date,
    (current_stock - reorder_point) AS marge_stock
FROM SILVER.inventory_clean
WHERE current_stock <= reorder_point
ORDER BY marge_stock ASC, product_category, region;

-- Synthèse tensions par catégorie et région
SELECT
    product_category,
    region,
    COUNT(*) AS nb_produits_total,
    SUM(CASE WHEN current_stock <= reorder_point THEN 1 ELSE 0 END) AS nb_produits_en_alerte,
    ROUND(SUM(CASE WHEN current_stock <= reorder_point THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS taux_alerte_pct,
    ROUND(AVG(current_stock), 0) AS stock_moyen,
    ROUND(AVG(reorder_point), 0) AS reorder_moyen
FROM SILVER.inventory_clean
GROUP BY product_category, region
ORDER BY taux_alerte_pct DESC;

-- Catégories les plus exposées (vue globale)
SELECT
    product_category,
    COUNT(*) AS nb_produits,
    SUM(CASE WHEN current_stock <= reorder_point THEN 1 ELSE 0 END) AS nb_en_alerte,
    ROUND(SUM(CASE WHEN current_stock <= reorder_point THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS taux_alerte_pct,
    ROUND(AVG(current_stock), 0) AS stock_moyen,
    ROUND(AVG(lead_time), 1) AS lead_time_moy_jours
FROM SILVER.inventory_clean
GROUP BY product_category
ORDER BY taux_alerte_pct DESC;

-- ============================================================
-- PARTIE B: DELAIS ET COUTS DE LIVRAISON
-- ============================================================

-- Délai et coût par méthode d'expédition
SELECT
    shipping_method,
    status,
    COUNT(*) AS nb_livraisons,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY shipping_method), 1) AS part_dans_methode_pct,
    ROUND(AVG(DATEDIFF('day', ship_date, estimated_delivery)), 1) AS delai_estim_moy_jours,
    ROUND(AVG(shipping_cost), 2) AS cout_moy
FROM SILVER.logistics_and_shipping_clean
GROUP BY shipping_method, status
ORDER BY shipping_method, nb_livraisons DESC;

-- Coût par méthode et région
SELECT
    shipping_method,
    destination_region,
    COUNT(*) AS nb_livraisons,
    ROUND(AVG(shipping_cost), 2) AS cout_moy,
    ROUND(MIN(shipping_cost), 2) AS cout_min,
    ROUND(MAX(shipping_cost), 2) AS cout_max,
    ROUND(AVG(DATEDIFF('day', ship_date, estimated_delivery)), 1) AS delai_estim_moy_jours
FROM SILVER.logistics_and_shipping_clean
GROUP BY shipping_method, destination_region
ORDER BY cout_moy DESC;

-- Taux de retour par méthode et région
SELECT
    shipping_method,
    destination_region,
    COUNT(*) AS nb_livraisons_total,
    COUNT(CASE WHEN status = 'Returned' THEN 1 END) AS nb_retours,
    ROUND(COUNT(CASE WHEN status = 'Returned' THEN 1 END) * 100.0 / COUNT(*), 1) AS taux_retour_pct,
    ROUND(AVG(shipping_cost), 2) AS cout_moy
FROM SILVER.logistics_and_shipping_clean
GROUP BY shipping_method, destination_region
HAVING COUNT(*) >= 10
ORDER BY taux_retour_pct DESC;

-- Evolution annuelle volume et coûts
SELECT
    EXTRACT(YEAR FROM ship_date) AS annee,
    COUNT(*) AS nb_livraisons,
    ROUND(AVG(shipping_cost), 2) AS cout_moy,
    ROUND(SUM(shipping_cost), 2) AS cout_total,
    COUNT(CASE WHEN status = 'Returned' THEN 1 END) AS nb_retours,
    ROUND(COUNT(CASE WHEN status = 'Returned' THEN 1 END) * 100.0 / COUNT(*), 1) AS taux_retour_pct
FROM SILVER.logistics_and_shipping_clean
GROUP BY annee
ORDER BY annee;

-- ============================================================
-- PARTIE C: FIABILITE DES FOURNISSEURS
-- ============================================================

-- Fiabilité par catégorie et région (avec tensions stock)
SELECT
    si.product_category,
    si.region,
    COUNT(DISTINCT si.supplier_id) AS nb_fournisseurs,
    ROUND(AVG(si.reliability_score), 2) AS reliability_moy,
    ROUND(AVG(si.lead_time), 1) AS lead_time_fournisseur_moy,
    COUNT(DISTINCT inv.product_id) AS nb_produits_inventaire,
    SUM(CASE WHEN inv.current_stock <= inv.reorder_point THEN 1 ELSE 0 END) AS nb_produits_en_alerte
FROM SILVER.supplier_information_clean si
LEFT JOIN SILVER.inventory_clean inv
    ON si.product_category = inv.product_category AND si.region = inv.region
GROUP BY si.product_category, si.region
ORDER BY reliability_moy ASC;

-- Fournisseurs à faible fiabilité (< 0.75)
SELECT
    supplier_id,
    supplier_name,
    product_category,
    region,
    country,
    lead_time,
    reliability_score,
    quality_rating
FROM SILVER.supplier_information_clean
WHERE reliability_score < 0.75
ORDER BY reliability_score ASC, product_category, region;

-- Synthèse par niveau de qualité
SELECT
    quality_rating,
    COUNT(*) AS nb_fournisseurs,
    ROUND(AVG(reliability_score), 2) AS reliability_moy,
    ROUND(AVG(lead_time), 1) AS lead_time_moy
FROM SILVER.supplier_information_clean
GROUP BY quality_rating
ORDER BY quality_rating;

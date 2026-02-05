-- customer_experience.sql
-- Analyse des avis produits et interactions service client

USE DATABASE ANYCOMPANY_LAB;

-- ============================================================
-- PARTIE A: AVIS PRODUITS
-- ============================================================

-- Note moyenne par catégorie
SELECT
    product_category,
    COUNT(*) AS nb_avis,
    ROUND(AVG(rating), 2) AS note_moyenne,
    MIN(rating) AS note_min,
    MAX(rating) AS note_max,
    ROUND(STDDEV(rating), 2) AS ecart_type
FROM SILVER.product_reviews_clean
GROUP BY product_category
ORDER BY note_moyenne DESC;

-- Distribution des notes (1 à 5 étoiles)
SELECT
    product_category,
    rating,
    COUNT(*) AS nb_avis,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY product_category), 1) AS part_pct
FROM SILVER.product_reviews_clean
GROUP BY product_category, rating
ORDER BY product_category, rating;

-- Evolution de la note moyenne dans le temps
SELECT
    DATE_TRUNC('QUARTER', review_date) AS trimestre,
    product_category,
    COUNT(*) AS nb_avis,
    ROUND(AVG(rating), 2) AS note_moyenne
FROM SILVER.product_reviews_clean
GROUP BY trimestre, product_category
ORDER BY trimestre, product_category;

-- Produits mal notés (< 3) - signaux d'alerte
SELECT
    product_id,
    product_category,
    COUNT(*) AS nb_avis,
    ROUND(AVG(rating), 2) AS note_moyenne,
    MIN(review_date) AS premier_avis,
    MAX(review_date) AS dernier_avis
FROM SILVER.product_reviews_clean
GROUP BY product_id, product_category
HAVING AVG(rating) < 3
ORDER BY note_moyenne ASC, nb_avis DESC;

-- Produits bien notés (>= 4, min 5 avis) - à promouvoir
SELECT
    product_id,
    product_category,
    COUNT(*) AS nb_avis,
    ROUND(AVG(rating), 2) AS note_moyenne
FROM SILVER.product_reviews_clean
GROUP BY product_id, product_category
HAVING AVG(rating) >= 4 AND COUNT(*) >= 5
ORDER BY note_moyenne DESC, nb_avis DESC;

-- ============================================================
-- PARTIE B: SERVICE CLIENT
-- ============================================================

-- Volume et satisfaction par type de problème
SELECT
    issue_category,
    COUNT(*) AS nb_interactions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS part_pct,
    ROUND(AVG(customer_satisfaction), 2) AS satisfaction_moy,
    ROUND(AVG(duration_minutes), 1) AS duree_moy_minutes
FROM SILVER.customer_service_interactions_clean
GROUP BY issue_category
ORDER BY nb_interactions DESC;

-- Satisfaction selon le statut de résolution
SELECT
    resolution_status,
    COUNT(*) AS nb_interactions,
    ROUND(AVG(customer_satisfaction), 2) AS satisfaction_moy,
    ROUND(AVG(duration_minutes), 1) AS duree_moy_minutes
FROM SILVER.customer_service_interactions_clean
GROUP BY resolution_status
ORDER BY satisfaction_moy ASC;

-- Satisfaction par canal (Chat, Email, Phone)
SELECT
    interaction_type,
    COUNT(*) AS nb_interactions,
    ROUND(AVG(customer_satisfaction), 2) AS satisfaction_moy,
    ROUND(AVG(duration_minutes), 1) AS duree_moy_minutes
FROM SILVER.customer_service_interactions_clean
GROUP BY interaction_type
ORDER BY satisfaction_moy DESC;

-- Croisement problème × statut résolution
SELECT
    issue_category,
    resolution_status,
    COUNT(*) AS nb_interactions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY issue_category), 1) AS part_dans_categorie_pct,
    ROUND(AVG(customer_satisfaction), 2) AS satisfaction_moy
FROM SILVER.customer_service_interactions_clean
GROUP BY issue_category, resolution_status
ORDER BY issue_category, resolution_status;

-- Evolution temporelle (trimestrielle)
SELECT
    DATE_TRUNC('QUARTER', interaction_date) AS trimestre,
    COUNT(*) AS nb_interactions,
    ROUND(AVG(customer_satisfaction), 2) AS satisfaction_moy,
    ROUND(AVG(duration_minutes), 1) AS duree_moy_minutes,
    COUNT(CASE WHEN resolution_status = 'Escalated' THEN 1 END) AS nb_escalades,
    ROUND(COUNT(CASE WHEN resolution_status = 'Escalated' THEN 1 END) * 100.0 / COUNT(*), 1) AS taux_escalade_pct
FROM SILVER.customer_service_interactions_clean
GROUP BY trimestre
ORDER BY trimestre;

-- Problèmes les plus longs à résoudre
SELECT
    issue_category,
    interaction_type,
    resolution_status,
    ROUND(AVG(duration_minutes), 1) AS duree_moy_minutes,
    COUNT(*) AS nb_interactions,
    ROUND(AVG(customer_satisfaction), 2) AS satisfaction_moy
FROM SILVER.customer_service_interactions_clean
GROUP BY issue_category, interaction_type, resolution_status
ORDER BY duree_moy_minutes DESC
LIMIT 15;

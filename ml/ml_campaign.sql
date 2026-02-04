----------------------------------------------------------------
-- TABLE ML_RAW: Données brutes pour ML
-- Objectif: On utilise cette base pour le modèle de prédiction du conversion_rate des campagnes marketing
-----------------------------------------------------------------

CREATE OR REPLACE TABLE ANALYTICS.ml_campaign_raw AS
SELECT 
    mc.campaign_id,
    mc.campaign_name,
    mc.campaign_type,
    mc.product_category,
    mc.target_audience,
    mc.start_date,
    mc.end_date,
    mc.region,
    mc.budget,
    mc.reach,
    mc.conversion_rate,

    EXTRACT(YEAR FROM mc.start_date) AS annee,
    EXTRACT(MONTH FROM mc.start_date) AS mois,
    EXTRACT(QUARTER FROM mc.start_date) AS trimestre,
    EXTRACT(DOW FROM mc.start_date) AS jour_semaine, -- 0=dimanche, 6=samedi
    DATEDIFF(day, mc.start_date, mc.end_date) AS duree_campagne_jours,
    DATE_TRUNC('month', mc.start_date) AS mois_debut,

    mc.budget / NULLIF(mc.reach, 0) AS budget_per_reach, -- coût par personne touchée

    icr.nb_clients AS nb_clients_region,
    icr.revenu_moyen AS revenu_moyen_region,
    icr.pct_femmes,
    icr.pct_hommes,
    icr.pct_maries,
    icr.pct_celibataires,

    pm.nb_ventes AS nb_ventes_region_mois,
    pm.ca_total AS ca_region_mois,
    pm.panier_moyen AS panier_moyen_region_mois,

    pm.nb_promos_actives AS nb_promos_region_mois,
    pm.discount_moyen AS discount_moyen_region_mois,

    pm.nb_campagnes_actives AS nb_autres_campagnes_mois,
    pm.budget_marketing AS budget_total_region_mois,
    pm.reach_total AS reach_total_region_mois

FROM SILVER.marketing_campaigns_clean mc
LEFT JOIN ANALYTICS.indicateurs_clients_region icr
    ON mc.region = icr.region
LEFT JOIN ANALYTICS.performance_marketing pm
    ON mc.region = pm.region
    AND DATE_TRUNC('month', mc.start_date) = pm.mois

WHERE mc.conversion_rate IS NOT NULL
  AND mc.budget > 0
  AND mc.reach > 0;
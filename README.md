# AnyCompany Food & Beverage - Marketing Analytics

[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://www.python.org/)
[![SQL](https://img.shields.io/badge/SQL-Snowflake-29B5E8.svg)](https://www.snowflake.com/)
[![Streamlit](https://img.shields.io/badge/Streamlit-1.28+-FF4B4B.svg)](https://streamlit.io/)
[![scikit-learn](https://img.shields.io/badge/scikit--learn-1.3+-F7931E.svg)](https://scikit-learn.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> **Projet MBA Big Data & IA - Architecture Big Data 2025-2026**  
> Optimisation de la stratégie marketing data-driven pour AnyCompany Food & Beverage

---

## Table des matières

- [Contexte du projet](#contexte-du-projet)
- [Architecture du projet](#️architecture-du-projet)
- [Phases du projet](#phases-du-projet)
- [Constats clés](#constats-clés)
- [Installation et exécution](#installation-et-exécution)
- [Technologies utilisées](#technologies-utilisées)
- [Résultats et livrables](#résultats-et-livrables)

---

## Contexte du projet

AnyCompany Food & Beverage fait face à une **baisse de sa part de marché de 28% à 22%** en 8 mois, avec une **réduction de 30% du budget marketing**. L'objectif est d'atteindre **32% de part de marché d'ici Q4 2025** grâce à une stratégie data-driven.

Ce projet analyse 11 tables de données pour identifier les leviers d'optimisation budgétaire et améliorer l'efficacité des campagnes marketing.

---

## Architecture du projet

```
anycompany-marketing-analytics/
├── sql/
│   ├── load_data.sql           # Chargement S3 Snowflake BRONZE
│   ├── clean_data.sql          # Nettoyage BRONZE, passage en SILVER
│   ├── create_analytics.sql    # Tables analytiques enrichies
│   └── sales_trends.sql        # Analyses ventes et tendances
├── streamlit/
│   ├── app.py                  # Dashboard principal
│   ├── requirements.txt        # Dépendances pour le dashboard
│   └── pages/
│       ├── 1_Performances.py           # Performances régionales
│       ├── 2_Campagnes_Marketing.py    # Efficacité des campagnes
│       └── 3_Analyse_Machine_Learning.py  # Résultats clustering
├── ml/
│   ├── 01_conversion_rate_prediction.ipynb  # Tentative prédiction
│   ├── 02_campaigns_clustering.ipynb        # K-Means clustering
│   └── ml_insights.md                       # Insights business ML
└── README.md
```

---

## Phases du projet

### Phase 1 : Data Engineering
- **Architecture medallion** : BRONZE (données brutes), SILVER (données nettoyées), ANALYTICS (tables enrichies)
- **11 tables chargées depuis S3** : customers, campaigns, transactions, promotions, etc.
- **Nettoyage** : gestion des doublons, valeurs manquantes, cohérence dates

### Phase 2 : Analyses Business
- **Évolution des ventes** : tendances mensuelles, trimestrielles et annuelles
- **Performance régionale** : CA et panier moyen par région
- **Impact promotions** : ventes avec/sans promotions actives
- **Efficacité campagnes** : CPM, taux de conversion, ROI

### Phase 3 : Machine Learning
- **Clustering K-Means** : segmentation de 4 861 campagnes en 5 clusters
- **5 types de campagnes identifiés** :
  - Cluster 0 "Ciblé Premium" : 5.72% conversion (meilleur ROI)
  - Cluster 1 "Ultra-Premium" : 5.87% conversion (très cher)
  - Clusters 2-3 "Mass Market" : 5.52-5.53% conversion (volume)
  - Cluster 4 "Échec" : 3.96% conversion (à stopper)

---

## Constats clés

### 1. Sous-exploitation des campagnes premium
- Les campagnes "Ciblé Premium" (Cluster 0) représentent seulement **1.5% des campagnes** mais ont le **meilleur taux de conversion** (5.72%)
- **Recommandation** : passer de 1.9% à 25% du budget sur ce segment

### 2. Gaspillage budgétaire
- 3 campagnes du Cluster 4 "Échec" (3.96% conversion) à stopper immédiatement
- **Économie estimée** : 1.2M€

### 3. Opportunité de réallocation
Allocation actuelle vs recommandée :

| Type de campagne | Budget actuel | Budget cible |
|------------------|---------------|--------------|
| Ciblé Premium    | 1.9%          | 25%          |
| Ultra-Premium    | 0.4%          | 5%           |
| Mass Market      | 97.5%         | 70%          |
| Échec            | 0.1%          | 0%           |

### 4. Performance régionale variable
- Fortes disparités de CA entre régions
- Opportunités d'optimisation par zone géographique

**Détails complets dans** `ml/ml_insights.md`

---

## Installation et exécution

### Prérequis
```bash
Python 3.11+
Compte Snowflake
```

### Installation
```bash
# Cloner le repository
git clone https://github.com/lucaslgk/anycompany-marketing-analytics.git
cd anycompany-marketing-analytics

# Installer les dépendances
pip install -r streamlit/requirements.txt
```

### Exécution Snowflake
1. Exécuter dans l'ordre :
   - `sql/load_data.sql` (créer base, charger données)
   - `sql/clean_data.sql` (nettoyer données)
   - `sql/create_analytics.sql` (créer tables analytiques)
   - `sql/sales_trends.sql` (analyses exploratoires)

2. Exporter les données pour Streamlit :
   - `ANALYTICS.ventes_enrichies` → `data/analytics/ventes_enrichies.csv`
   - `ANALYTICS.indicateurs_clients_region` → `data/analytics/indicateurs_clients_region.csv`
   - `SILVER.marketing_campaigns_clean` → `data/marketing_campaigns_clean.csv`

### Lancer le dashboard Streamlit
```bash
cd streamlit
streamlit run app.py
```

### Notebooks ML
```bash
jupyter notebook ml/02_campaigns_clustering.ipynb
```

---

## Technologies utilisées

### Infrastructure Data
- **Data Warehouse** : Snowflake
- **Stockage** : AWS S3
- **Architecture** : Medallion (Bronze/Silver/Analytics)

### Langages
- **SQL** : Requêtes analytiques, ETL, data modeling
- **Python 3.11+** : Preprocessing, ML, visualisation

### Librairies Python
- **Data Processing** : pandas 2.0+, numpy
- **Machine Learning** : scikit-learn 1.3+ (K-Means, StandardScaler, PCA, t-SNE)
- **Visualisation** : Plotly, Matplotlib, Seaborn
- **Dashboard** : Streamlit 1.28+
- **Connexion DB** : snowflake-connector-python

### Outils
- **Notebooks** : Jupyter Lab
- **Version Control** : Git/GitHub
- **IDE** : VS Code

### Méthodes ML
- Clustering K-Means (5 clusters, Elbow Method)
- Réduction dimensionnelle (PCA, t-SNE)
- Évaluation : Silhouette Score, Calinski-Harabasz, Davies-Bouldin

---

## Résultats et livrables

### Livrables techniques
- **4 scripts SQL** : ETL, nettoyage, analytics, analyses
- **Dashboard Streamlit** : 4 pages interactives avec visualisations Plotly
- **2 notebooks ML** : clustering K-Means et tentative de prédiction
- **Tables Snowflake** : 11 tables SILVER + 3 tables ANALYTICS enrichies
- **Documentation ML** : insights business et recommandations actionnables

### Métriques clés
- **4 861 campagnes** analysées (2010-2017)
- **5 clusters** identifiés avec profils distincts
- **5.72%** taux de conversion max (Cluster "Ciblé Premium")
- **1.2M€** d'économies potentielles (arrêt campagnes inefficaces)
- **23% de réallocation budgétaire** recommandée

### Impact business
- Augmentation potentielle de +15-20% du ROI marketing
- Optimisation de -30% de budget sans perte d'efficacité
- Stratégie data-driven pour atteindre 32% de part de marché

---

## Équipe

- Ines HIDECHE
- Camille THAUVIN
- Lucas GOUMARD

MBA Big Data & IA - Architecture Data 2025-2026

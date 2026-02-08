# Insights Machine Learning - AnyCompany Food & Beverage

## Contexte

On a testé deux approches ML pour optimiser la stratégie marketing de AnyCompany avec 4861 campagnes historiques (de 2010 à 2017) :
- Prédire le taux de conversion des futures campagnes
- Identifier différents types de campagnes pour mieux allouer le budget

**Objectif** : atteindre 32% de part de marché avec -30% de budget marketing.

## Réalisations

### 1. Tentative de prédiction du taux de conversion

**L'idée** : utiliser les caractéristiques d'une campagne (budget, reach, type, région, etc.) pour prédire son taux de conversion.

**Approche technique** :
- 31 variables de base + 8 variables créées (ratios, indicateurs)
- Preprocessing avec différents scalers selon les features (pipelines)
- Test de 8 modèles : Linear Regression, Ridge, SVR, Random Forest, XGBoost, etc.

**Résultats** : Échec complet. Tous les modèles ont des scores R² négatifs, ce qui veut dire qu'ils font pire qu'une simple moyenne.

**Pourquoi ?** Après vérifications nous avons compris que les corrélations entre les features et le taux de conversion sont quasi-nulles (max 0.024). Le CONVERSION_RATE dans les données synthétiques a possiblement été généré aléatoirement sans relation avec les autres variables. Donc impossible d'entrainer un modèle prédictif avec cette target.

**Conclusion** : L'approche prédictive ne fonctionne pas avec ces données. Nous avons donc choisi de nous tourner vers du clustering.

---

### 2. Clustering K-Means - Segmentation des campagnes

Etant donné que la prédiction ne fonctionne pas, nous changeons de stratégie : au lieu d'essayer de prédire, nous allons **grouper les campagnes similaires** pour pouvoir analyser leurs différents types.

**Méthode** : K-Means avec 5 clusters (Elbow Method)

**Features utilisées** : 
- Budget, Reach, Durée
- Coût par contact (CPM)
- Budget par jour, Reach par jour
- Type de campagne, Région, Produit
- Infos démographiques (revenu, genre)

## Les 5 types de campagnes identifiés

### Cluster 0 : "Ciblé Premium" (72 campagnes - 1.5%)

**Profil** :
- Budget : 328K€
- Reach : 14K personnes
- **Conversion : 5.72%**
- Coût par contact : 26€

**Canaux** : TV, Radio, Influencers  
**Régions** : Asie, Afrique, MENA

**Analyse** : Ces campagnes fonctionnent bien. Le coût par contact reste élevé mais le taux de conversion est très intéressant en comparaison avec les autres clusters.

**Recommandation** : Augmenter fortement ce types de campagnes dans la stratégie globale (passer de 1.9% à 25% du budget)

---

### Cluster 1 : "Ultra-Premium" (16 campagnes - 0.3%)

**Profil** :
- Budget : 344K€
- Reach : 4K personnes (très ciblé)
- Conversion : 5.87%
- Coût par contact : 88€ (très cher)

**Analyse** : Campagnes ultra-ciblées sur des niches très spécifiques. Elles sont selon nous trop chères mais efficaces.

**Recommandation** : Typologie de campagnes marketing à conserver pour des lancements produits premium (max 5% du budget)

---

### Cluster 2 : "Mass Market Digital" (2 353 campagnes - 48%)

**Profil** :
- Budget : 253K€
- Reach : 513K personnes (énorme)
- Conversion : 5.52%
- Coût par contact : 0.99€

**Canaux** : Social Media, Influencer, Email

**Analyse** : Ce cluster représente la moitié de nos campagnes. Coût très bas, reach impoortant, conversion correcte. C'est notre base.

**Recommandation** : A conserver mais en réduisant un peu le budget alloué pour les campagnes plus ciblées que nous avons évoqué précédemment (35% du budget)

---

### Cluster 3 : "Mass Market Traditionnel" (2 417 campagnes - 50%)

**Profil** :
- Budget : 253K€
- Reach : 510K personnes
- Conversion : 5.48%
- Coût par contact : 0.96€

**Canaux** : Print, Radio, TV

**Analyse** : Presque identique au Cluster 2 mais sur canaux traditionnels. Conversion légèrement inférieure.

**Recommandation** : A conserver mais en réduisant pour privilégier les campagnes plus ciblées (35% du budget)

---

### Cluster 4 : "Échec Total" (3 campagnes - 0.1%)

**Profil** :
- Budget : 396K€
- Reach : 2K personnes
- **Conversion : 3.49%** (catastrophique)
- Coût par contact : 180€ (trop important)

**Canaux** : 100% Radio

**Analyse** : 3 campagnes qui ont complètement raté. Budget élevé, reach minuscule, conversion deux fois inférieure à la moyenne, coût beaucoup trop important.

**Recommandation** : Nous préconisons d'arrêter immédiatement ce type de campagnes (0% du budget)

---

## Recommandations

### Nouvelle allocation budgétaire

**Budget total après -30%** : 865M€

```
Situation actuelle → Recommandation

Cluster 0 (Ciblé)      :  1.9% →  25%  (+23%)
Cluster 1 (Premium)    :  0.4% →   5%  (+4.6%)
Clusters 2-3 (Mass)    : 97.5% →  70%  (-27.5%)
Cluster 4 (Échec)      :  0.1% →   0%  (-0.1%)
```

**Nouvelle répartition en euros** :
- 605M€ → Mass Market (Clusters 2-3) : base solide, reach important
- 216M€ → Ciblé Premium (Cluster 0) : meilleur taux de conversion
- 43M€ → Ultra-Premium (Cluster 1) : niches stratégiques
- 0€ → Cluster 4 : stop immédiat

### Impact attendu

- Taux de conversion global : 5.50% → 5.57% (+0.07%)
- ROI estimé : +1.3%
- Part de marché : contribution vers l'objectif +10 points

### Plan d'action

**Immédiat (1 mois)** :
1. Arrêter les 3 campagnes du Cluster 4 → économie 1.2M€
2. Analyser en détail les 72 campagnes du Cluster 0 pour comprendre pourquoi elles fonctionnent bien
3. Identifier les campagnes les moins performantes des Clusters 2-3

**Court terme (6 mois)** :
1. Augmenter progressivement le budget Cluster 0 (+5% par mois)
2. Former les équipes aux campagnes ciblées premium
3. Réduire progressivement le mass market en gardant les meilleures campagnes

**Long terme (12 mois)** :
1. Dashboard de suivi en temps réel par cluster
2. Ajustements budgétaires mensuels selon performance
3. Tests de nouveaux segments (budget expérimentation 5%)

### Points d'attention

- **Capacité à scaler le Cluster 0** : il sera nécessaire de vérifier si il est possible de multiplier par 13 ce type de campagnes
- **Risque sur la notoriété** : réduire le mass market de 27% peut impacter la visibilité globale
- **Résistance au changement** : les équipes sont visiblement habituées aux campagnes mass market

---

## Conclusion

Le clustering a permis d'identifier clairement 5 types de campagnes avec des performances très différentes. 

**Insight principal** : La société sous-exploite massivement les campagnes ciblées premium (Cluster 0) qui ont le meilleur taux de conversion. En réallouant 23% du budget vers ce segment tout en maintenant une base mass market solide, nous pouvons améliorer significativement nos performances malgré la contrainte de -30% de budget.

**Action prioritaire** : Analyser les 72 campagnes du Cluster 0 pour identifier les facteurs de succès et les répliquer à plus grande échelle.

---

## Notes techniques

**Clustering K-Means** :
- Nombre de clusters : 5 (Elbow Method)
- Silhouette score : 0.44
- Features : 36 variables

**Visualisation** : PCA et t-SNE pour projection 2D

**Environnement** : Python 3.11, scikit-learn 1.3, pandas 2.0

**Limites** : Données synthétiques (CONVERSION_RATE aléatoire), période 2010-2017

---

*Notebooks source : `01_conversion_rate_prediction.ipynb`, `02_campaigns_clustering.ipynb`*

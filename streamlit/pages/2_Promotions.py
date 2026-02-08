"""
Analyse des promotions
"""

import streamlit as st
import pandas as pd
import plotly.express as px
from pathlib import Path

st.set_page_config(page_title="Promotions", layout="wide")

DATA_PATH = Path(__file__).parent.parent.parent / "data"
ANALYTICS_PATH = DATA_PATH / "analytics"


@st.cache_data
def load_data():
    ventes = pd.read_csv(ANALYTICS_PATH / "ventes_enrichies.csv")
    promos = pd.read_csv(DATA_PATH / "promotions_clean.csv")
    return ventes, promos


def main():
    st.title("Impact des Promotions")

    ventes, promos = load_data()

    # KPIs
    col1, col2, col3 = st.columns(3)

    ventes_promo = ventes[ventes['PROMO_ACTIVE'] == 'Oui']
    ventes_sans = ventes[ventes['PROMO_ACTIVE'] == 'Non']

    with col1:
        st.metric("Nombre de Promotions", len(promos))
    with col2:
        pct_promo = len(ventes_promo) / len(ventes) * 100
        st.metric("% Ventes avec promotion", f"{pct_promo:.1f}%")
    with col3:
        discount_moy = promos['DISCOUNT_PERCENTAGE'].mean() * 100
        st.metric("Réduction moyenne", f"{discount_moy:.1f}%")

    st.markdown("---")

    # Comparaison avec/sans promo
    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Panier moyen")

        panier_avec = ventes_promo['AMOUNT'].mean()
        panier_sans = ventes_sans['AMOUNT'].mean()

        fig = px.bar(
            x=['Sans promo', 'Avec promo'],
            y=[panier_sans, panier_avec],
            color=['Sans promo', 'Avec promo']
        )
        fig.update_layout(height=300, showlegend=False)
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.subheader("Répartition des ventes")

        fig = px.pie(
            values=[len(ventes_sans), len(ventes_promo)],
            names=['Sans promo', 'Avec promo'],
            hole=0.4
        )
        fig.update_layout(height=300)
        st.plotly_chart(fig, use_container_width=True)

    st.markdown("---")

    # Promos par categorie
    st.subheader("Promotions par categorie de produit")

    cat_stats = promos.groupby('PRODUCT_CATEGORY').agg({
        'DISCOUNT_PERCENTAGE': 'mean',
        'PROMOTION_ID': 'count'
    }).reset_index()
    cat_stats.columns = ['Categorie', 'Reduction', 'Nombre']
    cat_stats['Reduction'] = cat_stats['Reduction'] * 100

    fig = px.bar(cat_stats, x='Categorie', y='Nombre', color='Reduction')
    fig.update_layout(height=350)
    st.plotly_chart(fig, use_container_width=True)


if __name__ == "__main__":
    main()

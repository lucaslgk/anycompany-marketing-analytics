"""
Resultats du clustering K-Means
"""

import streamlit as st
import pandas as pd
import plotly.express as px
from pathlib import Path

st.set_page_config(page_title="Clustering ML", layout="wide")

DATA_PATH = Path(__file__).parent.parent.parent / "data"
ML_PATH = DATA_PATH / "ml"


@st.cache_data
def load_data():
    df = pd.read_csv(ML_PATH / "campaigns_clustered.csv")
    return df


def main():
    st.title("Segmentation des Campagnes (K-Means)")

    st.markdown("""
    Résultats du clustering realisé dans le notebook `02_campaigns_clustering.ipynb`.
    5 clusters identifiés avec la méthode Elbow.
    """)

    df = load_data()

    cluster_names = {
        0: "Cible Premium",
        1: "Ultra-Premium",
        2: "Mass Market Digital",
        3: "Mass Market Traditionnel",
        4: "Echec"
    }
    df['CLUSTER_NAME'] = df['cluster'].map(cluster_names)

    # Stats par cluster
    stats = df.groupby('cluster').agg({
        'BUDGET': 'mean',
        'REACH': 'mean',
        'CONVERSION_RATE': 'mean',
        'BUDGET_PER_REACH': 'mean',
        'CAMPAIGN_ID': 'count'
    }).reset_index()
    stats.columns = ['Cluster', 'Budget', 'Reach', 'Conversion', 'CPM', 'Nombre']
    stats['Nom'] = stats['Cluster'].map(cluster_names)
    stats['Conversion'] = stats['Conversion'] * 100

    # KPIs
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Nombre de Campagnes", len(df))
    with col2:
        st.metric("Nombre de Clusters", 5)
    with col3:
        st.metric("Conversion Moyenne", f"{df['CONVERSION_RATE'].mean()*100:.2f}%")

    st.markdown("---")

    # Tableau des clusters
    st.subheader("Profil des 5 clusters")

    display = stats[['Nom', 'Nombre', 'Budget', 'Reach', 'Conversion', 'CPM']].copy()
    display['Budget'] = display['Budget'].apply(lambda x: f"{x/1000:.0f} K")
    display['Reach'] = display['Reach'].apply(lambda x: f"{x/1000:.0f} K")
    display['Conversion'] = display['Conversion'].apply(lambda x: f"{x:.2f}%")
    display['CPM'] = display['CPM'].apply(lambda x: f"{x:.2f}")
    display.columns = ['Cluster', 'Nombre de Campagnes', 'Budget Moyen', 'Reach Moyen', 'Conversion', 'CPM']

    st.dataframe(display, use_container_width=True, hide_index=True)

    st.markdown("---")

    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Conversion par cluster")
        fig = px.bar(
            stats.sort_values('Conversion'),
            x='Conversion', y='Nom', orientation='h',
            color='Conversion', color_continuous_scale='RdYlGn'
        )
        fig.update_layout(height=350, showlegend=False)
        fig.update_coloraxes(showscale=False)
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.subheader("Répartition des campagnes")
        fig = px.pie(stats, values='Nombre', names='Nom', hole=0.3)
        fig.update_layout(height=350)
        st.plotly_chart(fig, use_container_width=True)

    st.markdown("---")

    # Scatter
    st.subheader("Visualisation CPM vs Conversion")
    fig = px.scatter(
        df, x='BUDGET_PER_REACH', y=df['CONVERSION_RATE']*100,
        color='CLUSTER_NAME', size='BUDGET',
        labels={'y': 'Conversion (%)', 'BUDGET_PER_REACH': 'CPM (euros)'}
    )
    fig.update_xaxes(type='log')
    fig.update_layout(height=400)
    st.plotly_chart(fig, use_container_width=True)

    st.markdown("---")

    # Recommandations
    st.subheader("Recommandations")

    col1, col2 = st.columns(2)

    with col1:
        st.markdown("""
        **Allocation actuelle vs recommandée**

        | Cluster | Actuel | Cible |
        |---------|--------|-------|
        | Cible Premium | 1.9% | 25% |
        | Ultra-Premium | 0.4% | 5% |
        | Mass Market | 97.5% | 70% |
        | Echec | 0.1% | 0% |
        """)

    with col2:
        st.markdown("""
        **Actions prioritaires**

        1. Stopper les campagnes du cluster "Echec"
        2. Augmenter le budget sur "Cible Premium"
        3. Réduire progressivement le mass market
        4. Analyser les 72 campagnes performantes
        """)


if __name__ == "__main__":
    main()

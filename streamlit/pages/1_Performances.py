"""
Performance par région
"""

import streamlit as st
import pandas as pd
import plotly.express as px
from pathlib import Path

st.set_page_config(page_title="Régions", layout="wide")

DATA_PATH = Path(__file__).parent.parent.parent / "data"
ANALYTICS_PATH = DATA_PATH / "analytics"


@st.cache_data
def load_data():
    ventes = pd.read_csv(ANALYTICS_PATH / "ventes_enrichies.csv")
    clients = pd.read_csv(ANALYTICS_PATH / "indicateurs_clients_region.csv")
    return ventes, clients


def main():
    st.title("Performance par Région")

    ventes, clients = load_data()

    # Stats par region
    stats = ventes.groupby('REGION').agg({
        'AMOUNT': ['sum', 'mean', 'count']
    }).reset_index()
    stats.columns = ['Region', 'CA', 'Panier_Moyen', 'Nb_Ventes']
    stats = stats.merge(clients, left_on='Region', right_on='REGION')

    # KPIs
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("CA Total", f"{ventes['AMOUNT'].sum()/1e6:.1f} M")
    with col2:
        best = stats.loc[stats['CA'].idxmax(), 'Region']
        st.metric("Region leader", best)
    with col3:
        st.metric("Nombre de Régions", len(stats))

    st.markdown("---")

    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Chiffre d'affaires par région")
        fig = px.bar(
            stats.sort_values('CA'),
            x='CA', y='Region', orientation='h'
        )
        fig.update_layout(height=350)
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.subheader("Nombre de clients vs CA généré")
        fig = px.scatter(
            stats, x='NB_CLIENTS', y='CA',
            size='Panier_Moyen', color='Region'
        )
        fig.update_layout(height=350)
        st.plotly_chart(fig, use_container_width=True)

    st.markdown("---")

    st.subheader("Detail par région")
    display = stats[['Region', 'CA', 'Panier_Moyen', 'Nb_Ventes', 'NB_CLIENTS']].copy()
    display['CA'] = display['CA'].apply(lambda x: f"{x/1e6:.2f} M")
    display['Panier_Moyen'] = display['Panier_Moyen'].apply(lambda x: f"{x:,.0f}")
    display.columns = ['Region', 'CA', 'Panier Moyen', 'Nombre de Ventes', 'Nombre de Clients']
    st.dataframe(display, use_container_width=True, hide_index=True)


if __name__ == "__main__":
    main()

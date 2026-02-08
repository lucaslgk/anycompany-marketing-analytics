"""
Dashboard des ventes
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from pathlib import Path

st.set_page_config(page_title="Ventes", layout="wide")

DATA_PATH = Path(__file__).parent.parent.parent / "data"
ANALYTICS_PATH = DATA_PATH / "analytics"


@st.cache_data
def load_data():
    ventes = pd.read_csv(ANALYTICS_PATH / "ventes_enrichies.csv")
    ventes['TRANSACTION_DATE'] = pd.to_datetime(ventes['TRANSACTION_DATE'])
    ventes['MOIS'] = pd.to_datetime(ventes['MOIS'])
    return ventes


def main():
    st.title("Analyse des Ventes")

    ventes = load_data()

    # Filtres
    st.sidebar.header("Filtres")
    regions = ['Toutes'] + sorted(ventes['REGION'].unique().tolist())
    selected_region = st.sidebar.selectbox("Region", regions)

    years = sorted(ventes['ANNEE'].unique().tolist())
    selected_years = st.sidebar.multiselect("Annees", years, default=years)

    # Appliquer filtres
    df = ventes.copy()
    if selected_region != 'Toutes':
        df = df[df['REGION'] == selected_region]
    if selected_years:
        df = df[df['ANNEE'].isin(selected_years)]

    # KPIs
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Chiffre d'Affaires Total", f"{df['AMOUNT'].sum()/1e6:.2f} M")
    with col2:
        st.metric("Nombre de Ventes", f"{len(df):,}")
    with col3:
        st.metric("Panier Moyen", f"{df['AMOUNT'].mean():,.0f} euros")

    st.markdown("---")

    # Evolution mensuelle
    st.subheader("Evolution mensuelle du Chiffre d'Affaires")
    ventes_mois = df.groupby('MOIS')['AMOUNT'].sum().reset_index()

    fig = px.line(ventes_mois, x='MOIS', y='AMOUNT')
    fig.update_layout(height=350)
    st.plotly_chart(fig, use_container_width=True)

    # Par region
    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Chiffre d'Affaires par Région")
        ca_region = df.groupby('REGION')['AMOUNT'].sum().reset_index()
        ca_region = ca_region.sort_values('AMOUNT', ascending=True)

        fig = px.bar(ca_region, x='AMOUNT', y='REGION', orientation='h')
        fig.update_layout(height=350)
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.subheader("Méthodes de paiement")
        payment = df.groupby('PAYMENT_METHOD')['AMOUNT'].sum().reset_index()

        fig = px.pie(payment, values='AMOUNT', names='PAYMENT_METHOD', hole=0.3)
        fig.update_layout(height=350)
        st.plotly_chart(fig, use_container_width=True)


if __name__ == "__main__":
    main()

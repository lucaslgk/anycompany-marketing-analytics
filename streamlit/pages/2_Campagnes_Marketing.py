"""
Analyse cout/efficacite des campagnes
"""

import streamlit as st
import pandas as pd
import plotly.express as px
from pathlib import Path

st.set_page_config(page_title="Campagnes", layout="wide")

DATA_PATH = Path(__file__).parent.parent.parent / "data"


@st.cache_data
def load_data():
    df = pd.read_csv(DATA_PATH / "marketing_campaigns_clean.csv")
    df['CPM'] = (df['BUDGET'] / df['REACH']) * 1000
    df['COUT_PAR_CONVERSION'] = df['BUDGET'] / (df['REACH'] * df['CONVERSION_RATE'])
    return df


def main():
    st.title("Efficacite des Campagnes")

    df = load_data()

    # Filtres
    st.sidebar.header("Filtres")
    types = ['Tous'] + sorted(df['CAMPAIGN_TYPE'].unique().tolist())
    selected = st.sidebar.selectbox("Type de campagne", types)

    if selected != 'Tous':
        df = df[df['CAMPAIGN_TYPE'] == selected]

    # KPIs
    col1, col2, col3 = st.columns(3)
    with col1:
        st.metric("Nb Campagnes", len(df))
    with col2:
        st.metric("CPM Moyen", f"{df['CPM'].mean():.2f} euros")
    with col3:
        st.metric("Conversion Moyenne", f"{df['CONVERSION_RATE'].mean()*100:.2f}%")

    st.markdown("---")

    # Scatter CPM vs Conversion
    st.subheader("CPM vs Taux de conversion")
    fig = px.scatter(
        df, x='CPM', y=df['CONVERSION_RATE']*100,
        color='CAMPAIGN_TYPE', size='BUDGET',
        hover_data=['CAMPAIGN_NAME', 'REGION'],
        labels={'y': 'Conversion (%)', 'CPM': 'CPM (euros)'}
    )
    fig.update_layout(height=400)
    st.plotly_chart(fig, use_container_width=True)

    st.markdown("---")

    col1, col2 = st.columns(2)

    with col1:
        st.subheader("CPM moyen par type")
        cpm_type = df.groupby('CAMPAIGN_TYPE')['CPM'].mean().reset_index()
        fig = px.bar(
            cpm_type.sort_values('CPM'),
            x='CPM', y='CAMPAIGN_TYPE', orientation='h'
        )
        fig.update_layout(height=300)
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.subheader("Conversion par type")
        conv_type = df.groupby('CAMPAIGN_TYPE')['CONVERSION_RATE'].mean().reset_index()
        conv_type['CONVERSION_RATE'] = conv_type['CONVERSION_RATE'] * 100
        fig = px.bar(
            conv_type.sort_values('CONVERSION_RATE'),
            x='CONVERSION_RATE', y='CAMPAIGN_TYPE', orientation='h'
        )
        fig.update_layout(height=300)
        st.plotly_chart(fig, use_container_width=True)


if __name__ == "__main__":
    main()

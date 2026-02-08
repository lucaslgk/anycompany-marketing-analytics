"""
ROI Marketing
"""

import streamlit as st
import pandas as pd
import plotly.express as px
from pathlib import Path

st.set_page_config(page_title="Marketing ROI", layout="wide")

DATA_PATH = Path(__file__).parent.parent.parent / "data"


@st.cache_data
def load_data():
    campaigns = pd.read_csv(DATA_PATH / "marketing_campaigns_clean.csv")
    campaigns['CPM'] = (campaigns['BUDGET'] / campaigns['REACH']) * 1000
    return campaigns


def main():
    st.title("ROI des Campagnes Marketing")

    df = load_data()

    # Filtres
    st.sidebar.header("Filtres")
    types = ['Tous'] + sorted(df['CAMPAIGN_TYPE'].unique().tolist())
    selected_type = st.sidebar.selectbox("Type", types)

    regions = ['Toutes'] + sorted(df['REGION'].unique().tolist())
    selected_region = st.sidebar.selectbox("Region", regions)

    # Appliquer
    if selected_type != 'Tous':
        df = df[df['CAMPAIGN_TYPE'] == selected_type]
    if selected_region != 'Toutes':
        df = df[df['REGION'] == selected_region]

    # KPIs
    col1, col2, col3, col4 = st.columns(4)

    with col1:
        st.metric("Budget Total", f"{df['BUDGET'].sum()/1e6:.1f} M")
    with col2:
        st.metric("Reach Total", f"{df['REACH'].sum()/1e6:.1f} M")
    with col3:
        st.metric("Conversion Moyenne", f"{df['CONVERSION_RATE'].mean()*100:.2f}%")
    with col4:
        st.metric("CPM Moyen", f"{df['CPM'].mean():.2f}")

    st.markdown("---")

    # Par type
    col1, col2 = st.columns(2)

    with col1:
        st.subheader("Conversion par type")
        type_perf = df.groupby('CAMPAIGN_TYPE')['CONVERSION_RATE'].mean().reset_index()
        type_perf['CONVERSION_RATE'] = type_perf['CONVERSION_RATE'] * 100

        fig = px.bar(
            type_perf.sort_values('CONVERSION_RATE', ascending=True),
            x='CONVERSION_RATE', y='CAMPAIGN_TYPE', orientation='h'
        )
        fig.update_layout(height=350)
        st.plotly_chart(fig, use_container_width=True)

    with col2:
        st.subheader("Budget par région")
        budget_region = df.groupby('REGION')['BUDGET'].sum().reset_index()

        fig = px.pie(budget_region, values='BUDGET', names='REGION', hole=0.3)
        fig.update_layout(height=350)
        st.plotly_chart(fig, use_container_width=True)

    st.markdown("---")

    # Top campagnes
    st.subheader("Top 10 campagnes (conversion)")

    top = df.nlargest(10, 'CONVERSION_RATE')[
        ['CAMPAIGN_NAME', 'CAMPAIGN_TYPE', 'REGION', 'CONVERSION_RATE', 'BUDGET']
    ].copy()
    top['CONVERSION_RATE'] = (top['CONVERSION_RATE'] * 100).round(2)

    st.dataframe(top, use_container_width=True, hide_index=True)


if __name__ == "__main__":
    main()

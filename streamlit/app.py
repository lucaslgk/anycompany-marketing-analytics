"""
AnyCompany Food & Beverage - Dashboard Marketing
"""

import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from pathlib import Path

st.set_page_config(
    page_title="AnyCompany - Marketing Analytics",
    page_icon="chart_with_upwards_trend",
    layout="wide"
)

# Chemins
DATA_PATH = Path(__file__).parent.parent / "data"
ANALYTICS_PATH = DATA_PATH / "analytics"


@st.cache_data
def load_data():
    """Charge les donnees."""
    data = {}
    data['ventes'] = pd.read_csv(ANALYTICS_PATH / "ventes_enrichies.csv")
    data['clients'] = pd.read_csv(ANALYTICS_PATH / "indicateurs_clients_region.csv")
    data['campaigns'] = pd.read_csv(DATA_PATH / "marketing_campaigns_clean.csv")
    return data


def main():
    st.title("AnyCompany Food & Beverage")
    st.subheader("Dashboard Marketing Analytics")

    st.markdown("---")

    try:
        data = load_data()

        # KPIs
        col1, col2, col3, col4 = st.columns(4)

        total_ca = data['ventes']['AMOUNT'].sum()
        nb_transactions = len(data['ventes'])
        nb_campaigns = len(data['campaigns'])
        conversion_moy = data['campaigns']['CONVERSION_RATE'].mean() * 100

        with col1:
            st.metric("Chiffre d'Affaires", f"{total_ca/1e6:.1f} M")

        with col2:
            st.metric("Transactions", f"{nb_transactions:,}")

        with col3:
            st.metric("Campagnes", f"{nb_campaigns:,}")

        with col4:
            st.metric("Conversion Moyenne", f"{conversion_moy:.1f}%")

        st.markdown("---")

        # Graphiques
        col_left, col_right = st.columns(2)

        with col_left:
            st.subheader("Clients par Region")
            fig = px.pie(
                data['clients'],
                values='NB_CLIENTS',
                names='REGION',
                hole=0.4
            )
            fig.update_layout(height=350)
            st.plotly_chart(fig, use_container_width=True)

        with col_right:
            st.subheader("Conversion par Type de Campagne")
            camp_perf = data['campaigns'].groupby('CAMPAIGN_TYPE').agg({
                'CONVERSION_RATE': 'mean'
            }).reset_index()
            camp_perf['CONVERSION_RATE'] = camp_perf['CONVERSION_RATE'] * 100

            fig = px.bar(
                camp_perf.sort_values('CONVERSION_RATE', ascending=True),
                x='CONVERSION_RATE',
                y='CAMPAIGN_TYPE',
                orientation='h'
            )
            fig.update_layout(height=350)
            st.plotly_chart(fig, use_container_width=True)

    except Exception as e:
        st.error(f"Erreur: {str(e)}")


if __name__ == "__main__":
    main()

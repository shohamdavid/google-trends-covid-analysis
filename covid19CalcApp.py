import streamlit as st
import pandas as pd
import numpy as np
from sklearn.linear_model import LinearRegression

# Page Configuration
st.set_page_config(page_title="COVID-19 Predictive System", layout="wide")

# App Header
st.title("🏥 COVID-19 Hospital Resource Predictor")
st.markdown("### Predicting Hospital Load using Search Engine Trends")
st.markdown("---")

# Data Loading Function
@st.cache_data
def load_data():
    try:
        # Using the direct path provided previously
        path = r"c:\Users\97252\פרויקט מסכם קורס Data Analyst\covid19AndGoogleSearchProject.csv"
        df = pd.read_csv(path)
        
        # Date Conversion
        df['report_date'] = pd.to_datetime(df['report_date'])
        
        # Ensure all columns are numeric to prevent "Flat Charts"
        numeric_cols = ['new_hospitalized_patients', 'breath_shortness_score', 
                        'cough_score', 'anosmia_7day_avg', 'fever_score']
        
        for col in numeric_cols:
            if col in df.columns:
                df[col] = pd.to_numeric(df[col], errors='coerce').fillna(0)
                
        return df
    except Exception as e:
        st.error(f"Error loading data: {e}")
        return None

df = load_data()

if df is not None:
    # --- 1. Model Preparation ---
    features = ['breath_shortness_score', 'cough_score', 'anosmia_7day_avg', 'fever_score']
    X = df[features]
    y = df['new_hospitalized_patients']
    
    # Train Linear Regression Model
    model = LinearRegression().fit(X, y)

    # --- 2. Sidebar Interface ---
    st.sidebar.header("📊 Real-time Search Indicators")
    st.sidebar.write("Enter current search intensity to predict future load:")

    user_breath = st.sidebar.slider("Breath Shortness (R=0.48)", 0, 100, 25)
    user_cough = st.sidebar.slider("Cough (R=0.40 - 21d Lag)", 0, 100, 30)
    user_anosmia = st.sidebar.slider("Anosmia (R=0.39 - 10d Lag)", 0, 100, 15)
    user_fever = st.sidebar.slider("Fever (R=0.34 - 14d Lag)", 0, 100, 20)

    # --- 3. Prediction Logic ---
    prediction = model.predict([[user_breath, user_cough, user_anosmia, user_fever]])[0]
    # Apply 10% Safety Buffer
    safe_prediction = int(round(max(0, prediction * 1.1)))

    # --- 4. Dashboard Metrics ---
    col1, col2, col3 = st.columns(3)

    with col1:
        st.metric(label="Predicted New Admissions (Next Week)", value=f"{safe_prediction} Patients")
        st.caption("Includes 10% safety margin")

    with col2:
        avg_hosp = df['new_hospitalized_patients'].mean()
        if safe_prediction > avg_hosp * 1.2:
            status = "High Load Warning"
            color = "red"
        else:
            status = "Stable / Routine"
            color = "green"
        st.markdown(f"System Status: <h3 style='color:{color};'>{status}</h3>", unsafe_allow_html=True)

    with col3:
        st.write("📋 **Management Recommendation:**")
        if safe_prediction > avg_hosp * 1.2:
            st.error("Reinforce Medical Staff & Emergency Ward")
        else:
            st.success("Maintain Standard Operating Procedures")

    st.markdown("---")

    # --- 5. Visualizations (Solving the 'Flat Chart' issue) ---
    st.subheader("Historical Trend Analysis: Search Interest vs. Hospitalizations")
    
    tab1, tab2 = st.tabs(["Normalized Comparison", "Detailed View"])

    with tab1:
        # Normalize data to 0-100 scale for visual comparison
        df_norm = df.copy()
        if df['breath_shortness_score'].max() > 0:
            df_norm['breath_shortness_norm'] = (df['breath_shortness_score'] / df['breath_shortness_score'].max()) * 100
        if df['new_hospitalized_patients'].max() > 0:
            df_norm['hospitalized_norm'] = (df['new_hospitalized_patients'] / df['new_hospitalized_patients'].max()) * 100
        
        st.line_chart(df_norm.set_index('report_date')[['breath_shortness_norm', 'hospitalized_norm']])
        st.caption("Note: Data is normalized (0-100 scale) to compare trend movements effectively.")

    with tab2:
        c1, c2 = st.columns(2)
        with c1:
            st.write("📈 Breath Shortness Trends (R=0.48)")
            st.area_chart(df.set_index('report_date')['breath_shortness_score'], color="#ff4b4b")
        with c2:
            st.write("🏥 Actual Hospitalizations")
            st.area_chart(df.set_index('report_date')['new_hospitalized_patients'], color="#0077b6")

else:
    st.warning("Data file not found. Please ensure 'covid19AndGoogleSearchProject.csv' is in the project folder.")
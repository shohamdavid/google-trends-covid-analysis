/*
Digital Thermometer - COVID-19 Search vs. Reality
*/

-- Extract and smooth Google Search Trends for symptoms
WITH search_trends AS (
  SELECT
    country_region,
    PARSE_DATE('%Y-%m-%d', date) AS report_date,
    
    -- Casting symptom scores to FLOAT64 for precise correlation analysis
    SAFE_CAST(symptom_anosmia AS FLOAT64) AS anosmia_score,
    SAFE_CAST(symptom_ageusia AS FLOAT64) AS ageusia_score,
    SAFE_CAST(symptom_fever AS FLOAT64) AS fever_score,
    SAFE_CAST(symptom_cough AS FLOAT64) AS cough_score,
    SAFE_CAST(symptom_shortness_of_breath AS FLOAT64) AS breath_shortness_score,
    SAFE_CAST(symptom_anxiety AS FLOAT64) AS anxiety_score,
    SAFE_CAST(symptom_depression AS FLOAT64) AS depression_score,
    SAFE_CAST(symptom_insomnia AS FLOAT64) AS insomnia_score,
    
    -- Calculating 7-day moving averages to remove daily noise and weekend reporting lags
    AVG(SAFE_CAST(symptom_anosmia AS FLOAT64)) OVER(
        PARTITION BY country_region 
        ORDER BY date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS anosmia_7day_avg,
    
    AVG(SAFE_CAST(symptom_ageusia AS FLOAT64)) OVER(
        PARTITION BY country_region 
        ORDER BY date 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS ageusia_7day_avg
    
  FROM 
    `bigquery-public-data.covid19_symptom_search.symptom_search_country_daily`
),

-- Extract official health metrics, policy indices, and mobility data
actual_health_and_metrics AS (
  SELECT 
    country_name,
    date AS report_date,
    new_confirmed,
    new_deceased,
    new_hospitalized_patients,
    current_intensive_care_patients,
    
    -- Contextual factors: Behavior (Mobility) and Government Policy (Stringency)
    mobility_workplaces, 
    mobility_residential,
    stringency_index,
    
    -- Demographic and Economic factors for normalization
    population,
    population_density,
    gdp_per_capita_usd
  FROM 
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE 
    -- Filtering for country-level data only (National level)
    aggregation_level = 0
)

-- Join datasets and calculate final analytical indicators
SELECT 
  s.*,
  a.new_confirmed,
  a.new_deceased,
  a.new_hospitalized_patients,
  a.current_intensive_care_patients,
  a.mobility_workplaces,
  a.mobility_residential,
  a.stringency_index,
  a.population_density,
  a.gdp_per_capita_usd,

  -- 7-day moving average for confirmed cases to align with the smoothed search data
  AVG(a.new_confirmed) OVER(
      PARTITION BY s.country_region 
      ORDER BY s.report_date 
      ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS confirmed_7day_avg,

  -- Normalizing cases per 100k population for fair cross-country comparison
  SAFE_DIVIDE(a.new_confirmed, a.population) * 100000 AS cases_per_100k

FROM 
  search_trends s
JOIN 
  actual_health_and_metrics a ON s.country_region = a.country_name 
  AND s.report_date = a.report_date

-- Sorting for time-series visualization
ORDER BY 
  s.country_region, s.report_date ASC;

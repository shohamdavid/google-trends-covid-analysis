/*
Digital Thermometer - COVID-19 Search vs. Reality
*/

WITH search_trends AS (
  -- Extract digital data from Google Search Trends
  SELECT
    country_region,
    PARSE_DATE('%Y-%m-%d', date) AS report_date, -- Convert string date to DATE format for time-series analysis
    -- Use SAFE_CAST to convert symptom scores from string to FLOAT, preventing query errors on nulls
    SAFE_CAST(symptom_anosmia AS FLOAT64) AS anosmia_score,
    SAFE_CAST(symptom_ageusia AS FLOAT64) AS ageusia_score,
    SAFE_CAST(symptom_fever AS FLOAT64) AS fever_score,
    SAFE_CAST(symptom_cough AS FLOAT64) AS cough_score,
    SAFE_CAST(symptom_shortness_of_breath AS FLOAT64) AS breath_shortness_score,
    SAFE_CAST(symptom_anxiety AS FLOAT64) AS anxiety_score,
    SAFE_CAST(symptom_depression AS FLOAT64) AS depression_score,
    SAFE_CAST(symptom_insomnia AS FLOAT64) AS insomnia_score
  FROM 
    `bigquery-public-data.covid19_symptom_search.symptom_search_country_daily`
),

actual_health_and_demographics AS (
  -- Extract official health outcomes, demographics, and economic data
  SELECT 
    country_name,
    date AS report_date,
    new_confirmed,
    new_deceased,
    new_hospitalized_patients,
    current_intensive_care_patients,
    new_ventilator_patients,
    population,                       
    population_density,
    gdp_per_capita_usd
  FROM 
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE 
    aggregation_level = 0 -- Filter for national level data only (removes city/state duplicates)
)

-- Final Join and Analytical Calculations
SELECT 
  s.*,
  a.new_confirmed,
  a.new_deceased,
  a.new_hospitalized_patients,
  a.current_intensive_care_patients,
  a.new_ventilator_patients,
  a.population,
  a.population_density,
  a.gdp_per_capita_usd,

  -- Normalize cases per 100k people for fair global comparison
  SAFE_DIVIDE(a.new_confirmed, a.population) * 100000 AS cases_per_100k,
  
  -- Ratio of hospitalized patients requiring ventilators (Severity Index)
  SAFE_DIVIDE(a.new_ventilator_patients, a.new_hospitalized_patients) AS ventilation_rate_per_hospitalized

FROM 
  search_trends s
JOIN 
  actual_health_and_demographics a ON s.country_region = a.country_name 
  AND s.report_date = a.report_date -- Exact match on Country and Date

ORDER BY 
  s.country_region, s.report_date ASC;

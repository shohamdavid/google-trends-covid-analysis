WITH search_trends AS (
  SELECT
    country_region,
    PARSE_DATE('%Y-%m-%d', date) AS report_date,
    SAFE_CAST(symptom_anosmia AS FLOAT64) AS anosmia_score,
    SAFE_CAST(symptom_fever AS FLOAT64) AS fever_score,
    SAFE_CAST(symptom_shortness_of_breath AS FLOAT64) AS breath_shortness_score,
    AVG(SAFE_CAST(symptom_anosmia AS FLOAT64)) OVER(PARTITION BY country_region ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS anosmia_7day_avg
  FROM 
    `bigquery-public-data.covid19_symptom_search.symptom_search_country_daily`
),

actual_health_and_demographics AS (
  SELECT 
    country_name,
    date AS report_date,
    new_confirmed,
    new_hospitalized_patients,
    mobility_workplaces, 
    mobility_residential,
    stringency_index, 
    population,
    gdp_per_capita_usd
  FROM 
    `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE 
    aggregation_level = 0
)

SELECT 
  s.*,
  a.new_confirmed,
  a.new_hospitalized_patients,
  a.mobility_workplaces,
  a.mobility_residential,
  a.stringency_index,
  a.gdp_per_capita_usd,

  AVG(a.new_confirmed) OVER(PARTITION BY s.country_region ORDER BY s.report_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS confirmed_7day_avg,

  SAFE_DIVIDE(a.new_confirmed, a.population) * 100000 AS cases_per_100k

FROM 
  search_trends s
JOIN 
  actual_health_and_demographics a ON s.country_region = a.country_name 
  AND s.report_date = a.report_date

ORDER BY 
  s.country_region, s.report_date ASC;
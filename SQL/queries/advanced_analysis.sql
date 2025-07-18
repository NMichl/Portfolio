-- Investigating and comparing debt per capita and % of GNI
-- (High debt per capita + high % of GNI = potentially risky)

-- Query 1: Analyze total debt, debt-to-GNI ratio, and debt per capita for 2019
-- Key insight: Countries with high absolute and relative debt burdens may face challenges
SELECT country_name, year, 
       ROUND(SUM(CASE WHEN series_code = 'DT.DOD.DECT.CD' THEN value END)/ 1000000000,2) ||'B' AS total_debt,
	   ROUND(MAX(CASE WHEN series_code = 'DT.DOD.DECT.GN.ZS' THEN value END)) || '%' AS debt_gni_ratio,
	   ROUND(MAX(CASE WHEN series_code = 'DT.DOD.DECT.PC.CD' THEN value END),2) AS debt_per_capita
FROM international_debt 
WHERE series_code IN ('DT.DOD.DECT.CD','DT.DOD.DECT.PC.CD', 'DT.DOD.DECT.GN.ZS')
	  AND year = 2019
GROUP BY country_name, year 
HAVING MAX (CASE WHEN series_code = 'DT.DOD.DECT.GN.ZS' THEN value END) IS NOT NULL
ORDER BY MAX(CASE WHEN series_code = 'DT.DOD.DECT.PC.CD' THEN value END) DESC;
- Observations:
-- Mongolia and Montenegro appear potentially risky with high debt compared to GNI and per capita
-- Notably, China has a low debt-to-GNI ratio (15%) — not necessarily low debt overall, but low borrowing from the World Bank



-- Query 2: Comparing debt-to-GNI ratios across years (2019 vs 2023)
-- Measures debt sustainability changes over time
SELECT country_name, 
	   Round(MAX(value) FILTER (WHERE year = 2019)) AS debt_gni_ratio_2019,
	   Round(MAX(value) FILTER (WHERE year = 2023)) AS debt_gni_ratio_2023
FROM international_debt
WHERE series_code = 'DT.DOD.DECT.GN.ZS'
GROUP BY country_name
HAVING  AVG(value) FILTER (WHERE year = 2019) >= 100
ORDER BY debt_gni_ratio_2019 DESC;
-- Insight: 9 countries have debt exceeding their annual GNI (2019)
-- Mozambique and Mongolia stand out with high ratios
-- Many countries reduced debt significantly — Mongolia improved, but Georgia and Lao PDR saw increases




-- Query 3: Breakdown of public vs private debt in 2019
-- Focus on countries where public debt is >60% of total debt
SELECT
    country_name,
    year,
    SUM(CASE WHEN series_code = 'DT.DOD.DPPG.CD' THEN value END) AS public_debt,
    SUM(CASE WHEN series_code = 'DT.DOD.DPNG.CD' THEN value END) AS private_debt,
    ROUND(100.0 * SUM(CASE WHEN series_code = 'DT.DOD.DPPG.CD' THEN value END) /
                 SUM(CASE WHEN series_code IN ('DT.DOD.DPPG.CD', 'DT.DOD.DPNG.CD') THEN value END), 2)
        AS pct_public,
    ROUND(100.0 * SUM(CASE WHEN series_code = 'DT.DOD.DPNG.CD' THEN value END) /
                 SUM(CASE WHEN series_code IN ('DT.DOD.DPPG.CD', 'DT.DOD.DPNG.CD') THEN value END), 2)
        AS pct_private
FROM international_debt
WHERE series_code IN ('DT.DOD.DPPG.CD', 'DT.DOD.DPNG.CD')
  AND year = 2019
GROUP BY country_name, year
HAVING ROUND(100.0 * SUM(CASE WHEN series_code = 'DT.DOD.DPPG.CD' THEN value END) /
                 SUM(CASE WHEN series_code IN ('DT.DOD.DPPG.CD', 'DT.DOD.DPNG.CD') THEN value END), 2) > 60
ORDER BY pct_public DESC;
-- Insight: 81 of 120 countries have a public debt share above 60%



-- Query 4: Opposite of the above — countries with <40% public debt
-- Highlights where private, non-guaranteed debt is dominant
-- Mozambique and Mongolia again appear — most of their debt is private
SELECT
    country_name,
    year,
    SUM(CASE WHEN series_code = 'DT.DOD.DPPG.CD' THEN value END) AS public_debt,
    SUM(CASE WHEN series_code = 'DT.DOD.DPNG.CD' THEN value END) AS private_debt,
    ROUND(100.0 * SUM(CASE WHEN series_code = 'DT.DOD.DPPG.CD' THEN value END) /
      SUM(CASE WHEN series_code IN ('DT.DOD.DPPG.CD', 'DT.DOD.DPNG.CD') THEN value END), 2) AS pct_public,
    ROUND(100.0 * SUM(CASE WHEN series_code = 'DT.DOD.DPNG.CD' THEN value END) /
      SUM(CASE WHEN series_code IN ('DT.DOD.DPPG.CD', 'DT.DOD.DPNG.CD') THEN value END), 2)AS pct_private
FROM international_debt
WHERE series_code IN ('DT.DOD.DPPG.CD', 'DT.DOD.DPNG.CD')
  AND year = 2019
GROUP BY country_name, year
HAVING ROUND(100.0 * SUM(CASE WHEN series_code = 'DT.DOD.DPPG.CD' THEN value END) /
       SUM(CASE WHEN series_code IN ('DT.DOD.DPPG.CD', 'DT.DOD.DPNG.CD') THEN value END), 2) < 40
ORDER BY pct_public DESC;



-- Query 5: Short-term external debt ratios
-- A high percentage can be risky due to refinancing pressure
SELECT
    country_name,
    year,
	ROUND(100.0 * SUM(CASE WHEN series_code = 'DT.DOD.DSTC.CD' THEN value END) /
      SUM(CASE WHEN series_code = 'DT.DOD.DECT.CD' THEN value END), 2) AS short_term_ratio_pct,
    ROUND(SUM(CASE WHEN series_code = 'DT.DOD.DSTC.CD' THEN value END)/1000000000,2) ||'B' AS short_term_debt,
    ROUND(SUM(CASE WHEN series_code = 'DT.DOD.DECT.CD' THEN value END)/1000000000,2) ||'B' AS total_external_debt    
FROM international_debt
WHERE series_code IN ('DT.DOD.DSTC.CD', 'DT.DOD.DECT.CD')
  AND year = 2019
GROUP BY country_name, year
HAVING ROUND(100.0 * SUM(CASE WHEN series_code = 'DT.DOD.DSTC.CD' THEN value END) /
              SUM(CASE WHEN series_code = 'DT.DOD.DECT.CD' THEN value END), 0) > 30
ORDER BY short_term_ratio_pct DESC;
-- Observation: Mozambique and Mongolia, despite high overall debt, have low short-term debt — this reduces near-term risk



-- Query 6: Focused view on short-term debt in Mozambique and Mongolia
-- Confirms short-term exposure is modest for both
SELECT
    country_name,
    year,
	ROUND(100.0 * SUM(CASE WHEN series_code = 'DT.DOD.DSTC.CD' THEN value END) /
      SUM(CASE WHEN series_code = 'DT.DOD.DECT.CD' THEN value END), 2) AS short_term_ratio_pct,
    ROUND(SUM(CASE WHEN series_code = 'DT.DOD.DSTC.CD' THEN value END)/1000000000,2) ||'B' AS short_term_debt,
    ROUND(SUM(CASE WHEN series_code = 'DT.DOD.DECT.CD' THEN value END)/1000000000,2) ||'B' AS total_external_debt    
FROM international_debt
WHERE series_code IN ('DT.DOD.DSTC.CD', 'DT.DOD.DECT.CD') 
  AND year = 2019  AND country_name IN ('Mozambique','Mongolia')
GROUP BY country_name, year
HAVING ROUND(100.0 * SUM(CASE WHEN series_code = 'DT.DOD.DSTC.CD' THEN value END) /
              SUM(CASE WHEN series_code = 'DT.DOD.DECT.CD' THEN value END), 0) < 30
ORDER BY short_term_ratio_pct DESC;


-- Query 7: Composite debt risk score
-- Criteria:
--   1. Debt-to-GNI > 60%
--   2. Debt per capita > $5000
--   3. Short-term debt > 30% of total external debt
SELECT country_name,
	   year,
	   ROUND(MAX(CASE WHEN series_code = 'DT.DOD.DECT.GN.ZS' THEN value END),2)|| '%' AS debt_gni_ratio,
	   ROUND(MAX(CASE WHEN series_code = 'DT.DOD.DECT.PC.CD' THEN value END)) AS debt_per_capita,
	   ROUND(100.0 * SUM(CASE WHEN series_code = 'DT.DOD.DSTC.CD' THEN value END) /
      	SUM(CASE WHEN series_code = 'DT.DOD.DECT.CD' THEN value END), 2) || '%' AS short_term_ratio_pct,
		CASE WHEN MAX(CASE WHEN series_code = 'DT.DOD.DECT.GN.ZS' THEN value END) > 60 THEN 1 ELSE 0 END +
		CASE WHEN MAX(CASE WHEN series_code = 'DT.DOD.DECT.PC.CD' THEN value END) > 5000 THEN 1 ELSE 0 END +
		CASE WHEN 100.0 * SUM(CASE WHEN series_code = 'DT.DOD.DSTC.CD' THEN value END) /
      	SUM(CASE WHEN series_code = 'DT.DOD.DECT.CD' THEN value END) > 30 THEN 1 ELSE 0 END 
		  AS risk_score
FROM international_debt
WHERE series_code IN  ('DT.DOD.DECT.GN.ZS', 'DT.DOD.DECT.PC.CD', 'DT.DOD.DSTC.CD', 'DT.DOD.DECT.CD')
	  AND year = 2019 
GROUP BY country_name , year
HAVING CASE WHEN MAX(CASE WHEN series_code = 'DT.DOD.DECT.GN.ZS' THEN value END) > 60 THEN 1 ELSE 0 END +
		CASE WHEN MAX(CASE WHEN series_code = 'DT.DOD.DECT.PC.CD' THEN value END) > 5000 THEN 1 ELSE 0 END +
		CASE WHEN 100.0 * SUM(CASE WHEN series_code = 'DT.DOD.DSTC.CD' THEN value END) /
      	SUM(CASE WHEN series_code = 'DT.DOD.DECT.CD' THEN value END) > 30 THEN 1 ELSE 0 END  >= 2
ORDER BY risk_score DESC;
-- Risk Score: 0–3 (number of criteria met)
-- Filtering for countries with a risk score of 2 or 3
-- Insight: 9 countries meet 2 risk criteria; 2 countries meet all 3, indicating highest concern





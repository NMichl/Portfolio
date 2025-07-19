-- Count the number of distinct countries in the dataset
SELECT  COUNT(DISTINCT country_code) 
AS total_distinct_countries
FROM international_debt;
-- Note: Some countries do not report all indicators, so null values may be present in some series (will be seen in advanced analysis).

-- Investigating the definition and structure of key debt ratios
SELECT country_name, series_name, series_code, value, year, counterpart_area_name
FROM international_debt
WHERE series_code = 'DT.DOD.DECT.GN.ZS'
ORDER BY country_name;
SELECT country_name, series_name, series_code, value, year, counterpart_area_name
FROM international_debt
WHERE series_code = 'DT.DOD.DECT.GN.ZS'
ORDER BY country_name;
SELECT country_name, series_name, series_code, value, year, counterpart_area_name
FROM international_debt
WHERE series_code = 'DT.DOD.DECT.CD'
ORDER BY country_name;
-- Observation:
-- Debt-to-GNI ratios are reported as single values per year, always using the World Bank as the counterpart.
-- Therefore, no aggregation is required across counterpart areas for this indicator, unlike for total external debt.


-- Countries with highest external debt in 2019 and comparison to 2023
SELECT country_name, 
	   Round(SUM(value) FILTER (WHERE year = 2019)/ 1000000000,2) ||'B' AS total_debt_2019,
	   Round(SUM(value) FILTER (WHERE year = 2023)/ 1000000000,2) ||'B' AS total_debt_2023
FROM international_debt
WHERE series_code = 'DT.DOD.DECT.CD' 
GROUP BY country_name
ORDER BY SUM(value) FILTER (WHERE year = 2019) DESC
LIMIT 10;
-- Insight:
-- Very mixed development. 5 countries increased debt (China, Brazil, India, Turkiye and Thailand) 
-- 3 countries experienced only slight changes in their debt (Kazakhstan, Mexico and Indonesia)
-- 2 reduced debt (South Africa, Argentina)



-- Biggest lenders in 2019 and 2023
SELECT counterpart_area_name,
	   Round(SUM(value) FILTER (WHERE year = 2019)/ 1000000000,2) ||'B' AS biggest_lender_2019,
	   Round(SUM(value) FILTER (WHERE year = 2023)/ 1000000000,2) ||'B' AS biggest_lender_2023
FROM international_debt
WHERE series_code = 'DT.DOD.DECT.CD' 
GROUP BY counterpart_area_name
ORDER BY sum(value) FILTER (WHERE year = 2019) DESC
LIMIT 10;
-- Observations:
-- As expected, the World Bank is the largest external lender
-- Only two countries/orginaizations which didn't lend more in 2023 (China and Japan)

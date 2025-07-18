-- Create table with prexisitng columns to easily import the data
CREATE TABLE international_debt (
	 country_name TEXT,
     country_code  TEXT,
     counterpart_area_name  TEXT,
     counterpart_area_code  TEXT,
     series_name  TEXT,
     series_code  TEXT,
	 year INTEGER,
	 value numeric
);

-- Data has still some aggregates like continets and unwanted data
SELECT DISTINCT country_name
FROM international_debt;

-- Delete unwanted data 
DELETE FROM international_debt
WHERE country_name IS NULL
   OR country_name ILIKE 'Latin America%'
   OR country_name ILIKE '%income%'
   OR country_name ILIKE 'IDA%'
   OR country_name ILIKE '%Asia%'
   OR country_name ILIKE 'Least developed%';

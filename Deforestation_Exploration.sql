



-- drop view forestation if exits
DROP VIEW IF EXISTS forestation;


-- Create a view called forestation

CREATE VIEW forestation AS SELECT fa.country_code,
		fa.country_name,
		fa.year,
		fa.forest_area_sqkm,
		la.total_area_sq_mi,
		la.total_area_sq_mi * 2.59 AS total_area_sqkm,
		re.region,
		re.income_group,
		(fa.forest_area_sqkm * 100)/ (total_area_sq_mi * 2.59) AS percent_forestation
	FROM forest_area fa
			JOIN land_area la 
				ON fa.country_code = la.country_code
				AND fa.year = la.year
					JOIN regions re
						ON re.country_code = fa.country_code;



-- Part 1 - GLOBAL SITUATION

--- What was the total forest area (in sq km) of the world in 1990? Please keep in mind that you can use the country record denoted as “World" in the region table.


SELECT SUM(forest_area_sqkm) AS sum_forest_area_sqkm_1990
	FROM forestation
	WHERE year = 1990 AND region = 'World'
	;


-- What was the total forest area (in sq km) of the world in 2016? Please keep in mind that you can use the country record in the table is denoted as “World.” 

SELECT SUM(forest_area_sqkm) AS sum_forest_area_sqkm_2016
	FROM forestation
	WHERE year = 2016 AND region = 'World'
	;


-- What was the change (in sq km) in the forest area of the world from 1990 to 2016? 

SELECT (fa1.forest_area_sqkm - fa2.forest_area_sqkm ) AS forest_area_change_1990_2016
	FROM forestation fa1, forestation fa2
	WHERE fa1.year = 1990
		AND fa1.region = 'World'
		AND fa2.year = 2016
		AND fa2.region = 'World'
	;



-- What was the percent change in forest area of the world between 1990 and 2016?


SELECT (fa1.forest_area_sqkm - fa2.forest_area_sqkm )* 100 / fa1.forest_area_sqkm AS pct_change_1990_2016
	FROM forestation fa1, forestation fa2
	WHERE fa1.year = 1990
		AND fa1.region = 'World'
		AND fa2.year = 2016
		AND fa2.region = 'World'
	;



-- If you compare the amount of forest area lost between 1990 and 2016, to which country's total area in 2016 is it closest to?



SELECT country_name, 
	   ROUND(CAST(total_area_sqkm AS numeric), 2)
	FROM forestation
	WHERE year = 2016 
	 AND total_area_sqkm < (SELECT (fa1.forest_area_sqkm - fa2.forest_area_sqkm )
								 FROM forestation fa1, 
								      forestation fa2
								 WHERE fa1.year = 1990
								  AND fa1.region = 'World'
								  AND fa2.year = 2016
								  AND fa2.region = 'World')
	ORDER BY total_area_sqkm DESC
	LIMIT 1
    ;

/*
Alternative

SELECT country_name, 
	   ROUND(CAST(total_area_sqkm AS numeric), 2)
	FROM forestation
	WHERE year = 2016 AND total_area_sqkm < 1324449
	ORDER BY total_area_sqkm DESC
	LIMIT 1
	;
*/






-- Part 2 - REGIONAL OUTLOOK

CREATE VIEW region_view AS 
	SELECT year, 
		   region, 
		   sum(forest_area_sqkm) AS forest_area_sqkm, 
		   sum(total_area_sqkm) AS total_area_sqkm, 
		   sum(forest_area_sqkm)* 100/ sum(total_area_sqkm) AS forest_percent
	FROM forestation
	WHERE year IN (1990, 2016)
	GROUP BY year, region
	ORDER BY region
	;


-- What was the percent forest of the entire world in 2016? Which region had the HIGHEST percent forest in 2016, and which had the LOWEST, to 2 decimal places?

SELECT ROUND(CAST(forest_percent AS numeric), 2)
	FROM region_view
	WHERE year = 2016 AND region = 'World'
	;


SELECT region, 
	   ROUND(CAST(forest_percent AS numeric), 2)
	FROM region_view
	WHERE year = 2016
	ORDER BY forest_percent DESC
	LIMIT 1
	;



SELECT region, 
	   ROUND(CAST(forest_percent AS numeric), 2)
	FROM region_view
	WHERE year = 2016
	ORDER BY forest_percent
	LIMIT 1
	;



-- What was the percent forest of the entire world in 1990? Which region had the HIGHEST percent forest in 1990, and which had the LOWEST, to 2 decimal places?

SELECT ROUND(CAST(forest_percent AS numeric), 2)
	FROM region_view
	WHERE year = 1990 AND region = 'World'
	;


SELECT region, 
	   ROUND(CAST(forest_percent AS numeric), 2)
	FROM region_view
	WHERE year = 1990
	ORDER BY forest_percent DESC
	LIMIT 1
	;



SELECT region, 
	   ROUND(CAST(forest_percent AS numeric), 2)
	FROM region_view
	WHERE year = 1990
	ORDER BY forest_percent
	LIMIT 1
	;

-- Based on the table you created, which regions of the world DECREASED in forest area from 1990 to 2016?


SELECT * 
	FROM(SELECT region,
			ROUND(CAST(MAX(CASE WHEN year = 1990 THEN 
				forest_percent ELSE 0 END) AS numeric), 2) AS Forest_Percentage_1990,
			ROUND(CAST(MAX(CASE WHEN year = 2016 THEN 
				forest_percent ELSE 0 END) AS numeric), 2) AS Forest_Percentage_2016
		FROM region_view
		GROUP BY region) sub
	WHERE region != 'World'
	ORDER BY forest_percentage_1990 DESC
	;




SELECT * 
	FROM(SELECT region,
			ROUND(CAST(MAX(CASE WHEN year = 1990 THEN 
				forest_percent ELSE 0 END) AS numeric),2) AS Forest_Percentage_1990,
			ROUND(CAST(MAX(CASE WHEN year = 2016 THEN 
				forest_percent ELSE 0 END) AS numeric),2) AS Forest_Percentage_2016
		FROM region_view
		GROUP BY region) sub
	WHERE region = 'World'
	ORDER BY forest_percentage_1990 DESC
	;





-- Part 3 - OUNTRY-LEVEL DETAIL


WITH t1 AS(SELECT country_name, year, forest_area_sqkm AS area_1990
			FROM forest_area
			WHERE forest_area_sqkm IS NOT NULL
				AND country_name <> 'World'
				AND year = 1990
				ORDER BY forest_area_sqkm DESC),
	t2 AS(SELECT country_name, year, forest_area_sqkm AS area_2016
			FROM forest_area
			WHERE forest_area_sqkm IS NOT NULL
				AND country_name <> 'World'
				AND year = 2016)
	SELECT t1.country_name, area_1990, area_2016, 
			ROUND(CAST(area_2016 - area_1990 AS numeric), 2) AS area_difference, 
			ROUND(CAST((area_2016-area_1990)/area_1990 AS numeric) * 100, 2) 
				AS area_difference_percent
	FROM t1
		JOIN t2
			ON t1.country_name = t2.country_name
	ORDER BY area_difference DESC
	LIMIT 2
	;



WITH t1 AS(SELECT country_name, year, forest_area_sqkm AS area_1990
			FROM forest_area
			WHERE forest_area_sqkm IS NOT NULL
				AND country_name <> 'World'
				AND year = 1990
				ORDER BY forest_area_sqkm DESC),
	t2 AS(SELECT country_name, year, forest_area_sqkm AS area_2016
			FROM forest_area
			WHERE forest_area_sqkm IS NOT NULL
				AND country_name <> 'World'
				AND year = 2016)
	SELECT t1.country_name, area_1990, area_2016, 
			ROUND(CAST(area_2016 - area_1990 AS numeric), 2) AS area_difference, 
			ROUND(CAST((area_2016-area_1990)/area_1990 AS numeric) * 100, 2) 
				AS area_difference_percent
	FROM t1
		JOIN t2
			ON t1.country_name = t2.country_name
	ORDER BY area_difference_percent DESC
	LIMIT 1
	;




-- Which 5 countries saw the largest amount decrease in forest area from 1990 to 2016? What was the difference in forest area for each?


WITH t1 AS(SELECT country_name, region, forest_area_sqkm AS area_1990
			FROM forestation
			WHERE forest_area_sqkm IS NOT NULL
				AND country_name <> 'World'
				AND year = 1990
			ORDER BY forest_area_sqkm DESC),
	t2 AS(SELECT country_name, region, forest_area_sqkm AS area_2016
			FROM forestation
			WHERE forest_area_sqkm IS NOT NULL
				AND country_name <> 'World'
				AND year = 2016
			ORDER BY forest_area_sqkm DESC)
	SELECT t1.country_name, t1.region, area_1990, area_2016, 
			ROUND(CAST(area_1990-area_2016 AS numeric),2)
				AS area_difference
	FROM t1
		JOIN t2
			ON t1.country_name = t2.country_name
	ORDER BY area_difference DESC
	LIMIT 5
	;





-- Which 5 countries saw the largest percent decrease in forest area from 1990 to 2016? What was the percent change to 2 decimal places for each?


WITH t1 AS(SELECT country_name, region, forest_area_sqkm AS area_1990
			FROM forestation
			WHERE forest_area_sqkm IS NOT NULL
				AND country_name <> 'World'
				AND year = 1990
			ORDER BY forest_area_sqkm DESC),
	t2 AS(SELECT country_name, region, forest_area_sqkm AS area_2016
			FROM forestation
			WHERE forest_area_sqkm IS NOT NULL
				AND country_name <> 'World'
				AND year = 2016
			ORDER BY forest_area_sqkm DESC)
	SELECT t1.country_name, t1.region, area_1990, area_2016, 
			ROUND(CAST(area_1990-area_2016 AS numeric),2)
				AS area_difference,
			ROUND(CAST((area_1990-area_2016)/area_1990 AS numeric) * 100, 2) 
				AS area_percent
	FROM t1
		JOIN t2
			ON t1.country_name = t2.country_name
	ORDER BY area_percent DESC
	LIMIT 5
	;



-- If countries were grouped by percent forestation in quartiles, which group had the most countries in it in 2016?


WITH tb1 AS(SELECT *
				FROM forestation
				WHERE year = 2016
					AND region NOT LIKE 'World'
					AND percent_forestation IS NOT NULL), 
	tb2 AS(SELECT *,
			CASE
				WHEN percent_forestation > 75 
					THEN '75-100%'
				WHEN percent_forestation <= 75 AND percent_forestation > 50 
					THEN '50-75%'
				WHEN percent_forestation <= 50 AND percent_forestation >25 
					THEN '25-50%'
				ELSE '0-25%'
				END AS quartiles
			FROM tb1)
	SELECT quartiles,
		   COUNT(*) AS quartiles_groups
	FROM tb2
	GROUP BY quartiles
	ORDER BY quartiles
	;


-- List all of the countries that were in the 4th quartile (percent forest > 75%) in 2016.


WITH tb1 AS(SELECT *
				FROM forestation
				WHERE year = 2016
					AND region NOT LIKE 'World'
					AND percent_forestation IS NOT NULL), 
	tb2 AS(SELECT *,
			CASE
				WHEN percent_forestation > 75 
					THEN '75-100%'
				WHEN percent_forestation <= 75 AND percent_forestation > 50 
					THEN '50-75%'
				WHEN percent_forestation <= 50 AND percent_forestation >25 
					THEN '25-50%'
				ELSE '0-25%'
				END AS quartiles
			FROM tb1)
	SELECT country_name
	FROM tb2
	WHERE quartiles = '75-100%'
	;



SELECT country_name,
	   region,
	   ROUND(CAST(percent_forestation AS numeric), 2)
	FROM forestation
	WHERE percent_forestation>75
		AND percent_forestation IS NOT NULL
		AND year=2016
	ORDER BY percent_forestation DESC
	;




-- How many countries had a percent forestation higher than the United States in 2016? 


SELECT count(*)
	FROM forestation
	WHERE year = 2016
		AND country_name <> 'World'
		AND percent_forestation > 
			(SELECT percent_forestation
				FROM forestation
				WHERE year = 2016
					AND country_name = 'United States')
	;






























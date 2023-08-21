--Viewing global numbers in totality
SELECT SUM(new_cases) AS total_cases
	, SUM(new_deaths) AS total_deaths
	, (SUM(new_deaths)/SUM(new_cases))*100 AS mortality_rate
FROM CovidDeaths
WHERE continent IS NOT NULL;

--Viewing death_count by continent
SELECT location
	, SUM (total_deaths) AS total_death_count
FROM CovidDeaths
WHERE continent IS NULL
AND location NOT IN ('World', 'High Income', 'Upper Middle Income', 'Lower Middle Income', 'European Union', 'Low Income')
GROUP BY location
ORDER BY total_death_count DESC;

SELECT location
	, population
	, MAX (total_cases) AS infection_high
	, MAX (total_cases/population)*100 AS infection_rate
FROM CovidDeaths
GROUP BY location, population
ORDER BY infection_rate DESC;
--Most of these countries with low infection_rate are likely just not reporting or not reporting accurate numbers (ie England)

SELECT location
	, population
	, date
	, MAX (total_cases) AS infection_high
	, MAX (total_cases/population)*100 AS infection_rate
FROM CovidDeaths
GROUP BY location, population, date
ORDER BY infection_rate DESC;
--Most of these countries with low infection_rate are likely just not reporting or not reporting accurate numbers (ie England)
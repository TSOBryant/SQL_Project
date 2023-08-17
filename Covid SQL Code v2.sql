--Viewing tables CovidDeaths and CovidVaccinations
SELECT * FROM CovidDeaths
ORDER BY location, date DESC;

SELECT * FROM CovidVaccinations
ORDER BY location, date DESC;

--Viewing pertinent data from CovidDeaths table
SELECT location
	, date
	, total_cases
	, new_cases
	, total_deaths
	, population
FROM CovidDeaths
ORDER BY location, date DESC;

--Viewing random countries to see dates of data reporting (choosing France, South Korea, United States, England, Canada, Turkey, Argentina)
SELECT location
	, date
	, total_cases
	, new_cases
	, total_deaths
	, population
FROM CovidDeaths
WHERE location IN ('France', 'South Korea', 'United States', 'England', 'Canada', 'Turkey', 'Argentina')
AND NOT new_cases = 0
ORDER BY location, date DESC;
--**Note that England does not report data, but is included in CovidDeaths table (see United Kingdom instead)
--This is accurate as it matches the original data from Excel file

--Adding new column to see the death percentage of all countries
SELECT location
	, date
	, total_cases
	, total_deaths
	, (total_deaths/total_cases)*100 AS mortality_rate
FROM CovidDeaths
ORDER BY location, date DESC;
--Error: "Operand data type nvarchar is invalid for divide operator."

--Looking at our data types
EXEC sp_help CovidDeaths;
--total_deaths and total_cases are nvarchar so must convert to int for aggregates

--Converting total_deaths and total_cases to FLOAT
ALTER TABLE CovidDeaths
ALTER COLUMN total_cases FLOAT;

ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths FLOAT;

--Rerunning above query to create new column mortality_rate after conversion of data types, using South Korea
--This shows us the percent of people that get covid in South Korea that die from it
SELECT location
	, date
	, total_cases
	, total_deaths
	, (total_deaths/total_cases)*100 AS mortality_rate
FROM CovidDeaths
WHERE location = 'South Korea'
ORDER BY date DESC;

--Viewing the percentage of population that contract covid
SELECT location
	, date
	, population
	, total_cases
	, (total_cases/population)*100 AS infection_rate
FROM CovidDeaths
WHERE location = 'South Korea'
ORDER BY date DESC;
--We see the infection_rate as around 64% as of 8/9/23
--**Note: There are reinfections so this number will show skewed. We do not know by how much

--Comparing countries with Highest and Lowest infection_rate
SELECT location
	, population
	, MAX (total_cases) AS infection_high
	, MAX (total_cases/population)*100 AS infection_rate
FROM CovidDeaths
GROUP BY location, population
ORDER BY infection_rate DESC;

SELECT location
	, population
	, MAX (total_cases) AS infection_high
	, MAX (total_cases/population)*100 AS infection_rate
FROM CovidDeaths
GROUP BY location, population
ORDER BY infection_rate;
--Most of these countries with low infection_rate are likely just not reporting or not reporting accurate numbers (ie England)

--Viewing the total death_count per country
SELECT location
	, MAX (total_deaths) AS death_count
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY death_count DESC;

--Viewing death_count by continent
SELECT location
	, MAX (total_deaths) AS death_count
FROM CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY death_count DESC;

--Viewing global numbers by date
SELECT date
	, SUM(new_cases) AS cases_this_date
	, SUM(new_deaths) AS deaths_this_date
	, (SUM(new_deaths)/SUM(new_cases))*100 AS mortality_rate
FROM CovidDeaths
WHERE continent IS NOT NULL
AND NOT new_cases = 0
GROUP BY date
ORDER BY date;

--Viewing global numbers in totality
SELECT SUM(new_cases) AS cases_this_date
	, SUM(new_deaths) AS deaths_this_date
	, (SUM(new_deaths)/SUM(new_cases))*100 AS mortality_rate
FROM CovidDeaths
WHERE continent IS NOT NULL
AND NOT new_cases = 0;

--Joining the CovidVaccinations table to CovidDeaths table to view vaccinations vs population
--Because we don't have primary keys, we will combine on two columns, location and date
SELECT Dea.continent
	, Dea.location
	, Dea.date
	, Dea.population
	, Vac.new_vaccinations
	, SUM(CONVERT(FLOAT, Vac.new_vaccinations)) 
		OVER (PARTITION BY Dea.location
		ORDER BY Dea.location, Dea.date) AS running_vaccination_count --Adding the running_vaccination_count column
FROM CovidDeaths Dea
	JOIN CovidVaccinations Vac
	ON Dea.location = Vac.location
	AND Dea.date = Vac.date
WHERE Dea.continent IS NOT NULL
ORDER BY 2, 3;

--We want our above query but need to use the running_vaccination_count column for an aggregate function (rate), so we must use CTE or Temp Table
--Using CTE (common table expression)
WITH PopVsVac (continent, location, date, population, new_vaccinations, running_vaccination_count)
AS 
(
	SELECT Dea.continent
		, Dea.location
		, Dea.date
		, Dea.population
		, Vac.new_vaccinations
		, SUM(CONVERT(FLOAT, Vac.new_vaccinations)) 
			OVER (PARTITION BY Dea.location
			ORDER BY Dea.location, Dea.date) AS running_vaccination_count --Adding the running_vaccination_count column
		--, (running_vaccination_count/population)*100 AS vaccination_rate -- this code is shown below because we needed to create the CTE first
	FROM CovidDeaths Dea
		JOIN CovidVaccinations Vac
		ON Dea.location = Vac.location
		AND Dea.date = Vac.date
	WHERE Dea.continent IS NOT NULL
	)
		SELECT *
			, (running_vaccination_count/population)*100 AS vaccination_rate --this gives us the percent of population vaccinated
		FROM PopVsVac;

--Using Temp Table
--DROP TABLE IF EXISTS #PercentPopulationVaccinated -- this code is in case we need to alter the Temp Table
CREATE TABLE #PercentPopulationVaccinated
	(continent nvarchar(255)
	, location nvarchar(255)
	, date datetime
	, population numeric
	, new_vaccinations numeric
	, running_vaccination_count numeric)
INSERT INTO #PercentPopulationVaccinated
	SELECT Dea.continent
			, Dea.location
			, Dea.date
			, Dea.population
			, Vac.new_vaccinations
			, SUM(CONVERT(FLOAT, Vac.new_vaccinations)) 
				OVER (PARTITION BY Dea.location
				ORDER BY Dea.location, Dea.date) AS running_vaccination_count --Adding the running_vaccination_count column
			--, (running_vaccination_count/population)*100 AS vaccination_rate -- this code is shown in below because we needed to create the CTE first
		FROM CovidDeaths Dea
			JOIN CovidVaccinations Vac
			ON Dea.location = Vac.location
			AND Dea.date = Vac.date
		WHERE Dea.continent IS NOT NULL
			SELECT *
				, (running_vaccination_count/population)*100 AS vaccination_rate --this gives us the percent of population vaccinated
			FROM #PercentPopulationVaccinated;

--Creating View for visualizations
CREATE VIEW PercentPopulationVaccinated
AS
	SELECT Dea.continent
			, Dea.location
			, Dea.date
			, Dea.population
			, Vac.new_vaccinations
			, SUM(CONVERT(FLOAT, Vac.new_vaccinations)) 
				OVER (PARTITION BY Dea.location
				ORDER BY Dea.location, Dea.date) AS running_vaccination_count --Adding the running_vaccination_count column
			--, (running_vaccination_count/population)*100 AS vaccination_rate -- commenting out temporarily
		FROM CovidDeaths Dea
			JOIN CovidVaccinations Vac
			ON Dea.location = Vac.location
			AND Dea.date = Vac.date
		WHERE Dea.continent IS NOT NULL;
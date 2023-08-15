/*
Exploratory Data Analysis with COVID-19 data
Data source can be obtained from https://ourworldindata.org/covid-deaths
*/

--Taking a look on our data:
SELECT location, continent
FROM portfolio_project.dbo.CovidData

--Here we can find that the data have NULL values on the 'continent' variable, therefore we need to query without those values
SELECT continent,location, population
FROM portfolio_project.dbo.CovidData
GROUP BY continent,location, population
ORDER BY continent, location

--historically cases and deaths all over the world:
SELECT
	location,
	date,
	population,
	total_cases,
	total_deaths,
	(CAST(total_deaths AS numeric)/CAST(total_cases AS numeric))*100 AS death_percentage
FROM portfolio_project.dbo.CovidData
WHERE continent IS NOT NULL
ORDER BY location, date;

--total cases and deaths per country:
SELECT
	location,
	population,
	SUM(new_cases) total_cases,
	SUM(new_deaths) total_deaths,
	SUM(new_deaths)/SUM(new_cases)*100 mortality_percentage
FROM portfolio_project.dbo.CovidData
WHERE continent IS NOT NULL
GROUP BY location, population
HAVING SUM(new_cases) <> 0
ORDER BY location;

--countries with zero cases and deaths (lack of data?)
SELECT
	location,
	population,
	SUM(new_cases) total_cases,
	SUM(new_deaths) total_deaths
FROM portfolio_project.dbo.CovidData
WHERE continent IS NOT NULL
GROUP BY location, population
HAVING SUM(new_cases) = 0 OR SUM(new_deaths) = 0
ORDER BY location;

--total deaths and cases over the world:
SELECT
	SUM(new_cases) total_cases,
	SUM(new_deaths) total_deaths
FROM portfolio_project.dbo.CovidData
WHERE continent IS NOT NULL

-------------------------------------------------------------------------
--Total Cases vs Population:
--shows what percent of population got covid over time:
SELECT
	location,
	date,
	total_cases,
	population,
	(CAST(total_cases AS numeric)/CAST(population AS numeric))*100 AS case_percentage
FROM portfolio_project.dbo.CovidData
WHERE continent IS NOT NULL
ORDER BY 1,2

---------------------------------------------------
--INFECTION RATE:
--what country has the highest infection rate? Cyprus (chipre) with ~73%
--Countries with highest infection rate compared to population:
SELECT
	location,
	population,
	MAX(total_cases) AS infection_count,
	MAX((CAST(total_cases AS numeric)/CAST(population AS numeric)))*100 AS infection_rate
FROM portfolio_project.dbo.CovidData
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY infection_rate desc;

--------------------------------------------------------
--countries with highest death count per population:
SELECT
	location,
	population,
	MAX(CAST(total_deaths AS int)) AS total_death_count,
	MAX((CAST(total_deaths AS numeric)/CAST(population AS numeric)))*100 AS death_percentage
FROM portfolio_project.dbo.CovidData
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY death_percentage DESC;

-------------------------------------------------------
--deaths per 1mi people:
SELECT
	location,
	population,
	MAX(CAST(total_deaths AS int)) AS total_death_count,
	MAX((CAST(total_deaths AS numeric)/CAST(population AS numeric)))*1000000 AS deaths_per_1mi
FROM portfolio_project.dbo.CovidData
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY location;

--cases per 1mi people:
SELECT
	location,
	population,
	MAX(CAST(total_cases AS int)) AS total_death_count,
	MAX((CAST(total_cases AS numeric)/CAST(population AS numeric)))*1000000 AS deaths_per_1mi
FROM portfolio_project.dbo.CovidData
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY location;


-----------------------------
--COVID VACCINATIONS
--Total Vaccinations over the world:
SELECT 
	location,
	date,
	population,
	new_vaccinations,
	SUM(CONVERT(numeric,new_vaccinations)) OVER
		(
		PARTITION BY location
		Order by location, date
		ROWS UNBOUNDED PRECEDING
		) AS vaccines_distribuited
FROM portfolio_project.dbo.CovidData
WHERE continent IS NOT NULL
GROUP BY location,date,new_vaccinations,population
ORDER BY location, date

--Total population and vaccines distribuited
--Creating a CTE

WITH CTE_Vaccs_vs_Population 
(continent,	location,date,population,new_vaccinations,vaccines_distribuited)
	AS
		(
		 SELECT
			continent,
			location,
			date,
			population,
			new_vaccinations,
			SUM(CONVERT(numeric,new_vaccinations))
				OVER
					(
					 PARTITION BY location
					 ORDER BY location, date
					 ROWS UNBOUNDED PRECEDING
					 ) AS vaccines_distribuited
		 FROM portfolio_project.dbo.CovidData
		 WHERE continent IS NOT NULL
		)
	SELECT *,(vaccines_distribuited/population)*100 AS vaccinations_vs_population_ratio
	FROM CTE_Vaccs_vs_Population 



-------------------------------------------
--Creating TEMP TABLES:

DROP TABLE IF EXISTS #percent_population_vaccinated
CREATE TABLE #percent_population_vaccinated
(
 continent nvarchar(255),
 location nvarchar(255),
 date date,
 population numeric,
 new_vaccinations numeric,
 vaccines_distribuited numeric
)
 

INSERT INTO #percent_population_vaccinated
SELECT
	continent,
	location,
	date,
	population,
	new_vaccinations,
	SUM(CONVERT(numeric,new_vaccinations))
		OVER
		(
		 PARTITION BY location
		 ORDER BY location, date
		 ROWS UNBOUNDED PRECEDING
		 ) AS vaccines_distribuited
FROM portfolio_project.dbo.CovidData
WHERE continent IS NOT NULL

SELECT *, (vaccines_distribuited/population)*100 AS vaccinations_vs_population_ratio
FROM #percent_population_vaccinated




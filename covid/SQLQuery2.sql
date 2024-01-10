SELECT *
FROM PortfolioProject..covidDeaths
ORDER BY 3,4;

SELECT *
FROM PortfolioProject..covidVaccinations
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..covidDeaths
ORDER BY 1,2;

-- Total reported cases vs total deaths

SELECT location, date, total_cases, total_deaths, ROUND((CAST(total_deaths AS float)/CAST(total_cases AS float))*100, 4) AS death_percentage
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total cases vs population

SELECT location, date, total_cases, population, ROUND((CAST(total_cases AS float)/population)*100, 4) AS infection_percentage
FROM PortfolioProject..covidDeaths
WHERE location = 'United States'
ORDER BY 1,2;

-- Countries with highest reported number of infections compared to population

SELECT location, population, MAX(CAST(total_cases AS float)) AS highest_infection_count, MAX(CAST(total_cases AS float)/population)*100 AS percent_reported_infections_vs_population
FROM PortfolioProject..covidDeaths
GROUP BY location, population
ORDER BY percent_reported_infections_vs_population DESC;

-- Countries with highest COVID-related deaths vs population

SELECT location, population, MAX(CAST(total_deaths AS float)) AS total_deaths, MAX(CAST(total_deaths AS float)/population)*100 AS percent_reported_deaths_vs_population
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_reported_deaths_vs_population DESC;

-- Ranking countries by number of COVID-related deaths

SELECT location, population, MAX(CAST(total_deaths AS float)) AS total_deaths
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY total_deaths DESC;

-- Ranking continents by number of COVID-related deaths (total deaths included)

SELECT location, MAX(CAST(total_deaths AS float)) AS total_deaths
FROM PortfolioProject..covidDeaths
WHERE continent IS NULL
	AND location NOT LIKE '%income%'
	AND location NOT LIKE '%European Union%'
GROUP BY location
ORDER BY total_deaths DESC;

-- Used the query below to try to determine which locations needed to be excluded from the query above

SELECT DISTINCT location
FROM PortfolioProject..covidDeaths
WHERE continent = 'Oceania';

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL;

-- Total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location
	ORDER BY dea.location, dea.date) AS rolling_vac_count
FROM PortfolioProject..covidDeaths dea
JOIN PortfolioProject..covidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

-- CTE

WITH popVsVac (continent, location, date, population, new_vaccinations, rolling_vac_count) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location
	ORDER BY dea.location, dea.date) AS rolling_vac_count
FROM PortfolioProject..covidDeaths dea
JOIN PortfolioProject..covidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, ROUND((rolling_vac_count/population)*100, 4) AS vacs_vs_pop_as_percent
FROM popVsVac

-- TEMP TABLE

DROP TABLE IF EXISTS #percentPopulationVaccinated
CREATE TABLE #percentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vac_count numeric
)
INSERT INTO #percentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location
	ORDER BY dea.location, dea.date) AS rolling_vac_count
FROM PortfolioProject..covidDeaths dea
JOIN PortfolioProject..covidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (rolling_vac_count/population)*100
FROM #percentPopulationVaccinated




-- Creating views to store for visualizations

DROP VIEW IF EXISTS percentPopulationVaccinated

CREATE VIEW percentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location
	ORDER BY dea.location, dea.date) AS rolling_vac_count
FROM PortfolioProject..covidDeaths dea
JOIN PortfolioProject..covidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

-- The query below can be run to verify the view exists (if it exists, and it is not showing in the Views folder, 
-- try closing software, dropping the view, and re-running query. Also, don't forget to refresh)

SELECT * 
FROM information_schema.views 
WHERE table_name = 'percentPopulationVaccinated';

-- Cases vs deaths by country

DROP VIEW IF EXISTS casesVersusDeaths

CREATE VIEW casesVersusDeaths AS
SELECT location, date, total_cases, total_deaths, ROUND((CAST(total_deaths AS float)/CAST(total_cases AS float))*100, 4) AS death_percentage
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL

-- Infections vs population

DROP VIEW IF EXISTS infectionsVsPopulation

CREATE VIEW infectionsVsPopulation AS
SELECT location, population, date, MAX(CAST(total_cases AS float)) AS highest_infection_count, MAX(CAST(total_cases AS float)/population)*100 AS percent_reported_infections_vs_population
FROM PortfolioProject..covidDeaths
GROUP BY location, population, date
ORDER BY percent_reported_infections_vs_population DESC

-- Number of COVID-related deaths vs country population

DROP VIEW IF EXISTS deathsVsPopulation

CREATE VIEW deathsVsPopulation AS
SELECT location, population, MAX(CAST(total_deaths AS float)) AS total_deaths, MAX(CAST(total_deaths AS float)/population)*100 AS percent_reported_deaths_vs_population
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population

-- Total COVID-related deaths by country

DROP VIEW IF EXISTS deathsByCountry

CREATE VIEW deathsByCountry AS
SELECT location, population, MAX(CAST(total_deaths AS float)) AS total_deaths
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population

-- Total COVID-related deaths by continent

DROP VIEW IF EXISTS deathsByContinent

CREATE VIEW deathsByContinent AS
SELECT location, MAX(CAST(total_deaths AS bigint)) AS total_deaths
FROM PortfolioProject..covidDeaths
WHERE continent IS NULL
	AND location NOT IN ('European Union', 'World')
	AND location NOT LIKE ('%income%')
GROUP BY location
ORDER BY total_deaths DESC



-- The queries that went on to create Tableau tables:

-- 1.
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL;

-- 2.
SELECT location, MAX(CAST(total_deaths AS bigint)) AS total_deaths
FROM PortfolioProject..covidDeaths
WHERE continent IS NULL
	AND location NOT IN ('European Union', 'World')
	AND location NOT LIKE ('%income%')
GROUP BY location
ORDER BY total_deaths DESC

-- 3.
SELECT location, population, MAX(CAST(total_deaths AS float)) AS total_deaths, MAX(CAST(total_deaths AS float)/population)*100 AS percent_reported_deaths_vs_population
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_reported_deaths_vs_population DESC

-- 4.
SELECT location, population, date, MAX(CAST(total_deaths AS float)) AS total_deaths, MAX(CAST(total_deaths AS float)/population)*100 AS percent_reported_deaths_vs_population
FROM PortfolioProject..covidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population, date
ORDER BY percent_reported_deaths_vs_population DESC
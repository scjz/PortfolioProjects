SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

--SELECT *
--FROM CovidVaccinations
--ORDER BY location, date

-- Select Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date

-- Total Cases vs Total Deaths
-- Likelihood of dying if you contract covid
SELECT location, date, total_cases, total_deaths, 
	(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Singapore'
ORDER BY location, date

-- Total Cases vs Population
SELECT location, date, total_cases, population,
	(total_cases/population)*100 AS '%Infected'
FROM PortfolioProject..CovidDeaths
WHERE location = 'Singapore'
ORDER BY location, date

-- Countries with Highest Infection Rate compared to Population
SELECT location, MAX(total_cases) AS HighestInfectionCount,
	population,
	MAX(total_cases/population)*100 AS '%Infected'
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY '%Infected' DESC

-- Countries with Highest Death Rate compared to Population
SELECT location, 
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount,
	population
	--MAX(total_deaths/population)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY TotalDeathCount DESC

-- Continent with Highest Death Rate compared to Population
SELECT continent, 
	MAX(CAST(total_deaths AS int)) AS TotalDeathCount,
	MAX(total_deaths/population)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- Global numbers
SELECT SUM(new_cases) AS TotalCases, 
	SUM(CAST(new_deaths as INT)) AS TotalDeaths,
	SUM(CAST(new_deaths as INT))/SUM(new_cases)*100 as DeathPerncetage
From PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL

-- Total population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, population,
	vac.new_vaccinations
FROM PortfolioProject..CovidDeaths AS dea
INNER JOIN PortfolioProject..CovidVaccinations AS vac 
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Cumulative count of vaccinations using Partition By
SELECT dea.continent, dea.location, dea.date, population,
	vac.new_vaccinations,
	SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS CumulativeVac
FROM PortfolioProject..CovidDeaths AS dea
INNER JOIN PortfolioProject..CovidVaccinations AS vac 
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- Use CTE
WITH CTE_CumulativeVac AS (
	SELECT dea.continent, dea.location, dea.date, population,
		vac.new_vaccinations,
		SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS CumulativeVac
	FROM PortfolioProject..CovidDeaths AS dea
	INNER JOIN PortfolioProject..CovidVaccinations AS vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
SELECT *, (CumulativeVac/population)*100
FROM CTE_CumulativeVac

-- TEMP Table
DROP TABLE IF EXISTS #PercentVac
CREATE TABLE #PercentVac
	(continent VARCHAR(255),
	location VARCHAR(255),
	date DATETIME,
	population BIGINT,
	new_vaccinations BIGINT,
	CumulativeVac BIGINT)

INSERT INTO #PercentVac
	SELECT dea.continent, dea.location, dea.date, population,
		vac.new_vaccinations,
		SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS CumulativeVac
	FROM PortfolioProject..CovidDeaths AS dea
	INNER JOIN PortfolioProject..CovidVaccinations AS vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL

SELECT *, (CumulativeVac/population)*100 AS PercentVac
FROM #PercentVac

-- Creating Views
CREATE VIEW PercentVac AS(
	SELECT dea.continent, dea.location, dea.date, population,
		vac.new_vaccinations,
		SUM(CAST(new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.Date) AS CumulativeVac
	FROM PortfolioProject..CovidDeaths AS dea
	INNER JOIN PortfolioProject..CovidVaccinations AS vac 
	ON dea.location = vac.location
	AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
)
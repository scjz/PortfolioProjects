SELECT *
FROM PortfolioProject..CovidDeaths

SELECT date, location, population, total_cases, new_cases, total_deaths, new_deaths
FROM PortfolioProject..CovidDeaths
WHERE location = 'Singapore'
ORDER BY date

-- Percentage of population infected
SELECT date, location, population, total_cases, new_cases, total_deaths, new_deaths,
	(total_cases/population)*100 AS PercentInfected
FROM PortfolioProject..CovidDeaths
WHERE location = 'Singapore'
ORDER BY date

-- Percentage of fatal covid cases
SELECT date, location, population, total_cases, new_cases, total_deaths, new_deaths,
	(total_cases/population)*100 AS PercentInfected,
	(total_deaths/total_cases)*100 AS PercentFatal
FROM PortfolioProject..CovidDeaths
WHERE location = 'Singapore'
ORDER BY date

-- Months with the highest infection rate
SELECT 
	MONTH(date) AS MonthOnly,
	YEAR(date) AS YearOnly,
	SUM(CAST(new_cases AS INT)) AS monthly_cases,
	SUM(CAST(new_deaths AS INT)) AS monthly_deaths
FROM PortfolioProject..CovidDeaths
WHERE location = 'Singapore'
GROUP BY MONTH(date), YEAR(date)
ORDER BY monthly_cases DESC
-- Month of October 21 has the highest infection and death rate

SELECT *
FROM PortfolioProject..CovidVaccinations
WHERE location = 'Singapore'

-- Vaccinated information
SELECT dea.date, dea.location, dea.population, dea.total_cases, dea.new_cases, dea.total_deaths, dea.new_deaths, 
	new_vaccinations, SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS CumulativeVaccinated,
	(dea.total_cases/dea.population)*100 AS PercentInfected,
	(dea.total_deaths/dea.total_cases)*100 AS PercentFatal
FROM PortfolioProject..CovidDeaths AS dea
INNER JOIN PortfolioProject..CovidVaccinations AS vac ON
dea.location = vac.location AND
dea.date = vac.date
WHERE dea.location = 'Singapore'
ORDER BY date

-- Percentage vaccinated
-- Using CTE

WITH CTE_vaccination AS (
	SELECT dea.date, dea.location, dea.population, dea.total_cases, dea.new_cases, dea.total_deaths, dea.new_deaths, 
		new_vaccinations, SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS CumulativeVaccinated,
		(dea.total_cases/dea.population)*100 AS PercentInfected,
		(dea.total_deaths/dea.total_cases)*100 AS PercentFatal
	FROM PortfolioProject..CovidDeaths AS dea
	INNER JOIN PortfolioProject..CovidVaccinations AS vac ON
	dea.location = vac.location AND
	dea.date = vac.date
	WHERE dea.location = 'Singapore'
)

SELECT *,
	(CumulativeVaccinated/population)*100 AS PercentVaccinated
FROM CTE_vaccination

-- Save as VIEW
DROP VIEW IF EXISTS SingaporeCovid

CREATE VIEW SingaporeCovid AS
WITH CTE_vaccination AS (
	SELECT dea.date, dea.location, dea.population, dea.total_cases, dea.new_cases, dea.total_deaths, dea.new_deaths, 
		new_vaccinations, SUM(CAST(new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS CumulativeVaccinated,
		(dea.total_cases/dea.population)*100 AS PercentInfected,
		(dea.total_deaths/dea.total_cases)*100 AS PercentFatal
	FROM PortfolioProject..CovidDeaths AS dea
	INNER JOIN PortfolioProject..CovidVaccinations AS vac ON
	dea.location = vac.location AND
	dea.date = vac.date
	WHERE dea.location = 'Singapore'
)
SELECT *,
	(CumulativeVaccinated/population)*100 AS PercentVaccinated
FROM CTE_vaccination


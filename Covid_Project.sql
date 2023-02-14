
USE SQL_Portfolio

--*****Important Note: 
-- 1)	The WHERE clause "WHERE continent is Not Null is used constantly to filter out the 
		--continents as a 'location' (country), otherwise it completely inflates the number when aggregating
--2)	I was personally interested in exploring the data for Sudan. So, in the code I have a filter applied for Sudan (but commented out)

SELECT *
FROM SQL_Portfolio..CovidDeaths
WHERE continent is NOT NULL 
ORDER BY 3,4


-- Select the Data that I will be using:
SELECT 
	[Location], 
	[date], 
	[total_cases], 
	[new_cases], 
	[total_deaths], 
	[population]
FROM SQL_Portfolio..CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2

-- Countries: Total Cases vs Total Deaths (percentage of death cases relative to infection cases)
SELECT 
	[Location], 
	[date], 
	[total_cases], 
	[new_cases], 
	[total_deaths], 
	ROUND(((total_deaths/total_cases)*100), 2) AS [% Death/Cases]
FROM SQL_Portfolio..CovidDeaths
WHERE continent is not NULL
	--AND Location LIKE 'Sudan%'
ORDER BY 1,2

--Countries: Total Cases vs Population (Percentage of cases relative to population)
SELECT 
	[Location], 
	[date], 
	[population], 
	[total_cases], 
	(total_cases/population)*100 AS [% cases/population]
FROM SQL_Portfolio..CovidDeaths
WHERE continent is not NULL
	--AND Location LIKE 'Sudan%'
ORDER BY 1,2

--Countries: the highest infection rate relative to population
SELECT 
	[Location], 
	[population], 
	MAX(total_cases) as [Highest Infection Count], 
	ROUND(MAX((total_cases/population))*100, 3) AS [Peak % cases/population]
FROM SQL_Portfolio..CovidDeaths
WHERE continent is not NULL
	--	AND Location LIKE 'Sudan%'
GROUP BY location, population
ORDER BY 4 DESC

--Countries: with the highest death counts
SELECT 
	[Location], 
	MAX(CAST(total_deaths as Int)) as [Total Death Count]
FROM SQL_Portfolio..CovidDeaths
WHERE continent is not NULL
	--AND Location LIKE 'Sudan%'
GROUP BY Location
ORDER BY 2 DESC


-- ****A breakdown by Continent/Continental aggregations**** 

--Continents: showing the highest death counts in each continent/aggregation
SELECT 
	[location], 
	MAX(CAST(total_deaths as Int)) as [Total Death Count]
FROM SQL_Portfolio..CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY 2 DESC

-- Continents: Total Cases vs Total Deaths
SELECT 
	[continent], 
	[date], 
	[total_cases], 
	[total_deaths], 
	(total_deaths/total_cases)*100 AS [% Death/Cases]
FROM SQL_Portfolio..CovidDeaths
WHERE continent is NOT NULL
ORDER BY 1,2



-- ********GLOBAL*********

SELECT 
	[date], 
	SUM(new_cases) AS [Global Total Case], 
	SUM(CAST(new_deaths as Int)) AS [Clobal Total Deaths], 
	ROUND(SUM(CAST(new_deaths as Int))/SUM(new_cases) *100,3) AS [Global % Death/Cases]
FROM SQL_Portfolio..CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY 1

SELECT 
	SUM(new_cases) AS [Global Total Cases], 
	SUM(CAST(new_deaths as Int)) AS [Global Total Deaths], 
	ROUND(SUM(CAST(new_deaths as Int))/SUM(new_cases) *100, 3) AS [Global % Death/Cases]
FROM SQL_Portfolio..CovidDeaths
WHERE continent is not NULL


--Total Population vs Vaccination
SELECT 
	D.continent, 
	D.location, 
	D.date, 
	D.population, 
	V.new_vaccinations,
	ROUND(SUM(CONVERT(BigInt, V.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.location, D.date), 3) As [Rolling Vacc Count]
FROM SQL_Portfolio..CovidDeaths D 
JOIN SQL_Portfolio..CovidVaccinations V
	ON D.Location = V.Location
	AND D.date = V.date
WHERE D.continent is NOT NULL
ORDER BY 2,3


--** Now I try to get the percent of the population vaccinated (in a rolling basis)
	-- In order to do that I have to construct a table with calculated rolling sum of vaccinated people and the use it get the %
	-- Below I try two methods to accomplish the above: Using the CTE method and the Temp Table method


--Using CTE--

WITH PopVsVacc (continent, location, date, population, new_vaccinations, [Rolling Vacc Count]) 
AS 
(
SELECT 
	D.continent, 
	D.location, 
	D.date, 
	D.population, 
	V.new_vaccinations, 
	SUM(CONVERT(BigInt, V.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) As [Rolling Vacc Count]
FROM SQL_Portfolio..CovidDeaths D 
JOIN SQL_Portfolio..CovidVaccinations V
	ON D.Location = V.Location
	AND D.date = V.date
WHERE D.continent is NOT NULL
)

SELECT 
	*, 
	([Rolling Vacc Count]/population)*100 [% Vaccinated/Population]
FROM PopVsVacc

--Temporary Table method
DROP Table if exists PopVsVacc
CREATE Table PopVsVacc 
(
	continent nvarchar(255), 
	location nvarchar(255), 
	date datetime, 
	population numeric, 
	new_vaccinations numeric, 
	[Rolling Vacc Count] numeric
)
INSERT INTO PopVsVacc
SELECT 
	D.continent, 
	D.location, 
	D.date, 
	D.population, 
	V.new_vaccinations,
	SUM(CONVERT(BigInt, V.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) As [Rolling Vacc Count]
FROM SQL_Portfolio..CovidDeaths D 
JOIN SQL_Portfolio..CovidVaccinations V
	ON D.Location = V.Location
	AND D.date = V.date
WHERE D.continent is NOT NULL
--ORDER by 2,3

SELECT *, ([Rolling Vacc Count]/population)*100 as [% Vaccinated/Population]
FROM PopVsVacc


--*********************************************************************************************
--*************************Creating the View Tables for Tableau Visuals************************
--*********************************************************************************************

-- 1) Countries: Total Cases vs Total Deaths
CREATE OR ALTER VIEW Countries_CasesVsPopulation AS
	SELECT 
		[Location], 
		[date], 
		[total_cases], 
		[new_cases], 
		[total_deaths], 
		ROUND(((total_deaths/total_cases)*100), 2) AS [% Death/Cases]
	FROM SQL_Portfolio..CovidDeaths
	WHERE continent is not NULL
		--AND Location LIKE 'Sudan%'
	--ORDER BY 1,2


--2) Countries: Total Cases vs Total Deaths
CREATE OR ALTER VIEW Countries_CasesVspopulation AS
	SELECT 
		[Location], 
		[date], 
		[population], 
		[total_cases], 
		(total_cases/population)*100 AS [% cases/population]
	FROM SQL_Portfolio..CovidDeaths
	WHERE continent is not NULL
		--AND Location LIKE 'Sudan%'
	--ORDER BY 1,2



--3) Countries: the highest infection rate compared to population
CREATE OR ALTER VIEW Countries_HighestInfectionRate AS
	SELECT 
		[Location], 
		[population], 
		MAX(total_cases) as [Highest Infection Count], 
		ROUND(MAX((total_cases/population))*100, 3) AS [Peak % cases/population]
	FROM SQL_Portfolio..CovidDeaths
	WHERE continent is not NULL
		--	AND Location LIKE 'Sudan%'
	GROUP BY location, population
	--ORDER BY 4 DESC


--4) Countries: with the highest death counts per population
CREATE OR ALTER VIEW Countries_HighestDeathRate AS
	SELECT 
		[Location], 
		MAX(CAST(total_deaths as Int)) as [Total Death Count]
	FROM SQL_Portfolio..CovidDeaths
	WHERE continent is not NULL
		--AND Location LIKE 'Sudan%'
	GROUP BY Location
	--ORDER BY 2 DESC


--5) Continents: showing the highest death counts in each continent/aggregation
CREATE OR ALTER VIEW Continent_HighestDeathRate AS
	SELECT 
		[location], 
		MAX(CAST(total_deaths as Int)) as [Total Death Count]
	FROM SQL_Portfolio..CovidDeaths
	WHERE continent is NULL
	GROUP BY location
	--ORDER BY 2 DESC


--6) Continents: Total Cases vs Total Deaths
CREATE OR ALTER VIEW Continent_CasesVsDeath AS
	SELECT 
		[continent], 
		[date], 
		[total_cases], 
		[total_deaths], 
		(total_deaths/total_cases)*100 AS [% Death/Cases]
	FROM SQL_Portfolio..CovidDeaths
	WHERE continent is NOT NULL
	--ORDER BY 1,2


-- 7) Global: Cases vs Deaths
CREATE OR ALTER VIEW Global_CasesVsDeath AS
	SELECT 
		[date], 
		SUM(new_cases) AS [Global Total Case], 
		SUM(CAST(new_deaths as Int)) AS [Clobal Total Deaths], 
		ROUND(SUM(CAST(new_deaths as Int))/SUM(new_cases) *100,3) AS [Global % Death/Cases]
	FROM SQL_Portfolio..CovidDeaths
	WHERE continent is not NULL
	GROUP BY date
	--ORDER BY 1



--8) A rolling count of countries' new vaccinations
CREATE OR ALTER VIEW RollingVaccinationCount AS
	WITH PopVsVacc (continent, location, date, population, new_vaccinations, [Rolling Vacc Count]) 
	AS 
	(
		SELECT 
			D.continent, 
			D.location, 
			D.date, 
			D.population, 
			V.new_vaccinations, 
			SUM(CONVERT(BigInt, V.new_vaccinations)) OVER (PARTITION BY D.location ORDER BY D.location, D.date) As [Rolling Vacc Count]
		FROM SQL_Portfolio..CovidDeaths D 
		JOIN SQL_Portfolio..CovidVaccinations V
			ON D.Location = V.Location
			AND D.date = V.date
		WHERE D.continent is NOT NULL
	)

	SELECT *, 
		([Rolling Vacc Count]/population)*100 [% Vaccinated/Population]
	FROM PopVsVacc

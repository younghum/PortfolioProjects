-- Original data

SELECT *
FROM model..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT *
FROM model..CovidVaccinations
ORDER BY 3,4;



-- Select data to be used
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM model..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;



-- Total Cases vs Total Deaths
-- Shows likelihood of dying of covid in your country
SELECT location, date, total_cases, total_deaths, CAST(total_deaths AS float) / CAST(total_cases AS float) * 100 AS death_percentage
FROM model..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;



-- Total Cases vs Total Deaths in United States
-- Shows likelihood of dying of covid in the United States
SELECT location, date, total_cases, total_deaths, CAST(total_deaths AS float) / CAST(total_cases AS float) * 100 AS death_percentage
FROM model..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2;



-- Total Cases vs Population
-- Shows percentage of population who got covid
SELECT location, date, population, total_cases, CAST(total_cases AS float) / CAST(population AS float) * 100 AS case_percentage
FROM model..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;



-- Countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX(CAST(total_cases AS float) / CAST(population AS float)) * 100 AS percent_infected
FROM model..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_infected DESC;



-- Countries with highest total death count
SELECT location, MAX(CAST(total_deaths AS float)) AS total_death_count_2
FROM model..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count_2 DESC;



-- Countries with Highest Death Count per Population
SELECT location, population, MAX(CAST(total_deaths AS float)) AS total_death_count, MAX(CAST(total_deaths AS float) / CAST(population AS float)) * 100 AS percent_deaths
FROM model..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_deaths DESC;



-- Breaking things down by continent
SELECT continent, MAX(CAST(total_deaths AS float)) AS total_death_count
FROM model..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;



-- Continents with the highest death count per population
SELECT continent, MAX(CAST(total_deaths AS float)) AS total_death_count, MAX(CAST(total_deaths AS float) / CAST(population AS float)) * 100 AS percent_deaths
FROM model..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY percent_deaths DESC;



-- Global numbers
SELECT --date, 
    SUM(CAST(new_cases AS float)) AS total_cases, SUM(CAST(new_deaths AS float)) AS total_deaths, SUM(CAST(new_deaths AS float)) / SUM(CAST(new_cases AS float))*100 AS percent_deaths
FROM model..CovidDeaths
WHERE continent IS NOT NULL
-- GROUP BY date
ORDER BY 1,2;

SELECT date, SUM(CAST(new_cases AS float)) AS total_cases, SUM(CAST(new_deaths AS float)) AS total_deaths, SUM(CAST(new_deaths AS float)) / SUM(CAST(new_cases AS float))*100 AS percent_deaths
FROM model..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;



-- Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations,
FROM model..CovidDeaths dea
JOIN model..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;



-- Use CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, rolling_vaccinations)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM model..CovidDeaths dea
JOIN model..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3
)
SELECT *, (rolling_vaccinations/population) *100 AS pop_vaccinated
FROM PopvsVac;



-- Temp Table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    continent nvarchar(255),
    location nvarchar(255),
    date datetime,
    population numeric,
    new_vaccinations numeric,
    rolling_vaccinations numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM model..CovidDeaths dea
JOIN model..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
-- WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3

SELECT *, (rolling_vaccinations/population) *100 AS pop_vaccinated
FROM #PercentPopulationVaccinated;



-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_vaccinations
FROM model..CovidDeaths dea
JOIN model..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
-- ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated;


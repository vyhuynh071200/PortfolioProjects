-- COVID-19 exploratory analysis (SQL Server / T-SQL)
-- Prerequisites:
--   PortfolioProject..CovidDeaths
--   PortfolioProject..CovidVaccination
-- Data files and import scripts are not yet included in this repository.
-- Exploratory queries: results depend on dataset snapshot and reporting quality.

-- 1. Reported cases, deaths and population by location/date
SELECT
    location,
    [date],
    TRY_CAST(total_cases AS float) AS total_cases,
    TRY_CAST(total_deaths AS float) AS total_deaths,
    TRY_CAST(population AS float) AS population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, [date];

-- 2. Reported case-fatality percentage (not an individual fatality risk)
SELECT
    location,
    [date],
    100.0 * TRY_CAST(total_deaths AS float)
        / NULLIF(TRY_CAST(total_cases AS float), 0) AS reported_case_fatality_pct
FROM PortfolioProject..CovidDeaths
WHERE location = 'Vietnam'
ORDER BY [date];

-- 3. Reported cases relative to population
SELECT
    location,
    [date],
    100.0 * TRY_CAST(total_cases AS float)
        / NULLIF(TRY_CAST(population AS float), 0) AS reported_cases_per_100_population
FROM PortfolioProject..CovidDeaths
WHERE location = 'Vietnam'
ORDER BY [date];

-- 4. Largest reported cumulative case total per location
SELECT
    location,
    MAX(TRY_CAST(population AS float)) AS population,
    MAX(TRY_CAST(total_cases AS float)) AS max_reported_cases
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY max_reported_cases DESC;

-- 5. Daily global totals (country-level rows only; avoid regional double-counting)
SELECT
    [date],
    SUM(TRY_CAST(new_cases AS float)) AS reported_new_cases,
    SUM(TRY_CAST(new_deaths AS float)) AS reported_new_deaths,
    100.0 * SUM(TRY_CAST(new_deaths AS float))
        / NULLIF(SUM(TRY_CAST(new_cases AS float)), 0) AS daily_deaths_to_cases_pct
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY [date]
ORDER BY [date];

-- 6. Vaccination reporting joined by location and date
-- Running totals are cumulative reported vaccination events, not unique people.
WITH DailyVaccination AS (
    SELECT
        d.continent,
        d.location,
        d.[date],
        TRY_CAST(d.population AS float) AS population,
        TRY_CAST(v.new_vaccinations AS float) AS new_vaccinations
    FROM PortfolioProject..CovidDeaths AS d
    INNER JOIN PortfolioProject..CovidVaccination AS v
      ON d.location = v.location
     AND d.[date] = v.[date]
    WHERE d.continent IS NOT NULL
)
SELECT
    continent,
    location,
    [date],
    population,
    new_vaccinations,
    SUM(COALESCE(new_vaccinations, 0.0))
      OVER (PARTITION BY location ORDER BY [date] ROWS UNBOUNDED PRECEDING)
      AS rolling_reported_vaccination_events
FROM DailyVaccination
ORDER BY location, [date];

-- Note: Inspect missingness, revisions and dataset versions before using this for decisions.

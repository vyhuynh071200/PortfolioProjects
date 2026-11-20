/*
COVID-19 DATA EXPLORATION | T-SQL / Microsoft SQL Server
Purpose : Explore reported cases, deaths, and vaccinations.
Inputs  : PortfolioProject.dbo.CovidDeaths
          PortfolioProject.dbo.CovidVaccination
Scope   : Reporting and exploratory analysis, NOT causal inference.

Assumptions:
- Both source tables use (location, date) as the intended reporting key.
- Country-level records have a non-NULL continent.
- Numeric fields may arrive as text, so TRY_CONVERT is used.
- Data can include missing values and retrospective reporting revisions.
- Source files and ingestion scripts are not included in this repository.

Run in SQL Server Management Studio or Azure Data Studio.
Each section can be executed independently after the prerequisites are met.
*/
SET NOCOUNT ON;

DECLARE @focus_location NVARCHAR(100) = N'Vietnam';

-- --------------------------------------------------------------------------
-- 01 | Explore input quality for the focus country
-- --------------------------------------------------------------------------
SELECT
    d.location,
    COUNT(*) AS reporting_rows,
    COUNT(DISTINCT d.[date]) AS distinct_reporting_dates,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(20, 2), d.total_cases) IS NULL
             THEN 1 ELSE 0 END) AS missing_or_invalid_total_cases,
    SUM(CASE WHEN TRY_CONVERT(DECIMAL(20, 2), d.total_deaths) IS NULL
             THEN 1 ELSE 0 END) AS missing_or_invalid_total_deaths
FROM PortfolioProject.dbo.CovidDeaths AS d
WHERE d.location = @focus_location
GROUP BY d.location;

-- --------------------------------------------------------------------------
-- 02 | Reported cases and case-fatality percentage over time
-- A case-fatality percentage is NOT the probability of death after infection.
-- --------------------------------------------------------------------------
SELECT
    d.location,
    d.[date] AS report_date,
    TRY_CONVERT(DECIMAL(20, 2), d.total_cases) AS reported_total_cases,
    TRY_CONVERT(DECIMAL(20, 2), d.total_deaths) AS reported_total_deaths,
    100.0 * TRY_CONVERT(DECIMAL(20, 2), d.total_deaths)
          / NULLIF(TRY_CONVERT(DECIMAL(20, 2), d.total_cases), 0)
          AS reported_case_fatality_pct
FROM PortfolioProject.dbo.CovidDeaths AS d
WHERE d.location = @focus_location
ORDER BY d.[date];

-- --------------------------------------------------------------------------
-- 03 | Reported cumulative cases as a share of population
-- This is NOT unique infection prevalence when repeated cases are included.
-- --------------------------------------------------------------------------
SELECT
    d.location,
    d.[date] AS report_date,
    100.0 * TRY_CONVERT(DECIMAL(20, 2), d.total_cases)
          / NULLIF(TRY_CONVERT(DECIMAL(20, 2), d.population), 0)
          AS cumulative_cases_per_100_people
FROM PortfolioProject.dbo.CovidDeaths AS d
WHERE d.location = @focus_location
ORDER BY d.[date];

-- --------------------------------------------------------------------------
-- 04 | Highest reported cumulative cases by country
-- Excludes regional/world aggregates to reduce double counting.
-- --------------------------------------------------------------------------
SELECT
    d.location,
    MAX(TRY_CONVERT(DECIMAL(20, 2), d.total_cases)) AS peak_reported_cumulative_cases,
    MAX(TRY_CONVERT(DECIMAL(20, 2), d.population)) AS reported_population
FROM PortfolioProject.dbo.CovidDeaths AS d
WHERE d.continent IS NOT NULL
GROUP BY d.location
ORDER BY peak_reported_cumulative_cases DESC;

-- --------------------------------------------------------------------------
-- 05 | Daily reported cases and deaths across country-level records
-- Reporting adjustments may create negative daily values.
-- --------------------------------------------------------------------------
SELECT
    d.[date] AS report_date,
    SUM(TRY_CONVERT(DECIMAL(20, 2), d.new_cases)) AS reported_new_cases,
    SUM(TRY_CONVERT(DECIMAL(20, 2), d.new_deaths)) AS reported_new_deaths
FROM PortfolioProject.dbo.CovidDeaths AS d
WHERE d.continent IS NOT NULL
GROUP BY d.[date]
ORDER BY d.[date];

-- --------------------------------------------------------------------------
-- 06 | Create a reusable reporting view
-- Joining assumes a unique row per (location, date) in each source.
-- Validate join-key uniqueness before relying on rolled-up results.
-- Cumulative vaccination events are NOT unique vaccinated individuals.
-- A CREATE VIEW statement must start its own SQL Server batch.
-- --------------------------------------------------------------------------
GO

CREATE OR ALTER VIEW dbo.vw_covid_vaccination_reporting
AS
SELECT
    d.continent,
    d.location,
    d.[date] AS report_date,
    TRY_CONVERT(DECIMAL(20, 2), d.population) AS population,
    TRY_CONVERT(DECIMAL(20, 2), v.new_vaccinations) AS reported_new_vaccinations,
    SUM(COALESCE(TRY_CONVERT(DECIMAL(20, 2), v.new_vaccinations), 0))
        OVER (
            PARTITION BY d.location
            ORDER BY d.[date]
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS rolling_reported_vaccination_events
FROM PortfolioProject.dbo.CovidDeaths AS d
INNER JOIN PortfolioProject.dbo.CovidVaccination AS v
    ON d.location = v.location
   AND d.[date] = v.[date]
WHERE d.continent IS NOT NULL;
GO

-- --------------------------------------------------------------------------
-- 07 | Inspect output of the reporting view
-- --------------------------------------------------------------------------
SELECT TOP (100)
    location,
    report_date,
    population,
    reported_new_vaccinations,
    rolling_reported_vaccination_events
FROM dbo.vw_covid_vaccination_reporting
ORDER BY location, report_date;

-- End of exploratory workflow.

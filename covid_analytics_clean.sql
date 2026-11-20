/*
COVID-19 | DATA EXPLORATION AND REPORTING (MICROSOFT SQL SERVER)

Purpose:
    Explore reported COVID-19 metrics using SQL joins, data-quality checks,
    common table expressions, window functions and a reusable reporting view.

Inputs (in the CURRENTLY SELECTED database):
    dbo.CovidDeaths
    dbo.CovidVaccination

Run order for the synthetic demonstration:
    1. Run demo/00_create_synthetic_database.sql.
    2. Set current database to CovidPortfolioDemo.
    3. Run this file.
    4. Run checks/01_data_quality.sql and tests/02_demo_assertions.sql.

For a separately imported real dataset:
    Select the database containing BOTH input tables before running this file.
    Do NOT run the demo setup against a real dataset.

Interpretation:
    Reported case-fatality ratios are NOT individual death probabilities.
    Cumulative cases can include repeat infections.
    Vaccination counts represent reported events, NOT unique people.
    Some missing data and reporting revisions are expected.
    No causal or epidemiological claims are made.

    Historical COVID-19 source files are not included in this repository.
*/
SET NOCOUNT ON;
DECLARE @focus_location NVARCHAR(100) = N'Vietnam';

-- 01. Basic data-quality overview for the target location.
SELECT
    d.location,
    COUNT(*) AS reporting_rows,
    COUNT(DISTINCT d.[date]) AS distinct_reporting_dates,
    SUM(CASE
        WHEN d.total_cases IS NOT NULL
             AND TRY_CONVERT(DECIMAL(20, 2), d.total_cases) IS NULL
            THEN 1 ELSE 0
        END) AS invalid_total_cases,
    SUM(CASE
        WHEN d.total_deaths IS NOT NULL
             AND TRY_CONVERT(DECIMAL(20, 2), d.total_deaths) IS NULL
            THEN 1 ELSE 0
        END) AS invalid_total_deaths
FROM dbo.CovidDeaths AS d
WHERE d.location = @focus_location
GROUP BY d.location;

-- 02. Cumulative cases, deaths, and reported case-fatality percentage.
SELECT
    d.location,
    d.[date] AS report_date,
    TRY_CONVERT(DECIMAL(20, 2), d.total_cases) AS reported_total_cases,
    TRY_CONVERT(DECIMAL(20, 2), d.total_deaths) AS reported_total_deaths,
    100.0 * TRY_CONVERT(DECIMAL(20, 2), d.total_deaths)
        / NULLIF(TRY_CONVERT(DECIMAL(20, 2), d.total_cases), 0)
        AS reported_case_fatality_pct
FROM dbo.CovidDeaths AS d
WHERE d.location = @focus_location
ORDER BY d.[date];

-- 03. Cumulative reported cases per 100 inhabitants.
-- This is not the unique percentage of the population ever infected.
SELECT
    d.location,
    d.[date] AS report_date,
    100.0 * TRY_CONVERT(DECIMAL(20, 2), d.total_cases)
        / NULLIF(TRY_CONVERT(DECIMAL(20, 2), d.population), 0)
        AS cumulative_reported_cases_per_100_people
FROM dbo.CovidDeaths AS d
WHERE d.location = @focus_location
ORDER BY d.[date];

-- 04. Latest available country-level reported case totals.
-- ROW_NUMBER chooses the latest reporting date, rather than the historic MAX,
-- which may differ when cumulative counts are revised downward.
WITH ranked_country_reports AS (
    SELECT
        d.location,
        d.continent,
        d.[date],
        TRY_CONVERT(DECIMAL(20, 2), d.total_cases) AS reported_total_cases,
        ROW_NUMBER() OVER (
            PARTITION BY d.location
            ORDER BY d.[date] DESC
        ) AS recency_rank
    FROM dbo.CovidDeaths AS d
    WHERE d.continent IS NOT NULL
)
SELECT
    location,
    continent,
    [date] AS last_report_date,
    reported_total_cases
FROM ranked_country_reports
WHERE recency_rank = 1
ORDER BY reported_total_cases DESC;

-- 05. Reported daily totals and a 7-reporting-day rolling average.
-- Window uses seven available report rows, NOT necessarily calendar days.
WITH daily_country_totals AS (
    SELECT
        d.[date] AS report_date,
        SUM(TRY_CONVERT(DECIMAL(20, 2), d.new_cases))
            AS reported_new_cases,
        SUM(TRY_CONVERT(DECIMAL(20, 2), d.new_deaths))
            AS reported_new_deaths
    FROM dbo.CovidDeaths AS d
    WHERE d.continent IS NOT NULL
    GROUP BY d.[date]
)
SELECT
    report_date,
    reported_new_cases,
    reported_new_deaths,
    AVG(reported_new_cases) OVER (
        ORDER BY report_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS trailing_7_reporting_day_avg_cases
FROM daily_country_totals
ORDER BY report_date;

-- 06. Latest reported country totals aggregated by continent.
-- Use the latest country row rather than summing cumulative observations
-- across all dates (which would double-count the same cases repeatedly).
WITH latest_per_location AS (
    SELECT
        d.continent,
        d.location,
        d.[date],
        TRY_CONVERT(DECIMAL(20, 2), d.total_cases)
            AS reported_total_cases,
        ROW_NUMBER() OVER (
            PARTITION BY d.location
            ORDER BY d.[date] DESC
        ) AS recency_rank
    FROM dbo.CovidDeaths AS d
    WHERE d.continent IS NOT NULL
)
SELECT
    continent,
    COUNT(*) AS countries_in_latest_snapshot,
    SUM(reported_total_cases) AS summed_latest_reported_cases
FROM latest_per_location
WHERE recency_rank = 1
GROUP BY continent
ORDER BY summed_latest_reported_cases DESC;

-- 07. Create a reusable view for vaccination reporting.
-- LEFT JOIN retains dates with no matching vaccination record.
-- SUM ignores NULLs (unknown values are not assumed to be observed zeros).
-- Verify uniqueness of (location, date) in BOTH sources before using.
GO

CREATE OR ALTER VIEW dbo.vw_covid_vaccination_reporting
AS
SELECT
    d.continent,
    d.location,
    d.[date] AS report_date,
    TRY_CONVERT(DECIMAL(20, 2), d.population) AS population,
    TRY_CONVERT(DECIMAL(20, 2), v.new_vaccinations)
        AS reported_new_vaccinations,
    SUM(TRY_CONVERT(DECIMAL(20, 2), v.new_vaccinations)) OVER (
        PARTITION BY d.location
        ORDER BY d.[date]
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS rolling_reported_vaccination_events
FROM dbo.CovidDeaths AS d
LEFT JOIN dbo.CovidVaccination AS v
    ON d.location = v.location
   AND d.[date] = v.[date]
WHERE d.continent IS NOT NULL;
GO

-- 08. Check that the view is queryable.
SELECT TOP (100)
    location,
    report_date,
    population,
    reported_new_vaccinations,
    rolling_reported_vaccination_events
FROM dbo.vw_covid_vaccination_reporting
ORDER BY location, report_date;

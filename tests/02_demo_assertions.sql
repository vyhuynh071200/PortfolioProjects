/*
DEMO 02 — AUTOMATED SQL SERVER ASSERTIONS

Run ONLY after:
1. demo/00_create_synthetic_database.sql (creates CovidPortfolioDemo).
2. covid_analytics_clean.sql while CovidPortfolioDemo is selected.

This test script explicitly switches to the isolated demonstration database.
It reads data and raises THROW on failures. It does not modify data.
All expected values describe INVENTED synthetic fixtures, not real COVID data.
*/
IF DB_ID(N'CovidPortfolioDemo') IS NULL
    THROW 52000, 'Create CovidPortfolioDemo with demo/00_create_synthetic_database.sql first.', 1;
GO
USE CovidPortfolioDemo;
GO

IF OBJECT_ID(N'dbo.vw_covid_vaccination_reporting', N'V') IS NULL
    THROW 52001, 'Reporting view not found; run covid_analytics_clean.sql first.', 1;

-- Country-level case reports: 3 rows for each of 2 synthetic countries.
IF (SELECT COUNT(*) FROM dbo.CovidDeaths WHERE continent IS NOT NULL) <> 6
    THROW 52002, 'Unexpected number of country-level case reports.', 1;

-- Expected latest cases for Vietnam: 200 on day 3.
IF (
    SELECT TRY_CONVERT(DECIMAL(20, 2), total_cases)
    FROM dbo.CovidDeaths
    WHERE location = N'Vietnam' AND [date] = '2021-01-03'
) <> 200
    THROW 52003, 'Synthetic Vietnam latest total_cases does not match fixture.', 1;

-- A cumulative reported case-fatality percentage of 4 / 200 * 100 = 2%.
IF (
    SELECT 100.0 * TRY_CONVERT(DECIMAL(20, 2), total_deaths)
           / NULLIF(TRY_CONVERT(DECIMAL(20, 2), total_cases), 0)
    FROM dbo.CovidDeaths
    WHERE location = N'Vietnam' AND [date] = '2021-01-03'
) <> 2.0
    THROW 52004, 'Synthetic case-fatality calculation is incorrect.', 1;

-- The view should retain all six country-level case dates.
IF (SELECT COUNT(*) FROM dbo.vw_covid_vaccination_reporting) <> 6
    THROW 52005, 'View row count mismatch. Check join-key uniqueness.', 1;

-- Reported vaccination events: Vietnam = 10 + 20 + 30 = 60.
IF (
    SELECT rolling_reported_vaccination_events
    FROM dbo.vw_covid_vaccination_reporting
    WHERE location = N'Vietnam' AND report_date = '2021-01-03'
) <> 60
    THROW 52006, 'Vietnam running vaccination total mismatch.', 1;

-- Missing Canadian day-2 value remains NULL, rather than being called zero.
IF EXISTS (
    SELECT 1
    FROM dbo.vw_covid_vaccination_reporting
    WHERE location = N'Canada'
      AND report_date = '2021-01-02'
      AND reported_new_vaccinations IS NOT NULL
)
    THROW 52007, 'Missing daily vaccination value was not preserved.', 1;

-- Sum of known Canadian vaccination events = 5 + NULL + 15 = 20.
IF (
    SELECT rolling_reported_vaccination_events
    FROM dbo.vw_covid_vaccination_reporting
    WHERE location = N'Canada' AND report_date = '2021-01-03'
) <> 20
    THROW 52008, 'Canada running vaccination total mismatch.', 1;

-- World aggregate with a NULL continent must not appear in the country view.
IF EXISTS (
    SELECT 1 FROM dbo.vw_covid_vaccination_reporting
    WHERE location = N'World'
)
    THROW 52009, 'Aggregate World row was incorrectly included.', 1;

PRINT 'PASS: all synthetic SQL Server demo assertions completed.';

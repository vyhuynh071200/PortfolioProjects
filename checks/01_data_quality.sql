/*
READ-ONLY DATA QUALITY AUDIT | Run in the database containing the input tables.

This script does not update or remove data. Investigate any duplicate join
keys BEFORE interpreting outputs from the reporting view.
*/
SET NOCOUNT ON;

-- 01 | Validate duplicates for expected (location, date) join keys.
SELECT
    'CovidDeaths' AS source_table,
    location,
    [date] AS report_date,
    COUNT(*) AS duplicate_rows
FROM dbo.CovidDeaths
GROUP BY location, [date]
HAVING COUNT(*) > 1
ORDER BY duplicate_rows DESC, location, report_date;

SELECT
    'CovidVaccination' AS source_table,
    location,
    [date] AS report_date,
    COUNT(*) AS duplicate_rows
FROM dbo.CovidVaccination
GROUP BY location, [date]
HAVING COUNT(*) > 1
ORDER BY duplicate_rows DESC, location, report_date;

-- 02 | Identify missing and unparsable numeric values.
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN [date] IS NULL THEN 1 ELSE 0 END) AS missing_date,
    SUM(CASE WHEN location IS NULL THEN 1 ELSE 0 END) AS missing_location,
    SUM(CASE WHEN total_cases IS NULL THEN 1 ELSE 0 END) AS missing_total_cases,
    SUM(CASE WHEN total_cases IS NOT NULL
                  AND TRY_CONVERT(DECIMAL(20, 2), total_cases) IS NULL
             THEN 1 ELSE 0 END) AS invalid_total_cases,
    SUM(CASE WHEN total_deaths IS NULL THEN 1 ELSE 0 END) AS missing_total_deaths,
    SUM(CASE WHEN total_deaths IS NOT NULL
                  AND TRY_CONVERT(DECIMAL(20, 2), total_deaths) IS NULL
             THEN 1 ELSE 0 END) AS invalid_total_deaths,
    MIN([date]) AS first_report_date,
    MAX([date]) AS last_report_date
FROM dbo.CovidDeaths;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN new_vaccinations IS NULL THEN 1 ELSE 0 END)
        AS missing_new_vaccinations,
    SUM(CASE WHEN new_vaccinations IS NOT NULL
                  AND TRY_CONVERT(DECIMAL(20, 2), new_vaccinations) IS NULL
             THEN 1 ELSE 0 END)
        AS invalid_new_vaccinations
FROM dbo.CovidVaccination;

-- 03 | Join coverage: country-level case reports lacking vaccination rows.
SELECT
    COUNT(*) AS country_level_case_reports,
    SUM(CASE WHEN v.location IS NULL THEN 1 ELSE 0 END)
        AS case_reports_without_vaccination_match
FROM dbo.CovidDeaths AS d
LEFT JOIN dbo.CovidVaccination AS v
    ON d.location = v.location
   AND d.[date] = v.[date]
WHERE d.continent IS NOT NULL;

-- 04 | Counts by country to identify reporting gaps.
SELECT
    continent,
    location,
    COUNT(*) AS report_rows,
    MIN([date]) AS first_report_date,
    MAX([date]) AS last_report_date
FROM dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY report_rows DESC, continent, location;

/*
DEMO 00 — SYNTHETIC SQL SERVER FIXTURE
Creates a separate, isolated database: CovidPortfolioDemo.

WARNING: Re-running this script DROPS and recreates dbo.CovidDeaths and
dbo.CovidVaccination inside CovidPortfolioDemo ONLY. Never run the script
against a real data database. The values below are entirely invented for
software demonstration; they are NOT historical COVID-19 statistics.

Run this file first, then select CovidPortfolioDemo as the active database
before running covid_analytics_clean.sql.
*/
IF DB_ID(N'CovidPortfolioDemo') IS NULL
BEGIN
    EXEC(N'CREATE DATABASE CovidPortfolioDemo');
END;
GO

USE CovidPortfolioDemo;
GO

DROP VIEW IF EXISTS dbo.vw_covid_vaccination_reporting;
DROP TABLE IF EXISTS dbo.CovidVaccination;
DROP TABLE IF EXISTS dbo.CovidDeaths;
GO

CREATE TABLE dbo.CovidDeaths (
    continent NVARCHAR(100) NULL,
    location NVARCHAR(100) NOT NULL,
    [date] DATE NOT NULL,
    population NVARCHAR(40) NULL,
    total_cases NVARCHAR(40) NULL,
    new_cases NVARCHAR(40) NULL,
    total_deaths NVARCHAR(40) NULL,
    new_deaths NVARCHAR(40) NULL,
    CONSTRAINT PK_DemoCovidDeaths PRIMARY KEY (location, [date])
);

CREATE TABLE dbo.CovidVaccination (
    location NVARCHAR(100) NOT NULL,
    [date] DATE NOT NULL,
    new_vaccinations NVARCHAR(40) NULL,
    CONSTRAINT PK_DemoCovidVaccination PRIMARY KEY (location, [date])
);

INSERT INTO dbo.CovidDeaths
    (continent, location, [date], population, total_cases, new_cases, total_deaths, new_deaths)
VALUES
    (N'Asia', N'Vietnam', '2021-01-01', N'1000000', N'100', N'20', N'2', N'1'),
    (N'Asia', N'Vietnam', '2021-01-02', N'1000000', N'150', N'50', N'3', N'1'),
    (N'Asia', N'Vietnam', '2021-01-03', N'1000000', N'200', N'50', N'4', N'1'),
    (N'North America', N'Canada', '2021-01-01', N'800000', N'50', N'10', N'1', N'0'),
    (N'North America', N'Canada', '2021-01-02', N'800000', N'70', N'20', N'1', N'0'),
    (N'North America', N'Canada', '2021-01-03', N'800000', N'110', N'40', N'2', N'1'),
    (NULL, N'World', '2021-01-01', N'1800000', N'150', N'30', N'3', N'1'),
    (NULL, N'World', '2021-01-02', N'1800000', N'220', N'70', N'4', N'1'),
    (NULL, N'World', '2021-01-03', N'1800000', N'310', N'90', N'6', N'2');

INSERT INTO dbo.CovidVaccination (location, [date], new_vaccinations)
VALUES
    (N'Vietnam', '2021-01-01', N'10'),
    (N'Vietnam', '2021-01-02', N'20'),
    (N'Vietnam', '2021-01-03', N'30'),
    (N'Canada', '2021-01-01', N'5'),
    (N'Canada', '2021-01-02', NULL),  -- Demonstrates an unknown daily value
    (N'Canada', '2021-01-03', N'15');

PRINT 'Synthetic demo ready. Select CovidPortfolioDemo and run covid_analytics_clean.sql.';

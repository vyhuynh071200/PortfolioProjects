# COVID-19 Data Exploration with SQL

**Portfolio focus:** exploratory analysis and reporting queries using SQL Server.

## Business / analytical questions
1. How did reported cases and deaths evolve over time?
2. What proportion of a location's population was reported as infected?
3. How did reported case-fatality percentages compare across dates and locations?
4. How can vaccination data be joined to case data to support time-series reporting?

## Skills demonstrated
- `JOIN` on location and date
- `GROUP BY` and aggregate functions (`SUM`, `MAX`)
- `CAST` and `NULLIF` for numeric calculations
- Window functions for rolling vaccination counts
- Temporary tables and a SQL view for downstream visualization

## Code
**[Read the SQL script](./Covid%20Project%20for%20Portfolio.sql)**

This is **T-SQL / SQL Server** syntax. It references two tables named `PortfolioProject..CovidDeaths` and `PortfolioProject..CovidVaccination`. The underlying dataset and table-creation scripts are **not currently included** in this repository, so the script cannot be run on a new machine without preparing those input tables first.

## Query workflow
1. Inspect case and vaccination tables.
2. Calculate case, death and population percentages.
3. Aggregate totals by location, continent and date.
4. Join deaths and vaccination tables on `location` and `date`.
5. Calculate a rolling count of vaccinations with a window function.
6. Prepare a SQL view (`dbo.PercentageVaccinated`) for visualization.

## Interpretation and limitations
- `total_deaths / total_cases` is a **reported case-fatality percentage**, not the probability of death for a person who becomes infected.
- Ratios depend on reporting quality, definitions, time coverage, and potentially zero or missing denominators.
- The rolling sum is based on reported new vaccination counts; it should **not** automatically be interpreted as the number of distinct people vaccinated.
- This repository demonstrates queries rather than a validated end-to-end dashboard or published findings. No output figures are claimed here without rerunning the code against documented data.

## Suggested next improvement
Include a data-source citation, reproducible import/cleaning script, expected output examples, and one dashboard or visual summary. Confirm each calculation against the actual source schema before publishing results.

---
*Portfolio project by Vy Huynh.*

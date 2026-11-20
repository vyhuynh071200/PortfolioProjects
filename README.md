# COVID-19 Data Exploration | SQL Server

**Portfolio case study** · SQL · Joins · Aggregations · Window Functions · Reporting Views

## Objective
Explore reported COVID-19 cases, deaths, and vaccination events to demonstrate analytical SQL patterns and careful metric interpretation.

## Analytical questions
1. How do reported cases and deaths change over time?
2. What is the reported case-fatality percentage for a chosen location?
3. How do cumulative reported cases compare with the population?
4. Which locations have the largest reported cumulative case totals?
5. How can case and vaccination records be combined into a reusable time-series reporting view?

## Repository files
- **[Clean analytical SQL script](./covid_analytics_clean.sql)** — the recommended, documented version, with consistent naming and a reporting view.
- [Original exploratory SQL script](./Covid%20Project%20for%20Portfolio.sql) — preserved as an earlier working draft.

## Technical approach
The cleaned script demonstrates `TRY_CONVERT`, `NULLIF`, `GROUP BY`, `SUM`, `MAX`, joins on `location` and `date`, and a window function with an explicit row frame. It builds `dbo.vw_covid_vaccination_reporting` for downstream queries.

### How to run
1. Use **Microsoft SQL Server** (SQL Server Management Studio or Azure Data Studio).
2. Prepare the tables `PortfolioProject.dbo.CovidDeaths` and `PortfolioProject.dbo.CovidVaccination`, with the expected fields.
3. Review the source data for duplicate `(location, date)` records and missing numeric fields.
4. Open and run [`covid_analytics_clean.sql`](./covid_analytics_clean.sql).
5. Query `dbo.vw_covid_vaccination_reporting` in the active database.

> **Reproducibility status:** Source datasets, ingestion scripts, and actual result outputs are **not included** here. The SQL has been reviewed for structure but **not executed against the original SQL Server tables**. The view is created in your currently selected database (it references source data in `PortfolioProject`).

## Interpretation and data-quality cautions
- `total_deaths / total_cases` estimates a **reported case-fatality percentage**, not a person's probability of dying after infection.
- Cumulative reported cases can count repeat infections and are not necessarily the share of unique people ever infected.
- A sum of reported vaccination events **does not measure distinct vaccinated individuals**.
- Reported totals depend on source definitions, missing values, reporting adjustments, and data quality.
- Aggregation excludes continent-level summary rows to reduce double counting; verify the dataset's location classifications.
- The time-series join assumes a unique `(location, date)` key in both source tables. Duplicate keys can inflate joined totals.

## Next steps
Add an attributed, reproducible sample dataset and ingestion script, validated sample outputs, and a concise dashboard. Avoid claiming results that have not been independently reproduced.

---
**Portfolio project by Vy Huynh** — SQL-based exploratory analysis and reporting.

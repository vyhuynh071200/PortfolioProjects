# Metric definitions and interpretation guide

This project demonstrates **exploratory reporting SQL**, not public-health inference. Definitions are useful for recruiters evaluating both query skills and analytical judgment.

| Metric | Calculation / implementation | What it does **not** mean |
| --- | --- | --- |
| Reported case-fatality percentage | `100 × reported cumulative deaths / reported cumulative cases` on the same reporting date; denominator zero gives `NULL` | It is not the infection fatality rate or a person's probability of dying |
| Cumulative reported cases per 100 people | `100 × total_cases / population` | This is not necessarily the number of **unique** people ever infected; repeat infections and data revisions can affect it |
| Latest reported cases | Select the latest available date per location using `ROW_NUMBER() OVER (PARTITION BY location ORDER BY date DESC)` | This need not equal the historical maximum if a later report revised data downward |
| Seven-reporting-day average of new cases | `AVG(SUM(new_cases)) OVER (ORDER BY report_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)` after aggregation by report date | It is not guaranteed to be a calendar seven-day average when report dates have gaps |
| Rolling vaccination events | `SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY date ROWS ...)` | It is not the count of distinct vaccinated people; boosters and repeated events may be included |

## Data validation checklist

1. Confirm **one row per (location, date)** in both source tables; otherwise joins may multiply records.
2. Inspect missing/unparsable numbers with `TRY_CONVERT` and record how missing values are treated.
3. Check whether the source uses region aggregates, `continent IS NULL` and alternative location labels.
4. Inspect reporting-date gaps and negative corrections before comparing daily trends.
5. Verify the data-source URL, license, download date and snapshot before presenting results.
6. Check that your target database is correct before running the view-creation script.

## Distinguishing evidence from demonstration

The records in `demo/00_create_synthetic_database.sql` are **invented for controlled SQL tests**. Do not cite them as actual country statistics or epidemiological insights. The historical source data for the original exploratory script are not packaged with this repo, so **no validated real-world result is claimed** in the README.

When real data become available, document the source and dates, run the quality audit, save verified results or dashboard screenshots, and record the SQL Server version used.

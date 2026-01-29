Select*
From PortfolioProject..CovidDeaths
order by 3,4

Select*
From PortfolioProject..CovidVaccination
order by 3,4

Select location,date,total_cases,new_cases,total_deaths,population
From PortfolioProject..CovidDeaths
order by 1,2

-- Show likelihood of dying if contracted covid in my country
Select location,date,total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
Where location='Vietnam'
order by 1,2

-- Shows what percentage of population got Covid
Select location,date,population,total_cases,(total_cases/population)*100 as CovidPercentage
From PortfolioProject..CovidDeaths
Where location='Vietnam'
order by 1,2

-- Looking at countries with highest infection rates
Select location,population,MAX(total_cases) as HighestInfect,Max((total_cases/population))*100 as CovidPercentage
From PortfolioProject..CovidDeaths
--Where location='Vietnam'
group by location,population
order by CovidPercentage desc

-- Showing countries with highest death counts per population
Select location,MAX(cast(total_deaths as int)) as HighestDeaths
From PortfolioProject..CovidDeaths
--Where location='Vietnam'
Where continent is not NULL
group by location
order by HighestDeaths desc

--Breaking things down by continent
Select continent,MAX(cast(total_deaths as int)) as HighestDeaths
From PortfolioProject..CovidDeaths
--Where location='Vietnam'
Where continent is not NULL
group by continent
order by HighestDeaths desc

-- Looking at death percentages across the world by date
Select date,Sum(new_cases) as total_cases, Sum(cast(new_deaths as int)) as total_deaths,(Sum(cast(new_deaths as int))*100)/NULLIF(Sum(new_cases),0) as DeathbydatePercentage
From PortfolioProject..CovidDeaths
--Where location='Vietnam'
group by date
order by 1,2

-- Looking at death percentages across the world in total
Select Sum(new_cases) as total_cases, Sum(cast(new_deaths as int)) as total_deaths,(Sum(cast(new_deaths as int))*100)/NULLIF(Sum(new_cases),0) as DeathbydatePercentage
From PortfolioProject..CovidDeaths
--Where location='Vietnam'
order by 1,2

-- --Looking at vaccination vs population
-- With PopvsVac (continent,location,date,population,new_vaccinations,RollingVaccinations)
-- as 
-- (
--Select cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,
--Sum(cast(cv.new_vaccinations as int)) OVER (Partition by cd.location Order by cd.location, cd.date) as RollingVaccinations
--From PortfolioProject..CovidDeaths cd
--Join PortfolioProject..CovidVaccination cv
--On cd.location=cv.location
--and cd.date=cv.date
--where cd.continent is not NULL
----order by 2,3
--)

--TEMP TABLE
Drop table if exists #PercentVaccinated
Create Table #PercentVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
RollingVaccinations numeric,
)
Insert into #PercentVaccinated
Select cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,
Sum(cast(cv.new_vaccinations as int)) OVER (Partition by cd.location Order by cd.location, cd.date) as RollingVaccinations
From PortfolioProject..CovidDeaths cd
Join PortfolioProject..CovidVaccination cv
On cd.location=cv.location
and cd.date=cv.date
--where cd.continent is not NULL
--order by 2,3

Select *, (RollingVaccinations/population)*100 as PercentVaccinated
From #PercentVaccinated

-- Creating View to store data for visulization
DROP VIEW IF EXISTS dbo.PercentageVaccinated;
GO

CREATE OR ALTER VIEW dbo.PercentageVaccinated AS
SELECT
  cd.continent,
  cd.location,
  cd.date,
  cd.population,
  cv.new_vaccinations,
  SUM(CAST(cv.new_vaccinations AS bigint)) OVER (
    PARTITION BY cd.location
    ORDER BY cd.date
  ) AS RollingVaccinations
FROM PortfolioProject..CovidDeaths cd
JOIN PortfolioProject..CovidVaccination cv
  ON cd.location = cv.location
 AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;
GO

SELECT *
FROM dbo.PercentageVaccinated;

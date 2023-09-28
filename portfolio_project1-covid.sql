--Portfolio Project 1: Data Exploration
--Source: Ourworldindata.org/covid-deaths
--Query 1: select data that we're using
SELECT location_covid, date_covid,total_cases, new_cases,total_deaths, population
FROM coviddeaths
order by 1,2

--Query 2: Looking at total cases vs. total deaths
--deathPercentage Shows likelihood of dying if you contract covid in US
SELECT location_covid, date_covid,total_cases,total_deaths, (total_deaths/total_cases)*100 as deathPercentage
FROM coviddeaths
WHERE location_covid like '%States%'
order by 1,2

--Query 3: Looking at total cases vs population
--covidPercentage Shows likelihood of contracting covid in US
SELECT location_covid, date_covid,population,total_cases,(total_cases/population)*100 as covidPercentage
FROM coviddeaths
WHERE location_covid like '%States%'
order by 1,2

--Query 4: which countries have highest infection rates compared to the population
SELECT location_covid,population,max(total_cases) as highestInfectonCount,max(total_cases/population)*100 as PercentPopulationInfected
FROM coviddeaths 
GROUP BY location_covid,population
order by PercentPopulationInfected desc;

--Query 5: Break down by continent (in this case if continent is null, then continent stores in location)
--showing continents with the highest death count
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM coviddeaths 
where continent is not null
GROUP BY continent
order by TotalDeathCount desc;

--Query 6: global numbers
SELECT sum(new_cases),sum(new_deaths),sum(new_deaths)/sum(new_cases)*100
FROM coviddeaths
WHERE continent is not null
order by 1,2

--Query 7: looking at total population vs vaccination
--Uses partition by for rolling count of vaccinations per location
--then find out sum of people vaccinated per location using CTE (query 8) or using temp table (query 9)
   --Can't do (rollingPeopleVaccinated/population) since rollingPeopleVaccinated was just created so create CTE (query 8) or Temp table
SELECT dea.continent,dea.location_covid,dea.date_covid,dea.population,vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location_covid order by dea.location_covid,dea.date_covid) as rollingPeopleVaccinated 
FROM coviddeaths dea
join covidvaccinations vac
on dea.date_covid=vac.date_covid and
dea.location_covid=vac.location_covid
where dea.continent is not null and new_vaccinations is not null
order by 2,3;

--Query 8 - use CTE
With PopvsVac as
(SELECT dea.continent,dea.location_covid,dea.date_covid,dea.population,vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location_covid order by dea.location_covid,dea.date_covid) as rollingPeopleVaccinated 
FROM coviddeaths dea
join covidvaccinations vac
on dea.date_covid=vac.date_covid and
dea.location_covid=vac.location_covid
where dea.continent is not null and new_vaccinations is not null order by 2,3)

select location_covid,max(rollingPeopleVaccinated) from PopvsVac
group by location_covid;

--Query 9 - use Temp Table
DROP table if exists PercentPopulationVaccinated
create temp table PercentPopulationVaccinated
(
Continent varchar(255),
Location varchar(255),
Date timestamp,
Population numeric, 
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into PercentPopulationVaccinated
SELECT dea.continent,dea.location_covid,dea.date_covid,dea.population,vac.new_vaccinations, 
sum(vac.new_vaccinations) over (partition by dea.location_covid order by dea.location_covid,dea.date_covid) as rollingPeopleVaccinated 
FROM coviddeaths dea
join covidvaccinations vac
on dea.date_covid=vac.date_covid and
dea.location_covid=vac.location_covid
where dea.continent is not null and new_vaccinations is not null order by 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
from PercentPopulationVaccinated;

--Creating views to store data for later visualizations

--rollingPeopleVaccinated for each location View
Create view RollingPeopleVaccinated as
SELECT dea.continent, dea.location_covid, dea.date_covid,dea.population, va.new_vaccinations,
sum(va.new_vaccinations) over (partition by dea.location_covid order by dea.location_covid,dea.date_covid) as rollingPeopleVaccinated
FROM coviddeaths dea
JOIN covidvaccinations va 
on dea.location_covid=va.location_covid AND 
dea.date_covid=va.date_covid 
where dea.continent is not null and new_vaccinations is not null order by 2,3

--deathPercentage View
create view deathPercentage as
select location_covid,date_covid,total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercent
from coviddeaths
order by 1,2

--covidPercentage View
create view covidPercentage as
select location_covid,date_covid,population,total_cases, (total_cases/population)*100 as covidPercent
from coviddeaths
order by 1,2


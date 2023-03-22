-- here is the data which i'm going to use in that project
select 
	location, 
	date, 
	total_cases, 
	new_cases, 
	total_deaths,
	new_deaths
	population
	from CovidDeaths
	order by 1,2

-- checking how much total cases vs total deaths
select 
	location, 
	Count(total_cases) as total_cases, 
	Count(total_deaths) as total_deaths
	from CovidDeaths
	group by location
	order by total_cases DESC;

-- check % of deaths per case with 'where' clause
select 
	location, 
	date,
	(total_deaths/total_cases)*100 as precent
	from CovidPortfolio..CovidDeaths
	where (total_deaths/total_cases)*100 != 0
	order by location, precent 
	
-- total cases vs population  for a specific country "Poland"
-- that will show us what precentage of population in poland get covid in specific date
select 
	location,
	date,
	population,
	total_cases,
	Round((total_cases/population)*100,6) as deathPrecentage
	from CovidPortfolio..CovidDeaths
	where (population/total_cases)*100 != 0 
	AND location LIKE '%poland%'
	order by location, date

-- looking for countries with highest infections rate compared to population

select 
	location,
	population,
	MAX(total_cases) as MaxInfectionCount,
	ROUND(MAX((total_cases/population))*100,6) as precentPopulationInfected
	from CovidPortfolio..CovidDeaths
	group by location, population
	having MAX(total_cases) != 0
	order by precentPopulationInfected desc

-- looking for top 10 locations  with highest sum of deaths count 

select top 10
	location,
	-- convert is not necessary in this case	
	SUM(convert (bigint, total_deaths)) as maxDeaths
	from CovidPortfolio..CovidDeaths
	-- data set contains location with the same names like continent
	where continent is not null
	group by location
	order by maxDeaths desc

-- looking for highest death count per population 

select 
	location, 
	MAX(convert (bigint, total_deaths)) as deathsCount
	from CovidPortfolio..CovidDeaths
	where continent is not null
	group by location
	order by deathsCount desc

-- counting deaths and cases based on continents

select 
	continent,
	max(convert (int, total_cases)) as totalCasesCount,
	max (convert(int, total_deaths)) as totalDeathCount
	from CovidPortfolio..CovidDeaths
	where continent is not null
	group by continent

-- This part will present global statistics and won't be limited to specific geographic locations or continents.

-- sum of total_cases and total_deaths per day 
-- percentage of death and total cases
select 
	date, 
	SUM(total_cases) as totalCasesCount,
	SUM(convert(int, total_deaths)) as totalDeathCount,
	Round(SUM(convert(int, total_deaths))/SUM(total_cases),6) as deathPercentage
	from CovidPortfolio..CovidDeaths
	where continent is not null
	group by date
	having SUM(total_cases) !=0 
	and  sum(convert(int, total_deaths)) != 0
	order by 1 asc 

-- checking percentage of new_cases and new_deaths

select 
	date,
	sum(new_cases) as newTotalCases,
	sum(convert(int, new_deaths)) as newTotalDeaths,
	Round(sum(convert(int, new_deaths))/sum(new_cases)*100,4) as deathPrecentage
	from CovidPortfolio..CovidDeaths
	where continent is not null
	group by date
	having sum(convert(int, new_deaths)) !=0 
	order by  1,4

-- ###### CovidVaccinations table ######

-- Checking how many tests have been taken, how many were positive, and how many people have been vaccinated.
select 
	date, 
	new_tests, 
	positive_rate, 
	new_vaccinations 
	from CovidPortfolio..CovidVaccinations
	where new_tests != 0
	and median_age between 18 and 26


-- people_vaccinated per country
select 
	location,
	MAX(convert(bigint,people_vaccinated)) as Pvacc, 
	mAX(convert(bigint, total_vaccinations)) as Tvacc
	from CovidPortfolio..CovidVaccinations
	where continent is not null
	group by location
	order by 1

-- Joins 
--looking for population per country vs the number of vaccinations per day, and the daily percentage of vaccinated people.

select
	vacc.continent, 
	vacc.location, 
	vacc.date, 
	death.population, 
	Convert(int,vacc.new_vaccinations) as newVaccinations, 
	Round(Convert(int,vacc.new_vaccinations)/ death.population,4) as vaccinationsPercentage
	from CovidPortfolio..CovidVaccinations vacc
	join CovidPortfolio..CovidDeaths as death	
	on death.location = vacc.location
	and death.date = vacc.date
	where vacc.continent is not null
	order by 2

-- sum of daily, new vaccinations for each country

select dea.location, dea.population, dea.date, vacc.new_tests, vacc.new_vaccinations,
	SUM(convert(int,vacc.new_tests)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as sumNewTest,
	SUM(convert(int,vacc.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as sumNewVacc
	from CovidPortfolio..CovidDeaths dea
	join CovidPortfolio..CovidVaccinations vacc
	on dea.location = vacc.location
	and dea.date = vacc.date
	where dea.continent is not null
	-- optional, there is possibility to add more "where" clause which allows to show date without "null" properties)'

--calculating nev_vaccination vs population
--using CTE

with popVsVacc (location, date, population, new_vaccinations, sumNewVacc)
as
(
select dea.location, dea.date, dea.population, vacc.new_vaccinations,
	SUM(convert(int,vacc.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as sumNewVacc
	from CovidPortfolio..CovidDeaths dea
	join CovidPortfolio..CovidVaccinations vacc
	on dea.location = vacc.location
	and dea.date = vacc.date
	where dea.continent is not null
)
select *,(sumNewVacc/population)*100 as numberOfVaccinated from popVsVacc


-- with Temp Table
drop table if exists #precentPopulationVaccinated
Create Table #precentPopulationVaccinated
(
location nvarchar(200),
date datetime,
population numeric, 
new_vaccinations numeric, 
sumNewVacc numeric
)

Insert into #precentPopulationVaccinated
select dea.location, dea.date, dea.population, vacc.new_vaccinations,
	SUM(convert(int,vacc.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as sumNewVacc
	from CovidPortfolio..CovidDeaths dea
	join CovidPortfolio..CovidVaccinations vacc
	on dea.location = vacc.location
	and dea.date = vacc.date
	where dea.continent is not null

select *,(sumNewVacc/population)*100 as numberOfVaccinated from #precentPopulationVaccinated


-- creating view for later data visualisation

create view precentPopulationVaccinated as
select dea.location, dea.date, dea.population, vacc.new_vaccinations,
	SUM(convert(int,vacc.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date) as sumNewVacc
	from CovidPortfolio..CovidDeaths dea
	join CovidPortfolio..CovidVaccinations vacc
	on dea.location = vacc.location
	and dea.date = vacc.date
	where dea.continent is not null

	select * from precentPopulationVaccinated
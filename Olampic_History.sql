DROP TABLE IF EXISTS athletes;
CREATE TABLE athletes(
					id int not null,
					athlete_name varchar(125),
					sex varchar(10),
					height int,
					weight int,
					team varchar(65),
					PRIMARY KEY(id)
					);

DROP TABLE IF EXISTS athlete_events;
CREATE TABLE athlete_events(
							athlete_id int not null,
							games varchar(55),
							year_played smallint,
							season varchar(20),
							city varchar(45),
							sport varchar(65),
							event_name varchar(120),
							medal varchar(35)
							);


--EXPLORATORY DATA
--Which Country has won the most Olampic medals?

select a.team,
		count(*) as total_medals
from athletes a
join athlete_events ae
on ae.athlete_id = a.id
where ae.medal in ('Gold', 'Silver', 'Bronze')
group by a.team
order by count(*) desc
limit 10;

--% of Missing height and weight

select count(*) as total_athletes,
		count(height) as height_present,
		count(*) - count(height) as height_missing,
		ROUND((count(*)-count(height))*100/count(*),2) as height_missing_percent,
		count(weight) as weight_present,
		count(*) - count(weight) as weight_missing,
		ROUND((count(*)-count(weight))*100/count(*),2) as weight_missing_percent
from athletes;


--How many male and female athletes have participated over time?

select ae.year_played,
		a.sex,
		count(*) as athlete_count
from athletes a
join athlete_events ae
on ae.athlete_id = a.id
group by ae.year_played, a.sex
order by ae.year_played;


--Which sport has the most event?

select sport,
		count(*) as total_events
from athlete_events
group by sport
order by count(*) desc
limit 10;


--DATA ANALYSIS

--Q1.How many athletes participated from each team in the most recent Olampic games?

select a.team,
		count(distinct a.id) as athlete_count
from athletes a
join athlete_events ae
on ae.athlete_id = a.id
where ae.year_played = (select max(year_played) from athlete_events)
group by a.team
order by athlete_count desc;

--Q2.Which team has won the maximum gold medals over the years?

select a.team,
		count(*) as gold_medal_count
from athletes a
join athlete_events ae
on ae.athlete_id = a.id
where ae.medal = 'Gold'
group by a.team
order by gold_medal_count desc
limit 5;

--Q3.For each team print total silver medals and year in which they won maximum silver medal..output 3 columns
-- team,total_silver_medals, year_of_max_silver?

with silver_medals_by_team_year as (
		select a.team,
				ae.year_played,
				count(distinct ae.event_name) as silver_medals,
				rank() over(
					partition by a.team
					order by count(distinct ae.event_name)
					) as rn
		from athletes a
		inner join athlete_events ae
		on ae.athlete_id = a.id
		where ae.medal = 'Silver'
		group by a.team, ae.year_played
)
select team,
		sum(silver_medals) as total_silver_medals,
		max(case when rn = 1 then year_played end) as year_of_max_silver
from silver_medals_by_team_year
group by team
order by total_silver_medals desc
limit 10;

--Q4.What is the average height and weight of athletes who won a medal, grouped by medal type?

select ae.medal,
		round(avg(height), 2) as avg_height,
		round(avg(weight), 2) as avg_weight
from athletes a
join athlete_events ae
on ae.athlete_id = a.id
where ae.medal in ('Gold', 'Silver', 'Bronze')
		and a.height is not null 
		and a.weight is not null
group by ae.medal
order by avg_height desc;

--Q5.Which player has won maximum gold medals  amongst the players.
--which have won only gold medal (never won silver or bronze) over the years?

select a.athlete_name,
		count(*) as gold_medal_count
from athletes a
join athlete_events ae 
on ae.athlete_id = a.id
where ae.medal = 'Gold'
	and a.id not in (
	 	select distinct athlete_id
		 from athlete_events
		 where medal in ('Silver', 'Bronze')
		 )
group by a.athlete_name, a.id
order by gold_medal_count desc
limit 1;

		
--Q6.In each year which player has won maximum gold medal . Write a query to print year,player name 
--and no of golds won in that year. In case of a tie print comma separated player names?

with top_athletes as (
	select ae.year_played,
			a.athlete_name,
			count(*) as gold_count,
			max(count(*)) over(partition by ae.year_played) as max_gold_in_year
	from athletes a
	join athlete_events ae
	on ae.athlete_id = a.id
	where ae.medal = 'Gold'
	group by ae.year_played, a.athlete_name
)
select year_played,
		string_agg(athlete_name, ',' order by athlete_name) as player_name,
		gold_count as no_of_golds
from top_athletes 
where gold_count = max_gold_in_year
group by year_played, gold_count
order by year_played;

--Q7.In which event and year India has won its first gold medal,first silver medal and first bronze medal
--print 3 columns medal,year,sport?

with india_medals as (
		select ae.medal,
			ae.year_played as year,
			ae.sport,
			ae.event_name,
			row_number() over(partition by ae.medal 
								order by ae.year_played, ae.event_name) as rn
		from athletes a
		join athlete_events ae
		on ae.athlete_id = a.id
		where ae.medal in ('Gold', 'Silver', 'Bronze')
			and a.team = 'India'
)
select medal,
		year,
		sport
from india_medals
where rn = 1
order by case medal
			when 'Gold' then 1
			when 'Silver' then 2
			when 'Bronze' then 3
			end;

--Q8.Find players who won gold medal in summer and winter olympics both?

with gold_medalist as (
		select a.athlete_name as player,
				ae.season
		from athletes a
		inner join athlete_events ae
		on ae.athlete_id = a.id
		where ae.medal = 'Gold'
				and ae.season in ('Summer', 'Winter')
		group by a.athlete_name, ae.season
)
select  player
from gold_medalist
group by player
having count(distinct season) = 2
order by player;

--Q9.What is the gender distribution of athletes in each Olampic season?

select ae.season,
		a.sex,
		count(distinct a.id) as athlete_count,
		round((count(distinct a.id)/sum(count(distinct a.id)) over(partition by ae.season)*100.0),
		2) as percentage_in_season
from athletes a
join athlete_events ae
on ae.athlete_id = a.id
group by ae.season, a.sex
order by athlete_count desc;


--Q10.Find players who have won gold medals in consecutive 3 summer olympics in the same event.Consider only olympics 2000 onwards. 
--Assume summer olympics happens every 4 year starting 2000. print player name and event name.

with summer_gold_medals as (
		select a.athlete_name,
				ae.event_name,
				ae.year_played
		from athletes a
		inner join athlete_events ae
		on ae.athlete_id = a.id
		where ae.medal = 'Gold'
		and ae.season = 'Summer'
		and ae.year_played >= 2000
),
consecutive_3_wins as (
		select athlete_name,
				event_name,
				year_played,
				lag(year_played, 1) over(
										partition by athlete_name, event_name
										order by year_played
									) as prev_year,
				lead(year_played, 1) over(
										partition by athlete_name, event_name
										order by year_played
									) as next_year
		from summer_gold_medals
)

select athlete_name as player,
		event_name as event
from consecutive_3_wins
where year_played = prev_year + 4
and year_played = next_year - 4 


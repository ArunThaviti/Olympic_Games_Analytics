# 🏅Olympic_Games_Analytics

📊 **A PostgreSQL-based SQL Analysis Project on 120+ Years of Olympic History (1896 - 2016)**

This project explores athlete performance, national dominance, and historical trends using **Common Table Expressions (CTEs)** and advanced SQL techniques in **PostgreSQL**.

---

## 📥 Dataset Overview

The dataset covers Olympic Games from **1896 to 2016** and is sourced from **two CSV files**:
### 📁1. `athletes.csv`
Contains demographic information about each athlete.

| Column Name    | Description |
|----------------|-------------|
| `id`           | Unique identifier for each athlete |
| `athlete_name` | Full name of the athlete (renamed from `name`) |
| `sex`          | Gender of the athlete (`M` or `F`) |
| `height`       | Height in centimeters (nullable) |
| `weight`       | weight in kilograms(nullable) |
| `team`         | National team or country the athlete represents |

> 💡 Note: `athlete_name` was renamed from `name` for clarity.

---

### 📁2. `athlete_events.csv`
Contains participation and results data for each Olympic event.

| Column Name     | Description |
|-----------------|-------------|
| `athlete_id`    | Foreign key linking to `athletes.id` |
| `games`         | Name of the Games (e.g., "1996 Summer") |
| `year_played`   | Year of the Games (renamed from `year`) |
| `season`        | Season of the Games (`Summer` or `Winter`) |
| `city`          | Host city of the Games |
| `sport`         | Sport discipline (e.g., Athletics, Swimming) |
| `event`         | Specific event within the sport (e.g., "100m Men's Sprint") |
| `medal`         | Medal won (`Gold`, `Silver`, `Bronze`, or `NA` → converted to `NULL`) |

> 💡 Note: `year_played` was renamed from `year` for clarity. `'NA'` values in `medal` were converted to `NULL` during data cleaning.

---

## 🔧 Technologies Used

- **PostgreSQL** – Database engine for storage and querying
- **SQL** – Advanced queries using:
  - Common Table Expressions (CTEs)
  - Window functions (`LAG`, `LEAD`, `RANK`, `ROW_NUMBER`, `STRING_AGG`)
  - Aggregation, filtering, and conditional logic
- **Data Analysis Techniques**:
  - Exploratory Data Analysis (EDA)
  - Data cleaning (`'NA'` → `NULL`, handling missing height/weight)
  - Trend analysis over time
  - Ranking and grouping
- **Tools**: CSV, `COPY` command, pgAdmin, GitHub

---

## 🧠 Key Analyses & Insights

The following 10 business questions were addressed using **CTEs**, **window functions**, and **clean SQL logic**:

1. ✅ **How many athletes participated from each team in the most recent Olympic Games?**  
   - Identified top delegations (e.g., USA, Australia) in the **2016 Rio Olympics**.

2. ✅ **Which team has won the maximum gold medals over the years?**  
   - The **USA** leads by a wide margin in total gold medal count (1896–2016).

3. ✅ **For each team, total silver medals and year of maximum silver wins?**  
   - Used `RANK()` and aggregation to find peak performance years.

4. ✅ **What is the average height and weight of athletes who won a medal, grouped by medal type?**  
   - Gold medalists are slightly taller and heavier on average — possibly due to sport-specific advantages.

5. ✅ **Which player has won the most gold medals among those who *only* won gold (never silver or bronze)?**  
   - Identified "pure gold" athletes — those who never stood on lower podium steps.

6. ✅ **In each year, which player won the most gold medals? (Handle ties)**  
   - Used `STRING_AGG` to combine names when multiple athletes tied for top.

7. ✅ **In which event and year did India win its first Gold, Silver, and Bronze medal?**  
   - First Gold: **1928 Amsterdam Olympics** in **Hockey** — a historic milestone.

8. ✅ **Find players who won gold medals in both Summer and Winter Olympics?**  
   - Extremely rare — only a few legends like **Eddie Eagan**

9. ✅ **What is the gender distribution of athletes in each Olympic season?**  
   - Female participation has steadily increased — from <5% in 1896 to ~44% in 2016.

10. ✅ **Find players who won gold medals in 3 consecutive Summer Olympics (2000 onwards) in the same event?**  
    - Legends like **Usain Bolt** and **Michael Phelps** achieved this rare feat of sustained dominance.

---

## 🚀 Sample Query: 3 Consecutive Golds

```sql
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

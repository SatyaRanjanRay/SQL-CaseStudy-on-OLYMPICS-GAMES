DROP TABLE IF EXISTS OLYMPICS_HISTORY;
CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY
(
    id          INT,
    name        VARCHAR,
    sex         VARCHAR,
    age         VARCHAR,
    height      VARCHAR,
    weight      VARCHAR,
    team        VARCHAR,
    noc         VARCHAR,
    games       VARCHAR,
    year        INT,
    season      VARCHAR,
    city        VARCHAR,
    sport       VARCHAR,
    event       VARCHAR,
    medal       VARCHAR
);

DROP TABLE IF EXISTS OLYMPICS_HISTORY_NOC_REGIONS;
CREATE TABLE IF NOT EXISTS OLYMPICS_HISTORY_NOC_REGIONS
(
    noc         VARCHAR,
    region      VARCHAR,
    notes       VARCHAR

SELECT * FROM OLYMPICS_HISTORY;
SELECT * FROM OLYMPICS_HISTORY_NOC_REGIONS;


-- Q1. How many olympics games have been held?
SELECT COUNT(DISTINCT(games)) FROM OLYMPICS_HISTORY;

-- Q2. List down all Olympics games held so far.
SELECT DISTINCT year, season, city FROM OLYMPICS_HISTORY;

-- Q3. Mention the total no of Countries who participated in each olympics game?
WITH All_Countries AS 
	(SELECT games,nr.region
	 from OLYMPICS_HISTORY oh 
	 JOIN OLYMPICS_HISTORY_NOC_REGIONS nr on oh.noc=nr.noc
	 GROUP BY games,nr.region)
SELECT games,COUNT(1) as Total_Countries
FROM All_Countries
GROUP BY games
ORDER BY games;
	
-- Q4. Which year was the highest and lowest no of countries participated in olympics?
WITH All_Countries AS 
		(SELECT games,nr.region
		 FROM OLYMPICS_HISTORY oh 
		 JOIN OLYMPICS_HISTORY_NOC_REGIONS nr on oh.noc=nr.noc
		 GROUP BY games,nr.region),    
	 count_Countries AS 
		(SELECT games,COUNT(1) as Total_Countries
		 FROM All_Countries
		 GROUP BY games
		 ORDER BY games)
SELECT DISTINCT
	CONCAT(FIRST_VALUE(games) OVER(ORDER BY Total_Countries)
	,'-'
	,FIRST_VALUE(Total_Countries) OVER(ORDER BY Total_Countries)) AS Lowest_no_of_countries,
	CONCAT(LAST_VALUE(games) OVER(ORDER BY Total_Countries 
	RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)
	,'-'
	,LAST_VALUE(Total_Countries) OVER(ORDER BY Total_Countries
	RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING)) AS Highest_no_of_countries
	FROM count_Countries;

-- Q5. Which Country has participated in all of the olympic games?

-- Approach-1 (Using CTE & JOIN):
WITH Tot_games AS
	    (SELECT COUNT(DISTINCT (games))as Total_games
		FROM OLYMPICS_HISTORY),
	 All_Countries AS 
		(SELECT games,nr.region as Country
		 FROM OLYMPICS_HISTORY oh 
		 JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON oh.noc=nr.noc
		 GROUP BY games,nr.region),    
	 count_Countries AS 
		(SELECT Country,COUNT(1) AS Total_Participated_games
		 FROM All_Countries
		 GROUP BY Country)
SELECT cc.* 
FROM count_Countries  cc
JOIN Tot_games tg ON tg.Total_games=cc.Total_Participated_games ;

-- Approach-2 (Using CTE & SubQuery)
WITH All_Countries AS 
		(SELECT games,nr.region AS Country
		 FROM OLYMPICS_HISTORY oh 
		 JOIN OLYMPICS_HISTORY_NOC_REGIONS nr ON oh.noc=nr.noc
		 GROUP BY games,nr.region),    
	 count_Countries AS 
		(SELECT Country,COUNT(1) AS Total_Participated_games
		 FROM All_Countries
		 GROUP BY Country)
SELECT * 
FROM count_Countries 
WHERE Total_Participated_games IN 
(SELECT COUNT(DISTINCT (games)) AS Total_games
FROM OLYMPICS_HISTORY );
	

-- Q6. Identify the sport which was played at every summer olympics.
	
WITH table1 AS
	    (SELECT COUNT(DISTINCT (games))as Total_games
		FROM OLYMPICS_HISTORY WHERE season='Summer' ),
	 table2 AS
	    (SELECT DISTINCT games,sport 
		FROM OLYMPICS_HISTORY WHERE season='Summer'),
	 table3 AS
	    (SELECT sport,COUNT(1) AS no_of_games
		FROM table2
		GROUP BY sport)
SELECT *
FROM table3 t3
JOIN table1 t1
ON t1.Total_games=t3.no_of_games;
	 
--Q7. Which Sports were just played only once in the olympics?

WITH table1 AS
	    (SELECT DISTINCT games,sport 
		FROM OLYMPICS_HISTORY),
	 table2 AS
	    (SELECT sport,COUNT(1) AS no_of_games
		FROM table1
		GROUP BY sport)
SELECT t2.*,t1.games
FROM table1 t1
JOIN table2 t2
ON t1.sport=t2.sport
WHERE t2.no_of_games=1
ORDER BY sport;
	


-- Q8. Fetch the Total No of sports played in each olympic games.

WITH table1 AS
	   (SELECT distinct games,sport
	   FROM OLYMPICS_HISTORY),
     table2 AS
	   (SELECT games,COUNT(1) AS no_of_games
	   FROM table1
	   GROUP BY games)
SELECT t2.*
FROM table1 t1
JOIN table2 t2
ON t1.games=t2.games
ORDER BY no_of_games DESC;
	  
-- Q9. Fetch oldest athletes to win a gold medal.

WITH table1 AS
	   (SELECT name,sex,cast(case when age = 'NA' then '0' else age end as int) as age,
	    team,noc,games,city,sport,event,medal
	    FROM OLYMPICS_HISTORY),
	 athlete_ranking AS
	    (SELECT *,
		RANK() OVER(ORDER BY age DESC) AS rnk
		FROM table1
		WHERE medal='Gold')
SELECT * 
FROM athlete_ranking
WHERE rnk=1;


-- Q10. Fetch the top 5 athletes who have won the most gold medals
	
-- Condition1: Top 5 Athletes with most gold medals
WITH table1 AS
	   (SELECT name,count(1) AS Medal_count
        FROM OLYMPICS_HISTORY
        WHERE medal='Gold'
        GROUP BY name
        ORDER BY Medal_count DESC),
     top_athletes AS
	   (SELECT *,
	    ROW_NUMBER() OVER(ORDER BY medal_count DESC) AS rn
	    FROM table1)
SELECT * 
FROM top_athletes
where rn<=5;
	
-- Condition2: Top 5 athletes considering the same medal holders as one rank
	
WITH table1 AS
		(SELECT name,count(1) AS Medal_count
	 	FROM OLYMPICS_HISTORY
	 	WHERE medal='Gold'
	 	GROUP BY name
	 	ORDER BY Medal_count DESC),
	 top_athletes AS
	 	(SELECT *,
		DENSE_RANK() OVER(ORDER BY medal_count DESC) AS d_rnk
		FROM table1)
SELECT name,medal_count
FROM top_athletes
WHERE d_rnk<=5;

--Q11. Fetch the top 5 athletes who have won the most medals
	
--Condition1: Top 5 Athletes with most medals
SELECT name,team,COUNT(1) AS Medal_count
FROM OLYMPICS_HISTORY
WHERE medal IN ('Gold','Silver','Bronze')	
GROUP BY name,team
ORDER BY Medal_count DESC
LIMIT 5;
	
--Condition2: Top 5 Athletes with most medals (considering same no of medals as one rank)

WITH table1 AS
		(SELECT name,team,COUNT(1) AS Medal_count
	    FROM OLYMPICS_HISTORY
		WHERE medal IN ('Gold','Silver','Bronze')	
		GROUP BY name,team
		ORDER BY Medal_count DESC),
	Top_Athletes AS
		(SELECT *,
		DENSE_RANK() OVER(ORDER BY Medal_count DESC) AS d_rnk
		FROM table1)
SELECT *
FROM Top_Athletes
WHERE d_rnk<=5;
	
	
--Q12. Fetch the top 5 most successful countries in olympics by No of medals won.

WITH table1 AS
		 (SELECT nr.region,COUNT(1) AS Medal_count
		  FROM OLYMPICS_HISTORY oh
          JOIN OLYMPICS_HISTORY_NOC_REGIONS nr
		  ON oh.noc=nr.noc
		  WHERE oh.medal<>'NA'
		  GROUP BY nr.region
		  ORDER BY Medal_count DESC),
	Region_ranking AS
		 (SELECT *,
		 ROW_NUMBER() OVER(ORDER BY Medal_count DESC) AS rn
		 FROM table1)
SELECT *
FROM Region_ranking
WHERE rn<=5;

	
--Q13. List down total gold, silver and bronze medals won by each country.

WITH table1 AS
		 (SELECT nr.region,oh.medal,COUNT(1) AS Medal_count
		  FROM OLYMPICS_HISTORY oh
          JOIN OLYMPICS_HISTORY_NOC_REGIONS nr
		  ON oh.noc=nr.noc
		  WHERE oh.medal<>'NA'
		  GROUP BY nr.region,oh.medal
		  ORDER BY Medal_count DESC)
	
SELECT region,
	MAX(CASE WHEN medal='Gold' THEN medal_count ELSE 0 END )AS gold_medal,
	MAX(CASE WHEN medal='Silver' THEN medal_count ELSE 0 END) AS Silver_medal,
	MAX(CASE WHEN medal='Bronze' THEN medal_count ELSE 0 END) AS Bronze_medal
FROM table1
GROUP BY region
ORDER BY gold_medal DESC, silver_medal DESC, bronze_medal DESC;
	
	

--Q14. List down total gold, silver and bronze medals won by each country corresponding to each olympic games.
	
WITH table1 AS
		 (SELECT oh.games,nr.region,oh.medal,COUNT(1) AS Medal_count
		  FROM OLYMPICS_HISTORY oh
          JOIN OLYMPICS_HISTORY_NOC_REGIONS nr
		  ON oh.noc=nr.noc
		  WHERE oh.medal<>'NA'
		  GROUP BY oh.games,nr.region,oh.medal
		  ORDER BY Medal_count DESC)

SELECT games,region,
	  MAX(CASE WHEN medal='Gold' THEN Medal_count ELSE 0 END) AS Gold_medal,
	  MAX(CASE WHEN medal='Silver' THEN Medal_count ELSE 0 END) AS Silver_medal,
	  MAX(CASE WHEN medal='Bronze' THEN Medal_count ELSE 0 END) AS Bronze_medal
FROM table1
GROUP BY games,region
ORDER BY Gold_medal DESC, Silver_medal DESC, Bronze_medal DESC;
	
	
	
--Q15. Identify which country won the most gold, most silver and most bronze medals in each olympic games

WITH table1 AS
		 (SELECT oh.games,nr.region,oh.medal,COUNT(1) AS Medal_count
		  FROM OLYMPICS_HISTORY oh
          JOIN OLYMPICS_HISTORY_NOC_REGIONS nr
		  ON oh.noc=nr.noc
		  WHERE oh.medal<>'NA'
		  GROUP BY oh.games,nr.region,oh.medal
		  ORDER BY Medal_count DESC),
-- SELECT * FROM table1 
    table2 AS
		 (SELECT games,region,
		  MAX(CASE WHEN medal='Gold' THEN Medal_count ELSE 0 END) AS Gold_medal,
		  MAX(CASE WHEN medal='Silver' THEN Medal_count ELSE 0 END) AS Silver_medal,
		  MAX(CASE WHEN medal='Bronze' THEN Medal_count ELSE 0 end) AS Bronze_medal
		  FROM table1
		  GROUP BY games,region
		  ORDER BY Gold_medal DESC, Silver_medal DESC, Bronze_medal DESC)
-- SELECT * FROM table2
SELECT DISTINCT games,

CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY gold_medal DESC)
,'-'
,FIRST_VALUE(gold_medal) OVER(PARTITION BY games ORDER BY gold_medal DESC)) AS Max_gold_medal,
	
CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY silver_medal DESC)
,'-'
,FIRST_VALUE(silver_medal) OVER(PARTITION BY games ORDER BY silver_medal DESC)) AS Max_silver_medal,

CONCAT(FIRST_VALUE(region) OVER(PARTITION BY games ORDER BY Bronze_medal DESC)
,'-'
,FIRST_VALUE(bronze_medal) OVER(PARTITION BY games ORDER BY bronze_medal DESC)) AS Max_bronze_medal
FROM table2
ORDER BY games;

	
	
--Q16. Identify which country won the most gold, most silver, most bronze medals and the most medals in each olympic games.
WITH tot_medals AS
		 (SELECT oh.games,nr.region,COUNT(1) AS Total_medals
		  FROM OLYMPICS_HISTORY oh
		  JOIN OLYMPICS_HISTORY_NOC_REGIONS nr
		  ON oh.noc=nr.noc
		  WHERE oh.medal<>'NA'
		  GROUP BY oh.games,nr.region 
		  ORDER BY 1, 2),
-- SELECT * FROM Tot_medals
     No_of_medals AS
		 (SELECT oh.games,nr.region,oh.medal,COUNT(1) AS Medal_count
		  FROM OLYMPICS_HISTORY oh
          JOIN OLYMPICS_HISTORY_NOC_REGIONS nr
		  ON oh.noc=nr.noc
		  WHERE oh.medal<>'NA'
		  GROUP BY oh.games,nr.region,oh.medal
		  ORDER BY Medal_count DESC),

	Max_Medal AS
		 (SELECT games,region,
		  MAX(CASE WHEN medal='Gold' THEN Medal_count ELSE 0 END) AS Gold_medal,
		  MAX(CASE WHEN medal='Silver' THEN Medal_count ELSE 0 END) AS Silver_medal,
		  MAX(CASE WHEN medal='Bronze' THEN Medal_count ELSE 0 end) AS Bronze_medal
		  FROM No_of_medals
		  GROUP BY games,region
		  ORDER BY Gold_medal DESC, Silver_medal DESC, Bronze_medal DESC)
-- SELECT * FROM Max_medal
SELECT DISTINCT mm.games,
	
CONCAT(FIRST_VALUE(mm.region) OVER(PARTITION BY mm.games ORDER BY gold_medal DESC)
,'-'
,FIRST_VALUE(mm.gold_medal) OVER(PARTITION BY mm.games ORDER BY gold_medal DESC)) AS Max_gold_medal,

CONCAT(FIRST_VALUE(mm.region) OVER(PARTITION BY mm.games ORDER BY silver_medal DESC)
,'-'
,FIRST_VALUE(mm.silver_medal) OVER(PARTITION BY mm.games ORDER BY silver_medal DESC)) AS Max_silver_medal,

CONCAT(FIRST_VALUE(mm.region) OVER(PARTITION BY mm.games ORDER BY Bronze_medal DESC)
,'-'
,FIRST_VALUE(mm.bronze_medal) OVER(PARTITION BY mm.games ORDER BY bronze_medal DESC)) AS Max_bronze_medal,

CONCAT(FIRST_VALUE(tm.region) OVER(PARTITION BY tm.games ORDER BY Total_medals DESC) 
,'-'
,FIRST_VALUE(tm.Total_medals) OVER(PARTITION BY tm.games ORDER BY Total_medals DESC)) AS Max_medals

FROM Max_medal mm
JOIN tot_medals tm 
ON tm.games=mm.games AND tm.region=mm.region 
ORDER BY games;


--Q17. Which countries have never won gold medal but have won silver/bronze medals?
	
WITH Table1 AS
		(SELECT nr.region,oh.medal,COUNT(1) AS medal_count
		FROM OLYMPICS_HISTORY oh
		JOIN OLYMPICS_HISTORY_NOC_REGIONS nr
		ON oh.noc=nr.noc
		WHERE medal<>'NA'
		GROUP BY nr.region,oh.medal
		ORDER BY nr.region,oh.medal)
SELECT * FROM (SELECT region,
	  MAX(CASE WHEN medal='Gold' THEN Medal_count ELSE 0 END) AS Gold_medal,
	  MAX(CASE WHEN medal='Silver' THEN Medal_count ELSE 0 END) AS Silver_medal,
	  MAX(CASE WHEN medal='Bronze' THEN Medal_count ELSE 0 end) AS Bronze_medal
	FROM Table1
	GROUP BY region) table2
	WHERE Gold_medal=0 AND (Silver_medal>0 OR Bronze_medal>0);


-- Q18. In which Sport/event, India has won highest medals. 

--Approach-1 (Window Function)
	
WITH Total_medals AS 
		(SELECT oh.sport,COUNT(medaL) as Medal_count
		FROM OLYMPICS_HISTORY oh
		JOIN OLYMPICS_HISTORY_NOC_REGIONS nr
		ON oh.noc=nr.noc
		WHERE medal<>'NA' AND REGION='India'
		GROUP BY sport),
     Highest_medal AS
		(SELECT *,
 		RANK() OVER(ORDER BY Medal_count DESC) as rnk
		FROM Total_medals)
SELECT sport,Medal_count
FROM Highest_medal
WHERE rnk=1;

-- Approach-2 (SubQuery)
	
WITH Total_medals AS 
		(SELECT oh.sport,COUNT(medaL) as Medal_count
		FROM OLYMPICS_HISTORY oh
		JOIN OLYMPICS_HISTORY_NOC_REGIONS nr
		ON oh.noc=nr.noc
		WHERE medal<>'NA' AND REGION='India'
		GROUP BY sport)
SELECT sport, Medal_count 
FROM Total_medals 
WHERE medal_count IN (SELECT MAX(Medal_count) FROM Total_medals);


--Q19. Break down all olympic games where India won medal for Hockey and how many medals in each olympic games
	
SELECT team, sport, games, COUNT(1) AS total_medals
    FROM olympics_history
    WHERE medal <> 'NA'
    AND team = 'India' AND sport = 'Hockey'
    GROUP BY team, sport, games
    ORDER BY total_medals DESC;
	
	
	
	
	
	
	
	
	
	
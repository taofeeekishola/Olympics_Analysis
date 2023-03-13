SELECT * FROM AthleteEvents;

--Total Number of Olympic games held so far
SELECT COUNT(DISTINCT Games) AS TotalOlympicGames FROM AthleteEvents;


--Finding all the Olympic Games so far
Select DISTINCT Games, City FROM AthleteEvents
ORDER BY Games
;


--Finding the total number of countries that participated in each olympic game
SELECT Games, COUNT(DISTINCT NOC) AS Total_Countries FROM AthleteEvents
GROUP BY Games;


--Finding the Olymppic game with the lowest and highest countries
WITH TEMP AS
	(SELECT CONCAT(Games, ' - ', COUNT(DISTINCT NOC)) AS lowest, 
		   CONCAT(Games, ' - ', COUNT(DISTINCT NOC)) AS highest FROM AthleteEvents
	GROUP BY Games)
SELECT MIN(lowest) AS Lowest_Countries, MAX(highest) Highest_Countries FROM TEMP;


--Finding the number of time each country has participated in the Olympic games
SELECT TOP(4) NE.region, COUNT(DISTINCT Games) Total_Participated_Game FROM AthleteEvents AE
JOIN NocRegions NE ON NE.NOC = AE.NOC 
GROUP BY NE.region
ORDER BY Total_Participated_Game  DESC;


--Finding all the sports that were played in all the SUMMER olympic games
WITH T1 AS(
	SELECT COUNT(DISTINCT Games) AS Total_Summer_Games FROM AthleteEvents
	WHERE Season = 'Summer'),
	T2 AS(
	SELECT DISTINCT Sport, Games FROM AthleteEvents
	WHERE Season = 'Summer' ),
	T3 AS (
	SELECT Sport, COUNT(Games) AS No_Of_Games FROM T2
	GROUP BY Sport)

SELECT * FROM T3
JOIN T1 ON T1.Total_Summer_Games = T3.No_Of_Games;

--Finding top 5 Athlets that have won the most gold medals

WITH T1 AS(
	SELECT Name, COUNT(1) AS Total_Medals FROM AthleteEvents
	WHERE Medal = 'Gold'
	GROUP BY Name
	),
	T2 AS (SELECT *, DENSE_RANK() OVER(ORDER BY Total_Medals DESC) AS RNK FROM T1)

SELECT * FROM T2
WHERE RNK <= 5;

--Finding all the Gold, Silva and Bronze medal won by all the countries
SELECT Country, 
COALESCE([Gold], 0) AS Gold, 
COALESCE([Silver], 0) AS Silver, 
COALESCE([Bronze], 0) AS Bronze
FROM
(SELECT NE.region AS Country, Medal, COUNT(Medal) AS Total_medals FROM AthleteEvents AE
JOIN NocRegions NE ON NE.NOC = AE.NOC
WHERE Medal <> 'NA'
GROUP BY NE.region, Medal
) AS Source_Table

PIVOT(
 Max(Total_medals) FOR
 Medal in ([Bronze],[Gold] , [Silver])
) AS Pivot_Table
ORDER BY Gold DESC, Silver DESC, Bronze DESC;


--Finding the country that won the most Gold, most Silver and most Bronze for each Olympic games
WITH TEMP AS
	(SELECT SUBSTRING(Games_Country,1,  CHARINDEX(' - ' , Games_Country)-1) AS Games,
	SUBSTRING(Games_Country, 14, CHARINDEX(' - ' , Games_Country)+3) AS Country,
	COALESCE([Gold], 0) AS Gold, 
	COALESCE([Silver], 0) AS Silver,  
	COALESCE([Bronze], 0) AS Bronze
	FROM
	(SELECT CONCAT(Games,' - ' ,NE.region )AS Games_Country, Medal, COUNT(Medal) AS Total_medals FROM AthleteEvents AE
	JOIN NocRegions NE ON NE.NOC = AE.NOC
	WHERE Medal <> 'NA'
	GROUP BY Games, NE.region, Medal
	) AS Source_Table

	PIVOT(
	 Max(Total_medals) FOR
	 Medal in ([Bronze],[Gold] , [Silver])
	) AS Pivot_Table)

SELECT DISTINCT Games, 
CONCAT(FIRST_VALUE(Country) OVER(PARTITION BY Games ORDER BY Gold DESC),
	' - ',
	FIRST_VALUE(Gold) OVER(PARTITION BY Games ORDER BY Gold DESC)) AS Gold,
CONCAT(FIRST_VALUE(Country) OVER(PARTITION BY Games ORDER BY Silver DESC),
	' - ',
	FIRST_VALUE(Silver) OVER(PARTITION BY Games ORDER BY Silver DESC)) AS Silver,
CONCAT(FIRST_VALUE(Country) OVER(PARTITION BY Games ORDER BY Bronze DESC),
	' - ',
	FIRST_VALUE(Bronze) OVER(PARTITION BY Games ORDER BY Bronze DESC)) AS Bronze
FROM TEMP
ORDER BY Games;


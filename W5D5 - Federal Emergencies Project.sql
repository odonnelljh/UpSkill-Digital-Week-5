--Create the database
CREATE DATABASE FEDERAL_EMERGENCIES

--Ctrl+Shift-R to refresh the local cache

--Use database so we can write code within it
USE FEDERAL_EMERGENCIES



--Import File
--FEMA: FEDERAL EMERGENCY MANAGEMENT AGENCY
--This dataset includes a record for every federal emergency or disaster declared by the President of the United States between 1953-2017
--The disaster database was published by the Federal Emergency Management Agency with data from the National Emergency Management Information System
SELECT * FROM Federal_Emergencies



--Can see only County and Close_Date have NULL values. These are fine, as disasters can be state-wide, and they may have never had close dates recorded
--Decleration_Type: Disaster = Large-scale event, Emergency = Small-scale event, Fire = A fire(?)

SELECT Declaration_Type, COUNT(Declaration_Type) AS DEC_COUNT
FROM Federal_Emergencies
GROUP BY Declaration_Type


--Count disasters per state
SELECT State, COUNT(Declaration_Date) AS State_Disaster_Count
		FROM Federal_Emergencies
		GROUP BY State


--Count what kind, and how many, disasters occured in each state
SELECT State, Disaster_Type, COUNT(Disaster_Type) AS Times_Declared
FROM Federal_Emergencies
GROUP BY State, Disaster_Type

--Now find the title of each disaster, and count how many times that happened
SELECT State, Disaster_Type, Disaster_Title, COUNT(Disaster_Title) AS Times_Spec_Declared
FROM Federal_Emergencies
GROUP BY State, Disaster_Type, Disaster_Title

--That gives unique, named results, but can also show that, for example, Alaska (AK) had 7 Earthquakes


--We also can see that Hurricane Katrina Evacuations were among the previous data selection. Let's drill into that...
SELECT State, Disaster_Title, COUNT(Declaration_Date) AS EVAC_EMERGENCIES_DECLARED
FROM Federal_Emergencies
WHERE Disaster_Title = 'Hurricane Katrina Evacuation'
GROUP BY State, Disaster_Title
ORDER BY EVAC_EMERGENCIES_DECLARED ASC



--And what about wildfires?
SELECT SUM(FIRES_DECLARED) AS SUM_OF_US_FIRES
FROM (SELECT COUNT(Declaration_Date) AS FIRES_DECLARED
		FROM Federal_Emergencies
		WHERE Disaster_Title LIKE '%fire%' OR Disaster_Title LIKE 'Fire'
		) Fire


--What's the average amount of disasters in the US?
SELECT AVG(DISASTER_DECLARED) AS AVG_US_DISASTERS
FROM (SELECT State, COUNT(Declaration_Date) AS DISASTER_DECLARED
		FROM Federal_Emergencies
		GROUP BY State
		) Av


--How many disasters happened between the year 2000, and now? (Only goes to 2017 obviously)
SELECT Disaster_Type, COUNT(Disaster_Type) AS DISASTER_COUNT
FROM Federal_Emergencies
WHERE Start_Date BETWEEN '2000-01-01' AND '2017-01-01'
GROUP BY Disaster_Type

--A lot! Almost 12,000 storms


--MORE DETAIL
SELECT Disaster_Type, Start_Date, COUNT(Disaster_Type) AS DISASTER_COUNT
FROM Federal_Emergencies
WHERE Start_Date BETWEEN '2000-01-01' AND '2017-01-01'
GROUP BY Disaster_Type, Start_Date


--A view to consolidate the disaster data?
GO
CREATE VIEW STATE_WIDE_AID AS
SELECT State,Disaster_Type, Disaster_Title, Individual_Assistance_Program, Individuals_Households_Program, Public_Assistance_Program, Hazard_Mitigation_Program
FROM Federal_Emergencies
GO

SELECT * FROM STATE_WIDE_AID

DROP VIEW STATE_WIDE_AID


--State count! Looks like there are more than the normal 50?
SELECT DISTINCT State, COUNT(DISTINCT State)
FROM Federal_Emergencies
GROUP BY State


--Assistance count?
GO
CREATE VIEW STATE_WIDE_AID AS
SELECT State,Disaster_Type, COUNT(Individual_Assistance_Program) AS IND_ASSISTANCE, COUNT(Individuals_Households_Program) AS HOUSEHOLD_PROGRAM, 
COUNT(Public_Assistance_Program) PUB_ASSIST, COUNT(Hazard_Mitigation_Program) AS HAZ_MIT
FROM Federal_Emergencies
GROUP BY State, Disaster_Type
GO

SELECT * FROM STATE_WIDE_AID

DROP VIEW STATE_WIDE_AID





--How many disasters were started, but never classified as closed?
SELECT Disaster_Type, COUNT(Declaration_Date) AS DATES_DECLARED, COUNT(Close_Date) AS DATES_CLOSED
FROM Federal_Emergencies
GROUP BY Disaster_Type

--Interesting! For example, 4 cases of terrorism have never been closed? Odd!




--Now, time to let the user of this data access the count within the span of a year

--Stored procedure to select count of disasters in a specific state within the period of a year
GO
CREATE PROCEDURE StateDisastersOneYear
@State AS VARCHAR(30), @Year AS DATETIME
AS
SELECT  State, Disaster_Type, COUNT(Disaster_Type) AS DISASTER_COUNT FROM Federal_Emergencies
WHERE State = @State AND Start_Date BETWEEN @Year AND DATEADD(year, 1, @Year)
GROUP BY State, Disaster_Type
GO


--Check if it works...
EXEC StateDisastersOneYear @State = 'TX', @Year = '2015-01-01';
--OR
EXEC StateDisastersOneYear 'AK', '2002-01-01';


--In case it needs to be altered 
GO
ALTER PROCEDURE StateDisastersOneYear
@State AS VARCHAR(30), @Year AS DATETIME
AS
SELECT  State, Disaster_Type, COUNT(Disaster_Type) AS DISASTER_COUNT FROM Federal_Emergencies
WHERE State = @State AND Start_Date BETWEEN @Year AND DATEADD(year, 1, @Year)
GROUP BY State, Disaster_Type
GO


--In case needing to delete the procedure
DROP PROCEDURE IF EXISTS StateDisastersOneYear






--Let's create a function, so the data's user can get quick information
GO
CREATE FUNCTION GetAllStateDisasters (
	@State_Name VARCHAR(10)
)
RETURNS TABLE
AS
RETURN SELECT State, County, Disaster_Type, COUNT(Disaster_Type) AS DISASTER_COUNT FROM Federal_Emergencies
		WHERE State = @State_Name
		GROUP BY State, County, Disaster_Type
GO


--Check if it works...
SELECT * FROM GetAllStateDisasters ('AK')
ORDER BY Disaster_Type
GO

--Drop function if needed
DROP FUNCTION IF EXISTS GetAllStateDisasters










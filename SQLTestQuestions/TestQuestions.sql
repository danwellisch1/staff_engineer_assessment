USE PERSONDATABASE

/*********************
Hello! 

Please use the test data provided in the file 'PersonDatabase' to answer the following
questions. Please also import the dbo.Contracts flat file to a table for use. 

All answers should be written in SQL. 


***********************

QUESTION 1


The table dbo.Person contains basic demographic information. The source system users 
input nicknames as strings inside parenthesis. Write a query or group of queries to 
return the full name and nickname of each person. The nickname should contain only letters 
or be blank if no nickname exists.

**********************/
;with findboundaries as
(
select personname, charindex('(', personname) as firstOccurrence, iif(datalength(personname) < datalength(personname) - charindex(')', reverse(personname)) + 1, 0,datalength(personname) - charindex(')', reverse(personname)) + 1)   as lastOccurrence from Person
),
names
as
(
select personname, iif(f.firstOccurrence = 0 or f.lastOccurrence = 0,'', substring(f.personname, f.firstOccurrence, f.lastOccurrence - f.firstOccurrence + 1)) as nicknamewithparens from findboundaries f
)
select ltrim(rtrim(replace(n.personname, n.nicknamewithparens, ''))) as fullname, replace(replace(n.nicknamewithparens,'(',''),')','') as nickname from names n


/**********************

QUESTION 2


The dbo.Risk table contains risk and risk level data for persons over time for various 
payers. Write a query that returns patient name and their current risk level. 
For patients with multiple current risk levels return only one level so that Gold > Silver > Bronze.


**********************/
with personrisk as
(
select p.personid, p.personname, r.risklevel, r.riskdatetime
from person p
inner join risk r on r.personid = p.personid
),
maxinfo as
(
select personid, max(risklevel) as highestlevel, max(riskdatetime) as currentrisk from risk
group by personid
)
select pr.personid, pr.personname, pr.risklevel, pr.riskdatetime
from personrisk pr
inner join maxinfo m on m.highestlevel = pr.risklevel and m.currentrisk = pr.riskdatetime
 

/**********************

QUESTION 3

Create a patient matching stored procedure that accepts (first name, last name, dob and sex) as parameters and 
and calculates a match score from the Person table based on the parameters given. If the parameters do not match the existing 
data exactly, create a partial match check using the weights below to assign partial credit for each. Return PatientIDs and the
 calculated match score. Feel free to modify or create any objects necessary in PersonDatabase.  

FirstName 
	Full Credit = 1
	Partial Credit = .5

LastName 
	Full Credit = .8
	Partial Credit = .4

Dob 
	Full Credit = .75
	Partial Credit = .3

Sex 
	Full Credit = .6
	Partial Credit = .25


**********************/

-- Call 
getMatchScore 'xxx', 'xxx', '1986-05-18', 'Male' 

-- Code
USE [PersonDatabase]
GO
/****** Object:  StoredProcedure [dbo].[getMatchScore]    Script Date: 2/15/2019 6:14:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER FUNCTION calcMatchScore (
	@FirstName varchar(255), 
	@LastName varchar(255), 
	@DOB datetime, 
	@Sex varchar(10),
	@FirstNameIn varchar(255), 
	@LastNameIn varchar(255), 
	@DOBIn datetime, 
	@SexIn varchar(10)

)
RETURNS DEC(10,2) AS
BEGIN

	DECLARE @TotalScore Dec(10,2)
	SET @TotalScore = 0.00
	/*
	FirstName 
		Full Credit = 1
		Partial Credit = .5
	*/
	if @FirstNameIn = @FirstName
		SET @TotalScore = @TotalScore + 1
	else if soundex(@FirstNameIn) = soundex(@FirstName)
		SET @TotalScore = @TotalScore + .5
	/*
	LastName 
		Full Credit = .8
		Partial Credit = .4
	*/
	if @LastNameIn = @LastName
		SET @TotalScore = @TotalScore + .8
	else if soundex(@LastNameIn) = soundex(@LastName)
		SET @TotalScore = @TotalScore + .4
	/*
	Dob 
		Full Credit = .75
		Partial Credit = .3
	*/
	if @DOBIn = @DOB
		SET @TotalScore = @TotalScore + .75
	else if (month(@DOBIn) = month(@DOB) AND year(@DOBIn) = year(@DOB))
		SET @TotalScore = @TotalScore + .3
	/*
	Sex 
		Full Credit = .6
		Partial Credit = .25
	*/
	if @SEX = @SEXIn
		SET @TotalScore = @TotalScore + .6
	else if (CHARINDEX(@SEXIn, @Sex) = 1)
		SET @TotalScore = @TotalScore + .25
    
	RETURN @TotalScore
END

GO
ALTER PROCEDURE getMatchScore
@FirstNameIn varchar(255), 
@LastNameIn varchar(255), 
@DOBIn datetime,
@SexIn varchar(10)
AS    
    DECLARE @matchScore dec(10,2);
    SET NOCOUNT ON; 

	with findboundaries 
	as
	(
		select personid, personname, charindex('(', personname) as firstOccurrence, iif(datalength(personname) < datalength(personname) - charindex(')', reverse(personname)) + 1, 0,datalength(personname) - charindex(')', reverse(personname)) + 1)   as lastOccurrence from Person
	),
	names
	as
	(
		select f.personid, f.personname, iif(f.firstOccurrence = 0 or f.lastOccurrence = 0,'', substring(f.personname, f.firstOccurrence, f.lastOccurrence - f.firstOccurrence + 1)) as nicknamewithparens from findboundaries f
	),
	scrubnames1 as
	(
		select n.personid, ltrim(rtrim(replace(n.personname, n.nicknamewithparens, ''))) as fullname from names n
	),
	scrubnames2 as
	(
		select s1.personid, REPLACE(REPLACE(REPLACE(s1.fullname, ' ', '*^'), '^*', ''), '*^', ' ') as fullnamefinal from scrubnames1 s1
	)
	select s2.personid, dbo.calcMatchScore(PARSENAME(REPLACE(s2.fullNameFinal,' ','.'),2), PARSENAME(REPLACE(s2.fullNameFinal,' ','.'),1), p.DateofBirth, p.Sex, @FirstNameIn, @LastNameIn, @DOBIn, @SexIn)
	from scrubnames2 s2
	inner join person p on p.personid = s2.personid


RETURN  


/**********************

QUESTION 4

A. Looking at the script 'PersonDatabase', what change(s) to the tables could be made to improve the database structure?  

B. What method(s) could we use to standardize the data allowed in dbo.Person (Sex) to only allow 'Male' or 'Female'?

C. Assuming these tables will grow very large, what other database tools/objects could we use to ensure they remain
efficient when queried?


**********************/
A.
Assumption: 

Goal is to minimize redundancy and maximize data integrity.
In other words, this database will be used for transactions and not reporting.

So, let's normalize to 3rd normal.  I will do it in steps to show progression.

Legend: FK: Foreign Key
        PK: Primary Key

1st NF:  

Person table is not in 1st NF - to get it in 1st NF,
         let's create CityId, StateId, and ZipId FKs and 
		 then create the City table (CityId, Name), State table (StateId, Name),
		 and Zipcode table (ZipCodeId, ZipCode).

		 Our table now looks like this:
		 PersonId (will change it to an auto-increment identity PK)
		 PersonName
		 Sex
		 DateOfBirth
		 Address
		 City
		 State
		 Zip
		 IsActive

Risk table already in 1st NF.

2nd NF: Person table already in 2nd NF
        Risk table not in 2nd NF. To get it in 2nd NF:

		Add new primary key as an auto-increment identity PK
		called RiskId

		Change PersonId to an int.  It is now an FK.

		Add the following FKs: AttributePayerId, RiskLevelId

		Create 2 tables:
		
		RiskLevel with LevelID (auto-increment identity PK) and LevelName varchar(10)
		AttributePayer with PayerID (auto-increment identity PK) and PayerName varchar(255)

3rd NF: All tables are now in 3rd NF

Last, we can get rid of the Dates table.  We can create all
of these fields using SQL functions to create each value.  No need
to store them.

B.
drop table sex
create table sex (sex varchar(30))

alter table sex
add constraint chksex CHECK  (binary_checksum(sex) = binary_checksum('Male') or binary_checksum(sex) = binary_checksum('Female')); 

C. I would create a separate denormalized database (PersonEDW) for querying.
   It would be a Data Warehouse Architecture.  We would update it as necessary,
   1 per day at a minimum and preferably at night or when users are not using the transaction db: PersonDatabase



/**********************

QUESTION 5

Write a query to return risk data for all patients, all contracts and a moving average of risk for that patient and contract 
in dbo.Risk. 

**********************/

-- I assumed the requirement was for all data from person/contract joins PLUS
-- the moving average...
/****** Script for SelectTopNRows command from SSMS  ******/
with patientAndContract
as
(
	SELECT r.PersonID
		  ,[AttributedPayer]
		  ,[RiskScore]
		  ,[RiskLevel]
		  ,[RiskDateTime]
		  ,c.ContractStartDate
		  ,c.ContractEndDate
	  FROM [PersonDatabase].[dbo].[Risk] r
	inner join Contracts c on r.PersonID = c.PersonID and r.RiskDateTime between c.ContractstartDate and c.ContractEndDate
),
movingavgs
as
(
	select pc.personid, pc.attributedpayer, avg(riskscore) as ma 
	from patientAndContract pc
	group by pc.personid, pc.AttributedPayer
)
select pc.*, mvavg.ma
from patientAndContract pc
inner join movingavgs mvavg on mvavg.PersonID = pc.PersonID and mvavg.AttributedPayer = pc.AttributedPayer


/**********************

QUESTION 6

Write script to load the dbo.Dates table with all applicable data elements for dates 
between 1/1/2010 and 500 days past the current date.


**********************/

--drop table #temp
--create  table  #temp (DateValue date, DateDayOfMonth int, DateDayOfYear int, DateQuarter int, DateWeekdayName varchar(20), DateMonthName varchar(20), DateYearMonth char(6))
declare @i date 
set @i= cast('2010-01-01' as date)

while(@i <= DATEADD(day, 500, getDate()))
begin
	insert into dates (DateValue, DateDayOfMonth, DateDayOfYear, DateQuarter, DateWeekdayName, DateMonthName, DateYearMonth) values (@i, day(@i), year(@i), DATEPART(QUARTER, @i), DATENAME(DW, @i), DATENAME(M, @i), concat(DATEPART(yy, @i), RIGHT(CONCAT('00', DATEPART(m, @i)), 2)))
	set @i= DATEADD(day, 1, @i)
End





/**********************

QUESTION 7

Please import the data from the flat file dbo.Contracts.txt to a table to complete this question. 

Using the data in dbo.Contracts, create a query that returns 

	(PersonID, AttributionStartDate, AttributionEndDate) 

The data should be structured so that rows with contiguous ranges are merged into a single row. Rows that contain a 
break in time of 1 day or more should be entered as a new record in the output. Restarting a row for a new 
month or year is not necessary.

Use the dbo.Dates table if helpful.

**********************/

-- Algorithm
--Let X = all start dates NOT contained in a date range
--Let Y = all end dates NOT contained in a date range

--So, X = all of our starting points.

--For each X, find the Y with the lowest date greater than X's date that has the same ID



with possibleX as
(
	select personId, contractstartdate from contracts
),
allRange as
(
	select personid, contractstartdate, contractenddate from contracts
),
X as
(
	select px.personId, px.contractstartdate from possibleX px
	where  not exists (select ar.contractstartdate from allRange ar where ar.personid = px.personid and px.contractstartdate > ar.contractstartdate and px.contractstartdate < ar.contractenddate)
),
possibleY as
(
	select personId, contractenddate from contracts
),
Y as
(
	select py.personId, py.contractenddate from possibleY py
	where  not exists (select ar.contractenddate from allRange ar where ar.personid = py.personid and py.contractenddate > ar.contractstartdate and py.contractenddate < ar.contractenddate)
),
filterXY
AS
(
	select X.personId, X.contractstartdate, Y.contractenddate
	from X
	inner join Y on X.personId = Y.personId and X.contractstartdate < Y.contractenddate
)
select filterXY.personId, filterXY.contractstartdate as AttributionStartDate, Min(filterXY.contractenddate) as AttributionEndDate
from filterXY
group by personId, contractstartdate
order by personId, contractstartdate







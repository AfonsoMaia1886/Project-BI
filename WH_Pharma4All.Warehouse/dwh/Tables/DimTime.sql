CREATE TABLE [dwh].[DimTime] (

	[SK_Time] int NOT NULL, 
	[Hour] smallint NOT NULL, 
	[Minute] smallint NOT NULL, 
	[TimeLabel] varchar(5) NOT NULL, 
	[DayPeriod] varchar(15) NOT NULL
);
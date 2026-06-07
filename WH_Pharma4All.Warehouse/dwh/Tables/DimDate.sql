CREATE TABLE [dwh].[DimDate] (

	[SK_Date] int NOT NULL, 
	[FullDate] date NOT NULL, 
	[Day] smallint NOT NULL, 
	[DayName] varchar(10) NOT NULL, 
	[WeekNumber] smallint NOT NULL, 
	[Month] smallint NOT NULL, 
	[MonthName] varchar(10) NOT NULL, 
	[Quarter] smallint NOT NULL, 
	[QuarterName] varchar(10) NOT NULL, 
	[Year] smallint NOT NULL, 
	[IsWeekend] bit NOT NULL, 
	[IsHoliday] bit NOT NULL, 
	[YTDFlag] bit NOT NULL
);
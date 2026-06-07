CREATE TABLE [dwh].[DimLocation] (

	[SK_Location] bigint NOT NULL, 
	[Municipality] varchar(100) NOT NULL, 
	[District] varchar(100) NULL, 
	[Country] varchar(50) NOT NULL
);
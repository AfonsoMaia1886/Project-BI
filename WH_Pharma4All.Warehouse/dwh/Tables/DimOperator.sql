CREATE TABLE [dwh].[DimOperator] (

	[SK_Operator] bigint NOT NULL, 
	[FirstName] varchar(100) NOT NULL, 
	[LastName] varchar(100) NOT NULL, 
	[FullName] varchar(200) NOT NULL, 
	[Email] varchar(255) NULL, 
	[Gender] varchar(20) NULL, 
	[Role] varchar(100) NULL, 
	[Team] int NULL
);
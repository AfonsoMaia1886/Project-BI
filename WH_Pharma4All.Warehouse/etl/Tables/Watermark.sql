CREATE TABLE [etl].[Watermark] (

	[ProcessName] varchar(100) NOT NULL, 
	[LastSourceSaleDateTime] datetime2(0) NULL, 
	[LastSaleID] bigint NULL, 
	[LastSuccessfulRun] datetime2(0) NULL, 
	[UpdatedAt] datetime2(0) NOT NULL
);
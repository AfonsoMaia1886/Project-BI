CREATE TABLE [etl].[LoadLog] (

	[PipelineRunID] varchar(100) NOT NULL, 
	[PipelineName] varchar(150) NOT NULL, 
	[ActivityName] varchar(150) NULL, 
	[TargetTable] varchar(150) NULL, 
	[RowsInserted] bigint NULL, 
	[RowsUpdated] bigint NULL, 
	[Status] varchar(30) NOT NULL, 
	[ErrorMessage] varchar(1000) NULL, 
	[StartedAt] datetime2(0) NOT NULL, 
	[FinishedAt] datetime2(0) NULL
);
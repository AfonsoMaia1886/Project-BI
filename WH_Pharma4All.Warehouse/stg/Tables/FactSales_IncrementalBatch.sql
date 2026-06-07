CREATE TABLE [stg].[FactSales_IncrementalBatch] (

	[SaleID] bigint NOT NULL, 
	[FK_Date] int NOT NULL, 
	[FK_Time] int NOT NULL, 
	[FK_Product] bigint NOT NULL, 
	[FK_Pharmacy] bigint NOT NULL, 
	[FK_Location] bigint NOT NULL, 
	[FK_Operator] bigint NOT NULL, 
	[FK_POS] bigint NOT NULL, 
	[Qty] smallint NOT NULL, 
	[Amount] decimal(18,2) NOT NULL, 
	[CurrencyCode] char(3) NULL, 
	[SourceSaleDateTime] datetime2(0) NOT NULL, 
	[LoadDateTime] datetime2(0) NOT NULL
);
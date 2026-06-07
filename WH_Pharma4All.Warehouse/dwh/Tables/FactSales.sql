CREATE TABLE [dwh].[FactSales] (

	[PK_SaleID] bigint NOT NULL, 
	[FK_Date] int NOT NULL, 
	[FK_Time] int NOT NULL, 
	[FK_Product] bigint NOT NULL, 
	[FK_Pharmacy] bigint NOT NULL, 
	[FK_Location] bigint NOT NULL, 
	[FK_Operator] bigint NOT NULL, 
	[FK_POS] bigint NOT NULL, 
	[Qty] int NOT NULL, 
	[Amount] decimal(18,2) NOT NULL, 
	[CurrencyCode] char(3) NULL, 
	[SourceSaleDateTime] datetime2(6) NOT NULL, 
	[LoadDateTime] datetime2(6) NOT NULL
);
CREATE TABLE [dwh].[DimProduct] (

	[SK_Product] bigint NOT NULL, 
	[CNP] bigint NOT NULL, 
	[ProductName] varchar(255) NOT NULL, 
	[Manufacturer] varchar(255) NULL, 
	[Brand] varchar(255) NULL, 
	[ProductPresentation] varchar(255) NULL, 
	[IsGeneric] bit NOT NULL, 
	[GenericLabel] varchar(20) NOT NULL
);
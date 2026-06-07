CREATE TABLE [dwh].[DimPharmacy] (

	[SK_Pharmacy] bigint NOT NULL, 
	[PharmacyName] varchar(255) NOT NULL, 
	[FK_Location] bigint NOT NULL
);
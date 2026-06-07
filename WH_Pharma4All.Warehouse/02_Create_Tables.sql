CREATE TABLE dwh.DimDate (
    SK_Date INT NOT NULL,
    FullDate DATE NOT NULL,
    [Day] SMALLINT NOT NULL,
    DayName VARCHAR(10) NOT NULL,
    WeekNumber SMALLINT NOT NULL,
    [Month] SMALLINT NOT NULL,
    MonthName VARCHAR(10) NOT NULL,
    [Quarter] SMALLINT NOT NULL,
    QuarterName VARCHAR(10) NOT NULL,
    [Year] SMALLINT NOT NULL,
    IsWeekend BIT NOT NULL,
    IsHoliday BIT NOT NULL,
    YTDFlag BIT NOT NULL
);


CREATE TABLE dwh.DimTime (
    SK_Time INT NOT NULL,
    [Hour] SMALLINT NOT NULL,
    [Minute] SMALLINT NOT NULL,
    TimeLabel VARCHAR(5) NOT NULL,
    DayPeriod VARCHAR(15) NOT NULL
);


CREATE TABLE dwh.DimProduct (
    SK_Product BIGINT NOT NULL,
    CNP BIGINT NOT NULL,
    ProductName VARCHAR(255) NOT NULL,
    Manufacturer VARCHAR(255) NULL,
    Brand VARCHAR(255) NULL,
    ProductPresentation VARCHAR(255) NULL,
    IsGeneric BIT NOT NULL,
    GenericLabel VARCHAR(20) NOT NULL
);


CREATE TABLE dwh.DimLocation (
    SK_Location BIGINT NOT NULL,
    Municipality VARCHAR(100) NOT NULL,
    District VARCHAR(100) NULL,
    Country VARCHAR(50) NOT NULL
);


CREATE TABLE dwh.DimPharmacy (
    SK_Pharmacy BIGINT NOT NULL,
    PharmacyName VARCHAR(255) NOT NULL,
    FK_Location BIGINT NOT NULL
);


CREATE TABLE dwh.DimOperator (
    SK_Operator BIGINT NOT NULL,
    FirstName VARCHAR(100) NOT NULL,
    LastName VARCHAR(100) NOT NULL,
    FullName VARCHAR(200) NOT NULL,
    Email VARCHAR(255) NULL,
    Gender VARCHAR(20) NULL,
    [Role] VARCHAR(100) NULL,
    Team INT NULL
);


CREATE TABLE dwh.DimPOS (
    SK_POS BIGINT NOT NULL,
    POSName VARCHAR(255) NOT NULL,
    POSEmail VARCHAR(255) NULL
);


CREATE TABLE dwh.FactSales (
    SaleKey BIGINT NOT NULL,
    SaleID BIGINT NOT NULL,
    FK_Date INT NOT NULL,
    FK_Time INT NOT NULL,
    FK_Product BIGINT NOT NULL,
    FK_Pharmacy BIGINT NOT NULL,
    FK_Location BIGINT NOT NULL,
    FK_Operator BIGINT NOT NULL,
    FK_POS BIGINT NOT NULL,
    Qty INT NOT NULL,
    Amount DECIMAL(18,2) NOT NULL,
    CurrencyCode CHAR(3) NULL,
    SourceSaleDateTime DATETIME2(6) NOT NULL,
    LoadDateTime DATETIME2(6) NOT NULL
);


CREATE TABLE dwh.DateSlicer (
    FullDate DATE NOT NULL
);

INSERT INTO dwh.DateSlicer (FullDate)
SELECT DISTINCT FullDate
FROM dwh.DimDate;
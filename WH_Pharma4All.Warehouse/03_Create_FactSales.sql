CREATE TABLE dwh.FactSales (
    PK_SaleID BIGINT NOT NULL,
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
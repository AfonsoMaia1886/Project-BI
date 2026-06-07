UPDATE etl.Watermark
SET
    LastSourceSaleDateTime =
    (
        SELECT TOP 1 SourceSaleDateTime
        FROM dwh.FactSales
        ORDER BY SourceSaleDateTime DESC, PK_SaleID DESC
    ),
    LastSaleID =
    (
        SELECT TOP 1 PK_SaleID
        FROM dwh.FactSales
        ORDER BY SourceSaleDateTime DESC, PK_SaleID DESC
    ),
    LastSuccessfulRun = CURRENT_TIMESTAMP,
    UpdatedAt = CURRENT_TIMESTAMP
WHERE ProcessName = 'Load_FactSales';
-- add this as a script activity at the end of the full load pipeline


SELECT *
FROM etl.Watermark
WHERE ProcessName = 'Load_FactSales';
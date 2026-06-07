DROP TABLE IF EXISTS dwh.PharmacySegmentation;

CREATE TABLE dwh.PharmacySegmentation
(
    PharmacyID BIGINT NOT NULL,
    PharmacyName VARCHAR(255) NULL,

    LocationCode VARCHAR(50) NULL,
    LocationName VARCHAR(255) NULL,
    District VARCHAR(100) NULL,
    Country VARCHAR(100) NULL,

    TotalSalesAmount FLOAT NULL,
    TotalQuantity BIGINT NULL,
    NumberOfTransactions BIGINT NULL,
    AvgTransactionAmount FLOAT NULL,

    ProductVariety BIGINT NULL,
    ManufacturerVariety BIGINT NULL,
    BrandVariety BIGINT NULL,

    MonthlySalesIntensity FLOAT NULL,
    BrandedSalesShare FLOAT NULL,
    GenericSalesShare FLOAT NULL,
    RecencyDays BIGINT NULL,

    ClusterID BIGINT NULL,
    SegmentRank BIGINT NULL,
    SegmentLabel VARCHAR(100) NULL,
    SegmentDescription VARCHAR(500) NULL,

    PCA1 FLOAT NULL,
    PCA2 FLOAT NULL,

    ModelRunDate DATE NULL
);
CREATE TABLE etl.Watermark (
    ProcessName VARCHAR(100) NOT NULL,
    LastSourceSaleDateTime DATETIME2(0) NULL,
    LastSaleID BIGINT NULL,
    LastSuccessfulRun DATETIME2(0) NULL,
    UpdatedAt DATETIME2(0) NOT NULL
);

CREATE TABLE etl.LoadLog (
    PipelineRunID VARCHAR(100) NOT NULL,
    PipelineName VARCHAR(150) NOT NULL,
    ActivityName VARCHAR(150) NULL,
    TargetTable VARCHAR(150) NULL,
    RowsInserted BIGINT NULL,
    RowsUpdated BIGINT NULL,
    Status VARCHAR(30) NOT NULL,
    ErrorMessage VARCHAR(1000) NULL,
    StartedAt DATETIME2(0) NOT NULL,
    FinishedAt DATETIME2(0) NULL
);

INSERT INTO etl.Watermark (
    ProcessName,
    LastSourceSaleDateTime,
    LastSaleID,
    LastSuccessfulRun,
    UpdatedAt
)
VALUES (
    'Load_FactSales',
    '1900-01-01 00:00:00',
    0,
    NULL,
    CURRENT_TIMESTAMP
);
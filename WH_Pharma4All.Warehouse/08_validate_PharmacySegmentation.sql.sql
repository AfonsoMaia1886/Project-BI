SELECT COUNT(*) AS RowsInPharmacySegmentation
FROM dwh.PharmacySegmentation;

SELECT SegmentLabel, COUNT(*) AS NumberOfPharmacies
FROM dwh.PharmacySegmentation
GROUP BY SegmentLabel
ORDER BY NumberOfPharmacies DESC;

SELECT COUNT(*) AS MissingPharmacyMatches
FROM dwh.PharmacySegmentation ps
LEFT JOIN dwh.DimPharmacy dp
    ON ps.PharmacyID = CAST(dp.PharmacyID AS VARCHAR(50))
WHERE dp.PharmacyID IS NULL;

if object_id('tempdb..#fulltextFragmentationDetails') is not null drop table #fulltextFragmentationDetails

-- Compute fragmentation information for all full-text indexes on the database
SELECT c.fulltext_catalog_id, c.name AS fulltext_catalog_name, i.change_tracking_state,
    i.object_id, OBJECT_SCHEMA_NAME(i.object_id) + '.' + OBJECT_NAME(i.object_id) AS object_name,
    f.num_fragments, f.fulltext_mb, f.largest_fragment_mb,
    100.0 * (f.fulltext_mb - f.largest_fragment_mb) / NULLIF(f.fulltext_mb, 0) AS fulltext_fragmentation_in_percent
INTO #fulltextFragmentationDetails
FROM sys.fulltext_catalogs c
JOIN sys.fulltext_indexes i
    ON i.fulltext_catalog_id = c.fulltext_catalog_id
JOIN (
    -- Compute fragment data for each table with a full-text index
    SELECT table_id,
        COUNT(*) AS num_fragments,
        CONVERT(DECIMAL(9,2), SUM(data_size/(1024.*1024.))) AS fulltext_mb,
        CONVERT(DECIMAL(9,2), MAX(data_size/(1024.*1024.))) AS largest_fragment_mb
    FROM sys.fulltext_index_fragments
    GROUP BY table_id
) f
    ON f.table_id = i.object_id

-- Apply a basic heuristic to determine any full-text indexes that are "too fragmented"
-- We have chosen the 10% threshold based on performance benchmarking on our own data
-- Our over-night maintenance will then drop and re-create any such indexes
SELECT *
FROM #fulltextFragmentationDetails
WHERE fulltext_fragmentation_in_percent >= 10
    AND fulltext_mb >= 1 -- No need to bother with indexes of trivial size
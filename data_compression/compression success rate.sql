-- https://www.sqlskills.com/blogs/paul/the-curious-case-of-tracking-page-compression-success-rates/

SELECT
    DISTINCT object_name (i.object_id) AS [Table],
    i.name AS [Index],
    p.partition_number AS [Partition],
    page_compression_attempt_count,
    page_compression_success_count,
    page_compression_success_count * 1.0 / page_compression_attempt_count
        AS [SuccessRate]
FROM
    sys.indexes AS i
INNER JOIN
    sys.partitions AS p
ON
    p.object_id = i.object_id
CROSS APPLY
    sys.dm_db_index_operational_stats (
        db_id(), i.object_id, i.index_id, p.partition_number) AS ios
WHERE
    p.data_compression = 2
    AND page_compression_attempt_count > 0
ORDER BY
    [SuccessRate];
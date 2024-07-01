USE msdb
GO

SELECT TOP(10)
      o.[object_id]
    , obj = SCHEMA_NAME(o.[schema_id]) + '.' + o.name
    , o.[type]
    , i.total_rows
    , i.total_size
FROM sys.objects o
JOIN (
    SELECT
          i.[object_id]
        , total_size = CAST(SUM(a.total_pages) * 8. / 1024 AS DECIMAL(18,2))
        , total_rows = SUM(CASE WHEN i.index_id IN (0, 1) AND a.[type] = 1 THEN p.[rows] END)
    FROM sys.indexes i
    JOIN sys.partitions p ON i.[object_id] = p.[object_id] AND i.index_id = p.index_id
    JOIN sys.allocation_units a ON p.[partition_id] = a.container_id
    WHERE i.is_disabled = 0
        AND i.is_hypothetical = 0
    GROUP BY i.[object_id]
) i ON o.[object_id] = i.[object_id]
WHERE o.[type] IN ('V', 'U', 'S')
ORDER BY i.total_size DESC
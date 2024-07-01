--use pegasus2008ms
go

SELECT
    t.NAME AS TableName,
    s.Name AS SchemaName,
    p.rows AS RowCounts,
    SUM(a.total_pages) * 8 / 1024 AS TotalSpaceMB,
    SUM(a.used_pages) * 8 / 1024 AS UsedSpaceMB,
    (SUM(a.total_pages) - SUM(a.used_pages)) * 8 / 1024 AS UnusedSpaceMB
FROM
    sys.tables t
INNER JOIN
    sys.indexes i ON t.OBJECT_ID = i.object_id
INNER JOIN
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN
    sys.allocation_units a ON p.partition_id = a.container_id
LEFT OUTER JOIN
    sys.schemas s ON t.schema_id = s.schema_id
WHERE
    t.NAME NOT LIKE 'dt%'
	-- им€ таблицы
	--AND t.name='_AccumRg36624'
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255
GROUP BY
    t.Name, s.Name, p.Rows
ORDER BY
    --p.rows DESC --Uncomment to order by amount rows instead of size in KB.
    SUM(a.total_pages) DESC
	
-- [dbo].[_InfoRg50036] –егистр—ведений.Ѕуферна€“аблицаЋогов 62GB  всего 271
-- [dbo].[_InfoRg41385] –егистр—ведений.Ћог–аботы—о¬нешними—истемами 52 505GB
-- [dbo].[_InfoRg25830] –егистр—ведений.рсжBCP_–егистраци€ќбъектовќбмена 29 35GB
-- [dbo].[_InfoRg47551] –егистр—ведений.MQ_—ообщени€ƒл€ќтправки 25GB

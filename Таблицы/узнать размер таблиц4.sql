-- use pegasus2008mh
SELECT 
	--v.VIEW_NAME as [1CObject],
    t.NAME AS TableName,
    s.Name AS SchemaName,

    p.rows,
  --  SUM(a.total_pages) * 8 AS TotalSpaceKB, 
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS TotalSpaceMB,
    --SUM(a.used_pages) * 8 AS UsedSpaceKB, 
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS NUMERIC(36, 2)) AS UsedSpaceMB, 
    --(SUM(a.total_pages) - SUM(a.used_pages)) * 8 AS UnusedSpaceKB,
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS NUMERIC(36, 2)) AS UnusedSpaceMB
	  ,p.partition_id,
  a.container_id
  ,p.OBJECT_ID
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
 -- получаем имена 1С обьектов
-- LEFT JOIN INFORMATION_SCHEMA.VIEW_TABLE_USAGE as v ON t.NAME = v.TABLE_NAME 
WHERE 
    t.NAME NOT LIKE 'dt%' 
    AND t.is_ms_shipped = 0
    AND i.OBJECT_ID > 255 
	AND t.NAME = 'event_messages'
GROUP BY 
    --v.VIEW_NAME,
	t.Name, s.Name, p.Rows
	 ,p.partition_id,
     a.container_id
	  ,p.OBJECT_ID
ORDER BY 
    TotalSpaceMB DESC--, t.Name

--	_InfoRg50240
49 735 686
--	USE Pegasus2008MS
--go
--select * from INFORMATION_SCHEMA.VIEW_TABLE_USAGE WHERE TABLE_NAME = '_InfoRg50240' 

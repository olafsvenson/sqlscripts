SELECT object_schema_name(sys.tables.object_id)+'.'+object_name(sys.tables.object_id),
CASE WHEN sys.indexes.object_id IS null THEN 'clustered' ELSE 'Heap' end
 FROM sys.tables
LEFT OUTER JOIN 
 sys.indexes
ON sys.indexes.object_id=sys.tables.object_id
and sys.indexes.type=0
where  object_schema_name(sys.tables.object_id) <>'sys'


SELECT SCHEMA_NAME(o.schema_id) AS [schema],object_name(i.object_id ) AS [table],p.rows 
--INTO #t
FROM sys.indexes i
  INNER JOIN sys.objects o ON i.object_id = o.object_id
	INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
	  LEFT OUTER JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id
WHERE i.type_desc = 'HEAP'
order by p.rows DESC



SELECT * FROM #t

SELECT [table],[rows]
FROM #t
GROUP BY [table],[rows]
ORDER BY [rows] DESC
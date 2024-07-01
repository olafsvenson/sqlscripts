-- Переделанный мною вариант от Критика
SELECT 
       DatbaseName = DB_NAME(),
       TableName = OBJECT_NAME(s.[object_id]),
       IndexName = i.name,
       i.type_desc,
       [Fragmentation %] = ROUND(avg_fragmentation_in_percent,2),
       page_count,
	   record_count AS [RecordCount],
	   i.allow_row_locks,
	   i.allow_page_locks,
	   i.is_disabled,
	   'alter index [' + i.name + '] on [' + sh.name + '].['+ OBJECT_NAME(s.[object_id]) + '] REBUILD  with (SORT_IN_TEMPDB = ON, ONLINE = ON, DATA_COMPRESSION = PAGE, allow_page_locks=off)' AS [Query]
  FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, 'SAMPLED') s
  INNER JOIN sys.indexes as i ON s.[object_id] = i.[object_id] AND
                                 s.index_id = i.index_id
  left join sys.partition_schemes as p on i.data_space_id = p.data_space_id
  left join sys.objects o on  s.[object_id] = o.[object_id]
  left join sys.schemas as sh on sh.[schema_id] = o.[schema_id]
  WHERE s.database_id = DB_ID() AND
        i.name IS NOT NULL 
        --OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0 
       -- and        avg_fragmentation_in_percent > 25
		--AND i.type = 1 -- NONCLUSTERED
		--AND page_count > 2000 --AND page_count < 2000
		--AND record_count > 500000
		--AND page_count >  2000
         and OBJECT_NAME(s.[object_id])='operation'
  ORDER BY [Fragmentation %] DESC,page_count DESC



  /*
ALTER TABLE [Document] SET (LOCK_ESCALATION = DISABLE)
ALTER INDEX ALL ON [Document] SET (ALLOW_PAGE_LOCKS = OFF)

  SELECT s.name AS schemaname, 
       OBJECT_NAME(t.object_id) AS table_name, 
       t.lock_escalation_desc
FROM sys.tables t, 
     sys.schemas s
WHERE OBJECT_NAME(t.object_id) IN('_InfoRg40715')
AND s.name = 'dbo'
AND s.schema_id = t.schema_id;

  */
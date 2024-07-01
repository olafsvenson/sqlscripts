 --use pegasus2008
 GO

SELECT TOP 100--s.name AS SchemaName, 
		--v.VIEW_NAME as [1CObject],
       OBJECT_NAME(o.OBJECT_ID) AS TableName, 
       ISNULL(i.name, 'HEAP') AS IndexName,
       CASE i.[type]
           WHEN 0 THEN 'HEAP'
           WHEN 1 THEN 'Clustered'
           WHEN 2 THEN 'NonClustered'
           WHEN 3 THEN 'XML'
           WHEN 4 THEN 'Spatial'
       END AS IndexType,
       CASE
           WHEN i.data_space_id > 65600
           THEN ps.name
           ELSE f.name
       END AS FG_or_PartitionName, 
       p.[rows] AS [RowCnt], 
       p.data_compression_desc AS CompressionType, 
       au.type_desc AS AllocType, 
       au.total_pages / 128 AS TotalMBs, 
       au.used_pages / 128 AS UsedMBs, 
       au.data_pages / 128 AS DataMBs,
	   'ALTER INDEX '+quotename(i.name)+' on '+ quotename(OBJECT_NAME(o.OBJECT_ID))+
	   						  + ' REBUILD with (SORT_IN_TEMPDB = ON, online = '+ CASE
							when SERVERPROPERTY('EngineEdition') = 3 then 'ON'
							ELSE 'OFF'
							END +', data_compression = page, allow_page_locks = off);' AS [compress_sql]

FROM sys.indexes i
     LEFT OUTER JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
     LEFT OUTER JOIN sys.filegroups f ON i.data_space_id = f.data_space_id
     INNER JOIN sys.objects o ON i.object_id = o.object_id
     INNER JOIN sys.partitions p ON i.object_id = p.object_id
                                    AND i.index_id = p.index_id
     INNER JOIN sys.schemas s ON o.schema_id = s.schema_id
     INNER JOIN sys.allocation_units au ON CASE
                                               WHEN au.[type] IN(1, 3) THEN p.hobt_id
                                               WHEN au.[type] = 2 THEN p.partition_id
                                           END = au.container_id
										    -- получаем имена 1С обьектов
 --LEFT JOIN INFORMATION_SCHEMA.VIEW_TABLE_USAGE as v ON OBJECT_NAME(o.OBJECT_ID) = v.TABLE_NAME 
WHERE o.is_ms_shipped <> 1
     -- AND OBJECT_NAME(o.object_id) in( '_Reference255')
	 --and p.[rows] BETWEEN 1000000 AND 20000000
	 -- nonclustered
	AND i.[type]=2
	 -- без компрессии
	 AND p.data_compression_desc = 'NONE'
	 AND (au.total_pages / 128) > 0 --TotalMBs > 0
ORDER BY  
		TotalMBs DESC, 
		OBJECT_NAME(o.OBJECT_ID);
		
		--ALTER INDEX [NCIX_tt_sqlhandle] on [awr].[blk_handle_collect] REBUILD with (SORT_IN_TEMPDB = ON, online = ON, data_compression = page, allow_page_locks = off);
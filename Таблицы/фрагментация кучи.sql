SELECT
    OBJECT_NAME(ps.object_id) as TableName,
    i.name as IndexName,
    ps.index_type_desc,
    ps.record_count,
	ps.page_count,
    ps.avg_fragmentation_in_percent,
    ps.forwarded_record_count
FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, 'DETAILED') AS ps
INNER JOIN sys.indexes AS i
    ON ps.object_id = i.object_id 
    AND ps.index_id = i.index_id
WHERE  forwarded_record_count > 0
ORDER BY 
		ps.forwarded_record_count desc, 
		ps.avg_fragmentation_in_percent desc,
		ps.record_count DESC


		---
		SELECT SCHEMA_NAME(o.schema_id) AS [schema],object_name(i.object_id ) AS [table],p.rows 
		FROM sys.indexes i
		  INNER JOIN sys.objects o ON i.object_id = o.object_id
			INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
				  LEFT OUTER JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id

    WHERE i.type_desc = 'HEAP'

  ORDER BY rows DESC

	--ALTER TABLE IncomingDocumentBase REBUILD WITH (online=on)
	-- 05:23
/*
		IncomingDocumentSpecDepoBase
		OutcomingDocumentBase
		SettlementAccount
		CheckingAccountStatment
		OutcomingDocumentSpecDepoBase
		CompareBase
		RegScheduledTaskLog
		OutcomingDocumentDepoBase
		OutcomingDocumentSpecRegistratorBase
*/


/* ќбщее кол-во таблиц
SELECT COUNT(*)
	FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
*/
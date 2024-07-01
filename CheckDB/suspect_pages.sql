/*
1 = An 823 error that causes a suspect page (such as a disk error) or an 824 error other than a bad checksum or a torn page (such as a bad page ID).
2 = Bad checksum.
3 = Torn page.
4 = Restored (page was restored after it was marked bad).
5 = Repaired (DBCC repaired the page).
7 = Deallocated by DBCC.
*/
SELECT 
	--[ServerName],
	DB_Name([database_id]) as [DB],
	[database_id],
	[file_id],
	[page_id],
	CASE
		WHEN event_type = 1 THEN N'Suspect page'
		WHEN event_type = 2 THEN N'Bad checksum'
		WHEN event_type = 3 THEN N'Torn page'
	END AS [event_desc],
	error_count,
	last_update_date
FROM msdb..suspect_pages  
   WHERE (event_type = 1 OR event_type = 2 OR event_type = 3)
   order by last_update_date desc
GO

DBCC TRACEON (3604);
DBCC PAGE (15, 1, 988717, 0);
DBCC TRACEOFF (3604);
GO


select OBJECT_NAME(1231343451)

SELECT DB_NAME(susp.database_id) DatabaseName,
OBJECT_SCHEMA_NAME(ind.object_id, ind.database_id) ObjectSchemaName,
OBJECT_NAME(ind.object_id, ind.database_id) ObjectName, 
	CASE
		WHEN event_type = 1 THEN N'Suspect page'
		WHEN event_type = 2 THEN N'Bad checksum'
		WHEN event_type = 3 THEN N'Torn page'
	END AS [event_desc],
*
FROM msdb.dbo.suspect_pages susp
CROSS APPLY SYS.DM_DB_DATABASE_PAGE_ALLOCATIONS(susp.database_id,null,null,null,null) ind
WHERE allocated_page_file_id = susp.file_id
AND allocated_page_page_id = susp.page_id
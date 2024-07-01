/*
 USE Pegasus2008MS
 USE Pegasus2008BB
*/

SELECT TOP 30
	OBJECT_NAME(s.[object_id]) AS [Table Name], 
	u.View_Name AS [1cName],
	i.name AS [Index Name],
	i.type_desc,
	p.data_compression_desc AS [compression],
	i.is_unique,
	user_updates AS [Total Writes], 
	user_seeks + user_scans + user_lookups AS [Total Reads],
	user_updates - (user_seeks + user_scans + user_lookups) AS [Difference],
	/*
	o.[type_desc], o.create_date, i.index_id, i.is_disabled,
	--,Drop_Query='DROP INDEX ' + i.name + ' ON ' + OBJECT_NAME(s.[object_id])  
	,Disable_Query = 'ALTER INDEX ' + i.name + ' ON ' + OBJECT_NAME(s.[object_id])  + ' Disable'
	,Enable_Query = 'ALTER INDEX ' + i.name + ' ON ' + OBJECT_NAME(s.[object_id])  + ' Rebuild with (SORT_IN_TEMPDB = ON, online = on, data_compression=page)'
	*/
	sum(p.rows) as RowCounts,
	sum(a.total_pages) as TotalPages,
	(sum(a.total_pages) * 8) / 1024 as SizeMB,
	Drop_Query='DROP INDEX ' + i.name + ' ON ' + OBJECT_NAME(s.[object_id])  
FROM sys.dm_db_index_usage_stats AS s WITH (NOLOCK)
	INNER JOIN sys.indexes AS i WITH (NOLOCK) ON s.[object_id] = i.[object_id]	AND i.index_id = s.index_id
	INNER JOIN sys.objects AS o WITH (NOLOCK) ON i.[object_id] = o.[object_id]
	INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
	INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
	LEFT JOIN INFORMATION_SCHEMA.VIEW_TABLE_USAGE u ON  u.Table_Name = OBJECT_NAME(s.[object_id])
WHERE 
	OBJECTPROPERTY(s.[object_id],'IsUserTable') = 1
	AND s.database_id = DB_ID()
--	AND user_updates > (user_seeks + user_scans + user_lookups) -- те, которые чаще обновляются, чем по ним идет поиск
--	AND (user_seeks + user_scans + user_lookups) > 0 -- индексы с нулевым поиском
	AND i.index_id > 1
	AND i.name not LIKE '%FK%' 
	and i.name NOT like 'PK%'
	--and i.is_unique = 0 -- не уникальные индексы
	and i.is_disabled = 0 -- активные индексы
	AND i.name LIKE 'IX_custom%'
	--AND OBJECT_NAME(s.[object_id]) = '_Reference91'
GROUP BY OBJECT_NAME(s.[object_id]), i.name, u.View_Name, i.type_desc,  p.data_compression_desc, i.is_unique, user_updates, 
		(user_seeks + user_scans + user_lookups),
		(user_updates - (user_seeks + user_scans + user_lookups))
ORDER BY SizeMB DESC 
		--[Difference] DESC, [Total Writes] DESC, [Total Reads] ASC 
OPTION (RECOMPILE)


/*
	https://habr.com/ru/post/271797/
*/
DECLARE @SQL NVARCHAR(MAX)
DECLARE @obj SYSNAME = '_AccumRg27066'
SELECT @SQL = 'DBCC SHOW_STATISTICS(''' + @obj + ''', ' + name + ') WITH STAT_HEADER'
FROM sys.stats
WHERE [object_id] = OBJECT_ID(@obj)
    AND stats_id < 2

EXEC sys.sp_executesql @SQL
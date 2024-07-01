/*
		Неиспользуемые индексы с высокими издержками при использовании
		
		http://msdn.microsoft.com/ru-ru/magazine/cc135978.aspx
*/

IF OBJECT_ID (N'tempdb..#TempUnusedIndexes', N'U') IS NOT NULL
	DROP TABLE #TempUnusedIndexes;	

-- Create required table structure only.
-- Note: this SQL must be the same as in the Database loop given in the following step.
SELECT TOP 1
        DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,user_updates    
        ,system_updates    
        -- Useful fields below:
        --, *
INTO #TempUnusedIndexes
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE  s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
    AND    user_seeks = 0
    AND user_scans = 0 
    AND user_lookups = 0
    AND s.[object_id] = -999  -- Dummy value to get table structure.
;

-- -Если нужно пройтись по всем базам
EXEC sp_MSForEachDB    'USE [?]; 
-- Table already exists.
INSERT INTO #TempUnusedIndexes 
SELECT TOP 10    
        DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,user_updates    
        ,system_updates    
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE  s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
    AND    user_seeks = 0
    AND user_scans = 0 
    AND user_lookups = 0
    AND i.name IS NOT NULL    -- Ignore HEAP indexes.
ORDER BY user_updates DESC
;
'
IF OBJECT_ID (N'tempdb..#t', N'U') IS NOT NULL
	DROP TABLE #t;
 
-- Если нужна только конкретная база

SELECT     
        DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,user_updates
		,user_seeks
       ,user_scans 
       ,user_lookups
        ,system_updates   
INTO 	#t	
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE  s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
    AND    user_seeks = 0
    AND user_scans = 0 
    AND user_lookups = 0
    AND i.name IS NOT NULL    -- Ignore HEAP indexes.
	--AND i.name LIKE '%custom%' -- Не используемые custom индексы
ORDER BY user_updates DESC

SELECT TOP 10 * FROM #t ORDER BY [user_updates] DESC

-- Select records.
SELECT TOP 10 * FROM #TempUnusedIndexes ORDER BY [user_updates] DESC


SELECT  DatabaseName, COUNT(*)
FROM #TempUnusedIndexes 
GROUP BY DatabaseName
ORDER BY COUNT(*) desc

SELECT  COUNT(*)
FROM #TempUnusedIndexes 
WHERE DatabaseName='UPP_SNH'






-- Tidy up.
DROP TABLE #TempUnusedIndexes

SELECT DatabaseName = DB_NAME(),
       TableName = OBJECT_NAME(s.[object_id]),
       IndexName = i.name,
       user_updates,
       system_updates,
      --'alter index [' +OBJECT_SCHEMA_NAME(i.object_id, DB_ID())+ '].['+i.name+'] ON ['+OBJECT_NAME(s.[object_id])+'] DISABLE' AS [Disable],
     -- 'exec sp_rename ''['+OBJECT_SCHEMA_NAME(i.object_id, DB_ID())+'].['+OBJECT_NAME(s.[object_id])+'].['+i.name+']'',''disable_'+i.name+''',''INDEX''' AS [RENAME],
	  'drop index ['+i.name+'] ON ['+OBJECT_NAME(s.[object_id])+']' AS [DROP]
  FROM sys.dm_db_index_usage_stats s 
  INNER JOIN sys.indexes i ON s.object_id = i.object_id AND
                              s.index_id  = i.index_id
  WHERE s.database_id = DB_ID() AND
        OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0 AND
        s.user_seeks   = 0 AND
        s.user_scans   = 0 AND
        s.user_lookups = 0 AND
        i.is_disabled  = 0 AND
        i.is_unique = 0 AND
        i.is_primary_key = 0 AND
        i.type_desc <> 'HEAP'
		AND i.name LIKE 'IX_custom%'
  ORDER BY user_updates + system_updates DESC
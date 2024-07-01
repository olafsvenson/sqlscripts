/*
	Неиспользуемые индексы
	
	http://msdn.microsoft.com/ru-ru/magazine/cc135978.aspx
*/

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

-- По всем базам.
EXEC sp_MSForEachDB    'USE [?] 
-- Table already exists.
INSERT INTO #TempUnusedIndexes 
SELECT TOP 10    
        DatabaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,user_updates    
        ,system_updates
		,Drop_Query=''DROP INDEX '' + i.name + '' ON '' + OBJECT_NAME(s.[object_id])     
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE  s.database_id = DB_ID()
    AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
    AND    user_seeks = 0
    AND user_scans = 0 
    AND user_lookups = 0
    AND i.name LIKE ''IX_%''
ORDER BY user_updates DESC

'


-- По одной базе
INSERT INTO #TempUnusedIndexes 
SELECT     
        DatabaseName = DB_NAME(s.database_id)
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,user_updates    
        ,system_updates
---INTO 		    
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE  
	--s.database_id = DB_ID()
    --AND 
	OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
    AND    user_seeks = 0
    AND user_scans = 0 
    AND user_lookups = 0
    AND i.name IS NOT NULL    -- Ignore HEAP indexes.
	AND i.name LIKE 'IX_%'
ORDER BY user_updates DESC
;




-- Select records.
SELECT * FROM #TempUnusedIndexes ORDER BY [user_updates] DESC

SELECT *,
	Drop_Query='DROP INDEX '+IndexName+' ON ' + TableName 
FROM #TempUnusedIndexes ORDER BY [user_updates] DESC


-- Tidy up.
--DROP TABLE #TempUnusedIndexes



-- статистика по индексам определенной таблицы

SELECT 
        DatabaseName = DB_NAME(s.database_id)
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,user_updates    
        ,system_updates
		,user_seeks
		,user_scans
        ,user_lookups
        -- Useful fields below:
         ,s.*
--INTO #TempUnusedIndexes
FROM   sys.dm_db_index_usage_stats s 
INNER JOIN sys.indexes i ON  s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
INNER JOIN sys.objects o ON o.object_id = i.object_id

WHERE  
	s.database_id = DB_ID()
    --AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
   AND 
   o.name = '_Reference91'
;


SELECT TOP 10  * FROM sys.indexes
SELECT TOP 10 * FROM sys.objects WHERE name ='_AccRgAT3487'
SELECT TOP 10 * FROM  sys.dm_db_index_usage_stats s 
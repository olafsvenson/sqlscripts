/*
	Базы данных и их отсутствующие индексы
	
	http://msdn.microsoft.com/ru-ru/magazine/cc135978.aspx
*/
SELECT 
    DatabaseName = DB_NAME(database_id)
    ,[Number Indexes Missing] = count(*) 
FROM sys.dm_db_missing_index_details
GROUP BY DB_NAME(database_id)
ORDER BY COUNT(*) DESC;

-----------------------
-- итоговое число отсутствующих индексов для каждой базы данных
SELECT [DatabaseName] = DB_NAME(database_id),
       [Number Indexes Missing] = count(*) 
  FROM sys.dm_db_missing_index_details
  GROUP BY DB_NAME(database_id)
  ORDER BY 2 DESC

-----------------------------------------

SELECT * FROM sys.dm_db_missing_index_details

-----------------------------------------

SELECT  TOP 10 
        [Total Cost]  = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) 
        , avg_user_impact
        , TableName = statement
        , [EqualityUsage] = equality_columns 
        , [InequalityUsage] = inequality_columns
        , [Include Cloumns] = included_columns
FROM        sys.dm_db_missing_index_groups g 
INNER JOIN    sys.dm_db_missing_index_group_stats s 
       ON s.group_handle = g.index_group_handle 
INNER JOIN    sys.dm_db_missing_index_details d 
       ON d.index_handle = g.index_handle
ORDER BY [Total Cost] DESC;


----------------------------------------


    SELECT    
      migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) AS improvement_measure,    
      'CREATE INDEX [missing_index_' + CONVERT (varchar, mig.index_group_handle) + '_' + CONVERT (varchar, mid.index_handle)    
      + '_' + LEFT (PARSENAME(mid.statement, 1), 32) + ']'   
      + ' ON ' + mid.statement    
      + ' (' + ISNULL (mid.equality_columns,'')    
        + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END    
        + ISNULL (mid.inequality_columns, '')   
      + ')'    
      + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement,    
      migs.*, mid.database_id, mid.[object_id]   
    FROM sys.dm_db_missing_index_groups mig   
    INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle   
    INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle   
    WHERE migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) > 10   
    ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC  

-----------------------------------------

-- Вариант с правильным названием индексов



IF OBJECT_ID (N'tempdb..#missing_indexes  ', N'U') IS NOT NULL
	DROP TABLE #missing_indexes  ;	

	 
 SELECT    
 
  
      'CREATE NONCLUSTERED INDEX [IX_custom_'+ LEFT (PARSENAME(mid.statement, 1), 32) 
	  +ISNULL (replace(REPLACE(replace(replace(mid.equality_columns,'[',''),']',''),',',''),' ',''),'')    
      + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN '_' ELSE '' END    
      +ISNULL ( replace(REPLACE(replace(replace(mid.inequality_columns,'[',''),']',''),',',''),' ',''),'')
	  +'_inc_' +ISNULL ( replace(REPLACE(replace(replace( LEFT(mid.included_columns, 50),'[',''),']',''),',',''),' ',''),'')
      + ']'   
      + ' ON ' + mid.statement
      + ' (' + ISNULL (mid.equality_columns,'')    
        + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END    
        + ISNULL (mid.inequality_columns, '')   
      + ')'    
      + ISNULL (' INCLUDE (' + mid.included_columns + ') /*with (online = on, maxdop = 4)*/', '') AS create_index_statement,    
	  --migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) AS improvement_measure,  
	  [Total_Cost]  = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) ,
      migs.*, mid.database_id, mid.[object_id]   
	into #missing_indexes     
FROM sys.dm_db_missing_index_groups mig   
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle   
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle   
WHERE 
		 ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) > 50000   -- Фильтруем по величине Total_Cost
		AND migs.last_user_seek >= DATEDIFF(month, GetDate(), -1) 
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC  

--SELECT * FROM #missing_indexes  WHERE create_index_statement LIKE '%_Document13084%'

---- узнаем размер таблиц

IF OBJECT_ID (N'tempdb..#tables_size', N'U') IS NOT NULL
	DROP TABLE #tables_size;	

create table #tables_size
(
    name varchar(500),
    rows bigint,
    reserved varchar(50),
    data varchar(50),
    index_size varchar(50),
    unused varchar(50)
)



declare @t_name varchar(500)
DECLARE t_cursor CURSOR
    FOR select name from sysobjects where xtype = 'U' AND id IN (select DISTINCT object_id FROM #missing_indexes)  order by name -- выбираем только те объекты для которых нет индексов
OPEN t_cursor
FETCH NEXT FROM t_cursor INTO @t_name;

WHILE @@FETCH_STATUS = 0
BEGIN
    insert into #tables_size exec sp_spaceused @t_name
    FETCH NEXT FROM t_cursor INTO @t_name;
END
CLOSE t_cursor;
DEALLOCATE t_cursor;
----   


-- просмотр
SELECT 
	s.name,
	rows,
	create_index_statement,
	unique_compiles,
	user_seeks,
	avg_total_user_cost,
	avg_user_impact,
	[Total_Cost],
	--[Count_Custom_Indexes] = (SELECT COUNT(*) FROM sys.indexes WHERE object_id = i.object_id AND name LIKE '%custom%')
	i.object_id
FROM #missing_indexes  i
	LEFT JOIN #tables_size s
		ON OBJECT_NAME(object_id) = s.name
WHERE 
		database_id = DB_ID()  -- buh2_0
		--AND create_index_statement LIKE '%_InfoRg13589%'
		--AND user_seeks > 1000
		--AND [Total_Cost] > 100000
		--AND rows > 1000000
GROUP BY object_id,create_index_statement,s.name,rows,unique_compiles,user_seeks,avg_total_user_cost,avg_user_impact,[Total_Cost]
ORDER BY 
		--[rows] desc, 
		 name,
		-- LEN(create_index_statement) desc,
		 --avg_user_impact DESC,
		[Total_Cost] desc
		       


--

/*
-- просмотр    
select 
	create_index_statement, 
	DB_NAME(database_id) AS [DB_name],
	OBJECT_NAME([object_id]) AS [Table_name],
	--AVG(avg_user_impact) AS [avg_user_impact],
	[avg_user_impact] = (SELECT MAX(avg_user_impact) FROM #t WHERE create_index_statement = t.create_index_statement),
	COUNT(*) AS [count]
	
INTO #t2
from #t t
WHERE 
		--create_index_statement LIKE '' AND 
		DB_NAME(database_id) ='buh2_0'
group by create_index_statement, DB_NAME(database_id),OBJECT_NAME([object_id])
order by [avg_user_impact] desc    



SELECT TOP 100 * 
INTO master..__new_indexes_list
FROM #t2


SELECT 
	
		l.create_index_statement,
		[DB_NAME],
		[Table_name],
		[avg_user_impact],
		s.rows

--MAX(LEN(create_index_statement))
FROM master..__new_indexes_list l
	left JOIN master..__tables_size s
ON l.table_NAME = s.NAME
--WHERE Table_name='_AccRgAT3487' AND LEN(create_index_statement) = 654
ORDER BY rows desc

CREATE CLUSTERED INDEX CI_tableName ON  master..__new_indexes_list(table_name)
CREATE CLUSTERED INDEX CI_tableName ON  master..__tables_size(name)


SELECT * FROM master..__new_indexes_list
SELECT * FROM master..__tables_size

SELECT * FROM sysindexes


SELECT COUNT(*) FROM _AccumRg13931  with (nolock) 

-- список баз для которых не хватает индексов
SELECT 
	DB_NAME(database_id) AS [Db_name],
	COUNT(1) AS [Count]
FROM #missing_indexes
GROUP BY DB_NAME(database_id)



SELECT TOP 100 * FROM #t
WHERE create_index_statement LIKE '%_InfoRg13589%'

CREATE INDEX [IX__Document2399_inc__Marked] ON [URBAN_UPN].[dbo].[_Document2399] ([_Marked]) with (online = on, maxdop = 4) INCLUDE ([_IDRRef], [_Fld2421RRef])



SELECT *
FROM #t2
GROUP BY [db_name], [table_name]
HAVING MAX(LEN(create_index_statement))


CREATE INDEX [IX_custom__Document13414_inc__Fld14807] ON [buh2_0].[dbo].[_Document13414] ([_Fld14807])  INCLUDE ([_IDRRef], [_Fld13432RRef], [_Fld17841RRef]) with ( maxdop = 4)


CREATE INDEX [IX_custom__AccRgED489_inc__Correspond_Value_TYPE_Value_RTRef_Value_RRRef__Period] ON [buh2_0].[dbo].[_AccRgED489] ([_Correspond], [_Value_TYPE], [_Value_RTRef], [_Value_RRRef],[_Period]) with (online = on, maxdop = 4) INCLUDE ([_RecorderTRef], [_RecorderRRef], [_LineNo])
*/
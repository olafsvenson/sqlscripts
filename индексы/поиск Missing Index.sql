/*
	Ñîçäàíèå missing index óäîëåòâîðÿþùèõ ðàçëè÷íûì óñëîâèÿì

*/
--use pegasus2008ms


go

IF OBJECT_ID (N'tempdb..#missing_indexes  ', N'U') IS NOT NULL
	DROP TABLE #missing_indexes  ;	


-- ÇÀÏÐÎÑ  ¹1 - ÔÎÐÌÈÐÓÅÌ ÑÏÈÑÎÊ ÎÒÑÓÒÑÒÂÓÞÙÈÕ ÈÍÄÅÊÑÎÂ
	 
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
      + ISNULL (' INCLUDE (' + mid.included_columns + ')', '')
	  + ' with (SORT_IN_TEMPDB = ON, online = on /*, maxdop = 4 ,  data_compression=page*/)' AS create_index_statement,    
	  --migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) AS improvement_measure,  
	  [Total_Cost]  = ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) ,
      migs.*, mid.database_id, mid.[object_id]   
into #missing_indexes     
FROM sys.dm_db_missing_index_groups mig   
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle   
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle   
WHERE 
		ROUND(avg_total_user_cost * avg_user_impact * (user_seeks + user_scans),0) > 50000   -- Ôèëüòðóåì ïî âåëè÷èíå Total_Cost
		AND migs.last_user_seek >= DATEDIFF(month, GetDate(), -1)							 -- Ïîñëåäíèé Seek áûë íå ïîçæå ìåñÿöà
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC  

--delete FROM #missing_indexes  WHERE create_index_statement LIKE '%_AccumRgT14726%'






-- ÇÀÏÐÎÑ ¹2 - ÓÇÍÀÅÌ ÐÀÇÌÅÐ ÄËß ÒÀÁËÈÖ ÈÇ ÏÐÅÄ. ÇÀÏÐÎÑÀ

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
    FOR select name from sysobjects where xtype = 'U' AND id IN (select DISTINCT object_id FROM #missing_indexes)  order by name -- âûáèðàåì òîëüêî òå îáúåêòû äëÿ êîòîðûõ íåò èíäåêñîâ
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


--  ÇÀÏÐÎÑ ¹3 - ÏÎËÓ×ÀÅÌ ÑÏÈÑÎÊ ÈÍÄÅÊÑÎÂ + SQL ÑÊÐÈÏÒ ÄËß ÑÎÇÄÀÍÈß
SELECT 
	s.name,
	rows,
	create_index_statement,
	unique_compiles,
	user_seeks,
	avg_total_user_cost,
	avg_user_impact,
	[Total_Cost],
	[Count_Custom_Indexes] = (SELECT COUNT(*) FROM sys.indexes WHERE object_id = i.object_id AND name LIKE '%custom%')
FROM #missing_indexes  i
	LEFT JOIN #tables_size s
		ON OBJECT_NAME(object_id) = s.name
WHERE 
		database_id = DB_ID()  -- buh2_0
		--and s.name='_Document573'
		--AND avg_user_impact> 60
		--AND rows BETWEEN 30000000 AND 40000000
		--AND ((SELECT COUNT(*) FROM sys.indexes WHERE object_id = i.object_id AND name LIKE '%custom%')) < 3
GROUP BY object_id,create_index_statement,s.name,rows,unique_compiles,user_seeks,avg_total_user_cost,avg_user_impact,[Total_Cost]
ORDER BY 
		 
		 [rows] desc,
		 name,
		 [Total_Cost] desc
		       
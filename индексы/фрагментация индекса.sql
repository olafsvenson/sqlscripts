/*
	Логически фрагментированные индексы
	
	http://msdn.microsoft.com/ru-ru/magazine/cc135978.aspx
*/

RETURN;

-- Create required table structure only.
-- Note: this SQL must be the same as in the Database loop given in the -- following step.
SELECT TOP 1 
        DatbaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,[Fragmentation %] = ROUND(avg_fragmentation_in_percent,2)
INTO #TempFragmentation
FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) s
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE s.[object_id] = -999  -- Dummy value just to get table structure.
;

declare @cmd1 varchar(500)
declare @cmd2 varchar(500)
declare @cmd3 varchar(500)

set @cmd1 ='print ''*** Processing DB [?] ***'''



-- Loop around all the databases on the server.
EXEC sp_MSForEachDB @command1= ' 


IF (''?'' NOT in (''master'',''model'',''msdb'', ''tempdb'',''Kadri'',''ZakazStroi'',''MetallSouzStroi'',''2003'',''Arsten'',''Arsten1'',''Arsten2004'',''BizPartner2004'',''BPartner'',''BuchUraniya'',''Buh'',''itilium'',''Zero'',''Exchange'',''Buhservis'',''Buhusn'',''BuhUtetTest'',''ConversAero'',''ConversAero2004'',''convert'',''DDS_F''
,''DDSsql'',''Delta'',''DIDIN'',''Dolgin'',''Expert2004'',''FondProgmatika'',''Forten'',''InterMet'',''Intermet2004'',''kadri2'',''KadriUpdate'',''Kantina'',''Karlova'',''KomplektStroi'',''Konv2003'',''Metex'',''Metex2004'',''Metka'',
''Milina2004'',''Next'',''Next_For_Test'',''NEXT_S'',''Next2'',''NextUnion'',''NiCrom'',''NPK'',''NPP'',''NppSouz2004'',''Octava'',''OctavaSNH'',''Konvers'',''Omega'',''Otdelka'',''Partner'',''Perspectiva'',''ProdRegServ'',''Proekti'',''promeks'',
''BlackList_sql'',''trade'',''avtomoika'',''Buh2_0s'',''URBAN_UPN'',''buh20120903'',''kazna_l'',''Roznica'',''Urban_UPN_test'',''urist_pr'',''Zero_SMS2011'',''Incidents'',''estaff'',''HiGate2010'',''EZSM_Dubovik'',
''UAT'',''citrix_urbangroup'',''novabrick_rtb_os'',''Documents'',''HiGate''))
begin

use ?
print ''*** Processing DB [?] ***''

-- Table already exists.
INSERT INTO #TempFragmentation 
SELECT TOP 10
        DatbaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,[Fragmentation %] = ROUND(avg_fragmentation_in_percent,2)
FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) s
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE s.database_id = DB_ID() 
	    AND i.name IS NOT NULL    -- Ignore HEAP indexes.
    AND OBJECTPROPERTY(s.[object_id], ''IsMsShipped'') = 0
ORDER BY [Fragmentation %] DESC
end
;
'

DROP TABLE #TempFragmentation 
DROP TABLE #T

-- Table already exists.
SELECT 
        DatbaseName = DB_NAME()
        ,TableName = OBJECT_NAME(s.[object_id])
        ,IndexName = i.name
        ,[Fragmentation %] = ROUND(avg_fragmentation_in_percent,2)
INTO #TempFragmentation 
FROM sys.dm_db_index_physical_stats(db_id(),null, null, null, null) s
INNER JOIN sys.indexes i ON s.[object_id] = i.[object_id] 
    AND s.index_id = i.index_id 
WHERE s.database_id = DB_ID() 
	    AND i.name IS NOT NULL    -- Ignore HEAP indexes.
    AND OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
ORDER BY [Fragmentation %] DESC



SELECT * 
FROM #TempFragmentation
WHERE [Fragmentation %] > 10

-- Select records.
SELECT 
		datbasename,
		tablename,
		COUNT(*) AS c
INTO #t
FROM #TempFragmentation 
WHERE [Fragmentation %] > 20
GROUP BY datbasename,tablename
ORDER BY COUNT(*) DESC

SELECT  
		datbasename,
		SUM(c) AS 'Count'
FROM #t
GROUP BY datbasename
ORDER BY SUM(c) DESC

-- Tidy up.
--DROP TABLE #TempFragmentation



-- Переделанный мною вариант от Критика

DROP TABLE #tt
use Pegasus2008

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
         and OBJECT_NAME(s.[object_id])='Document'
  ORDER BY [Fragmentation %] DESC,page_count DESC

  --alter index [clust] on [dbo].[sysjobhistory] REBUILD with(online=on/*,maxdop=4*/)
  
  select object_id('[sbrf].[Notification]')


  SELECT COUNT(*) FROM #tt WHERE   [Fragmentation %] > 25
  
  SELECT * FROM sys.indexes



  --- Еще один вариант

      SELECT '
    ALTER INDEX [' + i.name + N'] ON [' + SCHEMA_NAME(o.[schema_id]) + '].[' + o.name + '] ' +
        CASE WHEN s.avg_fragmentation_in_percent > 30
            THEN 'REBUILD WITH (SORT_IN_TEMPDB = ON'
                -- Enterprise, Developer
                + CASE WHEN SERVERPROPERTY('EditionID') IN (1804890536, -2117995310)
                        THEN ', ONLINE = ON'
                        ELSE ''
                  END + ')'
            ELSE 'REORGANIZE'
        END + ';'
    FROM (
        SELECT 
              s.[object_id]
            , s.index_id
            , avg_fragmentation_in_percent = MAX(s.avg_fragmentation_in_percent)
        FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'DETAILED') s
        WHERE s.page_count > 128 -- > 1 MB
            AND s.index_id > 0 -- <> HEAP
            AND s.avg_fragmentation_in_percent > 5
        GROUP BY s.[object_id], s.index_id
    ) s
    JOIN sys.indexes i WITH(NOLOCK) ON s.[object_id] = i.[object_id] AND s.index_id = i.index_id
    JOIN sys.objects o WITH(NOLOCK) ON o.[object_id] = s.[object_id]
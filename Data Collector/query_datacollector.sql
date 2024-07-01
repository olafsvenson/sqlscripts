/*
select  top 10 *  FROM [DataCollector].[custom_snapshots].[dm_exec_query_stats] dm
CROSS APPLY sys.dm_exec_sql_text(dm.sql_handle)
*/

--select distinct snapshot_id from [DataCollector].[custom_snapshots].[dm_exec_query_stats]

  SELECT TOP 10 
 [Execution count] = execution_count
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)
,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
,snapshot_id
FROM [DataCollector].[custom_snapshots].[dm_exec_query_stats] qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
where snapshot_id=125026
ORDER BY [Execution count] DESC

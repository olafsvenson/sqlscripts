/*
	Наиболее часто выполняемые запросы
	
	http://msdn.microsoft.com/ru-ru/magazine/cc135978.aspx
	
*/

SELECT TOP 50
 [Execution count] = execution_count
,[Individual Query] = SUBSTRING (qt.text,qs.statement_start_offset/2, 
         (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(max), qt.text)) * 2 
          ELSE qs.statement_end_offset END - qs.statement_start_offset)/2)
,QueryPlan_XML = (SELECT query_plan FROM sys.dm_exec_query_plan(qs.plan_handle)) 
,[Parent Query] = qt.text
,DatabaseName = DB_NAME(qt.dbid)
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as qt
ORDER BY [Execution count] DESC;


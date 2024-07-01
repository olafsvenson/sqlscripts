/*
	http://www.keepitsimpleandfast.com/2011/11/how-to-find-table-scans-in-your.html
*/
SELECT TOP 50 st.text AS [SQL], cp.cacheobjtype, cp.objtype, 
   DB_NAME(st.dbid)AS [DatabaseName], cp.usecounts AS [Plan usage] , qp.query_plan 
FROM sys.dm_exec_cached_plans cp 
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st 
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp 
WHERE CAST(qp.query_plan AS NVARCHAR(MAX)) LIKE ('%Tablescan%')
ORDER BY usecounts DESC 
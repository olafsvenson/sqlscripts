/*
   запросы ожидающие освобождение памяти
*/

SELECT 
 es.session_id AS SPID
,es.login_name
,es.host_name
,es.program_name, es.status AS Session_Status
,mg.requested_memory_kb
,DATEDIFF(mi, mg.request_time, GETDATE()) AS [WaitingSince-InMins]
FROM sys.dm_exec_query_memory_grants mg
JOIN sys.dm_exec_sessions es
  ON es.session_id = mg.session_id
WHERE mg.grant_time IS NULL
ORDER BY mg.request_time
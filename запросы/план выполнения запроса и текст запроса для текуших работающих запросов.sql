/*
   план выполнения запроса и текст запроса для текуших работающих запросов
*/

SELECT 
 er.session_id
,es.login_name
,er.request_id
,er.start_time
,QueryPlan_XML = (SELECT query_plan FROM sys.dm_exec_query_plan(er.plan_handle)) 
,SQLText = (SELECT Text FROM sys.dm_exec_sql_text(er.sql_handle))
FROM sys.dm_exec_requests er
JOIN sys.dm_exec_sessions es
  ON er.session_id = es.session_id
WHERE er.session_id >= 50
ORDER BY er.start_time ASC
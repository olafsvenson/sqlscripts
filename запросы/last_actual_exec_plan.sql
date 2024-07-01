/*
https://techcommunity.microsoft.com/t5/sql-server/what-if-the-actual-execution-plan-was-always-available-for-any/ba-p/393387
*/

DBCC TRACEON(2451, -1);

 

 

SELECT er.session_id, er.start_time, er.status, er.command, st.text,
            qp.query_plan AS cached_plan, qps.query_plan AS last_actual_exec_plan
FROM sys.dm_exec_requests AS er
OUTER APPLY sys.dm_exec_query_plan(er.plan_handle) qp
OUTER APPLY sys.dm_exec_sql_text(er.sql_handle) st
OUTER APPLY sys.dm_exec_query_plan_stats(er.plan_handle) qps
WHERE session_id > 50 AND status IN ('running', 'suspended');
GO
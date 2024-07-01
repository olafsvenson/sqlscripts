WITH XMLNAMESPACES ( 'http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p )
SELECT   top 50   OBJECT_NAME(st.objectid, st.dbid) AS ObjectName,
            cp.creation_time,
            cp.execution_count AS ExecutionCount,
            cp.plan_handle,
            st.text AS QueryText,
            qp.query_plan AS QueryPlan
FROM        sys.dm_exec_query_stats AS cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE     
--AND st.text LIKE '%FormSearchModel%'
            qp.query_plan.exist('//p:RelOp/@EstimatedExecutionMode[ .= "Batch"]') = 1
and         qp.query_plan.exist('//p:RelOp/@Parallel[ .= 1]') = 1
ORDER BY    cp.creation_time DESC;
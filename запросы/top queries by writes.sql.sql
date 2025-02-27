/*
https://gist.github.com/LitKnd/2f1dc3229604e7319fc2fa86f38745f6#file-top-queries-by-writes-sql
*/
SELECT TOP 20
 	(SELECT CAST(SUBSTRING(st.text, (qs.statement_start_offset/2)+1,   
		((CASE qs.statement_end_offset  
			WHEN -1 THEN DATALENGTH(st.text)  
			ELSE qs.statement_end_offset  
			END
		- qs.statement_start_offset)/2) + 1) AS NVARCHAR(MAX)) FOR XML PATH(''),TYPE) AS [TSQL],
    qs.execution_count AS [#],
	qs.total_logical_writes as [writes],
	CASE WHEN execution_count = 0 THEN 0 ELSE
		CAST(qs.total_logical_writes / execution_count AS numeric(30,1))
	END AS [avg logical writes],
    CAST(qs.total_worker_time/1000./1000. AS numeric(30,1)) AS [cpu sec],
	CASE WHEN execution_count = 0 THEN 0 ELSE
		CAST(qs.total_worker_time / execution_count / 1000. / 1000. AS numeric(30,1))
		END AS [avg cpu sec],
    CAST(qs.total_elapsed_time/1000./1000. AS numeric(30,1)) AS [elapsed sec],
	CASE WHEN execution_count = 0 THEN 0 ELSE
		CAST(qs.total_elapsed_time / execution_count / 1000. / 1000. AS numeric(30,1))
		END AS [avg elapsed sec],
    qs.total_logical_reads as [logical reads],
	CASE WHEN execution_count = 0 THEN 0 ELSE
		CAST(qs.total_logical_reads / execution_count AS numeric(30,1))
	END AS [avg logical reads],
    qp.query_plan AS [query execution plan]
FROM sys.dm_exec_query_stats AS qs
OUTER APPLY sys.dm_exec_sql_text (plan_handle) as st
OUTER APPLY sys.dm_exec_query_plan (plan_handle) AS qp
ORDER BY qs.total_logical_writes DESC
OPTION (RECOMPILE);
GO
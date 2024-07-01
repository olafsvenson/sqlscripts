SELECT 
IndexScanCount = ( 	SELECT count(1)
					FROM sys.dm_exec_cached_plans cp
					CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
					CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
					WHERE CAST(qp.query_plan AS NVARCHAR(MAX)) LIKE ('%Indexscan%')
				 ),
IndexSeekCount = ( SELECT count(1)
					FROM sys.dm_exec_cached_plans cp
					CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) st
					CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
					WHERE CAST(qp.query_plan AS NVARCHAR(MAX)) LIKE ('%Indexseek%')
				 )

--ORDER BY usecounts DESC

-- Scan 31895



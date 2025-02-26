SELECT TOP  20
	p.plan_handle, 
	st.text,qp.query_plan,
	[Average IO] = (qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count
FROM sys.dm_exec_cached_plans p
INNER JOIN sys.dm_exec_query_stats qs ON p.plan_handle = qs.plan_handle
CROSS APPLY sys.dm_exec_sql_text(p.plan_handle) AS st
CROSS APPLY sys.dm_exec_query_plan(p.plan_handle) AS qp
WHERE text LIKE N'%SELECT TOP 20%Document556%_Reference91%Reference217%'
ORDER BY [Average IO] DESC;

--

--DBCC FREEPROCCACHE (0xB21F65C116F48418)









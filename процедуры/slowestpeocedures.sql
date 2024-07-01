SELECT
    TOP (25) [p].[name] AS [SP Name],
    [eps].[min_elapsed_time],
    [eps].[total_elapsed_time] / [eps].[execution_count]
AS [avg_elapsed_time],
    [eps].[max_elapsed_time],
    [eps].[last_elapsed_time],
    [eps].[total_elapsed_time],
    [eps].[execution_count],
    ISNULL ([eps].[execution_count] /
		DATEDIFF (MINUTE, [eps].[cached_time], GETDATE ()), 0)
AS [Executions/Minute],
    FORMAT ([eps].[last_execution_time],
		'yyyy-MM-dd HH:mm:ss', 'en-US') AS [Last Execution Time],
    FORMAT ([eps].[cached_time],
		'yyyy-MM-dd HH:mm:ss', 'en-US') AS [Plan Cached Time]
    -- ,[qp].[query_plan] AS [Query Plan] -- Uncomment if you want the Query Plan
FROM sys.procedures AS [p] WITH (NOLOCK)
INNER JOIN sys.dm_exec_procedure_stats AS [eps] WITH (NOLOCK)
	ON [p].[object_id] = [eps].[object_id]
CROSS APPLY sys.dm_exec_query_plan ([eps]. [plan_handle]) AS [qp]
WHERE
	[eps].[database_id] = DB_ID ()
    AND DATEDIFF (MINUTE, [eps].[cached_time], GETDATE()) > 0
ORDER BY [avg_elapsed_time] DESC
OPTION (RECOMPILE);
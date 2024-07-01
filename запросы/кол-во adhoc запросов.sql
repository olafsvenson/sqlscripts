SELECT T.*, cast(T.[Total Plans - USE Count 1]*1.0/nullif(t.[Total Plans],0) *100  AS decimal(5,2)) Percentage
FROM
(
       SELECT objtype AS [CacheType]
                    , count_big(*) AS [Total Plans]
                    , sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 AS [Total MBs]
                    , sum(cast((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(18,2)))/1024/1024 AS [Total MBs - USE Count 1]
                    , sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Total Plans - USE Count 1]
       FROM sys.dm_exec_cached_plans cp
       WHERE cp.cacheobjtype = N'Compiled Plan'
       AND cp.objtype IN (N'Adhoc', N'Prepared') -- adhoc (произвольный запрос), prepared (параметризованный)
       GROUP BY objtype
) T
ORDER BY [Total MBs - USE Count 1] DESC
OPTION (RECOMPILE);  
-- Get all SQL Statements with "table scan" in cached query plan 
/*
	https://gallery.technet.microsoft.com/scriptcenter/Get-all-SQL-Statements-0622af19
*/


IF OBJECT_ID('tempdb.dbo.#PlanCacheAnalysis', 'U') IS NOT NULL
  DROP TABLE #PlanCacheAnalysis; 

CREATE TABLE #PlanCacheAnalysis (
id BIGINT IDENTITY(1,1) PRIMARY KEY
,[ExecutionCount] BIGINT NOT NULL
,[TotalWorkTime] BIGINT NOT NULL
,[TotalLogicalReads] BIGINT NOT NULL
,[TotalLogicalWrites] BIGINT NOT NULL
,[TotalElapsedTime] BIGINT NOT NULL
,[LastExecutionTime] DATETIME NULL
,[ObjectType] varchar(15) NULL
,[CacheObjectType] varchar(15) NULL
,[DatabaseName] varchar(25) NULL
,[ObjectName] varchar(500) NULL
,[Statement]  varchar(MAX) null    
,[QueryPlan] XML)


-- Get all SQL Statements with "table scan" in cached query plan
;WITH 
 XMLNAMESPACES
    (DEFAULT N'http://schemas.microsoft.com/sqlserver/2004/07/showplan'  
            ,N'http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS ShowPlan) 
,EQS AS
    (SELECT EQS.plan_handle
           ,SUM(EQS.execution_count) AS ExecutionCount
           ,SUM(EQS.total_worker_time) AS TotalWorkTime
           ,SUM(EQS.total_logical_reads) AS TotalLogicalReads
           ,SUM(EQS.total_logical_writes) AS TotalLogicalWrites
           ,SUM(EQS.total_elapsed_time) AS TotalElapsedTime
           ,MAX(EQS.last_execution_time) AS LastExecutionTime
     FROM sys.dm_exec_query_stats AS EQS
     GROUP BY EQS.plan_handle) 
INSERT INTO #PlanCacheAnalysis  
SELECT EQS.[ExecutionCount]
      ,EQS.[TotalWorkTime]
      ,EQS.[TotalLogicalReads]
      ,EQS.[TotalLogicalWrites]
      ,EQS.[TotalElapsedTime]
      ,EQS.[LastExecutionTime]
      ,ECP.[objtype] AS [ObjectType]
      ,ECP.[cacheobjtype] AS [CacheObjectType]
      ,DB_NAME(EST.[dbid]) AS [DatabaseName]
      ,OBJECT_NAME(EST.[objectid], EST.[dbid]) AS [ObjectName]
      ,EST.[text] AS [Statement]      
      ,EQP.[query_plan] AS [QueryPlan]
FROM sys.dm_exec_cached_plans AS ECP
     INNER JOIN EQS
         ON ECP.plan_handle = EQS.plan_handle     
     CROSS APPLY sys.dm_exec_sql_text(ECP.[plan_handle]) AS EST 
     CROSS APPLY sys.dm_exec_query_plan(ECP.[plan_handle]) AS EQP
WHERE EQS.[ExecutionCount] > 1  -- No Ad-Hoc queries
      AND ECP.[usecounts] > 1
ORDER BY EQS.TotalElapsedTime DESC
        ,EQS.ExecutionCount DESC;


CREATE PRIMARY XML INDEX XMLIndex ON #PlanCacheAnalysis([QueryPlan])

SELECT * FROM #PlanCacheAnalysis
WHERE queryplan.exist('declare namespace NS="http://schemas.microsoft.com/sqlserver/2004/07/showplan";data(//NS:RelOp[@PhysicalOp="Clustered Index Scan"][1])') = 1
      AND [ExecutionCount] > 1  -- No Ad-Hoc queries
ORDER BY TotalElapsedTime DESC
        ,ExecutionCount DESC;
        
        
-- DROP TABLE #PlanCacheAnalysis

--51485
SELECT count(1) FROM #PlanCacheAnalysis
WHERE [ExecutionCount] > 1

SELECT count(1) FROM #PlanCacheAnalysis
WHERE [ExecutionCount] = 1
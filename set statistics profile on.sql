-- включить 
SET STATISTICS PROFILE ON
GO

-- смотреть так
SELECT   
       node_id,
       physical_operator_name, 
       SUM(row_count) row_count, 
       SUM(estimate_row_count) AS estimate_row_count,
       CAST(SUM(row_count)*100 AS float)/SUM(estimate_row_count)  as estimate_percent_complete
FROM sys.dm_exec_query_profiles   
WHERE session_id=54  
GROUP BY node_id,physical_operator_name  
ORDER BY node_id desc;


-- второй вариант
/*
https://dba.stackexchange.com/questions/139191/sql-server-how-to-track-progress-of-create-index-command

This query has been tested against:

Creating:
NonClustered Indexes on a Heap
a Clustered Index (no NonClustered Indexes exist)
NonClustered Indexes on the Clustered Index/Table
a Clustered Index when NonClustered Indexes already exist
Unique NonClustered Indexes on the Clustered Index/Table
Rebuilding (table with Clustered Index and one NonClustered Index; tested on SQL Server 2014, 2016, 2017, and 2019) via:
ALTER TABLE [schema_name].[table_name] REBUILD; (only Clustered Index shows up when using this method)
ALTER INDEX ALL ON [schema_name].[table_name] REBUILD;
ALTER INDEX [index_name] ON [schema_name].[table_name] REBUILD;
*/
DECLARE @SPID INT = 51;

;WITH agg AS
(
     SELECT SUM(qp.[row_count]) AS [RowsProcessed],
            SUM(qp.[estimate_row_count]) AS [TotalRows],
            MAX(qp.last_active_time) - MIN(qp.first_active_time) AS [ElapsedMS],
            MAX(IIF(qp.[close_time] = 0 AND qp.[first_row_time] > 0,
                    [physical_operator_name],
                    N'<Transition>')) AS [CurrentStep]
     FROM sys.dm_exec_query_profiles qp
     WHERE qp.[physical_operator_name] IN (N'Table Scan', N'Clustered Index Scan',
                                           N'Index Scan',  N'Sort')
     AND   qp.[session_id] = @SPID
), comp AS
(
     SELECT *,
            ([TotalRows] - [RowsProcessed]) AS [RowsLeft],
            ([ElapsedMS] / 1000.0) AS [ElapsedSeconds]
     FROM   agg
)
SELECT [CurrentStep],
       [TotalRows],
       [RowsProcessed],
       [RowsLeft],
       CONVERT(DECIMAL(5, 2),
               (([RowsProcessed] * 1.0) / [TotalRows]) * 100) AS [PercentComplete],
       [ElapsedSeconds],
       (([ElapsedSeconds] / [RowsProcessed]) * [RowsLeft]) AS [EstimatedSecondsLeft],
       DATEADD(SECOND,
               (([ElapsedSeconds] / [RowsProcessed]) * [RowsLeft]),
               GETDATE()) AS [EstimatedCompletionTime]
FROM   comp;

--доработанный второй вариант
;WITH agg AS
(
     SELECT SUM(qp.[row_count]) AS [RowsProcessed],
            SUM(qp.[estimate_row_count]) AS [TotalRows],
            MAX(qp.last_active_time) - MIN(qp.first_active_time) AS [ElapsedMS],
            MAX(IIF(qp.[close_time] = 0 AND qp.[first_row_time] > 0,
                    [physical_operator_name],
                    N'<Transition>')) AS [CurrentStep]
     FROM sys.dm_exec_query_profiles qp
     WHERE qp.[physical_operator_name] IN (N'Table Scan', N'Clustered Index Scan',
                                           N'Index Scan',  N'Sort')
     AND   qp.[session_id] IN (SELECT session_id from sys.dm_exec_requests where command IN ( 'CREATE INDEX','ALTER INDEX','ALTER TABLE') )
), comp AS
(
     SELECT *,
            ([TotalRows] - [RowsProcessed]) AS [RowsLeft],
            ([ElapsedMS] / 1000.0) AS [ElapsedSeconds]
     FROM   agg
)
SELECT [CurrentStep],
       [TotalRows],
       [RowsProcessed],
       [RowsLeft],
       CONVERT(DECIMAL(5, 2),
               (([RowsProcessed] * 1.0) / [TotalRows]) * 100) AS [PercentComplete],
       [ElapsedSeconds],
       (([ElapsedSeconds] / [RowsProcessed]) * [RowsLeft]) AS [EstimatedSecondsLeft],
       DATEADD(SECOND,
               (([ElapsedSeconds] / [RowsProcessed]) * [RowsLeft]),
               GETDATE()) AS [EstimatedCompletionTime]
FROM   comp;
DECLARE @PageLookups1 BIGINT;
 
SELECT @PageLookups1 = cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Transactions/sec';
 
WAITFOR DELAY '00:00:10';
 
SELECT (cntr_value - @PageLookups1) / 10 AS 'Transactions/sec'
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Transactions/sec';


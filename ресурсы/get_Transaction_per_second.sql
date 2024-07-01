-- Measure Total Transactions on All Instances
-- First PASS
DECLARE @First INT
DECLARE @Second INT
SELECT @First = cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Transactions/sec'
-- Following is the delay
WAITFOR DELAY '00:00:01'
-- Second PASS
SELECT @Second = cntr_value
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Transactions/sec';
SELECT (@Second - @First) 'TotalTransactions'
GO


-- Instance Specific Transactions

-- First PASS
DECLARE @First INT
DECLARE @Second INT
SELECT @First = cntr_value
FROM sys.dm_os_performance_counters
WHERE
OBJECT_NAME = 'MSSQL$SQL19:Databases' AND -- Change name of your server ' AND -- Change name of your server
counter_name = 'Transactions/sec' AND
instance_name = '_Total';
-- Following is the delay
WAITFOR DELAY '00:00:10'
-- Second PASS
SELECT @Second = cntr_value
FROM sys.dm_os_performance_counters
WHERE
OBJECT_NAME = 'MSSQL$SQL19:Databases' AND -- Change name of your server
counter_name = 'Transactions/sec' AND
instance_name = '_Total';
SELECT (@Second - @First) 'TotalTransactions'
GO

-- Database Specific Transactions
-- First PASS
DECLARE @First INT
DECLARE @Second INT
SELECT @First = cntr_value
FROM sys.dm_os_performance_counters
WHERE
OBJECT_NAME = 'MSSQL$SQL19:Databases' AND -- Change name of your server ' AND -- Change name of your server
counter_name = 'Transactions/sec' AND
instance_name = 'tempdb'; -- Change name of your database
-- Following is the delay
WAITFOR DELAY '00:00:10'
-- Second PASS
SELECT @Second = cntr_value
FROM sys.dm_os_performance_counters
WHERE
OBJECT_NAME = 'MSSQL$SQL19:Databases' AND -- Change name of your server
counter_name = 'Transactions/sec' AND
instance_name = 'tempdb'; -- Change name of your database
SELECT (@Second - @First) 'TotalTransactions'
GO

-- Turn on advanced options
EXEC sp_configure 'Show Advanced Options', 1
GO
RECONFIGURE
GO

-- See what the current value is for 'optimize for ad hoc workloads'
EXEC sp_configure

-- Turn on optimize for ad hoc workloads
EXEC sp_configure 'optimize for ad hoc workloads', 1
GO
RECONFIGURE
GO

-- Finally, clear all the plans in the cache (use with caution on a Production Server)
DBCC FREEPROCCACHE
SELECT [Operation], PartitionId,count(*) as [count]
       FROM fn_dump_dblog (NULL, NULL, N'DISK', 1, N'D:\temp\Pegasus2008BB_LOG_2021-09-03_13.41.50.BAK',
       DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
       DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
       DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
       DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT,
       DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT, DEFAULT)
       WHERE Operation IN('LOP_DELETE_ROWS','LOP_INSERT_ROWS')
       GROUP BY [Operation],[PartitionId]
	   ORDER BY count(*) desc




SELECT TOP 10 * FROM sys.objects


USE pegasus2008
go

SELECT OBJECT_NAME(so.object_id), 
       u.view_name
FROM sys.objects so
     INNER JOIN sys.partitions sp ON so.object_id = sp.object_id
     INNER JOIN INFORMATION_SCHEMA.VIEW_TABLE_USAGE u ON TABLE_NAME = OBJECT_NAME(so.object_id)
WHERE partition_id = 72058027597889536


���������������.���������������������
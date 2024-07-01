/*
https://habr.com/ru/post/271797/
*/

--USE AdventureWorks2012
GO

SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

SELECT COUNT_BIG(*)
FROM Sales.SalesOrderDetail

SELECT SUM(p.[rows])
FROM sys.partitions p
WHERE p.[object_id] = OBJECT_ID('Sales.SalesOrderDetail')
    AND p.index_id < 2

SELECT SUM(s.row_count)
FROM sys.dm_db_partition_stats s
WHERE s.[object_id] = OBJECT_ID('Sales.SalesOrderDetail')
    AND s.index_id < 2
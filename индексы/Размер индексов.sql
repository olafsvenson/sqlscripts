
USE Pegasus2008
GO

DROP TABLE if exists #t

DECLARE @PageSize AS INT;
SELECT @PageSize = low / 1024.0
FROM master.dbo.spt_values
WHERE Number = 1
      AND type = 'E';
SELECT OBJECT_NAME(i.object_id) AS [TableName], 
       CONVERT(bigint, CONVERT(bigint, @PageSize * SUM(a.used_pages - CASE
                                                                                   WHEN a.type <> 1
                                                                                 THEN a.used_pages
                                                                                   WHEN p.index_id < 2
                                                                                   THEN a.data_pages
                                                                                   ELSE 0
                                                                               END)) / 1024) AS [IndexSpaceMB],---[DataSpaceMB], 
       CONVERT(bigint, CONVERT(bigint, @PageSize * SUM(CASE
                                                                           WHEN a.type <> 1
                                                                           THEN a.used_pages
                                                                           WHEN p.index_id < 2
                                                                           THEN a.data_pages
                                                                           ELSE 0
                                                                       END)) / 1024) AS [DataSpaceMB],--[IndexSpaceMB], 
       SUM(CASE
               WHEN p.index_id = 1
                    AND a.type = 1
               THEN p.rows
               ELSE 0
           END) AS [Rows]

INTO #t
FROM sys.indexes AS i
     JOIN sys.partitions AS p ON p.object_id = i.object_id
                                 AND p.index_id = i.index_id
     JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
     LEFT JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.type = 'U'
GROUP BY OBJECT_NAME(i.object_id)


SELECT TOP 100
v.VIEW_NAME as [1CObject],
[TableName],
[DataSpaceMB],
[IndexSpaceMB],
[DataSpaceMB]+[IndexSpaceMB] as  [TotalSpaceMB],
--[DataSpaceMB]/100*10 as[10PercentMB],
--[IndexSpaceMB]/iif([DataSpaceMB]<=0,1,[DataSpaceMB]) AS [greatethan],
[IndexSpaceMB] - [DataSpaceMB] AS [DiffMB],
[rows]
FROM #t t 
 -- получаем имена 1С обьектов
 LEFT JOIN INFORMATION_SCHEMA.VIEW_TABLE_USAGE as v ON t.[TableName] = v.TABLE_NAME 
--WHERE [rows]<100000000
 ORDER BY 
	[TotalSpaceMB] DESC
	--[IndexSpaceMB] - [DataSpaceMB] desc
	--[rows] desc
	


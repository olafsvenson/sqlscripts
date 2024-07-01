USE msdb
go

EXEC dbo.usp_AdaptiveIndexDefrag @Exec_Print = 0, @printCmds = 1, 


EXEC dbo.usp_AdaptiveIndexDefrag @minFragmentation = 75, @rebuildThreshold = 70, @dbScope = 'pegasus2008', @onlineRebuild = 1  ,@minPageCount = 5000,@sortInTempDB=1,@debugMode = 1, @outputResults = 1, @timeLimit = 10

EXEC dbo.usp_AdaptiveIndexDefrag @dbScope = 'Pegasus2008',@tblName ='dbo._InfoRg27060',@debugMode = 1,@onlineRebuild = 1 
--16:10

  EXEC msdb.dbo.usp_AdaptiveIndexDefrag  @dbScope = 'pegasus2008', @onlineRebuild = 1, @maxPageCount=25000, @sortInTempDB=1,@ixtypeOption=0,@onlinelocktimeout=50,@forceRescan=0@ debugMode = 1,

EXEC dbo.usp_AdaptiveIndexDefrag  @dbScope = 'pegasus2008',@debugMode = 1, @maxPageCount = 25000, @ixtypeOption=0, @timeLimit = 10

@onlineRebuild = 1,, @sortInTempDB=1,@debugMode = 1@onlinelocktimeout=50,@forceRescan=0
EXEC dbo.usp_AdaptiveIndexDefrag  @dbScope = 'pegasus2008', @onlineRebuild = 1, @minPageCount=25001,@maxPageCount=25000, @sortInTempDB=1,@debugMode = 1,@ixtypeOption=0,@onlinelocktimeout=50,@forceRescan=0 @outputResults = 1, @timeLimit = 10



EXEC dbo.usp_AdaptiveIndexDefrag @Exec_Print = 0, @printCmds = 1,@dbScope = 'sputnik',@tblName ='awr.blk_handle_collect',@debugMode = 1

SELECT DISTINCT [dbName] FROM [msdb].[dbo].[tbl_AdaptiveIndexDefrag_Working]


SELECT TOP (1000) [Comment]
      ,[dbName]
      ,[objectName]
      ,[indexName]
      ,[partitionNumber]
      ,[Avg_size_KB]
      ,[fill_factor]
  FROM [msdb].[dbo].[vw_AvgLargestLst30Days]

SELECT TOP (1000) *  FROM [msdb].[dbo].[tbl_AdaptiveIndexDefrag_Working]
ORDER BY 
		--page_count desc,
		range_scan_count desc,
		fragmentation desc


SELECT  min(page_count),mAX(page_count)
FROM [msdb].[dbo].[tbl_AdaptiveIndexDefrag_Working]

select *, FROM [msdb].[dbo].[tbl_AdaptiveIndexDefrag_Working]
WHERE page_count=4982862
		
SELECT TOP (1000) * from		[dbo].[tbl_AdaptiveIndexDefrag_Analysis_log]

USE [msdb]
GO

SELECT [dbID]
      ,[objectID]
      ,[indexID]
      ,[partitionNumber]
      ,[dbName]
      ,[schemaName]
      ,[objectName]
      ,[indexName]
      ,[fragmentation]
      ,[page_count]
	  ,[page_count]* 8 / 1024 AS SizeMB
      ,[is_primary_key]
      ,[fill_factor]
      ,[is_disabled]
      ,[is_padded]
      ,[is_hypothetical]
      ,[has_filter]
      ,[allow_page_locks]
      ,[compression_type]
      ,[range_scan_count]
      ,[record_count]
      ,[type]
      ,[scanDate]
      ,[defragDate]
      ,[printStatus]
      ,[exclusionMask]
  FROM [dbo].[tbl_AdaptiveIndexDefrag_Working]
WHERE objectid=1543604399


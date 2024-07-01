/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [dbName]
      ,[objectName]
      ,[indexName]
      ,[statsName]
      ,[partitionNumber]
      ,[fragmentation]
      ,[page_count]
      ,[range_scan_count]
      ,[dateTimeStart]
      ,[dateTimeEnd]
      ,[durationSeconds]
      ,[Operation]
      ,[errorMessage]
  FROM [msdb].[dbo].[vw_LastRun_Log]

  --SELECT getutcdate()
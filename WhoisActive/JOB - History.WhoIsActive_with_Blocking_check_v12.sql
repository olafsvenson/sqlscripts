USE [msdb]
GO

-- Поддерживает скрипт sp_whoisactive начиная с v12


IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'History.WhoIsActive')
EXEC msdb.dbo.sp_delete_job @job_name=N'History.WhoIsActive', @delete_unused_schedule=1
GO



-- при обновлении на v12

--drop table IF EXISTS [master].[dbo].[History_WhoIsActive]


/****** Object:  Job [History.WhoIsActive]    Script Date: 18.09.2023 16:42:52 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 18.09.2023 16:42:52 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'History.WhoIsActive', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Мониторинг текущих запросов  и блокировок', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [check helpers proc]    Script Date: 18.09.2023 16:42:53 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'check helpers proc', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @SQL nvarchar(max) = ''
CREATE or alter PROCEDURE [dbo].[sp_ExportTable2Html]
 @TableName [varchar](max),
 @UseStandartStyle BIT = 1,
 @Alignment VARCHAR(10) = ''''left'''',
 @OrderBy VARCHAR(MAX) = '''''''',
 @Script VARCHAR(MAX) OUTPUT
AS
BEGIN

SET NOCOUNT ON
 
 DECLARE
 @query NVARCHAR(MAX),
 @Database sysname,
 @Tabel sysname
 
 IF (LEFT(@TableName, 1) = ''''#'''')
 BEGIN
  SET @Database = ''''tempdb.''''
  SET @Tabel = @TableName
 END
 ELSE 
 BEGIN
  SET @Database = LEFT(@TableName, CHARINDEX(''''.'''', @TableName))
  SET @Tabel = SUBSTRING(@TableName, LEN(@TableName) - CHARINDEX(''''.'''', REVERSE(@TableName)) + 2, LEN(@TableName))
 END
 
 SET @query = ''''
 SELECT ORDINAL_POSITION, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE
 FROM '''' + @Database + ''''INFORMATION_SCHEMA.COLUMNS 
 WHERE TABLE_NAME = '''''''''''' + @Tabel + ''''''''''''
 ORDER BY ORDINAL_POSITION''''
 
 IF (OBJECT_ID(''''tempdb..#Columns'''') IS NOT NULL) DROP TABLE #Columns
 CREATE TABLE #Columns (
  ORDINAL_POSITION int, 
  COLUMN_NAME sysname, 
  DATA_TYPE nvarchar(128), 
  CHARACTER_MAXIMUM_LENGTH int,
  NUMERIC_PRECISION tinyint, 
  NUMERIC_SCALE int
  )
 
 INSERT INTO #Columns
 EXEC(@query)
 
 IF (@UseStandartStyle = 1)
 BEGIN
 SET @Script = ''''<html>
  <head>
  <title>Title</title>
  <style type="text/css">
  table { padding:0; border-spacing: 0; border-collapse: collapse;  }
  thead { background: #00B050; border: 1px solid #ddd; }
  th { padding: 10px; font-weight: bold; border: 1px solid #000; color: #fff;}
  tr { padding: 0; }
  td { padding: 5px; border: 1px solid #cacaca; margin:0; text-align:'''' + @Alignment + ''''; }
  </style>
  </head>''''
 END

SET @Script = ISNULL(@Script, '''''''') + ''''
 <table>
 <thead>
 <tr>''''

-- Заголовок таблицы
 DECLARE 
 @curColumns INT = 1, 
 @totalColumns INT = (SELECT COUNT(*) FROM #Columns), 
 @ColunmnName sysname,
 @ColumnType sysname

 WHILE(@curColumns <= @totalColumns)
 BEGIN
  SELECT @ColunmnName = COLUMN_NAME
  FROM #Columns
  WHERE ORDINAL_POSITION = @curColumns

  SET @Script = ISNULL(@Script, '''''''') + ''''
  <th>'''' + @ColunmnName + ''''</th>''''

  SET @curColumns = @curColumns + 1
 END

 SET @Script = ISNULL(@Script, '''''''') + ''''
 </tr>
 </thead>
 <tbody>''''

-- Содержание таблицы
DECLARE @Str VARCHAR(MAX)

 SET @query = ''''
 SELECT @Str = (
 SELECT ''''

 SET @curColumns = 1

 WHILE(@curColumns <= @totalColumns)
 BEGIN
  SELECT 
  @ColunmnName = COLUMN_NAME,
  @ColumnType = DATA_TYPE
  FROM 
  #Columns
  WHERE 
  ORDINAL_POSITION = @curColumns

 IF (@ColumnType IN (''''int'''', ''''bigint'''', ''''float'''', ''''numeric'''', ''''decimal'''', ''''bit'''', ''''tinyint'''', ''''smallint'''', ''''integer''''))
 BEGIN
  SET @query = @query + ''''
  ISNULL(CAST(['''' + @ColunmnName + ''''] AS VARCHAR(MAX)), '''''''''''''''') AS [td]''''
 END
 ELSE BEGIN
  SET @query = @query + ''''
  ISNULL(['''' + @ColunmnName + ''''], '''''''''''''''') AS [td]''''
 END

 IF (@curColumns < @totalColumns)
  SET @query = @query + '''',''''
  SET @curColumns = @curColumns + 1
 END

 SET @query = @query + ''''
 FROM '''' + @TableName + (CASE WHEN ISNULL(@OrderBy, '''''''') = '''''''' THEN '''''''' ELSE '''' 
 ORDER BY '''' END) + @OrderBy + ''''
 FOR XML RAW(''''''''tr''''''''), Elements
 )''''
 EXEC tempdb.sys.sp_executesql
 @query,
 N''''@Str NVARCHAR(MAX) OUTPUT'''',
 @Str OUTPUT

 SET @Str = REPLACE(@Str, ''''<tr>'''', ''''
 <tr>'''')
 SET @Str = REPLACE(@Str, ''''<td>'''', ''''
 <td>'''')
 SET @Str = REPLACE(@Str, ''''</tr>'''', ''''
 </tr>'''')
 SET @Script = ISNULL(@Script, '''''''') + @Str
 SET @Script = ISNULL(@Script, '''''''') + ''''
 </tbody>
 </table>''''
END

''

if not exists (select * from dbo.sysobjects where id = object_id(N''[dbo].[sp_ExportTable2Html]'') and OBJECTPROPERTY(id, N''IsProcedure'') = 1)
Exec(@SQL)
GO
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [WhoIsActive]    Script Date: 18.09.2023 16:42:53 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'WhoIsActive', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=1, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'--get output from Adam Machanic''s excellent "sp_WhoIsActive" script from http://whoisactive.com
--into logging table, should be scheduled every 30-60 seconds
--relies on sp_WhoIsActive stored proc being present in master database
--logging table hard-coded here to "WhoIsActive" table in Scratch database
--liberally borrowed from https://www.brentozar.com/archive/2016/07/logging-activity-using-sp_whoisactive-take-2/

USE [master]

SET NOCOUNT ON

DECLARE
    --number of days to retain output from sp_WhoIsActive in logging table
    @number_of_days_to_retain INT = 30,
    --logging table name (will be created if does not exist)
    @destination_table NVARCHAR(500) = N''History_WhoIsActive'',
    --logging table database (will not be created if it doesn''t exist)
    @destination_database SYSNAME = N''master'',
    --dynamic SQL, re-used
    @sql NVARCHAR(4000),
    --does the index on the logging table exist?
    @does_index_exist BIT

--prepend logging table with database and schema
SET @destination_table = @destination_database + N''.dbo.'' + @destination_table

--create the logging table if it doesn''t exist
IF OBJECT_ID(@destination_table) IS NULL BEGIN
    --get the CREATE TABLE statement to suit output from sp_WhoIsActive
    --EXEC master..sp_WhoIsActive @get_transaction_info = 1, @get_outer_command = 1, @get_plans = 1, @return_schema = 1, @format_output = 0, @get_additional_info = 1, @schema = @sql OUTPUT
 
    EXEC dbo.sp_WhoIsActive
           @get_transaction_info = 1,
            @get_outer_command = 1,
            @get_plans = 1,
            @get_task_info = 2,
            @get_additional_info = 1,
            @find_block_leaders = 1,
            @get_memory_info = 1,
           @format_output = 0,
            @return_schema = 1,
            @schema = @sql OUTPUT;

    --replace with logging table name in returned CREATE TABLE statement
    SET @sql = REPLACE(@sql, N''<table_name>'', @destination_table)
    --create the logging table by executing the CREATE TABLE statement
    EXEC(@sql)
END

--logging table exists; now check for index on collection_time column
--index on collection_time makes it easier to delete older data
SET @sql = N''USE '' + QUOTENAME(@destination_database) + N''; IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(@destination_table) AND name = N''''cx_collection_time'''') SET @does_index_exist = 0''
--check if the index exists, output will be in boolean "@does_index_exist"
EXEC sp_executesql @sql, N''@destination_table NVARCHAR(500), @does_index_exist bit OUTPUT'', @destination_table = @destination_table, @does_index_exist = @does_index_exist OUTPUT
--does index exist? If not, create it on the logging table
IF @does_index_exist = 0 BEGIN
  SET @sql = N''CREATE CLUSTERED INDEX cx_collection_time ON '' + @destination_table + '' (collection_time ASC) with (DATA_COMPRESSION = page)''
  EXEC(@sql)
END

SET NOCOUNT OFF

--get output from sp_WhoIsActive into logging table
--  @get_transaction_info: "Enables pulling transaction log write info and transaction duration"
--  @get_outer_command: "Get the associated outer ad hoc query or stored procedure call, if available"
--  @get_plans: "Get associated query plans for running tasks, if available"
--  @format_output: "...outputs all of the numbers as actual numbers rather than text"
--  @get_additional_info: "...he [additional_info] column is an XML column that returns a document with a root node called <additional_info>. What’s inside of the node depends on a number of things..."
--EXEC master..sp_WhoIsActive @get_transaction_info = 1, @get_outer_command = 1, @get_plans = 1, @format_output = 0, @get_additional_info = 1, @destination_table = @destination_table
    EXEC dbo.sp_WhoIsActive
           @get_transaction_info = 1,
            @get_outer_command = 1,
            @get_plans = 1,
            @get_task_info = 2,
            @get_additional_info = 1,
            @find_block_leaders = 1,
            @get_memory_info = 1,
            @format_output = 0,
            @destination_table = @destination_table

SET NOCOUNT ON

--delete data older than "number of days to retain" variable
SET @sql = N''DELETE FROM '' + @destination_table + N'' WHERE [collection_time] < DATEADD(day, -'' + CAST(@number_of_days_to_retain AS NVARCHAR(10)) + N'', GETDATE())''
EXEC(@sql)', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Blocking report]    Script Date: 18.09.2023 16:42:53 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Blocking report', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'/*
WhoIsActive View Blocking

Copyright 2023 Darling Data, LLC
https://www.erikdarlingdata.com/
This will set up two views:
 * dbo.WhoIsActive: a UNION ALL of all tables that match the WhoIsActive_YYYYMMDD formaty
 * dbo.WhoIsActive_blocking: a recursive CTE that walks blocking chains in the above view
If you need to get or update sp_WhoIsActive:
https://github.com/amachanic/sp_whoisactive
(C) 2007-2022, Adam Machanic
*/


 declare @CheckTimeSec datetime = dateadd(ss,-25,getdate()),
   @HTML VARCHAR(MAX)
   
 IF (OBJECT_ID(''tempdb..##tmpBlockingReport'') IS NOT NULL) DROP TABLE ##tmpBlockingReport



  ;WITH b AS
        (
            SELECT
                l =
                    CONVERT
                    (
                        varchar(1000),
                        REPLICATE
                        (
                            '' '',
                            4 -
                            LEN
                            (
                                CONVERT
                                (
                                    varchar(1000),
                                    wia.session_id
                                )
                            )
                        ) +
                          CONVERT
                          (
                              varchar(1000),
                              wia.session_id
                          )
                    ),
                wia.collection_time,
    wia.start_time,
              --  wia.[dd hh:mm:ss.mss],
      RIGHT (''0'' + CAST(DATEDIFF(s, wia.start_time, wia.collection_time) / 3600 AS VARCHAR),2) + '':'' +
    RIGHT (''0'' + CAST((DATEDIFF(s,wia.start_time, wia.collection_time) / 60) % 60 AS VARCHAR),2) + '':'' +
    RIGHT (''0'' + CAST(DATEDIFF(s, wia.start_time, wia.collection_time) % 60 AS VARCHAR),2) AS [duration] ,
                wia.sql_text,
                wia.sql_command,
                wia.login_name,
                wia.wait_info,
                wia.session_id,
                wia.blocking_session_id,
                wia.blocked_session_count,
                wia.implicit_tran,
                wia.status,
                wia.open_tran_count
              --  wia.query_plan,
                --wia.additional_info
            FROM dbo.History_WhoIsActive AS wia
            WHERE (wia.blocking_session_id IS NULL
                    OR  wia.blocking_session_id = wia.session_id)
            AND   EXISTS
                  (
                      SELECT
                          1/0
                      FROM dbo.History_WhoIsActive AS wia2
                      WHERE wia2.blocking_session_id = wia.session_id
                      AND   wia2.collection_time = wia.collection_time
                      AND   wia2.blocking_session_id <> wia2.session_id
                  )
            UNION ALL
            SELECT
                l =
                    CONVERT
                    (
                        varchar(1000),
                        REPLICATE
                        (
                            '' '',
                            4 -
                              LEN
                              (
                                  CONVERT(varchar(1000),
                                  wia.session_id
                              )
                        )
                    ) +
                      CONVERT
                      (
                          varchar(1000),
                          wia.session_id
                      )
                    ),
                wia.collection_time,
    wia.start_time,
              --  wia.[dd hh:mm:ss.mss],
      RIGHT (''0'' + CAST(DATEDIFF(s, wia.start_time, wia.collection_time) / 3600 AS VARCHAR),2) + '':'' +
    RIGHT (''0'' + CAST((DATEDIFF(s,wia.start_time, wia.collection_time) / 60) % 60 AS VARCHAR),2) + '':'' +
    RIGHT (''0'' + CAST(DATEDIFF(s, wia.start_time, wia.collection_time) % 60 AS VARCHAR),2) AS [duration] ,
                wia.sql_text,
                wia.sql_command,
                wia.login_name,
                wia.wait_info,
                wia.session_id,
                wia.blocking_session_id,
                wia.blocked_session_count,
                wia.implicit_tran,
                wia.status,
                wia.open_tran_count
              --  wia.query_plan,
                --wia.additional_info
            FROM dbo.History_WhoIsActive AS wia
            INNER JOIN b AS b
              ON  wia.blocking_session_id = b.session_id
              AND b.collection_time = wia.collection_time
            WHERE wia.blocking_session_id IS NOT NULL
            AND   wia.blocking_session_id <> wia.session_id
        )
        SELECT TOP (9223372036854775807)
            --b.[dd hh:mm:ss.mss],
   duration,
            blocking =
                ''|--->'' +
                REPLICATE
                (
                    '' |---> '',
                    LEN(b.l) / 4 - 1
                ) +
                CASE
                    WHEN b.blocking_session_id IS NULL
                    THEN '' Lead SPID: ''
                    ELSE ''|---> Blocked SPID: ''
                END +
                CONVERT
                (
                    varchar(10),
                    b.session_id
                ) +
                '' '' +
                CONVERT
                (
                    varchar(30),
                    b.collection_time
                ),
            b.wait_info,
            b.sql_text,
            b.sql_command,
          --  b.query_plan,
            --b.additional_info,
            b.session_id,
            b.blocking_session_id,
            b.blocked_session_count,
            b.implicit_tran,
            b.status,
            b.open_tran_count,
            b.login_name,
            b.collection_time
  into ##tmpBlockingReport
        FROM b AS b
  where  
  -- за последние NN сек
  [collection_time] >= @CheckTimeSec
  -- исключения
  and sql_text not like ''%sysjobhistory%''
  and sql_text not like ''%sysjobactivity%''
  -- длительность блокировки
  and DATEDIFF(ss,[start_time],[collection_time]) > 10
        ORDER BY
            b.collection_time desc
          , b.blocked_session_count DESC;
  

if not exists(select 1 from ##tmpBlockingReport) return;

select * from ##tmpBlockingReport

EXEC sp_ExportTable2Html
    @TableName = ''##tmpBlockingReport'', -- varchar(max)
    @OrderBy=''[collection_time] desc, [blocked_session_count] DESC'',
    @Script = @HTML OUTPUT -- varchar(max)

 SET @HTML = ''
<h2>Blocking report</h2>
Last 20 records<br/><br/>'' + ISNULL(@HTML, '''') 

 
 EXEC msdb.dbo.sp_send_dbmail
    @profile_name = ''DBA-Alerts'', -- sysname
    @recipients = ''vzheltonogov@sfn-am.ru'', -- varchar(max)
    @subject = N''Blocking Report'', -- nvarchar(255)
    @body = @HTML, -- nvarchar(max)
    @body_format = ''html''
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'whoisactive_monitoring', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=2, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20211101, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'982a3817-d5d7-4995-a0f9-d00c627a0016'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



USE [msdb]
GO


IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'Monitoring')
EXEC msdb.dbo.sp_delete_job @job_name=N'Monitoring', @delete_unused_schedule=1
GO


/****** Object:  Job [Monitoring]    Script Date: 28.02.2023 10:01:53 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 28.02.2023 10:01:53 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitoring', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQLAlert', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [dbsize]    Script Date: 28.02.2023 10:01:53 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'dbsize', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE master
GO
SET QUOTED_IDENTIFIER ON
go

IF OBJECT_ID(''tempdb.dbo.#dbsize'') IS NOT NULL
    DROP TABLE #dbsize


CREATE TABLE [#dbsize](
 [dt] datetime null,
 [TYPE] [nvarchar](60) NULL,
 [FILE_Name] [sysname] NOT NULL,
 [FILEGROUP_NAME] [sysname] NULL,
 [File_Location] [nvarchar](260) NULL,
 [FILESIZE_MB] [decimal](10, 2) NULL,
 [USEDSPACE_MB] [decimal](10, 2) NULL,
 [FREESPACE_MB] [decimal](10, 2) NULL,
 [FREESPACE_%] [decimal](10, 2) NULL,
 [AutoGrow] [varchar](84) NULL
)


IF (OBJECT_ID(''dbo.Monitoring_dbsize'') IS NULL)
begin
CREATE TABLE dbo.Monitoring_dbsize(
 [dt] datetime null,
 [TYPE] [nvarchar](60) NULL,
 [FILE_Name] [sysname] NOT NULL,
 [FILEGROUP_NAME] [sysname] NULL,
 [File_Location] [nvarchar](260) NULL,
 [FILESIZE_MB] int NULL,
 [USEDSPACE_MB] int NULL,
 [FREESPACE_MB] int NULL,
 [FREESPACE_%] int NULL,
 [AutoGrow] [varchar](84) NULL
)
  CREATE CLUSTERED INDEX CI_Monitoring_dbsize_dt ON dbo.Monitoring_dbsize(Dt) WITH(DATA_COMPRESSION = PAGE)
end 


-- обходим все базы
DECLARE @SQL NVARCHAR(MAX)


-- это аналог курсора по базам
SELECT @SQL = STUFF((
    SELECT ''
 USE ['' + d.name + '']
INSERT INTO [#dbsize] ([TYPE],[FILE_Name],[FILEGROUP_NAME],[File_Location],[FILESIZE_MB],[USEDSPACE_MB],[FREESPACE_MB]
           ,[FREESPACE_%]
           ,[AutoGrow])
SELECT 
    [TYPE] = A.TYPE_DESC
    ,[FILE_Name] = A.name
    ,[FILEGROUP_NAME] = fg.name
    ,[File_Location] = A.PHYSICAL_NAME
    ,[FILESIZE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0)
    ,[USEDSPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - ((SIZE/128.0) - CAST(FILEPROPERTY(A.NAME, ''''SPACEUSED'''') AS bigINT)/128.0))
    ,[FREESPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, ''''SPACEUSED'''') AS bigINT)/128.0)
    ,[FREESPACE_%] = CONVERT(DECIMAL(10,2),((A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, ''''SPACEUSED'''') AS bigINT)/128.0)/(A.SIZE/128.0))*100)
    ,[AutoGrow] = ''''By '''' + CASE is_percent_growth WHEN 0 THEN CAST(growth/128 AS VARCHAR(10)) + '''' MB -'''' 
        WHEN 1 THEN CAST(growth AS VARCHAR(10)) + ''''% -'''' ELSE '''''''' END 
        + CASE max_size WHEN 0 THEN ''''DISABLED'''' WHEN -1 THEN '''' Unrestricted'''' 
            ELSE '''' Restricted to '''' + CAST(max_size/(128*1024) AS VARCHAR(10)) + '''' GB'''' END 
        + CASE is_percent_growth WHEN 1 THEN '''' [autogrowth by percent, BAD setting!]'''' ELSE '''''''' END
FROM sys.database_files A 
 LEFT JOIN sys.filegroups fg ON A.data_space_id = fg.data_space_id 
order by A.TYPE desc, A.NAME; 
''
 FROM sys.databases d
    WHERE d.[state] = 0
 and [name] not like ''%(%)%''
    FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''), 1, 2, '''')

EXEC sys.sp_executesql @SQL



INSERT INTO dbo.Monitoring_dbsize
           ([dt]
           ,[TYPE]
           ,[FILE_Name]
     ,[FILEGROUP_NAME]
           ,[File_Location]
           ,[FILESIZE_MB]
           ,[USEDSPACE_MB]
           ,[FREESPACE_MB]
           ,[FREESPACE_%]
           ,[AutoGrow])
select 
  getdate() as ''dt''
 ,[TYPE] 
    ,[FILE_Name]
    ,[FILEGROUP_NAME]
    ,[File_Location]
    ,[FILESIZE_MB]
    ,[USEDSPACE_MB]
    ,[FREESPACE_MB]
    ,[FREESPACE_%]
    ,[AutoGrow]

from #dbsize
--WHERE
 --TYPE =''LOG''
-- #dbsize.File_Location LIKE ''e:\%''
--order by 
--FILESIZE_MB DESC
--[FREESPACE_MB] desc
--ORDER BY file_name

--select * from dbo.Monitoring_dbsize order by dt desc', 
		@database_name=N'master', 
		@flags=4
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [tablesize]    Script Date: 28.02.2023 10:01:53 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'tablesize', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use [master]
go

DECLARE @sqlCommand varchar(2048)

select @sqlCommand = ''use [?]

IF OBJECT_ID(N''''[master].[dbo].[Monitoring_tablesize]'''', N''''U'''') IS NULL  
begin 
CREATE TABLE [master].[dbo].[Monitoring_tablesize] (
   [dt]       [DATETIME] DEFAULT GETDATE(),
   [database_name]     [VARCHAR](255) NOT NULL,
   [table_name]        [VARCHAR](255) NOT NULL,
   [schema]            [VARCHAR](64) NOT NULL,
   [row_count]         [BIGINT]NOT NULL,
   [total_space_mb]    [DECIMAL](15,2) NOT NULL,
   [used_space_mb]     [DECIMAL](15,2) NOT NULL,
   [unused_space_mb]   [DECIMAL](15,2) NOT NULL,
   [created_date]      [DATETIME] NOT NULL  
)ON [PRIMARY]

    CREATE CLUSTERED INDEX CI_database_name_dt ON  [master].[dbo].[Monitoring_tablesize]([database_name], [Dt]) WITH(DATA_COMPRESSION=PAGE)

end
insert into [master].[dbo].[Monitoring_tablesize]
  SELECT 
 GETDATE(),
 ''''?'''',
    t.NAME AS table_name,
    s.Name AS [schema],
    p.rows AS row_count,
    CAST(ROUND(((SUM(a.total_pages) * 8) / 1024.00), 2) AS DECIMAL(15, 2)) AS total_space_mb,
    CAST(ROUND(((SUM(a.used_pages) * 8) / 1024.00), 2) AS DECIMAL(15, 2)) AS used_space_mb, 
    CAST(ROUND(((SUM(a.total_pages) - SUM(a.used_pages)) * 8) / 1024.00, 2) AS DECIMAL(15, 2)) AS unused_space_mb,
 t.create_date as created_date
    FROM sys.tables t
    INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
    INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
    INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
    LEFT OUTER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE t.NAME NOT LIKE ''''dt%'''' 
      AND t.is_ms_shipped = 0
      AND i.OBJECT_ID > 255
    GROUP BY t.Name, s.Name, p.Rows,t.create_date
    ORDER BY total_space_mb DESC, t.Name

 
 ''
EXEC sp_MSforeachdb @sqlCommand;

DELETE FROM [master].[dbo].[Monitoring_tablesize] WHERE database_name IN (''master'',''model'',''msdb'',''tempdb'') and[dt]> cast(getdate() as date)', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [waits]    Script Date: 28.02.2023 10:01:53 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'waits', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- Last updated October 1, 2021

/*
https://www.sqlskills.com/blogs/paul/wait-statistics-or-please-tell-me-where-it-hurts/

	—брос статистики ожидани€
	DBCC SQLPERF("sys.dm_os_wait_stats",CLEAR);  
*/



USE [master]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID(N''[master].[dbo].[Monitoring_waits]'', N''U'') IS NULL  
begin 

CREATE TABLE [dbo].[Monitoring_waits](
	[dt] datetime null default getdate(),
	[WaitType] [nvarchar](60) NULL,
	[Wait_S] [decimal](16, 2) NULL,
	[WaitCount] [bigint] NULL,
	[Percentage] [decimal](5, 2) NULL
) ON [PRIMARY]


CREATE CLUSTERED INDEX CI_Monitoring_waits_WaitType_dt ON dbo.Monitoring_waits(WaitType, Dt) WITH(DATA_COMPRESSION = PAGE)
end

  


-- Last updated October 1, 2021
;WITH [Waits] AS
    (SELECT
        [wait_type],
        [wait_time_ms] / 1000.0 AS [WaitS],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
        [signal_wait_time_ms] / 1000.0 AS [SignalS],
        [waiting_tasks_count] AS [WaitCount],
        100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
        ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
    FROM sys.dm_os_wait_stats
    WHERE [wait_type] NOT IN (
        -- These wait types are almost 100% never a problem and so they are
        -- filtered out to avoid them skewing the results. Click on the URL
        -- for more information.
        N''BROKER_EVENTHANDLER'', -- https://www.sqlskills.com/help/waits/BROKER_EVENTHANDLER
        N''BROKER_RECEIVE_WAITFOR'', -- https://www.sqlskills.com/help/waits/BROKER_RECEIVE_WAITFOR
        N''BROKER_TASK_STOP'', -- https://www.sqlskills.com/help/waits/BROKER_TASK_STOP
        N''BROKER_TO_FLUSH'', -- https://www.sqlskills.com/help/waits/BROKER_TO_FLUSH
        N''BROKER_TRANSMITTER'', -- https://www.sqlskills.com/help/waits/BROKER_TRANSMITTER
        N''CHECKPOINT_QUEUE'', -- https://www.sqlskills.com/help/waits/CHECKPOINT_QUEUE
        N''CHKPT'', -- https://www.sqlskills.com/help/waits/CHKPT
        N''CLR_AUTO_EVENT'', -- https://www.sqlskills.com/help/waits/CLR_AUTO_EVENT
        N''CLR_MANUAL_EVENT'', -- https://www.sqlskills.com/help/waits/CLR_MANUAL_EVENT
        N''CLR_SEMAPHORE'', -- https://www.sqlskills.com/help/waits/CLR_SEMAPHORE
 
        -- Maybe comment this out if you have parallelism issues
        N''CXCONSUMER'', -- https://www.sqlskills.com/help/waits/CXCONSUMER
 
        -- Maybe comment these four out if you have mirroring issues
        N''DBMIRROR_DBM_EVENT'', -- https://www.sqlskills.com/help/waits/DBMIRROR_DBM_EVENT
        N''DBMIRROR_EVENTS_QUEUE'', -- https://www.sqlskills.com/help/waits/DBMIRROR_EVENTS_QUEUE
        N''DBMIRROR_WORKER_QUEUE'', -- https://www.sqlskills.com/help/waits/DBMIRROR_WORKER_QUEUE
        N''DBMIRRORING_CMD'', -- https://www.sqlskills.com/help/waits/DBMIRRORING_CMD
        N''DIRTY_PAGE_POLL'', -- https://www.sqlskills.com/help/waits/DIRTY_PAGE_POLL
        N''DISPATCHER_QUEUE_SEMAPHORE'', -- https://www.sqlskills.com/help/waits/DISPATCHER_QUEUE_SEMAPHORE
        N''EXECSYNC'', -- https://www.sqlskills.com/help/waits/EXECSYNC
        N''FSAGENT'', -- https://www.sqlskills.com/help/waits/FSAGENT
        N''FT_IFTS_SCHEDULER_IDLE_WAIT'', -- https://www.sqlskills.com/help/waits/FT_IFTS_SCHEDULER_IDLE_WAIT
        N''FT_IFTSHC_MUTEX'', -- https://www.sqlskills.com/help/waits/FT_IFTSHC_MUTEX
  
       -- Maybe comment these six out if you have AG issues
        N''HADR_CLUSAPI_CALL'', -- https://www.sqlskills.com/help/waits/HADR_CLUSAPI_CALL
        N''HADR_FILESTREAM_IOMGR_IOCOMPLETION'', -- https://www.sqlskills.com/help/waits/HADR_FILESTREAM_IOMGR_IOCOMPLETION
        N''HADR_LOGCAPTURE_WAIT'', -- https://www.sqlskills.com/help/waits/HADR_LOGCAPTURE_WAIT
        N''HADR_NOTIFICATION_DEQUEUE'', -- https://www.sqlskills.com/help/waits/HADR_NOTIFICATION_DEQUEUE
        N''HADR_TIMER_TASK'', -- https://www.sqlskills.com/help/waits/HADR_TIMER_TASK
        N''HADR_WORK_QUEUE'', -- https://www.sqlskills.com/help/waits/HADR_WORK_QUEUE
 
        N''KSOURCE_WAKEUP'', -- https://www.sqlskills.com/help/waits/KSOURCE_WAKEUP
        N''LAZYWRITER_SLEEP'', -- https://www.sqlskills.com/help/waits/LAZYWRITER_SLEEP
        N''LOGMGR_QUEUE'', -- https://www.sqlskills.com/help/waits/LOGMGR_QUEUE
        N''MEMORY_ALLOCATION_EXT'', -- https://www.sqlskills.com/help/waits/MEMORY_ALLOCATION_EXT
        N''ONDEMAND_TASK_QUEUE'', -- https://www.sqlskills.com/help/waits/ONDEMAND_TASK_QUEUE
        N''PARALLEL_REDO_DRAIN_WORKER'', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_DRAIN_WORKER
        N''PARALLEL_REDO_LOG_CACHE'', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_LOG_CACHE
        N''PARALLEL_REDO_TRAN_LIST'', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_TRAN_LIST
        N''PARALLEL_REDO_WORKER_SYNC'', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_WORKER_SYNC
        N''PARALLEL_REDO_WORKER_WAIT_WORK'', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_WORKER_WAIT_WORK
        N''PREEMPTIVE_OS_FLUSHFILEBUFFERS'', -- https://www.sqlskills.com/help/waits/PREEMPTIVE_OS_FLUSHFILEBUFFERS
        N''PREEMPTIVE_XE_GETTARGETSTATE'', -- https://www.sqlskills.com/help/waits/PREEMPTIVE_XE_GETTARGETSTATE
        N''PVS_PREALLOCATE'', -- https://www.sqlskills.com/help/waits/PVS_PREALLOCATE
        N''PWAIT_ALL_COMPONENTS_INITIALIZED'', -- https://www.sqlskills.com/help/waits/PWAIT_ALL_COMPONENTS_INITIALIZED
        N''PWAIT_DIRECTLOGCONSUMER_GETNEXT'', -- https://www.sqlskills.com/help/waits/PWAIT_DIRECTLOGCONSUMER_GETNEXT
        N''QDS_PERSIST_TASK_MAIN_LOOP_SLEEP'', -- https://www.sqlskills.com/help/waits/QDS_PERSIST_TASK_MAIN_LOOP_SLEEP
        N''QDS_ASYNC_QUEUE'', -- https://www.sqlskills.com/help/waits/QDS_ASYNC_QUEUE
        N''QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP'',
            -- https://www.sqlskills.com/help/waits/QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP
        N''QDS_SHUTDOWN_QUEUE'', -- https://www.sqlskills.com/help/waits/QDS_SHUTDOWN_QUEUE
        N''REDO_THREAD_PENDING_WORK'', -- https://www.sqlskills.com/help/waits/REDO_THREAD_PENDING_WORK
        N''REQUEST_FOR_DEADLOCK_SEARCH'', -- https://www.sqlskills.com/help/waits/REQUEST_FOR_DEADLOCK_SEARCH
        N''RESOURCE_QUEUE'', -- https://www.sqlskills.com/help/waits/RESOURCE_QUEUE
        N''SERVER_IDLE_CHECK'', -- https://www.sqlskills.com/help/waits/SERVER_IDLE_CHECK
        N''SLEEP_BPOOL_FLUSH'', -- https://www.sqlskills.com/help/waits/SLEEP_BPOOL_FLUSH
        N''SLEEP_DBSTARTUP'', -- https://www.sqlskills.com/help/waits/SLEEP_DBSTARTUP
        N''SLEEP_DCOMSTARTUP'', -- https://www.sqlskills.com/help/waits/SLEEP_DCOMSTARTUP
        N''SLEEP_MASTERDBREADY'', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERDBREADY
        N''SLEEP_MASTERMDREADY'', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERMDREADY
        N''SLEEP_MASTERUPGRADED'', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERUPGRADED
        N''SLEEP_MSDBSTARTUP'', -- https://www.sqlskills.com/help/waits/SLEEP_MSDBSTARTUP
        N''SLEEP_SYSTEMTASK'', -- https://www.sqlskills.com/help/waits/SLEEP_SYSTEMTASK
        N''SLEEP_TASK'', -- https://www.sqlskills.com/help/waits/SLEEP_TASK
        N''SLEEP_TEMPDBSTARTUP'', -- https://www.sqlskills.com/help/waits/SLEEP_TEMPDBSTARTUP
        N''SNI_HTTP_ACCEPT'', -- https://www.sqlskills.com/help/waits/SNI_HTTP_ACCEPT
        N''SOS_WORK_DISPATCHER'', -- https://www.sqlskills.com/help/waits/SOS_WORK_DISPATCHER
        N''SP_SERVER_DIAGNOSTICS_SLEEP'', -- https://www.sqlskills.com/help/waits/SP_SERVER_DIAGNOSTICS_SLEEP
        N''SQLTRACE_BUFFER_FLUSH'', -- https://www.sqlskills.com/help/waits/SQLTRACE_BUFFER_FLUSH
        N''SQLTRACE_INCREMENTAL_FLUSH_SLEEP'', -- https://www.sqlskills.com/help/waits/SQLTRACE_INCREMENTAL_FLUSH_SLEEP
        N''SQLTRACE_WAIT_ENTRIES'', -- https://www.sqlskills.com/help/waits/SQLTRACE_WAIT_ENTRIES
        N''VDI_CLIENT_OTHER'', -- https://www.sqlskills.com/help/waits/VDI_CLIENT_OTHER
        N''WAIT_FOR_RESULTS'', -- https://www.sqlskills.com/help/waits/WAIT_FOR_RESULTS
        N''WAITFOR'', -- https://www.sqlskills.com/help/waits/WAITFOR
        N''WAITFOR_TASKSHUTDOWN'', -- https://www.sqlskills.com/help/waits/WAITFOR_TASKSHUTDOWN
        N''WAIT_XTP_RECOVERY'', -- https://www.sqlskills.com/help/waits/WAIT_XTP_RECOVERY
        N''WAIT_XTP_HOST_WAIT'', -- https://www.sqlskills.com/help/waits/WAIT_XTP_HOST_WAIT
        N''WAIT_XTP_OFFLINE_CKPT_NEW_LOG'', -- https://www.sqlskills.com/help/waits/WAIT_XTP_OFFLINE_CKPT_NEW_LOG
        N''WAIT_XTP_CKPT_CLOSE'', -- https://www.sqlskills.com/help/waits/WAIT_XTP_CKPT_CLOSE
        N''XE_DISPATCHER_JOIN'', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_JOIN
        N''XE_DISPATCHER_WAIT'', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_WAIT
        N''XE_TIMER_EVENT'' -- https://www.sqlskills.com/help/waits/XE_TIMER_EVENT
        )
    AND [waiting_tasks_count] > 0
    )
insert into [dbo].[Monitoring_waits]([WaitType], [Wait_S], [WaitCount], [Percentage])
SELECT
    MAX ([W1].[wait_type]) AS [WaitType],
    CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S],
    MAX ([W1].[WaitCount]) AS [WaitCount],
    CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage]
FROM [Waits] AS [W1]
INNER JOIN [Waits] AS [W2] ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY [W1].[RowNum]
HAVING SUM ([W2].[Percentage]) - MAX( [W1].[Percentage] ) < 95; -- percentage threshold
GO', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'_Monitoring', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20211222, 
		@active_end_date=99991231, 
		@active_start_time=10000, 
		@active_end_time=235959, 
		@schedule_uid=N'bcc3fd68-9f5e-4c99-a4d3-1915f15e9541'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



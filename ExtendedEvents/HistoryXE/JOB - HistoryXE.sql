USE master
GO

/* Просмотр данных

SELECT TOP (1000) *  FROM [master].[dbo].[History_TimeoutsXE] ORDER BY dt_event
SELECT TOP (1000) *  FROM [master].[dbo].[History_SystemErrorsXE] ORDER BY dt_event desc
SELECT TOP (1000) *  FROM [master].[dbo].[History_DeadlocksXE] ORDER BY dt_log
SELECT TOP (1000) *  FROM [master].[dbo].[History_SystemDeadlocksXE] ORDER BY dt_log

*/

IF ((SELECT COUNT(*) FROM sys.server_event_sessions WHERE [name] = 'History_Timeouts') > 0) DROP EVENT SESSION [History_Timeouts] ON SERVER 
GO

CREATE EVENT SESSION [History_Timeouts]
ON SERVER
ADD EVENT sqlserver.attention ( 
    ACTION
    (
        sqlserver.client_app_name,
        sqlserver.client_hostname,
        sqlserver.[database_name],
        sqlserver.nt_username,
      --  sqlserver.num_response_rows,
        sqlserver.server_instance_name,
        sqlserver.server_principal_name,
        sqlserver.server_principal_sid,
        sqlserver.session_id,
        sqlserver.session_nt_username,
        sqlserver.session_server_principal_name,
        sqlserver.sql_text,
        sqlserver.username
    )
)
ADD TARGET package0.event_file ( 
    SET 
        filename = N'History_Timeouts.xel',
        max_file_size = ( 20 ),
        max_rollover_files = ( 5 )
)
WITH
(
    STARTUP_STATE = ON-- Стартует при запуске сервера
)
GO

ALTER EVENT SESSION [History_Timeouts] ON SERVER STATE = START
GO

IF ((SELECT COUNT(*) FROM sys.server_event_sessions WHERE [name] = 'History_SystemErrors') > 0) DROP EVENT SESSION [History_SystemErrors] ON SERVER 
GO

CREATE EVENT SESSION [History_SystemErrors] ON SERVER 
ADD EVENT sqlserver.error_reported (
    ACTION(client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.session_id,sqlserver.session_nt_username,sqlserver.sql_text)
    WHERE severity > 10
)
ADD TARGET package0.event_file(SET filename=N'History_SystemErrors.xel',max_file_size=(3),max_rollover_files=(1))
WITH (STARTUP_STATE=ON) -- Стартует при запуске сервера
GO

ALTER EVENT SESSION [History_SystemErrors] ON SERVER STATE = START
GO

IF ((SELECT COUNT(*) FROM sys.server_event_sessions WHERE [name] = 'History_Deadlocks') > 0) DROP EVENT SESSION [History_Deadlocks] ON SERVER 
GO
CREATE EVENT SESSION [History_Deadlocks] ON SERVER 
ADD EVENT sqlserver.xml_deadlock_report(
    ACTION(sqlserver.client_app_name, sqlserver.client_hostname, sqlserver.database_name, sqlserver.plan_handle, sqlserver.session_id, sqlserver.session_server_principal_name, sqlserver.sql_text)
)
ADD TARGET package0.event_file(SET filename = N'History_Deadlocks.xel', max_file_size=(20), max_rollover_files=(1))
WITH (MAX_MEMORY=4096 KB, EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS, MAX_DISPATCH_LATENCY=30 SECONDS, MAX_EVENT_SIZE=0 KB, MEMORY_PARTITION_MODE=NONE, TRACK_CAUSALITY=OFF,
	STARTUP_STATE=ON
	)
GO

ALTER EVENT SESSION History_Deadlocks ON SERVER STATE = START
GO


-- Удаляем таблицы с историей
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[History_DeadlocksXE]') AND type in (N'U'))
DROP TABLE [dbo].[History_DeadlocksXE]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[History_SystemDeadlocksXE]') AND type in (N'U'))
DROP TABLE [dbo].[History_SystemDeadlocksXE]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[History_SystemErrorsXE]') AND type in (N'U'))
DROP TABLE [dbo].[History_SystemErrorsXE]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[History_TimeoutsXE]') AND type in (N'U'))
DROP TABLE [dbo].[History_TimeoutsXE]
GO


USE [msdb]
GO


IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'HistoryXE')
EXEC msdb.dbo.sp_delete_job @job_name=N'HistoryXE', @delete_unused_schedule=1
GO

USE [msdb]
GO


BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0

IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'HistoryXE', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'History_TimeoutsXE', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE master
GO
SET QUOTED_IDENTIFIER ON
go
IF (OBJECT_ID(''dbo.History_TimeoutsXE'') IS NULL)
BEGIN
 
    -- DROP TABLE dbo.History_TimeoutsXE
    CREATE TABLE dbo.History_TimeoutsXE (
        [Dt_Event]            DATETIME,
        [session_id]           INT,
        [duration]             BIGINT,
        [server_instance_name] VARCHAR(100),
        [database_name]        VARCHAR(100),
        [session_nt_username]  VARCHAR(100),
        [nt_username]          VARCHAR(100),
        [client_hostname]      VARCHAR(100),
        [client_app_name]      VARCHAR(100),
       -- [num_response_rows]    INT,
        [sql_text]             XML
    ) 
	    CREATE CLUSTERED INDEX CI_Dt_Event ON dbo.History_TimeoutsXE(Dt_Event) WITH(DATA_COMPRESSION = PAGE)

 
END
 
 
DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())
DECLARE @Dt_Ultimo_Evento DATETIME = ISNULL((SELECT MAX(Dt_Event) FROM dbo.History_TimeoutsXE WITH(NOLOCK)), ''1990-01-01'')
 
 
IF (OBJECT_ID(''tempdb..#Events'') IS NOT NULL) DROP TABLE #Events 
;WITH CTE AS (
    SELECT CONVERT(XML, event_data) AS event_data
    FROM sys.fn_xe_file_target_read_file(N''History_Timeouts*.xel'', NULL, NULL, NULL)
)
SELECT
    DATEADD(HOUR, @TimeZone, CTE.event_data.value(''(//event/@timestamp)[1]'', ''datetime'')) AS Dt_Event,
    CTE.event_data
INTO
    #Events
FROM
    CTE
WHERE
    DATEADD(HOUR, @TimeZone, CTE.event_data.value(''(//event/@timestamp)[1]'', ''datetime'')) > @Dt_Ultimo_Evento
    
 
INSERT INTO dbo.History_TimeoutsXE
SELECT
    A.Dt_Event,
    xed.event_data.value(''(action[@name="session_id"]/value)[1]'', ''int'') AS [session_id],
    xed.event_data.value(''(data[@name="duration"]/value)[1]'', ''bigint'') AS [duration],
    xed.event_data.value(''(action[@name="server_instance_name"]/value)[1]'', ''varchar(100)'') AS [server_instance_name],
    xed.event_data.value(''(action[@name="database_name"]/value)[1]'', ''varchar(100)'') AS [database_name],
    xed.event_data.value(''(action[@name="session_nt_username"]/value)[1]'', ''varchar(100)'') AS [session_nt_username],
    xed.event_data.value(''(action[@name="nt_username"]/value)[1]'', ''varchar(100)'') AS [nt_username],
    xed.event_data.value(''(action[@name="client_hostname"]/value)[1]'', ''varchar(100)'') AS [client_hostname],
    xed.event_data.value(''(action[@name="client_app_name"]/value)[1]'', ''varchar(100)'') AS [client_app_name],
  --  xed.event_data.value(''(action[@name="num_response_rows"]/value)[1]'', ''int'') AS [num_response_rows],
    TRY_CAST(xed.event_data.value(''(action[@name="sql_text"]/value)[1]'', ''varchar(max)'') AS XML) AS [sql_text]
FROM
    #Events A
    CROSS APPLY A.event_data.nodes(''//event'') AS xed (event_data)
	
	--delete old data
	DELETE FROM  [dbo].[History_TimeoutsXE] WHERE [dt_event] < DATEADD(day, -30, GETDATE())
	', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [History_SystemErrorsXE]    Script Date: 25.10.2021 20:04:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'History_SystemErrorsXE', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE master
go
IF (OBJECT_ID(''dbo.History_SystemErrorsXE'') IS NULL)
BEGIN

    -- DROP TABLE dbo.History_SystemErrorsXE
    CREATE TABLE dbo.History_SystemErrorsXE (
        Dt_Event DATETIME,
        session_id INT,
        [database_name] VARCHAR(100),
        session_nt_username VARCHAR(100),
        client_hostname VARCHAR(100),
        client_app_name VARCHAR(100),
        [error_number] INT,
        severity INT,
        [state] INT,
        sql_text XML,
        [message] VARCHAR(MAX)
    )

    CREATE CLUSTERED INDEX CI_Dt_Event ON dbo.History_SystemErrorsXE(Dt_Event) WITH(DATA_COMPRESSION = PAGE)

END


DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())
DECLARE @Dt_Ultimo_Evento DATETIME = ISNULL((SELECT MAX(Dt_Event) FROM dbo.History_SystemErrorsXE WITH(NOLOCK)), ''1990-01-01'')


IF (OBJECT_ID(''tempdb..#Events'') IS NOT NULL) DROP TABLE #Events

;WITH CTE AS (
    SELECT CONVERT(XML, event_data) AS event_data
    FROM sys.fn_xe_file_target_read_file(N''History_SystemErrors*.xel'', NULL, NULL, NULL)
)
SELECT
    DATEADD(HOUR, @TimeZone, CTE.event_data.value(''(//event/@timestamp)[1]'', ''datetime'')) AS Dt_Event,
    CTE.event_data
INTO
    #Events
FROM
    CTE
WHERE
    DATEADD(HOUR, @TimeZone, CTE.event_data.value(''(//event/@timestamp)[1]'', ''datetime'')) > @Dt_Ultimo_Evento


SET QUOTED_IDENTIFIER ON

INSERT INTO dbo.History_SystemErrorsXE
SELECT
    A.Dt_Event,
    xed.event_data.value(''(action[@name="session_id"]/value)[1]'', ''int'') AS [session_id],
    xed.event_data.value(''(action[@name="database_name"]/value)[1]'', ''varchar(100)'') AS [database_name],
    xed.event_data.value(''(action[@name="session_nt_username"]/value)[1]'', ''varchar(100)'') AS [session_nt_username],
    xed.event_data.value(''(action[@name="client_hostname"]/value)[1]'', ''varchar(100)'') AS [client_hostname],
    xed.event_data.value(''(action[@name="client_app_name"]/value)[1]'', ''varchar(100)'') AS [client_app_name],
    xed.event_data.value(''(data[@name="error_number"]/value)[1]'', ''int'') AS [error_number],
    xed.event_data.value(''(data[@name="severity"]/value)[1]'', ''int'') AS [severity],
    xed.event_data.value(''(data[@name="state"]/value)[1]'', ''int'') AS [state],
    TRY_CAST(xed.event_data.value(''(action[@name="sql_text"]/value)[1]'', ''varchar(max)'') AS XML) AS [sql_text],
    xed.event_data.value(''(data[@name="message"]/value)[1]'', ''varchar(max)'') AS [message]
FROM
    #Events A
    CROSS APPLY A.event_data.nodes(''//event'') AS xed (event_data)
	
	--delete old data
	DELETE FROM  [dbo].[History_SystemErrorsXE] WHERE [dt_event] < DATEADD(day, -30, GETDATE())

	-- удаляем данные ошибке "Invalid SPID specified"
 declare @job_id nvarchar(100)
 
 SELECT top 1 @job_id = (substring(sys.fn_varbintohexstr(sj.job_id),3,100)) FROM msdb..sysjobs sj WHERE name = ''History.WhoIsActive''

--select top 10 * 
delete 
from [dbo].[History_SystemErrorsXE] 
where 
		[error_number] = 7955
		and [severity] = 16
		and [state] = 2
		-- если добавили шаг в джоб History.WhoIsActive нужно здесь поменять STEP
		and[client_app_name] = ''SQLAgent - TSQL JobStep (Job 0x''+@job_id +'' : Step 2)'' 
	

 
	', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [History_SystemDeadlocksXE]    Script Date: 25.10.2021 20:04:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'History_SystemDeadlocksXE', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- https://en.dirceuresende.com/blog/sql-server-how-to-generate-deadlock-history-monitoring-for-routine-failure-analysis/
USE [master]
GO
SET QUOTED_IDENTIFIER ON
go
 
IF (OBJECT_ID(''dbo.History_SystemDeadlocksXE'') IS NULL)
BEGIN
	-- drop table dbo.History_SystemDeadlocksXE
    CREATE TABLE dbo.History_SystemDeadlocksXE (
        Dt_Log DATETIME,
        Ds_Log XML
    )
    CREATE CLUSTERED INDEX CI_Dt_Log ON dbo.History_SystemDeadlocksXE(Dt_Log) WITH(DATA_COMPRESSION = PAGE)
END
 
 
DECLARE @Dt_Max_Event DATETIME = ISNULL((SELECT MAX(Dt_Log) FROM dbo.History_SystemDeadlocksXE WITH(NOLOCK)), ''1900-01-01'')
 
INSERT INTO dbo.History_SystemDeadlocksXE
SELECT
    xed.value(''@timestamp'', ''datetime2(3)'') as CreationDate,
    xed.query(''.'') AS XEvent
FROM
(
    SELECT 
        CAST([target_data] AS XML) AS TargetData
    FROM 
        sys.dm_xe_session_targets AS st
        INNER JOIN sys.dm_xe_sessions AS s ON s.[address] = st.event_session_address
    WHERE 
        s.[name] = N''system_health''
        AND st.target_name = N''ring_buffer''
) AS [Data]
CROSS APPLY TargetData.nodes(''RingBufferTarget/event[@name="xml_deadlock_report"]'') AS XEventData (xed)
WHERE
    xed.value(''@timestamp'', ''datetime2(3)'') > @Dt_Max_Event
ORDER BY 
    CreationDate DESC
	
--delete old data
DELETE FROM  [dbo].[History_SystemDeadlocksXE] WHERE [dt_log] < DATEADD(day, -30, GETDATE())
	', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [History_DeadlocksXE]    Script Date: 25.10.2021 20:04:21 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'History_DeadlocksXE', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE master
GO

SET QUOTED_IDENTIFIER ON
GO

IF (OBJECT_ID(''dbo.History_DeadlocksXE'') IS NULL)
BEGIN

    -- DROP TABLE dbo.History_DeadlocksXE
    CREATE TABLE dbo.History_DeadlocksXE
    (
        [Dt_Log] DATETIME2,
        [isVictim] INT,
        [processId] VARCHAR(100),
        [processSqlCommand] XML,
        [resourceDBId] INT,
        [resourceDBName] NVARCHAR(128),
        [resourceObjectName] VARCHAR(128),
        [processWaitResource] VARCHAR(100),
        [processWaitTime] INT,
        [processTransactionName] VARCHAR(60),
        [processStatus] VARCHAR(60),
        [processSPID] INT,
        [processClientApp] VARCHAR(256),
        [processHostname] VARCHAR(256),
        [processLoginName] VARCHAR(256),
        [processIsolationLevel] VARCHAR(256),
        [processCurrentDb] VARCHAR(256),
        [processCurrentDbName] NVARCHAR(128),
        [processTranCount] INT,
        [processLockMode] VARCHAR(10),
        [resourceFileId] INT,
        [resourcePageId] INT,
        [resourceLockMode] VARCHAR(2),
        [resourceprocesswner] VARCHAR(128),
        [resourceprocesswnerMode] VARCHAR(2)
    )
		    CREATE CLUSTERED INDEX CI_Dt_Log ON dbo.History_DeadlocksXE(Dt_Log) WITH(DATA_COMPRESSION = PAGE)

END

    
DECLARE 
    @Dt_Max_Event DATETIME2 = ISNULL((SELECT MAX(Dt_Log) FROM dbo.History_DeadlocksXE WITH(NOLOCK)), ''1900-01-01''),
    @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())

IF (OBJECT_ID(''tempdb..#xml_deadlock'') IS NOT NULL) DROP TABLE #xml_deadlock
SELECT
    *
INTO
    #xml_deadlock
FROM
(
    SELECT
        module_guid,
        package_guid,
        [object_name],
        [file_name],
        [file_offset],
        DATEADD(HOUR, @TimeZone, CAST(CURRENT_TIMESTAMP AS DATETIME2)) AS Dt_Event,
        CAST(event_data AS XML) AS TargetData
    FROM 
        sys.fn_xe_file_target_read_file(N''History_Deadlocks*.xel'', NULL, NULL, NULL)
) AS [data]
WHERE
    Dt_Event > @Dt_Max_Event
ORDER BY 
    Dt_Event DESC

    
INSERT INTO dbo.History_DeadlocksXE
SELECT
    DATEADD(HOUR, @TimeZone, data.event_data.value(''@timestamp'', ''datetime2'')) AS [timestamp],
    (CASE WHEN victim.data.value(''@id'', ''varchar(100)'') = process.data.value(''@id'', ''varchar(100)'') THEN 1 ELSE 0 END) AS isVictim,
    process.data.value(''@id'', ''varchar(100)'') AS [processId],
    process.data.query(''(inputbuf/text())'') AS [processSqlCommand],
    recurso.resourceDBId,
    DB_NAME(recurso.resourceDBId) AS resourceDBName,
    recurso.resourceObjectName,
    process.data.value(''@waitresource'', ''varchar(100)'') AS [processWaitResource],
    process.data.value(''@waittime'', ''int'') AS [processWaitTime],
    process.data.value(''@transactionname'', ''varchar(60)'') AS [processTransactionName],
    process.data.value(''@status'', ''varchar(60)'') AS [processStatus],
    process.data.value(''@spid'', ''int'') AS [processSPID],
    process.data.value(''@clientapp'', ''varchar(256)'') AS [processClientApp],
    process.data.value(''@hostname'', ''varchar(256)'') AS [processHostname],
    process.data.value(''@loginname'', ''varchar(256)'') AS [processLoginName],
    process.data.value(''@isolationlevel'', ''varchar(256)'') AS [processIsolationLevel],
    process.data.value(''@currentdb'', ''varchar(256)'') AS [processCurrentDb],
    DB_NAME(process.data.value(''@currentdb'', ''varchar(256)'')) AS [processCurrentDbName],
    process.data.value(''@trancount'', ''int'') AS [processTranCount],
    process.data.value(''@lockMode'', ''varchar(10)'') AS [processLockMode],
    recurso.resourceFileId,
    recurso.resourcePageId,
    recurso.resourceLockMode,
    recurso.resourceprocesswner,
    recurso.resourceprocesswnerMode
FROM
    #xml_deadlock A
    CROSS APPLY A.TargetData.nodes(''//event'') AS data(event_data)
    CROSS APPLY data.event_data.nodes(''data/value/deadlock/victim-list/victimProcess'') AS victim(data)
    OUTER APPLY data.event_data.nodes(''data/value/deadlock/process-list/process'') AS process(data)
    LEFT JOIN (
        SELECT
            A.Dt_Event,
            recurso.data.value(''@fileid'', ''int'') AS [resourceFileId],
            recurso.data.value(''@pageid'', ''int'') AS [resourcePageId],
            recurso.data.value(''@dbid'', ''int'') AS [resourceDBId],
            recurso.data.value(''@objectname'', ''varchar(128)'') AS [resourceObjectName],
            recurso.data.value(''@mode'', ''varchar(2)'') AS [resourceLockMode],
            [owner].data.value(''@id'', ''varchar(128)'') AS [resourceprocesswner],
            [owner].data.value(''@mode'', ''varchar(2)'') AS [resourceprocesswnerMode]
        FROM 
            #xml_deadlock A
            CROSS APPLY A.TargetData.nodes(''//ridlock'') AS recurso(data)
            OUTER APPLY recurso.data.nodes(''owner-list/owner'') AS owner(data)
    ) AS recurso ON recurso.resourceprocesswner = process.data.value(''@id'', ''varchar(100)'') AND recurso.Dt_Event = A.Dt_Event
	
--delete old data
DELETE FROM  [dbo].[History_DeadlocksXE] WHERE [dt_log] < DATEADD(day, -30, GETDATE())
	', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'HistoryXE', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20211025, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'f3d47d2b-9788-4ffa-b14c-54bd5e7419f4'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



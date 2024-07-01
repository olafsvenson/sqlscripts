USE [msdb]
GO


USE [msdb]
GO


IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'Monitoring.CheckLog')
EXEC msdb.dbo.sp_delete_job @job_name=N'Monitoring.CheckLog', @delete_unused_schedule=1
GO



/****** Object:  Job [Monitoring.CheckLog]    Script Date: 10.01.2024 15:45:48 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Support]]    Script Date: 10.01.2024 15:45:48 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Support]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Support]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Monitoring.CheckLog', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Проверяет лог сервера, default trace на определенные события и отправляет алерт.', 
		@category_name=N'[Support]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [check helpers proc]    Script Date: 10.01.2024 15:45:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'check helpers proc', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
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
/****** Object:  Step [custom errors events]    Script Date: 10.01.2024 15:45:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'custom errors events', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use master
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--  Job frequency
DECLARE @CheckPeriodInMinute int = 30
		,@HTML VARCHAR(MAX)

DECLARE @errorlog TABLE(
      LogDate datetime
    , ProcessInfo varchar(32)
    , Text varchar(max)
)
DECLARE @notifiable_errors table(
      LogDate varchar(19)
    , ProcessInfo varchar(32)
    , Text varchar(1024)
    , error_category varchar(150)
)
 
 DECLARE @errorlog_definition TABLE(
    error_category varchar(150)
    , error_pattern varchar(1000)

)

insert into @errorlog_definition
    values (''Database Write Latency'', ''%I/O requests taking longer than%seconds to complete%'')
        ,(''Database Write Latency'', ''%cleaned up%bufs with%in%ms%for db%'')
        ,(''Database Write Latency'', ''%average%'')
        ,(''Database Write Latency'', ''%last target outstanding:%avgWriteLatency%'')
        ,(''Database Write Error Disk Full'', ''Could not allocate%'')
        ,(''Database Login Failure'', ''%Login Failed%'')
        ,(''SQL Server starting'', ''SQL Server is starting%'')
 
insert into @errorlog
    exec sp_readerrorlog 0
 

  IF (OBJECT_ID(''tempdb..##notifiable_errors'') IS NOT NULL) DROP TABLE ##notifiable_errors;


-- Get Error Log entries matching pattern (like)
--insert into @notifiable_errors
    select e.LogDate, e.ProcessInfo, e.Text, c.error_category
	into ##notifiable_errors
    from @errorlog AS e
        cross apply (
            select *
            from @errorlog_definition AS d
            where e.Text like d.error_pattern
        ) AS c
    where LogDate > DATEADD(MINUTE, -@CheckPeriodInMinute, GETDATE())
 

    if not exists(select 1 from ##notifiable_errors) return;


EXEC sp_ExportTable2Html
    @TableName = ''##notifiable_errors'', -- varchar(max)
    @OrderBy=''[LogDate]'',
    @Script = @HTML OUTPUT -- varchar(max)

 SET @HTML = ''
<h2>SQL Log Alerts report</h2><br/>'' + ISNULL(@HTML, '''') 

 EXEC msdb.dbo.sp_send_dbmail
    @profile_name = ''DBA-Alerts'', -- sysname
    @recipients = ''vzheltonogov@sfn-am.ru'', -- varchar(max)
    @subject = N''SQL Log Alerts report'', -- nvarchar(255)
    @body = @HTML, -- nvarchar(max)
    @body_format = ''html''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [autogrow events]    Script Date: 10.01.2024 15:45:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'autogrow events', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use master
go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

DECLARE @CheckPeriodInMinute int = 30
		,@HTML VARCHAR(MAX)


IF (OBJECT_ID(''tempdb..##autogrow_events'') IS NOT NULL) DROP TABLE ##autogrow_events;


  DECLARE 
    @Path_Default_Trace VARCHAR(500) = (SELECT [path] FROM sys.traces WHERE is_default = 1)
    
DECLARE
    @Index INT = PATINDEX(''%\%'', REVERSE(@Path_Default_Trace))
 
DECLARE
    @FullPath_Default_Trace VARCHAR(500) = LEFT(@Path_Default_Trace, LEN(@Path_Default_Trace) - @Index) + ''\log.trc''
 
 
SELECT
    A.DatabaseName,
    A.[Filename],
    ( A.Duration / 1000 ) AS ''Duration_ms'',
    A.StartTime,
    A.EndTime,
    ( A.IntegerData * 8.0 / 1024 ) AS ''GrowthSize_MB'',
    A.ApplicationName,
    A.HostName,
    A.LoginName
into ##autogrow_events
FROM
    ::fn_trace_gettable(@FullPath_Default_Trace, DEFAULT) A
WHERE
    A.EventClass >= 92
    AND A.EventClass <= 95
    AND A.ServerName = @@servername 
	and a.StartTime > DATEADD(MINUTE, -@CheckPeriodInMinute, GETDATE())
ORDER BY
	 A.StartTime DESC


if not exists(select 1 from ##autogrow_events) return;


EXEC sp_ExportTable2Html
    @TableName = ''##autogrow_events'', -- varchar(max)
    @OrderBy=''[StartTime]'',
    @Script = @HTML OUTPUT -- varchar(max)

 SET @HTML = ''
<h2>Autogrow Events report</h2><br/>'' + ISNULL(@HTML, '''') 

 EXEC msdb.dbo.sp_send_dbmail
    @profile_name = ''DBA-Alerts'', -- sysname
    @recipients = ''vzheltonogov@sfn-am.ru'', -- varchar(max)
    @subject = N''Autogrow Events report'', -- nvarchar(255)
    @body = @HTML, -- nvarchar(max)
    @body_format = ''html''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Monitoring.CheckLog', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=30, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20230914, 
		@active_end_date=99991231, 
		@active_start_time=14, 
		@active_end_time=235959, 
		@schedule_uid=N'224ec562-0861-4331-ad30-02ac3e576108'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



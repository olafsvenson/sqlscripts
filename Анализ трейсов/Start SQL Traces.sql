USE [msdb]
GO

/****** Object:  Job [Start SQL Trace]    Script Date: 6/25/2018 7:49:00 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 6/25/2018 7:49:00 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Start SQL Trace', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Запускает ежедневный сбор трейсов
dailyCpu не запускаем 11.08
', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQLAlert', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Start new trace]    Script Date: 6/25/2018 7:49:00 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Start new trace', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF
	(SELECT COUNT (DISTINCT traceID) FROM ::fn_trace_getinfo(default)) > 20  -- если трейсов больше 20, ставим ошибку и шлём нотификацию на почту
	
BEGIN
			
	RAISERROR (''Warning: Trace count >20'', 16, 1)
				
		DECLARE @subj NVARCHAR(100) =''Too many traces on ''+ @@servicename
		DECLARE @bodytext NVARCHAR(100) =''Warning: Trace count > 20''
		exec msdb.dbo.sp_send_dbmail
		@profile_name	= N''sql_mail'',
		@recipients		= N''vzheltonogov@urbgroup.ru'',
		@subject		= @subj,
		@body = @bodytext,
		@body_format	= ''TEXT'',
		@importance		= ''High''
		RETURN
END
-- 
declare @rc int
declare @TraceID int

--максимальный размер отдельного файла 1 ГБ
declare @maxfilesize bigint = 1024
declare @now datetime = getdate()

--время окончания устанавливаем на 23:59:50
declare @stopTime datetime = DATEADD(ss,-10,DATEADD(dd,1, DateAdd(day,0,DateDiff(day,0,GETDATE()))))

--путь к папке трэйса
declare @folder nvarchar(200) = N''D:\SQL_Traces\'' + @@servicename + N''\''

--путь к файлу трэйса
declare @fileName nvarchar(245) = @folder + N''dailyCPU '' + replace(convert(nvarchar(20), @now, 120), '':'', '''')
select @fileName

IF 
NOT EXISTS (SELECT * FROM ::fn_trace_getinfo(default) WHERE cast (VALUE AS VARCHAR(MAX)) LIKE ''%dailyCPU%'') --если нету трейса с таким путем, запускаем
BEGIN

--включить трэйс с опцией rollover
exec @rc = sp_trace_create @TraceID output, 2, @fileName, @maxfilesize, @stopTime
if (@rc != 0)
	return

-- События
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 10, 15, @on
exec sp_trace_setevent @TraceID, 10, 8, @on
exec sp_trace_setevent @TraceID, 10, 16, @on
exec sp_trace_setevent @TraceID, 10, 1, @on
exec sp_trace_setevent @TraceID, 10, 9, @on
exec sp_trace_setevent @TraceID, 10, 17, @on
exec sp_trace_setevent @TraceID, 10, 25, @on
exec sp_trace_setevent @TraceID, 10, 2, @on
exec sp_trace_setevent @TraceID, 10, 10, @on
exec sp_trace_setevent @TraceID, 10, 18, @on
exec sp_trace_setevent @TraceID, 10, 34, @on
exec sp_trace_setevent @TraceID, 10, 11, @on
exec sp_trace_setevent @TraceID, 10, 35, @on
exec sp_trace_setevent @TraceID, 10, 12, @on
exec sp_trace_setevent @TraceID, 10, 13, @on
exec sp_trace_setevent @TraceID, 10, 6, @on
exec sp_trace_setevent @TraceID, 10, 14, @on
exec sp_trace_setevent @TraceID, 12, 15, @on
exec sp_trace_setevent @TraceID, 12, 8, @on
exec sp_trace_setevent @TraceID, 12, 16, @on
exec sp_trace_setevent @TraceID, 12, 1, @on
exec sp_trace_setevent @TraceID, 12, 9, @on
exec sp_trace_setevent @TraceID, 12, 17, @on
exec sp_trace_setevent @TraceID, 12, 6, @on
exec sp_trace_setevent @TraceID, 12, 10, @on
exec sp_trace_setevent @TraceID, 12, 14, @on
exec sp_trace_setevent @TraceID, 12, 18, @on
exec sp_trace_setevent @TraceID, 12, 11, @on
exec sp_trace_setevent @TraceID, 12, 35, @on
exec sp_trace_setevent @TraceID, 12, 12, @on
exec sp_trace_setevent @TraceID, 12, 13, @on


-- Настроить фильтры
declare @intfilter int
declare @bigintfilter bigint

--исключить sp_reset_connection (TextData not like ''%sp_reset_connection%''
exec sp_trace_setfilter @TraceID, 1, 0, 7, N''%sp_reset_connection%''

--исключить события с пустым TextData
exec sp_trace_setfilter @TraceID, 1, 0, 1, NULL

--включить события с CPU >= 200
set @intfilter = 200
exec sp_trace_setfilter @TraceID, 18, 0, 4, @intfilter

--исключить события с пустым CPU
set @intfilter = NULL
exec sp_trace_setfilter @TraceID, 18, 0, 1, @intfilter


-- Запустить трэйс
exec sp_trace_setstatus @TraceID, 1
END


', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Start new deadlocks trace]    Script Date: 6/25/2018 7:49:00 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Start new deadlocks trace', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF	
	(SELECT COUNT (DISTINCT traceID) FROM ::fn_trace_getinfo(default)) > 20  -- если трейсов больше 20, ставим ошибку и шлём нотификацию на почту
	
BEGIN
			
	RAISERROR (''Warning: Trace count >20'', 16, 1)
				
		DECLARE @subj NVARCHAR(100) =''Too many traces on ''+ @@servicename
		DECLARE @bodytext NVARCHAR(100) =''Warning: Trace count > 20''
		exec msdb.dbo.sp_send_dbmail
		@profile_name	= N''sql_mail'',
		@recipients		= N''vzheltonogov@urbgroup.ru'',
		@subject		= @subj,
		@body = @bodytext,
		@body_format	= ''TEXT'',
		@importance		= ''High''
		RETURN
END
-- 
declare @rc int
declare @TraceID int

--максимальный размер отдельного файла 1 ГБ
declare @maxfilesize bigint = 1024
declare @now datetime = getdate()

--время окончания устанавливаем на 23:59:50
declare @stopTime datetime = DATEADD(ss,-10,DATEADD(dd,1, DateAdd(day,0,DateDiff(day,0,GETDATE()))))

--путь к папке трэйса
declare @folder nvarchar(200) = N''d:\SQL_Traces\'' + @@servicename + N''\''

--путь к файлк трэйса
declare @fileName nvarchar(245) = @folder + N''deadlocks '' + replace(convert(nvarchar(20), @now, 120), '':'', '''')
select @fileName

IF 
NOT EXISTS (SELECT * FROM ::fn_trace_getinfo(default) WHERE cast (VALUE AS VARCHAR(MAX)) LIKE ''%deadlocks%'') --если нету трейса с таким путем, запускаем
BEGIN

--включить трэйс с опцией rollover
exec @rc = sp_trace_create @TraceID output, 2, @fileName, @maxfilesize, @stopTime
if (@rc != 0)
	return

-- События
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 148, 1, @on
exec sp_trace_setevent @TraceID, 148, 41, @on
exec sp_trace_setevent @TraceID, 148, 4, @on
exec sp_trace_setevent @TraceID, 148, 12, @on
exec sp_trace_setevent @TraceID, 148, 11, @on
exec sp_trace_setevent @TraceID, 148, 51, @on
exec sp_trace_setevent @TraceID, 148, 14, @on
exec sp_trace_setevent @TraceID, 148, 26, @on
exec sp_trace_setevent @TraceID, 148, 60, @on
exec sp_trace_setevent @TraceID, 148, 64, @on
exec sp_trace_setevent @TraceID, 25, 15, @on
exec sp_trace_setevent @TraceID, 25, 8, @on
exec sp_trace_setevent @TraceID, 25, 32, @on
exec sp_trace_setevent @TraceID, 25, 56, @on
exec sp_trace_setevent @TraceID, 25, 1, @on
exec sp_trace_setevent @TraceID, 25, 9, @on
exec sp_trace_setevent @TraceID, 25, 25, @on
exec sp_trace_setevent @TraceID, 25, 57, @on
exec sp_trace_setevent @TraceID, 25, 2, @on
exec sp_trace_setevent @TraceID, 25, 10, @on
exec sp_trace_setevent @TraceID, 25, 11, @on
exec sp_trace_setevent @TraceID, 25, 35, @on
exec sp_trace_setevent @TraceID, 25, 4, @on
exec sp_trace_setevent @TraceID, 25, 12, @on
exec sp_trace_setevent @TraceID, 25, 13, @on
exec sp_trace_setevent @TraceID, 25, 6, @on
exec sp_trace_setevent @TraceID, 25, 14, @on
exec sp_trace_setevent @TraceID, 25, 22, @on
exec sp_trace_setevent @TraceID, 59, 32, @on
exec sp_trace_setevent @TraceID, 59, 56, @on
exec sp_trace_setevent @TraceID, 59, 1, @on
exec sp_trace_setevent @TraceID, 59, 25, @on
exec sp_trace_setevent @TraceID, 59, 57, @on
exec sp_trace_setevent @TraceID, 59, 2, @on
exec sp_trace_setevent @TraceID, 59, 14, @on
exec sp_trace_setevent @TraceID, 59, 22, @on
exec sp_trace_setevent @TraceID, 59, 35, @on
exec sp_trace_setevent @TraceID, 59, 4, @on
exec sp_trace_setevent @TraceID, 59, 12, @on
exec sp_trace_setevent @TraceID, 60, 1, @on
exec sp_trace_setevent @TraceID, 60, 9, @on
exec sp_trace_setevent @TraceID, 60, 3, @on
exec sp_trace_setevent @TraceID, 60, 4, @on
exec sp_trace_setevent @TraceID, 60, 5, @on
exec sp_trace_setevent @TraceID, 60, 6, @on
exec sp_trace_setevent @TraceID, 60, 7, @on
exec sp_trace_setevent @TraceID, 60, 8, @on
exec sp_trace_setevent @TraceID, 60, 10, @on
exec sp_trace_setevent @TraceID, 60, 11, @on
exec sp_trace_setevent @TraceID, 60, 12, @on
exec sp_trace_setevent @TraceID, 60, 14, @on
exec sp_trace_setevent @TraceID, 60, 21, @on
exec sp_trace_setevent @TraceID, 60, 22, @on
exec sp_trace_setevent @TraceID, 60, 25, @on
exec sp_trace_setevent @TraceID, 60, 26, @on
exec sp_trace_setevent @TraceID, 60, 32, @on
exec sp_trace_setevent @TraceID, 60, 35, @on
exec sp_trace_setevent @TraceID, 60, 41, @on
exec sp_trace_setevent @TraceID, 60, 49, @on
exec sp_trace_setevent @TraceID, 60, 51, @on
exec sp_trace_setevent @TraceID, 60, 55, @on
exec sp_trace_setevent @TraceID, 60, 56, @on
exec sp_trace_setevent @TraceID, 60, 57, @on
exec sp_trace_setevent @TraceID, 60, 58, @on
exec sp_trace_setevent @TraceID, 60, 60, @on
exec sp_trace_setevent @TraceID, 60, 61, @on
exec sp_trace_setevent @TraceID, 60, 64, @on
exec sp_trace_setevent @TraceID, 60, 66, @on


-- Настроить фильтры
declare @intfilter int
declare @bigintfilter bigint

exec sp_trace_setfilter @TraceID, 10, 0, 7, N''SQL Server Profiler - ba2f7e08-9367-4734-8f25-468af13073f6''

set @intfilter = 5
exec sp_trace_setfilter @TraceID, 32, 0, 0, @intfilter

exec sp_trace_setfilter @TraceID, 35, 0, 6, N''buh2_0''

-- Запустить трэйс
exec sp_trace_setstatus @TraceID, 1
END', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Start new trace with long queries]    Script Date: 6/25/2018 7:49:00 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Start new trace with long queries', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'IF
	(SELECT COUNT (DISTINCT traceID) FROM ::fn_trace_getinfo(default)) > 20  -- если трейсов больше 20, ставим ошибку и шлём нотификацию на почту	
BEGIN
			
	RAISERROR (''Warning: Trace count >20'', 16, 1)
				
		DECLARE @subj NVARCHAR(100) =''Too many traces on ''+ @@servicename
		DECLARE @bodytext NVARCHAR(100) =''Warning: Trace count >20''
		exec msdb.dbo.sp_send_dbmail
		@profile_name	= N''sql_mail'',
		@recipients		= N''vzheltonogov@urbgroup.ru'',
		@subject		= @subj,
		@body = @bodytext,
		@body_format	= ''TEXT'',
		@importance		= ''High''
		RETURN
END
-- 
declare @rc int
declare @TraceID int

--максимальный размер отдельного файла 1 ГБ
declare @maxfilesize bigint = 1024
declare @now datetime = getdate()

--время окончания устанавливаем на 23:59:50
declare @stopTime datetime = DATEADD(ss,-10,DATEADD(dd,1, DateAdd(day,0,DateDiff(day,0,GETDATE()))))

--путь к папке трэйса
declare @folder nvarchar(200) = N''d:\SQL_Traces\'' + @@servicename + N''\''

--путь к файлк трэйса
declare @fileName nvarchar(245) = @folder + N''dailyLong '' + replace(convert(nvarchar(20), @now, 120), '':'', '''')
select @fileName

IF 
NOT EXISTS (SELECT * FROM ::fn_trace_getinfo(default) WHERE cast (VALUE AS VARCHAR(MAX)) LIKE ''%dailyLong%'') --если нету трейса с таким путем, запускаем
BEGIN

--включить трэйс с опцией rollover
exec @rc = sp_trace_create @TraceID output, 2, @fileName, @maxfilesize, @stopTime
if (@rc != 0)
	return

-- События
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 10, 15, @on
exec sp_trace_setevent @TraceID, 10, 8, @on
exec sp_trace_setevent @TraceID, 10, 16, @on
exec sp_trace_setevent @TraceID, 10, 1, @on
exec sp_trace_setevent @TraceID, 10, 9, @on
exec sp_trace_setevent @TraceID, 10, 17, @on
exec sp_trace_setevent @TraceID, 10, 25, @on
exec sp_trace_setevent @TraceID, 10, 2, @on
exec sp_trace_setevent @TraceID, 10, 10, @on
exec sp_trace_setevent @TraceID, 10, 18, @on
exec sp_trace_setevent @TraceID, 10, 34, @on
exec sp_trace_setevent @TraceID, 10, 11, @on
exec sp_trace_setevent @TraceID, 10, 35, @on
exec sp_trace_setevent @TraceID, 10, 12, @on
exec sp_trace_setevent @TraceID, 10, 13, @on
exec sp_trace_setevent @TraceID, 10, 6, @on
exec sp_trace_setevent @TraceID, 10, 14, @on
exec sp_trace_setevent @TraceID, 12, 15, @on
exec sp_trace_setevent @TraceID, 12, 8, @on
exec sp_trace_setevent @TraceID, 12, 16, @on
exec sp_trace_setevent @TraceID, 12, 1, @on
exec sp_trace_setevent @TraceID, 12, 9, @on
exec sp_trace_setevent @TraceID, 12, 17, @on
exec sp_trace_setevent @TraceID, 12, 6, @on
exec sp_trace_setevent @TraceID, 12, 10, @on
exec sp_trace_setevent @TraceID, 12, 14, @on
exec sp_trace_setevent @TraceID, 12, 18, @on
exec sp_trace_setevent @TraceID, 12, 11, @on
exec sp_trace_setevent @TraceID, 12, 35, @on
exec sp_trace_setevent @TraceID, 12, 12, @on
exec sp_trace_setevent @TraceID, 12, 13, @on


-- Настроить фильтры
declare @intfilter int
declare @bigintfilter bigint

--исключить sp_reset_connection (TextData not like ''%sp_reset_connection%''
exec sp_trace_setfilter @TraceID, 1, 0, 7, N''%sp_reset_connection%''

--исключить события с пустым TextData
exec sp_trace_setfilter @TraceID, 1, 0, 1, NULL

--включить события с Duration >= 200
set @bigintfilter = 200000
exec sp_trace_setfilter @TraceID, 13, 0, 4, @bigintfilter

--исключить события с пустым Duration
set @bigintfilter = NULL
exec sp_trace_setfilter @TraceID, 13, 0, 1, @bigintfilter


-- Запустить трэйс
exec sp_trace_setstatus @TraceID, 1
END', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 2
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20101006, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'ae295231-3752-40e6-b5ef-aa3602c80cdd'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'On SQL Server Agent Start', 
		@enabled=1, 
		@freq_type=64, 
		@freq_interval=0, 
		@freq_subday_type=0, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20101009, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'25eaac09-0e9e-403c-bce4-d61bfb862c02'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


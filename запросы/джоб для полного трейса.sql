USE [msdb]
GO

/****** Object:  Job [Start Full Hourly SQL Trace]    Script Date: 01/31/2012 10:34:47 ******/
IF  EXISTS (SELECT job_id FROM msdb.dbo.sysjobs_view WHERE name = N'Start Full Hourly SQL Trace')
EXEC msdb.dbo.sp_delete_job @job_id=N'9c550dca-4a0e-41ae-aab9-68b5091728d8', @delete_unused_schedule=1
GO

USE [msdb]
GO

/****** Object:  Job [Start Full Hourly SQL Trace]    Script Date: 01/31/2012 10:34:47 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]]    Script Date: 01/31/2012 10:34:48 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Start Full Hourly SQL Trace', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Запуск трейса для анализа.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'repladmin', 
		@notify_email_operator_name=N'JobErrorOperator', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [start_trace]    Script Date: 01/31/2012 10:34:49 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'start_trace', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE
	@rc INT,
	@TraceID INT,
	@maxfilesize BIGINT = 10240,
	@now DATETIME = GETDATE(),
	@stopTime DATETIME,
	@folder NVARCHAR(200),
	@fileName NVARCHAR(245),
	@on BIT,
	@intfilter INT,
	@bigintfilter BIGINT

SET @stopTime = DATEADD(mi, 1, DATEADD(Hh, 1, CONVERT(NVARCHAR(20), @now, 120)))
SET @folder = N''x:\FullTraces\'' + @@SERVICENAME + N''\''
SET @fileName = @folder + N''hourly '' + REPLACE(CONVERT(NVARCHAR(20), @now, 120), '':'', '''')

--SELECT @now, @stopTime, @folder, @fileName

EXEC @rc = sp_trace_create @TraceID OUTPUT, 2, @fileName, @maxfilesize, @stopTime
IF (@rc != 0)
	RETURN

SET @on = 1

EXEC sp_trace_setevent @TraceID, 10, 15, @on
EXEC sp_trace_setevent @TraceID, 10, 8,  @on
EXEC sp_trace_setevent @TraceID, 10, 9,  @on
EXEC sp_trace_setevent @TraceID, 10, 12, @on
EXEC sp_trace_setevent @TraceID, 10, 35, @on
EXEC sp_trace_setevent @TraceID, 10, 1,  @on
EXEC sp_trace_setevent @TraceID, 10, 10, @on
EXEC sp_trace_setevent @TraceID, 10, 11, @on
EXEC sp_trace_setevent @TraceID, 10, 18, @on
EXEC sp_trace_setevent @TraceID, 10, 13, @on
EXEC sp_trace_setevent @TraceID, 10, 16, @on
EXEC sp_trace_setevent @TraceID, 10, 17, @on
EXEC sp_trace_setevent @TraceID, 10, 6,  @on
EXEC sp_trace_setevent @TraceID, 10, 14, @on
EXEC sp_trace_setevent @TraceID, 10, 34, @on
EXEC sp_trace_setevent @TraceID, 10, 25, @on
EXEC sp_trace_setevent @TraceID, 10, 2,  @on

EXEC sp_trace_setevent @TraceID, 12, 15, @on
EXEC sp_trace_setevent @TraceID, 12, 8,  @on
EXEC sp_trace_setevent @TraceID, 12, 9,  @on
EXEC sp_trace_setevent @TraceID, 12, 12, @on
EXEC sp_trace_setevent @TraceID, 12, 35, @on
EXEC sp_trace_setevent @TraceID, 12, 1,  @on
EXEC sp_trace_setevent @TraceID, 12, 10, @on
EXEC sp_trace_setevent @TraceID, 12, 11, @on
EXEC sp_trace_setevent @TraceID, 12, 18, @on
EXEC sp_trace_setevent @TraceID, 12, 13, @on
EXEC sp_trace_setevent @TraceID, 12, 16, @on
EXEC sp_trace_setevent @TraceID, 12, 17, @on
EXEC sp_trace_setevent @TraceID, 12, 6,  @on
EXEC sp_trace_setevent @TraceID, 12, 14, @on
EXEC sp_trace_setevent @TraceID, 12, 34, @on
EXEC sp_trace_setevent @TraceID, 12, 25, @on
EXEC sp_trace_setevent @TraceID, 12, 2,  @on

EXEC sp_trace_setfilter @TraceID, 1, 0, 7, N''%sp_reset_connection%''
EXEC sp_trace_setfilter @TraceID, 1, 0, 1, NULL


-- Запустить трэйс
EXEC sp_trace_setstatus @TraceID, 1', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Hourly', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20110828, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'7c7fb5f7-f71f-44a9-96a7-a88d8aadd8ae'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO



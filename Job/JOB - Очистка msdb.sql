USE [msdb]
GO

IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'Очистка msdb')
EXEC msdb.dbo.sp_delete_job @job_name=N'Очистка msdb', @delete_unused_schedule=1
GO

/****** Object:  Job [Очистка msdb]    Script Date: 09.11.2021 14:34:39 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 09.11.2021 14:34:39 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Очистка msdb', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Очистка данных старше 90 дней', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [clear]    Script Date: 09.11.2021 14:34:39 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'clear', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'-- (1) Либо использовать уже готовые хранимые процедуры sysmail_delete_mailitems_sp и sysmail_delete_log_sp:

DECLARE @DateBefore DATETIME 
SET @DateBefore = DATEADD(DAY, -90, GETDATE())

EXEC msdb.dbo.sysmail_delete_mailitems_sp @sent_before = @DateBefore --, @sent_status = ''sent''
EXEC msdb.dbo.sysmail_delete_log_sp @logged_before = @DateBefore


-- (2) История выполнения заданий SQL Server Agent также сохраняется в msdb. Когда записей в логе становится много с ним становится не сильно удобно работать, поэтому я стараюсь его периодически чистить sp_purge_jobhistory:

EXEC msdb.dbo.sp_purge_jobhistory @oldest_date = @DateBefore

-- (3) Еще нужно упомянуть, про информацию о резервных копиях, которая логируются в msdb. Старые записи о созданных бекапах можно удалять sp_delete_backuphistory:

EXEC msdb.dbo.sp_delete_backuphistory @oldest_date = @DateBefore', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Очистка msdb', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20211108, 
		@active_end_date=99991231, 
		@active_start_time=100, 
		@active_end_time=235959, 
		@schedule_uid=N'220291c7-e880-432d-9e57-7f7212438847'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



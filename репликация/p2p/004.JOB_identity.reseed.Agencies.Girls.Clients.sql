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
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'RESEED_Identity', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Обновляет identity на таблицах tblClients, tblMen.
Сделан для P2P-репликации.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'repladmin', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'reseed', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [svadba_catalog]
GO

DECLARE
	@sql NVARCHAR(MAX),
	@clients_identity_old INT, @clients_identity_new INT,
	@men_identity_old INT, @men_identity_new INT,
	@interval INT

-- tblClients
SELECT @clients_identity_old = IDENT_CURRENT(''tblClients'')

SET @interval = 60000

IF (CAST(RIGHT(CAST(@clients_identity_old AS nvarchar), 5) AS INT) BETWEEN 40001 AND 50000)
BEGIN
	SET @clients_identity_new = @clients_identity_old + @interval
	
	SET @sql = ''DBCC CHECKIDENT(tblClients, RESEED, '' + CAST(@clients_identity_new AS NVARCHAR) + '')''
	EXEC(@sql)
END

-- tblMen
SELECT @men_identity_old = IDENT_CURRENT(''tblMen'')

SET @interval = 60000

IF (CAST(RIGHT(CAST(@men_identity_old AS nvarchar), 5) AS INT) BETWEEN 40001 AND 50000)
BEGIN
	SET @men_identity_new = @men_identity_old + @interval
	
	SET @sql = ''DBCC CHECKIDENT(tblMen, RESEED, '' + CAST(@men_identity_new AS NVARCHAR) + '')''
	EXEC(@sql)
END', 
		@database_name=N'svadba_catalog', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'_reseed', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20111006, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'aa726f86-7a35-471d-8278-139b1e1af399'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO
USE [msdb]
GO

/****** Object:  Job [Репликация баз]    Script Date: 06.02.2024 11:32:39 ******/
EXEC msdb.dbo.sp_delete_job @job_id=N'ad17cfb8-f769-4452-a7e4-76c61c0d0434', @delete_unused_schedule=1
GO

/****** Object:  Job [Репликация баз]    Script Date: 06.02.2024 11:32:39 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Support]]    Script Date: 06.02.2024 11:32:39 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Support]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Support]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Репликация баз', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Восстановление копии баз. Перенесено с 1c-sql-02', 
		@category_name=N'[Support]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [1C_DO_ABTECH_REPL]    Script Date: 06.02.2024 11:32:39 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'1C_DO_ABTECH_REPL', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module dbatools;Set-DbaDbState -SqlInstance 1c-u-sql.sfn.local -Database 1C_DO_ABTECH_REPL -SingleUser -Force;Get-DbaDbBackupHistory -SqlInstance 1c-u-sql.sfn.local -Database 1C_DO_ABTECH -Last | Restore-DbaDatabase -SqlInstance 1c-u-sql.sfn.local -Database 1C_DO_ABTECH_REPL -ReplaceDbNameInFile -TrustDbBackupHistory -WithReplace;Set-DbaDbRecoveryModel  -SqlInstance 1c-u-sql.sfn.local -Database 1C_DO_ABTECH_REPL -RecoveryModel Simple -Confirm:$false;Invoke-DbaDbShrink -SqlInstance 1c-u-sql.sfn.local -Database 1C_DO_ABTECH_REPL -FileType Log -ShrinkMethod TruncateOnly;Remove-DbaDbBackupRestoreHistory -SqlInstance 1c-u-sql.sfn.local -Database 1C_DO_ABTECH_REPL -Confirm:$false;Set-DbaDbOwner -SqlInstance 1c-u-sql.sfn.local -Database 1C_DO_ABTECH_REPL -TargetLogin SFN\1c-u-app_gmsa$;"', 
		@flags=32
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [1C_Avancore_PIF_SFN_REPL]    Script Date: 06.02.2024 11:32:39 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'1C_Avancore_PIF_SFN_REPL', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module dbatools;Set-DbaDbState -SqlInstance 1c-u-sql.sfn.local -Database 1C_Avancore_PIF_SFN_REPL -SingleUser -Force;Get-DbaDbBackupHistory -SqlInstance 1c-sql-02.sfn.local -Database 1C_Avancore_PIF_SFN -Last | Restore-DbaDatabase -SqlInstance 1c-u-sql.sfn.local -Database 1C_Avancore_PIF_SFN_REPL -ReplaceDbNameInFile -TrustDbBackupHistory -WithReplace;Set-DbaDbRecoveryModel -SqlInstance 1c-u-sql.sfn.local -Database 1C_Avancore_PIF_SFN_REPL -RecoveryModel Simple -Confirm:$false;Invoke-DbaDbShrink -SqlInstance 1c-u-sql.sfn.local -Database 1C_Avancore_PIF_SFN_REPL -FileType Log -ShrinkMethod TruncateOnly;Remove-DbaDbBackupRestoreHistory -SqlInstance 1c-u-sql.sfn.local -Database 1C_Avancore_PIF_SFN_REPL -Confirm:$false;Set-DbaDbOwner -SqlInstance 1c-u-sql.sfn.local -Database 1C_Avancore_PIF_SFN_REPL -TargetLogin SFN\1c-u-app_gmsa$;"', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Reindex REPL databases]    Script Date: 06.02.2024 11:32:39 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Reindex REPL databases', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE dbo.IndexOptimize
@Databases = ''%REPL'',
@FragmentationLow = NULL,
@FragmentationMedium = ''INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'',
@FragmentationHigh = ''INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'',
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30,
@UpdateStatistics = ''ALL''
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Репликация баз', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20230912, 
		@active_end_date=99991231, 
		@active_start_time=70013, 
		@active_end_time=235959, 
		@schedule_uid=N'bf503d99-03cd-4b4c-8c1e-157ece5458a2'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



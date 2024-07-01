USE [msdb]
GO

IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'AlwaysOn.Sync')
EXEC msdb.dbo.sp_delete_job @job_name=N'AlwaysOn.Sync', @delete_unused_schedule=1
GO

/****** Object:  Job [AlwaysOn.Sync]    Script Date: 22.11.2023 15:23:05 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Support]]    Script Date: 22.11.2023 15:23:05 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Support]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Support]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'AlwaysOn.Sync', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Синхронизирует логины и джобы между нодами. Для работы нужно установить на сервер DBATOOLS. Т.к. подключается под gMSA учёткой ей выданы права sysadmin. WARNING: [14:59:06][Copy-DbaAgentJob] Issue dropping job | Only members of sysadmin role are allowed to update or delete jobs owned by a different login.', 
		@category_name=N'[Support]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [check for primary]    Script Date: 22.11.2023 15:23:05 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'check for primary', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'if master.dbo.fn_hadr_group_is_primary (''dwh-etl-p-ag'') = 0
begin
EXEC msdb..sp_stop_job N''$(ESCAPE_SQUOTE(JOBNAME))''    
end', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [sync]    Script Date: 22.11.2023 15:23:05 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'sync', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module dbatools;$primary =''dwh-etl-p-01.sfn.local'';$secondary=''dwh-etl-p-02.sfn.local'';Copy-DbaAgentOperator -Source $primary -Destination $secondary;Copy-DbaAgentJob -Source $primary -Destination $secondary -ExcludeJob ''Maintenance.AlwaysOn.Sync'',''AlwaysOn.CheckPrimary'',''AlwaysOn.Sync'',''cdc.SberbankCSDDataMart_capture'',''cdc.SberbankCSDDataMart_cleanup'',''cdc.CDIDataMart_capture'',''cdc.CDIDataMart_cleanup'',''cdc.SBOLDataMart_capture'',''cdc.SBOLDataMart_cleanup'',''cdc.SBOLDataMartPSI_capture'',''cdc.SBOLDataMartPSI_cleanup'',''Backup.Diff'',''Backup.Full'',''Backup.Log'',''Backup.Full.Pythoness_Transport_Archive'',''History.WhoIsActive'',''HistoryXE'',''HistoryXE.Report'',''History.Blocking'',''Maintenance.CheckDb'',''Maintenance.FreeProcCache'',''Maintenance.Rebuild'',''Maintenance.Update Statistics'',''Maintenance.Очистка msdb'',''Maintenance.Очистка'',''Maintenance.ShrinkAll'',''Monitoring'',''Monitoring.Jobs'',''Monitoring.LongTransactions'',''Monitoring.CheckLog'',''syspolicy_purge_history'',''sp_delete_backuphistory'',''sp_purge_jobhistory'',''SSIS Failover Monitor Job'',''AlwaysOn.CheckSSISDBFailover'',''SSIS Failover Monitor Job'' -Force;Copy-DbaLogin -Source $primary -Destination $secondary -ExcludeSystemLogins"', 
		@output_file_name=N'd:\MSSQL\Logs\AlwaysOn.Sync_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt', 
		@flags=32
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [delete old logs]    Script Date: 22.11.2023 15:23:05 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'delete old logs', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'PowerShell', 
		@command=N'## Delete files older than 90 days

$a = Get-ChildItem d:\MSSQL\Logs
foreach($x in $a)
    {
        $y = ((Get-Date) - $x.CreationTime).Days
        if ($y -gt 90 -and $x.PsISContainer -ne $True)
            {$x.Delete()}
    }', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'AlwaysOn.Sync', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20231109, 
		@active_end_date=99991231, 
		@active_start_time=512, 
		@active_end_time=235959, 
		@schedule_uid=N'1a681f27-26bc-48d8-94b7-117e60fdf434'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



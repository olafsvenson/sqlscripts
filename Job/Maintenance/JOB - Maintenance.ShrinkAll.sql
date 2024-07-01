USE [msdb]
GO

IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'Maintenance.ShrinkAll')
EXEC msdb.dbo.sp_delete_job @job_name=N'Maintenance.ShrinkAll', @delete_unused_schedule=1
GO

/****** Object:  Job [Maintenance.ShrinkAll]    Script Date: 14.06.2022 11:26:05 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Support]]    Script Date: 14.06.2022 11:26:05 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Support]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Support]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Maintenance.ShrinkAll', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Support]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQLAlert', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [shrinkall]    Script Date: 14.06.2022 11:26:05 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'shrinkall', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET QUOTED_IDENTIFIER ON
GO

DECLARE @SQL NVARCHAR(MAX)=
(
 select  
    ''USE ['' + d.NAME + N'']'' + CHAR(13) + CHAR(10) 
  + ''DBCC SHRINKFILE (N'''''' + mf.name + N'''''' , 0, TRUNCATEONLY)'' 
  + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
 FROM 
    sys.master_files mf 
  JOIN sys.databases d 
   ON mf.database_id = d.database_id 
 WHERE d.database_id > 4 
   AND d.state = 0 -- ONLINE
   and d.is_read_only = 0
   and mf.type_desc = ''LOG'' -- ROWS , LOG
    FOR XML PATH(''''), TYPE).value(''.'', ''NVARCHAR(MAX)''
);
PRINT @SQL
EXEC sp_executesql @SQL;', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'_Maintenance.ShrinkAll', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20220610, 
		@active_end_date=99991231, 
		@active_start_time=72100, 
		@active_end_time=235959, 
		@schedule_uid=N'e0f956a3-6dbf-40e9-9a62-c9ec72f19a3a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



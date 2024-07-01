USE [msdb]
GO

/****** Object:  Job [Тестирование бекапов]    Script Date: 21.05.2024 17:27:56 ******/
IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'Тестирование бекапов')
EXEC msdb.dbo.sp_delete_job @job_name=N'Тестирование бекапов', @delete_unused_schedule=1
GO


/****** Object:  Job [Тестирование бекапов]    Script Date: 21.05.2024 17:27:56 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 21.05.2024 17:27:57 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Тестирование бекапов', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'В 1-ом  шаге указываем сервера, во 2-ом кому должен прийти отчет (данные за последние 8ч).', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQLAlert', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [all servers]    Script Date: 21.05.2024 17:27:57 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'all servers', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'CmdExec', 
		@command=N'powershell.exe -ExecutionPolicy Bypass -Command "Import-Module dbatools;$Servers = ''1c-sql.SFN.LOCAL'',''1c-sql-02.SFN.LOCAL'',''sfn-etl-p-01.SFN.LOCAL'',''sfn-dmart-p-01.SFN.LOCAL'',''sfn-dmart-p-02.SFN.LOCAL'',''lk-dmart-p-01.SFN.LOCAL,54831'',''lk-dmart-p-02.SFN.LOCAL,54831'',''sql-01.SFN.LOCAL'',''sql-p-02.SFN.LOCAL'',''dwh-p-01.SFN.LOCAL'',''dwh-p-02.SFN.LOCAL'';foreach ($Server in $Servers) {Test-DbaLastBackup -Destination db-restore-p-01.SFN.LOCAL -SqlInstance  $Server -MaxTransferSize 4194304 -BufferCount 24 | Select-Object -Property RestoreStart, SourceServer, Database, BackupFiles, RestoreResult,DBCCResult | Write-DbaDbTableData -SqlInstance db-restore-p-01.SFN.LOCAL -Database master  -Table TestRestoreStatus -AutoCreateTable}"', 
		@output_file_name=N'd:\MSSQL\Logs\Тестирование_бекапов_Step_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt', 
		@flags=32
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Отправка отчета]    Script Date: 21.05.2024 17:27:57 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Отправка отчета', 
		@step_id=2, 
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

DECLARE @HTML VARCHAR(MAX),@OutputRestoreResultHTML VARCHAR(MAX),@OutputServerListHTML VARCHAR(MAX), @OutputDbccResultHTML VARCHAR(MAX),
		@OutputTableHTML VARCHAR(MAX),@hour smallint = -32 -- данные за последние 32ч (!!!) т.к. джоб может работать очень долго

IF (OBJECT_ID(''tempdb..##TestRestoreStatus'') IS NOT NULL) DROP TABLE ##TestRestoreStatus
SELECT
	   [RestoreStart]
      ,[SourceServer]
      ,[Database]
      ,[BackupFiles]
      ,[RestoreResult]
      ,[DbccResult]
	into ##TestRestoreStatus
FROM [master].[dbo].[TestRestoreStatus]
where [RestoreStart] > dateadd(hh, @hour, getdate()) -- данные за последние 8ч (!!!)

EXEC sp_ExportTable2Html
    @TableName = ''##TestRestoreStatus'', -- varchar(max)
	@OrderBy=''[RestoreResult], [DbccResult]'',
    @Script = @OutputTableHTML OUTPUT -- varchar(max)

IF (OBJECT_ID(''tempdb..##TestRestoreServerList'') IS NOT NULL) DROP TABLE ##TestRestoreServerList
SELECT distinct [SourceServer]
	into ##TestRestoreServerList
FROM [master].[dbo].[TestRestoreStatus]
where [RestoreStart] > dateadd(hh, @hour ,getdate()) -- данные за последние 8ч (!!!)

EXEC sp_ExportTable2Html
    @TableName = ''##TestRestoreServerList'', -- varchar(max)
	@OrderBy=''[SourceServer]'',
    @Script = @OutputServerListHTML OUTPUT -- varchar(max)


IF (OBJECT_ID(''tempdb..##RestoreStatus'') IS NOT NULL) DROP TABLE ##RestoreStatus
SELECT	   
       [RestoreResult], count(*) as ''Count''
	into ##RestoreStatus
FROM [master].[dbo].[TestRestoreStatus]
where 
[RestoreStart] > dateadd(hh, @hour, getdate()) -- данные за последние 8ч (!!!)
group by  [RestoreResult]

EXEC sp_ExportTable2Html
    @TableName = ''##RestoreStatus'', -- varchar(max)
	@OrderBy=''[RestoreResult]'',
    @Script = @OutputRestoreResultHTML OUTPUT -- varchar(max)

IF (OBJECT_ID(''tempdb..##dbccStatus'') IS NOT NULL) DROP TABLE ##dbccStatus
SELECT	   
       [DbccResult], count(*) as ''Count''
into ##dbccStatus
FROM [master].[dbo].[TestRestoreStatus]
where 
[RestoreStart] > dateadd(hh, @hour, getdate()) -- данные за последние 8ч (!!!)
group by  [DbccResult]
      

EXEC sp_ExportTable2Html
@TableName = ''##dbccStatus'', -- varchar(max)
@OrderBy=''[DbccResult]'',
@Script = @OutputDbccResultHTML OUTPUT -- varchar(max)

SET @HTML =''<h2>Отчет по тестированию бекапов</h2><br />Список серверов''+ISNULL(@OutputServerListHTML, '''')+ ''<br/>Результат восстановления''+ ISNULL(@OutputRestoreResultHTML, '''')+''<br />Результат CHECKDB''+ ISNULL(@OutputDbccResultHTML, '''')+''<br />Ошибки (если есть) отображаются в начале<br/>'' + ISNULL(@OutputTableHTML, '''')
	
EXEC msdb.dbo.sp_send_dbmail
@profile_name = ''DBA-Alerts'', -- sysname
@recipients = ''vzheltonogov@sfn-am.ru'', -- varchar(max)
@subject = N''Test Restore Report'', -- nvarchar(255)
@body = @HTML, -- nvarchar(max)
@body_format = ''html''

', 
		@database_name=N'master', 
		@output_file_name=N'd:\MSSQL\Logs\Тестирование_бекапов_Step_$(ESCAPE_SQUOTE(STEPID))_$(ESCAPE_SQUOTE(STRTDT))_$(ESCAPE_SQUOTE(STRTTM)).txt', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'_TestRestoreBackup', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=36, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20220201, 
		@active_end_date=99991231, 
		@active_start_time=3016, 
		@active_end_time=235959, 
		@schedule_uid=N'a6e5f534-d493-4bc9-892a-eb59eea43b38'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



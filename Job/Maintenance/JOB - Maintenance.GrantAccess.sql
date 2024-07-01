USE [msdb]
GO

IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'Maintenance.GrantAccess')
EXEC msdb.dbo.sp_delete_job @job_name=N'Maintenance.GrantAccess', @delete_unused_schedule=1
GO
/****** Object:  Job [Maintenance.GrantAccess]    Script Date: 19.05.2023 10:44:49 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Support]]    Script Date: 19.05.2023 10:44:49 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Support]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Support]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Maintenance.GrantAccess', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Выдает права на базы указанным  группам', 
		@category_name=N'[Support]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [sec_SQL_role_devel_DC-1C-DEV]    Script Date: 19.05.2023 10:44:50 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'sec_SQL_role_devel_DC-1C-DEV', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Use master
GO

--CONFIG
DECLARE @UserName VARCHAR(50) = ''SFN\sec_SQL_role_devel_DC-1C-DEV''
DECLARE @PrintOnly bit = 0
DECLARE @Add_DataReader bit = 1
DECLARE @Add_DataWriter bit = 1
DECLARE @Add_DDLAdmin bit = 1

-------------------------------------------
DECLARE @dbname VARCHAR(50)
DECLARE @statement NVARCHAR(max)
DECLARE @ParmDefinition NVARCHAR(500);
DECLARE @UserExists bit

DECLARE db_cursor CURSOR
LOCAL FAST_FORWARD
FOR
	SELECT name
	FROM sys.databases
	WHERE name NOT IN (''master'',''model'',''msdb'',''tempdb'',''distribution'')
	and state_desc = ''ONLINE''

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @dbname
WHILE @@FETCH_STATUS = 0
BEGIN

--Check if user already exists in the database
SET @statement = N''USE '' + QUOTENAME(@dbname) + N'';
IF EXISTS (SELECT [name]
FROM [sys].[database_principals]
WHERE [name] = '''''' + @UserName + '''''')
set @UserExistsOUT = 1
else
set @UserExistsOUT = 0''
SET @ParmDefinition = N''@UserExistsOUT bit OUTPUT'';

EXEC sp_executesql @statement, @ParmDefinition, @UserExistsOUT = @UserExists OUTPUT

----Start Creating Script
SET @statement = ''use ''+ QUOTENAME(@dbname) +'';''

--If user doesn''t exist then add CREATE statement
IF @UserExists = 0
BEGIN
SET @statement = @statement + char(10) + ''CREATE USER [''+ @UserName +''] FOR LOGIN [''+ @UserName +''];''
END

IF @Add_DataReader = 1
SET @statement = @statement + char(10) + ''EXEC sp_addrolemember N''''db_datareader'''', [''+ @UserName +''];''

IF @Add_DataWriter = 1
SET @statement = @statement + char(10) + ''EXEC sp_addrolemember N''''db_datawriter'''', [''+ @UserName +''];''

IF @Add_DDLAdmin  = 1
SET @statement = @statement + char(10) + ''EXEC sp_addrolemember N''''db_ddladmin'''', [''+ @UserName +''];''




IF @PrintOnly = 1
PRINT @statement
ELSE
exec sp_executesql @statement

FETCH NEXT FROM db_cursor INTO @dbname
END
CLOSE db_cursor
DEALLOCATE db_cursor', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [sec_SQL_SA_role_UAT]    Script Date: 19.05.2023 10:44:50 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'sec_SQL_SA_role_UAT', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Use master
GO

--CONFIG
DECLARE @UserName VARCHAR(50) = ''SFN\sec_SQL_SA_role_UAT''
DECLARE @PrintOnly bit = 0
DECLARE @Add_DataReader bit = 1
DECLARE @Add_DataWriter bit = 1
DECLARE @Add_DDLAdmin bit = 1

-------------------------------------------
DECLARE @dbname VARCHAR(50)
DECLARE @statement NVARCHAR(max)
DECLARE @ParmDefinition NVARCHAR(500);
DECLARE @UserExists bit

DECLARE db_cursor CURSOR
LOCAL FAST_FORWARD
FOR
	SELECT name
	FROM sys.databases
	WHERE name NOT IN (''master'',''model'',''msdb'',''tempdb'',''distribution'')
	and state_desc = ''ONLINE''

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @dbname
WHILE @@FETCH_STATUS = 0
BEGIN

--Check if user already exists in the database
SET @statement = N''USE '' + QUOTENAME(@dbname) + N'';
IF EXISTS (SELECT [name]
FROM [sys].[database_principals]
WHERE [name] = '''''' + @UserName + '''''')
set @UserExistsOUT = 1
else
set @UserExistsOUT = 0''
SET @ParmDefinition = N''@UserExistsOUT bit OUTPUT'';

EXEC sp_executesql @statement, @ParmDefinition, @UserExistsOUT = @UserExists OUTPUT

----Start Creating Script
SET @statement = ''use ''+ QUOTENAME(@dbname) +'';''

--If user doesn''t exist then add CREATE statement
IF @UserExists = 0
BEGIN
SET @statement = @statement + char(10) + ''CREATE USER [''+ @UserName +''] FOR LOGIN [''+ @UserName +''];''
END

IF @Add_DataReader = 1
SET @statement = @statement + char(10) + ''EXEC sp_addrolemember N''''db_datareader'''', [''+ @UserName +''];''

IF @Add_DataWriter = 1
SET @statement = @statement + char(10) + ''EXEC sp_addrolemember N''''db_datawriter'''', [''+ @UserName +''];''

IF @Add_DDLAdmin  = 1
SET @statement = @statement + char(10) + ''EXEC sp_addrolemember N''''db_ddladmin'''', [''+ @UserName +''];''




IF @PrintOnly = 1
PRINT @statement
ELSE
exec sp_executesql @statement

FETCH NEXT FROM db_cursor INTO @dbname
END
CLOSE db_cursor
DEALLOCATE db_cursor', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Maintenance.GrantAccess', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20230519, 
		@active_end_date=99991231, 
		@active_start_time=213, 
		@active_end_time=235959, 
		@schedule_uid=N'f0570f8b-e950-468e-8c7b-ddb24fa74432'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



USE [msdb]
GO

/****** Object:  Job [ActualDT]    Script Date: 6/25/2018 7:47:51 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 6/25/2018 7:47:51 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'ActualDT', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Проставляет текущее время в каждую пользовательскую БД в таблицу ActualDT

Нужен, для мониторинга LogShippinga', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		--@notify_email_operator_name=N'SQLAlert'
		 @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [set]    Script Date: 6/25/2018 7:47:51 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'set', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=1, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Declare @StrSQL varchar(4000)

Declare @Name VARCHAR(100)
declare curXXX cursor FAST_FORWARD READ_ONLY for
	 SELECT Name FROM master.dbo.sysdatabases sd			-- Список нормальных БД 
	  WHERE	sd.STATUS & 32 =0 	-- loading 
		AND sd.STATUS & 64 =0	-- pre recovery 
		AND sd.STATUS & 128=0	-- recovering 
		AND sd.STATUS & 256=0	-- not recovered 
		AND sd.STATUS & 512=0	-- offline (ALTER DATABASE) 
		AND sd.STATUS &1024=0	-- read only (ALTER DATABASE) 
		AND sd.STATUS &2048=0	-- dbo use only (ALTER DATABASE using SET RESTRICTED_USER) 
		AND sd.STATUS &4096=0	-- single user (ALTER DATABASE) 
		AND sd.STATUS &32768=0	--	 emergency mode
		AND NAME NOT IN (''master'',''msdb'',''distribution'',''model'',''tempdb'',''TraceReport'',''Monitoring'')
	 ORDER BY Name

open curXXX
fetch next from curXXX into @Name
WHILE (@@FETCH_STATUS =0) begin
	Set @StrSQL=
		''USE [''+@Name+'']	
		IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N''''[''+@Name+''].[dbo].[ActualDT]'''') AND type in (N''''U''''))	 
		BEGIN
		  CREATE TABLE ActualDT (DT datetime)
		  INSERT INTO ActualDT (DT) VALUES (GETDATE())
		END
		UPDATE top(1) [''+@Name+''].[dbo].ActualDT SET DT = getdate()'' 	-- Устанавливаем текущее время

--	PRINT @StrSQL
	EXEC (@StrSQL)
  fetch next from curXXX into @Name
end
close curXXX
deallocate curXXX', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'_5min', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=5, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20170201, 
		@active_end_date=99991231, 
		@active_start_time=0, 
		@active_end_time=235959, 
		@schedule_uid=N'5df05ed9-7c58-4b80-b5f1-bba3bd8eaca6'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


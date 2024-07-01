USE [msdb]
GO


IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'** Остановка регламентных заданий')
EXEC msdb.dbo.sp_delete_job @job_name=N'** Остановка регламентных заданий', @delete_unused_schedule=1
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
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'** Остановка регламентных заданий', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [** Обновление статистики]    Script Date: 15.02.2021 12:02:49 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'** Обновление статистики', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @JobName sysname = ''** Обновление статистики''

IF EXISTS
(
	SELECT 
		sj.name,
		DATEDIFF(SECOND,aj.start_execution_date,GetDate()) AS Seconds
	FROM msdb..sysjobactivity aj
		JOIN msdb..sysjobs sj on sj.job_id = aj.job_id
	WHERE aj.stop_execution_date IS NULL -- job hasn''t stopped running
		AND aj.start_execution_date IS NOT NULL -- job is currently running
		AND sj.name = @JobName -- имя джоба
		and not EXISTS
		( -- make sure this is the most recent run
			select 1
			from msdb..sysjobactivity new
			where new.job_id = aj.job_id
			and new.start_execution_date > aj.start_execution_date
		)
)
BEGIN
	-- если джоб запущен, то останавливаем его
	exec msdb..sp_stop_job   @job_name = @JobName 

--	RAISERROR(@JobName, 16, 1)
end', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [05.2. Обслуживание индексов. Реиндексация (КД 0242-2314 15мин)]    Script Date: 15.02.2021 12:02:49 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'05.2. Обслуживание индексов. Реиндексация (КД 0242-2314 15мин)', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @JobName sysname = ''05.2. Обслуживание индексов. Реиндексация (КД 0242-2314 15мин)''

IF EXISTS
(
	SELECT 
		sj.name,
		DATEDIFF(SECOND,aj.start_execution_date,GetDate()) AS Seconds
	FROM msdb..sysjobactivity aj
		JOIN msdb..sysjobs sj on sj.job_id = aj.job_id
	WHERE aj.stop_execution_date IS NULL -- job hasn''t stopped running
		AND aj.start_execution_date IS NOT NULL -- job is currently running
		AND sj.name = @JobName -- имя джоба
		and not EXISTS
		( -- make sure this is the most recent run
			select 1
			from msdb..sysjobactivity new
			where new.job_id = aj.job_id
			and new.start_execution_date > aj.start_execution_date
		)
)
BEGIN
	-- если джоб запущен, то останавливаем его
	exec msdb..sp_stop_job   @job_name = @JobName 

--	RAISERROR(@JobName, 16, 1)
end', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'_8:01', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20210208, 
		@active_end_date=99991231, 
		@active_start_time=80100, 
		@active_end_time=235959, 
		@schedule_uid=N'9c93edc5-9d3b-45a7-b52a-ee6cd27e0a54'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



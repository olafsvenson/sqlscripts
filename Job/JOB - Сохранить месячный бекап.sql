use master
go

IF OBJECT_ID ('CopyLastFullBackup', 'P') IS NOT NULL
    DROP PROCEDURE CopyLastFullBackup;
GO  

Create proc CopyLastFullBackup (
								@dbname sysname
							   ,@destination nvarchar(512)
							   )
as
set nocount on

declare @last_bak_path nvarchar(260)
		,@ag_role sysname

-- получаем путь последнего бекапа
SELECT TOP 1
	   @last_bak_path = msdb.dbo.backupmediafamily.physical_device_name   
FROM   msdb.dbo.backupmediafamily  
   INNER JOIN msdb.dbo.backupset ON msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id  
WHERE  msdb.dbo.backupset.type = 'D' 
	   and msdb.dbo.backupset.is_copy_only = 0
	   AND msdb.dbo.backupset.database_name = @dbname
ORDER BY  msdb.dbo.backupset.backup_start_date DESC

-- определяем первичную ноду AlwaysOn(если есть)
SELECT
	@ag_role = hars.role_desc
FROM
	sys.databases d
	INNER JOIN sys.dm_hadr_availability_replica_states hars ON d.replica_id = hars.replica_id
WHERE
	database_id = DB_ID(@dbname);

if @last_bak_path is not null and @destination is not null and (@ag_role <> N'SECONDARY' or @ag_role is null)
	exec master.sys.xp_copy_files @last_bak_path, @destination
GO

USE [msdb]
GO

IF EXISTS (SELECT job_id 
            FROM msdb.dbo.sysjobs_view 
            WHERE name = N'Сохранить бекапы в архив')
EXEC msdb.dbo.sp_delete_job @job_name=N'Сохранить бекапы в архив', @delete_unused_schedule=1

/****** Object:  Job [Сохранить бекапы в архив]    Script Date: 09.02.2022 13:16:48 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Support]]    Script Date: 09.02.2022 13:16:48 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Support]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Support]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Сохранить бекапы в архив', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Раз в месяц сохраняем бекапы для поднятия исторических срезов данных', 
		@category_name=N'[Support]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'SQLAlert', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [базы]    Script Date: 09.02.2022 13:16:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Список баз', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec master.dbo.CopyLastFullBackup
@dbname = ''LkDataMart''
,@destination = ''\\db-backups-p-01\Backups\_Archive\lk-dmart-p\LkDataMart''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'_Monthly', 
		@enabled=1, 
		@freq_type=32, 
		@freq_interval=2, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=1, 
		@freq_recurrence_factor=1, 
		@active_start_date=20220209, 
		@active_end_date=99991231, 
		@active_start_time=70000, 
		@active_end_time=235959, 
		@schedule_uid=N'cd9304ff-7788-40dd-b893-1c5f9525e600'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


